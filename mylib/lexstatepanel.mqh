//+------------------------------------------------------------------+
//|                                                lexstatepanel.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict


//графическая панель, для отображения текущего состояния советника в табличном виде.
//короче отображает инфу из файла (state.txt для удобства)
#include <mybase/lgridpanel.mqh>

class LExStatePanel
{
public:
   enum TotalOperationType {totSum = 91, totMax, totMin, totNone}; //тип значения которое должно отображатся в итоговой строке, totNone - ничего не отображать

   LExStatePanel(string ex_full_name) :m_name(ex_full_name) {}
   virtual ~LExStatePanel() {destroy();}
   
   //инициализация графической панели.
   //couples - список инструментов по которым идет работа
   //params - горизонтальные заголовки, список параметров состояния
   void initPanel(const LStringList &couples, const LStringList &params); 
   
   
   //обновить строку с параметрами для инструмента couple, строка Total обновляется автоматически
   //размер values должен быть (col_count-1), т.е. значения всех параметров для одного инструмента
   void updateParamsByCouple(string couple, const LStringList &values);
   
   //обновить строку с индексом row_index, строка Total обновляется автоматически
   //размер values должен быть (col_count-1), т.е. значения всех параметров для одного инструмента
   void updateParamsByRow(int row_index, const LStringList &values);
   
   //установка точности p для указаного столбца col_index = 0 .. (col_count-2)
   void setPrecision(int col_index, int p);

   //установка типа значения для итоговой строки для указаного столбца col_index = 0 .. (col_count-2)
   void setTotalOperation(int col_index, int tt);
   
   
protected:
   string m_name;   
   LGridPanel *m_panel;
   LMapStringInt m_coupleRows; //информация о названиях инструментов и индексах строк в которых они размещены
   
   //информация о точностях данных в каждом столбце (кроме 1-го), 0-int, -1-string, >0-double, 
   //по умолчанию контейнер заполняется заполняется нулями
   //размер контейнера должен быть (col_count-1)
   LIntList m_colPrecisios; 
   
   //типы операций для строки total   
   //по умолчанию контейнер заполняется заполняется totSum
   //размер контейнера должен быть (col_count-1)
   LIntList m_totalOperations;
   

   void destroy();
   void setPanelSizes(const LStringList &params); //установить размеры панели
   void setPanelMainParams(); //установить основные параметры панели
   void setVHeadersText(const LStringList &couples);
   void setHHeadersText(const LStringList &params);
   void updateRowData(int, const LStringList&); //обновить данные заданной строки
   void updateTotalRowData(); //обновить данные итоговой строки
   
   
   
private:
   int rowHeight() const {return 24;}   //высота строки в пикселях
   int colWidth() const {return 70;}   //ширина столбца в пикселях
   color headerColor() const {return clrDarkBlue;} //цвет текста горизонтального заголовка
   color textColor() const {return clrBlack;} //цвет текста ячеек таблицы
   color coupleColor() const {return clrGreen;}  //цвет текста вертикального заголовка
   color bgColor() const {return 0xEEDDDD;} //цвет фона панели
   int totalRowIndex() const; //индекст итоговой строки

};
void LExStatePanel::destroy()
{
   if (m_panel)
   {
      delete m_panel;
      m_panel = NULL;
   }
}
void LExStatePanel::setPrecision(int col_index, int p)
{
   if (col_index < 0 || col_index >= m_colPrecisios.count()) return;
   m_colPrecisios.replace(col_index, p);
}
void LExStatePanel::setTotalOperation(int col_index, int tt)
{
   if (col_index < 0 || col_index >= m_totalOperations.count()) return;
   m_totalOperations.replace(col_index, tt);
}
void LExStatePanel::updateParamsByCouple(string couple, const LStringList &values)
{
   if (!m_panel || !m_coupleRows.contains(couple)) return;
   if (values.isEmpty() || values.count() != (m_panel.colCount()-1)) return;
   int row_index = m_coupleRows.value(couple);
   updateRowData(row_index, values);
}
void LExStatePanel::updateParamsByRow(int row_index, const LStringList &values)
{
   if (!m_panel || row_index < 0) return;
   if (values.isEmpty() || values.count() != (m_panel.colCount()-1)) return;
   updateRowData(row_index, values);   
}
void LExStatePanel::updateRowData(int i, const LStringList &data)
{
   if (i < 0 || i >= (m_panel.rowCount()-1)) return;
   
   int n = data.count();
   for (int j=0; j<n; j++)
      m_panel.setCellText(i, j+1, data.at(j), textColor());
      
   updateTotalRowData();
}
void LExStatePanel::updateTotalRowData()
{
   int tr = totalRowIndex();
   if (tr < 0) return;
   
   int cols = m_panel.colCount();
   int rows = m_coupleRows.count();
   for (int col=1; col<cols; col++)
   {
      int p = m_colPrecisios.at(col-1);
      if (p < 0) return;
      
      double sum = 0;
      double min = 0;
      double max = 0;
      for (int row = 0; row<rows; row++)
      {         
         string cell_data = m_panel.getCellText(row, col);
         if (cell_data == "???" || cell_data == "") continue;
         double v = StrToDouble(cell_data);
         sum += v;
         
         if (row == 0) min = max = v;
         else
         {
            if (v < min) min = v;
            if (v > max) max = v;            
         }
      }
      
      string total_text = "---"; 
      switch (m_totalOperations.at(col-1))
      {
         case totSum: {total_text = DoubleToStr(sum, p); break;}
         case totMax: {total_text = DoubleToStr(max, p); break;}
         case totMin: {total_text = DoubleToStr(min, p); break;}
         default: break;
      }
      m_panel.setCellText(tr, col, total_text, textColor());
   }
}
int LExStatePanel::totalRowIndex() const
{
   if (!m_panel || m_coupleRows.isEmpty()) return -1;
   return m_coupleRows.count();
}
void LExStatePanel::initPanel(const LStringList &couples, const LStringList &params)
{
   if (m_panel) destroy();   
   if (couples.isEmpty()) {Print("LExStatePanel::initPanel() ERR:  couples is empty"); return;}
   if (params.isEmpty()) {Print("LExStatePanel::initPanel() ERR:  params is empty"); return;}
   if (m_name == "") {Print("LExStatePanel::initPanel() ERR:  m_name is empty string"); return;}
   
   m_coupleRows.clear();
   m_colPrecisios.clear();
   m_totalOperations.clear();
   
   string p_name = StringConcatenate(m_name, "_panel");
   m_panel = new LGridPanel(p_name, couples.count()+1, params.count()+1, true);
   setPanelMainParams();
   setPanelSizes(params);

   m_panel.repaint();
   setVHeadersText(couples);
   setHHeadersText(params);
}
void LExStatePanel::setPanelSizes(const LStringList &params)
{   
   int h = rowHeight()*(m_panel.rowCount() + 1) + m_panel.headerSeparatorHeight();
   int w = colWidth()*m_panel.colCount();
   m_panel.setSize(w, h);
   
   int step_symbols = 2;
   LIntList sizes;
   sizes.append(3); //couple size
   for (int i=0; i<params.count(); i++)
   {
      int len = StringLen(params.at(i));
      int size = 1;
      for (;;)
      {
         if (len > size*step_symbols) size++;
         else break;
      }
      sizes.append(size);
      //Print("size=", size);
   }
      
   int sum_sizes = sizes.sumValues();
   double step_col_width = double(100)/double(sum_sizes);
   Print("sum_sizes=", sum_sizes, "   step_col_width=", step_col_width);
   sum_sizes = 0;
   for (int i=0; i<m_panel.colCount(); i++)
   {
      int p = int(double(sizes.at(i))*step_col_width);
      //Print("p=", p);
      sizes.replace(i, p);
      sum_sizes += p;
   }
   Print("sum_sizes_P=", sum_sizes);
   
   if (sum_sizes > 100)
   {
      int p = sizes.at(0) - (sum_sizes-100);
      sizes.replace(0, p);
   }
   else if (sum_sizes < 100)
   {
      int p = sizes.at(0) + (100-sum_sizes);
      sizes.replace(0, p);   
   }
   
   m_panel.setColSizes(sizes);
   
}
void LExStatePanel::setPanelMainParams()
{
   m_panel.setCorner(pcLeftUp);
   m_panel.setMargin(4);
   m_panel.setOffset(20, 20);
   
   m_panel.setBackgroundColor(bgColor());
   m_panel.setHeaderTextColor(headerColor());
   m_panel.setHeaderSeparatorParams(clrBlack, 2);
   m_panel.setCellsTextColor(textColor());
   m_panel.setFontSizes(8, 10);
}
void LExStatePanel::setVHeadersText(const LStringList &couples)
{
   int n = couples.count();
   for (int i=0; i<n; i++)
   {
      m_panel.setCellText(i, 0, couples.at(i), coupleColor());
      m_coupleRows.insert(couples.at(i), i);
   }
      
   m_panel.setCellText(n, 0, "Total:", headerColor());   
}
void LExStatePanel::setHHeadersText(const LStringList &params)
{
   int n = params.count();
   for (int i=0; i<n; i++)
   {
      m_panel.setHeaderText(i+1, params.at(i), headerColor());
      m_colPrecisios.append(0);
      m_totalOperations.append(totSum);
   }
      
   m_panel.setHeaderText(0, "", headerColor());   
}

