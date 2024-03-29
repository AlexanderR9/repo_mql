//+------------------------------------------------------------------+
//|                                                  check_swaps.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/trade/ltradeinfo.mqh>

#define MIN_SWAP  0.4 //pips

//скрипт находит все положительные свопы (более MIN_SWAP) и выводит их в дебаг


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("---------------------------------------------");
   LMarketWatchInfo mw;
   LStaticTradeInfo::getMarketWatchInfo(mw);
   int n_positive = 0;
   for (int i=0; i<mw.q_couples.count(); i++)
   {  
      LMarketCoupleInfo info(mw.q_couples.at(i));
      LStaticTradeInfo::getMarketCoupleInfo(info);
      if (info.swap_buy > MIN_SWAP || info.swap_sell > MIN_SWAP)
      {      
         n_positive++;
         Print(info.toStr());         
      }
   }
   Print("find positive swaps: ", n_positive);
}
//+------------------------------------------------------------------+
