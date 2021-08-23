//+------------------------------------------------------------------+
//|                                                      fl_grid.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/lflgrid.mqh>
#include <mylib/flinputparams.mqh>

#define EXEC_TIMER_INTERVAL         3
#define GRID_COUNT                  10

//expert vars
LFLGrid fl_grids[GRID_COUNT];
string ex_name = "flgrid";
int ex_magic = 0;
bool ex_invalid_state = false;
int timer_counter = 0;


void calcMagic()
{
   int k = 0;
   //k = 1000 * TimeSeconds(TimeCurrent());
   string s = Symbol();
   for (int i=0; i< 10000; i++)
      if (s == SymbolName(i, false)) 
      {
         ex_magic = k + i;
         break;
      }
}
string ex_id() 
{
   return (ex_name + IntegerToString(ex_magic));
}

//+------------------------------------------------------------------+
//| Expert MQL functions                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("-------------------------------------------------------------");
   calcMagic();
   setGridsParams();
   loadState();
   Print("Expert FL_GRID started!  COUPLE="+Symbol()+"    TF="+IntegerToString(PERIOD_CURRENT)+"  magic="+IntegerToString(ex_magic));
   //Print("Expert ID: "+ex_id());
      
   EventSetTimer(int(EXEC_TIMER_INTERVAL));   
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();   
   saveState();
   //obj_panel.destroy();
}
void OnTimer()
{
   timer_counter++;
   Print("OnTimer()");
   if (ex_invalid_state) return;
   
   int result = 0;
   string err = "";
   
   ////////////////////test/////////////////////////////////////////
  // if (timer_counter < 5) 
      //fl_grids[timer_counter-1].testShowPanel();
      fl_grids[0].exec(result, err);


   return;
   
   for (int i=0; i<GRID_COUNT; i++)
   {
      fl_grids[i].exec(result, err);
      switch (result)
      {
         case erLookNextGrid: break;
         case erOpenedGridOrder:
         case erFinishExecuting: return;
         case erOpenedHedgeOrder:
         {
            Print("opened hedge order for grid ", fl_grids[i].number());
            
            return;
         }
         case erHasError:
         {
            Print("ERR: has error by executing for grid ", fl_grids[i].number(), "   GetLastError()=", GetLastError());
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
//+------------------------------------------------------------------+
void loadState()
{
   if (ex_invalid_state) return;
   
   for (int i=0; i<GRID_COUNT; i++)
      fl_grids[i].loadState();
}
void saveState()
{
   if (ex_invalid_state) return;
   
   for (int i=0; i<GRID_COUNT; i++)
      fl_grids[i].saveState();
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
   
   for (int i=0; i<GRID_COUNT; i++)
   {
      fl_grids[i].setNumber(i+1);
      fl_grids[i].setTradeKind(OP_BUY);
      fl_grids[i].setMagic(ex_magic);
      
      if (fl_grids[i].invalid())
      {
         ex_invalid_state = true;
         Print("grid ", fl_grids[i].number(), " is invalid!");
      }
      //else Print("grid ", fl_grids[i].number(), " ok!");
   }
}


//инициализация объекта для вывода графической панели
/*
void initPanel()
{
   obj_panel.setCorner(pcLeftDown);
   obj_panel.setOffset(10, 10);
   obj_panel.setSize(250, 350);
   obj_panel.setGridSize(4, 2);
   //obj_panel.setBackgroundColor(clrMediumSeaGreen);
   obj_panel.setHeaderTextColor(clrRed);
   obj_panel.setCellsTextColor(clrWhite);
   obj_panel.setFontSizes(12, 16);
   //obj_panel.setHeaderSeparatorParams(clrBlue, 2);
   obj_panel.setMargin(20);
   
}
*/


