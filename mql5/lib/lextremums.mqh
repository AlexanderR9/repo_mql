//+------------------------------------------------------------------+
//|                                                   lextremums.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


#include <fllib/lcontainer.mqh>

//+------------------------------------------------------------------+

//класс для поиска экстремумов заданного индикатора
class IExtremums
{
public:
   IExtremums(string name) :i_name(name), m_handle(-1) {}
   
   void updateBuffer(int n);
   
   int highAt(int) const;
   int lowAt(int) const;

   bool isExstremumLow(int, int, int) const;
   bool isExstremumHigh(int, int, int) const;
   void addHighIndex(int i);
   void addLowIndex(int i);
   bool IExtremums::isDivergenceLow(int) const;
   bool IExtremums::isDivergenceHigh(int) const;
   void reset();
   
   
   inline bool buffEmpty() const {return (buffSize() == 0);}
   inline void setIndicatorHandle(int h) {m_handle = h;}
   inline int highCount() const {return m_highPoints.count();}
   inline int lowCount() const {return m_lowPoints.count();}
   inline int count() const {return (highCount() + lowCount());}
   double buffValue(int i) const;

   static double invalidValue() {return -11;}

protected:
   string i_name;
   LIntList m_highPoints;
   LIntList m_lowPoints;
   int m_handle;
   double m_buffer[];
   
   int buffSize() const {return ArraySize(m_buffer);}
   
};
void IExtremums::reset()
{
   m_handle = -1;
   m_highPoints.clear();
   m_lowPoints.clear();
}
bool IExtremums::isDivergenceLow(int low_index) const
{
   if (low_index < 0 && low_index+1 < lowCount()) return false;
   int pos1 = lowAt(low_index);
   int pos2 = lowAt(low_index+1);
   bool b1 = (buffValue(pos1) > buffValue(pos2));
   bool b2 = iLow(Symbol(), PERIOD_CURRENT, pos1) > iLow(Symbol(), PERIOD_CURRENT, pos2);
   return (b1 != b2);
}
bool IExtremums::isDivergenceHigh(int high_index) const
{
   if (high_index < 0 && high_index+1 < highCount()) return false;
   int pos1 = highAt(high_index);
   int pos2 = highAt(high_index+1);
   bool b1 = (buffValue(pos1) > buffValue(pos2));
   bool b2 = iHigh(Symbol(), PERIOD_CURRENT, pos1) > iHigh(Symbol(), PERIOD_CURRENT, pos2);
   return (b1 != b2);
}
double IExtremums::buffValue(int i) const
{
   if (i < 0 || i >= buffSize()) return invalidValue();
   return m_buffer[i];
}
int IExtremums::highAt(int i) const
{
   if (i < 0 || i >= highCount()) return -1;
   return m_highPoints.at(i);
}
int IExtremums::lowAt(int i) const
{
   if (i < 0 || i >= lowCount()) return -1;
   return m_lowPoints.at(i);
}
void IExtremums::updateBuffer(int n)
{
   //Print("updateBuffer  m_handle=", m_handle, "  n=", n);
   if (m_handle < 0 || n < 1) return;
   if (n > 1000) n = 1000;
   
   //--- заполнение массива m_buffer[] текущими значениями индикатора
   CopyBuffer(m_handle, 0, 0, n, m_buffer);
   
   //--- задаём порядок индексации массива m_buffer[] как в MQL4
   ArraySetAsSeries(m_buffer, true);    
}
void IExtremums::addHighIndex(int i_high)
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
void IExtremums::addLowIndex(int i_low)
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
bool IExtremums::isExstremumLow(int pos, int start_pos, int n_bars) const
{
   if (buffEmpty()) return false;
   //if (pos<5) Print("isExstremumLow:  i=", pos, "  start_pos=", start_pos, "  n_bars=", n_bars);
   if (pos < 0 || pos >= buffSize()) return false;
   if (start_pos < 0 || start_pos >= buffSize()) return false;
   
   int end_pos = start_pos + n_bars - 1;
   if (end_pos < 0 || end_pos >= buffSize()) return false;

   double min = 1000000;
   int min_index = -1;
   for (int j=start_pos; j<=end_pos; j++)
      if (buffValue(j) < min) {min = buffValue(j); min_index = j;}
      
   return (min_index == pos);
}
bool IExtremums::isExstremumHigh(int pos, int start_pos, int n_bars) const
{
   if (buffEmpty()) return false;
   //if (pos<25) Print("isExstremumHigh:  i=", pos, "  start_pos=", start_pos, "  n_bars=", n_bars);
   if (pos < 0 || pos >= buffSize()) return false;
   if (start_pos < 0 || start_pos >= buffSize()) {Print("ERR_2"); return false;}
   
   int end_pos = start_pos + n_bars - 1;
   if (end_pos < 0 || end_pos >= buffSize()) return false;

   double max = 0;
   int max_index = -1;
   for (int j=start_pos; j<=end_pos; j++)
   {
      
      if (buffValue(j) > max) {max = buffValue(j); max_index = j;}
      //if (pos<5) Print("i=", j, "   value=", value(j));
      
   }
   //if (pos<25) Print("max_index=", max_index);
      
   return (max_index == pos);
}

//класс для расчета точек буфера индикатора 
class FLDivCalc
{
public:
   static void calcLineHighPoints(int, int, LDoubleList&); //аппроксимация прямой(верхней) по двум точкам
   static void calcLineLowPoints(int, int, LDoubleList&); //аппроксимация прямой(верхней) по двум точкам
   static void updateBuffSegment(double &buff[], int, const LDoubleList&); //обновить точки для отрезкa в buff, начиная с i_bar_fist

};
void FLDivCalc::calcLineHighPoints(int i_bar_fist, int i_bar_last, LDoubleList &list)
{
   list.clear();
   if (i_bar_fist < 0 || i_bar_fist >= i_bar_last) return;
   
   int line_points = i_bar_last - i_bar_fist + 1;
   double value_first = iHigh(Symbol(), PERIOD_CURRENT, i_bar_fist);
   double value_last = iHigh(Symbol(), PERIOD_CURRENT, i_bar_last);
   double step = MathAbs(value_first - value_last)/double(line_points - 1);
   if (value_first > value_last) step *= (-1);
   
   list.append(value_first);
   if (line_points > 2)
   {
      for (int i=0; i<(line_points-2); i++)
         list.append(value_first + (i+1)*step);
   }
   list.append(value_last);

}
void FLDivCalc::calcLineLowPoints(int i_bar_fist, int i_bar_last, LDoubleList &list)//аппроксимация прямой(нижней) по двум точкам
{
   list.clear();
   if (i_bar_fist < 0 || i_bar_fist >= i_bar_last) return;
   
   int line_points = i_bar_last - i_bar_fist + 1;
   double value_first = iLow(Symbol(), PERIOD_CURRENT, i_bar_fist);
   double value_last = iLow(Symbol(), PERIOD_CURRENT, i_bar_last);
   double step = MathAbs(value_first - value_last)/double(line_points - 1);
   if (value_first > value_last) step *= (-1);
   
   list.append(value_first);
   if (line_points > 2)
   {
      for (int i=0; i<(line_points-2); i++)
         list.append(value_first + (i+1)*step);
   }
   list.append(value_last);
}
void FLDivCalc::updateBuffSegment(double &buff[], int i_bar_fist, const LDoubleList &list) //обновить точки для отрезкa в buff, начиная с i_bar_fist
{
   if (list.isEmpty() || i_bar_fist < 0) return;
   
   int n = list.count();
   for (int i=0; i<n; i++)
      buff[i + i_bar_fist] = list.at(i);
}

