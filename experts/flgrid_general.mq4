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


#define MAIN_TIMER_INTERVAL      10

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
   Print("FLGrid general executing"); 
   
   bool need_panel_repaint = false;
   readExchamgerNewMessages(need_panel_repaint);
   
   if (need_panel_repaint) repaintGeneralPanel(); //если появилось что-то новое, обновить панель
   else checkCmdGeneralObject(); //проверить необходимость отправить команду на погашение долга
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (id < CHARTEVENT_CUSTOM) return;
   m_exchanger.receiveMsg(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void checkCmdGeneralObject()
{
   int pos = general_object.findHedgeLossOver(StartClosingMinus);
   if (pos < 0) return;
   
   FLGridCoupleGeneralState rec;
   general_object.getRecord(pos, rec);
   double need_repay = rec.current_pl*PercentageClose/100;
   
   long chart_id = 0;
   double loss = 0;
   general_object.findChartForRepaing(rec.couple, chart_id, loss);
   if (chart_id <= 0 || loss >= 0) return;
   
   if (MathAbs(loss) < MathAbs(need_repay)) need_repay = loss;
   need_repay = general_object.profitByLoss(need_repay);
   
   Print("send repay command  chart_id=",chart_id, "  sum=", need_repay);
   m_exchanger.sendRepayCommand(chart_id, need_repay);
   general_object.repayDone(chart_id, need_repay);
   
}
void readExchamgerNewMessages(bool &need_panel_repaint)
{
   int n = m_exchanger.msgCount();
   Print("Exchanger records: ", n);  
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
            general_object.expertOpenedPos(msg.str_value, msg.d_value);
            break;
         }
         case ExchangeMsgType::emtHedgeGrid:
         {
            Print("emtHedgeGrid message");
            general_object.expertHedgeGrid(msg.str_value, msg.d_value, msg.i_value);
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
      
      general_panel.setCellText(i, 0, rec.couple, clrDarkOrange);
      general_panel.setCellText(i, 1, DoubleToStr(rec.current_pl, prec), clrBlack);       sum_pl += rec.current_pl;
      general_panel.setCellText(i, 2, DoubleToStr(rec.total_lot, prec), clrBlack);        sum_lot += rec.total_lot;
      general_panel.setCellText(i, 3, DoubleToStr(rec.closed_profit, prec), clrBlack);    sum_closed += rec.closed_profit;
      general_panel.setCellText(i, 4, IntegerToString(rec.ex_count), clrBlack);           sum_count += rec.ex_count;
   }
   
   general_panel.setCellText(n, 0, "Total:", clrBlack);
   general_panel.setCellText(n, 1, DoubleToStr(sum_pl, prec), clrBlack);
   general_panel.setCellText(n, 2, DoubleToStr(sum_lot, prec), clrBlack);
   general_panel.setCellText(n, 3, DoubleToStr(sum_closed, prec), clrBlack);
   general_panel.setCellText(n, 4, IntegerToString(sum_count), clrBlack);
   
}
//инициализация объекта для вывода графической панели
void reinitGeneralPanel()
{
   if (general_panel.invalid()) return;
   
   general_panel.setCorner(pcLeftUp);
   general_panel.setMargin(5);
   general_panel.setOffset(30, 40);
   general_panel.setBackgroundColor(clrLightGray);
   general_panel.setHeaderTextColor(clrSeaGreen);
   general_panel.setHeaderSeparatorParams(clrBlack, 2);
   general_panel.setCellsTextColor(clrBlack);
   general_panel.setFontSizes(8, 10);

   int cols = 5;
   int rows = general_object.recordsCount() + 1;
   general_panel.setGridSize(rows, cols);
   
   int row_height = 20;   
   int h = row_height*(rows + 1) + 8;
   int w = 400;
   general_panel.setSize(w, h);
   
}
