-- NESBuilder plugin
-- smbthing.lua

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

-- create index
for k,v in ipairs(smbPaletteData) do
    smbPaletteData[v.name]=v
end

-- create functions
for i,item in ipairs(smbPaletteData) do
    plugin['smbPalette'..item.name.."_cmd"] = function(t) smbPaletteCmd(t) end
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
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=buttonWidth, name="smbthingReload",text="Reload"}
    y = y + control.height + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=buttonWidth, name="smbthingImport",text="Import"}
    
    x = x + control.width + pad
    y = pop()
    
    control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="smbthingPalette", palette=nespalette}
    control.helpText = "Click to select a color"
    y = y + control.height + pad*2
    
    
    push(x + control.width+pad * 2)
    
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
        control.helpText = "Click to apply a color, right click to select a color"
        control.data.index=k
        
        y = y + control.height + pad
        
        bottom = math.max(y, bottom)
        
        x=pop()
    end
    pop() -- consume the pop and discard
    
    plugin.selectedColor=0x0f
end

function plugin.onLoadProject()
    data.project.smbPaletteData = data.project.smbPaletteData or {}
    smbthingRefreshPalettes()
end

function plugin.onBuild()
    smbthingExport()
end

function smbthingReload_cmd()
    -- make sure file is loaded
    if not data.project.rom.data then return end

    data.project.smbPaletteData = {}
    smbthingRefreshPalettes()
end

function smbthingImport_cmd()
    local f = NESBuilder:openFile{filetypes={{"NES rom", ".nes"}}}
    if f == "" then
        print("Open cancelled.")
        return
    end
    local fileData = NESBuilder:getFileAsArray(f)
    
    data.project.smbPaletteData = {}
    for _, item in ipairs(smbPaletteData) do
        p={}
        for i=0,item.nColors-1 do
            data.project.smbPaletteData[item.offset + i] = int(fileData[0x10 + item.offset + i])
            table.insert(p, data.project.smbPaletteData[item.offset + i])
        end
    
        c = NESBuilder:getControl('smbPalette'..item.name)
        c.setAll(p)
    end
end

function smbthingExport()
    local out
    
    out = "bank 0\n\n"
    for _, item in ipairs(smbPaletteData) do
        out = out .. string.format("; %s\norg $%04x\n", item.name, 0x8000 + item.offset)
        out = out .. string.format("    db ")
        for i = 0, item.nColors - 1 do
            if i > 0 then
                out = out .. ', '
            end
            out = out .. string.format("$%02x", data.project.smbPaletteData[item.offset + i] or 0)
        end
        out = out .. "\n\n"
    end
    
    filename = data.folders.projects..projectFolder.."code/smbPalettes.asm"
    util.writeToFile(filename,0, out, true)
end

function smbthingRefreshPalettes()
    local c
    
    if not data.project.rom.data then return end
    
    for _, item in ipairs(smbPaletteData) do
        p={}
        for i=0,item.nColors-1 do
            if not data.project.smbPaletteData[item.offset + i] then
                -- Make sure it's not a <class 'numpy.uint8'>
                data.project.smbPaletteData[item.offset + i] = int(data.project.rom.data[0x10 + item.offset + i])
            end
            table.insert(p, data.project.smbPaletteData[item.offset + i])
        end
    
        c = NESBuilder:getControl('smbPalette'..item.name)
        c.setAll(p)
    end
    
end

function smbthingPalette_cmd(t)
    local event = t.cell.event
    if event.button == 1 or event.button == 2 then
        plugin.selectedColor = t.cellNum
    end
end

function smbPaletteCmd(t)
    local event = t.cell.event
    local p, control
    
    -- make sure file is loaded
    if not data.project.rom.data then return end
    
    local paletteData = smbPaletteData[t.control.data.index]
    
    if event.button == 2 then
        -- right click
        plugin.selectedColor = data.project.smbPaletteData[paletteData.offset + t.cellNum]
    elseif event.button == 1 then
        -- left click
        data.project.smbPaletteData[paletteData.offset + t.cellNum] = int(plugin.selectedColor)
        
        smbthingRefreshPalettes()
    end
end

return plugin