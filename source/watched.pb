; Show Kodi-Watched Movies & Episodes
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
moviesQuery$    = ReadPreferenceString("movies","")
episodesQuery$  = ReadPreferenceString("episodes","")
font$           = ReadPreferenceString("font","")
fontSize        = ReadPreferenceInteger("fontsize",12)
width           = ReadPreferenceInteger("width",600)
height          = ReadPreferenceInteger("height",400)

; GUI
If LoadFont(0, font$, fontSize)
	SetGadgetFont(#PB_Default, FontID(0))
EndIf
XIncludeFile "watched-window.pbf"
OpenWindowMain(0, 0, width, height)
ResizeGadgetsWindowMain()

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

; Query Episodes
If DatabaseQuery(databaseHandle, episodesQuery$)
  While NextDatabaseRow(databaseHandle)
    ;Debug GetDatabaseString(databaseHandle,0) + GetDatabaseString(databaseHandle,1) + GetDatabaseString(databaseHandle,2)
    AddGadgetItem(ListSeries, -1, GetDatabaseString(databaseHandle,0) + Chr(10) + GetDatabaseString(databaseHandle,1) + Chr(10) + GetDatabaseString(databaseHandle,2))
  Wend
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
 
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 28
; FirstLine = 9
; EnableXP
; UseIcon = icon.ico
; Executable = ..\watched.exe
; CPU = 1
; DisableDebugger