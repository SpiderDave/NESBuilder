-- NESBuilder plugin
-- ca65.lua

local plugin = {
    author = "CluckFox",
    name = "ca65",
    _loaded = false,
    default = true,
}

function plugin.onInit()
    NESBuilder:cfgMakeSections( 'ca65' )
    print(plugin.name..' plugin initialized')
end

function plugin.onRegisterAssembler()
    local tools = NESBuilder:importFunction('plugins.ca65', 'cc65tools')
    
    NESBuilder:cfgSetDefault('ca65','path', '/usr')
    plugin.tools = tools(cfgGet('ca65','path'))
    
    if NESBuilder:fileExists(cfgGet('ca65','path')..'/bin/ca65.exe') then
        table.insert(data.assemblers, 'ca65')
        plugin._loaded = true
    end
end

function plugin.onAssemble(assembler)
    if assembler == plugin.name then
        if plugin._loaded == true then
            local folder = data.folders.projects..data.project.folder
            local cmd = plugin.tools.forAssemble('project.s', '-g', '-o', 'project.o')
            NESBuilder:run(folder, cmd[0], cmd[1])
            cmd = plugin.tools.forLink('-C', 'project.cfg', 'project.o', '-o', data.project.binaryFilename)
            NESBuilder:run(folder, cmd[0], cmd[1])
        end
    end
end

return plugin