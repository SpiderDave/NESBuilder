-- NESBuilder plugin
-- debug.lua
--
-- Plugins starting with "_" are disabled.

local plugin = {
    author = "SpiderDave",
    default = true,
}

function plugin.onInit()
    local items = {
        {name="restart", text="Restart"},
        {name="forceClose", text="Force Close"},
        {name="openMainFolder", text="Open Main Folder"},
        {name="openPluginFolder", text="Open Plugins Folder"},
    }
    control = NESBuilder:makeMenuQt{name="debugMenu", text="Debug", menuItems=items, prefix=true}
end

function debugMenu_restart_cmd()
    NESBuilder:restart()
end

function debugMenu_forceClose_cmd()
    NESBuilder:forceClose()
end

function debugMenu_openMainFolder_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    NESBuilder:shellOpen(workingFolder, "")
end

debugMenu_openProjectFolder_cmd = OpenProjectFolder_cmd

function debugMenu_openPluginFolder_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    NESBuilder:shellOpen(workingFolder, data.folders.plugins)
end

return plugin