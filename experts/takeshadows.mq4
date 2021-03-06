//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property version   "1.01"
#property copyright "AlexMql"
#property strict

#property description "Цель советника взять заданное число пунктов теней каждой дневной свечи,"
#property description "все параметры задавать для 4-х значного советника независимо от типа терминала."

#include <mygames/takeshadows.mqh>
#include <mylib/spreadlogger.mqh>

#define  EX_MAGIC_VALUE    5 //уникальное магическое число для этого экземпляра советника


//  входные параметры советника
input IP_TimerInterval U_MainTimerInterval = ipMTI_15;    //Main timer interval
input IP_TimerInterval U_SaveTimerInterval = ipMTI_600;  //Save state timer interval
input string U_BeginTime = "1:30";                       //Begin time, msk
input string U_EndTime = "22:45";                        //End time, msk
input string U_Couples = "eurchf; usdchf; usdcad";       //Work couples
input IP_SimpleNumber U_SlipPage = ipMTI_Num1;           //Slip page
input IP_SimpleNumber U_MaxSpread = ipMTI_Num3;          //Max spread, pips
input IP_LotSize U_StartLot = ipMTI_Lot01;               //Start lot size
input double U_LotFactor = 1.1;                          //Lot factor
input IP_SimpleNumber U_Dist = ipMTI_Num0;               //Distattion steps
input IP_SimpleNumber U_StepLower = ipMTI_Num1;          //Step lower
input IP_SimpleNumber U_StepUpper = ipMTI_Num3;          //Step upper
input IP_TrateType U_TradeType = ipMTI_OnlyBuy;          //Trade type
input IP_SimpleNumber U_ShadowPips = ipMTI_Num8;         //Shadow pips
input IP_SimpleNumber U_StopLossPips = ipMTI_Num0;       //Stop loss pips
input IP_SimpleNumber U_MaxCandlePips = ipMTI_Num0;       //Max current candle size


//главный объект реализующий стратегию советника
TakeShadowsGame m_game;

LSpreadLogger *m_spreadLogger;

//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_spreadLogger = NULL;
   m_game.setMagic(EX_MAGIC_VALUE);
   m_spreadLogger = new LSpreadLogger(m_game.workingFolder());
   m_spreadLogger.setInterval(120);
   
   bool ok;
   checkInputParams(ok);
   if (!ok) return(INIT_PARAMETERS_INCORRECT);
   
   m_game.exInit();
   
   
   EventSetTimer(m_game.mainTimerInterval());
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   m_game.exDeinit();
   delete m_spreadLogger;
   m_spreadLogger = NULL;
}
void OnTimer()
{
   if (LDateTime::isHolidayNow()) return;
   m_game.mainExec();
   
   if (m_spreadLogger) 
      m_spreadLogger.exec();
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void initCouples()
{
   LStringList list;
   LStringWorker::parseCouples(U_Couples, list);
   if (list.isEmpty()) 
   {
      MessageBox(StringConcatenate("Invalid couples strings: ", U_Couples), "Error input params");
      return;
   }
   
   int n = list.count();
   for (int i=0; i<n; i++)
   {
      m_game.addSymbol(list.at(i));
      m_spreadLogger.addCouple(list.at(i));
   }
}
void initTimesRange(bool &ok)
{
   ok = true;
   datetime dt_begin = LDateTime::fromString(U_BeginTime, ok);
   if (!ok)
   {
      MessageBox(StringConcatenate("Invalid value BeginTime=", U_BeginTime), "Error input params");
      return;
   }
   datetime dt_end = LDateTime::fromString(U_EndTime, ok);
   if (!ok)
   {
      MessageBox(StringConcatenate("Invalid value EndTime=", U_EndTime), "Error input params");
      return;
   }  
   if (dt_end < dt_begin)
   {
      MessageBox("Invalid time range:  EndTime < BeginTime", "Warning");
      ok = false;
      return;
   }
  
   m_game.setTimesRange(dt_begin, dt_end);
}
void initLotFactor(bool &ok)
{
   ok = true;
   if (U_LotFactor < 1 || U_LotFactor > 10)
   {
      MessageBox(StringConcatenate("Invalid value LotFactor=", U_LotFactor), "Error input params");
      ok = false;
      return;      
   }
   m_game.setInputParam(exipNextBetFactor, U_LotFactor);
}
void setTimerIntervals()
{
   int t1 = IP_ConvertClass::fromTimerInterval(U_MainTimerInterval);
   int t2 = IP_ConvertClass::fromTimerInterval(U_SaveTimerInterval);
   
   if (t1 < 1) t1 = 10;
   m_game.setInputParam(exipTimerInterval, t1);
   if (t2 > 1) m_game.setInputParam(exipSaveInterval, t2);
}
void initStopProfit(bool &ok)
{
   ok = true;
   if (U_StopLossPips < 3 && U_StopLossPips != 0)
   {
      MessageBox(StringConcatenate("Invalid value StopLossPips=", U_StopLossPips), "Error input params");
      ok = false;
      return;      
   }
   if (U_ShadowPips < 3)
   {
      MessageBox(StringConcatenate("Invalid value ShadowPips=", U_ShadowPips), "Error input params");
      ok = false;
      return;      
   }
   
   m_game.setInputParam(exipStop, IP_ConvertClass::fromSimpleNumber(U_StopLossPips));
   m_game.setInputParam(exipProfit, IP_ConvertClass::fromSimpleNumber(U_ShadowPips));
}
void checkInputParams(bool &ok)
{
   ok = true;
   initCouples();
   if (m_game.isEmpty()) {ok = false; return;}
   
   initTimesRange(ok);
   if (!ok) return;

   initLotFactor(ok);
   if (!ok) return;
   
   initStopProfit(ok);
   if (!ok) return;
   
   setTimerIntervals();
   
   m_game.setInputParam(exipStartLot, IP_ConvertClass::fromLotSize(U_StartLot));
   m_game.setInputParam(exipPermittedPos, int(U_TradeType));
   m_game.setInputParam(exipSlipPips, IP_ConvertClass::fromSimpleNumber(U_SlipPage));
   m_game.setInputParam(exipMaxSpread, IP_ConvertClass::fromSimpleNumber(U_MaxSpread));
   m_game.setInputParam(exipDist, IP_ConvertClass::fromSimpleNumber(U_Dist));
   m_game.setInputParam(exipDecStep, IP_ConvertClass::fromSimpleNumber(U_StepLower));
   m_game.setInputParam(exipIncStep, IP_ConvertClass::fromSimpleNumber(U_StepUpper));
   m_game.setInputParam(exipNPips, IP_ConvertClass::fromSimpleNumber(U_MaxCandlePips));
}

