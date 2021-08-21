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

#define NOMRMALIZE_LOT_DIGIST    2
#define FLGRID_SLIP_PAGE         100



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
class LFLGrid
{
public:
   enum ExecResult {erLookNextGrid = 60, erFinishExecuting, erOpenedGridOrder, erOpenedHedgeOrder, erHasError};

   LFLGrid() {reset();}
   //LFLGrid(int number);
   
   //main working func
   void exec(int &result, string &err);
   
   void setLotParams(double, double, double);
   void setOtherParams(int, int, int, int);
   void findCurrentOrders(); //требуется при перезапуске, проводит поиск текуших открытых ордеров (только для 1-й сетки)
   
   inline void setNumber(int n) {m_number = n;}
   inline void setTradeKind(int kind) {m_tradeKind = kind;}
   inline void setMagic(int m) {m_magic = m;}   
   
   inline int number() const {return m_number;}
   inline bool invalid() const {return (m_number < 1 || m_magic < 0 || !(m_tradeKind == OP_BUY || m_tradeKind == OP_SELL));}
   inline bool hedgingNow() const {return (m_hedgeOrder > 0);}
   
   
   static string orderComment(int grid_number, int step) {return ("grid"+IntegerToString(grid_number)+" / "+"step"+IntegerToString(step));}
   static string hedgeComment(int grid_number) {return ("gridlock"+IntegerToString(grid_number));}
   

protected:
   int m_number; //номер сетки 1..10
   int m_tradeKind; // buy or sell
   FLGridParams m_params;
   LIntList m_orders; 
   int m_hedgeOrder;
   int m_magic;
   
   //когда вся сетка ушла в минус и пришло время открывать хеджирующий ордер
   //в этот момент сюда записываются убытки каждого одера сетки (включая своп и комисию)
   //key - ticket, value - loss
   LMapIntDouble m_lossValues;
   
   void reset();
   int stepByCommect(string s) const;
   double stepLot(int step) const; //возвращает размер лота для заданного шага, если step <= 0, то вернет -1
   double sumGridLot() const; //вернет потенциальный суммарный лот всех ордеров сетки, не включая хеджирующий, т.е. хеджирующий должен быть такой же
   bool gridLotsOver() const; //признак того что сумарный лот сетки превысил допустимый и настал момент хеджирования
   bool nextTradeMoment() const; //признак того что настал монет для открытия очередного ордера сетки и хеджирующего в том числе
   
   //trade funcs
   void tryOpenNextGridOrder(int &result, string &err); //открывает очередной ордер сетки
   void tryOpenHedgeOrder(int &result, string &err); //открывает хеджирующий ордер сетки
   
};


//description LFLGrid
/*
LFLGrid::LFLGrid(int n)
   :m_number(n)
{
   reset();
}
*/
void LFLGrid::exec(int &result, string &err)
{
   err = "";
   result = erFinishExecuting;
   
   if (hedgingNow())
   {
      result = erLookNextGrid;
      return;
   }
   
   if (m_orders.isEmpty())
   {
      tryOpenNextGridOrder(result, err);
      return;
   }
   
   if (nextTradeMoment())
   {
      if (gridLotsOver()) tryOpenHedgeOrder(result, err);
      else tryOpenNextGridOrder(result, err);
   }
}
bool LFLGrid::nextTradeMoment() const
{
   return false;
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
   int n = m_orders.count();
   double sum = 0;
   for (int i=0; i<n; i++)
      sum += stepLot(i+1);
      
   return (sum >= m_params.lot_hedge_level);
}
void LFLGrid::tryOpenNextGridOrder(int &result, string &err)
{
   string couple = Symbol();
   int step = m_orders.count() + 1;
   double lot = stepLot(step);
   int slip = FLGRID_SLIP_PAGE;
   string s = orderComment(number(), step);
   double price = MarketInfo(couple, MODE_ASK);
   if (m_tradeKind == OP_SELL) price = MarketInfo(couple, MODE_BID);
   
   Print("tryOpenNextGridOrder, step=", step, "  lot=", lot, "  slip=", slip, "  price=", price, "  Comment=", s);
   
  // result = erOpenedGridOrder;
  // m_orders.append(123);
  // return;

   
   int ticket = OrderSend(couple, m_tradeKind, lot, price, slip, 0, 0, s, m_magic);
   if (ticket > 0) 
   {
      result = erOpenedGridOrder;
      m_orders.append(ticket);
   }
   else
   {
      result = erHasError;
      err = "error open order, grid " + IntegerToString(number()) + 
               "  step="+IntegerToString(step) + " couple="+couple;
   }
}
void LFLGrid::tryOpenHedgeOrder(int &result, string &err)
{
   //int ticket = OrderSend(Symbol(), );
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
   
   Print("1");
   
   LMapIntDouble map; // key - step
   Print("OrdersTotal ", n);
   for (int i=0; i<n; i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != m_magic || OrderType() != m_tradeKind) continue;   
      
      int step = stepByCommect(OrderComment());
      if (step > 0) 
      {
         map.insert(step, OrderTicket());         
         Print("Finded order=", map.value(step), "  by step", step);
      }
   }
      Print("3");

   //return;
   
   /////////////////////////////////
   n = map.count();
   if (n == 0) return;
   bool ok = true;
   for (int step=1; step<=n; step++)
   {
      if (!map.contains(step)) {ok = false; break;}
      m_orders.append(int(map.value(step)));
   }
   
   if (!ok)
   {
      m_orders.clear();
      Print("ERR: findCurrentOrders result");
   }
}
void LFLGrid::reset()
{
   m_number = 0;
   m_orders.clear();
   m_hedgeOrder = -1;
   m_tradeKind = -1;
   m_magic = -1;
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
