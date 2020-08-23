-- NESBuilder plugin
-- smbthing.lua
--
-- To enable this plugin, remove the "_" from the start of the filename.

local plugin = {
    author = "SpiderDave",
}

local smbPaletteData = {
    {name = 'Mario', offset = 0x5d7, nColors = 4},
    {name = 'Ground1', offset = 0xccb, nColors = 4},
    {name = 'Ground2', offset = 0xccf, nColors = 4},
    {name = 'Ground3', offset = 0xcd3, nColors = 4},
    {name = 'Ground4', offset = 0xcd7, nColors = 4},
    {name = 'Ground5', offset = 0xcdb, nColors = 4},
    {name = 'Ground6', offset = 0xcdf, nColors = 4},
    {name = 'Ground7', offset = 0xce3, nColors = 4},
    {name = 'Ground8', offset = 0xce7, nColors = 4},
    {name = 'Rotate', offset = 0x9c3, nColors = 6},
}

for k,v in ipairs(smbPaletteData) do
    smbPaletteData[v.name]=v
end

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
    
    x=left
    for k,item in ipairs(smbPaletteData) do
        push(x)
        push(y)
        control = NESBuilder:makeLabel{x=x,y=y+4,name="smbPalette"..item.name.."Label",clear=true,text=item.name}
        x=x+100+pad
        
        local palette = {}
        for i=0,item.nColors-1 do
            palette[i] = nespalette[0x0f]
        end
        
        y = pop()
        control=NESBuilder:makePaletteControl{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="smbPalette"..item.name, palette=palette}
        control.dataIndex = k
        
        y = y + control.height + pad
        
        
        x=pop()
        
    end
    
    control = NESBuilder:makeCheckbox{x=x,y=y,name="smbRotateMod", text="Palette Rotation Mod"}
    y = y + control.height + pad
    
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
    
    if NESBuilder:getControl('smbRotateMod').get() == 1 then
--        plugin.fileData[0x10+0x9e1]=0x60 -- disable palette rotation
--        plugin.fileData[0x10+0x9e1]=0xa5 -- enable palette rotation
        
        -- replace the last two entries in "BlankPalette" with the last two from Ground4
        plugin.fileData[0x10+0x9ce]= plugin.fileData[0x10 + smbPaletteData.Ground4.offset+2]
        plugin.fileData[0x10+0x9cf]= plugin.fileData[0x10 + smbPaletteData.Ground4.offset+3]
        
        -- Modify a counter so the last two colors of area type aren't used for palette 3
        -- It will instead fall back to the entries in BlankPalette above.
        plugin.fileData[0x10+0x9ff]=0x01
    else
        plugin.fileData[0x10+0x9ce]= 0xff
        plugin.fileData[0x10+0x9cf]= 0xff
        plugin.fileData[0x10+0x9ff]= 0x03
    end
    
    
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
    
    for _, item in ipairs(smbPaletteData) do
        offset = 0x10+item.offset
    
        p={}
        for i=0,item.nColors-1 do
            table.insert(p,plugin.fileData[offset+i])
        end
    
        c = NESBuilder:getControl('smbPalette'..item.name)
        c.setAll(p)
    end
    
end

function smbthingPalette_cmd(t)
    if not t.cellNum then return end -- the frame was clicked.
    if t.event.button == 1 then
        plugin.selectedColor = t.cellNum
    end
end

function smbPaletteMario_cmd(t)
    smbPaletteCmd(t)
end
function smbPaletteGround1_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround2_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround3_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround4_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround5_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround6_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround7_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround8_cmd(t) smbPaletteCmd(t) end
function smbPaletteRotate_cmd(t) smbPaletteCmd(t) end

function smbPaletteCmd(t)
    local offset
    local p, control
    
    if not t.cellNum then return end -- the frame was clicked.
    -- make sure file is loaded
    if not plugin.fileData then return end
    
    local paletteData = smbPaletteData[t.dataIndex]
    
    offset = 0x10+paletteData.offset
    
    if not t.cellNum then return end -- the frame was clicked.
    if not plugin.fileData then return end
    
    if t.event.button == 1 then
        -- left click
        plugin.selectedColor = plugin.fileData[offset+t.cellNum]
    elseif t.event.button == 3 then
        plugin.fileData[offset+t.cellNum]=plugin.selectedColor
        
        smbthingRefreshPalettes()
    end
end



return plugin