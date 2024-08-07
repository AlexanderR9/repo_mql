//+------------------------------------------------------------------+
//|                                                       lprice.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/structs/lpriceoperations.mqh>


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
   double p1 = iOpen(v, tf, i);
   double p2 = iClose(v, tf, i);
   return (p1 > p2);
}
bool LBar::isUp(string v, int tf, int i)
{
   double p1 = iOpen(v, tf, i);
   double p2 = iClose(v, tf, i);
   return (p1 < p2);
}
int LBar::size(string v, int tf, int i)
{
   double p1 = iOpen(v, tf, i);
   double p2 = iClose(v, tf, i);
   LPricePair lpp(v, p1, p2);
   return int(MathAbs(lpp.priceDiff()));
}
int LBar::sizeFull(string v, int tf, int i)
{
   double p1 = iLow(v, tf, i);
   double p2 = iHigh(v, tf, i);
   LPricePair lpp(v, p1, p2);
   return int(MathAbs(lpp.priceDiff()));
}
int LBar::sizeShadowUp(string v, int tf, int i)
{
   double ph = iHigh(v, tf, i);
   double p = iOpen(v, tf, i);
   double p2 = iClose(v, tf, i);
   if (p2 > p) p = p2;
     
   LPricePair lpp(v, p, ph);
   return lpp.priceDiff();   
}
int LBar::sizeShadowDown(string v, int tf, int i)
{
   double pl = iLow(v, tf, i);
   double p = iOpen(v, tf, i);
   double p2 = iClose(v, tf, i);
   if (p2 < p) p = p2;
   
   LPricePair lpp(v, pl, p);
   return lpp.priceDiff();   
}
int LBar::sizeShadowUpFull(string v, int tf, int i)
{
   double p = iOpen(v, tf, i);   
   double ph = iHigh(v, tf, i);
   return int(MathAbs(LPrice::pricesDiff(p, ph, v)));
}
int LBar::sizeShadowDownFull(string v, int tf, int i)
{
   double p = iOpen(v, tf, i);
   double ph = iLow(v, tf, i);
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
   string s = StringConcatenate("average size: body/full = ", averageBodySize(v, tf, n), "/", averageFullSize(v, tf, n));
   return s;
}


