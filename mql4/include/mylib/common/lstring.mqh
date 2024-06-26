//+------------------------------------------------------------------+
//|                                                      lstring.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/common/lcontainer.mqh>


// class LStringWorker
class LStringWorker
{
public:
   static string trim(const string&); 
   static bool contains(const string &source, string find_text) {return (StringFind(source, find_text) >= 0);}
   static string toLower(const string&);
   static string toUpper(const string&);
   static int indexOf(const string&, string find_text, int start_pos = -1);
   
   static void split(const string &text, string sep, LStringList &arr, bool include_empty = false); 
   
   static string left(string, int); //возвращает n символов слева, исходную строку не меняет
   static string right(string, int);//возвращает n символов справа, исходную строку не меняет
   static string cutLeft(string, int); //отрезает n символов слева и возвращает строку без них, исходную строку не меняет
   static string cutRight(string, int);//отрезает n символов справа и возвращает строку без них, исходную строку не меняет
   
   //парсит строку типа AUDUSD; EURUSD; USDJPY .....
   //извлекает набор пар и добавляет в arr
   //регистр не важен, все преобразуется к заглавным буквам
   //невалидные или повторяющиеся пары не добавятся
   static void parseCouples(const string &text, LStringList &arr);
   
   //проверяет существование инструмента
   static bool isValidSymbol(string v);
   
   static string lineBreakeSymbol() {return "\n";}
   
   //возвращает строку состоящую из N одинаковых символов
   static string symbolString(char c, uint  N = 10);


};
string LStringWorker::symbolString(char c, uint N)
{
   string s;
   for (uint i=0; i<N; i++) s += CharToStr(c);
   return s;
}
int LStringWorker::indexOf(const string &source, string find_text, int start_pos)
{
   if (start_pos < 0) start_pos = 0;
   return StringFind(source, find_text, start_pos);
}
string LStringWorker::toLower(const string &source) 
{
   string s = source;
   StringToLower(s);
   return s;
}
string LStringWorker::toUpper(const string &source) 
{
   string s = source;
   StringToUpper(s);
   return s;
}
string LStringWorker::cutLeft(string s, int n)
{
   if (n <= 0) return s;
   if (n >= StringLen(s)) return "";
   return right(s, StringLen(s) - n);
}
string LStringWorker::cutRight(string s, int n)
{
   if (n <= 0) return s;
   if (n >= StringLen(s)) return "";
   return left(s, StringLen(s) - n);
}
string LStringWorker::left(string s, int n)
{
   if (n <= 0) return "";
   if (n >= StringLen(s)) return s;
   return StringSubstr(s, 0, n); 
}
string LStringWorker::right(string s, int n)
{
   if (n <= 0) return "";
   int len = StringLen(s);
   if (n >= len) return s;
   return StringSubstr(s, len - n); 
}
string LStringWorker::trim(const string &s)
{
   string result = StringTrimLeft(s);
   result = StringTrimRight(result);
   return result;
}
void LStringWorker::parseCouples(const string &text, LStringList &arr)
{
   arr.clear();
   LStringList list;
   split(text, ";", list);
   if (list.isEmpty()) return;
   
   int n = list.count();
   for (int i=0; i<n; i++)
   {
      string v = list.at(i);
      v = trim(v);
      StringToUpper(v);
      if (arr.contains(v)) continue;
      if (isValidSymbol(v)) arr.append(v);
   }
}
bool LStringWorker::isValidSymbol(string v)
{
   int n = SymbolsTotal(false);
   for (int i=0; i<n; i++)
      if (SymbolName(i, false) == v) return true;
   return false;
}
void LStringWorker::split(const string &text, string sep, LStringList &arr, bool include_empty)
{
   arr.clear();
   if (sep == "") return;
   
   int start_pos = 0;
   int pos = -1;
   int sep_len = StringLen(sep);
   string el;
   
   for (;;)
   {
      pos = StringFind(text, sep, start_pos);
      if (pos < 0) break;
      
      el = StringSubstr(text, start_pos, pos - start_pos);
      if (include_empty) arr.append(el);
      else
      {
         if (trim(el) != "") arr.append(el);
      }   
      
      start_pos = pos + sep_len;
   }
   
   el = StringSubstr(text, start_pos);
   if (include_empty) arr.append(el);
   else
   {
      if (trim(el) != "") arr.append(el);
   }   
}





