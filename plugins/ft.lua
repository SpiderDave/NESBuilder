-- NESBuilder plugin
-- ft.lua

local plugin = {
    author = "SpiderDave",
    default = false,
}

function plugin.onInit()
    makeTab{name="famitracker", text="FamiTracker"}
    setTab("famitracker")
    
    local x,y,control,pad
    
    pad=6
    x=pad*1.5
    y=pad*1.5
    
    y=y+pad
    
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="ftLoad", text="Load"}
    control.helpText = "Load a .txt file exported from FamiTracker"
    push(x)
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="ftBuild", text="Build"}
    control.helpText = "Build .asm from the FamiTracker .txt export."
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="ftUnload", text="Remove"}
    control.helpText = "Remove FamiTracker .txt file."
    y = y + control.height + pad
    x = pop()
    control = NESBuilder:makeLabelQt{x=x, y=y, clear=true, name="ftInputFilename", text=""}
    y = y + control.height + pad
    control = NESBuilder:makeLabelQt{x=x, y=y, clear=true, name="ftOutputFilename", text=""}
    y = y + control.height + pad
    control = NESBuilder:makeTextEdit{x=x,y=y,w=700,h=600,name="ftInfo"}
    
end

function plugin.onBuild()
    plugin.ftBuild_cmd()
end

local function updateLabels()
    getControl('ftInputFilename').setText(plugin.data.ftInputFile or "")
    getControl('ftOutputFilename').setText(plugin.data.ftOutputFile or "")
end

function plugin.ftBuild_cmd()
    if plugin.data.ftInputFile and plugin.data.ftOutputFile then
        print("converting ft txt export:")
        printf("    %s --> %s", plugin.data.ftInputFile, plugin.data.ftOutputFile)
        
        setProjectFolder()
        
        -- import the class, instantiate it, and select the "main" method to assign to our variable
        local famitracker = NESBuilder:importFunction('plugins.ft_txt_to_asm_spiderdave','FT')()
        
        -- process the file
        famitracker.main(plugin.data.ftInputFile)
        
        
        local c=getControl('ftInfo')
        c.clear()
        c.print = function(txt) c.appendPlainText((txt or '')) end
        
        c.print("input file: " .. plugin.data.ftInputFile)
        c.print()
        
        for k,v in pairs({'Title', 'Author', 'Copyright'}) do
            local v2 = v
            v = string.lower(v)
            if famitracker[v] and NESBuilder:getLen(famitracker[v]) > 0 then c.print(string.format("%s: %s", v2, famitracker[v])) end
        end
        
        c.print()
        
        if NESBuilder:getLen(famitracker.comment) > 0 then
            c.print('--------------------')
            for item in python.iter(famitracker.comment) do
                c.print(item)
            end
            c.print('--------------------')
        end
        
        c.print()
        
        c.print("Song tracks:")
        for i,track in python.enumerate(famitracker.song_tracks) do
            c.print(string.format("%2d. %s", track.index, track.displayName))
        end
        c.print()
        c.print("Sfx tracks:")
        for i,track in python.enumerate(famitracker.sfx_tracks) do
            c.print(string.format("%2d. %s", track.index, track.displayName))
        end
        
    end
end

function plugin.ftUnload_cmd()
    if (not plugin.data.ftInputFile) and (not plugin.data.ftOutputFile) then
        return
    end
    
    getControl('ftInfo').clear()
    
    plugin.data.ftInputFile = nil
    plugin.data.ftOutputFile = nil
    updateLabels()
    dataChanged()
end

function plugin.ftLoad_cmd()
    local f, f2
    
    local folder = setProjectFolder()

    local f = NESBuilder:openFile{filetypes={{"FamiTracker text export (.txt)", ".txt"}}, initial=folder}
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        local outputFile = rsplit(f, '.txt')[0] .. ".asm"
        
        f2 = outputFile
        --f2 = NESBuilder:saveFileAs{filetypes={{"ASM", ".asm"}}, initial=outputFile}
        if f2 == "" then
            print("Save cancelled.")
        else
            print("file: "..f2)
            
            -- make folders relative and cannonical
            local f0 = fixPath(folder)
            f = split(fixPath(f), f0)[1]
            f2 = split(fixPath(f2), f0)[1]
            
            plugin.data.ftInputFile = f
            plugin.data.ftOutputFile = f2
            updateLabels()
            dataChanged()
        end
    end
end


function plugin.onSaveProject()
    data.project.ft = {
        inputFile = plugin.data.ftInputFile,
        outputFile = plugin.data.ftOutputFile,
        infoCache = getControl('ftInfo').text,
    }
end

function plugin.onLoadProject()
    plugin.data.ftInputFile = nil
    plugin.data.ftOutputFile = nil

    getControl('ftInfo').clear()
    
    if data.project.ft then
        plugin.data.ftInputFile = data.project.ft.inputFile
        plugin.data.ftOutputFile = data.project.ft.outputFile
        getControl('ftInfo').setText(data.project.ft.infoCache or "")
    end
    
    updateLabels()
end


return plugin