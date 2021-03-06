//+------------------------------------------------------------------+
//|                                                 flDivergence.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "FL divergence indicator"

#include <fllib/lextremums.mqh>

#define MAIN_TIMER_INTERVAL      1
#define RECALC_INTERVAL          5

//основные характеристики нашего индикатора
#property indicator_chart_window //указывает на то, что индикатор рисуется в том же окне что и график цены
#property indicator_plots   4 //Указывает количество графических построений в индикаторе (линий или др. сущностей)
#property indicator_buffers 4 //Указывает количество требуемых индикаторных буферов
#property indicator_color1 clrRed
#property indicator_color2 clrGreen
#property indicator_color3 clrMagenta
#property indicator_color4 clrLime

#define INVALID_POINT_VALUE   0 //недостоверное значение индикатора, которое не отрисовывается
#define INDICATOR_NAME "FL Divergence" //имя всего индикатора (у каждой линии свое отдельное имя)

//--- indicator buffers
double m_buffHigh[]; //верхние отрезки
double m_buffLow[]; //нижние отрезки
double m_buffHigh2[]; //верхние отрезки
double m_buffLow2[]; //нижние отрезки

//простой набор целых чисел         
enum IP_SimpleNumber
         {
            ipMTI_Num1 = 1,        // 1
            ipMTI_Num2,            // 2
            ipMTI_Num3,            // 3
            ipMTI_Num4,            // 4
            ipMTI_Num5,            // 5
            ipMTI_Num6,            // 6
            ipMTI_Num7,            // 7
            ipMTI_Num8,            // 8
            ipMTI_Num9,            // 9
            ipMTI_Num10,           // 10
         };

//--- input parameters
input IP_SimpleNumber U_LeftBars = ipMTI_Num5;     // Left bars (first indicator)
input IP_SimpleNumber U_RightBars = ipMTI_Num5;     // Right bars (first indicator)
input IP_SimpleNumber U_LeftBars2 = ipMTI_Num2;     // Left bars (second indicator)
input IP_SimpleNumber U_RightBars2 = ipMTI_Num3;     // Right bars (second indicator)

//vars
string m_couple = "";
//int b_left = 1;
//int b_right = 1;
int rsi_ma_period = 1;
int bars_total = -1;
//bool m_timeout = false;
//bool is_firstCalc = true;
int m_counter = -1;

//extremums obj of RSI
IExtremums rsi_extremums("rsi"); // 5 - 5
IExtremums rsi_extremums2("rsi"); // 2 - 3

//LStringList text_ob


//+------------------------------------------------------------------+
//| MQL functions
//+------------------------------------------------------------------+
int OnInit()
{
   initVars();
   initIndicatorBuffers(m_buffHigh, 0);
   initIndicatorBuffers(m_buffLow, 1);
   initIndicatorBuffers(m_buffHigh2, 2);
   initIndicatorBuffers(m_buffLow2, 3);
   
   IndicatorSetInteger(INDICATOR_DIGITS, Digits()); //точность значений индикатора
   IndicatorSetString(INDICATOR_SHORTNAME, INDICATOR_NAME); //сокращенное имя всего индикатора
   initIndicatorProperties(0, "high divergence 1"); //инициализация верхних отрезков (5-5)
   initIndicatorProperties(1, "low divergence 1"); //инициализация нижних отрезков (5-5)
   initIndicatorProperties(2, "high divergence 2"); //инициализация верхних отрезков (2-3)
   initIndicatorProperties(3, "low divergence 2"); //инициализация нижних отрезков (2-3)
   
   
   initRSIObjects();
   
   Print("----------------Indicator started-------------------------");
   EventSetTimer(MAIN_TIMER_INTERVAL);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   resetAllBuffs();
}
void OnTimer()
{
   m_counter++;
   if (m_counter > 1000000) m_counter = 0;
   if (m_counter % int(RECALC_INTERVAL) > 0) return;

   bars_total = iBars(m_couple, PERIOD_CURRENT);
   //Print("bars_total = ", bars_total);
   if (bars_total > 1000) bars_total = 1000;

   //m_timeout = true;
   on_calc();
}            
void on_calc()
{
   rsi_extremums.updateBuffer(bars_total);
   rsi_extremums2.updateBuffer(bars_total);
   
   //найти экремумы среди значений индикатора RSI
   for(int i=0; i<bars_total; i++)
   {
      rsi_extremums.checkExtremum(i);
      rsi_extremums2.checkExtremum(i);
   }
      //checkExtremumRSI(i);

   resetAllBuffs();
   recalcBuffs();
}
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])                
{
   //Print("OnCalculate:   rates_total=", rates_total, "  prev_calculated=", prev_calculated);
/*
   bars_total = rates_total;
   if (!m_timeout) return rates_total;
   m_timeout = false;
   
   int limit = rates_total - prev_calculated;
   Print("   rates_total=", rates_total, "  prev_calculated=", prev_calculated, " limit=", limit, "   is_firstCalc=", is_firstCalc);
   
   
   if (is_firstCalc) 
   {
      if (rsi_extremums.buffEmpty()) return rates_total;
      limit = rates_total; 
      is_firstCalc = false;
   }
   else if (limit == 0) limit++;
   
   //найти экремумы среди значений индикатора RSI
   for(int i=0; i<limit; i++)
   {
      //m_buff[i] = iLow(m_couple, 0, i);
      checkExtremumRSI(i);
   }
   //m_buff[10] = 0;
   

   recalcBuffs(); //пересчитать значения нашего индикатора
   */
   
   return rates_total;
}

//+------------------------calc/update indicator funcs------------------------------------------+
void resetAllBuffs()
{
   resetBuff(m_buffHigh);
   resetBuff(m_buffLow);
   resetBuff(m_buffHigh2);
   resetBuff(m_buffLow2);
}
void resetBuff(double &buff[])
{
   int n = ArraySize(buff);
   for (int i=0; i<n; i++) buff[i] = int(INVALID_POINT_VALUE);
}
void recalcBuffs()
{
   //Print("updateBuff()  rsi extremums=", rsi_extremums.count(), " (", rsi_extremums.highCount(), "/", rsi_extremums.lowCount(), ")");
   
   rsi_extremums.recalcDivergenceHighPoints(m_buffHigh);
   rsi_extremums.recalcDivergenceLowPoints(m_buffLow);
   
   rsi_extremums2.recalcDivergenceHighPoints(m_buffHigh2);
   rsi_extremums2.recalcDivergenceLowPoints(m_buffLow2);
   
   /*
   int n_extr = rsi_extremums.lowCount() - 1;
   int i = 0;
   while (i < n_extr)
   {
      if (rsi_extremums.isDivergenceLow(i))
      {
         recalcSegment(i, false);
        // i += 2;
      }
     // else i++;
     i++;
   }
   
   n_extr = rsi_extremums.highCount() - 1;
   i = 0;
   while (i < n_extr)
   {
      if (rsi_extremums.isDivergenceHigh(i))
      {
         recalcSegment(i, true);
        // i += 2;
      }
      //else i++;
      i++;
   }
   */
}
/*
void recalcSegment(int begin_index, bool is_high)
{
   if (begin_index < 0) return;
   int pos_first, pos_last;
   if (is_high)
   {
      pos_first = rsi_extremums.highAt(begin_index);
      pos_last = rsi_extremums.highAt(begin_index+1);
      recalcBuffSegmentHigh(pos_first, pos_last);
   }
   else
   {
      pos_first = rsi_extremums.lowAt(begin_index);
      pos_last = rsi_extremums.lowAt(begin_index+1);   
      recalcBuffSegmentLow(pos_first, pos_last);
   }
}
void recalcBuffSegmentHigh(int pos_first, int pos_last)
{
      if (pos_first < 0 || pos_first >= pos_last) 
      {
         Print("recalcBuffSegmentHigh ERR  pos_first=",pos_first,"  pos_last=",pos_last); 
         return;
      }
      
      LDoubleList list;
      FLDivCalc::calcLineHighPoints(pos_first, pos_last, list);
      FLDivCalc::updateBuffSegment(m_buffHigh, pos_first, list);
      
      
}
void recalcBuffSegmentLow(int pos_first, int pos_last)
{
      if (pos_first < 0 || pos_first >= pos_last) 
      {
         Print("recalcBuffSegmentLow ERR  pos_first=",pos_first,"  pos_last=",pos_last); 
         return;
      }
      
      LDoubleList list;
      FLDivCalc::calcLineLowPoints(pos_first, pos_last, list);
      FLDivCalc::updateBuffSegment(m_buffLow, pos_first, list);
}
*/

////////////////////////INIT FUNC/////////////////////////////////
void initVars()
{
   m_couple = Symbol();
   //b_left = U_LeftBars;
   //b_right = U_RightBars;
   rsi_ma_period = 14;
   bars_total = -1;
   //m_timeout = false;
   //is_firstCalc = true;  
   m_counter = -1;
   
}
void initRSIObjects()
{
   rsi_extremums.reset();
   rsi_extremums.setIndicatorHandle(iRSI(m_couple, PERIOD_CURRENT, rsi_ma_period, PRICE_CLOSE));
   rsi_extremums.setDiapazon(U_LeftBars, U_RightBars);

   rsi_extremums2.reset();
   rsi_extremums2.setIndicatorHandle(iRSI(m_couple, PERIOD_CURRENT, rsi_ma_period, PRICE_CLOSE));
   rsi_extremums2.setDiapazon(U_LeftBars2, U_RightBars2);
}
void initIndicatorProperties(int index, string line_name)
{

   //PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 15); //--- sets first bar from what index will be drawn
   PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_LINE); //вид отрисовки линии
   PlotIndexSetString(index, PLOT_LABEL, line_name); //название линии
   PlotIndexSetInteger(index, PLOT_SHIFT, 0);
   //PlotIndexSetInteger(index, PLOT_LINE_COLOR, line_color);
   PlotIndexSetInteger(index, PLOT_LINE_WIDTH, 2);
   PlotIndexSetInteger(index, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetDouble(index, PLOT_EMPTY_VALUE, int(INVALID_POINT_VALUE)); //Пустое значение для построения, для которого нет отрисовки
   
}
void initIndicatorBuffers(double &buff[], int index)
{
   ArraySetAsSeries(buff, true); //инвертирует порядок индексации
   SetIndexBuffer(index, buff, INDICATOR_DATA);
   resetBuff(buff);
}

/*
///поиск экстремумов цены (close)
bool isExstremumLow(int i)
{
   int start_pos, n_bars;
   findRangeForSearchExstremum(i, start_pos, n_bars);   
   return (iLowest(m_couple, PERIOD_CURRENT, MODE_CLOSE, n_bars, start_pos) == i);
}
bool isExstremumHigh(int i)
{
   int start_pos, n_bars;
   findRangeForSearchExstremum(i, start_pos, n_bars);   
   return (iHighest(m_couple, PERIOD_CURRENT, MODE_CLOSE, n_bars, start_pos) == i);
}
void findRangeForSearchExstremum(int i, int &start_pos, int &n)
{
   int left = b_right;
   start_pos = i - b_right;
   if (start_pos < 0) {start_pos = 0; left = i;}
   n = left + b_left + 1;
   if ((start_pos + n) >= bars_total) n = 1;
}
*/

/*
void checkExtremumRSI(int i)
{
   int start_pos, n_bars;
   findRangeForSearchExstremum(i, start_pos, n_bars);   

   //Print("checkExtremumBar i=", i);
   if (rsi_extremums.isExstremumHigh(i, start_pos, n_bars)) rsi_extremums.addHighIndex(i);
   else if (rsi_extremums.isExstremumLow(i, start_pos, n_bars)) rsi_extremums.addLowIndex(i);
}
*/




