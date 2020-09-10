-- NESBuilder plugin
-- nesst.lua
--
-- To enable this plugin, remove the "_" from the start of the filename.

local plugin = {
    author = "SpiderDave",
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
    NESBuilder:makeTabQt{name="nesst", text="Screen Tool"}
    NESBuilder:setTabQt("nesst")
    
    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth, name="nesstLoad",text="Open Session"}
    push(x, y+control.height+pad)
    x = x + control.width + pad
    control=NESBuilder:makeLabel{x=x,y=y+3,clear=true,text="NOTE: This plugin is unfinished"}
    y,x=pop(2)
    
    
    push(y)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=32*8,h=30*8,name="nesstCanvas", scale=2, columns=32, rows=30}
    
    x = x + control.width + pad*2
    y=pop()
    push(left, y+control.height+pad)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=16*8,h=16*8,name="nesstTileset", scale=2, columns=16, rows=16}
    
    y = y + control.height + pad
    
    push(x)
    control=NESBuilder:makeLabelQt{x=x,y=y+3,clear=true,text="Pattern table"}
    x = x + control.width + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=30,h=buttonHeight, name="CHR0",text="A", toggle=1, toggleSet = "chrAB"}
    x = x + control.width + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=30,h=buttonHeight, name="CHR1",text="B", toggle=1, toggleSet = "chrAB"}
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
        table.insert(plugin.paletteControls, control)
        x = x + control.width + pad * 1.5
        if i==2 then
            x=pop()
            y = y + control.height+pad
        end
    end
    plugin.paletteControls.select = function(index)
        for i,control in ipairs(plugin.paletteControls) do
            if i==index then
                control.highlight(True)
            else
                control.highlight()
            end
        end
    end
    
    x=pop()
    y = y + control.height+pad
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=6*7.5,h=buttonHeight, name="testHand",text="split"}
    y = y + control.height+pad
    
    
    control=NESBuilder:makeSpinBox{x=x,y=y,w=60,h=buttonHeight, name="splitNum", index=i}
    control=NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="splitNum", index=i}
    x = x + control.width+pad
    control=NESBuilder:makeSpinBox{x=x,y=y,w=60,h=buttonHeight, name="splitY", index=i}
    control=NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="splitY", index=i}
    
    
    y,x = pop(2)
    
    control=NESBuilder:makeLabel{x=x,y=y+3,clear=true,text="Status bar"}
    plugin.status = control
    
    plugin.loadDefault()
end

function plugin.CHR0_cmd(t)
    --NESBuilder:getControlNew("CHR1").setValue(1-t.getValue())
    CHR0_cmd(t)
    plugin.updateTileset()
end
function plugin.CHR1_cmd(t)
    --NESBuilder:getControlNew("CHR0").setValue(1-t.getValue())
    CHR1_cmd(t)
    plugin.updateTileset()
end

function plugin.onTabChanged(t)
    if t.window.name == "Main" then
        local tab = t.tab()
        if tab == "nesst" then
            if not plugin.data.file then
                plugin.loadDefault()
            end
        end
    end
end

function plugin.loadDefault()
    local control,p,d,f,chr
    
    if not data.project.chr then return end
    if not data.project.palettes then return end
    
    p=data.project.palettes[data.project.palettes.index]
    control = NESBuilder:getControlNew("nesstTileset")
    control.loadCHRData{imageData=data.project.chr[data.project.chr.index], colors=p,columns=16,rows=16}
    
    control = NESBuilder:getControlNew("nesstCanvas")
    control.columns = 32
    control.rows = 30
    control.chrData = data.project.chr[data.project.chr.index]
    
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
    
    control.nameTable = nameTable
    control.attrTable = attrTable
    
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            
            tile=control.nameTable[y*control.columns+x+1]
            attr = attrTable[math.floor(y/4)*8+math.floor(x/4)+1]
            
            n = math.floor(attr/(2^(((math.floor(y/2) % 2)*2 + math.floor(x/2) % 2)*2))) % 4
            
            p = data.project.palettes[n]
            control.drawTile{x*8,y*8, tile=tile, colors=p}
            --control.tilePalette[y*control.columns+x+1]=n
        end
    end
    
    plugin.data.file = true
end


function plugin.nesstLoad_cmd()
    local control,p,d,f,chr
    
    f = NESBuilder:openFile({{"NES Screen Tool Session", ".nss"}})
    
    if f == "" then
        print("Open cancelled.")
        return
    end
    
    plugin.data.file = f
    
    local getData = NESBuilder:importFunction('plugins.nesst','getData')
    d = getData(f)
    
    p = NESBuilder:hexStringToList(d.Palette)
    data.project.palettes = {}
    
    for i=0,15 do
        data.project.palettes[i] = {p[i*4+0],p[i*4+1],p[i*4+2],p[i*4+3]}
    end
    
    for i=0,3 do
        plugin.paletteControls[i+1].setAll(data.project.palettes[i])
        plugin.paletteControls[i+1].index = i
    end
    data.project.palettes.index = d.VarPalActive
    
    p=data.project.palettes[data.project.palettes.index]
    
    
    data.project.chr = {}
    data.project.chr[0]=util.hexToTable(string.sub(d.CHRMain,1+0,0+0x2000))
    data.project.chr[1]=util.hexToTable(string.sub(d.CHRMain,1+0x2000,0x2000+0x2000))
    
    if d.VarBankActive == 4096 then
        data.project.chr.index=1
    else
        data.project.chr.index=0
    end
    
    
    chr = util.hexToTable(string.sub(d.CHRMain,1+0,0+0x2000))
    
    control = NESBuilder:getControlNew("nesstTileset")
    control.loadCHRData{imageData=data.project.chr[data.project.chr.index], colors=p,columns=16,rows=16}
    
    control = NESBuilder:getControlNew("nesstCanvas")
    control.columns = d.VarNameW
    control.rows = d.VarNameH
    
    control.chrData = data.project.chr[1]
    
    local tile,p, attr,n
    
    local nameTable = util.hexToTable(d.NameTable)
    local attrTable = util.hexToTable(d.AttrTable)
    control.nameTable = nameTable
    control.attrTable = attrTable
    
    -- This data will be overwritten below, just using
    -- it to get an array of the right size.
    --control.tilePalette = util.hexToTable(d.NameTable)
    
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            
            tile=control.nameTable[y*control.columns+x+1]
            attr = attrTable[math.floor(y/4)*8+math.floor(x/4)+1]
            
            n = math.floor(attr/(2^(((math.floor(y/2) % 2)*2 + math.floor(x/2) % 2)*2))) % 4
            
            p = data.project.palettes[n]
            control.drawTile{x*8,y*8, tile=tile, colors=p, useCache=false}
            --control.tilePalette[y*control.columns+x+1]=n
        end
    end
    
    --control.test()
    
    plugin.paletteControls[data.project.palettes.index+1].highlight(True)
    
    PaletteEntryUpdate()
    dataChanged()
end

function plugin.testHand_cmd(t)
    local control = NESBuilder:getControlNew("nesstCanvas")
    
    control.tool = "split"
    control.setCursor("LinkSelect")
    print('test')
    
end

function plugin.nesstTileset_cmd(t)
    if not plugin.data.file then return end
    
    local x = math.floor(t.event.x/t.scale)
    local y = math.floor(t.event.y/t.scale)
    local mtileX = math.floor(x/8)
    local mtileY = math.floor(y/8)
    local mtileNum = mtileY*16+mtileX
    
    if t.event and t.event.type == "ButtonPress" then
        local control = NESBuilder:getControlNew("nesstCanvas")
        control.tool = "draw"
        control.setCursor("pencil")
        plugin.selectedTile = mtileNum
    end
end

function plugin.nesstCanvas_cmd(t)
    if not plugin.data.file then return end
    
    local x = math.floor(t.event.x/t.scale)
    local y = math.floor(t.event.y/t.scale)
    x,y=math.max(x,0),math.max(y,0)
    x,y=math.min(x,t.columns*8-1),math.min(y,t.rows*8-1)
    
    local mtileX = math.floor(x/8)
    local mtileY = math.floor(y/8)
    local mtileNum = mtileY*t.columns+mtileX
    print(y)
    if t.tool == "split" then
        t.drawSplit(plugin.splits)
        if t.button == 1 then
            local value = math.floor(NESBuilder:getControl("splitNum").get())
            NESBuilder:getControl("splitY").set(y)
            
            plugin.splits[value+1] = y
        elseif t.button==3 and t.event.type == "ButtonPress" then
            local value = math.floor(NESBuilder:getControl("splitNum").get())
            NESBuilder:getControl("splitY").set(0)
            
            table.remove(plugin.splits, value+1)
            --plugin.splits[value+1]=0
        end
        t.drawSplit(plugin.splits)
    end
    
    
    if t.tool == "draw" or t.tool == false then
        if (t.event.type == "ButtonPress" and t.event.button == 1) or t.event.type == "Motion" then
                local p = data.project.palettes[data.project.palettes.index]
                
                t.nameTable[mtileNum+1] = plugin.selectedTile
                --t.tilePalette[mtileNum+1] = data.project.palettes.index
                
                local x1= math.floor(x/32)
                local y1= math.floor(y/32)
                local attr = t.attrTable[y1*8+x1+1]
                local a = {}
                for i = 0,3 do
                    a[i] = math.floor(attr/(2^(i*2))) % 4
                end
                local i = (mtileY % 2)*2+(mtileX % 2)
                a[i] = data.project.palettes.index
                attr = 0
                for i = 0,3 do
                    attr = attr + a[i]*(2^(i*2))
                end
                t.attrTable[y1*8+x1+1] = attr
                
                t.drawTile{mtileX*8,mtileY*8, tile=plugin.selectedTile, colors=p, chrData = NESBuilder:getControlNew("nesstTileset").chrData}
                
                --plugin.splits = plugin.splits or {0x40, 0x60}
                t.drawSplit(plugin.splits)
        elseif t.event.type == "ButtonPress" and t.event.button == 3 then
            plugin.selectedTile = t.nameTable[mtileNum+1]
            
            
            local x1= math.floor(x/32)
            local y1= math.floor(y/32)
            local attr = t.attrTable[y1*8+x1+1]
            local a = {}
            for i = 0,3 do
                a[i] = math.floor(attr/(2^(i*2))) % 4
            end
            local i = (mtileY % 2)*2+(mtileX % 2)
            attr = a[i]
            
            
    --        if data.project.palettes.index ~= t.tilePalette[mtileNum+1] then
    --            data.project.palettes.index = t.tilePalette[mtileNum+1]
            if data.project.palettes.index ~= attr then
                data.project.palettes.index = attr
                
                --data.project.palettes.index = t.attrTable[math.floor(y/32)*8+math.floor(x/32)+1]
                
                
                plugin.paletteControls.select(data.project.palettes.index+1)
                PaletteEntryUpdate()
            end
            
            print("selected tile "..plugin.selectedTile)
        end
    end
end

--function getAttr(tileX, tileY, attrTable)
--end



function plugin.nesstPalette1_cmd(t) plugin.nesstPalette_cmd(t) end
function plugin.nesstPalette2_cmd(t) plugin.nesstPalette_cmd(t) end
function plugin.nesstPalette3_cmd(t) plugin.nesstPalette_cmd(t) end
function plugin.nesstPalette4_cmd(t) plugin.nesstPalette_cmd(t) end


function plugin.nesstPalette_cmd(t)
    if not plugin.data.file then return end
    
    plugin.paletteControls.select(t.index+1)
    
    data.project.palettes.index = t.index
    
    plugin.updateTileset()
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
    
    if not plugin.data.file then return end
    
    local filename = data.folders.projects..projectFolder.."code/nametable.asm"
    
    control = NESBuilder:getControlNew("nesstCanvas")
    
    out=out.. "nametable_data:\n"
    for i,v in ipairs(control.nameTable) do
        if (i-1) % 16 == 0 then
            out=out.."    .db "
        end
        out=out..string.format("$%02x",v or "????")
        if (i-1) % 16 == 15 then
            out=out.."\n"
        --elseif i<=#control.nameTable then
        else
            out=out..", "
        end
    end
    
    out=out.. "; attribute data\n"
    for i,v in ipairs(control.attrTable) do
        if (i-1) % 16 == 0 then
            out=out.."    .db "
        end
        out=out..string.format("$%02x",v or "????")
        if (i-1) % 16 == 15 then
            out=out.."\n"
        --elseif i<=#control.attrTable then
        else
            out=out..", "
        end
    end
    
    out=out..string.format("; NT length = %s\n; AT length = %s\n",#control.nameTable, #control.attrTable)
    
    print("File created "..filename)
    util.writeToFile(filename,0, out, true)
end

return plugin