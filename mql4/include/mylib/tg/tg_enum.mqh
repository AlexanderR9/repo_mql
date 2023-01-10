//+------------------------------------------------------------------+
//|                                                      tg_enum.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict



//+------------------------------------------------------------------+
//|   ENUM_LANGUAGES                                                 |
//+------------------------------------------------------------------+
enum ENUM_LANGUAGES {LANGUAGE_EN, LANGUAGE_RU};

//+------------------------------------------------------------------+
//|   ENUM_UPDATE_MODE                                               |
//+------------------------------------------------------------------+
enum ENUM_UPDATE_MODE {UPDATE_FAST, UPDATE_NORMAL, UPDATE_SLOW};

//+------------------------------------------------------------------+
//|   ENUM_RUN_MODE                                                  |
//+------------------------------------------------------------------+
enum ENUM_RUN_MODE {RUN_OPTIMIZATION, RUN_VISUAL, RUN_TESTER, RUN_LIVE};

//+------------------------------------------------------------------+
//|   ENUM_ERROR_LEVEL                                               |
//+------------------------------------------------------------------+  
enum ENUM_ERROR_LEVEL {LEVEL_INFO, LEVEL_WARNING, LEVEL_ERROR, LEVEL_CRITICAL};
  
//+------------------------------------------------------------------+
//|   ENUM_CHAT_ACTION                                               |
//+------------------------------------------------------------------+
enum ENUM_CHAT_ACTION
{
   ACTION_FIND_LOCATION,   //picking location
   ACTION_RECORD_AUDIO,    //recording audio
   ACTION_RECORD_VIDEO,    //recording video
   ACTION_TYPING,          //typing
   ACTION_UPLOAD_AUDIO,    //sending audio
   ACTION_UPLOAD_DOCUMENT, //sending file
   ACTION_UPLOAD_PHOTO,    //sending photo
   ACTION_UPLOAD_VIDEO     //sending video
};
  
  
  
  
  
  
  
  
  
  
  