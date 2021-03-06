//+------------------------------------------------------------------+
//|                                                         func.mq4 |
//|                      Copyright © 2008, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#include <mylib/base.mqh>

class LCalcSteps
{
public:
   enum LCalcStages {csStopped = 880, csWaitResult, csLoss, csWin};
   
   LCalcSteps() {reset();}
   
   bool invalid() const;
   
   inline void setLots(const double &a, const double &b) {start_lot = a; min_lot = b;}
   inline void setDist(int a) {m_dist = a;}
   inline void setStep(int a) {m_step = a;}
   inline void setPrevStep(int a) {prev_step = a;}
   inline void setDecStep(int a) {dec_step = a;}
   inline void setFactor(const double &a) {next_factor = a;}
   inline void setFixLot(bool b) {fix_lot = b;}
   inline void setStage(int a) {last_stage = a;}
   inline void setCoupleIndex(int a) {couple_index = a;}
   
   inline int dist() const {return m_dist;}
   inline int step() const {return m_step;}
   inline int prevStep() const {return prev_step;}
   inline int coupleIndex() const {return couple_index;}
   
   
   inline bool waitResult() const {return (last_stage == csWaitResult);}
   inline bool isLoss() const {return (last_stage == csLoss);}
   inline bool isWin() const {return (last_stage == csWin);}
   inline bool isCWin() const {return (isWin() && (m_step == 1));}
   inline bool isOver() const {return (isLoss() && (m_step == m_dist));} //full loss
   inline void win() {last_stage = csWin;}
   inline void loss() {last_stage = csLoss;}
   
   double nextLot() const;
   double currentLot() const;
   int nextStep() const;
   //void nextBet();
   
   
   void out() const;
   
protected:
   int m_dist;
   double next_factor;
   int m_step;   
   int prev_step;
   int dec_step; //на сколько шагов отступать назад в случае победы
   double start_lot;
   double min_lot;
   int last_stage;
   bool fix_lot;
   int couple_index;
   
   void reset();
   
};

//-------------------------------------------------
void LCalcSteps::out() const
{
   string s = "LCalcSteps::out():  ";
   s += "m_dist="+IntegerToString(m_dist)+"  ";
   s += "next_factor="+DoubleToString(next_factor, 2)+"  ";
   s += "m_step="+IntegerToString(m_step)+"  ";
   s += "prev_step="+IntegerToString(prev_step)+"  ";
   s += "dec_step="+IntegerToString(dec_step)+"  ";
   s += "start_lot="+DoubleToString(start_lot, 2)+"  ";
   s += "min_lot="+DoubleToString(min_lot, 2)+"  ";
   s += "last_stage="+IntegerToString(last_stage)+"  ";
   s += "fix_lot="+(fix_lot?"true":"false")+"  ";
   s += "couple_index="+IntegerToString(couple_index)+"  ";
   if (invalid()) s += "--INVALID STATE--";
   Print(s);
}
bool LCalcSteps::invalid() const
{
   if (m_dist < 1 || m_dist > 50) return true;
   if (next_factor < 1 || next_factor > 50) return true;
   if (start_lot < 0.01 || start_lot > 100)  return true;
   if (min_lot < 0.01 || min_lot > 1 || min_lot > start_lot)  return true;
   return false;
}
void LCalcSteps::reset() 
{
   m_dist = 1; 
   next_factor = 1; 
   m_step = prev_step = 0; 
   dec_step = -1;
   start_lot = min_lot = 0.1; 
   last_stage = csStopped;
   fix_lot = false;
   couple_index = 0;
}
/*
void LCalcSteps::nextBet()
{
   prev_step = m_step;
   m_step = nextStep();
   last_stage = csWaitResult;
}
*/
int LCalcSteps::nextStep() const
{
   if (invalid()) return 0;
   if (waitResult()) return 0;
   if (isOver()) return 1;
   if (isWin())
   {
      if (dec_step < 0)  return 1;
      int ns = step() - dec_step;
      if (ns <= 0) ns = 1;
      return ns;
   }
   
   
   return (m_step + 1);
}
double LCalcSteps::currentLot() const
{
   if (invalid()) return 0;
   if (fix_lot) return start_lot;

   double lot = start_lot;
   if (m_step < 1) return min_lot;
   if (m_step == 1) return lot;

   for (int i=2; i<=m_step; i++)
      lot *= next_factor;
   
   return lot;
}
double LCalcSteps::nextLot() const
{
   if (invalid()) return 0;
   if (waitResult()) return 0;
   if (fix_lot) return start_lot;
   
   double lot = start_lot;
   int step = nextStep();
   if (step < 1) return min_lot;
   if (step == 1) return lot;
   
   for (int i=2; i<=step; i++)
      lot *= next_factor;
   
   return lot;
}

//набор статический функции помогающих определить состояние рынка
class LStaticCalc
{
public:

   //определяет тип n-баров подряд, на чиная с start_pos (отчет в обратную сторону),
   //пара - couple, таймфрейм - tf.
   //результат: 0 - все бары направлены вверх, 1 - все бары направлены вниз, -1 - разнонаправленные
   static int barsType(string couple, int tf, int n, int start_pos = 0);
   
   //определяет тип бара с индексом index,
   //пара - couple, таймфрейм - tf.
   //результат: 0 - направлен вверх, 1 - направлен вниз, 2 - нулевой (open == close)
   static int barType(string couple, int tf, int index);
   
   //определяет количество пройденых пунктов(для 4-х значных брокеров) n-баров подряд, на чиная с start_pos (отчет в обратную сторону)
   //пара - couple, таймфрейм - tf.
   //результат может быть положительным и отрицательным
   static double barPips(string couple, int tf, int index);

   //определяет количество пройденых пунктов(для 4-х значных брокеров) бара с индексом index (close-open),
   //пара - couple, таймфрейм - tf.
   //результат может быть положительным и отрицательным
   static double barsPips(string couple, int tf, int n, int start_pos = 0);

};
int LStaticCalc::barsType(string couple, int tf, int n, int start_pos)
{
   if (!MQValidityData::isValidCouple(couple)) return int(MQValidityData::errValue());
   if (!MQValidityData::isValidTimeFrame(tf)) return int(MQValidityData::errValue());
   if (start_pos < 0 || n < 1) return int(MQValidityData::errValue());
   
   bool up = true;
   bool down = true;
   for (int i=(start_pos + n - 1); i>=start_pos; i--)
   {
      int type = barType(couple, tf, i);
      if (type != 0) up = false;
      if (type != 1) down = false;
   }

   if (up) return 0;
   if (down) return 1;
   return -1;
}
double LStaticCalc::barsPips(string couple, int tf, int n, int start_pos)
{
   if (!MQValidityData::isValidCouple(couple)) return int(MQValidityData::errValue());
   if (!MQValidityData::isValidTimeFrame(tf)) return int(MQValidityData::errValue());
   if (start_pos < 0 || n < 1) return int(MQValidityData::errValue());
   
   double pips = 0;
   for (int i=(start_pos + n - 1); i>=start_pos; i--)
   {
      pips += barPips(couple, tf, i);
     // Print(couple, " i=", i, "  pips=", DoubleToStr(pips, 2));
   }

   return pips;
}

double LStaticCalc::barPips(string couple, int tf, int index)
{
   if (!MQValidityData::isValidCouple(couple)) return int(MQValidityData::errValue());
   if (!MQValidityData::isValidTimeFrame(tf)) return int(MQValidityData::errValue());
   if (index < 0) return int(MQValidityData::errValue());
   
   int dig = int(MarketInfo(couple, MODE_DIGITS));
   double d_price = iClose(couple, tf, index) - iOpen(couple, tf, index);
   double pips = d_price * double(MathPow(10, dig));
   if ((dig % 2) > 0) pips /= double(10);

   return pips;
}
int LStaticCalc::barType(string couple, int tf, int index)
{
   double pips = barPips(couple, tf, index);
   if (int(pips) == MQValidityData::errValue()) return int(pips);
   if (MathAbs(pips) < 0.1) return 2;
   if (pips > 0) return 0;
   return 1;
}


/*
//возвращает информацию о котирвке v при обьёме lot
//котировка, обьём, спред в пунктах,стоимость спреда и стоимость 1-го пункта в центах
string infoV(string v, double lot=1)
{
   string s = v+":  размер лота "+DoubleToStr(lot,2);
   s=s+", cпрэд в пунктах "+DoubleToStr(MarketInfo(v,MODE_SPREAD),0);
   s=s+", cпрэд в центах "+DoubleToStr(priceSpred(v,lot),2);
   s=s+", стоимость 1-го пункта "+DoubleToStr(moneyPunkt(v,lot),2);
   
   return (s);
}
//возвращает номер тикера открытой позиции с номером pos
//если такой позиции нет, функция вернёт -1
int tickerOrder(int pos=0)
{
   if (OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) return (OrderTicket());
   return (-1);
}
//возвращает разницу между ценами открытия и закрытия, i-го бара инструмента v, per-период бара
double dBar(string v,int per,int i)
{
   return(iClose(v,per,i)-iOpen(v,per,i));
}
//возвращает верхнюю тень i-го бара инструмента v, per-период бара в пунктах
double upShadow(string v,int per,int i)
{
   double d;
   int dig = MarketInfo(v, MODE_DIGITS); 
   
   if (sBar(v, per, i) == "up")
      d = MathAbs(iHigh(v, per, i) - iClose(v, per, i));  
   else
      d = MathAbs(iHigh(v, per, i) - iOpen(v, per, i));  
      
   return (d * MathPow(10, dig));  
}
//возвращает нижнюю тень i-го бара инструмента v, per-период бара в пунктах
double downShadow(string v,int per,int i)
{
   double d;
   int dig = MarketInfo(v, MODE_DIGITS); 
   
   if (sBar(v, per, i) == "down")
      d = MathAbs(iLow(v, per, i) - iClose(v, per, i));  
   else
      d = MathAbs(iLow(v, per, i) - iOpen(v, per, i));  
      
   return (d * MathPow(10, dig));  
}
//возвращает строку значения теней i-го бара инструмента v, per-период бара
string sShadow(string v,int per,int i, int precision = 0)
{
   int d = precision;
   string s = "Up/Down  (" + DoubleToStr(upShadow(v, per, i), d)+"/"+ DoubleToStr(downShadow(v, per, i), d)+")";
   return (s);
}
//возвращает строку параметров i-го бара инструмента v, per-период бара
string sBarParameters(string v,int per,int i)
{
   int d = MarketInfo(v, MODE_DIGITS);
   string s = "Open/Close  (" + DoubleToStr(iOpen(v, per, i), d)+"/"+ DoubleToStr(iClose(v, per, i), d)+")";
   s = s+",  High/Low  (" + DoubleToStr(iHigh(v, per, i), d)+"/"+ DoubleToStr(iLow(v, per, i), d)+")";
   return (s);
}
//возвращает строку параметров с тенями i-го бара инструмента v, per-период бара с дельтами
string sdBarParameters(string v,int per,int i)
{
   int d = MarketInfo(v, MODE_DIGITS);
   string s = "Open/Close  (" + DoubleToStr(iOpen(v, per, i), d)+"/"+ DoubleToStr(iClose(v, per, i), d)+")";
   s = s+",  High/Low  (" + DoubleToStr(iHigh(v, per, i), d)+"/"+ DoubleToStr(iLow(v, per, i), d)+")";
   s = s+"\n"+"Shadows:  "+sShadow(v, per, i);
   return (s);
}
//возвращает вид i-го бара инструмента v, per-период бара
string sBar(string v,int per,int i)
{
   if (dBar(v, per, i) > 0) return ("up");
   if (dBar(v, per, i) < 0) return ("down");
   return ("null");
}
// проверяет последовательно  n-последних баров начиная с fi
// котировка v, тайм фрайм tf
// если все типа up то вернёт true иначе false
bool isLastBarsUp(string v, int tf, int n, int fi = 1)
{
   if (tf <= 0 || n <=0 || fi < 0) return (false);
   for (int i=fi; i<(fi+n); i++)
      if (sBar(v, tf, i) != "up") return (false);
   return (true);      
}
// проверяет последовательно  n-последних баров начиная с fi
// котировка v, тайм фрайм tf
// если все типа down то вернёт true иначе false
bool isLastBarsDown(string v, int tf, int n, int fi = 1)
{
   if (tf <= 0 || n <=0 || fi < 0) return (false);
   for (int i=fi; i<(fi+n); i++)
      if (sBar(v, tf, i) != "down") return (false);
   return (true);      
}

//возвращает разницу между ценами открытия и закрытия  в пунктах, i-го бара инструмента v, per-период бара
double dOpenClose(string v,int per,int i)
{
   return (dPriceToPips(v,0,dBar(v,per,i)));
}
//возвращает разницу между ценами максимальной и минимальной, i-го бара инструмента v, per-период бара
double maxDeltaPriceBar(string v,int per,int i)
{
   return(iHigh(v,per,i)-iLow(v,per,i));
}
//возвращает разницу между ценами максимальной и минимальной в пунктах, i-го бара инструмента v, per-период бара
double dHighLow(string v,int per,int i)
{
   return (dPriceToPips(v,0,maxDeltaPriceBar(v,per,i)));
}
//возвращает среднюю цену i-го бара, инструмента v, per-период бара
double mediumPriceBar(string v,int per,int i)
{
   return(iLow(v,per,i)+maxDeltaPriceBar(v,per,i)/2);
}
//возвращает среднюю величину полного тела бара среди n_bars последних баров
// котировки v, в пунктах
int average_bar_size_hl(string v, int per, int n_bars = 100)
{
    int s = 0;
    for (int i=1; i<=n_bars; i++)
      s += dHighLow(v, per, i);
      
    return (s/n_bars);
}
//возвращает среднюю величину тела бара без теней среди n_bars последних баров
// котировки v, в пунктах
int average_bar_size_oc(string v, int per, int n_bars = 100)
{
    int s = 0;
    for (int i=1; i<=n_bars; i++)
      s += MathAbs(dOpenClose(v, per, i));
      
    return (s/n_bars);
}

//возвращает текущую прибыль по всем ордерам открытым по инструменту v, 
// прибыль суммируется вместе со свопами
// прибыль может быть положительной и отрицательной
double rezSumVWithSwap(string v)
{
   double sum=0;
   if (OrdersTotal()>0)
   {
      for (int i=0;i<OrdersTotal();i++)
        if (OrderSelect(i,SELECT_BY_POS) && OrderSymbol()==v) 
            sum+=OrderProfit()+OrderSwap();
   }
   return (sum);
}
//возвращает текущую прибыль по всем ордерам открытым по инструменту v, 
// прибыль суммируется без учёта свопов
// прибыль может быть положительной и отрицательной
double rezSumVWithoutSwap(string v)
{
   double sum=0;
   if (OrdersTotal()>0)
   {
      for (int i=0;i<OrdersTotal();i++)
        if (OrderSelect(i,SELECT_BY_POS) && OrderSymbol()==v) sum+=OrderProfit();
   }
   return (sum);
}
//возвращает текущую прибыль по всем ордерам открытым по инструменту v, 
// прибыль суммируется с учётом только отрицательных свопов
// прибыль может быть положительной и отрицательной
double rezSumVBadSwap(string v)
{
   double sum=0;
   if (OrdersTotal()>0)
   {
      for (int i=0;i<OrdersTotal();i++)
        if (OrderSelect(i,SELECT_BY_POS) && OrderSymbol()==v)
        {
             if (OrderSwap()<0) sum+=OrderProfit()+OrderSwap();
                  else sum+=OrderProfit();
        }
   }
   return (sum);
}
//возвращает текущую сумму свопов по всем ордерам открытым по инструменту v
// прибыль может быть положительной и отрицательной
double sumSwapV(string v)
{
   double sum=0;
   if (OrdersTotal()>0)
   {
      for (int i=0;i<OrdersTotal();i++)
        if (OrderSelect(i,SELECT_BY_POS) && OrderSymbol()==v)   sum+=OrderSwap();

   }
   return (sum);
}
//возвращает номер начального бара где есть максимальное количество падающих подряд баров из count последних баров
//инструмента v, per-период баров
int indexBeginLossBar(int count=1000,string v="symbol",int per=-1)
{
   int index=-1;
   int n=0;
   if (v=="symbol") v=Symbol();
   if (per==-1) per=Period();
   for (int i=0;i<count;i++)
   {
         if (dBar(v,per,i)<0) n++;
            else n=0; 
         if (n==1) index=i;   
  }
  return (index);
}
//возвращает количество всех нулевых(не изменившихся в цене) баров из count последних баров
//инструмента v, per-период баров
int countNullBar(int count=1000,string v="symbol",int per=-1)
{
   int n=0;   
   if (v=="symbol") v=Symbol();
   if (per==-1) per=Period();
   for (int i=0;i<count;i++) 
      if (dBar(v,per,i)==0) n++;
  return (n);
}
// признак наличия открытой позиции по интрументу (v), если такая позиция есть, функция вернёт true
bool openPosInList(string v) 
{
  if (OrdersTotal()>0) 
  {
      for (int i=0; i<OrdersTotal();i++)
      {
         if (OrderSelect(i,SELECT_BY_POS))
         if (OrderSymbol()==v) return(true);
      }
   }
   return (false);
}
// признак наличия открытой позиции с тикером ticker, 
// если такой ордер открыт в данный момент и
// не является отложеным, то функция вернёт true
bool isOrderOpened(int ticker) 
{
  if (OrdersTotal()>0) 
  {
      for (int i=0; i<OrdersTotal();i++)
      {
         if (OrderSelect(i,SELECT_BY_POS))
            if (OrderTicket() == ticker) 
            {
               int type = OrderType();
               if ((type == OP_BUY) || (type == OP_SELL)) return (true);
            }
      }
   }
   return (false);
}
// признак наличия закрытой позиции с тикером (ticker) в списке истории, 
// если такая позиция есть, функция номер позиции из истории, если такой нет вернёт -1
int posOrderInHistory(int ticker) 
{
  if (HistoryTotal()==0) return (-1); 
  for (int i=0; i<HistoryTotal();i++)
         if (OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) && OrderTicket()==ticker)
            return(i);
   return (-1);
}
// № позиции по интрументу (v), если такой позиции нет, функция вернёт -1
int indexPos(string v) 
{
  if (OrdersTotal()>0) 
  {
      for (int i=0; i<OrdersTotal();i++)
      {
         if (OrderSelect(i,SELECT_BY_POS))
         if (OrderSymbol()==v) return(i);
      }
   }
   return (-1);
}
// возвращает размер 1-го пункта котировки - v в центах (в валюте счёта), при обьёме ордера lot лотов.
double moneyPunkt(string v, double lot = 0.1)
{
   return (lot*MarketInfo(v,16));
}
// возвращает количество пунктов которое надо набрать котировке v 
// при обьёме lot чтобы возместить потери loss
int countPipsForBackLoss(string v, double loss, double lot = 0.1)
{
   return (MathRound(MathAbs(loss)/moneyPunkt(v,lot))+1);
}
// возвращает стоимость спреда в центах, котировки v 
// при обьёме лота - lot 
double priceSpred(string v, double lot = 0.1)
{
   return (moneyPunkt(v,lot)*MarketInfo(v,13));
}
//возвращает разницу в пунктах между ценами котировки v , 
//a - начальная цена , b - конечная
int dPriceToPips(string v, double a, double b)
{
   return (MathPow(10,MarketInfo(v,12))*(b-a));
}
// возвращает true если спред котировки v  не превышает значение - a 
bool validSpred(string v, int a=5)
{
   if (MarketInfo(v,13)>a ) return ( false);
   return (true);  
}
// преабразует пункты в значение цены 
double intPipsToDoublePrice(string v, int a)
{
   return (a/MathPow(10,MarketInfo(v,12)));
}
//считает стартовую ставку (начальную) при комлексной игре
//factor - коэффициент
//sum - максимальная сумма проигрыша
//d - дистанция(число шагов, на последнем сумма слита и игра остановлена)
//over - незначительная прибыль сверх отыгрыша потерь
double complexStartBet(double factor, double sum, int d, double over = 0)
{
    if (factor <= 1 || d < 2 || sum < 0.1) 		return (-1);
    if (over < 0) over = 0;
    
    double f = factor - 1;
    double t = 0;
    for (int i=2; i<=d; i++) t += MathPow(factor,i-2)/MathPow(f,i-1);
    return  ((sum - over*t) / (t + 1));
}
//считает самую мелкую ставку при комлексной игре из всех возможных в серии distantion
//обычно самая мелкая ставка меньше 1-й (начальной) если коэффициент больше 2
//factor - коэффициент
//sum - максимальная сумма проигрыша
//d - дистанция(число шагов, на последнем сумма слита и игра остановлена)
//over - незначительная прибыль сверх отыгрыша потерь
double complexMinBet(double factor, double sum, int d, double over = 0)
{
   double start_bet = complexStartBet(factor, sum, d, over);  
   if (start_bet < 0) return (-1); 
   double min_bet = start_bet;
   for (int step=2; step<=d; step++)
   {
       double next_bet = complexStepBet(step, factor, sum, d, over);
       if (next_bet < min_bet) min_bet =  next_bet;
   }
   return (min_bet);
}
//считает ставку в комлексной игре при шаге step [1..n]
//factor - коэффициент
//sum - максимальная сумма проигрыша
//d - дистанция(число шагов, на последнем сумма слита и игра остановлена)
//over - незначительная прибыль сверх отыгрыша потерь
double complexStepBet(int step, double factor, double sum, int d, double over = 0)
{
    if (step <= 0 || factor <= 1 || d < 2 || sum < 0.1) 		return (-1);
    if (over < 0) over = 0;
    
    double start_bet = complexStartBet(factor, sum, d, over);
    if (start_bet < 0) return (-1); 
    if (step == 1)	return (start_bet);

    double f = factor - 1;
    double b = start_bet  + over;
    return (b*(MathPow(factor,step-2)/MathPow(f,step-1)));
}

// возвращает размер лота котировки - v при котором потери на n_pips пунктов
// n_pips как правило это стоп ордера
// составит в loss долларов
// если лот получается меньше допустимого (наименьшего) функция вернёт -1
double lotValue(string v, int n_pips, double loss, bool ifPrint = true)
{
   int precition = 6;
   double min_lot = MarketInfo(v, MODE_MINLOT);
   double lot_step = MarketInfo(v, MODE_LOTSTEP);
   int lot_dig = 1/lot_step;
   double pips_price = MarketInfo(v, MODE_TICKVALUE)/100;
   double min_pips_price = min_lot * pips_price;
   double punct_price = loss/n_pips;
   
   if (ifPrint)
   Print(" Lot info for "+v+":  min lot = "+DoubleToStr(min_lot,precition)+
   ",  lot step = "+DoubleToStr(lot_step,precition)+
   ",  lot dig = "+DoubleToStr(lot_dig,precition)+
   ",  pips price = "+DoubleToStr(pips_price,precition)+
   ",  min pips price = "+DoubleToStr(min_pips_price,precition)+
   ",  punct price = "+DoubleToStr(punct_price,precition));
   
   
   if (punct_price < min_pips_price)
   {
       if (ifPrint) Print("Error:  punct_price < min_pips_price");
       return (-1);
   }
   
   double lot_size = min_lot*punct_price/min_pips_price;
   if (ifPrint) Print("Lot size = "+DoubleToStr(lot_size,precition));
   double lot_size_ceil = MathCeil(lot_dig*lot_size)/lot_dig;
   if (ifPrint) Print("Lot size ceil = "+DoubleToStr(lot_size_ceil,precition));

   return (lot_size_ceil);
}
//возвращает случайное число от t1 до t2
//t1 t2  должны быть целыми от 0 до 32767
//при условии t2 <= t1 вернёт ошибочное значение -1
//если b = true  генератор предварительно устанавливается в случайное состояние
int random(int t1 = 0, int t2 = 100, bool b = true)
{
      if (t2 <= t1) return (-1);  
      int d =  t2 - t1 + 1;  
      int a = 32767 / d;
      
      if (b) MathSrand(TimeLocal());
      return (t1 + MathRand()/a);
}
// возвращает прибыль закрытого ордера с тикиром ticker (в валюте счёта т.е. центы или доллары)
// возвращает 0 если ордер не закрыт ещё
// возвращает 1982 если такой ордер совсем не найден
double profitOrder(int ticker)
{
   int total = OrdersTotal();
   if (total>0)
   {
      for (int i=0; i<total; i++)
      {
         if (OrderSelect(i,SELECT_BY_POS))
         {
            if(OrderTicket() == ticker) return(0);
         }
      }  
   }
   if (OrderSelect(ticker,SELECT_BY_TICKET))   return (OrderProfit());
   return (1982);
}
//возвращает тип ордера с тикером ticker
// -1 если ордер не найден
//  0 если ордер открыт в данный момент 
//  1 если ордер закрыт и находится в истории
//  2 если ордер является отложеным и находится в ожидании 
int findOrder(int ticker)
{
   if (!OrderSelect(ticker,SELECT_BY_TICKET))   return (-1);
   
   int type = OrderType();
   if ((type == OP_BUYLIMIT) || (type == OP_BUYSTOP) || 
       (type == OP_SELLLIMIT) || (type == OP_SELLSTOP)) return (2);
   
   if (isOrderOpened(ticker))  return (0);
   return (1);     
}
//определяет текущий тренд котировки v
//на графика с таймфреймом per за последние n баров
//ema_per - период экспоненциальной средней скользящей
string curTrend(string v, int per = PERIOD_H4, int n = 50, int ema_per = 55)
{
   string result = "";
   string unknown_trend = "unknown";
   int i;
   double ema_value;
   double bar_price;
   
   for (i=0; i<n; i++) 
   {
      ema_value = iMA(v, per, ema_per, 0, MODE_EMA, PRICE_CLOSE, i);
      bar_price = iHigh(v, per, i);
      if (ema_value < bar_price) {result = unknown_trend; break;}
   }
   
   if (result != unknown_trend) {result = "down"; return (result);} 
   
   result = "";
   for (i=0; i<n; i++) 
   {
      ema_value = iMA(v, per, ema_per, 0, MODE_EMA, PRICE_CLOSE, i);
      bar_price = iLow(v, per, i);
      if (ema_value > bar_price) {result = unknown_trend; break;}
   }

   if (result != unknown_trend) result = "up"; 
   
   return (result);
}
*/


