//+------------------------------------------------------------------+
//|                                                 lstatictrade.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/trade/ltradestructs.mqh>



//класс для проведения торговых операци
class LStaticTrade
{
public:
   //проверяет состояние ордера по входному тикету(элемент структуры LCheckOrderInfo) и записывает необходимую информацию в структуру, 
   //после выполнения этой функции ордер остается выделенным(OrderSelect) и можно выполнять различные функции MQL для получения доп. информации .
   //в случае возникновения ошибки при выполнении этой функции, код запишется в переменную LCheckOrderInfo.err_code   
   static void checkOrderState(LCheckOrderInfo&);

   //открывает позицию по текущей цене (применимо только для OP_BUY или OP_SELL)
   //в LOpenPosParams.ticket  записывает тикет открытого ордера (если откроется), иначе -1
   //параметр это структура описывающая входные данные для открытия позы, там же будет код результата err_code
   //в случае возникновения ошибки при выполнении этой функции, код запишется в переменную LOpenPosParams.err_code   
   // 0 - успех
   //-8 - некорректное значение type
   //-7 - некорректное значение lots
   //-6 - некорректное значение couple
   //-1 - ошибка при открытии ордера, подробнее GetLastError()
   static void tryOpenPos(LOpenPosParams&);
   
   //выставляет отложенный ордер с заданными параметрами (применимо только для OP_BUYLIMIT, OP_BUYSTOP, OP_SELLLIMIT, OP_SELLSTOP)
   //в LOpenPendingOrderParams.ticket  записывает тикет открытого ордера (если откроется), иначе -1
   //параметр это структура описывающая входные данные для открытия позы, там же будет код результата err_code
   //в случае возникновения ошибки при выполнении этой функции, код запишется в переменную LOpenPendingOrderParams.err_code   
   // 0 - успех
   //-8 - некорректное значение type
   //-7 - некорректное значение lots
   //-6 - некорректное значение couple
   //-1 - ошибка при открытии ордера, подробнее GetLastError()
   static void setPendingOrder(LOpenPendingOrderParams&);   
   
   //принудительно закрывает открытую позу, во второй параметр записывает код результата
   //если указан LCloseOrderParams.lot_size > 0 то закрывается только часть объема позы, в этом случае переменная LCloseOrderParams.ticket переписывается новым значением.
   //параметр это структура описывающая входные данные, тикет закрываемой  позы это элемент структуры, там же будет код результата err_code
   //в случае возникновения ошибки при выполнении этой функции, код запишется в переменную LCloseOrderParams.err_code   
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер уже в истории 
   // -3: ордер является отложенным
   // -4: ошибка при закрытии ордера, подробнее GetLastError()
   // -5: новый ордер не найден (эта ситуация возможна при LCloseOrderParams.lot_size > 0)
   //  0: успех
   static void tryClosePos(LCloseOrderParams&);
   
   
   //удаляет отложенный ордер, тикет которого это элемент входной структуры LCloseOrderParams.
   //параметр это структура описывающая входные данные, там же будет код результата err_code
   //в случае возникновения ошибки при выполнении этой функции, код запишется в переменную LCloseOrderParams.err_code   
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер уже в истории 
   // -3: ордер не является отложенным
   // -4: ошибка при удалении ордера, подробнее GetLastError()
   //  0: успех
   static void deletePendingOrder(LCloseOrderParams&);
   
   
   //проверяет цену и подтягивает stoploss при необходимости, (takeprofit не меняется в любом случае)
   //тралинг срабатывает только если текущий профит положителен.
   //тралинг срабатывает только на открытой позе.
   //параметр это структура описывающая входные данные где нужно указать параметры sl , там же будет код результата err_code
   //в случае возникновения ошибки при выполнении этой функции, код запишется в переменную LCloseOrderParams.err_code   
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер не является открытой позой
   // -3: ошибка при модификации ордера, подробнее GetLastError()
   //  0: успех, ордер был модифицирован
   //  1: цена не ушла на нужное количество пунктов, модификация не требуется
   //  2: размер тралинга не задан
   // примечание: если до этого stoploss не был установлен, то теперь установится на traling_pips
   static void tryTraling(LOrderModifyParams&);


   //устанавливает/обновляет значения stoploss и takeprofit у указанной открытой позиции
   //во входной структуре необходимо указать тикет меняемой позы и новые значения stoploss/takeprofit либо -1 если менять не планируется
   //параметр это структура описывающая входные данные, там же будет код результата err_code
   // -1: некорретктный тикет (не найден и т.п.)
   // -2: ордер не является открытой позой
   // -3: ошибка при модификации ордера, подробнее GetLastError()
   //  0: успех, ордер был модифицирован   
   static void trySetSlTp(LOrderModifyParams&);

};
//---------------------------------------------------------------
//---------------------------------------------------------------
//---------------------------------------------------------------
//---------------------------------------------------------------
void LStaticTrade::tryTraling(LOrderModifyParams &params)
{
   if (params.invalidTicket()) {params.err_code = -1; return;}
   if (!params.tralingOn())  {params.err_code = 2; return;}

   LCheckOrderInfo info(params.ticket);
   LStaticTrade::checkOrderState(info);
   if (info.isError())        {params.err_code = -1; return;}
   if (!info.isOpened())      {params.err_code = -2; return;}

   int sign = ((OrderType() == OP_BUY) ? 1 : -1); 

   string v = OrderSymbol();
   double sl = OrderStopLoss();
   double tp = OrderTakeProfit();
   double op = OrderOpenPrice();
   double cur_price = MarketInfo(v, ((sign > 0) ? MODE_BID : MODE_ASK));              

   //check cur profit
   params.err_code = 1;
   if (sign > 0 && cur_price <= op) return;
   if (sign < 0 && cur_price >= op) return;
   
   //check cur diff traling
   params.err_code = 0;
   double next_sl = params.calcNewSL(v, cur_price, sign);
   if (sl > 0)
   {
      if ((sign > 0) && (sl > next_sl)) params.err_code = 1; //old SL more suitable 
      if ((sign < 0) && (sl < next_sl)) params.err_code = 1; //old SL more suitable 
      if (params.err_code == 1) 
      {
         Print(StringConcatenate("Current SL(",DoubleToStr(sl,4),") is more suitable than TRALING_SL(",DoubleToStr(next_sl,4),")")); 
         return;
      }
   }
   
   //try send new sl
   bool ok = OrderModify(params.ticket, 0, next_sl, tp, 0);
   if (!ok) params.err_code = -3;   
}
void LStaticTrade::trySetSlTp(LOrderModifyParams &params)
{
   if (params.invalidTicket()) {params.err_code = -1; return;}
   
   LCheckOrderInfo info(params.ticket);
   LStaticTrade::checkOrderState(info);
   if (info.isError())        {params.err_code = -1; return;}
   if (!info.isOpened())      {params.err_code = -2; return;}

   int sign = ((OrderType() == OP_BUY) ? 1 : -1); 

   string v = OrderSymbol();
   double sl = OrderStopLoss();
   double tp = OrderTakeProfit();
   double point_price = OrderOpenPrice();
   if (params.dev_type == 0) point_price = MarketInfo(v, ((sign > 0) ? MODE_BID : MODE_ASK));              
   
   if (params.sl_value > 0) sl = params.sl_value; 
   else if (params.needRemove_SL()) sl = 0; 
   else if (params.sl_value == 0) sl = params.calcNewSL(v, point_price, sign);

   if (params.tp_value > 0) tp = params.tp_value;
   else if (params.needRemove_TP()) tp = 0;
   else if (params.tp_value == 0) tp = params.calcNewTP(v, point_price, sign);

   bool ok = OrderModify(params.ticket, 0, sl, tp, 0);
   if (!ok) params.err_code = -3;   
}
void LStaticTrade::setPendingOrder(LOpenPendingOrderParams &params)
{
   if (params.invalidCouple()) {params.err_code = -6; return;}
   if (params.invalidLotSize()) {params.err_code = -7; return;}
   if (params.invalidCmd()) {params.err_code = -8; return;}
   
   double cur_price = MarketInfo(params.couple, (params.isBuy() ? MODE_ASK : MODE_BID));   
   int sign = ((params.type == OP_BUYLIMIT || params.type == OP_SELLSTOP) ? -1 : 1);
   
   //calc trigger price   
   double t_price = params.trigger_price;   
   LPricePair lpp(params.couple, ((t_price > 0) ? t_price : cur_price));
   if (params.dev_price > 0)
   {
      lpp.addPriceDeviation(params.dev_price*sign);
      t_price = lpp.p2;
   }
   else if (params.d_price > 0)
   {
      lpp.addPipsPrice(params.d_price*sign);
      t_price = lpp.p2;   
   }
   params.trigger_price = t_price;
   
   
   //calc SL & TP
   sign = (params.isBuy() ? 1 : -1);
   double sl = params.stop_loss*sign;
   double tp = params.take_profit*sign;
   lpp.p1 = t_price;
   if (params.stop_loss > 0)
   {
      if (params.dev_price_sl) {lpp.addPriceDeviation(-1*sl); sl = lpp.p2;}
      else if (params.stop_pips) {lpp.addPipsPrice(int(-1*sl)); sl = lpp.p2;}
      else sl = params.stop_loss;
   }
   if (params.take_profit > 0)
   {
      if (params.dev_price_tp) {lpp.addPriceDeviation(tp); tp = lpp.p2;}
      else if (params.stop_pips) {lpp.addPipsPrice(int(tp)); tp = lpp.p2;}
      else tp = params.take_profit;
   }   
   params.stop_loss = sl;
   params.take_profit = tp;
   
   //return;
   //попытка выставить отложенный ордер
   int t = OrderSend(params.couple, params.type, params.lots, t_price, params.slip, sl, tp, params.comment, params.magic, params.realExpiration());
   if (t <= 0) params.err_code = -1;      
   else params.ticket = t;
}
void LStaticTrade::tryOpenPos(LOpenPosParams &params)
{
   if (params.invalidCouple())   {params.err_code = -6; return;}
   if (params.invalidLotSize())  {params.err_code = -7; return;}
   if (params.invalidCmd())      {params.err_code = -8; return;}
      
   double cur_price = MarketInfo(params.couple, (params.isBuy() ? MODE_ASK : MODE_BID));   
   int sign = (params.isBuy() ? 1 : -1);
   double sl = params.stop_loss*sign;
   double tp = params.take_profit*sign;
   
   //calc SL & TP
   LPricePair lpp(params.couple, cur_price);
   if (params.stop_loss > 0)
   {
      if (params.dev_price_sl) {lpp.addPriceDeviation(-1*sl); sl = lpp.p2;}
      else if (params.stop_pips) {lpp.addPipsPrice(int(-1*sl)); sl = lpp.p2;}
      else sl = params.stop_loss;
   }
   if (params.take_profit > 0)
   {
      if (params.dev_price_tp) {lpp.addPriceDeviation(tp); tp = lpp.p2;}
      else if (params.stop_pips) {lpp.addPipsPrice(int(tp)); tp = lpp.p2;}
      else tp = params.take_profit;
   }   
   params.stop_loss = sl;
   params.take_profit = tp;
   
   //попытка открытия позы
   int t = OrderSend(params.couple, params.type, params.lots, cur_price, params.slip, sl, tp, params.comment, params.magic);
   if (t <= 0) params.err_code = -1;      
   else params.ticket = t;
}
void LStaticTrade::checkOrderState(LCheckOrderInfo &info)
{
   int t = info.checking_ticket;
   if (t <= 0) {info.err_code = -11; return;}
   if (!OrderSelect(t, SELECT_BY_TICKET)) {info.err_code = -12; return;}
   
   info.digist = int(MarketInfo(OrderSymbol(), MODE_DIGITS));
   
   //определяем текущий статус ордера
   int order_type = OrderType();
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
   if (info.isError()) return;      
   
   if (OrderCloseTime() == 0) {} //ордер в работе
   else info.status += 10; //ордер в истории
   
   //извлекаем основные параметры ордера/позы
   info.swap = OrderSwap();
   info.commision = OrderCommission();
   info.lots = OrderLots();
   info.open_price = OrderOpenPrice();
   if (!info.isHistory()) return; // ордер/поза все еще в работе

   if (info.isFinished())
   {
      info.result = OrderProfit();
      info.close_price = OrderClosePrice();
      double sl = OrderStopLoss();
      double tp = OrderTakeProfit();
      info.closed_by_stoploss = (sl > 0 && (MathAbs(1 - sl/info.close_price) < 0.001));
      info.closed_by_takeprofit = (tp > 0 && (MathAbs(1 - tp/info.close_price) < 0.001));
   }   
}
void LStaticTrade::tryClosePos(LCloseOrderParams &params)
{
   if (params.invalidTicket()) {params.err_code = -1; return;}

   LCheckOrderInfo info(params.ticket);
   LStaticTrade::checkOrderState(info);
   if (info.isError())        {params.err_code = -1; return;}
   if (info.isHistory())      {params.err_code = -2; return;}
   if (info.isPengingNow())   {params.err_code = -3; return;}
   
   //try close
   double lot = (params.needPartCloseVolume() ? params.lot_size : OrderLots());
   string v = OrderSymbol();
   double price =  MarketInfo(v, ((OrderType() == OP_BUY) ? MODE_BID : MODE_ASK));              
   if (!OrderClose(params.ticket, lot, price, params.slip)) 
   {
      params.err_code = -4;
      return;
   }
   
   //find new ticket if closed only part lots
   if (params.needPartCloseVolume())
   {
      int n = OrdersTotal();
      string s_ticket = IntegerToString(params.ticket);   
      params.ticket = -1;
      for (int i=0; i<n; i++)
      {
         if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
         if (StringFind(OrderComment(), s_ticket) >= 0)
         {
            params.ticket = OrderTicket();
            break;
         }         
      }      
      if (params.ticket < 0) params.err_code = -5;
   }      
}
void LStaticTrade::deletePendingOrder(LCloseOrderParams &params)
{
   if (params.invalidTicket()) {params.err_code = -1; return;}

   LCheckOrderInfo info(params.ticket);
   LStaticTrade::checkOrderState(info);
   if (info.isError())        {params.err_code = -1; return;}
   if (info.isHistory())      {params.err_code = -2; return;}
   if (!info.isPengingNow())  {params.err_code = -3; return;}
   
   //try delete order
   if (!OrderDelete(params.ticket)) 
      params.err_code = -4;
}


