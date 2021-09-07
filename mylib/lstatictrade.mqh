//+------------------------------------------------------------------+
//|                                                 lstatictrade.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <fllib/ltradestructs.mqh>
#include <fllib/lprice.mqh>


class LStaticTrade
{
public:
   //проверяет состояние ордера по тикету и записывает необходимую информацию в структуру
   //после выполнения этой функции ордер остается выделенным и можно выполнять различные функции MQL для получения доп. информации 
   static void checkOrderState(int ticket, LCheckOrderInfo&);

   //принудительно закрывает открытый ордер, во второй параметр записывает код результата
   // -1: некорретктный тикет
   // -2: ордер уже в истории 
   // -3: ордер является отложенным
   // -4: ошибка при закрытии ордера, подробнее GetLastError()
   //  0: успех
   static void tryOrderClose(int, int&, int slip = 10);


   //открывает позицию по текущей цене (применимо только для OP_BUY или OP_SELL)
   //в 1-й параметр записывает тикет открытого ордера (если откроется)
   //второй параметр это структура описывающая входные данные для открытия позы, там же будет код результата
   // 0 - успех
   //-8 - некорректное значение type
   //-7 - некорректное значение lots
   //-6 - некорректное значение couple
   //-1 - ошибка при открытии ордера, подробнее GetLastError()
   static void tryOpenPos(int&, LOpenPosParams&);


};
//---------------------------------------------------------------
//---------------------------------------------------------------
//---------------------------------------------------------------
//---------------------------------------------------------------
void LStaticTrade::tryOpenPos(int &ticket, LOpenPosParams &params)
{
   ticket = -1;
   if (params.invalidCouple()) {params.err_code = -6; return;}
   if (params.invalidLotSize()) {params.err_code = -7; return;}
   if (params.invalidCmd()) {params.err_code = -8; return;}
   
   double price = MarketInfo(params.couple, MODE_ASK);
   if (params.isSell()) price = MarketInfo(params.couple, MODE_BID);
   
   double sl = params.stop;
   double tp = params.profit;
   if (params.stop_pips) //необходимо пункты перевести в значения цены
   {
      int signum = (params.isSell() ? -1 : 1);
      if (params.stop > 0) 
         sl = LPrice::addPipsPrice(price, int(params.stop)*signum*(-1), params.couple);
      if (params.profit > 0) 
         tp = LPrice::addPipsPrice(price, int(params.profit)*signum, params.couple);
   }

   //попытка открытия позы
   ticket = OrderSend(params.couple, params.type, params.lots, price, params.slip, sl, tp, params.comment, params.magic);
   if (ticket <= 0)
   {
      ticket = -1;
      params.err_code = -1;      
   }
}
void LStaticTrade::checkOrderState(int ticket, LCheckOrderInfo &info)
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
void LStaticTrade::tryOrderClose(int ticket, int &code, int slip)
{
   code = 0;
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(ticket, info);
   
   if (info.isError()) {code = -1; return;}   
   if (info.isHistory()) {code = -2; return;}   
   if (info.isPengingNow()) {code = -3; return;}   
   
   double lot = OrderLots();
   int type = OrderType();
   string v = OrderSymbol();
   double price = MarketInfo(v, MODE_ASK);
   if (type == OP_BUY) price = MarketInfo(v, MODE_BID);
   
   if (!OrderClose(ticket, lot, price, slip)) code = -4;
}

