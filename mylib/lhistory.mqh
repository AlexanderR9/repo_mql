//+------------------------------------------------------------------+
//|                                                     lhistory.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/ltrade.mqh>
#include <mylib/lfile.mqh>


//текущие цены в mt4 на момент открытия позиции
struct LMTPrices
{
   LMTPrices() {reset();}
   LMTPrices(const double &a, const double &b) :mt_ask(a), mt_bid(b) {}
   LMTPrices(string v) {reset(); setValues(v);}
   
   double mt_ask;
   double mt_bid;
   
   void reset() {mt_ask = 0; mt_bid = 0;}
   void setValues(const string &v)
   {
      if (!MQValidityData::isValidCouple(v)) {Print("LMTPrices::setValues ERROR SYMBOL"); return;}
      mt_ask = MarketInfo(v, MODE_ASK);
      mt_bid = MarketInfo(v, MODE_BID);
   }
   void setValues(const double &a, const double &b)
   {
      mt_ask = a;
      mt_bid = b;
   }
   void toStr(LStringList &list, int dig) const 
   {
      list.append(DoubleToString(mt_ask, dig));
      list.append(DoubleToString(mt_bid, dig));
   }
   void fromStr(const LStringList &list, int &i)
   {
      mt_ask = StrToDouble(list.at(i)); i++;
      mt_bid = StrToDouble(list.at(i)); i++;
   }
   
};

//ценовые значения ордера
struct LOrderPrices
{
   LOrderPrices() {reset();}

   double cmd; //запрошенная цена при посылке команды
   double pending; //выставленная цена срабатывания отложенного ордера
   double open; //цена открытия позы
   double close; //цена закрытия позы
   double stoploss; //уровень stoploss
   double takeprofit; //уровень takeprofit

   void reset() {cmd = 0; pending = 0; open = 0; close = 0; stoploss = 0; takeprofit = 0;}
   void toStr(LStringList &list, int dig) const 
   {
      list.append(DoubleToString(cmd, dig));
      list.append(DoubleToString(pending, dig));
      list.append(DoubleToString(open, dig));
      list.append(DoubleToString(close, dig));
      list.append(DoubleToString(stoploss, dig));
      list.append(DoubleToString(takeprofit, dig));
   }
   void fromStr(const LStringList &list, int &i)
   {
      cmd = StrToDouble(list.at(i)); i++;
      pending = StrToDouble(list.at(i)); i++;
      open = StrToDouble(list.at(i)); i++;
      close = StrToDouble(list.at(i)); i++;
      stoploss = StrToDouble(list.at(i)); i++;
      takeprofit = StrToDouble(list.at(i)); i++;
   }
   
};

//результаты работы ордера
struct LOrderResult
{
   LOrderResult() {reset();}

   double result_sum; // итоговый результат в валюте счета (без учета свопа и комиссий)
   double swap_sum; //размера свопа в валюте счета
   double comission_sum; //размера комиссии в валюте счета
   
   //результат выполнения ордера в пунктах (всегда для 4-х значных счетов, на 5-ти тоже работает)
   //для 4-х значных счетов это будет целое число, а для 5-ти значных с одним знаком после запятой
   //может быть как положительным, так и отрицательным числом
   double result_pips;
   
   bool was_takeprofit; //признак того, что сработал takeprofit
   bool was_stoploss; //признак того, что сработал stoploss

   void reset() {result_sum = 0; swap_sum = 0; comission_sum = 0; result_pips = 0; 
                           was_stoploss = false; was_takeprofit = false; }
                           
   void toStr(LStringList &list, int dig) const 
   {
      list.append(DoubleToString(result_sum, dig));
      list.append(DoubleToString(swap_sum, dig));
      list.append(DoubleToString(comission_sum, dig));
      list.append(DoubleToString(result_pips, 1));
      list.append(was_takeprofit ? "true" : "false");
      list.append(was_stoploss ? "true" : "false");
   }
   void fromStr(const LStringList &list, int &i)
   {
      result_sum = StrToDouble(list.at(i)); i++;
      swap_sum = StrToDouble(list.at(i)); i++;
      comission_sum = StrToDouble(list.at(i)); i++;
      result_pips = StrToDouble(list.at(i)); i++;
      was_takeprofit = (list.at(i) == "true"); i++;
      was_stoploss = (list.at(i) == "true"); i++;
   }


};

//временные метки ордера (время сервера)
struct LOrderTimes
{
   LOrderTimes() {reset();}

   datetime sendcmd; //время отправления команды на сервер 
   datetime pending; //время выставления отложенного ордера
   datetime open; //время открытия позы
   datetime close; //время закрытия позы
   
   void reset() {pending = 0; open = 0; close = 0; sendcmd = 0;}
   void toStr(LStringList &list) const 
   {
      list.append(IntegerToString(int(sendcmd)));
      list.append(IntegerToString(int(pending)));
      list.append(IntegerToString(int(open)));
      list.append(IntegerToString(int(close)));
   }
   void fromStr(const LStringList &list, int &i)
   {
      sendcmd = StrToInteger(list.at(i)); i++;
      pending = StrToInteger(list.at(i)); i++;
      open = StrToInteger(list.at(i)); i++;
      close = StrToInteger(list.at(i)); i++;
   }
   
};

//полная инфа по ордеру
class LOrderHistoryInfo
{
public:
   LOrderHistoryInfo() :m_couple(""), m_ticket(-1), m_cmd(-1), m_status(-1), m_lots(0) {reset();}
   LOrderHistoryInfo(string v, int ticket, int cmd) :m_couple(v), m_ticket(ticket), m_cmd(cmd), m_status(-1), m_lots(0) {reset();}
   LOrderHistoryInfo(int ticket) :m_couple(""), m_ticket(ticket), m_cmd(-1), m_status(-1), m_lots(0) {reset();}
   
   inline bool isOpened() const {return (m_status == 0);}
   inline bool isClosed() const {return (m_status == 1);}
   inline bool isCancelled() const {return (m_status == 2);}
   inline bool historyNow() const {return (isClosed() || isCancelled());}
   inline bool invalid() const {return (m_status < 0);}
   
   //инициализация значений m_couple, m_cmd, m_status, m_lots
   //подразумевается, что m_ticket уже задан и ордер на данный момент выделен
   void init();
   
   //обновление переменной m_step (не обязательная функция)
   inline void setStep(int x) {m_step = x;}
   //обновление времени посылки команды на исполнение
   inline void updateSendTime(const datetime &dt) {m_times.sendcmd = dt;}
   //обновление запрошенной цены при посылке команды на исполнение
   inline void updateSendPrice(const double &p) {m_prices.cmd = p;}
   //обновление значений цен терминала
   inline void updateMTPrices(const LMTPrices &mtp) {mt_prices.setValues(mtp.mt_ask, mtp.mt_bid);}
   //проверка, перешел ли ордер в историю, если да обновить структуру результатов
   void tryCheckResult();
   
   
   //преобразование всех полей в строку для записи в файл
   string toFileLine(int) const;
   //считать значения всех полей из строки
   void fromFileLine(const string&, string&);
   //количество значений в строке файла
   int lineParamCount() const {return 25;}
   
protected:   
   int m_ticket;
   string m_couple;
   int m_cmd;
   double m_lots;
   bool is_pending;
   int m_step;
   
   // текущий статус ордера
   // 0 - открыт
   // 1 - закрыт (находится в истории)
   // 2 - удален  (находится в истории)
   // -1 - статус неизвестен
   int m_status;
   
   //order info   
   LOrderTimes m_times;
   LOrderPrices m_prices;
   LMTPrices mt_prices;
   LOrderResult m_result;
   
   void reset() {m_result.reset(); m_prices.reset(); mt_prices.reset(); m_times.reset(); is_pending = false; m_step = 0;}
   //обновление всех полей структуры результатов
   void updateResult(const LCheckOrderInfo&);
   //инициализация времени и цены открытия и is_pending и уровней стопов
   void initOpenParams();
   
private:
   string splitSymbol() const {return ";";}      
   
                      
};
string LOrderHistoryInfo::toFileLine(int dig) const
{
//формат строки:
//couple*order*status*cmd*lots*ispending*times*mtprices*tprices*results
   if (invalid()) return "";
   
   LStringList list;
   list.append(m_couple);
   list.append(IntegerToString(m_ticket));
   list.append(IntegerToString(m_status));
   list.append(IntegerToString(m_cmd));
   list.append(DoubleToString(m_lots, 2));
   list.append(is_pending ? "true" : "false");
   list.append(IntegerToString(m_step));

   m_times.toStr(list);
   mt_prices.toStr(list, dig);
   m_prices.toStr(list, dig);
   m_result.toStr(list, dig);

   string line = list.at(0);
   for (int i=1; i<list.count(); i++)
      line += (LFile::splitSymbol() + list.at(i));
   
   return line;
}
void LOrderHistoryInfo::fromFileLine(const string &line, string &err)
{
   err = "";
   LStringList list;
   list.splitFromString(line, LFile::splitSymbol());
   if (list.isEmpty()) return;     

   if (lineParamCount() != list.count())
   {
      err = "invalid param count, n != " + IntegerToString(lineParamCount());
      return;
   }

//couple*order*status*cmd*lots*ispending*times*mtprices*tprices*results
   int i = 0;
   m_couple = list.at(i); i++;
   m_ticket = StrToInteger(list.at(i)); i++; 
   m_status = StrToInteger(list.at(i)); i++; 
   m_cmd = StrToInteger(list.at(i)); i++; 
   m_lots = StrToDouble(list.at(i)); i++; 
   is_pending = (list.at(i) == "true"); i++;
   m_step = StrToInteger(list.at(i)); i++; 

   m_times.fromStr(list, i);
   mt_prices.fromStr(list, i);
   m_prices.fromStr(list, i);
   m_result.fromStr(list, i);
   
}
void LOrderHistoryInfo::initOpenParams()
{
   is_pending = MQValidityData::isPendingOrder(m_cmd);
   if (is_pending) 
   {
      m_times.pending = OrderOpenTime();
      m_prices.pending = OrderOpenPrice();
   }
   else 
   {
      m_times.open = OrderOpenTime();
      m_prices.open = OrderOpenPrice();
   }
   
   m_prices.stoploss = OrderStopLoss();
   m_prices.takeprofit = OrderTakeProfit();
}
void LOrderHistoryInfo::init()
{
   m_status = -1;
   m_couple = OrderSymbol();
   m_cmd = OrderType();
   m_lots = OrderLots();
   
   if (!MQValidityData::isValidCouple(m_couple)) return;
   if (!MQValidityData::isValidOrderType(m_cmd)) return;
   
   initOpenParams();
   
   if (OrderCloseTime() == 0) m_status = 0;
   else 
   {
      tryCheckResult();
   }
}
void LOrderHistoryInfo::tryCheckResult()
{
   if (invalid()) return;
   if (historyNow()) return;
   
   LTrade trade;
   LCheckOrderInfo info;
   trade.checkOrder(m_ticket, info);
   if (info.isError())
   {
      Print("LOrderHistoryInfo::tryCheckResult() ERR ", info.err_code);
      return;
   }
   
   if (info.isFinished())
   {
      m_times.close = OrderCloseTime();
      m_prices.close = OrderClosePrice();
      m_status = 1;
      updateResult(info);
      
      if (is_pending)
      {
         m_times.open = OrderOpenTime();
         m_prices.open = OrderOpenPrice();
      }
   }
   else if (info.isPengingCancelled())
   {
      m_times.close = OrderCloseTime();
      m_status = 2;   
   }
}
void LOrderHistoryInfo::updateResult(const LCheckOrderInfo &info)
{
   m_result.result_sum = info.result;
   m_result.result_pips = info.result_pips;
   m_result.was_stoploss = info.isStoplossClosed();
   m_result.was_takeprofit = info.isTakeprofitClosed();
   m_result.swap_sum = OrderSwap();
   m_result.comission_sum = OrderCommission();
}


//класс для ведения истории всех торговых операций советника
class LTradeHistory
{
public:
   LTradeHistory() :f_name(""), m_digist(4) {}
   virtual ~LTradeHistory() {clear();}

   inline void setFileName(const string &s) {f_name = s;}
   inline void setDigist(int x) {m_digist = x;}
   inline bool invalid() const {return (StringLen(f_name) < 5);}
   inline string fileName() const {return f_name;}
   
   
   //добавляет новый элемент в контейнер m_data с указанным тикером ордера
   //во 2-параметр записывается код ошибки
   //если code < 0, то новый элемент не создается
   //    -1  некорректное значение ордера
   //    -2  ордер не найден
   //принцип добавления новых ордеров в список истории:
   //предварительно запоминается текущее время сервера и цена открытия,
   //создается экземпляр структуры LMTPrices и в него записываются текущие цены ask и bid,
   //в коде советника открывается поза или выставляется отложенный ордер, если результат успешный,
   //то выполняем метод addOrder с новым тикетом, если код ошибки 0, то далее
   //выполняем методы: updateSendTime, updateSendPrice, updateMTPrices    
   void addOrder(int, int &code); 
      
   //обновление времени посылки команды на исполнение у i-го элементта, если i<0, то последнего
   void updateSendTime(const datetime &dt, int i = -1);
   //обновление запрошенной цены при посылке команды на исполнение у i-го элементта, если i<0, то последнего
   void updateSendPrice(const double &p, int i = -1);
   //обновление значений цен терминала у i-го элементта, если i<0, то последнего
   void updateMTPrices(const LMTPrices &mtp, int i = -1);
   //обновление шага
   void setStep(int, int i = -1);
   
   
   
   void load(string&); //считать историю из файла
   void save(string&); //сохранить историю в файл
   void clear(); //очищает контейнер m_data и удаляет его элементы из памяти
   void checkResult(int n = -1); //проверяет результат работы n последних ордеров (если n < 0, то у всех)
   
protected:
   string f_name;
   int m_digist; //точность брокера (4 или 5 знаков)

   LOrderHistoryInfo* m_data[]; // history data array

   inline int count() const {return ArraySize(m_data);} //возвращает количество элементов контейнера m_data

   const LOrderHistoryInfo* at(int) const;
   LOrderHistoryInfo* atVar(int) const;
   const LOrderHistoryInfo* last() const; //возвращает последний элемент контейнера m_data
   LOrderHistoryInfo* lastVar() const;
      
};


//////////////////////////////////////////////////////////
//////////////////   CPP CODE   //////////////////////////
//////////////////////////////////////////////////////////
void LTradeHistory::load(string &err)
{
   clear();
   
   err = "";
   if (invalid()) {err = "LTradeHistory::load - invalid filename ["+f_name+"]"; return;}
   if (!LFile::isFileExists(f_name)) {err = "LTradeHistory::load - file not found ["+f_name+"]"; return;}
   
   LStringList list;
   int n = LFile::readFileToStringList(f_name, list);
   if (n < 0) {err = "LTradeHistory::load - file can not read ["+f_name+"]"; return;}

   for (int i=0; i<n; i++)
   {
      string s = list.at(i);
      s = StringTrimLeft(s);
      s = StringTrimRight(s);
      if (s == "") continue;
      
      LOrderHistoryInfo *hi = new LOrderHistoryInfo();
      hi.fromFileLine(s, err);
      if (err != "") {delete hi; return;}
      if (hi.invalid()) {delete hi; err = "LTradeHistory::load - loaded invalid LOrderHistoryInfo"; return;}
      
      int nn = count();
      ArrayResize(m_data, nn+1);
      m_data[nn] = hi;
   }

   Print("Successed load file trade history, count ", count());
}
void LTradeHistory::save(string &err)
{
   err = "";
   if (invalid()) {err = "LTradeHistory::save - invalid filename ["+f_name+"]"; return;}

   string s;
   LStringList list;
   
   int nn = count();
   if (nn == 0) return;
   
   for (int i=0; i<nn; i++)
   {
      s = at(i).toFileLine(m_digist);
      list.append(s);   
   }
   
   if (!LFile::stringListToFile(f_name, list)) {err = "LTradeHistory::save - error write file ["+f_name+"]"; return;}
   
   Print("Successed saved file trade history, count ", count());
}
void LTradeHistory::checkResult(int n)
{
   if (n < 0 || n > count()) n = count();
   if (n <= 0) return;
   
   int i = count() - 1;
   int x = 0;
   while (x < n)
   {
      atVar(i).tryCheckResult();
      i--;
      x++;
   }
}
void LTradeHistory::updateSendTime(const datetime &dt, int i)
{
   LOrderHistoryInfo *hi = NULL;
   if (i < 0) hi = lastVar();
   else hi = atVar(i);
   
   if (hi) hi.updateSendTime(dt);
}
void LTradeHistory::setStep(int x, int i)
{
   LOrderHistoryInfo *hi = NULL;
   if (i < 0) hi = lastVar();
   else hi = atVar(i);
   
   if (hi) hi.setStep(x);
}
void LTradeHistory::updateSendPrice(const double &p, int i)
{
   LOrderHistoryInfo *hi = NULL;
   if (i < 0) hi = lastVar();
   else hi = atVar(i);
   
   if (hi) hi.updateSendPrice(p);
}
void LTradeHistory::updateMTPrices(const LMTPrices &mtp, int i)
{
   LOrderHistoryInfo *hi = NULL;
   if (i < 0) hi = lastVar();
   else hi = atVar(i);
   
   if (hi) hi.updateMTPrices(mtp);
}
void LTradeHistory::addOrder(int ticket, int &code)
{
   code = 0;
   if (ticket <= 0) {code = -1; return;}
   if (!OrderSelect(ticket, SELECT_BY_TICKET)) {code = -2; return;}
   
   int n = count();
   ArrayResize(m_data, n+1);
   m_data[n] = new LOrderHistoryInfo(ticket);
   m_data[n].init();


}
void LTradeHistory::clear()
{
   int n = count();
   for (int i=0; i<n; i++)
      delete m_data[i];
   
   ArrayFree(m_data);
   ArrayResize(m_data, 0);
}
const LOrderHistoryInfo* LTradeHistory::at(int index) const
{
   if (index < 0 || index >= count()) return NULL;
   return m_data[index];
}
LOrderHistoryInfo* LTradeHistory::atVar(int index) const
{
   if (index < 0 || index >= count()) return NULL;
   return m_data[index];
}
const LOrderHistoryInfo* LTradeHistory::last() const
{
   return at(count()-1);
}
LOrderHistoryInfo* LTradeHistory::lastVar() const
{
   return atVar(count()-1);
}

