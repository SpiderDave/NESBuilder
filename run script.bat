@echo off
rem -- Settings ----------------------------

rem pause when done
rem (note: errors will always pause)
set dopause=0

rem ----------------------------------------

rem default error
set errormessage=unspecified error

rem run this to fill the pycmd environment variable
call findpython.bat 1
if %errorlevel% NEQ 0 goto error

rem clear screen to give a fresh console output window for debugging
cls

%pycmd% NESBuilder.py
if %errorlevel% NEQ 0 set errormessage=script error&goto error

goto theend

:error
echo.
echo.ERROR: %errormessage%
echo.
pause
exit

:theend
if %dopause% NEQ 0 pause