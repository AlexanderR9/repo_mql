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
#include <fllib/lprice.mqh>
#include <fllib/lstatictrade.mqh>


#define MAIN_TIMER_INTERVAL      10
#define DEFAULT_BEGIN_TIME       "1:30"
#define DEFAULT_END_TIME         "22:45"

input int U_NPips = 50;                            //N pips
input string U_BeginTime = DEFAULT_BEGIN_TIME;     //Begin time
input string U_EndTime = DEFAULT_END_TIME;         //End time
input int U_SlipPage = 20;                         //Slip page
input double U_LotSize = 0.1;                      //Lot size

//parameters
int n_pips; //input
datetime dt_begin; //input
datetime dt_end; //input
int m_slip; //input
double m_lot; //input
string m_couple = Symbol();
int m_period = PERIOD_M5;
bool on_tick_event = true; //если true то советник работает в событии OnTick() иначе в OnTimer()


//vars
double m_priceBase = -1; //опорная цена
datetime last_exec_time; //используется только при on_tick = true чтобы отлавливать интервалы MAIN_TIMER_INTERVAL
int m_ticket = -1;

void resetVars()
{
   m_priceBase = -1;
   m_ticket = -1;
   last_exec_time = TimeLocal();
}
void load()
{
   //m_ticket = 910510170;
}

//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   resetVars();
   checkInputParams();
   load();
   
   
   Print("----------------------Expert FL_LIMIT started!-----------------------");
   Print("COUPLE=", m_couple,"  TIME_FRAME=", m_period, "  NPips=", n_pips, "  SlipPage=", m_slip,
      //" BeginTime=", LDateTime::dateTimeToString(dt_begin, ".", ":", true), " EndTime=", LDateTime::dateTimeToString(dt_end, ".", ":", true));
      " BeginTime=", LDateTime::timeToString(dt_begin, ":", false), " EndTime=", LDateTime::timeToString(dt_end, ":", false));
  
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
      if (nextExec()) mainExec("OnTick()");
   }
}
void OnTimer()
{
   if (on_tick_event) return;
   mainExec("OnTimer()");
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void mainExec(string event_name)
{
   //Print("mainExec() func,  event_name=", event_name);
   updateDateDay(); //обновить дату если наступил следующий день
   updatePriceBase(); //обновить опорную цену, при необходимости
   if (m_priceBase <= 0) return;
   
   if (isTradingTime()) //время торговли
   {
      //Print("isTradingTime()");
      if (m_ticket > 0) checkOrderResult(); //проверить состояние открытого ордера
      else monitCurrentPrice(); //проверить на сколько ушла цена от опорного значения
   }
   else
   {
      //Print("trading time is over");
      checkForClose(); //при необходимости принудительно закрыть открытый ордер
   }
}
void checkForClose()
{
   if (m_ticket < 0) return;
   
  // Print("try close order by over time day");
   
   int code = 0;
   LStaticTrade::tryOrderClose(m_ticket, code, m_slip);
   
   if (code < 0)
   {
      err(StringConcatenate("func[checkForClose()]  err_code=", code, "  ticket=", m_ticket));
      if (code == -1 || code == -2 || code == -3) m_ticket = -1;
   }
   else m_ticket = -1;
}
void checkOrderResult()
{
  // Print("checkOrderResult()");
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(m_ticket, info);
   if (info.isError())
   {
      err(StringConcatenate("func[checkOrderResult()]  err_code=", info.err_code, "  ticket=", m_ticket));
      m_ticket = -1;
      return;
   }
   
   if (info.isHistory())
   {
      string s = StringConcatenate("Order cloded,  ticket=", m_ticket, "  result: ");
      if (info.isLoss())
      {
         Print(s, "LOSS (", DoubleToStr(info.result, 2), ")");
         
      }
      else if (info.isWin())
      {
         Print(s, "WIN (", DoubleToStr(info.result, 2), ")");
         m_priceBase = OrderClosePrice();
      }
      else 
      {
         Print(s, "NULL");
      }
      
      m_ticket = -1;
      Print("Base price value now: ", m_priceBase);
   }
   //else Print("order is opened");
}
void monitCurrentPrice()
{
   if (m_priceBase <= 0) return;
   double cur_price = MarketInfo(m_couple, MODE_BID);
   if (cur_price <= 0) return;
   
   int cmd = -1;
   int n = LPrice::pricesDiff(m_priceBase, cur_price, m_couple);
   if (n > n_pips) cmd = OP_BUY;
   else if (n < (-1*n_pips)) cmd = OP_SELL;
   
  // Print("m_priceBase=", m_priceBase, "  cur_price=", cur_price, "  d_pips=", n, "  cmd=", cmd);
   
   if (cmd != -1) openPos(cmd);
}
void openPos(int cmd)
{
   LOpenPosParams params(m_couple, m_lot, cmd);
   params.slip = m_slip;
   params.comment = "fl_limit";
   params.setStops(n_pips, n_pips, true);
   
   Print(params.out());
   //return;
   
   LStaticTrade::tryOpenPos(m_ticket, params);
   if (params.isError())
   {
      m_ticket = -1;
      err(StringConcatenate("func[openPos()]  err_code=", params.err_code));
   }
}
void err(string s)
{
   Print("WAS ERROR: ", s, "  GetLastError()=", GetLastError());
}
void updatePriceBase()
{
   if (m_priceBase > 0) return;
   for (int i=0; i<10000; i++)
   {
      datetime dt_open = iTime(m_couple, m_period, i);
      if (dt_open <= dt_begin)
      {
         if (i > 0) 
            m_priceBase = iClose(m_couple, m_period, i);
         
         break;
      }
   }
   
   if (m_priceBase > 0)
      Print("Base price updated: ", m_priceBase);
}
void updateDateDay()
{
   if (TimeDay(TimeLocal()) != TimeDay(dt_begin))
   {
      LDateTime::addDays(dt_begin, 1);
      LDateTime::addDays(dt_end, 1);
      m_priceBase = -1;
      
      string times = StringConcatenate("BeginTime=", LDateTime::dateTimeToString(dt_begin, ".", ":", false), 
         " EndTime=", LDateTime::dateTimeToString(dt_end, ".", ":", false));
      Print("Date day updated: ", times);
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
bool isTradingTime()
{
   if (LDateTime::isHolidayNow()) return false;
   datetime dt = TimeLocal();
   return ((dt > dt_begin) && (dt < dt_end));
}


void checkInputParams()
{
   m_slip = U_SlipPage;
   if (m_slip < 0) m_slip = 20;
   
   n_pips = U_NPips;
  int stopLevel =int(MarketInfo(m_couple, MODE_STOPLEVEL));
  if (U_NPips < 1 || U_NPips < stopLevel)
  {
      MessageBox(StringConcatenate("Invalid value NPips=", U_NPips,", \n set min validity value: ", stopLevel + 1), "Error input params");
      n_pips = stopLevel + 1;
  }
  
  m_lot = U_LotSize;
  double minLot = MarketInfo(m_couple, MODE_MINLOT);
  double maxLot = MarketInfo(m_couple, MODE_MAXLOT);
  if (m_lot < minLot || maxLot > maxLot)
  {
      MessageBox(StringConcatenate("Invalid value LotSize=", U_LotSize,", \n set min validity value: ", minLot), "Error input params");
      m_lot = minLot;  
  }
  
  
  //check time
  bool ok;
  dt_begin = LDateTime::fromString(U_BeginTime, ok);
  if (!ok)
  {
      MessageBox(StringConcatenate("Invalid value BeginTime=", U_BeginTime,", \n  set default value: ", DEFAULT_BEGIN_TIME), "Error input params");
      dt_begin = LDateTime::fromString(DEFAULT_BEGIN_TIME, ok);
  }
  dt_end = LDateTime::fromString(U_EndTime, ok);
  if (!ok)
  {
      MessageBox(StringConcatenate("Invalid value EndTime=", U_EndTime,", \n  set default value: ", DEFAULT_END_TIME), "Error input params");
      dt_begin = LDateTime::fromString(DEFAULT_END_TIME, ok);
  }  
  if (dt_end < dt_begin)
  {
      MessageBox("Invalid time range:  EndTime < BeginTime", "Warning");
  }
}