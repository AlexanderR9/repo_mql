//+------------------------------------------------------------------+
//|                                                         func.mq4 |
//|                      Copyright © 2008, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#property strict


// class LDateTime
class LDateTime
{
public:
   //возвращает текущее значение GMT
   static datetime gmt();

   //возвращает текущую дату сервера, c - разделитель , некоторые спец символы ставить нельзя
   // пример: 12^03^2008 (c = "^"), по умолчанию с = "_"
   static string currentDateServ(string c = "_");

   // возвращает текущее время сервера, c - разделитель , некоторые спец символы ставить нельзя
   // пример: 12:03 (c = ":"), по умолчанию с = ":"
   // если ifSec=true время выводится с секундами(12:03:45) иначе только часы и минуты (12:03)
   static string currentTimeServ(string c=":", bool ifSec=false);

   // возвращает текущее дату и время сервера, c1 - разделитель в формате даты, c2 - разделитель в формате времени,
   // если ifSec=true время выводится с секундами(12:03:45) иначе только часы и минуты (12:03)
   static string currentDateTimeServ(string c1="_", string c2=":", bool ifSec=false);

   //возвращает текущую дату локального компа, c - разделитель , некоторые спец символы ставить нельзя
   // пример: 12^03^2008 (c = "^"), по умолчанию с = "_"
   static string currentDate(string c="_");

   // возвращает текущее время локального компа, c - разделитель , некоторые спец символы ставить нельзя
   // пример: 12:03 (c = ":"), по умолчанию с = ":"
   // если ifSec=true время выводится с секундами(12:03:45) иначе только часы и минуты (12:03)
   static string currentTime(string c=":", bool ifSec=false);

   // возвращает текущее дату и время локального компа, c1 - разделитель в формате даты, c2 - разделитель в формате времени,
   // если ifSec=true время выводится с секундами(12:03:45) иначе только часы и минуты (12:03)
   static string currentDateTime(string c1="_", string c2=":", bool ifSec=false);
   
   //возвращает текущую дату GMT, c - разделитель , некоторые спец символы ставить нельзя
   // пример: 12^03^2008 (c = "^"), по умолчанию с = "_"
   static string currentDateGMT(string c="_");

   // возвращает текущее время GMT, c - разделитель , некоторые спец символы ставить нельзя
   // пример: 12:03 (c = ":"), по умолчанию с = ":"
   // если ifSec=true время выводится с секундами(12:03:45) иначе только часы и минуты (12:03)
   static string currentTimeGMT(string c=":", bool ifSec=false);

   // возвращает текущее дату и время GMT, c1 - разделитель в формате даты, c2 - разделитель в формате времени,
   // если ifSec=true время выводится с секундами(12:03:45) иначе только часы и минуты (12:03)
   static string currentDateTimeGMT(string c1="_", string c2=":", bool ifSec=false);

   //разница между двумя значениями времени в секундах
   //при условии t2 > t1
   static int dTime(datetime t1, datetime t2);
   
   //признак того, указанное время - выходной день
   static bool isHoliday(datetime t1);
   
   //признак того, текущее время локального компа - выходной день
   static bool isHolidayNow() {return isHoliday(TimeLocal());}
   
   //к заданому времени добавляет количество секунд, secs может быть отрицательным 
   static void addSecs (datetime &dt, int secs) {dt += secs;}
   
   //к заданому времени добавляет количество часов, hours может быть отрицательным 
   static void addHour (datetime &dt, int hours) {addSecs(dt, hours*3600);}

   //к заданому времени добавляет количество дней, days может быть отрицательным 
   static void addDays (datetime &dt, int days) {addHour(dt, days*24);}
   
   //возвращает время равнозначное началу 20-го года (01.01.2020 00:00)
   static datetime year20() {datetime dt=D'2020.01.01 00:00'; return dt;}
   
   //признак того, что текущее время выходит за диапазон торговой недели
   //параметры: mh, mm - локальные часы и минуты понедельника (начало торговли),
   //fh, fm - локальные часы и минуты пятницы (конец торговли)
   //если какая то пара мельше 0, то граница не задана
   static bool overWeekTrade(int mh, int mm, int fh, int fm);

   static string dateToString(const datetime &dt, string c);
   static string timeToString(const datetime &dt, string c, bool ifSec);
   static string dateTimeToString(const datetime &dt, string c1, string c2, bool ifSec);
   
   //преобразование строки в datetime, ok - признак успешности.
   //строка должна быть формата: (01.01.2020 00:00:00) или (01.01.2020 00:00)
   //может присутствовать только дата или же только время т.е. (01.01.2020) или (00:00),
   //если дата отсутствует то она установится текущая локальная,
   //если время отсутствует то оно установится (00:00).
   //в случае неудачи вернет year20()
   static datetime fromString(string s, bool &ok);
   
private:  
   static void parseDate(const string&, int&, int&, int&); //парсит строку типа  01.01.2020
   static void parseTime(const string&, int&, int&, int&); //парсит строку типа  00:00:00 или 00:00
   
};






///////////// CPP DESCRIPTION //////////////////////
datetime LDateTime::fromString(string s, bool &ok)
{
   ok = false;
   datetime dt = TimeLocal();
   
   s = StringTrimLeft(s);
   s = StringTrimRight(s);
   if (StringLen(s) < 3) return year20();
   
   string s_date = "";
   string s_time = "";
   int pos = StringFind(s, " ");
   if (pos > 0)
   {
      s_date = StringSubstr(s, 0, pos);
      s_date = StringTrimLeft(s_date);
      s_date = StringTrimRight(s_date);
      
      s_time = StringSubstr(s, pos+1);
      s_time = StringTrimLeft(s_time);
      s_time = StringTrimRight(s_time);
      
      if (s_date == "" || s_time == "") return year20();
      s = "";
   }
   
   /////////////////////////////////////////////////
   MqlDateTime dt_struct;
   if (s == "")
   {
      int day, month, year;
      parseDate(s_date, day, month, year);
      if (day < 0) return year20();
      
      int hour, min, sec;
      parseTime(s_time, hour, min, sec);
      if (hour < 0) return year20();    
      
      dt_struct.day = day;
      dt_struct.mon = month;
      dt_struct.year = year;
      dt_struct.hour = hour;
      dt_struct.min = min;
      dt_struct.sec = sec;
   }
   else //s - либо дата либо время
   {
      int day, month, year;
      parseDate(s, day, month, year);
      if (day < 0) //только время
      {
         int hour, min, sec;
         parseTime(s, hour, min, sec);
         if (hour < 0) return year20();    
         
         dt_struct.day = TimeDay(dt);
         dt_struct.mon = TimeMonth(dt);
         dt_struct.year = TimeYear(dt);
         dt_struct.hour = hour;
         dt_struct.min = min;
         dt_struct.sec = sec;         
      }
      else //только дата
      {
         dt_struct.day = day;
         dt_struct.mon = month;
         dt_struct.year = year;
         dt_struct.hour = 0;
         dt_struct.min = 0;
         dt_struct.sec = 0;
      }
   }   
   
   ok = true;
   return StructToTime(dt_struct);
}
void LDateTime::parseDate(const string &s, int &day, int &month, int &year)
{
   day = month = year = -1;
   string arr[];
   StringSplit(s, StringGetCharacter(".", 0), arr);
   if (ArraySize(arr) != 3) return;
   day = StrToInteger(arr[0]);
   if (day < 1 || day > 31) {day = month = year = -1; return;}
   month = StrToInteger(arr[1]);
   if (month < 1 || month > 12) {day = month = year = -1; return;}
   year = StrToInteger(arr[2]);
   if (year < 2000 || year > 2100) {day = month = year = -1; return;}   
}
void LDateTime::parseTime(const string &s, int &hour, int &min, int &sec)
{
   hour = min = sec = -1;
   string arr[];
   StringSplit(s, StringGetCharacter(":", 0), arr);
   int arr_size = ArraySize(arr);
   if (arr_size != 3 && arr_size != 2) return;
   
   hour = StrToInteger(arr[0]);
   if (hour < 0 || hour > 23) {hour = min = sec = -1; return;}
   min = StrToInteger(arr[1]);
   if (min < 0 || min > 59) {hour = min = sec = -1; return;}
   if (arr_size == 3)
   {
      sec = StrToInteger(arr[2]);
      if (sec < 0 || sec > 59) {hour = min = sec = -1; return;}
   }
   else sec = 0;
}
bool LDateTime::overWeekTrade(int mh, int mm, int fh, int fm)
{
   datetime dt = TimeLocal();
   int d = TimeDayOfWeek(dt);
   if (d == 6 || d == 0) return true;
   
   int h = TimeHour(dt);
   int m = TimeMinute(dt);
   
   if (d == 1)
   {
      if (mh < 0 || mm < 0) return false;
      if (h < mh) return true;
      if (h == mh && m < mm) return true;
   }
   else if (d == 5)
   {
      if (fh < 0 || fm < 0) return false;
      if (h > fh) return true;
      if (h == fh && m > fm) return true;
   }

   return false;
}
bool LDateTime::isHoliday(datetime t1)
{
   int d = TimeDayOfWeek(t1);
   if (d > 5 || d == 0) return true;
   return false;
}
string LDateTime::dateToString(const datetime &dt, string c)
{
   int d = TimeDay(dt);
   string sd = IntegerToString(d);
   if (d < 10) sd = ("0" + sd);

   int m = TimeMonth(dt);
   string sm = IntegerToString(m);
   if (m < 10) sm = ("0" + sm);
   
   string sy = IntegerToString(TimeYear(dt));
   
   return (sd + c + sm + c + sy);
}
string LDateTime::timeToString(const datetime &dt, string c, bool ifSec)
{
   int h = TimeHour(dt);
   string sh = IntegerToString(h);
   if (h < 10) sh = ("0" + sh);
   
   int min = TimeMinute(dt);
   string smin = IntegerToString(min);
   if (min < 10) smin = ("0" + smin);

   int sec = TimeSeconds(dt);
   string ssec = IntegerToString(sec);
   if (sec < 10) ssec = ("0" + ssec);

   if(ifSec) return (sh + c + smin + c + ssec);
   return (sh + c + smin);
   
   /*
   return (    
               DoubleToStr(TimeHour(dt), 0) + c +
               DoubleToStr(TimeMinute(dt), 0) + c +
               DoubleToStr(TimeSeconds(dt), 0)
          );
       
   return (    
               DoubleToStr(TimeHour(dt), 0) + c +
               DoubleToStr(TimeMinute(dt), 0)
          );
          */
}
string LDateTime::dateTimeToString(const datetime &dt, string c1, string c2, bool ifSec)
{
   string s_date = dateToString(dt, c1);
   string s_time = timeToString(dt, c2, ifSec);
   return (s_date + "  " + s_time);
}

datetime LDateTime::gmt()
{
   //return (TimeLocal() + D_GMT*3600);
   return TimeGMT();
}
string LDateTime::currentDateServ(string c)
{
   datetime dt = TimeCurrent();
   return dateToString(dt, c);
}
string LDateTime::currentTimeServ(string c, bool ifSec)
{
   datetime dt = TimeCurrent();
   return timeToString(dt, c, ifSec);
}
string LDateTime::currentDateTimeServ(string c1, string c2, bool ifSec)
{
   datetime  dt = TimeCurrent();
   return dateTimeToString(dt, c1, c2, ifSec);
}
string LDateTime::currentDate(string c)
{
   datetime  dt = TimeLocal();
   return dateToString(dt, c);
}
string LDateTime::currentTime(string c, bool ifSec)
{
   datetime  dt = TimeLocal();
   return timeToString(dt, c, ifSec);
}
string LDateTime::currentDateTime(string c1, string c2, bool ifSec)
{
   datetime  dt = TimeLocal();
   return dateTimeToString(dt, c1, c2, ifSec);
}
string LDateTime::currentDateGMT(string c)
{
   datetime  dt = gmt();
   return dateToString(dt, c);
}
string LDateTime::currentTimeGMT(string c, bool ifSec)
{
   datetime  dt = gmt();
   return timeToString(dt, c, ifSec);
}
string LDateTime::currentDateTimeGMT(string c1, string c2, bool ifSec)
{
   datetime  dt = gmt();
   return dateTimeToString(dt, c1, c2, ifSec);
}
int LDateTime::dTime(datetime t1, datetime t2)
{
      if (t2 < t1) return (-1);     
      return int(t2 - t1);
}


