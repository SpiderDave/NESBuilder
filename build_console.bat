@echo off
copy/y main.lua dist
copy/y chr.png dist
pyinstaller --onefile -c -i icon.ico -n guic.exe ^
            --add-binary "include\Tserial.lua;include" ^
            --add-binary "include\util.lua;include" ^
            --add-binary "cursors\pencil.cur;cursors" ^
            gui.py
