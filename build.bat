@echo off
copy/y main.lua dist
copy/y chr.png dist
copy/y SMBLevelExtract.py dist
rem -c for console, -w for window
pyinstaller --onefile -w -i icon.ico gui.py
