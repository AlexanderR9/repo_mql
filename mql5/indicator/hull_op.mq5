//+------------------------------------------------------------------+
//|                                                      hull_op.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define  MAX_BARS    500


#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1

#property indicator_label1  "hull_op"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrOrange,clrAqua
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2


double line_buff[];
double color_buff[];


void resetBuffs()
{
   int n = ArraySize(line_buff);
   for (int i=0; i<n; i++)
   {
      line_buff[i] = EMPTY_VALUE;
      color_buff[i] = EMPTY_VALUE;
   }

}



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, line_buff, INDICATOR_DATA); 
   SetIndexBuffer(1, color_buff, INDICATOR_COLOR_INDEX); 
   resetBuffs();

   ArraySetAsSeries(line_buff, true);
   ArraySetAsSeries(color_buff, true);

   
   //Print("indicator ", indicator_label1, " started!");
   return(INIT_SUCCEEDED);
}
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int n = ArraySize(open);
   int n2 = (n > MAX_BARS) ? MAX_BARS : n;
   if (n2 < 10) return rates_total;
   
   for (int i=0; i<n2; i++)
   {
      line_buff[i] = open[n-i-1];
   }
   
   for (int i=0; i<n2-1; i++)
   {
      if (line_buff[i+1] < line_buff[i]) color_buff[i] = 0;
      else if (line_buff[i+1] > line_buff[i]) color_buff[i] = 1;
      else color_buff[i] = 2;
   }

   //Print("calc n=", n, "  line_buff[0]=", line_buff[0]);
   return(rates_total);
}
//void OnTimer() {}
//+------------------------------------------------------------------+


