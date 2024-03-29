//+------------------------------------------------------------------+
//|                                                       tg_bot.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\List.mqh>
#include <mylib/tg/jason.mqh>
#include <mylib/tg/tg_structs.mqh>
#include <mylib/tg/tg_common.mqh>

//+------------------------------------------------------------------+
//|   Defines                                                        |
//+------------------------------------------------------------------+
#define TELEGRAM_BASE_URL  "https://api.telegram.org"
#define WEB_TIMEOUT        5000

//+------------------------------------------------------------------+
//|   TG base bot class                                                     |
//+------------------------------------------------------------------+
class CCustomBot
{
public:
   CCustomBot();

   inline string Name() const {return(m_name);} //nickname бота
   inline long chatID() const {return m_chat.id();} //ID чата
   inline int msgCount() const {return m_chat.msgCount();} //все поступившие сообщения (количество)
   inline bool hasUncheckedMessages() {return m_chat.hasUncheckedMessages();} //признак того что есть не прочитанные сообщения
   inline int uncheckedMessages() {return m_chat.uncheckedMessages();} //не просмотренные поступившие сообщения (количество)   
   inline CCustomMessage* messageAt(int index) {return m_chat.messageAt(index);} //получить сообщение по индексу
   inline CCustomMessage* messageLast() {return m_chat.messageLast();} //получить последнее сообщение находящееся в контейнере чата
   
   int setToken(const string); //задать токен бота
   void setChatID(long); //задать ID чата в котором бот будет общаться
   
   //telegram API function
   int getMe(); // запрос в API, получить сведения о себе
   int getUpdates(); //запрос в API, получить все новые пришедшие сообщения (если они есть)

   //is_HTML - признак того что text это html код.
   //silently - если true, это означает не требуется уведомления о доставке сообщения.
   int sendMsg(string text, bool is_HTML=false, bool silently=true);  //запрос в API, отправить сообщение в чат.
   
   //Используйте этот метод, когда вам нужно сообщить пользователю, что что-то происходит на стороне бота. 
   //Статус прорисовывается на 5 секунд или меньше.
   //Это как бы декорация для оповещения того, что бот например загружает файл или пишет сообщение.
   //Без этого метода вполне можно обойтись, используется чисто для красоты.
   int sendChatAction(ENUM_CHAT_ACTION action_type); //запрос в API, показать в чате текущее состояние бота
   

   //некоторые статические функции для парсинга ответов при запросах API
   static string stringTrim(string);
   static string stringDecode(string);
   static void stringReplace(string &string_var, const int start_pos, const int length, const string replacement);
   static string urlEncode(const string);
   static int shortToUtf8(const ushort, uchar &out[]);

   
protected:
   CCustomChat    m_chat;
   string         m_token;
   string         m_name;
   long           m_update_id;
   bool           m_first_remove;

   int postRequest(string &out, const string url, const string params, const int timeout=5000); //standard http request

};

//CPP DESC
CCustomBot::CCustomBot()
{
   m_token=NULL;
   m_name=NULL;
   m_update_id=0;
   m_first_remove=true;
}
void CCustomBot::setChatID(long chat_id)
{
   m_chat.setID(chat_id);
}
int CCustomBot::setToken(const string _token)
{
   string token = CCustomBot::stringTrim(_token);
   if(token=="") return(ERR_TOKEN_ISEMPTY);
   m_token = token;
   return(0);
}
int CCustomBot::postRequest(string &out, const string url, const string params, const int timeout)
{
   char data[];
   int data_size=StringLen(params);
   StringToCharArray(params,data,0,data_size);
   uchar result[];
   string result_headers;

   //--- application/x-www-form-urlencoded
   int res = WebRequest("POST", url, NULL, NULL, timeout, data, data_size, result, result_headers);
   switch (res)
   {
      case 200: //OK
      {
         //--- delete BOM
         int start_index=0;
         int size=ArraySize(result);
         for(int i=0; i<fmin(size,8); i++)
         {
            if(result[i]==0xef || result[i]==0xbb || result[i]==0xbf) start_index=i+1;
            else break;
         }
         out=CharArrayToString(result, start_index, WHOLE_ARRAY,CP_UTF8);
         return(0);      
      }
      case -1: return(_LastError);
      default: break;   
   }
   
   //--- HTTP errors
   if(res>=100 && res<=511)
   {
      out=CharArrayToString(result, 0, WHOLE_ARRAY,CP_UTF8);
      Print(out);
      return(ERR_HTTP_ERROR_FIRST + res);
   }
   return(res);
}
int CCustomBot::getMe()
{
   if(m_token==NULL) return(ERR_TOKEN_ISEMPTY);

   string out;
   string url=StringFormat("%s/bot%s/getMe",TELEGRAM_BASE_URL,m_token);
   string params="";
   int res=postRequest(out,url,params,WEB_TIMEOUT);
   if(res==0)
   {
      CJAVal js(NULL,jtUNDEF);
      bool done = js.Deserialize(out);
      if(!done) return(ERR_JSON_PARSING);
      bool ok = js["ok"].ToBool();
      if(!ok) return(ERR_JSON_NOT_OK);

      if(m_name==NULL) 
         m_name=js["result"]["username"].ToStr();
   }
   return(res);
}
int CCustomBot::getUpdates()
{
   if(m_token==NULL) return(ERR_TOKEN_ISEMPTY);
   if (m_chat.invalid()) return(ERR_CHATID_INVALID);

   string out;
   string url=StringFormat("%s/bot%s/getUpdates", TELEGRAM_BASE_URL, m_token);
   string params=StringFormat("offset=%d", m_update_id);
   int res=postRequest(out, url, params, WEB_TIMEOUT);
   if(res==0)
   {
      CJAVal js(NULL, jtUNDEF);
      bool done=js.Deserialize(out);
      if(!done) return(ERR_JSON_PARSING);
      bool ok=js["ok"].ToBool();
      if(!ok) return(ERR_JSON_NOT_OK);

      CCustomMessage msg;
      int total=ArraySize(js["result"].m_e);
      for(int i=0; i<total; i++)
      {
         CJAVal item=js["result"].m_e[i];
         msg.update_id=item["update_id"].ToInt();
         msg.message_id=item["message"]["message_id"].ToInt();
         msg.message_date=(datetime)item["message"]["date"].ToInt();
         msg.message_text=item["message"]["text"].ToStr();
         msg.message_text=CCustomBot::stringDecode(msg.message_text);
         //msg.from_id=item["message"]["from"]["id"].ToInt();
         msg.from_first_name=item["message"]["from"]["first_name"].ToStr();
         msg.from_first_name=CCustomBot::stringDecode(msg.from_first_name);
         msg.from_last_name=item["message"]["from"]["last_name"].ToStr();
         msg.from_last_name=CCustomBot::stringDecode(msg.from_last_name);
         msg.from_username=item["message"]["from"]["username"].ToStr();
         msg.from_username=CCustomBot::stringDecode(msg.from_username);
         msg.chat_id=item["message"]["chat"]["id"].ToInt();
         msg.chat_first_name=item["message"]["chat"]["first_name"].ToStr();
         msg.chat_first_name=CCustomBot::stringDecode(msg.chat_first_name);
         msg.chat_last_name=item["message"]["chat"]["last_name"].ToStr();
         msg.chat_last_name=CCustomBot::stringDecode(msg.chat_last_name);
         msg.chat_username=item["message"]["chat"]["username"].ToStr();
         msg.chat_username=CCustomBot::stringDecode(msg.chat_username);
         msg.chat_type=item["message"]["chat"]["type"].ToStr();
         
         m_update_id = msg.update_id + 1;
         if(m_first_remove) continue;
         
         //Print(msg.msgInfo());
         //Print(msg.userInfo());
         //Print(msg.chatInfo());
         if (msg.chat_id == m_chat.id())
         {
            m_chat.addMsg(msg);
         }
         else Print("CCustomBot::getUpdates() WARNING - wrong msg.chat_id ", msg.chat_id);         
      }            
      m_first_remove = false;
   }
   return(res);
}
int CCustomBot::sendMsg(string text, bool is_HTML, bool silently)
{
   if(m_token==NULL) return(ERR_TOKEN_ISEMPTY);
   if (m_chat.invalid()) return(ERR_CHATID_INVALID);

   string out;
   string url=StringFormat("%s/bot%s/sendMessage", TELEGRAM_BASE_URL, m_token);
   string params=StringFormat("chat_id=%lld&text=%s", chatID(), CCustomBot::urlEncode(text));
   //if(reply_markup != NULL) params+="&reply_markup="+reply_markup;
   if(is_HTML) params+="&parse_mode=HTML";
   if(silently) params+="&disable_notification=true";
   int res = postRequest(out, url, params, WEB_TIMEOUT);
   return(res);
}
int CCustomBot::sendChatAction(ENUM_CHAT_ACTION action_type)
{
   if(m_token==NULL) return(ERR_TOKEN_ISEMPTY);
   if (m_chat.invalid()) return(ERR_CHATID_INVALID);
   
   string out;
   string url=StringFormat("%s/bot%s/sendChatAction", TELEGRAM_BASE_URL, m_token);      
   string s_act = StringSubstr(EnumToString(action_type), 7);
   Print("act=", s_act);
   StringToLower(s_act);
   string params = StringFormat("chat_id=%lld&action=%s", chatID(), s_act);
   Print("params=", params);
   
   int res = postRequest(out, url, params, WEB_TIMEOUT);
   return(res);
}



//static funcs
string CCustomBot::urlEncode(const string text)
{
   string result=NULL;
   int length=StringLen(text);
   for(int i=0; i<length; i++)
   {
      ushort ch=StringGetCharacter(text,i);
      if((ch>=48 && ch<=57) || // 0-9
         (ch>=65 && ch<=90) || // A-Z
         (ch>=97 && ch<=122) || // a-z
         (ch=='!') || (ch=='\'') || (ch=='(') ||
         (ch==')') || (ch=='*') || (ch=='-') ||
         (ch=='.') || (ch=='_') || (ch=='~'))
      {
         result+=ShortToString(ch);
      }
      else
      {
         if(ch==' ') result+=ShortToString('+');
         else
         {
            uchar array[];
            int total=CCustomBot::shortToUtf8(ch,array);
            for(int k=0;k<total;k++)
               result+=StringFormat("%%%02X",array[k]);
         }
      }
   }
   return result;
}
string CCustomBot::stringTrim(string text)
{
#ifdef __MQL4__
   text = StringTrimLeft(text);
   text = StringTrimRight(text);
#endif
#ifdef __MQL5__
   StringTrimLeft(text);
   StringTrimRight(text);
#endif
   return(text);
}
void CCustomBot::stringReplace(string &string_var, const int start_pos, const int length, const string replacement)
{
   string temp = ((start_pos==0) ? "" : StringSubstr(string_var, 0, start_pos));
   temp+=replacement;
   temp+=StringSubstr(string_var, start_pos+length);
   string_var = temp;
}
string CCustomBot::stringDecode(string text)
{
   StringReplace(text, "\n", ShortToString(0x0A));

   int haut=0;
   int pos=StringFind(text,"\\u");
   while(pos!=-1)
   {
      string strcode=StringSubstr(text,pos,6);
      string strhex=StringSubstr(text,pos+2,4);
      StringToUpper(strhex);

      int total=StringLen(strhex);
      int result=0;
      for(int i=0,k=total-1; i<total; i++,k--)
      {
         int coef=(int)pow(2,4*k);
         ushort ch=StringGetCharacter(strhex,i);
         if(ch>='0' && ch<='9') result+=(ch-'0')*coef;
         if(ch>='A' && ch<='F') result+=(ch-'A'+10)*coef;
      }

      if(haut!=0)
      {
         if(result>=0xDC00 && result<=0xDFFF)
         {
            int dec=((haut-0xD800)<<10)+(result-0xDC00);//+0x10000;
            CCustomBot::stringReplace(text, pos, 6, ShortToString((ushort)dec));
            haut=0;
         }
         else haut=0;
      }
      else
      {
         if(result>=0xD800 && result<=0xDBFF)
         {
            haut=result;
            CCustomBot::stringReplace(text, pos, 6, "");
         }
         else CCustomBot::stringReplace(text, pos, 6, ShortToString((ushort)result));
      }
      pos=StringFind(text,"\\u",pos);
   }
   return(text);
}
int CCustomBot::shortToUtf8(const ushort _ch,uchar &out[])
{
   if(_ch<0x80)
   {
      ArrayResize(out,1);
      out[0]=(uchar)_ch;
      return(1);
   }
   if(_ch<0x800)
   {
      ArrayResize(out,2);
      out[0] = (uchar)((_ch >> 6)|0xC0);
      out[1] = (uchar)((_ch & 0x3F)|0x80);
      return(2);
   }
   if(_ch<0xFFFF)
   {
      if(_ch>=0xD800 && _ch<=0xDFFF)//Ill-formed
      {
         ArrayResize(out,1);
         out[0]=' ';
         return(1);
      }
      else if(_ch>=0xE000 && _ch<=0xF8FF)//Emoji
      {
         int ch=0x10000|_ch;
         ArrayResize(out,4);
         out[0] = (uchar)(0xF0 | (ch >> 18));
         out[1] = (uchar)(0x80 | ((ch >> 12) & 0x3F));
         out[2] = (uchar)(0x80 | ((ch >> 6) & 0x3F));
         out[3] = (uchar)(0x80 | ((ch & 0x3F)));
         return(4);
      }
      else
      {
         ArrayResize(out,3);
         out[0] = (uchar)((_ch>>12)|0xE0);
         out[1] = (uchar)(((_ch>>6)&0x3F)|0x80);
         out[2] = (uchar)((_ch&0x3F)|0x80);
         return(3);
      }
   }
   
   ArrayResize(out,3);
   out[0] = 0xEF;
   out[1] = 0xBF;
   out[2] = 0xBD;
   return(3);
}









