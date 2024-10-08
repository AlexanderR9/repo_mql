//+------------------------------------------------------------------+
//|                                                 ltrailingobj.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict


#include <mylib/trade/lstatictrade.mqh>



//класс для отлеживания одной открытой позы (именно открытой) для подтягивания стопа по заданным условиям
//необходимо в конструкторе указать тикет отслеживаемой позы, 
//затем задать 1 из 2-х параметров размера отклонения от текущей цены, либо p_deviation либо m_pips
class LTrailingPos
{
public:
   LTrailingPos(int t) :m_ticket(t) {reset();}

   inline bool isOpen() const {return is_opened;}
   inline bool invalid() const {return ((m_ticket<=0) || (p_deviation<=0 && m_pips<=0));}
   inline bool isSell() const {return (m_sign < 0);}
   inline bool isBuy() const {return (m_sign > 0);}
   inline bool hasErr() const {return (m_err != "");}
   inline string err() const {return m_err;}
   inline int ticket() const {return m_ticket;}
   inline double openPrice() const {return m_openPrice;}
   inline double curPrice() const {return m_curPrice;}
   
   
   void updateState();   //обновить данные по текущему состоянию позы 
   void setDeviationPersent(double a) {p_deviation = a; m_pips = -1;} //установить размер отклонения в % которое нужно отслеживать
   void setDeviationPips(int a) {p_deviation = -1; m_pips = a;} //установить размер отклонения в пипсах инструмента которое нужно отслеживать
   bool needMoveSL() const; //признак того что стоп надо передвинуть/установить
   double nextSL() const; //выдает новое значение SL, куда нужно передвинуть стоп

protected:
   int m_ticket; //ордер за которым нужно следить и подтягивать SL
   double p_deviation; //отклонение от текущей цены, % (если > 0, то pips не важно)
   int m_pips; //отклонение от текущей цены в пипсах инструмента
   
   //extra vars
   double m_openPrice;
   double m_curPrice;
   int m_sign; //trade type (sell -1, buy 1)
   bool is_opened; 
   ushort m_digist;
   string m_err;
   
   void reset();
};
void LTrailingPos::reset()
{
   p_deviation = -1;
   m_pips = -1;
   m_openPrice = m_curPrice = 0;
   m_sign = 0;   
   is_opened = false;
   m_digist = 0;
   m_err= "";
}
double LTrailingPos::nextSL() const
{
   double d_price = 0;
   if (p_deviation > 0) d_price = m_curPrice*p_deviation/double(100);       
   else if (m_pips > 0) d_price = double(m_pips)/MathPow(10, m_digist);
   else return -1;
   
   double sl = m_curPrice - m_sign*d_price;   
   return NormalizeDouble(sl, m_digist);      
}
bool LTrailingPos::needMoveSL() const
{
   if (m_openPrice<=0 || m_curPrice<=0) return false;
   double d_price = m_sign*(m_curPrice - m_openPrice);
   if (d_price <= 0) return false;
   
   if (p_deviation > 0)
   {
      double need_dp = m_curPrice*p_deviation/double(100);   
      return (d_price > need_dp);
   }
   else if (m_pips > 0)
   {
      double need_dp = double(m_pips)/MathPow(10, m_digist);
      return (d_price > need_dp);      
   }
   return false;
}
void LTrailingPos::updateState()
{
   m_err = "";
   m_openPrice = m_curPrice = 0;
   LCheckOrderInfo info(m_ticket);
   LStaticTrade::checkOrderState(info);   
   if (info.isError())
   {         
      m_err = StringConcatenate("LTrailingPos: occured error(", info.err_code,") by checking pos, tiket=", m_ticket);
      return;
   }
   
   is_opened = info.isOpened();
   m_openPrice = info.open_price;
   m_sign = ((OrderType()==OP_BUY) ? 1 : -1);
   m_curPrice = MarketInfo(OrderSymbol(), isBuy() ? MODE_BID : MODE_ASK);
   
   if (m_digist == 0) 
      m_digist = ushort(MarketInfo(OrderSymbol(), MODE_DIGITS));
}


////////////////////////////////////////////////////
//класс предназначен для работы с открытыми позами.
//в процессе работы советника объекту добавляются записи c краткой инфой по открытой позиции функцией addTrackPos.
//если добавляемый тикет уже присутствует в контейнере m_posList, то он не добавится.
//В процесе работы советника с определенным интервалом у объекта нужно вызывать метод tryTrailing() (выставлять/подтягивать стопы).  
//позы которые перешли в историю автоматом удаляются из контейнера m_posList и более не отслеживаются.
////////////////////////////////////////////////
class LTrailingObj
{
public:
   LTrailingObj() {reset();}
   virtual ~LTrailingObj() {reset();}

   inline int count() const {return ArraySize(m_posList);} //количество отслеживаемых поз этим объектом
   inline bool isEmpty() const {return (count() == 0);}
   inline void setTrailMax(int a) {m_trailMax = ((a <= 0 || a > 10) ? -1 : a);}
   
   void tryTrailing(); //выполнять переодически по таймеру, пробегает по всем позам и при необходимости подтягивает стоп
   void addTrackPos(int, double, bool is_pips_dev = false); //добавить позицию для отслеживания   
   bool posContains(int) const; //признак того что поза с указанным тикетом уже присутствует в m_posList 
    
protected:
   LTrailingPos* m_posList[];
   int m_trailMax; //максимально количество передвигания стопов (модифицируемых поз) за один раз

   void reset();
   void removePosAt(int); //remove element by index from m_posList
   void tryMoveSL(int); //передвинуть/выставить стоп для указанного элемента m_posList

};
void LTrailingObj::reset()
{
   m_trailMax = -1;
   if (isEmpty()) return;
   
   int n = count();
   for (int i=0; i<n; i++) 
   {
      delete m_posList[i];
      m_posList[i] = NULL;
   }   
   ArrayFree(m_posList);
}
bool LTrailingObj::posContains(int t) const
{
   if (!isEmpty())
   {
      int n = count();
      for (int i=0; i<n; i++) 
       if (m_posList[i].ticket() == t) return true;   
   }   
   return false;
}
void LTrailingObj::addTrackPos(int t, double dev_size, bool is_pips_dev)
{
   if (t <= 0 || dev_size <= 0) return;
   if (posContains(t)) {Print("LTrailingObj: WARNING pos ticket=",t," already tracking for trailing"); return;}
   
   int next_n = count()+1;
   ArrayResize(m_posList, next_n);
   m_posList[next_n-1] = new LTrailingPos(t);
   if (is_pips_dev) m_posList[next_n-1].setDeviationPips(int(dev_size));
   else m_posList[next_n-1].setDeviationPersent(dev_size);   
}
void LTrailingObj::tryTrailing()
{
   if (isEmpty()) return;
      
   ushort n_trail = 0;      
   int n = count();
   for (int i=0; i<n; i++)
   {
      m_posList[i].updateState();      
      if (m_posList[i].hasErr()) {Print(m_posList[i].err()); continue;}
      
      if (!m_posList[i].isOpen())
      {
         Print("ticket ", m_posList[i].ticket(), " is not opened, need remove from container");
         removePosAt(i);
         return;
      }
      
      if (m_posList[i].needMoveSL()) {tryMoveSL(i); n_trail++;}
      if (m_trailMax > 0 && n_trail >= m_trailMax) break;                           
   }   
}
void LTrailingObj::tryMoveSL(int i)
{
   int t = m_posList[i].ticket();
   LOrderModifyParams p(t, 0);
   p.sl_value = m_posList[i].nextSL();
   Print("try set sl/tp pos: ", t, "cur_price=", DoubleToStr(m_posList[i].curPrice(), 5));   
   Print(p.toStr());
   if (p.isError()) Print("GetLastError=", GetLastError());   
}
void LTrailingObj::removePosAt(int i)
{
   if (isEmpty()) return;
   if (i<0 || i>=count()) return;
   
   int next_n = count()-1;
   while (2>1)
   {
      if (i == next_n) break;
      m_posList[i] = m_posList[i+1];
      i++;
   }
   
   delete m_posList[next_n];
   m_posList[next_n] = NULL;
   ArrayResize(m_posList, next_n);
}


