//+------------------------------------------------------------------+
//|                                                ltradestructs.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


#include <mylib/structs/lpriceoperations.mqh>


// стуктура параметров для модификации ордера (поза/ордер не должны быть в истории).
struct LOrderModifyParams
{
   LOrderModifyParams(int t, int dev_t = 1) :ticket(t), dev_type(dev_t)  {reset();}  
   
   //////////////VARS////////////////////
   int ticket; //тикет удаляемого ордера/позы (входной параметр)
   int err_code;  //код ошибки, 0 - успех
   
   //------------------------------------------------------------------
   
   //настройки для установки новых значений stoploss/takeprofit у открытой позы
   
   //новое значение sl, если -1 то это значит что sl не должен изменится.
   //если 0 (при sl_pip==0, sl_deviation==0) то это значит что текущий sl нужно отменить.
   //если больше 0 то sl_pips и sl_deviation не имеет значение, а sl_value это и будет новый sl .
   double sl_value; 
   int sl_pips; //отклонение в пипсах от цены(зависит от dev_type), если sl_value==0
   double sl_deviation; //отклонение в % от цены(зависит от dev_type), если sl_value==0, если sl_deviation>0 то sl_pips не имеет значение 
   
   //аналогично настройкам sl
   double tp_value;
   int tp_pips;
   double tp_deviation;
   
   // 0-отклонение stoploss/takeprofit рассчитывать от текущей цены
   // 1-отклонение stoploss/takeprofit рассчитывать от цены открытия
   // имеет смысл только если sl_value/tp_value == 0
   int dev_type; //default 1
   
   //------------------------------------------------------------------

   //параметры тралинга, задаются следующим образом:
   //dev_t=0; sl_value=0; 
   // sl_pips/sl_deviation требуемое значение пользователя (отклонение от текущей цены которое надо отслеживать, и подтягивать)
   //настроки takeprofit не трогать.

   ///////////////////////METODS/////////////////////////////////
   inline bool isError() const {return (err_code < 0);}
   inline bool tralingOn() const {return (dev_type == 0 && sl_value == 0 && (sl_pips > 0 || sl_deviation > 0));}
   inline bool invalidTicket() const {return (ticket <= 0);}
   inline bool needRemove_SL() const {return (sl_value == 0 && sl_pips == 0 && sl_deviation == 0);}
   inline bool needRemove_TP() const {return (tp_value == 0 && tp_pips == 0 && tp_deviation == 0);}

   double calcNewSL(string v, double price, int sign) const
   {
      LPricePair lpp(v, price);
      int pips = sl_pips;
      if (sl_deviation > 0) 
      {
         lpp.addPriceDeviation(-1*sign*sl_deviation);
         pips = MathAbs(lpp.priceDiff());
      }
      double res = price-(double(pips)*lpp.digFactor()*sign);
      return NormalizeDouble(res, int(MarketInfo(v, MODE_DIGITS)));
   }
   double calcNewTP(string v, double price, int sign) const
   {
      LPricePair lpp(v, price);
      int pips = tp_pips;
      if (tp_deviation > 0) 
      {
         lpp.addPriceDeviation(sign*tp_deviation);
         pips = MathAbs(lpp.priceDiff());
      }
      double res = price+(double(pips)*lpp.digFactor()*sign);
      return NormalizeDouble(res, int(MarketInfo(v, MODE_DIGITS)));
   }
   string toStr() const
   {
      string s = "LOrderModifyParams: ";
      s += StringConcatenate(" TICKET (", ticket, ");  dev_type=", dev_type);
      if (!isError())
      {
         s += StringConcatenate("; sl_params=", DoubleToStr(sl_value, 4), "; sl_pips", sl_pips, "; sl_deviation", DoubleToStr(sl_deviation, 2));
         s += StringConcatenate("; tp_params=", DoubleToStr(tp_value, 4), "; tp_pips", tp_pips, "; tp_deviation", DoubleToStr(tp_deviation, 2));
         s += ";   result=OK!";
      }
      else s += StringConcatenate("  ERR=", err_code);
      return s;
   }   

private:
   void  resetSlTp() 
   {
      sl_value = tp_value = -1;
      sl_pips = tp_pips = 0;
      sl_deviation = tp_deviation = 0;
   }
   void reset() {err_code=0; /*traling_pips = 0; dev_traling=0;*/ resetSlTp();}

};

// стуктура параметров для закрытия позиции либо удаления отложенного ордера (поза/ордер не должны быть в истории).
// если нужно закрыть часть позиции, то используется переменная lot_size
struct LCloseOrderParams
{
   LCloseOrderParams(int t) :ticket(t) {reset();}  
   
   //////////////VARS////////////////////
   int ticket; //тикет удаляемого ордера/позы (входной параметр)
   int err_code;  //код ошибки, 0 - успех
   int slip; //допустимое проскальзывание в пунктах
   double lot_size; //часть закрываемого объема позы (по умолчанию -1)
   
   ///////////////////////METODS/////////////////////////////////
   inline bool isError() const {return (err_code < 0);}
   inline bool invalidTicket() const {return (ticket <= 0);}
   inline bool needPartCloseVolume() const {return (lot_size > 0);}

   string toStr() const
   {
      string s = "LRemoveOrderParams: ";
      if (!isError())
      {
         s += StringConcatenate(" REMOVABLE_TICKET (", ticket, ");  ", "slip=", slip);
         s += StringConcatenate("; lot_size=", DoubleToStr(lot_size, 2));
         s += ";   result=OK!";
      }
      else s += StringConcatenate("  ERR=", err_code);
      return s;
   }

private:
   void reset() {err_code=0; slip=10;}      

};


//стуктура параметров для открытия позиции (SELL и BUY)
struct LOpenPosParams
{
   LOpenPosParams(string s, int tt, int sp=5) :couple(s), type(tt), slip(sp) {reset();}
   
   
   //////////////VARS////////////////////   
   string couple;
   int type; //тип ордера, только OP_BUY или OP_SELL
   int slip; //допустимое проскальзывание в пунктах
   
   double lots;      
   string comment;   
   int magic;
   double stop_loss; // цена закрытия, (0 - стоп не выставлен), только НЕ отрицательное число
   double take_profit;// цена закрытия, (0 - профит не выставлен), только НЕ отрицательное число
   int err_code;  //код ошибки, 0 - успех
   
   //признак того что параметры stop_loss и take_profit задаются в пунктах, на расстоянии которых 
   //перед открытием позы необходимо вычислить реальные стопы от текущей цены открытия ордера
   bool stop_pips; 
   
   //признак того что stop_loss задается как отклюнение в % от текущей цены (неотрицательное значение)
   //перед открытием позы необходимо вычислить реальные стопы от текущей цены открытия ордера
   //при dev_price_sl == true, stop_pips не имеет значения
   bool dev_price_sl;
   
   //признак того что take_profit задается как отклюнение в % от текущей цены (неотрицательное значение)
   //перед открытием позы необходимо вычислить реальные стопы от текущей цены открытия ордера
   //при dev_price_tp == true, stop_pips не имеет значения
   bool dev_price_tp;
   
   int ticket; //result ticket after opening pos

   ///////////////////////METODS/////////////////////////////////
   bool isBuy() const {return (type == OP_BUY);}
   bool isSell() const {return (type == OP_SELL);}
   bool isError() const {return (err_code < 0);}
   bool invalidCouple() const {return (StringLen(couple) < 3);}
   bool invalidLotSize() const {return (lots < MarketInfo(couple, MODE_MINLOT));}
   bool invalidCmd() const {return (type != OP_BUY && type != OP_SELL);}
   
   string toStr() const
   {
      string s = "LOpenPosParams: ";
      if (!isError())
      {
         int dig = int(MarketInfo(couple, MODE_DIGITS));
         s += StringConcatenate(" symbol:", couple, "; tt=", type, "; slip=", slip, "; lot_size=", DoubleToStr(lots, 2));
         s += StringConcatenate("; magic=", magic, "; comment[", comment,"]");         
         s += StringConcatenate("; SL/TP=", DoubleToStr(stop_loss, dig), "/", DoubleToStr(take_profit, dig));
         s += StringConcatenate("; RESULT_TIKET=", ticket);                  
      }
      else s += StringConcatenate("  ERR=", err_code);
      return s;
   }
     
private:
   void resetStops() {stop_loss = take_profit = 0; stop_pips = dev_price_sl = dev_price_tp = false;}
   void reset() {ticket=-1; err_code=0; lots=0; comment=""; magic=0; resetStops();}      
   
};

//стуктура параметров для открытия отложенных ордеров (SELL_LIMIT(STOP) и BUY_LIMIT(STOP))
struct LOpenPendingOrderParams : public LOpenPosParams
{
   LOpenPendingOrderParams(string s, int tt) :LOpenPosParams(s, tt) {resetPriceSettings(); resetExpiration();}

   //////////////VARS////////////////////   
   //установки цены открытия:
   double trigger_price;  //цена срабатывания ордера(открытия)
   int d_price;   //отклонение цены в пипсах от trigger_price, если trigger_price==0, то от текущей цены (неотрицательное значение)
   double dev_price; //отклонение цены в % от trigger_price, если trigger_price==0, то от текущей цены (неотрицательное значение), если dev_price>0 то d_price не имеет значение

   // установки времени жизни отложенного ордера:
   // если 0 то нет срока, 
   // имеется ввиду время сервера
   // при выставлении ордера может появлятся ошибка если expiration меньше допустимого значения (10 мин от текущего времени)
   // пример задания: StrToTime( "2007.04.21 00:00" )
   datetime  expiration; 
   
   //отклонение времени в МИНУТАХ от expiration, если expiration==0 то от текущего времени (неотрицательное значение)
   //участвует в расчетах expiration только если больше 0
   int d_expiration; 

   
   ///////////////////////METODS/////////////////////////////////
   inline bool isBuy() const {return (type == OP_BUYLIMIT || type == OP_BUYSTOP);}
   inline bool isSell() const {return (type == OP_SELLLIMIT || type == OP_SELLSTOP);}
   inline bool isLimitKind() const {return (type == OP_BUYLIMIT || type == OP_SELLLIMIT);}
   inline bool isStopKind() const {return (type == OP_BUYSTOP || type == OP_SELLSTOP);}
   bool invalidCmd() const {return (!isBuy() && !isSell());}

   //вернет корректное значение которое можно передать в функцию OrderSend
   datetime realExpiration() const 
   {
      if (d_expiration > 0)
      {
         int d_sec = d_expiration*60;
         if (expiration > 0) return (expiration + d_sec);
         return (TimeCurrent() + d_sec);      
      }
      return expiration;
   }
   
   string toStr() const
   {
      string s = "LOpenPendingOrderParams: ";
      if (!isError())
      {
         int dig = int(MarketInfo(couple, MODE_DIGITS));
         s += StringConcatenate(" symbol:", couple, "; tt=", type, "; slip=", slip, "; lot_size=", DoubleToStr(lots, 2));
         s += StringConcatenate("; magic=", magic, "; comment[", comment,"]");         
         s += StringConcatenate("; trigger_price=", DoubleToStr(trigger_price, dig));
         s += StringConcatenate("; SL/TP=", DoubleToStr(stop_loss, dig), "/", DoubleToStr(take_profit, dig));
         s += StringConcatenate("; expiration[", TimeToStr(realExpiration()), "]");                  
         s += StringConcatenate("; RESULT_TIKET=", ticket);                  
      }
      else s += StringConcatenate("  ERR=", err_code);
      return s;
   }
   

private:
   void resetPriceSettings() {trigger_price = 0; d_price = 0; dev_price = 0;}
   void resetExpiration() {expiration = 0; d_expiration = 0;}

};


//структура для проверки результатов и доп. информации об ордере (checking_ticket)
struct LCheckOrderInfo
{
   LCheckOrderInfo(int t) :checking_ticket(t) {reset();}  
   
   //////////////VARS////////////////////
   int checking_ticket; //проверяемый тикет (входной параметр)

   double swap; //размер свопа
   double commision; //размер комиссии
   double lots; //размер лота
   bool closed_by_takeprofit; //признак того что поза закрылась по takeprofit
   bool closed_by_stoploss; //признак того что поза закрылась по stoploss   
   double open_price; //цена открытия (либо срабатывания)
   double close_price; //цена закрытия, отлична от нуля только у закрытой позиции (status == 11)
   int digist; //точность для инструмента у этого ордера

   //код ошибки, возникшей при проверки заданного ордера
   // 0 - нет ошибки
   // -11 - не корректный тикет ( <= 0)
   // -12 - ордер не найден
   // -13 - не корректный тип ордера (OrderType())
   // -14 - неизвестная ошибка
   int err_code;
      
   // текущий статус ордера, значение имеет смысл при (err_code == 0)
   // 1 - текущий открытый ордер
   // 2 - текущий отложенный ордер
   // 11 - закрытый ордер, находится в истории
   // 12 - удаленный отложенный ордер, находится в истории
   int status;

   //результат выполнения ордера в валюте счета (без учета свопа и комиссий)
   //если поза еще открыта или это отложенный ордер, то вернет 0
   double result;      


   ///////////////////////METODS/////////////////////////////////
   inline bool isError() const {return (err_code < 0);}
   inline bool isOpened() const {return (!isError() && (status == 1));} // в текущий момент это открытая позиция
   inline bool isPengingNow() const {return (!isError() && (status == 2));} // в текущий момент это выставленный отложенный ордер
   inline bool isFinished() const {return (!isError() && (status == 11));} // позиция закрыта и находится в истории
   inline bool isPengingCancelled() const {return (!isError() && (status == 12));} // отложенный ордер был удален и находится в истории
   inline bool isHistory() const {return (isFinished() ||  isPengingCancelled());} 
   inline bool incorrectTicket() const {return (err_code == -11);}
   inline bool isWin() const {return (result > 0);}
   inline bool isLoss() const {return (result < 0);}
   inline double totalResult() const {return (swap + commision + result);} //итоговый результат включая коммисию и своп (в валюте счета)
   
   string toStr() const
   {
      string s = "LCheckOrderInfo: TICKET("+IntegerToString(checking_ticket)+") : ";
      if (!isError())
      {
         s += StringConcatenate("  status=", status);
         s += StringConcatenate("; swap=", DoubleToStr(swap, 2), "; commision=", DoubleToStr(commision, 2), "; lots=", DoubleToStr(lots, 2));
         s += StringConcatenate("; price(Op/Cl)=", DoubleToStr(open_price, digist), "/");
         s += (isFinished() ? DoubleToStr(close_price, digist) : "---");
         s += StringConcatenate("; symbol:", OrderSymbol(), "; digist=", IntegerToString(digist));
         s += StringConcatenate("; SL/TP=", closed_by_stoploss, "/", closed_by_takeprofit);
         s += StringConcatenate("; result=", (isFinished() ? DoubleToStr(result, digist) : "---"));
      }
      else s += StringConcatenate("  ERR=", err_code);
      return s;
   }

private:
   void resetStops() {closed_by_takeprofit = false; closed_by_stoploss = false;}   
   void reset() {err_code=status=digist=0; result=swap=commision=lots=open_price=close_price=0; resetStops();}      
   
};

