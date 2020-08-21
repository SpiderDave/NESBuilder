# NES Builder
NES development tool made with Python and Lua

Current Stage: Alpha

![_](https://i.imgur.com/HyRHRub.png)

## Features ##
* Open source
* "Build" project, which exports various items and assembles project.asm if it exists.
* Palette editor
* Import CHR banks from .chr, .png, .png (nesmaker).
* Export CHR banks to .png with chosen palette.
* plugin system (Lua/Python)

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

See sample plugins for more information.

### Callbacks ###
## Main Callbacks ##
* init
    called after loading the main program file
* onPluginsLoaded
    called after plugins are loaded, if there are any.
* onReady
    called when the program is in a ready state.  This happens after plugins are loaded, if there are any.

## Plugin Callbacks ###
These are localized to plugins.
* plugin.onInit
    called after a plugin is loaded
* plugin.onLoadProject
    called when a project is loaded
* plugin.onSaveProject
    called when a project is saved
* plugin.onBuild
    called when a project is built
* plugin.onExit
    called when the program is exited


