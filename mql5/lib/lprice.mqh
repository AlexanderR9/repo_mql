//+------------------------------------------------------------------+
//|                                                       lprice.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


//опрерации с ценами инструментов
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
   int dig_factor = int(MathPow(10, SymbolInfoInteger(couple, SYMBOL_DIGITS)));
   double dp = p2 - p1;
   return int(MathRound(dp*dig_factor));
}
double LPrice::addPipsPrice(double price, int n, string couple)
{
   int dig_factor = int(MathPow(10, SymbolInfoInteger(couple, SYMBOL_DIGITS)));
   double dp = double(n)/double(dig_factor);
   return (price + dp);
}

//информация о свече
class LBar
{
public:
   static int size(string v, int tf, int i); //размер тела свечи в пунктах (не отрицательное число)
   static int sizeFull(string v, int tf, int i); //размер между low и high свечи в пунктах (не отрицательное число)
   static bool isDown(string v, int tf, int i); //признак того что свеча падающая
   static bool isUp(string v, int tf, int i); //признак того что свеча растущая
   static bool isNoTrend(string v, int tf, int i); //признак того что цены открытия и закрытия одинаковые
   static int sizeShadowUp(string v, int tf, int i); //размер верхней тени свечи в пунктах (не отрицательное число)
   static int sizeShadowDown(string v, int tf, int i); //размер нижней тени свечи в пунктах (не отрицательное число)
   static int sizeShadowUpFull(string v, int tf, int i); //размер верхней тени свечи в пунктах, считается от цены открытия (не отрицательное число)
   static int sizeShadowDownFull(string v, int tf, int i); //размер нижней тени свечи в пунктах, считается от цены открытия (не отрицательное число)
   
   static int averageBodySize(string v, int tf, int n); //средний размер тела свечи в пунктах (не отрицательное число) за последние n баров
   static int averageFullSize(string v, int tf, int n); //средний размер всей свечи целиком в пунктах (не отрицательное число) за последние n баров
   static string strAverageSize(string v, int tf, int n); //строка вида:    averageBodySize/averageFullSize
   
};
bool LBar::isNoTrend(string v, int tf, int i)
{
   return (!isDown(v, tf, i) && !isUp(v, tf, i));
}
bool LBar::isDown(string v, int tf, int i)
{
   double p1 = iOpen(v, ENUM_TIMEFRAMES(tf), i);
   double p2 = iClose(v, ENUM_TIMEFRAMES(tf), i);
   return (p1 > p2);
}
bool LBar::isUp(string v, int tf, int i)
{
   double p1 = iOpen(v, ENUM_TIMEFRAMES(tf), i);
   double p2 = iClose(v, ENUM_TIMEFRAMES(tf), i);
   return (p1 < p2);
}
int LBar::size(string v, int tf, int i)
{
   double p1 = iOpen(v, ENUM_TIMEFRAMES(tf), i);
   double p2 = iClose(v, ENUM_TIMEFRAMES(tf), i);
   return int(MathAbs(LPrice::pricesDiff(p1, p2, v)));
}
int LBar::sizeFull(string v, int tf, int i)
{
   double p1 = iLow(v, ENUM_TIMEFRAMES(tf), i);
   double p2 = iHigh(v, ENUM_TIMEFRAMES(tf), i);
   return int(MathAbs(LPrice::pricesDiff(p1, p2, v)));
}
int LBar::sizeShadowUp(string v, int tf, int i)
{
   double p = iOpen(v, ENUM_TIMEFRAMES(tf), i);
   double p2 = iClose(v, ENUM_TIMEFRAMES(tf), i);
   if (p2 > p) p = p2;
   
   double ph = iHigh(v, ENUM_TIMEFRAMES(tf), i);
   return int(MathAbs(LPrice::pricesDiff(p, ph, v)));
}
int LBar::sizeShadowDown(string v, int tf, int i)
{
   double p = iOpen(v, ENUM_TIMEFRAMES(tf), i);
   double p2 = iClose(v, ENUM_TIMEFRAMES(tf), i);
   if (p2 < p) p = p2;
   
   double ph = iLow(v, ENUM_TIMEFRAMES(tf), i);
   return int(MathAbs(LPrice::pricesDiff(p, ph, v)));
}
int LBar::sizeShadowUpFull(string v, int tf, int i)
{
   double p = iOpen(v, ENUM_TIMEFRAMES(tf), i);   
   double ph = iHigh(v, ENUM_TIMEFRAMES(tf), i);
   return int(MathAbs(LPrice::pricesDiff(p, ph, v)));
}
int LBar::sizeShadowDownFull(string v, int tf, int i)
{
   double p = iOpen(v, ENUM_TIMEFRAMES(tf), i);
   double ph = iLow(v, ENUM_TIMEFRAMES(tf), i);
   return int(MathAbs(LPrice::pricesDiff(p, ph, v)));
}
int LBar::averageBodySize(string v, int tf, int n)
{
   if (n <= 0) return 0;
   
   int a = 0;
   for (int i=0; i<n; i++)
      a += size(v, tf, i);
   return int(a/n);
}
int LBar::averageFullSize(string v, int tf, int n)
{
   if (n <= 0) return 0;
   
   int a = 0;
   for (int i=0; i<n; i++)
      a += sizeFull(v, tf, i);
   return int(a/n);
}
string LBar::strAverageSize(string v, int tf, int n)
{
   string s;
//   string s = StringConcatenate("average size: body/full = ", averageBodySize(v, tf, n), "/", averageFullSize(v, tf, n));
   StringConcatenate(s, "average size: body/full = ", averageBodySize(v, tf, n), "/", averageFullSize(v, tf, n));
   return s;
}


