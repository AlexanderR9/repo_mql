//+------------------------------------------------------------------+
//|                                                 lhistoryinfo.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/common/lvalidity.mqh>
#include <mylib/common/lstring.mqh>
#include <mylib/common/ldatetime.mqh>

//типы исторических событий
enum LHistoryOperationType {hotClosed = 201, hotCanceled, hotDeposit, hotRebate, hotDiv, hotRollover};

//данные по одной записи из истории
struct LHistoryEvent
{
      LHistoryEvent() {reset();}
      
      int type; //element of HistoryOperationType
      string couple;
      double swap;
      double commis;
      double profit;
      double lots;
      datetime time;
      string comment;
      

      bool isDiv() const {return (type == hotDiv);}
      bool isRebate() const {return (type == hotRebate);}
      bool isRollover() const {return (type == hotRollover);}
      bool isClosed() const {return (type == hotClosed);}
      bool isCanceled() const {return (type == hotCanceled);}
      bool isDeposit() const {return (type == hotDeposit);}
      
      bool invalid() const {return (type == 0);}
      string strTime() const {return LDateTime::dateTimeToString(time, ".", ":", false);}
      void reset()
      {
         type = 0;
         couple = "?";
         comment = "";
         swap = commis = profit = lots = 0;
         time = LDateTime::year20();
      }
      string toStr() const 
      {
         return StringConcatenate("HEvent: COUPLE(", couple, ")  ", strTime(), "  type=",LHistoryInfo::strEventType(type),
         "(",  type, ")  swap=", DoubleToStr(swap, 2), "  commis=", DoubleToStr(commis, 2), 
          "  profit=", DoubleToStr(profit, 2), "  lot=", DoubleToStr(lots, 2), "  coment=<", comment, ">");
      }
      void setData(const LHistoryEvent &rec)
      {
         type = rec.type;
         couple = rec.couple;
         comment = rec.comment;
         swap = rec.swap;
         commis = rec.commis;
         profit = rec.profit;
         lots = rec.lots;
         time = rec.time;      
      }
};


////class для получения информации о всех произошедших событиях находящихся в истории.
// и списку относящихся к ним инструментам
class LHistoryInfo
{
public:
   LHistoryInfo() {reset();}
   virtual ~LHistoryInfo() {reset();}
   
   void reloadHistory(const datetime&); //загрузить истрорию в контейнер m_data начиная с указанной даты
   
   inline int count() const {return ArraySize(m_data);}   //общее количество событий
   inline bool isEmpty() const {return (count() == 0);}
   inline void setMagic(int m) {m_magic = m;}
   void getRecAt(int, LHistoryEvent&) const;
   
   //выдать количество событий указанного типа
   int countByType(int) const;
   
   //выдать суммарный профит всех событий указанного типа
   double amountProfitByType(int) const;
   
   //выдать множество инструментов участвующих в загруженной истории.
   //если type > 0, то пары будут выбираться только из с записей с таким типом
   void getCoupleList(LStringList&, int type = -1); 
   
   static string strEventType(int);
   
protected:   
   datetime m_startDate;
   int m_magic; //если больше 0, то позы ищутся только с таким числом
   LHistoryEvent m_data[]; //контейнер с данными по истории

   void reset();
   void addRecord(); //position was selected success
   
private:
   void parseType(LHistoryEvent&);   

};

/////////////////////////////////////////////////////
void LHistoryInfo::reset() 
{
   ArrayFree(m_data);
   m_startDate = LDateTime::year20();
   m_magic = -1;
}
void LHistoryInfo::getCoupleList(LStringList &list, int type = -1)
{
   list.clear();
   if (isEmpty()) return;
   
   int size = count();
   for (int i=0; i<size; i++)
   {
      if (m_data[i].invalid()) continue; 
      if (type > 0 && m_data[i].type != type) continue;      
      string v = m_data[i].couple;
      if (StringLen(v) < 2) continue;
      if (!list.contains(v)) list.append(v);
   }               
}
double LHistoryInfo::amountProfitByType(int type) const
{
   double sum = 0;
   if (!isEmpty())
   {
      int size = count();
      for (int i=0; i<size; i++)
         if (m_data[i].type == type) 
            sum += m_data[i].profit;
   }
   return sum;
}
int LHistoryInfo::countByType(int type) const
{
   int n = 0;
   if (!isEmpty())
   {
      int size = count();
      for (int i=0; i<size; i++)
         if (m_data[i].type == type) n++;
   }
   return n;   
}
string LHistoryInfo::strEventType(int type)
{
   switch (type)
   {
      case hotClosed:      return "HClosed";
      case hotCanceled:    return "HCanceled";
      case hotDeposit:     return "HDeposit";
      case hotRebate:      return "HRebate";
      case hotDiv:         return "HDiv";
      case hotRollover:    return "HRollover";
      default: break;
   }
   return "HInvalid";
}
void LHistoryInfo::getRecAt(int i, LHistoryEvent &rec) const
{   
   rec.reset();
   
   if (i < 0 || i >= count()) return;
   rec.setData(m_data[i]);
}
void LHistoryInfo::reloadHistory(const datetime &dt)
{
   reset();
   m_startDate = dt;
   if (m_startDate < LDateTime::year20() || m_startDate >= TimeLocal())
   {
      Print("LHistoryInfo::loadHistory: WARNING invalid StartDate value: ", LDateTime::dateToString(m_startDate, "."));
      return;
   }
   
   int n = OrdersHistoryTotal();
   for (int i=0; i<n; i++)
   {
      if (OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if (OrderCloseTime() >= m_startDate)
            addRecord();
      }
      else Print("LHistoryInfo::loadHistory: WARNING can't selection history pos ", i);
   }
}
void LHistoryInfo::addRecord()
{
   if (m_magic > 0 && m_magic != OrderMagicNumber()) return;
   
   int n = count();
   ArrayResize(m_data, n+1);
   m_data[n].time = OrderCloseTime();
   m_data[n].couple = OrderSymbol();
   m_data[n].comment = OrderComment();
   m_data[n].commis = OrderCommission();
   m_data[n].swap = OrderSwap();
   m_data[n].profit = OrderProfit();
   m_data[n].lots = OrderLots();
   parseType(m_data[n]);      
   //Print(m_data[n].toStr());
}
void LHistoryInfo::parseType(LHistoryEvent &rec)
{
   string s = LStringWorker::trim(rec.comment);
   s = LStringWorker::toLower(s);
   
   if (LStringWorker::contains(s, "dividend"))
   {
      rec.type = hotDiv;
      int pos = LStringWorker::indexOf(s, "for");
      if (pos > 0)
      {
         s = LStringWorker::cutLeft(s, pos+1+3);
         rec.couple = LStringWorker::trim(s);
         rec.couple = LStringWorker::toUpper(rec.couple);
         rec.comment = "";
      }
      else rec.couple = "invalid";
   }
   else if (LStringWorker::contains(s, "rebate"))
   {
      rec.type = hotRebate;
      rec.couple = "";
      rec.comment = "";
   }
   else if (LStringWorker::contains(s, "rollover"))
   {
      rec.type = hotRollover;
      rec.couple = "";
      rec.comment = "";
   }
   else if (LStringWorker::contains(s, "cancelled"))
   {
      rec.type = hotCanceled;
      rec.comment = "";
   }
   else if (OrderType() == 6)
   {
      if (rec.profit >= 1000) rec.type = hotDeposit;
   }
   else rec.type = hotClosed;
   
}

