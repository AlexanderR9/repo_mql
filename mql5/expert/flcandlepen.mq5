//+------------------------------------------------------------------+
//|                                                  flcandlepen.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//задание:
//заданное время работы в настройках,
//жестко заданный таймфрейм в настройках,
//размер лота в настройках,
//инструмент с текущего графика,
//
//алгоритм: Смотрим максимум и минимум прошлой свечи.Выставляем Бай стоп и селл стоп на этих уровнях.
//Если позиция открылась, то ее закрываем по закрытию свечи.
//Если не открылась, то переходим на выполнение алгоритма для следующей свечи.
//Если позиция открылась по одному из ордеров и далее дошла до срабатывания другого ордера, то она закроется.
//В этом случае переходим на выполнение алгоритма по следующей свече.
//При выставлении отложенных ордеров если не хватает минимального зазора в цене, то увеличить(уменьшить) планку 
//цены открытия чтобы ордер смог выставиться.



#include <mylib/inputparamsenum.mqh>
#include <fllib/flcandlepenobj.mqh>

#define EX_NAME                  "FL_CANDLE_PEN"
#define MAIN_TIMER_INTERVAL      20
#define DEFAULT_BEGIN_TIME       "6:30"
#define DEFAULT_END_TIME         "21:45"

//input params
input string U_BeginTime = DEFAULT_BEGIN_TIME;     //Begin time
input string U_EndTime = DEFAULT_END_TIME;         //End time
input IP_WorkingTimeFrame U_Period = ipWTF_15M;    //Period
input double U_LotSize = 0.1;                      //Lot size


//vars
string m_couple;
double lot_size;
FLCandlePenObj *m_obj = NULL;
LTradeIntervalChecker t_checker;

void resetVars()
{
   m_couple = "";
   lot_size = 0;
   
   if (m_obj)
   {
      delete m_obj;
      m_obj = NULL;
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   resetVars();
   
   m_couple = Symbol();
   checkInputParams();
   initExpertTradeObj();

   EventSetTimer(MAIN_TIMER_INTERVAL);
   Print("Expert ", EX_NAME, " started!!!");
   Print(toStr());
   
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   resetVars();
}
void OnTimer()
{
   if (!inputParamsValidity())
   {
      Print("ERROR: input parameters is invalid.");
      return;
   }
   mainExec();
}
//+------------------------------------------------------------------+
void mainExec()
{
   t_checker.checkUpdateDateDay(); //обновить дату если наступил следующий день

   if (m_obj) 
      m_obj.exec();   
}
bool inputParamsValidity()
{
   if (t_checker.invalid()) return false;
   return (lot_size >= 0.01);
}
void initExpertTradeObj()
{
   if (!inputParamsValidity()) return;
   m_obj = new FLCandlePenObj(&t_checker, m_couple, lot_size, U_Period);
}
void checkInputParams()
{
  lot_size = U_LotSize;
  double minLot = SymbolInfoDouble(m_couple, SYMBOL_VOLUME_MIN);
  double maxLot = SymbolInfoDouble(m_couple, SYMBOL_VOLUME_MAX);
  if (lot_size < minLot || lot_size > maxLot)
  {
      string text;
      StringConcatenate(text, "Invalid value LotSize=", U_LotSize,", \n set min validity value: ", minLot);
      MessageBox(text, "Error input params");
      lot_size = minLot;  
  }
  
  //check time
  t_checker.init(U_BeginTime, U_EndTime);
  if (t_checker.invalid())
  {
      MessageBox(t_checker.err(), "Error input params");

      string text;
      StringConcatenate(text, "Set default time interval: ", DEFAULT_BEGIN_TIME, " - ", DEFAULT_END_TIME);
      MessageBox(text, "Error input params");
      t_checker.init(string(DEFAULT_BEGIN_TIME), string(DEFAULT_END_TIME));
  }
}
string toStr()
{
   string s = "Input params: ";
   StringAdd(s, ("  lot_size=" + DoubleToString(lot_size, 2)));
   StringAdd(s, ("  period=" + IntegerToString(U_Period)));
   StringAdd(s, ("  " + t_checker.toStr()));
   return s;
}

