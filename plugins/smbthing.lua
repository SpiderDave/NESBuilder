-- NESBuilder plugin
-- smbthing.lua

local plugin = {
    author = "SpiderDave",
    default = false,
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

smbData = {
    { category='speed' },
    { offset = 0xb441, text = "Walk/Swim Speed Left", },
    { offset = 0xb444, text = "Walk/Swim Speed Right", },
    { offset = 0xb440, text = "Run Speed Left", },
    { offset = 0xb443, text = "Run Speed Right", },
    { offset = 0xb442, text = "Ocean Walk Speed Left", },
    { offset = 0xb445, text = "Ocean Walk Speed Right", },
    { offset = 0xb446, text = "Auto Walk Speed", },
    { category='jump1' },
    { offset = 0xb432, text = "Jump Power Base (Slow/Stopped)", newCol=true, newSection=True},
    { offset = 0xb433, text = "Jump Power Base (Walking)", },
    { offset = 0xb434, text = "Jump Power Base (Slow Run)", },
    { offset = 0xb435, text = "Jump Power Base (Run)", },
    { offset = 0xb436, text = "Jump Power Base (Fast Run)", },
    
    { offset = 0xb439, text = "Jump Power Correction (Slow/Stopped)", },
    { offset = 0xb43a, text = "Jump Power Correction (Walking)", },
    { offset = 0xb43b, text = "Jump Power Correction (Slow Run)", },
    { offset = 0xb43c, text = "Jump Power Correction (Run)", },
    { offset = 0xb43d, text = "Jump Power Correction (Fast Run)", },
    
    { offset = 0xb424, text = "Jump Power Rise Rate (Slow/Stopped)", newCol=true},
    { offset = 0xb425, text = "Jump Power Rise Rate (Walking)", },
    { offset = 0xb426, text = "Jump Power Rise Rate (Slow Run)", },
    { offset = 0xb427, text = "Jump Power Rise Rate (Run)", },
    { offset = 0xb428, text = "Jump Power Rise Rate (Fast Run)", },
    
    { offset = 0xb42b, text = "Jump Power Fall Rate (Slow/Stopped)", },
    { offset = 0xb42c, text = "Jump Power Fall Rate (Walking)", },
    { offset = 0xb42d, text = "Jump Power Fall Rate (Slow Run)", },
    { offset = 0xb42e, text = "Jump Power Fall Rate (Run)", },
    { offset = 0xb42f, text = "Jump Power Fall Rate (Fast Run)", },
    { category='jump2' },
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
    makeTab{name="smbthing", text="SMB Thing"}
    setTab("smbthing")
    
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
    
    x,y=left,top
    
    local remodellerItems = {'(S.M.B. Remodeller)','Mario Settings','General Settings 1','General Settings 2','Enemy Settings 1','Enemy Settings 2','Enemy Settings 3','Scoring Settings','Color Settings','Palette Settings'}
    control = NESBuilder:makeComboBox{x=x,y=y,w=buttonWidth*1.5,h=buttonHeight*1.1, text="test", name="smbthingRemodeller", itemList = remodellerItems}
    --control.setByText('')
    --y = y + control.height + pad
    x = x + control.width + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, text="tools", name="smbSwitchFrame4", functionName = 'smbthingRemodeller', value='tools'}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, text="palette", name="smbSwitchFrame4", functionName = 'smbthingRemodeller', value='palette'}
    x = x + control.width + pad
--    for i,item in pairs(smbData) do
--        if item.category then
--            control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, text=item.category, name="smbSwitchFrame", functionName = 'smbthingSwitchFrame', value=item.category}
--            x = x + control.width + pad
--        end
--    end
    
    y = y + control.height + pad
    
    x=left
    startY = y
    
    local setFrame = function(self, f)
        for k,v in pairs(self) do
            if k == "set" then
            elseif k == f then
                v.show()
            else
                v.hide()
            end
        end
    end
    
    plugin.remodellerFrames = {
        set = setFrame,
        palette = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="palette"},
        tools = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="smbthingTools"},
    }
    for i,v in ipairs(remodellerItems) do
        plugin.remodellerFrames[v] = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, v}
    end
    
    NESBuilder:setContainer(plugin.remodellerFrames['Mario Settings'])
    x,y = left,top
    
    for i,item in pairs(smbData) do
        if item.category then
            control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, text=item.category, name="smbSwitchFrame", functionName = 'smbthingSwitchFrame', value=item.category}
            x = x + control.width + pad
        end
    end
    x=left
    
    --palette = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="palette"},
    --tools = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="smbthingTools"},
    plugin.frames2 = {
        frame2 = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="frame2"},
        speed = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="speed"},
        jump1 = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="jump1"},
        jump2 = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="jump2"},
        frame6 = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="frame6"},
        set = setFrame,
    }
    
    
    
    
    
--    control = NESBuilder:makeLabelQt{x=x,y=y,name="testLabel",clear=true,text="SMB Thing!"}
--    control.setFont("Verdana", 24)
--    y = y + control.height + pad
    
    NESBuilder:setContainer(plugin.remodellerFrames.palette)
    x,y = left,top
    
    push(y)
    
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, name="smbthingReload",text="Reload"}
    control.helpText = "Load palette from current project rom."
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, name="smbthingImport",text="Import"}
    control.helpText = "Import palette from another file."
    y = y + control.height + pad
    
    x = x + control.width + pad
    y = pop()
    
    
    control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="smbthingPalette", palette=nespalette}
    control.helpText = "Click to select a color"
    y = y + control.height + pad*2
    --y=y2
    
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

    if not devMode() then return end
    
    NESBuilder:setContainer(plugin.frames2.frame2)
    x,y = left,top
    
    --control = NESBuilder:makeScrollFrame{x=x,y=y,w=buttonWidth*5,h=config.height, name="smbScrollFrame"}
    --NESBuilder:setContainer(control)
    
    for i, item in ipairs(smbData) do
        if item.category then
            NESBuilder:setContainer(plugin.frames2[item.category])
            x,y = top,left
        else
            push(x)
            push(y)
            control = NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, text=item.text}
            control.setFont("Verdana", 10)
            x = x + buttonWidth * 1.8 + pad
            y = pop()
            control = NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*4, h=buttonHeight, name = string.format('smbData%d', i), format="decimal"}
            smbData[i].control = control
            x = pop()
            y = y + control.height + pad
        end
    end
    
    NESBuilder:setContainer(plugin.remodellerFrames.tools)
    x,y = left,top
    --control = NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, text='tools'}
    
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, name="smbthingLevelExtract",text="Extract Level"}
    control.helpText = "Extract level from a .nes file."
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, name="smbthingMtiles",text="Generate MTiles"}
    control.helpText = "Generate Metatiles for use in the Metatiles tab."
    y = y + control.height + pad

end

function smbthingRemodeller_cmd(t)
    local control = t.control or t
    
    if control.value == '' then return end
    print(control.value)
    
    plugin.remodellerFrames:set(control.value)
end

function smbthingSwitchFrame_cmd(t)
    plugin.frames2:set(t.value)
end

function plugin.onLoadProject()
    local control
    local offset
    
    data.project.smbPaletteData = data.project.smbPaletteData or {}
    smbthingRefreshPalettes()
    
    
    if not getRomData() then return end
    
    if devMode() then
--        control = NESBuilder:getControl("smbWalkSpeed")
--        offset = 0xB444 - 0x8000 + 0x10
--        control.value = int(data.project.rom.data[offset])
        
        for i, item in ipairs(smbData) do
            if item.offset then
                offset = item.offset - 0x8000 + 0x10
                item.control.value = int(data.project.rom.data[offset])
            end
        end
    end
end

function plugin.onBuild()
    smbthingExport()
end

function plugin.onTemplateInit()
end

function plugin.onTemplateAction(k, v)
    if k == 'initSMB' then
        plugin.smbthingReload_cmd()
        plugin.smbthingMtiles_cmd()
    end
end

function plugin.smbthingReload_cmd()
    -- make sure file is loaded
    if not getRomData() then return end

    data.project.smbPaletteData = {}
    smbthingRefreshPalettes()
end

function smbthingLevelExtract_cmd()
    NESBuilder:setWorkingFolder()
    local f = NESBuilder:openFile{filetypes={{"NES rom", ".nes"}}}
    if f == "" then
        print("Open cancelled.")
        return
    end
    
    NESBuilder:setWorkingFolder()
    local levelExtract = NESBuilder:importFunction('plugins.SMBLevelExtract.SMBLevelExtract','LevelExtract')
    local outputFilename = data.folders.projects..data.project.folder.."code/output.asm"
    levelExtract(f, outputFilename)
    
end

function plugin.smbthingMtiles_cmd()
    local offset = 0x8B10 - 0x8000 + 0x10
    local mTilesPerPalette = {[0]=39,46,10,6}
    local tileNum = 0
    local tileSet = 0
    
    -- wipe all
    data.project.mTileSets = {}
    
    -- Remove entries already named the same
--    for i,v in ipairs_sparse(data.project.mTileSets) do
--        for p = 0,3 do
--            if v.name == string.format("Palette%x_MTiles",p) then
--                data.project.mTileSets[i] = nil
--            end
--        end
--    end
    
    -- Get index to place new items at
    for i,v in ipairs_sparse(data.project.mTileSets) do
        if iLength(v) > 0 then
            tileSet = i + 1
        end
    end
    
    for p = 0,3 do
        data.project.mTileSets[tileSet] = {index=0, name=string.format("Palette%x_MTiles",p), style="grid", map={[0]=0,2,1,3},w=2,h=2, chrIndex = 1, org=0x8b10+tileNum*4}
        
        for m = 0,mTilesPerPalette[p]-1 do
            data.project.mTileSets[tileSet][m] = {}
            for i = 0, 3 do
                data.project.mTileSets[tileSet][m][i] = int(data.project.rom.data[offset + tileNum*4 + i])
            end
            data.project.mTileSets[tileSet][m].palette = p
            tileNum = tileNum + 1
        end
        tileSet = tileSet + 1
    end
    
    offset = 0xe73e - 0x8000 + 0x10
    data.project.mTileSets[tileSet] = {index=0, name="EnemyGraphicsTable", style="grid", map={[0]=0,1,2,3,4,5}, w=2,h=3, chrIndex = 0, org=0xe73e}
    for tileNum = 0,43-1 do
        data.project.mTileSets[tileSet][tileNum] = {}
        for i = 0, 5 do
            data.project.mTileSets[tileSet][tileNum][i] = int(data.project.rom.data[offset + tileNum*6 + i])
        end
        data.project.mTileSets[tileSet][tileNum].palette = 4
    end
    tileSet = tileSet + 1
    
    offset = 0xee17 - 0x8000 + 0x10
    data.project.mTileSets[tileSet] = {index=0, name="PlayerGraphicsTable", style="grid", map={[0]=0,1,2,3,4,5,6,7}, w=2,h=4, chrIndex = 0, org=0xee17}
    for tileNum = 0,26-1 do
        data.project.mTileSets[tileSet][tileNum] = {}
        for i = 0, 7 do
            data.project.mTileSets[tileSet][tileNum][i] = int(data.project.rom.data[offset + tileNum*8 + i])
        end
        data.project.mTileSets[tileSet][tileNum].palette = 4
    end
    tileSet = tileSet + 1
    
    updateMTileList()
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
    
    filename = data.folders.projects..data.project.folder.."code/smbPalettes.asm"
    util.writeToFile(filename,0, out, true)
    
    
    if not devMode() then return end
    
    filename = data.folders.projects..data.project.folder.."code/smbTest.asm"
    out = ""
    
    --control = NESBuilder:getControl("smbWalkSpeed")
    
    out = out .. "bank 0\n"
    
--    offset = 0xB441
--    out = out .. string.format("org $%04x\n", offset)
--    out = out .. string.format("    db $%02x\n", 0x100-control.value)
--    out = out .. "\n"
    
--    offset = 0xB444
--    out = out .. string.format("org $%04x\n", offset)
--    out = out .. string.format("    db $%02x\n", control.value)
--    out = out .. "\n"
    
    for i, item in ipairs(smbData) do
        if item.offset then
            out = out .. string.format("; %s\n", item.text)
            out = out .. string.format("org $%04x\n", item.offset)
            out = out .. string.format("    db $%02x\n", item.control.value)
            out = out .. "\n"
        end
    end
    
    
    util.writeToFile(filename,0, out, true)


end

function smbthingRefreshPalettes()
    local c
    
    if not getRomData() then return end
    
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
    if not getRomData() then return end
    
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