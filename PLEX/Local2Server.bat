@echo off
setlocal EnableDelayedExpansion

call set configName=config.txt
call set logName=log.txt
call set utilsDir=%CD%\utils

call :getLock
exit /b

:main
call :initLogger
call :config

for /f "delims=" %%x in (%utilsDir%\%configName%) do set "%%x"

TITLE %title%

%drive2%


for /l %%G in (0, 1, %tvIndex%) do (
call :localPlexShows !tvL[%%G]!, !tvS[%%G]!
)

for /l %%G in (0, 1, %movieIndex%) do (
call :localPlexMovies !movieL[%%G]!, !movieS[%%G]!
)

call :serverUpdate

cd %home%

pause
exit /b

rem looks for any Shows on local storage and copies it over to the plex server.
:localPlexShows
set local=%~1
set server=%~2

echo "started function :localPlexShows - %local%"
call :logger "started function :localPlexShows - %local%"
cd %local%

echo "looking for files in %local%"
call :logger "looking for files in %local%"
for /r %%f in (*.mp4;*.mkv;*.avi) do (

CALL :fileToFolderName "%%~nf", -, _resultFolderName
CALL :getSeasonShowNumber "%%~nxf", ret_val2
call :trim "!ret_val2!", _resultSeasonName

echo "parsing %%f"
call :logger "parsing %%f"

call :copyAndMoveFile "!server!\!_resultFolderName!\!_resultSeasonName!\", "%%f", "!localBackUp!", "!_resultFolderName!", "%%~nxf"

)
echo "finished in %local%"
call :logger "finished in %local%"
EXIT /B 0

rem looks for any movie on local storage and copies it over to the plex server.
:localPlexMovies
set local=%~1
set server=%~2
echo "started function :localPlexMovies - %local%"
call :logger "started function :localPlexMovies - %local%"
cd %local%
echo "looking for files in %local%"
call :logger "looking for files in %local%"
for /r %%f in (*.mp4;*.mkv;*.avi) do (

echo "parsing %%f"
call :logger "parsing %%f"

call :stringContains "!%%~nf!", (, _stringResult
if "!_stringResult!"=="0" (
CALL :fileToFolderName "%%~nf", (, _folderName
set folderName=!_folderName!
) else (
call :trim "%%~nf", _folderName
set folderName=!_folderName!
)

call :copyAndMoveFile "!server!\!folderName!\", "%%f", "%localBackUp%", "!folderName!", "%%~nxf"
)
echo "finished in %local%"
call :logger "finished in %local%"
EXIT /B 0

rem function to copy to the plex server and move the original file to backup.
rem function to move from the plex server and copy file to backup.
rem call :copyAndMoveFile "serverDir", "localDir", "backupFolder", "folderName", "fileName"
:copyAndMoveFile
set _serverDir=%~1
set _localDir=%~2
set _localBackUpDir=%~3
set _folderName=%~4
set _fileName=%~5

if not exist "!_serverDir!\" md "!_serverDir!\" && echo created '!_serverDir!' on PLEX server.  
if exist "!_serverDir!!_fileName!" (
rem server
call :moveFile "!_serverDir!%_fileName%", "%_localBackUpDir%\Server\!_folderName!", "!_fileName!"
call :copyFile "!_localDir!", "!_serverDir!", "!_fileName!"
call :moveFile "!_localDir!", "%_localBackUpDir%\Local\!_folderName!\", "!_fileName!"
) else (
rem local
call :copyFile "!_localDir!", "!_serverDir!", "!_fileName!"
call :moveFile "!_localDir!", "%_localBackUpDir%\Local\!_folderName!", "!_fileName!"
)
EXIT /B 0

:copyFile
set _mLocalDir=%~1
set _mServerDir=%~2
set _mFileName=%~3

Echo n|COPY /y "!_mLocalDir!" "!_mServerDir!!_mFileName!"
echo "copied file from '!_mLocalDir!' to '!_mServerDir!!_mFileName!'"
call :logger "copied file from '!_mLocalDir!' to '!_mServerDir!!_mFileName!'"
EXIT /B 0

:moveFile
set _mLocalDir=%~1
set _mLocalBackUpDir=%~2
set _mFileName=%~3

if not exist "!_mLocalBackUpDir!" md "!_mLocalBackUpDir!"
move "!_mLocalDir!" "!_mLocalBackUpDir!" && echo "moved from '!_mLocalDir!' to '!_mLocalBackUpDir!!_mFileName!'"
call :logger "moved from '!_mLocalDir!' to '!_mLocalBackUpDir!!_mFileName!'"
EXIT /B 0

rem output " The Rising of the Shield Hero - S01E001 " = "The Rising of the Shield Hero"
:fileToFolderName
set variable1=%~1
set variable2=%~2
for /f "tokens=1 delims=%variable2%" %%a in ("%variable1%") do (
call :trim "%%a", _folderName
SET %~3=!_folderName!
)
endlocal
EXIT /B 0

:stringContains
set variable1=%~1
set variable2=%~2
if not "x!variable1:%variable2%=!"=="x%variable1%" (
    SET %~3=0
) else (
    SET %~3=1
)
EXIT /B 0


rem output S01 = 1, S20 = 20, S00 = Specials
:getSeasonShowNumber
set str=%~1
set "season=%str:- S=" & set "season=%"

if %season:~0,2%==00 ( SET %~2=Specials ) ELSE (
IF %season:~0,1%==0 ( SET %~2=S%season:~1,1% ) ELSE ( SET %~2=S%season:~0,2% )
)
EXIT /B 0

rem output " The Rising of the Shield Hero " = "The Rising of the Shield Hero"

:trim
set input=%~1
for /f "tokens=* delims= " %%a in ("%input%") do set input=%%a
for /l %%a in (1,1,100) do if "!input:~-1!"==" " set input=!input:~0,-1!
SET %~2=%input%
EXIT /B 0

rem calls TinyMediaManager to update the plex server.
:serverUpdate
%drive1%
cd %tmmDir%
tinyMediaManagerCMD.exe -update -scrapeNew
%drive2%
cd %home%
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
echo %input% >> "%utilsDir%\%logName%"
EXIT /B 0

:config
if exist %utilsDir%\%configName% (
echo %configName% exists....
) else (
(
echo title=Local2Server
echo.
echo drive1="<c drive>"
echo drive2="<d drive>"
echo.
echo home="<home dir where this script is located>"
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
) > %utilsDir%\%configName%
%utilsDir%\%configName%
echo update the config file before continuing....
pause
)
EXIT /B 0

:getLock
:: The CALL will fail if another process already has a write lock on the script
call :main 9>>"%~f0"
exit /b
