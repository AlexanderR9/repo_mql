//+------------------------------------------------------------------+
//|                                                 spreadlogger.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include <mylib/common/lstring.mqh>
#include <mylib/common/ldatetime.mqh>
#include <mylib/common/lfile.mqh>



//класс для периодической запись в файл logFileName() текущих значений спреда.
//спред мониторится для заданного списка пар m_couples.
//запись в файл происходит с интервалом m_interval секунд, 
//для этого необходимо вызывать функцию exec() не реже чем m_interval (чаще можно)
class LSpreadLogger
{
public:
   LSpreadLogger(string path) :m_path(LStringWorker::trim(path)), m_interval(300) {m_couples.clear();  last_save_time = TimeLocal();}
   virtual ~LSpreadLogger() {m_couples.clear();}
   
   void exec();
   void addCouple(string v);
   
   inline int count() const {return m_couples.count();}
   inline void setInterval(int t) {if (t > 10) m_interval = t;}

protected:
   string m_path;
   LStringList m_couples;
   int m_interval; //secs
   datetime last_save_time;
      
   void tryLog();
   string getData(const string) const;
   void checkLogFile(string &err);
   
private:
   inline string logFileName() const {return "spread_log.txt";}
   inline string fullFileFile() const {return StringConcatenate(m_path, "/", logFileName());}
   //inline bool invalid() const {return FileIsExist(fullFileFile());}
  
};
void LSpreadLogger::checkLogFile(string &err)
{
   err = "";
   string f_name = fullFileFile();
   if (LFile::isFileExists(f_name)) return;
   
   if (m_path == "") {err = "ERR: dir path is empty"; return;}
   if (!LFile::isDirExists(m_path))   {err = "ERR: dir path not found - "+m_path; return;} 
   
   if (!LFile::createFile(f_name))
      err = "ERR: can not create file - " + f_name;
}
void LSpreadLogger::tryLog()
{
   string err;
   checkLogFile(err);
   if (err != "") {Print("LSpreadLogger::tryLog() ", err); return;}
   
   LStringList data;
   data.append(LDateTime::currentDateTime(".", ":", true));
   int n = count();
   for (int i=0; i<n; i++)
      data.append(getData(m_couples.at(i)));
   data.append("");   
   
   if (!LFile::appendStringListToFile(fullFileFile(), data))
      Print("LSpreadLogger::tryLog() ERR: can't append data to file: ", fullFileFile(), "   GetLastError=", GetLastError());
      
}
string LSpreadLogger::getData(const string v) const
{
   string s = StringConcatenate(v, ":");
   s += StringConcatenate("   spread = ", DoubleToStr(MarketInfo(v, MODE_SPREAD), 0));
   return s;
}
void LSpreadLogger::addCouple(string v)
{
   v = LStringWorker::trim(v);
   if (!LStringWorker::isValidSymbol(v)) return;
   if (!m_couples.contains(v)) m_couples.append(v);
}
void LSpreadLogger::exec()
{
   datetime dt_cur = TimeLocal();
   int d_sec = LDateTime::dTime(last_save_time, dt_cur);
   if (d_sec > m_interval)
   {
      tryLog();
      last_save_time = dt_cur;   
   }
}


