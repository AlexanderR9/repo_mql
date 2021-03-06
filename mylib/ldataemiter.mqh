//+------------------------------------------------------------------+
//|                                                   dataemiter.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


#include <mylib/lstring.mqh>
#include <mylib/lfile.mqh>
#include <mylib/ldatetime.mqh>



////////////LEmitDataElement////////////////////
//один элемент цены с соответствующим для нее временем
struct LEmitDataElement
{
   LEmitDataElement() :dt(0), price(-1) {}
   LEmitDataElement(const datetime &t, const double &p) :dt(t), price(p) {}
   LEmitDataElement(const LEmitDataElement &el) :dt(el.dt), price(el.price) {}
   
   //vars
   datetime dt;
   double price;
   
   //funcs
   void setData(const LEmitDataElement &el) {dt = el.dt; price = el.price;}
   void setData(const datetime &t, const double &p) {dt = t; price = p;}
   string toStr() const {return StringConcatenate("History element:  time=", LDateTime::dateTimeToString(dt, ".", ":", false), "  price=", price);}
};


////////////LCoupleEmiter////////////////////
class LCoupleEmiter
{
public:
   LCoupleEmiter(string couple) :m_couple(LStringWorker::trim(couple)) {reset();}
   virtual ~LCoupleEmiter() {}
   
   inline int count() const {return m_size;} //количество прочитанных цен
   inline bool isEmpty() const {return (count() == 0);}
   inline bool invalid() const {return !m_validity;}
   inline void stop() {last_getter_index = 0;}
   inline bool finished() const {return (last_getter_index < 0);}
   inline string couple() const {return m_couple;}
   
   
   void loadFile(); //загрузка файла данных
   void getRecordAt(int, LEmitDataElement&) const; //получение одной записи по индексу из контейнера m_history
   
   
   //выдать цену по заданному времени, если данных до и после dt нет то вернет -1, 
   //если нет такой записи с временем dt, то вернет последнюю до этого времени
   double getPrice(const datetime &dt); 
   
    
   static string historyDataDir() {return "fx_data";} //каталог с файлами данных, должен находится в папке MQL4/Files
   
protected:
   string m_couple;
   LEmitDataElement m_history[]; //исторические данные
   bool m_validity; //становится true после успешной загрузки данных из файла
   int m_size; //реальное количество значений цен, счетчик прочитанных строк
   int last_getter_index; //индекс записи, которая была выдана в последнем запросе
   
   void tryReadFile(string f_name, string &arr[], string &err);
   void parseFileLine(const string&); //парсинг одной строки данных
   void reset() {m_size = 0; m_validity = false; last_getter_index = -1;}
       
};
void LCoupleEmiter::getRecordAt(int i, LEmitDataElement &rec) const
{
   if (i<0 || i<=count()) return;
   rec.setData(m_history[i]);
}
double LCoupleEmiter::getPrice(const datetime &dt)
{
   if (isEmpty() || finished()) return -1;
   if (dt < m_history[0].dt || dt > m_history[m_size-1].dt) return -1;
   
   double price = -1;
   last_getter_index--;
   while (last_getter_index < m_size)
   {
      last_getter_index++;
      if (m_history[last_getter_index].dt < dt) continue;
      price = m_history[last_getter_index].price;
      break;
   }
   
   if (last_getter_index >= m_size) last_getter_index = -1;   
   return price;
}
void LCoupleEmiter::loadFile()
{
   Print("Try load data for ", m_couple, " .............");
   string v = LStringWorker::trim(m_couple);
   if (v == "")
   {
      Print("LCoupleEmiter::loadFile() ERR: couple is empty!");
      return;
   }

   string f_name = StringConcatenate(historyDataDir(), "/", m_couple, "_modif.txt");
   string f_data[];
   string err;
   tryReadFile(f_name, f_data, err);
   if (err != "")
   {
      Print("LCoupleEmiter::loadFile() ERR: ", err);
      return;
   }
   
   int n = ArraySize(f_data);
   if (n == 0)
   {
      Print("LCoupleEmiter::loadFile() WARNING: file data is Empty!  file: ", f_name);
      return;
   }
   
   for (int i=0; i<n; i++)
      parseFileLine(f_data[i]);
      
   if (isEmpty())      
   {
      Print("LCoupleEmiter::loadFile() WARNING: parsing data is Empty!  file: ", f_name);
      return;
   }
   
   ArrayResize(m_history, m_size);   
   m_validity = !isEmpty();      
}
void LCoupleEmiter::parseFileLine(const string &line)
{
   if (LStringWorker::trim(line) == "") return;
   
   LStringList arr;
   LStringWorker::split(line, LFile::splitSymbol(), arr);
   if (arr.count() != 2) return;
   
   bool ok;
   datetime dt = LDateTime::fromString(arr.at(0), ok);
   if (ok)
   {
      double price = StrToDouble(arr.at(1));
      if (m_size == ArraySize(m_history)) ArrayResize(m_history, m_size+1000);
      m_history[m_size].setData(dt, price);
      m_size++;   
   }
   
   
   //if (n < 5) Print(m_history[n].toStr());
}
void LCoupleEmiter::tryReadFile(string f_name, string &arr[], string &err)
{
   err = "";
   ArrayFree(arr);
   ResetLastError();
   
   if (!FileIsExist(f_name))
   {
      err = StringConcatenate("file not found: ", f_name);
      return;
   }   
   
   int f_handle = FileOpen(f_name, FILE_TXT | FILE_READ);
   if (f_handle < 1)
   {
      err = StringConcatenate("can not open file: ", f_name, "  err_code=", GetLastError());
      return;
   }
   
    FileReadArray(f_handle, arr);
    int code = GetLastError();
    FileClose(f_handle);
    
    if (code != 0)
    {
      err = StringConcatenate("invalid reading data of file: ", f_name, "  err_code=", code);
      ArrayFree(arr);
      return;    
    }
}


////////////LDataEmiter////////////////////
class LDataEmiter
{
public:
   LDataEmiter() {reset();}
   virtual ~LDataEmiter() {destroyAll();}
   
   int count() const {return ArraySize(m_data);}
   bool isEmpty() const {return (count() == 0);}
   void addCouple(string);
   void setTimeRange(int, int); //задать интервал имитации данных, задается в виде 20190801 т.е. ГодМесяцДень
   void setTimeFrame(int tf) {m_tf = tf;}
   
   void stop(); //остановить данные, перевести все пары в исходное состояние
   bool finished() const {return (m_iterator < 0);} //признак того что имитация окончена, время вышло за end_dt или загруженные данные закончились по всем парам
   void nextData(LMapStringDouble&, datetime&); //выдать очередную порцию данных
   
protected:
   LCoupleEmiter*  m_data[];      
   datetime begin_dt; //начальная дата имитации, время берется 00:00
   datetime end_dt; //конечная дата имитации, время берется 00:00
   int m_tf; //имитируемый таймфрейм графиков заданных пар
   int m_iterator; //cчетчик интервалов данных с периодом m_tf
   
   void destroyAll();
   void reset();
   bool invalid() const;
   datetime nextDT() const; //сгенерить очередное время данных

};
void LDataEmiter::nextData(LMapStringDouble &map, datetime &dt)
{
   map.clear();
   if (invalid()) {Print("LDataEmiter::nextData ERR - invalid parameters obj"); return;}
   if (finished()) {Print("LDataEmiter::nextData WARNINT - emitator is finished!!!"); return;}
   
   dt = nextDT();
   if (dt > end_dt) {m_iterator = -1; return;}
   m_iterator++;
   
   int n = count();
   for (int i=0; i<n; i++)
   {
      if (m_data[i].finished()) continue;
      string v = m_data[i].couple();
      double price = m_data[i].getPrice(dt);
      if (price > 0) map.insert(v, price);
   }
   
   if (map.isEmpty()) m_iterator = -1;
}
datetime LDataEmiter::nextDT() const
{
   datetime dt = begin_dt;
   int n_sec = 60*m_tf*m_iterator;
   LDateTime::addSecs(dt, n_sec);
   return dt;
}
void LDataEmiter::stop()
{
   m_iterator = 0;
   if (isEmpty()) return;
   int n = count();
   for (int i=0; i<n; i++) m_data[i].stop();
}
void LDataEmiter::setTimeRange(int t1, int t2)
{
   string s1 = IntegerToString(t1);
   string s2 = IntegerToString(t2);
   if (StringLen(s1) != 8 || StringLen(s2) != 8) {Print("LDataEmiter::setTimeRange Invalid values"); return;}
   
   bool ok;
   string s_dt = StringConcatenate(StringSubstr(s1, 6, 2), ".", StringSubstr(s1, 4, 2), ".", StringSubstr(s1, 0, 4));
   begin_dt = LDateTime::fromString(s_dt, ok);
   if (!ok)
   {
      Print("LDataEmiter::setTimeRange ERR parse begin_dt");
      reset();
      return;
   }
   
   s_dt = StringConcatenate(StringSubstr(s2, 6, 2), ".", StringSubstr(s2, 4, 2), ".", StringSubstr(s2, 0, 4));
   end_dt = LDateTime::fromString(s_dt, ok);
   if (!ok)
   {
      Print("LDataEmiter::setTimeRange ERR parse end_dt");
      reset();
      return;
   }
   
   Print("Set time range success:   ", LDateTime::dateTimeToString(begin_dt, ".", ":", false), " - ", LDateTime::dateTimeToString(end_dt, ".", ":", false));
}
void LDataEmiter::reset()
{
   begin_dt = LDateTime::year20();
   end_dt = LDateTime::year20();
   m_tf = 5;
}
bool LDataEmiter::invalid() const
{
   if (isEmpty()) return true;
   if (begin_dt <= LDateTime::year20() || begin_dt > TimeCurrent()) return true;
   if (end_dt <=  begin_dt || end_dt > TimeCurrent()) return true;
   if (m_tf != 1 && m_tf != 5 && m_tf != 15 && m_tf != 30 && m_tf != 60) return true;
   return false;
}
void LDataEmiter::destroyAll()
{
   int n = count();
   if (n > 0)
   {
      for (int i=0; i<n; i++)
         delete m_data[i];
   }
   ArrayFree(m_data);
}
void LDataEmiter::addCouple(string v)
{
   LCoupleEmiter *c_emiter = new LCoupleEmiter(v);
   c_emiter.loadFile();
   if (c_emiter.invalid())
   {
      Print("invalid state data for ", v);
      delete c_emiter;
      return;
   }
   
   int n = count();
   ArrayResize(m_data, n+1);
   m_data[n] = c_emiter;
   Print("Couple ", v, " added successed,  history size ", m_data[n].count());
}



