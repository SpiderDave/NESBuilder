@echo off
set starttime=%TIME%
copy/y main.lua dist
copy/y chr.png dist
pyinstaller --onefile -w -i icon.ico -n NESBuilder.exe ^
            --add-binary "include\Tserial.lua;include" ^
            --add-binary "include\util.lua;include" ^
            --add-binary "cursors\pencil.cur;cursors" ^
            NESBuilder.py

echo start time: %starttime%
echo end time: %TIME%
pause