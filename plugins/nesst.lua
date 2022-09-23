-- NESBuilder plugin
-- nesst.lua

local plugin = {
    author = "SpiderDave",
    name = "nesst",
    default = false,
}

plugin.splits = {}
--plugin.splits = {0x40, 0x60}

function plugin.onInit()
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
    
    --NESBuilder:setWindow("Main")
    makeTab{name="nesst", text="Screen Tool"}
    NESBuilder:setTabQt("nesst")
    

    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstRefresh",text="Refresh"}
    control.helpText = "Refresh/redraw the nametable."
    push(x, y+control.height+pad)
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, name="nesstLoad",text="Open Session"}
    control.helpText = "Load a .nss file created with Shiru's NES Screen tool."
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstImportFromRom",text="Import from rom data"}
    control.helpText = "Import nametable data from current rom."
--    x = x + control.width + pad
--    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstLoadChr",text="Load CHR"}
    
    y,x=pop(2)
    
    
    push(y)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=32*8,h=30*8,name="nesstCanvas", scale=2, columns=32, rows=30}
    control.helpText = "Click to draw tiles, right-click to select a tile"
    control.setCursor('pencil')
    
    x = x + control.width + pad*2
    y=pop()
    push(left, y+control.height+pad)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=16*8,h=16*8,name="nesstTileset", scale=2, columns=16, rows=16}
    control.helpText = "Click to select a tile"
    
    y = y + control.height + pad
    
    p = {[0]=0x0f,0x0f,0x0f,0x0f}
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    
    plugin.paletteControls = {}
    
    push(x)
    push(x)
    for i=1,4 do
        control=NESBuilder:makeLabelQt{x=x,y=y+3,clear=true,text=(i-1)..":"}
        control.setFont("Verdana", 10)
        x = x + control.width + pad
        control = NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="nesstPalette"..i, palette=palette}
        control.helpText = "Click to select this palette"
        control.data.index = i
        table.insert(plugin.paletteControls, control)
        x = x + control.width + pad * 1.5
        if i==2 then
            x=pop()
            y = y + control.height+pad
        end
    end
    
    plugin.paletteControls.select = function(index, cell)
        for i,control in ipairs(plugin.paletteControls) do
            if i==index then
                --control.highlight(true)
            else
                --control.highlight(false)
            end
        end
    end
    
    x=pop()
    y = y + control.height+pad
    
    control = NESBuilder:makeCheckbox{x=x,y=y,name="nesstApplyTiles", text="Apply tiles", value=true}
    control.helpText = "Apply tiles when drawing/selecting"
    y = y + control.height+pad
    control = NESBuilder:makeCheckbox{x=x,y=y,name="nesstApplyAttr", text="Apply attributes", value=true}
    control.helpText = "Apply attributes when drawing/selecting"
    y = y + control.height+pad
    
    --if devMode() then
    if false then
        push(x)
        control = NESBuilder:makeButton{x=x,y=y,w=6*7.5,h=buttonHeight, name="testHand",text="split"}
        y = y + control.height+pad
        
        control=NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="splitNum", index=i}
        control.helpText = "Split number"
        x = x + control.width + pad
        control=NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="splitY", index=i}
        control.helpText = "Split y position"
        y = y + control.height + pad
        
        x=pop()
    end
    control = NESBuilder:makeComboBox{x=x,y=y,w=300, name="nesstCHRSelect", itemList = {'Use current CHR','Use CHR with index','Use loaded custom CHR', 'Use linked custom CHR'}}
    control.helpText = "Select an option to help determine which CHR to use for the nametable."
    y = y + control.height + pad
    --control = NESBuilder:makeButton{x=x,y=y,w=6*7.5,h=buttonHeight, name="nesstCHRSelectSet",text="set"}
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstCHRSelectSet",text="set"}
    
    y = y + control.height + pad
    
    y, x = pop(2)
    
--    control=NESBuilder:makeLabelQt{x=x,y=y+3,clear=true,text="Status bar"}
--    plugin.status = control
    
    plugin.loadDefault()
end

function nesstApplyTiles_cmd(t)
    plugin.data.applyTiles = t.isChecked()
end

function nesstApplyAttr_cmd(t)
    plugin.data.applyAttr = t.isChecked()
end

function plugin.nesstRefresh_cmd()
    nesstRefreshScreen()
end

function plugin.onCHRRefresh(surface)
    local index = plugin.getSelectedCHRType()
    
    if index == 0 then
        NESBuilder:getControl("nesstTileset").paste(surface)
    else
        nesstRefreshTileset()
    end
end

function nesstCHR(n)
    setChr(n)
    refreshCHR()
end

function plugin.nesstCHR0_cmd(t) nesstCHR(0) end
function plugin.nesstCHR1_cmd(t) nesstCHR(1) end
function plugin.nesstCHRCurrent_cmd(t)
    nesstCHR(data.project.chr.index)
end

function plugin.onTabChanged(t)
    if t.window.name == "Main" then
        local tab = t.tab()
        if tab == "nesst" then
            if not plugin.data.nameTable then
                plugin.loadDefault()
            end
        end
    end
end

function plugin.loadDefault()
    local control,p,d,f,chr
    
    if not currentChr() then return end
    if not getPaletteSet() then return end
    
    p=currentPalette()
    control = NESBuilder:getControlNew("nesstTileset")
    control.loadCHRData{imageData=currentChr(), colors=p,columns=16,rows=16}
    
    control = NESBuilder:getControlNew("nesstCanvas")
    control.clear()
    control.columns = 32
    control.rows = 30
    control.chrData = currentChr()
    
    for i=0,3 do
        plugin.paletteControls[i+1].setAll(data.project.palettes[i])
        plugin.paletteControls[i+1].index = i
    end
    
    local nameTable = {}
    local attrTable = {}
    for i = 1, control.columns*control.rows do
        nameTable[i]=0
    end
    
    for i = 1, 8*8 do
        attrTable[i]=0
    end
    
    plugin.data.nameTable = nameTable
    plugin.data.attrTable = attrTable
    
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            
            tile=plugin.data.nameTable[y*control.columns+x+1]
            attr = attrTable[math.floor(y/4)*8+math.floor(x/4)+1]
            
            n = math.floor(attr/(2^(((math.floor(y/2) % 2)*2 + math.floor(x/2) % 2)*2))) % 4
            
            p = data.project.palettes[n]
            control.drawTile{x*8,y*8, tile=tile, colors=p}
        end
    end
end

function plugin.nesstLoad_cmd()
    local control,p,d,f,chr
    
    f = NESBuilder:openFile{filetypes={{"NES Screen Tool Session", ".nss"}}}
    
    if f == "" then
        print("Open cancelled.")
        return
    end
    
    -- Get Screen Tool data from .nss file
    local getData = NESBuilder:importFunction('plugins.nesst','getData')
    d = getData(f)
    
    -- Load all palettes
    p = NESBuilder:hexStringToList(d.Palette)
    data.project.palettes = {}
    for i=0,15 do
        data.project.palettes[i] = {p[i*4+0],p[i*4+1],p[i*4+2],p[i*4+3]}
    end
    
    -- Apply palettes to this tab's palette controls
    for i=0,3 do
        plugin.paletteControls[i+1].setAll(data.project.palettes[i])
        plugin.paletteControls[i+1].index = i
    end
    data.project.palettes.index = d.VarPalActive
    
    p = currentPalette()
    
    -- Load CHR and set selected bank
    data.project.chr = {[0]=d.CHR[0],d.CHR[1]}
    data.project.chr.index = d.CHRBank
    
    
    
    -- create an off-screen drawing surface
    local surface = NESBuilder:makeNESPixmap(128,128)
    -- load CHR Data to the surface
    surface.loadCHR(currentChr())
    -- apply current palette to it
    surface.applyPalette(currentPalette())
    
    -- paste the surface to the CHR tab and the tileset here
    NESBuilder:getControl("canvasQt").paste(surface)
    NESBuilder:getControl("nesstTileset").paste(surface)
    
    control = NESBuilder:getControlNew("nesstCanvas")
    control.columns = d.VarNameW
    control.rows = d.VarNameH
    
    control.chrData = currentChr()
    
    local tile,p, attr,n
    
    local nameTable = NESBuilder:hexToList(d.NameTable)
    local attrTable = NESBuilder:hexToList(d.AttrTable)
    
    plugin.data.nameTable = nameTable
    plugin.data.attrTable = attrTable
    
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            
            tile=plugin.data.nameTable[y*control.columns+x]
            attr = attrTable[math.floor(y/4)*8+math.floor(x/4)]
            
            n = math.floor(attr/(2^(((math.floor(y/2) % 2)*2 + math.floor(x/2) % 2)*2))) % 4
            
            p = data.project.palettes[n]
            control.drawTile(x*8,y*8, tile, currentChr(), p, 32,32)
        end
    end
    
    PaletteEntryUpdate()
    dataChanged()
end

---function nesstLoadChr_cmd()
function nesstLoadChr()
    local f = NESBuilder:openFile{filetypes={{"All valid types", ".chr", ".png"}, {"CHR", ".chr"}, {"Images", ".png"}}}
    if f == "" then
        print("Open cancelled.")
        return
    else
        print("file: "..f)
    end
    
    plugin.data.customChr = getChrFromFile(f)
    nesstRefreshScreen()
    
    return true
end

function nesstImportFromRom_cmd()
    if (not data.project.rom.filename) and (not data.project.rom.data) then
        NESBuilder:showError("Error", "No rom file or data.")
        return
    end
    
    
    local defaultText = "0x9010" -- default for zombie nation title screen
    local txt = askText('Import nametable from rom data', 'Enter a file offset of nametable data.', defaultText)
    
    -- cancelled
    if not txt then return end
    
    local address = tonumber(txt)
    if not address then return end
    
    if data.project.rom.filename and not data.project.rom.data then
        loadRom(data.project.rom.filename)
        print("loading rom data")
        if not data.project.rom.data then return end
    end
    
    -- we use toList to make sure the elements are regular ints
    -- to avoid issues when converting from np arrays
    local romData = NESBuilder:toList(getRomData())
    plugin.data.nameTable = sliceList(romData, address, address + 0x3c0)
    plugin.data.attrTable = sliceList(romData, address + 0x3c0, address + 0x3c0 + 0x40)
    
    nesstRefreshScreen()
end

function nesstRefreshScreen()
    if plugin.refresh then
        plugin.resetRefresh = true
        return
    end
    
    -- update chr select button
    local control = getControl("nesstCHRSelectSet")
    local index = getControl("nesstCHRSelect").currentIndex()
    if index == 0 then
        control.setText('Set to this CHR')
    elseif index == 1 then
        control.setText('Specify CHR Index')
    elseif index == 2 then
        control.setText('Load CHR from file')
    elseif index == 3 then
        control.setText('Specify external CHR')
    end
    
    
    plugin.refresh = true
    control = NESBuilder:getControlNew("nesstCanvas")
    
    if not plugin.data.nameTable then
        print('setting nametable default')
        plugin.data.nameTable = control.setNameTable()
        plugin.data.attrTable = control.setAttrTable()
    end
    
    control.columns = 32
    control.rows = 30
    
    --control.chrData = currentChr()
    control.chrData = plugin.getSelectedCHR()
    
    local tile,p, attr,n
    
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    
    control.clear()
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            tile = plugin.data.nameTable[y*control.columns+x]
            n = NESBuilder:getAttribute(plugin.data.attrTable, x,y)
            
            if pSet then
                p = pSet.palettes[n+1] or {0x0f, 0x01, 0x11, 0x21}
            else
                p = currentPalette()
            end
            --control.drawTile(x*8,y*8, tile, currentChr(), p, control.columns, control.rows)
            control.drawTile(x*8,y*8, tile, control.chrData, p, control.columns, control.rows)
        end
        --control.update()
        control.repaint()
        NESBuilder:updateApp()
        if plugin.resetRefresh then break end
    end
    
    if plugin.resetRefresh then
        plugin.refresh = false
        plugin.resetRefresh = false
        -- exit out of this refresh and start a new one
        nesstRefreshScreen()
        return
    end
    
    PaletteEntryUpdate()
    plugin.refresh = false
    
--    control.drawLine2(0, 16*8,control.width+1,16*8)
--    control.update()

    -- Fixes an issue where the app stays open if you quit while refreshing.
    -- Need a better solution.
--    local main = NESBuilder:getControlNew('main')
--    if main.closing then NESBuilder:forceClose() end
end

function plugin.getSelectedCHRType()
    local control = getControl("nesstCHRSelect")
    if not control then return plugin.data.chrType or 0 end
    
    local index = control.currentIndex()
    
    return plugin.data.chrType or index
end

function plugin.getSelectedCHR()
    local index = plugin.getSelectedCHRType()
    
    printf("getSelectedCHR %s", index)
    
    if index == 0 then
        -- current CHR
        return currentChr()
    elseif index == 1 then
        -- specific CHR
        return currentChr(plugin.data.chrIndex or 0)
    elseif index == 2 then
        -- custom CHR
        return plugin.data.customChr or currentChr(0)
    end
end

function nesstRefreshTileset()
    if not currentChr() then return end
    if not getPaletteSet() then return end
    
    local p=currentPalette()
    local control = getControl("nesstTileset")
    
    -- create an off-screen drawing surface
    local surface = NESBuilder:makeNESPixmap(128, 128)
    -- load CHR Data to the surface
    surface.loadCHR(plugin.getSelectedCHR())
    -- apply current palette to it
    surface.applyPalette(currentPalette())
    -- paste the surface on our canvas (it will be sized to fit)
    control.paste(surface)
end

function nesstCHRSelect_cmd(t)
    local index = t.control.currentIndex()
    print(index)
    
    if index == 3 then
        notImplemented()
        t.control.setCurrentIndex(plugin.data.chrType)
        return
    end
    
    
    plugin.data.chrType = index
    
    nesstRefreshScreen()
end

function nesstCHRSelectSet_cmd(t)
    local control = getControl("nesstCHRSelect")
    
    local index = plugin.getSelectedCHRType()
    if index == 0 then
        -- current CHR
        
        -- change to specific CHR using current index
        plugin.data.chrIndex = currentChrIndex()
        control.setCurrentIndex(1)
        nesstRefreshScreen()
    elseif index == 1 then
        -- specific CHR
        
        local n = askText("Specify CHR Index", "Please enter a valid CHR index.")
        if (not n) or n=='' then
            print('cancelled')
            return
        end
        
        n = tonumber(n)
        if (not n) or (n<0) or (n>#data.project.chr) then
            print("invalid value.")
            return 
        end
        
        plugin.data.chrIndex = n
        
        nesstRefreshScreen()
    elseif index == 2 then
        -- custom CHR
        nesstLoadChr()
    end
end

function plugin.testHand_cmd(t)
    local control = NESBuilder:getControlNew("nesstCanvas")
    
    plugin.data.tool = "split"
    control.setCursor('SplitVCursor')
end

function plugin.nesstTileset_cmd(t)
    local event = t.control.event
    local x = event.x // t.scale
    local y = event.y // t.scale
    local mtileX = x // 8
    local mtileY = y // 8
    local mtileNum = mtileY*16+mtileX
    
    if event and event.type == "ButtonPress" then
        local control = NESBuilder:getControlNew("nesstCanvas")
        plugin.data.tool = "draw"
        control.setCursor('pencil')
        --control.setCursor("pencil")
        plugin.data.selectedTile = mtileNum
        printl('Tile ', mtileNum)
    end
end

function plugin.nesstCanvas_cmd(t)
    local event = t.control.event
    if not plugin.data.nameTable then
        local control = NESBuilder:getControlNew("nesstCanvas")
        plugin.data.nameTable = control.setNameTable()
        plugin.data.attrTable = control.setAttrTable()
        return
    end
    local tile
    local x = event.x // t.scale
    local y = event.y // t.scale
    x,y=math.max(x,0),math.max(y,0)
    x,y=math.min(x,t.columns*8-1),math.min(y,t.rows*8-1)
    
    local tileX = x // 8
    local tileY = y // 8
    local attrX = tileX // 2
    local attrY = tileY // 2
    local attrIndex = tileY // 4 * 8 + tileX // 4
    
    local tileNum = tileY*t.columns+tileX
    
    if plugin.data.tool == "split" then
        if event.button == 1 then
            nesstRefreshScreen()
            local control = NESBuilder:getControlNew("nesstCanvas")
            
            control.drawLine2(0, y,control.width+1,y)
            control.repaint()
            
            
            
--            control.horizontalLine(y)
--            print(y)
--            control.repaint()

            local value = math.floor(NESBuilder:getControl("splitNum").value)
            NESBuilder:getControl("splitY").value = y
            
            plugin.splits[value+1] = y
        elseif event.button==2 and event.type == "ButtonPress" then
            local value = math.floor(NESBuilder:getControl("splitNum").value)
            NESBuilder:getControl("splitY").value = 0
            
            table.remove(plugin.splits, value+1)
        end
    end
    
    if (plugin.data.tool or "draw") == "draw" then
        if event.button == 1 then
            local c = NESBuilder:getAttribute(plugin.data.attrTable, tileX, tileY)
            if plugin.data.applyTiles then
                plugin.data.nameTable[tileNum] = plugin.data.selectedTile or 0
            end
            if plugin.data.applyAttr then
                NESBuilder:setAttribute(plugin.data.attrTable, tileX, tileY, getPaletteSet().index)
            end
            
            control = NESBuilder:getControlNew("nesstCanvas")
            
            for x=0,1 do
                for y=0,1 do
                    tile = plugin.data.nameTable[(attrY*2+y)*t.columns+(attrX*2+x)]
                    --control.drawTile((attrX*2+x)*8,(attrY*2+y)*8, tile, currentChr(), currentPalette(c), 32,32)
                    control.drawTile((attrX*2+x)*8,(attrY*2+y)*8, tile, plugin.getSelectedCHR(), currentPalette(c), 32,32)
                end
            end
            control.repaint()
        end
        
        if event.button == 2 then
            if plugin.data.applyTiles then
                plugin.data.selectedTile = plugin.data.nameTable[tileNum]
                printl("selected tile:", plugin.data.selectedTile)
                --print(bin(plugin.data.attrTable[attrY*4+attrX]))
            end
            if plugin.data.applyAttr then
                local c = NESBuilder:getAttribute(plugin.data.attrTable, tileX, tileY)
                
                if data.project.paletteSets[data.project.paletteSets.index+1].index ~=c then
                    data.project.paletteSets[data.project.paletteSets.index+1].index = c
                    
                    --plugin.paletteControls.select(data.project.palettes.index+1)
                    PaletteEntryUpdate()
                end
                printl("selected palette:", c)
            end
        end
    end
end

--function getAttr(tileX, tileY, attrTable)
--end

function plugin.nesstPalette1_cmd(t) plugin.nesstPalette_cmd(t, t.control.data.index-1) end
function plugin.nesstPalette2_cmd(t) plugin.nesstPalette_cmd(t, t.control.data.index-1) end
function plugin.nesstPalette3_cmd(t) plugin.nesstPalette_cmd(t, t.control.data.index-1) end
function plugin.nesstPalette4_cmd(t) plugin.nesstPalette_cmd(t, t.control.data.index-1) end

function plugin.onPaletteChange()
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    for i=0,3 do
        --plugin.paletteControls[i+1].setAll(data.project.palettes[i])
        plugin.paletteControls[i+1].setAll(pSet.palettes[i+1])
        plugin.paletteControls[i+1].index = i
    end
end

function plugin.nesstPalette_cmd(t, index)
    if not data.project.chr then return end
    
    plugin.paletteControls.select(index+1, t.cellNum)
    
    data.project.paletteSets[data.project.paletteSets.index+1].index = index
    
    --data.project.palettes.index = index
    
    PaletteEntryUpdate()
end

-- is this used?
function plugin.updateTileset()
    local p = data.project.palettes[data.project.palettes.index]
    local control = NESBuilder:getControlNew("nesstTileset")
    control.loadCHRData{imageData=data.project.chr[data.project.chr.index], colors=p,columns=16,rows=16}
end

function plugin.onBuild()
    local out, control, filename
    out = ""
    
    if not plugin.data.nameTable then return end
    
    local filename = data.folders.projects..projectFolder.."code/nametable.asm"
    local nameTable = NESBuilder:listToTable(plugin.data.nameTable)
    local attrTable = NESBuilder:listToTable(plugin.data.attrTable)
    
    control = NESBuilder:getControlNew("nesstCanvas")
    
    out=out.. "nametable_data:\n"
    for i,v in ipairs(nameTable) do
        if (i-1) % 16 == 0 then
            out=out.."    .db "
        end
        
        out=out..string.format("$%02x",v or "????")
        if (i-1) % 16 == 15 then
            out=out.."\n"
        else
            out=out..", "
        end
    end
    
    out=out.. "; attribute data\n"
    for i,v in ipairs(attrTable) do
        if (i-1) % 16 == 0 then
            out=out.."    .db "
        end
        out=out..string.format("$%02x",v or "????")
        if (i-1) % 16 == 15 then
            out=out.."\n"
        else
            out=out..", "
        end
    end
    
    out=out..string.format("; NT length = %s\n; AT length = %s\n",#nameTable, #attrTable)
    
    print("File created "..filename)
    util.writeToFile(filename,0, out, true)
    
    if (plugin.getSelectedCHRType() == 2) and plugin.data.customChr then
        filename = data.folders.projects..data.project.folder.."chr/custom.chr"
        NESBuilder:saveArrayToFile(filename, plugin.data.customChr)
    end
end

function plugin.onAutoSave()
    print('auto save.')
end

function plugin.onSaveProject()
    data.project.screenTool = {
        nameTable = NESBuilder:listToTable(plugin.data.nameTable),
        attrTable = NESBuilder:listToTable(plugin.data.attrTable),
        selectedTile = plugin.data.selectedTile,
        applyTiles = plugin.data.applyTiles,
        applyAttr = plugin.data.applyAttr,
        customChr = plugin.data.customChr,
        chrIndex = plugin.data.chrIndex,
        chrType = plugin.data.chrType,
    }
end

function plugin.onLoadProject()
    plugin.data.nameTable = nil
    plugin.data.attrTable = nil
    plugin.data.selectedTile = 0
    plugin.data.applyTiles = true
    plugin.data.applyAttr = true
    plugin.data.customChr = nil
    plugin.data.chrIndex = nil
    plugin.data.chrType = 0
    control = NESBuilder:getControlNew("nesstCanvas")
    control.clear()

    if data.project.screenTool then
        plugin.data.nameTable = NESBuilder:tableToList(data.project.screenTool.nameTable,0)
        plugin.data.attrTable = NESBuilder:tableToList(data.project.screenTool.attrTable,0)
        plugin.data.selectedTile = data.project.screenTool.selectedTile
        plugin.data.applyTiles = data.project.screenTool.applyTiles
        plugin.data.applyAttr = data.project.screenTool.applyAttr
        plugin.data.customChr = data.project.screenTool.customChr
        plugin.data.chrIndex = data.project.screenTool.chrIndex
        plugin.data.chrType = data.project.screenTool.chrType or 0
    end
    
    
    getControl("nesstCHRSelect").setCurrentIndex(plugin.getSelectedCHRType())
    
    
    getControl('nesstApplyTiles').setChecked(bool(plugin.data.applyTiles))
    getControl('nesstApplyAttr').setChecked(bool(plugin.data.applyAttr))
end

function plugin.onTabChanged(t)
--    if t.name == 'nesst' then
--        nesstRefreshScreen()
--    end
end

function plugin.onShow()
    nesstRefreshScreen()
end

return plugin