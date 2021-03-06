//+------------------------------------------------------------------+
//|                                                   lmaanalize.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict



//структура для хранения взаимного состояния 2-х ema (для i-го бара)
struct FLMA_State_i
{
   //стуктура для хранения одного значение 1-й ema
   struct FLMA_Data
   {
      FLMA_Data() {reset();}
      double v; //значение ema
      double dv; //изменение значения ema относительно прошлого бара, т.е. если больше нуля то значение выросло
      void reset() {v = dv = 0;}         
      bool isUp() const {return (dv > 0);} //ema выросла относительно прошлого бара
      bool isDown() const {return (dv < 0);} //ema упала относительно прошлого бара
      bool isNullTrend() const {return (MathAbs(dv) < 0.00001);} //ema не изменилась относительно прошлого бара
      string strTrend() const {return (isNullTrend()?"no_trend":(isDown()?"down":"up"));} //строковое значение тренда относительно прошлого бара
      string toStr() const {return StringConcatenate("value=", DoubleToStr(v, 4), "  d_value=", DoubleToStr(dv, 4), " (", strTrend(), ")");}      
   };

   FLMA_State_i() :bar_index(-1) {reset();}
   FLMA_State_i(int i_bar) :bar_index(i_bar) {reset();}

   int bar_index; //индекс текущего бара
   FLMA_Data ema1; //младшая ema
   FLMA_Data ema2;  //старшая ema 
   
   double d_ema; //текущая разница между  младшей ema5 и старшей ema20 (расстояние), т.е. если больше нуля то линия младшей над старшей

   //показатель, как повели себя линии младшей ema и старшей ema относительно прошлого бара
   // -1 - расстояние между линиями уменьшилось (сходятся)
   //  0 - произошло пересечение
   //  1 - расстояние между линиями увеличилось (расходятся)
   int ema_prev; 
              
   void reset() {d_ema = ema_prev = 0; ema1.reset(); ema2.reset();}              
   bool invalid() const {return (bar_index < 0);}
   bool wasCross() const {return (ema_prev == 0);} //c момента прошлого бара было пересечение 2-х ema
   bool ema1Up() const {return ema1.isUp();} //младшая ema растет
   bool ema2Up() const {return ema2.isUp();} //старшая ema растет
   bool ema1Down() const {return ema1.isDown();} //младшая ema падает
   bool ema2Down() const {return ema2.isDown();} //старшая ema падает
   string strTrend1() const {return ema1.strTrend();} //строковое значение текущего тренда младшей ema
   string strTrend2() const {return ema2.strTrend();} //строковое значение текущего тренда старшей ema
   bool isConverge() const {return (ema_prev < 0);}
   bool isDiverge() const {return (ema_prev > 0);}
   
   
   void setMAValues(int i, double v1, double v2) // установка значений обеих ema для текущего бара
   {
      bar_index = i;
      ema1.v = v1;
      ema2.v = v2;
      d_ema = v1 - v2;
   }
   void calcStateByPrevios(double v1, double v2) //определение поведения машек относительно прошлого бара
   {
      ema1.dv = ema1.v - v1;
      ema2.dv = ema2.v - v2;
      double d_ema_prev = v1 - v2;
      if (d_ema_prev > 0 && d_ema <= 0) ema_prev = 0;
      else if (d_ema_prev <= 0 && d_ema > 0) ema_prev = 0;
      else if (MathAbs(d_ema_prev) < MathAbs(d_ema)) ema_prev = 1;
      else ema_prev = -1;
   }
   
   string toStr() const
   {
      string s = StringConcatenate("FLMA_State: i=", bar_index);
      s += StringConcatenate("   ema1: ", ema1.toStr());
      s += StringConcatenate("   ema2: ", ema2.toStr());
      s += StringConcatenate("  d_ema=", DoubleToStr(d_ema, 4));
      
      string ss = "??";
      switch(ema_prev)
      {
         case -1: {ss = "converge"; break;}
         case 0: {ss = "cross"; break;}
         case 1: {ss = "diverge"; break;}
         default: break;
      }
      s += StringConcatenate(" (", ss, ")");
      
      return s;
   }
};

//анализирует поведение 2-х заданных машек, в заданном диапазоне свечей
class LMAPairAnalizator
{
public:
   LMAPairAnalizator(string v) :m_couple(v) {reset();}
   virtual ~LMAPairAnalizator() {clearData();}
   
   void setParameters(int, int, int); //установить параметры: m_timeFrame, ma_period1, ma_period2 
   void setBarsRange(int i1, int i2) {bar_index1=i1; bar_index2=i2;}
   void updateData(); //обновить контейнер m_data
   int lastCrossBar() const; //последний индекс бара в котором было пересечение, -1 значит небыло пересечений
   const FLMA_State_i recAt(int i) const; //возвращает элемент m_data по индексу
   bool hasData() const {return (!isEmpty() && !invalidParams());}
   
   
   /////////////////////поиск ведется только внутри массива m_data////////////////////////////////
   
   //пик цены предшедствующий пересечению если младшая МА пересекла старшую сверху или
   //яма цены если младшая МА пересекла снизу
   double lastCrossPeakPrice() const;
   //найти 1-й пик (индекс бара) для младшей ema начиная с start_pos, т.е разворот ema
   int findPeakIndex1(int start_pos) const;
   //найти 1-й пик (индекс бара) для старшей ema начиная с start_pos
   int findPeakIndex2(int start_pos) const;
   //найти 1-ю яму (индекс бара) для младшей ema начиная с start_pos
   int findPitIndex1(int start_pos) const;
   //найти 1-ю яму (индекс бара) для старшей ema начиная с start_pos
   int findPitIndex2(int start_pos) const;
   
   string toStrAt(int) const; 

protected:
   string m_couple;   
   int m_timeFrame; //таймфрейм графика
   int ma_period1; //период младшей машки
   int ma_period2; //период старшей машки
   int bar_index1; //меньший индекс бара с которого начать собирать данные
   int bar_index2; //больший индекс бара на котором закончить собирать данные
   
   FLMA_State_i m_data[]; //данные
   
   void reset() {m_timeFrame = ma_period1 = ma_period2 = -1; bar_index1 = 0; bar_index2 = 50;}
   bool invalidParams() const;
   void clearData() {ArrayFree(m_data);}
   int dataSize() const {return ArraySize(m_data);}
   bool isEmpty() const {return (dataSize() == 0);}
   double ema1Value(int b_index) const; //значение самой младшей ema с индексом бара b_index
   double ema2Value(int b_index) const; //значение самой старшей ema с индексом бара b_index
   
private:
   int arrIndexByBarIndex(int b_index) const; //найти индекс в массива m_data, елемент которого содержит bar_index==i
   bool containsBarIndex(int b_index) const {return (arrIndexByBarIndex(b_index) >= 0);}
   
};
const FLMA_State_i LMAPairAnalizator::recAt(int i) const
{
   FLMA_State_i rec;
   if (isEmpty()) return rec;
   if (i < 0 || i >= dataSize()) return rec;
   return m_data[i];
}
int LMAPairAnalizator::arrIndexByBarIndex(int b_index) const
{
   if (invalidParams() || isEmpty()) return -1;
   
   int n = dataSize();
   for (int i=0; i<n; i++)
      if (m_data[i].bar_index == b_index) return i;
   return -1;
}
int LMAPairAnalizator::findPeakIndex1(int start_pos) const
{
   if (!containsBarIndex(start_pos)) return -1;
   
   int n = dataSize();
   int i = arrIndexByBarIndex(start_pos);   
   for (;;)
   {
      if (i < 1 || i >= (n-1)) break;
      if (m_data[i-1].ema1.isDown() && m_data[i].ema1.isUp()) return i;
      i++;
   }
   return -1;
}
int LMAPairAnalizator::findPeakIndex2(int start_pos) const
{
   if (!containsBarIndex(start_pos)) return -1;
   
   int n = dataSize();
   int i = arrIndexByBarIndex(start_pos);   
   for (;;)
   {
      if (i < 1 || i >= (n-1)) break;
      if (m_data[i-1].ema2.isDown() && m_data[i].ema2.isUp()) return i;
      i++;
   }
   return -1;
}
int LMAPairAnalizator::findPitIndex1(int start_pos) const
{
   if (!containsBarIndex(start_pos)) return -1;
   
   int n = dataSize();
   int i = arrIndexByBarIndex(start_pos);   
   for (;;)
   {
      if (i < 1 || i >= (n-1)) break;
      if (m_data[i].ema1.isDown() && m_data[i-1].ema1.isUp()) return i;
      i++;
   }
   return -1;
}
int LMAPairAnalizator::findPitIndex2(int start_pos) const
{
   if (!containsBarIndex(start_pos)) return -1;
   
   int n = dataSize();
   int i = arrIndexByBarIndex(start_pos);   
   for (;;)
   {
      if (i < 1 || i >= (n-1)) break;
      if (m_data[i].ema2.isDown() && m_data[i-1].ema2.isUp()) return i;
      i++;
   }
   return -1;
}
double LMAPairAnalizator::lastCrossPeakPrice() const
{
   int cross_index = lastCrossBar();
   if (cross_index < 0) {Print("LMAPairAnalizator::lastCrossPeakPrice()  cross_index < 0,  datasize=", dataSize()); return -1;}
   
   if (m_data[cross_index].d_ema > 0) //младшая пересекла старшую снизу  
   {
      int peak_index = findPitIndex1(cross_index); //ищем яму для ema1 за пересечением
      if (peak_index > 0)
      {
         //Print("Pit EMA1 index: ", peak_index);
         peak_index--;
         double min_low = 1000000;
         for (int i=0; i<5; i++)
         {
            double bar_low = iLow(m_couple, m_timeFrame, peak_index);
            if (bar_low < min_low) min_low = bar_low;
            peak_index++;
         }
         return min_low;
      }
   }
   else //младшая пересекла старшую сверху  
   {
      int peak_index = findPeakIndex1(cross_index);  //ищем пик для ema1 за пересечением
      if (peak_index > 0)
      {
         //Print("Peak EMA1 index: ", peak_index);
         peak_index--;
         double max_high = -1;
         for (int i=0; i<5; i++)
         {
            double bar_high = iHigh(m_couple, m_timeFrame, peak_index);
            if (bar_high < max_high) max_high = bar_high;
            peak_index++;
         }
         return max_high;
      }
   }
   return -1;
}
int LMAPairAnalizator::lastCrossBar() const
{
   if (invalidParams()) return -1;
   
   int n = dataSize();
   for (int i=0; i<n; i++)
      if (m_data[i].wasCross()) return m_data[i].bar_index;   
   return -1;
}
string LMAPairAnalizator::toStrAt(int i) const
{
   if (i < 0 || i >= dataSize()) return ("invalid index: "+IntegerToString(i));
   return m_data[i].toStr();
}
void LMAPairAnalizator::updateData()
{
   clearData();
   if (invalidParams()) return;
   
   int n = bar_index2 - bar_index1 + 1; //будущий размер контейнера m_data
   ArrayResize(m_data, n);
   
   int cur_index = bar_index1;
   for (int i=0; i<n; i++)
   {
      m_data[i].setMAValues(cur_index, ema1Value(cur_index), ema2Value(cur_index));
      cur_index++;

      m_data[i].calcStateByPrevios(ema1Value(cur_index), ema2Value(cur_index));
   }
}
double LMAPairAnalizator::ema1Value(int b_index) const
{
   if (invalidParams() || b_index < 0) return -1;
   return iMA(m_couple, m_timeFrame, ma_period1, 0, MODE_EMA, PRICE_CLOSE, b_index);
}
double LMAPairAnalizator::ema2Value(int b_index) const
{
   if (invalidParams() || b_index < 0) return -1;
   return iMA(m_couple, m_timeFrame, ma_period2, 0, MODE_EMA, PRICE_CLOSE, b_index);
}
void LMAPairAnalizator::setParameters(int tf, int p1, int p2)
{
   m_timeFrame = tf;
   ma_period1 = p1;
   ma_period2 = p2;
   
   if (invalidParams())
      Print("LMAPairAnalizator::setParameters: ERR invalid params values");
}
bool LMAPairAnalizator::invalidParams() const
{
   if (m_timeFrame < 1 || m_timeFrame > 1440) return true;
   if (ma_period1 < 3 || ma_period1 >= ma_period2) return true;
   if (bar_index1 < 0 || bar_index1 >= bar_index2 || bar_index2 > 500) return true;
   return false;
}


