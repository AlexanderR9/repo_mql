//+------------------------------------------------------------------+
//|                                        ltradeintervalchecker.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <mylib/ldatetime.mqh>


//класс для задание временного интервала работы советника (когда он может торговать)
//а так же слежение за переходом на новый день
class LTradeIntervalChecker
{
public:
   LTradeIntervalChecker() {reset();}
   
   //инициализация интервала выполняется одной из 2-х следующих функций
   void init(const datetime&, const datetime&); //инициализация объекта временным интервалом
   void init(string, string); //инициализация объекта временным интервалом (в строковом виде)
   
   //проверить текущий момент времени на наступление нового дня, в этом случае обновить переменные dt_begin и dt_end.
   //данную функцию необходимо периодически выполнять
   void checkUpdateDateDay(); 
   
   //возвращает true если в текущий момент можно торговать
   bool isTradingTime() const;
   
   //выхлоп значений dt_begin и dt_end (для отладки)
   string toStr() const;
   
   //вернет true если объект не был инициализирован или инициализирован некорректными значениями
   bool invalid() const; 
   
   inline string err() const {return m_err;}
   
protected:
   datetime dt_begin;
   datetime dt_end;
   string m_err; //если все ок, то значение переменной всегда пустая строка

   void reset(); //сброс состояния
   void checkValidity(); //проверка заданных значений dt_begin и dt_end

};
///////////////////////////////////////
void LTradeIntervalChecker::reset()
{
   dt_begin = dt_end = 0;
   m_err = "LTradeIntervalChecker ERROR: not initializate object";
}
bool LTradeIntervalChecker::isTradingTime() const
{
   if (LDateTime::isHolidayNow()) return false;
   datetime dt = TimeLocal();
   return ((dt >= dt_begin) && (dt < dt_end));
}
void LTradeIntervalChecker::checkUpdateDateDay()
{
   if (invalid()) return;

   MqlDateTime dt_struct_local;
   TimeToStruct(TimeLocal(), dt_struct_local);
   MqlDateTime dt_struct;
   TimeToStruct(dt_begin, dt_struct);
   
   if (dt_struct.day != dt_struct_local.day)
   {
      LDateTime::addDays(dt_begin, 1);
      LDateTime::addDays(dt_end, 1);
      
      string text;
      StringConcatenate(text, "BeginTime=", LDateTime::dateTimeToString(dt_begin, ".", ":", false), 
         " EndTime=", LDateTime::dateTimeToString(dt_end, ".", ":", false));
      Print("LTradeIntervalChecker - Date day updated: ", text);
   }
}
bool LTradeIntervalChecker::invalid() const
{
   return (dt_begin <= 0 || dt_end <= 0 || dt_begin >= dt_end);
}
void LTradeIntervalChecker::checkValidity()
{
   m_err = "";
   if (invalid())
   {
      m_err = "LTradeIntervalChecker ERROR: invalid interval values";
      StringAdd(m_err, ("   time_begin="+LDateTime::dateTimeToString(dt_begin, ".", ":", false)));
      StringAdd(m_err, ("   time_end="+LDateTime::dateTimeToString(dt_end, ".", ":", false)));
   }
}
void LTradeIntervalChecker::init(const datetime &dt1, const datetime &dt2)
{
   dt_begin = dt1;
   dt_end = dt2;
   checkValidity();
}
void LTradeIntervalChecker::init(string s_dt1, string s_dt2)
{
   m_err = "";
   
   bool ok;
   dt_begin = LDateTime::fromString(s_dt1, ok);
   if (!ok)
   {
      StringConcatenate(m_err, "LTradeIntervalChecker ERROR: invalid value BeginTime=", s_dt1);
      dt_end = 0;
      return;
   }


   dt_end = LDateTime::fromString(s_dt2, ok);
   if (!ok)
   {
      StringConcatenate(m_err, "LTradeIntervalChecker ERROR: invalid value EndTime=", s_dt2);
      dt_begin = 0;
      return;
   }
   
   checkValidity();
}
string LTradeIntervalChecker::toStr() const
{
      string s = "time interval: ";
      s += ("dt_begin="+LDateTime::dateTimeToString(dt_begin, ".", ":", false)+"  ");
      s += ("dt_end="+LDateTime::dateTimeToString(dt_end, ".", ":", false)+"  ");
      return s;
}




