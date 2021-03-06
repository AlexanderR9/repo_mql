//+------------------------------------------------------------------+
//|                                                  exbasetrade.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/exbase.mqh>
#include <mylib/lhistory.mqh>
#include <mylib/lcalc.mqh>


//базовый советник, подрузамевающй торговлю и ведение истории ордеров


//////////////////////////////////////
class ExBaseTrade : public ExBase
{
public:
   ExBaseTrade() :ExBase() {}

   void setMagic(int);
   
   //основная функция работы советника, которая выполняется с заданным периодом 
   virtual void exec();

   // приведение любого вещественного значения лота в допустимое 
   double normalizeLot(double v) const;


protected:
   //объект для совершения торговых операций
   LTrade m_trade;
   //объект для ведения журнала торговых операций
   LTradeHistory m_history;
   //объект для расчета ставок и шагов
   LCalcSteps m_calc;
   //контейнер для подсчета ошибок по операциям и подсчета циклов для пропусков указанных пар и действий по ним
   LMapStringInt err_operations;

   //набор параметров для сохранения суммарных значений по всем парам (порядок не важен)
   virtual LIntList totalStateParams() const = 0;
   //добавить основные значения состояния всех пар в строковый список
   void addStateParamsToStringList(LStringList&);
   //добавить сумарные значения в строковый список
   void addTotalParamsToStringList(LStringList&);
   //инициализировать(при старте советника) параметры текущего состояния линии указанной пары
   virtual void initStateLine(MQMarketInfo*);


   //загрузить историю операций
   virtual void loadHistory();
   //сохранить историю операций
   virtual void saveHistory();
   
      //записать в объект m_calc текущее состояние пары
   //virtual void setStateCoupleToCalc(MQMarketInfo*) = 0;

   virtual void initCalcObj(); //иницизация объекта m_calc
   virtual void loadState(); //загрузить состояние советника из файла
   virtual void checkConfigParams();  //проверка значений параметров из конфигов  


    //признак того что текущее локальное время находится вне диапазона торговой недели.
    //если параметры exipMondayTime и exipFridayTime не заданы, то считается что ограничений нет
   bool overWeekTrade() const;
   //превышен лимит открытых и выставленных ордеров
   bool overOrdersCount() const;
   //добавление нового ордера в историю
   void addOrderHistory(int, const datetime&, const LMTPrices&);
   
   
   
   //открыть позу с заданной командой и записать тикет во 2-й параметр в случае успеха
   virtual void openPos(const LOpenPosParams&, int&);
   //выставить отложенный ордер с заданной командой и записать тикет во 2-й параметр в случае успеха
   virtual void openPendingPos(const LOpenPendingOrder&, int&);
   
   
   //закрыть позу или удалить отложенный ордер по тикету и записать код результата во 2-й параметр
   //result_code < 0 : ошибка
   //result_code == 0 : успех
   //result_code == 1 : ордер уже в истории, закрывать нечего
   virtual void closePos(int, int &result_code);
   
   
   
   //признак того, что эта операция по заданной паре в данный момент заблокирована (присутствует в контейнере err_operations)
   //параметр cmd - элемент множества ExTradeOperations
   bool operationLocked(const string&, int cmd) const;
   // отметить очередной цикл у всех заблокированных операции, при достижении необходимого количества циклов удалить операцию из err_operations
   void nextSpaceLocketOperations();
   //признак того, что не надо вести учет произошедших ошибок при торговле
   bool notOperationLocking() const {return (int(paramValue(exipCoupleSpace)) == 0);}
   
   //добавить ошибку по торговой операциии в контейнер err_operations
   //параметр cmd - элемент множества ExTradeOperations
   //параметр mq_cmd - элемент множества MQL от OP_BUY до OP_SELLSTOP
   //если параметр mq_cmd < 0, то параметр cmd берется как есть, иначе его еще нужно определить по параметру mq_cmd
   void addErrOperation(const string&, int cmd, int mq_cmd = -1);
   
   
   
   //функции для задания параметров открытия позы
   virtual double nextLot() const {return m_calc.nextLot();}
   virtual int nextStopPips() const {return int(paramValue(exipStop));} //уровень стопа в пипсах от цены открытия
   virtual int nextProfitPips() const {return int(paramValue(exipProfit));}
   virtual string commentPos(bool isPending = false) const {return fullName();}
   
   void addStateParamValue(MQMarketInfo*, int, double); //добавляет значение к указанному параметру состояния
   void addStateParamCounter(MQMarketInfo*, int);//увеличивает на единицу указанный параметр состояния




};
double ExBaseTrade::normalizeLot(double v) const
{
   double min_lot = 0.1;
   if (m_couples.count() > 0)
      min_lot = m_couples.at(0).minLot();
      
   if (min_lot <= 0) min_lot = 0.1;
   if (v < min_lot) return min_lot;
   if (v > 20) return 20;
   double lot = v*100;
   lot = MathRound(lot);
   return (lot/100);
}

//-------------------------------------------------------------
void ExBaseTrade::initStateLine(MQMarketInfo *mi)
{
   if (!mi) {Print("ExBaseTrade::initStateLine err(mi == null)"); return;}
   
   ExBase::initStateLine(mi);
   
   if (mi.state().contains(exspOrder))
      mi.insertStateParam(exspOrder, -1);    
           
   if (mi.state().contains(exspNextOrder))
      mi.insertStateParam(exspNextOrder, -1);   
      
   if (mi.state().contains(exspPendingOrder))
      mi.insertStateParam(exspPendingOrder, -1);   
}
void ExBaseTrade::addErrOperation(const string &couple, int cmd, int mq_cmd)
{
   if (notOperationLocking()) return;

   if (mq_cmd >= 0)
      MQEnumsStatic::convertTradeOperation(mq_cmd, cmd);

   int value = 0;
   string key = couple + "_" + MQEnumsStatic::shortStrByType(cmd);
   if (err_operations.contains(key)) value = err_operations.value(key);

   value++;
   err_operations.insert(key, value);

   if (value == int(paramValue(exipMaxErrs)))
   {
      int pos = m_couples.indexOf(couple);
      if (pos >= 0)
      {
         addStateParamCounter(m_couples.atVar(pos), exspLockedCount);      
      }
   }   
}
void ExBaseTrade::addStateParamsToStringList(LStringList &save_data)
{    
   int n = m_couples.count();
   for (int i=0; i<n; i++)
   {
      const MQMarketInfo *mi = m_couples.at(i);
      if (!mi)
      {
         addErr(etInternal, "ExBaseTrade::saveState() m_couples.at(i) == NULL");
         return;   
      }
      save_data.append(saveStateLine(mi));
   }
   save_data.append("");
}
void ExBaseTrade::addTotalParamsToStringList(LStringList &save_data)
{
   LIntList params = totalStateParams();
   int n = params.count();
   for (int i=0; i<n; i++)
   {
      int param = params.at(i);
      int precision = MQEnumsStatic::paramPresicion(param);
      save_data.append(MQEnumsStatic::shortStrByType(param) + "  " + DoubleToString(sumStateParam(param), precision));
   }
   save_data.append("");
}
void ExBaseTrade::exec()
{
   if (!invalid()) 
      nextSpaceLocketOperations();
      
   ExBase::exec();
}
bool ExBaseTrade::operationLocked(const string &couple, int cmd) const
{
   string s = couple + "_" + MQEnumsStatic::shortStrByType(cmd);
   if (!err_operations.contains(s)) return false;
   int value = err_operations.value(s);
   return (value > int(paramValue(exipMaxErrs)));
}
void ExBaseTrade::nextSpaceLocketOperations()
{
   if (notOperationLocking()) return;
   
   int max_errs = int(paramValue(exipMaxErrs));
   const LStringList *keys = err_operations.keys();
   int n = keys.count();
   
   for (int i=0; i<n; i++)
   {
      string key = keys.at(i);
      int value = err_operations.value(key);
      if (value > max_errs) 
      {
         value--;
         if (value == max_errs) err_operations.remove(key);
         else err_operations.insert(key, value);
      }
      else if (value == max_errs) 
      {
         value += int(paramValue(exipCoupleSpace));
         err_operations.insert(key, value);
      }
   }
}
void ExBaseTrade::openPendingPos(const LOpenPendingOrder &params, int &ticket)
{
   ticket = -1;
   int code = 0;
   
   if (overOrdersCount())
   {
      addErr(etOverOrdersCount, "try open pending: couple=" + params.couple + "  cmd=" + IntegerToString(params.type));
      return;
   }

   //////////prepare history params//////////
   datetime time_cur_server = TimeCurrent();
   LMTPrices mt_prices(params.couple);
   /////////////////////////////////////////

   m_trade.setPendingOrder(ticket, code, params); //попытка открытия
   if (code == 0) //успех
   {
      //add to history      
      addOrderHistory(ticket, time_cur_server, mt_prices);
   }
   else // ошибка
   {
      ticket = -1;
      int cmd = 0;
      MQEnumsStatic::convertTradeOperation(params.type, cmd);
      string key = params.couple + "_" + MQEnumsStatic::shortStrByType(cmd);
      addErr(code, "trade operation: [" + key + "]");
      addErrOperation(params.couple, 0, params.type);    
     
      int pos = m_couples.indexOf(params.couple);
      MQMarketInfo *mi = m_couples.atVar(pos);
      if (mi)
      {
         if (mi.state().contains(exspTradeErrCount))
            addStateParamCounter(mi, exspTradeErrCount);      
      }
   }
}
void ExBaseTrade::openPos(const LOpenPosParams &params, int &ticket)
{
   ticket = -1;
   int code = 0;
   
   if (overOrdersCount())
   {
      addErr(etOverOrdersCount, "try open: couple=" + params.couple + "  cmd=" + IntegerToString(params.type));
      return;
   }
   
   //////////prepare history params//////////
   datetime time_cur_server = TimeCurrent();
   LMTPrices mt_prices(params.couple);
   /////////////////////////////////////////

   m_trade.openPos(ticket, code, params); //попытка открытия
   if (code == 0) //успех
   {
      //add to history      
      addOrderHistory(ticket, time_cur_server, mt_prices);
   }
   else // ошибка
   {
      ticket = -1;
      int cmd = 0;
      MQEnumsStatic::convertTradeOperation(params.type, cmd);
      string key = params.couple + "_" + MQEnumsStatic::shortStrByType(cmd);
      addErr(code, "trade operation: [" + key + "]");
      addErrOperation(params.couple, 0, params.type);    
     
      int pos = m_couples.indexOf(params.couple);
      MQMarketInfo *mi = m_couples.atVar(pos);
      if (mi)
      {
         if (mi.state().contains(exspTradeErrCount))
            addStateParamCounter(mi, exspTradeErrCount);      
      }
   }
}
void ExBaseTrade::closePos(int ticket, int &result_code)
{
   int code = 0;
   LCheckOrderInfo info;
   m_trade.checkOrder(ticket, info);
   
   //ордер не найден
   if (info.isError())
   {
      string s_err = "ExBaseTrade::closePos:  ticket="+IntegerToString(ticket)+"  err_code="+IntegerToString(info.err_code);
      addErr(etFindOrder, s_err);
      result_code = etFindOrder;
      return;
   }
   
   //уже попал в историю
   if (info.isFinished() || info.isPengingCancelled())
   {
      result_code = 1;
      return;
   }
   
   string couple = OrderSymbol();
   
   //является выставленным отложенным
   if (info.isPengingNow())
   {
      m_trade.deletePendingOrder(ticket, code);
      result_code = code;
      
      if (code < 0)
      {
         string key = couple + "_" + MQEnumsStatic::shortStrByType(toDelete);
         string s_err = "ExBaseTrade::closePos: operation="+key+"  ticket=" + IntegerToString(ticket)+"";
         addErr(code, s_err);
         addErrOperation(couple, toDelete);   
      }
      
      return;
   }

   //является текущим открытым
   if (info.isOpened())
   {
      m_trade.orderClose(ticket, code);
      result_code = code;
      
      if (code < 0)
      {
         string key = couple + "_" + MQEnumsStatic::shortStrByType(toClose);
         string s_err = "ExBaseTrade::closePos: operation="+key+"  ticket=" + IntegerToString(ticket)+"";
         addErr(code, s_err);
         addErrOperation(couple, toClose);   
      }      
      
      return;
   }
   
   result_code = etInternal; //неизвестная ситуация
   string s_err = "ExBaseTrade::closePos: couple="+couple+"  ticket=" + IntegerToString(ticket)+"";
   addErr(result_code, s_err);
}
void ExBaseTrade::setMagic(int x)
{
   ExBase::setMagic(x);
   m_trade.setMagic(x);
}
void ExBaseTrade::initCalcObj()
{
   double min_lot = MarketInfo(MQValidityData::testCouple(), MODE_MINLOT);
   double start_lot = paramValue(exipStartLot);
   if (start_lot < 0)
   {
      start_lot = paramValue(exipFixLot);
      m_calc.setFixLot(true);
   }
   m_calc.setLots(start_lot, min_lot);
   
   double f = paramValue(exipNextBetFactor);
   if (f < 1) f = 1;
   m_calc.setFactor(f);
      
   int dist = int(paramValue(exipDist));
   if (dist < 1) dist = 1;
   m_calc.setDist(dist);
   
   int ds =  int(paramValue(exipDecStep, -1));
   if (ds > 0) m_calc.setDecStep(ds);
   
   m_calc.out();
  // if (m_calc.invalid()) Print("*************************");
}
void ExBaseTrade::loadHistory()
{
   string fname = fullFileName(historyFile());
   m_history.setFileName(fname);
   m_history.setDigist(int(MarketInfo(MQValidityData::testCouple(), MODE_DIGITS)));
  // Print("ExBaseTrade::loadHistory()  file name ", m_history.fileName());

   string err;
   m_history.load(err);
   if (err != "")
   {
      Print(err);
      addErr(etReadFile, err);
   }
}
void ExBaseTrade::saveHistory()
{
   string err;
   m_history.save(err);
   if (err != "")
   {
      Print(err);
      addErr(etWriteFile, err);
   }
}
bool ExBaseTrade::overWeekTrade() const
{   
   int mh, mm, fh, fm;
   double t1 = paramValue(exipMondayTime);
   double t2 = paramValue(exipFridayTime);
   MQEnumsStatic::convertTimeParam(t1, mh, mm);
   MQEnumsStatic::convertTimeParam(t2, fh, fm);
   
   return LDateTime::overWeekTrade(mh, mm, fh, fm);
}
void ExBaseTrade::addOrderHistory(int ticket, const datetime &serv_time, const LMTPrices &mt_prices)
{
      int code = 0;
      m_history.addOrder(ticket, code);
      if (code == 0)
      {
         m_history.updateSendTime(serv_time);
         double p = m_trade.lastSendPrice();
         m_history.updateSendPrice(p);
         m_history.updateMTPrices(mt_prices);
         if (m_calc.dist() > 1) m_history.setStep(m_calc.nextStep());
      }
      else addErr(etAddOrderHistory, "code="+IntegerToString(code));
}
void ExBaseTrade::loadState()
{
   string fname = fullFileName(currentStateFile());
   LStringList save_data;
   int f_lines = LFile::readFileToStringList(fname, save_data);
   if (f_lines < 0)
   {
      addErr(etReadFile, fname);
      return;
   }
      
   int n = m_couples.count();
   if (n >= save_data.count())
   {
      Print(fullName(),"::loadState(),  save_data size ", save_data.count());
      addErr(etLoadState, fname);
      return;
   }
   
   bool ok;
   for (int i=0; i<n; i++)
   {
      MQMarketInfo *mi = m_couples.atVar(i);
      if (!mi)
      {
         addErr(etInternal, fullName() + "::loadState() m_couples.at(i) == NULL");
         return;   
      }      
      loadStateLine(mi, save_data.at(i), ok);
      if (!ok) return;
   }
   
   Print("State file - ", fname, ":  loaded OK!");
}
bool ExBaseTrade::overOrdersCount() const
{
   int n = int(paramValue(exipMaxOrders));
   if (n <= 0) return false;
   
   return (OrdersTotal() >= n); 
}
void ExBaseTrade::checkConfigParams()
{
   ExBase::checkConfigParams();
   if (invalid()) return;

   checkConfigParam(exipSlipPips, m_inputParams, 0, 10, 1);
   if (invalid()) return;
   checkConfigParam(exipMaxOrders, m_inputParams, 1, 50, 1);
   if (invalid()) return;
   checkConfigParam(exipPermittedPos, m_inputParams, 150, 152, 0);
   if (invalid()) return;   
   checkConfigParam(exipMondayTime, m_inputParams, -1, 2359, 0);
   if (invalid()) return;   
   checkConfigParam(exipFridayTime, m_inputParams, -1, 2359, 0);
   if (invalid()) return;   
   checkConfigParam(exipCoupleSpace, m_inputParams, 0, 1000, 0); //сколько циклов пропускать для пары, по которой произошла ошибка при торговой операции
   if (invalid()) return;   
   checkConfigParam(exipMaxErrs, m_inputParams, 1, 7, 0);//серия ошибок подряд по какой-либо торговой операции, после чего x-циклов пропускать  
   if (invalid()) return;   
   
   m_trade.setSlip(int(paramValue(exipSlipPips)));

}
void ExBaseTrade::addStateParamValue(MQMarketInfo *mi, int type, double value)
{
   if (!mi) return;
   if (!mi.state().contains(type))
   {
      addErr(etInvalidStateParam, "ExBaseTrade::addStateParamValue: not exist state param "+IntegerToString(type)+" for "+mi.couple());
      return;
   }   
   
   double v = mi.state().value(type);
   mi.insertStateParam(type, v + value);
}
void ExBaseTrade::addStateParamCounter(MQMarketInfo *mi, int type)
{
   if (!mi) return;
   if (!mi.state().contains(type))
   {
      addErr(etInvalidStateParam, "ExBaseTrade::addStateParamCounter: not exist state param "+IntegerToString(type)+" for "+mi.couple());
      return;
   }   
   
   int v = int(mi.state().value(type));
   v++;
   mi.insertStateParam(type, v);
}









