; Show Kodi-Watched Movies & Series
; Alex, 2017/07/16

; Config
ini$ = "watched.ini"
; Open Preferences
If (OpenPreferences(ini$) = 0)
  MessageRequester("Error", "Can not open ini-file: "+ini$)
  End
EndIf
; Read Config
database$       = ReadPreferenceString("database","")
; Movies
moviesTabname$  = ReadPreferenceString("moviesTabname","Movies")
moviesColumns$  = ReadPreferenceString("moviesColumns","Title,438,Year,100")
moviesQuery$    = ReadPreferenceString("moviesQuery","")
; Series
seriesTabname$  = ReadPreferenceString("seriesTabname","Series")
seriesColumns$  = ReadPreferenceString("seriesColumns","Title,338,Season,100,Episode,100")
seriesQuery$    = ReadPreferenceString("seriesQuery","")
seriesSummarize = ReadPreferenceInteger("seriesSummarize",1)
; Window
title$          = ReadPreferenceString("title","Kodi - WatchedList")
font$           = ReadPreferenceString("font","")
fontSize        = ReadPreferenceInteger("fontsize",12)
width           = ReadPreferenceInteger("width",600)
height          = ReadPreferenceInteger("height",400)
startTab        = ReadPreferenceInteger("startTab",0)
maximized       = ReadPreferenceInteger("maximized",0)

; Procedures
Declare ConfigureList(Gadget, Position, Tabname$, Columns$)
Declare StartWindow(Width, Height, Title$, Font$, FontSize, StartTab, Maximized)

; GUI
XIncludeFile "watched-window.pbf"
StartWindow(width, height, title$, font$, fontSize, startTab, maximized)

; GUI-Texts
ConfigureList(ListMovies, 0, moviesTabname$, moviesColumns$)
ConfigureList(ListSeries, 1, seriesTabname$, seriesColumns$)

; Open Database
UseSQLiteDatabase()
database$ = ReplaceString(database$, "%APPDATA%", GetEnvironmentVariable("APPDATA"), #PB_String_NoCase)
databaseHandle = OpenDatabase(#PB_Any, database$, "", "")
If (databaseHandle = 0)
  MessageRequester("Error", "Can not open database: "+database$)
  End
EndIf

; Query Movies
If DatabaseQuery(databaseHandle, moviesQuery$)
  While NextDatabaseRow(databaseHandle)
    ;Debug GetDatabaseString(databaseHandle,0)
    movieName$ = GetDatabaseString(databaseHandle,0)
    movieYear$ = Left(Right(movieName$,5),4)
    movieName$ = Left(movieName$, Len(movieName$)-7)
    AddGadgetItem(ListMovies, -1, movieName$ + Chr(10) + movieYear$)
  Wend
  FinishDatabaseQuery(databaseHandle)
Else
  MessageRequester("Error", "Can not execute: "+DatabaseError())
EndIf

; Query Series
If DatabaseQuery(databaseHandle, seriesQuery$)
  While NextDatabaseRow(databaseHandle)
    ;Debug GetDatabaseString(databaseHandle,0) + GetDatabaseString(databaseHandle,1) + GetDatabaseString(databaseHandle,2)
    If seriesSummarize=0 
      AddGadgetItem(ListSeries, -1, GetDatabaseString(databaseHandle,0) + Chr(10) + GetDatabaseString(databaseHandle,1) + Chr(10) + GetDatabaseString(databaseHandle,2))
      Continue
    EndIf
    ; Summarize
    seriesName$   = GetDatabaseString(databaseHandle,0)
    seriesSeason  = GetDatabaseLong(databaseHandle,1)
    seriesEpisode = GetDatabaseLong(databaseHandle,2)
    ; First run
    If seriesNamePrev$ = "" ; And seriesSeasonPrev=0 And seriesEpisode=0
      seriesNamePrev$   = seriesName$
      seriesSeasonPrev  = seriesSeason
      seriesEpisodePrev = seriesEpisode
      seriesEpisodeMin  = seriesEpisode
    EndIf
    ; Summarize Episodes
    If seriesName$ <> seriesNamePrev$ Or seriesSeason <> seriesSeasonPrev Or seriesEpisode > seriesEpisodePrev+1
      ; Special Handling for one Episode
      If seriesEpisodeMin = seriesEpisodePrev
        seriesEpisodeOut$ = Str(seriesEpisodeMin)
      Else
        seriesEpisodeOut$ = Str(seriesEpisodeMin)+"-"+Str(seriesEpisodePrev)
      EndIf
      ; Output
      AddGadgetItem(ListSeries, -1, seriesNamePrev$ + Chr(10) + Str(seriesSeasonPrev) + Chr(10) + seriesEpisodeOut$)
      ; New min episode
      seriesEpisodeMin = seriesEpisode
    EndIf
    ; Store current values
    seriesNamePrev$   = seriesName$
    seriesSeasonPrev  = seriesSeason
    seriesEpisodePrev = seriesEpisode
  Wend
  If summarize=1
    AddGadgetItem(ListSeries, -1, seriesName$ + Chr(10) + Str(seriesSeasonPrev) + Chr(10) + Str(seriesEpisodeMin)+"-"+Str(seriesEpisodePrev))
  EndIf
  FinishDatabaseQuery(databaseHandle)
Else
  MessageRequester("Error", "Can not execute: "+DatabaseError())
EndIf

; Window
Repeat
  Event = WaitWindowEvent()
  Select EventWindow()
    Case WindowMain
      WindowMain_Events(Event)
    EndSelect
 Until Event = #PB_Event_CloseWindow
 
; ----------------------------------------------------------------------------------------------------------------------------------

Procedure ConfigureList(List, Position, Tabname$, Columns$)
  ; Headline
  SetGadgetItemText(PanelHandle, Position, Tabname$)
  ; Remove existing columns
  RemoveGadgetColumn(List,#PB_All)
  ; Add Columns
  For i = 1 To CountString(Columns$,",")+1 Step 2
    AddGadgetColumn(List, Int(i/2), StringField(Columns$, i, ","), Val(StringField(Columns$, i+1, ",")))
  Next
EndProcedure

Procedure StartWindow(Width, Height, Title$, Font$, FontSize, StartTab, Maximized)
  ; Load Font
  If LoadFont(0, Font$, FontSize)
    SetGadgetFont(#PB_Default, FontID(0))
  EndIf
  ; Open Window
  OpenWindowMain(0, 0, Width, Height)
  SetWindowTitle(WindowMain, Title$)
  SetGadgetState(PanelHandle, StartTab)
  If Maximized = 1
    ShowWindow_(WindowID(WindowMain),#SW_MAXIMIZE)
  EndIf
  ResizeGadgetsWindowMain()
EndProcedure

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 28
; FirstLine = 9
; EnableXP
; UseIcon = icon.ico
; Executable = ..\watched.exe
; CPU = 1
; DisableDebugger