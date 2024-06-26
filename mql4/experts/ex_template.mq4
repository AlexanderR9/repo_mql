//+------------------------------------------------------------------+
//|                                                       spring.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


//шаблонный торговый советник, для ускорения разработки других советников для конкретных задач
#include <mylib/exbase/extradeabstract.mqh>


input int U_SaveStateInterval = 220; //Saving state interval



//ПРИМЕР:
//структура хранящая текущее состояние по одному торговому инструменту.
//нужна для загрузки/выгрузки в файл состояния stateFile
struct ExTemplateState
{
   ExTemplateState() {reset();}

   //примерные поля, для конкредной задачи используйте свой набор.
   string ticker;
   LIntList cur_tickets; 
   int pen_ticket;
   int max_step;
   double closed_lots; //подсчет общего объема всех закрытых поз за время работы советника
   double closed_pnl; //подсчет итогового результата всех закрытых поз за время работы советника
   
   
   void reset()
   {
      ticker = "?";
      cur_tickets.clear();
      pen_ticket = max_step = 0;
      closed_lots = closed_pnl = 0;      
   }
};
////////////////////////////////////
class ExTemplate : public LExTradeAbstract
{
public:
   ExTemplate() :LExTradeAbstract() {}
   
   
protected:
   
   virtual string name() const {return "template_name";} //имя советника
   
   virtual void work(); //выполнить сценарий алгоритма конкретной стратегии (основная функция)
   virtual void saveState(); //сохранить состояние советника
   virtual void loadState(); //загрузить состояние советника
   virtual void loadInputParams(); //загрузить входные параметры советника
    
};
void ExTemplate::work()
{
   Print("ExTemplate::work()");
}
void ExTemplate::saveState()
{

}
void ExTemplate::loadState()
{

}
void ExTemplate::loadInputParams()
{
   LExTradeAbstract::loadInputParams();
   if (invalid()) return;
   
   m_inputParams.insert(exipSaveInterval, U_SaveStateInterval);
   
}

////////////////////////////////////


// ex vars
ExTemplate *ex_obj = NULL;


//+------------------------------------------------------------------+
//| Expert global functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{   
   destroyObj();
   ex_obj = new ExTemplate();
   ex_obj.exInit();
   if (ex_obj.invalid())
   {
      Print("WARNING - Expert invalid state");   
      return INIT_FAILED;
   }
   
   Print("Expert started [SUCCESS]");   
   EventSetTimer(U_MainTimerInterval);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   if (ex_obj) ex_obj.exDeinit();
   destroyObj();
}
void OnTimer()
{
   if (ex_obj) ex_obj.mainExec();
}
//+------------------------------------------------------------------+


void destroyObj()
{
   if (ex_obj) {delete ex_obj; ex_obj = NULL;}   
}



