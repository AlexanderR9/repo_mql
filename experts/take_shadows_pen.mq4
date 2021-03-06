//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/ldatetime.mqh>
#include <mylib/lprice.mqh>
#include <mylib/lstatictrade.mqh>
#include <mylib/lcontainer.mqh>


#define MAIN_TIMER_INTERVAL      10
#define CLOSE_TIME               22

enum TrateTypes { 
                  ttAll = 20,    //All
                  ttOnlyBuy,     //Only BUY
                  ttOnlySell     //Only SELL
                };

//input int U_TimeFrame = PERIOD_D1; //Timeframe
input int U_NeedShadowPips = 7; //Shadow pips
input int U_StopLossPips = 0; //Stop loss pips
input int U_PendingPips = 5; //Pending pips

input double U_StartLot = 0.1; //Start lot
input double U_LotFactor = 2.5; //Lot factor
input int U_MaxStep = 4; //Max loss step
input int U_StepLower = 0; //Step lower
input int U_StepUpper = 1; //Step upper
input int U_Slip = 2; //Slip page
input TrateTypes U_TradeType = ttAll; //Trade type


struct LossInfo
{
   LossInfo() {reset();}
   
   bool last_loss_buy;
   bool last_loss_sell;
   
   int loss_buy_count;
   int loss_sell_count;
   int loss_buy_next; //сколько раз была ситуация, лось бай сразу же после такого же лося
   int loss_sell_next; //сколько раз была ситуация, лось sell сразу же после такого же лося
   
   void win() {last_loss_buy = last_loss_sell = false;}
   void lossBuy()
   {
      loss_buy_count++;
      if (last_loss_buy) loss_buy_next++;
      last_loss_buy = true;
      last_loss_sell=false;
   }
   void lossSell()
   {
      loss_sell_count++;
      if (last_loss_sell) loss_sell_next++;
      last_loss_sell = true;
      last_loss_buy=false;
   }   
   void reset()
   {
      last_loss_buy=last_loss_sell=false;
      loss_buy_count = loss_sell_count = loss_buy_next = loss_sell_next = 0;
   }
   string toStr() const
   {
      string s = StringConcatenate("LossInfo: loss orders  buy/sell = ", loss_buy_count, "/", loss_sell_count);
      s = StringConcatenate(s, "     loss next buy/sell = ", loss_buy_next, "/", loss_sell_next);
      return s;
   }
   
};


struct State
{
   State() {reset();}

   int step;
   int max_step;
   int pending_orders; //число выставленных ордеров
   int opened_orders; //число сработавших ордеров
   int win_orders;
   int loss_orders;
   int was_bars;
   int average_loss_pips;
   double sum_lots;
   int open_errs;
   int close_errs;
   int check_errs;
   double result_sum;
   int close_count;
   int full_loss;
   
   int last_result_pips;
   
   double winPercent() const
   {
      if (opened_orders == 0) return -1;
      double d = double(win_orders)/double(opened_orders);
      return double(d*100);
   }
   string errs() const
   {
      string s = StringConcatenate("Errors:  check/open/close = ", check_errs, "/", open_errs, "/", close_errs);
      return s;
   }
   
   void reset() 
   {
      step = 1;
      max_step=loss_orders=average_loss_pips=was_bars=close_count=full_loss=0;
      pending_orders=opened_orders=win_orders=0;
      open_errs = close_errs = 0; 
      last_result_pips = 0;
      sum_lots=result_sum=0;
   }
   void win()
   {
      if (U_StepLower <= 0) step = 1;
      else step -= U_StepLower;
      if (step < 1) step = 1;
   }
   void loss()
   {
      if (U_MaxStep == 1) {step = 1; return;}
      
      if (step > max_step) max_step = step;
      
      step += U_StepUpper;
      if (step > U_MaxStep) 
      {
         step = 1;
         full_loss++;
         Print("**************FULL LOSS***********************");   
      }
   }
};



//working vars
bool on_tick_event = true; //если true то советник работает в событии OnTick() иначе в OnTimer()
datetime last_exec_time; //используется только при on_tick = true чтобы отлавливать интервалы MAIN_TIMER_INTERVAL
string m_couple = "";
int m_tf = 0;
State m_state;
int ticket_buy;
int ticket_sell;
datetime last_bet_time;
LIntList loss_stat;
LossInfo l_info;


//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   last_exec_time = last_bet_time = TimeLocal();
   m_couple = Symbol();
   //m_tf = PERIOD_CURRENT;
   m_tf = PERIOD_D1;
   ticket_buy = ticket_sell = -1;
   
   EventSetTimer(MAIN_TIMER_INTERVAL);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   Print("was_bars/loss=", m_state.was_bars,"/", loss_stat.count(), " full_loss=", m_state.full_loss,
      "  average loss=", DoubleToStr(loss_stat.average(), 1), 
      "  max step=", m_state.max_step, "  sum_lot=", DoubleToStr(m_state.sum_lots, 1), 
      "  pending/opened/wins/closed = ", m_state.pending_orders, "/", m_state.opened_orders,"/", 
      m_state.win_orders, "(", DoubleToStr(m_state.winPercent(), 1), "%)", "/", m_state.close_count);
      
   Print(l_info.toStr());      
   Print(m_state.errs());      
   
}
void OnTick()
{
   if (on_tick_event)
   {
      if (nextExec()) mainExec();
   }
}
void OnTimer()
{
   if (on_tick_event) return;
   mainExec();
   
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void mainExec()
{
   if (ordersOpened() && isCloseTime())
   {
      if (ticket_sell > 0) closeOrder(ticket_sell);
      if (ticket_buy > 0) closeOrder(ticket_buy);
      checkResult();
      return;
   }

   if (waitNextBet())
   {
      if (isOpeningTime())
         tryOpen();
   }
   else checkResult();
}
bool ordersOpened()
{
   return (ticket_buy > 0 || ticket_sell > 0);
}
bool waitNextBet()
{
   return (ticket_buy < 0 && ticket_sell < 0);
}
bool isCloseTime()
{
   return (TimeHour(TimeLocal()) >= CLOSE_TIME);
}
bool isOpeningTime()
{
   if (TimeDay(TimeLocal()) != TimeDay(last_bet_time))
   {
      if (LBar::size(m_couple, m_tf, 0) < 5) return true;
   }
   return false;
}
void checkResult()
{
   if (ticket_sell > 0) checkOrder(ticket_sell);
   if (ticket_buy > 0) checkOrder(ticket_buy);

   if (waitNextBet())
   {
      if (m_state.last_result_pips < 0)
      {
         loss_stat.append(m_state.last_result_pips);
         m_state.loss();
         //Print("loss pips: ", m_state.last_result_pips, "   average=", DoubleToStr(loss_stat.average(), 1));
      }
      else if (m_state.last_result_pips > needWinPips()) {m_state.win(); l_info.win();}
      else m_state.step--; //ни то ни се, пропуск этого шага, остались на том же месте
   }
}
void checkOrder(int &ticket)
{
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(ticket, info);
   if (info.isError())
   {
      m_state.check_errs++;
      ticket = -1;         
      Print("Error check order, code=", info.err_code);
   }
   else if (info.isFinished())
   {
      m_state.sum_lots += OrderLots();
      m_state.result_sum += info.totalResult();
      m_state.last_result_pips += int(info.result_pips);
      m_state.opened_orders++;
      
      if (info.isWin())
      {
         m_state.win_orders++;
      }
      else
      {
         m_state.loss_orders++;
         if (ticket == ticket_buy) l_info.lossBuy();
         else l_info.lossSell();
      }  
      
      ticket = -1;    
   }
}
void tryOpen()
{
   LOpenPendingOrder params(m_couple, nextLot(), OP_BUYLIMIT);
   params.setStops(U_StopLossPips, U_NeedShadowPips, true);
   params.price = 0;
   params.d_price = U_PendingPips;
   
   if (canBuy())
   {
      LStaticTrade::setPendingOrder(ticket_buy, params);
      if (params.isError()) m_state.open_errs++;
      else m_state.pending_orders++;
   }

   if (canSell())
   {
      params.type = OP_SELLLIMIT;
      LStaticTrade::setPendingOrder(ticket_sell, params);
      if (params.isError()) m_state.open_errs++;
      else m_state.pending_orders++;
   }

   if (ordersOpened())
   {
      Print("last result pips ", m_state.last_result_pips, ",  current step ", m_state.step);
      m_state.was_bars++;
      last_bet_time = TimeLocal();
      m_state.last_result_pips = 0;
   }
}
void closeOrder(int &ticket)
{
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(ticket, info);
   if (info.isError())
   {
      Print("closeOrder() ERR check orcder state, code=", info.err_code);
      ticket = -1;
      m_state.check_errs++;
      return;
   }
   
   int err = 0;
   if (info.isPengingNow())
   {
      LStaticTrade::deletePendingOrder(ticket, err);
      if (err != 0) Print("closeOrder() ERR delete pending order, code=", err);
      else ticket = -1;
   }
   else if (info.isOpened())
   {
      LStaticTrade::tryOrderClose(ticket, err, U_Slip);
      m_state.close_count++;
      if (err < 0)
      {
         m_state.close_errs++;
         Print("closeOrder(): Error close order: code=", err);
      }
   }
}
double nextLot()
{
   double lot = U_StartLot;
   if (m_state.step > 1)
      for (int i=1; i<m_state.step; i++) lot *= U_LotFactor;
   return NormalizeDouble(lot, 2);   
}
bool nextExec()
{
   int n = LDateTime::dTime(last_exec_time, TimeLocal());
   if (n >= MAIN_TIMER_INTERVAL)
   {
      last_exec_time = TimeLocal();
      return true;
   }
   return false;
}
bool canBuy() {return (U_TradeType == ttAll || U_TradeType == ttOnlyBuy);}
bool canSell() {return (U_TradeType == ttAll || U_TradeType == ttOnlySell);}
int needWinPips()
{
   if (U_TradeType == ttAll) return int(1.5*U_NeedShadowPips);
   return int(0.7*U_NeedShadowPips);
}
