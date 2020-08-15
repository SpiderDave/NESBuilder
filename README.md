# NES Builder
NES Building Software made with Python and Lua

![_](https://i.imgur.com/HyRHRub.png)

## Building ##
Currently there is no binary release, but you can build your own.
The resulting single file exe is rather large (~30MB) so binary 
releases won't be frequent, and wont happen until the program 
changes a bit less rapidly.

Requirements:
* Windows
* Python 3

Python packages:
You can use "install dependencies.bat" to install these.
* lupa
* pyinstaller
* pillow


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
