-- NESBuilder plugin
-- nesst.lua

-- To Do:
--     * save a checksum for linked chr


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
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, name="nesstLoad",text="Import from .nss"}
    control.helpText = "Load a .nss file created with Shiru's NES Screen tool."
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstSave",text="Export to .nss"}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstImportFromRom",text="Import From ROM Data"}
    control.helpText = "Import nametable data from current rom."
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstImportFromPPUDump",text="Import From PPU Dump"}
    
    if devMode() then
        x = x + control.width + pad
        control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstTest",text="test"}

    end
    
    y,x=pop(2)
    
    if devMode() then
        control = NESBuilder:makeLabel{x=x,y=y, clear=true, text="Screen / Session"}
        y = y + control.height + pad
        
        push(x)
        control = NESBuilder:makeComboBox{x=x,y=y,w=buttonWidth * 2, name="nesstScreenSelect", itemList = {"foo", "bar", "baz"}}
        x = x + control.width + pad
        control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstAddScreen", text="Add"}
        x = x + control.width + pad
        control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstDelScreen", text="Del"}
        x = pop()
        
        
        y = y + control.height + pad
    end
    
    push(y)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=32*8,h=30*8,name="nesstCanvas", scale=2, columns=32, rows=30}
    control.helpText = "Click to draw tiles, right-click to select a tile"
    control.setCursor('pencil')
    
    push(x, y)
    y = y + control.height + pad
    --control = NESBuilder:makeLineEdit{x=x,y=y,w=buttonWidth,h=inputHeight, name="nesstBankInput", text="00 01 02 03"}
    control = NESBuilder:makeComboBox{x=x,y=y,w=buttonWidth * 2, name="nesstCompressionSelect", itemList = {}}
    y,x = pop(2)
    
    control = getControl("nesstCanvas")
    
    x = x + control.width + pad*2
    y=pop()
    push(left, y+control.height+pad)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=16*8,h=16*8,name="nesstTileset", scale=2, columns=16, rows=16}
    control.helpText = "Click to select a tile"
    
    push(x, y + control.height + pad)
    
    x = x + control.width + pad
    
    if devMode() then
        for i = 0,3 do
            txt = string.format("%02x", i)
            control = NESBuilder:makeLabelQt{x=x,y=y, name = "nesstChrBank", clear=true, text=txt, index=i-1}
            y = y + 8 * 4 * 2
        end
    end
    
    y,x=pop(2)
    
    push(x)
    control = NESBuilder:makeLabelQt{x=x,y=y, clear=true, text="A B"}
    control = NESBuilder:makeButton{x=x,y=y,w=buttonHeight,h=buttonHeight, name="nesstChrA", text="A"}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonHeight,h=buttonHeight, name="nesstChrB", text="B"}
    y = y + control.height + pad
    x = pop()
    
    
    
--    y = y + control.height + pad
    
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
    control = NESBuilder:makeComboBox{x=x,y=y,w=128*2, name="nesstCHRSelect", itemList = {'Use current CHR','Use CHR with index','Use loaded custom CHR', 'Use linked custom CHR'}}
    control.helpText = "Select an option to help determine which CHR to use for the nametable."
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,h=buttonHeight, name="nesstCHRSelectSet",text="set"}
    
    y = y + control.height + pad
    
    y, x = pop(2)
    
--    control=NESBuilder:makeLabelQt{x=x,y=y+3,clear=true,text="Status bar"}
--    plugin.status = control
    
    plugin.loadDefault()
end


function plugin.makeScreen(name)
    local nt = makeNp0(0x3c0)
    local at = makeNp0(0x40)
    local chr0 = makeNp0(0x1000)
    local chr1 = makeNp0(0x1000)
    local pal = makeNp0(0x20)
    
    local screen = {
        index = n,
        name = name or "screen",
        nameTable = {data = nt},
        attrTable = {data = at},
        chr = {
            index = 0,
            {type = 0, data = chr0},
            {type = 0, data = chr0},
        },
        pal = {data = pal},
        compression = "None",
    }
    
    return screen
end

function nesstDelScreen_cmd(t)
    local index = plugin.data.currentScreen or 0
    local screen = plugin.getScreen()
    
    if not screen then return end
    
    local control = getControl("nesstScreenSelect")
    control.removeItem(index)
    table.remove(plugin.data.screens, index + 1)
    
    if #plugin.data.screens == 0 then
        nesstAddScreen_cmd()
    end
    
    
    nesstRefreshScreen()
    dataChanged()

end

function nesstAddScreen_cmd(t)
    local index = #plugin.data.screens+1
    
    local screen = plugin.makeScreen(string.format("screen %s", index))
    plugin.data.screens[index] = screen
    
    local control = getControl("nesstScreenSelect")
    control.addItem(screen.name)
end

function plugin.getScreen()
    if not plugin.data.screens then
        plugin.loadDefault()
    end

    return plugin.data.screens[(plugin.data.currentScreen or 0)+1]
end

function plugin.getNameTableData()
    local screen = plugin.getScreen()
    return screen.nameTable.data
end
function plugin.getAttrTableData()
    local screen = plugin.getScreen()
    return screen.attrTable.data
end
function plugin.getPalette()
    local pSet = util.deepCopy(getPaletteSet())
    local p = {}
    for i = 0,3 do
        local palette = pSet.palettes[i+1]
        p[#p+1] = pSet.palettes[i+1] or {0x0f, 0x01, 0x11, 0x21}
    end
    return p
end


function nesstScreenSelect_cmd(t)
    local control = t.control
    local index = control.currentIndex()
    
--    printf("control index: %s", index)
--    printf("plugin.data.currentScreen: %s", plugin.data.currentScreen)
    
    if index == plugin.data.currentScreen then return end
    
    plugin.data.currentScreen = index
    local screen = plugin.getScreen()
    
--    plugin.data.nameTable = screen.nameTable.data
--    plugin.data.attrTable = screen.attrTable.data
--    local nt = plugin.getNameTableData()
--    local at = plugin.getAttrTableData()
    
    plugin.setCompressionSelect(screen.compression or "None")
    getControl("nesstCHRSelect").setCurrentIndex(plugin.getSelectedCHRType())
    
    nesstRefreshScreen()
    dataChanged()
    
end

function nesstChrA_cmd()
    local screen = plugin.getScreen()
    screen.chr.index = 0
    getControl("nesstCHRSelect").setCurrentIndex(plugin.getSelectedCHRType())
    nesstRefreshScreen()
end
function nesstChrB_cmd()
    local screen = plugin.getScreen()
    screen.chr.index = 1
    getControl("nesstCHRSelect").setCurrentIndex(plugin.getSelectedCHRType())
    nesstRefreshScreen()
end

function plugin.getSelectedCHR()
    local screen = plugin.getScreen()
    return screen.chr.index
end

function nesstCompressionSelect_cmd(t)
    local control = t.control
    local index = control.currentIndex()
    
    
    local screen = plugin.getScreen() or {}
    screen.compression = control.currentText()
    
--    plugin.data.currentCompression = control.currentText()
--    if plugin.data.currentCompression == "None" then plugin.data.currentCompression = nil end
--    print(plugin.data.currentCompression)
    print(screen.compression)
end

function plugin.getCompression()
    local screen = plugin.getScreen() or {}
    return screen.compression
    --return plugin.data.currentCompression
end

function plugin.onUpdateCompression()
    local control = getControl("nesstCompressionSelect")
    
    control.itemList = data.compression
    control.clear()
    
    control.addItem("None")
    for k,v in pairs(data.compression) do
        control.addItem(k)
    end
    
    if tableIsEmpty(data.compression) then control.hide() else control.show() end
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
    
--    plugin.data.nameTable = nameTable
--    plugin.data.attrTable = attrTable
    
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            
            --tile=plugin.data.nameTable[y*control.columns+x+1]
            tile=nameTable[y*control.columns+x+1]
            --attr = attrTable[math.floor(y/4)*8+math.floor(x/4)+1]
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
    
    local p = {}
    for i = 0, 15 do
        p[i//4+1] = p[i//4+1] or {}
        p[i//4+1][i % 4+1] = d.Palette[i]
    end
    
    -- add palette set
    local pSet = {
      name = "nss session palette import",
      palettes = p,
      palettesDesc = {},
      index = 0,
    }
    -- select the new palette set and update
    data.project.paletteSets[#data.project.paletteSets+1] = pSet
    updatePaletteSets(#data.project.paletteSets-1)
    
    p = currentPalette()
    
    -- load custom chr
    local pat = 0
    if d.BtnChrBank2 == 1 then pat = 1 end
    local chr = makeNp(d.CHR[pat])
--    plugin.data.customChr = makeNp(d.CHR[pat])
    
    -- set chr type to custom
    plugin.data.chrType = 2
    
    control = NESBuilder:getControlNew("nesstCanvas")
    control.columns = d.VarNameW or 32
    control.rows = d.VarNameH or 30
    
--    plugin.data.nameTable = NESBuilder:hexToList(d.NameTable)
--    plugin.data.attrTable = NESBuilder:hexToList(d.AttrTable)
--    plugin.data.nameTable = d.NameTable
--    plugin.data.attrTable = d.AttrTable
    printf("%04x", len(d.NameTable))
    printf("%04x", len(d.AttrTable))
    
    
    
    local index = #plugin.data.screens+1
    local screen = plugin.makeScreen(string.format("nss import %s", index))
    screen.nameTable.data = d.NameTable
    screen.attrTable.data = d.AttrTable
    screen.chr[1].data = chr
    screen.chr[2].data = chr
    
    -- custom type
    screen.chr[1].type = 2
    screen.chr[2].type = 2
    
    screen.compression = "None"
    plugin.data.screens[index] = screen
    control = getControl("nesstScreenSelect")
    control.addItem(screen.name)
    plugin.data.currentScreen = index - 1
    control.setCurrentIndex(index - 1)
    
    plugin.setCompressionSelect()
    getControl("nesstCHRSelect").setCurrentIndex(plugin.getSelectedCHRType())
    
    
    nesstRefreshScreen()
    dataChanged()
end

function nesstLoadChr(filename)
    local f
    if filename then
        f = filename
    else
        f = NESBuilder:openFile{filetypes={{"All valid types", ".chr", ".png"}, {"CHR", ".chr"}, {"Images", ".png"}}}
        if f == "" then
            print("Open cancelled.")
            return
        end
    end
    print("file: "..f)
    --plugin.data.customChr = makeNp(getChrFromFile(f))
    
    local screen = plugin.getScreen()
    
    screen.chr[screen.chr.index+1].data = makeNp(getChrFromFile(f))
    screen.chr[screen.chr.index+1].filename = f
    
    nesstRefreshScreen()
    
    return f
end

function nesstSave_cmd()
    local filename = "nsst export.nss"
    local f, ext, filter = NESBuilder:saveFileAs{filetypes={{"NXXT / NES Screen tool Session (.nss)", ".nss"}}, initial=filename}
    if f == "" then
        print("Export cancelled.")
    else
        print("file: "..f)
    end
    
    local nameTable = plugin.getNameTableData()
    local attrTable = plugin.getAttrTableData()
    
    local p = list()
    
    for _, palette in ipairs(plugin.getPalette()) do
        listExtend(p, NESBuilder:tableToList(palette, 0))
    end
    
    local createNss = NESBuilder:importFunction('plugins.nesst','createNss')
    
    local screen = plugin.getScreen()
    local CHRNum = screen.chr.index
    local chr0 = NESBuilder:toList(plugin.getCHRData(0))
    local chr1 = NESBuilder:toList(plugin.getCHRData(1))
    local chr = joinList(chr0, chr1)
    
    createNss(toDict({
        filename = f,
        nameTable = nameTable,
        attrTable = attrTable,
        chr = chr,
        chrNum = CHRNum,
        palette = p,
    }))
    print("done.")
end

function nesstTest_cmd()
--    print(compress('Konami RLE'))
--    print(decompress('Konami RLE'))
--    if true then return end
    
    local nt = NESBuilder:toList(plugin.data.nameTable)
    local at = NESBuilder:toList(plugin.data.attrTable)
    
    local data = compress('Konami RLE', {data = joinList(nt, at)})
    local data2 = decompress('Konami RLE', {data = data['data']})
    
    print(data['length'])
    print(data2['length'])
--    print(len(data['data']))
--    print(len(data2['data']))
    print(len(data2['ppu']['palette']))
    print(len(data2['ppu']['nameTable'][0]))
    
    
    if true then return end
    
--[[
     types of data:
       * static/fixed - data doesn't change
       * loaded - use loaded romdata
       * external - data is linked to external file
       * current - use something selected elsewhere
       * set/specific - use a set index/selection
       * none

     some options:
       * compression/decompression methods
       * file/romdata offsets
     
     example:
        Castlevania III
        palette:
            type: set/specific
            palSet: (index)
        chr:
            type: set/specific
            banks: 0x41, 0x70, 0x71, 0x72
        nametable:
            type: loaded
            file offset: 0xb580
            compression/decompression: Konami RLE
]]--

    
--    local screen = {
--        nameTable = {},
--        attrTable = {},
--        chr = {},
--        palette = {},
--    }
    
    
    
    
    local banks = {0x41, 0x70, 0x71, 0x72}
    local chr = list()
    local t = {}
    
    for i, bank in ipairs(banks) do
        local l = NESBuilder:toList(sliceList(currentChr(bank // 4), 0 + 0x400 * (bank % 4), 0 + 0x400 * (bank % 4) + 0x400))
        chr = joinList(chr, l)
    end
    
    plugin.data.customChr = makeNp(chr)
    nesstRefreshScreen()
end

function nesstImportFromPPUDump_cmd()
    local f = NESBuilder:openFile{filetypes={{"ppu dump", ".bin"}}}
    if f == "" then
        print("Open cancelled.")
        return
    end
    print("file: "..f)
    
    local fileData = NESBuilder:getFileContents(f)
    
    local chr0 = makeNp(sliceList(fileData, 0, 0 + 0x1000))
    local chr1 = makeNp(sliceList(fileData, 0x1000, 0x1000 + 0x1000))
--    local nt1 = makeNp(sliceList(fileData, 0x2000, 0x2000 + 0x3c0))
--    local attr1 = makeNp(sliceList(fileData, 0x23c0, 0x23c0 + 0x40))
    local nt1 = sliceList(fileData, 0x2000, 0x2000 + 0x3c0)
    local attr1 = sliceList(fileData, 0x23c0, 0x23c0 + 0x40)
    local palettes = sliceList(fileData, 0x3f00, 0x3f00 + 0x20)
    
    local p = {}
    for i = 0,3 do
        p[i+1] = NESBuilder:listToTable(sliceList(palettes, 0 + i * 4, 0 + i * 4 + 4))
    end
    
    local pSet = {
      name = "test ppu dump palette import",
      palettes = p,
      palettesDesc = {},
      index = 0,
    }
    data.project.paletteSets[#data.project.paletteSets+1] = pSet
    updatePaletteSets(#data.project.paletteSets-1)
    
    plugin.data.customChr = chr0
    --plugin.data.customChr = chr1
    plugin.data.nameTable = nt1
    plugin.data.attrTable = attr1
    
    nesstRefreshScreen()
end

function nesstImportFromRom_cmd()
    if (not data.project.rom.filename) and (not data.project.rom.data) then
        NESBuilder:showError("Error", "No rom file or data.")
        return
    end
    
    
    plugin.data.defaultImportFromRomOffset = defaultImportFromRomOffset or 0x9010 -- default for zombie nation title screen
    
    local defaultText = string.format("0x%04x", plugin.data.defaultImportFromRomOffset)
    local txt = askText('Import nametable from rom data', 'Enter a file offset of nametable data.', defaultText)
    
    -- cancelled
    if not txt then return end
    
    local address = tonumber(txt)
    if not address then return end
    
    plugin.data.defaultImportFromRomOffset = address
    
    if data.project.rom.filename and not data.project.rom.data then
        loadRom(data.project.rom.filename)
        print("loading rom data")
        if not data.project.rom.data then return end
    end
    
    -- we use toList to make sure the elements are regular ints
    -- to avoid issues when converting from np arrays
    local romData = NESBuilder:toList(getRomData())
    
    local compression = plugin.getCompression()
    printf("Compression: %s", compression or "None")
    
    if compression then
        -- for now, compression assumes combined nt+attr
        local d = decompress(compression, {data = romData, offset = address})
        if not d then
            print("invalid data.")
            return
        end
        plugin.data.nameTable = d["ppu"]["nameTable"][0]
        plugin.data.attrTable = d["ppu"]["attrTable"][0]
        --printf("length: %s", d['length'])
    else
        plugin.data.nameTable = sliceList(romData, address, address + 0x3c0)
        plugin.data.attrTable = sliceList(romData, address + 0x3c0, address + 0x3c0 + 0x40)
    end
    
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
    
    local nt = plugin.getNameTableData()
    local at = plugin.getAttrTableData()
    
    
--    if not plugin.data.nameTable then
--        print('setting nametable default')
--        plugin.data.nameTable = control.setNameTable()
--        plugin.data.attrTable = control.setAttrTable()
--    end
    
    control.columns = 32
    control.rows = 30
    
    --control.chrData = currentChr()
    control.chrData = plugin.getCHRData()
    
    local tile,p, attr,n
    
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    
    control.clear()
    for y=0, control.rows-1 do
        for x=0, control.columns-1 do
            tile = nt[y*control.columns+x]
            --tile = plugin.data.nameTable[y*control.columns+x]
            --n = NESBuilder:getAttribute(plugin.data.attrTable, x,y)
            n = NESBuilder:getAttribute(at, x,y)
            
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

function plugin.getSelectedCHRType(CHRNum)
    local control = getControl("nesstCHRSelect")
    if not control then return 0 end
    
    local screen = plugin.getScreen()
    if not screen then return 0 end
    
    CHRNum = CHRNum or screen.chr.index
    local index = control.currentIndex()
    
    
    
    if screen then return screen.chr[CHRNum+1].type or index end
    
    return index
end

function plugin.getCHRData(CHRNum)
    local screen = plugin.getScreen()
    
    CHRNum = CHRNum or screen.chr.index
    local index = plugin.getSelectedCHRType(CHRNum)
    
    
    
    --printf("getSelectedCHR %s", index)
    
    if index == 0 then
        -- current CHR
        return currentChr()
    elseif index == 1 then
        -- specific CHR
        --return currentChr(plugin.data.chrIndex or 0)
        return currentChr(screen.chr[CHRNum+1].index or 0)
    elseif index == 2 then
        -- custom CHR
        --return plugin.data.customChr or currentChr(0)
        return screen.chr[CHRNum+1].data or currentChr(0)
    elseif index == 3 then
        -- linked CHR
        --return plugin.data.customChr or currentChr(0)
        return screen.chr[CHRNum+1].data or currentChr(0)
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
    surface.loadCHR(plugin.getCHRData())
    -- apply current palette to it
    surface.applyPalette(currentPalette())
    -- paste the surface on our canvas (it will be sized to fit)
    control.paste(surface)
end

function nesstCHRSelect_cmd(t)
    local index = t.control.currentIndex()
    print(index)
    
    local screen = plugin.getScreen()
    
    if not devMode() then
        if index == 3 then
            notImplemented()
            --t.control.setCurrentIndex(plugin.data.chrType)
            t.control.setCurrentIndex(plugin.getSelectedCHRType())
            return
        end
    end
    
    
    screen.chr[screen.chr.index+1].type = index
    --plugin.data.chrType = index
    
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
        plugin.data.chrFilename = nil
    elseif index == 3 then
        -- linked CHR
        local f = nesstLoadChr()
        plugin.data.chrFilename = f
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
--    if not plugin.data.nameTable then
--        local control = NESBuilder:getControlNew("nesstCanvas")
--        plugin.data.nameTable = control.setNameTable()
--        plugin.data.attrTable = control.setAttrTable()
--        return
--    end
    local nt = plugin.getNameTableData()
    local at = plugin.getAttrTableData()
    
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
            --local c = NESBuilder:getAttribute(plugin.data.attrTable, tileX, tileY)
            local c = NESBuilder:getAttribute(at, tileX, tileY)
            if plugin.data.applyTiles then
                --plugin.data.nameTable[tileNum] = plugin.data.selectedTile or 0
                nt[tileNum] = plugin.data.selectedTile or 0
            end
            if plugin.data.applyAttr then
                --NESBuilder:setAttribute(plugin.data.attrTable, tileX, tileY, getPaletteSet().index)
                NESBuilder:setAttribute(at, tileX, tileY, getPaletteSet().index)
            end
            
            control = NESBuilder:getControlNew("nesstCanvas")
            
            for x=0,1 do
                for y=0,1 do
                    --tile = plugin.data.nameTable[(attrY*2+y)*t.columns+(attrX*2+x)]
                    tile = nt[(attrY*2+y)*t.columns+(attrX*2+x)]
                    --control.drawTile((attrX*2+x)*8,(attrY*2+y)*8, tile, currentChr(), currentPalette(c), 32,32)
                    control.drawTile((attrX*2+x)*8,(attrY*2+y)*8, tile, plugin.getCHRData(), currentPalette(c), 32,32)
                end
            end
            control.repaint()
        end
        
        if event.button == 2 then
            if plugin.data.applyTiles then
                --plugin.data.selectedTile = plugin.data.nameTable[tileNum]
                plugin.data.selectedTile = nt[tileNum]
                printl("selected tile:", plugin.data.selectedTile)
                --print(bin(plugin.data.attrTable[attrY*4+attrX]))
            end
            if plugin.data.applyAttr then
                --local c = NESBuilder:getAttribute(plugin.data.attrTable, tileX, tileY)
                local c = NESBuilder:getAttribute(at, tileX, tileY)
                
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
    
    --if not plugin.data.nameTable then return end
    
    local filename = data.folders.projects..projectFolder.."code/nametable.asm"
--    local nameTable = NESBuilder:listToTable(plugin.data.nameTable)
--    local attrTable = NESBuilder:listToTable(plugin.data.attrTable)
    
    local nameTable = plugin.getNameTableData()
    local attrTable = plugin.getAttrTableData()
    if not nameTable then return end
    
    if (plugin.getSelectedCHRType() == 3) and plugin.data.chrFilename then
        -- update linked file
        --nesstLoadChr(plugin.data.chrFilename)
    end
    
    if false then
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
    
    -- make sure nametable folder exists
    NESBuilder:makeDir(data.folders.projects..projectFolder.."nametable")
    
    local compression = plugin.getCompression()
    printf("Compression: %s", compression or "None")
    
    if compression then
        -- for now, compression assumes combined nt+attr
        --local d = compress(compression, {data = joinList(plugin.data.nameTable, plugin.data.attrTable)})
        print("marker 1 *******************")
        print(type(nameTable))
        print(type(attrTable))
        
        local nt = NESBuilder:toList(nameTable)
        local at = NESBuilder:toList(attrTable)
        
        --local d = compress(compression, {data = joinList(nameTable, attrTable)})
        local d = compress(compression, {data = joinList(nt, at)})
        if d then
            filename = data.folders.projects..projectFolder.."nametable/screenTool.compressed.nt"
            NESBuilder:saveArrayToFile(filename, d['data'])
            out = string.format('screenToolCompression="%s"\n\n', compression)
            out = out .. 'incbin "screenTool.compressed.nt"\n'
        else
            print("compression failed. falling back to uncompressed.")
            compression = false
        end
    end
    
    if not compression then
        filename = data.folders.projects..projectFolder.."nametable/screenTool.nt"
        NESBuilder:saveArrayToFile(filename, nameTable)
        filename = data.folders.projects..projectFolder.."nametable/screenTool.attr"
        NESBuilder:saveArrayToFile(filename, attrTable)
        out = 'incbin "screenTool.nt"\nincbin "screenTool.attr"\n'
    end
    
    filename = data.folders.projects..projectFolder.."nametable/screenTool.nametable.asm"
    
    print("File created "..filename)
    util.writeToFile(filename,0, out, true)
    
    --if (plugin.getSelectedCHRType() == 2) and plugin.data.customChr then
    if (plugin.getSelectedCHRType() == 2) then
        filename = data.folders.projects..data.project.folder.."chr/screenTool.custom.chr"
        NESBuilder:saveArrayToFile(filename, plugin.getCHRData())
    end
    
    
    filename = data.folders.projects..data.project.folder.."code/screenTool.palette.asm"
    out = ""
    
    local palette = plugin.getPalette()
    
--    local pSet = getPaletteSet()
    
--    out=out..string.format("; %s\n", pSet.name)
--    if pSet.desc then
--        out=out..string.format("; %s\n", pSet.desc)
--    end
    
    for i = 0,3 do
        local p = palette[i+1]
        out=out..string.format("screenToolPal%s = $%02x, $%02x, $%02x, $%02x\n", i, p[1], p[2], p[3], p[4])
    end
    
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
        applyTiles = plugin.data.applyTiles,
        applyAttr = plugin.data.applyAttr,
        customChr = plugin.data.customChr,
        chrIndex = plugin.data.chrIndex,
        chrType = plugin.data.chrType,
        compression = plugin.data.currentCompression,
        chrFilename = plugin.data.chrFilename,
        --screens = plugin.data.screens,
        currentScreen = plugin.data.currentScreen,
    }
end


--local screen = {
--    nameTable = false,
--    attrTable = false,
--    selectedTile = false,
--    applyTiles = false,
--    applyAttr = false,
    
--}

function plugin.setCompressionSelect(compression)
    control = getControl("nesstCompressionSelect")
    
    compression = compression or plugin.getCompression()
    
    for i = 0, control.count() do
        if control.itemText(i) == compression then
            control.setCurrentIndex(i)
            return
        end
    end
end

function plugin.onEnablePlugin()
    local control
    
    plugin.data.nameTable = nil
    plugin.data.attrTable = nil
    plugin.data.selectedTile = 0
    plugin.data.applyTiles = true
    plugin.data.applyAttr = true
    plugin.data.customChr = nil
    plugin.data.chrIndex = nil
    plugin.data.chrType = 0
    plugin.data.currentCompression = nil
    plugin.data.currentScreen = 0
    plugin.data.chrFilename = nil
    plugin.data.screens = {}
    control = NESBuilder:getControlNew("nesstCanvas")
    control.clear()
    
    if #plugin.data.screens == 0 then
        local screen = plugin.makeScreen("default")
        plugin.data.screens[1] = screen
        control = getControl("nesstScreenSelect")
        control.addItem(screen.name)
    end
    
    plugin.setCompressionSelect()
    getControl("nesstCHRSelect").setCurrentIndex(plugin.getSelectedCHRType())
    getControl('nesstApplyTiles').setChecked(bool(plugin.data.applyTiles))
    getControl('nesstApplyAttr').setChecked(bool(plugin.data.applyAttr))
end

function plugin.onLoadProject()
    local control
    
    plugin.data.nameTable = nil
    plugin.data.attrTable = nil
    plugin.data.selectedTile = 0
    plugin.data.applyTiles = true
    plugin.data.applyAttr = true
    plugin.data.customChr = nil
    plugin.data.chrIndex = nil
    plugin.data.chrType = 0
    plugin.data.currentCompression = nil
    plugin.data.currentScreen = 0
    plugin.data.chrFilename = nil
    plugin.data.screens = {}
    control = NESBuilder:getControlNew("nesstCanvas")
    control.clear()
    local control = getControl("nesstScreenSelect")
    control.clear()
    
    if data.project.screenTool then
        --plugin.data.nameTable = NESBuilder:tableToList(data.project.screenTool.nameTable,0)
        --plugin.data.attrTable = NESBuilder:tableToList(data.project.screenTool.attrTable,0)
        local nt = NESBuilder:tableToList(data.project.screenTool.nameTable,0)
        local at = NESBuilder:tableToList(data.project.screenTool.attrTable,0)
        plugin.data.selectedTile = data.project.screenTool.selectedTile
        plugin.data.applyTiles = data.project.screenTool.applyTiles
        plugin.data.applyAttr = data.project.screenTool.applyAttr
        --plugin.data.customChr = data.project.screenTool.customChr
        --plugin.data.chrIndex = data.project.screenTool.chrIndex
        --plugin.data.chrType = data.project.screenTool.chrType or 0
        --plugin.data.currentCompression = data.project.screenTool.compression
        plugin.data.chrFilename = data.project.screenTool.chrFilename
        plugin.data.screens = data.project.screens or {}
        
        if data.project.screenTool.nameTable then
            local index = #plugin.data.screens+1
            --local screen = plugin.makeScreen(string.format("screen %s", index))
            local screen = plugin.makeScreen(string.format("test screen %s", index))
            screen.nameTable.data = nt
            screen.attrTable.data = at
            screen.chr[1].data = data.project.screenTool.customChr
            screen.chr[2].data = data.project.screenTool.customChr
            
            screen.chr[1].index = data.project.screenTool.chrIndex
            screen.chr[2].index = data.project.screenTool.chrIndex
            
            screen.chr[1].type = data.project.screenTool.chrType
            screen.chr[2].type = data.project.screenTool.chrType
            
            screen.compression = data.project.screenTool.compression
            plugin.data.screens[index] = screen
            control = getControl("nesstScreenSelect")
            control.addItem(screen.name)
        end
    end
    
    if (plugin.getSelectedCHRType() == 3) and plugin.data.chrFilename then
        -- update linked file
        nesstLoadChr(plugin.data.chrFilename)
    end
    
    if #plugin.data.screens == 0 then
        local screen = plugin.makeScreen("default")
        plugin.data.screens[1] = screen
        control = getControl("nesstScreenSelect")
        control.addItem(screen.name)
    end
    
    local screen = plugin.getScreen()
    plugin.setCompressionSelect(screen.compression or "None")
    
    getControl("nesstCHRSelect").setCurrentIndex(plugin.getSelectedCHRType())
    getControl('nesstApplyTiles').setChecked(bool(plugin.data.applyTiles))
    getControl('nesstApplyAttr').setChecked(bool(plugin.data.applyAttr))
    
--    local screen = {
--        index = n,
--        name = name or "screen",
--        nameTable = {data = nt},
--        attrTable = {data = at},
--        chr0 = {data = chr0},
--        chr1 = {data = chr1},
--        pal = {data = pal},
--        compression = "None",
--    }
    
--    local index = #plugin.data.screens+1
    
--    local screen = plugin.makeScreen(string.format("screen %s", index))
--    plugin.data.screens[index] = screen
    
--    local control = getControl("nesstScreenSelect")
--    control.addItem(screen.name)

    
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