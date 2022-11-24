//+------------------------------------------------------------------+
//|                                             open_pos_monitor.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//советник не торгует.
//советник мониторит текущие открытые позы 
//и выводит информацию о них на графическую панель на графике.

#include <mylib/common/ldatetime.mqh>
#include <mylib/common/lgridpanel.mqh>
#include <mylib/trade/ltradeinfo.mqh>


#define MAIN_TIMER_INTERVAL      55
#define EX_NAME                  "pos_monit" 

input color PB_COLOR = 0xDDDDEE;  //Background color of panel


LGridPanel *m_panel = NULL; //объект для отображения панели
LOpenedOrdersInfo m_ordersInfo;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{   
   m_ordersInfo.reset();
   initPanel();
   EventSetTimer(MAIN_TIMER_INTERVAL);   
   Print("--------------- expert started ------------------------");
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   deinitPanel();
   EventKillTimer();
}
void OnTimer()
{
   mainExec();
   //EventKillTimer();
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void mainExec()
{
   Print(EX_NAME, ":  exec timer!!", "   panel_rows=", m_panel.rowCount(), "  heght=", panelHeight());
   LStaticTradeInfo::getOpenedOrdersInfo(m_ordersInfo);
   
   if (m_panel.rowCount() != rowCount())
      initPanel();
            
   updatePanelCells();
}
void deinitPanel()
{
   if (m_panel) 
   {
      delete m_panel; 
      m_panel = NULL;
   }
}
int rowCount()
{
   return m_ordersInfo.opened_couples.count() + 1;
}
int panelHeight()
{
   return rowCount()*16 + m_panel.headerSeparatorHeight() + 20;
}
void initPanel()
{
   deinitPanel();
   
   string p_name = EX_NAME+"_panel";
   m_panel = new LGridPanel(p_name, rowCount(), 7);
   m_panel.setCorner(PlacedCorner::pcLeftUp);
   m_panel.setOffset(20, 20);
   m_panel.setBackgroundColor(PB_COLOR);
   m_panel.setSize(400, panelHeight());
   m_panel.setFontSizes(8, -1);
   m_panel.setMargin(4);
   m_panel.repaint();
   
   fillPanelHeader();
   Print("INIT OBJECT: ", m_panel.panelName());
}
void fillPanelHeader()
{
   if (!m_panel) return;
   
   int col = 0;
   color ht_color = clrSienna;
   m_panel.setHeaderText(col, "Couple", ht_color); col++;
   m_panel.setHeaderText(col, "Lots", ht_color); col++;
   m_panel.setHeaderText(col, "N pos", ht_color); col++;
   m_panel.setHeaderText(col, "Commis", ht_color); col++;
   m_panel.setHeaderText(col, "Swap", ht_color); col++;
   m_panel.setHeaderText(col, "Profit", ht_color); col++;
   m_panel.setHeaderText(col, "Result", ht_color); col++;
}
void updatePanelCells()
{
   int n = rowCount() - 1;   
   m_panel.setCellText(n, 0, "Total", clrDarkGreen);   
   for (int i=0; i<n; i++)
      m_panel.setCellText(i, 0, m_ordersInfo.opened_couples.at(i), clrNavy);      
      
   int n_cfd = rowCount() - 1;
   int n_tickets = m_ordersInfo.opened_tickets.count();   
   updateLots(n_cfd, n_tickets);        
   updatePosNumber(n_cfd, n_tickets);
   updateCommissions(n_cfd, n_tickets);        
   updateSwaps(n_cfd, n_tickets);
   updateProfits(n_cfd, n_tickets);
   
}

//calc lots
void updateLots(int n_cfd, int n_tickets)
{
   double sum_total = 0;
   for (int i=0; i<n_cfd; i++)
   {
      double couple_lots = 0;
      for (int j=0; j<n_tickets; j++)
      {
         if (OrderSelect(m_ordersInfo.opened_tickets.at(j), SELECT_BY_TICKET, MODE_TRADES))
         {
            if (m_ordersInfo.opened_couples.at(i) == OrderSymbol()) 
               couple_lots += OrderLots();
         }
         else {couple_lots = -9999; break;}                     
      }
      
      if (couple_lots > 0) sum_total += couple_lots;
      m_panel.setCellText(i, 1, DoubleToStr(couple_lots, 2), clrNavy);            
   }
   m_panel.setCellText(n_cfd, 1, DoubleToStr(sum_total, 2), clrDarkGreen);            
}
//calc number
void updatePosNumber(int n_cfd, int n_tickets)
{
   for (int i=0; i<n_cfd; i++)
   {
      int n = 0;
      for (int j=0; j<n_tickets; j++)
      {
         if (OrderSelect(m_ordersInfo.opened_tickets.at(j), SELECT_BY_TICKET, MODE_TRADES))
         {
            if (m_ordersInfo.opened_couples.at(i) == OrderSymbol()) n++;
         }
         else {n = -9999; break;}                     
      }
      m_panel.setCellText(i, 2, IntegerToString(n), clrNavy);               
   }
   m_panel.setCellText(n_cfd, 2, IntegerToString(n_tickets), clrDarkGreen);            
}
//calc commissions
void updateCommissions(int n_cfd, int n_tickets)
{
   double sum_total = 0;
   for (int i=0; i<n_cfd; i++)
   {
      double couple_sum = 0;
      for (int j=0; j<n_tickets; j++)
      {
         if (OrderSelect(m_ordersInfo.opened_tickets.at(j), SELECT_BY_TICKET, MODE_TRADES))
         {
            if (m_ordersInfo.opened_couples.at(i) == OrderSymbol()) 
               couple_sum += OrderCommission();
         }
         else {couple_sum = -9999; break;}                     
      }
      
      sum_total += couple_sum;
      m_panel.setCellText(i, 3, DoubleToStr(couple_sum, 2), clrNavy);            
   }
   m_panel.setCellText(n_cfd, 3, DoubleToStr(sum_total, 2), clrDarkGreen);            
}
//calc swaps
void updateSwaps(int n_cfd, int n_tickets)
{
   double sum_total = 0;
   for (int i=0; i<n_cfd; i++)
   {
      double couple_sum = 0;
      for (int j=0; j<n_tickets; j++)
      {
         if (OrderSelect(m_ordersInfo.opened_tickets.at(j), SELECT_BY_TICKET, MODE_TRADES))
         {
            if (m_ordersInfo.opened_couples.at(i) == OrderSymbol()) 
               couple_sum += OrderSwap();
         }
         else {couple_sum = -9999; break;}                     
      }
      
      sum_total += couple_sum;
      m_panel.setCellText(i, 4, DoubleToStr(couple_sum, 2), clrNavy);            
   }
   m_panel.setCellText(n_cfd, 4, DoubleToStr(sum_total, 2), clrDarkGreen);            
}
//calc profits
void updateProfits(int n_cfd, int n_tickets)
{
   double result_total = 0;
   double sum_total = 0;
   for (int i=0; i<n_cfd; i++)
   {
      double couple_sum = 0;
      double couple_res = 0;
      for (int j=0; j<n_tickets; j++)
      {
         if (OrderSelect(m_ordersInfo.opened_tickets.at(j), SELECT_BY_TICKET, MODE_TRADES))
         {
            if (m_ordersInfo.opened_couples.at(i) == OrderSymbol()) 
            {
               couple_sum += OrderProfit();
               couple_res += (OrderCommission() + OrderSwap());
            }
         }
         else {couple_sum = -9999; couple_res = 0; break;}                     
      }
      
      if (couple_sum != -9999) 
      {
         sum_total += couple_sum;
         couple_res += couple_sum;
         result_total += couple_res;
      }
      m_panel.setCellText(i, 5, DoubleToStr(couple_sum, 1), (couple_sum < 0) ? 0x0000DD : clrNavy);            
      m_panel.setCellText(i, 6, DoubleToStr(couple_res, 1), (couple_res < 0) ? 0x0000DD : clrNavy);            
   }
   m_panel.setCellText(n_cfd, 5, DoubleToStr(sum_total, 1), clrDarkGreen);            
   m_panel.setCellText(n_cfd, 6, DoubleToStr(result_total, 1), clrDarkGreen);            
}



