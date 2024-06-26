//+------------------------------------------------------------------+
//|                                                 lstatictrade.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/trade/ltradestructs.mqh>
#include <mylib/trade/lpriceoperations.mqh>


class LStaticTrade
{
public:
   //проверяет состояние ордера по тикету и записывает необходимую информацию в структуру
   //после выполнения этой функции ордер остается выделенным и можно выполнять различные функции MQL для получения доп. информации 
   static void checkOrderState(int ticket, LCheckOrderInfo&);

   //открывает позицию по текущей цене (применимо только для OP_BUY или OP_SELL)
   //в 1-й параметр записывает тикет открытого ордера (если откроется)
   //второй параметр это структура описывающая входные данные для открытия позы, там же будет код результата
   // 0 - успех
   //-8 - некорректное значение type
   //-7 - некорректное значение lots
   //-6 - некорректное значение couple
   //-1 - ошибка при открытии ордера, подробнее GetLastError()
   static void tryOpenPos(int&, LOpenPosParams&);
   
   //выставляет отложенный ордер с заданными параметрами (применимо только для OP_BUYLIMIT, OP_BUYSTOP, OP_SELLLIMIT, OP_SELLSTOP)
   //в 1-й параметр записывает тикет открытого ордера   
   //2-й параметр это структура описывающая входные данные для выставления отложенного ордера, там же будет код результата
   // 0 - успех
   //-8 - некорректное значение type
   //-7 - некорректное значение lots
   //-6 - некорректное значение couple
   //-1 - ошибка при открытии ордера, подробнее GetLastError()
   static void setPendingOrder(int&, LOpenPendingOrder&);   
   
   //принудительно закрывает открытый ордер, во второй параметр записывает код результата
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер уже в истории 
   // -3: ордер является отложенным
   // -4: ошибка при закрытии ордера, подробнее GetLastError()
   //  0: успех
   static void tryOrderClose(int, int&, int slip = 10);
   
   //принудительно закрывает часть открытого ордер, во второй параметр записывает код результата
   // в второй параметр запишется новый тикет, а так же код выполнения    
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер уже в истории 
   // -3: ордер является отложенным
   // -4: ошибка при закрытии ордера, подробнее GetLastError()
   // -5: новый ордер не найден
   //  0: успех
   static void tryOrderClosePart(int ticket, LCloseOrderPart&);
   

   //удаляет отложенный ордер, во второй параметр записывает код результата
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер уже в истории 
   // -3: ордер не является отложенным
   // -4: ошибка при удалении ордера, подробнее GetLastError()
   //  0: успех
   static void deletePendingOrder(int, int&);
   
   
   //проверяет цену и подтягивает stoploss при необходимости, (takeprofit не меняется в любом случае)
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер не является открытым
   // -3: ошибка при модификации ордера, подробнее GetLastError()
   //  0: успех, ордер был модифицирован
   //  1: цена не ушла на нужное количество пунктов, модификация не требуется
   // примечание: если до этого stoploss не был установлен, то теперь он сразу установится на traling_pips
   static void tryTraling(int ticket, int traling_pips, int &err_code); // traling_pips > 0

   //признак того что терминал 5-ти знаковый
   static bool isDigist5(string v) {int x = int(MarketInfo(v, MODE_DIGITS)); return (x == 3 || x == 5);} 

};
//---------------------------------------------------------------
//---------------------------------------------------------------
//---------------------------------------------------------------
//---------------------------------------------------------------
void LStaticTrade::tryTraling(int ticket, int traling_pips, int &err_code)
{
   err_code = 0;
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(ticket, info);
   if (info.isError() || traling_pips <= 0) {err_code = -1; return;}  
   if (!info.isOpened()) {err_code = -2; return;}   
   
   string v = OrderSymbol();
   double sl = OrderStopLoss();
   double cur_price = MarketInfo(v, MODE_ASK);
   if (OrderType() == OP_BUY) cur_price = MarketInfo(v, MODE_BID);
   
   int noise_pips = 3; //на столько пипсов должна цена быть выше traling_pips
   if (isDigist5(v)) noise_pips *= 10;
   
   int d_sl = (sl > 0) ? MathAbs(LPrice::pricesDiff(cur_price, sl, v)) : 0;
   if (d_sl > 0 && d_sl < (traling_pips + noise_pips)) {err_code = 1; return;} 
   
   //calc new stoploss
   if (OrderType() == OP_SELL) sl = LPrice::addPipsPrice(cur_price, traling_pips, v);
   else  sl = LPrice::addPipsPrice(cur_price, -1*traling_pips, v);
   
   //try modif order
   if (!OrderModify(ticket, 0, sl, OrderTakeProfit(), 0)) err_code = -3;
}
void LStaticTrade::tryOrderClosePart(int ticket, LCloseOrderPart &params)
{
   params.err_code = 0;
   params.new_ticket = -1;
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(ticket, info);
   
   if (info.isError()) {params.err_code = -1; return;}   
   if (info.isHistory()) {params.err_code = -2; return;}   
   if (info.isPengingNow()) {params.err_code = -3; return;}   
   
   int type = OrderType();
   string v = OrderSymbol();
   double price = MarketInfo(v, MODE_ASK);
   if (type == OP_BUY) price = MarketInfo(v, MODE_BID);
   if (!OrderClose(ticket, params.lot_part, price, params.slip)) params.err_code = -4;
   
   //find new ticket
   int n = OrdersTotal();
   string s_ticket = IntegerToString(ticket);   
   for (int i=0; i<n; i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      string s = OrderComment();
      if (StringFind(s, s_ticket) < 0) continue;
      
      params.new_ticket = OrderTicket();
      break;
   }
   
   if (params.new_ticket < 0) params.err_code = -5;
}
void LStaticTrade::setPendingOrder(int &ticket, LOpenPendingOrder &params)
{
   ticket = -1;
   if (params.invalidCouple()) {params.err_code = -6; return;}
   if (params.invalidLotSize()) {params.err_code = -7; return;}
   if (params.invalidCmd()) {params.err_code = -8; return;}
   
   double cur_price = MarketInfo(params.couple, MODE_ASK);
   if (params.isSell()) cur_price = MarketInfo(params.couple, MODE_BID);

   
   //calc open price
   double open_price = params.price;
   if (params.d_price > 0)
   {      
      int dpips = params.d_price;
      switch (params.type)
      {
         case OP_SELLLIMIT:
         case OP_BUYSTOP: {dpips = MathAbs(dpips); break;} 
         case OP_SELLSTOP:
         case OP_BUYLIMIT: {dpips = -1*MathAbs(dpips); break;} 
         default: break;
      }
      
      if (params.price == 0) open_price = LPrice::addPipsPrice(cur_price, dpips, params.couple);
      else open_price = LPrice::addPipsPrice(params.price, dpips, params.couple);
   }
   else if (params.dev_price > 0)
   {
      double d = params.dev_price;
      switch (params.type)
      {
         case OP_SELLLIMIT:
         case OP_BUYSTOP: {d = MathAbs(d); break;} 
         case OP_SELLSTOP:
         case OP_BUYLIMIT: {d = -1*MathAbs(d); break;} 
         default: break;
      }
      
      if (params.price == 0) open_price = LPrice::addPriceDeviation(cur_price, d, params.couple);
      else open_price = LPrice::addPriceDeviation(params.price, d, params.couple);
   }
     
   //calc stops
   double sl = params.stop;
   double tp = params.profit;
   if (params.stop_pips) //необходимо пункты перевести в значения цены
   {
      int signum = (params.isSell() ? -1 : 1);
      if (params.stop > 0) 
         sl = LPrice::addPipsPrice(open_price, int(params.stop)*signum*(-1), params.couple);
      if (params.profit > 0) 
         tp = LPrice::addPipsPrice(open_price, int(params.profit)*signum, params.couple);
   }

   //попытка открытия отложенного ордера
   Print("set pending order: open_price=", open_price, "  sl=", sl, "  tp=", tp);
   ticket = OrderSend(params.couple, params.type, params.lots, open_price, 10, sl, tp, params.comment, params.magic, params.getRealExpiration());
   if (ticket <= 0)
   {
      ticket = -1;
      params.err_code = -1;      
   }
}
void LStaticTrade::deletePendingOrder(int ticket, int &code)
{
   code = 0;
   LCheckOrderInfo info;
   checkOrderState(ticket, info);
   
   if (info.isError()) {code = -1; return;}
   if (info.isHistory()) {code = -2; return;}
   if (!info.isPengingNow()) {code = -3; return;}
   
   if (!OrderDelete(ticket)) code = -4;
}
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
      
            
      //результирующее количество пунктов (знаковость терминала влияет на значение)
      info.result_pips = MathAbs(LPrice::pricesDiff(OrderOpenPrice(), OrderClosePrice(), OrderSymbol()));
      if (info.isLoss()) info.result_pips *= (-1);      
      
      
      
      //определяем закрылся ли ордер по стопам
      /* version 1
      string s = OrderComment();
      string s_tp = "[tp]";
      string s_sl = "[sl]";
      info.closed_by_takeprofit = (StringFind(s, s_tp) > 0);
      info.closed_by_stoploss = (StringFind(s, s_sl) > 0);
      ////////////////НЕОБХОДИМО ПРОВЕРИТЬ РАБОТАЕТ ЛИ ЭТО ПРИ СКРЫТОМ СТОЛБЦЕ КОМЕНТОВ !!!!!!///////////////////////
      */
      
      // version 2
      int k = (isDigist5(OrderSymbol()) ? 10 : 1);
      if (OrderTakeProfit() > 0 && info.isWin())
      {
         int tp_pips = MathAbs(LPrice::pricesDiff(OrderOpenPrice(), OrderTakeProfit(), OrderSymbol()));
         info.closed_by_takeprofit = (info.result_pips >= (tp_pips - k));
      }
      if (OrderStopLoss() > 0 && info.isLoss())
      {
         int sl_pips = MathAbs(LPrice::pricesDiff(OrderOpenPrice(), OrderStopLoss(), OrderSymbol()));
         info.closed_by_stoploss = (MathAbs(info.result_pips) >= (sl_pips - k));
      }
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

