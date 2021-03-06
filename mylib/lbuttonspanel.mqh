//+------------------------------------------------------------------+
//|                                                lbuttonspanel.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+

#include <mybase/lgridpanel.mqh>

////////////////////////////////////////////////////////
// Графический объект на графике в виде панели c кнопками (аналог ToolBar),
////////////////////////////////////////////////////////
class LToolBarPanel : public LAbstractPanel
{
public:
   enum ButtonTypes {btUp = 430, btDown, btStart, btStop, btReset}; //типы кнопок

   LToolBarPanel(string name) :LAbstractPanel(name) {reset();}
   virtual ~LToolBarPanel() {destroy();}
   
   inline void setButtonSize(int x) {if (x >= 16 || x <= 256) m_buttonSize = x;}
   
   void addButton(int); //добавить кнопку из множества ButtonTypes, если такая уже есть то она не добавляется
   
   
protected:
   int m_buttonSize; //задается в пикселях
   LIntList m_buttons; //типы кнопок, которые участвуют в панели

   void reset();
   void destroy();
   void createPanelObjects();  //создает все дочерние графический объекты на панели

   int width() const {return (m_buttons.count()*m_buttonSize + m_margin*(m_buttons.count()+1));} //итоговая ширина панели
   int height() const {return (m_margin*2 + m_buttonSize);}  //итоговая высота панели 

private:
   bool invalidType(int t) const {return (t < btUp || t > btReset);}
   string objButtonName(int) const; //возвращает имя графического объекта-кнопки

};
void LToolBarPanel::addButton(int type)
{
   if (invalidType(type)) return;
   if (m_buttons.contains(type)) return;
   
   m_buttons.append(type);
}
void LToolBarPanel::reset()
{
   LAbstractPanel::reset();
   m_buttonSize = 32;
   m_buttons.clear();
   
   
}
void LToolBarPanel::createPanelObjects()
{
   int type = OBJ_BUTTON;
   int n = m_buttons.count();  
   int skx = cornerXSignum(m_corner);
   int sky = cornerYSignum(m_corner);
   int dx = xOffset(width(), x_offset, m_corner);
   int dy = yOffset(height(), y_offset, m_corner) + sky*m_margin;

   for (int i=0; i<n; i++)
   {
      string obj_name = objButtonName(m_buttons.at(i));
      if (obj_name == "") return;
      
      ObjectCreate(obj_name, type, 0, 0, 0);
      ObjectSet(obj_name, OBJPROP_CORNER, cornerByEnumValue(m_corner));
      ObjectSet(obj_name, OBJPROP_XSIZE, m_buttonSize);
      ObjectSet(obj_name, OBJPROP_YSIZE, m_buttonSize);
      ObjectSet(obj_name, OBJPROP_BGCOLOR, clrAliceBlue); //устанавливает цвет фона кнопки
      ObjectSet(obj_name, OBJPROP_BACK, false); //устанавливает кнопку на заднем плане
      ObjectSet(obj_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSet(obj_name, OBJPROP_STATE, false); //устанавливает заданное состояние кнопки, нажата\отжата
      ObjectSet(obj_name, OBJPROP_FONTSIZE, 14); //--- установим размер шрифта
      ObjectSet(obj_name, OBJPROP_COLOR, clrGreen); //--- установим цвет текста
      ObjectSetText(obj_name, "Text btn"); //устанавливает текст кнопки
      
      
      //устанавливает возможность перемещения кнопки мышкой (сл. две строки)
      ObjectSet(obj_name,OBJPROP_SELECTABLE,false);
      ObjectSet(obj_name,OBJPROP_SELECTED,false);

      //отступы
      int t = m_margin*(i+1) + m_buttonSize*i;
      ObjectSet(obj_name, OBJPROP_XDISTANCE, dx + skx*t);
      ObjectSet(obj_name, OBJPROP_YDISTANCE, dy);
      
   }
}
void LToolBarPanel::destroy()
{
   Print("LGridPanel::destroy()");
   if (invalid()) {Print("LToolBarPanel::destroy() ERR: invalid object"); return;}

   tryDeleteObject(m_name);
   
   int n = m_buttons.count();
   for (int i=0; i<n; i++)
   {
      string obj_name = objButtonName(m_buttons.at(i));
      tryDeleteObject(obj_name);
   }
}
string LToolBarPanel::objButtonName(int t) const
{
   if (invalidType(t)) return "";
   return StringConcatenate(m_name, "_button_", IntegerToString(t));
}


