//+------------------------------------------------------------------+
//|                                               flgridexchange.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


//структура для передачи одного сообщения между советниками
struct FLGridExchangeMsg
{
   FLGridExchangeMsg() :i_value(-1), d_value(-1), str_value("empty"), message_type(-1), readed(false) {}
   FLGridExchangeMsg(long p1, double p2, string p3) :i_value(p1), d_value(p2), str_value(p3), message_type(-1), readed(false) {}
   
   bool invalid() const {return (message_type < 0);}
   void setData(const FLGridExchangeMsg &rec)
   {
      i_value = rec.i_value;
      d_value = rec.d_value;
      str_value = rec.str_value;
      message_type = rec.message_type;
   }
   bool isRepayType() const {return (message_type == ExchangeMsgType::emtRepayCommand);}
   
   long i_value;
   double d_value;
   string str_value;
   int message_type;
   bool readed; 
   
   string toStr() const 
   {
      return StringConcatenate("ID=", message_type, "  (p1=", i_value, "  p2=", d_value, "  p3=", str_value, ")");
   }
};

////////////////////////////////////////////////////
class FLGridExchanger
{
public:
   enum ExchangeMsgType {emtStart = 211, emtDestroy, emtPing, emtOpenedPos, emtRepayCommand,
                           emtGettedProfit, emtHedgeGrid, emtUnknown = -1};
   
   FLGridExchanger() {reset();}
   
   inline void setKey(string s) {m_key = s;}
   inline void setOwnChartID(long id) {m_chartID = id;}
   inline bool hasMessage() const {return (msgCount() > 0);}
   inline int msgCount() const {return ArraySize(m_receivedData);}
      
   void getRecord(int i, FLGridExchangeMsg&, bool checked = true);
   bool isRecReaded(int i) const;
   
   void emitStarted();
   void emitDestroy();
   void emitOpenedPos(double lot_size);
   void emitGetedProfit(double profit_size);
   void emitHedgeGrid(double loss_size);
   
   
   
   void sendPing();
   void receiveMsg(int, long, double, string); //получено сообщение
   void sendRepayCommand(long, double);
   
   static ushort eventIDByMsgType(int type) {return (ushort(CHARTEVENT_CUSTOM)*10 + ushort(type));} //кодируем ID сообщения
   
protected:
   string m_key;
   long m_chartID;
   bool has_new_msg;
   FLGridExchangeMsg m_receivedData[];
   

   void reset() {m_key = "none"; m_chartID = -1;}   
   void sendBroadcastMsg(const FLGridExchangeMsg&); //отправить сообщение всем
   
};
//--------------------------------------------------------------
void FLGridExchanger::getRecord(int i, FLGridExchangeMsg &rec, bool checked)
{
   if (i<0 || i>=msgCount()) return;
   rec.setData(m_receivedData[i]);
   m_receivedData[i].readed = checked;
}
void FLGridExchanger::sendPing()
{
   FLGridExchangeMsg msg(0, 0, m_key);
   msg.message_type = emtPing;
   sendBroadcastMsg(msg);
}
void FLGridExchanger::sendRepayCommand(long chart_id, double sum)
{
   ushort eventID = eventIDByMsgType(emtRepayCommand);
   EventChartCustom(chart_id, eventID, 0, sum, m_key); //отправляем пользовательское событие графику с идентификатором chart_id
}
void FLGridExchanger::emitOpenedPos(double lot_size)
{
   FLGridExchangeMsg msg(0, lot_size, m_key);
   msg.message_type = emtOpenedPos;
   sendBroadcastMsg(msg);
}
void FLGridExchanger::emitHedgeGrid(double loss_size)
{
   FLGridExchangeMsg msg(m_chartID, loss_size, m_key);
   msg.message_type = emtHedgeGrid;
   sendBroadcastMsg(msg);
}
void FLGridExchanger::emitGetedProfit(double profit_size)
{
   FLGridExchangeMsg msg(0, profit_size, m_key);
   msg.message_type = emtGettedProfit;
   sendBroadcastMsg(msg);
}
void FLGridExchanger::emitStarted()
{
   FLGridExchangeMsg msg(0, 0, m_key);
   msg.message_type = emtStart;
   sendBroadcastMsg(msg);
}
void FLGridExchanger::emitDestroy()
{
   ArrayFree(m_receivedData);
   FLGridExchangeMsg msg(0, 0, m_key);
   msg.message_type = emtDestroy;   
   sendBroadcastMsg(msg);
}
void FLGridExchanger::receiveMsg(int id, long p1, double p2, string p3)
{
   FLGridExchangeMsg msg(p1, p2, p3);
   while (id >= 1000) id -= 1000;
   msg.message_type = id;
   Print("receiveMsg: key=", m_key, "      msg: ", msg.toStr());
   
   int n = msgCount();
   ArrayResize(m_receivedData, n+1);
   m_receivedData[n].setData(msg);
   
}
bool FLGridExchanger::isRecReaded(int i) const
{
   if (i < 0 || i > msgCount()) return false;
   return m_receivedData[i].readed;
}

void FLGridExchanger::sendBroadcastMsg(const FLGridExchangeMsg &msg)
{
   if (msg.invalid()) {Print("FLGridExchanger::sendBroadcastMsg - ERR: msg is invalid!"); return;}

   ushort eventID = eventIDByMsgType(msg.message_type); //кодируем ID сообщения
   long chartID = ChartFirst(); //1-й график
   for (;;) //отсылаем поочереди всем графикам
   {
      Print("Send msg, id=", msg.message_type, "  key=", m_key, "  eventID=", eventID);
      if (m_chartID != chartID)
         EventChartCustom(chartID, eventID, msg.i_value, msg.d_value, msg.str_value); //отправляем пользовательское событие графику с идентификатором chartID
      chartID = ChartNext(chartID); // на основании предыдущего получим новый идентификатор графика
      if(chartID < 0) break;        // достигли конца списка открытых графиков
   }
}  



