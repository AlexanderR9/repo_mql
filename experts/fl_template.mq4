//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <fllib/ldatetime.mqh>


#define MAIN_TIMER_INTERVAL      10

//working vars
bool on_tick_event = true; //если true то советник работает в событии OnTick() иначе в OnTimer()
datetime last_exec_time; //используется только при on_tick = true чтобы отлавливать интервалы MAIN_TIMER_INTERVAL


//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   last_exec_time = TimeLocal();
   
   
   EventSetTimer(MAIN_TIMER_INTERVAL);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
}
void OnTick()
{
   if (on_tick_event)
   {
      if (nextExec()) mainExec();
   }
}
void OnTimer()
{
   if (on_tick_event) return;
   mainExec();
   
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void mainExec()
{

}
bool nextExec()
{
   int n = LDateTime::dTime(last_exec_time, TimeLocal());
   if (n >= MAIN_TIMER_INTERVAL)
   {
      last_exec_time = TimeLocal();
      return true;
   }
   return false;
}

