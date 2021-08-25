//+------------------------------------------------------------------+
//|                                                       flgrid.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
#include <mylib/lcontainer.mqh>
#include <mylib/lgridpanel.mqh>

#define NOMRMALIZE_LOT_DIGIST    2
#define FLGRID_SLIP_PAGE         100
#define PANEL_COLUMNS            3
#define OPEN_CANDLE_SECONDS      30 //в течении какого времени после открытия свечи надо успеть открыть очередной ордер
#define LOSS_ERR_VALUE           -9999
#define MAX_CLOSE_GRID_ERRS      3 //максимальное количество ошибок при закрытии сетки, посли чего сетка сбрасывается




struct FLGridParams
{
   FLGridParams() {reset();}
   
   double start_lot;         
   double lot_factor;
   double lot_hedge_level;
   int candle_step;
   int order_distance;
   int profit_points; 
   int hedge_profit; //%
      
   bool lossoff_upward_metod; //погашение убытков в сторону увеличения, если true то сначала гасится самый маленький
   
   double hedgeFactor() const {return (1 + double(hedge_profit)/double(100));}
   
   void reset() 
   {
      start_lot = 0.1; lot_factor = 1.1; lot_hedge_level = 2.5;
      candle_step = 2; order_distance = 20; profit_points = 15; hedge_profit = 0;
      lossoff_upward_metod = true;
      
   }
};

/////////////////////////////////////
struct FLGridState
{
   FLGridState() {reset();}

   LIntList orders; 
   int hedge_order;
   bool need_close;
   double last_profit;
   int magic;
   int trade_kind; //тип открытия ордеров сеток
   int close_errs;
   //double current_lot; //текущий суммарный
   
   //когда вся сетка ушла в минус и пришло время открывать хеджирующий ордер
   //в этот момент сюда записываются убытки каждого одера сетки (включая своп и комисию)
   //key - ticket, value - loss
   LMapIntDouble loss_values;
   
   
   //заполняется в тот же момент когда и loss_values.
   //здесь будут хранится индксы ордеров из контейнера orders
   // в том порядке в каком их надо гасить, начиная с 0-го
   //порядок зависит от параметра lossoff_upward_metod
   LIntList lossoff_indexes; 

   
   inline bool invalidTradeKind() const {return ((trade_kind != OP_BUY) && (trade_kind != OP_SELL));}
   inline void addOrder(int ticket) {orders.append(ticket);}
   inline bool ordersEmpty() const {return orders.isEmpty();}
   inline int ordersCount() const {return orders.count();}
   
   void reset()
   {
      orders.clear();
      loss_values.clear();
      lossoff_indexes.clear();
      hedge_order = -1;
      need_close = false;
      last_profit = 0;
      magic = 0;
      trade_kind = -1;
      close_errs = 0;
   }
   void tradeReset()
   {
      orders.clear();
      loss_values.clear();
      lossoff_indexes.clear();
      hedge_order = -1;
      need_close = false;
      last_profit = 0;
      close_errs = 0;   
   }
};


/////////////////////////////////////
class LFLGrid
{
public:
   enum ExecResult {erLookNextGrid = 60, erFinishExecuting, erOpenedGridOrder, erOpenedHedgeOrder, 
            erHasError, erGetedProfit, erGridClosed};

   LFLGrid() {reset();}
   //LFLGrid(int number);
   
   //main working func
   void exec(int &result, string &err);
   void applyOtherProfit(double profit); //погсить текущие убытки за счет профита другой сетки
   
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
   

protected:
   int m_number; //номер сетки 1..10   
   FLGridParams m_params; //входные параметры работы сетки
   FLGridState m_state; //текущее состояние сетки
   LGridPanel m_panel; //объект для отображения панели
   
   //load funcs
   void reset();
   int stepByCommect(string s) const;
   void findCurrentOrders(); //при перезапуске проводит поиск текуших открытых ордеров (надо выполнить только для 1-й сетки)

   //trade funcs
   void tryOpenNextGridOrder(int &result, string &err); //открывает очередной ордер сетки
   void tryOpenHedgeOrder(int &result, string &err); //открывает хеджирующий ордер сетки
   void tryCloseAllOrders(string &err); //попытка закрыть все ордера сетки т.е. сетка вышла в нужный профит (хеджирующего нет в данной ситуации)
   bool selectLastOrder() const; //пытается выполнить OrderSelect для последнего ордера
   
   bool nextTradeMoment() const; //признак того что настал монет для открытия очередного ордера сетки (хеджирующего в том числе)
   void saveLossValues(); //сохранить текущие значения убытков в контейнер m_lossValues
   bool needCloseGrid() const {return m_state.need_close;} //признак состояния закрытия всех ордеров сетки
   
   
   double stepLot(int step) const; //возвращает размер лота для заданного шага, если step <= 0, то вернет -1
   double sumGridLot() const; //вернет потенциальный суммарный лот всех ордеров сетки, не включая хеджирующий, т.е. хеджирующий должен быть такой же
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
   
   if (needCloseGrid())
   {
      tryCloseAllOrders(err);
      if (err != "") 
      {
         result = erHasError;
         m_state.close_errs++;
         if (m_state.close_errs >= MAX_CLOSE_GRID_ERRS) tradeReset();
      }
      else 
      {
         result = erGridClosed;
         tradeReset();
      }
      return;
   }
   
   if (profitSuccessed())
   {
      double x = 0;
      m_state.last_profit = currentResult(x);
      m_state.need_close = true;
      result = erGetedProfit;
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
         tryOpenHedgeOrder(result, err);
         if (hedgingNow())
         {
            saveLossValues();
            startPanel();
         }
      }
      else tryOpenNextGridOrder(result, err);
   }
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
   
   
   // old code
   //int dig_factor = int(MathPow(10, int(MarketInfo(Symbol(), MODE_DIGITS))));
   //int op = int(MathRound(OrderOpenPrice()*dig_factor));
   //int cp = int(MathRound(coupleCurentPrice()*dig_factor));
   //int dp = cp - op;
   //if (isSellGrid()) dp *= (-1);
   
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
double LFLGrid::sumGridLot() const
{
   double sum = m_params.start_lot;
   for(int step=2; step<1000; step++)
   {
      double lot = stepLot(step);
      if ((sum+lot) > m_params.lot_hedge_level) break;
      sum += lot;
   }
   return NormalizeDouble(sum, NOMRMALIZE_LOT_DIGIST);
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
void LFLGrid::applyOtherProfit(double profit)
{
   int n = m_state.lossoff_indexes.count();
   if (n == 0) {Print("ERR: LFLGrid::applyOtherProfit() lossoff_indexes is empty"); return;}

   for (int i=0; i<n; i++)
   {
      int ticket = m_state.orders.at(m_state.lossoff_indexes.at(i));
      double loss = m_state.loss_values.value(ticket);
      if (loss < 0)
      {
         if (OrderSelect(ticket, SELECT_BY_TICKET))
         {
            loss += profit;
            if (loss >= 0)
            {
               m_state.loss_values.insert(ticket, 0);
               double lot = OrderLots();
               double price = currentClosePrice();
               int slip = FLGRID_SLIP_PAGE;   
               if (!OrderClose(ticket, lot, price, slip))
                  Print(StringConcatenate("applyOtherProfit() ERR: can not OrderClose() order ", ticket));
               
               price = coupleCurentPrice();
               if (!OrderClose(m_state.hedge_order, lot, price, slip))
                  Print(StringConcatenate("applyOtherProfit() ERR: can not OrderClose() hedge order ", m_state.hedge_order));
               else findNewHedgeTicket();   
                   
               profit = loss;
            }
            else 
            {
               m_state.loss_values.insert(ticket, loss);
               break;
            }
         }
         else 
         {
            StringConcatenate("applyOtherProfit() ERR: can not OrderSelect() order ", ticket);
            break;
         }
      }
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
      if (!OrderSelect(ticket, SELECT_BY_TICKET))
      {
         err = StringConcatenate("tryCloseAllOrders() ERR: can not OrderSelect() order ", ticket);
         continue;
      }
      
      double lot = OrderLots();
      double price = currentClosePrice();
      int slip = FLGRID_SLIP_PAGE;   
      if (!OrderClose(ticket, lot, price, slip))
         err = StringConcatenate("tryCloseAllOrders() ERR: can not OrderSelect() order ", ticket);
      else m_state.orders.replace(i, -1);
   }
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
      m_state.addOrder(ticket);
   }
   else
   {
      result = erHasError;
      err = StringConcatenate("error open order, grid ", number(), "  step=", step, " couple=", Symbol());
   }
}
void LFLGrid::tryOpenHedgeOrder(int &result, string &err)
{
   double lot = sumGridLot();
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
   LMapIntDouble map; // key - step
   for (int i=0; i<n; i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      //if (OrderMagicNumber() != orderMagic() || OrderType() != m_state.trade_kind) continue;   
      if (OrderMagicNumber() != orderMagic()) continue;   
      if (OrderSymbol() != Symbol()) continue;   
      if (cmd < 0) cmd = OrderType();
      else if (cmd != OrderType()) continue;
      
      int step = stepByCommect(OrderComment());
      if (step > 0) 
      {
         map.insert(step, OrderTicket());         
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
      m_state.addOrder(int(map.value(step)));
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
   m_panel.setHeaderText(2, "Liquidation");
   
   /*
   int n = m_state.lossoff_indexes.count();
   for (int i=0; i<n; i++)
   {
      int ticket = m_state.orders.at(m_state.lossoff_indexes.at(i));
      double loss = m_state.loss_values.value(ticket);
      m_panel.setCellText(i, 0, IntegerToString(ticket));
      m_panel.setCellText(i, 1, DoubleToString(loss, 2));
      m_panel.setCellText(i, 2, "NONE");
   }
   m_panel.setCellText(n, 0, StringConcatenate("Total volume:  ", sumGridLot()));   
   */
   
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
      m_panel.setCellText(i, 0, IntegerToString(ticket));
      m_panel.setCellText(i, 1, DoubleToString(loss, 2));
      string status = "NONE";
      color c = clrNONE;
      if (loss == 0)
      {
         status = "CLOSED";
         c = clrGreen;
      }
      m_panel.setCellText(i, 2, status, c);
   }
   
   if (OrderSelect(m_state.hedge_order, SELECT_BY_TICKET))
   {
      double lot = OrderLots();
      m_panel.setCellText(n, 0, StringConcatenate("Total volume:  ", lot));
   }
   else
   {
      Print("LFLGrid::updatePanel() ERR: can not OrderSelect() hedge ticket ", m_state.hedge_order);
      m_panel.setCellText(n, 0, "Total volume:  -1");
   }

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
   
   int test_rows = 7;
   int row_height = 18;
   
   int h = row_height*(m_state.orders.count() + 3);
//   int h = row_height*(test_rows + 3);

   int w = 200;
   m_panel.setSize(w, h);
   int dx = w*(number()-1);
   m_panel.setOffset(10 + dx, 20);
   
   
   //m_panel.setGridSize(test_rows, PANEL_COLUMNS);
   m_panel.setGridSize(m_state.ordersCount()+1, PANEL_COLUMNS);
   
   
   LIntList col_sizes;
   col_sizes.append(30);
   col_sizes.append(30);
   col_sizes.append(40);
   m_panel.setColSizes(col_sizes);
}
