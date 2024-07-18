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
   static int len(const string&);
   
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
   
   //извлекает строку обрамленную указанными разделителями.
   //если хотя бы один разделитель не найден, то вернет пустою стоку.
   //если  s_left/s_right - пустая строка то вернет все что справа/слева от не пустого разделителя.     
   //если s_left находится после s_right, то вернет пустою стоку.
   //если s_left/s_right встречаются несколько раз, то вернет результат при нахождении первой пары разделителей
   static string subStrByRange(const string &text, string s_left = "[", string s_right = "]");


};
int LStringWorker::len(const string &text)
{
   return StringLen(text);
}
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
string LStringWorker::subStrByRange(const string &text, string s_left, string s_right)
{
   string s = "";
   s_left = trim(s_left);
   s_right = trim(s_right);
   if (trim(text) == "") return s;
   if (s_left == "" && s_right == "") return s;
   
   int pos1 = -2;
   if (s_left != "")
   {
      pos1 = indexOf(text, s_left);
      if (pos1 < 0) return s;
   }
   
   int pos2 = -2;
   if (s_right != "")
   {
      pos2 = indexOf(text, s_right);
      if (pos2 < 0) return s;
   }
   
   if (pos1 == -2) s = left(text, pos2);
   else if (pos2 == -2) s = cutLeft(text, pos1+len(s_left));
   else
   {
      s = cutLeft(text, pos1+len(s_left));
      pos2 = indexOf(s, s_right);
      s = left(s, pos2);
   }
   
   return s;
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





