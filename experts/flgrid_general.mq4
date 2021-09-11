//+------------------------------------------------------------------+
//|                                               flgrid_general.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#include <fllib/flgridobject.mqh>
#include <fllib1/flgridobject.mqh>
#include <fllib1/flgridgeneralobject.mqh>
#include <fllib1/flgridexchange.mqh>

input double StartClosingMinus = 50.0;       //Start closing minus
input double PercentageClose = 80.0;         //Percentage of Close


#define MAIN_TIMER_INTERVAL      3

FLGridGeneral general_object;
FLGridExchanger m_exchanger;
LGridPanel general_panel("generalpanel", 1, 1, true);


//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //reinitGeneralPanel();
   repaintGeneralPanel();
   EventSetTimer(MAIN_TIMER_INTERVAL);
   
   Print("Expert FL_GRID_GENERAL started!");      
   
   m_exchanger.setKey("general");
   m_exchanger.setOwnChartID(ChartID());
   m_exchanger.emitStarted();
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   //m_exchanger.emitDestroy();
   //sleep(500);
   EventKillTimer();
   general_panel.destroy();
}
void OnTimer()
{
   //Print("FLGrid general executing"); 
   
   int old_rows = general_object.recordsCount();
   bool need_panel_repaint = false;
   readExchamgerNewMessages(need_panel_repaint);
   
   if (need_panel_repaint) //если появилось что-то новое, обновить панель
   {
      if (old_rows == general_object.recordsCount()) updateGeneralPanelData(); 
      else repaintGeneralPanel(); 
   }
   else checkCmdGeneralObject(); //проверить необходимость отправить команду на погашение долга
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (sparam == "general") return;
   if (id < CHARTEVENT_CUSTOM) return;

   m_exchanger.receiveMsg(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void checkCmdGeneralObject()
{
   int pos = general_object.findHedgeLossOver(StartClosingMinus); //найти долг превышающий StartClosingMinus
   if (pos < 0)
   {
      //если большого долга нет ищем местные долги
      checkStandartRepay();
      return;
   }
   
   FLGridCoupleGeneralState rec;
   general_object.getRecord(pos, rec);
   double need_repay = rec.current_pl*PercentageClose/100;
   
   long chart_id = 0;
   double loss = 0;
   general_object.findChartForRepaing(rec.couple, chart_id, loss);
   if (chart_id <= 0 || loss >= 0) return;
   
   if (MathAbs(loss) < MathAbs(need_repay)) need_repay = loss;
   need_repay = general_object.profitByLoss(need_repay);
   
   Print("send over max repay command  chart_id=",chart_id, "  sum=", need_repay);
   m_exchanger.sendRepayCommand(chart_id, need_repay);
   general_object.repayDone(chart_id, need_repay);
}
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
   general_object.repayStandardDone(chart_id, profit);
   
}
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
            general_object.expertDestroyed(msg.str_value);
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
            Print("expertCurPLOpenedGrid message");
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
   Print("repaintGeneralPanel()");
   
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
   
   Print("updateGeneralPanelData()");

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
