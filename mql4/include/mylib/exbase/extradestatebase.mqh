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


//базовый класс для хранения состояния торговли по одному инструменту
class ExCoupleStateBase
{
public:
   ExCoupleStateBase(string v) :m_couple(v) {}
   virtual ~ExCoupleStateBase() {}
   
   inline string instrumentName() const {return m_couple;}
   
   virtual void load(const LStringList &state_data, string &err) = 0;
   
protected:
   string m_couple;
      


};


//контейнер состояний для всех рабочих инструментов советника
//файл состо
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
   
    //добавить елемент в m_state унаследованный от ExCoupleStateBase, 
    //выполняется на этапе инициализации советника
   virtual void addCoupleState(ExCoupleStateBase*);
   
   bool containsInstrument(string) const; //признак нахождения указанного инструмента в m_state

protected:
   ExCoupleStateBase* m_state[];


   void reset();
   void loadStateByCouple(LStringList&, string &err); //загрузка состояния по указанному инструменту
   ExCoupleStateBase* coupleState(string) const; //выдать елемент m_state по названию инструмента or NULL


};
void ExStateContainer::addCoupleState(ExCoupleStateBase *cs)
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
void ExStateContainer::loadState(const LStringList &state_data, string &err)
{
   err = "";
   if (isEmpty()) {err = "state container is empty"; return;}
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
         if (!couple_state.isEmpty())
         {
            loadStateByCouple(couple_state, err);
            if (err != "") return;           
         }
         
         couple_state.clear();  
         couple_state.append(couple);       
      }
   }
         
   if (!couple_state.isEmpty())
      loadStateByCouple(couple_state, err);
   
}
void ExStateContainer::loadStateByCouple(LStringList &data, string &err)
{
   string couple = data.at(0);
   data.removeFirst();
   data.trim();         

   if (!containsInstrument(couple))
   {
      err =  StringConcatenate("find invalid instrumet: ", couple);
      return;
   }
   if (data.isEmpty())
   {
      err =  StringConcatenate("state date by couple: ", couple, " is empty");
      return;
   }
   
    ExCoupleStateBase *cs = coupleState(couple);
    cs.load(data, err);
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
   




