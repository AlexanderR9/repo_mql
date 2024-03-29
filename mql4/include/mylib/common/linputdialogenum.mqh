//+------------------------------------------------------------------+
//|                                              inputparamsenum.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

///////////////////////////////////////////////
// здесь описаны множества, которые можно использовать для задания 
// входных параметров советника в диалоговом окне при запске советника.
// выбор значения параметра будет выглядеть в виде всплывающего списка.
///////////////////////////////////////////////


//интервал работы различных таймеров
enum IP_TimerInterval
         {
            ipMTI_1 = 1101,      // 1 sec      
            ipMTI_2,             // 2 sec      
            ipMTI_3,             // 3 sec      
            ipMTI_5,             // 5 sec      
            ipMTI_10,            // 10 sec      
            ipMTI_15,            // 15 sec      
            ipMTI_20,            // 20 sec      
            ipMTI_30,            // 30 sec      
            ipMTI_60,            // 1 min      
            ipMTI_300,           // 5 min
            ipMTI_600,           // 10 min   
            ipMTI_1800,          // 30 min   
            ipMTI_none = -1,     // timer turned off     
         };

//возможный тип открытия позиция
enum IP_TrateType
         {
            ipMTI_All = 1151,    // BUY and SELL      
            ipMTI_OnlyBuy,       // Only BUY     
            ipMTI_OnlySell,      // Only SELL             
         };
         
//простой набор целых чисел         
enum IP_SimpleNumber
         {
            ipMTI_Num0 = 1201,     // 0
            ipMTI_Num1,            // 1
            ipMTI_Num2,            // 2
            ipMTI_Num3,            // 3
            ipMTI_Num4,            // 4
            ipMTI_Num5,            // 5
            ipMTI_Num6,            // 6
            ipMTI_Num7,            // 7
            ipMTI_Num8,            // 8
            ipMTI_Num9,            // 9
            ipMTI_Num10,           // 10
            ipMTI_Num11,           // 11
            ipMTI_Num12,           // 12
            ipMTI_Num13,           // 13
            ipMTI_Num14,           // 14
            ipMTI_Num15,           // 15
            ipMTI_Num16,           // 16
            ipMTI_Num17,           // 17
            ipMTI_Num18,           // 18
            ipMTI_Num19,           // 19
            ipMTI_Num20,           // 20
            ipMTI_Num22,           // 22
            ipMTI_Num25,           // 25
            ipMTI_Num30,           // 30
            ipMTI_Num40,           // 40
            ipMTI_Num50,           // 50
            ipMTI_Num60,           // 60
            ipMTI_Num70,           // 70
            ipMTI_Num80,           // 80
            ipMTI_Num90,           // 90
            ipMTI_Num100,          // 100
            ipMTI_Num200,          // 200
            ipMTI_Num300,          // 300
            ipMTI_Num500,          // 500
               
         };         

//набор для установки размера лота         
enum IP_LotSize
         {
            ipMTI_Lot001 = 1251,    // 0.01
            ipMTI_Lot002,           // 0.02
            ipMTI_Lot003,           // 0.03
            ipMTI_Lot004,           // 0.04
            ipMTI_Lot005,           // 0.05
            ipMTI_Lot01,            // 0.1
            ipMTI_Lot02,            // 0.2
            ipMTI_Lot04,            // 0.4
            ipMTI_Lot08,            // 0.8
            ipMTI_Lot1,             // 1.0
            
         };


//convert functions
class IP_ConvertClass
{
public:
   static int fromSimpleNumber(const IP_SimpleNumber); //конвертирует элемент множества IP_SimpleNumber в нормальное значение
   static int fromTimerInterval(const IP_TimerInterval); //конвертирует элемент множества IP_TimerInterval в нормальное значение 
   static double fromLotSize(const IP_LotSize); //конвертирует элемент множества IP_LotSize в нормальное значение 
   
   static bool canTradeOnlyBuy(int t) {return (t == int(ipMTI_OnlyBuy));}
   static bool canTradeOnlySell(int t) {return (t == int(ipMTI_OnlySell));}
   static bool canTradeAll(int t) {return (t == int(ipMTI_All));}
   
   
   
};
double IP_ConvertClass::fromLotSize(const IP_LotSize value)
{
   switch (value)
   {
      case ipMTI_Lot001:      return 0.01;
      case ipMTI_Lot002:      return 0.02;
      case ipMTI_Lot003:      return 0.03;
      case ipMTI_Lot004:      return 0.04;
      case ipMTI_Lot005:      return 0.05;
      case ipMTI_Lot01:       return 0.1;
      case ipMTI_Lot02:       return 0.2;
      case ipMTI_Lot04:       return 0.4;
      case ipMTI_Lot08:       return 0.8;
      case ipMTI_Lot1:        return 1;
      
      default: break;
   }
   return -1;
};
int IP_ConvertClass::fromTimerInterval(const IP_TimerInterval value)
{
   switch (value)
   {
      case ipMTI_1:     return 1;
      case ipMTI_2:     return 2;
      case ipMTI_3:     return 3;
      case ipMTI_5:     return 5;
      case ipMTI_10:    return 10;
      case ipMTI_15:    return 15;
      case ipMTI_20:    return 20;
      case ipMTI_30:    return 30;
      case ipMTI_60:    return 60;
      case ipMTI_300:   return 300;
      case ipMTI_600:   return 600;
      case ipMTI_1800:  return 1800;
      
      default: break;
   }
   return -1;
};
int IP_ConvertClass::fromSimpleNumber(const IP_SimpleNumber value)
{
   switch (value)
   {
      case ipMTI_Num0: return 0;
      case ipMTI_Num1: return 1;
      case ipMTI_Num2: return 2;
      case ipMTI_Num3: return 3;
      case ipMTI_Num4: return 4;
      case ipMTI_Num5: return 5;
      case ipMTI_Num6: return 6;
      case ipMTI_Num7: return 7;
      case ipMTI_Num8: return 8;
      case ipMTI_Num9: return 9;
      case ipMTI_Num10: return 10;
      case ipMTI_Num11: return 11;
      case ipMTI_Num12: return 12;
      case ipMTI_Num13: return 13;
      case ipMTI_Num14: return 14;
      case ipMTI_Num15: return 15;
      case ipMTI_Num16: return 16;
      case ipMTI_Num17: return 17;
      case ipMTI_Num18: return 18;
      case ipMTI_Num19: return 19;
      case ipMTI_Num20: return 20;
      
      case ipMTI_Num22: return 22;
      case ipMTI_Num25: return 25;
      case ipMTI_Num30: return 30;
      case ipMTI_Num40: return 40;
      case ipMTI_Num50: return 50;
      case ipMTI_Num60: return 60;
      case ipMTI_Num70: return 70;
      case ipMTI_Num80: return 80;
      case ipMTI_Num90: return 90;
      case ipMTI_Num100: return 100;
      case ipMTI_Num200: return 200;
      case ipMTI_Num300: return 300;
      case ipMTI_Num500: return 500;
      
      default: break;
   }
   return -1;
};

