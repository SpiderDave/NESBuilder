@echo off
set starttime=%TIME%
copy/y main.lua dist
copy/y chr.png dist
pyinstaller --onefile -c -i icon.ico -n NESBuilderC.exe ^
            --add-binary "include\Tserial.lua;include" ^
            --add-binary "include\util.lua;include" ^
            --add-binary "cursors\pencil.cur;cursors" ^
            NESBuilder.py

echo start time: %starttime%
echo end time: %TIME%
