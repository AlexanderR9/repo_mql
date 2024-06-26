//+------------------------------------------------------------------+
//|                                              extradeabstract.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/exbase/lexabstract.mqh>
#include <mylib/trade/ltradeinfo.mqh>
#include <mylib/trade/lstatictrade.mqh>
#include <mylib/common/linputdialogenum.mqh>

//example
input int U_MainTimerInterval = 12; //Work timer interval
input string U_Tikers = "Cardano; #Litecoin; Uniswap"; //Work instruments
input IP_TrateType U_TradeType = ipMTI_OnlySell; //Trade type





////////////////////////////////////////////////////
//базовый советник, подрузамевающй торговлю
////////////////////////////////////////////////
class LExTradeAbstract : public LExAbstract
{
public:
   LExTradeAbstract() :LExAbstract() {ticker_index = -1;}
   
   // распарсить строку состояния из файла в которой находится список тикетов разделенных '*',
   // количетсво '*' не важно, все пустые подстроки игнорятся
   static void loadTicketsFromStateLine(LIntList&, string); 
   
protected:
   LStringList m_tickers; //набор рабочих инструментов      
   LStaticTrade m_trade; //объект для совершения торговых операций
   int ticker_index; //текущий индекс инструмента для которого нужно провести алгоритм стратегии в текущий цикл (в функции )

   
   virtual void loadInstruments(string s_input, string s_sep = ";"); //загрузить в контейнер m_tickers список тикеров (разделенные s_sep) из входной строки 
   virtual void checkValidityInstruments(); //проверить корректность элементов m_tickers, некорректные удалить и добавить запись в лог-файл
   virtual void loadInputParams(); //parent class
   virtual void work(); //parent class

};
void LExTradeAbstract::work()
{
   ticker_index++;
   if (ticker_index >= m_tickers.count()) ticker_index = 0;
}
void LExTradeAbstract::loadTicketsFromStateLine(LIntList &list, string fline)
{
   list.clear();
   if (StringLen(fline) < 5) return;
   
   fline = LStringWorker::trim(fline);
   LStringList s_list;
   s_list.splitFromString(fline, LFile::splitSymbol());
   if (s_list.isEmpty()) return;   
   
   for (int i=0; i<s_list.count(); i++)
   {
      string v = s_list.at(i);
      v = LStringWorker::trim(v);
      if (v == "") continue;
      int a = StrToInteger(v);
      if (GetLastError() == 0) list.append(a);
      else Print("LExTradeAbstract::loadTicketsFromStateLine WARNING: can't convert string to INT: ", v);
   }   
}
void LExTradeAbstract::loadInstruments(string s_input, string s_sep)
{
   m_tickers.clear();
   if (s_sep == "")
   {
      Print("Invalid ticker separator (empty)");
      return;
   }   
   if (s_input == "")
   {
      Print("Invalid instruments string (empty)");
      return;
   }   
   m_tickers.splitFromString(s_input, s_sep);
   
   checkValidityInstruments();
   
   if (m_tickers.isEmpty())
   {
      is_valid = false;
      Print("Warning: work instrumets list is empty");
   }   
   else is_valid = true;
}
void LExTradeAbstract::checkValidityInstruments()
{
   if (m_tickers.isEmpty()) return;
   
   for (int i=0; i<m_tickers.count(); i++)
   {
      string s = m_tickers.at(i);
      s = LStringWorker::trim(s);
      if (StringLen(s) < 3) 
      {
         Print("Warning: invalid ticker ", s);
         m_tickers.removeAt(i);
         continue;
      }
      
      LMarketCoupleInfo info(s);
      LStaticTradeInfo::getMarketCoupleInfo(info);
      if (info.invalidTicker()) 
      {
         Print("Warning: invalid ticker ", s);
         m_tickers.removeAt(i);
         continue;
      }
      
      Print("TIKER OK [", s, "]");
      m_tickers.replace(i, s);
   }
}
void LExTradeAbstract::loadInputParams()
{
   //example
   loadInstruments(U_Tikers);
   
   
   // to do next load input params

}


