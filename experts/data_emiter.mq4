//+------------------------------------------------------------------+
//|                                                      fllimit.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <mylib/ldataemiter.mqh>
#include <fllib1/flgridexchange.mqh>


//советник эмуляции данных для нескольких пар одновременно.
//набор пар инициализируются в initCouples(). там же загружаюся данные для каждой пары.
//если данные не могут загрузится для пары, эта пара не попадает в контейнер m_emiter.
//данные эмулируются только для тех пар, по которым успешно загрузились эти данные из файлов.

//данные эмулируются в виде сообщений через объект FLGridExchanger.
//одно сообщение представляется собой одно значение цены(закрытия свечи) в параметре double, 
//по инструменту(параметр string), параметр long это datetime текущей свечи.
//сообщения рассылаются c заданным интервал U_EmitInterval, по всем парам.
//Один тик имитации соответствует одной свече с заданным периодом U_TimeFrame.
//если для какого-то времени нет данных по свече, отправляется цена прошлой свечи, но с новым временем 

#define MSG_TIMER_INTERVAL      5
//#define MAIN_TIMER_INTERVAL_MS     3000

input int U_TimeFrame = 1; //Chart timeframe
input int U_EmitInterval = 500; //Emulate interval, ms
input int U_BeginDT = 20210601; //Start date
input int U_EndDT = 20210801; //Finish date




//working vars
datetime init_delay; //используется при запуске, задержка после инициализации
datetime msg_time; //используется для проверки новых поступивших сообщений от др советников
LDataEmiter m_emiter;
FLGridExchanger m_exchanger;
bool is_running;
bool data_loaded = false;


//+------------------------------------------------------------------+
//| Expert template functions                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   msg_time = init_delay = TimeLocal();
   data_loaded = false;
   initCouples();
   is_running = true;
   
   Print("-------------------- DATA EMITER STARTED!!!--------------------------");
   m_exchanger.setKey("data_emiter");
   m_exchanger.setOwnChartID(ChartID());
   EventSetMillisecondTimer(U_EmitInterval);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
}
void OnTimer()
{

   //Print("OnTimer() dataemiter");
   mainExec();
   
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (sparam == m_exchanger.key()) return;
   if (id < CHARTEVENT_CUSTOM) return;

   m_exchanger.receiveMsg(id, lparam, dparam, sparam);
}
void mainExec()
{
   if (LDateTime::dTime(init_delay, TimeLocal()) < 10) return;
   if (!data_loaded) return;
   
   if (LDateTime::dTime(msg_time, TimeLocal()) > MSG_TIMER_INTERVAL)
   {
      Print("read msg");
      msg_time = TimeLocal();
      readExchamgerNewMessages();
      return;
   }
   
   if (is_running) emitNextData();
   else Print("is_running == false");
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void emitNextData() //отправить очередную порцию данных по всем инструментам
{
   //Print("1");
   if (m_emiter.finished()) 
   {
      Print("Emiter finished!");
      is_running = false;
      return;
   }
   
//   Print("2");
   LMapStringDouble map;
   datetime dt;
   m_emiter.nextData(map, dt);
   if (map.isEmpty()) {Print("emitNextData(): WARNING next data is empty!"); return;}
   
   //prepare message
   FLGridExchangeMsg msg;
   msg.message_type = ExchangeMsgType::emtEmitData_TestMode;
   msg.i_value = dt;
   
   //send emiting data
   const LStringList *keys = map.keys();
   int n = keys.count();
   //Print("n=", n);
   for (int i=0; i<n; i++)
   {
      //одно сообщение представляется собой одно значение цены(закрытия свечи) в параметре double, 
      //по инструменту(параметр string), параметр long это datetime текущей свечи.
      msg.d_value = map.value(keys.at(i));
      msg.str_value = keys.at(i);
      m_exchanger.sendMsg(msg);
   }
}
void readExchamgerNewMessages() //ловит сообщения для останова/запуска генерации данных
{
   if (!m_exchanger.hasNewMessages()) return;
   
   int n = m_exchanger.msgCount();
   for (int i=0; i<n; i++)
   {
      if (m_exchanger.isRecReaded(i)) continue;
   
      FLGridExchangeMsg msg;
      m_exchanger.getRecord(i, msg);
      switch (msg.message_type)
      {
         case emtStartData_TestMode: 
         {
            is_running = true; 
            break;
         }
         case emtStopData_TestMode: 
         {
            is_running = false; 
            m_emiter.stop(); 
            break;
         }
         default: break;
      }
   }   
}
void initCouples()
{
   m_emiter.setTimeRange(U_BeginDT, U_EndDT);
   m_emiter.setTimeFrame(U_TimeFrame);
   
   Print("try load data......");
   //m_emiter.addCouple("USDJPY");
   m_emiter.addCouple("USDCAD");
   m_emiter.addCouple("AUDUSD");
   //m_emiter.addCouple("EURJPY");
   
   
   Print("couples successed loaded: ", m_emiter.count());
   m_emiter.stop(); 
   data_loaded = true;
   
}

