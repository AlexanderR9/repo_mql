//+------------------------------------------------------------------+
//|                                                  takeshadows.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
#include <mygames/gamebase.mqh>
#include <mylib/inputparamsenum.mqh>
#include <mylib/lstatictrade.mqh>
#include <mylib/lexstatepanel.mqh>


struct TakeShadowsCoupleState
{
   TakeShadowsCoupleState() {reset();}
   TakeShadowsCoupleState(const TakeShadowsCoupleState &other)
   {
      step = other.step;
      max_step = other.max_step;
      buy_ticket = other.buy_ticket;
      sell_ticket = other.sell_ticket;
      closed_lots = other.closed_lots;
      win_pips = other.win_pips;
      loss_pips = other.loss_pips;
      result_sum = other.result_sum;
      sl_count = other.sl_count;
      tp_count = other.tp_count;      
      opened_orders = other.opened_orders;
      err_count = other.err_count;
      full_loss_count = other.full_loss_count;
   }
   
   int step;
   int max_step;
   int buy_ticket;
   int sell_ticket;
   double closed_lots; //сумарный размер лота закрытых ордеров
   int win_pips; //положительное значение
   int loss_pips; //отрицательное
   double result_sum; //сумарный результат по инструменту, включая коммисию и своп
   int sl_count; 
   int tp_count;
   int opened_orders;
   int err_count;
   int full_loss_count;
   
   void reset()
   {
      step = max_step = win_pips = loss_pips = 0;
      sl_count = tp_count = opened_orders = err_count = full_loss_count = 0;
      closed_lots = result_sum = 0;
      sell_ticket = buy_ticket = -1;
   }
   void updateMaxStep() {if (step > max_step) max_step = step;} 
   bool needCheck() const {return (sell_ticket > 0 || buy_ticket > 0);} //признак необходимости проверки результата ордеров
   static int paramCount() {return 13;} //количество членов этой структуры
   
   
};

//TakeShadowsCouple
class TakeShadowsCouple: public AbstractGameCouple
{
public:
   TakeShadowsCouple(string, MQErr*);
   virtual ~TakeShadowsCouple() {}

   inline void setTimesRange(const datetime &dt1, const datetime &dt2) {m_openTime = dt1; m_closeTime = dt2;}
   inline void setStops(int sl, int tp) {stop_level = sl; shadow_size = tp;}
   inline void setStepInfo(int dist, int sl, int su) {m_dist = dist; m_stepLower = sl; m_stepUpper = su;} 
   inline void setLotInfo(double lot, double f) {m_startLot = lot; m_lotFactor = f;}
   inline void setMaxCandlePips(int pips) {max_candle_pips = pips;}
   inline const TakeShadowsCoupleState state() const {return m_state;}
   
   void exec();
   
   void loadState(const string&); //загрузить состояние
   string toStateLine() const; //сформировать строку для сохранения состояния в файле
   
protected:
   datetime m_openTime; //время открытия позы
   datetime m_closeTime; //время закрытия позы, при  условии что она не была еще закрыта по стопам 
   int stop_level;
   int shadow_size;     
   int m_dist;
   int m_stepLower;
   int m_stepUpper;
   double m_startLot;
   double m_lotFactor;
   int max_candle_pips; //максимально допустимое количество пунктов на которое уже успела уйти цена еще до открытия позы, 0 значит не проверять
   
   TakeShadowsCoupleState m_state;
   MQErr *m_errObj;
   
   bool isTradeTime() const; //признак того что сейчас время открытия сделок (m_openTime + 10 минут)
   bool isCloseTime() const; //признак того что сейчас время принудительного закрытия сделок (m_closeTime + 10 минут)
   //bool isOverDayTime() const; //признак того что сейчас время вне торгового интервала сделок
   bool isBadCandle(int trade_type, int max_pips) const; //проверяет если на текущий момент уже ушла далеко в нужном направлении, ДО открытия, т.е. поезд ушел
   
   void checkOpen(); // при необходимости открыть ордера
   void checkClose(); // при необходимости закрыть ордера
   void checkResult(); // проверить результаты текущих открытых ордеров
   
   void openBuy();
   void openSell();
   void closeOrder(int);
   void checkOrder(int&);
   
   void addErr(int enum_code, int err_code = 0);
   double nextLot() const;
   string comment() const;
   
private:
   inline bool canBuy() const {return (IP_ConvertClass::canTradeOnlyBuy(m_tradeType) || IP_ConvertClass::canTradeAll(m_tradeType));}
   inline bool canSell() const {return (IP_ConvertClass::canTradeOnlySell(m_tradeType) || IP_ConvertClass::canTradeAll(m_tradeType));}
   inline bool canTradeAll() const {return (canBuy() && canSell());}
   inline void resetLast() {last_result_buy = 0; last_result_sell = 0;}
   
   double last_result_buy; //последний результат работы ордера типа buy (в валюте счета)
   double last_result_sell; //последний результат работы ордера типа sell (в валюте счета)
   void analizeResult(); //анализировать последний результат

};
TakeShadowsCouple::TakeShadowsCouple(string v, MQErr *err) 
   :AbstractGameCouple(v), 
   m_errObj(err) 
{
   setPeriod(PERIOD_D1); 
   resetLast();
   max_candle_pips = 0;
}
void TakeShadowsCouple::exec()
{
   Print("TakeShadowsCouple::exec() for ", m_symbol);
   ResetLastError();
   if (m_state.step < 1) m_state.step = 1;
   
   if (isTradeTime()) checkOpen();
   else if (isCloseTime()) checkClose();
   else checkResult();
}
void TakeShadowsCouple::loadState(const string &f_line)
{
   LDoubleList list;
   AbstractGame::parseStateFileLine(f_line, list);
   if (list.count() != m_state.paramCount()) {Print("TakeShadowsCouple::loadState ERR invalid state line params count"); return;}

   int i = 0;
   m_state.step = int(list.at(i));              i++;
   m_state.max_step = int(list.at(i));          i++;
   m_state.buy_ticket = int(list.at(i));        i++;
   m_state.sell_ticket = int(list.at(i));       i++;
   m_state.closed_lots = list.at(i);            i++;
   m_state.win_pips = int(list.at(i));          i++;
   m_state.loss_pips = int(list.at(i));         i++;
   m_state.result_sum = list.at(i);             i++;   
   m_state.sl_count = int(list.at(i));          i++;
   m_state.tp_count = int(list.at(i));          i++;
   m_state.opened_orders = int(list.at(i));     i++;
   m_state.err_count = int(list.at(i));         i++;
   m_state.full_loss_count = int(list.at(i));   i++;
}
string TakeShadowsCouple::toStateLine() const
{
   LDoubleList values;
   LIntList precisions;
   
   values.append(m_state.step);              precisions.append(0);
   values.append(m_state.max_step);          precisions.append(0);
   values.append(m_state.buy_ticket);        precisions.append(0);
   values.append(m_state.sell_ticket);       precisions.append(0);
   values.append(m_state.closed_lots);       precisions.append(2);
   values.append(m_state.win_pips);          precisions.append(0);
   values.append(m_state.loss_pips);         precisions.append(0);
   values.append(m_state.result_sum);        precisions.append(4);
   values.append(m_state.sl_count);          precisions.append(0);
   values.append(m_state.tp_count);          precisions.append(0);
   values.append(m_state.opened_orders);     precisions.append(0);
   values.append(m_state.err_count);         precisions.append(0);
   values.append(m_state.full_loss_count);   precisions.append(0);
      
   return AbstractGame::toStateFileLine(values, precisions);
}
double TakeShadowsCouple::nextLot() const
{
   double lot = m_startLot;
   if (m_state.step > 1)
      lot *= MathPow(m_lotFactor, m_state.step - 1);
   return NormalizeDouble(lot, 2);   
}
void TakeShadowsCouple::addErr(int enum_code, int err_code)
{
   string other = m_symbol;
   if (err_code != 0) other += StringConcatenate(" err_code=", err_code);
   switch(enum_code)
   {
      case etSpreadOver: {other += StringConcatenate(" spread=", MarketInfo(m_symbol, MODE_SPREAD)); break;}
      case etPipsOver: {other += StringConcatenate(" pips=", LBar::size(m_symbol, m_period, 0)); break;}
      
      
      default: break;
   }
   
   if (m_errObj) 
      m_errObj.appendError(enum_code, other);
      
   m_state.err_count++;
}
void TakeShadowsCouple::checkOpen()
{
  // Print("TakeShadowsCouple::checkOpen()");
   if (canBuy() && m_state.buy_ticket < 0) openBuy();
   if (canSell() && m_state.sell_ticket < 0) openSell();
   
   resetLast();
   m_state.updateMaxStep();
}
void TakeShadowsCouple::checkClose()
{
   bool need_check = false;
   if (m_state.sell_ticket > 0) {need_check = true; closeOrder(m_state.sell_ticket);}
   if (m_state.buy_ticket > 0) {need_check = true; closeOrder(m_state.buy_ticket);}
   
   if (need_check) checkResult();
}
void TakeShadowsCouple::checkResult()
{
   if (!m_state.needCheck()) return;
   
   if (m_state.buy_ticket > 0) checkOrder(m_state.buy_ticket);
   if (m_state.sell_ticket > 0) checkOrder(m_state.sell_ticket);
   if (!m_state.needCheck()) analizeResult();
}
void TakeShadowsCouple::analizeResult()
{
   double r = (last_result_buy + last_result_sell)/OrderLots();
   int r_pips = int(r*MathPow(10, MarketInfo(m_symbol, MODE_DIGITS)));
   int k = (AbstractGame::isTerminalFive() ? 10 : 1);
   if (MathAbs(r_pips) < 3*k) {Print(m_symbol,": has null result!!!"); return;} //позиция около нулевая

   if (r > 0) m_state.step -= m_stepLower; 
   else
   {
      m_state.step += m_stepUpper;   
      if (m_dist > 1 && m_state.step > m_dist)
      {
         m_state.step = 1;
         m_state.full_loss_count++;
      }
   }

   if (m_dist <= 1 || m_state.step <= 1) 
      m_state.step = 1;
}
void TakeShadowsCouple::checkOrder(int &ticket)
{
   LCheckOrderInfo info;
   LStaticTrade::checkOrderState(ticket, info);
   if (info.isError())
   {
       addErr(etFindOrder, info.err_code);
       ticket = -1;  
   }
   else if (info.isFinished())
   {
      m_state.closed_lots += OrderLots();
      m_state.result_sum += info.totalResult();
      if (info.closed_by_stoploss) m_state.sl_count++;
      if (info.closed_by_takeprofit) m_state.tp_count++;
      
      if (ticket == m_state.buy_ticket) last_result_buy = info.totalResult();
      else last_result_sell = info.totalResult();
      if (info.isWin()) m_state.win_pips += int(info.result_pips);
      else m_state.loss_pips += int(info.result_pips);
      ticket = -1;    
   }
}
bool TakeShadowsCouple::isTradeTime() const
{
   datetime dt = TimeLocal();
   int h_loc = TimeHour(dt);
   int min_loc = TimeMinute(dt);
   int h_open = TimeHour(m_openTime);
   int min_open = TimeMinute(m_openTime);
   int d_loc = h_loc*60 + min_loc;
   int d_open = h_open*60 + min_open;
   
   //Print("h_loc(", h_loc, "):min_loc(", min_loc, "),  d_loc=",d_loc );
   //Print("h_open(", h_open, "):min_open(", min_open, "),  d_open=",d_open );
   
   if (d_loc < d_open) return false;
   if (d_loc > (d_open + 10)) return false;
   
   return true;
}
bool TakeShadowsCouple::isCloseTime() const
{
   datetime dt = TimeLocal();
   int h_loc = TimeHour(dt);
   int min_loc = TimeMinute(dt);
   int h_close = TimeHour(m_closeTime);
   int min_close = TimeMinute(m_closeTime);
   int d_loc = h_loc*60 + min_loc;
   int d_close = h_close*60 + min_close;
   
   if (d_loc < d_close) return false;
   if (d_loc > (d_close + 10)) return false;
   
   return true;
}
void TakeShadowsCouple::openBuy()
{
   if (spreadOver()) {addErr(etSpreadOver); return;}
   if (isBadCandle(OP_BUY, max_candle_pips)) {addErr(etPipsOver); return;}
   
   LOpenPosParams params(m_symbol, nextLot(), OP_BUY);
   params.slip = m_slip;
   params.comment = comment();
   params.setStops(stop_level, shadow_size, true);
   
   LStaticTrade::tryOpenPos(m_state.buy_ticket, params);
   if (params.isError()) addErr(etOpenOrder, params.err_code);
   else m_state.opened_orders++;
}
void TakeShadowsCouple::openSell()
{
   if (spreadOver()) {addErr(etSpreadOver); return;}
   if (isBadCandle(OP_SELL, max_candle_pips)) {addErr(etPipsOver); return;}
   
   LOpenPosParams params(m_symbol, nextLot(), OP_SELL);
   params.slip = m_slip;
   params.comment = comment();
   params.setStops(stop_level, shadow_size, true);
   
   LStaticTrade::tryOpenPos(m_state.sell_ticket, params);
   if (params.isError()) addErr(etOpenOrder, params.err_code);
   else m_state.opened_orders++;
}
void TakeShadowsCouple::closeOrder(int ticket)
{
   int err_code = 0;
   LStaticTrade::tryOrderClose(ticket, err_code, m_slip);
   if (err_code < 0) addErr(etCloseOrder, err_code);
}
string TakeShadowsCouple::comment() const
{
   string s = "takeshadows";
   s += StringConcatenate(" step=", m_state.step, "/", m_dist);
   return s;
}
bool TakeShadowsCouple::isBadCandle(int trade_type, int max_pips) const
{
   if (max_pips <= 0) return false;
   int cur_size = LBar::size(m_symbol, m_period, 0);
   if (cur_size < max_pips) return false;
   
   switch (trade_type)
   {
      case OP_BUY: return LBar::isUp(m_symbol, m_period, 0);
      case OP_SELL: return LBar::isDown(m_symbol, m_period, 0);
      default: break;
   }
   return false;
}


//TakeShadowsGame
class TakeShadowsGame: public AbstractGame
{
public:
   TakeShadowsGame() :AbstractGame() {exec_index = -1;}
   virtual ~TakeShadowsGame() {clear();}

   virtual void exInit();//выполнить инициализацию (загрузка всех конфигов и состояний)   
   virtual void exDeinit();

   inline int count() const {return ArraySize(m_objs);}
   inline bool isEmpty() const {return (count() == 0);}
   inline int mainTimerInterval() const {return int(m_inputParams.value(exipTimerInterval));}
   inline string workingFolder() const {return fullName();}

   void addSymbol(const string v); //создать новый объект TakeShadowsCouple и добавить в контейнер m_objs, v необходимо задать корректно
   void setTimesRange(const datetime&, const datetime&); //установить время открытия/закрытия позиций
   
protected:
   TakeShadowsCouple* m_objs[]; //набор инструментов по которым ведется работа
   LExStatePanel *m_statePanel; //панель для отображения текущего состояния
   int exec_index;

   void clear(); //очистить контейнер m_objs
   string name() const {return "takeshadows";}
   void work(); //выполнить сценарий алгоритма конкретной стратегии (основная функция)
   void saveState(); //сохранить состояние советника
   void loadState(); //загрузить состояние советника
   void loadInputParams(); //загрузить входные параметры советника
   void initStatePanel(); //создать графическую панель состояния
   void updateStatePanel(int i); //обновить графическую панель состояния по заданному инструменту

};
void TakeShadowsGame::exInit()
{
   AbstractGame::exInit();
   initStatePanel();
}
void TakeShadowsGame::exDeinit()
{
   AbstractGame::exDeinit();
   clear();
}
void TakeShadowsGame::work()
{
   //Print("TakeShadowsGame::work()");
   if (isEmpty()) return;
   
   exec_index++;
   if (exec_index >= count()) exec_index = 0;
   
   m_objs[exec_index].exec();
   updateStatePanel(exec_index);
}
void TakeShadowsGame::updateStatePanel(int i)
{
   if (!m_statePanel) return;
   TakeShadowsCoupleState state(m_objs[i].state());
   
   LStringList values;
   values.append(IntegerToString(state.step));
   values.append(IntegerToString(state.max_step));
   values.append(DoubleToStr(state.closed_lots, 2));
   values.append(IntegerToString(state.win_pips));
   values.append(IntegerToString(state.loss_pips));
   values.append(DoubleToStr(state.result_sum, 3));
   values.append(IntegerToString(state.opened_orders));
   values.append(IntegerToString(state.sl_count));
   values.append(IntegerToString(state.tp_count));
   values.append(IntegerToString(state.full_loss_count));
   values.append(IntegerToString(state.err_count));
   
   m_statePanel.updateParamsByCouple(m_objs[i].symbol(), values);
}
void TakeShadowsGame::initStatePanel()
{   
   LStringList symbols;
   int n = count();
   for (int i=0; i<n; i++) 
      symbols.append(m_objs[i].symbol());
   
   LStringList state_params;
   state_params.append("Step");              //col 0
   state_params.append("Max step");          //col 1
   state_params.append("Lots");              //col 2
   state_params.append("Win pips");          //col 3
   state_params.append("Loss pips");         //col 4
   state_params.append("Result sum");        //col 5
   state_params.append("Orders");            //col 6
   state_params.append("S/L");               //col 7
   state_params.append("T/P");               //col 8
   state_params.append("Full loss");         //col 9
   state_params.append("Errors");            //col 10
   
   m_statePanel = new LExStatePanel(fullName());
   m_statePanel.initPanel(symbols, state_params);
   
   m_statePanel.setPrecision(2, 2);
   m_statePanel.setPrecision(5, 1);
   
   m_statePanel.setTotalOperation(0, totNone);
   m_statePanel.setTotalOperation(1, totMax);
   
   
}
void TakeShadowsGame::loadInputParams()
{
   if (isEmpty()) return;
   Print("TakeShadowsGame::loadInputParams()");

   int n = count();
   int dig_factor = (isTerminalFive() ? 10 : 1);
   for (int i=0; i<n; i++)
   {
      m_objs[i].setMagic(m_magic);
      m_objs[i].setSlip(dig_factor*int(m_inputParams.value(exipSlipPips)));
      m_objs[i].setMaxSpread(dig_factor*int(m_inputParams.value(exipMaxSpread)));
      m_objs[i].setTradeType(int(m_inputParams.value(exipPermittedPos)));
      m_objs[i].setLotInfo(m_inputParams.value(exipStartLot), m_inputParams.value(exipNextBetFactor));
      
      int sl = dig_factor*int(m_inputParams.value(exipStop));
      int tp = dig_factor*int(m_inputParams.value(exipProfit));
      m_objs[i].setStops(sl, tp);
      
      int dist = int(m_inputParams.value(exipDist));
      int step_lower = int(m_inputParams.value(exipDecStep));
      int step_upper = int(m_inputParams.value(exipIncStep));
      m_objs[i].setStepInfo(dist, step_lower, step_upper);
      
      int mcp = int(m_inputParams.value(exipNPips));
      m_objs[i].setMaxCandlePips(mcp*dig_factor);
   }
   
   is_valid = true;
}
void TakeShadowsGame::clear()
{
   if (!isEmpty())
   {
      int n = count();
      for (int i=0; i<n; i++)
         delete m_objs[i];
   }
   ArrayFree(m_objs);
   
   if (m_statePanel)
   {
      delete m_statePanel;
      m_statePanel = NULL;
   }
}
void TakeShadowsGame::addSymbol(const string v)
{
   int n = count();
   ArrayResize(m_objs, n+1);
   m_objs[n] = new TakeShadowsCouple(v, &m_err);;
}
void TakeShadowsGame::setTimesRange(const datetime &dt1, const datetime &dt2)
{
   if (isEmpty()) return;
   int n = count();
   for (int i=0; i<n; i++)
      m_objs[i].setTimesRange(dt1, dt2);
}
void TakeShadowsGame::saveState()
{
   if (isEmpty()) return;
   
   LStringList save_state_data;
   int n = count();
   for (int i=0; i<n; i++)
      save_state_data.append(m_objs[i].toStateLine());
      
   string fname = fullFileName(stateFile());
   LFile::stringListToFile(fname, save_state_data);
}
void TakeShadowsGame::loadState()
{
   if (isEmpty()) return;
   
   string fname = fullFileName(stateFile());
   if (!LFile::isFileExists(fname)) {addErr(etLoadState); return;}
   
   LStringList state_data;
   if (LFile::readFileToStringList(fname, state_data) < 0) {addErr(etReadFile, fname); return;}
   if (state_data.count() < count()) {addErr(etLoadState, "invalid statefile lines count"); return;}
   
   int n = count();
   for (int i=0; i<n; i++)
   {
      string f_line = state_data.at(i);
      m_objs[i].loadState(f_line);   
   }
}




