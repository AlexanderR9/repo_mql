//+------------------------------------------------------------------+
//|                                              extradeabstract.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/exbase/lexabstract.mqh>
#include <mylib/exbase/extradestatebase.mqh>
#include <mylib/trade/ltradeinfo.mqh>
#include <mylib/trade/lstatictrade.mqh>
#include <mylib/common/linputdialogenum.mqh>
#include <mylib/common/lfile.mqh>

//example
input int U_MainTimerInterval = 25; //Work timer interval
input IP_TimerInterval U_SaveStateInterval = ipMTI_300; //Saving state interval
input string U_Tikers = "Filecoin; #Litecoin; Uniswap"; //Work instruments
//input string U_Tikers = "Uniswap"; //Work instruments
input IP_TrateType U_TradeType = ipMTI_OnlySell; //Trade type



////////////////////////////////////////////////////
//базовый советник, подрузамевающй торговлю по входным инструмента.
////////////////////////////////////////////////
class LExTradeAbstract : public LExAbstract
{
public:
   LExTradeAbstract();
   virtual ~LExTradeAbstract() {reset();}
    
protected:
   LStringList m_tickers; //набор рабочих инструментов      
   int ticker_index; //текущий индекс инструмента для которого нужно провести алгоритм стратегии в текущий цикл (в функции work)
   ExStateContainer *m_stateContainer;
   
   virtual void loadInstruments(string s_input, string s_sep = ";"); //загрузить в контейнер m_tickers список тикеров (разделенные s_sep) из входной строки 
   virtual void checkValidityInstruments(); //проверить корректность элементов m_tickers, некорректные удалить и добавить запись в лог-файл
   virtual void loadInputParams(); //parent class
   virtual void work(); //parent class
   virtual void reset();
      
   virtual void actionAfterLoad() = 0; //при необходимость выполнить некоторые действия после загрузки файла-состояния
   virtual void initStateContainer() = 0; //инициализировать объект m_stateContainer, т.е. заполнить его елементами унаследованными от ExCoupleStateBase
   virtual void saveState(); //from parent class
   virtual void loadState(); //from parent class

};
///////////////////////////////////////////////////////////
LExTradeAbstract::LExTradeAbstract() 
   :LExAbstract() 
{
   ticker_index = -1;
   m_stateContainer = new ExStateContainer();
}
void LExTradeAbstract::loadState()
{
   if (!m_stateContainer) return;
   if (m_stateContainer.isEmpty()) return;

   
   LStringList state_data;
   string fname = fullFileName(stateFile());   
   if (!LFile::isFileExists(fname)) {saveState(); return;}
   
   int code = LFile::readFileToStringList(fname, state_data);
   if (code < 0)
   {
      Print("Error of reading state_file");
      addErr(etReadFile, StringConcatenate("state file, last_err = ", GetLastError()));   
   }
   else
   {
      Print("LExTradeAbstract: try load state from file, readed ", state_data.count(), " f_lines");
   
      string err;
      m_stateContainer.loadState(state_data, err);
      if (err != "") 
      {
         addErr(etLoadState, err);
      }
      else 
      {  
         Print("Success loaded expert state");   
         actionAfterLoad();
      }
   }
}
void LExTradeAbstract::saveState()
{
   if (!m_stateContainer) return;
   if (m_stateContainer.isEmpty()) return;
   
   LStringList state_data;
   m_stateContainer.saveState(state_data);
   if (state_data.isEmpty())
   {
      Print("WARNING: state_data list is empty!");
      return;      
   }
   
   string fname = fullFileName(stateFile());      
   bool ok = LFile::stringListToFile(fname, state_data);
   if (!ok) 
   {
      Print("Error of writing state_file");
      addErr(etWriteFile, fname);
   }
   else Print("State file was overwrite");   
}
void LExTradeAbstract::work()
{
   ticker_index++;
   if (ticker_index >= m_tickers.count()) ticker_index = 0;
}
void LExTradeAbstract::reset()
{
   ticker_index = -1;
   if (m_stateContainer)
   {
      delete m_stateContainer;
      m_stateContainer = NULL;
   }
}
void LExTradeAbstract::loadInstruments(string s_input, string s_sep)
{
   m_tickers.clear();
   if (s_sep == "")
   {
      Print("Invalid ticker separator (empty)");
      addErr(etLoadInputParams, "Invalid ticker separator (empty)");
      return;
   }   
   if (s_input == "")
   {
      Print("Invalid instruments string (empty)");
      addErr(etLoadInputParams, "Invalid instruments string (empty)");
      return;
   }   
      
   LStringWorker::split(s_input, s_sep, m_tickers, false);
   checkValidityInstruments();   
   if (m_tickers.isEmpty())
   {
      is_valid = false;
      Print("Warning: work instrumets list is empty");
      addErr(etLoadInputParams, "instrumets list is empty");
   }   
   else 
   {
      is_valid = true;
      Print("LExTradeAbstract: loaded instruments OK! ", m_tickers.toStrLine());
   }
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
         addErr(etLoadInputParams, "invalid ticker: "+s);
         m_tickers.removeAt(i);
         continue;
      }
      
      LMarketCoupleInfo info(s);
      LStaticTradeInfo::getMarketCoupleInfo(info);
      if (info.invalidTicker()) 
      {
         Print("Warning: invalid ticker ", s);
         addErr(etLoadInputParams, "invalid ticker: "+s);
         m_tickers.removeAt(i);
         continue;
      }
      
      Print("TIKER OK [", s, "]");
      m_tickers.replace(i, s);
   }
}
void LExTradeAbstract::loadInputParams()
{
   //load working instruments
   loadInstruments(U_Tikers);
   if (invalid()) return;
      
   //load base input params      
   m_inputParams.insert(exipSaveInterval, IP_ConvertClass::fromTimerInterval(U_SaveStateInterval));
   m_inputParams.insert(exipTradeType, U_TradeType);
   
   //init state of expert
   initStateContainer();
   
   // to do next load input params in child class
}


