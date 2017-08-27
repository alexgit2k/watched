# Watched

Show which movies or series have already been watched in Kodi.

![Screenshot](screenshot.png)

## Prerequisites
- Kodi: https://kodi.tv/
- Add-on WatchedList: http://kodi.wiki/view/Add-on:WatchedList

## Configuration
Watched can be configured in the file watched.ini
### Base
- database: Location of WatchedList sqlite-database
### Movies
- moviesTabname: Title
- moviesColumns: Headlines and widths
- moviesQuery: Query
- moviesMenu: Context-menu text
### Series
- seriesTabname: Title
- seriesColumns: Headlines and widths
- seriesQuery: Query
- seriesSummarizeQuery: Query for summarized episodes
- seriesSummarize: Summarize episodes per season
- seriesSummarizeCol: Column used to summarize
- seriesTitleSeasonCols: Columns for title and season (used for marking completed seasons)
- seriesMenu: Context-menu text
- completeFeature: Enable marking of completed seasons
### Window
- title: Window-title
- font: Font
- fontsize: Fontsize
- width: Window-width
- height: Window-height
- startTab: = Open tab-number at start (0-1)
- maximized: Start window maximized
- completeColor = Color for marking completed seasons
