@echo off
copy/y main.lua dist
copy/y chr.png dist
copy/y SMBLevelExtract.py dist
rem copy/y Tserial.lua dist
rem -c for console, -w for window
rem pyinstaller --onefile -c -i icon.ico -n guic.exe gui.py
pyinstaller --onefile -c -i icon.ico -n guic.exe ^
            --add-binary "include\Tserial.lua;include" ^
            --add-binary "include\util.lua;include" ^
            gui.py
