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

## Building / Running From Source ##
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

## Installation Issues ##
Issue:
    In Windows 10, when installing Python 3 from the Windows store, importing PyQt5.QtWidgets causes
    an error: "ImportError: DLL load failed: The specified module could not be found."
Solution:
    None yet :(

Issue:
    When pip attempts to install lupa, there are many errors, and one of them near the bottom says
    "error: Microsoft Visual C++ 14.0 is required. Get it with "Build Tools for Visual Studio": https://visualstudio.microsoft.com/downloads/"
Solution:
    using cholatey:
    choco install visualcpp-build-tools --version=14.0.25420.1
    Installing this appeared to hang, but it actually required pressing enter.
    It's possible the latest version might work instead, and other installations untested.

Issue:
    Unable to get NESBuilder working form source.
Workaround:
    If you can run the binary NESBuilder.exe you can pass a parameter to run the latest version of the script.
    "NESBuilder.exe main.lua"
    The binary won't be updated as often, and this may not work or cause errors, but it's possible you can
    still try out features without waiting for a new binary.

## Plugins ##
Plugins are Lua scripts, but can also import Python scripts.

See sample plugins for more information.

