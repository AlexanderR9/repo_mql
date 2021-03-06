//+------------------------------------------------------------------+
//|                                                   lextremums.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


#include <fllib/lcontainer.mqh>
#include <fllib/lextremums.mqh>


//+------------------------------------------------------------------+

//класс для поиска экстремумов цены
class IPriceExtremums
{
public:
   IPriceExtremums(string couple) :m_couple(couple) {reset();}
   virtual ~IPriceExtremums() {reset();}
   
   void updateBuffer(int n);
   void recalcDivergenceHighPoints(double &[]);
   void recalcDivergenceLowPoints(double &[]);
   
   void updateExtremumsPoints(); //пересчитать экстремумы и обновить контейнеры m_highPoints и m_lowPoints
   
   int highAt(int) const; 
   int lowAt(int) const;

   void setDiapazon(int, int);
//   void checkExtremum(int i); //проверка что i-й бар является экстремумом (low или high)

   
   inline bool buffEmpty() const {return (buffSize() == 0);}
   inline void setIndicatorHandle(int h) {m_handle = h;}
   inline int highCount() const {return m_highPoints.count();}
   inline int lowCount() const {return m_lowPoints.count();}
   inline int count() const {return (highCount() + lowCount());}
   double buffValue(int i) const; //i-е значение индикатора m_handle

   static double invalidValue() {return -11;}

protected:
   string m_couple;
   LIntList m_highPoints;  //индексы свечей на против которых расположены максимумы
   LIntList m_lowPoints;   //индексы свечей на против которых расположены минимумы
   int m_handle;           //дескриптор индикатора
   double m_buffer[];      //массив значений индикатора (постоянно должен обновляться)
   int b_left;
   int b_right;
   
   void reset();
   int buffSize() const {return ArraySize(m_buffer);}
   void findRangeForSearchExstremum(int i, int &start_pos, int &n) const; //определение диапазона свечей для поиска экстремума
   void addHighIndex(int i);
   void addLowIndex(int i);
   bool isDivergenceLow(int) const;
   bool isDivergenceHigh(int) const;
   void recalcDivergenceSegment(int i_first, int i_last, double &[], string type = "high");
   
private:
   bool isExstremumLow(int i) const;
   bool isExstremumHigh(int i) const;
   
   
};
void IPriceExtremums::reset()
{
   m_handle = -1;
   m_highPoints.clear();
   m_lowPoints.clear();
   b_left = b_right = 5;
}
void IPriceExtremums::updateExtremumsPoints()
{
   m_highPoints.clear();
   m_lowPoints.clear();
   if (buffEmpty()) return;
   
   int n = buffSize();
   int i = n - 1;
   while (i >= 0)
   {
      if (i < 0) Print("err i = ", i);
      if (i > 11000) Print("err i = ", i);
      
      //if (i < 50 && b_left == 2) Print("updateExtremumsPoints: i = ", i);
      
      if (isExstremumHigh(i)) addHighIndex(i);
      else if (isExstremumLow(i)) addLowIndex(i);
      i--;
   }
   
   
   /*
   if (b_left != 2) return;
   Print("updateExtremumsPoints: high_point ", lowCount());
   int m = 4;
   int j = lowCount() - m/2;
   for (i=0; i<m; i++)
      if (i<m/2) Print("i=", i, "  pos=", lowAt(i));
      else 
      {
         Print("i=", j, "  pos=", lowAt(j));
         j++;
      }
      */
}
void IPriceExtremums::recalcDivergenceHighPoints(double &arr[])
{
   int n_extremums = highCount() - 1;
   int pos = 0;
   while (pos < n_extremums)
   {
      if (isDivergenceHigh(pos)) //в промежутке свечей от pos до pos+1 обнаружена дивиргенция
      {
         int i_first = highAt(pos);
         int i_last = highAt(pos+1);
         recalcDivergenceSegment(i_first, i_last, arr, "high");
      }
      pos++;
   }
}
void IPriceExtremums::recalcDivergenceLowPoints(double &arr[])
{
   int n_extremums = lowCount() - 1;
   int pos = 0;
   while (pos < n_extremums)
   {
      if (isDivergenceLow(pos)) 
      {
         int i_first = lowAt(pos);
         int i_last = lowAt(pos+1);
         recalcDivergenceSegment(i_first, i_last, arr, "low");
      }
      pos++;
   }
}
void IPriceExtremums::recalcDivergenceSegment(int i_first, int i_last, double &arr[], string type)
{
      if (i_first < 0 || i_first >= i_last) 
      {
         Print("IExtremums::recalcDivergenceSegment ERR  pos_first=", i_first,"  pos_last=", i_last, "  type: ", type); 
         return;
      }

      LDoubleList list;
      if (type == "high") FLDivCalc::calcLineHighPoints(i_first, i_last, list);
      else if (type == "low") FLDivCalc::calcLineLowPoints(i_first, i_last, list);
      else
      {  
         Print("IExtremums::recalcDivergenceSegment ERR  invalid type: ", type); 
         return;
      }
      
      FLDivCalc::updateBuffSegment(arr, i_first, list);
}
void IPriceExtremums::setDiapazon(int lb, int rb)
{
   if (lb > 0 && lb < 50)  b_left = lb;
   if (rb > 0 && rb < 50)  b_right = rb;
}
bool IPriceExtremums::isDivergenceLow(int low_index) const
{
   if (low_index < 0 && low_index+1 < lowCount()) return false;
   
   int pos1 = lowAt(low_index);
   int pos2 = lowAt(low_index+1);
   bool b1 = (buffValue(pos1) > buffValue(pos2));
   bool b2 = iLow(m_couple, PERIOD_CURRENT, pos1) > iLow(m_couple, PERIOD_CURRENT, pos2);
   return (b1 != b2);
}
bool IPriceExtremums::isDivergenceHigh(int high_index) const
{
   if (high_index < 0 && high_index+1 < highCount()) return false;
   
   int pos1 = highAt(high_index);
   int pos2 = highAt(high_index+1);
   bool b1 = (buffValue(pos1) > buffValue(pos2));
   bool b2 = iHigh(m_couple, PERIOD_CURRENT, pos1) > iHigh(m_couple, PERIOD_CURRENT, pos2);
   return (b1 != b2);
}
double IPriceExtremums::buffValue(int i) const
{
   if (i < 0 || i >= buffSize()) return invalidValue();
   return m_buffer[i];
}
int IPriceExtremums::highAt(int i) const
{
   if (i < 0 || i >= highCount()) return -1;
   return m_highPoints.at(i);
}
int IPriceExtremums::lowAt(int i) const
{
   if (i < 0 || i >= lowCount()) return -1;
   return m_lowPoints.at(i);
}
void IPriceExtremums::updateBuffer(int n)
{
   //Print("updateBuffer  m_handle=", m_handle, "  n=", n);
   if (m_handle < 0 || n < 1) return;
   if (n > 1000) n = 1000;
   
   //--- заполнение массива m_buffer[] текущими значениями индикатора m_handle
   CopyBuffer(m_handle, 0, 0, n, m_buffer);
   
   //--- задаём порядок индексации массива m_buffer[] как в MQL4
   ArraySetAsSeries(m_buffer, true);    
}
void IPriceExtremums::addHighIndex(int i_high)
{
   //if (i_high < 20) Print("addHighIndex ", i_high);
   if (m_highPoints.isEmpty()) {m_highPoints.append(i_high); return;}
   if (m_highPoints.contains(i_high)) return;
   
   if (i_high == 0)
   {
      if (m_highPoints.first() == 1)  m_highPoints.replace(0, i_high);
      else m_highPoints.insert(0, i_high);
      return;
   }
   
   bool added = false;
   int n = m_highPoints.count();
   for (int i=0; i<n; i++)
   {
      if (m_highPoints.at(i) > i_high)
      {
         m_highPoints.insert(i, i_high);
         added = true;
         break;
      }
   }
   if (!added) m_highPoints.append(i_high);
}
void IPriceExtremums::addLowIndex(int i_low)
{
   //if (i_low < 20) Print("addLowIndex ", i_low);
   if (m_lowPoints.isEmpty()) {m_lowPoints.append(i_low); return;}
   if (m_lowPoints.contains(i_low)) return;
   
   if (i_low == 0)
   {
      if (m_lowPoints.first() == 1)  m_lowPoints.replace(0, i_low);
      else m_lowPoints.insert(0, i_low);
      return;
   }
   
   bool added = false;
   int n = m_lowPoints.count();
   for (int i=0; i<n; i++)
   {
      if (m_lowPoints.at(i) > i_low)
      {
         m_lowPoints.insert(i, i_low);
         added = true;
         break;
      }
   }
   if (!added) m_lowPoints.append(i_low);
}
void IPriceExtremums::findRangeForSearchExstremum(int i, int &start_pos, int &n) const
{
   //start_pos - правая позиция на графике
   //n - смещение влево
   start_pos = i - b_right;
   if (start_pos < 0) start_pos = 0;
   
   int bn = buffSize();
   int end_pos = i + b_left;
   if (end_pos >= bn) end_pos = bn - 1;
   if (end_pos < start_pos) end_pos = start_pos;
   
   n = (end_pos - start_pos + 1);
}
///поиск экстремумов цены (close)
bool IPriceExtremums::isExstremumLow(int i) const
{
   int start_pos, n_bars;
   findRangeForSearchExstremum(i, start_pos, n_bars);   
   return (iLowest(m_couple, PERIOD_CURRENT, MODE_LOW, n_bars, start_pos) == i);
}
bool IPriceExtremums::isExstremumHigh(int i) const
{
   int start_pos, n_bars;
   findRangeForSearchExstremum(i, start_pos, n_bars);   
   return (iHighest(m_couple, PERIOD_CURRENT, MODE_HIGH, n_bars, start_pos) == i);
}




