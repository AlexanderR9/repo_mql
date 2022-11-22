//+------------------------------------------------------------------+
//|                                                 orders_count.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include <mylib/trade/ltradeinfo.mqh>

//скрипт показывает количество открытых и отложенных ордеров
void OnStart()
{
   LOpenedOrdersInfo info;
   LStaticTradeInfo::getOpenedOrdersInfo(info);
   MessageBox(info.toStr(true), "Info");
   
}




