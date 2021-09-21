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
   
   
   static int tf2(int);
   static int tf3(int);

protected:
   string m_couple;   
   int m_period;
   int m_slip;
   double m_lot;
   
   LMAPairAnalizator *m_pairAnalizator;
   
   //state vars
   int m_order;
   //LOpenPosParams open_params; 
   LOpenPendingOrder pending_params;
   
   void reset() {m_period = PERIOD_M15; m_slip = 10; m_lot = 0.1; m_order = -1;}
   bool isOrderOpened() const {return (m_order > 0);}
   void chekOrderState(int&); //проверить состояние открытого ордера
   void chekMarketState(); //проверить состояние рынка на предмет обнаружения точки входа
   void tryOpenOrder(int&); //открыть ордер
   void err(string s);
   string comment() const {return "fl_4ma";}
   int hasTrendTF(int tf) const; //текущая ситуация на рынке при заданном периоде, определяет наличие тренда на последних барах
   
   //обнаружение закрепления и раскрытия ema на рабочем тайфрейме
   //если будет обнаружено то в переменную sl запишется стоплос а
   //в cmd тип отложенного ордера, если cmd > 0 значит обнаружилась такая ситуация
   void findFixing(double &sl, int &cmd, double &open_price);
   
   
   void checkPendingState(int &result, LCheckOrderInfo&); //проверить ситуацию на предмет отмены отложенного ордера
   void checkHistoryState(int &result, LCheckOrderInfo&); //проверить результат работы ордера, после того как он попал в историю
   void checkOpenedState(int &result, LCheckOrderInfo&); //проверить ситуацию на предмет закрытия или переноса стопа открытого ордера

private:   
   bool maCross() const; //признак того что сейчас машки пересеклись (в нулевом баре рабочего ТФ)
   bool isDigist5() const {int x = int(MarketInfo(m_couple, MODE_DIGITS)); return (x == 3 || x == 5);} //признак того что терминал 5-ти знаковый

   
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
bool FL4MA_Couple::maCross() const
{
   if (!m_pairAnalizator.hasData()) return false;
   return m_pairAnalizator.recAt(0).wasCross();
}
void FL4MA_Couple::findFixing(double &sl, int &cmd, double &open_price)
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
            if (i_pit > 0 && i_pit < i_cross)
            {
               cmd = OP_SELLSTOP;
               open_price = iLow(m_couple, m_period, i_pit);
               
               double cur_price = MarketInfo(m_couple, MODE_BID);
               if (LPrice::pricesDiff(cur_price, open_price, m_couple) < MarketInfo(m_couple, MODE_SPREAD))
                  open_price = LPrice::addPipsPrice(cur_price, -6*k_dig, m_couple);
                  
               if (sl <= 0) sl = LPrice::addPipsPrice(open_price, 50*k_dig, m_couple);
            }
         }
         else //buy stop
         {
            int i_peak = m_pairAnalizator.findPeakIndex1(1);
            if (i_peak > 0 && i_peak < i_cross)
            {
               cmd = OP_BUYSTOP;
               open_price = iHigh(m_couple, m_period, i_peak);
               
               double cur_price = MarketInfo(m_couple, MODE_ASK);
               if (LPrice::pricesDiff(cur_price, open_price, m_couple) < MarketInfo(m_couple, MODE_SPREAD))
                  open_price = LPrice::addPipsPrice(cur_price, 6*k_dig, m_couple);
                  
                if (sl <= 0) sl = LPrice::addPipsPrice(open_price, -50*k_dig, m_couple);
            }         
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
   //Print("FL4MA_Couple::chekMarketState(), couple=", m_couple);
   
   //определяем тренд на старших ТФ и смотрим что он совпадает
   int situation2 = hasTrendTF(tf2(m_period));
   int situation3 = hasTrendTF(tf3(m_period));
  // Print("situation2=", situation2, "  situation3=", situation3);
   if (situation2 != situation3) return;
   if (situation2 != msTrendUp && situation2 != msTrendDown) return; //нет ни какого тренда
   
   Print("Has trend: ", (situation2==msTrendUp)?"TrendUp":"TrendDown"); //обнаружили тренд на старших ТФ
   
   
   //обнаружение закрепления и раскрытия ema на рабочем тайфрейме
   double sl = 0;
   double open_price = 0;
   int cmd = -1;
   findFixing(sl, cmd, open_price);
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
   pending_params.price = open_price;
   pending_params.stop = sl;
   
   Print("Finded input point: cmd=", cmd, "  open_price=", open_price, "  cur_price=", MarketInfo(m_couple, MODE_BID));
   
}
void FL4MA_Couple::tryOpenOrder(int &result)
{
   pending_params.couple = m_couple;
   pending_params.lots = m_lot;
   pending_params.comment = comment();
   pending_params.magic = FL4MA_MAGIC;
   Print("FL4MA_Couple::tryOpenOrder: ", pending_params.out());
   
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
   //Print("FL4MA_Couple::chekOrderState");
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
   //ордер уже выделен, в info хранится информация о нем
   
   //1. подтянуть стоп если в данный момент он больше 25 п.
   //2. если машки пересеклись закрыть половину сделки (при условии что она до этого не была закрыта)
   //3. закрыть позу если появилось обратное закрепление
   
   //1.
   double sl = OrderStopLoss();
   double cur_price = MarketInfo(m_couple, MODE_ASK);
   int d = MathAbs(LPrice::pricesDiff(cur_price, sl, m_couple));
   int k = 1;
   if (isDigist5()) k = 10;
   int traling_pips = 20;
   if (d/k > (traling_pips+5))
   {
      
      if (OrderType() == OP_SELL) sl = LPrice::addPipsPrice(cur_price, traling_pips*k, m_couple);
      else  sl = LPrice::addPipsPrice(cur_price, -1*traling_pips*k, m_couple);
      if (!OrderModify(m_order, 0, sl, 0, 0))
         err(StringConcatenate("FL4MA_Couple::checkOpenedState  ERR open modify"));
      result = erTryOrderModif;
      return;    
   }   
   
   //2.
   double lot = OrderLots();
   bool need_part = ((m_lot/2) >= MarketInfo(m_couple, MODE_MINLOT) && (lot == m_lot)); 
   if (need_part && maCross())  
   {
         LCloseOrderPart params;
         params.lot_part = NormalizeDouble(lot/2, 2);
         params.slip = m_slip;
         LStaticTrade::tryOrderClosePart(m_order, params);
         if (params.isError()) err(StringConcatenate("FL4MA_Couple::checkOpenedState  ERR close part order: ", m_order));
         else m_order = params.new_ticket;
         result = erTryOrderCloseHalf;
         return;   
   }
   
   if (OrderProfit() <= 0) return;
   
   //3.
   sl = 0;
   double open_price = 0;
   int cmd = -1;
   findFixing(sl, cmd, open_price);
   if (cmd < 0) return;
   
   if ((OrderType() == OP_BUY && cmd == OP_SELLSTOP) ||
         (OrderType() == OP_SELL && cmd == OP_BUYSTOP))
   {
      int code = 0;
      LStaticTrade::tryOrderClose(m_order, code, m_slip);
      if (code != 0) err(StringConcatenate("FL4MA_Couple::checkOpenedState  ERR close order: ", m_order));
      result = erClosingOrder;   
   }
   
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
      case PERIOD_M15:  return PERIOD_M30;
      case PERIOD_M30:  return PERIOD_H1;
      case PERIOD_H1:   return PERIOD_H4;
      case PERIOD_H4:   return PERIOD_D1;
      default: break;
   }
   return PERIOD_H1;
}
int FL4MA_Couple::tf3(int tf)
{
   switch(tf)
   {
      case PERIOD_M1:   return PERIOD_M15;
      case PERIOD_M5:   return PERIOD_M30;
      case PERIOD_M15:  return PERIOD_H1;
      case PERIOD_M30:  return PERIOD_H4;
      case PERIOD_H1:   return PERIOD_D1;
      case PERIOD_H4:   return PERIOD_W1;
      default: break;
   }
   return PERIOD_H4;
}


  