//+------------------------------------------------------------------+
//|                                                        enums.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/common/lcontainer.mqh>


///////////////////////////////////////////////
// здесь описаны множества входных и выходных параметров советника, а также множество возможных ошибок при работе советника.
// все значения входных параметров задавать всегда для 4-х значного брокера (в случае 5-знакового брокера советник должен все пересчитывать)                         
// exipExecTime,exipEndTime,exipMondayTime,exipFridayTime - указывается в виде целого числа, часы затем минуты, пример: 1200 (12:00), 610 (6:10) или -1 (считается, что не указан)                        
// exipMondayTime,exipFridayTime - временные метки в понедельник и пятницы (локальное время компа) между которыми можно вести торговлю.
///////////////////////////////////////////////




// множество входных параметров для стратегии советника
enum ExInputParamsTypes {exipStop = 10, exipProfit, exipDist, exipNBars, exipNPips, exipTimeFrame,
                         exipStartLot, exipNextBetFactor, exipNextLineFactor, exipSum, exipPermittedPos,
                         exipFixLot, exipExecTime, exipEndTime, exipExecSpace, exipMaxErrs, exipCoupleSpace,
                         exipMondayTime, exipFridayTime, exipDecStep, exipIncStep, exipStopFactor, exipMaxSpread,
                         exipTimerInterval, exipSaveInterval, exipSlipPips, exipCommision, exipMaxOrders, exipTradeType,
                         exipDeviation, exipExpiration, exipStartPrice};



// множество параметров текущего состояния советника
enum ExStateParamsTypes {exspStep = 100, exspPrevStep, exspMaxStep, exspOrder, exspNextOrder, exspNumber, exspWinNumber, 
         exspCWinNumber, exspWinPips, exspLossNumber, exspFullWinNumber, exspStopLossCount, exspTakeProfitCount,
         exspFullLossNumber, exspLossSum, exspLossPips, exspCurrentSum, exspMinSum, exspMaxSum, exspResultSum,
         exspBetsSize, exspLotsSize, exspCommisionSize, exspSwapSize, exspLineNumber, exspTradeErrCount, exspLockedCount,
         exspPendingOrder, exspPendingOrderBuy, exspPendingOrderSell, exspPendingOrderCount, exspPendingOrderWorkedCount, 
         exspPendingOrderWinCount, exspPendingOrderLossCount, exspPendingStopLossCount, exspPendingTakeProfitCount, 
         exspLastTradeCmd};
         

// множество кодов ошибок или результатов выполнения операций
enum MQErrTypes {etOpenOrder = -100, etOpenNextOrder, etFindOrder, etFindNextOrder, etCloseOrder, etDeleteNextOrder, 
		    etOpenFile, etReadFile, etWriteFile, etAppendFile, etFileName, etFindFile, etCreateFile, 
		    etLoadMainParams, etLoadInputParams, etConfigParamValue, etLoadCouples, etLoadState, etSaveState, etNextOrderOpened, 
		    etNextOrderHistory, etConvertType, etConnectionStateFault, etNextOrderNotPlaced, etNextOrderStillPlaced, 
		    etInternal, etMqlFunc, etInvalidStateParam, etAddOrderHistory, etSpreadOver, etOverOrdersCount, etPipsOver, etUnknown = -101, 
		    etOpenOrderOk = 1001, etOpenNextOrderOk = 1002, etDeleteNextOrderOk = 1003, etConnectionStateOk = 1004};


// множество типов разрешенных позиций при работе советника
enum MQPermittedPosTypes {pptAll = 150, pptOnlyLong, pptOnlyShort};

//множество торговых операций
enum ExTradeOperations {toBuy = 200, toSell, toBuyStop, toSellStop, toBuyLimit, toSellLimit, toClose, toDelete};


class MQEnumsStatic
{
public:
   // короткое описание типа (для чтения значения из файла)
   static string shortStrByType(int);
   
   // описание типа, для информативного отображения
   static string strByType(int);
   
   // выдает список всех типов входных параметров для стратегии советника
   // need_clear_container параметр указывает на то что контейнер предварительно надо очистить
   static void getInputParams(LIntList&, bool need_clear_container = false);  
   
   //точность параметра при выводе куда-нибудь
   static int paramPresicion(int);
   
   //преобразует значение временного параметра из конфига в часы и минуты
   //применимо для параметров: exipExecTime,exipEndTime,exipMondayTime,exipFridayTime
   static void convertTimeParam(const double&, int&, int&);
   
   //преобразует значение из множества торговых операций MQL в елемент множества ExTradeOperations
   static void convertTradeOperation(int, int&);

};                         
void MQEnumsStatic::convertTradeOperation(int mq_cmd, int &cmd)
{
   cmd = -1;
   switch (mq_cmd)
   {
      case OP_BUY: {cmd = toBuy; break;}
      case OP_SELL: {cmd = toSell; break;}
      case OP_BUYSTOP: {cmd = toBuyStop; break;}
      case OP_SELLSTOP: {cmd = toSellStop; break;}
      case OP_BUYLIMIT: {cmd = toBuyLimit; break;}
      case OP_SELLLIMIT: {cmd = toSellLimit; break;}
      default: break;
   }
}
void MQEnumsStatic::convertTimeParam(const double &config_value, int &h, int &m)
{
   h = -1;
   m = -1;
   if (config_value >= 0 && config_value <= 2359)
   {
      int x = int(config_value);
      h = (x - (x%100))/100;
      m = (x - h*100);
   }
}
void MQEnumsStatic::getInputParams(LIntList &params, bool need_clear_container)
{
   if (need_clear_container) params.clear();
   params.append(exipStop);   
   params.append(exipProfit);   
   params.append(exipDist);   
   params.append(exipDecStep);   
   params.append(exipIncStep);   
   params.append(exipNBars);   
   params.append(exipNPips);   
   params.append(exipTimeFrame);      
   params.append(exipStartLot);   
   params.append(exipFixLot);   
   params.append(exipMaxErrs);   
   params.append(exipExecTime);   
   params.append(exipEndTime);   
   params.append(exipMondayTime);   
   params.append(exipFridayTime);   
   params.append(exipExecSpace);   
   params.append(exipCoupleSpace);   
   params.append(exipNextBetFactor);   
   params.append(exipStopFactor);   
   params.append(exipMaxSpread);   
   params.append(exipNextLineFactor);   
   params.append(exipSum);   
   params.append(exipPermittedPos);   

   params.append(exipTimerInterval);   
   params.append(exipSaveInterval);   
   params.append(exipSlipPips);   
   params.append(exipCommision);   
   params.append(exipMaxOrders);   
   params.append(exipTradeType);   
   params.append(exipDeviation);   
   params.append(exipExpiration);   
   params.append(exipStartPrice);   
   
   
}  
int MQEnumsStatic::paramPresicion(int type)
{
   switch (type)
   {
      case exspStep:
      case exspPrevStep:
      case exspMaxStep:
      case exspOrder:
      case exspNextOrder:
      case exspNumber:      
      case exspWinNumber:      
      case exspCWinNumber:      
      case exspTradeErrCount:
      case exspLockedCount:
      case exspLossNumber:
      case exspLastTradeCmd:
      case exspFullLossNumber:
      case exspFullWinNumber:
      case exspStopLossCount:
      case exspTakeProfitCount:
      case exspLineNumber: return 0;
      
      case exspPendingOrder:
      case exspPendingOrderBuy:
      case exspPendingOrderSell:
      case exspPendingOrderCount:
      case exspPendingOrderWorkedCount:
      case exspPendingOrderLossCount:
      case exspPendingStopLossCount:
      case exspPendingTakeProfitCount:
      case exspPendingOrderWinCount: return 0;


      case exspLotsSize:
      case exspBetsSize:
      case exspSwapSize:
      case exspResultSum:
      case exspCommisionSize: return 2;

      default: break;
   }
   
   return 1;
}
string MQEnumsStatic::shortStrByType(int type)
{
   switch (type)
   {
      case exipTimerInterval: return "timer_interval"; 
      case exipSaveInterval: return "save_interval"; 
      case exipSlipPips: return "slip_pips"; 
      case exipCommision: return "commision"; 
      case exipMaxOrders: return "max_orders"; 
      case exipTradeType: return "trade_type"; 
      case exipDeviation: return "deviation"; 
      case exipExpiration: return "expiration"; 
      case exipStartPrice: return "start_price"; 
      
      
      
      case exipStop: return "stop_pips"; 
      case exipProfit: return "profit_pips"; 
      case exipDist: return "dist"; 
      case exipDecStep: return "dec_step"; 
      case exipIncStep: return "inc_step"; 
      case exipNBars: return "nbars"; 
      case exipNPips: return "npips"; 
      case exipTimeFrame: return "time_frame"; 
      case exipStartLot: return "start_lot"; 
      case exipFixLot: return "fix_lot"; 
      case exipMaxErrs: return "max_errs"; 
      case exipExecTime: return "exec_time"; 
      case exipEndTime: return "end_time"; 
      case exipMondayTime: return "monday_time"; 
      case exipFridayTime: return "friday_time"; 
      case exipExecSpace: return "exec_space"; 
      case exipCoupleSpace: return "couple_space"; 
      
      case exipNextBetFactor: return "next_bet_factor"; 
      case exipStopFactor: return "stop_factor"; 
      case exipMaxSpread: return "max_spread"; 
      case exipNextLineFactor: return "next_line_factor"; 
      case exipSum: return "sum";
      case exipPermittedPos: return "permitted_pos";
       
      
      case exspStep: return "step"; 
      case exspPrevStep: return "prev_step"; 
      case exspMaxStep: return "max_step"; 
      case exspOrder: return "order"; 
      case exspNextOrder: return "next_order"; 
      case exspNumber: return "pos_number"; 
      case exspWinNumber: return "win_n"; 
      case exspCWinNumber: return "cwin_n"; 
      case exspWinPips: return "win_pips"; 
      case exspLossNumber: return "loss_n"; 
      case exspLastTradeCmd: return "last_cmd"; 
      case exspFullLossNumber: return "full_loss_lines"; 
      case exspFullWinNumber: return "full_win_n"; 
      case exspStopLossCount: return "stop_loss_count";
      case exspTakeProfitCount: return "take_profit_count";

      case exspLossSum: return "loss_sum"; 
      case exspLossPips: return "loss_pips"; 
      case exspCurrentSum: return "current_sum"; 
      case exspMinSum: return "min_sum"; 
      case exspMaxSum: return "max_sum"; 
      case exspResultSum: return "result_sum"; 
      case exspBetsSize: return "bets_size"; 
      case exspLotsSize: return "lots_size"; 
      case exspCommisionSize: return "commision_size"; 
      case exspSwapSize: return "swap_size"; 
      case exspLineNumber: return "lines"; 
      case exspTradeErrCount: return "trade_errs";
      case exspLockedCount: return "locked_count";
      
      case exspPendingOrder: return "pending_order";
      case exspPendingOrderBuy: return "pending_order_buy";
      case exspPendingOrderSell: return "pending_order_sell";
      case exspPendingOrderCount: return "pending_order_count";
      case exspPendingOrderWorkedCount: return "pending_order_worked_count";
      case exspPendingOrderWinCount: return "pending_order_win_count";
      case exspPendingOrderLossCount: return "pending_order_loss_count";
      case exspPendingStopLossCount: return "pending_stop_loss_count";
      case exspPendingTakeProfitCount: return "pending_take_profit_count";
      
      case toBuy: return "buy";
      case toSell: return "sell";
      case toBuyStop: return "buy_stop";
      case toSellStop: return "sell_stop";
      case toBuyLimit: return "buy_limit";
      case toSellLimit: return "sell_limit";
      case toClose: return "close";
      case toDelete: return "delete";
      
      default: break;
   }
   
   return "??";
}
string MQEnumsStatic::strByType(int type)
{
   switch (type)
   {
      case etOpenOrder: return "ошибка при открытии позиции"; 
      case etOpenNextOrder: return "ошибка при попытке выставить отложенный ордер"; 
      case etFindOrder: return "не удалось найти ордер"; 
      case etFindNextOrder: return "не удалось найти отложенный ордер"; 
      case etCloseOrder: return "ошибка при закрытии позиции"; 
      case etDeleteNextOrder: return "ошибка при удалении отложенного ордера"; 
      case etSpreadOver: return "ошибка, спред слишком большой"; 
      case etPipsOver: return "ошибка, превышено количество пунктов"; 
      case etOverOrdersCount: return "ошибка, превышено количество открытых и выставленных ордеров"; 
      
      
      case etConvertType: return "ошибка при преобразованиии типов данных"; 
      case etFileName: return "ошибка, не корректное имя файла"; 
      case etFindFile: return "ошибка, файл не найден"; 
      case etOpenFile: return "ошибка при открытии файла"; 
      case etReadFile: return "ошибка при чтении файла"; 
      case etCreateFile: return "ошибка при создании файла"; 
      case etWriteFile: return "ошибка при записи в файл"; 
      case etAppendFile: return "ошибка при добавлении в файл"; 
      case etLoadMainParams: return "ошибка при загрузке глобальных параметров советника из конфигурационного файла"; 
      case etLoadInputParams: return "ошибка при загрузке входных параметров стратегии советника из конфигурационного файла"; 
      case etConfigParamValue: return "не корректное значение конфигурационного параметра"; 
      case etLoadCouples: return "ошибка при загрузке валютных пар из конфигурационного файла"; 
      case etLoadState: return "ошибка при загрузке файла текущего состояния советника"; 
      case etSaveState: return "ошибка при сохранении файла текущего состояния советника"; 
      case etInternal: return "внутренняя ошибка при работе советника, возможно ошибка в коде"; 
      case etMqlFunc: return "ошибка при выполнении зарезервированной функции MQL"; 
      case etInvalidStateParam: return "неверный параметр состояния"; 
      
      case etConnectionStateFault: return "ошибка соединения с сервером"; 
      case etNextOrderNotPlaced: return "ошибка, отложенный ордер не был выставлен"; 
      case etNextOrderStillPlaced: return "ошибка, отложенный ордер все еще выставлен"; 
      case etAddOrderHistory: return "ошибка при добавлении ордера в историю"; 
      
      
      case etOpenOrderOk: return "позиция открылась успешно"; 
      case etOpenNextOrderOk: return "отложенный ордер выставлен успешно"; 
      case etDeleteNextOrderOk: return "отложенный ордер удален успешно"; 
      case etConnectionStateOk: return "соединение с сервером установлено успешно"; 
   
      default: break;
   }
   
   return "??";
}





