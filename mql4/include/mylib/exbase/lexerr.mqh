//+------------------------------------------------------------------+
//|                                                         lerr.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include <mylib/common/lfile.mqh>
#include <mylib/common/ldatetime.mqh>
#include <mylib/exbase/lexparamsenum.mqh>

//базовый класс счетчика ошибок и изменений состояния
class MQErrBase
{
public:
    MQErrBase() {}

   //установить файл протокола 
    virtual void setProtocolFileName(const string&);

protected:
    string m_protocol_file;

   //добавить сообщение в файл, перед сообщением вставится текущие дата и время
    virtual void appendToPtotocol(const string&);
    
};
void MQErrBase::setProtocolFileName(const string &fname)
{
   m_protocol_file = fname;
   m_protocol_file = StringTrimLeft(m_protocol_file);
   m_protocol_file = StringTrimRight(m_protocol_file);
}
void MQErrBase::appendToPtotocol(const string &line)
{
   if (StringLen(m_protocol_file) < 5) 
   {
      Print("MQErrBase: invalid protocol file name!" + "[" + m_protocol_file + "]");
      return;   
   }

   string s = LDateTime::currentDateTime(".",  ":", true) + "   " + line;
   if (!LFile::appendToFile(m_protocol_file, s))
        Print("MQErrBase: error append to protocol file new message!");
}


///////////class MQErr/////////////////////////////////
class MQErr : public MQErrBase
{
public:
    MQErr() {}
    
    //возвращает количество ошибок с указанным кодом code
    //если code = etUnknown, то вернет количество всех ошибок
    int errCount(int code = etUnknown) const;
    
    //добавить ошибку в контейнер и в файл
    void appendError(int, const string other = "");
    
    //заружает старые ошибки из файла, если он существует (обычно при старте советника)
    void load();
    
protected:
   LIntList m_errors;    
    
};    
void MQErr::load()
{
   if (LFile::isFileExists(m_protocol_file))
   {
      LStringList list;
      LFile::readFileToStringList(m_protocol_file, list);
      
      for (int i=0; i<list.count(); i++)
      {
         string s = list.at(i);
         int pos = StringFind(s, "code");
         if (pos < 0) continue;
         int pos2 = StringFind(s, " ", pos+1);
         if (pos2 < 0) continue;
         string s_value = StringSubstr(s, pos+5, pos2-pos-5);
         int code = StrToInteger(s_value);
         if (GetLastError() == 0) 
         {
            m_errors.append(code);
            //Print("last err code ", m_errors.last());    
         }
         else Print("MQErr::load() - error convert string to int code");

      }
   }
}
int MQErr::errCount(int code) const
{
   if (code == etUnknown)
      return m_errors.count();
      
   int n = m_errors.count();
   int n_err = 0;
   for (int i=0; i<n; i++)
      if (m_errors.at(i) == code) n_err++;
   return n_err;   
}
void MQErr::appendError(int code, const string other)
{
   m_errors.append(code);
   string f_line = "code=" + IntegerToString(code) + "  " + MQEnumsStatic::strByType(code);
   if (other != "") f_line += (", " + other);
   f_line += ("   (GetLastError()=" + IntegerToString(GetLastError()) + ")");
   f_line += "   err_count = "+IntegerToString(m_errors.count());   
   appendToPtotocol(f_line);
}



///////////class MQConnectionState/////////////////////////////////
//класс для периодической проверки состояния соединения с сервером
class MQConnectionState : public MQErrBase
{
public:
    MQConnectionState() :m_state(etConnectionStateOk), err_count(0) {}

   // вернуть последнее состояние соедиения 
    bool curStateOk() const {return (m_state == etConnectionStateOk);}
    
    //проверить текущее состояние соединения и при необходимости обновить m_state и добавить сообщение в протокол
    void checkState();
    
    void expertInit(); //инициализации объекта
    void expertDeinit(); //завершение работы объекта
    
    //количество разрывов
    inline int connectionLossCount() const {return err_count;}


protected:
    int m_state;
    int err_count;

    void stateChanged();
    
};
void MQConnectionState::expertInit()
{
   string f_line = "expert was init! "; 
   appendToPtotocol(f_line);
}
void MQConnectionState::expertDeinit()
{
   string f_line = "expert was deinit! "; 
   appendToPtotocol(f_line);
}
void MQConnectionState::checkState()
{
   if (IsConnected())
   {
      if (!curStateOk()) 
      {
         m_state = etConnectionStateOk;
         stateChanged();
      }
   }
   else
   {
      if (curStateOk()) 
      {
         err_count++;
         m_state = etConnectionStateFault;
         stateChanged();
      }   
   }
}
void MQConnectionState::stateChanged()
{
   string f_line = MQEnumsStatic::strByType(m_state);
   f_line += ("   (GetLastError()=" + IntegerToString(GetLastError()) + ")");
   if (!curStateOk()) f_line += "   err_count = "+IntegerToString(err_count);
   appendToPtotocol(f_line);
}





