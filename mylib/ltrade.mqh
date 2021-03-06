//+------------------------------------------------------------------+
//|                                                       ltrade.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/exenums.mqh>
#include <mylib/base.mqh>
#include <mylib/ltradestructs.mqh>




//класс для совершения торговых операций и проверки их результатов
class LTrade
{
public:
   LTrade::LTrade() :m_slip(1), m_magic(0), last_send_price(-1) {}
   
   inline void setSlip(int x) {m_slip = x;}
   inline void setMagic(int x) {m_magic = x;}

   //принудительно закрывает открытый ордер, во второй параметр записывает код результата
   void orderClose(int, int&);

   //удаляет отложенный ордер, во второй параметр записывает код результата
   void deletePendingOrder(int, int&);
   
   //открывает позицию по текущей цене (применимо только для OP_BUY или OP_SELL)
   //в 1-й параметр записывает тикет открытого ордера   
   //во 2-й параметр записывает код результата открытия
   //3-й параметр это структура описывающая входные данные для открытия позы
   void openPos(int&, int&, const LOpenPosParams&);
   
   //выставляет отложенный ордер с заданными параметрами (применимо только для OP_BUYLIMIT или OP_BUYSTOP или OP_SELLLIMIT или OP_SELLSTOP)
   //в 1-й параметр записывает тикет открытого ордера   
   //во 2-й параметр записывает код результата открытия
   //3-й параметр это структура описывающая входные данные для выставления отложенного ордера
   void setPendingOrder(int&, int&, const LOpenPendingOrder&);

   //проверяет состояние ордера по тикету и записывает необходимую информацию в структуру
   //после выполнения этой функции ордер остается выделенным и можно выполнять различные функции MQL для получения доп. информации 
   void checkOrder(int, LCheckOrderInfo&);
   
   inline double lastSendPrice() const {return last_send_price;}
    
protected:
   int m_slip;
   int m_magic;
   
   //последняя запрошенная цена при открытии позы или выставлении отложенного ордера
   double last_send_price;

};


//////////////////////////////////////////////////////////
//////////////////   CPP CODE   //////////////////////////
//////////////////////////////////////////////////////////
void LTrade::openPos(int &ticket, int &code, const LOpenPosParams &params)
{
   code = 0;
   ticket = 0;
   if (params.invalidCmd())
   {
      Print("LTrade::openPos ERR - invalid pos type");
      code = etOpenOrder;
      return;
   }
   
   int dig = int(MarketInfo(params.couple, MODE_DIGITS));


   //check spread   
   double cur_spread = MarketInfo(params.couple, MODE_SPREAD);
   if (dig%2 > 0) cur_spread /= double(10);
   if (MQValidityData::spreadOver(params.couple, cur_spread))
   {
      code = etSpreadOver;
      Print("LTrade::openPos - spread over "+DoubleToStr(cur_spread)+"   couple "+params.couple);
      return;
   }
   
   double stop = params.stop;
   double profit = params.profit;
   last_send_price = MarketInfo(params.couple, MODE_ASK);
   if (params.type == OP_SELL) last_send_price = MarketInfo(params.couple, MODE_BID);

   int slip = m_slip;
   if (dig%2 > 0) {dig--; slip *= 10;}
   
   if (params.stop_pips)
   {
      if (stop != 0)
      {
         stop = MathAbs(stop)/double(MathPow(10, dig));
         if (params.isBuy()) stop = last_send_price - stop;
         else stop = last_send_price + stop;
      }
      if (profit != 0)
      {
         profit = MathAbs(profit)/double(MathPow(10, dig));
         if (params.isSell()) profit = last_send_price - profit;
         else profit = last_send_price + profit;
      }
   }
   
   Print(params.out());
   Print("    last_send_price=",DoubleToStr(last_send_price, 6));
   
   //попытка открытия позы
   ticket = OrderSend(params.couple, params.type, params.lots, last_send_price, slip, stop, profit, params.comment, m_magic);
   if (ticket <= 0)
   {
      ticket = 0;
      code = etOpenOrder;      
   }
}
void LTrade::setPendingOrder(int &ticket, int &code, const LOpenPendingOrder &params)
{
   code = 0;
   ticket = 0;
   if (params.invalidCmd())
   {
      Print("LTrade::setPendingOrder ERR - invalid pos type");
      code = etOpenNextOrder;
      return;
   }

/*
   double cur_spread = MarketInfo(params.couple, MODE_SPREAD);
   if (MQValidityData::spreadOver(params.couple, cur_spread))
   {
      code = etSpreadOver;
      return;
   }
   */
   
   int slip = 0;
   int dig = int(MarketInfo(params.couple, MODE_DIGITS));
   if (dig%2 > 0) {dig--;}

   //calc price
   last_send_price = params.price;
   if (params.d_price > 0)
   {
      //текущая рыночная цена пары
      double cur_price = MarketInfo(params.couple, MODE_ASK);
      if (params.isSell()) cur_price = MarketInfo(params.couple, MODE_BID);
      
      if (params.price > 0) cur_price = params.price;
      double dp = double(params.d_price)/double(MathPow(10, dig));
      if (params.type == OP_BUYSTOP || params.type == OP_SELLLIMIT) last_send_price = cur_price + dp;
      else last_send_price = cur_price - dp;
   }
   
   //calc stops
   double stop = params.stop;
   double profit = params.profit;
   if (params.stop_pips)
   {
      if (stop != 0)
      {
         stop = MathAbs(stop)/double(MathPow(10, dig));
         if (params.isBuy()) stop = last_send_price - stop;
         else stop = last_send_price + stop;
      }
      if (profit != 0)
      {
         profit = MathAbs(profit)/double(MathPow(10, dig));
         if (params.isSell()) profit = last_send_price - profit;
         else profit = last_send_price + profit;
      }
   }

   //calc expiration
   datetime expiration = params.expiration;
   if (params.d_expiration > 0)
   {
      if (params.expiration > 0) expiration += params.d_expiration;
      else expiration = TimeCurrent() + params.d_expiration;
   }

   //попытка открытия отложенного ордера
   ticket = OrderSend(params.couple, params.type, params.lots, last_send_price, slip, stop, profit, params.comment, m_magic, expiration);
   if (ticket <= 0)
   {
      ticket = 0;
      code = etOpenNextOrder;      
   }
}
void LTrade::deletePendingOrder(int ticket, int &code)
{
   code = 0;
   LCheckOrderInfo info;
   checkOrder(ticket, info);
   
   if (info.isError())
   {
      Print("LTrade::deletePendingOrder ERR="+IntegerToString(info.err_code));
      code = etDeleteNextOrder;
      return;
   }

   if (!info.isPengingNow())
   {
      Print("LTrade::deletePendingOrder ERR="+IntegerToString(info.err_code)+", order is not pending!");
      code = etDeleteNextOrder;
      return;   
   }

   if (!OrderDelete(ticket)) 
      code = etDeleteNextOrder;
}
void LTrade::orderClose(int ticket, int &code)
{
   code = 0;
   LCheckOrderInfo info;
   checkOrder(ticket, info);
   
   if (info.isError())
   {
      Print("LTrade::orderClose ERR="+IntegerToString(info.err_code));
      code = etCloseOrder;
      return;
   }
   
   if (!info.isOpened())
   {
      Print("LTrade::orderClose ERR="+IntegerToString(info.err_code)+",  order not opened: "+IntegerToString(ticket));
      code = etCloseOrder;
      return;   
   }
   
   double lots = OrderLots();
   int type = OrderType();
   string v = OrderSymbol();
   double price = MarketInfo(v, MODE_ASK);
   if (type == OP_BUY) price = MarketInfo(v, MODE_BID);
   
   int slip = m_slip;
   int dig = int(MarketInfo(v, MODE_DIGITS));
   if (dig%2 > 0) {dig--; slip *= 10;}
   
   if (!OrderClose(ticket, lots, price, slip))
      code = etCloseOrder;
}
void LTrade::checkOrder(int ticket, LCheckOrderInfo &info)
{
   info.resetAll();
   if (ticket <= 0) {info.err_code = -11; return;}
   if (!OrderSelect(ticket, SELECT_BY_TICKET)) {info.err_code = -12; return;}
   
   //определяем текущий статус ордера
   int order_type = OrderType();
   if (OrderCloseTime() == 0) //ордер в работе
   {
      switch(order_type)
      {
         case OP_BUY:
         case OP_SELL: {info.status = 1; break;}

         case OP_BUYLIMIT:
         case OP_BUYSTOP:
         case OP_SELLLIMIT:
         case OP_SELLSTOP: {info.status = 2; break;}

         default: {info.err_code = -13; return;}
      }
   }
   else //ордер в истории
   {
      switch(order_type)
      {
         case OP_BUY:
         case OP_SELL: {info.status = 11; break;}

         case OP_BUYLIMIT:
         case OP_BUYSTOP:
         case OP_SELLLIMIT:
         case OP_SELLSTOP: {info.status = 12; break;}

         default: {info.err_code = -13; return;}
      }   
   }
   
   //определяем результаты работы ордера (ордер должен быть закрытым и находится в истории)
   if (info.isFinished())
   {
      info.result = OrderProfit();
      info.swap = OrderSwap();
      info.commision = OrderCommission();
      info.lots = OrderLots();
      
      int dig = int(MarketInfo(OrderSymbol(), MODE_DIGITS));
      double d_price = MathAbs(OrderOpenPrice() - OrderClosePrice());
      info.result_pips = d_price * double(MathPow(10, dig));
       
      if ((dig % 2) > 0) info.result_pips /= double(10);
      if (info.isLoss()) info.result_pips *= (-1);      
      
      //определяем закрылся ли ордер по стопам
      string s = OrderComment();
      string s_tp = "[tp]";
      string s_sl = "[sl]";
      info.closed_by_takeprofit = (StringFind(s, s_tp) > 0);
      info.closed_by_stoploss = (StringFind(s, s_sl) > 0);
      ////////////////НЕОБХОДИМО ПРОВЕРИТЬ РАБОТАЕТ ЛИ ЭТО ПРИ СКРЫТОМ СТОЛБЦЕ КОМЕНТОВ !!!!!!///////////////////////
   }
}





