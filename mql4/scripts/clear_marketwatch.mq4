//+------------------------------------------------------------------+
//|                                            clear_marketwatch.mq4 |
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

//скрипт удаляет из обзора рынка все инструменты 
//(примечание: если по инструментам открыты позы или графики, то инструмент не может удалится)
void OnStart()
{
   Print("");
   int n = SymbolsTotal(true);
   for (int i=n-1; i>=0; i--)
   {
      string v = SymbolName(i, true);
      bool ok = SymbolSelect(v, false);
      Print(i, ".  ", v, "   hiding result: ", ok?"OK":"fault");
      if (!ok) Print("GetLastError = ", GetLastError());
   }   
}



