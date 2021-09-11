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
struct LEmitDataElement
{
   LEmitDataElement() :dt(0), price(-1) {}
   LEmitDataElement(const datetime &t, const double &p) :dt(t), price(p) {}
   LEmitDataElement(const LEmitDataElement &el) :dt(el.dt), price(el.price) {}
   
   datetime dt;
   double price;
   
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
   
   inline int count() const {return m_size;}
   inline bool isEmpty() const {return (count() == 0);}
   inline bool invalid() const {return !m_validity;}
   
   void loadFile();
   void getRecordAt(int, LEmitDataElement&) const;
    
   static string historyDataDir() {return "fx_data";}
   
protected:
   string m_couple;
   LEmitDataElement m_history[]; //исторические данные
   bool m_validity; //становится true после успешной загрузки данных из файла
   int m_size;
   
   void tryReadFile(string f_name, string &arr[], string &err);
   void parseFileLine(const string&);
   void reset() {m_size = 0; m_validity = false;}
       
};
void LCoupleEmiter::getRecordAt(int i, LEmitDataElement &rec) const
{
   if (i<0 || i<=count()) return;
   rec.setData(m_history[i]);
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
   {
      //if (i < 5) Print(f_data[i]);
      parseFileLine(f_data[i]);
   }
      
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
   if (!ok) return;
   
   //int n = count();
   
   double price = StrToDouble(arr.at(1));
   if (m_size == ArraySize(m_history)) ArrayResize(m_history, m_size+1000);
   
   //ArrayResize(m_history, n+1);
   //if (n > 100) return;
   m_history[m_size].setData(dt, price);
   m_size++;
   
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
   LDataEmiter() {}
   virtual ~LDataEmiter() {destroyAll();}
   
   int count() const {return ArraySize(m_data);}
   bool isEmpty() const {return (count() == 0);}
   void addCouple(string);
   
protected:
   LCoupleEmiter*  m_data[];      
   
   void destroyAll();

};
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



