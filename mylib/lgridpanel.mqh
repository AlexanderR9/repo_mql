//+------------------------------------------------------------------+
//|                                                   lgridpanel.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <fllib1/lcontainer.mqh>

////////////////////////////////////////////////////////
// Графический объект на графике в виде прямоугольной панели,
// на которой размещена информация в табличном виде
////////////////////////////////////////////////////////
class LGridPanel
{
public:
   enum PlacedCorner {pcLeftUp = 190, pcLeftDown, pcRightUp, pcRightDown}; //угол размещения в окне

   LGridPanel(string name, int rows = 2, int cols = 2, bool has_header = true);
   LGridPanel() :m_name("none"), m_hasHeader(false) {reset();}
   
   void repaint(); //перерисовывает всю панель
   void destroy(); //удаляет всю панель
   void setHeaderText(int col, string text, color c = clrNONE);
   void setCellText(int i, int j, string text, color c = clrNONE);
   
   bool invalid() const {return (m_name=="" || m_name=="none");}
   inline string panelName() const {return m_name;}
   
   void setSize(int w, int h); //задает ширину и высоту, отрицательное число означает что параметр не меняется
   void setGridSize(int rows, int cols); //задает параметры таблицы, отрицательное число означает что параметр не меняется
   void setCorner(int corner); //задает угол размещения панели в окне
   void setOffset(int dx, int dy); //задает отступы панели от соответвующего угла, отрицательное число означает что параметр не меняется
   void setFontSizes(int cell, int header); //задает размеры шрифтов, отрицательное число означает что параметр не меняется
   void setColSizes(const LIntList&); //задает ширины столбцов в процентах, в случае некорректного списка значений m_colSizes обнуляется
   void setHeaderSeparatorParams(color, int); //задает цвет и толщину разделительной линии после заголовка
   void setName(string s) {m_name = s; checkName();}
   void setHaveHeader(bool b) {m_hasHeader = b;}
   
   
   inline void setBackgroundColor(color x) {m_panelColor = x;}
   inline void setHeaderTextColor(color x) {m_headerColor = x;}
   inline void setCellsTextColor(color x) {m_dataColor = x;}
   inline void setMargin(int x) {if (x >= 0) m_margin = x;}
   
   static int cornerByEnumValue(int); //возвращает значение угла MQL по значению из множества PlacedCorner

protected:
   string m_name;//уникальное имя панели, латиницей слитно
   int m_width; //задается в пикселях
   int m_height; //задается в пикселях
   int m_rowCount; //количетсво строк (без заголовка)
   int m_colCount; //количетсво столбцов
   bool m_hasHeader; //присутствует ли заголовок у этой таблицы
   int m_margin; //отступ данных от границы панели со всех сторон
   color m_panelColor; //цвет фона панели
   color m_headerColor; //цвет текста заголовка
   color m_dataColor; //цвет текста ячеек
   color m_headerSeparatorColor; //цвет разделителя заголовка
   int m_headerSeparatorThickness; //толщина разделителя заголовка
   int m_corner; //угол в котором размещается панель
   int x_offset; //отступ панели от угла, в пикселях
   int y_offset; //отступ панели от угла, в пикселях
   int m_fontSize; //размер шрифта в ячейках сетки
   int m_headerFontSize; //размер шрифта заголовка
   

   //ширины столбцов в процентах, сумма должна быть 100, если список пуст то они равномерно распределяются.
   //при изменении количества столбцов список обнуляется, т.е. его надо снова задавать если нужны разные ширины
   LIntList m_colSizes; 
   
   void reset();
   void createPanel(); //создает графический объект (панель)
   void createHeaderObjects(); //создает метки в заголовке
   void createHeaderSeparator(); //создает разделитель после заголовка
   void createCellsObjects(); //создает метки в ячейках таблицы
   
private:   
   string cellLabelName(int i, int j) const; //возвращает имя объекта заданной ячейки, в случае неудачи вернет пустую строку
   string headerLabelName(int col) const; //возвращает имя объекта в звголовке заданного столбца, в случае неудачи вернет пустую строку
   string headerSeparatorName() const; //возвращает имя объекта разделитель звголовка
   void tryDeleteObject(string obj_name); //удаляет заданный графический объект
   int xOffset(int obj_width, int dx) const;  //возвращает реальный отступ объекта от угла окна, взависимости от его ширины и от угла размещения
   int yOffset(int obj_height, int dy) const;  //возвращает реальный отступ объекта от угла окна, взависимости от его высоты и от угла размещения
   int colWidth(int col) const; //возвращает ширину заданного столбца (с учетом margins)
   int headerHeight() const; //возвращает высоту заголовка
   int rowHeight() const; //возвращает высоту строки таблицы  
   int headerSeparatorHeight() const {return 8;} //возвращает высоту области разделяющую заголовок и такблицу
   double headerHeightFactor() const {return 1.2;} //возвращает коэф. высоты заголовка отностительно высоты строки таблицы
   void checkName(); //проверяет корректность переменной m_name
   bool hasObject(string obj_name) const {return (ObjectFind(obj_name) >= 0);} //проверяет, существует ли объект obj_name
   int cornerXSignum() const; //возвращает 1 или -1 для определения offset объектов по Х
   int cornerYSignum() const; //возвращает 1 или -1 для определения offset объектов по Y
   

};

////////////////////////////////////////////////////
LGridPanel::LGridPanel(string name, int rows, int cols, bool has_header) 
   :m_name(name),
   m_hasHeader(has_header)
{
   reset();
   setGridSize(rows, cols);
   
}
int LGridPanel::cornerXSignum() const
{
   switch (m_corner)
   {
      case pcRightUp:
      case pcRightDown: return -1;
      default: break;
   }
   return 1;
}
int LGridPanel::cornerYSignum() const
{
   switch (m_corner)
   {
      case pcLeftDown:
      case pcRightDown: return -1;
      default: break;
   }
   return 1;
}
void LGridPanel::setHeaderText(int col, string text, color c)
{
   if (!m_hasHeader) return;
   string obj_name = headerLabelName(col);
   //Print("setHeaderText col=", col, "  text=", text, "  obj_name=", obj_name);
   if (obj_name == "") return;

   color text_color = ((c == clrNONE) ? m_headerColor : c);
   if (hasObject(obj_name)) 
      ObjectSetText(obj_name, text, m_headerFontSize, NULL, text_color);      
   else Print("LGridPanel::setHeaderText ERR: no find obj "+obj_name);   
}
void LGridPanel::setCellText(int i, int j, string text, color c)
{
   string obj_name = cellLabelName(i, j);
   if (obj_name == "") return;

   color text_color = ((c == clrNONE) ? m_dataColor : c);
   if (hasObject(obj_name)) 
      ObjectSetText(obj_name, text, m_fontSize, NULL, text_color);      
   else Print("LGridPanel::setCellText ERR: no find obj "+obj_name);   
}
void LGridPanel::checkName()
{
   m_name = StringTrimLeft(m_name);
   m_name = StringTrimRight(m_name);
   StringToLower(m_name);
   
   if (m_name == "") return;
   if (StringFind(m_name, " ") >= 0)  m_name = "";
}
void LGridPanel::repaint()
{
   if (invalid()) {Print("LGridPanel::repaint() ERR: invalid object"); return;}
   //Print("rows="+IntegerToString(m_rowCount)+",  cols="+IntegerToString(m_colCount));

   destroy();
   createPanel();
   createHeaderObjects();
   createHeaderSeparator();
   createCellsObjects();
}
void LGridPanel::createPanel()
{
   int type = OBJ_RECTANGLE_LABEL;
   ObjectCreate(m_name, type, 0, 0, 0);
   
   ObjectSet(m_name, OBJPROP_CORNER, cornerByEnumValue(m_corner));
   ObjectSet(m_name, OBJPROP_XSIZE, m_width);
   ObjectSet(m_name, OBJPROP_YSIZE, m_height);
   ObjectSet(m_name, OBJPROP_XDISTANCE, xOffset(m_width, x_offset));
   ObjectSet(m_name, OBJPROP_YDISTANCE, yOffset(m_height, y_offset));
   ObjectSet(m_name, OBJPROP_BGCOLOR, m_panelColor);
   ObjectSet(m_name, OBJPROP_SELECTABLE, false);
   ObjectSet(m_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
}
void LGridPanel::createCellsObjects()
{
   int type = OBJ_LABEL;
   int skx = cornerXSignum();
   int sky = cornerYSignum();
   int dx = xOffset(m_width, x_offset) + skx*m_margin;
   
   int rh = rowHeight();
   int dy = yOffset(m_height, y_offset) + sky*m_margin;
   if (m_hasHeader) dy += sky*(headerHeight() + headerSeparatorHeight());
   
   for (int j=0; j<m_colCount; j++)
   {
      for (int i=0; i<m_rowCount; i++)
      {
         string obj_name = cellLabelName(i, j);
         if (obj_name == "") return;
         
         ObjectCreate(obj_name, type, 0, 0, 0);
         ObjectSet(obj_name, OBJPROP_CORNER, cornerByEnumValue(m_corner));
         ObjectSet(obj_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
         ObjectSet(obj_name, OBJPROP_XSIZE, colWidth(j));
         ObjectSet(obj_name, OBJPROP_YSIZE, rh);
         ObjectSet(obj_name, OBJPROP_XDISTANCE, dx);
         ObjectSet(obj_name, OBJPROP_YDISTANCE, dy + sky*(rh*(i+1)));
         ObjectSet(obj_name, OBJPROP_SELECTABLE, false);
         
         //string text = ("Cell_"+IntegerToString(i)+"_"+IntegerToString(j));
         ObjectSetText(obj_name, "", m_fontSize, NULL, m_dataColor);      
      }
      dx += (skx*colWidth(j));
   }
}
void LGridPanel::createHeaderObjects()
{
   if (!m_hasHeader) return;
   
   int type = OBJ_LABEL;
   int skx = cornerXSignum();
   int sky = cornerYSignum();
   int dx = xOffset(m_width, x_offset) + skx*m_margin;
   int dy = yOffset(m_height, y_offset) + sky*m_margin + sky*headerHeight();
   for (int j=0; j<m_colCount; j++)
   {
      string obj_name = headerLabelName(j);
      if (obj_name == "") return;
      
      //Print("create "+obj_name+",  width="+IntegerToString(width));
      ObjectCreate(obj_name, type, 0, 0, 0);
      ObjectSet(obj_name, OBJPROP_CORNER, cornerByEnumValue(m_corner));
      ObjectSet(obj_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSet(obj_name, OBJPROP_XSIZE, colWidth(j));
      ObjectSet(obj_name, OBJPROP_YSIZE, headerHeight());
      ObjectSet(obj_name, OBJPROP_XDISTANCE, dx);
      ObjectSet(obj_name, OBJPROP_YDISTANCE, dy);
      ObjectSet(obj_name, OBJPROP_SELECTABLE, false);
      
      dx += (skx*colWidth(j));
      string text = ("Header"+(IntegerToString(j+1)));
      ObjectSetText(obj_name, text, m_headerFontSize, NULL, m_headerColor);      
   }
}
void LGridPanel::createHeaderSeparator()
{
   if (!m_hasHeader) return;
   string obj_name = headerSeparatorName();
   if (obj_name == "") return;
   
   int type = OBJ_RECTANGLE_LABEL;
   if (!ObjectCreate(obj_name, type, 0, 0, 0))
      Print("LGridPanel::createHeaderSeparator() ERR: create obj: "+obj_name);
              
   ObjectSet(obj_name, OBJPROP_CORNER, cornerByEnumValue(m_corner));
   ObjectSet(obj_name, OBJPROP_SELECTABLE, false);
   ObjectSet(obj_name, OBJPROP_BGCOLOR, m_headerSeparatorColor);
   ObjectSet(obj_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);

   int skx = cornerXSignum();
   int sky = cornerYSignum();
   int dx = xOffset(m_width, x_offset) +  skx*m_margin;
   int dy = yOffset(m_height, y_offset) + sky*(m_margin + headerHeight() + headerSeparatorHeight()/2);
   ObjectSet(obj_name, OBJPROP_XDISTANCE, dx);
   ObjectSet(obj_name, OBJPROP_YDISTANCE, dy);
   ObjectSet(obj_name, OBJPROP_XSIZE, m_width - 2*m_margin);
   ObjectSet(obj_name, OBJPROP_YSIZE, m_headerSeparatorThickness);
}
int LGridPanel::headerHeight() const
{
   if (!m_hasHeader) return 0;
   int h = m_height - 2*m_margin - headerSeparatorHeight();
   double h1 = double(h)/double(m_rowCount+1);
   if (headerHeightFactor() == double(1.0)) return int(h1);
   double t = m_rowCount*headerHeightFactor() + 1;
   return int(double(h)/t);
}
int LGridPanel::rowHeight() const
{
   int h = m_height - 2*m_margin;
   if (m_hasHeader) h -= (headerHeight() + headerSeparatorHeight());
   return int(double(h)/double(m_rowCount));
}
int LGridPanel::colWidth(int col) const
{
   if (m_colCount <= 0) return 0;
   if (col < 0 || col >= m_colCount) return 0;
   int w = m_width - 2*m_margin;
   if (m_colSizes.count() != m_colCount) return int(double(w)/double(m_colCount));
   double k = double(m_colSizes.at(col))/double(100);
   return int(double(w)*k);
}
void LGridPanel::setColSizes(const LIntList &list)
{
   m_colSizes.clear();
   if (m_colCount <= 0) return;
   if (m_colCount != list.count()) return;
   
   int sum = 0;
   for (int i=0; i<list.count(); i++)
   {
      if (list.at(i) < 10) {sum = -1; break;} 
      sum += list.at(i);
   }
   
   if (sum != 100) return;
   
   for (int i=0; i<list.count(); i++)
      m_colSizes.append(list.at(i));
}
int LGridPanel::xOffset(int obj_width, int dx) const
{
   switch (m_corner)
   {
      case pcLeftDown:
      case pcLeftUp:       return dx;
      case pcRightUp:
      case pcRightDown:    return (dx + obj_width);
      default: break;
   }
   return 0;
}
int LGridPanel::yOffset(int obj_height, int dy) const
{
   switch (m_corner)
   {
      case pcLeftUp:       
      case pcRightUp:      return dy;
      case pcLeftDown:
      case pcRightDown:    return (dy + obj_height);
      default: break;
   }
   return 0;
}
void LGridPanel::destroy()
{
   if (invalid()) {Print("LGridPanel::destroy() ERR: invalid object"); return;}

   tryDeleteObject(m_name);
   tryDeleteObject(headerSeparatorName());
   
   for (int j=0; j<m_colCount; j++)
   {
      tryDeleteObject(headerLabelName(j));
      for (int i=0; i<m_rowCount; i++)
         tryDeleteObject(cellLabelName(i, j));
   }
}
void LGridPanel::tryDeleteObject(string obj_name)
{
   if (obj_name == "") return;
   if (ObjectFind(obj_name) < 0) return;
   if (!ObjectDelete(obj_name))
      Print("LGridPanel::tryDeleteObject: ERR - ObjectDelete() result=false, obj_name="+obj_name);
}
string LGridPanel::cellLabelName(int i, int j) const
{
   if (i < 0 || i >= m_rowCount) return "";
   if (j < 0 || j >= m_colCount) return "";
   string s = m_name + "_cell_";
   s += (IntegerToString(i)+"_"+IntegerToString(j));
   return s;
}
string LGridPanel::headerLabelName(int col) const
{
   if (col < 0 || col >= m_colCount) return "";
   string s = m_name + "_header_";
   s += IntegerToString(col);
   return s;
}
string LGridPanel::headerSeparatorName() const
{
   string s = m_name + "_header_separator";
   return s;
}
void LGridPanel::reset()
{
   m_width = 100;
   m_height = 100;
   m_rowCount = 2;
   m_colCount = 2;
   m_margin = 4;
   x_offset = 10;
   y_offset = 10;
   m_corner = pcLeftDown;
   
   m_panelColor = clrGainsboro;
   m_headerColor = clrDarkBlue;
   m_dataColor = clrBlack;
   
   m_fontSize = 8;
   m_headerFontSize = 10;
   m_headerSeparatorThickness = 2;
   m_headerSeparatorColor = clrBlack;

}
void LGridPanel::setHeaderSeparatorParams(color c, int t)
{
   if (t > 0 && t < 10) m_headerSeparatorThickness = t;
   m_headerSeparatorColor = c;
}
void LGridPanel::setCorner(int corner)
{
   switch (corner)
   {
      case pcLeftUp:
      case pcLeftDown:
      case pcRightUp:
      case pcRightDown: {m_corner = corner; break;}
      default: break;
   }
}
int LGridPanel::cornerByEnumValue(int corner)
{
   switch (corner)
   {
      case pcLeftUp:       return 0;
      case pcLeftDown:     return 2;
      case pcRightUp:      return 1;
      case pcRightDown:    return 3;
      default: break;
   }
   return 0;
}
void LGridPanel::setOffset(int dx, int dy)
{
   if (dx >= 0) x_offset = dx;
   if (dy >= 0) y_offset = dy;   
}
void LGridPanel::setSize(int w, int h)
{
   if (w > 0) m_width = w;
   if (h > 0) m_height = h;    
}
void LGridPanel::setFontSizes(int cell, int header)
{
   if (cell > 0) m_fontSize = cell;
   if (header > 0) m_headerFontSize = header;
}
void LGridPanel::setGridSize(int rows, int cols)
{
   if (rows > 0) m_rowCount = rows;
   if (cols > 0) m_colCount = cols;
}



