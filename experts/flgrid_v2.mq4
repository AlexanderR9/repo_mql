//+------------------------------------------------------------------+
//|                                                      fl_grid.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <fllib1/flgridobject.mqh>
#include <fllib1/flgridinputparams.mqh>
#include <fllib1/flgridexchange.mqh>


#define MAIN_TIMER_INTERVAL         2
#define GRID_COUNT                  10

//expert vars
LFLGrid fl_grids[GRID_COUNT];
string ex_name = "flgrid";
int ex_magic = 0;
bool ex_invalid_state = false;
double start_price = 0; //цена инструмента на момент запуска советника
double cmd_repay_sum = 0; //сумма полученная от главного советника на погашение хеджированных сеток
double cmd_repay_sum_opened = 0; //сумма полученная от главного советника на погашение открытой сетки
bool chart_event_off = false;
int m_pause = 0;


LGridPanel trade_type_panel("ttpanel", 1, 1, false);
LGridPanel profit_moment_panel("lpmpanel", 1, 1, false);
//FLGridProfitMoment lp_moment; 


////////////////EXCHANGER////////////////////////////
FLGridExchanger *m_exchanger = NULL;
void initExchanger(string chart_key)
{
   if (m_exchanger)
   {
      delete m_exchanger;
      m_exchanger = NULL;
   }
   
   m_exchanger = new FLGridExchanger();
   m_exchanger.setKey(chart_key);
   m_exchanger.setOwnChartID(ChartID());
   m_exchanger.emitStarted();
}
void deinitExchanger(bool need_emit_destroy)
{
   if (m_exchanger)
   {
      Sleep(50);
      if (need_emit_destroy)
         m_exchanger.emitDestroy();
      Sleep(100);
      
      delete m_exchanger;
      m_exchanger = NULL;
   }
}
////////////////EXCHANGER////////////////////////////



//+------------------------------------------------------------------+
//| Expert MQL functions                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   chart_event_off = true;
   m_pause = 0;
   initTradeTypePanel();
   resetStartPrice();
   setGridsParams();
   calcMagic();
   loadState();
   EventSetTimer(int(MAIN_TIMER_INTERVAL));   
   
   Print("Expert FL_GRID_v2 started!  COUPLE="+Symbol()+"    TF="+IntegerToString(PERIOD_CURRENT)+"  magic="+IntegerToString(ex_magic));   
   
   
   initExchanger(Symbol());
   m_exchanger.emitOpenedPos(fl_grids[0].openedOrderSLot());
   chart_event_off = false;
   
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   chart_event_off = true;
   EventKillTimer();   
   saveState();
   hideTradeTypePanel();
   profit_moment_panel.destroy();
   deinitExchanger(true);
   
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (chart_event_off) return;
   if (sparam != "general") return;
   if (id < CHARTEVENT_CUSTOM) return;
   
   m_exchanger.receiveMsg(id, lparam, dparam, sparam);
}
void OnTimer() 
{
   if (m_pause > 0) {m_pause--; return;}
   mainExec();
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void mainExec()
{
   if (ex_invalid_state) {Print("mainExec(): INVALID STATE, check params!!!"); return;}
   if (findTradeMode()) return;
   
   int pos = hasNeedCloseGrid();
   if (pos >= 0) {gridsExec(pos); return;}
   
   if (cmd_repay_sum > 0) {tryRepayHedgeOrdersGrid(); return;}
   else if (cmd_repay_sum_opened > 0) {tryRepayOrdersOpenedGrid(); return;}
   
   pos = 0;
   readExchamgerNewMessages();
   if (cmd_repay_sum > 0) tryRepayHedgeOrdersGrid();
   else gridsExec(pos);
}
void readExchamgerNewMessages()
{
   int n = m_exchanger.msgCount();
   if (n == 0) return;

   //Print("Exchanger records: ", n);  
   for (int i=0; i<n; i++)
   {
      if (m_exchanger.isRecReaded(i)) continue;
   
      FLGridExchangeMsg msg;
      m_exchanger.getRecord(i, msg);
      if (msg.isRepayType())
      {
         cmd_repay_sum = msg.d_value;
         break;
      }
      else if (msg.isRepayOpenedType())
      {
         cmd_repay_sum_opened = msg.d_value;
         break;
      }
   }
}
void tryRepayOrdersOpenedGrid() //погашение открытой сетки
{
   Print("tryRepayOrdersOpenedGrid()  sum=", cmd_repay_sum_opened);
   int i_grid = openedGridIndex();
   if (i_grid < 0)
   {
      Print("tryRepayOrdersOpenedGrid() - ERR: not found opened grid now");
      cmd_repay_sum_opened = 0;
      return;
   }   
   
   m_pause = 5;
   fl_grids[i_grid].setRepayOpened(cmd_repay_sum_opened);
   Print("tryRepayOrdersOpenedGrid() after repay:  sum=", cmd_repay_sum_opened);
   if (cmd_repay_sum_opened < 0) 
      m_exchanger.emitGetedProfit(cmd_repay_sum_opened);
   cmd_repay_sum_opened = 0;
}
void tryRepayHedgeOrdersGrid() //погашение старшей хеджированной сетки
{
   Print("tryRepayHedgeOldesGrid()  sum=", cmd_repay_sum);
   int i_grid = hasHedgeGrid();
   if (i_grid < 0)
   {
      Print("tryRepayHedgeOldesGrid() - ERR: not found hedged grid");
      m_exchanger.emitGetedProfit(cmd_repay_sum);
      cmd_repay_sum = 0;
      return;
   }   
   
   double profit = MathAbs(fl_grids[i_grid].hedgeLoss());
   if (profit > cmd_repay_sum) {profit = cmd_repay_sum; cmd_repay_sum = 0;}
   else cmd_repay_sum -= profit;
   fl_grids[i_grid].applyOtherProfit(profit);
   
   if (MathAbs(cmd_repay_sum) < 0.01) cmd_repay_sum = 0;
}
void gridsExec(int start_pos)
{
   //Print("gridsExec():  start_pos=", start_pos);
   int result = 0;
   string err = "";

   for (int i=start_pos; i<GRID_COUNT; i++)
   {
      fl_grids[i].exec(result, err);
      int grid_number = fl_grids[i].number();
      
      switch (result)
      {
         case erLookNextGrid: break;
         case erGridBreak: {Print("gridsExec():  i=",i, "  reuslt=erGridBreak"); return;} //некорректные входные параметры сетки, прервать просмотр сеток, начиная с этой
         
         case erFinishExecuting:
         {
            m_exchanger.emitCurPLOpenedGrid(fl_grids[i].currentPL());
            return;
         }         
         case erOpenedGridOrder:
         {
            Print("opened next order for grid ", grid_number);
            m_exchanger.emitOpenedPos(fl_grids[i].lastOrderLot());
            return;
         }         
         case erOpenedHedgeOrder:
         {
            Print("opened hedge order for grid ", grid_number);
            m_exchanger.emitOpenedPos(fl_grids[i].maxGridLot());
            m_exchanger.emitHedgeGrid(fl_grids[i].hedgeLoss());
            return;
         }
         case erHasError:
         {
            Print("ERR: has error by executing for grid ", fl_grids[i].number(), "   GetLastError()=", GetLastError());
            Print(err);
            return;
         }
         case erGetedProfit:
         {
            return;
         }
         case erGridClosed:
         {
            Print(Symbol(), "  emit erGridClosed  profit=", fl_grids[i].lastProfit());
            gridClosed(i);
            return;
         }
         default:
         {
            Print("WARNING: unknown exec result code: ", result);
            return;
         }
      }
   }
}
void gridClosed(int i)
{
   m_exchanger.emitCurPLOpenedGrid(0);
   
   double last_closed_profit = fl_grids[i].lastProfit();
   Print("gridClosed i_grid=", i,  "  closed_profit=", last_closed_profit,  "    ",Symbol());
   if (i == 0)
   {
      resetStartPrice();
      hideTradeTypePanel();
   }
   
   int hedge_pos = hasHedgeGrid();
   if (hedge_pos >= 0) cmd_repay_sum += last_closed_profit;
   else m_exchanger.emitGetedProfit(last_closed_profit);
}  
int hasHedgeGrid() //вернуть индекс старшей хеджированной сетки или -1
{
   int pos = -1;
   for (int i=0; i<GRID_COUNT; i++)
      if (fl_grids[i].hedgingNow()) pos = i;
      else break;
   return pos;   
}
int openedGridIndex() //индекс рабочей сетки (не хеджированной)
{
   for (int i=0; i<GRID_COUNT; i++)
   {
      if (!fl_grids[i].hedgingNow() && !fl_grids[i].notWorking()) return i;
   }
   return -1;   
}
void resetStartPrice()
{
   start_price = MarketInfo(Symbol(), MODE_BID);
   Print("resetStartPrice()  start_price=", DoubleToStr(start_price, 4));  
}
bool findTradeMode() // признак того что сейчас только определяется в какую сторону торговать
{
   if (ex_invalid_state) return false; 
   if (!fl_grids[0].notWorking()) return false;
   if (StartTrade <= 0) return false;
   
   double current_price = MarketInfo(Symbol(), MODE_BID);
   int pips = LFLGrid::pricesDiff(start_price, current_price);
   //Print(" findTradeMode()  pips=", pips);
   bool ok = (MathAbs(pips) >= StartTrade);
   if (ok) setGridsTradeKind(((pips > 0) ? OP_SELL : OP_BUY), ok);   
   return !ok;
}
void setGridsTradeKind(int cmd, bool &ok)
{
   if (cmd != fl_grids[0].tradeKind())
   {
      ok = false;
      resetStartPrice();
      return;
   }

   ok = true;
   startTradeTypePanel(cmd);      
}
int hasNeedCloseGrid()
{
   if (ex_invalid_state) return -1;
   for (int i=0; i<GRID_COUNT; i++)
      if (fl_grids[i].needClose()) return i;
   return -1;   
}
void loadState()
{
   if (ex_invalid_state) return;
   
   for (int i=0; i<GRID_COUNT; i++)
      fl_grids[i].loadState();   
      
   if (!fl_grids[0].notWorking())
   {
      startTradeTypePanel(fl_grids[0].tradeKind());    
   }
}
void saveState()
{
   if (ex_invalid_state) return;
   
   for (int i=0; i<GRID_COUNT; i++)
      fl_grids[i].saveState();
}
void calcMagic()
{
   ex_magic = 0;
   if (ex_invalid_state) return;
   
   int k = fl_grids[0].isBuyGrid() ? 10000 : 20000;
   string s = Symbol();
   for (int i=0; i< 10000; i++)
   {
      if (s == SymbolName(i, false)) 
      {
         ex_magic = k + i;
         break;
      }
   }
   
   for (int i=0; i<GRID_COUNT; i++)
      fl_grids[i].setMagic(ex_magic);
   
}
string ex_id() 
{
   return (ex_name + IntegerToString(ex_magic));
}

//установка всех параметров для всех сеток при запуске
void setGridsParams()
{
   if (GRID_COUNT != 10)
   {
      Print("ERR: invalid GRID_COUNT ", GRID_COUNT);
      ex_invalid_state = true;
      return;
   }
   
   string trade_kind = TradeKind;
   trade_kind = StringTrimLeft(trade_kind);
   trade_kind = StringTrimRight(trade_kind);
   StringToLower(trade_kind);
   if (trade_kind != "buy" && trade_kind != "sell")
   {
      ex_invalid_state = true;
      MessageBox(StringConcatenate("Invalid value TradeKind=", TradeKind), "Error input params");
      return;
   }
   
   

   //1
   fl_grids[0].setLotParams(FirstLot1, LotFactor1, LotHedge1);
   fl_grids[0].setOtherParams(CandleStep1, MinOrdersDistance1, ProfitPoints1, 0);
   //2
   fl_grids[1].setLotParams(FirstLot2, LotFactor2, LotHedge2);
   fl_grids[1].setOtherParams(CandleStep2, MinOrdersDistance2, ProfitPoints2, HedgeProfitFactor2);
   //3
   fl_grids[2].setLotParams(FirstLot3, LotFactor3, LotHedge3);
   fl_grids[2].setOtherParams(CandleStep3, MinOrdersDistance3, ProfitPoints3, HedgeProfitFactor3);
   //4   
   fl_grids[3].setLotParams(FirstLot4, LotFactor4, LotHedge4);
   fl_grids[3].setOtherParams(CandleStep4, MinOrdersDistance4, ProfitPoints4, HedgeProfitFactor4);
   //5
   fl_grids[4].setLotParams(FirstLot5, LotFactor5, LotHedge5);
   fl_grids[4].setOtherParams(CandleStep5, MinOrdersDistance5, ProfitPoints5, HedgeProfitFactor5);
   //6   
   fl_grids[5].setLotParams(FirstLot6, LotFactor6, LotHedge6);
   fl_grids[5].setOtherParams(CandleStep6, MinOrdersDistance6, ProfitPoints6, HedgeProfitFactor6);
   //7
   fl_grids[6].setLotParams(FirstLot7, LotFactor7, LotHedge7);
   fl_grids[6].setOtherParams(CandleStep7, MinOrdersDistance7, ProfitPoints7, HedgeProfitFactor7);
   //8   
   fl_grids[7].setLotParams(FirstLot8, LotFactor8, LotHedge8);
   fl_grids[7].setOtherParams(CandleStep8, MinOrdersDistance8, ProfitPoints8, HedgeProfitFactor8);
   //9
   fl_grids[8].setLotParams(FirstLot9, LotFactor9, LotHedge9);
   fl_grids[8].setOtherParams(CandleStep9, MinOrdersDistance9, ProfitPoints9, HedgeProfitFactor9);
   //10   
   fl_grids[9].setLotParams(FirstLot10, LotFactor10, LotHedge10);
   fl_grids[9].setOtherParams(CandleStep10, MinOrdersDistance10, ProfitPoints10, HedgeProfitFactor10);
   
   //lp_moment.reset();

   for (int i=0; i<GRID_COUNT; i++)
   {
      fl_grids[i].setNumber(i+1);
      fl_grids[i].setTradeKind((trade_kind == "buy") ? OP_BUY : OP_SELL);
      fl_grids[i].setMagic(ex_magic);
      fl_grids[i].setUpwardMetod(RepaymentLossUpward);
      //fl_grids[i].setProfitMomentObject(&lp_moment);
      
      if (i > 0) fl_grids[i-1].setHedgeFactor(fl_grids[i].hedgeFactor());
      
      if (fl_grids[i].invalid())
      {
         ex_invalid_state = true;
         Print("grid ", fl_grids[i].number(), " is invalid!");
      }      
   }
}



//other panels
/*
void updateProfitMomentPanel()
{
   profit_moment_panel.destroy();
   profit_moment_panel.setCorner(pcRightDown);
   profit_moment_panel.setBackgroundColor(clrWhite);
   profit_moment_panel.setCellsTextColor(clrBlack);
   profit_moment_panel.setFontSizes(8, 9);
   profit_moment_panel.setMargin(5);
   profit_moment_panel.setOffset(10, 10);
   
   int cols = 2;
   int rows = lp_moment.panelRowsCount();
   profit_moment_panel.setGridSize(rows, cols);
   
   int width = 300;
   int height = rows*20;
   profit_moment_panel.setSize(width, height);   
   profit_moment_panel.repaint();
   
   ///////////////////////////////////////////////
   
   color text_color = clrDarkBlue;
   int row = 0;
   profit_moment_panel.setCellText(row, 0, "Grid / Orders", text_color);
   profit_moment_panel.setCellText(row, 1, StringConcatenate(lp_moment.grid_number, " / ", lp_moment.lots.count()), text_color);
   row++;

   
   double lot = 0;
   double profit = 0;
   const LIntList *list = lp_moment.lots.keys();
   for (int i=0; i<list.count(); i++)
   {
      int ticket = list.at(i);
      profit_moment_panel.setCellText(row, 0, StringConcatenate("order ", i+1), text_color);
      lot = LFLGrid::normalizeValue(lp_moment.lots.value(ticket), 2);
      profit = LFLGrid::normalizeValue(lp_moment.profits.value(ticket), 3);
      profit_moment_panel.setCellText(row, 1, StringConcatenate("lot=", lot, "  profit=", profit), text_color);
      row++;      
   }
   
   profit_moment_panel.setCellText(row, 0, "TOTAL:", text_color);
   lot = LFLGrid::normalizeValue(lp_moment.gridLots(), 2);
   profit = LFLGrid::normalizeValue(lp_moment.gridProfit(), 3);
   profit_moment_panel.setCellText(row, 1, StringConcatenate("lot=", lot, "  profit=", profit), text_color);
   row++;
   
   ///////////////////////////////////////////////////////////////////
   
   text_color = clrDarkRed;
   const LIntList *list2 = lp_moment.repay_profits.keys();
   for (int i=0; i<list2.count(); i++)
   {
      int ticket = list2.at(i);
      profit_moment_panel.setCellText(row, 0, StringConcatenate("loss order ", ticket), text_color);
      lot = LFLGrid::normalizeValue(lp_moment.repay_lots.value(ticket), 2);
      profit = LFLGrid::normalizeValue(lp_moment.repay_profits.value(ticket), 3);
      profit_moment_panel.setCellText(row, 1, StringConcatenate("lot=", lot, "  profit=", profit), text_color);
      row++;      
   }   
   const LIntList *list3 = lp_moment.hedge_profits.keys();
   for (int i=0; i<list3.count(); i++)
   {
      int ticket = list3.at(i);
      profit_moment_panel.setCellText(row, 0, StringConcatenate("hedge order ", ticket), text_color);
      profit = LFLGrid::normalizeValue(lp_moment.hedge_profits.value(ticket), 3);
      profit_moment_panel.setCellText(row, 1, StringConcatenate("profit=", profit), text_color);
      row++;      
   }      

   profit_moment_panel.setCellText(row, 0, "TOTAL:", text_color);
   lot = LFLGrid::normalizeValue(lp_moment.hedgeLots(), 2);
   profit = LFLGrid::normalizeValue(lp_moment.hedgeProfit(), 3);
   profit_moment_panel.setCellText(row, 1, StringConcatenate("lot=", lot, "  profit=", profit), text_color);
   row++;
   
}
void updateProfitMoment()
{
   const LIntList *list = lp_moment.lots.keys();
   for (int i=0; i<list.count(); i++)
   {
      int ticket = list.at(i);
      if (OrderSelect(ticket, SELECT_BY_TICKET))
      {
         double p = OrderProfit() + OrderSwap() + OrderCommission();
         lp_moment.profits.insert(ticket, p);
      }
   }
   
   const LIntList *list2 = lp_moment.repay_profits.keys();
   for (int i=0; i<list2.count(); i++)
   {
      int ticket = list2.at(i);
      if (OrderSelect(ticket, SELECT_BY_TICKET))
      {
         double p = OrderProfit() + OrderSwap() + OrderCommission();
         lp_moment.repay_profits.insert(ticket, p);
      }
   }
   
   const LIntList *list3 = lp_moment.hedge_profits.keys();
   for (int i=0; i<list3.count(); i++)
   {
      int ticket = list3.at(i);
      if (OrderSelect(ticket, SELECT_BY_TICKET))
      {
         double p = OrderProfit() + OrderSwap() + OrderCommission();
         lp_moment.hedge_profits.insert(ticket, p);
      }
   }
   
   updateProfitMomentPanel();
}
*/
void initTradeTypePanel()
{
   trade_type_panel.setCorner(pcLeftDown);
   trade_type_panel.setMargin(5);
   trade_type_panel.setBackgroundColor(clrWhite);
   trade_type_panel.setCellsTextColor(clrBlack);
   trade_type_panel.setFontSizes(14, 9);
   trade_type_panel.setSize(70, 40);
   trade_type_panel.setOffset(20, 20);
}
void startTradeTypePanel(int type)
{
   if (ex_invalid_state) return;   
   
   trade_type_panel.repaint();
   string text = "???";
   color type_color = clrOrange;
   switch (type)
   {
      case OP_BUY: {text = " BUY"; type_color = clrGreen; break;}
      case OP_SELL: {text = "SELL"; type_color = clrRed; break;}
      default: break;
   
   }
   trade_type_panel.setCellText(0, 0, text, type_color);
}
void hideTradeTypePanel()
{
   trade_type_panel.destroy();
}


