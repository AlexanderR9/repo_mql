//+------------------------------------------------------------------+
//|                                                   tg_structs.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

//#include <Object.mqh>
#include <Arrays\List.mqh>


//telegram bot message
class CCustomMessage : public CObject
{
public:
   CCustomMessage();
   CCustomMessage(const CCustomMessage&);
     
   long              update_id;
   long              message_id;
   string            from_first_name;
   string            from_last_name;
   string            from_username;
   long              chat_id;
   string            chat_first_name;
   string            chat_last_name;
   string            chat_username;
   string            chat_type;
   datetime          message_date;
   string            message_text;
   bool              checked; //пользователь сам устанавливает когда прочет его
   
   string userInfo() const;
   string chatInfo() const;
   string msgInfo() const;
   
    
};
string CCustomMessage::msgInfo() const
{
   string s = "MSG: ";
   s += (TimeToString(message_date)+"  text=["+message_text+"]  ");
   s += ("  update_id="+IntegerToString(update_id));
   s += ("  message_id="+IntegerToString(message_id));
   return s;   
}
string CCustomMessage::userInfo() const
{
   string s = "MSG_USER: ";
   s += (from_first_name+"/"+from_last_name+"  ");
   s += ("  name="+from_username);
   return s;   
}
string CCustomMessage::chatInfo() const
{
   string s = "MSG_CHAT: ";
   s += ("id="+IntegerToString(chat_id)+"  type="+chat_type+"  ");
   s += (chat_first_name+"/"+chat_last_name+"  ");
   s += ("  chat_user="+chat_username);
   return s;   
}
CCustomMessage::CCustomMessage()
   :CObject()
{
   update_id=0;
   message_id=0;
   from_first_name=NULL;
   from_last_name=NULL;
   from_username=NULL;
   chat_id=0;
   chat_first_name=NULL;
   chat_last_name=NULL;
   chat_username=NULL;
   chat_type=NULL;
   message_date=0;
   message_text=NULL;
   checked = false;
}
CCustomMessage::CCustomMessage(const CCustomMessage &msg)
{
   update_id=msg.update_id;
   message_id=msg.message_id;
   from_first_name=msg.from_first_name;
   from_last_name=msg.from_last_name;
   from_username=msg.from_username;
   chat_id=msg.chat_id;
   chat_first_name=msg.chat_first_name;
   chat_last_name=msg.chat_last_name;
   chat_username=msg.chat_username;
   chat_type=msg.chat_type;
   message_date=msg.message_date;
   message_text=msg.message_text;   
   checked=msg.checked;   
}


//bot chat   
class CCustomChat
{
public:
   CCustomChat();
   virtual ~CCustomChat() {m_messages.Clear();}
   
   inline void setID(long id) {m_id = id;}
   inline long id() const {return m_id;}
   inline int msgCount() const {return m_messages.Total();}
   inline bool isEmpty() const {return (msgCount() == 0);}
   inline bool hasUncheckedMessages() {return (uncheckedMessages() > 0);}
   inline bool invalid() const {return (m_id <= 0);}
   
   void addMsg(const CCustomMessage&);
   CCustomMessage* messageAt(int);
   CCustomMessage* messageLast();
   int uncheckedMessages();
   
   
protected:
   long        m_id;
   CList       m_messages;
   int         m_state;
   datetime    m_time;
   
};
CCustomChat::CCustomChat()
   :m_id(-1),
   m_state(0)
{
   m_messages.Clear();
}
void CCustomChat::addMsg(const CCustomMessage &msg)
{
   m_messages.Add(new CCustomMessage(msg));
}
CCustomMessage* CCustomChat::messageAt(int index)
{
   if (index < 0 || index >= msgCount()) return NULL;
   return m_messages.GetNodeAtIndex(index);
}
CCustomMessage* CCustomChat::messageLast()
{
   if (isEmpty()) return NULL;
   return m_messages.GetLastNode();
}
int CCustomChat::uncheckedMessages()
{
   int n = 0;
   for (int i=0; i<msgCount(); i++)
      if (!messageAt(i).checked) n++;
   return n;      
}
   

