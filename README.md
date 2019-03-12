# Local2Plex
batch script to push files from local drive to nas server that runs plex/kodi with automatic folder creating and other features.

this script reqires third party software called TinyMediaManager - https://www.tinymediamanager.org/
to update the server with nfo files, images, etc. vs per device loading info from kodi. The info is the same across all devices.
if tiny media is not needed for you...then comment out 'call :serverUpdate'

Movies and TV shows have different naming conventions...so in order for the script to work on almost all tv shows.... this is the naming 
scheme I use for all my Tv shows, Animes, and other 'animes'

TV:

OK:)

file name - SXXEXXX.XXX

NOT ok:( - script/server will break

file name - SXXEXXX - bla bla bla.XXX


Movies

OK:)

file name.XXX
file name (XXXX).XXX


NOT ok - script/server will break

file name - bla bla - bla bla (2018).XXX
file name (XXXX) - bla - (bla bla).XXX


Once the script has started it will lock itself so it can not be excuted again until it closes/fails.
This is a safey mechanism to not cause file(s) corruption.
it will also create a file called config.txt too if its not available...unfortunately it will need to be populated by hand:(

so here's a great summary on how to do that!

### Config.txt

title=Local2Server -> change this too whatever you want; optional

drive1=c: -> this is my main drive that has third party programs installed on it; TinyMediaManager

drive2=d: -> this is my main drive that house all my media locally before sending it over to the server

home="D:\Downloads\PLEX" -> main folder thats holds all the data and scripts

tmmDir="C:\Program Files (x86)\TMM" -> dir where TinyMediaManager is located

localBackUp="D:\Downloads\PLEX\BackUp" -> dir where all files will be moved after being copied to server /from server to local

tvL[0]="D:\Downloads\PLEX\Animes" -> local tv folder1; L

tvS[0]="P:\Animes" -> server tv folder1; S

tvL[1]="D:\Downloads\PLEX\AnimesH" -> local tv folder2; L

tvS[1]="P:\AnimesH" -> server tv folder2; S

tvL[2]="D:\Downloads\PLEX\TV" -> local tv folder3; L

tvS[2]="P:\TV" -> server tv folder3; S

tvIndex=2 -> index of last tv(L/S); has to be the same number!

movieL[0]="D:\Downloads\PLEX\Movies" -> local movie folder1; L

movieS[0]="P:\Movies" -> local movie folder1; S

movieIndex=0 -> index of last movie(L/S); has to be the same number!

###
notes: 

tvL/S and movieL/S is for the default folders where everything is stored on local and server
do NOT use it declare every specific tv/movie folder as will break the script!

### Log.txt
the script will create a log.txt and logged almost all the actions:

* parsing the file
* copying to server
* moving file from local to backup
* moving file from server to backup

### specials
if you followed my naming convention...then you should be thrilled about this...
if the file is "fileName - S00E001.mp4" it will send it over to a folder called Specials instead of S0/S00
however if thats not what you want then changed 'Specials' to what ever you want in ':getSeasonShowNumber'
