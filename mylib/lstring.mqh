//+------------------------------------------------------------------+
//|                                                      lstring.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <mylib/lcontainer.mqh>

// class LStringWorker
class LStringWorker
{
public:
   static string trim(const string&); 
   
   static void split(const string &text, string sep, LStringList &arr, bool include_empty = false); 
   


};


string LStringWorker::trim(const string &s)
{
   string result = StringTrimLeft(s);
   result = StringTrimRight(result);
   return result;
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





