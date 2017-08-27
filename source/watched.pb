; Show Kodi-Watched Movies & Series
; Alex, 2017/07/16

; Variables
Global NewMap Config$()

; Procedures
Declare ReadPreference(Map PrefMap$())
Declare ConfigureList(Gadget, Position, Tabname$, Columns$)
Declare PopulateList(Handle, List, Query$)
Declare SummarizeList(List, Column)
Declare Connect(Database$)
Declare Disconnect(Database)
Declare ExecuteQuery(Handle, Query$)
Declare StartWindow(Width, Height, Title$, Font$, FontSize, StartTab, Maximized$)
Declare MenuShow(MenuItem$)
Declare MenuHandle()
Declare MenuCopySelection(List)

; Config
ReadPreference(Config$())

; GUI
XIncludeFile "watched-window.pbf"
StartWindow(Val(Config$("width")), Val(Config$("height")), Config$("title"), Config$("font"), Val(Config$("fontsize")), Val(Config$("startTab")), Config$("maximized"))

; GUI-Texts
ConfigureList(ListMovies, 0, Config$("moviesTabname"), Config$("moviesColumns"))
ConfigureList(ListSeries, 1, Config$("seriesTabname"), Config$("seriesColumns"))

; Populate
databaseHandle = Connect(Config$("database"))
PopulateList(databaseHandle, ListMovies, Config$("moviesQuery"))
If (Config$("seriesSummarize") = "0")
  PopulateList(databaseHandle, ListSeries, Config$("seriesQuery"))
Else
  PopulateList(databaseHandle, ListSeries, Config$("seriesSummarizeQuery"))
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
        MenuShow(Config$("menu"))
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

Procedure MenuShow(MenuItem$)
  If CreatePopupMenu(0)
    MenuItem(1, MenuItem$)
  EndIf
  DisplayPopupMenu(0, WindowID(WindowMain))
EndProcedure

Procedure MenuHandle()
  If EventMenu() = 1
    If GetGadgetState(PanelHandle)=0 And GetGadgetState(ListMovies) <> -1
      MenuCopySelection(ListMovies)
    EndIf
    If GetGadgetState(PanelHandle)=1 And GetGadgetState(ListSeries) <> -1
      MenuCopySelection(ListSeries)
    EndIf
  EndIf
EndProcedure

Procedure MenuCopySelection(List)
  content$ = ""
  For i=0 To GetGadgetAttribute(List,#PB_ListIcon_ColumnCount)-1
    content$ = content$ + ", " + GetGadgetItemText(List,GetGadgetState(List),i)
  Next
  SetClipboardText(Trim(Trim(content$,",")))
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
EndProcedure

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 28
; FirstLine = 9
; EnableXP
; UseIcon = icon.ico
; Executable = ..\watched.exe
; CPU = 1
; DisableDebugger