@echo off

set numpackages=7

echo Checking for administrative permissions...

net session >nul 2>&1
if %errorLevel% == 0 (
    echo Admin permissions confirmed.
) else (
    set errormessage=Please run this file as adminstrator
    goto error
)

rem make sure the working folder is the one containing this file.
cd /D "%~dp0"
echo current directory: %cd%

rem run this to fill the pycmd environment variable
call findpython.bat 1
if %errorlevel% NEQ 0 goto error

echo.

echo Checking for pip...
%pycmd% -m pip --version 2>NUL
if %errorlevel% NEQ 0 set errormessage=Could not find pip & goto error
echo Attempting to install lupa...
%pycmd% -m pip install lupa
if %errorlevel% NEQ 0 echo Could not install Lupa
echo Attempting to install pyinstaller...
%pycmd% -m pip install pyinstaller
if %errorlevel% NEQ 0 echo Could not install PyInstaller
echo Attempting to install pillow...
%pycmd% -m pip install pillow
if %errorlevel% NEQ 0 echo Could not install Pillow
echo Attempting to install numpy...
%pycmd% -m pip install numpy
if %errorlevel% NEQ 0 echo Could not install NumPy
echo Attempting to install PyQt5...
%pycmd% -m pip install PyQt5
if %errorlevel% NEQ 0 echo Could not install PyQt5
echo Attempting to install QScintilla...
%pycmd% -m pip install QScintilla
if %errorlevel% NEQ 0 echo Could not install QScintilla


rem set up variables
set /a counter=0
set pip=
set lupa=
set numpy=
set PyInstaller=
set PyQt5=
set Pillow=
set QScintilla=

echo.
echo -- Summary -----------------------------
set name=
for /f "tokens=1,2 delims= " %%A in ('pip list') do ^
if "%%A"=="pip" (set %%A=%%B) else ^
if "%%A"=="lupa" (set %%A=%%B) else ^
if "%%A"=="numpy" (set %%A=%%B) else ^
if "%%A"=="PyInstaller" (set %%A=%%B) else ^
if "%%A"=="pyinstaller" (set %%A=%%B) else ^
if "%%A"=="PyQt5" (set %%A=%%B) else ^
if "%%A"=="Pillow" (set %%A=%%B) else ^
if "%%A"=="QScintilla" (set %%A=%%B) else ^
rem

rem Windows 10 (and others?) is "pyinstaller" (lowercase)
if %pyinstaller%x neq x set PyInstaller=%pyinstaller%

if %pip%x neq x (echo pip %pip% & set /a counter=%counter%+1) else echo pip [not installed]
if %lupa%x neq x (echo lupa %lupa% & set /a counter=%counter%+1) else (echo lupa [not installed])
if %numpy%x neq x (echo numpy %numpy% & set /a counter=%counter%+1) else echo numpy [not installed]
if %PyInstaller%x neq x (echo PyInstaller %PyInstaller% & set /a counter=%counter%+1) else echo PyInstaller [not installed]
if %PyQt5%x neq x (echo PyQt5 %PyQt5% & set /a counter=%counter%+1) else echo PyQt5 [not installed]
if %Pillow%x neq x (echo Pillow %Pillow% & set /a counter=%counter%+1) else echo Pillow [not installed]
if %QScintilla%x neq x (echo QScintilla %QScintilla% & set /a counter=%counter%+1) else echo QScintilla [not installed]
echo.

echo %counter%/%numpackages% required packages were installed.
echo ----------------------------------------
if %counter% neq %numpackages% set errormessage=Some packages not installed.&goto error

goto success

:error
echo.
echo Did NOT complete successfully.
echo.ERROR: %errormessage%
echo.
echo.
echo                      No longer do the dance of joy Numfar.
echo.
echo.
pause
goto theend

:success
echo.
echo Done.
echo.
echo.
echo                           Numfar, do the dance of joy!
echo.
echo.
pause

:theend