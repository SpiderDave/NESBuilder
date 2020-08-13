@echo off

rem run this to fill the pycmd environment variable
call findpython.bat 1
if %errorlevel% NEQ 0 goto error

echo.

echo Checking for pip...
%pycmd% -m pip --version 2>NUL
if errorlevel 1 set errormessage=Error: Could not find pip & goto error
echo.

echo Attempting to install lupa...
%pycmd% -m pip install lupa
echo Attempting to install pyinstaller...
%pycmd% -m pip install pyinstaller
echo Attempting to install pillow...
%pycmd% -m pip install pillow
echo Attempting to install numpy...
%pycmd% -m pip install numpy

if %errorlevel% NEQ 0 goto error

goto theend

:error
echo.
echo Did NOT complete successfully.
echo.%errormessage%
echo.
echo.
echo                      No longer do the dance of joy Numfar.
echo.
echo.
pause
exit

:theend
echo.
echo Done.
echo.
echo.
echo                           Numfar, do the dance of joy!
echo.
echo.
pause