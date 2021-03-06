//+------------------------------------------------------------------+
//|                                                 flDivergence.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "FL divergence indicator (version 2)"

#include <fllib/lextremums2.mqh>

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

#define INVALID_POINT_VALUE   -1 //недостоверное значение индикатора, которое не отрисовывается
#define INDICATOR_NAME "FL Divergence v2" //имя всего индикатора (у каждой линии свое отдельное имя)

//--- indicator buffers
double m_buffHigh[]; //верхние отрезки
double m_buffLow[]; //нижние отрезки
double m_buffHigh2[]; //верхние отрезки
double m_buffLow2[]; //нижние отрезки


//--- input parameters
input IP_SimpleNumber U_LeftBars = ipMTI_Num5;     // Left bars (first indicator)
input IP_SimpleNumber U_RightBars = ipMTI_Num5;     // Right bars (first indicator)
input IP_SimpleNumber U_LeftBars2 = ipMTI_Num2;     // Left bars (second indicator)
input IP_SimpleNumber U_RightBars2 = ipMTI_Num3;     // Right bars (second indicator)

//vars
string m_couple = "";
int rsi_ma_period = 1;
int bars_total = -1;
int m_counter = -1;

//extremums obj of chart prices
IPriceExtremums *price_extremums = NULL;     // 5 - 5
IPriceExtremums *price_extremums2 = NULL;    // 2 - 3


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
   
   
   initPriceObjects();
   
   Print("----------------Indicator started-------------------------");
   EventSetTimer(MAIN_TIMER_INTERVAL);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   resetAllBuffs();
   if (price_extremums) delete price_extremums;
   if (price_extremums2) delete price_extremums2;
}
void OnTimer()
{
   m_counter++;
   if (m_counter % int(RECALC_INTERVAL) > 0) return;
   if (m_counter > 1000000) m_counter = 0;

   updateBarsCount();
   on_calc();
}            
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])                
{
   //Print("OnCalculate:   rates_total=", rates_total, "  prev_calculated=", prev_calculated);
   return rates_total;
}

//+------------------------calc/update indicator funcs------------------------------------------+
void on_calc()
{
   price_extremums.updateBuffer(bars_total);
   price_extremums2.updateBuffer(bars_total);
   
   price_extremums.updateExtremumsPoints();
   price_extremums2.updateExtremumsPoints();
   
   resetAllBuffs();
   recalcBuffs();   
   
}
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
void updateBarsCount()
{
   bars_total = iBars(m_couple, PERIOD_CURRENT);
   if (bars_total > 1000) bars_total = 1000;
}
void recalcBuffs()
{
   //Print("updateBuff()  rsi extremums=", rsi_extremums.count(), " (", rsi_extremums.highCount(), "/", rsi_extremums.lowCount(), ")");
   price_extremums.recalcDivergenceHighPoints(m_buffHigh);
   price_extremums.recalcDivergenceLowPoints(m_buffLow);
   
   price_extremums2.recalcDivergenceHighPoints(m_buffHigh2);
   price_extremums2.recalcDivergenceLowPoints(m_buffLow2);
}


////////////////////////INIT FUNC/////////////////////////////////
void initVars()
{
   m_couple = Symbol();
   rsi_ma_period = 14;
   bars_total = -1;
   m_counter = -1;   
   
   price_extremums = NULL; // 5 - 5
   price_extremums2 = NULL; // 2 - 3
}
void initPriceObjects()
{
   price_extremums = new IPriceExtremums(m_couple);
   price_extremums.setIndicatorHandle(iRSI(m_couple, PERIOD_CURRENT, rsi_ma_period, PRICE_CLOSE));
   price_extremums.setDiapazon(U_LeftBars, U_RightBars);

   price_extremums2 = new IPriceExtremums(m_couple);
   price_extremums2.setIndicatorHandle(iRSI(m_couple, PERIOD_CURRENT, rsi_ma_period, PRICE_CLOSE));
   price_extremums2.setDiapazon(U_LeftBars2, U_RightBars2);
}
void initIndicatorProperties(int index, string line_name)
{
   PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_LINE); //вид отрисовки линии
   PlotIndexSetString(index, PLOT_LABEL, line_name); //название линии
   PlotIndexSetInteger(index, PLOT_SHIFT, 0);
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
void checkExtremumRSI(int i)
{
   int start_pos, n_bars;
   findRangeForSearchExstremum(i, start_pos, n_bars);   

   //Print("checkExtremumBar i=", i);
   if (rsi_extremums.isExstremumHigh(i, start_pos, n_bars)) rsi_extremums.addHighIndex(i);
   else if (rsi_extremums.isExstremumLow(i, start_pos, n_bars)) rsi_extremums.addLowIndex(i);
}
*/




