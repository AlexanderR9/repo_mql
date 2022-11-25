//+------------------------------------------------------------------+
//|                                              history_monitor.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//советник не торгует.
//советник мониторит историю совершенных сделок и прочих событий начиная с указанной даты, 
//и выводит информацию о них на графическую панель на графике.


#include <mylib/common/ldatetime.mqh>
#include <mylib/common/lgridpanel.mqh>
#include <mylib/trade/ltradeinfo.mqh>
#include <mylib/trade/lhistoryinfo.mqh>
#include <mylib/common/linputdialogenum.mqh>

#define MAIN_TIMER_INTERVAL      55 //default value
#define EX_NAME                  "history_monit" 
#define PANEL_WIDTH              750

//input params of expert
input datetime START_DATE = datetime("01.11.2022"); //Start date
input color PB_COLOR = 0xEBCE87;  //Background color of panel
input color CT_COLOR = 0xBB8050;  //Text color of cells
input color HT_COLOR = 0x0050DD;  //Text color of header
input color TT_COLOR = 0x30AA30;  //Text color of total row
input IP_SimpleNumber CT_SIZE = ipMTI_Num8;  //Text size of cells
input IP_SimpleNumber HT_SIZE = ipMTI_Num10;  //Text size of header
input IP_SimpleNumber TIMER_INTERVAL = ipMTI_Num15;  //Update timer interval, sec.

LGridPanel *m_panel = NULL; //объект для отображения панели
LHistoryInfo *m_objHistory = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{   
   m_objHistory = new LHistoryInfo();

   //m_ordersInfo.reset();
   initPanel();
   int t = IP_ConvertClass::fromSimpleNumber(TIMER_INTERVAL);
   if (t < 10) t = TIMER_INTERVAL;
   EventSetTimer(t);   
   Print("--------------- expert started ------------------------");
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   deinitPanel();
   if (m_objHistory) {delete m_objHistory; m_objHistory = NULL;}
   EventKillTimer();
}
void OnTimer()
{
   mainExec();
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void mainExec()
{
   Print(EX_NAME, ":  exec timer!!", "   panel_rows=", m_panel.rowCount(), "  heght=", panelHeight());
   //LStaticTradeInfo::getOpenedOrdersInfo(m_ordersInfo);
   
   
   if (m_objHistory.isEmpty())
   {
      Print("TRY LOAD HISTORY .................");
      m_objHistory.reloadHistory(START_DATE);
      Print("container size: ", m_objHistory.count());
   }
   
   /*
   if (m_panel.rowCount() != rowCount())
      initPanel();
            
   updatePanelCells();
   
   Print("cell_text [", m_panel.getCellText(rowCount()-1, 0), "]");
   */
}
void deinitPanel()
{
   Print("DEINIT PANEL");
   if (m_panel) 
   {
      delete m_panel; 
      m_panel = NULL;
   }
}
int rowCount()
{
   return 5;
   //return m_ordersInfo.opened_couples.count() + 1;
}
int panelHeight()
{
   return rowCount()*16 + m_panel.headerSeparatorHeight() + 20;
}
void initPanel()
{
   deinitPanel();
   
   string p_name = EX_NAME+"_panel";
   m_panel = new LGridPanel(p_name, rowCount(), 10);
   m_panel.setCorner(PlacedCorner::pcLeftUp);
   m_panel.setOffset(20, 20);
   m_panel.setBackgroundColor(PB_COLOR);
   m_panel.setSize(PANEL_WIDTH, panelHeight());
   m_panel.setFontSizes(IP_ConvertClass::fromSimpleNumber(CT_SIZE), IP_ConvertClass::fromSimpleNumber(HT_SIZE));
   m_panel.setMargin(4);
   
   initPanelColumsParams();
   m_panel.repaint();
   
   fillPanelHeader();
   Print("INIT OBJECT: ", m_panel.panelName());
}
void fillPanelHeader()
{
   if (!m_panel) return;
   
   int col = 0;
   color ht_color = HT_COLOR;
   m_panel.setHeaderText(col, "Couple", ht_color); col++;
   m_panel.setHeaderText(col, "Closed lots", ht_color); col++;
   m_panel.setHeaderText(col, "Closed pos", ht_color); col++;
   m_panel.setHeaderText(col, "Canceled", ht_color); col++;
   m_panel.setHeaderText(col, "Swap", ht_color); col++;
   m_panel.setHeaderText(col, "Commision", ht_color); col++;
   m_panel.setHeaderText(col, "Profit", ht_color); col++;
   m_panel.setHeaderText(col, "Loss", ht_color); col++;
   m_panel.setHeaderText(col, "Divs", ht_color); col++;
   m_panel.setHeaderText(col, "Result", ht_color); col++;
}
void initPanelColumsParams()
{

   /*
   LIntList col_sizes;
   col_sizes.append(20);
   col_sizes.append(12);
   col_sizes.append(12);
   col_sizes.append(14);
   col_sizes.append(14);
   col_sizes.append(14);
   col_sizes.append(14);
   m_panel.setColSizes(col_sizes);

   LIntList align_sizes;
   align_sizes.append(4);
   align_sizes.append(1);
   align_sizes.append(4);
   align_sizes.append(1);
   align_sizes.append(1);
   align_sizes.append(0);
   align_sizes.append(0);
   m_panel.setColCellSpaces(align_sizes);
   */
}

