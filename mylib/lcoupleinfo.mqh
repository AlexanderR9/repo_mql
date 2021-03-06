//+------------------------------------------------------------------+
//|                                                         base.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include <mylib/lcontainer.mqh>

        
////////////MQMarketInfo///////////////////
class MQMarketInfo
{
public:
   //рыночные параметры по каждой паре
    MQMarketInfo() {reset();}
    MQMarketInfo(const MQMarketInfo &mi) {this = mi;}

   // сброс значений всех переменных
    void reset() {m_digist = -1; m_spread = -1; m_min_lot = 0; m_step_lot = 0; m_max_lot = 0; m_pprice_1lot=0; m_couple="";}
    
    // инициализация переменых (чтение рыночной информации)
    void init(const string &coup);
    
    // признак корректности значений переменных
    bool invalid() const {return (m_digist <= 0) || (m_spread < 0) || (m_min_lot <= 0) || (m_step_lot <= 0) || (m_max_lot <= 0) || StringLen(m_couple)!=6;}
    
    // коэффициент для перевода пунктов в цену
    double digFactor() const {return (double(1)/MathPow(10, m_digist));}	
    
   // приведение любого вещественного значения лота в допустимое 
    //double normalizeLot(double v) const;
    
    //перегрузка операции =
    void operator = (const MQMarketInfo&);
    
    //установить значание параметра в контейнере m_state
    void insertStateParam(int type, double value = -1) {m_state.insert(type, value);}
   
   // константные знаения инкапсулированных переменных 
    inline int digist() const {return m_digist;}  
    inline int spread() const {return m_spread;}  
    inline double minLot() const {return m_min_lot;}  
    inline double maxLot() const {return m_max_lot;}  
    inline double stepLot() const {return m_step_lot;}  
    inline double pprice1Lot() const {return m_pprice_1lot;}  
    inline string couple() const {return m_couple;}  
    inline const LMapIntDouble* state() const {return &m_state;}
    
    
protected:
    int m_digist; //точность
    int m_spread; // спред
    double m_min_lot; //минимальное значение лота
    double m_step_lot; //минимальный шаг лота
    double m_max_lot; // максимальное значение лота
    double m_pprice_1lot; // цена пункта (самого мизерного изменения цены в текущем терминале) в валюте счета при обьеме - 1 лот
    string m_couple; //имя пары
    
   LMapIntDouble m_state;   
      
};
void MQMarketInfo::operator = (const MQMarketInfo &mi) 
{
    m_digist = mi.digist();
    m_spread = mi.spread();
    m_min_lot = mi.minLot();
    m_max_lot = mi.maxLot();
    m_step_lot = mi.stepLot();
    m_pprice_1lot = mi.pprice1Lot();
    m_couple = mi.couple();
}
void MQMarketInfo::init(const string &coup)
{
   m_couple = coup;
   if (StringLen(m_couple) != 6) {reset(); return;}
   
   m_digist = (int)MarketInfo(m_couple, MODE_DIGITS);
   m_spread = (int)MarketInfo(m_couple, MODE_SPREAD);
   m_min_lot = MarketInfo(m_couple, MODE_MINLOT);
   m_step_lot = MarketInfo(m_couple, MODE_LOTSTEP);
   m_max_lot = MarketInfo(m_couple, MODE_MAXLOT);
   //m_pprice_1lot = MarketInfo(m_couple, MODE_TICKVALUE)/stepLot();
   m_pprice_1lot = MarketInfo(m_couple, MODE_TICKVALUE);
   
   Print("MQMarketInfo::init couple=" + m_couple + "  digist="+IntegerToString(m_digist) +"  spread="+IntegerToString(m_spread) +"  min_lot="+DoubleToString(m_min_lot, 4) +
   "  step_lot="+DoubleToString(m_step_lot, 4) +"  max_lot="+DoubleToString(m_max_lot, 4) +"  pprice_1lot="+DoubleToString(m_pprice_1lot, 4));
}
/*
double MQMarketInfo::normalizeLot(double v) const
{
   if (invalid()) return -1;
	if (v < m_min_lot) return m_min_lot;
	if (v > m_max_lot) return m_max_lot;
    
   int a = int(MathRound(m_step_lot*1000));
   int b = int(MathRound(v*1000));
   int c = b/a - 2;
   if (c < 0) c = 0;
    
   double res_lot = (m_min_lot + c*m_step_lot);
   while (res_lot < v) 
      res_lot += m_step_lot;
      
   return res_lot;
}
*/


// container for MQMarketInfo
class MQMarketInfoList
{
public:
   MQMarketInfoList() {clear();}
   virtual ~MQMarketInfoList() {clear();}

   void append(string);
   int count() const {return ArraySize(m_data);}
   void clear();   
   const MQMarketInfo* at(int) const;
   MQMarketInfo* atVar(int) const;
   bool contains(string) const;
   int indexOf(string) const;
   void removeAt(int);
   
protected:
   MQMarketInfo* m_data[];           // data array

};
const MQMarketInfo* MQMarketInfoList::at(int index) const
{
   if (index < 0 || index >= count()) return NULL;
   return m_data[index];
}
MQMarketInfo* MQMarketInfoList::atVar(int index) const
{
   if (index < 0 || index >= count()) return NULL;
   return m_data[index];
}
void MQMarketInfoList::removeAt(int index)
{
   if (index < 0 || index >= count()) return;
   
   int n = count();
   for (int i=index+1; i<n; i++)
      m_data[i-1] = m_data[i];
      
   ArrayResize(m_data, n-1);
}
int MQMarketInfoList::indexOf(string s) const
{
   int n = count();
   for (int i=0; i<n; i++)
      if (m_data[i].couple() == s) return i;
   return -1;
}
bool MQMarketInfoList::contains(string s) const
{
   int n = count();
   for (int i=0; i<n; i++)
      if (m_data[i].couple() == s) return true;
   return false;
}
void MQMarketInfoList::clear()
{
   int n = count();
   for (int i=0; i<n; i++)
      delete m_data[i];
   
   ArrayFree(m_data);
   ArrayResize(m_data, 0);
}
void MQMarketInfoList::append(string coup)
{
   int n = count();
   ArrayResize(m_data, n+1);
   m_data[n] = new MQMarketInfo();
   m_data[n].init(coup);
};



