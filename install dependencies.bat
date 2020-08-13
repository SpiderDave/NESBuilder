@echo off

rem test to make sure we have the "where" command
where/?>nul 2>&1
if %errorlevel% NEQ 0 set errormessage="where" command not available.& goto error


rem -- find python --------------------
echo Locating python...
echo Attempt 1: "py"
py --version 2>NUL
if errorlevel 1 set errormessage=Error: Could not find python & goto error
set pycmd=py
goto foundpython

echo Attempt 2: "python"
python -c "from sys import version_info as v;_=0/int(v.major/3)">nul 2>&1
if %errorlevel% EQU 0 set pycmd=python&goto foundpython

echo Attempt 3: "python" using "python" environment variable

rem check for environment variable
if %python%X EQU X goto skip1

rem test "%python%/python"
%python%\python -c "from sys import version_info as v;_=0/int(v.major/3)">nul 2>&1
if %errorlevel% NEQ 0 goto skip1

set pycmd=%python%\python
goto foundpython

:skip1

:foundpython
echo Found.

rem -----------------------------------

echo.

rem echo Checking for python...
rem py --version 2>NUL
rem if errorlevel 1 set errormessage=Error: Could not find python & goto error
rem echo.

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