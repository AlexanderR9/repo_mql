//+------------------------------------------------------------------+
//|                                                       exbase.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/base.mqh>
#include <mylib/lcoupleinfo.mqh>
#include <mylib/lerr.mqh>



// ExBase
class ExBase
{
public:
   ExBase() :is_valid(false), m_magic(-1) {}

   //выполнить инициализацию (загрузка всех конфигов и состояний)   
   virtual void exInit();
   //завершить работу
   virtual void exDeinit();
   //основная функция работы советника, которая выполняется с заданным периодом 
   virtual void exec();
   
   inline bool invalid() const {return !is_valid;}
   virtual void setMagic(int v) {m_magic = v;}   
   static int errStateValue() {return - 2;} 
   
   //вернуть значение параметра из контейнеров m_inputParams или m_mainParams
   double paramValue(int, double defValue = -1) const;
   //выхлоп считанных их конфигов названий пар и значений входных параметров советника, отладочная функция
   void outLoadedConfigValues();
   //выхлоп значений текущего состояния линии по всем парам, отладочная функция
   void outStateParams();
   
   
protected:
   bool is_valid;
   int m_magic;
   datetime last_save_time;

   //входные параметры для работы советника
   LMapIntDouble m_inputParams;   
   //набор валютных пар и дополнительная информация по каждой из них
   MQMarketInfoList m_couples;
   //счетчик ошибок сетевого соединения с сервером   
   MQConnectionState m_connectionState;
   //счетчик ошибок при работе советника
   MQErr m_err;
   
   //проверка корректности значений загруженных параметров из конфигов и их состав
   virtual void checkConfigParams();   
   //загрузить конфиги
   virtual void loadConfigs();
   //загрузить историю операций
   virtual void loadHistory() {}
   //сохранить историю операций
   virtual void saveHistory() {}
   //инициализировать объект расчетов
   virtual void initCalcObj() {}
   //сохранить состояние советника
   virtual void saveState() = 0;
   //загрузить состояние советника
   virtual void loadState() = 0;
   //набор параметров для хранения текущего состояния линии каждой пары
   virtual LIntList lineStateParams() const = 0;
   //сформировать строку для сохранения текущего состояния линии указанной пары
   virtual string saveStateLine(const MQMarketInfo*) const;
   //загрузить значения параметров текущего состояния линии указанной пары из строки
   virtual void loadStateLine(MQMarketInfo*, const string, bool&);
   //инициализировать набор параметров для отслеживания текущего состояния работы, для всех пар
   virtual void initStateParams();
   //инициализировать(обычно при старте советника) параметры текущего состояния линии указанной пары
   virtual void initStateLine(MQMarketInfo*);
   //выполнить сценарий алгоритма конкретной стратегии
   virtual void work() = 0;
   //имя советника
   virtual string name() const {return "ex_base";}
   //сумарное значение указанного параметра состояния по всем парам
   virtual double sumStateParam(int) const;
   //максимальное значение указанного параметра состояния по всем парам
   virtual double maxStateParam(int) const;
   //сумарное значение указанного параметра состояния по всем парам в виде строки для записи в файл
   //если header пустая строка, то в качестве заголовка значения будет MQEnumsStatic::shortStrByType(type)
   virtual string strSumStateParam(int, string header = "") const;
   //возвращает индекс пары в контейнере m_couples
   virtual int coupleIndex(MQMarketInfo*) const;
   
   //формирует строку с параметрами текущего состояния линии указанной пары (для выхлопа, отладочная функция)
   string stateParamsLineToString(int) const;
   
  

   //инициализация объекта m_connectionState
   void initConnStateObj();
   //инициализация объекта m_err
   void initErrObj();
   //чтение файла couplesFile() и инициализация контейнера m_couples
   void initCouples();
   //вернуть полный путь файла (fullName()/fname)
   string fullFileName(const string) const;   
   // проверить корректность значения заданного параметра
   void checkConfigParam(int, const LMapIntDouble&, double, double, int precision = 2);   
   // в файл протокола добавляется сообщение об ошибке
   void addErr(int, string other = ""); 
   
   //полное уникальное имя советника (name()+magic)
   string fullName() const;
   void checkExDir();
      
      
   //рабочие файлы советника   
   inline string inputParamsFile() const {return "input_params.txt";}
   inline string couplesFile() const {return "couples.txt";}
   inline string currentStateFile() const {return "state.txt";}
   inline string historyFile() const {return "history.txt";}
   inline string errorsFile() const {return "errors.txt";}
   inline string connectionFile() const {return "connection_errors.txt";}

   
};
int ExBase::coupleIndex(MQMarketInfo *mi) const
{
   if (!mi) return -1;
   return m_couples.indexOf(mi.couple());
}
string ExBase::strSumStateParam(int param, string header) const
{
   string line = (header != "") ? header : MQEnumsStatic::shortStrByType(param);
   int precision = MQEnumsStatic::paramPresicion(param); 
   double sum = sumStateParam(param);
   line += ("  " + DoubleToString(sum, precision));
   return line;
}
double ExBase::sumStateParam(int param) const
{
   double s = 0;
   int n = m_couples.count();
   for (int i=0; i<n; i++)
   {
      const MQMarketInfo *mi = m_couples.at(i);
      if (!mi) return -9999;
      if (mi.invalid()) return -9998;
      
      const LMapIntDouble* state = mi.state();
      if (!state) return -9997;
      
      s += state.value(param, 0);
   }
   
   return s;
}
double ExBase::maxStateParam(int param) const
{
   double max = -1;
   int n = m_couples.count();
   for (int i=0; i<n; i++)
   {
      const MQMarketInfo *mi = m_couples.at(i);
      if (!mi) return -9999;
      if (mi.invalid()) return -9998;
      
      const LMapIntDouble* state = mi.state();
      if (!state) return -9997;
      
      double v = state.value(param, 0);
      if (v > max) max = v;
   }
   
   return max;
}
void ExBase::outStateParams()
{
   Print("");
   int n = m_couples.count();
   if (n == 0) return;
   
   for (int i=0; i<n; i++)
      Print(stateParamsLineToString(i));
   
   Print("----------------- STATE LINES -------------------");
   Print("");

}
string ExBase::stateParamsLineToString(int index) const
{
   string s;
   const MQMarketInfo *mi = m_couples.at(index);
   if (!mi) {Print("ExBase::outStateParamsLine"); return s;}
   if (mi.invalid()) {Print("ExBase::outStateParamsLine"); return s;}
   
   const LMapIntDouble* state = mi.state();
   if (!state) {Print("ExBase::outStateParamsLine err(mi.state() == null)"); return s;}

   s = "State " + mi.couple() + ": ";
   LIntList state_params = lineStateParams();
   int n = state_params.count();
   for (int i=0; i<n; i++)
   {
      int param = state_params.at(i);
      int precision = MQEnumsStatic::paramPresicion(param);
      string p_name =  MQEnumsStatic::shortStrByType(param);
      double value = state.value(param, errStateValue());
      s += " " + p_name + "=" + DoubleToString(value, precision);
   }   
   
   return s;
}
void ExBase::initStateLine(MQMarketInfo *mi)
{
   if (!mi) {Print("ExBase::initStateLine err(mi == null)"); return;}
   if (mi.invalid()) {Print("ExBase::initStateLine err(mi.invalid())"); return;}

   LIntList state_params = lineStateParams();
   int n = state_params.count();
   for (int i=0; i<n; i++)
      mi.insertStateParam(state_params.at(i), 0);
}
void ExBase::loadStateLine(MQMarketInfo *mi, const string line, bool &ok)
{
   ok = false;
   if (!mi) {Print("ExBase::loadStateLine err(mi == null)"); return;}
   if (mi.invalid()) {Print("ExBase::loadStateLine err(mi.invalid())"); return;}
   
   const LMapIntDouble* state = mi.state();
   if (!state) {Print("ExBase::loadStateLine err(mi.state() == null)"); return;}

   LStringList slist;
   slist.splitFromString(line, LFile::splitSymbol());
   
   LIntList state_params = lineStateParams();
   int n = state_params.count();
   if (n != (slist.count()-1)) {Print("ExBase::loadStateLine err(invalid param count in line)"); return;}
   
   for (int i=0; i<n; i++)
   {
      int param = state_params.at(i);
      double value = StringToDouble(slist.at(i+1));
      mi.insertStateParam(param, value);
   }   
   
   ok = true;
}
string ExBase::saveStateLine(const MQMarketInfo *mi) const
{
   string s;
   if (!mi) {s = "ExBase::saveStateLine err(mi == null)"; return s;}
   if (mi.invalid()) {s = "ExBase::saveStateLine err(mi.invalid())"; return s;}
   
   const LMapIntDouble* state = mi.state();
   if (!state) {s = "ExBase::saveStateLine err(mi.state() == null)"; return s;}
   
   LIntList state_params = lineStateParams();
   int n = state_params.count();
   if (n == 0) return s;
   
   s = mi.couple(); 
   s += LFile::splitSymbol();
   
   
   //state_param1 * state_param2 * state_param3 ......
   for (int i=0; i<n; i++)
   {
      int param = state_params.at(i);
      int precision = MQEnumsStatic::paramPresicion(param);
      if (precision == 0) s += IntegerToString(int(state.value(param, 0)));
      else s += DoubleToString(state.value(param, 0), precision);
      if (i < (n-1)) s += LFile::splitSymbol();
   }
   
   return s;
}
void ExBase::outLoadedConfigValues()
{
   Print("");
   Print("///////////// couples count "+IntegerToString(m_couples.count())+"///////////////");
   for (int i=0; i<m_couples.count(); i++)
      Print(m_couples.at(i).couple());
      
      
     /* 
   Print("");
   Print("///////////// main params count "+IntegerToString(m_mainParams.count())+"///////////////");
   const LIntList *keys = m_mainParams.keys();
   for (int i=0; i<keys.count(); i++)
      Print(MQEnumsStatic::shortStrByType(keys.at(i))+" = "+DoubleToString(m_mainParams.value(keys.at(i)), 2));
      */
      
   Print("");
   Print("///////////// input params count "+IntegerToString(m_inputParams.count())+"///////////////");
   const LIntList *keys = m_inputParams.keys();
   for (int i=0; i<keys.count(); i++)
      Print(MQEnumsStatic::shortStrByType(keys.at(i))+" = "+DoubleToString(m_inputParams.value(keys.at(i)), 2));

   Print("");
}
void ExBase::initStateParams()
{
   int n = m_couples.count();
   for (int i=0; i<n; i++)
   {
      initStateLine(m_couples.atVar(i));
   }
   
   last_save_time = TimeLocal();
}
void ExBase::exec()
{
   if (invalid())
   {
      Print("Expert "+fullName()+" is incorrect, impossible running.");
      return;      
   }
   
   if (LDateTime::dTime(last_save_time, TimeLocal()) > paramValue(exipSaveInterval, 600))
   {
      Print("Expert "+fullName()+" try save state ........");
      saveState();
      saveHistory();
      last_save_time = TimeLocal();
      return;
   }
   
   m_connectionState.checkState();
   if (m_connectionState.curStateOk())
      work();
}
double ExBase::paramValue(int type, double defValue = -1) const
{
   //if (m_mainParams.contains(type))
      //return m_mainParams.value(type);
   if (m_inputParams.contains(type))
      return m_inputParams.value(type);
   return defValue;
}
/*
void ExBase::addErrCount(MQMarketInfo *mi)
{
   if (!mi) return;
   if (!mi.state()) return;
   if (!mi.state().contains(exspErrCount)) return;
   
   int n = int(mi.state().value(exspErrCount));
   mi.insertStateParam(exspErrCount, n+1);
}
*/
void ExBase::addErr(int err_code, string other)
{
   m_err.appendError(err_code, other);
   string s = "ERR: " + MQEnumsStatic::strByType(err_code);
   if (other != "") s += (" (" + other + ")");
   Print(name(), "   ", s);
}
string ExBase::fullName() const
{
   if (m_magic > 0) 
      return (name()+IntegerToString(m_magic));    
   return name();
}
string ExBase::fullFileName(const string fname) const
{
   if (StringLen(fname) < 5) 
   {
      Print("ExBase::fullFileName error file name - ", fname);
      return "";
   }
   
   return (fullName()+"/"+fname);    
}
void ExBase::checkConfigParam(int param, const LMapIntDouble &map, double min, double max, int precision)
{
   if (!map.contains(param))
   {
      string s = MQEnumsStatic::shortStrByType(param)+" not found";
      addErr(etConfigParamValue, s); 
      is_valid = false;
      return;
   }

   double v = map.value(param);
   if (v < min)
   {
      string s = MQEnumsStatic::shortStrByType(param)+"   "+DoubleToString(v, precision)+" < "+DoubleToString(min, precision);
      addErr(etConfigParamValue, s); 
      is_valid = false;
      return;
   }
   if (v > max)
   {
      string s = MQEnumsStatic::shortStrByType(param)+"   "+DoubleToString(v, precision)+" > "+DoubleToString(max, precision);
      addErr(etConfigParamValue, s); 
      is_valid = false;
      return;
   }

   is_valid = true;
}
void ExBase::checkConfigParams()
{
   checkConfigParam(exipTimerInterval, m_inputParams, 3, 300, 1);
   if (invalid()) return;

   checkConfigParam(exipSaveInterval, m_inputParams, 20, 3600, 1);
   if (invalid()) return;

   checkConfigParam(exipTimeFrame, m_inputParams, 1, 10080, 1);
   if (invalid()) return;

}
void ExBase::checkExDir()
{
   is_valid = true;
}
void ExBase::loadConfigs()
{
   checkExDir();
   if (invalid()) return;

   initCouples();
   if (invalid()) return;

/*
   string fname = fullFileName(mainParamsFile());
   bool ok = LFile::loadParams(fname, m_mainParams);
   if (!ok)
   {
      is_valid = false;
      addErr(etLoadMainParams, fname);
      return;
   }
   else Print("Load config file - ", fname, ", OK!");
   */
   
   string fname = fullFileName(inputParamsFile());
   bool ok = LFile::loadParams(fname, m_inputParams);
   if (!ok)
   {
      is_valid = false;
      addErr(etLoadInputParams, fname);
      return;
   }
   else Print("Load config file - ", fname, ", OK!");
   
   is_valid = true;     
}
void ExBase::initCouples()
{
   //string arr[50];
   LStringList data;
   string fname = fullFileName(couplesFile());
   int result = LFile::readFileToStringList(fname, data);
   if (result < 0)
   {
      is_valid = false;
      addErr(etLoadCouples, fname);
      return;
   }
   else Print("Load config file - ", fname, ", OK!");
   
   //init container
   int n = data.count();
   for (int i=0; i<n; i++)
   {
      string coup = data.at(i);
      coup = StringTrimLeft(coup);
      coup = StringTrimRight(coup);
      if (coup == "") continue;
      if (StringSubstr(coup, 0, 1) == "#") continue;
      
      if (!MQValidityData::isValidCouple(coup))
      {
         Print("ExBase::initCouples() - ERR invalid couple ", coup);
         continue;
      }
 
      m_couples.append(coup);
   }   

   //check container
   n = m_couples.count();
   if (n == 0)
   {
      is_valid = false;
      addErr(etLoadCouples, "couples is empty");
      return;   
   }

   for (int i=0; i<n; i++)
   {
      const MQMarketInfo *mi = m_couples.at(i);
      if (!mi)
      {
         is_valid = false;
         addErr(etLoadCouples, "couple["+IntegerToString(i)+"] is NULL");
         return;   
      }
      
      if (mi.invalid())
      {
         is_valid = false;
         addErr(etLoadCouples, "couple "+mi.couple()+" is invalid");
         return;   
      }      
   }

   is_valid = true;        
}
void ExBase::initConnStateObj()
{
   string fname = fullFileName(connectionFile());
   m_connectionState.setProtocolFileName(fname);
   m_connectionState.expertInit();
}
void ExBase::initErrObj()
{
   string fname = fullFileName(errorsFile());
   m_err.setProtocolFileName(fname);
   m_err.load();   
}
void ExBase::exInit()
{
   initErrObj();
   initConnStateObj();
   
   loadConfigs();
   if (invalid()) return;
       
   checkConfigParams();
   if (invalid()) return;

   loadHistory();
   if (invalid()) return;
   
   initCalcObj();
   initStateParams();
   loadState();
}
void ExBase::exDeinit()
{
   m_connectionState.expertDeinit();
   if (invalid()) return;
   saveState();
}



/*
// ExSpring
class ExSpring : public ExBase
{
public:
   ExSpring() :ExBase()  {}
   
protected:
   void work();   
   void checkConfigParams();   
   void resetState(int);
   void saveState();
   void loadState();
   void loadStateLine(int, const string&);
   string name() const {return "ex_spring";}

   void updateStateParam(MQMarketInfo*, int, const string);
   void getStateParamsList(LIntList&);

};
void ExSpring::getStateParamsList(LIntList &list)
{
   list.clear();
   list.append(exspOrder);
   list.append(exspNextOrder);
   list.append(exspStep);
   list.append(exspCWinNumber);
   list.append(exspFullLossNumber);
   list.append(exspLotsSize);   
}
void ExSpring::resetState(int index)
{
   MQMarketInfo *mi = m_couples.atVar(index);
   if (!mi) return;

   LIntList list;
   getStateParamsList(list);
   
   int n = list.count();
   for (int i=0; i<n; i++)
      mi.insertStateParam(list.at(i), 0);

   mi.insertStateParam(exspOrder, -1);
   mi.insertStateParam(exspNextOrder, -1);
}
void ExSpring::work()
{
   Print("******* "+fullName()+" work ***********");
}
void ExSpring::checkConfigParams()
{
   ExBase::checkConfigParams();
   if (invalid()) return;

   checkConfigParam(exmpSlipPips, m_mainParams, 0, 10, 1);
   if (invalid()) return;
   checkConfigParam(exmpCommision, m_mainParams, -5, 5, 1);
   if (invalid()) return;
   checkConfigParam(exmpMaxOrders, m_mainParams, 1, 50, 1);
   if (invalid()) return;
   
   checkConfigParam(exipStop, m_inputParams, 5, 500, 1);
   if (invalid()) return;
   checkConfigParam(exipProfit, m_inputParams, 5, 500, 1);
   if (invalid()) return;
   checkConfigParam(exipDist, m_inputParams, 1, 50, 1);
   if (invalid()) return;
   checkConfigParam(exipStartLot, m_inputParams, 0.01, 10, 2);
   if (invalid()) return;
   
   checkConfigParam(exipNBars, m_inputParams, 1, 20, 1);
   if (invalid()) return;
   checkConfigParam(exipNPips, m_inputParams, 0, 500, 1);
   if (invalid()) return;
   checkConfigParam(exipNextBetFactor, m_inputParams, 1, 3.5, 2);
   if (invalid()) return;   
}
void ExSpring::saveState()
{
   int n = m_couples.count();
   string arr[50];
   
   int n_cwin = 0;
   int n_fl = 0;
   double lots = 0;
   
   
   LIntList p_list;
   getStateParamsList(p_list);
   int np = p_list.count();

   
   for (int i=0; i<n; i++)
   {
      const MQMarketInfo *mi = m_couples.at(i);
      if (!mi) continue;
      const LMapIntDouble *mi_state = m_couples.at(i).state();
      if (!mi_state) continue;
            
      string s = mi.couple();
      for (int j=0; j<np; j++)
         s += LFile::splitSymbol()+DoubleToString(mi_state.value(p_list.at(j), errStateValue()), MQEnumsStatic::paramPresicion(p_list.at(j)));
         
//      s += LFile::splitSymbol()+DoubleToString(mi_state.value(exspNextOrder, errStateValue()), 0);
//      s += LFile::splitSymbol()+DoubleToString(mi_state.value(exspStep, errStateValue()), 0);
//      s += LFile::splitSymbol()+DoubleToString(mi_state.value(exspCWinNumber, errStateValue()), 0);
//      s += LFile::splitSymbol()+DoubleToString(mi_state.value(exspFullLossNumber, errStateValue()), 0);
//      s += LFile::splitSymbol()+DoubleToString(mi_state.value(exspLotsSize, errStateValue()), 2);
      arr[i] = s;
      
      n_cwin += int(mi_state.value(exspCWinNumber, 0));
      n_fl += int(mi_state.value(exspFullLossNumber, 0));
      lots += mi_state.value(exspLotsSize, 0);
   }
   
   arr[n+2] = MQEnumsStatic::shortStrByType(exspCWinNumber)+"  "+IntegerToString(n_cwin);
   arr[n+3] = MQEnumsStatic::shortStrByType(exspFullLossNumber)+"  "+IntegerToString(n_fl);
   arr[n+4] = MQEnumsStatic::shortStrByType(exspLotsSize)+"  "+DoubleToString(lots, 2);
   arr[n+5] = "err_count  "+IntegerToString(m_err.errCount());

   string fname = fullFileName(currentStateFile());
   bool ok = LFile::stringListToFile(fname, arr);
   if (!ok)
   {
      addErr(etSaveState, fname);
      return;
   }
   else Print("Save state OK!");

}
void ExSpring::updateStateParam(MQMarketInfo *mi, int param_type, const string s_value)
{
   if (!mi) return;
   
   double value = StringToDouble(s_value); 
   if (GetLastError() != 0)
   {
      Print("ExSpring::updateStateParam  ERR state param value: "+MQEnumsStatic::shortStrByType(param_type));
      addErr(etLoadState, mi.couple() +" param_value "+MQEnumsStatic::shortStrByType(param_type));
      
      int mi_index = m_couples.indexOf(mi.couple());
      resetState(mi_index);
   }
   else mi.insertStateParam(param_type, value); 
}
void ExSpring::loadStateLine(int index, const string &s)
{
   MQMarketInfo *mi = m_couples.atVar(index);
   if (!mi) return;
      
   LStringList list;
   list.splitFromString(s, LFile::splitSymbol());
   
   if (list.count() != (mi.state().count()+1))
   {
      Print("ExSpring::loadStateLine  ERR load state: "+s);
      resetState(index);
      addErr(etLoadState, mi.couple());
      return;
   }

   LIntList p_list;
   getStateParamsList(p_list);
   int np = p_list.count();
   for (int i=0; i<np; i++)
      updateStateParam(mi, p_list.at(i), list.at(i+1));
   
}
void ExSpring::loadState()
{
   Print("Expert "+fullName()+" try load state ........");
   int n = m_couples.count();

   string arr[50];
   string fname = fullFileName(currentStateFile());
   int lines = LFile::readFileToStringList(fname, arr);
   if (lines < (n+10))
   {
      addErr(etLoadState, fname);
      return;
   }

   for (int i=0; i<n; i++)
      loadStateLine(i, arr[i]);

   Print("Load state OK!");
}

*/






