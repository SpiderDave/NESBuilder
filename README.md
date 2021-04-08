# NES Builder
NES development and romhacking tool made with Python and Lua

Current Stage: Alpha

![_](https://i.imgur.com/iIQ8cAW.png)

## Features ##
* Open source
* "Build" project, which exports various items and assembles project.asm if it exists.
* Palette editor
* Import CHR banks from .chr, .png, .png (nesmaker).
* Export CHR banks to .png with chosen palette.
* Metatile creator
* plugin system (Lua/Python)
* Integrated custom 6502 assembler (sdasm)

## Installing ##
Download the [latest release](https://github.com/SpiderDave/NESBuilder/releases).
The NESBuilder_Setup.exe installer will allow you to download and install the latest compoents:
* NESBuilder Executable
* NESBuilder Source
* Installer Source
* Start Menu Shortcuts

## Building ##
Requirements:
* Windows
* Python 3

Python packages:
You can use "install dependencies.bat" to install these.  Make sure you run "as administrator".
* lupa
* pyinstaller
* pillow
* numpy
* PyQt5
* QScintilla

## Plugins ##
Plugins are Lua scripts, but can also import Python scripts.

See sample plugins for more information.

