//+------------------------------------------------------------------+
//|                                                flinputparams.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict



//--------------------user params----------------------------------

input int StartTrade = 8;                //Start trade
input bool RepaymentLossUpward = true;    //Working off a loss upward
input string TradeKind = "BUY";           //Trade kind (BUY or SELL)


input double FirstLot1 = 0.1;             //First lot (grid 1)
input double LotFactor1 = 1.1;            //Volume coefficient (grid 1)
input double LotHedge1 = 0.5;               //Hedge volume (grid 1)
input int CandleStep1 = 2;                //Candle step (grid 1)
input int MinOrdersDistance1 = 15;        //Min orders distance (grid 1)
input int ProfitPoints1 = 50;             //Profit points (grid 1)

//grid 2
input double FirstLot2 = 0.15;                //First lot (grid 2)
input double LotFactor2 = 1.1;               //Volume coefficient (grid 2)
input double LotHedge2 = 0.8;                //Hedge volume (grid 2)
input int CandleStep2 = 2;                   //Candle step (grid 2)
input int MinOrdersDistance2 = 15;           //Min orders distance (grid 2)
input int ProfitPoints2 = 50;                //Profit points (grid 2)
input int HedgeProfitFactor2 = 5;             //Hedge profit coefficient,% (grid 2)

//grid 3
input double FirstLot3 = 0.2;                //First lot (grid 3)
input double LotFactor3 = 1.1;               //Volume coefficient (grid 3)
input double LotHedge3 = 1.5;                //Hedge volume (grid 3)
input int CandleStep3 = 2;                   //Candle step (grid 3)
input int MinOrdersDistance3 = 20;           //Min orders distance (grid 3)
input int ProfitPoints3 = 50;                //Profit points (grid 3)
input int HedgeProfitFactor3 = 5;             //Hedge profit coefficient,% (grid 3)

//grid 4
input double FirstLot4 = 0.3;                //First lot (grid 4)
input double LotFactor4 = 1.1;               //Volume coefficient (grid 4)
input double LotHedge4 = 2;                //Hedge volume (grid 4)
input int CandleStep4 = 3;                   //Candle step (grid 4)
input int MinOrdersDistance4 = 20;           //Min orders distance (grid 4)
input int ProfitPoints4 = 50;                //Profit points (grid 4)
input int HedgeProfitFactor4 = 5;             //Hedge profit coefficient,% (grid 4)

//grid 5
input double FirstLot5 = 0;                //First lot (grid 5)
input double LotFactor5 = 1.1;               //Volume coefficient (grid 5)
input double LotHedge5 = 2.5;                //Hedge volume (grid 5)
input int CandleStep5 = 3;                   //Candle step (grid 5)
input int MinOrdersDistance5 = 50;           //Min orders distance (grid 5)
input int ProfitPoints5 = 10;                //Profit points (grid 5)
input int HedgeProfitFactor5 = 5;             //Hedge profit coefficient,% (grid 5)


/*
//grid 1
input double FirstLot1 = 0.1;             //First lot (grid 1)
input double LotFactor1 = 1.1;            //Volume coefficient (grid 1)
input double LotHedge1 = 2.5;               //Hedge volume (grid 1)
input int CandleStep1 = 3;                //Candle step (grid 1)
input int MinOrdersDistance1 = 50;        //Min orders distance (grid 1)
input int ProfitPoints1 = 10;             //Profit points (grid 1)

//grid 2
input double FirstLot2 = 0.1;                //First lot (grid 2)
input double LotFactor2 = 1.1;               //Volume coefficient (grid 2)
input double LotHedge2 = 2.5;                //Hedge volume (grid 2)
input int CandleStep2 = 3;                   //Candle step (grid 2)
input int MinOrdersDistance2 = 50;           //Min orders distance (grid 2)
input int ProfitPoints2 = 10;                //Profit points (grid 2)
input int HedgeProfitFactor2 = 5;             //Hedge profit coefficient,% (grid 2)

//grid 3
input double FirstLot3 = 0.1;                //First lot (grid 3)
input double LotFactor3 = 1.1;               //Volume coefficient (grid 3)
input double LotHedge3 = 2.5;                //Hedge volume (grid 3)
input int CandleStep3 = 3;                   //Candle step (grid 3)
input int MinOrdersDistance3 = 50;           //Min orders distance (grid 3)
input int ProfitPoints3 = 10;                //Profit points (grid 3)
input int HedgeProfitFactor3 = 5;             //Hedge profit coefficient,% (grid 3)

//grid 4
input double FirstLot4 = 0.1;                //First lot (grid 4)
input double LotFactor4 = 1.1;               //Volume coefficient (grid 4)
input double LotHedge4 = 2.5;                //Hedge volume (grid 4)
input int CandleStep4 = 3;                   //Candle step (grid 4)
input int MinOrdersDistance4 = 50;           //Min orders distance (grid 4)
input int ProfitPoints4 = 10;                //Profit points (grid 4)
input int HedgeProfitFactor4 = 5;             //Hedge profit coefficient,% (grid 4)

//grid 5
input double FirstLot5 = 0.1;                //First lot (grid 5)
input double LotFactor5 = 1.1;               //Volume coefficient (grid 5)
input double LotHedge5 = 2.5;                //Hedge volume (grid 5)
input int CandleStep5 = 3;                   //Candle step (grid 5)
input int MinOrdersDistance5 = 50;           //Min orders distance (grid 5)
input int ProfitPoints5 = 10;                //Profit points (grid 5)
input int HedgeProfitFactor5 = 5;             //Hedge profit coefficient,% (grid 5)
*/

//grid 6
input double FirstLot6 = 0.1;                //First lot (grid 6)
input double LotFactor6 = 1.1;               //Volume coefficient (grid 6)
input double LotHedge6 = 2.5;                //Hedge volume (grid 6)
input int CandleStep6 = 3;                   //Candle step (grid 6)
input int MinOrdersDistance6 = 50;           //Min orders distance (grid 6)
input int ProfitPoints6 = 10;                //Profit points (grid 6)
input int HedgeProfitFactor6 = 5;             //Hedge profit coefficient,% (grid 6)

//grid 7
input double FirstLot7 = 0.1;                //First lot (grid 7)
input double LotFactor7 = 1.1;               //Volume coefficient (grid 7)
input double LotHedge7 = 2.5;                //Hedge volume (grid 7)
input int CandleStep7 = 3;                   //Candle step (grid 7)
input int MinOrdersDistance7 = 50;           //Min orders distance (grid 7)
input int ProfitPoints7 = 10;                //Profit points (grid 7)
input int HedgeProfitFactor7 = 5;             //Hedge profit coefficient,% (grid 7)

//grid 8
input double FirstLot8 = 0.1;                //First lot (grid 8)
input double LotFactor8 = 1.1;               //Volume coefficient (grid 8)
input double LotHedge8 = 2.5;                //Hedge volume (grid 8)
input int CandleStep8 = 3;                   //Candle step (grid 8)
input int MinOrdersDistance8 = 50;           //Min orders distance (grid 8)
input int ProfitPoints8 = 10;                //Profit points (grid 8)
input int HedgeProfitFactor8 = 5;             //Hedge profit coefficient,% (grid 8)

//grid 9
input double FirstLot9 = 0.1;                //First lot (grid 9)
input double LotFactor9 = 1.1;               //Volume coefficient (grid 9)
input double LotHedge9 = 2.5;                //Hedge volume (grid 9)
input int CandleStep9 = 3;                   //Candle step (grid 9)
input int MinOrdersDistance9 = 50;           //Min orders distance (grid 9)
input int ProfitPoints9 = 10;                //Profit points (grid 9)
input int HedgeProfitFactor9 = 5;             //Hedge profit coefficient,% (grid 9)

//grid 10
input double FirstLot10 = 0.1;                //First lot (grid 10)
input double LotFactor10 = 1.1;               //Volume coefficient (grid 10)
input double LotHedge10 = 2.5;                //Hedge volume (grid 10)
input int CandleStep10 = 3;                   //Candle step (grid 10)
input int MinOrdersDistance10 = 50;           //Min orders distance (grid 10)
input int ProfitPoints10 = 10;                //Profit points (grid 10)
input int HedgeProfitFactor10 = 5;             //Hedge profit coefficient,% (grid 10)
//---------------------------------------------------------------------------------

