//+------------------------------------------------------------------+
//|                                                 fl4ma_couple.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/lstatictrade.mqh>
#include <mylib/lmaanalize.mqh>

#define FL4MA_MAGIC     111



///////////////////////////////////////////////////////
class FL4MA_Couple
{
public:
   enum ExecResult {erNone = 35, erOpenedOrder, erClosingOrder, erHasError, 
                        erOrderGoneHistory, erOrderCanceled, erTryOrderCancel, erTryOrderCloseHalf, erTryOrderModif};
                        
   enum MarketSituation {msNone = 135, msTrendDown, msTrendUp, msFlat};

   FL4MA_Couple(string v);
   virtual ~FL4MA_Couple() {delete m_pairAnalizator;}
   
   void exec(int&);
   void setParams(int tf, double lot, int slip);
   void setStops(int sl, int tp) {m_sl = sl; m_tp = tp;}
   void setTrailing(bool b) {is_trailing = b;}
   
   
   static int tf2(int);
   static int tf3(int);

protected:
   string m_couple;   
   int m_period;
   int m_slip;
   double m_lot;
   int m_sl;
   int m_tp;
   bool is_trailing;
   
   LMAPairAnalizator *m_pairAnalizator;
   
   //state vars
   int m_order;
   //LOpenPosParams open_params; 
   LOpenPendingOrder pending_params;
   
   void reset() {m_period = PERIOD_M15; m_slip = 10; m_lot = 0.1; m_order = -1; setStops(0, 0); is_trailing = true;}
   bool isOrderOpened() const {return (m_order > 0);}
   void chekOrderState(int&); //проверить состояние открытого ордера
   void chekMarketState(); //проверить состояние рынка на предмет обнаружения точки входа
   void tryOpenOrder(int&); //открыть ордер
   void err(string s);
   string comment() const {return "fl_4ma";}
   int hasTrendTF(int tf) const; //текущая ситуация на рынке при заданном периоде, определяет наличие тренда на последних барах
   void recalcSlTp(); //пересчитать стопы перед открытием, сработает если m_sl и m_tp > 0
   void recalcPendingPrice(); //пересчитать цену срабатывания отложенного ордера относительно текущей
   void checkTraling(bool &was_traling); //проверить текущую цену и подтянуть стоп при необходимости
   void checkCloseHalf(bool was_close);  //проверить текущую цену и закрыть половину позиции при необходимости
   void checkCloseEnd(bool was_close);  //проверить текущую цену и закрыть позицию полностью при необходимости
   void checkCloseByCross(bool was_close);  //проверить текущую цену и закрыть позицию полностью при пересечении машек 5 и 20
   
   
   //обнаружение закрепления и раскрытия ema на рабочем тайфрейме
   //если будет обнаружено то в переменную sl запишется стоплос а
   //в cmd тип отложенного ордера, если cmd > 0 значит обнаружилась такая ситуация
   void findFixing(double &sl, int &cmd);
   
   
   void checkPendingState(int &result, LCheckOrderInfo&); //проверить ситуацию на предмет отмены отложенного ордера
   void checkHistoryState(int &result, LCheckOrderInfo&); //проверить результат работы ордера, после того как он попал в историю
   void checkOpenedState(int &result, LCheckOrderInfo&); //проверить ситуацию на предмет закрытия или переноса стопа открытого ордера

private:   
   bool maCross() const; //признак того что сейчас машки пересеклись (в нулевом баре рабочего ТФ)
   bool isDigist5() const {int x = int(MarketInfo(m_couple, MODE_DIGITS)); return (x == 3 || x == 5);} //признак того что терминал 5-ти знаковый
   int digFactor() const {return (isDigist5() ? 10 : 1);}   
   int dPipsOpenPrice() const; //на сколько пунктов сместить цену открытия от текущей цены (для отложенного ордера)

   
}; 
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
FL4MA_Couple::FL4MA_Couple(string v) 
   :m_couple(v) 
{
   reset(); 
   m_pairAnalizator = new LMAPairAnalizator(v);
   m_pairAnalizator.setBarsRange(0, 50);
}
void FL4MA_Couple::exec(int &result_code)
{
   result_code = erNone;
   if (isOrderOpened())// ордер был выставлен или перешел в открытые
   {
      chekOrderState(result_code);
      return;
   }
   
   //open_params.reset();
   pending_params.reset();
   chekMarketState(); //проверить наличие точки входа
   if (pending_params.type < 0) return;
   
   tryOpenOrder(result_code);
}
int FL4MA_Couple::dPipsOpenPrice() const
{
   int spread = int(MarketInfo(m_couple, MODE_SPREAD));
   if (spread == 0) spread = 4*digFactor();
   return 2*spread;
}
bool FL4MA_Couple::maCross() const
{
   if (!m_pairAnalizator.hasData()) {Print("FL4MA_Couple::maCross() WARNING no data"); return false;}
   return m_pairAnalizator.recAt(0).wasCross();
}
void FL4MA_Couple::findFixing(double &sl, int &cmd)
{
   cmd = -1;
   m_pairAnalizator.setParameters(m_period, 5, 20);
   m_pairAnalizator.updateData();
   
   FLMA_State_i rec0 = m_pairAnalizator.recAt(0);
   FLMA_State_i rec1 = m_pairAnalizator.recAt(1);
   FLMA_State_i rec2 = m_pairAnalizator.recAt(2);

   if (rec0.isDiverge() && rec1.isConverge() && rec2.isConverge()) //закрепление     
   {
      int i_cross = m_pairAnalizator.lastCrossBar();
      int k_dig = (isDigist5() ? 10 : 1);
      if (i_cross > 2)
      {
         sl = m_pairAnalizator.lastCrossPeakPrice();
         if (rec0.d_ema < 0) //sell stop
         {
            int i_pit = m_pairAnalizator.findPitIndex1(1);
            if (i_pit > 0 && i_pit < i_cross) cmd = OP_SELLSTOP;
         }
         else //buy stop
         {
            int i_peak = m_pairAnalizator.findPeakIndex1(1);
            if (i_peak > 0 && i_peak < i_cross) cmd = OP_BUYSTOP;
         }
      }
   }
}
int FL4MA_Couple::hasTrendTF(int tf) const
{
   m_pairAnalizator.setParameters(tf, 5, 20);
   m_pairAnalizator.updateData();
   FLMA_State_i rec0 = m_pairAnalizator.recAt(0);
   FLMA_State_i rec1 = m_pairAnalizator.recAt(1);
   FLMA_State_i rec2 = m_pairAnalizator.recAt(2);
   
   if (rec0.ema2Down() && rec1.ema2Down() && rec2.ema2Down() && /*rec0.isDiverge() &&*/
            rec0.d_ema < 0 && rec1.d_ema < 0 && rec2.d_ema < 0)
   {
      return msTrendDown;
   }
   if (rec0.ema2Up() && rec1.ema2Up() && rec2.ema2Up() && /*rec0.isDiverge() && */
            rec0.d_ema > 0 && rec1.d_ema > 0 && rec2.d_ema > 0)
   {
      return msTrendUp;
   }
      
   return msNone;
}
void FL4MA_Couple::chekMarketState()
{
   //определяем тренд на старших ТФ и смотрим что он совпадает
   int situation2 = hasTrendTF(tf2(m_period));
   int situation3 = hasTrendTF(tf3(m_period));
   if (situation2 != situation3) return;
   if (situation2 != msTrendUp && situation2 != msTrendDown) return; //нет ни какого тренда
   
  // Print("Has trend: ", (situation2==msTrendUp)?"TrendUp":"TrendDown"); //обнаружили тренд на старших ТФ
   
   
   //обнаружение закрепления и раскрытия ema на рабочем тайфрейме
   double sl = 0;
   int cmd = -1;
   findFixing(sl, cmd);
   if (cmd < 0) return; //нет такой ситуации
   
   //проверяем совпадает ли тип ордера с трендом старших ТФ
   switch (situation2)
   {
      case msTrendUp: 
      {
         if (cmd != OP_BUYSTOP) return;
         break;
      }
      case msTrendDown: 
      {
         if (cmd != OP_SELLSTOP) return;
         break;
      }
      default: return;
   }

   //тренд одобрен
   pending_params.type = cmd;
   pending_params.stop = sl;
   
   //Print("Finded input point: cmd=", cmd, "  cur_price=", MarketInfo(m_couple, MODE_BID));
   
}
void FL4MA_Couple::recalcSlTp()
{
   if (pending_params.stop < 0) pending_params.stop = 0;
   if (m_sl <= 0 && m_tp <= 0) return;
   pending_params.setStops(m_sl, m_tp, true);
}
void FL4MA_Couple::recalcPendingPrice()
{
   double cur_price = MarketInfo(m_couple, MODE_BID);
   int signum = -1;
   if (pending_params.isBuy()) 
   {
      cur_price = MarketInfo(m_couple, MODE_BID);
      signum = 1;
   }
   
   int d_pips = signum*dPipsOpenPrice();
   pending_params.price = LPrice::addPipsPrice(cur_price, d_pips, m_couple);
}
void FL4MA_Couple::tryOpenOrder(int &result)
{
   pending_params.couple = m_couple;
   pending_params.lots = m_lot;
   pending_params.comment = comment();
   pending_params.magic = FL4MA_MAGIC;
   recalcPendingPrice();
   recalcSlTp();
   Print("FL4MA_Couple::tryOpenOrder: [finded input point] ", pending_params.out());
   
   LStaticTrade::setPendingOrder(m_order, pending_params);
   if (pending_params.isError())
   {
      m_order = -1;
      err(StringConcatenate("func[FL4MA_Couple::tryOpenOrder()]  err_code=", pending_params.err_code));
      result = erHasError;
   }
   else 
   {
      result = erOpenedOrder;
      m_pairAnalizator.setParameters(m_period, 5, 20);
      m_pairAnalizator.updateData();   
   }
}
void FL4MA_Couple::chekOrderState(int &result)
{
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(m_order, info);
   if (info.isError())
   {
      err(StringConcatenate("func[FL4MA_Couple::chekOrderState()]  err_code=", info.err_code, "  ticket=", m_order));
      m_order = -1;
      result = erHasError;
      return;
   }
   
   if (info.isPengingNow()) checkPendingState(result, info); //еще отложенный
   else if (info.isOpened()) checkOpenedState(result, info); //ордер перешел в открытые
   else if (info.isHistory()) checkHistoryState(result, info); //ордер в истории, либо закрыт с профитом, либо удален еще отложенным
}
void FL4MA_Couple::checkPendingState(int &result, LCheckOrderInfo &info)
{
   if (maCross()) //проверить если машки пересеклись, то отменить отложенный ордер
   {
      result = erTryOrderCancel;
      int code = 0;
      LStaticTrade::deletePendingOrder(m_order, code);
      if (code < 0)
      {
         err(StringConcatenate("func[FL4MA_Couple::checkPendingState()]  err_code=", code));
      }
   }
}
void FL4MA_Couple::checkOpenedState(int &result, LCheckOrderInfo &info)
{
   //ордер уже выделен, в info хранится информация о нем.
   //1. подтянуть стоп если в данный момент он больше traling_pips.
   //2. если машки пересеклись закрыть половину сделки (при условии что она до этого не была закрыта)
   //3. закрыть позу если появилось обратное закрепление
   
   //1.
   bool was_action = false;
   if (is_trailing)
   {
      checkTraling(was_action);
      if (was_action) {result = erTryOrderModif; return;}
   }
   
   /*
   //2.
   checkCloseHalf(was_action);
   if (was_action) {result = erTryOrderCloseHalf; return;}
   
   //3.
   checkCloseEnd(was_action);
   if (was_action) result = erClosingOrder;  
   */
   
   m_pairAnalizator.updateData();
   
   checkCloseByCross(was_action);
   if (was_action) result = erClosingOrder;  
   
}
void FL4MA_Couple::checkHistoryState(int &result, LCheckOrderInfo &info)
{
   m_order = -1;
   if (info.isPengingCancelled())
   {
      //ордер был отменен
      result = erOrderCanceled;
   }
   else
   {
      //ордер закрылся с неким результатом
      string s = StringConcatenate("Order cloded,  ticket=", m_order, "  result: ");
      if (info.isLoss()) Print(s, "LOSS (", DoubleToStr(info.result, 2), ")");
      else if (info.isWin()) Print(s, "WIN (", DoubleToStr(info.result, 2), ")");
      else Print(s, "NULL");      
      result = erOrderGoneHistory;   
   }
}
void FL4MA_Couple::checkCloseByCross(bool was_close)
{
   //Print("FL4MA_Couple::checkCloseByCross exec");
   was_close = false;
   if (OrderProfit() <= 0) return;
   
   if (maCross())  // машки пересеклись, надо закрыть позу полностью
   {
      Print("///////////////////////////////////////////////////////");
      int code = 0;
      LStaticTrade::tryOrderClose(m_order, code, m_slip);
      if (code != 0) err(StringConcatenate("FL4MA_Couple::checkCloseByCross  ERR close order: ", m_order, "  err=", code));
      was_close = true;       
   }
}
void FL4MA_Couple::checkCloseEnd(bool was_close)
{
   was_close = false;
   if (OrderProfit() <= 0) return;

   double sl = 0;
   double open_price = 0;
   int cmd = -1;
   findFixing(sl, cmd);
   if (cmd < 0) return;
   
   if ((OrderType() == OP_BUY && cmd == OP_SELLSTOP) || (OrderType() == OP_SELL && cmd == OP_BUYSTOP))
   {
      int code = 0;
      LStaticTrade::tryOrderClose(m_order, code, m_slip);
      if (code != 0) err(StringConcatenate("FL4MA_Couple::checkOpenedState  ERR close order: ", m_order));
      was_close = true;    
   }
}
void FL4MA_Couple::checkCloseHalf(bool was_close)
{
   was_close = false;
   double lot = OrderLots();
   bool need_part = ((m_lot/2) >= MarketInfo(m_couple, MODE_MINLOT) && (lot == m_lot)); 
   if (need_part && maCross())  
   {
      LCloseOrderPart params;
      params.lot_part = NormalizeDouble(lot/2, 2);
      params.slip = m_slip;
      LStaticTrade::tryOrderClosePart(m_order, params);
      if (params.isError()) err(StringConcatenate("FL4MA_Couple::checkCloseHalf  ERR close part order: ", m_order));
      else m_order = params.new_ticket;
      
      was_close = true;   
   }
}
void FL4MA_Couple::checkTraling(bool &was_traling)
{
   was_traling = false;
   int traling_pips = 20*digFactor();
   if (m_sl > 0) traling_pips = m_sl;
   
   int err_code = 0;
   LStaticTrade::tryTraling(m_order, traling_pips, err_code);
   switch (err_code)
   {
      case -1:
      case -2: {err(StringConcatenate("FL4MA_Couple::checkTraling  ERR modify, code=", err_code)); break;}
      case 0: {was_traling = true; break;}
      case -3: 
      {
         err(StringConcatenate("FL4MA_Couple::checkTraling  ERR modify, code=", err_code));
         was_traling = true; 
         break;
      }
      default: break;
   }
}
void FL4MA_Couple::err(string s)
{
   Print("WAS ERROR: ", s, "  GetLastError()=", GetLastError());
}
void FL4MA_Couple::setParams(int tf, double lot, int slip)
{
   m_period = tf;
   m_slip = slip;
   m_lot = lot;
}
int FL4MA_Couple::tf2(int tf)
{
   switch(tf)
   {
      case PERIOD_M1:   return PERIOD_M5;
      case PERIOD_M5:   return PERIOD_M15;
      case PERIOD_M15:  return PERIOD_H1;
      case PERIOD_H1:   return PERIOD_H4;
      case PERIOD_H4:   return PERIOD_D1;
      case PERIOD_D1:   return PERIOD_W1;
      default: break;
   }
   return PERIOD_H1;
}
int FL4MA_Couple::tf3(int tf)
{
   switch(tf)
   {
      case PERIOD_M1:   return PERIOD_M15;
      case PERIOD_M5:   return PERIOD_H1;
      case PERIOD_M15:  return PERIOD_H4;
      case PERIOD_H1:   return PERIOD_D1;      
      case PERIOD_H4:   return PERIOD_W1;
      case PERIOD_D1:   return PERIOD_MN1;
      default: break;
   }
   return PERIOD_H4;
}



/*
void FL4MA_Couple::tryOpenOrder(int &result)
{
   open_params.couple = m_couple;
   open_params.lots = m_lot;
   open_params.slip = m_slip;
   open_params.comment = comment();
   open_params.magic = FL4MA_MAGIC;
   
   //calcSlTp();
   
   LStaticTrade::tryOpenPos(m_order, open_params);
   if (open_params.isError())
   {
      m_order = -1;
      Print("open_params:  ", open_params.out());
      err(StringConcatenate("func[FL4MA_Couple::tryOpenOrder()]  err_code=", open_params.err_code));
      result = erHasError;
   }
   else result = erOpenedOrder;
}
void FL4MA_Couple::chekOrderState(int &result)
{
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(m_order, info);
   if (info.isError())
   {
      err(StringConcatenate("func[FL4MA_Couple::chekOrderState()]  err_code=", info.err_code, "  ticket=", m_order));
      m_order = -1;
      result = erHasError;
      return;
   }
   
   if (info.isHistory())
   {
      string s = StringConcatenate("Order cloded,  ticket=", m_order, "  result: ");
      if (info.isLoss()) Print(s, "LOSS (", DoubleToStr(info.result, 2), ")");
      else if (info.isWin()) Print(s, "WIN (", DoubleToStr(info.result, 2), ")");
      else Print(s, "NULL");
      
      m_order = -1;
      result = erOrderGoneHistory;
   }  
}
*/

  