//+------------------------------------------------------------------+
//|                                                flgridstructs.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/lcontainer.mqh>


//дополнительная структура(информационная) для отображения некоторых параметров в момент получения профита любой сетки
/*
class FLGridProfitMoment
{
public:
   FLGridProfitMoment() {reset();}

   //информация о сетке от которой получен профит
   int grid_number;
   LMapIntDouble lots;
   LMapIntDouble profits;
   
   double gridLots() const {return lots.sumValues();}
   double gridProfit() const {return profits.sumValues();}
   int panelRowsCount() const {return ((1+lots.count()+1) + (2*repay_lots.count()+1));}
   
//////////////////////////////////////////////////////////////
   
   //информация о сетке в которой погашаются убытки
   LMapIntDouble repay_lots;
   LMapIntDouble repay_profits;
   LMapIntDouble hedge_profits;
  
   double hedgeLots() const {return repay_lots.sumValues();}
   double hedgeProfit() const {return (repay_profits.sumValues() + hedge_profits.sumValues());}

//////////////////////////////////////////////////////////////
   
   //инициализация параметров
   void reset()
   {
      grid_number = -1;
      lots.clear();
      profits.clear();
      
      repay_lots.clear();
      repay_profits.clear();
      hedge_profits.clear();
   }
};
*/

//структура для входных параметров каждой сетки
struct FLGridInputParams
{
   FLGridInputParams() {reset();}
   
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
   bool invalid() const
   {
      if (start_lot < 0.01) return true;
      if (candle_step < 1) return true;
      if (lot_factor < 0.5) return true;
      if (lot_hedge_level < 0.01) return true;
      
      return false;
   }
};

//структура для хранения текущего состояния каждой сетки
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
   
   //когда вся сетка ушла в минус и пришло время открывать хеджирующий ордер
   //в этот момент сюда записываются убытки каждого одера сетки (включая своп и комисию)
   //key - ticket, value - loss
   LMapIntDouble loss_values;
   LMapIntDouble profit_values; //текущий размер погашенного убытка каждого ордера захеджированной сетки
   
   //размеры лотов открытых ордеров сетки,
   //добаляются в контейнер по мере открытия каждого очередного ордера.
   LMapIntDouble lots_values;
   
   //заполняется в тот же момент когда и loss_values.
   //здесь будут хранится индксы ордеров из контейнера orders
   // в том порядке в каком их надо гасить, начиная с 0-го
   //порядок зависит от параметра lossoff_upward_metod
   LIntList lossoff_indexes; 

   
   inline bool invalidTradeKind() const {return ((trade_kind != OP_BUY) && (trade_kind != OP_SELL));}
   inline void addOrder(int ticket, double lot_size) {orders.append(ticket); lots_values.insert(ticket, lot_size);} 
   inline bool ordersEmpty() const {return orders.isEmpty();}
   inline int ordersCount() const {return orders.count();}
   
   double currentLoss() const
   {
      double sum = 0;
      for (int i=0; i<orders.count(); i++)
         sum += loss_values.value(orders.at(i));
      return sum;
   }
   
   void clearContainers()
   {
      orders.clear();
      loss_values.clear();
      lossoff_indexes.clear();
      lots_values.clear();
      profit_values.clear();   
   }
   void reset()
   {
      clearContainers();
      
      hedge_order = -1;
      need_close = false;
      last_profit = 0;
      magic = 0;
      trade_kind = -1;
      close_errs = 0;
      
   }
   void tradeReset()
   {
      clearContainers();
      
      hedge_order = -1;
      need_close = false;
      //last_profit = 0;
      close_errs = 0;   
   }
};
