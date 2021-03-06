//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/lstatictrade.mqh>
#include <Trade/Trade.mqh>



#define MAIN_TIMER_INTERVAL      10

input int U_MAGIC = -1;  //Orders magic
input int U_INTERVAL = 10;  //Working timer interval
input bool U_RandomPos = false;  //Random pos

CTrade m_tradeObj;

//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{  
   if (U_INTERVAL > 0 && U_INTERVAL < 301) EventSetTimer(U_INTERVAL);
   else EventSetTimer(MAIN_TIMER_INTERVAL);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
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
   int n = OrdersTotal(); //отложенные ордера
   int pn = PositionsTotal(); //открытые позиции
   Print("close_all: mainExec(),  OrdersTotal = ", n, "  PositionsTotal = ", pn);
   if (pn == 0) return;
   
   ulong ticket = 0;
   if (U_RandomPos)
   {
      int pos = MathRand() % pn;
      Print("try close random pos: ", pos);
      ticket = PositionGetTicket(pos);
      if (!PositionSelectByTicket(ticket)) Print("Error selection by pos ", pos);
      else tryClose(ticket);
   }
   else
   {   
      for (int i=0; i<pn; i++)
      {
         ticket = PositionGetTicket(i);
         if (!PositionSelectByTicket(ticket)) Print("Error selection by pos ", i, "   ticket=", ticket);
         else {tryClose(ticket); break;}
      }
   }
}
void tryClose(ulong &ticket)
{
   if (U_MAGIC >= 0)
   {
      if (PositionGetInteger(POSITION_MAGIC) != U_MAGIC) return;
   }
   
   //int ticket = OrderTicket();
   //LCheckOrderInfo info;
   //LStaticTrade::checkOrderState(ticket, info);
   Print("ticket=", ticket, "   status=", PositionGetString(POSITION_SYMBOL));
   
   //MqlTradeRequest req;
   //MqlTradeResult reply;
   
   m_tradeObj.PositionClose(ticket);
   
   
   /*
   if (info.isPengingNow())
   {
      bool ok = OrderDelete(ticket);
      if (ok) Print("Pending order deleted ok!  ticket=", ticket);
      else Print("Error delete pending order: ", ticket);
   }
   else if (info.isOpened())
   {
      int result = -1;
      LStaticTrade::tryOrderClose(ticket, result, 100);
      if (result < 0) Print("ERR: closing order: ", ticket, ",  err_code=", result);
   }
   */
   
   

}

