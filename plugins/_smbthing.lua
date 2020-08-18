-- NESBuilder plugin
-- smbthing.lua
--
-- To enable this plugin, remove the "_" from the start of the filename.

local plugin = {
    author = "SpiderDave",
}

function plugin.onInit()
    NESBuilder:createTab("smbthing", "SMB Thing")
    NESBuilder:setTab("smbthing")
    
    local stack, push, pop = NESBuilder:newStack()
    local x,y,control,pad
    local top,left
    
    pad=6
    left=pad*1.5
    top=pad*1.5
    x,y=left,top
    
    control = NESBuilder:makeLabel{x=x,y=y,name="testLabel",clear=true,text="SMB Thing!"}
    control.setFont("Verdana", 24)
    y = y + control.height + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="smbthingLoadRom",text="Load rom"}
    y = y + control.height + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="smbthingSaveRom",text="Save rom"}
    y = y + control.height + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="smbthingSaveRomAs",text="Save rom as..."}
    y = y + control.height + pad
    
    control=NESBuilder:makePaletteControl{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="smbthingPalette", palette=nespalette}
    y = y + control.height + pad
    
    local p = {[0]=0x0f,0x0f,0x0f,0x0f}
    
    local palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    
    
    control=NESBuilder:makePaletteControl{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="MarioPalette", palette=palette}
    push(y + control.height + pad)
    
    x=x+100+pad
    control = NESBuilder:makeLabel{x=x,y=y+4,name="MarioPaletteLabel",clear=true,text="Mario's Palette"}
    
    x=left
    y = pop()
    
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="smbthingTest",text="Test rom"}
    y = y + control.height + pad
    
    plugin.selectedColor=0x0f
end

function smbthingTest_cmd()
    local f = plugin.outputFile or plugin.inputFile
    if not f then return end
    local workingFolder = f
    NESBuilder:shellOpen(workingFolder, f)
end

function smbthingLoadRom_cmd()
    local f = NESBuilder:openFile({{"NES rom", ".nes"}})
    if f == "" then
        print("Open cancelled.")
        return
    end
    plugin.fileData = NESBuilder:getFileAsArray(f)
    plugin.inputFile = f
    smbthingRefreshPalettes()
end

function smbthingSaveRom_cmd()
    if not plugin.fileData then return end
    plugin.outputFile = plugin.inputFile
    NESBuilder:saveArrayToFile(plugin.fileData, plugin.inputFile)
end

function smbthingSaveRomAs_cmd()
    if not plugin.fileData then return end
    
    local f = NESBuilder:saveFileAs({{"NES rom", ".nes"}},'output.nes')
    if f == "" then
        print("Save cancelled.")
    else
        print("file: "..f)
        NESBuilder:saveArrayToFile(plugin.fileData, f)
        plugin.outputFile = f
    end
end


function smbthingRefreshPalettes()
    local offset
    
    if not plugin.fileData then return end
    
    offset = 0x10+0x5d7
    
    p={}
    for i=0,3 do
        table.insert(p,plugin.fileData[offset+i])
    end
    
    c = NESBuilder:getControl('MarioPalette')
    c.setAll(p)
end

function smbthingPalette_cmd(t)
    if not t.cellNum then return end -- the frame was clicked.
    if t.event.num == 1 then
        plugin.selectedColor = t.cellNum
    end
end

function MarioPalette_cmd(t)
    local offset
    offset = 0x10+0x5d7
    
    if not t.cellNum then return end -- the frame was clicked.
    if not plugin.fileData then return end
    
    if t.event.num == 1 then
        -- left click
    elseif t.event.num == 3 then
        plugin.fileData[offset+t.cellNum]=plugin.selectedColor
        smbthingRefreshPalettes()
    end

end

return plugin