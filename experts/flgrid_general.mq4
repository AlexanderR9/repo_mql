//+------------------------------------------------------------------+
//|                                               flgrid_general.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <fllib1/flgridobject.mqh>
#include <fllib1/flgridgeneralobject.mqh>
#include <fllib1/flgridexchange.mqh>

input double StartClosingMinus = 10.0;       //Start closing minus
input double PercentageClose = 80.0;         //Percentage of Close


#define MAIN_TIMER_INTERVAL      3

FLGridGeneral general_object;
LGridPanel general_panel("generalpanel", 1, 1, true);
int m_pause = 0;


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
      if (need_emit_destroy)
         m_exchanger.emitDestroy();
      delete m_exchanger;
      m_exchanger = NULL;
   }
}
////////////////EXCHANGER////////////////////////////



//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   repaintGeneralPanel();
   EventSetTimer(MAIN_TIMER_INTERVAL);
   
   Print("Expert FL_GRID_GENERAL started!");      
   initExchanger("general");
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   Print("OnDeinit():  reason=",reason);
   EventKillTimer();
   general_panel.destroy();
   deinitExchanger(false);
}
void OnTimer()
{
   //Print("FLGrid general executing"); 
   
   int old_rows = general_object.recordsCount();
   bool need_panel_repaint = false;
   readExchamgerNewMessages(need_panel_repaint);
   //general_object.outLossStat();
   //general_object.outData();
   
   if (need_panel_repaint) //если появилось что-то новое, обновить панель
   {
      if (old_rows == general_object.recordsCount()) updateGeneralPanelData(); 
      else repaintGeneralPanel(); 
   }
   
   
   if (m_pause > 0) {m_pause--; return;}
   checkCmdGeneralObject(); //проверить необходимость отправить команду на погашение долга
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (!m_exchanger) return;
   if (sparam == m_exchanger.key()) return;
   if (id < CHARTEVENT_CUSTOM) return;

   m_exchanger.receiveMsg(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void checkCmdGeneralObject()
{
   int pos = general_object.findCurrentLossOver(StartClosingMinus); //найти номер записи, долг которой превышает StartClosingMinus, и больше всех остальных
   if (pos < 0) return;
   
   FLGridCoupleGeneralState rec;
   general_object.getRecord(pos, rec);
   double need_repay = rec.current_pl*PercentageClose/100; //сумма на которую надо погасить долг (отрицательное значение)
   //Print("Find debt=", rec.current_pl, "   thisover: ", StartClosingMinus, "   need repay sum: ", DoubleToStr(need_repay, 2));
   if (general_object.freeProfitSize() < MathAbs(need_repay)) 
   {
      //закрытый профит меньше суммы на которую надо погасить долг
      Print("WARNING: free_profit=", DoubleToStr(general_object.freeProfitSize(), 2), ", need_repay  ", need_repay); 
      return;
   }
   
   
   long chart_id = 0;
   double loss = 0;
   general_object.findChartForRepaing(rec.couple, chart_id, loss); //поиск графика с наибольшим убытком с хеджированными сетками
   if (chart_id <= 0 || loss >= 0)
   {
      //хеджированных сеток нет, гасим убыточные ордера открытой сетки
      closeOrdersOpenedGrid(rec, need_repay);
      /*
      general_object.findChartForRepaingOpenedGrid(rec.couple, chart_id, loss); //поиск графика с наибольшим убытком с открытой сеткой
      if (chart_id <= 0 || loss >= 0) return;
      
      if (MathAbs(loss) < MathAbs(need_repay)) need_repay = loss;
      need_repay = general_object.profitByLoss(need_repay);
      Print("send repay opened command  chart_id=",chart_id, "  sum=", need_repay);
      m_exchanger.sendRepayOpenedCommand(chart_id, need_repay);
      general_object.repayOpenedDone(chart_id, need_repay);
      */
      return;
   }
   
   if (MathAbs(loss) < MathAbs(need_repay)) need_repay = loss;
   need_repay = general_object.profitByLoss(need_repay);
   
   Print("send over max repay command  chart_id=",chart_id, "  sum=", need_repay);
   m_exchanger.sendRepayCommand(chart_id, need_repay); m_pause = 3;
   general_object.repayDone(chart_id, need_repay);
}
void closeOrdersOpenedGrid(const FLGridCoupleGeneralState &rec, double need_repay_loss)
{
   long chart_id = 0;
   double loss = 0;
   general_object.findChartForRepaingOpenedGrid(rec.couple, chart_id, loss); //поиск графика c инструментом rec.couple с наибольшим убытком в открытой сетке
   if (chart_id <= 0 || loss >= 0) return;
      
   if (MathAbs(loss) < MathAbs(need_repay_loss)) need_repay_loss = loss;
   
   //нормализация суммы погашения, need_repay_loss > 0 and need_repay_loss <= free_profit
   need_repay_loss = general_object.profitByLoss(need_repay_loss);
   //need_repay_loss = MathAbs(need_repay_loss);
   
   //отправить команду советнику chart_id: 
   //закрыть убыточные ордера на сумму не более чем need_repay_loss
   Print("send repay [opened grid] command,  chart_id=",chart_id, "  sum=", need_repay_loss);
   m_exchanger.sendRepayOpenedCommand(chart_id, need_repay_loss);  m_pause = 3;
   //general_object.repayOpenedDone(chart_id, need_repay_loss);
}
/*
void checkStandartRepay()
{
   long chart_id = -1;
   double profit = 0;
   double loss = 0;
   general_object.findDataForLastRepay(chart_id, profit, loss);
   if (chart_id <= 0 || profit <= 0 || loss >= 0) return;
   
   if (MathAbs(loss) < profit) profit = MathAbs(loss);
   Print("send standart repay command  chart_id=",chart_id, "  sum=", profit);
   m_exchanger.sendRepayCommand(chart_id, profit);
   general_object.repayStandardDone(chart_id, profit); m_pause = 3;
}
*/
void readExchamgerNewMessages(bool &need_panel_repaint)
{
   int n = m_exchanger.msgCount();
  // Print("Exchanger records: ", n);  
   if (n == 0) return;
   
   for (int i=0; i<n; i++)
   {
      if (m_exchanger.isRecReaded(i)) continue;
   
      FLGridExchangeMsg msg;
      m_exchanger.getRecord(i, msg);
      analizeExchamgerMessage(msg);
      need_panel_repaint = true;
   }   
}
void analizeExchamgerMessage(const FLGridExchangeMsg &msg)
{
      switch (msg.message_type)
      {
         case ExchangeMsgType::emtStart:
         {
            Print("expertStarted message");
            general_object.expertStarted(msg.str_value);
            break;
         }
         case ExchangeMsgType::emtDestroy:
         {
            Print("expertDestroyed message");
            general_object.expertDestroyed(msg.str_value, msg.i_value);
            break;
         }
         case ExchangeMsgType::emtOpenedPos:
         {
            Print("emtOpenedPos message");
            general_object.expertOpenedPos(msg.str_value, msg.d_value);
            break;
         }
         case ExchangeMsgType::emtGettedProfit:
         {
            Print("emtGettedProfit message");
            general_object.expertGetedProfit(msg.str_value, msg.d_value, msg.i_value);
            break;
         }
         case ExchangeMsgType::emtHedgeGrid:
         {
            Print("emtHedgeGrid message");
            general_object.expertHedgeGrid(msg.str_value, msg.d_value, msg.i_value);
            break;
         }
         case ExchangeMsgType::emtCurPLOpenedGrid: 
         {
            //Print("expertCurPLOpenedGrid message");
            general_object.expertCurPLOpenedGrid(msg.str_value, msg.d_value, msg.i_value);
            break;
         }
         default: 
         {
            Print("analizeExchamgerMessage() WARNING: invalid msg type: ", msg.message_type);
            return;
         }
      } 
}
void repaintGeneralPanel()
{
   //Print("repaintGeneralPanel()");
   
   reinitGeneralPanel();
   general_panel.repaint();
   
   general_panel.setHeaderText(0, "Symbol");
   general_panel.setHeaderText(1, "Current P/L");
   general_panel.setHeaderText(2, "Total lots");
   general_panel.setHeaderText(3, "Closed profit");
   general_panel.setHeaderText(4, "Expert started");
      
   updateGeneralPanelData();
}
void updateGeneralPanelData()
{
   if (general_object.isEmpty()) return;
   
  // Print("updateGeneralPanelData()");

   double sum_pl = 0;
   double sum_lot = 0;
   double sum_closed = 0;
   int sum_count = 0;
   
   int n = general_object.recordsCount();
   int prec = 2;
   for (int i=0; i<n; i++)
   {
      FLGridCoupleGeneralState rec;
      general_object.getRecord(i, rec);
            
      setCellPanel(i, 0, rec.couple, clrSaddleBrown, false); 
      setCellPanel(i, 1, DoubleToStr(rec.current_pl, prec));            sum_pl += rec.current_pl;
      setCellPanel(i, 2, DoubleToStr(rec.total_lot, prec));             sum_lot += rec.total_lot;
      setCellPanel(i, 3, DoubleToStr(rec.closed_profit, prec));         sum_closed += rec.closed_profit;
      setCellPanel(i, 4, IntegerToString(rec.ex_count));                sum_count += rec.ex_count;
   }
   
   setCellPanel(n, 0, "Total:", clrSeaGreen, false); 
   setCellPanel(n, 1, DoubleToStr(sum_pl, prec)); 
   setCellPanel(n, 2, DoubleToStr(sum_lot, prec)); 
   setCellPanel(n, 3, DoubleToStr(sum_closed, prec)); 
   setCellPanel(n, 4, IntegerToString(sum_count)); 
}
void setCellPanel(int i, int j, string text, color c = clrBlack, bool with_space = true)
{
   string space = "    ";
   string s = with_space ? StringConcatenate(space, text) : text;
   general_panel.setCellText(i, j, s, c); 
}
//инициализация объекта для вывода графической панели
void reinitGeneralPanel()
{
   general_panel.destroy();
   if (general_panel.invalid()) return;
   
   general_panel.setCorner(pcLeftUp);
   general_panel.setMargin(4);
   general_panel.setOffset(20, 20);
   //general_panel.setBackgroundColor(clrLightGray);
   general_panel.setBackgroundColor(0xfefefe);
   general_panel.setHeaderTextColor(clrSeaGreen);
   general_panel.setHeaderSeparatorParams(clrBlack, 2);
   general_panel.setCellsTextColor(clrBlack);
   general_panel.setFontSizes(8, 10);

   int cols = 5;
   int rows = general_object.recordsCount() + 1;
   general_panel.setGridSize(rows, cols);
   
   int row_height = 20;   
   int h = row_height*(rows + 2) + 8;
   int w = 600;
   general_panel.setSize(w, h);
   
}
