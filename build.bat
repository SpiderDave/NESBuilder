@echo off

rem -- Settings ----------------------------

rem pyinstaller flag to add a console window
set console=0

rem pause when done
rem (note: errors will always pause)
set dopause=0

rem ----------------------------------------


set starttime=%TIME%

rem test to make sure we have the "where" command
where/?>nul 2>&1
if %errorlevel% NEQ 0 set errormessage="where" command not available.& goto error

rem set pyinstaller flag to determine if a console window will be added
set parameter=w
if %console% NEQ 0 set suffix=C& set parameter=c

rem run this to fill the pycmd environment variable
call findpython.bat 1
if %errorlevel% NEQ 0 goto error

rem make sure we can find pyinstaller
where/q pyinstaller
if %errorlevel% NEQ 0 set errormessage=Could not find pyinstaller.& goto error

%pycmd% makeVersion.py
if %errorlevel% NEQ 0 set errormessage=Could not create version information file.&goto error

rem run pyinstaller
echo starting pyinstaller...
pyinstaller --onefile -%parameter% -i icon.ico -n NESBuilder%suffix%.exe ^
            --add-binary "main.lua;include" ^
            --add-binary "icons\__init__.py;icons" ^
            --add-binary "icons\folder32.png;icons" ^
            --add-binary "icons\folderplus32.png;icons" ^
            --add-binary "icons\gear32.png;icons" ^
            --add-binary "icons\note32.png;icons" ^
            --add-binary "icons\clock32.png;icons" ^
            --add-binary "icons\project.png;icons" ^
            --add-binary "include\Tserial.lua;include" ^
            --add-binary "include\util.lua;include" ^
            --add-binary "include\style.qss;include" ^
            --add-binary "cursors\pencil.cur;cursors" ^
            --add-binary "cursors\LinkSelect.cur;cursors" ^
            --hidden-import "lupa._lupa" ^
            --hidden-import PyQt5.QtPrintSupport ^
            --version-file "version.py" ^
            NESBuilder.py
if %errorlevel% NEQ 0 goto error

set sdasmupdate="J:\svn\NESBuilder\include\SpiderDaveAsm\update and commit.bat"
call "%sdasmupdate%"
if %errorlevel% NEQ 0 set errormessage=Could not find %sdasmupdate%.& goto error

echo start time: %starttime%
echo end time: %TIME%

goto success

:error
echo.
echo.ERROR: %errormessage%
echo.
pause
goto theend

:success
echo Done.
if %dopause% NEQ 0 pause

:theend

