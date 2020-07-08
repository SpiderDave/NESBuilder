@echo off
copy/y main.lua dist
copy/y chr.png dist
copy/y SMBLevelExtract.py dist
rem -c for console, -w for window
pyinstaller --onefile -c -i icon.ico -n guic.exe gui.py
