//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/ldataemiter.mqh>
#include <fllib1/flgridexchange.mqh>


//#define MAIN_TIMER_INTERVAL      5
#define MAIN_TIMER_INTERVAL_MS     3000


//working vars
datetime last_exec_time; //используется только при on_tick = true чтобы отлавливать интервалы MAIN_TIMER_INTERVAL
LDataEmiter m_emiter;
FLGridExchanger m_exchanger;
bool is_running;


//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   last_exec_time = TimeLocal();
   initCouples();
   is_running = false;
   
   Print("-------------------- DATA EMITER STARTED!!!--------------------------");
   
   //EventSetTimer(MAIN_TIMER_INTERVAL);
   
   m_exchanger.setKey("data_emiter");
   m_exchanger.setOwnChartID(ChartID());

   EventSetMillisecondTimer(MAIN_TIMER_INTERVAL_MS);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
}
void OnTimer()
{
   Print("OnTimer() dataemiter");
   mainExec();
   
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (sparam == m_exchanger.key()) return;
   if (id < CHARTEVENT_CUSTOM) return;

   m_exchanger.receiveMsg(id, lparam, dparam, sparam);
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void readExchamgerNewMessages()
{
   if (!m_exchanger.hasNewMessages()) return;
   int n = m_exchanger.msgCount();
  // Print("Exchanger records: ", n);  
   if (n == 0) return;
   
   for (int i=0; i<n; i++)
   {
      if (m_exchanger.isRecReaded(i)) continue;
   
      FLGridExchangeMsg msg;
      m_exchanger.getRecord(i, msg);
      
      switch (msg.message_type)
      {
         case emtStartData_TestMode: {is_running = true; break;}
         case emtStopData_TestMode: {is_running = false; break;}
         default: break;
      }
   }   
}
void initCouples()
{
   Print("try load data......");
   m_emiter.addCouple("USDJPY");
   m_emiter.addCouple("USDCAD");
   m_emiter.addCouple("EURJPY");
   
   
   Print("couples successed loaded: ", m_emiter.count());
   
}
void mainExec()
{

}

