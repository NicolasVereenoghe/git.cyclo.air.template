@echo off
set PAUSE_ERRORS=1
call bat_air\SetupSDK.bat
call bat_air\SetupApplication.bat

set AIR_TARGET=
::set AIR_TARGET=-captive-runtime
set OPTIONS=-tsa none
call bat_air\Packager.bat

pause