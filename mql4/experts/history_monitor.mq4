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
#include <mylib/common/lfile.mqh>
#include <mylib/common/lgridpanel.mqh>
#include <mylib/trade/ltradeinfo.mqh>
#include <mylib/trade/lhistoryinfo.mqh>
#include <mylib/common/linputdialogenum.mqh>

#define MAIN_TIMER_INTERVAL      55 //default value
#define EX_NAME                  "history_monit" 
#define PANEL_WIDTH              640
#define PANEL_COLUMNS            9
#define PANEL2_WIDTH             180
#define PANEL2_COLUMNS           3
#define PANEL2_ROWS              5
#define CORNER_OFFSET            15
#define ROW_HEIGHT               15


//input params of expert
input datetime START_DATE = datetime("15.11.2022"); //Start date
input color PB_COLOR = 0xF0FFFF;  //Background color of panel
input color CT_COLOR = 0xBB8050;  //Text color of cells
input color HT_COLOR = 0x0050DD;  //Text color of header
input color TT_COLOR = 0x30AA30;  //Text color of total row
input IP_SimpleNumber CT_SIZE = ipMTI_Num8;  //Text size of cells
input IP_SimpleNumber HT_SIZE = ipMTI_Num10;  //Text size of header
input IP_SimpleNumber TIMER_INTERVAL = ipMTI_Num11;  //Update timer interval, sec.

LGridPanel *m_panel = NULL; //объект для отображения панели (основная)
LGridPanel *m_panel2 = NULL; //объект для отображения панели (краткая)
LHistoryInfo *m_objHistory = NULL;
int m_curRows = -1; 
int exec_counter = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{   
   m_objHistory = new LHistoryInfo();
   reinitPanel();
   initPanel2();
   
   exec_counter = 0;
   
   int t = IP_ConvertClass::fromSimpleNumber(TIMER_INTERVAL);
   if (t < 5) t = TIMER_INTERVAL;
   EventSetTimer(t);   
   Print("--------------- expert started ------------------------");
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   deinitPanel(m_panel);
   deinitPanel(m_panel2);
   if (m_objHistory) {delete m_objHistory; m_objHistory = NULL;}
   EventKillTimer();
}
void OnTimer()
{
   mainExec();
   exec_counter++;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void mainExec()
{
   Print(EX_NAME, ":  exec timer!!", "   panel_rows=", m_panel.rowCount(), "  heght=", panelHeight());
   
   reloadHistoryData();   
   updateRowCount();   
   updatePanel2Cells();
   
   if (exec_counter % 10 == 1) saveToFile();
}
void reloadHistoryData()
{
      Print("TRY LOAD HISTORY .................");
      m_objHistory.reloadHistory(START_DATE);
      Print("container size: ", m_objHistory.count());
      if (m_objHistory.isEmpty())
      {
         Print("WARNING: was loaded empty history!!!");
         return;
      }
      
      //printRecords();
}
void printRecords() //debug info
{
      int n = m_objHistory.count();
      for (int i=0; i<n; i++)      
      {
         LHistoryEvent rec;
         m_objHistory.getRecAt(i, rec);         
         Print(rec.toStr());
      }    
      
      Print("divs count: ", m_objHistory.countByType(hotDiv));
      Print("rollover count: ", m_objHistory.countByType(hotRollover));
      Print("closed count: ", m_objHistory.countByType(hotClosed));
      Print("rebate count: ", m_objHistory.countByType(hotRebate));             
}
void updateRowCount()
{
     LStringList list;
     m_objHistory.getCoupleList(list);
     m_curRows = list.count();
     Print("m_curRows = ", m_curRows);
     if (rowCount() != m_panel.rowCount()) 
         reinitPanel();
      
     updatePanelCells(list);      
     updateTotalRow();
}
void deinitPanel(LGridPanel *p)
{
   Print("DEINIT PANEL");
   if (p) 
   {
      delete p; 
      p = NULL;
   }
}
int rowCount()
{
   if (m_curRows <= 0) return 1;
   return (m_curRows + 1);
}
int panelHeight()
{
   return (rowCount()*ROW_HEIGHT + m_panel.headerSeparatorHeight() + int(ROW_HEIGHT*1.2));
}
void reinitPanel()
{
   deinitPanel(m_panel);
   
   string p_name = EX_NAME+"_panel_main";
   m_panel = new LGridPanel(p_name, rowCount(), PANEL_COLUMNS);
   m_panel.setCorner(PlacedCorner::pcLeftUp);
   m_panel.setOffset(CORNER_OFFSET, CORNER_OFFSET);
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
   m_panel.setHeaderText(col, "Closed/Canceled", ht_color); col++;
   m_panel.setHeaderText(col, "Swap", ht_color); col++;
   m_panel.setHeaderText(col, "Commision", ht_color); col++;
   m_panel.setHeaderText(col, "Profit", ht_color); col++;
   m_panel.setHeaderText(col, "Loss", ht_color); col++;
   m_panel.setHeaderText(col, "Divs", ht_color); col++;
   m_panel.setHeaderText(col, "Result", ht_color); col++;
}

//PANEL 2
void initPanel2()
{
   deinitPanel(m_panel2);
   
   //init panel2
   string p_name = EX_NAME+"_panel_other";
   m_panel2 = new LGridPanel(p_name, PANEL2_ROWS, PANEL2_COLUMNS);
   m_panel2.setCorner(PlacedCorner::pcLeftUp);
   m_panel2.setOffset(CORNER_OFFSET+PANEL_WIDTH+10, CORNER_OFFSET);
   m_panel2.setBackgroundColor(PB_COLOR);
   m_panel2.setSize(PANEL2_WIDTH, (PANEL2_ROWS+1)*ROW_HEIGHT + ROW_HEIGHT*2);
   m_panel2.setFontSizes(IP_ConvertClass::fromSimpleNumber(CT_SIZE), IP_ConvertClass::fromSimpleNumber(HT_SIZE));
   m_panel2.setMargin(4);
   
   LIntList col_sizes;
   col_sizes.append(44);
   col_sizes.append(28);
   col_sizes.append(28);
   m_panel2.setColSizes(col_sizes);
   LIntList align_sizes;
   align_sizes.append(3);
   align_sizes.append(2);
   align_sizes.append(0);
   m_panel2.setColCellSpaces(align_sizes);
   

   m_panel2.repaint();
   
   //fill headers
   m_panel2.setHeaderText(0, "Event type", HT_COLOR);
   m_panel2.setHeaderText(1, "Count", HT_COLOR);
   m_panel2.setHeaderText(2, "Size", HT_COLOR);

   m_panel2.setCellText(0, 0, "Depo", clrDarkBlue);
   m_panel2.setCellText(1, 0, "Rebate", clrDarkBlue);
   m_panel2.setCellText(2, 0, "Rollover", clrDarkBlue);
   m_panel2.setCellText(3, 0, "Divs", clrDarkBlue);
   m_panel2.setCellText(4, 0, "N (all)", clrDarkBlue);
   
   Print("INIT OBJECT: ", m_panel2.panelName());   
}
void updatePanel2Cells()
{
   m_panel2.setCellText(0, 1, IntegerToString(m_objHistory.countByType(hotDeposit)), CT_COLOR);
   m_panel2.setCellText(1, 1, IntegerToString(m_objHistory.countByType(hotRebate)), CT_COLOR);
   m_panel2.setCellText(2, 1, IntegerToString(m_objHistory.countByType(hotRollover)), CT_COLOR);
   m_panel2.setCellText(3, 1, IntegerToString(m_objHistory.countByType(hotDiv)), CT_COLOR);
   m_panel2.setCellText(4, 1, IntegerToString(m_objHistory.count()), CT_COLOR);

   m_panel2.setCellText(0, 2, DoubleToStr(m_objHistory.amountProfitByType(hotDeposit), 0), CT_COLOR);
   m_panel2.setCellText(1, 2, DoubleToStr(m_objHistory.amountProfitByType(hotRebate), 2), CT_COLOR);
   m_panel2.setCellText(2, 2, DoubleToStr(m_objHistory.amountProfitByType(hotRollover), 2), CT_COLOR);
   m_panel2.setCellText(3, 2, DoubleToStr(m_objHistory.amountProfitByType(hotDiv), 1), CT_COLOR);
   m_panel2.setCellText(4, 2, "---", CT_COLOR);


}

void updateTotalRow()
{
   int n = rowCount() - 1;
   for (int col=1; col<PANEL_COLUMNS; col++)
   {
      double sum = 0;
      int closed = 0;
      int canceled = 0;
      for (int row=0; row<n; row++)
      {
         string text = m_panel.getCellText(row, col);
         switch (col)
         {
            case 2:
            {
               LStringList arr;
               LStringWorker::split(text, "/", arr);
               if (arr.count() == 2)
               {
                  closed += StrToInteger(arr.at(0));
                  canceled += StrToInteger(arr.at(1));
               }
               break;
            }
            default:
            {
               sum += StrToDouble(text);
               break;
            }
         }         
      }
      if (col == 2) m_panel.setCellText(n, col,  StringConcatenate(IntegerToString(closed), " / ", IntegerToString(canceled)), TT_COLOR);            
      else m_panel.setCellText(n, col, DoubleToStr(sum, 1), TT_COLOR);            
   } 
}
void updateCoupleRow(int row_index, string v)
{
      double lots = 0;
      int closed_pos = 0;
      int cncl = 0;
      double swap = 0;
      double commis = 0;
      double prof = 0;
      double loss = 0;
      double divs = 0;
      
      int n = m_objHistory.count();
      for (int i=0; i<n; i++)      
      {
         LHistoryEvent rec;
         m_objHistory.getRecAt(i, rec);         
         if (rec.couple == v)
         {
            if (rec.isClosed()) 
            {
               closed_pos++;
               lots += rec.lots;     
               if (rec.profit > 0) prof += rec.profit;
               else loss += rec.profit;            
               swap = rec.swap;
               commis = rec.commis;               
            }
            else if (rec.isCanceled()) cncl++;        
            else if (rec.isDiv()) divs += rec.profit;    
         }
      }
      
      m_panel.setCellText(row_index, 1, DoubleToStr(lots, 2), CT_COLOR);               
      m_panel.setCellText(row_index, 2, StringConcatenate(IntegerToString(closed_pos), " / ", IntegerToString(cncl)) , CT_COLOR);               
      m_panel.setCellText(row_index, 3, DoubleToStr(swap, 2), CT_COLOR);               
      m_panel.setCellText(row_index, 4, DoubleToStr(commis, 2), CT_COLOR);               
      m_panel.setCellText(row_index, 5, DoubleToStr(prof, 2), CT_COLOR);               
      m_panel.setCellText(row_index, 6, DoubleToStr(loss, 2), CT_COLOR);               
      m_panel.setCellText(row_index, 7, DoubleToStr(divs, 2), CT_COLOR);   
      
      double res = swap + commis + prof + loss + divs;            
      m_panel.setCellText(row_index, 8, DoubleToStr(res, 2), (res < 0) ? 0x0000DD : 0x00AA10);               
}
void initPanelColumsParams()
{   
   LIntList col_sizes;
   col_sizes.append(13);
   col_sizes.append(14);
   col_sizes.append(18);
   col_sizes.append(7);
   col_sizes.append(13);
   col_sizes.append(8);
   col_sizes.append(8);
   col_sizes.append(8);
   col_sizes.append(11);
   m_panel.setColSizes(col_sizes);

   LIntList align_sizes;
   align_sizes.append(4);
   align_sizes.append(4);
   align_sizes.append(8);
   align_sizes.append(1);
   align_sizes.append(3);
   align_sizes.append(0);
   align_sizes.append(0);
   align_sizes.append(0);
   align_sizes.append(0);
   m_panel.setColCellSpaces(align_sizes);
   
}
void updatePanelCells(const LStringList &couples)
{
   int n = rowCount() - 1;   
   m_panel.setCellText(n, 0, "Total", TT_COLOR);   
   if (couples.isEmpty()) return;
   
   for (int i=0; i<n; i++)
   {
      m_panel.setCellText(i, 0, couples.at(i), CT_COLOR);     
      updateCoupleRow(i, couples.at(i));       
   }
   
   m_panel.setHeaderText(0, StringConcatenate("Couple (", n, ")"), HT_COLOR);
        
}
void saveToFile()
{
   string fname = StringConcatenate(EX_NAME, "_data", ".txt");
   Print("Try save data to file: ", fname);
   
   
   LStringList data;
   data.append("");
   data.append(LDateTime::currentDateTime());
   data.append(StringConcatenate("COUPLE_COUNT = ", IntegerToString(m_panel.rowCount()-1)));
   
   for (int i=0; i<m_panel.rowCount(); i++)
   {
      string f_line = "";
      for (int j=0; j<PANEL_COLUMNS; j++)
      {
         if (j == 2 || j == 3 || j == 5) continue;
         
         string s = m_panel.getCellText(i, j);
         if (j == 0) f_line = s;
         else f_line += StringConcatenate(" / ", s);
      }
      data.append(f_line);
   }
   
   
   bool ok = LFile::appendStringListToFile(fname, data);
   if (!ok) Print("result is fault!!!");
   else Print("Data saved OK!");
//      static bool appendStringListToFile(string filename, const LStringList &list);

}



