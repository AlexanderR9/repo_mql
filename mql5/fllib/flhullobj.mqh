//+------------------------------------------------------------------+
//|                                                    flhullobj.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <mylib/ldatetime.mqh>
#include <Trade/Trade.mqh>

#define  FL_HULL_MAGIC     125
#define  HULL_BUFF_SIZE    500
#define  TRADE_CODE_OK     TRADE_RETCODE_DONE
#define  USE_DEBUG         false

/////////// FLHullObj ///////////////////////////
class FLHullObj
{
public:
   FLHullObj(string couple, int slip, int hh, double volume) :m_couple(couple), m_slip(slip), i_handle(hh), m_lot(volume) {reset();}
   
   void exec(const datetime&, const datetime&); //основная функция от куда вызывается весь алгоритм класса
   inline void setInverse(bool b) {m_inverse = b;}
   
protected:
   void reset();
   bool isTradingTime(const datetime&, const datetime&) const; //проверка что текущий момент времени попадает в рабочий интервал
   void checkCloseOrdersByOverTradingTime(); //принудительно закрыть открытые ордера т.к. время вышло из рабочего интервала
   void checkTrade(); //проверить текущее состояние рынка и при необходимости открыть\закрыть позу
   void updateBuffer(); //обновляет m_buffer, заполняя его свежими значениями индикатора
   bool changeIHullToUp() const; //индикатор в предпоследней свече сменил направление на "вверх"
   bool changeIHullToDown() const; //индикатор в предпоследней свече сменил направление на "вниз"
   void checkTradeDown(); //ситуация когда нужно открыть позу sell и закрыть buy (при условии что это еще не выполнено)
   void checkTradeUp(); //ситуация когда нужно открыть позу buy и закрыть sell (при условии что это еще не выполнено)
   void checkTradeDown_v2();
   void checkTradeUp_v2();
   double currentPrice(ENUM_ORDER_TYPE type) const; //текущая цена инструмента для открытия позы (зависит от type) 
   
   
   inline int buffSize() const {return ArraySize(m_buffer);}
   inline bool buffEmpty() const {return (buffSize() == 0);}
   inline string comment() const {return ("fl_hull  n_opened="+IntegerToString(m_counter));}
   
   
   //trade operations
   void closeOrder(long&, string&);
   void openOrder(int, long&, string&);
   
private:   
   long order_sell;
   long order_buy;
   string m_couple;
   int m_slip;
   double m_lot;
   int i_handle;           // дескриптор индикатора hull_
   double m_buffer[];      //массив значений индикатора (постоянно должен обновляться)
   CTrade m_tradeObj;
   int m_counter; //счетчик открытий поз
   bool m_inverse;
   
};
//#############################################################
void FLHullObj::exec(const datetime &dt1, const datetime &dt2)
{
   //Print("FLHullObj::exec");
   if (isTradingTime(dt1, dt2))
   {
      if (USE_DEBUG) Print("------------------------------");
      if (USE_DEBUG) Print("isTradingTime");
      updateBuffer();
      checkTrade();
   }
   else
   {
      if (USE_DEBUG) Print("TradingTime over");
      checkCloseOrdersByOverTradingTime();
   }
}
void FLHullObj::reset()
{
   order_buy = order_sell = -1;
   m_counter = 1;
   m_inverse = false; 
   
   //order_sell = 123456;
   
}
void FLHullObj::updateBuffer()
{
   if (i_handle < 0) return;
   
   //заполнение массива m_buffer[] текущими значениями индикатора i_handle
   int result = CopyBuffer(i_handle, 0, 0, HULL_BUFF_SIZE, m_buffer);
   if (result < 0)
   {
      Print("WARNING: can't copy buffer.  HULL_BUFF_SIZE=", HULL_BUFF_SIZE);
      return;
   }
   
   //задаём порядок индексации массива m_buffer[] как в MQL4
   ArraySetAsSeries(m_buffer, true);    
}
bool FLHullObj::isTradingTime(const datetime &dt_begin, const datetime &dt_end) const
{
   if (LDateTime::isHolidayNow()) return false;
   datetime dt = TimeLocal();
   return ((dt >= dt_begin) && (dt < dt_end));
}
void FLHullObj::checkCloseOrdersByOverTradingTime()
{
   string err;
   if (order_buy > 0)
   {
      Print("TradingTime is over, closing order_buy .........");
      closeOrder(order_buy, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!");
   }
   if (order_sell > 0)
   {
      Print("TradingTime is over, closing order_sell .........");
      closeOrder(order_sell, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!");
   }
}
double FLHullObj::currentPrice(ENUM_ORDER_TYPE type) const
{
   switch (type)
   {
      case ORDER_TYPE_BUY: return SymbolInfoDouble(m_couple, SYMBOL_ASK);
      case ORDER_TYPE_SELL: return SymbolInfoDouble(m_couple, SYMBOL_BID);
      default: break;
   }
   return -1;
}
void FLHullObj::openOrder(int type, long &ticket, string &err)
{
   err = "";
   ENUM_ORDER_TYPE tt = ENUM_ORDER_TYPE(type);
   m_tradeObj.SetDeviationInPoints(m_slip);
   m_tradeObj.SetExpertMagicNumber(FL_HULL_MAGIC);
   if (USE_DEBUG) Print("open_pos: m_lot=", m_lot);
   
   if (!m_tradeObj.PositionOpen(m_couple, tt, m_lot, currentPrice(tt), 0, 0, comment()))
   {
      StringConcatenate(err, "!m_tradeObj.PositionOpen: ", "  GetLastError=", GetLastError());
      if (USE_DEBUG) m_tradeObj.PrintResult();
      return;   
   }

   MqlTradeResult result;
   m_tradeObj.Result(result);
   if (result.retcode != TRADE_CODE_OK)
   {
      StringConcatenate(err, "opening order error: ", " code=", result.retcode, "  GetLastError=", GetLastError(),
               "  comment=", result.comment);
      return;
   }

   ticket = long(result.order);
   m_counter++;
}
void FLHullObj::closeOrder(long &ticket, string &err)
{
   err = "";
   if (!m_tradeObj.PositionClose(ticket, m_slip))
   {
      StringConcatenate(err, "!m_tradeObj.PositionClose by ticket: ", IntegerToString(ticket), "  GetLastError=", GetLastError());
      return;   
   }
   
   uint code = m_tradeObj.ResultRetcode();
   if (code != TRADE_CODE_OK)
   {
      StringConcatenate(err, "order close error: ", " code=", code, "  GetLastError=", GetLastError());
      return;
   }
   
   ticket = -1;
}
void FLHullObj::checkTrade()
{
   if (USE_DEBUG) Print("FLHullObj::checkTrade():");
   if (buffEmpty())
   {
      Print("WARNING: buffer is empty.");
      return;
   }
   
   if (m_inverse)
   {
      if (changeIHullToUp()) checkTradeUp();
      else if (changeIHullToDown()) checkTradeDown();      
   }
   else
   {
      if (changeIHullToUp()) checkTradeUp_v2();
      else if (changeIHullToDown()) checkTradeDown_v2();   
   }
   
}
void FLHullObj::checkTradeDown()
{
   string err;
   if (order_buy > 0)
   {
      Print("Indigator change trend to: DOWN, closing order_buy .........");
      closeOrder(order_buy, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_buy=", order_buy);
   }
   if (order_sell < 0)
   {
      Print("Indigator change trend to: DOWN, try open order_sell .........");
      openOrder(ORDER_TYPE_SELL, order_sell, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_sell=", order_sell);
   }   
}
void FLHullObj::checkTradeUp()
{
   string err;
   if (order_sell > 0)
   {
      Print("Indigator change trend to: UP, closing order_sell .........");
      closeOrder(order_sell, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_sell=", order_sell);
   }
   if (order_buy < 0)
   {
      Print("Indigator change trend to: UP, try open order_buy .........");
      openOrder(ORDER_TYPE_BUY, order_buy, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_buy=", order_buy);
   }   
}
void FLHullObj::checkTradeDown_v2()
{
   string err;
   if (order_sell > 0)
   {
      Print("Indigator change trend to: DOWN, closing order_sell .........");
      closeOrder(order_sell, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_sell=", order_sell);
   }
   if (order_buy < 0)
   {
      Print("Indigator change trend to: DOWN, try open order_buy .........");
      openOrder(ORDER_TYPE_BUY, order_buy, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_buy=", order_buy);
   }   
}
void FLHullObj::checkTradeUp_v2()
{
   string err;
   if (order_buy > 0)
   {
      Print("Indigator change trend to: UP, closing order_buy .........");
      closeOrder(order_buy, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_buy=", order_buy);
   }
   if (order_sell < 0)
   {
      Print("Indigator change trend to: UP, try open order_sell .........");
      openOrder(ORDER_TYPE_SELL, order_sell, err);
      if (err != "") Print("ERR: ", err);
      else Print("Ok!,  order_sell=", order_sell);
   }   
}
bool FLHullObj::changeIHullToUp() const
{
   if (buffSize() < 5) return false;
   return ((m_buffer[2] < m_buffer[3]) && (m_buffer[1] > m_buffer[2]));
}
bool FLHullObj::changeIHullToDown() const
{
   if (buffSize() < 5) return false;
   return ((m_buffer[2] > m_buffer[3]) && (m_buffer[1] < m_buffer[2]));
}


