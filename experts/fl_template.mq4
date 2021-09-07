//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#define MAIN_TIMER_INTERVAL      10


//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   EventSetTimer(MAIN_TIMER_INTERVAL);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
}
void OnTick()
{
   
}
void OnTimer()
{
   
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
