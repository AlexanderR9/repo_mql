//+------------------------------------------------------------------+
//|                                                       lprice.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


//структцрв для проведения различных опрераций с парой цен инструментов
struct LPricePair
{
   LPricePair() {reset();}
   LPricePair(string s, double a, double b=-1) :ticker(s), p1(a), p2(b) {}
   
   string ticker; //instrument name
   double p1;
   double p2;
   
   
   inline void reset() {ticker="?"; p1=p2=-1;}
   inline bool invalid() const {return (StringLen(ticker) < 3 || p1 <= 0);}
   
   //коэффициент - соответствующий минимальному изменению цены (т.е соответствующая значению digist) 
   double digFactor() const
   {
      if (invalid()) return 0;
      int d = int(MathPow(10, int(MarketInfo(ticker, MODE_DIGITS))));
      return double(1)/double(d);   
   }
   
   //разница между ценами в абсолютной величине
   double dPrice() const {return (p2-p1);}

   //разница между ценами в пунктах для инструмента couple (т.е соответствующая значению digist),
   // результат: p2 - p1  (может быть отрицательным)
   int priceDiff() const
   {
      if (invalid() || p2 <= 0) return 0;
      double dp = p2 - p1;
      return int(MathRound(dp/digFactor()));
   }
      
   //добавить к цене p1 n пунктов (соответствующих значению digist) и записать новую цену в переменную p2,
   //n может быть отрицательным
   void addPipsPrice(int n)
   {
      p2 = 0;
      if (!invalid())
      {      
         double dp = double(n)*digFactor();
         p2 = p1 + dp;
      }   
   }
   
   //добавить к цене p1 отклонение dev_p,% и записать новую цену в переменную p2,
   //dev_p может быть отрицательным
   void addPriceDeviation(double dev_p)
   {
      p2 = 0;
      if (!invalid())
      {            
         p2 = p1*(1 + dev_p/double(100));
         int dig = int(MarketInfo(ticker, MODE_DIGITS));
         p2 = NormalizeDouble(p2, dig);
      }         
   }

};


