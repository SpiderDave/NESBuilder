# NES Builder
NES Building Software made with Python and Lua

!(https://i.imgur.com/HyRHRub.png)

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
Plugins are lua scripts.
Create a "plugins" folder in the main folder and create a file there with 
.lua extension.  Files starting with "_" will be ignored.

Example plugin:

myPlugin.lua
```lua
local plugin = {}

-- This plugin can be accessed from plugins.foobar
-- the plugin name defaults to the filename without extension if not defined.
plugin.name = "foobar"

-- This will be executed after the plugin has been loaded.
function plugin.onInit()
    print("hello plugin world!")
end

-- The plugin needs to return a table or it will be ignored.
return plugin
```

### Callbacks ###
* onInit
* onLoadProject
* onSaveProject
* onBuild
* onExit
