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
   
   void reset() 
   {
      start_lot = 0.1; lot_factor = 1.1; lot_hedge_level = 2.5;
      candle_step = 2; order_distance = 20; profit_points = 15; hedge_profit = 0;
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
   
   //когда вся сетка ушла в минус и пришло время открывать хеджирующий ордер
   //в этот момент сюда записываются убытки каждого одера сетки (включая своп и комисию)
   //key - ticket, value - loss
   LMapIntDouble loss_values;
   
   inline void addOrder(int ticket) {orders.append(ticket);}
   inline bool ordersEmpty() const {return orders.isEmpty();}
   inline int ordersCount() const {return orders.count();}
   
   void reset()
   {
      orders.clear();
      loss_values.clear();
      hedge_order = -1;
      need_close = false;
      last_profit = 0;
      magic = 0;
      
   }
};


/////////////////////////////////////
class LFLGrid
{
public:
   enum ExecResult {erLookNextGrid = 60, erFinishExecuting, erOpenedGridOrder, erOpenedHedgeOrder, erHasError, erGetedProfit};

   LFLGrid() {reset();}
   //LFLGrid(int number);
   
   //main working func
   void exec(int &result, string &err);
   
   void setLotParams(double, double, double);
   void setOtherParams(int, int, int, int);
   void loadState(); //требуется при перезапуске, проводит поиск текуших открытых ордеров (только для 1-й сетки)
   void saveState(); //требуется при перезапуске/отключении советника
   void testShowPanel(); //тестовая функция
   
   
   inline void setNumber(int n) {m_number = n;}
   inline void setTradeKind(int kind) {m_tradeKind = kind;}
   inline void setMagic(int m) {m_state.magic = m;}   
   inline int number() const {return m_number;}
   inline bool invalid() const {return (m_number < 1 || m_state.magic < 0 || !(m_tradeKind == OP_BUY || m_tradeKind == OP_SELL));}
   inline bool hedgingNow() const {return (m_state.hedge_order > 0);} //признак того что в текущий момент сетка хеджируется (m_hedgeOrder > 0)
   inline bool isSellGrid() const {return (m_tradeKind == OP_SELL);}
   inline bool isBuyGrid() const {return (m_tradeKind == OP_BUY);}
   
   
   static string orderComment(int grid_number, int step) {return ("grid"+IntegerToString(grid_number)+" / "+"step"+IntegerToString(step));}
   static string hedgeComment(int grid_number) {return ("gridlock"+IntegerToString(grid_number));}
   

protected:
   int m_number; //номер сетки 1..10
   int m_tradeKind; // buy or sell
   
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
   bool selectLastOrder() const; //пытается выполнить OrderSelect для последнего ордера
   bool nextTradeMoment() const; //признак того что настал монет для открытия очередного ордера сетки (хеджирующего в том числе)
   void saveLossValues(); //сохранить текущие значения убытков в контейнер m_lossValues
   
   
   double stepLot(int step) const; //возвращает размер лота для заданного шага, если step <= 0, то вернет -1
   double sumGridLot() const; //вернет потенциальный суммарный лот всех ордеров сетки, не включая хеджирующий, т.е. хеджирующий должен быть такой же
   bool gridLotsOver() const; //признак того что сумарный лот сетки превысил допустимый и дальше надо хеджирования
   int lastCandleCount() const; //сколько свечей закрылось после открытия последнего ордера
   bool openTimeCandleNow() const; //признак того что сейчас наступило всемя открытия свечи
   double coupleCurentPrice() const; //текущая цена инструмента (ask или buy) взависимости от m_tradeKind
   double coupleCurentPrice(int cmd) const; //текущая цена инструмента (ask или buy)
   int hedgeCmd();
   void reinitPanel(); //инициализация панели перед отображением
   void startPanel(); //запуск панели в момент хеджирования
   int orderMagic() const;
   
   //текущая разница (в пунктах) между ценой открытия последнего ордера и  coupleCurentPrice()
   //значение также зависит от m_tradeKind.
   //значение может быть как положительным так и отрицательным, (отрицательное - убыток и наоборот соответственно)
   int lastPriceDistance() const; //текущая разница (в пунктах) между ценой открытия последнего ордера и  coupleCurentPrice()
   
   //текущий суммарный результат работы всех открытых ордеров сетки включая комиссию и свопы (в валюте счета).
   //значение имеет смысл пока сетка не захеджирована.
   //значение может быть как положительным так и отрицательным, (отрицательное - убыток и наоборот соответственно).
   double currentResult() const;
   

};


//description LFLGrid
void LFLGrid::testShowPanel()
{
   

   startPanel();
}
void LFLGrid::exec(int &result, string &err)
{
   Print("openTimeCandleNow = ", openTimeCandleNow());
   Print("lastCandleCount = ", lastCandleCount(), "  lastPriceDistance=", lastPriceDistance());
   return;
   ///////////////////////////////////

   err = "";
   result = erFinishExecuting; //закончить выполнение сеток в этом цикле
   
   if (hedgingNow())
   {
      result = erLookNextGrid; //если сетка уже захеджирована перейти к следующей сетке
      return;
   }
   
   if (m_state.ordersEmpty())
   {
      tryOpenNextGridOrder(result, err); //если нет открытых ордеров для этой сетки, то просто открываем 1-й ордер (прямо сейчас)
      return;
   }
   
   if (nextTradeMoment()) //выполнилось условие для открытия очередного ордера
   {
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
int LFLGrid::orderMagic() const
{
   return m_state.magic;
}
void LFLGrid::saveLossValues()
{
   m_state.loss_values.clear();
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
         m_state.loss_values.insert(ticket, (x1+x2+x3));
      }
      else m_state.loss_values.insert(ticket, LOSS_ERR_VALUE);         
   }
}
double LFLGrid::currentResult() const
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
      }
   }
   return sum;
}
double LFLGrid::coupleCurentPrice() const
{
   switch (m_tradeKind)
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
   int dig_factor = int(MathPow(10, int(MarketInfo(Symbol(), MODE_DIGITS))));
   int op = int(MathRound(OrderOpenPrice()*dig_factor));
   int cp = int(MathRound(coupleCurentPrice()*dig_factor));
   int dp = cp - op;
   //Print("op=",op,"  cp=",cp, " dig_factor=", dig_factor);
   if (isSellGrid()) dp *= (-1);
   
   return int(dp);
}
int LFLGrid::lastCandleCount() const
{
   if (!selectLastOrder()) return -1;
   
   datetime dt = OrderOpenTime();
   Print("order open time: ", dt);
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
   switch (m_tradeKind)
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
   if (lastCandleCount() < m_params.candle_step) return false;
   int d_pips = MathAbs(lastPriceDistance());
   if (d_pips < m_params.order_distance) return false;
   return true;
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
   double sum = 0;
   for(int step=1; step<1000; step++)
   {
      sum += stepLot(step);
      if (sum >= m_params.lot_hedge_level) break;
   }
   return NormalizeDouble(sum, NOMRMALIZE_LOT_DIGIST);
}
bool LFLGrid::gridLotsOver() const
{
   int n = m_state.orders.count();
   double sum = 0;
   for (int i=0; i<n; i++)
      sum += stepLot(i+1);
      
   return (sum >= m_params.lot_hedge_level);
}
void LFLGrid::tryOpenNextGridOrder(int &result, string &err)
{
   int step = m_state.ordersCount() + 1;
   double lot = stepLot(step);
   int slip = FLGRID_SLIP_PAGE;
   string s = orderComment(number(), step);
   double price = coupleCurentPrice();   
   
   Print("tryOpenNextGridOrder, step=", step, "  lot=", lot, "  slip=", slip, "  price=", price, "  Comment=", s);
   int ticket = OrderSend(Symbol(), m_tradeKind, lot, price, slip, 0, 0, s, orderMagic());
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
void LFLGrid::findCurrentOrders()
{
   int n = OrdersTotal();
   if (n == 0) return;
   
  // Print("1");
   
   LMapIntDouble map; // key - step
   Print("OrdersTotal ", n);
   for (int i=0; i<n; i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != orderMagic() || OrderType() != m_tradeKind) continue;   
      
      int step = stepByCommect(OrderComment());
      if (step > 0) 
      {
         map.insert(step, OrderTicket());         
         Print("Finded order=", map.value(step), "  by step", step);
      }
   }
     // Print("3");

   //return;
   
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
}
void LFLGrid::reset()
{
   m_number = 0;
   m_tradeKind = -1;
   m_state.reset();
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
   
   int n = m_state.ordersCount();
   for (int i=0; i<n; i++)
   {
      m_panel.setCellText(i, 0, IntegerToString(m_state.orders.at(i)));
      m_panel.setCellText(i, 1, DoubleToString(m_state.loss_values.value(m_state.orders.at(i)), 2));
      m_panel.setCellText(i, 2, "NONE");
   }
   m_panel.setCellText(6, 0, StringConcatenate("Total volume:  ", sumGridLot()));
   //m_panel.setCellText(0, 2, "Closed", clrGreen);
   //m_panel.setCellText(1, 2, "Closed", clrDarkGreen);
   
   
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
