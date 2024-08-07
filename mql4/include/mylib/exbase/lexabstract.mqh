//+------------------------------------------------------------------+
//|                                                     gamebase.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/exbase/lexerr.mqh>
#include <mylib/common/lstring.mqh>

//абстрактный класс для любого советника, с основными базовыми заготовками функций
//все параметры задавать учитывая точность (digist) рабочих инструментов, для разных инструментов она может быть разной. 
//перед запуском советника должна быть создана папка с названием fullName() в папке терминала MQL4/Files
class LExAbstract
{
public:
   LExAbstract() :is_valid(false), m_magic(0) {m_inputParams.clear();}
   virtual ~LExAbstract() {}
   
   virtual void exInit();//выполнить инициализацию (загрузка всех конфигов и состояний), необходимо выполнить сразу после создания объекта   
   virtual void exDeinit(); //завершить работу, необходимо выполнить перед удалением объекта
   virtual void mainExec(); //главная функция работы советника, которая выполняется с заданным периодом 

   inline bool invalid() const {return !is_valid;}
   inline void setMagic(int x) {if (x >= 0) m_magic = x;}  
   inline void setInputParam(int key, double value) {m_inputParams.insert(key, value);}
  
   //признак того что терминал 5-ти знаковый
   static bool isTerminalFive() {return (int(MarketInfo("EURUSD", MODE_DIGITS)) == 5);} 
   //парсит строку состояния из файла state.txt и записывает значения в контейнер (для одного инструмента)
   static void parseStateFileLine(const string, LDoubleList&);
   //преобразует values в строку для записи состояния в файл state.txt (для одного инструмента)
   static string toStateFileLine(const LDoubleList &values, const LIntList &precisions);

protected:
   bool is_valid; //обобщенный признак валидности всего советника
   int m_magic;
   datetime last_save_time; //время последней записи в файл состояния советника

   LMapIntDouble m_inputParams;    //входные параметры для работы советника (задавать всегда для 4-х значного советника)
   MQConnectionState m_connectionState; //счетчик ошибок сетевого соединения с сервером   
   MQErr m_err; //счетчик ошибок при работе советника

   
   //функции, которые необходимо переопределить в классе-наследнике
   virtual string name() const {return "test_name";} //имя советника
   virtual void work() = 0; //выполнить сценарий алгоритма конкретной стратегии (основная функция)
   virtual void saveState() = 0; //сохранить состояние советника
   virtual void loadState() = 0; //загрузить состояние советника
   virtual void loadInputParams() = 0; //загрузить входные параметры советника

   
   //рабочие файлы советника, создаются в папке советника fullName()   
   inline string stateFile() const {return "state.txt";}
   inline string errorsFile() const {return "errors_log.txt";}
   inline string connectionFile() const {return "connection_log.txt";}

   string fullName() const; //полное уникальное имя экземпляра советника (name()+magic)
   string fullFileName(const string) const; //вернуть полный путь файла (fullName()/fname)   
   void addErr(int, string other = ""); // добавить в файл протокола сообщение об ошибке

private:
   void initConnStateObj(); //инициализация объекта m_connectionState
   void initErrObj(); //инициализация объекта m_err
   bool needLoadSaveState() const; //признак наличия не нулевого временного интервала между сохранениями настроек во входных параметрах советника, иначе состояние советника не сохраняется/загружается
   void trySaveState(bool&); //попытка очередного сохранения состояния по истечении заданного интервала


};
//////////////////////// CPP DISCRIPTION //////////////////////////////////////////
void LExAbstract::mainExec()
{
   if (invalid())
   {
      Print("Expert "+fullName()+" is incorrect, impossible running.");
      return;      
   }
   
   //check save state
   bool was_saved;
   trySaveState(was_saved);
   if (was_saved) return;
   
   //check exec algoritm
   m_connectionState.checkState();
   if (m_connectionState.curStateOk()) work();
}
void LExAbstract::parseStateFileLine(const string f_line, LDoubleList &list)
{
   list.clear();
   LStringList arr;
   LStringWorker::split(f_line, LFile::splitSymbol(), arr);
   if (arr.isEmpty()) {Print("AbstractGame::parseStateFileLine ERR parsed state line invalid"); return;}
   
   int n = arr.count();
   for (int i=0; i<n; i++)
   {
      string v = arr.at(i);
      v = LStringWorker::trim(v);
      if (v == "") continue;
      list.append(StrToDouble(v));
    }
}
string LExAbstract::toStateFileLine(const LDoubleList &values, const LIntList &precisions)
{
   string f_line;
   if (values.isEmpty()) {Print("AbstractGame::toStateFileLine ERR  state values is empty"); return "??";}
   if (values.count() != precisions.count()) {Print("AbstractGame::toStateFileLine ERR  values  count != precisions count"); return "??";}
   
   int n = values.count();
   for (int i=0; i<n; i++)
   {
      if (i > 0) f_line += LFile::splitSymbol();
      string s = DoubleToStr(values.at(i), precisions.at(i));
      f_line += s;
   }
   
   return f_line;
}
void LExAbstract::trySaveState(bool &was_saved)
{
   was_saved = false;
   if (!needLoadSaveState()) return;
   
   int d_sec = LDateTime::dTime(last_save_time, TimeLocal());
   if (d_sec > int(m_inputParams.value(exipSaveInterval)))
   {
      Print("Expert "+fullName()+" try save state ........");
      saveState();
      was_saved = true;
      last_save_time = TimeLocal();   
   }
}
void LExAbstract::initConnStateObj()
{
   string fname = fullFileName(connectionFile());
   m_connectionState.setProtocolFileName(fname);
   m_connectionState.expertInit();
}
void LExAbstract::initErrObj()
{
   string fname = fullFileName(errorsFile());
   m_err.setProtocolFileName(fname);
   m_err.load();   
}
string LExAbstract::fullFileName(const string fname) const
{
   if (StringLen(fname) < 5) 
   {
      Print("AbstractGame::fullFileName error file name - ", fname);
      return "";
   }
   return (fullName()+"/"+fname);    
}
string LExAbstract::fullName() const
{
   if (m_magic > 0) 
      return (name()+IntegerToString(m_magic));    
   return name();
}
void LExAbstract::exInit()
{
   Print("try execute init() ....");
   is_valid = false;
   if (!LFile::isDirExists(fullName()))
   {
      Print("ERR: Expert folder not found: ", fullName());
      MessageBox(StringConcatenate("Expert folder not found: ", fullName()), "Error initialization!");
      return;
   }
   
   initErrObj();
   initConnStateObj();
   loadInputParams();
   if (invalid()) return;
   
   //try load state   
   last_save_time = TimeLocal();
   if (needLoadSaveState()) loadState();
   
   Print("Expert [", fullName(), "] was success started!!!");
}
void LExAbstract::exDeinit()
{
   m_connectionState.expertDeinit();
   if (invalid()) return;
   
   if (needLoadSaveState()) saveState();
}
void LExAbstract::addErr(int err_code, string other)
{
   m_err.appendError(err_code, other);
   string s = "ERR: " + MQEnumsStatic::strByType(err_code);
   if (other != "") s += (" (" + other + ")");
   Print(name(), "   ", s);
}
bool LExAbstract::needLoadSaveState() const
{
   if (!m_inputParams.contains(exipSaveInterval)) return false;
   int t = int(m_inputParams.value(exipSaveInterval));
   return (t > 1);
}







/*
//абстрактный класс для работы с одним инструментом
class AbstractGameCouple
{
public:
   AbstractGameCouple(string v) :m_symbol(v) {reset();}
   virtual ~AbstractGameCouple() {}
   
   void setPeriod(int); //установить значение m_period, некорректное значение не установится
   
   //предполагается что значения корректные и конвертированные для нужного терминала
   inline void setMagic(int x) {m_magic = x;}  
   inline void setSlip(int x) {m_slip = x;}  
   inline void setMaxSpread(int x) {m_maxSpread = x;}  
   inline void setTradeType(int x) {m_tradeType = x;}  
   
   inline string symbol() const {return m_symbol;}

protected:
   string m_symbol; //название инструмента
   int m_period; // тайм фрейм с которым предстоит работать
   int m_slip;
   int m_magic;
   int m_maxSpread; //допустимый спред для открытия помиций, -1 значит не обращать внимания на спред
   int m_tradeType; //тип допустимых опрераций при открытии позиций

   void reset() {m_magic = 0; m_slip = 10; m_period = PERIOD_H1; m_maxSpread = -1; m_tradeType = -1;}
   bool spreadOver() const; //признак того, что в текущий момент спред по инструенту превышен
   
};
bool AbstractGameCouple::spreadOver() const
{
   if (m_tradeType < 0) return false;
   int cur_sread = int(MarketInfo(m_symbol, MODE_SPREAD));
   return (cur_sread > m_tradeType);
}
void AbstractGameCouple::setPeriod(int tf)
{
   switch (tf)
   {
      case PERIOD_M1:
      case PERIOD_M5:
      case PERIOD_M15:
      case PERIOD_M30:
      case PERIOD_H1:
      case PERIOD_H4:
      case PERIOD_D1:
      case PERIOD_W1:
      case PERIOD_MN1: {m_period = tf; break;}
      default: {Print("AbstractGameCouple::setPeriod() ERR: invalid timframe ", tf); break;}
   }
}

*/








