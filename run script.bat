@echo off
rem -- Settings ----------------------------

rem pause when done
rem (note: errors will always pause)
set dopause=0

set script=NESBuilder.py

rem ----------------------------------------

rem default error
set errormessage=unspecified error

rem make sure the working folder is the one containing this file.
cd /D "%~dp0"

rem run this to fill the pycmd environment variable
call findpython.bat 1
if %errorlevel% NEQ 0 goto error

rem clear screen to give a fresh console output window for debugging
cls

%pycmd% %script%
if %errorlevel% NEQ 0 set errormessage=script error&goto error

goto success

:error
echo.
echo.ERROR: %errormessage%
echo.
pause
goto theend

:success
if %dopause% NEQ 0 pause

:theend