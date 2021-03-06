//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/ldatetime.mqh>
#include <mylib/lcontainer.mqh>
#include <fl4ma/fl4ma_couple.mqh>


#define MAIN_TIMER_INTERVAL      5

input bool U_eurusd = false;      //EURUSD
input bool U_euraud = false;      //EURAUD
input bool U_gbpusd = false;      //GBPUSD
input bool U_usdjpy = false;      //USDJPY
input bool U_audusd = false;     //AUDUSD
input bool U_usdcad = false;     //USDCAD
input bool U_eurjpy = true;     //EURJPY

input int U_WTF = 5;            //Working timeframe, (minutes)   
input int U_SlipPage = 20;       //Slip page
input double U_LotSize = 0.1;    //Lot size

//parameters
int m_slip; //input
double m_lot; //input
int m_period = 0; //input
LStringList m_couples; //input

FL4MA_Couple* m_couplesObj[];


//working vars
bool on_tick_event = true; //если true то советник работает в событии OnTick() иначе в OnTimer()
datetime last_exec_time; //используется только при on_tick = true чтобы отлавливать интервалы MAIN_TIMER_INTERVAL


//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   last_exec_time = TimeLocal();
   checkInputParams();
   initCoupleObjects();
   
   Print("");
   Print("");
   Print("");
   Print("---------------FL4MA STARTED------------------");
   
   EventSetTimer(MAIN_TIMER_INTERVAL);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   destroyCoupleObjects();
   m_couples.clear();
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
   if (couplesEmpty()) return;
   
   int n = couplesCount();
   for (int i=0; i<n; i++)
   {
      int result = 0;
      m_couplesObj[i].exec(result);
      if (result == ExecResult::erNone) continue;
      
      break;
   }
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
int couplesCount() {return m_couples.count();}
bool couplesEmpty() {return (couplesCount() == 0);}
void initCoupleObjects()
{
   ArrayFree(m_couplesObj);
   if (couplesEmpty()) return;
   
   int n = couplesCount();
   for (int i=0; i<n; i++)
   {
      ArrayResize(m_couplesObj, i+1);
      m_couplesObj[i] = new FL4MA_Couple(m_couples.at(i));
      m_couplesObj[i].setParams(m_period, m_lot, m_slip);
   }
}
void destroyCoupleObjects()
{
   int n = couplesCount();
   if (n > 0)
   {
      for (int i=0; i<n; i++)
      {
         delete m_couplesObj[i];
         m_couplesObj[i] = NULL;
      }
   }  
   ArrayFree(m_couplesObj);
}
void checkInputParams()
{
   //slippage
   m_slip = U_SlipPage;
   if (m_slip < 0) m_slip = 20;
   
  
  //lotsize
  m_lot = U_LotSize;
  double minLot = MarketInfo(Symbol(), MODE_MINLOT);
  double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
  if (m_lot < minLot || maxLot > maxLot)
  {
      MessageBox(StringConcatenate("Invalid value LotSize=", U_LotSize,", \n set min validity value: ", minLot), "Error input params");
      m_lot = minLot;  
  }
  
  //timeframe
  m_period = U_WTF;
  if (U_WTF != 1 && U_WTF != 5 && U_WTF != 15 && U_WTF != 30 && U_WTF != 60 && U_WTF != 240)
  {      
      MessageBox(StringConcatenate("Invalid value TimeFrame=", U_WTF,", \n set validity value: M5"), "Error input params");
      m_period = 5;
  }
  
  //couples
  m_couples.clear();
  if (U_eurusd) m_couples.append("EURUSD");
  if (U_euraud) m_couples.append("EURAUD");
  if (U_gbpusd) m_couples.append("GBPUSD");
  if (U_usdjpy) m_couples.append("USDJPY");
  if (U_audusd) m_couples.append("AUDUSD");
  if (U_usdcad) m_couples.append("USDCAD");
  if (U_eurjpy) m_couples.append("EURJPY");
  
}











