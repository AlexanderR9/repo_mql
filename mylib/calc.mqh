//+------------------------------------------------------------------+
//|                                                         func.mq4 |
//|                      Copyright � 2008, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
//���������� ���������� � �������� v ��� ������ lot
//���������, �����, ����� � �������,��������� ������ � ��������� 1-�� ������ � ������
string infoV(string v, double lot=1)
{
   string s = v+":  ������ ���� "+DoubleToStr(lot,2);
   s=s+", c���� � ������� "+DoubleToStr(MarketInfo(v,MODE_SPREAD),0);
   s=s+", c���� � ������ "+DoubleToStr(priceSpred(v,lot),2);
   s=s+", ��������� 1-�� ������ "+DoubleToStr(moneyPunkt(v,lot),2);
   
   return (s);
}
//���������� ����� ������ �������� ������� � ������� pos
//���� ����� ������� ���, ������� ����� -1
int tickerOrder(int pos=0)
{
   if (OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) return (OrderTicket());
   return (-1);
}
//���������� ������� ����� ������ �������� � ��������, i-�� ���� ����������� v, per-������ ����
double dBar(string v,int per,int i)
{
   return(iClose(v,per,i)-iOpen(v,per,i));
}
//���������� ������� ���� i-�� ���� ����������� v, per-������ ���� � �������
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
//���������� ������ ���� i-�� ���� ����������� v, per-������ ���� � �������
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
//���������� ������ �������� ����� i-�� ���� ����������� v, per-������ ����
string sShadow(string v,int per,int i, int precision = 0)
{
   int d = precision;
   string s = "Up/Down  (" + DoubleToStr(upShadow(v, per, i), d)+"/"+ DoubleToStr(downShadow(v, per, i), d)+")";
   return (s);
}
//���������� ������ ���������� i-�� ���� ����������� v, per-������ ����
string sBarParameters(string v,int per,int i)
{
   int d = MarketInfo(v, MODE_DIGITS);
   string s = "Open/Close  (" + DoubleToStr(iOpen(v, per, i), d)+"/"+ DoubleToStr(iClose(v, per, i), d)+")";
   s = s+",  High/Low  (" + DoubleToStr(iHigh(v, per, i), d)+"/"+ DoubleToStr(iLow(v, per, i), d)+")";
   return (s);
}
//���������� ������ ���������� � ������ i-�� ���� ����������� v, per-������ ���� � ��������
string sdBarParameters(string v,int per,int i)
{
   int d = MarketInfo(v, MODE_DIGITS);
   string s = "Open/Close  (" + DoubleToStr(iOpen(v, per, i), d)+"/"+ DoubleToStr(iClose(v, per, i), d)+")";
   s = s+",  High/Low  (" + DoubleToStr(iHigh(v, per, i), d)+"/"+ DoubleToStr(iLow(v, per, i), d)+")";
   s = s+"\n"+"Shadows:  "+sShadow(v, per, i);
   return (s);
}
//���������� ��� i-�� ���� ����������� v, per-������ ����
string sBar(string v,int per,int i)
{
   if (dBar(v, per, i) > 0) return ("up");
   if (dBar(v, per, i) < 0) return ("down");
   return ("null");
}
// ��������� ���������������  n-��������� ����� ������� � fi
// ��������� v, ���� ����� tf
// ���� ��� ���� up �� ����� true ����� false
bool isLastBarsUp(string v, int tf, int n, int fi = 1)
{
   if (tf <= 0 || n <=0 || fi < 0) return (false);
   for (int i=fi; i<(fi+n); i++)
      if (sBar(v, tf, i) != "up") return (false);
   return (true);      
}
// ��������� ���������������  n-��������� ����� ������� � fi
// ��������� v, ���� ����� tf
// ���� ��� ���� down �� ����� true ����� false
bool isLastBarsDown(string v, int tf, int n, int fi = 1)
{
   if (tf <= 0 || n <=0 || fi < 0) return (false);
   for (int i=fi; i<(fi+n); i++)
      if (sBar(v, tf, i) != "down") return (false);
   return (true);      
}

//���������� ������� ����� ������ �������� � ��������  � �������, i-�� ���� ����������� v, per-������ ����
double dOpenClose(string v,int per,int i)
{
   return (dPriceToPips(v,0,dBar(v,per,i)));
}
//���������� ������� ����� ������ ������������ � �����������, i-�� ���� ����������� v, per-������ ����
double maxDeltaPriceBar(string v,int per,int i)
{
   return(iHigh(v,per,i)-iLow(v,per,i));
}
//���������� ������� ����� ������ ������������ � ����������� � �������, i-�� ���� ����������� v, per-������ ����
double dHighLow(string v,int per,int i)
{
   return (dPriceToPips(v,0,maxDeltaPriceBar(v,per,i)));
}
//���������� ������� ���� i-�� ����, ����������� v, per-������ ����
double mediumPriceBar(string v,int per,int i)
{
   return(iLow(v,per,i)+maxDeltaPriceBar(v,per,i)/2);
}
//���������� ������� �������� ������� ���� ���� ����� n_bars ��������� �����
// ��������� v, � �������
int average_bar_size_hl(string v, int per, int n_bars = 100)
{
    int s = 0;
    for (int i=1; i<=n_bars; i++)
      s += dHighLow(v, per, i);
      
    return (s/n_bars);
}
//���������� ������� �������� ���� ���� ��� ����� ����� n_bars ��������� �����
// ��������� v, � �������
int average_bar_size_oc(string v, int per, int n_bars = 100)
{
    int s = 0;
    for (int i=1; i<=n_bars; i++)
      s += MathAbs(dOpenClose(v, per, i));
      
    return (s/n_bars);
}

//���������� ������� ������� �� ���� ������� �������� �� ����������� v, 
// ������� ����������� ������ �� �������
// ������� ����� ���� ������������� � �������������
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
//���������� ������� ������� �� ���� ������� �������� �� ����������� v, 
// ������� ����������� ��� ����� ������
// ������� ����� ���� ������������� � �������������
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
//���������� ������� ������� �� ���� ������� �������� �� ����������� v, 
// ������� ����������� � ������ ������ ������������� ������
// ������� ����� ���� ������������� � �������������
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
//���������� ������� ����� ������ �� ���� ������� �������� �� ����������� v
// ������� ����� ���� ������������� � �������������
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
//���������� ����� ���������� ���� ��� ���� ������������ ���������� �������� ������ ����� �� count ��������� �����
//����������� v, per-������ �����
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
//���������� ���������� ���� �������(�� ������������ � ����) ����� �� count ��������� �����
//����������� v, per-������ �����
int countNullBar(int count=1000,string v="symbol",int per=-1)
{
   int n=0;   
   if (v=="symbol") v=Symbol();
   if (per==-1) per=Period();
   for (int i=0;i<count;i++) 
      if (dBar(v,per,i)==0) n++;
  return (n);
}
// ������� ������� �������� ������� �� ���������� (v), ���� ����� ������� ����, ������� ����� true
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
// ������� ������� �������� ������� � ������� ticker, 
// ���� ����� ����� ������ � ������ ������ �
// �� �������� ���������, �� ������� ����� true
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
// ������� ������� �������� ������� � ������� (ticker) � ������ �������, 
// ���� ����� ������� ����, ������� ����� ������� �� �������, ���� ����� ��� ����� -1
int posOrderInHistory(int ticker) 
{
  if (HistoryTotal()==0) return (-1); 
  for (int i=0; i<HistoryTotal();i++)
         if (OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) && OrderTicket()==ticker)
            return(i);
   return (-1);
}
// � ������� �� ���������� (v), ���� ����� ������� ���, ������� ����� -1
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
// ���������� ������ 1-�� ������ ��������� - v � ������ (� ������ �����), ��� ������ ������ lot �����.
double moneyPunkt(string v, double lot = 0.1)
{
   return (lot*MarketInfo(v,16));
}
// ���������� ���������� ������� ������� ���� ������� ��������� v 
// ��� ������ lot ����� ���������� ������ loss
int countPipsForBackLoss(string v, double loss, double lot = 0.1)
{
   return (MathRound(MathAbs(loss)/moneyPunkt(v,lot))+1);
}
// ���������� ��������� ������ � ������, ��������� v 
// ��� ������ ���� - lot 
double priceSpred(string v, double lot = 0.1)
{
   return (moneyPunkt(v,lot)*MarketInfo(v,13));
}
//���������� ������� � ������� ����� ������ ��������� v , 
//a - ��������� ���� , b - ��������
int dPriceToPips(string v, double a, double b)
{
   return (MathPow(10,MarketInfo(v,12))*(b-a));
}
// ���������� true ���� ����� ��������� v  �� ��������� �������� - a 
bool validSpred(string v, int a=5)
{
   if (MarketInfo(v,13)>a ) return ( false);
   return (true);  
}
// ����������� ������ � �������� ���� 
double intPipsToDoublePrice(string v, int a)
{
   return (a/MathPow(10,MarketInfo(v,12)));
}
//������� ��������� ������ (���������) ��� ���������� ����
//factor - �����������
//sum - ������������ ����� ���������
//d - ���������(����� �����, �� ��������� ����� ����� � ���� �����������)
//over - �������������� ������� ����� �������� ������
double complexStartBet(double factor, double sum, int d, double over = 0)
{
    if (factor <= 1 || d < 2 || sum < 0.1) 		return (-1);
    if (over < 0) over = 0;
    
    double f = factor - 1;
    double t = 0;
    for (int i=2; i<=d; i++) t += MathPow(factor,i-2)/MathPow(f,i-1);
    return  ((sum - over*t) / (t + 1));
}
//������� ����� ������ ������ ��� ���������� ���� �� ���� ��������� � ����� distantion
//������ ����� ������ ������ ������ 1-� (���������) ���� ����������� ������ 2
//factor - �����������
//sum - ������������ ����� ���������
//d - ���������(����� �����, �� ��������� ����� ����� � ���� �����������)
//over - �������������� ������� ����� �������� ������
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
//������� ������ � ���������� ���� ��� ���� step [1..n]
//factor - �����������
//sum - ������������ ����� ���������
//d - ���������(����� �����, �� ��������� ����� ����� � ���� �����������)
//over - �������������� ������� ����� �������� ������
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

// ���������� ������ ���� ��������� - v ��� ������� ������ �� n_pips �������
// n_pips ��� ������� ��� ���� ������
// �������� � loss ��������
// ���� ��� ���������� ������ ����������� (�����������) ������� ����� -1
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
//���������� ��������� ����� �� t1 �� t2
//t1 t2  ������ ���� ������ �� 0 �� 32767
//��� ������� t2 <= t1 ����� ��������� �������� -1
//���� b = true  ��������� �������������� ��������������� � ��������� ���������
int random(int t1 = 0, int t2 = 100, bool b = true)
{
      if (t2 <= t1) return (-1);  
      int d =  t2 - t1 + 1;  
      int a = 32767 / d;
      
      if (b) MathSrand(TimeLocal());
      return (t1 + MathRand()/a);
}
// ���������� ������� ��������� ������ � ������� ticker (� ������ ����� �.�. ����� ��� �������)
// ���������� 0 ���� ����� �� ������ ���
// ���������� 1982 ���� ����� ����� ������ �� ������
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
//���������� ��� ������ � ������� ticker
// -1 ���� ����� �� ������
//  0 ���� ����� ������ � ������ ������ 
//  1 ���� ����� ������ � ��������� � �������
//  2 ���� ����� �������� ��������� � ��������� � �������� 
int findOrder(int ticker)
{
   if (!OrderSelect(ticker,SELECT_BY_TICKET))   return (-1);
   
   int type = OrderType();
   if ((type == OP_BUYLIMIT) || (type == OP_BUYSTOP) || 
       (type == OP_SELLLIMIT) || (type == OP_SELLSTOP)) return (2);
   
   if (isOrderOpened(ticker))  return (0);
   return (1);     
}
//���������� ������� ����� ��������� v
//�� ������� � ����������� per �� ��������� n �����
//ema_per - ������ ���������������� ������� ����������
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


