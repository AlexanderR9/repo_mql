//+------------------------------------------------------------------+
//|                                                         func.mq4 |
//|                      Copyright © 2008, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#property strict

#include <mylib/common/lcontainer.mqh>


// class LFile
class LFile
{
public:
   //симол разделяющий значения в одной строке файла
   static string splitSymbol() {return "*";}

   // возвращает количество строк в файле, при этом полагается что файл уже открыт
   // и курсор в стоит в начале файла, handle -  дескриптор читаемого файла,
   // после выполнения функции файл не закрывается, а курсор становится в конец файла.
   static int countStrInFile(int handle);

   //возвращает количество строк в файле
   static int fileLineNumber(string filename);

   //записывает масив строк arr в файл filename
   //точнее count 1-х строк, если count==-1 то все строки
   //если в файле что то есть, всё затирается
   //в случае не удачи вернёт false, иначе true
    //Имя открываемого файла, может содержать подпапки. Если файл открывается для записи, то указанные подпапки будут созданы в случае их отсутствия.
   static bool stringListToFile(string filename, string &arr[], int count = -1);
   static bool stringListToFile(string filename, const LStringList &list);

   //добавляет масив строк arr в конец файла filename
   //точнее count 1-х строк, если count==-1 то все строки
   //в случае не удачи вернёт false, иначе true
   static bool appendStringListToFile(string filename, string &arr[], int count = -1);
   static bool appendStringListToFile(string filename, const LStringList &list);

   //находит строку файла где существует подстрока strParameter
   //меняет значение параметра strParameter в соответствующей строке файла
   //новый параметр newStrValue записывается между символами []
   // если подстрока strParameter не найдена или не найдены оба символа [] функция вернет "false"  
   static bool changeParameterInFile(string filename, string strParameter, string newStrValue);

   // читает файл filename, и записывает в массив строк  arr
   // возвращает колличество прочитаных строк
   // в случае не удачи возвращает -1
   // массив строк должен быть заведомо размерным, обьявлен с приблизительным размером типа s_arr[10]
   static int readFileToStringList(string filename, string &arr[]);
   static int readFileToStringList(string filename, LStringList &list);

   // проверяет существование файла с именем fname
   //Имя открываемого файла, может содержать подпапки.
   static bool isFileExists(string fname);

   // проверяет существование папки с именем dir_name
   static bool isDirExists(string dir_name);

   // добавляет в конец файла строку
   // в случае не удачи возвращает false
   // если файл не существует, то он создастся  
   static bool appendToFile(string filename, string s);

   // создаёт файл filename и закрывает
   // в случае не удачи возвращает false
    //Имя файла может содержать подпапки (test/file.data). Подпапки будут созданы в случае их отсутствия.
    static bool createFile(string filename);

   //возвращает из масива строк находит строку где существует подстрока str и 
   // из этой строки возвращает строковое значение заключённое в символах []
   // если подстрока str не найдена или не найдены оба символа [] функция вернет "err"
   static string getStrValueFromList(string str, string &arr[]);
   
   //загрузить из файла значения параметров, парсятся строки типа  [string_name * value] 
   //static bool loadParams(string filename, LMapIntDouble &params); 

};




/*


bool LFile::loadParams(string filename, LMapIntDouble &params)
{
   params.clear();   
   
   string fdata[100];
   int n = LFile::readFileToStringList(filename, fdata);
   if (n < 0) return false;
   
   LIntList paramsTypes;
   MQEnumsStatic::getInputParams(paramsTypes);
      
   for (int i=0; i<n; i++)
   {
      string s = fdata[i];
      if (StringLen(s) < 5) continue;
      
      int pos1 = StringFind(s, "[");
      int pos2 = StringFind(s, LFile::splitSymbol());
      int pos3 = StringFind(s, "]");
      if (pos1 < 0 || pos2 < 0 || pos3 < 0) continue;
      if (pos1 >= pos2 || pos1 >= pos3 || pos2 >= pos3) continue;
      
      string s1 = StringSubstr(s, pos1+1, pos2-pos1-1);
      string s2 = StringSubstr(s, pos2+1, pos3-pos2-1);
      s1 = StringTrimLeft(s1); s1 = StringTrimRight(s1);
      s2 = StringTrimLeft(s2); s2 = StringTrimRight(s2);
      double dvalue = StringToDouble(s2);
      
      int err = GetLastError();
      if (err != 0) {Print(s1 + " = " + DoubleToString(dvalue, 4)+"   err " + IntegerToString(err)); continue;}
      
      
      for (int j=0; j<paramsTypes.count(); j++)
      {
         string sparam = MQEnumsStatic::shortStrByType(paramsTypes.at(j));
         if (StringLen(sparam) < 3) continue;
         if (sparam == s1)
         {
            params.insert(paramsTypes.at(j), dvalue);
            break;
         }
      }
   }
   
   return true;
}
*/
int LFile::countStrInFile(int handle)
{
   if (handle<0) return(-1);
   int a=0;
   string str;
   while(!FileIsEnding(handle))
   {
      str=FileReadString(handle);
      if (FileIsLineEnding(handle) && str!="") a++;
   }
   return (a);
}
int LFile::fileLineNumber(string filename)
{
    int handle=FileOpen(filename, FILE_CSV|FILE_READ);
    int count = 0;
    if(handle <= 0)
    {
      Print("Файл не открыт для чтения, последняя ошибка ", GetLastError());
      return(-1); 
    }
    while(!FileIsEnding(handle))
    {
         FileReadString(handle);
         if (GetLastError() == 4099) break;
         count++;
    }
    FileClose(handle);
    return(count);
}
bool LFile::stringListToFile(string filename, string &arr[], int count)
{
   if (count < 0) count = ArraySize(arr); 
   if (count == 0) return (false);
   int handle=FileOpen(filename,FILE_CSV|FILE_WRITE,';');
   if(handle<1)
   {
      Print("Файл не открыт для записи, последняя ошибка ", GetLastError());
      return(false);
   }
   for (int i=0; i<count; i++)
      FileWrite(handle, arr[i]);
      
   FileClose(handle);
   return(true);
}
bool LFile::stringListToFile(string filename, const LStringList &list)
{
   int n = list.count();
   if (n == 0) return false;
   
   int handle = FileOpen(filename, FILE_TXT|FILE_WRITE);
   if(handle<1)
   {
      Print("Файл не открыт для записи, последняя ошибка ", GetLastError());
      return(false);
   }
   
   for (int i=0; i<n; i++)
      FileWrite(handle, list.at(i));
      
   FileClose(handle);   
   return true;   
}
bool LFile::appendStringListToFile(string filename, string &arr[], int count)
{
   if (count < 0) count = ArraySize(arr); 
   if (count == 0) return (false);
   int   handle = FileOpen(filename, FILE_TXT|FILE_READ|FILE_WRITE);
   if (handle < 1)
   {
      Print("Файл не открыт для записи, последняя ошибка ", GetLastError());
      return(false);
   }

   FileSeek(handle, 0, SEEK_END);
   for (int i=0; i<count; i++)
      FileWrite(handle, arr[i]);
      
   FileClose(handle);
   return(true);
}
bool LFile::appendStringListToFile(string filename, const LStringList &list)
{
   int n = list.count();
   if (n == 0) return false;
   
   int   handle = FileOpen(filename, FILE_TXT|FILE_READ|FILE_WRITE);
   if (handle < 1)
   {
      Print("Файл не открыт для записи, последняя ошибка ", GetLastError());
      return(false);
   }
   
   FileSeek(handle, 0, SEEK_END);
   for (int i=0; i<n; i++)
      FileWrite(handle, list.at(i));
      
   FileClose(handle);   
   return true;
}
bool LFile::changeParameterInFile(string filename, string strParameter, string newStrValue)
{
  string s_arr[10];
  int count =  readFileToStringList(filename, s_arr);
  if (count <= 0)
  {
      Print("changeParameterInFile: read file error!");
      return(false);
  }

   for (int i=0; i<count; i++)
   {
      string s = s_arr[i];
      if (StringFind(s, strParameter) >= 0)
      {
         s_arr[i] = strParameter+"=["+newStrValue+"]";
         break;
      }
      if (i == (count-1))
      {
            Print("changeParameterInFile: parameter not found in file");
            return(false);            
      }
   }
   stringListToFile(filename, s_arr);
   return (true);

}
int LFile::readFileToStringList(string filename, LStringList &list)
{
   list.clear();
   int handle = FileOpen(filename, FILE_TXT | FILE_READ);
   if (handle < 1)
   {
      Print("Файл не открыт для чтения, последняя ошибка ", GetLastError());
      return -1;
   }
   
   //Print("file " + filename +",  size "+IntegerToString(FileSize(handle)));
   
   while(!FileIsEnding(handle))
   {
      //Print("-----------");
      string str = FileReadString(handle);
      //if (GetLastError() == 4099) break; //конец файла
      list.append(str);
   }

   FileClose(handle);   
   return list.count();
}
int LFile::readFileToStringList(string filename, string &arr[])
{
    int handle=FileOpen(filename, FILE_CSV|FILE_READ);
    int count = 0;
    string str;

    if(handle>0)
    {
      while(!FileIsEnding(handle))
      {
         str=FileReadString(handle);
         if (GetLastError() == 4099) break;
         arr[count] = str;
         count++;
      }
    }
    else
    {
      Print("Файл "+filename+" не обнаружен, последняя ошибка ", GetLastError());
      return(-1);
    }

    FileClose(handle);
    Print("Файл "+filename+" закрыт, последняя ошибка ", GetLastError());
    return (count);  
}
bool LFile::isDirExists(string dir_name)
{
   dir_name = StringTrimLeft(dir_name);
   dir_name = StringTrimRight(dir_name);
   if (dir_name == "") {Print("LFile::isDirExists() ERR: dir_name is empty!"); return false;}
   
   ResetLastError();
   //--- если это файл, то функция вернет true, а если директория, то функция генерирует ошибку ERR_FILE_IS_DIRECTORY
   if (FileIsExist(dir_name)) return false; //this file
   return (GetLastError()==ERR_FILE_IS_DIRECTORY);
}
bool LFile::isFileExists(string fname)
{
   fname = StringTrimLeft(fname);
   fname = StringTrimRight(fname);
   if (fname == "") {Print("LFile::isFileExists() ERR: file name is empty!"); return false;}
   return FileIsExist(fname);

/*   old version
   int handle=FileOpen(fname, FILE_CSV|FILE_READ);
   if (handle > 0)
   {
      FileClose(handle);
      return (true);
   }
   return (false);
   */
}
bool LFile::appendToFile(string filename, string s)
{
   int handle = FileOpen(filename,FILE_CSV|FILE_READ|FILE_WRITE);
   if (handle>-1)
   {
      countStrInFile(handle);
      uint n = FileWrite(handle, s);
      FileClose(handle);
      return (n > 0);
   }
   return(false);
}
bool LFile::createFile(string filename)
{
  int handle;
  handle=FileOpen(filename,FILE_CSV|FILE_WRITE,';');
  if(handle<1)
    {
     Print("Файл не создан, последняя ошибка ", GetLastError());
     return(false);
    }

    FileClose(handle);
    return(true);
}
string LFile::getStrValueFromList(string str, string &arr[])
{
   int size = ArraySize(arr);
   if (size <= 0) return ("err");
   for (int i=0; i<size; i++)
   {
      string s = arr[i];
      if (StringFind(s, str) >= 0)
      {
         int pos1 = StringFind(s, "[");
         int pos2 = StringFind(s, "]");
         if ((pos1 >= 0) && (pos2 >= 0) && (pos2 > (pos1+1))) 
         {
            return (StringSubstr(s, pos1+1, pos2 - pos1 - 1));
         }
      }
   }
   return ("err");
}


