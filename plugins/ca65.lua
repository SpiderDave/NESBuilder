-- NESBuilder plugin
-- ca65.lua
--
-- blah

local plugin = {
    author = "CluckFox",
    name = "ca65",
    _loaded = false,
}

function plugin.onInit()
    NESBuilder:cfgMakeSections( 'ca65' )
    table.insert(data.assemblers, 'ca65')
    print(plugin.name..' plugin initialized')
end

function plugin.onRegisterAssembler()
    local tools = NESBuilder:importFunction('plugins.ca65', 'cc65tools')
    local toolPath = NESBuilder:cfgGetValue('ca65', 'path', '/usr')
    plugin.tools = tools(toolPath)
    plugin._loaded = true
end

function plugin.onAssemble(assembler)
    if assembler == plugin.name then
        if plugin._loaded == true then
            local folder = data.folders.projects..data.project.folder
            local cmd = plugin.tools.forAssemble('project.s', '-g', '-o', 'project.o')
            NESBuilder:run(folder, cmd[0], cmd[1])
            cmd = plugin.tools.forLink('-C', 'project.cfg', 'project.o', '-o', 'project.nes')
            NESBuilder:run(folder, cmd[0], cmd[1])
        end
    end
end

return plugin