//+------------------------------------------------------------------+
//|                                                 fl4ma_couple.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <fllib/lstatictrade.mqh>

#define FL4MA_MAGIC     111

struct FLMA_State_i
{
   FLMA_State_i() :bar_index(-1) {reset();}
   FLMA_State_i(int i_bar) :bar_index(i_bar) {reset();}

   int bar_index; //индекс текущего бара
   double v5; //значение ema5 текущего бара
   double dv_5_20_cur; //текущая разница между  ema5[i] и ema20[i] (расстояние), т.е. если больше нуля то линия ema5 над ema20 

   //разница между  ema5[i] и ema5[i+1], т.е. если больше нуля то значение выросло
   double dv5_prev;  
   
   //показатель, как повели себя линии ema5 и ema20 относительно прошлого бара
   // -1 - расстояние между линиями уменьшилось
   //  0 - произошло пересечение
   //  1 - расстояние между линиями увеличилось
   int dv_5_20_prev; 
              
   void reset() {v5 = dv5_prev = dv_5_20_cur = dv_5_20_prev = 0;}              
   bool invalid() const {return (bar_index < 0);}
   
};

class FL4MA_Couple
{
public:
   enum ExecResult {erNone = 35, erOpenedOrder, erClosingOrder, erHasError, erOrderGoneHistory};
   enum MarketSituation {msNone = 135, msTrendDown, msTrendUp, msFlat};

   FL4MA_Couple(string v) :m_couple(v) {reset();}
   
   void exec(int&);
   void setParams(int tf, double lot, int slip);
   
   
   static int tf2(int);
   static int tf3(int);

protected:
   string m_couple;   
   int m_period;
   int m_slip;
   double m_lot;
   
   //state vars
   int m_order;
   LOpenPosParams open_params; 
   
   void reset() {m_period = PERIOD_M15; m_slip = 10; m_lot = 0.1; m_order = -1;}
   bool isOrderOpened() const {return (m_order > 0);}
   void chekOrderState(int&); //проверить состояние открытого ордера
   void chekMarketState(); //проверить состояние рынка на предмет обнаружения точки входа
   void tryOpenOrder(int&); //открыть ордер
   void err(string s);
   int currentSituation(int tf) const; //текущая ситуациа на рынке при заданнов периоде
   void calcSlTp(); //определить уровни стопа и тейка для открытия ордера
   string comment() const {return "fl_4ma";}
   
}; 
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
int FL4MA_Couple::currentSituation(int tf) const
{
   const int n = 100;
   FLMA_State_i arr[];
   ArrayResize(arr, n);
   
   for (int i=0; i<n; i++)
   {
      double v5 = iMA(m_couple, tf, 5, 0, MODE_EMA, PRICE_CLOSE, i);
      double v20 = iMA(m_couple, tf, 20, 0, MODE_EMA, PRICE_CLOSE, i);
      
      arr[i].bar_index = i;
      arr[i].v5 = v5;
      arr[i].dv_5_20_cur = v5 - v20;
      
      
      //for [i-1]
      if (i > 0)
      {
         arr[i-1].dv5_prev = arr[i-1].v5 - v5;
         
         double prev = arr[i].dv_5_20_cur;
         double cur = arr[i-1].dv_5_20_cur;
         
         if (prev > 0 && cur <= 0) arr[i-1].dv_5_20_prev = 0;
         else if (prev < 0 && cur >= 0) arr[i-1].dv_5_20_prev = 0;
         else if (MathAbs(prev) < MathAbs(cur)) arr[i-1].dv_5_20_prev = 1;
         else arr[i-1].dv_5_20_prev = -1;  
      }
   }
   
   
   ArrayFree(arr);
   return msNone;
}
void FL4MA_Couple::calcSlTp()
{
   open_params.stop_pips = false;
}
void FL4MA_Couple::exec(int &result_code)
{
   result_code = erNone;
   if (isOrderOpened())
   {
      chekOrderState(result_code);
      return;
   }
   
   open_params.reset();
   chekMarketState();
   if (open_params.type < 0) return;
   
   tryOpenOrder(result_code);
}
void FL4MA_Couple::chekMarketState()
{
   int situation1 = currentSituation(m_period);
   int situation2 = currentSituation(tf2(m_period));
   int situation3 = currentSituation(tf3(m_period));
   
   switch (situation1)
   {
      case msTrendUp:
      {
         if (situation1 == situation2 && situation1 == situation3) //все тренды совпадают
         {
            Print("Find trend UP");
            open_params.type = OP_BUY;
         }
         break;
      }
      case msTrendDown:
      {
         if (situation1 == situation2 && situation1 == situation3) //все тренды совпадают
         {
            Print("Find trend down");
            open_params.type = OP_SELL;
         }         
         break;
      }
      case msFlat:
      {
         break;
      }
      default: break;
   }
}
void FL4MA_Couple::tryOpenOrder(int &result)
{
   open_params.couple = m_couple;
   open_params.lots = m_lot;
   open_params.slip = m_slip;
   open_params.comment = comment();
   open_params.magic = FL4MA_MAGIC;
   
   calcSlTp();
   
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


  