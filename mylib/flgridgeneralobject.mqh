//+------------------------------------------------------------------+
//|                                          flgridgeneralstruct.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/lcontainer.mqh>

//структура для хранения итоговых разультатов по одному инструменту
struct FLGridCoupleGeneralState
{
   FLGridCoupleGeneralState() {reset();}
   FLGridCoupleGeneralState(const FLGridCoupleGeneralState &rec) {setData(rec);}
   
   string couple;
   int ex_count;
   double current_pl;
   double total_lot;
   double closed_profit;
   
   void reset() {couple = ""; ex_count = 0; current_pl = total_lot = closed_profit = 0;}
   inline bool invalid() const {return (couple == "");}
   void setData(const FLGridCoupleGeneralState &rec)
   {
      couple = rec.couple;
      ex_count = rec.ex_count;
      current_pl = rec.current_pl;
      total_lot = rec.total_lot;
      closed_profit = rec.closed_profit;
   }
   
   string toStr() const
   {
      string s = StringConcatenate("GENERAL STATE: ", couple, "  [");
      s += StringConcatenate("ex_count=", ex_count, "  current_pl=", current_pl, "  total_lot=", total_lot, "  closed_profit=", closed_profit,"]");
      return s;
   }
   
   
};
/////////////////////////////////////
struct FLGridLossStat
{
   FLGridLossStat() {reset();}

   string couple;
   long chart_id;
   double loss; //убыток всех хеджированных сеток этого советника
   
   double current_pl; //текущий суммарный результат всех ордеров последней открытой сетки вместе со свопом и коммисией (если она в работе)
   
   void reset() {couple=""; chart_id=-1; loss=0; current_pl=0;}
   void setData(const FLGridLossStat &rec)
   {
      couple = rec.couple;
      chart_id = rec.chart_id;
      loss = rec.loss;
      current_pl = rec.current_pl;
   }
   
   string toStr() const
   {
      string s = StringConcatenate("LOSS STAT DATA: ", couple, "  [");
      s += StringConcatenate("chart_id=", chart_id, "  hedge_loss=", loss, "  current_pl=", current_pl, "]");
      return s;
   }
};

/////////////////////////////////////
class FLGridGeneral
{
public:
   FLGridGeneral() {reset();}
   
   inline int recordsCount() const {return ArraySize(m_data);}
   inline bool isEmpty() const {return (recordsCount() == 0);}

   
   void expertStarted(string key);   
   void expertDestroyed(string key, long chart_id);   
   void expertOpenedPos(string key, double lot_size);
   void expertGetedProfit(string key, double profit_size, long chart_id);
   void expertHedgeGrid(string key, double loss_size, long chart_id);
   void expertCurPLOpenedGrid(string key, double pl_size, long chart_id);
   
   string coupleAt(int) const; //возвращает поле couple записи с указанным индексом
   void getRecord(int, FLGridCoupleGeneralState&);
   int exCountByCouple(string) const; //возвращает поле ex_count найденой записи или 0
   int findByCouple(string) const; //возвращает индекс записи в m_data или -1
   double freeProfitSize() const; //возвращает весь свободный профит на текущий момент  
   
   //prepare cmd funcs
   int findCurrentLossOver(double max) const; //найти запись c убытком превышающим max
   void findChartForRepaing(string v, long &chart_id, double &loss); //найти chart_id  по v где наибольший убыток, (размер убытка записать в loss)
   double profitByLoss(double loss) const; //вернуть максимально допустимый размер профита для погашения долга loss 
   void repayDone(long chart_id, double sum); //обновить данные после погашения долга на сумму sum  
   void repayOpenedDone(double sum); //обновить данные после погашения долга открытой сетки на сумму sum  
   void findChartForRepaingOpenedGrid(string v, long &chart_id, double &loss); //найти chart_id  по v где наибольший убыток по открытой сетке, (размер убытка записать в loss)
   
   //void findDataForLastRepay(long &chart_id, double &last_profit, double &loss); //найти данные для погашения какой-либо сетки стандартным методом, т.е. своим же профитом
   //void repayStandardDone(long chart_id, double sum); //обновить данные после стандартного погашения сетки своего же долга на сумму sum  
   
   
   static bool existsTerminalSymbol(string v);
   void outLossStat();
   void outData();


protected:
   FLGridCoupleGeneralState m_data[]; //собранная стата по всем работающим инструментам
   FLGridLossStat m_lossStat[]; //собранная стата по всем графикам где запущены советники на предмет захеджированыых лосей
   
   //long last_profit_chart_id; //chart_id советника, от которого пришел последний профит
   //double last_profit_size; //размер последнего полученного профита
   
   
   //текущий размер профитов по разным инструмента, который надо раскидать на погашение захеджированных сеток
   //key - couple, value - profit
   //LMapStringDouble getted_profits; 
   inline int lossStatCount() const {return ArraySize(m_lossStat);}

   
   void reset() {clearData(); /*resetLastProfit();*/}
   //void resetLastProfit() {last_profit_chart_id = -1; last_profit_size = 0;}
   void addCouple(string s);
   bool coupleContains(string v) const;
   void removeAt(int);
   void removeLossStatByChartID(long);
   void clearData() {ArrayFree(m_data);}
   void clearLossStat() {ArrayFree(m_lossStat);}
   void incrementExCount(string); //увеличить счетчик ex_count на единицу
   void decrementExCount(string); //уменьшить счетчик ex_count на единицу
   void addLossStatRecord(string s, long chart_id); //добавить новую запись в m_lossStat
   int findLossStatByID(long) const; //возвращает индекс записи в m_lossStat или -1
   void updateCoupleCurrentPL(string couple); //обновить значение current_pl для указанной пары


};
//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
void FLGridGeneral::outLossStat()
{
   int n = lossStatCount();
   Print("---------Loss stat info count=", n, "------------------");
   if (n==0) return;
   
   for (int i=0; i<n; i++)
      Print(m_lossStat[i].toStr());
}
void FLGridGeneral::outData()
{
   int n = recordsCount();
   Print("---------General data info count=", n, "------------------");
   if (n==0) return;
   
   for (int i=0; i<n; i++)
      Print(m_data[i].toStr());

}
void FLGridGeneral::expertStarted(string key)
{
   if (!existsTerminalSymbol(key)) return;
   if (coupleContains(key)) incrementExCount(key);
   else addCouple(key);
}
void FLGridGeneral::expertDestroyed(string key, long chart_id)
{
   if (!coupleContains(key)) return;
   removeLossStatByChartID(chart_id);
   int n = exCountByCouple(key);
   if (n > 1) decrementExCount(key);
   else removeAt(findByCouple(key));
}
void FLGridGeneral::expertGetedProfit(string key, double profit_size, long chart_id)
{
   Print("FLGridGeneral::expertGetedProfit key=", key, "  profit_size=", profit_size);
   if (profit_size < 0) 
   {
      repayOpenedDone(MathAbs(profit_size));
      return;
   }
   
   
   int pos = findByCouple(key);
   if (pos >= 0) m_data[pos].closed_profit += profit_size;
   Print("total profit now: ", freeProfitSize());
   
   //last_profit_chart_id = chart_id;
   //last_profit_size = profit_size;
}
void FLGridGeneral::expertOpenedPos(string key, double lot_size)
{
   int pos = findByCouple(key);
   if (pos >= 0) m_data[pos].total_lot += lot_size;
}
void FLGridGeneral::updateCoupleCurrentPL(string couple)
{
   int pos = findByCouple(couple);
   if (pos < 0) return;
   
   m_data[pos].current_pl = 0;

   int n = lossStatCount();
   if (n == 0) return;
   for (int i=0; i<n; i++)
   {
      if (m_lossStat[i].couple == couple)
      {
         m_data[pos].current_pl += m_lossStat[i].loss;
         m_data[pos].current_pl += m_lossStat[i].current_pl;
      }
   }
}
void FLGridGeneral::expertCurPLOpenedGrid(string key, double pl_size, long chart_id)
{
   //Print("FLGridGeneral::expertCurPLOpenedGrid key=", key, "  pl_size=", pl_size);
   int pos = findLossStatByID(chart_id);
   if (pos < 0)
   {
      addLossStatRecord(key, chart_id);
      pos = findLossStatByID(chart_id);
   }
   
   if (pos >= 0)
      m_lossStat[pos].current_pl = pl_size;
      
   updateCoupleCurrentPL(key);   
}
void FLGridGeneral::expertHedgeGrid(string key, double loss_size, long chart_id)
{
   //int pos = findByCouple(key);
   //if (pos >= 0) m_data[pos].current_pl += loss_size;   
   
   //////////////////////////////////////////
   int pos = findLossStatByID(chart_id);
   if (pos < 0)
   {
      addLossStatRecord(key, chart_id);
      pos = findLossStatByID(chart_id);
   }
   
   if (pos >= 0) 
      m_lossStat[pos].loss += loss_size;

   updateCoupleCurrentPL(key);   
}
int FLGridGeneral::findLossStatByID(long chart_id) const
{
   int n = lossStatCount();
   if (n == 0) return -1;
   for (int i=0; i<n; i++)
      if (m_lossStat[i].chart_id == chart_id) return i;
   return -1;
}
int FLGridGeneral::findByCouple(string v) const
{
   if (isEmpty()) return -1;
   int n = recordsCount();
   for (int i=0; i<n; i++)
      if (m_data[i].couple == v) return i;
   return -1;
}
double FLGridGeneral::freeProfitSize() const
{
   if (isEmpty()) return 0;
   
   double sum = 0; 
   int n = recordsCount();
   for (int i=0; i<n; i++) 
      sum += m_data[i].closed_profit;
   return sum;   
}
/*
void FLGridGeneral::repayStandardDone(long chart_id, double sum)
{
   //resetLastProfit();

   int pos = findLossStatByID(chart_id);
   if (pos >= 0) 
   {
      m_lossStat[pos].loss += sum;
      pos = findByCouple(m_lossStat[pos].couple);
      if (pos >= 0)
      {
         m_data[pos].current_pl += sum;
         m_data[pos].closed_profit -= sum;
      }
   }
}
*/
void FLGridGeneral::repayOpenedDone(double sum)
{
   Print("FLGridGeneral::repayOpenedDone sum=", sum);
   
   if (isEmpty()) return;
   int n = recordsCount();   
   
   double profit1 = freeProfitSize();
   
   for (int i=0; i<n; i++)
   {
      if (m_data[i].closed_profit > sum) 
      {
         m_data[i].closed_profit -= sum;
         sum = 0;
         break;
      }
      else
      {
         sum -= m_data[i].closed_profit;
         m_data[i].closed_profit = 0;
         if (MathAbs(sum) < 0.01) {sum = 0; break;}
      }
   }
   
   double profit2 = freeProfitSize();
   Print("total profit before/after = ", profit1, "/", profit2);

}
void FLGridGeneral::repayDone(long chart_id, double sum)
{
   //resetLastProfit();
   
   int pos = findLossStatByID(chart_id);
   if (pos >= 0) 
   {
      m_lossStat[pos].loss += sum;
      pos = findByCouple(m_lossStat[pos].couple);
      if (pos >= 0) m_data[pos].current_pl += sum;
   }
   
   if (isEmpty()) return;
   int n = recordsCount();   
   
   while (sum > 0)
   {
      double max = 0;
      pos = 0;
      for (int i=0; i<n; i++)
      {
         if (m_data[i].closed_profit > max)
         {
            max = m_data[i].closed_profit;
            pos = i;
         }
      } 
      
      if (m_data[pos].closed_profit > sum) 
      {
         m_data[pos].closed_profit -= sum;
         sum = 0;
      }
      else
      {
         sum -= m_data[pos].closed_profit;
         m_data[pos].closed_profit = 0;
         if (MathAbs(sum) < 0.01) sum = 0;
      }
   }
}
double FLGridGeneral::profitByLoss(double loss) const
{
   double x = MathAbs(loss);
   double p_free = freeProfitSize();
   return ((x > p_free) ? p_free : x);
}
/*
void FLGridGeneral::findDataForLastRepay(long &chart_id, double &last_profit, double &loss)
{
   loss = 0;
   chart_id = last_profit_chart_id;
   last_profit = last_profit_size;
   if (chart_id <= 0) return;
   
   int pos = findLossStatByID(chart_id);
   if (pos < 0) return;
   
   loss = m_lossStat[pos].loss;
}
*/
int FLGridGeneral::findCurrentLossOver(double max) const
{
   if (isEmpty()) return -1;
   int n = recordsCount();
   int pos = -1;
   
   double max_loss = 0;
   for (int i=0; i<n; i++)
   {
      if (m_data[i].current_pl >= 0) continue;
      double x = MathAbs(m_data[i].current_pl);
      if (x > MathAbs(max))
      {
         if (x > max_loss)
         {
            max_loss = x;
            pos = i;
         }
      }
   }
   return pos;
}
void FLGridGeneral::findChartForRepaing(string v, long &chart_id, double &loss)
{
   chart_id = -1;
   loss = 0;

   int n = lossStatCount();
   if (n == 0) return;
   
   double max_loss = 0;
   for (int i=0; i<n; i++)
   {
      if (m_lossStat[i].couple != v) continue;
      
      double x = MathAbs(m_lossStat[i].loss);
      if (x > max_loss)
      {
         max_loss = x;
         chart_id = m_lossStat[i].chart_id;
      }
   }

   loss = max_loss*(-1);
}
void FLGridGeneral::findChartForRepaingOpenedGrid(string v, long &chart_id, double &loss)
{
   chart_id = -1;
   loss = 0;

   int n = lossStatCount();
   if (n == 0) return;
   
   double max_loss = 0;
   for (int i=0; i<n; i++)
   {
      if (m_lossStat[i].couple != v) continue;
      if (m_lossStat[i].current_pl >= 0) continue;
      
      double x = MathAbs(m_lossStat[i].current_pl);
      if (x > max_loss)
      {
         max_loss = x;
         chart_id = m_lossStat[i].chart_id;
      }
   }

   loss = max_loss*(-1);
}
int FLGridGeneral::exCountByCouple(string v) const
{
   if (isEmpty()) return 0;
   int n = recordsCount();
   for (int i=0; i<n; i++)
      if (m_data[i].couple == v) return m_data[i].ex_count;
   return 0;
}
void FLGridGeneral::getRecord(int i, FLGridCoupleGeneralState &rec)
{
   if (i<0 || i>=recordsCount()) return;
   rec.setData(m_data[i]);
}
void FLGridGeneral::addCouple(string s)
{
   int n = recordsCount();
   ArrayResize(m_data, n+1);
   m_data[n].couple = s;
   m_data[n].ex_count = 1;
}
void FLGridGeneral::addLossStatRecord(string s, long chart_id)
{
   int n = lossStatCount();
   ArrayResize(m_lossStat, n+1);
   m_lossStat[n].couple = s;
   m_lossStat[n].chart_id = chart_id;
}
void FLGridGeneral::removeLossStatByChartID(long chart_id)
{
   int index = findLossStatByID(chart_id);
   if (index < 0) return;

   int n = lossStatCount();
   for (int i=index+1; i<n; i++)
      m_lossStat[i-1].setData(m_lossStat[i]);
   ArrayResize(m_lossStat, n-1);
}
void FLGridGeneral::removeAt(int index)
{
   int n = recordsCount();
   if (index < 0 || index >= n) return;
   
   for (int i=index+1; i<n; i++)
      m_data[i-1].setData(m_data[i]);
      
   ArrayResize(m_data, n-1);
}
string FLGridGeneral::coupleAt(int i) const
{
   if (i < 0 || i >= recordsCount()) return "???";
   return m_data[i].couple;
}
bool FLGridGeneral::existsTerminalSymbol(string v)
{
   if (v == "") return false;
   string result = SymbolInfoString(v, SYMBOL_CURRENCY_BASE);   
   return (StringLen(result) > 0);
}
bool FLGridGeneral::coupleContains(string v) const
{
   if (isEmpty()) return false;
   
   int n = recordsCount();
   for (int i=0; i<n; i++)
      if (m_data[i].couple == v) return true;
   return false;      
}
void FLGridGeneral::incrementExCount(string v)
{
   int pos = findByCouple(v);
   if (pos >= 0) m_data[pos].ex_count++;
}
void FLGridGeneral::decrementExCount(string v)
{
   int pos = findByCouple(v);
   if (pos >= 0) m_data[pos].ex_count--;
}

