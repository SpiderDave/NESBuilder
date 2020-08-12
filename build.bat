@echo off
copy/y main.lua dist
copy/y chr.png dist
pyinstaller --onefile -w -i icon.ico -n gui.exe ^
            --add-binary "include\Tserial.lua;include" ^
            --add-binary "include\util.lua;include" ^
            --add-binary "cursors\pencil.cur;cursors" ^
            gui.py
