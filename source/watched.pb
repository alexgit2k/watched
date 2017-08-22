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
database$             = ReadPreferenceString("database","")
; Movies
moviesTabname$        = ReadPreferenceString("moviesTabname","")
moviesColumns$        = ReadPreferenceString("moviesColumns","")
moviesQuery$          = ReadPreferenceString("moviesQuery","")
; Series
seriesTabname$        = ReadPreferenceString("seriesTabname","")
seriesColumns$        = ReadPreferenceString("seriesColumns","")
seriesQuery$          = ReadPreferenceString("seriesQuery","")
seriesSummarizeQuery$ = ReadPreferenceString("seriesSummarizeQuery","")
seriesSummarize       = ReadPreferenceInteger("seriesSummarize",0)
seriesSummarizeCol    = ReadPreferenceInteger("seriesSummarizeCol",0)
; Window
title$                = ReadPreferenceString("title","")
font$                 = ReadPreferenceString("font","")
fontSize              = ReadPreferenceInteger("fontsize",0)
width                 = ReadPreferenceInteger("width",0)
height                = ReadPreferenceInteger("height",0)
startTab              = ReadPreferenceInteger("startTab",0)
maximized             = ReadPreferenceInteger("maximized",0)

; Procedures
Declare ConfigureList(Gadget, Position, Tabname$, Columns$)
Declare PopulateList(Handle, List, Query$)
Declare SummarizeList(List, Column)
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

; Populate
databaseHandle = Connect(database$)
PopulateList(databaseHandle, ListMovies, moviesQuery$)
If (seriesSummarize = 0)
  PopulateList(databaseHandle, ListSeries, seriesQuery$)
Else
  PopulateList(databaseHandle, ListSeries, seriesSummarizeQuery$)
  SummarizeList(ListSeries, seriesSummarizeCol)
EndIf
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

Procedure PopulateList(Handle, List, Query$)
  ExecuteQuery(Handle, Query$)
  ; Loop over resultset
  While NextDatabaseRow(Handle)
    ; Debug GetDatabaseString(Handle,0)
    content$ = GetDatabaseString(Handle,0)
    ; Get each column
    For i=1 To DatabaseColumns(Handle)-1
      content$ = content$ + Chr(10) + GetDatabaseString(Handle,i)
    Next
    AddGadgetItem(List, -1, content$)
  Wend
  FinishDatabaseQuery(Handle)
EndProcedure

Procedure SummarizeList(List, Column)
  Dim episodes(0)
  For i=0 To CountGadgetItems(List)
    ; Get episodes
    content$ = GetGadgetItemText(List, i, Column-1)
    ReDim episodes(CountString(content$,","))
    For j=0 To CountString(content$,",")
      episodes(j) = Val(StringField(content$, j+1, ","))
    Next
    ; Only one episode
    If ArraySize(episodes())=0
      Continue
    EndIf
    ; Summarize episodes
    new$ = ""
    seriesEpisodePrev = episodes(0)
    seriesEpisodeMin  = episodes(0)
    For j=1 To ArraySize(episodes())
      ; Following episode
      If episodes(j) = seriesEpisodePrev+1
        seriesEpisodePrev = episodes(j)
      ; Gap between episodes
      Else
        ; Only one episode
        If seriesEpisodePrev=seriesEpisodeMin
          new$ = new$ + "," + Str(seriesEpisodePrev)
        ; Several episodes
        Else
          new$ = new$ + "," + Str(seriesEpisodeMin) + "-" + Str(seriesEpisodePrev)
        EndIf
        seriesEpisodePrev = episodes(j)
        seriesEpisodeMin  = episodes(j)
      EndIf
    Next
    If seriesEpisodePrev <> seriesEpisodeMin
      new$ = new$ + "," + Str(seriesEpisodeMin) + "-" + Str(seriesEpisodePrev)
    EndIf
    SetGadgetItemText(List, i, Trim(new$,","), Column-1)
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