//+------------------------------------------------------------------+
//|                                                         base.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

                         
////////////MQPrecision///////////////////
struct MQPrecision
{
    MQPrecision() :factor(2), sum(1), lot(2), bet(3) {}

    int factor;
    int sum;
    int lot;
    int bet;
};


////////////MQValidityData///////////////////
//класс для проверки значений различных параметров и вхождение их в правильный диапазон
class MQValidityData
{
public:
   //проверяет имя пары
   static bool isValidCouple(const string&);
   
   //проверяет тип ордера
   static bool isValidOrderType(int);
   
   //проверяет является ли ордер отложенным
   static bool isPendingOrder(int);
   
   //проверяет значение текущего спреда для пары
   static bool spreadOver(const string&, const double&);
   
   //проверяет значение timeframe
   static bool isValidTimeFrame(int);

   
   static double errValue() {return -9999;}
   static string errStrValue() {return "error";}
   static string testCouple() {return "EURUSD";}
   

};
bool MQValidityData::isValidTimeFrame(int tf)
{
   return (tf == PERIOD_M1 || tf == PERIOD_M5 || tf == PERIOD_M15 || tf == PERIOD_M30 ||
            tf == PERIOD_H1 || tf == PERIOD_H4 || tf == PERIOD_D1 || tf == PERIOD_W1 || tf == PERIOD_MN1);
}
bool MQValidityData::spreadOver(const string &couple, const double &spread)
{
   string v = couple;
   StringToLower(v);
   if (v == "eurusd" || v == "gbpusd" || v == "audusd" || v == "usdchf" || v == "eurchf" ||
      v == "usdcad" || v == "eurgbp" || v == "eurjpy" || v == "usdjpy")
   {
      return (spread > 3.1);
   } 
      
   if (v == "nzdusd" || v == "audjpy" || v == "chfjpy" || v == "nzdjpy")
   {
      return (spread > 4.1);
   } 
   
   if (v == "gbpjpy" || v == "cadjpy" || v == "cadchf")
   {
      return (spread > 6.1);
   } 
   
   //if (v == "gbpaud" || v == "gbpnzd" || v == "euraud" || v == "eurnzd" || v == "gbpchf" ||
     //    v == "gbpcad" || v == "eurcad" || v == "audcad" || v == "nzdcad" || v == "audcfh" || v == "nzdcfh")
   //{
    //  return (spread > 8.1);
   //} 
   
   
   //return true;
   
   return (spread > 8.1);
}
bool MQValidityData::isPendingOrder(int cmd)
{
   return ((cmd == OP_BUYLIMIT) || (cmd == OP_BUYSTOP) || 
      (cmd == OP_SELLLIMIT) || (cmd == OP_SELLSTOP));
}
bool MQValidityData::isValidOrderType(int cmd)
{
   return ((cmd == OP_BUY) || (cmd == OP_SELL) || 
      (cmd == OP_BUYLIMIT) || (cmd == OP_BUYSTOP) || 
      (cmd == OP_SELLLIMIT) || (cmd == OP_SELLSTOP));
}
bool MQValidityData::isValidCouple(const string &couple)
{
   string v = couple;
   //StringTrimLeft(couple);
   //v = StringTrimRight(v);
   StringToLower(v);
   if (StringLen(v) != 6) return false;
   
   //usd
   if (v == "eurusd") return true;
   if (v == "gbpusd") return true;
   if (v == "audusd") return true;
   if (v == "nzdusd") return true;
   
   //jpy
   if (v == "eurjpy") return true;
   if (v == "usdjpy") return true;
   if (v == "cadjpy") return true;
   if (v == "audjpy") return true;
   if (v == "nzdjpy") return true;
   if (v == "gbpjpy") return true;
   if (v == "chfjpy") return true;
   
   //cad
   if (v == "eurcad") return true;
   if (v == "usdcad") return true;
   if (v == "gbpcad") return true;
   if (v == "audcad") return true;
   if (v == "nzdcad") return true;
   
   //chf
   if (v == "eurchf") return true;
   if (v == "usdchf") return true;
   if (v == "gbpchf") return true;
   if (v == "audchf") return true;
   if (v == "nzdchf") return true;
   if (v == "cadchf") return true;
   
   //aud / nzd
   if (v == "euraud") return true;
   if (v == "eurnzd") return true;
   if (v == "gbpaud") return true;
   if (v == "gbpnzd") return true;
   
   //other
   if (v == "eurgbp") return true;
   
   return false;
}
