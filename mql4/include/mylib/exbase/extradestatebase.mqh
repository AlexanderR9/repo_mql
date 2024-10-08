//+------------------------------------------------------------------+
//|                                             extradestatebase.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

/*
базовый класс для хранения/загрузки/выгрузки текущего состояния торговли по рабочим инструментам
файл состояния должен иметь следующий вид:
      [INSTRUMENT1]
        param1
        param2
        .....   

      [INSTRUMENT2]
        param1
        param2
        .....   
        
загрузка/выгрузка параметров-состояния для конкретного советника переопределяется в функции load()/save()       
в класе унаследованном от ExCoupleStateBase
*/


#include <mylib/common/lstring.mqh>


//базовый класс для хранения состояния торговли по одному инструменту.
//подразумевается что для каждой стратегии, нужно разработать свой класс хранения состояния по инструменту, унаследованный от ExCoupleStateBase
class ExCoupleStateBase
{
public:
   ExCoupleStateBase(string v);// :m_couple(v) {}
   virtual ~ExCoupleStateBase() {reset();}
   
   inline string instrumentName() const {return m_couple;}
   
    //считывает все значения параметров состояния для текущего инструмента
   // на вход поступает только полезные строки со значениями (без шапки вида [INSTRUMENT1])      
    //в случае ошибки в параметр err запишется текст ошибки
   virtual void load(const LStringList &state_data, string &err) = 0;

   //записывает  все значения параметров состояния для текущего инструмента, 
   //записываются только сами значения параметров-состояния,
   //шапка вида [INSTRUMENT1] и доп. пустые строки не пишутся
   virtual void save(LStringList &state_data) = 0; 
   
   //размер блока state_data (количество элементов) не включая шапку вида [INSTRUMENT1]
   virtual uint stateBlockSize() const = 0; 
   
   //заполнение m_values дефолтными значениями, зависит от стратегии, выполняется сразу после создания объекта
   virtual void initValues() = 0; 
   
   //обновить значение в m_values по ключу, если такого ключа нет, то ничего не происходит
   virtual void updateValue(int, double);
   
   // распарсить строку состояния из файла в которой находится список тикетов разделенных '*',
   // количетсво '*' не важно, все пустые подстроки игнорятся
   // результат запишется во 2-й параметр
   static void loadTicketsFromStateLine(const string &fline, LIntList &result); 

   //сформировать строку состояния в которой будут записаны тикеты ордеров/поз разделенных '*'
   //если список list пуст, то вернет '*'
   static string ticketsToStateLine(const LIntList &list); 

   //симол разделяющий значения в одной строке файла-состояния
   static string lineSeparator() {return "*";}
   
   inline string lastErr() const {return m_lastErr;}
   inline bool hasErr() const {return (m_lastErr != "");}
   inline int digist() const {return m_digist;}
   
   virtual string toStr() const; //diag func

protected:
   string m_couple;
   LMapIntDouble m_values; //контейнер для хранения значений параметров-состояния, key - ExStateParamsTypes     
   string m_lastErr; //вспомогательная переменная для хранения последней ошибки при обращении к этому объекту (если таковая была)
   int m_digist; //вспомогательная переменная для хранения точности цены инструмента m_couple

   virtual void reset() {m_couple = m_lastErr = ""; m_values.clear();}
      
};
ExCoupleStateBase::ExCoupleStateBase(string v) 
   :m_couple(v),
   m_lastErr("") 
{
   m_values.clear();
   m_digist = int(MarketInfo(m_couple, MODE_DIGITS));
}
string ExCoupleStateBase::toStr() const
{
   string s = StringConcatenate("ExCoupleState: INSTRUMENT(", m_couple,")");
   s += StringConcatenate("  digist=", m_digist, "  map_values(", m_values.count(), ")");   
   return s;
}
void ExCoupleStateBase::loadTicketsFromStateLine(const string &fline, LIntList &list)
{
   list.clear();
   string s = LStringWorker::trim(fline);      
   if (LStringWorker::len(s) < 5) return;
   
   LStringList s_list;
   LStringWorker::split(s, lineSeparator(), s_list, false);
   if (s_list.isEmpty()) return;   
      
   bool ok;
   int n = s_list.count();
   for (int i=0; i<n; i++)
   {
      string v = s_list.at(i);
      v = LStringWorker::trim(v);
      if (v == "") continue;
      
      int a = LStringWorker::toInt(v, ok);
      if (GetLastError() == 0) list.append(a);
      else Print("ExCoupleStateBase::loadTicketsFromStateLine WARNING: can't convert string to INT: ", v);
   }   
}
string ExCoupleStateBase::ticketsToStateLine(const LIntList &list) 
{
   string s = lineSeparator();
   if (!list.isEmpty())
   {
      int n = list.count();
      for (int i=0; i<n; i++)
      {
         s += IntegerToString(list.at(i));
         s += lineSeparator();
      }
   }
   return s;
}
void ExCoupleStateBase::updateValue(int key, double v)
{
   if (m_values.contains(key))
      m_values.insert(key, v);
}

///////////////////////////////////////////////////////////////////////////////////////////////////


//контейнер состояний для всех рабочих инструментов советника.
//содержится как член класса в каждом советнике, который ведет торговлю.
//нужен для сохранения/чтения - текущего состояния торговли советника.
class ExStateContainer
{
public:
   ExStateContainer() {reset();}
   virtual ~ExStateContainer() {reset();}
   
   inline int count() const {return ArraySize(m_state);}
   inline bool isEmpty() const {return (count() == 0);}

   //загрузка полного состояния советника для всех инструментов.
   //на вход подается полное содержимое файла-состояния stateFile()
   //в случае ошибки в параметр err запишется соответствующий текст
   virtual void loadState(const LStringList &state_data, string &err);
   
   //получение полного состояния советника для всех инструментов.
   //state_data записывается полностью для дальнейшей перезаписи файла-состояния stateFile()
   virtual void saveState(LStringList &state_data);   
   
    //добавить елемент в m_state унаследованный от ExCoupleStateBase, 
    //выполняется на этапе инициализации советника
   virtual void addCoupleStateObj(ExCoupleStateBase*);
   
   bool containsInstrument(string) const; //признак нахождения указанного инструмента в m_state
   const ExCoupleStateBase* coupleStateAt(int) const; //выдать елемент m_state по index or NULL
   ExCoupleStateBase* coupleStateAtVar(int); //выдать елемент m_state по index or NULL
   void updateValue(string couple, int key, double v); //обновить конкретное значение для указанного инструмента в m_state

protected:
   ExCoupleStateBase* m_state[];

   void reset();
   void loadStateByCouple(LStringList&, string &err); //загрузка состояния по указанному инструменту
   ExCoupleStateBase* coupleState(string) const; //выдать елемент m_state по названию инструмента or NULL

};
void ExStateContainer::addCoupleStateObj(ExCoupleStateBase *cs)
{
   if (cs != NULL)
   {
      int n = count();
      ArrayResize(m_state, n+1);
      m_state[n] = cs;
   }
}
void ExStateContainer::reset()
{
   if (isEmpty()) return;
   
   int n = count();
   for (int i=0; i<n; i++) 
   {
      delete m_state[i];
      m_state[i] = NULL;
   }
   ArrayFree(m_state);
}
void ExStateContainer::updateValue(string couple, int key, double v)
{
   ExCoupleStateBase *cs = coupleState(couple);
   if (cs) cs.updateValue(key, v);
}
ExCoupleStateBase* ExStateContainer::coupleState(string v) const
{
   if (!isEmpty())   
   {
      int n = count();
      for (int i=0; i<n; i++) 
         if (m_state[i].instrumentName() == v) return m_state[i];   
   }
   return NULL;
}
ExCoupleStateBase* ExStateContainer::coupleStateAtVar(int i)
{
   if (i<0 || i>=count()) return NULL;
   return m_state[i];
}
const ExCoupleStateBase* ExStateContainer::coupleStateAt(int i) const
{
   if (i<0 || i>=count()) return NULL;
   return m_state[i];
}
void ExStateContainer::loadState(const LStringList &state_data, string &err)
{
   err = "";
   if (isEmpty()) {err = "ExStateContainer: state container is empty"; return;}
   if (state_data.isEmpty()) {Print("WARNING: loadState => state data is empty"); err="state data is empty"; return;}
   
   LStringList couple_state;
   couple_state.clear();
   
   int n = state_data.count();
   for (int i=0; i<n; i++) 
   {
      string s = state_data.at(i);
      s = LStringWorker::trim(s);
      if (s == "") continue;
      
      string couple = LStringWorker::subStrByRange(s, "[", "]");
      if (couple != "") //find new state block
      {
         Print("find start state block: [", couple, "]");
         if (!couple_state.isEmpty())
         {
            loadStateByCouple(couple_state, err);
            if (err != "") return;           
         }
         
         couple_state.clear();  
         couple_state.append(couple);       
      }
      else couple_state.append(s);       
   }
         
   if (!couple_state.isEmpty())
      loadStateByCouple(couple_state, err);   
}
void ExStateContainer::saveState(LStringList &state_data)
{
   state_data.clear();
   if (isEmpty()) return;
      
   int n = count();
   for (int i=0; i<n; i++) 
   {
      ExCoupleStateBase *state_obj = m_state[i];
      if (!state_obj) continue;
      
      LStringList couple_state;
      state_data.append(StringConcatenate("[", state_obj.instrumentName(), "]"));      
      state_obj.save(couple_state);
      state_data.append(couple_state);
      state_data.append("");
   }
}
void ExStateContainer::loadStateByCouple(LStringList &data, string &err)
{
   Print("loadStateByCouple - block size ", data.count());
   string couple = data.at(0);
   data.removeFirst();
   data.trim();         

   if (!containsInstrument(couple))
   {
      err =  StringConcatenate("ExStateContainer: find invalid instrumet: ", couple);
      return;
   }
   if (data.isEmpty())
   {
      err = StringConcatenate("ExStateContainer: state data by couple: ", couple, " is empty");
      return;
   }
   
    ExCoupleStateBase *cs = coupleState(couple);
    cs.load(data, err);
    Print(cs.toStr());
}
bool ExStateContainer::containsInstrument(string v) const
{
   if (LStringWorker::trim(v) == "") return false;
   if (isEmpty()) return false;
   
   int n = count();
   for (int i=0; i<n; i++) 
      if (m_state[i].instrumentName() == v) return true;
      
   return false;      
}
   


