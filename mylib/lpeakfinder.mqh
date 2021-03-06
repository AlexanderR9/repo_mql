//+------------------------------------------------------------------+
//|                                                  lpeakfinder.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/lcontainer.mqh>


//находит пики и впадины цен на графике с заданными параметрами
class LPeakFinder
{
public:
   LPeakFinder(string v) :m_couple(v), m_tf(60), m_barsCount(500), m_shoulderSize(8) {}      
   
   void refind(); //провести поиск заново, обновить все данные
   void setTimeFrame(int tf) {m_tf = tf;}
   void setBarsCount(int n) {m_barsCount = n;}
   void setShoulderSize(int n) {m_shoulderSize = n;}
   
protected:
   string m_couple; //инструмент графика
   int m_tf; //ТФ графика
   int m_barsCount; //количетсво опрашиваемых свечей
   int m_shoulderSize; // количетсво свечей с скаждой стороны от пика/впадины, которое анализируется что бы понять где этот самый пик
   
   LMapIntDouble m_peaks; //пики, (key-номер свечи, value-цена high)
   LMapIntDouble m_pits; //впадина, (key-номер свечи, value-цена low)
   
   void clearData();
   void findPits();
   void findPeaks();
   

};
void LPeakFinder::refind()
{
   clearData();
   findPeaks();
   findPits();
   
} 
void LPeakFinder::clearData()
{
   m_peaks.clear();
   m_pits.clear();
} 
void LPeakFinder::findPeaks()
{
   for (int i=0; i<m_barsCount; i++)
   {
      int look_index = i + m_shoulderSize;
      int start_index = i - look_index;
      int finish_index = start_index + 2*m_shoulderSize;
      
      double max = 0;
      int i_max = 0;
      for (int j=start_index; j<finish_index; j++)
      {
         double h = iHigh(m_couple, m_tf, j);
         if (j == start_index) {max=h; i_max=j; continue;}
         if (h > max) {max=h; i_max=j;}
      }
      
      if (i_max == look_index) m_peaks.insert(i_max, max);
   }
}
void LPeakFinder::findPits()
{
   for (int i=0; i<m_barsCount; i++)
   {
      int look_index = i + m_shoulderSize;
      int start_index = i - look_index;
      int finish_index = start_index + 2*m_shoulderSize;
      
      double min = 0;
      int i_min = 0;
      for (int j=start_index; j<finish_index; j++)
      {
         double l = iLow(m_couple, m_tf, j);
         if (j == start_index) {min=l; i_min=j; continue;}
         if (l < min) {min=l; i_min=j;}
      }
      
      if (i_min == look_index) m_pits.insert(i_min, min);
   }
}




