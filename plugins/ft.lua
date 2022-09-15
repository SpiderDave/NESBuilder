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
    
    control = NESBuilder:makeLabelQt{x=x, y=y, clear=true, text="Load a FamiTracker txt export file to be converted when building project."}
    control.setFont("Verdana", 10)
    y = y + control.height + pad*2
    
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="ftLoad", text="Load"}
    push(x)
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="ftBuild", text="Build"}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="ftUnload", text="Remove"}
    y = y + control.height + pad
    x = pop()
    control = NESBuilder:makeLabelQt{x=x, y=y, clear=true, name="ftInputFilename", text=""}
    y = y + control.height + pad
    control = NESBuilder:makeLabelQt{x=x, y=y, clear=true, name="ftOutputFilename", text=""}
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
        local famitracker = NESBuilder:importFunction('plugins.ft_txt_to_asm_spiderdave','FT')().main
        
        -- process the file
        famitracker(plugin.data.ftInputFile)
    end
end

function plugin.ftUnload_cmd()
    plugin.data.ftInputFile = nil
    plugin.data.ftOutputFile = nil
    updateLabels()
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
        end
    end
end


function plugin.onSaveProject()
    data.project.ft = {
        inputFile = plugin.data.ftInputFile,
        outputFile = plugin.data.ftOutputFile,
    }
end

function plugin.onLoadProject()
    plugin.data.ftInputFile = nil
    plugin.data.ftOutputFile = nil

    if data.project.ft then
        plugin.data.ftInputFile = data.project.ft.inputFile
        plugin.data.ftOutputFile = data.project.ft.outputFile
    end
    updateLabels()
end


return plugin