//+------------------------------------------------------------------+
//|                                                lterminalinfo.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

//структуры - контейнеры для сбора обобщенной информации о терминале, торговом счете, списке инструментов и т.п.


#include <mylib/common/lstring.mqh>


//структура для получения параметров терминала брокера (тип счета, баланс, валюта и т.п.)
struct LTerminalInfo
{
   LTerminalInfo() {reset();}
   
   string broker_name;     // название брокерской компании
   string user_name;       // имя пользователя текущего счета
   string terminal_type;   //наименование клиентского терминала
   string currency;        // валюта депозита
   string trade_server;    // наименование активного сервера

   double my_balance;      //Баланс счета в валюте депозита
   double margin_size;     //Размер зарезервированных залоговых средств на счете  в валюте депозита
   double balance_free;    //Размер свободных средств на счете  в валюте депозита, доступных для открытия ордера
    
   void reset() 
   {
      my_balance = margin_size = balance_free = MQValidityData::errValue();
      broker_name = user_name = terminal_type = currency = trade_server = "???";
   }
   
   //выдать строку с полной информацией структуры.
   //line_break указывает на то надо ли вставлять перенос '\n' после каждого значения
   string toStr(bool line_break = false) const
   {
      string space = "  ";
      string s = StringConcatenate("Broker: ", broker_name); 
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Terminal: ", terminal_type);
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("User: ", user_name);
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Currency: ", currency);
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Trade server: ", trade_server);
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      if (line_break) s += ("-----------------------------------------------" + LStringWorker::lineBreakeSymbol());
      s += StringConcatenate("Ballance:  ", DoubleToStr(my_balance, 1));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);      
      s += StringConcatenate("Margin/free size:  ", DoubleToStr(margin_size, 1), " / ", DoubleToStr(balance_free, 1));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      return s;
   }
};



////структура для получения информации о текущем количестве открытых/отложенных ордеров 
// и списку относящихся к ним инструментам
struct LOpenedOrdersInfo
{
   LOpenedOrdersInfo() {reset();}
   
   //vars
   int total; //общее количество всех поз (открытые + отложенные)
   LIntList opened_tickets; // тикеты открытых поз
   LIntList pending_tickets; // тикеты отложенных ордеров      
   LStringList couples; //названия всех инструментов которые встречаются во всех позах (открытые + отложенные)
   LStringList opened_couples; //названия всех инструментов которые встречаются в открытых позах
   LStringList pending_couples; //названия всех инструментов которые встречаются в отложенных ордерах

   void reset() 
   {
      total = 0; 
      opened_tickets.clear(); 
      pending_tickets.clear(); 
      couples.clear();  
      opened_couples.clear(); 
      pending_couples.clear();
   }
      
   //выдать строку с полной информацией структуры.
   //line_break указывает на то надо ли вставлять перенос '\n' после каждого значения
   string toStr(bool line_break = false) const
   {
      string space = "  ";
      string s = StringConcatenate("All orders: ", total); 
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("opened/pending:  ", IntegerToString(opened_tickets.count(), 1), " / ", IntegerToString(pending_tickets.count(), 1));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Couples count: ", couples.count()); 
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("opened/pending:  ", IntegerToString(opened_couples.count(), 1), " / ", IntegerToString(pending_couples.count(), 1));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);     
      return s;
   }
   
};


//обзор доступных инструментов
struct LMarketWatchInfo
{
   LMarketWatchInfo() {reset();}

   //names containers of market
   LStringList q_couples; //валютные пары
   LStringList cfd; //stocks list
   LStringList indexes; // indexes list
   LStringList crypto; //crypto list
    
   void reset() {q_couples.clear(); cfd.clear(); indexes.clear(); crypto.clear();}
   int total() const {return (q_couples.count() + cfd.count() + indexes.count() + crypto.count());} //общее количество всех инструментов
   string toStr(bool line_break = false) const
   {
      string space = "  ";
      string s = StringConcatenate("All couple: ", total()); 
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Currency couples:  ", IntegerToString(q_couples.count()));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Stocks:  ", IntegerToString(cfd.count()));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Indexes:  ", IntegerToString(indexes.count()));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("Crypto:  ", IntegerToString(crypto.count()));
      return s;
   }
   
};


//структура для хранения информации о торговых условиях для заданного инструмента
struct LMarketCoupleInfo
{
   LMarketCoupleInfo(string v) :couple(v) {}
   
   string couple;
   double spread; //спред в пунктах
   double swap_buy; //своп на покупку в пунктах
   double swap_sell; //своп на продажу в пунктах
   double pip_price; //цена пункта при 1 лоте
   double need_margin; //требуемый залог при 1 лоте
   double min_lot;
   double cur_price;
   int digist; //точность цены для  этого инструмента
   
   
   
   bool invalidTicker() const {return (min_lot < 0.01 || cur_price < 0.01 || digist < 1);}
   void reset() {spread = swap_buy = swap_sell = pip_price = need_margin = min_lot = 0; cur_price=-1; digist=0;}
   
   double spredSize_p() const  //размер спреда в процентах от текущей цены
   {
      if (invalidTicker()) return -1;
      
      double k = 1/double(MathPow(10, digist));          
      return double(100)*(k*spread/cur_price);
   }
   
   string toStr(bool line_break = false) const
   {
      string space = "  ";
      string s = StringConcatenate(couple, ": "); 
      
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("cur_price=", DoubleToStr(cur_price, digist));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("spread=", DoubleToStr(spread, 1));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("swap_buy=", DoubleToStr(swap_buy, 2));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("swap_sell=", DoubleToStr(swap_sell, 2));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("pip_price=", DoubleToStr(pip_price, 2));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("need_margin=", DoubleToStr(need_margin, 1));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("min_lot=", DoubleToStr(min_lot, 2));
      s += (line_break ? LStringWorker::lineBreakeSymbol() : space);
      s += StringConcatenate("digist=", IntegerToString(digist));
      return s;
   }

};


