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
moviesTabname$  = ReadPreferenceString("moviesTabname","")
moviesColumns$  = ReadPreferenceString("moviesColumns","")
moviesQuery$    = ReadPreferenceString("moviesQuery","")
; Series
seriesTabname$  = ReadPreferenceString("seriesTabname","")
seriesColumns$  = ReadPreferenceString("seriesColumns","")
seriesQuery$    = ReadPreferenceString("seriesQuery","")
seriesSummarize = ReadPreferenceInteger("seriesSummarize",0)
; Window
title$          = ReadPreferenceString("title","")
font$           = ReadPreferenceString("font","")
fontSize        = ReadPreferenceInteger("fontsize",0)
width           = ReadPreferenceInteger("width",0)
height          = ReadPreferenceInteger("height",0)
startTab        = ReadPreferenceInteger("startTab",0)
maximized       = ReadPreferenceInteger("maximized",0)

; Procedures
Declare ConfigureList(Gadget, Position, Tabname$, Columns$)
Declare Connect(Database$)
Declare Disconnect(Database)
Declare ExecuteQuery(Handle, Query$)
Declare StartWindow(Width, Height, Title$, Font$, FontSize, StartTab, Maximized)

; GUI
XIncludeFile "watched-window.pbf"
StartWindow(width, height, title$, font$, fontSize, startTab, maximized)

; GUI-Texts
ConfigureList(ListMovies, 0, moviesTabname$, moviesColumns$)
ConfigureList(ListSeries, 1, seriesTabname$, seriesColumns$)

; Open Database
databaseHandle = Connect(database$)

; Query Movies
ExecuteQuery(databaseHandle, moviesQuery$)
While NextDatabaseRow(databaseHandle)
  ;Debug GetDatabaseString(databaseHandle,0)
  movieName$ = GetDatabaseString(databaseHandle,0)
  movieYear$ = Left(Right(movieName$,5),4)
  movieName$ = Left(movieName$, Len(movieName$)-7)
  AddGadgetItem(ListMovies, -1, movieName$ + Chr(10) + movieYear$)
Wend
FinishDatabaseQuery(databaseHandle)

; Query Series
ExecuteQuery(databaseHandle, seriesQuery$)
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

; Close database
Disconnect(databaseHandle)

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

Procedure Connect(Database$)
  UseSQLiteDatabase()
  Database$ = ReplaceString(Database$, "%APPDATA%", GetEnvironmentVariable("APPDATA"), #PB_String_NoCase)
  Handle = OpenDatabase(#PB_Any, Database$, "", "")
  If (Handle = 0)
    MessageRequester("Error", "Can not open database: "+Database$)
    End
  EndIf
  ProcedureReturn Handle
EndProcedure

Procedure Disconnect(Database)
  CloseDatabase(Database)
EndProcedure

Procedure ExecuteQuery(Handle, Query$)
  If Not DatabaseQuery(Handle, Query$)
    MessageRequester("Error", "Can not execute: "+DatabaseError())
    End
  EndIf
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