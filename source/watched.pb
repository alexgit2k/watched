; Show Kodi-Watched Movies & Series
; Alex, 2017/07/16

; Variables
Global NewMap Config$()
Global NewMap SeasonComplete()

; Procedures
Declare ReadPreference(Map PrefMap$())
Declare ConfigureList(Gadget, Position, Tabname$, Columns$)
Declare PopulateList(Handle, List, Query$, Complete)
Declare SummarizeList(List, Column)
Declare Connect(Database$)
Declare Disconnect(Database)
Declare ExecuteQuery(Handle, Query$)
Declare StartWindow(Width, Height, Title$, Font$, FontSize, StartTab, Maximized$)
Declare MenuShow(ActiveList)
Declare MenuHandle()
Declare MenuCopySelection(List)
Declare MenuHighlightSelection(List)
Declare MarkComplete(List,Row,State$)
Declare GetSeasonComplete()
Declare.s GetTitleSeason(List,Row,Cols$)

; Config
ReadPreference(Config$())

; GUI
XIncludeFile "watched-window.pbf"
StartWindow(Val(Config$("width")), Val(Config$("height")), Config$("title"), Config$("font"), Val(Config$("fontsize")), Val(Config$("startTab")), Config$("maximized"))

; GUI-Texts
ConfigureList(ListMovies, 0, Config$("moviesTabname"), Config$("moviesColumns"))
ConfigureList(ListSeries, 1, Config$("seriesTabname"), Config$("seriesColumns"))

; Populate
GetSeasonComplete()
databaseHandle = Connect(Config$("database"))
PopulateList(databaseHandle, ListMovies, Config$("moviesQuery"), 0)
If (Config$("seriesSummarize") = "0")
  PopulateList(databaseHandle, ListSeries, Config$("seriesQuery"), 1)
Else
  PopulateList(databaseHandle, ListSeries, Config$("seriesSummarizeQuery"), 1)
  SummarizeList(ListSeries, Val(Config$("seriesSummarizeCol")))
EndIf
Disconnect(databaseHandle)

; Window
Repeat
  Event = WaitWindowEvent()
  Select EventWindow()
    Case WindowMain
      WindowMain_Events(Event)
  EndSelect
  ; ContextMenu
  Select Event
    Case #PB_Event_Gadget
      If EventType() = #PB_EventType_RightClick And (EventGadget() = ListMovies Or EventGadget() = ListSeries)
        MenuShow(EventGadget())
      EndIf
    Case #PB_Event_Menu
      MenuHandle()
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

Procedure PopulateList(Handle, List, Query$, Complete)
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
    ; Complete
    If Complete = 1 And Config$("completeFeature")="1"
      row = CountGadgetItems(List)-1
      If (SeasonComplete(GetTitleSeason(List,row,Config$("seriesTitleSeasonCols")))=1)
        SetGadgetItemColor(List, row, #PB_Gadget_BackColor, Val(Config$("completeColor")))
      EndIf
    EndIf
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
  If FindString(Query$,"SELECT ", 0, #PB_String_NoCase)=1
    result=DatabaseQuery(Handle, Query$)
  Else
    result=DatabaseUpdate(Handle, Query$)
  EndIf
  If result=0
    MessageRequester("Error", "Can not execute: "+DatabaseError())
    End
  EndIf
EndProcedure

Procedure StartWindow(Width, Height, Title$, Font$, FontSize, StartTab, Maximized$)
  ; Load Font
  If LoadFont(0, Font$, FontSize)
    SetGadgetFont(#PB_Default, FontID(0))
  EndIf
  ; Open Window
  OpenWindowMain(0, 0, Width, Height)
  SetWindowTitle(WindowMain, Title$)
  SetGadgetState(PanelHandle, StartTab)
  If Maximized$ = "1"
    ShowWindow_(WindowID(WindowMain),#SW_MAXIMIZE)
  EndIf
  ResizeGadgetsWindowMain()
EndProcedure

Procedure MenuShow(ActiveList)
  If ActiveList=ListMovies
    MenuItems$ = Config$("moviesMenu")
  ElseIf ActiveList=ListSeries
    MenuItems$ = Config$("seriesMenu")
  EndIf
  If CreatePopupMenu(0)
    ; Add Menus
    For i = 1 To CountString(MenuItems$,",")+1
      MenuItem(i, StringField(MenuItems$, i, ","))
    Next
  EndIf
  DisplayPopupMenu(0, WindowID(WindowMain))
EndProcedure

Procedure MenuHandle()
  ; Get active list
  If GetGadgetState(PanelHandle)=0 And GetGadgetState(ListMovies) <> -1
    ActiveList = ListMovies
  EndIf
  If GetGadgetState(PanelHandle)=1 And GetGadgetState(ListSeries) <> -1
    ActiveList = ListSeries
  EndIf
  ; Fire menu handler
  If EventMenu() = 1
    MenuCopySelection(ActiveList)
  ElseIf EventMenu() = 2 And Config$("completeFeature")="1"
    MenuHighlightSelection(ActiveList)
  EndIf
EndProcedure

Procedure MenuCopySelection(List)
  content$ = ""
  For i=0 To GetGadgetAttribute(List,#PB_ListIcon_ColumnCount)-1
    content$ = content$ + ", " + GetGadgetItemText(List,GetGadgetState(List),i)
  Next
  SetClipboardText(Trim(Trim(content$,",")))
EndProcedure

Procedure MenuHighlightSelection(List)
  row = GetGadgetState(List)
  If GetGadgetItemColor(List, row, #PB_Gadget_BackColor) = -1
    SetGadgetItemColor(List, row, #PB_Gadget_BackColor, Val(Config$("completeColor")))
    MarkComplete(List,row,"1")
  Else
    SetGadgetItemColor(List, row, #PB_Gadget_BackColor, -1)
    MarkComplete(List,row,"0")
  EndIf
EndProcedure

Procedure MarkComplete(List,Row,State$)
  ; Get title and season  
  titleseason$ = GetTitleSeason(List,Row,Config$("seriesTitleSeasonCols"))
  ; Store
  databaseHandle = Connect(Config$("FileDatabase"))
  ExecuteQuery(databaseHandle, "REPLACE INTO season_complete VALUES('"+titleseason$+"',"+State$+")")
  Disconnect(databaseHandle)
EndProcedure

Procedure GetSeasonComplete()
  If Config$("completeFeature") <> "1"
    ProcedureReturn
  EndIf
  ; Read completed seasons
  databaseHandle = Connect(Config$("FileDatabase"))
  ExecuteQuery(databaseHandle, "SELECT * FROM season_complete WHERE complete=1")
  While NextDatabaseRow(databaseHandle)
    SeasonComplete(GetDatabaseString(databaseHandle,0))=1
  Wend
  FinishDatabaseQuery(databaseHandle)
  Disconnect(databaseHandle)
EndProcedure

Procedure.s GetTitleSeason(List,Row,Cols$)
  content$ = ""
  For i=0 To CountString(Cols$,",")
    content$ = content$ + "#" + GetGadgetItemText(List, Row, Val(StringField(Cols$, i+1, ","))-1)
  Next
  ProcedureReturn ReplaceString(Mid(content$, 2),"'","''")
EndProcedure

Procedure ReadPreference(Map PrefMap$())
  ; Open Preferences
  PrefMap$("FileIni") = GetFilePart(ProgramFilename(),#PB_FileSystem_NoExtension) + ".ini"
  If (OpenPreferences(PrefMap$("FileIni")) = 0)
    MessageRequester("Error", "Can not open ini-file: "+PrefMap$("FileIni"))
    End
  EndIf
  
  ; Read
  ExaminePreferenceGroups()
  While NextPreferenceGroup()
    ExaminePreferenceKeys()
    While  NextPreferenceKey()
      ; Debug PreferenceGroupName() + ": " + PreferenceKeyName() + "=" + PreferenceKeyValue()
      PrefMap$(PreferenceKeyName())=PreferenceKeyValue()
    Wend
  Wend
  
  ; Close
  ClosePreferences()

  ; Special Configs
  PrefMap$("FileDatabase") = GetFilePart(ProgramFilename(),#PB_FileSystem_NoExtension) + ".db"
  PrefMap$("completeColor") = ReplaceString(PrefMap$("completeColor"), "#", "$")
EndProcedure

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 28
; FirstLine = 9
; EnableXP
; UseIcon = icon.ico
; Executable = ..\watched.exe
; CPU = 1
; DisableDebugger