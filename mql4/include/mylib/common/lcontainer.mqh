//+------------------------------------------------------------------+
//|                                                   lcontainer.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


#include <mylib/common/lvalidity.mqh>


////////////////////////////////////////////////////////
// LIntList контейнер, аналог QList<int>
////////////////////////////////////////////////////////
class LIntList
{
public:
   LIntList() {clear();}
   LIntList(const LIntList&);
   virtual ~LIntList() {clear();}

   void append(int);
   int count() const {return ArraySize(m_data);}
   void clear();   
   int at(int) const;
   void removeAt(int);
   void removeLast() {removeAt(count()-1);}
   void removeFirst() {removeAt(0);}
   int indexOf(int) const;
   bool contains(int) const;
   void replace(int, int);

   double average() const;
   int sumValues() const; //сумма всех значений
   string toStrLine(string sep = ",") const; //все элементы возвращает в виде одной строки разделяя их sep


   inline bool isEmpty() const {return (count() == 0);} 
   inline int first() const {if (isEmpty()) return int(MQValidityData::errValue()); return at(0);}
   inline int last() const {if (isEmpty()) return int(MQValidityData::errValue()); return at(count()-1);}
   
   string out() const;
   
protected:
   int m_data[];           // data array

};
LIntList::LIntList(const LIntList &data)
{
   clear();
   int n = data.count();
   for (int i=0; i<n; i++)
      append(data.at(i));
}
string LIntList::toStrLine(string sep) const
{
   LStringList s_list;
   if (!isEmpty())
   {
      int n = count();
      for (int i=0; i<n; i++) 
         s_list.append(IntegerToString(at(i)));
   }
   return s_list.toStrLine(sep);
}
double LIntList::average() const
{
   if (isEmpty()) return 0;
   double a = sumValues();
   return (a/count());
}
int LIntList::sumValues() const
{
   if (isEmpty()) return 0;
   int sum = 0;
   int n = count();
   for (int i=0; i<n; i++) sum += at(i);
   return sum;
}
void LIntList::replace(int index, int value)
{
   if (index < 0 || index >= count()) return;
   m_data[index] = value;
}
bool LIntList::contains(int value) const
{
   int n = count();
   if (n == 0) return false;

   for (int i=0; i<n; i++)
      if (m_data[i] == value) return true;
      
   return false;   
}
int LIntList::indexOf(int value) const
{
   int n = count();
   if (n == 0) return -1;

   for (int i=0; i<n; i++)
      if (m_data[i] == value) return i;
      
   return -1;   
}
string LIntList::out() const
{
   int n = count();
   if (n == 0) return "Array is empty!";
   
   string s = "size="+IntegerToString(count())+",  array values: ";
   for (int i=0; i<n; i++)
      s += IntegerToString(i) + "[" + IntegerToString(m_data[i]) + "]  ";
   return s;
}
int LIntList::at(int index) const
{
   if (index < 0 || index >= count()) return int(MQValidityData::errValue());
   return m_data[index];
}
void LIntList::removeAt(int index)
{
   if (index < 0 || index >= count()) return;
   int n = count();
   for (int i=index+1; i<n; i++)
      m_data[i-1] = m_data[i];
      
   ArrayResize(m_data, n-1);
}
void LIntList::clear()
{
   ArrayFree(m_data);
   ArrayResize(m_data, 0);
}
void LIntList::append(int value)
{
   int n = count();
   ArrayResize(m_data, n+1);
   m_data[n] = value;
};


////////////////////////////////////////////////////////
// LDoubleList контейнер, аналог QList<double>
////////////////////////////////////////////////////////
class LDoubleList
{
public:
   LDoubleList() {clear();}
   virtual ~LDoubleList() {clear();}

   void append(double);
   int count() const {return ArraySize(m_data);}
   bool isEmpty() const {return (count() == 0);}
   void clear();   
   void removeAt(int);
   void removeLast() {removeAt(count()-1);}
   void removeFirst() {removeAt(0);}
   int indexOf(double) const;
   bool contains(double) const;
   void replace(int, double);
   

   double at(int) const;
   double first() const;
   double last() const;
   double average() const;
   
   string out() const;
   
protected:
   double m_data[];           // data array

};
void LDoubleList::replace(int index, double value)
{
   if (index < 0 || index >= count()) return;
   m_data[index] = value;
}
bool LDoubleList::contains(double value) const
{
   int n = count();
   if (n == 0) return false;

   for (int i=0; i<n; i++)
      if (m_data[i] == value) return true;
      
   return false;   
}
int LDoubleList::indexOf(double value) const
{
   int n = count();
   if (n == 0) return -1;

   for (int i=0; i<n; i++)
      if (m_data[i] == value) return i;
      
   return -1;   
}
string LDoubleList::out() const
{
   int n = count();
   if (n == 0) return "Array is empty!";
   
   string s = "size="+IntegerToString(count())+",  array values: ";
   for (int i=0; i<n; i++)
      s += IntegerToString(i) + "[" + DoubleToString(m_data[i], 4) + "]  ";
   return s;
}
double LDoubleList::at(int index) const
{
   if (index < 0 || index >= count()) return int(MQValidityData::errValue());
   return m_data[index];
}
double LDoubleList::first() const
{
   if (isEmpty()) return int(MQValidityData::errValue());
   return m_data[0];
}
double LDoubleList::last() const
{
   if (isEmpty()) return int(MQValidityData::errValue());
   return m_data[count()-1];
}
double LDoubleList::average() const
{
   if (isEmpty()) return 0;
   double a = 0;
   int n = count();
   for (int i=0; i<n; i++) a += at(i);
   return (a/n);
}
void LDoubleList::removeAt(int index)
{
   if (index < 0 || index >= count()) return;
   int n = count();
   for (int i=index+1; i<n; i++)
      m_data[i-1] = m_data[i];
      
   ArrayResize(m_data, n-1);
}
void LDoubleList::clear()
{
   ArrayFree(m_data);
   ArrayResize(m_data, 0);
}
void LDoubleList::append(double value)
{
   int n = count();
   ArrayResize(m_data, n+1);
   m_data[n] = value;
};



////////////////////////////////////////////////////////
// LStringList контейнер, аналог QStringList
////////////////////////////////////////////////////////
class LStringList
{
public:
   LStringList() {clear();}
   virtual ~LStringList() {clear();}


   void append(string);
   void append(const LStringList&);
   int count() const {return ArraySize(m_data);}
   bool isEmpty() const {return (count() == 0);}
   void clear();   
   string at(int) const;
   void removeAt(int);
   void removeLast() {removeAt(count()-1);}
   void removeFirst() {removeAt(0);}
   int indexOf(string) const;
   bool contains(string) const;
   void replace(int, string);
   //void splitFromString(string, string); has about LString class
   
   //удаляет все пустые строки в начале и конце массива, если таковые имеются. 
   //если all==true то вообще все пустые строки
   void trim(bool all = false); 
  
   string toStrLine(string sep = ",") const; //все элементы возвращает в виде одной строки разделяя их sep
   
   string out() const;
   
protected:
   string m_data[];           // data array

};
string LStringList::toStrLine(string sep) const
{
   if (isEmpty()) return "IS_EMPTY";
   
   string s = at(0);
   int n = count()-1;
   if (n > 0)
   {
      for (int i=1; i<=n; i++)
         s += StringConcatenate(sep, " ", at(i));
   }   
   return s;
}
/*
void LStringList::splitFromString(string s, string split_symbol)
{
   clear();
   s = StringTrimLeft(s);
   s = StringTrimRight(s);
   if (s == "") return;
   
   int start_pos = 0;
   for(;;)
   {
      int pos = StringFind(s, split_symbol, start_pos);
      if (pos < 0) 
      {
         append(StringSubstr(s, start_pos, StringLen(s)-start_pos));
         break;
      }
      else
      {
         append(StringSubstr(s, start_pos, pos-start_pos));
         start_pos = pos + 1;
      }      
   }
}
*/
void LStringList::replace(int index, string value)
{
   if (index < 0 || index >= count()) return;
   m_data[index] = value;
}
bool LStringList::contains(string value) const
{
   int n = count();
   if (n == 0) return false;

   for (int i=0; i<n; i++)
      if (m_data[i] == value) return true;
      
   return false;   
}
int LStringList::indexOf(string value) const
{
   int n = count();
   if (n == 0) return -1;

   for (int i=0; i<n; i++)
      if (m_data[i] == value) return i;
      
   return -1;   
}
string LStringList::out() const
{
   int n = count();
   if (n == 0) return "Array is empty!";
   
   string s = "size="+IntegerToString(count())+",  array values: ";
   for (int i=0; i<n; i++)
      s += IntegerToString(i) + "[" + m_data[i] + "]  ";
   return s;
}
string LStringList::at(int index) const
{
   int err = int(MQValidityData::errValue());
   if (index < 0 || index >= count()) return IntegerToString(err);
   return m_data[index];
}
void LStringList::removeAt(int index)
{
   if (index < 0 || index >= count()) return;
   int n = count();
   for (int i=index+1; i<n; i++)
      m_data[i-1] = m_data[i];
      
   ArrayResize(m_data, n-1);
}
void LStringList::trim(bool all)
{
   if (isEmpty()) return;
   
   int n = count();
   string s;
   
   //remove last
   for (int i=n-1; i>=0; i--)
   {
      s = StringTrimLeft(at(i));
      s = StringTrimRight(s);
      if (s == "") removeAt(i);
      else break;
   }

   //remove first   
   while (2 > 1)
   {
      if (isEmpty()) break;
   
      s = StringTrimLeft(at(0));
      s = StringTrimRight(s);
      if (s == "") removeFirst();
      else break;
   }
   
   //remove mid
   if (all && !isEmpty())
   {
      n = count();
      for (int i=n-1; i>=0; i--)
      {
         s = StringTrimLeft(at(i));
         s = StringTrimRight(s);
         if (s == "") removeAt(i);   
      }
   }
}
void LStringList::clear()
{
   ArrayFree(m_data);
   ArrayResize(m_data, 0);
}
void LStringList::append(string value)
{
   int n = count();
   ArrayResize(m_data, n+1);
   m_data[n] = value;
};
void LStringList::append(const LStringList &other)
{
   if (other.isEmpty()) return;
   
   for(int i=0; i<other.count(); i++)
      append(other.at(i));   
}


////////////////////////////////////////////////////////
// LMapIntDouble контейнер, аналог QMap<int, double>
////////////////////////////////////////////////////////
class LMapIntDouble
{
public:
   struct LIntDoublePair
   {
      LIntDoublePair() :key(0), value(0) {}
      LIntDoublePair(int a, double b) :key(a), value(b) {}
      LIntDoublePair(const LIntDoublePair &p) :key(p.key), value(p.value) {}
      
      int key;
      double value;
   };
   
   LMapIntDouble() {clear();}
   LMapIntDouble(const LMapIntDouble&);
   virtual ~LMapIntDouble() {clear();}

   void clear() {m_keys.clear(); m_values.clear();}   
   int count() const {return m_keys.count();}
   bool isEmpty() const {return (count() == 0);}
   void insert(int, double);
   void remove(int);
   double value(int, double v = -1) const;
   bool contains(int key) const {return m_keys.contains(key);}
   const LIntDoublePair minValueIterator() const; //возвращает итератор с минимальным значением в контейнере m_values
   const LIntDoublePair maxValueIterator() const; //возвращает итератор с максимальным значением в контейнере m_values
   double sumValues() const; //сумма всех значений values()
   
   inline const LIntList* keys() const {return &m_keys;}
   inline const LDoubleList* values() const {return &m_values;}

   string out() const;

protected:
   LIntList m_keys;
   LDoubleList m_values;

};
LMapIntDouble::LMapIntDouble(const LMapIntDouble &map)
{
   clear();
   const LIntList *keys = map.keys();
   if (keys.isEmpty()) return;
   int n = keys.count();
   for (int i=0; i<n; i++)
      insert(keys.at(i), map.value(keys.at(i)));
}
double LMapIntDouble::sumValues() const
{
   double sum = 0;
   int n = count();
   for (int i=0; i<n; i++)
       sum += value(m_keys.at(i));
   return sum;
}
const LIntDoublePair LMapIntDouble::minValueIterator() const
{
   LIntDoublePair it;
   it.key = int(MQValidityData::errValue());
   it.value = int(MQValidityData::errValue());
   if (isEmpty()) return it;

   int n = count();
   it.key = m_keys.at(0);
   it.value = value(it.key);
   for (int i=0; i<n; i++) 
   {
      if (value(m_keys.at(i)) < it.value) 
      {
         it.key = m_keys.at(i);
         it.value = value(it.key);
      }
   }   
   return it;
}
const LIntDoublePair LMapIntDouble::maxValueIterator() const
{
   LIntDoublePair it;
   it.key = int(MQValidityData::errValue());
   it.value = int(MQValidityData::errValue());
   if (isEmpty()) return it;

   int n = count();
   it.key = m_keys.at(0);
   it.value = value(it.key);
   for (int i=0; i<n; i++) 
   {
      if (value(m_keys.at(i)) > it.value) 
      {
         it.key = m_keys.at(i);
         it.value = value(it.key);
      }
   }   
   return it;
}
double LMapIntDouble::value(int key, double v) const
{
   int pos = m_keys.indexOf(key);
   return ( (pos >= 0) ? m_values.at(pos) : v);
}
void LMapIntDouble::remove(int key)
{
   int pos = m_keys.indexOf(key);
   if (pos >= 0)
   {
      m_keys.removeAt(pos);
      m_values.removeAt(pos);
   }
}
void LMapIntDouble::insert(int key, double value)
{
   int pos = m_keys.indexOf(key);
   if (pos < 0)
   {
      m_keys.append(key);
      m_values.append(value);
   }
   else
   {
      m_values.replace(pos, value);
   }
}
string LMapIntDouble::out() const
{
   int n = count();
   if (n == 0) return "Map is empty!";
   
   string s = "size="+IntegerToString(count())+",  map values: ";
   for (int i=0; i<n; i++)
      s += IntegerToString(i) + "[" + IntegerToString(m_keys.at(i)) +" : " + DoubleToString(m_values.at(i), 4) + "]  ";
   return s;
}


////////////////////////////////////////////////////////
// LMapStringInt контейнер, аналог QMap<string, int>
////////////////////////////////////////////////////////
class LMapStringInt
{
public:
   LMapStringInt() {clear();}
   virtual ~LMapStringInt() {clear();}

   inline void clear() {m_keys.clear(); m_values.clear();}   
   inline int count() const {return m_keys.count();}
   inline bool isEmpty() const {return (count() == 0);}
   inline bool contains(string key) const {return m_keys.contains(key);}
   inline const LStringList* keys() const {return &m_keys;}
   inline const LIntList* values() const {return &m_values;}
   
   void insert(string, int);
   void remove(string);
   int value(string, int v = -1) const;
   int maxValue() const;
   int minValue() const;
   double averageValue() const;
   
   int sumValues() const; //сумма всех значений values()
   string out() const;

protected:
   LStringList m_keys;
   LIntList m_values;

};
int LMapStringInt::sumValues() const
{
   int sum = 0;
   int n = count();
   for (int i=0; i<n; i++)
       sum += value(m_keys.at(i));
   return sum;
}
int LMapStringInt::maxValue() const
{
   if (isEmpty()) return 0;
   int n = count();
   int max = -1000000000;
   for (int i=0; i<n; i++)
      if (value(m_keys.at(i)) > max) max = value(m_keys.at(i));
   return max;
}
int LMapStringInt::minValue() const
{
   if (isEmpty()) return 0;
   int n = count();
   int min = 1000000000;
   for (int i=0; i<n; i++)
      if (value(m_keys.at(i)) < min) min = value(m_keys.at(i));
   return min;

}
double LMapStringInt::averageValue() const
{
   if (isEmpty()) return 0;
   int n = count();
   double a = sumValues();
   return (a/n);
}
int LMapStringInt::value(string key, int v) const
{
   int pos = m_keys.indexOf(key);
   return ( (pos >= 0) ? m_values.at(pos) : v);
}
void LMapStringInt::remove(string key)
{
   int pos = m_keys.indexOf(key);
   if (pos >= 0)
   {
      m_keys.removeAt(pos);
      m_values.removeAt(pos);
   }
}
void LMapStringInt::insert(string key, int value)
{
   int pos = m_keys.indexOf(key);
   if (pos < 0)
   {
      m_keys.append(key);
      m_values.append(value);
   }
   else
   {
      m_values.replace(pos, value);
   }
}
string LMapStringInt::out() const
{
   int n = count();
   if (n == 0) return "Map is empty!";
   
   string s = "size="+IntegerToString(count())+",  map values: ";
   for (int i=0; i<n; i++)
      s += IntegerToString(i) + "[" + m_keys.at(i) +" : " + IntegerToString(m_values.at(i), 4) + "]  ";
   return s;
}


////////////////////////////////////////////////////////
// LMapStringDouble контейнер, аналог QMap<string, double>
////////////////////////////////////////////////////////
class LMapStringDouble
{
public:
   LMapStringDouble() {clear();}
   virtual ~LMapStringDouble() {clear();}

   void clear() {m_keys.clear(); m_values.clear();}   
   int count() const {return m_keys.count();}
   bool isEmpty() const {return (count() == 0);}
   bool contains(string key) const {return m_keys.contains(key);}
   
   void insert(string, double);
   void remove(string);
   double value(string, double v = -1) const;
   
   double sumValues() const; //сумма всех значений values()
   
   inline const LStringList* keys() const {return &m_keys;}
   inline const LDoubleList* values() const {return &m_values;}

   string out() const;

protected:
   LStringList m_keys;
   LDoubleList m_values;

};
double LMapStringDouble::sumValues() const
{
   double sum = 0;
   int n = count();
   for (int i=0; i<n; i++)
       sum += value(m_keys.at(i));
   return sum;
}
double LMapStringDouble::value(string key, double v) const
{
   int pos = m_keys.indexOf(key);
   return ( (pos >= 0) ? m_values.at(pos) : v);
}
void LMapStringDouble::remove(string key)
{
   int pos = m_keys.indexOf(key);
   if (pos >= 0)
   {
      m_keys.removeAt(pos);
      m_values.removeAt(pos);
   }
}
void LMapStringDouble::insert(string key, double value)
{
   int pos = m_keys.indexOf(key);
   if (pos < 0)
   {
      m_keys.append(key);
      m_values.append(value);
   }
   else m_values.replace(pos, value);
}
string LMapStringDouble::out() const
{
   int n = count();
   if (n == 0) return "Map is empty!";
   
   string s = "size="+IntegerToString(count())+",  map values: ";
   for (int i=0; i<n; i++)
      s += StringConcatenate(i, "[", m_keys.at(i), " : ", m_values.at(i), "]  ");
   return s;
}


