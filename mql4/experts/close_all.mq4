//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/trade/lstatictrade.mqh>



#define MAIN_TIMER_INTERVAL      10 //default value, be set if U_INTERVAL will be invalid value

input int U_MAGIC = -1;  //Orders magic
input int U_INTERVAL = 10;  //Working timer interval
input bool U_RandomPos = false;  //Random pos


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
   int n = OrdersTotal();
   Print("close_all: mainExec(),  OrdersTotal = ", n);
   if (n == 0) return;
   
   
   if (U_RandomPos)
   {
      int pos = int(MathMod(MathRand(), n));
      Print("try close random pos: ", pos);
      if (!OrderSelect(pos, SELECT_BY_POS))
         Print("Error selection by pos ", pos);
      else tryClose();
   }
   else
   {   
      for (int i=0; i<n; i++)
      {
         if (!OrderSelect(i, SELECT_BY_POS))
            Print("Error selection by pos ", i);
         else {tryClose(); break;}
      }
   }
}
void tryClose()
{
   
   if (U_MAGIC >= 0)
   {
      if (OrderMagicNumber() != U_MAGIC) return;
   }
   
   int ticket = OrderTicket();
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(ticket, info);
   Print("ticket=", ticket, "   status=", info.status);
   
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

}

