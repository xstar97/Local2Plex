# Local2Plex
batch script to push files from local drive to nas server that runs plex/kodi with automatic folder creating and other features.

this script optionally uses a third party software called TinyMediaManager - https://www.tinymediamanager.org/
to update the server with nfo files, images, etc. vs per device loading info from kodi. The info is the same across all devices.
if tiny media is not needed for you...then just leave tmmDir="" blank.

another program that ties in nicely with this one is 'uget' -> https://ugetdm.com/
In the settings when downloads are completed my script can be excuted automatically.

Movies and TV shows have different naming conventions...so in order for the script to work on almost all tv shows.... this is the default naming scheme I use for all my Tv shows, Animes, and other 'animes'
I may add a config later to add additional naming conventions, but....im lazy:/

TV: OKAY!
   
file name - SXXEXXX.XXX

file name - SXXEXXX - bla bla bla.XXX


Movies: OK:)

file name.XXX

file name (XXXX).XXX


NOT OK:(

file name - bla bla - bla bla (2018).XXX

file name (XXXX) - bla - (bla bla).XXX


### specials
if you followed my naming convention...then you should be thrilled about this...
if the file is "fileName - S00E001.mp4" it will send it over to a folder called Specials instead of S0/S00
however if thats not what you want then changed 'Specials' to what ever you want in ':getSeasonShowNumber'

Once the script has started it will lock itself so it can not be excuted again until it closes/fails.
This is a safey mechanism to not cause file(s) corruption.
it will also create a file called config.txt too if its not available...populate it with data and continue the script.

### Config.txt

please see my sample config.txt in https://github.com/Xstar97/Local2Plex/blob/master/PLEX/utils/config.txt
on how it supposed to be used with this script.

notes: 
tvL/S and movieL/S are for the default folders where everything is stored on local and server
do NOT use it declare every specific tv/movie folder as will break the script!

examples:
* TV
* Anime
* Action TV

* Movies
* Comedy Movies


### Log.txt
the script will create a log.txt and logged almost all the actions:

* parsing the file
* copying to server
* moving file from local to backup
* moving file from server to backup
