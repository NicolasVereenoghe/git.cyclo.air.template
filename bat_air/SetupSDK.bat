:user_configuration

:: Path to Flex SDK
::set FLEX_SDK=C:\Program Files (x86)\FlashDevelop\Tools\flexsdk17.0.0.124
set FLEX_SDK=C:\Program Files (x86)\FlashDevelop\Tools\flexsdk_air27.0.0.116


:validation
if not exist "%FLEX_SDK%" goto flexsdk
goto succeed

:flexsdk
echo.
echo ERROR: incorrect path to Flex SDK in 'bat_air\SetupSDK.bat'
echo.
echo %FLEX_SDK%
echo.
if %PAUSE_ERRORS%==1 pause
exit

:succeed
set PATH=%PATH%;%FLEX_SDK%\bin

