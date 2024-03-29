//+------------------------------------------------------------------+
//|                                                         base.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+


//статический класс для проверки значений различных параметров и вхождение их в правильный диапазон
class MQValidityData
{
public:
   //проверяет имя пары
   static bool isValidCouple(const string&);
   
   //проверяет тип ордера
   static bool isValidOrderType(int);
   
   //проверяет является ли тип ордера, относящимся к отложенным
   static bool isPendingOrderType(int);
      
   //проверяет значение timeframe
   static bool isValidTimeFrame(int);

   
   static double errValue() {return -9999;} //standard value
   static string errStrValue() {return "error";} //standard value
   static string testCouple() {return "EURUSD";}
   

};
bool MQValidityData::isValidTimeFrame(int tf)
{
   return (tf == PERIOD_M1 || tf == PERIOD_M5 || tf == PERIOD_M15 || tf == PERIOD_M30 ||
            tf == PERIOD_H1 || tf == PERIOD_H4 || tf == PERIOD_D1 || tf == PERIOD_W1 || tf == PERIOD_MN1);
}
bool MQValidityData::isPendingOrderType(int type)
{
   return ((type == OP_BUYLIMIT) || (type == OP_BUYSTOP) || 
      (type == OP_SELLLIMIT) || (type == OP_SELLSTOP));
}
bool MQValidityData::isValidOrderType(int type)
{
   return ((type == OP_BUY) || (type == OP_SELL) || 
      (type == OP_BUYLIMIT) || (type == OP_BUYSTOP) || 
      (type == OP_SELLLIMIT) || (type == OP_SELLSTOP));
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
