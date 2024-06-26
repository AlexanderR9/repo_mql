//+------------------------------------------------------------------+
//|                                                ltradestructs.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

//стуктура параметров для закрытия части ордера
struct LCloseOrderPart
{
   LCloseOrderPart() {reset();}
   
   //код ошибки, 0 - успех
   int err_code; 
   int new_ticket;
   double lot_part;
   int slip;
   
   inline bool isError() const {return (err_code < 0);}
   void reset() {err_code = 0; new_ticket = -1; lot_part = 0; slip = 10;}
};

//стуктура параметров для открытия отложенных ордеров (SELL_LIMIT(STOP) и BUY_LIMIT(STOP))
struct LOpenPendingOrder
{
   LOpenPendingOrder() {reset();}
   LOpenPendingOrder(string s, double x, int t) :couple(s), lots(x), type(t), err_code(0), magic(0) {resetStops();}
   
   //код ошибки, 0 - успех
   int err_code; 
   
   string couple;
   double lots;      
   int type; //тип ордера, только OP_BUYLIMIT или OP_BUYSTOP или OP_SELLLIMIT или OP_SELLSTOP
   string comment;
   int magic;

   
   inline bool invalidCmd() const {return (type != OP_BUYLIMIT && type != OP_BUYSTOP && type != OP_SELLLIMIT && type != OP_SELLSTOP);}
   inline bool invalidCouple() const {return (couple == "");}
   inline bool invalidLotSize() const {return (lots < MarketInfo(couple, MODE_MINLOT));}
   inline bool isError() const {return (err_code < 0);}


   //установки цены
   double price; //цена срабатывания ордера(открытия)
   int d_price;   //отклонение цены в пипсах (может принимать значения >= 0)
   double dev_price; // отклонение цены в процентах (может принимать значения >= 0)
   //если d_price > 0 и price == 0, то price рассчитывается как отступ от текущей цены на d_price пунктов
   //если d_price > 0 и price > 0, то price рассчитывается как отступ от значения price на d_price пунктов
   //если dev_price > 0 и price == 0, то price рассчитывается как отступ от текущей цены на dev_price %
   //если dev_price > 0 и price > 0, то price рассчитывается как отступ от значения price на dev_price %
   
   
   double stop; // цена закрытия или 0 (стоп не выставлен) или количество пунктов > 0
   double profit;// цена закрытия или 0 (профит не выставлен) или количество пунктов > 0   
   //признак того что параметры stop и profit задаются в пунктах, на расстоянии которых 
   //рассчитываются реальные стопы от цены открытия(срабатывания) ордера
   bool stop_pips;
   
   
   // срок истечения ордера, если 0 то нет срока, имеется ввиду время сервера
   // при выставлении ордера может появлятся ошибка если expiration меньше допустимого значения (10 мин от текущего времени)
   // пример задания: StrToTime( "2007.04.21 00:00" )
   // пример задания: TimeCurrent() + 60;
   datetime  expiration; 
   
   //если d_expiration > 0 и expiration == 0, то expiration рассчитывается как текущее время + d_expiration секунд
   //если d_expiration > 0 и expiration > 0, то price рассчитывается как значение времени expiration + d_expiration секунд
   int d_expiration; 
   
   //calc real expiration
   datetime getRealExpiration() const
   {
      if (d_expiration > 0)
      {
         if (expiration > 0) return (expiration + d_expiration);
         return (TimeCurrent() + d_expiration);      
      }
      return expiration;
   }



   void resetStops() {stop = profit = price = dev_price = 0; d_price = 0; stop_pips = false; expiration = 0; d_expiration = 0;}
   void reset() {couple=""; type=-1; lots=0; err_code=0; magic=0; resetStops();}

   
   //установить значения уровней стопа и профита, а также принак того в чем измеряются эти значения
   void setStops(double sl, double tp, bool is_pips)
   {
      stop = sl;
      profit = tp;
      stop_pips = is_pips;
   }

   
   inline bool isBuy() const {return (type == OP_BUYLIMIT || type == OP_BUYSTOP);}
   inline bool isSell() const {return (type == OP_SELLLIMIT || type == OP_SELLSTOP);}
   inline bool isLimit() const {return (type == OP_BUYLIMIT || type == OP_SELLLIMIT);}
   inline bool isStop() const {return (type == OP_BUYSTOP || type == OP_SELLSTOP);}

   string out() const 
   {
      return StringConcatenate("LOpenPendingOrder: ", couple, "  open_price=", price, "  d_pips_price=", d_price, "  deviation_price=", dev_price,
            "  lot=", lots, "  cmd=", type, "  comment=", comment, 
            "  sl=", stop, "  tp=", profit,  "  stop_pips=", stop_pips);
   }


};


//стуктура параметров для открытия позиции (SELL и BUY)
struct LOpenPosParams
{
   LOpenPosParams() {reset();}
   LOpenPosParams(string s, double x, int t = OP_BUY) :couple(s), lots(x), type(t), err_code(0), slip(10), magic(0) {resetStops();}
   
   //код ошибки, 0 - успех
   int err_code; 

   string couple;
   double lots;      
   int type; //тип ордера, только OP_BUY или OP_SELL
   int slip;
   string comment;   
   int magic;
   
   //признак того что параметры stop и profit задаются в пунктах, на расстоянии которых 
   //рассчитываются реальные стопы от текущей цены открытия ордера
   bool stop_pips;
   double stop; // цена закрытия или 0 (стоп не выставлен) или количество пунктов > 0
   double profit;// цена закрытия или 0 (профит не выставлен) или количество пунктов > 0   
   

   inline void resetStops() {stop = 0; profit = 0; stop_pips = false;}
   inline void reset() {couple=""; type=-1; lots=0; err_code=0; slip=10; magic=0; resetStops();}
   inline bool isBuy() const {return (type == OP_BUY);}
   inline bool isSell() const {return (type == OP_SELL);}
   inline bool isError() const {return (err_code < 0);}
   inline bool invalidCouple() const {return (couple == "");}
   inline bool invalidLotSize() const {return (lots < MarketInfo(couple, MODE_MINLOT));}
   inline bool invalidCmd() const {return (type != OP_BUY && type != OP_SELL);}
   
   //установить значения уровней стопа и профита, а также принак того в чем измеряются эти значения
   void setStops(double sl, double tp, bool is_pips)
   {
      stop = sl;
      profit = tp;
      stop_pips = is_pips;
   }
   string out() const 
   {
      return StringConcatenate("LOpenPosParams: ", couple, "  lot=", lots, "  cmd=", type, "  comment=", comment, 
            "  sl=", stop, "  tp=", profit,  "  stop_pips=", stop_pips);
   }
};


//структура для проверки результатов и доп. информации об ордере
struct LCheckOrderInfo
{
   LCheckOrderInfo() :err_code(0), result(0), result_pips(0), status(0) {resetStops();}
   
   
   //код ошибки, возникшей при проверки заданного ордера
   // 0 - нет ошибки
   // -11 - не корректный тикет ( <= 0)
   // -12 - ордер не найден
   // -13 - не корректный тип ордера (OrderType())
   // -14 - неизвестная ошибка
   int err_code;
   
   inline bool isError() const {return (err_code < 0);}
   inline bool incorrectTicket() const {return (err_code == -11);}
   
   //результат выполнения ордера в валюте счета (без учета свопа и комиссий)
   //если поза еще открыта или это отложенный ордер, то вернет 0
   double result;
   inline bool isWin() const {return (result > 0);}
   inline bool isLoss() const {return (result < 0);}
   
   //результат выполнения ордера в пунктах (всегда для 4-х значных счетов, на 5-ти тоже работает)
   //для 4-х значных счетов это будет целое число, а для 5-ти значных с одним знаком после запятой
   //если поза еще открыта или это отложенный ордер, то вернет 0
   //может быть как положительным, так и отрицательным числом
   double result_pips;
   double swap;
   double commision;
   double lots;
   
   //итоговый результат включая коммисию и своп (в валюте счета)
   inline double totalResult() const {return (swap + commision + result);}

   // текущий статус ордера, значение имеет смысл при (err_code == 0)
   // 1 - текущий открытый ордер
   // 2 - текущий отложенный ордер
   // 11 - закрытый ордер, находится в истории
   // 12 - удаленный отложенный ордер, находится в истории
   int status;

   inline bool isOpened() const {return (!isError() && (status == 1));}
   inline bool isPengingNow() const {return (!isError() && (status == 2));}
   inline bool isFinished() const {return (!isError() && (status == 11));}
   inline bool isPengingCancelled() const {return (!isError() && (status == 12));}
   inline bool isHistory() const {return (isFinished() ||  isPengingCancelled());}

   bool closed_by_takeprofit; //признак того что поза закрылась по takeprofit
   bool closed_by_stoploss; //признак того что поза закрылась по stoploss
   
   void resetStops() {closed_by_takeprofit = false; closed_by_stoploss = false;}   
   void resetAll() {err_code=0; result=swap=commision=lots=0; result_pips=0; status=0;  resetStops();}
   
   
};

