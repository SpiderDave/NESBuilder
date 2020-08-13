@echo off
echo Checking for python...
py --version 2>NUL
if errorlevel 1 set errormessage=Error: Could not find python & goto error
echo.

echo Checking for pip...
py -m pip --version 2>NUL
if errorlevel 1 set errormessage=Error: Could not find pip & goto error
echo.

echo Attempting to install lupa...
py -m pip install lupa
echo Attempting to install pyinstaller...
py -m pip install pyinstaller
echo Attempting to install pillow...
py -m pip install pillow
echo Attempting to install numpy...
py -m pip install numpy

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