-- NESBuilder plugin
-- smbthing.lua
--
-- To enable this plugin, remove the "_" from the start of the filename.

local plugin = {
    author = "SpiderDave",
}

local smbPaletteData = {
    {name = 'Ground1', offset = 0xccb, nColors = 4},
    {name = 'Ground2', offset = 0xccf, nColors = 4},
    {name = 'Ground3', offset = 0xcd3, nColors = 4},
    {name = 'Ground4', offset = 0xcd7, nColors = 4},
    {name = 'Ground5', offset = 0xcdb, nColors = 4},
    {name = 'Ground6', offset = 0xcdf, nColors = 4},
    {name = 'Ground7', offset = 0xce3, nColors = 4},
    {name = 'Ground8', offset = 0xce7, nColors = 4},
    
    {name = 'Water1', offset = 0xca7, nColors = 4, newCol=true},
    {name = 'Water2', offset = 0xcab, nColors = 4},
    {name = 'Water3', offset = 0xcaf, nColors = 4},
    {name = 'Water4', offset = 0xcb3, nColors = 4},
    {name = 'Water5', offset = 0xcb7, nColors = 4},
    {name = 'Water6', offset = 0xcbb, nColors = 4},
    {name = 'Water7', offset = 0xcbf, nColors = 4},
    {name = 'Water8', offset = 0xcc3, nColors = 4},

    {name = 'Underground1', offset = 0xcef, nColors = 4, newCol=true},
    {name = 'Underground2', offset = 0xcf3, nColors = 4},
    {name = 'Underground3', offset = 0xcf7, nColors = 4},
    {name = 'Underground4', offset = 0xcfb, nColors = 4},
    {name = 'Underground5', offset = 0xcff, nColors = 4},
    {name = 'Underground6', offset = 0xd03, nColors = 4},
    {name = 'Underground7', offset = 0xd07, nColors = 4},
    {name = 'Underground8', offset = 0xd0b, nColors = 4},

    {name = 'Castle1', offset = 0xd13, nColors = 4, newCol=true},
    {name = 'Castle2', offset = 0xd17, nColors = 4},
    {name = 'Castle3', offset = 0xd1b, nColors = 4},
    {name = 'Castle4', offset = 0xd1f, nColors = 4},
    {name = 'Castle5', offset = 0xd23, nColors = 4},
    {name = 'Castle6', offset = 0xd27, nColors = 4},
    {name = 'Castle7', offset = 0xd2b, nColors = 4},
    {name = 'Castle8', offset = 0xd2f, nColors = 4},

    {name = 'Background1', offset = 0x5cf, nColors = 4, newSection=true},
    {name = 'Background2', offset = 0x5d3, nColors = 4},
    {name = 'Mario', offset = 0x5d7, nColors = 4},
    {name = 'Luigi', offset = 0x5db, nColors = 4},
    {name = 'Fire', offset = 0x5df, nColors = 4},
    
    {name = 'Rotate', offset = 0x9c3, nColors = 6, newCol=true},
    {name = 'Palette3Data1', offset = 0x9d1, nColors = 4},
    {name = 'Palette3Data2', offset = 0x9d5, nColors = 4},
    {name = 'Palette3Data3', offset = 0x9d9, nColors = 4},
    {name = 'Palette3Data4', offset = 0x9dd, nColors = 4},
    

}

for k,v in ipairs(smbPaletteData) do
    smbPaletteData[v.name]=v
end

function plugin.onInit()
    NESBuilder:makeTabQt{name="smbthing", text="SMB Thing"}
    NESBuilder:setTabQt("smbthing")
    
    local stack, push, pop = NESBuilder:newStack()
    local x,y,control,pad
    local top,left,bottom
    local buttonWidth = config.buttonWidth*7.5
    local buttonHeight = 27
    
    pad=6
    left=pad*1.5
    top=pad*1.5
    bottom=0
    x,y=left,top
    
    control = NESBuilder:makeLabelQt{x=x,y=y,name="testLabel",clear=true,text="SMB Thing!"}
    control.setFont("Verdana", 24)
    y = y + control.height + pad
    
    push(y)
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=buttonWidth, name="smbthingLoadRom",text="Load rom"}
    y = y + control.height + pad
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=buttonWidth, name="smbthingSaveRom",text="Save rom"}
    y = y + control.height + pad
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=buttonWidth, name="smbthingSaveRomAs",text="Save rom as..."}
    y = y + control.height + pad
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=buttonWidth, name="smbthingTest",text="Test rom"}
    y = y + control.height + pad
    
    push(x + control.width+pad*2)
    
    local p = {[0]=0x0f,0x0f,0x0f,0x0f}
    
    local palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    
    x=left
    
    push(y) -- This is here since the loop may start with a pop
    for k,item in ipairs(smbPaletteData) do
        if item.newCol or item.newSection then
            x=x+200
            y=pop()
            
            if item.newSection then
                x=left
                y= bottom+pad*2
            end
            
            push(y)
        end

        push(x)
        push(y)
        control = NESBuilder:makeLabelQt{x=x,y=y+4,name="smbPalette"..item.name.."Label",clear=true,text=item.name}
        x=x+80+pad
        
        local palette = {}
        for i=0,item.nColors-1 do
            palette[i] = nespalette[0x0f]
        end
        
        y = pop()
        control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="smbPalette"..item.name, palette=palette}
        control.data.index=k
        
        y = y + control.height + pad
        
        bottom = math.max(y, bottom)
        
        x=pop()
    end
    pop() -- consume the pop and discard
    
    x,y = pop(2)
    
    control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="smbthingPalette", palette=nespalette}
    y = y + control.height + pad*2
    
    plugin.selectedColor=0x0f
end

function smbthingTest_cmd()
--    local f = plugin.outputFile or plugin.inputFile
--    if not f then return end
--    local workingFolder = f
--    NESBuilder:shellOpen(workingFolder, f)
    
    local f = "temp.nes"
    local workingFolder = f
    --local workingFolder = NESBuilder:getWorkingFolder()
    NESBuilder:saveArrayToFile(plugin.fileData, f)
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
    plugin.outputFile = plugin.inputFile
    
    smbthingRefreshPalettes()
end

function smbthingSaveRom_cmd()
    if not plugin.fileData then return end
    plugin.outputFile = plugin.inputFile
    
--    if NESBuilder:getControl('smbRotateMod').get() == 1 then
        -- replace the last two entries in "BlankPalette" with the last two from Ground4
--        plugin.fileData[0x10+0x9ce]= plugin.fileData[0x10 + smbPaletteData.Ground4.offset+2]
--        plugin.fileData[0x10+0x9cf]= plugin.fileData[0x10 + smbPaletteData.Ground4.offset+3]
        
        -- Modify a counter so the last two colors of area type aren't used for palette 3
        -- It will instead fall back to the entries in BlankPalette above.
--        plugin.fileData[0x10+0x9ff]=0x01
--    else
--        plugin.fileData[0x10+0x9ce]= 0xff
--        plugin.fileData[0x10+0x9cf]= 0xff
--        plugin.fileData[0x10+0x9ff]= 0x03
--    end
    
    
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
        plugin.inputFile = plugin.outputFile
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

function smbPaletteMario_cmd(t) smbPaletteCmd(t) end
function smbPaletteLuigi_cmd(t) smbPaletteCmd(t) end
function smbPaletteFire_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater1_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater2_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater3_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater4_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater5_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater6_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater7_cmd(t) smbPaletteCmd(t) end
function smbPaletteWater8_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround1_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround2_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround3_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround4_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround5_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround6_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround7_cmd(t) smbPaletteCmd(t) end
function smbPaletteGround8_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle1_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle2_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle3_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle4_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle5_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle6_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle7_cmd(t) smbPaletteCmd(t) end
function smbPaletteCastle8_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground1_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground2_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground3_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground4_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground5_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground6_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground7_cmd(t) smbPaletteCmd(t) end
function smbPaletteUnderground8_cmd(t) smbPaletteCmd(t) end

function smbPaletteRotate_cmd(t) smbPaletteCmd(t) end

function smbPalettePalette3Data1_cmd(t) smbPaletteCmd(t) end
function smbPalettePalette3Data2_cmd(t) smbPaletteCmd(t) end
function smbPalettePalette3Data3_cmd(t) smbPaletteCmd(t) end
function smbPalettePalette3Data4_cmd(t) smbPaletteCmd(t) end

function smbPaletteBackground1_cmd(t) smbPaletteCmd(t) end
function smbPaletteBackground2_cmd(t) smbPaletteCmd(t) end

function smbPaletteCmd(t)
    local offset
    local p, control
    
    if not t.cellNum then return end -- the frame was clicked.
    -- make sure file is loaded
    if not plugin.fileData then return end
    
    local paletteData = smbPaletteData[t.control.data.index]
    
    offset = 0x10+paletteData.offset
    
    if not t.cellNum then return end -- the frame was clicked.
    if not plugin.fileData then return end
    
    if t.event.button == 1 then
        -- left click
        plugin.selectedColor = plugin.fileData[offset+t.cellNum]
    elseif t.event.button == 2 then
        plugin.fileData[offset+t.cellNum]=plugin.selectedColor
        
        smbthingRefreshPalettes()
    end
end

return plugin