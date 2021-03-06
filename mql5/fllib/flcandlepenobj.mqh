//+------------------------------------------------------------------+
//|                                               flcandlepenobj.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+


#include <mylib/ltradeintervalchecker.mqh>
#include <Trade/Trade.mqh>

#define  FL_OBJ_MAGIC      126
#define  TRADE_CODE_OK     TRADE_RETCODE_DONE
#define  USE_DEBUG         false
#define  MAX_TRADE_ERRS    3 //максимальное количество повторных неудачных попыток какой-либо торговой операции



/////////// FLCandlePenObj ///////////////////////////
class FLCandlePenObj
{
public:
   enum CP_Stage {
                     cpStarted = 330,           //советник только что стартовал, состояние сброшено
                     cpWaitNextCandle,          //ожидание появления новой свечи
                     cpNeedCloseOrders,         //открылась новая свеча, необходимо закрыть все открытые позы и\или удалить отложенные ордера
                     cpNeedPlaceOrders,         //открылась новая свеча, необходимо выставить ордера 
                     cpMonitoringPlacedOrders,  //выставлены отложенные ордера, теперь требуется постоянно мониторить их состояние, а также попутно следить за появлением новой свечи
                     cpNeedCloseBuy,            //ситуация когда сначала сработал ордер buy, затем цена ушла вниз и сработал ордер sell, значит необходимо удалить открытую позу buy
                     cpNeedCloseSell,           //ситуация когда сначала сработал ордер sell, затем цена ушла вверх и сработал ордер buy, значит необходимо удалить открытую позу sell
                     
                  };
                  
   enum CP_OrdersState {
                           cpPending = 430,        //ордер является отложенным
                           cpOpened,               //ордер сработал по заданной цене и в данный момент является открытой позицией
                           cpCanceled,             //ордер находится в истории, является отложенным-удаленным
                           cpClosed,               //ордер находится в истории, является закрытой позицией
                           cpPendingUnknownState,  //ордер является отложенным, но его текущее состояние неизвестно
                           cpHistoryUnknownState,  //ордер находится в истории, но его состояние неизвестно
                           cpUnfinded = -1,        //ордер с таким тикетом не найден
                       };
                     

   FLCandlePenObj(const LTradeIntervalChecker *tc, string couple, double volume, int tf) 
      :t_checker(tc), m_couple(couple), m_lot(volume), m_period(tf) {reset();}
   
   void exec(); //основная функция от куда вызывается весь алгоритм класса
   
protected:
   const LTradeIntervalChecker *t_checker;
   CTrade m_tradeObj;   

   void reset();
   void waitNextCandle(); //expert startet, wait next candle
   void tryPlaceOrders(); //открылась новая свеча, необходимо выставить новую пару ордеров
   void monitoringOrders(); //после выставления отложенных ордеров требуется отслеживать их состояние
   void tryCloseOrders(); //время текущей свечи вышло, необходимо закрыть и удалить открытые ордера
   
   void placeOrders(double&, double&); //выставить ордера по заданным ценам
   void calcOpenPrices(double&, double&); //определить цены открытия для выставления отложенных ордеров
   void removeOrder(long&); //закрыть/удалить позу/ордер
   void checkPendingState(); //проверить текущее состояние отложенных ордеров на предмет когда сработали оба поочередно
   void tryCloseBuy();
   void tryCloseSell();
   
   inline bool tradeErrsOver() const {return (m_errCounter >= MAX_TRADE_ERRS);}
   inline void changeStage(int v) {m_stage = v; m_errCounter = 0;}
   
   //trade funcs
   void placeOrder(const double&, int, long&); //выставить отложенный ордер заданного типа
   int getOrderState(const long&) const; //получить текущее состояние заданного ордера
   void closeOrder(long&); //закрыть открытую позу
   void cancelOrder(long&); //отменить отложенный ордер
   
private:   
   
   //state
   int m_stage;
   datetime last_candle_time;
   long order_sell;
   long order_buy;
   int m_counter; //счетчик открытий поз
   int m_errCounter; // счетчик повторных неудачных попыток какой-либо торговой операции

   //input params   
   string m_couple;
   double m_lot;
   int m_period;

   
};
void FLCandlePenObj::exec()
{
   Print("FLCandlePenObj::exec()  stage = ", m_stage);
   switch (m_stage)
   {
      case cpStarted:
      {
         last_candle_time = iTime(m_couple, ENUM_TIMEFRAMES(m_period), 0);
         changeStage(cpWaitNextCandle);
         break;
      }
      case cpWaitNextCandle:
      {
         waitNextCandle();
         break;
      }
      case cpNeedPlaceOrders:
      {
         tryPlaceOrders();
         break;
      }
      case cpMonitoringPlacedOrders:
      {
         monitoringOrders();
         break;
      }
      case cpNeedCloseOrders:
      {
         tryCloseOrders();
         break;
      }
      case cpNeedCloseBuy:
      {
         tryCloseBuy();
         break;
      }
      case cpNeedCloseSell:
      {
         tryCloseSell();
         break;
      }
      default: 
      {
         Print("FLCandlePenObj::exec() WARNING: unknown stage ", m_stage);
         break;
      }
   }
}
void FLCandlePenObj::calcOpenPrices(double &for_buy, double &for_sell)
{
   double cur_ask = SymbolInfoDouble(m_couple, SYMBOL_ASK);
   double cur_bid = SymbolInfoDouble(m_couple, SYMBOL_BID);
   for_buy = iHigh(m_couple, ENUM_TIMEFRAMES(m_period), 1);
   for_sell = iLow(m_couple, ENUM_TIMEFRAMES(m_period), 1);
   
   double pips_size = SymbolInfoDouble(m_couple, SYMBOL_TRADE_TICK_SIZE); //  1 / pow(10, digist)
   int min_pips_offset = (int)SymbolInfoInteger(m_couple, SYMBOL_TRADE_STOPS_LEVEL);
   double x = pips_size * (min_pips_offset + 1);
   if ((for_buy - cur_ask) < x) for_buy = cur_ask + x;
   if ((cur_bid - for_sell) < x) for_sell = cur_bid - x;
}
void FLCandlePenObj::reset()
{
   order_buy = order_sell = -1;
   m_counter = m_errCounter = 0;
   m_stage = cpStarted;
   last_candle_time = 0;
}
void FLCandlePenObj::waitNextCandle()
{
   datetime cur_dt = iTime(m_couple, ENUM_TIMEFRAMES(m_period), 0);
   if (last_candle_time != cur_dt)
   {
      last_candle_time = cur_dt;
      changeStage(cpNeedPlaceOrders);
   }
}
void FLCandlePenObj::tryPlaceOrders()
{
   if (!t_checker.isTradingTime())
   {
      changeStage(cpWaitNextCandle);
      return;
   }
   if (tradeErrsOver())
   {
      changeStage(cpMonitoringPlacedOrders);
      Print("FLCandlePenObj::tryPlaceOrders() ERR: trade errs(", m_errCounter, ")  is over LIMIT");
      return;   
   }

   double buy_price = 0;
   double sell_price = 0;
   calcOpenPrices(buy_price, sell_price);   
   placeOrders(buy_price, sell_price);
}
void FLCandlePenObj::placeOrders(double &buy_price, double &sell_price)
{
   if (order_sell < 0)
   {
      placeOrder(sell_price, ORDER_TYPE_SELL_STOP, order_sell);
      if (order_sell < 0) m_errCounter++;
   }
   if (order_buy < 0)
   {
      placeOrder(buy_price, ORDER_TYPE_BUY_STOP, order_buy);
      if (order_buy < 0) m_errCounter++;   
   }
   
   if (order_sell > 0 && order_buy > 0) 
      changeStage(cpMonitoringPlacedOrders);
}
void FLCandlePenObj::monitoringOrders()
{
   if (order_sell < 0 && order_buy < 0) //мониторить нечего, ждем следующую свечу
   {
      changeStage(cpWaitNextCandle);
      return;
   }

   //check next candle
   datetime cur_dt = iTime(m_couple, ENUM_TIMEFRAMES(m_period), 0);
   if (last_candle_time != cur_dt)
   {
      last_candle_time = cur_dt;
      changeStage(cpNeedCloseOrders);
      return;
   }
   
   checkPendingState();
}
void FLCandlePenObj::checkPendingState()
{
   if (order_sell < 0 || order_buy < 0) return;
   
   int state_sell = getOrderState(order_sell);
   datetime dt_sell = datetime(PositionGetInteger(POSITION_TIME));
   int state_buy = getOrderState(order_buy);
   datetime dt_buy = datetime(PositionGetInteger(POSITION_TIME));
   
   if (state_sell == cpOpened && state_buy == cpOpened)
   {
      if (dt_sell > dt_buy) changeStage(cpNeedCloseBuy);
      else if (dt_sell < dt_buy) changeStage(cpNeedCloseSell);
      else Print("FLCandlePenObj::checkPendingState() WARNING: dt_sell == dt_buy");
   }
}
void FLCandlePenObj::tryCloseOrders()
{
   if (tradeErrsOver())
   {
      changeStage(cpWaitNextCandle);
      order_buy = order_sell = -1;
      Print("FLCandlePenObj::tryCloseOrders() ERR: trade errs(", m_errCounter, ")  is over LIMIT");
      return;   
   }

   if (order_sell > 0)
   {
      removeOrder(order_sell);
      if (order_sell > 0) m_errCounter++;
   }
   if (order_buy > 0)
   {
      removeOrder(order_buy);
      if (order_buy > 0) m_errCounter++;   
   }
   
   if (order_sell < 0 && order_buy < 0) //все закрыто, переходим к выставлению новой пары ордеров
   {
      changeStage(cpNeedPlaceOrders);
      return;
   }
}
void FLCandlePenObj::removeOrder(long &ticket)
{
   int state = getOrderState(ticket);
   switch (state)
   {
      case cpOpened: {closeOrder(ticket); break;}
      case cpPending: {cancelOrder(ticket); break;}
      default:
      {
         ticket = -1;
         Print("FLCandlePenObj::removeOrder WARNING: unknown order state ", state);
         break;
      }
   }
}
void FLCandlePenObj::tryCloseBuy()
{
   if (tradeErrsOver())
   {
      order_buy = -1;
      changeStage(cpMonitoringPlacedOrders);
      Print("FLCandlePenObj::tryCloseBuy() ERR: trade errs(", m_errCounter, ")  is over LIMIT");
      return;
   }
   
   closeOrder(order_buy);
   if (order_buy > 0) {m_errCounter++; return;}
       
   changeStage(cpMonitoringPlacedOrders);
}
void FLCandlePenObj::tryCloseSell()
{
   if (tradeErrsOver())
   {
      order_sell = -1;
      changeStage(cpMonitoringPlacedOrders);
      Print("FLCandlePenObj::tryCloseSell() ERR: trade errs(", m_errCounter, ")  is over LIMIT");
      return;
   }
   
   closeOrder(order_sell);
   if (order_sell > 0) {m_errCounter++; return;}
       
   changeStage(cpMonitoringPlacedOrders);
}




//////////////////////// TRADE FUNCTION ///////////////////////////
int FLCandlePenObj::getOrderState(const long &ticket) const
{
   if (ticket <= 0) return cpUnfinded;
   
   long property = -1;
   if (OrderSelect(ticket))
   {
      property = OrderGetInteger(ORDER_STATE);
      if (property == ORDER_STATE_PLACED) return cpPending;
      if (property == ORDER_STATE_CANCELED) return cpCanceled;
      return cpPendingUnknownState;
   }
   if (PositionSelectByTicket(ticket))
   {
      return cpOpened;
   }
   if (HistoryOrderSelect(ticket))
   {
      property = HistoryOrderGetInteger(ticket, ORDER_STATE);
      if (property == ORDER_STATE_FILLED) return cpClosed;
      if (property == ORDER_STATE_CANCELED) return cpCanceled;
      return cpHistoryUnknownState;
   }
   return cpUnfinded;
}
void FLCandlePenObj::placeOrder(const double &price, int type, long &ticket)
{
   ticket = -1;
   bool ok = false;
   switch (type)
   {
      case ORDER_TYPE_BUY_STOP:
      {
         ok = m_tradeObj.BuyStop(m_lot, price, m_couple);
         break;      
      }
      case ORDER_TYPE_SELL_STOP:
      {
         ok = m_tradeObj.SellStop(m_lot, price, m_couple);
         break;      
      }
      default:
      {
         Print("FLCandlePenObj::placeOrder ERR: invalid place type ", type);
         return;
      }   
   }

   if (!ok) return;
   
   //check result operation
   MqlTradeResult result;
   m_tradeObj.Result(result);
   ticket = long(result.order);
   m_counter++;
}
void FLCandlePenObj::closeOrder(long &ticket)
{
   int spread = (int)SymbolInfoInteger(m_couple, SYMBOL_SPREAD);
   if (spread == 0) spread = 20;
   
   string err;
   bool ok = m_tradeObj.PositionClose(ticket, spread);
   if (!ok)
   {
      err = "";
      StringConcatenate(err, "!m_tradeObj.PositionClose by ticket: ", IntegerToString(ticket), "  GetLastError=", GetLastError());
      Print("FLCandlePenObj::closeOrder ERROR: ", err);
      return;
   }
   
   uint code = m_tradeObj.ResultRetcode();
   if (code != TRADE_CODE_OK)
   {
      err = "";
      StringConcatenate(err, "order close error: ", " result_code=", code, "  GetLastError=", GetLastError());
      Print("FLCandlePenObj::closeOrder ERROR: ", err);
      return;
   }

   ticket = -1;
}
void FLCandlePenObj::cancelOrder(long &ticket)
{
   bool ok = m_tradeObj.OrderDelete(ticket);
   if (!ok)
   {
      string err = "";
      StringConcatenate(err, "order delete error: ", "  GetLastError=", GetLastError());
      Print("FLCandlePenObj::cancelOrder ERROR: ", err);
      return;
   }
   
   ticket = -1;
}

