# NES Builder
NES Building Software made with Python and Lua

Current Stage: Alpha

![_](https://i.imgur.com/HyRHRub.png)

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
You can use "install dependencies.bat" to install these.
* lupa
* pyinstaller
* pillow
* numpy


## Plugins ##
Plugins are Lua scripts, but can also import Python scripts.
Create a "plugins" folder in the main folder and create a file there with 
.lua extension.  Files starting with "_" will be ignored.

See the sample plugin for more information.

### Callbacks ###
* onInit
* onLoadProject
* onSaveProject
* onBuild
* onExit
