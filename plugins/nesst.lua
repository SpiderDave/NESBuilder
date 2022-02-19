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
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth*7.5, name="nesstLoad",text="Open Session"}
    control.helpText = "Load a .nss file created with Shiru's NES Screen tool."
    push(x, y+control.height+pad)
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="testRefresh",text="refresh"}
    y,x=pop(2)
    
    
    push(y)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=32*8,h=30*8,name="nesstCanvas", scale=2, columns=32, rows=30}
    control.helpText = "Click to draw tiles, right-click to select a tile"
    
    x = x + control.width + pad*2
    y=pop()
    push(left, y+control.height+pad)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=16*8,h=16*8,name="nesstTileset", scale=2, columns=16, rows=16}
    control.helpText = "Click to select a tile"
    
    y = y + control.height + pad
    
    push(x)
    control=NESBuilder:makeLabelQt{x=x,y=y+3,clear=true,text="Pattern table"}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=30,h=buttonHeight, name="nesstCHR0",text="A", toggle=1, toggleSet = "chrAB"}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=30,h=buttonHeight, name="nesstCHR1",text="B", toggle=1, toggleSet = "chrAB"}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=30,h=buttonHeight, name="nesstCHRCurrent",text="*"}
    --control.setValue(1)
    y = y + control.height + pad
    x=pop()
    
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
    
--    push(x)
--    control = NESBuilder:makeButton{x=x,y=y,w=6*7.5,h=buttonHeight, name="testHand",text="split"}
--    y = y + control.height+pad
    
--    control=NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="splitNum", index=i}
--    x = x + control.width+pad
--    control=NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="splitY", index=i}
    
--    x=pop()
    
--    y = y + control.height+pad
    
    y,x = pop(2)
    
--    control=NESBuilder:makeLabelQt{x=x,y=y+3,clear=true,text="Status bar"}
--    plugin.status = control
    
    plugin.loadDefault()
end

function plugin.testRefresh_cmd()
    nesstRefreshScreen()
end

function plugin.onCHRRefresh(surface)
    NESBuilder:getControl("nesstTileset").paste(surface)
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

function nesstRefreshScreen()
    if plugin.refresh then
        plugin.resetRefresh = true
        return
    end
    
    plugin.refresh = true
    local control = NESBuilder:getControlNew("nesstCanvas")
    
    if not plugin.data.nameTable then
        print('setting nametable default')
        plugin.data.nameTable = control.setNameTable()
        plugin.data.attrTable = control.setAttrTable()
    end
    
    control.columns = 32
    control.rows = 30
    
    control.chrData = currentChr()
    
    local tile,p, attr,n
    
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            tile = plugin.data.nameTable[y*control.columns+x]
            n = NESBuilder:getAttribute(plugin.data.attrTable, x,y)
            
            --p = data.project.palettes[n]
            p = pSet.palettes[n+1] or {0x0f, 0x01, 0x11, 0x21}
            control.drawTile(x*8,y*8, tile, currentChr(), p, control.columns, control.rows)
        end
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


    -- Fixes an issue where the app stays open if you quit while refreshing.
    -- Need a better solution.
--    local main = NESBuilder:getControlNew('main')
--    if main.closing then NESBuilder:forceClose() end
end


function plugin.testHand_cmd(t)
    local control = NESBuilder:getControlNew("nesstCanvas")
    
    plugin.data.tool = "split"
    control.setCursor('SplitVCursor')
end

function plugin.nesstTileset_cmd(t)
    local event = t.control.event
    local x = math.floor(event.x/t.scale)
    local y = math.floor(event.y/t.scale)
    local mtileX = math.floor(x/8)
    local mtileY = math.floor(y/8)
    local mtileNum = mtileY*16+mtileX
    
    if event and event.type == "ButtonPress" then
        local control = NESBuilder:getControlNew("nesstCanvas")
        plugin.data.tool = "draw"
        control.setCursor('pencil')
        --control.setCursor("pencil")
        plugin.data.selectedTile = mtileNum
        print('Tile '..mtileNum)
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
    local x = math.floor(event.x/t.scale)
    local y = math.floor(event.y/t.scale)
    x,y=math.max(x,0),math.max(y,0)
    x,y=math.min(x,t.columns*8-1),math.min(y,t.rows*8-1)
    
    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local attrX = math.floor(tileX / 2)
    local attrY = math.floor(tileY / 2)
    local attrIndex = math.floor(tileY / 4) * 8 + math.floor(tileX / 4)
    
    local tileNum = tileY*t.columns+tileX
    
    if plugin.data.tool == "split" then
        if event.button == 1 then
            local control = NESBuilder:getControlNew("nesstCanvas")
            control.horizontalLine(y)
            print(y)
            control.repaint()

            local value = math.floor(NESBuilder:getControl("splitNum").get())
            NESBuilder:getControl("splitY").set(y)
            
            plugin.splits[value+1] = y
        elseif event.button==2 and event.type == "ButtonPress" then
            local value = math.floor(NESBuilder:getControl("splitNum").get())
            NESBuilder:getControl("splitY").set(0)
            
            table.remove(plugin.splits, value+1)
        end
    end
    
    if (plugin.data.tool or "draw") == "draw" then
        --if t.event.button == 1 then
        if event.button == 1 then
            plugin.data.nameTable[tileNum] = plugin.data.selectedTile or 0
            
            --NESBuilder:setAttribute(plugin.data.attrTable, tileX, tileY, data.project.palettes.index)
            NESBuilder:setAttribute(plugin.data.attrTable, tileX, tileY, getPaletteSet().index)
            
            
            control = NESBuilder:getControlNew("nesstCanvas")
            for x=0,1 do
                for y=0,1 do
                    tile = plugin.data.nameTable[(attrY*2+y)*t.columns+(attrX*2+x)]
                    control.drawTile((attrX*2+x)*8,(attrY*2+y)*8, tile, currentChr(), currentPalette(), 32,32)
                end
            end
            control.repaint()
        end
        
        if event.button == 2 then
            plugin.data.selectedTile = plugin.data.nameTable[tileNum]
            --print(string.format("%04b",plugin.data.attrTable[attrY*4+attrX]))
            
            local bin = python.eval('lambda x:"{0:08b}".format(x)')
            print(bin(plugin.data.attrTable[attrY*4+attrX]))
            
--            local x1= math.floor(x/32)
--            local y1= math.floor(y/32)
--            local attr = plugin.data.attrTable[y1*8+x1]
--            local a = {}
--            for i = 0,3 do
--                a[i] = math.floor(attr/(2^(i*2))) % 4
--            end
--            local i = (tileY % 2)*2+(tileX % 2)
--            attr = a[i]
            
            local c = NESBuilder:getAttribute(plugin.data.attrTable, tileX, tileY)
            
            if data.project.paletteSets[data.project.paletteSets.index+1].index ~=c then
                data.project.paletteSets[data.project.paletteSets.index+1].index = c
                
                --plugin.paletteControls.select(data.project.palettes.index+1)
                PaletteEntryUpdate()
            end
            
            print("selected tile "..plugin.data.selectedTile)
            print("palette: "..c)
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

function plugin.updateTileset()
    local p = data.project.palettes[data.project.palettes.index]
    control = NESBuilder:getControlNew("nesstTileset")
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
end

function plugin.onAutoSave()
    print('auto save.')
end

function plugin.onSaveProject()
    data.project.screenTool = {
        nameTable = NESBuilder:listToTable(plugin.data.nameTable),
        attrTable = NESBuilder:listToTable(plugin.data.attrTable),
        selectedTile = plugin.data.selectedTile,
    }
end

function plugin.onLoadProject()
    plugin.data.nameTable = nil
    plugin.data.attrTable = nil
    plugin.data.selectedTile = 0
    control = NESBuilder:getControlNew("nesstCanvas")
    control.clear()

    if data.project.screenTool then
        plugin.data.nameTable = NESBuilder:tableToList(data.project.screenTool.nameTable,0)
        plugin.data.attrTable = NESBuilder:tableToList(data.project.screenTool.attrTable,0)
        plugin.data.selectedTile = data.project.screenTool.selectedTile
    end
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