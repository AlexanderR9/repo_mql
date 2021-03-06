//+------------------------------------------------------------------+
//|                                                       flhull.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <mylib/ldatetime.mqh>
#include <mylib/inputparamsenum.mqh>
#include <fllib/flhullobj.mqh>

#define EX_NAME                  "FL_HULL"
#define MAIN_TIMER_INTERVAL      2
#define DEFAULT_BEGIN_TIME       "6:30"
#define DEFAULT_END_TIME         "21:45"

//input params
input string U_BeginTime = DEFAULT_BEGIN_TIME;     //Begin time
input string U_EndTime = DEFAULT_END_TIME;         //End time
input int U_Period = 60;                           //Period
input int U_SlipPage = 20;                         //Slip page
input double U_LotSize = 0.1;                      //Lot size

input double   U_I_HmaLength =   14;     // Hull period (indicator hull)
input double   U_I_HmaPower  =    1;     // Hull power (indicator hull)
input enPrices U_I_Price     = pr_close; // Price (indicator hull)


//input params struct
struct IParams
{
   datetime dt_begin;
   datetime dt_end;
   double lot_size;
   int slip_pips;
   int period;
   
   double ihull_len;
   double ihull_power;
   int ihull_price_type;
   
   
   void reset()
   {
      dt_begin = dt_end= 0;
      lot_size = 0;
      slip_pips = 0;
      period = PERIOD_H1;  
      ihull_len = ihull_power = ihull_price_type = -1;
   }
   bool invalid() const
   {
      return (dt_begin <= 0 || dt_end <= 0 || dt_begin >= dt_end ||
                  lot_size < 0.01 || slip_pips < 0 || period < 0 ||
                  ihull_len < 2 || ihull_len > 500 || ihull_power < 1 || ihull_power > 10
                  || ihull_power >= (ihull_len/2) || ihull_price_type < pr_close);
   }
   string toStr() const
   {
      string s = "INPUT PARAMS: ";
      s += ("dt_begin="+LDateTime::dateTimeToString(dt_begin, ".", ":", false)+"  ");
      s += ("dt_end="+LDateTime::dateTimeToString(dt_end, ".", ":", false)+"  ");
      s += ("slip_pips="+IntegerToString(slip_pips)+"  ");
      s += ("period="+IntegerToString(period)+"  ");
      s += ("lot_size="+DoubleToString(lot_size, 2)+"  ");
      s += "\n";
      s += "IDICATOR HULL PARAMS: ";
      s += ("period="+IntegerToString(int(ihull_len))+"  ");
      s += ("power="+IntegerToString(int(ihull_power))+"  ");
      s += ("price_type="+IntegerToString(ihull_price_type)+"  ");
      return s;
   }
};

//vars
string m_couple;
IParams m_params;
int hull_handle;
FLHullObj *m_obj = NULL;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_couple = Symbol();
   hull_handle = -1;
   m_params.reset();
   checkInputParams();
   initHullHandle();
   initHullObj();

   EventSetTimer(MAIN_TIMER_INTERVAL);
   Print("Expert ", EX_NAME, " started!!!");
   Print(m_params.toStr());
   
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   
   if (m_obj)
   {
      delete m_obj;
      m_obj = NULL;
   }
}
void OnTick() {}
void OnTimer()
{
   if (m_params.invalid())
   {
      Print("ERROR: input parameters is invalid.");
      return;
   }
   
   if (hull_handle < 0)
   {
      Print("ERROR: hull_handle < 0");
      return;
   }

   mainExec();
}
//+------------------------------------------------------------------+
void mainExec()
{
   updateDateDay(); //обновить дату если наступил следующий день

   if (m_obj) 
      m_obj.exec(m_params.dt_begin, m_params.dt_end);   
}
void initHullHandle()
{
   hull_handle = -2;
   if (m_params.invalid()) return;
   hull_handle = -1;
   hull_handle = iCustom(m_couple, ENUM_TIMEFRAMES(m_params.period), "hull_", 
                     m_params.ihull_len, m_params.ihull_power, m_params.ihull_price_type);
                     
   if (hull_handle < 0)
   {
      Print("Invalid handle for indicator [hull_], expert breaked!");
   }                     
}
void initHullObj()
{
   if (hull_handle < 0) return;
   if (m_params.invalid()) return;
   m_obj = new FLHullObj(m_couple, m_params.slip_pips, hull_handle, m_params.lot_size);
}
void checkInputParams()
{
   m_params.slip_pips = U_SlipPage;
   if (m_params.slip_pips < 0) m_params.slip_pips = 20;
     
  m_params.lot_size = U_LotSize;
  double minLot = SymbolInfoDouble(m_couple, SYMBOL_VOLUME_MIN);
  double maxLot = SymbolInfoDouble(m_couple, SYMBOL_VOLUME_MAX);
  if (m_params.lot_size < minLot || m_params.lot_size > maxLot)
  {
      string text;
      StringConcatenate(text, "Invalid value LotSize=", U_LotSize,", \n set min validity value: ", minLot);
      MessageBox(text, "Error input params");
      m_params.lot_size = minLot;  
  }

   m_params.period = U_Period;
   if (m_params.period != 1 && m_params.period != 5 && m_params.period != 15 && 
         m_params.period != 30 && m_params.period != 60 && m_params.period != 240 && m_params.period != PERIOD_D1)
   {
      string text;
      StringConcatenate(text, "Invalid value Period=", U_Period);
      MessageBox(text, "Error input params");
      m_params.period = -1;      
   }                 
  
  //check time
  bool ok;
  m_params.dt_begin = LDateTime::fromString(U_BeginTime, ok);
  if (!ok)
  {
      string text;
      StringConcatenate(text, "Invalid value BeginTime=", U_BeginTime,", \n  set default value: ", DEFAULT_BEGIN_TIME);
      MessageBox(text, "Error input params");
      m_params.dt_begin = LDateTime::fromString(DEFAULT_BEGIN_TIME, ok);
  }
  m_params.dt_end = LDateTime::fromString(U_EndTime, ok);
  if (!ok)
  {
      string text;
      StringConcatenate(text, "Invalid value EndTime=", U_EndTime,", \n  set default value: ", DEFAULT_END_TIME);
      MessageBox(text, "Error input params");
      m_params.dt_begin = LDateTime::fromString(DEFAULT_END_TIME, ok);
  }  
  if (m_params.dt_end < m_params.dt_begin)
  {
      MessageBox("Invalid time range:  EndTime < BeginTime", "Warning");
  }
  
  //indicator params
  m_params.ihull_len = U_I_HmaLength;
  m_params.ihull_power = U_I_HmaPower;
  m_params.ihull_price_type = U_I_Price;
}
void updateDateDay()
{
   MqlDateTime dt_struct_local;
   TimeToStruct(TimeLocal(), dt_struct_local);
   MqlDateTime dt_struct;
   TimeToStruct(m_params.dt_begin, dt_struct);
   
   if (dt_struct.day != dt_struct_local.day)
   {
      LDateTime::addDays(m_params.dt_begin, 1);
      LDateTime::addDays(m_params.dt_end, 1);
      
      string text;
      StringConcatenate(text, "BeginTime=", LDateTime::dateTimeToString(m_params.dt_begin, ".", ":", false), 
         " EndTime=", LDateTime::dateTimeToString(m_params.dt_end, ".", ":", false));
      Print("Date day updated: ", text);
   }
}




