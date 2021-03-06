//+------------------------------------------------------------------+
//|                                               flgridexchange.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#define MAX_MSG_CONTAINTER  50


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
   bool isRepayOpenedType() const {return (message_type == ExchangeMsgType::emtRepayOpenedCommand);}
   
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
   enum ExchangeMsgType {emtStart = 211, emtDestroy, emtPing, emtOpenedPos, emtRepayCommand, emtRepayOpenedCommand,
                           emtGettedProfit, emtHedgeGrid, emtCurPLOpenedGrid, emtHistoryPrice_TestMode, /*emtBackRepayPart,*/
                           emtStartData_TestMode, emtStopData_TestMode, emtEmitData_TestMode, emtUnknown = -1};
   
   FLGridExchanger() {reset();}
   virtual ~FLGridExchanger() {ArrayFree(m_receivedData);}
   
   inline void setKey(string s) {m_key = s;}
   inline string key() const {return m_key;}
   inline void setOwnChartID(long id) {m_chartID = id;}
   inline bool hasMessage() const {return (msgCount() > 0);}
   bool hasNewMessages() const;
   inline int msgCount() const {return ArraySize(m_receivedData);}
      
   void getRecord(int i, FLGridExchangeMsg&, bool checked = true);
   bool isRecReaded(int i) const;
   
   void emitStarted(); //отправить сигнал о старте советника
   void emitDestroy(); //отправить сигнал об окончании работы советника
   void emitOpenedPos(double lot_size); 
   void emitGetedProfit(double profit_size);
   void emitHedgeGrid(double loss_size);
   void emitCurPLOpenedGrid(double pl_size);
   
   
   
   void sendPing(); //разослать всем графикам тестовый сигнал
   void receiveMsg(int, long, double, string); //получено сообщение
   void sendMsg(const FLGridExchangeMsg&, long to_chart_id = -1); //отправить сообщение указанному графику, если chart_id < 0 то всем графикам
   void sendRepayCommand(long, double);
   void sendRepayOpenedCommand(long, double);

   //кодируем ID сообщения, ID - элемент множества ExchangeMsgType   
   static ushort eventIDByMsgType(int type) {return (ushort(CHARTEVENT_CUSTOM)*10 + ushort(type));} 
   
protected:
   string m_key; //уникальный идентификатор своего советника
   long m_chartID; //ID своего графика терминала
   //bool has_new_msg;
   FLGridExchangeMsg m_receivedData[]; //контейнер с полученными сообщениями от др. советников
   

   void reset() {m_key = "none"; m_chartID = -1;}   
   void sendBroadcastMsg(const FLGridExchangeMsg&); //отправить сообщение всем
   void clearOld(); //удалить прочитанные сообщения из контейнера m_receivedData
   void removeAt(int); //удалить заданное сообщение из контейнера m_receivedData

   
};
//--------------------------------------------------------------
void FLGridExchanger::clearOld()
{
   if (msgCount() < MAX_MSG_CONTAINTER) return;
   
   bool need_remove = true;
   while (need_remove)
   {
      int n = msgCount();
      int i_remove = -1;
      for (int i=n-1; i>=0; i--)
         if (m_receivedData[i].readed) {i_remove = i; break;}
         
      if (i_remove < 0) need_remove = false;
      else  removeAt(i_remove);
   }
}
void FLGridExchanger::removeAt(int index)
{
   int n = msgCount();
   if (index < 0 || index >= n) return;
   
   for (int i=index+1; i<n; i++)
   {
      m_receivedData[i-1].setData(m_receivedData[i]);
      m_receivedData[i-1].readed = m_receivedData[i].readed;
   }
      
   ArrayResize(m_receivedData, n-1);
}
bool FLGridExchanger::hasNewMessages() const
{
   int n = msgCount();
   if (n == 0) return false;
   for (int i=0; i<n; i++)
      if (!m_receivedData[i].readed) return true;
   return false;    
}
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
void FLGridExchanger::sendRepayOpenedCommand(long chart_id, double sum)
{
   ushort eventID = eventIDByMsgType(emtRepayOpenedCommand);
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
void FLGridExchanger::emitCurPLOpenedGrid(double pl_size)
{
   FLGridExchangeMsg msg(m_chartID, pl_size, m_key);
   msg.message_type = emtCurPLOpenedGrid;
   sendBroadcastMsg(msg);
}
void FLGridExchanger::emitGetedProfit(double profit_size)
{
   FLGridExchangeMsg msg(m_chartID, profit_size, m_key);
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
   FLGridExchangeMsg msg(m_chartID, 0, m_key);
   msg.message_type = emtDestroy;   
   sendBroadcastMsg(msg);
   Sleep(100);
}
void FLGridExchanger::receiveMsg(int id, long p1, double p2, string p3)
{
   FLGridExchangeMsg msg(p1, p2, p3);
   while (id >= 1000) id -= 1000;
   msg.message_type = id;
   //Print("receiveMsg: key=", m_key, "      msg: ", msg.toStr());
   
   int n = msgCount();
   ArrayResize(m_receivedData, n+1);
   m_receivedData[n].setData(msg);
   
   clearOld();
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
      //Print("Send msg, id=", msg.message_type, "  key=", m_key, "  eventID=", eventID);
      if (m_chartID != chartID)
         EventChartCustom(chartID, eventID, msg.i_value, msg.d_value, msg.str_value); //отправляем пользовательское событие графику с идентификатором chartID
      chartID = ChartNext(chartID); // на основании предыдущего получим новый идентификатор графика
      if(chartID < 0) break;        // достигли конца списка открытых графиков
   }
}  
void FLGridExchanger::sendMsg(const FLGridExchangeMsg &msg, long to_chart_id)
{
   if (to_chart_id < 0)
   {
      sendBroadcastMsg(msg);
      Print("FLGridExchanger::sendMsg: ", msg.toStr());
      return;
   }
   
   if (msg.invalid()) {Print("FLGridExchanger::sendMsg - ERR: msg is invalid!"); return;}
   ushort eventID = eventIDByMsgType(msg.message_type); //кодируем ID сообщения
   EventChartCustom(to_chart_id, eventID, msg.i_value, msg.d_value, msg.str_value); //отправляем пользовательское событие графику с идентификатором to_chart_id
   
   
   Print("FLGridExchanger::sendMsg: ", msg.toStr());
     
}



