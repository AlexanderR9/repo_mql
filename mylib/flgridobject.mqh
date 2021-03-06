//+------------------------------------------------------------------+
//|                                                       flgrid.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
#include <mylib/lgridpanel.mqh>
#include <fllib1/flgridstructs.mqh>
#include <mylib/lstatictrade.mqh>


#define NOMRMALIZE_LOT_DIGIST    2
#define FLGRID_SLIP_PAGE         100
#define PANEL_COLUMNS            4
#define OPEN_CANDLE_SECONDS      30 //в течении какого времени после открытия свечи надо успеть открыть очередной ордер
#define LOSS_ERR_VALUE           -9999
#define MAX_CLOSE_GRID_ERRS      3 //максимальное количество ошибок при закрытии сетки, посли чего сетка сбрасывается



/////////////////////////////////////
class LFLGrid
{
public:
   enum ExecResult {erLookNextGrid = 60, erFinishExecuting, erOpenedGridOrder, erOpenedHedgeOrder, 
            erHasError, erGetedProfit, erGridClosed, erGridBreak};

   LFLGrid() {reset();}
   //LFLGrid(int number);
   
   //main working func
   void exec(int &result, string &err);
   
   void setLotParams(double, double, double);
   void setOtherParams(int, int, int, int);
   void loadState(); //требуется при перезапуске, проводит поиск текуших открытых ордеров (только для 1-й сетки)
   void saveState(); //требуется при перезапуске/отключении советника
  // void testShowPanel(); //тестовая функция

   //set
   inline void setNumber(int n) {m_number = n;}
   inline void setTradeKind(int kind) {m_state.trade_kind = kind;}
   inline void setUpwardMetod(bool b) {m_params.lossoff_upward_metod = b;}
   inline void setMagic(int m) {m_state.magic = m;}   
   inline void setHedgeFactor(int hf) {m_params.hedge_profit = hf;}
   //inline void setProfitMomentObject(FLGridProfitMoment *m) {last_profit_moment = m;}   
   //get
   inline int hedgeFactor() const {return m_params.hedge_profit;}
   inline int number() const {return m_number;}
   inline int tradeKind() const {return m_state.trade_kind;}
   inline bool invalid() const {return (m_number < 1 || m_state.magic < 0 || m_state.invalidTradeKind());}
   inline bool hedgingNow() const {return (m_state.hedge_order > 0);} //признак того что в текущий момент сетка хеджируется (m_hedgeOrder > 0)
   inline bool isSellGrid() const {return (m_state.trade_kind == OP_SELL);}
   inline bool isBuyGrid() const {return (m_state.trade_kind == OP_BUY);}
   inline bool notWorking() const {return m_state.ordersEmpty();} //признак того что сетка еще не начинала работать, не открыто ни одного ордера
   inline double lastProfit() const {return m_state.last_profit;}
   inline bool needClose() const {return m_state.need_close;} //признак того что эту сетку надо закрывать
   
   
   static string orderComment(int grid_number, int step) {return ("grid"+IntegerToString(grid_number)+" / "+"step"+IntegerToString(step));}
   static string hedgeComment(int grid_number) {return ("gridlock"+IntegerToString(grid_number));}
   static int pricesDiff(double p1, double p2); //разница между ценами в пунктах (для текущего инструмента)
   static double normalizeValue(double value, int dig); //приводит вещественное число к заданному числу знаков
   
   double maxGridLot() const; //вернет потенциальный суммарный лот всех ордеров сетки, не включая хеджирующий, т.е. хеджирующий должен быть такой же
   double lastOrderLot() const;  //вернет лот последнего открытого ордера
   double openedOrderSLot() const;  //вернет суммарный лот текущих открытых ордеров (не хеджированной сетки)
   double hedgeLoss() const {return m_state.loss_values.sumValues();} //суммарный убыток всех ордеров сетки (включая своп и коммисии) на момент хеджирования
   void applyOtherProfit(double profit); //погсить текущие убытки за счет профита другой сетки
   double currentPL() const; ////текущий суммарный результат всех ордеров сетки (не хеджированной), (включая своп и коммисии)
   void setRepayOpened(double &sum);// {need_opened_repay = true; opened_repay_sum = sum;}
   //последний суммарный результат работы всех ордеров открытой сетки включая комиссию и свопы (в валюте счета), ПОСЛЕ ИХ ЗАКРЫТИЯ.
   double lastClosedResult() const;

protected:
   int m_number; //номер сетки 1..10   
   FLGridInputParams m_params; //входные параметры работы сетки
   FLGridState m_state; //текущее состояние сетки
   LGridPanel m_panel; //объект для отображения панели
   //FLGridProfitMoment *last_profit_moment;
   
   //opened repay
   //bool need_opened_repay;
   //double opened_repay_sum;
   
   //load funcs
   void reset();
   int stepByCommect(string s) const;
   void findCurrentOrders(); //при перезапуске проводит поиск текуших открытых ордеров (надо выполнить только для 1-й сетки)

   //trade funcs
   void tryOpenNextGridOrder(int &result, string &err); //открывает очередной ордер сетки
   void tryOpenHedgeOrder(int &result, string &err); //открывает хеджирующий ордер сетки
   void tryCloseAllOrders(string &err); //попытка закрыть все ордера сетки т.е. сетка вышла в нужный профит (хеджирующего нет в данной ситуации)
   bool selectLastOrder() const; //пытается выполнить OrderSelect для последнего ордера
   void lossLiquidation(int ticket, double &profit); //погасить часть/весь убыток для заданного ордера
   
   bool nextTradeMoment() const; //признак того что настал монет для открытия очередного ордера сетки (хеджирующего в том числе)
   void saveLossValues(); //сохранить текущие значения убытков в контейнер m_lossValues
   bool needCloseGrid() const {return m_state.need_close;} //признак состояния закрытия всех ордеров сетки
   //void updateProfitMoment_profitinfo();
   //void updateProfitMoment_hedgeinfo();
   
   
   
   double stepLot(int step) const; //возвращает размер лота для заданного шага, если step <= 0, то вернет -1
   bool gridLotsOver() const; //признак того что сумарный лот сетки превысил допустимый и дальше надо хеджирования
   int lastCandleCount() const; //сколько свечей закрылось после открытия последнего ордера
   bool openTimeCandleNow() const; //признак того что сейчас наступило всемя открытия свечи
   double coupleCurentPrice() const; //текущая цена инструмента (ask или buy) взависимости от m_tradeKind
   double coupleCurentPrice(int cmd) const; //текущая цена инструмента (ask или buy)
   double currentClosePrice() const;
   int hedgeCmd();
   void reinitPanel(); //инициализация панели перед отображением
   void startPanel(); //запуск панели в момент хеджирования
   void updatePanel(); //обновление панели после погашения части убытков
   int orderMagic() const;
   void tradeReset(); //сбрасывает состояние сетки
   bool profitSuccessed() const; //признак того что профит сетки достигнут и надо закрывать сетку
   void checkHeadgeState(); //проверить текущие убытки
   void findNewHedgeTicket();//посик нового тикета хеджирующего ордера после частичного закрытия
   
   //текущая разница (в пунктах) между ценой открытия последнего ордера и  coupleCurentPrice()
   //значение также зависит от m_tradeKind.
   //значение может быть как положительным так и отрицательным, (отрицательное - убыток и наоборот соответственно)
   int lastPriceDistance() const; //текущая разница (в пунктах) между ценой открытия последнего ордера и  coupleCurentPrice()
   
   //текущий суммарный результат работы всех открытых ордеров сетки включая комиссию и свопы (в валюте счета).
   //значение имеет смысл пока сетка не захеджирована.
   //значение может быть как положительным так и отрицательным, (отрицательное - убыток и наоборот соответственно).
   double currentResult(double &grid_lot) const;
      
   

};


//description LFLGrid
void LFLGrid::exec(int &result, string &err)
{
   err = "";
   result = erFinishExecuting; //закончить выполнение сеток в этом цикле
   
   if (hedgingNow())
   {
      result = erLookNextGrid; //если сетка уже захеджирована перейти к следующей сетке
      return;
   }
   
   if (m_params.invalid())
   {
      result = erGridBreak; //начиная с этой сетки не принимать в работу
      return;
   }
   
   if (needCloseGrid()) //закрываем открытую сетку
   {
      tryCloseAllOrders(err);
      if (err != "") 
      {
         result = erHasError;
         m_state.close_errs++;
         if (m_state.close_errs >= MAX_CLOSE_GRID_ERRS)
         {
            m_state.last_profit = lastClosedResult();
            tradeReset();   
         }
      }
      else 
      {
         m_state.last_profit = lastClosedResult();
         result = erGridClosed;
         tradeReset();
      }
      return;
   }
   
   if (profitSuccessed())
   {
      double x = 0;
      //m_state.last_profit = currentResult(x);
      m_state.last_profit = 0;
      m_state.need_close = true;
      result = erGetedProfit;
      //updateProfitMoment_profitinfo();
      return;
   }
   
   if (notWorking())
   {
      tryOpenNextGridOrder(result, err); //если нет открытых ордеров для этой сетки, то просто открываем 1-й ордер (прямо сейчас)
      return;
   }
   
   if (nextTradeMoment()) //выполнилось условие для открытия очередного ордера
   {
      Print("Need next open order now!!!");
      if (gridLotsOver()) //превышен допустимый суммарный лот сетки
      {
         tryOpenHedgeOrder(result, err); //открываем хеджирующий ордер
         if (hedgingNow())
         {
            saveLossValues();
            startPanel();
         }
      }
      else tryOpenNextGridOrder(result, err); //отркываем очередной ордер сетки
   }
}
double LFLGrid::lastOrderLot() const
{
   if (m_state.ordersEmpty()) return 0;
   int ticket = m_state.orders.last();
   return m_state.lots_values.value(ticket);
}
double LFLGrid::openedOrderSLot() const
{
   return m_state.lots_values.sumValues();
}
/*
void LFLGrid::updateProfitMoment_profitinfo()
{
   last_profit_moment.reset();
   last_profit_moment.grid_number = number();
   
   int n = m_state.orders.count();
   for (int i=0; i<n; i++)
   {
      int ticket = m_state.orders.at(i);
      last_profit_moment.lots.insert(ticket, m_state.lots_values.value(ticket));
   }
}
void LFLGrid::updateProfitMoment_hedgeinfo()
{
   //last_profit_moment.
}
*/
double LFLGrid::normalizeValue(double value, int dig)
{
   if (dig < 0) return -9999;
   int k = int(MathPow(10, dig));
   double result = MathRound(k*value); 
   return (result/k);
}
void LFLGrid::tradeReset()
{
   m_state.tradeReset();
   m_panel.destroy();
}
int LFLGrid::orderMagic() const
{
   return m_state.magic;
}
void LFLGrid::saveLossValues()
{
   //Print("*****************************LFLGrid::saveLossValues()***************************************");
   m_state.loss_values.clear();
   m_state.lossoff_indexes.clear();
   if (m_state.ordersEmpty()) return;
   
   int n = m_state.ordersCount();
   for (int i=0; i<n; i++)
   {
      int ticket = m_state.orders.at(i);
      if (OrderSelect(ticket, SELECT_BY_TICKET)) 
      {
         double x1 = OrderProfit();
         double x2 = OrderCommission();
         double x3 = OrderSwap();
         double loss = m_params.hedgeFactor()*(x1+x2+x3);
         m_state.loss_values.insert(ticket, loss);
         m_state.profit_values.insert(ticket, 0);
         
         //Print("saveLossValues()  ticket=", ticket, "  loss=", loss, "  index=", i);
      }
      else m_state.loss_values.insert(ticket, LOSS_ERR_VALUE);         
   }
   ///////////////////////////////////////
   
   LMapIntDouble map(m_state.loss_values);
   while (!map.isEmpty())
   {
      LIntDoublePair it = (m_params.lossoff_upward_metod ? map.maxValueIterator() : map.minValueIterator());
      int pos = m_state.orders.indexOf(it.key);
      m_state.lossoff_indexes.append(pos);
      //Print("find lossoff_indexes: pos=", pos, "  ticker=", it.key, "  loss=", it.value);
      map.remove(it.key);
   }
}
bool LFLGrid::profitSuccessed() const
{
   if (hedgingNow()) return false;
   if (notWorking())  return false;
   
   double grid_lot = 0;
   double x = currentResult(grid_lot);
   if (x <= 0) return false;
   
   double pipce_price = grid_lot*MarketInfo(Symbol(), MODE_TICKVALUE);
   double must_profit = m_params.profit_points*pipce_price;
   return (x > must_profit);
}
double LFLGrid::currentPL() const
{
   if (hedgingNow()) return 0;
   
   double lot = 0;
   double result = currentResult(lot);
   return result;
}
double LFLGrid::lastClosedResult() const
{
   if (m_state.ordersEmpty()) return 0;
   double closed_result = 0;
   
   LCheckOrderInfo info;
   int n = m_state.ordersCount();
   for (int i=0; i<n; i++)
   {
      LStaticTrade::checkOrderState(m_state.orders.at(i), info);
      if (info.isError()) {Print("LFLGrid::lastClosedResult() ERR check state order ", m_state.orders.at(i), "  err=", info.err_code); continue;}
      if (info.isHistory()) closed_result += info.totalResult();
   }
   return closed_result;
}
double LFLGrid::currentResult(double &grid_lot) const
{
   if (m_state.ordersEmpty()) return 0;
   
   double sum = 0;
   int n = m_state.ordersCount();
   for (int i=0; i<n; i++)
   {
      if (OrderSelect(m_state.orders.at(i), SELECT_BY_TICKET)) 
      {
         sum += OrderProfit();
         sum += OrderCommission();
         sum += OrderSwap();
         grid_lot += OrderLots();
      }
   }
   return sum;
}
double LFLGrid::coupleCurentPrice() const
{
   switch (m_state.trade_kind)
   {
      case OP_BUY: return MarketInfo(Symbol(), MODE_ASK);
      case OP_SELL: return MarketInfo(Symbol(), MODE_BID);
      default: break;
   }
   return -1;
}
double LFLGrid::coupleCurentPrice(int cmd) const
{
   switch (cmd)
   {
      case OP_BUY: return MarketInfo(Symbol(), MODE_ASK);
      case OP_SELL: return MarketInfo(Symbol(), MODE_BID);
      default: break;
   }
   return -1;
}
bool LFLGrid::selectLastOrder() const
{
   if (m_state.ordersEmpty()) return false;
   int ticket = m_state.orders.last();
   if (!OrderSelect(ticket, SELECT_BY_TICKET))
   {
      Print("ERR: !OrderSelect(), ticket=", ticket);
      return false;
   }   
   return true;
}
int LFLGrid::lastPriceDistance() const
{
   if (!selectLastOrder()) return 0;
   int dp = pricesDiff(OrderOpenPrice(), coupleCurentPrice());
   if (isSellGrid()) dp *= (-1);
   return dp;
}
int LFLGrid::pricesDiff(double p1, double p2)
{
   int dig_factor = int(MathPow(10, int(MarketInfo(Symbol(), MODE_DIGITS))));
   double dp = p2 - p1;
   return int(MathRound(dp*dig_factor));
}
int LFLGrid::lastCandleCount() const
{
   if (!selectLastOrder()) return -1;
   
   datetime dt = OrderOpenTime();
   int n = 0;
   for (int i=0; i<1000; i++)
   {
      if (iTime(Symbol(), Period(), i) > dt) n++;
      else break;  
   }
   return n;
}
bool LFLGrid::openTimeCandleNow() const
{
   datetime dt_open = iTime(Symbol(), Period(), 0);   
   datetime dt_now = TimeCurrent();
   int d = int(dt_now - dt_open);
   return (d < int(OPEN_CANDLE_SECONDS));
}
int LFLGrid::hedgeCmd()
{
   switch (m_state.trade_kind)
   {
      case OP_BUY: return OP_SELL;
      case OP_SELL: return OP_BUY;
      default: break;
   }
   return -1;
}
bool LFLGrid::nextTradeMoment() const
{
   if (!openTimeCandleNow()) return false;
   //Print("Begin candle now,  lastCandleCount ", lastCandleCount());
   if (lastCandleCount() < m_params.candle_step) return false;
   int d_pips = lastPriceDistance();
   //Print("d_pips ", d_pips);
   if (d_pips >= 0) return false;
   return (MathAbs(d_pips) >= m_params.order_distance);
}
double LFLGrid::stepLot(int step) const
{
   if (step <= 0) return -1;

   double lot = m_params.start_lot;
   if (step > 1)
   {
      for (int i=2; i<=step; i++)
         lot *= m_params.lot_factor;
   }
   return NormalizeDouble(lot, NOMRMALIZE_LOT_DIGIST);
}
double LFLGrid::maxGridLot() const
{
   double sum = m_params.start_lot;
   for(int step=2; step<1000; step++)
   {
      double lot = stepLot(step);
      if ((sum+lot) > m_params.lot_hedge_level) break;
      sum += lot;
   }
   return sum;
}
bool LFLGrid::gridLotsOver() const
{
   int n = m_state.orders.count()+1;
   if (n < 2) return false;
   
   double sum = 0;
   for (int i=0; i<n; i++)
      sum += stepLot(i+1);
      
   return (sum >= m_params.lot_hedge_level);
}
void LFLGrid::lossLiquidation(int ticket, double &profit)
{
   double order_loss = m_state.loss_values.value(ticket); //текущий убыток орера (на момент хеджирования)
   double order_profit = m_state.profit_values.value(ticket); //текущий профит
   
   if (MathAbs(order_loss) > profit) order_profit += profit;
   else order_profit += MathAbs(order_loss);
   m_state.profit_values.insert(ticket, order_profit);
   
   profit += order_loss; //то что останется от профита после погашения убытка   
   if (profit >= 0) //убыток погашен и необходимо закрыть ордер, а также закрыть часть лота хеджирующего ордера
   {
      double lot = m_state.lots_values.value(ticket); //размер лота ордера с котором он был открыт
      //last_profit_moment.repay_lots.insert(ticket, lot);
      //last_profit_moment.repay_profits.insert(ticket, 0);
      
      double price = currentClosePrice();
      int slip = FLGRID_SLIP_PAGE;   
      if (!OrderClose(ticket, lot, price, slip)) //закрываем погашеный ордер
         Print(StringConcatenate("lossLiquidation() ERR: can not OrderClose() order ", ticket));
           
      //last_profit_moment.hedge_profits.insert(m_state.hedge_order, 0);

      price = coupleCurentPrice();
      if (!OrderClose(m_state.hedge_order, lot, price, slip)) //закрываем часть хеджирующего ордера
         Print(StringConcatenate("lossLiquidation() ERR: can not OrderClose() hedge order ", m_state.hedge_order));
      else findNewHedgeTicket();   //находим новый тикет хеджирующего ордера
   }
}
void LFLGrid::applyOtherProfit(double profit)
{
   int n = m_state.lossoff_indexes.count();
   if (n == 0) {Print("ERR: LFLGrid::applyOtherProfit() lossoff_indexes is empty"); return;}

   for (int i=0; i<n; i++)
   {
      int pos = m_state.lossoff_indexes.at(i); //текущая позиция в контейнере m_state.orders
      int ticket = m_state.orders.at(pos); //текущий тикет, убыток которого надо ликвидировать
      double order_loss = m_state.loss_values.value(ticket); //текущий убыток орера (на момент хеджирования)
      if (order_loss == 0) continue; //текущий убыток орера уже был ликвидирован
      
      lossLiquidation(ticket, profit);
      if (profit <= 0)
      {
         m_state.loss_values.insert(ticket, profit);
         break;
      }
      else m_state.loss_values.insert(ticket, 0);
   }

   updatePanel();
   checkHeadgeState();
}
void LFLGrid::checkHeadgeState()
{
   int n = m_state.ordersCount();
   for (int i=0; i<n; i++)
   {
      int ticket = m_state.orders.at(i);
      if (m_state.loss_values.value(ticket) != 0) return;   
   }
   tradeReset();
}
void LFLGrid::tryCloseAllOrders(string &err)
{
   if (m_state.ordersEmpty())
   {
      err = "tryCloseAllOrders() ERR: orders list is empty";
      return;
   }
   
   int n = m_state.ordersCount();
   for (int i=0; i<n; i++)
   {
      int ticket = m_state.orders.at(i);
      double lot = m_state.lots_values.value(ticket);
      double price = currentClosePrice();
      int slip = FLGRID_SLIP_PAGE;   
      if (!OrderClose(ticket, lot, price, slip))
         err = StringConcatenate("tryCloseAllOrders() ERR: can not OrderSelect() order ", ticket);
      //else m_state.orders.replace(i, -1);
   }
}
void LFLGrid::setRepayOpened(double &repay_sum)
{
   if (m_state.ordersEmpty())
   {
      Print("setRepayOpened() ERR: orders list is empty");
      return;
   }
   
   Print("TRY REPAY OPENED GRID, ", Symbol(), "  repay_sum=", repay_sum);
   
   //находим все ордера с текущими отрицательными результатами
   int n = m_state.ordersCount();
   LMapIntDouble pl_list;
   for (int i=0; i<n; i++)
   {
      if (!OrderSelect(m_state.orders.at(i), SELECT_BY_TICKET)) continue;
      double pl = OrderProfit()+OrderSwap()+OrderCommission();
      Print("i=",i ,  "    pl=", pl);
      if (pl >= 0) continue;
      pl_list.insert(m_state.orders.at(i), pl);
   }
   
   //удаляем из контейнера ордера по одному до тех пор пока суммарный убыток не будет превышать доступную сумму для погашения repay_sum
   for (;;)
   {
      double pl_sum = MathAbs(pl_list.sumValues());
      if (repay_sum >= pl_sum) break;
      const LIntDoublePair it = pl_list.maxValueIterator();
      pl_list.remove(it.key);
   }
   
   
   repay_sum = 0; //обнуляем переменную
   LCheckOrderInfo info;   
   const LIntList *keys = pl_list.keys();
   n = keys.count();
   Print("  pl count ", n, "/", m_state.ordersCount());
   if (n <= 0) return;
   
   for (int i=0; i<n; i++)
   {
      int code = 0;
      LStaticTrade::tryOrderClose(keys.at(i), code); //закрываем убыточный ордер открытой сетки 
      if (code == 0)
      {
         LStaticTrade::checkOrderState(keys.at(i), info);
         if (info.isFinished()) repay_sum += info.totalResult(); //подсчитываем реальный закрытый убыток
         Print("   totalResult()=", info.totalResult());
         m_state.orders.removeAt(m_state.orders.indexOf(keys.at(i)));
      }
   }
   
   if (m_state.ordersEmpty()) tradeReset();
}
double LFLGrid::currentClosePrice() const
{
   if (isBuyGrid()) return coupleCurentPrice(OP_SELL);
   return coupleCurentPrice(OP_BUY);
}
void LFLGrid::tryOpenNextGridOrder(int &result, string &err)
{
   int step = m_state.ordersCount() + 1;
   double lot = stepLot(step);
   int slip = FLGRID_SLIP_PAGE;
   string s = orderComment(number(), step);
   double price = coupleCurentPrice();   
   
   Print("tryOpenNextGridOrder, step=", step, "  lot=", lot, "  slip=", slip, "  price=", price, "  Comment=", s);
   int ticket = OrderSend(Symbol(), m_state.trade_kind, lot, price, slip, 0, 0, s, orderMagic());
   if (ticket > 0) 
   {
      result = erOpenedGridOrder;
      m_state.addOrder(ticket, lot);
   }
   else
   {
      result = erHasError;
      err = StringConcatenate("error open order, grid ", number(), "  step=", step, " couple=", Symbol());
   }
}
void LFLGrid::tryOpenHedgeOrder(int &result, string &err)
{
   double lot = maxGridLot();
   int slip = FLGRID_SLIP_PAGE;
   string s = hedgeComment(number());
   int cmd = hedgeCmd();
   double price = coupleCurentPrice(cmd);   
   
   Print("tryOpenHedgeOrder, lot=", lot, "  slip=", slip, "  price=", price, "  Comment=", s);
   int ticket = OrderSend(Symbol(), cmd, lot, price, slip, 0, 0, s, orderMagic());
   if (ticket > 0) 
   {
      result = erOpenedHedgeOrder;
      m_state.hedge_order = ticket;
   }
   else
   {
      result = erHasError;
      err = StringConcatenate("error open hedge order, grid ", number(), " couple=", Symbol());
   }
}
int LFLGrid::stepByCommect(string s) const
{
   if (s == "") return -1;
   for (int i=1; i<100; i++)
      if (s == orderComment(m_number, i)) return i;
   return 0;
}
void LFLGrid::findNewHedgeTicket()
{
   int n = OrdersTotal();
   if (n == 0) return;

   if (m_state.hedge_order <= 0) return;
   string s_ticket = IntegerToString(m_state.hedge_order);
   
   for (int i=0; i<n; i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      string s = OrderComment();
      if (StringFind(s, s_ticket) < 0) continue;
      
      m_state.hedge_order = OrderTicket();
      break;
   }
}
void LFLGrid::findCurrentOrders()
{
   int n = OrdersTotal();
   if (n == 0) return;
   
   int cmd = -1;
   LMapIntDouble map; // key - step, value - ticket 
   LMapIntDouble lots_map; // key - ticket, value - lot 
   
   for (int i=0; i<n; i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != orderMagic()) continue;   
      if (OrderSymbol() != Symbol()) continue;   
      
      if (cmd < 0) cmd = OrderType();
      else if (cmd != OrderType()) continue;
      
      int step = stepByCommect(OrderComment());
      if (step > 0) 
      {
         map.insert(step, OrderTicket());         
         lots_map.insert(OrderTicket(), OrderLots());         
         Print("Finded order=", DoubleToString(map.value(step), 0), "  by step", step);
      }
   }
   
   /////////////////////////////////
   n = map.count();
   if (n == 0) return;
   bool ok = true;
   for (int step=1; step<=n; step++)
   {
      if (!map.contains(step)) {ok = false; break;}
      int ticket = int(map.value(step));
      m_state.addOrder(ticket, lots_map.value(ticket));
   }
   
   if (!ok)
   {
      m_state.orders.clear();
      Print("ERR: findCurrentOrders result");
   }
   else m_state.trade_kind = cmd;
}
void LFLGrid::reset()
{
   m_number = 0;
   m_state.reset();
   m_params.reset();
   //last_profit_moment = NULL;
   //need_opened_repay = false;
   //opened_repay_sum = 0;

}
void LFLGrid::setLotParams(double start_lot, double lot_factor, double lot_hedge_level)
{
   m_params.lot_factor = lot_factor;
   m_params.lot_hedge_level = lot_hedge_level;
   
   double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
   if (start_lot < min_lot) m_params.start_lot = min_lot;
   else m_params.start_lot = start_lot;   
}
void LFLGrid::setOtherParams(int candle_step, int order_distance, int profit_points, int hedge_profit)
{
   m_params.candle_step = candle_step;
   m_params.order_distance = order_distance;
   m_params.profit_points = profit_points;
   m_params.hedge_profit = hedge_profit;
}
void LFLGrid::loadState()
{
   if (invalid()) return;
   
   if (number() == 1)
      findCurrentOrders();
   
   string p_name = "flpanel"+IntegerToString(number());
   m_panel.setName(p_name);
   m_panel.setHaveHeader(true);
   //reinitPanel();
}
void LFLGrid::saveState()
{
   if (invalid()) return;
   
   m_panel.destroy();
   
}
void LFLGrid::startPanel()
{
   if (m_panel.invalid()) return;
   Print("start panel: "+m_panel.panelName());
   
   reinitPanel();
   m_panel.repaint();
   
   m_panel.setHeaderText(0, "Block "+IntegerToString(number()));
   m_panel.setHeaderText(1, " P/L");
   //m_panel.setHeaderText(2, "Liquidation");
   m_panel.setHeaderText(2, "Repay");
   m_panel.setHeaderText(3, "Lot");
   
   updatePanel();
}
void LFLGrid::updatePanel()
{
   int n = m_state.lossoff_indexes.count();
   if (n == 0) {Print("ERR: LFLGrid::applyOtherProfit() lossoff_indexes is empty"); return;}

   for (int i=0; i<n; i++)
   {
      int ticket = m_state.orders.at(m_state.lossoff_indexes.at(i));
      double loss = m_state.loss_values.value(ticket);
      double lot = m_state.lots_values.value(ticket);
      double profit = m_state.profit_values.value(ticket);
      
      m_panel.setCellText(i, 0, IntegerToString(ticket));
      m_panel.setCellText(i, 1, DoubleToString(loss, 2));
      m_panel.setCellText(i, 3, DoubleToString(lot, 2));
      
      string status = "NONE";
      color c = clrNONE;
      if (loss == 0)
      {
         status = "CLOSED";
         c = clrGreen;
      }
      else if (profit > 0)
      {
         status = StringConcatenate("+", DoubleToString(profit, NOMRMALIZE_LOT_DIGIST));
         c = clrBlue; 
      }
      m_panel.setCellText(i, 2, status, c);
   }
   
   //hedge volume
   string text = "??";
   if (OrderSelect(m_state.hedge_order, SELECT_BY_TICKET))
   {
      text = StringConcatenate("Total volume:  ", DoubleToString(OrderLots(), NOMRMALIZE_LOT_DIGIST));
      m_panel.setCellText(n, 0, text);
   }
   else
   {
      Print("LFLGrid::updatePanel() ERR: can not OrderSelect() hedge ticket ", m_state.hedge_order);
      m_panel.setCellText(n, 0, "Total volume:  -1");
   }

   //loss
   text = StringConcatenate("Current loss:  ", DoubleToString(m_state.currentLoss(), NOMRMALIZE_LOT_DIGIST));
   m_panel.setCellText(n+1, 0, text);

}

//инициализация объекта для вывода графической панели
void LFLGrid::reinitPanel()
{
   if (m_panel.invalid()) return;
   
   m_panel.setCorner(pcLeftUp);
   m_panel.setMargin(5);
   m_panel.setBackgroundColor(clrLightGray);
   m_panel.setHeaderTextColor(clrDarkBlue);
   m_panel.setCellsTextColor(clrBlack);
   m_panel.setFontSizes(7, 9);
   m_panel.setHeaderSeparatorParams(clrBlack, 2);
   
   //int test_rows = 7;
   int row_height = 18;
   
   int h = row_height*(m_state.orders.count() + 3);
//   int h = row_height*(test_rows + 3);

   int w = 220;
   m_panel.setSize(w, h);
   int dx = w*(number()-1);
   m_panel.setOffset(10 + dx, 20);
   
   
   //m_panel.setGridSize(test_rows, PANEL_COLUMNS);
   m_panel.setGridSize(m_state.ordersCount()+1+1, PANEL_COLUMNS);
   
   
   LIntList col_sizes;
   col_sizes.append(30);
   col_sizes.append(22);
   col_sizes.append(30);
   col_sizes.append(18);
   m_panel.setColSizes(col_sizes);
}
