//+------------------------------------------------------------------+
//|                                                       lprice.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


//статический класс для проведения различных опрераций с ценами инструментов
class LPrice
{
public:   
   //разница между ценами в пунктах для инструмента couple,
   // результат: p2 - p1  (может быть отрицательным)
   static int pricesDiff(double p1, double p2, string couple);
   
   //добавить к цене price n пунктов и вернуть новую цену,
   //n может быть отрицательным
   static double addPipsPrice(double price, int n, string couple);

};
int LPrice::pricesDiff(double p1, double p2, string couple)
{
   int dig_factor = int(MathPow(10, int(MarketInfo(couple, MODE_DIGITS))));
   double dp = p2 - p1;
   return int(MathRound(dp*dig_factor));
}
double LPrice::addPipsPrice(double price, int n, string couple)
{
   int dig_factor = int(MathPow(10, int(MarketInfo(couple, MODE_DIGITS))));
   double dp = double(n)/double(dig_factor);
   return (price + dp);
}

