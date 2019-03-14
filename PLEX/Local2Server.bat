@echo off
setlocal EnableDelayedExpansion
cls

SET mypath=%~dp0
set utilsDir=%mypath:~0,-1%\utils
set configName=config.txt
set logName=log.txt
call :getLock
EXIT /B 0

::function loads config file and loops though the specified dir(s) for both TV and Movies
::additionally starts T.M.M to update the server with .nfo and other media files; optional.
:main
if not exist "!utilsDir!\" md "!utilsDir!\"
call :initLogger
call :config
for /f "delims=" %%x in (!utilsDir!\!configName!) do set "%%x"

TITLE %title%

%drive2%
for /l %%G in (0, 1, %tvIndex%) do (
call :localPlexTvShows !tvL[%%G]!, !tvS[%%G]!
)

for /l %%G in (0, 1, %movieIndex%) do (
call :localPlexMovies !movieL[%%G]!, !movieS[%%G]!
)

call :tmmUpdate

cd %home%
pause
EXIT /B 0

::looks for any Shows on local storage and copies it over to the plex server.
:localPlexTvShows
set local=%~1
set server=%~2
if exist "%local%" (
echo "started function :localPlexTvShows"
call :logger "started function localPlexTvShows - %local%"
cd %local%
call :colorizeVariable "%local%" 93, _resultLocal
echo "looking for files in !_resultLocal!"
call :logger "looking for files in %local%"

for /r %%f in (*.mp4;*.mkv;*.avi) do (

CALL :fileToFolderName "%%~nf", -, _resultFolderName
CALL :getSeasonShowNumber "%%~nxf", ret_val2
call :trim "!ret_val2!", _resultSeasonName

call :colorizeVariable "%%~nxf" 93, _resultFile
echo "parsing !_resultFile!..."
call :logger "parsing %%f..."

if exist "%server%" (
call :copyAndMoveFile "!server!\!_resultFolderName!\!_resultSeasonName!", "%%~df%%~pf\", "!localBackUp!", "!_resultFolderName!", "%%~nxf"
) else (
echo "server TV directory does not exist or has not been added yet in config!"
call :logger "server TV directory does not exist or has not been added yet in config!"
)
)

call :colorizeVariable "finished" 92, _resultFinished
echo "!_resultFinished! in !_resultLocal!"
call :logger "finished in %local%"
) else ( 
echo "local TV directory does not exist or has not been added yet in config!"
call :logger "local TV directory does not exist or has not been added yet in config!"
)
EXIT /B 0

::looks for any movie on local storage and copies it over to the plex server.
:localPlexMovies
set local=%~1
set server=%~2
if exist "%local%" (
echo "started function :localPlexMovies"
call :logger "started function :localPlexMovies - %local%"
cd %local%
call :colorizeVariable "%local%" 93, _resultLocal
echo "looking for files in !_resultLocal!"
call :logger "looking for files in %local%"
for /r %%f in (*.mp4;*.mkv;*.avi) do (

call :colorizeVariable "%%~nxf" 93, _resultFile
echo "parsing !_resultFile!..."
call :logger "parsing %%~nxf"

call :trim "%%~nf", _folderName
set folderName=!_folderName!

if exist "%server%" (
call :copyAndMoveFile "!server!\!folderName!", "%%~df%%~pf\", %localBackUp%, "!folderName!", "%%~nxf"
) else (
echo "server MOVIE directory does not exist or has not been added yet in config!"
call :logger "server MOVIE directory does not exist or has not been added yet in config!"
)
)
call :colorizeVariable "finished" 92, _resultFinished
call :colorizeVariable "%local%" 93, _resultLocal
echo "!_resultFinished! in !_resultLocal!"
call :logger "finished in %local%"
) else ( 
echo "local MOVIE directory does not exist or has not been added yet in config!"
call :logger "local MOVIE directory does not exist or has not been added yet in config!"
)
EXIT /B 0

::function to copy to the plex server and move the original file to backup.
::function to move from the plex server and copy file to backup.
::call :copyAndMoveFile "serverDir", "localDir", "backupFolder", "folderName", "fileName"
:copyAndMoveFile
set _serverDir=%~1
set _localDir=%~2
set _localBackUpDir=%~3
set _folderName=%~4
set _fileName=%~5

if exist "!_serverDir!\!_fileName!" (
rem server
call :moveFile "%_serverDir%", "%_localBackUpDir%\Server\%_folderName%\", "%_fileName%"
)
rem local
call :copyFile "!_localDir!", "!_serverDir!", "!_fileName!"

IF %ERRORLEVEL% EQU 0 (
call :moveFile "%_localDir%", "%_localBackUpDir%\Local\%_folderName%\", "%_fileName%"
) else (
call :logger "exitCode= %ERRORLEVEL%"
echo check "%utilsDir%\%configName%" for errors.
)
EXIT /B 0

::function to copy file from one location to another
:copyFile
set _mDirFileFrom=%~1
set _mDirFileTo=%~2
set _mFileName=%~3

call :logger "copying '%_mFileName%' from '%_mDirFileFrom%' to '%_mDirFileTo%'"

robocopy "%_mDirFileFrom%" "%_mDirFileTo%" "%_mFileName%" /MT:%roboCopyMT% /R:%roboCopyRetryCount% /W:%roboCopyRetryWaitTime% /J /V

IF %ERRORLEVEL% EQU 1 (
call :logger "copied from '%_mDirFileFrom%!_mFileName!' to '%_mDirFileTo%\!_mFileName!'"
) ELSE (
call :logger "exitCode= %ERRORLEVEL%"
call :logger "Copied failed...from '!_mFileName!' to '%_mDirFileTo%'."
)
EXIT /B 0

::function to copy file from one location to another and remove the original file
:moveFile
set _mDirFileFrom=%~1
set _mDirFileTo=%~2
set _mFileName=%~3

call :logger "moving '!_mFileName!' from '%_mDirFileFrom%' to '%_mDirFileTo%"

robocopy "%_mDirFileFrom%" "%_mDirFileTo%\" "%_mFileName%" /MT:%roboCopyMT% /R:%roboCopyRetryCount% /W:%roboCopyRetryWaitTime% /J /V /mov

IF %ERRORLEVEL% EQU 1 (
call :logger "moved '!_mFileName!' from '%_mDirFileFrom%' to '%_mDirFileTo%'"
) ELSE (
call :logger "exitCode= %ERRORLEVEL%"
call :logger "Moved Failed...from '!_mFileName!' to '%_mDirFileTo%'"
)
EXIT /B 0

::call :fileToFolderName "The Rising of the Shield Hero - S01E001.mp4", -, result
::echo result = !result! 
::result = "The Rising of the Shield Hero"
:fileToFolderName
set fileName=%~1
set character=%~2
for /f "tokens=1 delims=%character%" %%a in ("%fileName%") do (
call :trim "%%a", _folderName
SET %~3=!_folderName!
)
endlocal
EXIT /B 0

::functions sees if variable has the specific character/word
:: 0 = true
:: 1 = false
:variableContains
set fileName=%~1
set character=%~2
if not "x!fileName:%character%=!"=="x%fileName%" (
    SET %~3=0
) else (
    SET %~3=1
)
EXIT /B 0

::function to add some color to my script!
::92 = green
::93 = yellow
::91 = red
:colorizeVariable
set variable1=%~1
set colorN=%~2
set %~3=[!colorN!m!variable1![0m
exit /b

::call :getSeasonShowNumber "The Rising of the Shield Hero - S01E001.mp4", result
::call :getSeasonShowNumber "The Rising of the Shield Hero - S00E001.mp4", result2
::echo result = !result! 
::result = "S1"
::result2 = "Specials"
:getSeasonShowNumber
set str=%~1
set "season=%str:- S=" & set "season=%"

if %season:~0,2%==00 ( SET %~2=Specials ) ELSE (
IF %season:~0,1%==0 ( SET %~2=S%season:~1,1% ) ELSE ( SET %~2=S%season:~0,2% )
)
EXIT /B 0

::call :trim " The Rising of the Shield Hero ", result
::echo result = !result! 
::result = "The Rising of the Shield Hero"
:trim
set input=%~1
for /f "tokens=* delims= " %%a in ("%input%") do set input=%%a
for /l %%a in (1,1,100) do if "!input:~-1!"==" " set input=!input:~0,-1!
SET %~2=%input%
EXIT /B 0

::calls TinyMediaManager to update the plex server.
:tmmUpdate
IF exist "!tmmDir!\tinyMediaManagerCMD.exe" (
%drive1%
cd !tmmDir!
tinyMediaManagerCMD.exe -update -scrapeNew
%drive2%
cd %home%
)
EXIT /B 0

:initLogger
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%
echo. >> "%utilsDir%\%logName%"
echo "started script on %ldt%" >> "%utilsDir%\%logName%"
echo. >> "%utilsDir%\%logName%"
EXIT /B 0

:logger
set input=%~1
echo "%input%" >> "%utilsDir%\%logName%"
EXIT /B 0


::function to check if config exists and read it to see if its been properly filled out
::if config does not exist; it will create a config.txt in the utils\ dir and launch it before
::excuting the :main fuction
:config

if exist "%utilsDir%\%configName%" (

call :colorizeVariable "exists!" 92, _resultExists
echo "%configName% !_resultExists!"
call :logger "%configName% exists!"

>nul findstr "<" "%utilsDir%\%configName%" && (
%utilsDir%\%configName%
call :colorizeVariable "%configName%" 91, _resultName
echo update !_resultName! before continuing....
pause
)
) else (
call :configCreator
)
EXIT /B 0

:configCreator
(
echo title=Local2Server
echo.
echo drive1="<c drive>"
echo drive2="<d drive>"
echo.
echo home=%mypath:~0,-1%
echo tmmDir="<folder location of Tiny Media Manager>"
echo localBackUp="<folder to moved copied files to>"
echo.
echo tvL[0]="<Local TV folder 1>"
echo tvS[0]="<Server TV folder 1>"
echo tvIndex="<TV index 0>"
echo.
echo movieL[0]="<Local Movie folder 1>"
echo movieS[0]="<Server Movie folder 1>"
echo movieIndex="<Movie index 0>"
echo.
echo roboCopyMT="<8-128>"
echo roboCopyRetryCount="<1-10000000>"
echo roboCopyRetryWaitTime="<X in seconds>"
) > "%utilsDir%\%configName%"
%utilsDir%\%configName%
call :colorizeVariable "ILL" 93, _resultILL
echo "%configName% is !_resultILL!"
echo update the config file before continuing....
echo if config file has not been edited...this script will exit.
pause
EXIT /B 0


:: The CALL will fail if another process already has a write lock on the script
:getLock
call :main 9>>"%~f0"
exit /b
