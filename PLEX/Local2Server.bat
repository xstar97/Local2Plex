@echo off
setlocal EnableDelayedExpansion
cls

:: path where batch script is located
SET mypath=%~dp0
::utils dir
set utilsDir=%mypath:~0,-1%\utils
::name of config file
set configName=config.txt
::name of log file
set logName=log.txt
::"boolean" to start TMM if any changes were made; any files copied to the server.
set startTMM=1

rem for /f "delims== tokens=1,2" %%G in (%utilsDir%\lang\strings-1033.txt) do set %%G=%%H

::starts script
call :getLock
EXIT /B 0

:: The CALL will fail if another process already has a write lock on the script
:getLock
call :main 9>>"%~f0"
exit /b

::function loads config file and loops though the specified dir(s) for both TV and Movies
::additionally starts T.M.M to update the server with .nfo and other media files; optional.
:main
if not exist "!utilsDir!\" md "!utilsDir!\"

call :initLogger
call :config

::method loads config and sets all the variables for the script
for /f "delims=" %%x in (!utilsDir!\!configName!) do set "%%x"

::this hacks your zoom
TITLE %title%

::in order to cd from different drives....this switches to the drive letter first.
%drive2%
::loops through the main dirs/sub dir for files
for /l %%G in (0, 1, %tvIndex%) do (
call :localPlexTvShows !tvL[%%G]!, !tvS[%%G]!
)

::loops through the main dirs/sub dir for files
for /l %%G in (0, 1, %movieIndex%) do (
call :localPlexMovies !movieL[%%G]!, !movieS[%%G]!
)

::starts T.M.M to update the server
call :tmmUpdate

cd %home%
pause
EXIT /B 0

::looks for any Shows on local storage and copies it over to the plex server.
:localPlexTvShows
set local=%~1
set server=%~2

set startFunction=Started function :localPlexTvShows
set lookingForFiles=Looking for files in '%local%'

set noServerDir=server directory does not exist or has not been added yet in config; '%server%'
set noLocalDir=local directory does not exist or has not been added yet in config; '%local%'
set finishedIn=Finished in '%local%'
set parsing=Parsing
if exist "%local%" (

echo "%startFunction%"
call :logger "%startFunction% - %local%"
cd %local%
call :colorizeVariable "%lookingForFiles%" 93, _resultLocal
echo "!_resultLocal!"
call :logger "%lookingForFiles%"

if "!videoFilterTV!"=="" ( set videoFilterTV=*.mp4;*.mkv;*.avi
)
for /r %%f in (!videoFilterTV!) do (

CALL :fileToFolderName "%%~nf", -, _resultFolderName
CALL :getSeasonShowNumber "%%~nxf", ret_val2
call :trim "!ret_val2!", _resultSeasonName

call :colorizeVariable "%%~nxf" 93, _resultFile
echo "%parsing% !_resultFile!..."
call :logger "%parsing% %%f..."

if exist "%server%" (
call :copyAndMoveFile "!server!\!_resultFolderName!\!_resultSeasonName!", "%%~df%%~pf\", "!localBackUp!", "!_resultFolderName!", "%%~nxf"
) else (
call :colorizeVariable "%noServerDir%" 91, _noServerCl
echo "!_noServerCl!"
call :logger "%noServerDir%"
)
)
call :colorizeVariable "%finishedIn%" 92, _resultFinished
echo "!_resultFinished!"
call :logger "%finishedIn%"
) else ( 

call :colorizeVariable "%noLocalDir%" 91, _noLocalCl
echo "!_noLocalCl!"
call :logger "%noLocalDir%"
)
EXIT /B 0

::looks for any movie on local storage and copies it over to the plex server.
:localPlexMovies
set local=%~1
set server=%~2

set startFunction=Started function :localPlexMovies
set lookingForFiles=Looking for files in '%local%'

set noServerDir=server directory does not exist or has not been added yet in config; '%server%'
set noLocalDir=local directory does not exist or has not been added yet in config; '%local%'
set finishedIn=Finished in '%local%'
set parsing=Parsing

if exist "%local%" (
echo "%startFunction%"
call :logger "%startFunction% - %local%"
cd %local%
call :colorizeVariable "%lookingForFiles%" 93, _resultLocal
echo "!_resultLocal!"
call :logger "%lookingForFiles%"

if "!videoFilterMovie!"=="" ( set videoFilterMovie=*.mp4;*.mkv;*.avi
)
for /r %%f in (!videoFilterMovie!) do (
call :colorizeVariable "%%~nxf" 93, _resultFile
echo "%parsing% !_resultFile!..."
call :logger "%parsing% %%~nxf"

call :trim "%%~nf", _folderName
set folderName=!_folderName!

if exist "%server%" (
call :copyAndMoveFile "!server!\!folderName!", "%%~df%%~pf\", %localBackUp%, "!folderName!", "%%~nxf"
) else (
call :colorizeVariable "%noServerDir%" 91, _noServerCl
echo "!_noServerCl!"
call :logger "%noServerDir%"
)
)
call :colorizeVariable "%finishedIn%" 92, _resultFinished
echo "!_resultFinished!"
call :logger "%finishedIn%"
) else ( 

call :colorizeVariable "%noLocalDir%" 91, _noLocalCl
echo "!_noLocalCl!"
call :logger "%noLocalDir%"
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

set checkConfigForErrors=Check '%configName%' for errors; '%utilsDir%\%configName%'
set exitCode=exitCode equals
if exist "!_serverDir!\!_fileName!" (
rem server
call :moveFile "%_serverDir%", "%_localBackUpDir%\Server\%_folderName%\", "%_fileName%"
)
rem local
call :copyFile "!_localDir!", "!_serverDir!", "!_fileName!"

IF %ERRORLEVEL% EQU 0 (
call :moveFile "%_localDir%", "%_localBackUpDir%\Local\%_folderName%\", "%_fileName%"
) else (
call :logger "%exitCode% %ERRORLEVEL%"
echo "%checkConfigForErrors%"
)
EXIT /B 0

::function to copy file from one location to another
:copyFile
set _mDirFileFrom=%~1
set _mDirFileTo=%~2
set _mFileName=%~3

set copyingFromTo=Copying '%_mFileName%' from '%_mDirFileFrom%' to '%_mDirFileTo%'
set copiedFromTo=Copied '%_mFileName%' from '%_mDirFileFrom%' to '%_mDirFileTo%'
set errorCopiedFromTo=Failed to copy '%_mFileName%'...from '%_mDirFileFrom%' to '%_mDirFileTo%'

set exitCode=exitCode equals

call :logger "%copyingFromTo%"

robocopy "%_mDirFileFrom%" "%_mDirFileTo%" "%_mFileName%" /MT:%roboCopyMT% /R:%roboCopyRetryCount% /W:%roboCopyRetryWaitTime% /J /V

IF %ERRORLEVEL% EQU 1 (
call :logger "%copiedFromTo%"
set startTMM=0
) ELSE (
call :logger "%exitCode% %ERRORLEVEL%"
call :logger "!errorCopiedFromTo!"
)
EXIT /B 0

::function to copy file from one location to another and remove the original file
:moveFile
set _mDirFileFrom=%~1
set _mDirFileTo=%~2
set _mFileName=%~3

set movingFile=moving '!_mFileName!' from '%_mDirFileFrom%' to '%_mDirFileTo%
set movedFile=moved '!_mFileName!' from '%_mDirFileFrom%' to '%_mDirFileTo%'
set errorFailedToMoved=Failed to move '%_mFileName%'...from '%_mDirFileFrom%' to '%_mDirFileTo%'
set exitCode=ExitCode equals

call :logger "%movingFile%"

robocopy "%_mDirFileFrom%" "%_mDirFileTo%\" "%_mFileName%" /MT:%roboCopyMT% /R:%roboCopyRetryCount% /W:%roboCopyRetryWaitTime% /J /V /mov

IF %ERRORLEVEL% EQU 1 (
call :logger "%movedFile%"
) ELSE (
call :logger "%exitCode% %ERRORLEVEL%"
call :logger "%errorFailedToMoved%"
)
EXIT /B 0

::calls TinyMediaManager to update the plex server.
:tmmUpdate
set noNeedToStartTMM=No files were copied to the server, no need to start T.M.M

IF exist "!tmmDir!\tinyMediaManagerCMD.exe" (
if "%startTMM%"=="0" (
%drive1%
cd !tmmDir!
tinyMediaManagerCMD.exe -update -scrapeNew
%drive2%
cd %home%
set startTMM=1
) else (
echo "%noNeedToStartTMM%"
call :logger "%noNeedToStartTMM%"
)
)
EXIT /B 0

:initLogger
set scriptStarted=started script on
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%
(
echo.
echo "%scriptStarted% %ldt%"
echo.
)>> "%utilsDir%\%logName%"
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

set fileExist='%configName%' exists!
call :colorizeVariable "!fileExist!" 92, _resultExists
echo "!_resultExists!"
call :logger "%fileExist%"

>nul findstr "<" "%utilsDir%\%configName%" && (
%utilsDir%\%configName%
call :colorizeVariable "%configName%" 91, _resultName
set updateConfig=Update '!_resultName!' before continuing....
echo "%updateConfig%"
)
) else (
call :configCreator
)
EXIT /B 0

:configCreator
set updateConfig=Update '%configName%' before continuing....
set editConfig=If '%configName%' has not been edited/fixed...this script will exit.
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
echo videoFilterTV=*.mp4;*.mkv;*.avi
echo.
echo movieL[0]="<Local Movie folder 1>"
echo movieS[0]="<Server Movie folder 1>"
echo movieIndex="<Movie index 0>"
echo videoFilterMovie=*.mp4;*.mkv;*.avi
echo.
echo roboCopyMT="<8-128>"
echo roboCopyRetryCount="<1-10000000>"
echo roboCopyRetryWaitTime="<X in seconds>"
echo.
) > "%utilsDir%\%configName%"
%utilsDir%\%configName%
echo "%updateConfig%"
echo "%editConfig%"
pause
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
