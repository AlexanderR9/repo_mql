//+------------------------------------------------------------------+
//|                                                      cfddivs.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include <mylib/lfile.mqh>
#include <mylib/lcontainer.mqh>
#include <mylib/lstring.mqh>
#include <mylib/ldatetime.mqh>



/////////DivStruct//////////
struct DivStruct
{
   DivStruct() {reset();}
   DivStruct(const DivStruct &data) {setData(data);}
   
   datetime ex_date;
   string ticker;
   double div_size;
   double div_present;
   
   void tryParse(string s, bool &ok)
   {
      ok = false;
      LStringList list;
      LStringWorker::split(s, " / ", list);
      if (list.count() != 4) return;
      
      int i = 0;
      ticker = list.at(i); 
      ticker = LStringWorker::trim(ticker);
      i++;
      
      ex_date = LDateTime::fromString(list.at(i), ok); 
      if (!ok) {Print("invalid parse ex_date: ", list.at(i)); return;}
      ok = false;
      i++;
      
      ResetLastError();
      div_size = StrToDouble(list.at(i));
      if (GetLastError() != 0) {Print("invalid parse div_size: ", list.at(i)); return;}
      i++;
      
      div_present = StrToDouble(list.at(i));
      if (GetLastError() != 0) {Print("invalid parse div_present: ", list.at(i)); return;}
      
      ok = true;
   }
   void setData(const DivStruct &data)
   {
      ex_date = data.ex_date;
      ticker = data.ticker;
      div_size = data.div_size;
      div_present = data.div_present;
   }
   void reset()
   {
      ticker = "";
      div_size = div_present = -1;
      ex_date = 0;
   }

};


/////////CFDDivsCompany//////////
class CFDDivsCompany
{
public:
   CFDDivsCompany(string v) :m_name(v) {}
   virtual ~CFDDivsCompany() {}
   
   void exec();
   
protected:
   string m_name;   

};
void CFDDivsCompany::exec()
{

}








/////////CFDDivsGame//////////
class CFDDivsGame
{
public:
   CFDDivsGame() :exec_index(-1), new_day(false) {}
   virtual ~CFDDivsGame() {clear();}
   
   inline int count() const {return ArraySize(m_objs);}
   inline bool isEmpty() const {return (count() == 0);}
   inline void resetDay() {new_day = true;}
   
   
   void addCompany(string);
   void exec();
   
   static string calendarFile() {return "cfd_divs/div_calendar.txt";}
   static string tmpFile() {return "cfd_divs/div_tmp.txt";}
   static void parseFileData(const LStringList &f_data, DivStruct &arr[]); //преобразовать данные из файла в массив DivStruct
   
protected:
   CFDDivsCompany* m_objs[]; //массив компаний
   int exec_index; //индекс тикера m_objs для выполнения сценария
   bool new_day; //признак того что начался новый рабочий день

   void clear(); //очистить контейнер m_objs
   void updateDivCalendarFile(); //ежедневный переброс актуальной информации из tmp файла в div_calendar.txt

};
void CFDDivsGame::exec()
{
   if (isEmpty()) return;
   
   if (new_day)
   {
      updateDivCalendarFile();
      new_day = false;
      return;
   }
   
   exec_index++;
   if (exec_index >= count()) exec_index = 0;
   
   m_objs[exec_index].exec();
}
void CFDDivsGame::addCompany(string v)
{
   int n = count();
   ArrayResize(m_objs, n+1);
   m_objs[n] = new CFDDivsCompany(v);;
}
void CFDDivsGame::clear()
{
   if (!isEmpty())
   {
      int n = count();
      for (int i=0; i<n; i++)
         delete m_objs[i];
   }
   ArrayFree(m_objs);
}
void CFDDivsGame::updateDivCalendarFile()
{
   LStringList tmp_data;
   string f_name = CFDDivsGame::tmpFile();
   if (LFile::readFileToStringList(f_name, tmp_data) < 0) 
   {
      Print("Invalid reading TMP file: ", f_name);
      return;
   }
   Print("Readed tmp data, size ", tmp_data.count());
   
   DivStruct tmp_arr[];
   CFDDivsGame::parseFileData(tmp_data, tmp_arr);
   if (ArraySize(tmp_arr) == 0)
   {
      Print("WARNING: parsed tmp file records list is empty");
      return;
   }
   
   

}
void CFDDivsGame::parseFileData(const LStringList &f_data, DivStruct &arr[])
{
   ArrayFree(arr);
   if (f_data.isEmpty()) return;
   
   bool ok;
   int n = f_data.count();
   for (int i=0; i<n; i++)
   {
      string s = f_data.at(i);
      s = LStringWorker::trim(s);
      if (s == "") continue;
      if (LStringWorker::left(s, 2) == "//") continue;
      
      DivStruct div;
      div.tryParse(s, ok);
      if (ok)
      {
         int arr_size = ArraySize(arr);
         ArrayResize(arr, arr_size + 1);
         arr[arr_size].setData(div);      
      }
   }
}


