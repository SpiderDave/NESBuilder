main = {}
config = {
    title="NESBuilder",
    width=850,
    height=700,
    cellWidth=24,
    cellHeight=24,
    buttonWidth=20,
    buttonHeight=26,
    buttonWidthSmall=4,
    aboutURL = "https://github.com/SpiderDave/NESBuilder#readme",
    bitcoinURL = "bitcoin:1ZdyKcXeqbbBp9yFxpEdpCMwSwccR2Cey",
    moneroURL = "monero:831QMtQnoJJPik5Jtbz5wPhjDDM5JnMFVh5G7z834gTbLyHo4TcE83KBi4Co7FoBSi3V4j7VQpHWi5ZEckBZqhjCAA4BowV",
    colors = {
        bk='#202036',
        bk2='#303046',
        bk3='#404050',      -- text background
        bk4='#656570',
        bk_hover='#454560',
        fg = '#eef',
        menuBk='#404056',
        bk_menu_highlight='#606080',
        bk_highlight='#404060',
        tkDefault='#656570',
        link='white',
        linkHover='#88f',
        borderLight='#56565a',
        borderDark='#101020',
        textInputBorder='#99a',
    },
    pluginFolder = "plugins", -- this one is for python
    nRecentFiles = 12,
    nRecentFiles_menu = 4,
    defaultAssembler = 'sdasm',
}

config.buttonWidthNew = 20*7.5
config.buttonHeightNew = 26*7.5


config.pad = 6
config.left = config.pad*1.5
config.top = config.pad*1.5


config.launchText=[[
Created by SpiderDave
-------------------------------------------------------------------------------------------
NESBuilder is a NES development and romhacking tool made with
Python and Lua.

The goal of NESBuilder is to make NES development and romhacking
easier, helping to create a NES game from start to finish or
modify an existing game easily.

Features:
 *  Open source
 *  Integrated custom assembler
 *  Palette editor
 *  CHR Import/export and editing.
 *  Metatiles
 *  plugin system (Lua/Python)
]]

-- global stacks
stack, push, pop = NESBuilder:newStack()
recentProjects = NESBuilder:newStack{maxlen=config.nRecentFiles}

pad,left,top=config.pad, config.left, config.top

data = {}

data.projectTypes = {
    {name = "dev", text = "NES Game", helpText="Create a new NES game."},
    {name = "romhack", text = "Rom Hack", helpText="Modify an existing NES Rom."},
}

-- Override print with something custom.
_print = print
print = function(...) NESBuilder:print(...) end


makeHex = function(n)
    if NESBuilder:cfgGetValue("main", "upperhex")==1 then
        return string.format("%02X",n)
    else
        return string.format("%02x",n)
    end
end

data.selectedColor = 0
data.palettes = {}

data.palettes = {
    index=0,
    [0]={0x0f,0x21,0x11,0x01},
    {0x0f,0x26,0x16,0x06},
    {0x0f,0x29,0x19,0x09},
    {0x0f,0x30,0x10,0x00},
}

data.projectID = "project1" -- this determines the folder that it will load the project data from

data.folders = {
    projects = "projects/",
    tools = "tools/",
    templates = "templates/",
    plugins = config.pluginFolder.."/",
    palettes = "palettes/",
}

data.project = {chr={}}
data.assemblers = {'sdasm','asm6','xkasplus'}

function init()
    local x,y,pad
    local control, b, c
    local top,left
    pad=6
    top = config.top
    left = config.left
    x,y=left,top
    
    print("init")
    
    -- load default palette file if found
    local f = NESBuilder:findFile(NESBuilder:cfgGetValue("main", "defaultPaletteFile"), list(NESBuilder:cfgGetValue("main", "defaultPaletteFolder")))
    NESBuilder.palette.load(f)
    
    local buttonWidth = config.buttonWidth*7.5
    local buttonHeight = 27
    
--    local main = NESBuilder:getWindowQt()
--    main.tabParent.self.setTabsClosable(false)
--    main.update()
    
    NESBuilder:incLua("Tserial")
    util = NESBuilder:incLua("util")
    
    ipairs_sparse = util.ipairs_sparse
    
    -- make sure projects folder exists
    --NESBuilder:makeDir(data.folders.projects)
    
    statusBar=NESBuilder:makeLabelQt{x=x,y=y,text="Status bar"}
    statusBar.setFont("Verdana", 10)
    
    -- This dummy tab fixes an issue with create-on-demand tabs showing up
    -- blank if all other tabs are closed.
    -- We hide it at the end of this init()
    local dummyTab = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="dummy",text="dummy", showInList = false}
    
    if cfgGet('alphawarning')==1 then
        control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Warning",text="Warning"}
    end
    
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="tabLog",text="Log"}
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Launcher",text="Launcher"}
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Palette",text="Palette"}
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Image",text="CHR"}
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Symbols",text="Symbols"}
    
    local items
    -- The separator and Quit items will be added
    -- in onReady() so plugins can add items before them.
    items = {
        {name="New", text="\u{1f4c1} New Project"},
        {name="Open", text="\u{1f4c2} Open Project"},
        {name="Save", text="\u{1f4be} Save Project"},
        {name="SaveAs", text="\u{1f4be} Save As"},
        {name="Preferences", text="\u{2699}\u{fe0f} Preferences"},
    }
    control = NESBuilder:makeMenuQt{name="menuFile", text="File", menuItems=items}
    
    control = NESBuilder:makeMenuQt{name="menuEdit", text="Edit", menuItems={}}
    
    --control.control.setEnable(false)
    --local f = python.eval("lambda x: x[0]")
    --print(control)
    --print(f(control))
    
    items = {
        {name="Build", text="\u{27A0} Build"},
        {name="BuildTest", text="\u{27A0} Build and Test"},
        {name="TestRom", text="\u{27A5} Re-Test Last"},
    }
    control = NESBuilder:makeMenuQt{name="menuProject", text="Project", menuItems=items}
    
    if cfgGet('alphawarning')==1 then
        NESBuilder:setTabQt("Warning")
        x,y=left,top
        text=[[
        
        WARNING:
        
        This project is in alpha stage.  It's going well but 
        some things may be broken or unstable.  Make frequent
        backups.
        
        You can disable this warning tab in preferences.
        
            --SpiderDave
        
        ]]
        control=NESBuilder:makeLabelQt{x=x,y=y,text=text}
        control.setFont("Verdana",12)
        
        x=left+pad*8
        y = y + control.height + pad*8
        b=NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight,name="buttonWarningClose",text="close"}

    end
    
    local items = {}
    control = NESBuilder:makeMenuQt{name="menuView",text="View", menuItems=items}
    
    
    NESBuilder:setTabQt("tabLog")
    x,y = left, top
    control = NESBuilder:makeConsole{x=x,y=y,w=750,h=600,name="log", text=""}
    console = control
    local oldPrint = print
    print = function(...)
        oldPrint(...)
        console.print(NESBuilder:getPrintable(...))
    end
    handlePythonError = function(err, e)
        print(string.rep('-', 79))
        print(e)
        print(string.rep('-', 79))
        
        return true
    end
    handleLuaError = function(e)
        print(string.rep('-', 80))
        print("LuaError:\n")
        print(e)
        print()
        print(string.rep('-', 80))
        
        return true
    end
    
    
    --control=NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight,name="testError",text="Test"}
    
    NESBuilder:setTabQt("Image")
    x,y=config.left, config.top
    control=NESBuilder:makeCanvasQt{x=x,y=y,w=128,h=128,name="canvasQt", scale=3}
    control.helpText = "Click to select a tile"
    
    x=x+control.width
    y=y+control.height+pad
    
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=8,h=8,name="canvasTile", scale=10}
    control.helpText = "Left-click: apply color, right-click: select color"
    control.setCursor('pencil')
    
    -- right align it with the above canvas
    control.move(x-control.width,y)
    
    x=x-control.width
    y=y+control.height + pad
    local itemList = {
        "Cut",
        "Copy",
        "Paste",
        "\u{2194} Flip Tile Horizontally",
        "\u{2195} Flip Tile Vertically",
        "Shift Tile Up",
        "Shift Tile Down",
        "Shift Tile Left",
        "Shift Tile Right",
    }
    control = NESBuilder:makeMenuBox{x=x,y=y, name="buttonCanvasTileActions", text="actions \u{25bc}", itemList = itemList}
    control.helpText = "Tile actions"
    
    
    
    x,y = left,top
    
    NESBuilder:setTabQt("Palette")
    NESBuilder:setDirection("h")
    x,y=left,top
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    
    control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="PaletteQt", palette=getNESPalette(), upperHex=cfgGet('upperhex')}
    control.helpText = "Click to select a color"
    
    palette = {}
    for i=0,#p do
        palette[i] = getNESPalette()[p[i]]
    end
    
    placeX = left
    placeY = top
    
    x=left
    y=y+control.height+pad
    
    local buttonHeight = config.buttonHeight
    
    --control = NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="SpinChangePalette"}
    
    --x = left
    --y = y + control.height + pad
    
--    p = {[0]=0x0f,0x21,0x11,0x01}
--    palette = {}
--    for i=0,#p do
--        palette[i] = getNESPalette()[p[i]]
--    end
--    control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="PaletteEntryQt", palette=palette}
--    control.helpText = "Click to apply a color, right click to select a color"
    
    --push(y+control.height+pad)

--    x=x+control.width+pad
--    c=NESBuilder:makeLabelQt{x=x,y=y+pad,name="PaletteEntryLabelQt",clear=true,text="foobar"}
--    c.setFont("Verdana", 10)

--    x=left
--    y=pop()
    
--    for i=0,#p do
--        palette[i] = getNESPalette()[p[i]]
--    end
    
    y=y+pad
    
    local itemList = {
        "New",
        "Rename",
        "Delete",
        "Move Up",
        "Move Down",
        "Duplicate",
    }
    control = NESBuilder:makeMenuBox{x=x,y=y, name="paletteSetActions", text="actions \u{25bc}", itemList = itemList}
    control.helpText = "Palette set actions"
    y = y + control.height + pad
    
    control = NESBuilder:makeComboBox{x=x,y=y,w=400, name="paletteSet", itemList = {'set 0','set 1'}}
    control.helpText = "Select a palette set"
    y = y + control.height + pad
    
    x = left
    local scroll = NESBuilder:makeScrollFrame{x=x,y=y,w=400,h=400,name='scrollArea1'}
    NESBuilder:setContainer(scroll.frame)
    y=pad
    x=left
    
    paletteControl = {}
    for i = 0,15 do
        paletteControl[i] = {}
        
        c = NESBuilder:makeLabelQt{x=x,y=y+pad,clear=true, text=string.format('   %02x', i), name=string.format('paletteLabelLeft%02x', i),functionName = 'paletteLabelLeft', index=i}
        c.setFont("Verdana", 10)
        x = x + c.width + pad
        paletteControl[i].labelControlLeft = c
        
        control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name=string.format('Palette%02x',i), palette=palette}
        paletteControl[i].control = control
        paletteControl[i].index = i
        x = x + control.width + pad
        c = NESBuilder:makeLabelQt{x=x,y=y+pad,clear=true, text='00', name=string.format('paletteLabel%02x', i), functionName = 'paletteLabel', index=i}
        c.setFont("Verdana", 10)
        paletteControl[i].labelControl = c
        y=y + control.height
        x = left
        
        main[control.name..'_cmd'] = function(t)
            local f = main.Palette_cmd or Palette_cmd
            if f then return f(t, i) end
        end
    end
    
    if devMode() then
        NESBuilder:setTabQt("Palette")
        y = scroll.y() + scroll.height + pad
        x = left
        control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth,name="test",text="test"}
        y = y + control.height + pad
--        local control = pythonEval('QtDave.QComboBox')(NESBuilder:getTabQt())
--        control.move(x,y)
--        control.resize(buttonWidth, buttonHeight)
--        control.addItems(list('item 1', 'item 2', 'item 3'))
    end
    
    
    NESBuilder:setTabQt("Image")
    p = {[0]=0x0f,0x21,0x11,0x01}
    palette = {}
    for i=0,#p do
        palette[i] = getNESPalette()[p[i]]
    end

    x=pad
    y=pad+128*3+pad*1.5
    placeY = y
    c=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="CHRPalette", palette=palette}
    
    x=left + 120
    y=placeY
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall*7.5,name="ButtonPrevPaletteCHR",text="<"}

    x=x+b.width+pad
    y=placeY
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall*7.5,name="ButtonNextPaletteCHR",text=">"}

    x=left
    
    y = y + 32 + pad
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthNew,name="LoadCHRImage",text="Load Image"}

    y = y + b.height + pad
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthNew,name="LoadCHRNESmaker",text="Load NESmaker Image"}

    y = y + b.height + pad
    
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthNew,name="LoadCHR",text="Load .chr"}
    y = y + b.height + pad
    
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthNew,name="ExportCHR",text="Export"}
    y = y + b.height + pad
    
    if devMode() then
        b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthNew,name="test2",text="test"}
        y = y + b.height + pad
    end
    
    x=128*3+pad*3
    y=top
    c=NESBuilder:makeLabelQt{x=x,y=y,name="CHRNumLabel",clear=true,text="CHR"}
    y = y + buttonHeight
    
    --y=top
    x=128*3+pad*3
    
    --  Yes, we're cheating with Python here.
    local l = python.eval('["CHR {0:02n}".format(x) for x in range(8)]')
    
    local menu = {
        {name='add new', action = addCHR_cmd},
        {name='rename', action = notImplemented},
        {name='delete', action = delCHR},
    }
    control = NESBuilder:makeList{x=x,y=y,w=buttonWidth,h=buttonHeight*12, name="CHRList",list = l, contextMenuItems = menu}
    control.helpText = "left-click: Select a CHR set, right-click: context menu"
    push(y + control.height + pad, x)
    
    x=x + control.width + pad*.5
    b=NESBuilder:makeButton{x=x,y=y,w=30,name="addCHR",text="+"}
    
    x,y = pop(2)
    
    control = NESBuilder:makeLineEdit{x=x,y=y,w=control.width,h=inputHeight, name="CHRName"}
    y = y + control.height + pad
    
    NESBuilder:setTabQt("Symbols")
    left = config.left
    top = config.top
    x,y = left,top
    
    control = NESBuilder:makeTable{x=x,y=y,w=buttonWidth*5,h=buttonHeight*20, name="symbolsTable1",rows=100, columns=3}
    control.setHorizontalHeaderLabels("Symbol", "Value", "Comment")
    control.setColumnWidth(0,buttonWidth)
    control.setColumnWidth(1,buttonWidth)
    control.horizontalHeader().setStretchLastSection(true)
    y = y + control.height + pad
    
    NESBuilder:setTabQt("Launcher")
    x,y = left,top
    local startY
    
    control = NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, name="launcherRecentTitle",text="NESBuilder"}
    control.setFont("Verdana", 28)
    
    push(y+control.height+pad, x)
    
    x = x + control.width+pad
    y = y + pad*2
    control = NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, name="launcherProjectName", text="test"}
    control.setFont("Verdana", 14)
    x,y=pop(2)
    
    --y = y + control.height + pad
    push(y)
    
    control = NESBuilder:makeButton{x=x,y=y,w=190,h=64, name="launcherButtonRecent",text="Recent Projects", image="icons/clock32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=190,h=64, name="launcherButtonOpen",text="Open Project", image="icons/folder32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=190,h=64, name="launcherButtonNew",text="New Project", image="icons/folderplus32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=190,h=64, name="launcherButtonTemplates",text="Templates", image="icons/folder32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=190,h=64, name="launcherButtonPreferences",text="Preferences", image="icons/gear32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButton{x=x,y=y,w=190,h=64, name="launcherButtonInfo",text="About", image="icons/note32.png", iconMod=true}
    y = y + control.height + pad
    
    x=x+control.width+pad*2
    y=top
    startY=pop()
    
    data.launchFrames = {
        recent = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="frameRecentProjects"},
        open = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="frameOpenProjects"},
        new = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="frameNewProject"},
        templates = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="frameTemplates"},
        pref = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="framePreferences"},
        about = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name="frameAbout"},
        set = function(f)
            for k,v in pairs(data.launchFrames) do
                if k == "set" then
                elseif k == f then
                    v.show()
                else
                    v.hide()
                end
            end
        end,
    }
    
    NESBuilder:setContainer(data.launchFrames.recent)
    
    local columns = 3
    local rows = 4
    local iconWidth = 180
    recentData = {}
    
    for i = 1, config.nRecentFiles do
        recentData[i-1]={}
        x = ((i-1) % columns)*(iconWidth+15) + pad
        y = math.floor((i-1)/columns)*130
        
        control = NESBuilder:makeLauncherIcon{x=x,y=y,h=120, w=iconWidth, name="launcherRecentIcon", index=i-1}
        recentData[i-1].icon = control
        
        y=y+control.height-25
        control = NESBuilder:makeLabelQt{x=x,y=y, name="launcherRecentLabel",text="", class="launcherText"}
        control.width = iconWidth
        control.height=20
        
        recentData[i-1].label = control
    end
    
    NESBuilder:setContainer(data.launchFrames.new)
    for i, item in ipairs(data.projectTypes) do
        --recentData[i-1]={}
        x = ((i-1) % columns)*(iconWidth+15) + pad
        y = math.floor((i-1)/columns)*130
        
        control = NESBuilder:makeLauncherIcon{x=x,y=y,h=120, w=iconWidth, name="launcherProjectType", index=i-1}
        control.helpText = item.helpText

        y=y+control.height-25
        control = NESBuilder:makeLabelQt{x=x,y=y, name="launcherRecentLabel", text=item.text, class="launcherText"}
        control.width = iconWidth
        control.height=20
    end
    
    
    NESBuilder:setContainer(data.launchFrames.templates)
    
    local i = 1
    local baseFilename
    local name
    for f in python.iter(NESBuilder:files(data.folders.templates..'*.template.zip')) do
        baseFilename = pathSplit(f)[1]
        name = nil
        local templateConfig = NESBuilder:getTextFromArchive(f, 'template.ini')
        if templateConfig then
            name = NESBuilder:parseTemplateData(templateConfig, 'main', 'name')
        end
        if not name then
            name = pathSplit(f)[1]
            name = rsplit(name, '.template.zip')[0]
        end
        
        x = ((i-1) % columns)*(iconWidth+15) + pad
        y = math.floor((i-1)/columns)*130
        
        control = NESBuilder:makeButton{x=x,y=y,w=iconWidth, h=120, name="launcherTemplate",text=name, index=i-1, class="templateButton", filename=baseFilename}
        --control.setIconFromArchive(data.folders.templates..'smb.template.zip', 'templateicon.png')
        control.setIconFromArchive(f, 'templateicon.png')
        
        if templateConfig then
            control.helpText = NESBuilder:parseTemplateData(templateConfig, 'main', 'helptext')
        end

        --control.helpText = item.helpText

        y=y+control.height-25
        i=i+1
    end

    NESBuilder:makeTab{name="Metatiles", text="Metatiles"}
    NESBuilder:setTabQt("Metatiles")
    
    x,y=left,top
    
    push(y)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=128,h=128,name="tsaCanvasQt", scale=2}
    control.helpText = "Click to select a tile"
    push(x+control.width+pad)
    
    x = left
    y=y + control.height + pad
    
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=8,h=8,name="tsaTileCanvasQt", scale=8, columns=1, rows=1}
    control.helpText = "Selected tile"
    y=y + control.height + pad
    
    x = pop()
    y = pop()
    
    push(y)
    local menu = {
        {name='add new', action = addMTileSet},
        {name='rename', action = renameMTileSet},
    }
    control = NESBuilder:makeList{x=x,y=y,w=buttonWidth,h=buttonHeight*12, name="mTileList", list = list(), contextMenuItems = menu}
    control.helpText = "left-click: Select a metatile set, right-click: context menu"
    y = y + control.height + pad
    
    local newX = x + control.width + pad
    
    control = NESBuilder:makeLabelQt{x=x,y=y, clear=true, text="Address:"}
    control.setFont("Verdana", 11)
    push(x)
    x = x + control.width + pad
    
    control = NESBuilder:makeLineEdit{x=x,y=y,w=buttonWidth/2,h=inputHeight, name="MTileAddress"}
    control.helpText = "Address for metatile set (optional)"
    y = y + control.height + pad
    
    x = pop()
    --control = NESBuilder:makeCheckbox{x=x,y=y,name="mTileIncludePointers", text="Include pointers", value=bool(0)}
    control = NESBuilder:makeCheckbox{x=x,y=y,name="mTileIncludePointers", text="Include pointers"}
    control.helpText="Include a table of pointers to metatiles for this set"
    
    data.mTileTypes = {}
    y = y + control.height + pad
    control = NESBuilder:makeComboBox{x=x,y=y,w=buttonWidth, name="mTileTypeList"}
    control.helpText="metatile type."
    
    y = pop()
    x = newX
    
    push(x)
    
    push(y)
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall*7.5, name="metatilePrev",text="<"}
    control.helpText = "Previous metatile"
    y=pop()
    x = x + control.width+pad
    
    push(y)
    control=NESBuilder:makeLineEdit{x=x,y=y,w=24,h=buttonHeight, name="metatileNumber",text="0"}
    control.helpText = "Current metatile index"
    y=pop()
    x= x + control.width+pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall*7.5, name="metatileNext",text=">"}
    control.helpText = "Next metatile"
    
    y = y + control.height + pad
    
    x=pop()
    
    push(x)
    
    control = NESBuilder:makeNumberEdit{x=x,y=y,w=config.buttonWidthSmall*7.5,h=inputHeight, name="metatileW", value = 2}
    control.helpText = "Metatile width"
    x = x + control.width + pad
    control = NESBuilder:makeNumberEdit{x=x,y=y,w=config.buttonWidthSmall*7.5,h=inputHeight, name="metatileH", value = 2}
    control.helpText = "Metatile height"
    
    x=x+control.width+pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall*7.5, name="metatileNew",text="Set"}
    control.helpText = "Create a new metatile (WIP)"
    
    y = y + control.height + pad
    
    x=pop()
    
    
    control = NESBuilder:makeLabelQt{x=x,y=y, name="metatileName", text="name"}
    control.helpText = "Metatile name.  Left-click: Edit"
    control.setFont("Verdana", 10)
    control.autoSize = false
    control.width = buttonWidth * 2
--    control.height=20
    
    y = y + control.height + pad
    
    
    control = NESBuilder:makeLabelQt{x=x,y=y, name="metatileOffset", text="offset: (0, 0)"}
    control.setFont("Verdana", 10)
    control.autoSize = false
    control.width = buttonWidth * 2
    
    y = y + control.height + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall*7.5*3, name="metatileOffsetTest",text="set offset"}
    control.helpText = "Toggle Offset mode"
    
    y = y + control.height + pad
    
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=16,h=16,name="tsaCanvas2Qt", scale=6}
    control.helpText = "Left-click: apply tile, right-click: select tile"
    y = y + control.height + pad
    --x = x + control.width + pad
    
    ppInit()
    createAboutTab()
    
    data.launchFrames.set('recent')
    
    loadSettings()

    local tabParent = NESBuilder:getWindowQt().tabParent
    tabParent.setTabVisible(tabParent.indexOf(dummyTab), false)
end

function onPluginsLoaded()
    handlePluginCallback("onInit")
    handlePluginCallback("onRegisterAssembler")
    
    getControl('mTileTypeList').clear()
    local control = getControl('mTileTypeList')
    control.addItem('(none)')
    for k, v in iterItems(data.mTileTypes) do
        control.addItem(v.name)
    end
end

function addMTileType(t)
    data.mTileTypes[t.name] = t

    getControl('mTileTypeList').clear()
    local control = getControl('mTileTypeList')
    control.addItem('(none)')
    for k, v in iterItems(data.mTileTypes) do
        control.addItem(v.name)
    end

end
function removeMTileType(n)
    data.mTileTypes[n] = nil


    getControl('mTileTypeList').clear()
    local control = getControl('mTileTypeList')
    control.addItem('(none)')
    for k, v in iterItems(data.mTileTypes) do
        control.addItem(v.name)
    end


end

function onReady()
    local k, control
    local items = {}
    
    -- add recent files
    items[#items+1] = {text="-"}
    for i,v in python.enumerate(reverseList(recentProjects.asList())) do
        k = string.format("recentproject%d", i+1)
        
        items[#items+1] = {name = k, text = v, index = i, action = function() recentproject_cmd({index=i}) end}
        if i >= config.nRecentFiles_menu then break end
    end
    
    items[#items+1] = {text="-"}
    items[#items+1] = {name="Quit", text="\u{274e} Exit"}
    
    control = NESBuilder:makeMenuQt{name="menuFile", text="File", menuItems=items}
    
    local items = {
        {text="-"},
        {name="openProjectFolder", text="\u{1f4c2} Open Project Folder"},
        {name="projectProperties", text="\u{2699} Project Properties"},
    }
    control = NESBuilder:makeMenuQt{name="menuProject", text="Project", menuItems=items}
    
    local items = {
        {name="importAllChr", text="\u{1f4c4}\u{20d6}  Import all CHR from .nes"},
        {name="exportAllChr", text="\u{1f4c4}\u{20d7}  Export all CHR to .nes"},
        {name="importMultiChr", text="\u{1f4c4}\u{20d6}  Import all CHR from .chr"},
    }
    
    control = NESBuilder:makeMenuQt{name="menuTools",text="Tools", menuItems=items}
    
    local items = {
        {name="About", text="\u{2753} About"},
    }
    control = NESBuilder:makeMenuQt{name="menuHelp", text="Help", menuItems=items}
    
    local items = {}
    local control = NESBuilder:getWindowQt()
    for k, v in iterItems(control.tabs) do
        table.insert(items, {name=k, text=v.title, action = function() toggleTab(k, nil, true) end, checked = true})
    end
    control = NESBuilder:makeMenuQt{name="menuView",text="View", menuItems=items}
    
    handlePluginCallback("onReady")
    LoadProject()
    
    
    if cfgGet('autosave')==1 then
        local main = NESBuilder:getWindowQt()
        -- minimum auto save interval is 45 seconds
        main.setTimer(math.max(cfgGet('autosaveinterval'), 1000*45), autoSave, true)
    end
    
    if getControl(data.project.savedTab) then
        NESBuilder:switchTab(data.project.savedTab)
    else
        NESBuilder:switchTab("Launcher")
    end
end

function toggleTab(n, visible, switchTo)
    local control = NESBuilder:getWindowQt()
    local tab = control.getTab(n)
    
    if not tab then return end
    
    if visible~=true and visible~=false then
        visible = control.tabParent.isTabVisible(control.tabParent.indexOf(tab))
    else
        visible = not visible
    end
    if visible then
        control.menus['menuView'].actions[n].setChecked(false)
        control.tabParent.removeTab(control.tabParent.indexOf(tab))
    else
        control.menus['menuView'].actions[n].setChecked(true)
        
        if control.tabParent.isTabVisible(control.tabParent.indexOf(tab)) then
            -- already visible, no need to add
        else
            control.tabParent.insertTab(tab.index, tab, tab.title)
        end
        
        if switchTo then NESBuilder:switchTab(n) end
    end
end

function handlePluginCallback(f, arg)
    local keys={}
    for k,v in pairs(plugins or {}) do
        table.insert(keys,k)
    end
    table.sort(keys)
    
    for _,n in pairs(keys) do
        _getPlugin = function() return plugins[n] end
        if plugins[n][f] then
            if not plugins[n].hide then
                print(string.format("(Plugin %s): %s",n,f))
                if type(arg) == 'table' then
                    plugins[n][f](table.unpack(arg))
                else
                    plugins[n][f](arg)
                end
            end
        end
    end
end

function loadSettings()
    data.projectID = NESBuilder:cfgGetValue("main", "project", data.projectID)
    
    
    local dupCheck = {}
    
    -- load recent projects list
    local k,v
    for i=1, config.nRecentFiles do
        k = string.format("recentproject%d", i)
        v = NESBuilder:cfgGetValue("main", k, false)
        if not v then break end
        if not dupCheck[v] then
            recentProjects.push(v)
            dupCheck[v] = true
        end
    end
end

function saveSettings()
    local k
    NESBuilder:cfgSetValue("main", "project", data.projectID)

    -- save recent projects list
    for i,v in python.enumerate(recentProjects.asList()) do
        k = string.format("recentproject%d", i+1)
        NESBuilder:cfgSetValue("main", k,v)
    end
end

function doCommand(t)
    if type(t) == 'string' then
        print("**** doCommand "..t)
    else
        if t.anonymous then return false end
        
        local functionName = t.functionName or t.name or false
        
        pcall(function()
            t.event.button = t.event.event.button()
        end)
        
        if not t.anonymous then
            print("doCommand "..functionName)
        end
        if functionName then
            if t.plugin then
                if t.plugin[functionName.."_cmd"] then
                    t.plugin[functionName.."_cmd"](t)
                    return false
                end
            elseif functionName then
                if main[functionName.."_cmd"] then
                    main[functionName.."_cmd"](t)
                    return false
                end
            end
        end
    end
    return true
end

function PaletteQt_cmd(t)
    local event = t.cell.event
    
    
    local badColor = {}
    for _,v in pairs({0x0d,0x0e,0x1d,0x1e,0x1f,0x2e,0x2f,0x3e,0x3f}) do
        badColor[v] = 0x0f
    end
    
    if event.button == 1 or event.button == 2 then
        data.selectedColor = badColor[t.cellNum] or t.cellNum
        print(string.format("Selected palette %02x", data.selectedColor))
    end
end

function CHRPalette_cmd(t)
    local event = t.cell.event
    local p = currentPalette()
    if event.button == 1 then
        data.selectedColor = p[t.cellNum+1]
        data.selectedColorIndex = t.cellNum
        print(string.format("Selected palette %02x",data.selectedColor))
        
        --data.drawColorIndex = t.cellNum
--    elseif t.event.button == 3 then
--        print(string.format("Set palette %02x",data.selectedColor or 0x0f))
--        if t.set(t.cellNum, data.selectedColor) then
--            refreshCHR()
--            dataChanged()
--        end
    end
end

function ButtonMakeCHR_cmd()
    local f = NESBuilder:openFile{filetypes={{"Images", ".png"}}}
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        f2 = NESBuilder:saveFileAs{filetypes={{"CHR", ".chr"}},'output.chr'}
        if f2 == "" then
            print("Save cancelled.")
        else
            print("file: "..f2)
            NESBuilder:imageToCHR(f,f2,NESBuilder:getNESColors('0f211101'))
        end
    end
end

function test2_cmd()
    --print(data.project.chr.index)
    
    local font = pythonEval('QtDave.QFontDialog').getFont()
    font.setStyleStrategy(pythonEval('QtDave.QFont.NoAntialias'))
    --getControl('canvasQt').testText(font)
    --getControl('canvasQt').testText()
    
    
    -- create a surface
    local surface = NESBuilder:makeNESPixmap(128,128)
    
    -- load blank chr
    --surface.loadCHR()
    
    -- load current chr data
    surface.loadCHR(getChrData())
    
    local args = {text='Title', color=list(0,255,0), font=font}
    pythonEval('lambda x, y:x(**y)')(surface.testText, args)
    
    -- get chr data and store in selected project bank
    local chr = surface.loadCHRFromImage(surface.toImage(), NESBuilder:getNESmakerColors())
    
    local control = NESBuilder:getControl("canvasQt")
    
    -- apply current palette to it
    surface.applyPalette(currentPalette())
    
    -- paste the surface on our canvas (it will be sized to fit)
    control.paste(surface)
    
    setChrData(chr)
    --refreshCHR()
end

function test_cmd()
    --print(NESBuilder:folders(data.folders.projects))
    
--    local control = pythonEval('QtDave.QComboBox')(NESBuilder:getTabQt())
--    control.move(x,y)
--    control.resize(buttonWidth, buttonHeight)
--    control.addItems(list('item 1', 'item 2', 'item 3'))

    --print(pythonEval('QtDave.QFontDialog').getFont())
    
    --getControl('canvasQt').create_text{10,10,fill="darkblue",font="Times 20 italic bold", text="text!"}
    --getControl('canvasQt').testText()
end


function loadPaletteFile(f)
    if f then
        f = NESBuilder:findFile(f, list(NESBuilder:cfgGetValue("main", "defaultPaletteFolder")))
        if not f then
            print("File not found: "..f)
            return
        end
    else
        print(NESBuilder:cfgGetValue("main", "defaultPaletteFolder"))
        f = NESBuilder:openFile{filetypes={{"Palette files", ".pal"}}, initial=NESBuilder:cfgGetValue("main", "defaultPaletteFolder")}
        if f == "" then
            print("Open cancelled.")
            return
        end
    end
    
    print("file: "..f)

    NESBuilder.palette.load(f)
    
    -- update main palette control
    getControl('PaletteQt').setAll(pythonEval("list(range(0x3f))"))
    -- update palette sets
    updatePaletteSets()
    -- update selected palette control
    PaletteEntryUpdate()
    -- update metatile image
    updateSquareoid()
    
    -- update selected tile in metatiles tab
    if data.selectedTile then
        local control = getControl('tsaTileCanvasQt')
        control.drawTile(0,0, data.selectedTile, currentChr(), currentPalette(), control.columns, control.rows)
        control.update()
    end
end

function Palette_cmd(t, index)
    if not t.cell then return end -- border clicked
    
    local event = t.cell.event
    local p
    local topIndex = 0
    
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    if not pSet then return end
    
    if event.button == 2 then
        data.selectedColor = pSet.palettes[index+1][t.cellNum+1]
        print(string.format('pSet=%s, index=%02x, cell=%02x, selected color=%02x',pSet.name or '', index, t.cellNum, data.selectedColor))
    elseif event.button == 1 then
        if index>#pSet.palettes then return end
        local oldColor
        if not pSet.palettes[index+1] then
            pSet.palettes[index+1] = {0x0f, 0x0f, 0x0f, 0x0f}
        else
            oldColor = pSet.palettes[index+1][t.cellNum+1]
        end
        print(index)
        print(#pSet.palettes)
        local newColor = data.selectedColor or 0x0f
        
        if oldColor ~= newColor then
            print(string.format('pSet=%s, index=%02x, cell=%02x, newColor=%02x',pSet.name or '', index, t.cellNum, newColor))
            pSet.palettes[index+1][t.cellNum+1] = newColor
            t.setAll(pSet.palettes[index+1])
            dataChanged()
            
            -- if changing currently selected palette,
            -- do an update
            if index == pSet.index then
                PaletteEntryUpdate()
            end
        end
    end
    updatePaletteLabels()
end


function paletteLabel_cmd(t)
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    
    local n = askText('Palette Description', 'Enter a description for the palette.', pSet.palettesDesc[t.index] or '')
    print(n)
    if n then
        if n == '' then n = nil end
        data.project.paletteSets[data.project.paletteSets.index+1].palettesDesc[t.index] = n
        paletteControl[t.index].labelControl.setText(pSet.palettesDesc[t.index] or '---')
    end
end

function paletteLabelLeft_cmd(t)
    local event = t.control.event
    
    if event.type == 'ButtonPress' and event.button == 1 then
        local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
        if t.index == #pSet.palettes then
            pSet.palettes[t.index+1] = {0x0f, 0x0f, 0x0f, 0x0f}
            
            paletteControl[t.index].control.setAll(pSet.palettes[t.index+1])
            dataChanged()
        end
        data.project.paletteSets.selectedIndex = t.index
        updatePaletteLabels()
        
        pSet.index = t.index
        
        PaletteEntryUpdate()
    end


--        local pSet = {
--          name = n,
--          palettes = {
--          },
--          index = 0,
--        }
--        data.project.paletteSets[#data.project.paletteSets+1] = pSet
--        updatePaletteSets(#data.project.paletteSets-1)


end

function updatePaletteLabels()
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1] or {index=0, palettes={}}
    
    local selectedIndex = pSet.index
    
    for i = 0, #paletteControl do
        if i == #pSet.palettes then
            paletteControl[i].labelControlLeft.setText('    +')
            paletteControl[i].labelControlLeft.helpText = 'Click to add a palette'
        elseif i > #pSet.palettes then
            paletteControl[i].labelControlLeft.setText('')
        elseif i == selectedIndex then
            paletteControl[i].control.highlight(true)
            paletteControl[i].labelControlLeft.setText(string.format('\u{1f449} %02x ', i ))
            paletteControl[i].labelControlLeft.helpText = ''
        else
            paletteControl[i].control.highlight(false)
            paletteControl[i].labelControlLeft.setText(string.format('   %02x', i ))
            paletteControl[i].labelControlLeft.helpText = 'Click to select palette'
        end
    end
end

function PaletteEntryUpdate()
    getControl('CHRPalette').setAll(currentPalette())
    updatePaletteLabels()
    handlePluginCallback("onPaletteChange")
    refreshCHR()
end

function paletteSetActions_cmd(t)
    local action = t.itemList[t.control.index+1]
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    print(action)
    
    if action == "New" then
        local n = askText('New Palette Set', 'Enter a name for the palette set.', string.format("palette set test %02x", #data.project.paletteSets))
        if not n then return end
        local pSet = {
          name = n,
          palettes = {},
          palettesDesc = {},
          index = 0,
        }
        data.project.paletteSets[#data.project.paletteSets+1] = pSet
        updatePaletteSets(#data.project.paletteSets-1)
        return
    elseif action == "Rename" then
        if not pSet then return end
        local n = askText('Rename Palette Set', 'Enter a new name for the palette set.', pSet.name)
        if not n then return end
        data.project.paletteSets[data.project.paletteSets.index+1].name = n
    elseif action == "Delete" then
        if not pSet then return end
        if NESBuilder:askYesNoCancel("Delete palette set", string.format('Are you sure you want to delete palette set\n"%s"?', pSet.name)) then
            table.remove(data.project.paletteSets, data.project.paletteSets.index+1)
            if (data.project.paletteSets.index > 0) and (data.project.paletteSets.index == #data.project.paletteSets) then
                data.project.paletteSets.index = #data.project.paletteSets - 1
            end
        else
            return
        end
    elseif action == "Move Up" then
        if not pSet then return end
        local index = data.project.paletteSets.index
        if (index == 0) then return end
        data.project.paletteSets[index], data.project.paletteSets[index+1] = data.project.paletteSets[index+1], data.project.paletteSets[index]
        data.project.paletteSets.index = index - 1
    elseif action == "Move Down" then
        if not pSet then return end
        local index = data.project.paletteSets.index
        if (index+1 >= #data.project.paletteSets) then return end
        
        data.project.paletteSets[index+2], data.project.paletteSets[index+1] = data.project.paletteSets[index+1], data.project.paletteSets[index+2]
        data.project.paletteSets.index = index + 1
    elseif action == "Duplicate" then
        if not pSet then return end
        
        local n = askText('New Palette Set', 'Enter a name for the palette set.', pSet.name .. ' copy')
        if not n then return end
        data.project.paletteSets[#data.project.paletteSets+1] = util.deepCopy(pSet)
        updatePaletteSets(#data.project.paletteSets-1)
        return
    end
    updatePaletteSets()
end

function paletteSet_cmd(t)
    if data.project.paletteSets.index == t.control.currentIndex() then return end
    
    data.project.paletteSets.index = t.control.currentIndex()
    paletteListUpdate()
    PaletteEntryUpdate()
end

-- update the palette sets dropdown
function updatePaletteSets(index)
    local control
    index = index or data.project.paletteSets.index
    
    control = getControl('paletteSet')
    control.clear()
    for i, item in ipairs(data.project.paletteSets) do
        control.addItem(item.text or item.name)
    end
    
    control.setCurrentIndex(index)
    data.project.paletteSets.index = index
    paletteListUpdate()
end

function paletteListUpdate()
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    
    for i = 0, #paletteControl do
        v = paletteControl[i]
        c = v.control
        
        if pSet and pSet.palettes[i+1] then
            c.setAll(pSet.palettes[i+1])
            v.labelControl.setText(pSet.palettesDesc[i] or '---')
        else
            c.setAll({[0]=0x0f,0x0f,0x0f,0x0f})
            c.clear()
            v.labelControl.setText('')
        end
    end
    
--    local control = getControl('SpinChangePalette')
--    control.max = #pSet.palettes
--    control.value = pSet.index
--    control.refresh()
    
    updatePaletteLabels()
end

--function SpinChangePalette_cmd(t)
--    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    
--    data.project.paletteSets[data.project.paletteSets.index+1].index = t.control.value
--    PaletteEntryUpdate()
--end

function ButtonPrevPalette_cmd()
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    local i = pSet.index-1
    if i<0 then i = 0 end
    if i > #pSet.palettes-1 then i = #pSet.palettes-1 end
    data.project.paletteSets[data.project.paletteSets.index+1].index = i
    PaletteEntryUpdate()
end

function ButtonNextPalette_cmd(t)
    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
    local i = pSet.index+1
    if i<0 then i = 0 end
    if i > #pSet.palettes-1 then i = #pSet.palettes-1 end
    data.project.paletteSets[data.project.paletteSets.index+1].index = i
    PaletteEntryUpdate()
end

ButtonPrevPaletteCHR_cmd = ButtonPrevPalette_cmd
ButtonNextPaletteCHR_cmd = ButtonNextPalette_cmd

function ButtonLevelExtract_cmd()
    local f = NESBuilder:openFile{filetypes={{"NES rom", ".nes"}}}
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        f2 = NESBuilder:saveFileAs({{"ASM", ".asm"}},'output.asm')
        if f2 == "" then
            print("Save cancelled.")
        else
            print("file: "..f2)
            SMBLevelExtract(f,f2)
        end
    end
end

function dataChanged(changed)
    if changed == false then
        data.project.changed = false
    else
        data.project.changed = true
    end
    updateTitle()
end

function updateTitle()
    changed = data.project.changed and "*" or ""
    
    NESBuilder:setTitle(string.format("%s - %s%s", config.title, data.projectID, changed))
    local control = NESBuilder:getControl('launcherProjectName')
    control.setText(data.projectID)
end

function NewProject_cmd()
    if data.project.changed then
        q= NESBuilder:askYesNoCancel("", string.format("Save changes to %s?",data.projectID))
        
        -- cancel
        if q==nil then return end
        
        if q==true then
            SaveProject()
        end
    end

    n = askText("New Project", "Please enter a name for the project")
    if (not n) or n=='' then
        print('cancelled')
        return
    end
    
    
    if devMode() then
        -- Currently, must start with letter or number, and can contain 
        -- letters, numbers, underscore, dash, space
        if not NESBuilder:regexMatch("^[A-Za-z0-9]+[ A-Za-z0-9_-]*$",n) then
            NESBuilder:showError("Error", string.format('Invalid project name: "%s"',n))
            return
        end
    else
        -- Currently, must start with letter or number, and can contain 
        -- letters, numbers, underscore, dash
        if not NESBuilder:regexMatch("^[A-Za-z0-9]+[A-Za-z0-9_-]*$",n) then
            NESBuilder:showError("Error", string.format('Invalid project name: "%s"',n))
            return
        end
    end
    
    -- check if the project folder already exists
    f = data.folders.projects..n
    if NESBuilder:pathExists(f) then
         local q= NESBuilder:askYesNoCancel("", string.format('The project folder "%s" already exists.  Load it instead?', n))
         -- cancel
        if q==nil then return end
        
        -- no
        if q==false then return end

        -- yes
        data.projectID = n
        LoadProject()
        return
    end
    
    print(string.format('Creating new project "%s"',n))
    data.projectID = n
    LoadProject()
    
    -- wipe the project rom, regardless of project type
    data.project.rom = {}
    
    if data.project.type == "romhack" then
        loadRom()
        importAllChr()
    end
end

function ppLoadRom_cmd() loadRom() end

function notImplemented()
    NESBuilder:showError("Error", "Not yet implemented.")
end

function Cut_cmd() notImplemented() end
function Copy_cmd() notImplemented() end
function Paste_cmd() notImplemented() end

function launcherButtonOpen_cmd() Open_cmd() end
function launcherButtonNew_cmd()
    data.launchFrames.set('new')
end
function launcherButtonRecent_cmd()
    data.launchFrames.set('recent')
end
function launcherButtonTemplates_cmd()
    toggleTab('Launcher', true, true)
    data.launchFrames.set('templates')
end

function launcherTemplate_cmd(t)
    loadTemplate(t.filename)
end

function launcherProjectType_cmd(t)
    data.projectType = data.projectTypes[t.index+1].name
    if (data.projectType == "dev") or (data.projectType == "romhack") then
        NewProject_cmd()
    end
end

function doTemplateActions()
    local k,v
    for action in python.iter(getTemplateData('actions')) do
        k=action[0]
        v=action[1] or ''

        if k == "loadRom" then
            -- wipe rom data here to make sure 
            -- we're loading fresh when prompted.
            data.project.rom = {}
            loadRom()
        end
        if k == "showInfo" then 
            NESBuilder:showInfo(v.title or "Info", v)
        end
        if k == "importCHR" then 
            importAllChr() 
        end
        handlePluginCallback("onTemplateAction", {k, v})
    end
    
    handlePluginCallback("onTemplateInit")
end


function ppInit()
    local x,y,left,top,pad,control
    pad = config.pad
    left = config.left
    top = config.top
    x,y = left,top
    local buttonWidth = config.buttonWidth*7.5
    local buttonHeight = 27
    
    -- Project Properties
    NESBuilder:makeTab{name="tabProjectProperties",text="Project Properties"}
    setTab("tabProjectProperties")
    
    local items = {
        {'main', 'Main'},
        {'plugins', 'Plugins'},
    }
    
    for i,v in ipairs(items) do
        control = NESBuilder:makeButton{x=x,y=y,w=buttonWidth, text=v[2], name="ppSwitchFrame", functionName = 'ppSwitchFrame', value=v[1]}
        x = x + control.width + pad
    end
    x = x + pad * 2
    NESBuilder:makeButton{x=x,y=y,w=buttonWidthSmall,h=buttonHeight,name="ppClose",text="close"}
    
    y = y + control.height + pad
    
    x=left
    local startY = y
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
    
    main.ppFrames = {
        set = setFrame,
    }
    for i,v in ipairs(items) do
        main.ppFrames[v[1]] = NESBuilder:makeFrame{x=x,y=startY,w=buttonWidth*5,h=config.height, name=v[1]}
    end
    
    NESBuilder:setContainer(main.ppFrames['main'])
    main.ppFrames:set('main')
    x,y = left,top
    
    control = NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight, name="ppLoadRom",text="Load ROM"}
    x = x + control.width + pad
    push(y + control.height + pad)
    control = NESBuilder:makeLabelQt{x=x,y=y, name = "ppRomFile", clear=true, text="filename"}
    control.setFont("Verdana", 10)
    
    x=left
    y=pop()

    control = NESBuilder:makeCheckbox{x=x,y=y,name="ppRomDataInc", text="Save ROM data with project", value=bool(data.project.incRomData)}
    y = y + control.height + pad
    
    control = NESBuilder:makeLabelQt{x=x,y=y, clear=true, text="Assembler"}
    control.setFont("Verdana", 10)
    push(x)
    x = x + control.width + pad
    --data.assemblers = {'sdasm','asm6','xkasplus'}
    
    f = data.folders.tools..'bB/2600basic.exe'
    if NESBuilder:fileExists(f) then
        table.insert(data.assemblers, 'bB')
    end
    
    control = NESBuilder:makeComboBox{x=x,y=y,w=buttonWidth, name="ppAssembler", text="Test", itemList = {}}
    y = y + control.height + pad
    x=pop()

    control.setByText(data.project.assembler)
    
    control = NESBuilder:makeTable{x=x,y=y,w=buttonWidth*5,h=buttonHeight*5, name="ppSettingsTable", rows=30, columns=3}
    control.setHorizontalHeaderLabels("Setting", "Value", "Comment")
    control.setColumnWidth(0,buttonWidth)
    control.setColumnWidth(1,buttonWidth)
    control.horizontalHeader().setStretchLastSection(true)
    
    control.onChange = function() ppUpdate() end
    
    y = y + control.height + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight, name="ppLoadIPS",text="Load IPS Patch"}
    y = y + control.height + pad
    
    control = NESBuilder:makeTable{x=x,y=y,w=buttonWidth*5,h=buttonHeight*5, name="patchesTable",rows=30, columns=1}
    control.setHorizontalHeaderLabels("IPS patches")
    local header = control.horizontalHeader()
    header.setStretchLastSection(true)
    
    y = y + control.height + pad
    
    
    NESBuilder:setContainer(main.ppFrames['plugins'])
    x,y = left, top
    
    control=NESBuilder:makeLabelQt{x=x,y=y, clear=true,text="Select which plugins will be available for this project."}
    control.setFont("Verdana", 10)
    y = y + control.height + pad*2
    
    push(x)
    for file in python.iter(pluginsList()) do
        if cfgGet('plugins', file) == 1 then
            control = NESBuilder:makeCheckbox{x=x,y=y,name='ppPlugin_'.. replace(replace(file, '.','_'), '_lua', ''), text=file, value=1, file=file, functionName='ppEnablePlugin'}
            y = y + control.height + pad
        end
    end
    x=pop()
end

function ppLoad()
    local control, i
    
    control = getControl('ppAssembler')
    control.itemList = data.assemblers
    control.clear()
    
    for i, item in ipairs_sparse(data.assemblers) do
        control.addItem(item)
    end
    
    control.setByText(data.project.assembler)
    
    control = getControl('ppRomFile')
    control.setText(data.project.rom.filename)
    
    -- todo: migrate to project.properties table?
    control = getControl('ppRomDataInc')
    control.setChecked(bool(data.project.incRomData))
    
    control = getControl('ppSettingsTable')
    
    i = 0
    for _,row in pairs(data.project.properties) do
        if row ~= {} and row.k and strip(row.k) ~= '' then
            control.set(i,0,row.k)
            control.set(i,1,row.v)
            control.set(i,2,row.comment)
            i=i+1
        end
    end
    ppUpdate()
    
    control = getControl('patchesTable')
    control.clear()
    for i,f in ipairs_sparse(data.project.patches) do
        control.set(i,0,f)
    end
    
    local pluginName,n,value
    for file in python.iter(pluginsList()) do
        pluginName = getPluginNameFromFile(file)
        if pluginName then
            n = 'ppPlugin_'.. replace(replace(file, '.','_'), '_lua', '')
            value = data.project.plugins[pluginName]
            if value == nil then
                if plugins[pluginName].default == true then
                    -- Plugin indicates it should default to on
                    value = 1
                elseif plugins[pluginName].default == false then
                    -- Plugin indicates it should default to off
                    value = 0
                else
                    -- Default value for plugin that doesn't specify
                    value = 1
                end
            else
                -- Use saved value from project properties
                value = boolNumber(value)
            end
            if value == 0 then
                -- need this so the callbacks won't run
                hidePlugin(pluginName)
            end
            
            control = getControl(n)
            if control then
                control.setChecked(value)
                control.setText(pluginName)
            end
        end
    end
    
    handlePluginCallback("onRegisterMTileType")
    
    print('ppLoad()')
end


function ppSwitchFrame_cmd(t)
    local control = t.control or t
    
    if control.value == '' then return end
    print(control.value)
    
    main.ppFrames:set(control.value)
end


function projectProperties_cmd()
    toggleTab('tabProjectProperties', true)
    NESBuilder:switchTab("tabProjectProperties")
end

function ppSettingsTable_cmd(t)
    data.project.properties = {}
    for i, row in python.enumerate(t.control.getData()) do
        k,v,comment = row[0],row[1],row[2]
        if k~='' then
            data.project.properties[i] = {k=k,v=v,comment=comment}
        end
    end
end

function ppRomDataInc_cmd(t)
    data.project.incRomData = t.isChecked()
end

function getPluginNameFromFile(filename)
    for k,v in pairs(plugins) do
        if v.file == filename then
            return k
        end
    end
end

function ppEnablePlugin_cmd(t)
    local n = getPluginNameFromFile(t.file)
    print(t.isChecked())
    
    if t.isChecked() == true then
        showPlugin(n)
        data.project.plugins[n] = true
    else
        hidePlugin(n)
        data.project.plugins[n] = false
    end
end

function launcherButtonPreferences_cmd()
    local x,y,left,top,pad,control
    pad = config.pad
    left = config.left
    top = config.top
    x,y = left,top


--    NESBuilder:makeWindow{x=0,y=0,w=760,h=600, name="prefWindow",title="Preferences"}
--    NESBuilder:setWindow("prefWindow")
    
    NESBuilder:makeTab{name="tabPreferences",text="Preferences"}
    
    NESBuilder:setTabQt("tabPreferences")
    
    control = NESBuilder:makeCheckbox{x=x,y=y,name="prefUpperHex", text="Show hexidecimal in upper-case.", value=cfgGet('upperhex')}
    y = y + control.height + pad
    control = NESBuilder:makeCheckbox{x=x,y=y,name="prefAlphaWarning", text="Show Warning tab on startup.", value=cfgGet('alphawarning')}
    y = y + control.height + pad
    
    control = NESBuilder:makeCheckbox{x=x,y=y,name="prefLoadPlugins", text="Load plugins.", value=cfgGet('loadplugins')}
    y = y + control.height + pad
    
    push(x)
    x=x+pad*4
    for file in python.iter(pluginsList()) do
        control = NESBuilder:makeCheckbox{x=x,y=y,name='prefPlugin_'.. replace(replace(file, '.','_'), '_lua', ''), text=file, value=cfgGet('plugins', file), file=file, functionName='prefEnablePlugin'}
        y = y + control.height + pad
    end
    x=pop()
    
    y = y + pad * 8
    control = NESBuilder:makeLabelQt{x=x,y=y, clear=true,text="Note: Some preferences may require a restart."}
    y = y + control.height + pad
    b=NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight,name="buttonPreferencesClose",text="close"}
    
    NESBuilder:switchTab("tabPreferences")
end

function Preferences_cmd()
    launcherButtonPreferences_cmd()
end

function prefUpperHex_cmd(t)
    NESBuilder:cfgSetValue("main", "upperhex", boolNumber(t.isChecked()))
end

function prefAlphaWarning_cmd(t)
    NESBuilder:cfgSetValue("main", "alphawarning", boolNumber(t.isChecked()))
end

function prefLoadPlugins_cmd(t)
    NESBuilder:cfgSetValue("main", "loadplugins", boolNumber(t.isChecked()))
end

function prefEnablePlugin_cmd(t)
    NESBuilder:cfgSetValue("plugins", t.file, boolNumber(t.isChecked()))
end

function launcherButtonInfo_cmd() About_cmd() end

function createAboutTab()
    local x,y,left,top,pad
    pad = config.pad
    left = config.left
    top = config.top
    x,y = left,top
    local control

    -- make a closure for help text of links
    local linkHelpText = python.eval("lambda x: lambda: x.getUrl()")

    --NESBuilder:makeTab{name="tabAbout", text="About"}
    makeTab{name="tabAbout", text="About"}
    NESBuilder:setTabQt("tabAbout")

--    NESBuilder:makeWindow{x=0,y=0,w=760,h=600, name="infoWindow",title="Info"}
--    NESBuilder:setWindow("infoWindow")

    control = NESBuilder:makeLabelQt{x=x,y=y,name="launchLabel",clear=true,text="NESBuilder"}
    control.setFont("Verdana", 24)
    
    y = y + control.height + pad*1.5
    
    control = NESBuilder:makeLabelQt{x=x,y=y,name="launchLabel2",clear=true,text=config.launchText}
    control.setFont("Verdana", 12)
    
    y = y + control.height + pad
    control = NESBuilder:makeLink{x=x,y=y,name="linkAbout",clear=true,text="NESBuilder on GitHub", url=config.aboutURL}
    control.setFont("Verdana", 12)
    control.helpText = linkHelpText(control)
    
    y = y + control.height
    
    y = y + control.height + pad
    control = NESBuilder:makeLink{x=x,y=y,name="linkDonate",clear=true,text="\u{2764} Donate Bitcoin", url=config.bitcoinURL}
    control.setFont("Verdana", 12)
    control.helpText = linkHelpText(control)

    y = y + control.height + pad
    control = NESBuilder:makeLink{x=x,y=y,name="linkDonate",clear=true,text="\u{2764} Donate Monero", url=config.moneroURL}
    control.setFont("Verdana", 12)
    control.helpText = linkHelpText(control)
end

function New_cmd()
    toggleTab('Launcher', true)
    data.launchFrames.set('new')
    NESBuilder:switchTab("Launcher")
end

function OpenProject_cmd() Open_cmd() end
function BuildProjectTest_cmd() BuildTest_cmd() end
function Save_cmd() SaveProject() end

function SaveAs_cmd()
    local n, f
    n = askText("Save As", "Please enter a name for the project")
    if (not n) or n=='' then
        print('cancelled')
        return
    end
    
    -- Currently, must start with letter or number, and can contain 
    -- letters, numbers, underscore, dash
    if not NESBuilder:regexMatch("^[A-Za-z0-9]+[A-Za-z0-9_-]*$",n) then
        NESBuilder:showError("Error", string.format('Invalid project name: "%s"',n))
        return
    end
    
    -- check if the project folder already exists
    f = data.folders.projects..n
    if NESBuilder:pathExists(f) then
        NESBuilder:showError("Error", string.format('The project folder "%s" already exists.',n))
        return
    end
    
    -- Copy entire folder
    local src = data.folders.projects..data.project.folder
    local dst = data.folders.projects..n
    print(string.format('Copying folder "%s" to "%s".',src, dst))
    NESBuilder:copyFolder(src, dst)
    
    data.projectID = n
    data.project.folder = n.."/"
    SaveProject()
end

function loadTemplate(templateFileName)
    local n, f
    n = askText("New Project", "Please enter a name for the project")
    if (not n) or n=='' then
        print('cancelled')
        return
    end
    
    -- Currently, must start with letter or number, and can contain 
    -- letters, numbers, underscore, dash
    if not NESBuilder:regexMatch("^[A-Za-z0-9]+[A-Za-z0-9_-]*$",n) then
        NESBuilder:showError("Error", string.format('Invalid project name: "%s"',n))
        return
    end
    
    -- check if the project folder already exists
    f = data.folders.projects..n
    if NESBuilder:pathExists(f) then
        NESBuilder:showError("Error", string.format('The project folder "%s" already exists.',n))
        return
    end
    
    data.projectID = n
    data.project.folder = n.."/"
    
    
    NESBuilder:setWorkingFolder()
    -- make sure folders exist for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    
    -- exclude template files
    local exclude = list('templateicon.png', 'template.ini')
    NESBuilder:extractAll(data.folders.templates..templateFileName, data.folders.projects..data.project.folder, exclude)
    
    LoadProject()
    
    data.project.template = data.project.template or {}
    
    local templateConfig = NESBuilder:getTextFromArchive(data.folders.templates..templateFileName, 'template.ini')
    if templateConfig then
        print(templateConfig)
        data.project.template.data = templateConfig
    else
        data.project.template.data = ''
    end
    
    doTemplateActions()
end


function openProjectFolder_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    NESBuilder:shellOpen(workingFolder, data.folders.projects..data.project.folder)
end

function Build_cmd() BuildProject() end

function BuildTest_cmd()
    BuildProject()
    if data.buildFail then
        toggleTab('tabLog', true)
        NESBuilder:switchTab("tabLog")
    else
        TestRom_cmd()
    end
end

function TestRom_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    
    -- get binary filename with path
    --local f = getOutputBinaryFilename(true)
    
    -- get actual binary filename
    local f = getBuildBinary(true)
    
    print("shellOpen "..f)
    NESBuilder:shellOpen(workingFolder, f)
end

function BuildProject()
    local n
    local out, out2
    local folder = data.folders.projects..data.project.folder
    
    data.buildFail = false
    
    NESBuilder:setWorkingFolder()
    
    -- make sure folders exist for this project
    NESBuilder:makeDir(folder)
    NESBuilder:makeDir(folder.."chr")
    NESBuilder:makeDir(folder.."code")
    
    -- remove old binary
    NESBuilder:delete(getOutputBinaryFilename(true))
    
    handlePluginCallback("onBuild")
    
    -- use old build project routine
    if cfgGet("oldbuild")==1 and data.project.type == 'dev' then
        --BuildProject_cmd()
        print("Error: oldbuild parameter no longer supported.")
        return
    end
    if data.project.type == "romhack" then
        print(data.project.rom.filename)
        print(data.project.rom.data)
        if data.project.rom.filename and not data.project.rom.data then
            loadRom(data.project.rom.filename)
            print("loading rom data")
            
            if not data.project.rom.data then return end
        end

        -- export chr to rom and build binary
        exportAllChr()
    end
    
    if ppGet("exportPalettes", "bool") then
        -- Will use default if not defined
        exportPalettes(ppGet("exportPaletteFile"))
    end
    
    -- build_sdasm
    NESBuilder:setWorkingFolder()
    
    saveChr()
    
    if data.project.assembler == 'bB' then
        -- dont make a bunch of default stuff for bB
    else
        if not NESBuilder:fileExists(folder.."project.asm") and templateData("code") then
            -- Copy entire folder
            local src = data.folders.templates..templateData("code")
            local dst = data.folders.projects..data.project.folder
            print(string.format('Copying folder "%s" to "%s".',src, dst))
            NESBuilder:copyFolder(src, dst)
        end
        
        
        -- create default code
        if not NESBuilder:fileExists(folder.."project.asm") then
            print("project.asm not found, extracting code template...")
            --NESBuilder:extractAll('templates/romhack_xkasplus1.zip',folder)
            NESBuilder:extractAll("templates/romhack_sdasm1.zip",folder)
        end
    end
    
    local filename = data.folders.projects..data.project.folder.."code/symbols.asm"
    out=""
    
    out= out .. string.format('binaryFilename = "%s"\n', getOutputBinaryFilename())
    
    local d = getControl("symbolsTable1").getData()
    local line = ''
    for i, row in python.enumerate(d) do
        k,v,comment = row[0],row[1],row[2]
        if k~='' then
            if comment~='' then
                line = string.format("%s = %s",k,v or 0)
                if #line < 40 then
                    line = line .. string.rep(' ', 40-#line)
                end
                line = string.format("%s ; %s\n", line, comment)
                out = out .. line
            else
                out = out .. string.format("%s = %s\n",k,v or 0)
            end
        end
    end
    if out ~= '' then
        util.writeToFile(filename,0, out, true)
    end
    
    if ppGet('exportMetatiles', 'bool') then
    
        if iLength(data.project.mTileSets) > 0 then
            print('exporting metatiles...')
        end
        -- Make metatilesXX.asm
        for tileSet in ipairs_sparse(data.project.mTileSets) do
            if iLength(data.project.mTileSets[tileSet]) > 0 then
                filename = data.folders.projects..data.project.folder..string.format("code/metatiles%02x.asm",tileSet)
                
                n = data.project.mTileSets[tileSet].name or string.format("Metatiles%02x",tileSet)
                out = string.format('; Tile Set: %s\n\n', n)
                n = makeLabel(n)
                
                local subLabel = string.format('mTile%02x_', tileSet)
                
                if data.project.mTileSets[tileSet].includePointers then
                    out = out .. makePointerTable(n, subLabel, iLength(data.project.mTileSets[tileSet]))
                end
                
                out = out .. string.format("%s:\n",n)
                out2 = string.format("%s_offset:\n",n)
                
                for tileNum=0, #data.project.mTileSets[tileSet] do
                    local tile = data.project.mTileSets[tileSet][tileNum]
                    local mTileSet = data.project.mTileSets[tileSet]
                    local mtileOffsets = tile.map or mTileSet.map or {[0]=0,2,1,3}
                    
                    if tile then
                        for i,v in ipairs_sparse(tile) do
                            v = tile[mtileOffsets[i]]
                            
                            if i==0 then
                                if mTileSet.includePointers then
                                    out=out..string.format('%s_%02x: .db ', subLabel, tileNum)
                                else
                                    out=out..'    .db '
                                end
                            else
                                out=out..', '
                            end
                            out=out..string.format('$%02x',v)
                        end

                        if tile.desc and strip(tile.desc)~='' then
                            out = out .. '  ; '..tile.desc
                        end

                        out=out..'\n'
                        
                        local offset = tile.offset or mTileSet.offset or {x=0, y=0}
                        out2=out2..string.format('    .db $%02x, $%02x', offset.x, offset.y)
                        if tile.desc and strip(tile.desc)~='' then
                            out2 = out2 .. '            ; '..tile.desc
                        end

                    end
                    out2=out2..'\n'
                end
                out = out .. '\n'..out2
                util.writeToFile(filename,0, out, true)
            end
        end
        
        -- Make metatiles.asm
        out = ''
        filename = data.folders.projects..data.project.folder.."code/metatiles.asm"
        for tileSet=0, #data.project.mTileSets do
            if #data.project.mTileSets[tileSet] > 0 then
--                n = data.project.mTileSets[tileSet].name or string.format("Metatiles%02x",tileSet)
--                n = makeLabel(n)
                
                if data.project.mTileSets[tileSet].org then
                    out = out .. string.format("org $%04x\n", data.project.mTileSets[tileSet].org)
                end
                
                --out = out .. string.format("%s:\n",n)
                out = out .. string.format('include "code/metatiles%02x.asm"\n\n',tileSet)
            end
        end
        if out ~= '' then
            print(string.format('%s created.',filename))
            util.writeToFile(filename,0, out, true)
        end
    end
    
    NESBuilder:setWorkingFolder(folder)
    
    if data.project.assembler == 'asm6' then
        local cmd = data.folders.tools.."asm6.exe"
        local args = string.format("-L project.asm %s list.txt", getOutputBinaryFilename())
        print("Starting asm 6...")
        
        NESBuilder:run(folder, cmd, args)
    elseif data.project.assembler == 'bB' then
        local bBFolder = data.folders.tools..'bB/'
        cmd = data.folders.tools.."bB/2600bas.bat"
        
        local args = string.format("project.bas %s", getOutputBinaryFilename())
        print("Starting bB...")
        
        NESBuilder:run(folder, cmd, args)
        
        cleanupFiles = {
            "bB.asm",
            "2600basic_variable_redefs.h",
            "includes.bB",
            "project.bas.sym",
            "project.bas.lst",
        }
        
        for _, file in ipairs(cleanupFiles) do
            file = fixPath(data.folders.projects..data.project.folder..file)
            NESBuilder:delete(file)
        end
        
        NESBuilder:rename(data.folders.projects..data.project.folder.."project.bas.bin", getOutputBinaryFilename(true))
        
        
        
--        local cmd = data.folders.tools.."bB/2600basic.exe"
--        local args = "project.bas"
--        print("Starting bB...")
        
--        NESBuilder:run(folder, cmd, args)
    elseif data.project.assembler == 'xkasplus' then
        local cmd = data.folders.tools.."xkas-plus/xkas.exe"
        local args = string.format("-o %s project.asm", getOutputBinaryFilename())
        print("Starting xkas plus...")
        
        NESBuilder:run(folder, cmd, args)
    elseif data.project.assembler == 'sdasm' then
        local sdasm = python.eval('sdasm')
        local fixPath = python.eval('fixPath2')
        local romData = data.project.rom.data
        
        if data.project.type == 'romhack' then
            -- Apply IPS patches.
            for i, patchFile in ipairs_sparse(data.project.patches) do
                f = NESBuilder:findFile(patchFile, list(folder))
                if f then
                    print('Applying IPS patch: '..f)
                    ipsData = NESBuilder:getFileAsArray(f)
                    romData = NESBuilder:applyIps(ipsData, romData)
                elseif patchFile ~='' then
                    print('*** Invalid IPS patch: '..patchFile)
                end
            end
        end
        
        -- Start assembling with sdasm
        print("Assembling with sdasm...")
        
        local success, errorText = sdasm.assemble('project.asm', getOutputBinaryFilename(), 'output.txt', fixPath(data.folders.projects..data.project.folder..'config.ini'), romData, nil, nil, nil, "NESBuilder")
        if not success then
            data.buildFail = true
            print(errorText)
        end
        
        data.project.buildBinaryFilename = sdasm.assembler.outputFilename
    else
        handlePluginCallback("onAssemble", data.project.assembler)
        --print('invalid assembler '..data.project.assembler)
    end
    
    print("done.")
end

function getBuildBinary(includePath)
    local f = data.project.buildBinaryFilename or ppGet('binaryFilename') or data.project.binaryFilename
    if includePath then
        return data.folders.projects..data.project.folder..f
    end
    return f
end

function getOutputBinaryFilename(includePath)
    local f = ppGet('binaryFilename') or data.project.binaryFilename
    
    --f = data.project.buildBinaryFilename or f
    
    if includePath then
        return data.folders.projects..data.project.folder..f
    end
    return f
end

function saveChr()
    if #data.project.chr == 0 then return end
    
    -- make sure folders exist for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."chr")
    --NESBuilder:makeDir(data.folders.projects..data.project.folder.."code")

    -- save CHR
    local filename = data.folders.projects..data.project.folder.."chr/chr.asm"
    local out = 'chr 0\n'
    for i in ipairs_sparse(data.project.chr) do
        if data.project.chr[i] then
            local f = data.folders.projects..data.project.folder..string.format("chr/chr%02x.chr",i)
            print("File created "..f)
            --print(data.project.chr[i][0])
            NESBuilder:saveArrayToFile(f, data.project.chr[i])
            out = out..string.format('    incbin "chr%02x.chr"  ; %s\n',i, data.project.chrNames[i])
        end
    end
    
    
    util.writeToFile(filename,0, out, true)
end

function LoadProject_cmd()
    LoadProject()
end

function closePluginTabs()
    toggleTab('Palette', false)
    toggleTab('Image', false)
    toggleTab('Symbols', false)
    toggleTab('Metatiles', false)
    toggleTab('tabLog', false)
    toggleTab('tabAbout', false)
    
    toggleTab('tabProjectProperties', false)

    for _,p in pairs(plugins) do
        for _,tab in ipairs(p.tabs or {}) do
            toggleTab(tab, false)
        end
    end
end

function LoadProject(templateFilename)
    local projectID, filename, control
    
    -- Close all plugin tabs by default
    closePluginTabs()
    
    
    control = getControl('ppSettingsTable')
    if control then control.clear() end
    
    for k,v in pairs(plugins) do
        -- Unhide plugin by default
        -- This makes the plugin available and work, but doesn't
        -- actually show the tab.
        showPlugin(k)
    end
    
    handlePluginCallback("onPreLoadProject")
    
    NESBuilder:setWorkingFolder()
    print("loading project "..data.projectID)
    
    projectFolder = data.projectID.."/"
    
    projectID = data.projectID
    
    if templateFilename then
        filename = data.folders.templates..templateFilename
    else
        filename = data.folders.projects..projectFolder.."project.dat"
    end
    print('load project filename: '..filename)
    
    data.project = util.unserialize(util.getFileContents(filename))
    data.projectID = projectID
    
    if not data.project then
        data.project = {type = data.projectType}
    end
    data.project.const = data.project.const or {}
    
    data.project.savedTab = data.project.currentTab
    
    
    -- Adjust project properties as needed
    local prop = {}
    for i, row in ipairs_sparse(data.project.properties or {}) do
        if row.k and strip(row.k) ~= '' then
            tableAppend(prop, row)
        end
    end
    data.project.properties = prop
    
    -- Add this to projects that didn't have a project type
    data.project.type = data.project.type or "dev"
    
    data.project.assembler = data.project.assembler or config.defaultAssembler
    
    -- update project folder in case it's been moved
    data.project.folder = projectFolder
    
    if data.project.assembler == 'bB' then
        data.project.binaryFilename = data.project.binaryFilename or "game.bin"
    else
        data.project.binaryFilename = data.project.binaryFilename or "game.nes"
    end
    
    -- use default palettes if not found
    --data.project.palettes = data.project.palettes or util.deepCopy(data.palettes)
    
    data.project.paletteSets = data.project.paletteSets or {}
--    data.project.paletteSets = data.project.paletteSets or {
--        index = 0,
--        {
--            name = "palette set 00",
--            palettes = {
--            },
--            index = 0,
--        },
--    }
    data.project.paletteSets.index = data.project.paletteSets.index or 0
    for i,pSet in ipairs(data.project.paletteSets) do
        pSet.palettes = pSet.palettes or {}
        pSet.palettesDesc = pSet.palettesDesc or {}
    end
    
    if data.project.palettes then
        -- convert old palettes to palette set format
        local pSet = {
          name = 'converted',
          palettes = {},
          palettesDesc = {},
          index = 0,
        }
        for i, item in ipairs_sparse(data.project.palettes) do
            pSet.palettes[#pSet.palettes+1] = item
        end
        data.project.paletteSets[#data.project.paletteSets+1] = pSet
        data.project.palettes = nil
    end
    
    
    if #data.project.paletteSets == 0 then
        local pSet = {
          name = 'main',
          palettes = {},
          palettesDesc = {},
          index = 0,
        }
        data.project.paletteSets[#data.project.paletteSets+1] = pSet
    end
    
    if not data.project.mTileSets then
        data.project.mTileSets = {index=0}
        
        -- convert old metatile format or make blank
        data.project.mTileSets[data.project.mTileSets.index] = data.project.metatiles or {index=0}
    end
    
    updateMTileList()
    
    data.project.chr = data.project.chr or {index=0}
    data.project.chrNames = data.project.chrNames or {}
    
    local converted = false
    for i in ipairs_sparse(data.project.chr) do
        if type(data.project.chr[i]) == "table" then
            data.project.chr[i] = NESBuilder:tableToList(data.project.chr[i], 0)
            data.project.chr[i] = makeNp(data.project.chr[i])
            converted = true
        end
    end
    if converted then print("converted old chr tables to ndarray") end
    
    local control = NESBuilder:getControl('CHRList')
    control.clear()
    
    for i in ipairs_sparse(data.project.chr) do
        data.project.chrNames[i] = data.project.chrNames[i] or string.format("CHR %02x", i)
        control.addItem(data.project.chrNames[i])
    end
    
    data.project.chr.index = math.max(0, (data.project.chr.index or 0))
    
    data.project.chr[0] = data.project.chr[0] or NESBuilder:newCHRData()
    
    data.selectedTile = data.selectedTile or 0
    data.selectedColorIndex = data.selectedColorIndex or 0
    local p = currentPalette()
    data.selectedColor = p[data.selectedColorIndex+1]
    
    control.setCurrentRow(data.project.chr.index)
    NESBuilder:getControl('CHRName').setText(data.project.chrNames[data.project.chr.index])
    
    -- load symbols table
    local control = getControl('symbolsTable1')
    control.clear()
    data.project.constants = data.project.constants or {}
    for i,row in pairs(data.project.constants) do
        control.set(i,0,row.k)
        control.set(i,1,row.v)
        control.set(i,2,row.comment)
    end
    
    data.project.patches = removeEmpty(data.project.patches or {})
    
--    NESBuilder:setWorkingFolder(data.folders.projects..data.project.folder)
--    if data.project.rom then
--        data.project.rom.data = NESBuilder:listToTable(NESBuilder:getFileAsArray(data.project.rom.filename))
--    end
--    NESBuilder:setWorkingFolder()
    
    -- temporary fix
    data.project.rom = data.project.rom or {}
    if not templateFilename then
        if data.project.rom.filename and not data.project.rom.data then
            loadRom(data.project.rom.filename)
            print('loading rom data')
        end
    end
    
    local t = {}
    local control = NESBuilder:getWindowQt()
    for n in iterItems(control.menus['menuView'].actions) do
        t[n] = control.tabParent.isTabVisible(control.tabParent.indexOf(control.getTab(n)))
    end
    data.project.visibleTabs = data.project.visibleTabs or {}
    for k,v in pairs(data.project.visibleTabs) do
        t[k] = v
    end
    data.project.visibleTabs = t
    
    data.project.tabsList = data.project.tabsList  or {}
    for i,tab in ipairs (data.project.tabsList) do
        toggleTab(tab, data.project.visibleTabs[tab])
    end
    
    data.project.plugins = data.project.plugins or {}
    
    for k,v in pairs(data.project.plugins) do
        if v then
            showPlugin(k)
        else
            hidePlugin(k)
        end
    end
    
    handlePluginCallback("onLoadProject")
    
    PaletteEntryUpdate()
    updatePaletteSets()
    
    -- refresh metatile tile canvas
    local control = getControl('tsaTileCanvasQt')
    control.drawTile(0,0, data.selectedTile, currentChr(), currentPalette(), control.columns, control.rows)
    control.update()
    
    updateSquareoid()
    
    dataChanged(false)
    
    recentProjects.remove(data.projectID)
    recentProjects.push(data.projectID)
    updateRecentProjects()
    
--    c = NESBuilder:getControl('PaletteList')
--    c.set(data.project.paletteIndex or 0)
    
--    f=data.folders.projects..projectFolder.."chr.png"
--    NESBuilder:loadImageToCanvas(f)
    
    ppLoad()
    
    if getControl(data.project.savedTab) then
        NESBuilder:switchTab(data.project.savedTab)
    else
        NESBuilder:switchTab("Launcher")
    end
    
    updateTitle()
end

function SaveProject()
    NESBuilder:setWorkingFolder()
    
    -- make sure folder exists for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    
    -- Convert symbols table
    print("converting symbols...")
    local d = getControl('symbolsTable1').getData()
    local t = {}
    for i, row in python.enumerate(d) do
        t[i] = {k=row[0],v=row[1],comment=row[2]}
    end
    data.project.constants = t
    
    local romData = nil
    if data.project.rom then
        if (data.project.rom.data) and (not data.project.incRomData) then
            romData = data.project.rom.data
            data.project.rom.data = nil
        end
    end
    
    -- Save tabs
    data.project.visibleTabs = {}
    data.project.tabsList = {}
    local control = NESBuilder:getWindowQt()
    for n in iterItems(control.menus['menuView'].actions) do
        table.insert(data.project.tabsList, n)
        data.project.visibleTabs[n] = control.tabParent.isTabVisible(control.tabParent.indexOf(control.getTab(n)))
    end
    
    handlePluginCallback("onSaveProject")
    
    local time = python.eval("time.time")
    local t = time()
    
    local filename = data.folders.projects..data.project.folder.."project.dat"
    util.writeToFile(filename,0, util.serialize(data.project), true)
    
    if data.project.rom then
        data.project.rom.data = romData
    end
    
    dataChanged(false)
    
    print(string.format("Project saved (%s)",data.projectID))
end

function Label1_cmd(name, label)
    print(name)
end

function PaletteList_cmd(t)
    print(t.get())
end

function About_cmd()
    --NESBuilder:exec(string.format("webbrowser.get('windows-default').open('%s')",config.aboutURL))
    toggleTab('tabAbout', true)
    NESBuilder:switchTab("tabAbout")
end

function Quit_cmd()
    NESBuilder:Quit()
end

function refreshCHR()
    local w,h
    local c = NESBuilder:getControl('CHRNumLabel')
    if currentChr() then
        c.text = string.format("CHR %02x/%02x", data.project.chr.index, #data.project.chr)
    else
        c.text = ''
    end
    
    if currentChr() then
        local nTiles = NESBuilder:getLen(currentChr())/16
        -- Fixed width of 16
        w = 16 * 8
        h = nTiles/16 *8
    else
        w = 16 * 8
        h = 16 * 8
    end
    
    -- get canvas control
    local control = NESBuilder:getControl("canvasQt")
    
    control.resize(w*control.scale, h*control.scale)
    
    -- create an off-screen drawing surface
    local surface = NESBuilder:makeNESPixmap(w,h)
    -- load CHR Data to the surface
    surface.loadCHR(currentChr())
    -- apply current palette to it
    surface.applyPalette(currentPalette())
    -- paste the surface on our canvas (it will be sized to fit)
    control.paste(surface)
    
    if currentChr() then
        control = getControl("canvasTile")
        control.chrData = currentChr()
        control.drawTile(0,0, data.selectedTile, currentChr(), currentPalette(), control.columns, control.rows)
        control.update()
        control.copy()
        
        control = NESBuilder:getControl("tsaCanvasQt")
        if control then
            control.paste(surface)
        end
    else
        getControl('canvasTile').clear()
        getControl('tsaCanvasQt').clear()
    end
    
    handlePluginCallback("onCHRRefresh", surface)
end

function LoadCHRImage_cmd()
    if not currentChr() then return end
    
    local CHRData
    local f = NESBuilder:openFile{filetypes={{"Images", ".png"}}}
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        -- Load the image into data
        CHRData = NESBuilder:imageToCHRData(f,NESBuilder:getNESColors(currentPalette()))
        -- Store in selected project bank
        setChrData(CHRData)
        
        refreshCHR()
        dataChanged()
    end
end

function LoadCHRNESmaker_cmd()
    if not currentChr() then return end
    
    local CHRData
    local f = NESBuilder:openFile{filetypes={{"Bitmap (NESMaker)", ".bmp"}}}
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        -- Load the image into data
        --CHRData = NESBuilder:imageToCHRData(f,NESBuilder:getNESmakerColors())
        -- Store in selected project bank
        --setChrData(CHRData)
        
        --refreshCHR()
        --dataChanged()

        -- create a surface
        local surface = NESBuilder:makeNESPixmap(128,128)
        -- get chr data and store in selected project bank
        setChrData( surface.loadCHRFromImage(f, NESBuilder:getNESmakerColors()) )
        
        local control = NESBuilder:getControl("canvasQt")
        control.width = surface.width*control.scale
        control.height = surface.height*control.scale
    
        refreshCHR()
        dataChanged()


    end
end

function ExportCHR_cmd()
    if not currentChr() then return end
    
    local filename = string.format("chr_%02x_export.png",data.project.chr.index)
    local f, ext, filter = NESBuilder:saveFileAs{filetypes={{"PNG", ".png"},{"Bitmap", ".bmp"}, {"Bitmap (NESMaker)", ".bmp"}, {"Raw CHR Data", ".chr"}}, initial=filename}
    if f == "" then
        print("Export cancelled.")
    else
        print("file: "..f)
    end
    
    -- get canvas control
    local control = NESBuilder:getControl("canvasQt")
    -- create an off-screen drawing surface
    local surface = NESBuilder:makeNESPixmap(128,128)
    -- load CHR Data to the surface
    surface.loadCHR(currentChr())
    
    if filter ~= "Bitmap (NESMaker) (*.bmp)" then
        -- apply current palette to it
        surface.applyPalette(currentPalette())
    end
    
    local formats = {
        bmp = "BMP",
        gif = "GIF",
        jpg = "JPEG",
        jpeg = "JPEG",
        png = "PNG",
        pbm = "PBM",
        ppm = "PPM",
        xbm = "XBM",
        xpm = "XPM",
    }
    
    fmt = formats[string.sub(ext, 2)]
    
    if fmt then
        surface.save(f, fmt)
    elseif ext == ".chr" then
        --util.writeToFile(f, 0, currentChr(), true)
        NESBuilder:saveArrayToFile(f, currentChr())
    else
        print("unknown extension "..ext)
    end
end

function LoadCHR_cmd()
    if not currentChr() then return end
    
    local f = NESBuilder:openFile{filetypes={{"CHR", ".chr"}}}
    if f == "" then
        print("Open cancelled.")
        return
    end
    
    loadChr(f)
    refreshCHR()
    dataChanged()
end

function Open_cmd()
    local q
    
    if data.project.changed then
        q = NESBuilder:askYesNoCancel{message=string.format("Save changes to %s?",data.projectID)}
        
        -- cancel
        if q==nil then return end
        
        if q==true then
            SaveProject()
        end
    end
    
    local f, projectID = NESBuilder:openFolder("projects")
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        data.projectID = projectID
        LoadProject()
    end
end

function onExit(cancel)
    print("onExit")
    
    if data.project.changed then
        q= NESBuilder:askYesNoCancel("", string.format('Save changes to "%s?"',data.projectID))
        
        -- cancel
        if q==nil then return true end
        
        if q==true then
            SaveProject()
        end
    end
    
    handlePluginCallback("onExit")
    
    saveSettings()
end

function updateMTileList()
    local control = NESBuilder:getControl('mTileList')
    control.clear()
    for i,v in ipairs_sparse(data.project.mTileSets) do
        v.name = v.name or string.format("MTile Set %02x", i)
        if (i==0) or (iLength(v) > 0) then
            control.addItem(v.name)
        else
            data.project.mTileSets[i] = nil
        end
    end
end

function mTileIncludePointers_cmd(t)
    local mTileSet = currentMetatileSet()
    if mTileSet then
        mTileSet.includePointers = t.isChecked()
        getControl('mTileIncludePointers').setChecked(mTileSet.includePointers)
    end
end

function mTileList_cmd(t)
    local index = t.getIndex()
    data.project.mTileSets.index = index
    data.project.mTileSets[data.project.mTileSets.index] = data.project.mTileSets[data.project.mTileSets.index] or {index=0}
    updateSquareoid()

    local mTileSet = currentMetatileSet()
    if mTileSet then
        getControl('mTileIncludePointers').setChecked(bool(mTileSet.includePointers))
    end
end

function delMTileSet(index)
    index = index or data.project.mTileSets.index
    
    tableRemove(data.project.mTileSets, data.project.mTileSets.index)

    local control = NESBuilder:getControl('mTileList')
    
    -- Setting this to -1 avoids refreshing things too soon
    control.setCurrentRow(-1)
    control.removeItem(index)
    
    index = math.min(#data.project.mTileSets, index - 0)
    data.project.mTileSets.index = index
    
    -- This will trigger the callback, and refresh the chr
    control.setCurrentRow(index)
end

function mTileList_keyPress_cmd(t)
    local key = t.control.event.key
    if key == "Delete" then
        delMTileSet(t.getIndex())
    end
end

function addMTileSet()
    local tileIndex = 0
    local control = NESBuilder:getControl('mTileList')
    
    local n = "New MTile Set"
    local index = len(data.project.mTileSets)+1
    data.project.mTileSets[index] = {index=0, name=n}
    control.addItem(n)
    control.setCurrentRow(index)
end

function renameMTileSet()
    local control = getControl("mTileList")
    if control.count() == 0 then return end

    local n = askText('Rename Metatile Set', 'Enter a new name for the metatile set.')
    local index = data.project.mTileSets.index
    if n and (n~='') then
        data.project.mTileSets[index].name = n
        control.item(index).setText(n)
    end
    
end

-- Why does this exist?  table.remove does not handle
-- a list index of 0.
-- This function does not return the removed item.
function tableRemove(t, index)
    if type(index) == 'number' then
        if index == 0 and #t == 0 and t[0] then
            t[0] = nil
            return
        end
        
        for i=0, #t-1 do
            print(string.format('i = %s',i))
            if i >= index then
                t[i] = t[i+1]
            end
        end
        if #t > 0 then table.remove(t, #t) end
    end
end

function delCHR(index)
    index = index or data.project.chr.index
    
    local chr = {}
    local chrNames = {}
    
    -- ToDo: handle removing of only chr (make blank?)
    
    tableRemove(data.project.chr, index)
    tableRemove(data.project.chrNames, index)
    
    local control = NESBuilder:getControl('CHRList')
    
    if index == 0 then getControl('canvasQt').clear() end
    
    -- Setting this to -1 avoids refreshing things too soon
    control.setCurrentRow(-1)
    control.removeItem(index)
    
    index = math.min(#data.project.chr, index - 0)
    data.project.chr.index = index
    
    if not currentChr() then
        getControl('CHRNumLabel').text = ''
        getControl('CHRName').clear()
    end
    
    -- This will trigger the callback, and refresh the chr
    control.setCurrentRow(index)
end


function CHRList_keyPress_cmd(t)
    local key = t.control.event.key
    if key == "Delete" then delCHR(t.getIndex()) end
    print(key)
end

function CHRList_cmd(t)
    local index = t.getIndex()
    if index == -1 then return end
    
    data.project.chr.index = index
    
    local control = NESBuilder:getControl('CHRName')
    control.setText(t.getItem())
    
    refreshCHR()
end

function CHRName_cmd(t)
    if not currentChr() then
        t.control.clear()
        return
    end
    
    local control = NESBuilder:getControl('CHRList')
    
    if control.getIndex() == -1 then return end
    
    if t.control.text~=control.getItem() then
        --control.editItem(control.currentItem())
        local item = control.currentItem()
        --item.setText(t.text)
        
        item.setText(t.control.text)
        
        data.project.chrNames[control.getIndex()] = t.control.text
    end
end

function tsaCanvas_cmd(t)
    local x = math.floor(t.event.x/t.scale)
    local y = math.floor(t.event.y/t.scale)
    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tileNum = tileY*0x10+tileX
    local tileOffset = 16*tileNum
    local CHRData, TileData
    
    if x<0 or y<0 or x>=128 or y>=128 then return end
    
    local p = currentPalette()
    
    if t.event.type == "ButtonPress" then
        if t.event.button == 1 then
            print(string.format("%02x", tileNum))
            
            local TileData = {}
            
            for i=0,15 do
                TileData[i+1] = t.chrData[tileOffset+i+1]
            end
            
            data.project.tileData = TileData
            data.project.tileNum = tileNum
            getControl("tsaTileCanvas").loadCHRData(TileData, p)
        end
    end
end

function metatilePrev_cmd()
    data.project.mTileSets[data.project.mTileSets.index].index = math.max(0, data.project.mTileSets[data.project.mTileSets.index].index - 1)
    print(string.format("%d %d",data.project.mTileSets.index, data.project.mTileSets[data.project.mTileSets.index].index))
    updateSquareoid()
end
function metatileNext_cmd()
    data.project.mTileSets[data.project.mTileSets.index].index = math.min(255, data.project.mTileSets[data.project.mTileSets.index].index + 1)
    print(string.format("%d %d",data.project.mTileSets.index, data.project.mTileSets[data.project.mTileSets.index].index))
    updateSquareoid()
end


function makeMap(w,h, direction)
    local m = {}
    local x,y = 0,0
    
    -- ToDo: some kind of default metatile map here
    direction = direction or 0
    
    for i = 0, w * h -1 do
        if direction == 1 then
            -- tiles go top to bottom, left to right
            x = math.floor(i / w)
            y = i % h
            m[i] = y * w + x
        else
            -- tiles go left to right, top to bottom
            m[i] = i
        end
    end
    return m
end

function metatileNew_cmd()
    local mTileSet = currentMetatileSet()
    local currentMTile = currentMetatile()
    local m = {}
    
    m.w = NESBuilder:getInt(getControl('metatileW').value)
    m.h = NESBuilder:getInt(getControl('metatileH').value)
    
    if m.w == 0 or m.h == 0 then return end
    if m.w > 16 or m.h > 16 then return end
    
    m.map = makeMap(m.w, m.h)
    
    m.palette = data.project.paletteSets.index
    m.chrIndex = data.project.chr.index
    for i=0,m.w * m.h-1 do
        m[i] = 0
        m.map[i] = i
    end
    
    for y=0, m.h-1 do
        for x=0, m.w-1 do
            if not currentMTile then
                m[m.map[y * m.w + x]] = 0
            elseif not currentMTile.w then
                m[m.map[y * m.w + x]] = 0
            elseif x > currentMTile.w-1 or y > currentMTile.h-1 then
                -- position doesn't exist in old metatile, use default
                m[m.map[y * m.w + x]] = 0
            elseif m.map[y * m.w + x] then
                local mapOld = currentMTile.map or mTileSet.map or makeMap(currentMTile.w, currentMTile.h)
                
                if mapOld[y * currentMTile.h + x] then
                    m[m.map[y * m.w + x]] = currentMTile[mapOld[y * currentMTile.w + x]]
                end
            end
        end
    end
    
    if currentMTile then
        m.desc = currentMTile.desc
    else
        m.desc = ''
    end
    
    data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] = m
    
    updateSquareoid()
end

function metatileNumber_cmd(t)
    --print(t)
--    if t.event and t.event.type == "KeyPress" and t.event.event.keycode==13 then
--        data.project.mTileSets[data.project.mTileSets.index].index = tonumber(NESBuilder:getControl("metatileNumber").getText())
--    end
--    local index = tonumber(t.text)
--    data.project.mTileSets[data.project.mTileSets.index].index = math.min(255, math.max(0, index))
--    updateSquareoid()
end

function updateSquareoid()
    local tileNum
    local tileOffset1, tileOffset2
    local m = currentMetatile()
    local controlFrom = getControl("tsaCanvasQt")
    local controlTo = getControl("tsaCanvas2Qt")
    
    local control = getControl("mTileList")
    
    getControl('metatileName').clear()
    getControl('metatileOffset').clear()
    
    if control.count() == 0 then return end
    
    if data.project.mTileSets.index == -1 then
        data.project.mTileSets.index = 0
        control.setCurrentRow(0)
    end
    
    -- make sure current item is selected in list
    control.setCurrentRow(data.project.mTileSets.index)
    
    local mTileSet = currentMetatileSet()
    
    local control = NESBuilder:getControl("metatileNumber")
    control.setText(string.format('%s',data.project.mTileSets[data.project.mTileSets.index].index))
    if not m then
        controlTo.reset(2,2)
        controlTo.clear()
        controlTo.repaint()
        NESBuilder:getControl("MTileAddress").setText('')
        return
    end
    
    local cols = m.w or mTileSet.w or 2
    local rows = m.h or mTileSet.h or 2
    controlTo.reset(cols,rows)
    controlTo.clear()
    
    local chrIndex = m.chrIndex or mTileSet.chrIndex
    
    if (chrIndex or data.project.chr.index) ~= data.project.chr.index then
        --setChr(chrIndex)
    end
    
    if not data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] then
        local mtileOffsets = m.map or mTileSet.map or {[0]=0,2,1,3}
        
        for i, v in ipairs_sparse(mtileOffsets) do
            controlTo.drawTile(i%controlTo.columns *8,math.floor(i/controlTo.columns) *8, m[v], currentChr(), p, controlTo.columns, controlTo.rows)
            controlTo.update()
        end
        return
    end
    
    data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] = data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] or {[0]=0,0,0,0}
    --local p = currentPalette()
    local pSetIndex = m.pSet or 0
    
    print(string.format("pSetIndex=%s", pSetIndex))
    print(string.format("m.palette=%s", m.palette))
    print(getPaletteSet(pSetIndex))
    
    local p
    if not pcall(function()
        p = getPaletteSet(pSetIndex).palettes[(m.palette or 0)+1]
        print("p -----")
        print(p)
        print("-------")
    end) then
        -- prevents a crash; how was this supposed to work again?
        print("error")
        p = currentPalette()
    end
    
    local mtileOffsets = m.map or mTileSet.map or {[0]=0,2,1,3}
    for i, v in ipairs_sparse(mtileOffsets) do
        controlTo.drawTile(i%controlTo.columns *8,math.floor(i/controlTo.columns) *8, m[v], currentChr(), p, controlTo.columns, controlTo.rows)
        
    end
    controlTo.update()
    
    local control = NESBuilder:getControl("MTileAddress")
    local address = data.project.mTileSets[data.project.mTileSets.index].org
    if address then
        control.setText(string.format("$%04x", address))
    else
        control.setText("")
    end
    
    local tile = mTileSet[mTileSet.index]
    
    local txt = data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index].desc
    if txt == '' then
        txt = nil
        data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index].desc = txt
    end
    getControl('metatileName').setText(txt or "---")
    
    local offset = tile.offset or mTileSet.offset or {x=0, y=0}
    getControl('metatileOffset').setText(string.format('offset: (%d, %d)', offset.x, offset.y))
    
    
    if data.metatileCursorMode == 'offset' and m.offset then
        drawTargetCrosshairs(controlTo, m.offset.x, m.offset.y)
    end
end

function drawTargetCrosshairs(control, x,y)
    local centerPad = 1
    if x-centerPad >= 0 then
        control.drawLine2(x-centerPad,y or 0,-1,y or 0)
    end
    if x+centerPad <= control.width then
        control.drawLine2(x+centerPad, y or 0,control.width+1,y or 0)
    end
    if y-centerPad >=0 then
        control.drawLine2(x, y-centerPad,x,-1)
    end
    if y+centerPad <= control.height then
        control.drawLine2(x, y+centerPad,x,control.height+1)
    end
end

function metatileOffsetTest_cmd(t)
    local mTile = currentMetatile()
    if not mTile then return end
    
    local control = getControl('tsaCanvas2Qt')
    
    print(tostring(not data.metatileCursorMode and "offset"))
    -- toggle mode
    setMetatileMode(not data.metatileCursorMode and "offset", true)
end

function setMetatileMode(mode, update)
    local control
    
    data.metatileCursorMode = mode or false
    
    control = getControl('tsaCanvas2Qt')
    
    if data.metatileCursorMode == "offset" then
        control.helpText = "Left-click: set offset, right-click: cancel"
        data.metatileCursorMode = "offset"
        control.setCursor('crosshair')
    else
        control.helpText = "Left-click: apply tile, right-click: select tile"
        data.metatileCursorMode = false
        control.setCursor()
    end
    
    if update then updateSquareoid() end
end


function metatileName_cmd(t)
    if not currentMetatile() then return end
    
    local control = t.control
    
    if t.control.event.button == 1 then
        local defaultText = data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index].desc
        local txt = askText('Metatile Description', 'Enter a new description for this metatile.', defaultText)
        local index = data.project.mTileSets.index
        
        if txt then
            if txt == '' then txt = nil end
            data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index].desc = txt
            control.setText(txt or "---")
        end
    end
end


function tsaTest_cmd()
    local p=data.project.palettes[data.project.palettes.index]
    
    getControl("tsaCanvas").loadCHRData(data.project.chr[data.project.chr.index], p)
end

--function onTabChanged_cmd(t)
--    local tab = t.tab()
--    if t.window.name == "Main" then
--        if tab == "tsa" then
--            local p=data.project.palettes[data.project.palettes.index]
            
--            local control = getControl("tsaCanvas")
--            getControl("tsaCanvas").loadCHRData(data.project.chr[data.project.chr.index], p)
            
--            updateSquareoid()
--        end
--    end
--    handlePluginCallback("onTabChanged", t)
--end

function updateRecentProjects()
    local stack = NESBuilder:newStack(recentProjects.stack)
    local id, control, k, menu
    
    for _, control in pairs(recentData) do
        control.label.setText("")
    end
    
    for i=1, len(recentProjects.stack) do
        id = stack.pop()
        recentData[i-1].label.setText(id)
    end
    
    -- Update recent projects in file menu
    menu = NESBuilder:getWindowQt().menus['menuFile']
    
    for i,v in python.enumerate(reverseList(recentProjects.asList())) do
        k = string.format("recentproject%d", i+1)
        if dictGet(menu.actions, k) then
            menu.actions[k].setText(v)
        end
        if i >= config.nRecentFiles_menu then break end
    end
end

-- file menu recent items
function recentproject_cmd(t) launcherRecentIcon_cmd(t) end

function launcherRecentIcon_cmd(t)
    local id,n,q
    
    updateRecentProjects()
    
    if t.index<=len(recentProjects.stack)-1 then
        n = len(recentProjects.stack)- 1 - t.index
        id = recentProjects.stack[n]

        if data.project.changed then
            q= NESBuilder:askYesNoCancel("", string.format("Save changes to %s?",data.projectID))
            
            -- cancel
            if q==nil then return end
            
            if q==true then
                SaveProject()
            end
        end
        
        data.projectID = id
        
        LoadProject()
    end
end

function MainQttabs_cmd(t,a)
    local tabIndex = t.control.currentIndex()
    local tab = t.control.widget(tabIndex)
    
    if not tab then return end
    
    if t.event and t.event.button == 4 then
        print('middle click')
        if devMode() then
            t.control.setIcon(tabIndex, 'icons/note32.png')
        end
    elseif t.event and t.event.button == 2 then
        print('right click')
    else
        --print('click')
        --print(tab.widget(tab.currentIndex()))
        --local dir = python.eval('lambda x:dir(x)')
        --print(dir(tab.name))
        --print(tab)
        data.project.currentTab = tab.name
        handlePluginCallback("onTabChanged", t.control.currentWidget())
    end
    
end

function hFlip()
    local tileOffset = 16*data.selectedTile
    local y
    
    for y=0,7 do
        for i = 0,1 do
            local b = data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8]
            data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8] = reverseByte(b)
        end
    end
    refreshCHR()
end

function vFlip()
    local tileOffset = 16*data.selectedTile
    local y
    local bytes = {}
    
    for y=0,7 do
        bytes[y] = {}
        for i = 0,1 do
            bytes[y][i] = data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8]
        end
    end
    for y=0,7 do
        for i = 0,1 do
            data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8] = bytes[7-y][i]
        end
    end
    refreshCHR()
end

function buttonCanvasTileActions_cmd(t)
    local y
    local tileOffset = 16*data.selectedTile
    local action = t.itemList[t.control.index+1]
    print(action)
    
    if action == "\u{2194} Flip Tile Horizontally" then
        hFlip()
    elseif action == "\u{2195} Flip Tile Vertically" then
        vFlip()
    end

    if (action == "Copy") or (action == "Cut") then
        local tileData = {}
        for y=0,7 do
            for i = 0,1 do
                local b = data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8]
                table.insert(tileData, b)
            end
        end
        data.tileCopyData = tileData
    elseif action == "Paste" then
        for y=0,7 do
            for i = 0,1 do
                local b = data.tileCopyData[y*2+i+1]
                data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8] = b
            end
        end
    end
    
    if (action == "Delete") or (action == "Cut") then
        for y=0,7 do
            for i = 0,1 do
                data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8] = 0
            end
        end
    end
    
    if (action == "Shift Tile Up") or (action == "Shift Tile Down") then
        local n = 7
        if action == "Shift Tile Down" then n = 1 end
        
        local tileData = {}
        for y=0,7 do
            for i = 0,1 do
                local b = data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8]
                table.insert(tileData, b)
            end
        end
        for y=0,7 do
            for i = 0,1 do
                local b = tileData[y*2+i+1]
                data.project.chr[data.project.chr.index][tileOffset+((i)*8)+(y+n)%8] = b
            end
        end
    elseif (action == "Shift Tile Left") or (action == "Shift Tile Right") then
        local n = 7
        if action == "Shift Tile Right" then n = 1 end
        local tileData = {}
        for y=0,7 do
            for i = 0,1 do
                local b = data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8]
                data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8] = NESBuilder:ror(b, n, 8)
            end
        end
    end
    
    if action == "Copy" then return end
    refreshCHR()
    
end

function canvasTile_cmd(t)
    if not currentChr() then return end
    
    local event = t.control.event
    local x = math.floor(event.x/t.scale)
    local y = math.floor(event.y/t.scale)
    x = math.min(t.control.columns*8-1, math.max(0,x))
    y = math.min(t.control.rows*8-1, math.max(0,y))
    local p = currentPalette()
    local tile = data.selectedTile
    local tileOffset = 16*tile
    
    if event.button == 1 then
        local control = NESBuilder:getControl(t.name)
        control.setPixel(x,y, getNESPalette()[data.selectedColor])
        control.update()
        
        local cBits = NESBuilder:numberToBitArray(data.selectedColorIndex)
        for i=0, 1 do
            local b = data.project.chr[data.project.chr.index][tileOffset+(i*8)+y%8]
            local l=NESBuilder:numberToBitArray(b)
            l[x%8]=cBits[7-i]
            b = NESBuilder:bitArrayToNumber(l)
            data.project.chr[data.project.chr.index][tileOffset+(i*8)+y%8] = b
        end
    end
    if event.button == 2 then
        local control = NESBuilder:getControl(t.name)
        local c=0
        for i = 0,1 do
            local b = data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8]
            local cBits = NESBuilder:numberToBitArray(b)
            --print(cBits[x])
            c = c + cBits[x]
            if i==1 then c = c + cBits[x] end
        end
        data.selectedColorIndex = c
        data.selectedColor = p[c+1]
    end
    if event.type == "ButtonRelease" then
        refreshCHR()
    end
    
    dataChanged()
end

function canvasQt_cmd(t)
    if not currentChr() then return end
    
    local event = t.control.event
    local x = math.floor(event.x/t.scale)
    local y = math.floor(event.y/t.scale)
    x = math.min(t.control.columns*8-1, math.max(0,x))
    y = math.min(t.control.rows*8-1, math.max(0,y))

    local control = getControl(t.name)
    local p = currentPalette()
    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tile = tileY*control.columns+tileX
    local tileOffset = 16*tile
    --local cBits = NESBuilder:numberToBitArray(data.selectedColorIndex)
    
--    control.setPixel(x,y, getNESPalette()[data.selectedColor])
--    control.update()
    
--    for i=0, 1 do
--        local b = data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8]
--        local l=NESBuilder:numberToBitArray(b)
--        l[x%8]=cBits[7-i]
--        b = NESBuilder:bitArrayToNumber(l)
--        data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8] = b
--    end
    
    
    
    control = getControl("canvasTile")
    --control.clear()
    control.chrData = currentChr()
    control.drawTile(0,0, tile, currentChr(), p, control.columns, control.rows)
    control.update()
    data.selectedTile = tile
    
--    if t.event.button ~= 0 then
--        control.lastX = x
--        control.lastY = y
--    end
    
--    control.drawLine(control.lastX,control.lastY, x,y)
--    control.lastX = x
--    control.lastY = y

    
end

function tsaCanvasQt_cmd(t)
    if not currentChr() then return end
    
    local control
    local event = t.control.event
    local x = math.floor(event.x/t.scale)
    local y = math.floor(event.y/t.scale)
    x = math.min(t.control.columns*8-1, math.max(0,x))
    y = math.min(t.control.rows*8-1, math.max(0,y))

    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tile = tileY*t.control.columns+tileX
    local tileOffset = 16*tile
    
    data.selectedTile = tile
    
    local control = getControl('tsaTileCanvasQt')
    control.drawTile(0,0, tile, currentChr(), currentPalette(), control.columns, control.rows)
    control.update()
    
    -- turn off metatile offset mode
    setMetatileMode(false, true)
end

function tsaCanvas2Qt_cmd(t)
    local control
    local event = t.control.event
    local x = math.floor(event.x/t.scale)
    local y = math.floor(event.y/t.scale)
    x = math.min(t.control.columns*8-1, math.max(0,x))
    y = math.min(t.control.rows*8-1, math.max(0,y))

    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tile = tileY*t.control.columns+tileX
    local tileOffset = 16*tile
    local m = currentMetatile()
    if not m then return end
    
    local mTileSet = currentMetatileSet()
    
    local mtileOffsets = m.map or mTileSet.map or {[0]=0,2,1,3}
    
    if data.metatileCursorMode == 'offset' then
        control = t.control
        if event.button == 1 then
            m.offset = {x=x, y=y}
            updateSquareoid()
            drawTargetCrosshairs(control, x, y)
--            control.drawLine2(0,m.offset.y,control.width,m.offset.y)
--            control.drawLine2(m.offset.x,0,m.offset.x,control.height)
        elseif event.button == 2 then
            -- turn off offset mode
            setMetatileMode(false, true)
        end
        
        return
    end
    
    if event.button == 1 then
        t.control.drawTile(tileX*8,tileY*8, data.selectedTile, currentChr(), currentPalette(), t.control.columns, t.control.rows)
        t.control.update()
        
        m[mtileOffsets[tileY*t.control.columns+tileX]] = data.selectedTile
--        printl("mtileOffsets:", mtileOffsets)
--        print(m)
--        printl("selected tile:", data.selectedTile)
--        printl("palette:", currentPalette())
        printl("xy:", tileY*t.control.columns+tileX)
        printl("xy mapped:", mtileOffsets[tileY*t.control.columns+tileX])
        
--        print(mtileOffsets)
        
        --local m = currentMetatile()
        --local mtileOffsets = {[0]=0,2,1,3}
        --m[tileX*t.control.columns+tileY] = data.selectedTile
        
        m.pSet = data.project.paletteSets.index
        m.palette = data.project.paletteSets.index
        m.chrIndex = data.project.chr.index
        
        printl("m.pSet:", m.pSet)
        printl("m.palette:", m.palette)
        
        setMetatileData(m)
        --print(data.project.mTileSets[data.project.mTileSets.index])
    elseif event.button == 2 then
--        printl("mtileOffsets:", mtileOffsets)
--        printl("m.map:", m.map)
--        printl("mTileSet.map:", mTileSet.map)
--        printl("?:", m.map or mTileSet.map or {[0]=0,2,1,3})
--        printl("xy?:", tileY*t.control.columns+tileX)
        --local m = currentMetatile()
        --local mtileOffsets = {[0]=0,2,1,3}
        --data.selectedTile = m[tileX*t.control.columns+tileY]
        data.selectedTile = m[mtileOffsets[tileY*t.control.columns+tileX]]
        
--        print(m)
        
        data.project.paletteSets.index = m.palette

        local control = getControl('tsaTileCanvasQt')
        control.drawTile(0,0, data.selectedTile, currentChr(), currentPalette(), control.columns, control.rows)
        control.update()
    end
end

function tsaTileCanvasQt_cmd()
    -- turn off metatile offset mode
    setMetatileMode(false, true)
end

--function buttonWarningClose_cmd() closeTab('Warning', 'Launcher') end
function buttonWarningClose_cmd() toggleTab('Warning', false) end
function buttonPreferencesClose_cmd() closeTab('tabPreferences', 'Launcher') end
function ppClose_cmd()
    toggleTab('tabProjectProperties', false)
end

function ppUpdate()
    local control
    local k,v, comment
    
    -- update patches from table
    data.project.patches = {}
    for i, row in python.enumerate(getControl('patchesTable').getData()) do
        data.project.patches[i] = row[0]
    end
    data.project.patches = removeEmpty(data.project.patches)
    
    -- update project properites from table
    data.project.properties = {}
    for i, row in python.enumerate(getControl('ppSettingsTable').getData()) do
        k,v,comment = row[0],row[1],row[2]
        if len(row)>0 and k and strip(k)~='' then
            data.project.properties[i] = {k=k,v=v,comment=comment}
        end
    end
    
    data.project.binaryFilename = getOutputBinaryFilename()
    
    --print('ppUpdate')
end

-- Convenience functions
function currentPalette(n)
    local pSet = data.project.paletteSets[(data.project.paletteSets.index or 0) + 1]
    if not pSet then return {0x0f, 0x01, 0x11, 0x21} end
    return pSet.palettes[(n or pSet.index or 0)+1] or {0x0f, 0x01, 0x11, 0x21}
    
    --return data.project.palettes[n or data.project.palettes.index]
end
function getPaletteSet(n)
    local pSet = data.project.paletteSets[(n or data.project.paletteSets.index) + 1]
    return pSet
end

function currentChr(n) return data.project.chr[n or data.project.chr.index] end
function setChr(n) data.project.chr.index = n end
function loadChr(f, n)
    data.project.chr[n or data.project.chr.index] = makeNp(NESBuilder:getFileContents(f))
    print(len(data.project.chr[n or data.project.chr.index]))
--    print(type(data.project.chr[n or data.project.chr.index]))
    
--    for i in ipairs_sparse(data.project.chr) do
--        if type(data.project.chr[i]) == "table" then
--            data.project.chr[i] = NESBuilder:tableToList(data.project.chr[i], 0)
--            data.project.chr[i] = makeNp(data.project.chr[i])
--            converted = true
--        end
--    end
    
end
function getChrData(n) return data.project.chr[n or data.project.chr.index] end
function setChrData(chrData, n) data.project.chr[n or data.project.chr.index]=chrData end
function boolNumber(v) if v then return 1 else return 0 end end
function devMode() return (cfgGet('dev')==1) end
function type(item) return NESBuilder:type(item) end
--function currentMetatile() return data.project.mTileSets[data.project.mTileSets.index][n or data.project.mTileSets[data.project.mTileSets.index].index] or {[0]=0,0,0,0} end
function currentMetatile() return data.project.mTileSets[data.project.mTileSets.index][n or data.project.mTileSets[data.project.mTileSets.index].index] or false end
function currentMetatileSet() return data.project.mTileSets[data.project.mTileSets.index] or false end

function setMetatileData(mTileData, n) data.project.mTileSets[data.project.mTileSets.index][n or data.project.mTileSets[data.project.mTileSets.index].index]=mTileData end
function getControl(n) return NESBuilder:getControl(n) end
--function getControl(n) return NESBuilder:getControl(n) or NESBuilder:getControlNew(n) end

function templateData(k)
    local t = data.project.template or {}
    if k then t = t[k] end
    return t
end


-- getTemplateData(section, key)     get single item from dict items of section
-- getTemplateData(section, "list")  get list items of section
-- getTemplateData(section, "dict")  get dict items of section
-- getTemplateData()                 get entire template data structure
function getTemplateData(section, key)
    return NESBuilder:parseTemplateData(data.project.template.data, section, key)
end

pythonEval = function(s)
    out =    "try:\n"
    out=out.."  "..s.."\n"
    out=out.."except LuaError as err:\n"
    out=out.."  handleLuaError(err)\n"
    out=out.."except Exception as err:\n"
    out=out.."  handlePythonError(err)\n"
    return python.eval(s)
end

-- print formatted string
function printf(...)
    print(string.format(...))
end

-- prints arguments separated by a space
function printl(...)
    local out = ''
    
    -- to catch None/nil even if it's the last 
    -- argument, we use a py eval
    local args = pythonEval('lambda *x:list(x)')(...)
    
    for i, item in python.enumerate(args) do
        if i > 0 then
            out = out .. ' '
        end
        out=out..NESBuilder:getPrintable(item)
    end
    print(out)
end

str = pythonEval('str')
split = pythonEval('str.split')
rsplit = pythonEval('str.rsplit')
fixPath = pythonEval('fixPath2')
pathSplit = pythonEval("lambda x:list(os.path.split(x))")
splitExt = pythonEval("lambda x:list(os.path.splitext(x))")
stem = pythonEval("lambda x:pathlib.Path(x).stem")
int = pythonEval("lambda x:int(x)")
bin = python.eval('lambda x:"{0:08b}".format(x)')
sliceList = pythonEval("lambda x,y,z:x[y:z]")
joinList = pythonEval("lambda x,y:x+y")
reverseList = pythonEval("lambda x:list(reversed(x))")
reverseByte = pythonEval("lambda x:int(('{:08b}'.format(x))[::-1],2)")
replace = pythonEval("lambda x,y,z:x.replace(y,z)")
list = pythonEval("lambda *x:[item for item in x]")
listAppend = pythonEval("lambda x,y:x.append(y)")
tableAppend = function(...) util.tableAppendSparse(...) end
maxTableIndex = function(...) util.maxTableIndex(...) end
makeLabel = pythonEval("lambda x:x.replace(' ','_')")
makeNp = pythonEval("lambda x: np.array(x)")
dictGet = pythonEval('lambda x,y:x.get(y, False)')
startsWith = pythonEval('lambda x,y:x.startswith(tuple(y))')
endsWith = pythonEval('lambda x,y:x.endswith(tuple(y))')

strip = pythonEval("lambda x:x.strip()")
lstrip = pythonEval("lambda x:x.lstrip()")
rstrip = pythonEval("lambda x:x.rstrip()")

set = pythonEval("lambda *x:set([item for item in x])")
bool = pythonEval("bool")
range = pythonEval('range')

-- Get integer keys from a list (including 0, sparse arrays)
iKeys = pythonEval("lambda l:sorted([x for x in l if type(x)==int]) or False")
max = pythonEval("lambda x:max(x)")
min = pythonEval("lambda x:min(x)")

pyItems = pythonEval("lambda x: x.items()")
function iterItems(x) return python.iter(pyItems(x)) end

function numericOnly(t, base)
    local newTable = {}
    local i = base or 0
    for _, item in ipairs_sparse(t) do
        newTable[i] = item
        i = i + 1
    end
    return newTable
end

function removeEmpty(t, base)
    local newTable = {}
    local i = base or 0
    for _, item in ipairs_sparse(t) do
        if item == nil then
            -- remove nil items
        elseif type(item == 'string') and strip(item) == '' then
            -- remove items that are all whitespace
        else
            newTable[i] = item
            i = i + 1
        end
    end
    return newTable
end

-- Number of items in a list with integer keys (including 0, sparse arrays)
iLength = function(t)
    local keys = iKeys(t)
    if keys then
        return len(keys)
    else
        return 0
    end
end

function makeTab(t)
    local ret = NESBuilder:makeTab{name=t.name, text=t.text}
    
    -- Keep track of which plugin generated a tab
    local p = _getPlugin and plugins[_getPlugin().name]
    if p then
        p.tabs = p.tabs or {}
        table.insert(p.tabs, t.name)
    end
    return ret
end

function setTab(tab)
    NESBuilder:setTabQt(tab)
end

function cfgGet(section, key)
    key, section = key or section, (key and section) or "main"
    return NESBuilder:cfgGetValue(section, key)
end

function ppGet(keyword, mode)
    local ret
    for i, row in ipairs_sparse(data.project.properties) do
        if string.lower(row.k) == string.lower(keyword) then
            ret = row.v
            break
        end
    end
    
    if mode == "bool" then
        ret = strip(string.lower(ret or ''))
        if (not bool(ret)) or (ret == 'false') or (ret == 'none') or (ret == '0') then
            return false
        end
    end
    
    return ret
end

-- Close a tab in current window
function closeTab(tabName, switchTo)
    local control = NESBuilder:getWindowQt()
    control.tabParent.removeTab(control.tabParent.indexOf(control.tabs[tabName]))
    control.tabs[tabName] = nil
    if switchTo then
        NESBuilder:switchTab(switchTo)
    end
end

-- Tab closed using X button
function closeTabButton_cmd(t)
    local n = t.control.closingWidget.name
    
    local control = NESBuilder:getWindowQt()
    
    local actionObject = dictGet(control.menus['menuView'].actions, n)
    if actionObject then
        -- If it exists in view menu, just change the checkmark
        print('close(toggle) '..n)
        actionObject.setChecked(false)
    else
        -- If it doesn't exist in view menu, delete the tab
        print('close '..n)
        --closeTab(n, 'Launcher')
        control.tabs[n] = nil
    end
end

function autoSave()
    -- This is here just so the app doesn't stay open if something goes
    -- Wrong and it's running things while trying to close.  It's not a
    -- great solution, but at least it wont have a process open in the
    -- background forever.
    local main = getControl('main')
    if main.closing then
        NESBuilder:forceClose()
        return
    end
    
    handlePluginCallback("onAutoSave")
end

function onShow()
--    local x,y
--    x,y=left,top
    
--    NESBuilder:setWindowQt("main")
--    NESBuilder:setTabQt()
    
--    local m = NESBuilder:getWindowQt()
    --y = m.height-20
--    y=726-80
    
--    control=NESBuilder:makeLabelQt{x=x,y=y,clear=true,text="Status bar",test=true}
    --control.raise()
--    statusBar = control
    handlePluginCallback("onShow")
end

function onResize(width, height, oldWidth, oldHeight)
    --print(width..' '..height)
    
    local main = NESBuilder:getWindowQt()
    main.tabParent.width = width
    main.tabParent.height = height
    statusBar.move(left, height-statusBar.height-pad)
end


function onHover(control)
    --print(control.name)
    --pcall(function()
        if type(control.helpText) == 'function' then
            statusBar.text = control.helpText() or ""
        else
            statusBar.text = control.helpText or ""
        end
    --end)
end

function addCHR_cmd()
    local control = NESBuilder:getControl('CHRList')
    
--    tableAppend(data.project.chr, NESBuilder:newCHRData())
--    local n = maxTableIndex(data.project.chr) or 0
    local n = #data.project.chr+1
    data.project.chr[n] = NESBuilder:newCHRData()
    data.project.chrNames[n] = string.format("CHR %02x", n)
    control.addItem(data.project.chrNames[n])
end

function updateCHRList()
    local control = NESBuilder:getControl('CHRList')
    control.clear()
    
    for i in ipairs_sparse(data.project.chr) do
        data.project.chrNames[i] = data.project.chrNames[i] or string.format("CHR %02x", i)
        control.addItem(data.project.chrNames[i])
    end
    
    data.project.chr.index = math.max(0, (data.project.chr.index or 0))
end


function ppLoadIPS_cmd()
    local f, filename
    local control
    
    local folder = data.folders.projects..data.project.folder
    NESBuilder:setWorkingFolder(folder)
    
    f = NESBuilder:openFile{filetypes={{"IPS Patch", ".ips"}}, initial= folder}
    if f == "" then
        print("Open cancelled.")
        return
    end
    filename = f
    
    if (not NESBuilder:fileExists(filename)) then
        print('File "'..filename..'" not found.\nSearching...')
        
        local baseFileName = pathSplit(filename)[1]
        local folders = list(data.folders.projects..data.project.folder)
        
        f = NESBuilder:findFile(baseFileName, folders)
        if f then
            filename = f
            print('Found: "'..filename..'".')
        else
            print('*** Error: Coould not find file "'..baseFileName..'".')
            return
        end
    end
    
    if fixPath(pathSplit(folder)[0]) == fixPath(pathSplit(f)[0]) then
        filename = pathSplit(filename)[1]
    end
    
    control = NESBuilder:getControl('patchesTable')
    
    tableAppend(data.project.patches, filename)
    
    control.clear()
    for i,f in ipairs_sparse(data.project.patches) do
        control.set(i,0,f)
    end
    control.update()
    
    ppUpdate()
end

function loadRom(filename)
    local f
    
    if not filename then
        f = NESBuilder:openFile{filetypes={{"NES Rom", ".nes"}}}
        if f == "" then
            print("Open cancelled.")
            return
        end
        filename = f
    end
    
    if (not NESBuilder:fileExists(filename)) and ((not data.project.incRomData) or (not data.project.rom.data)) then
        print('File "'..filename..'" not found.\nSearching...')
        
        local baseFileName = pathSplit(filename)[1]
        
        local folders = list(data.folders.projects..data.project.folder)
        
        f = NESBuilder:findFile(baseFileName, folders)
        if f then
            filename = f
            print('Found: "'..filename..'".')
        else
            print('*** Error: Coould not find file "'..baseFileName..'".')
            return
        end
    end
    
    -- make sure projects folder exists
    NESBuilder:makeDir(data.folders.projects)
    -- make sure folders exist for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    
    local fileData = NESBuilder:getFileAsArray(filename)
    
    --print(NESBuilder:getLen(fileData))
    
--    data.rom = {
--        filename = f,
--        data = fileData,
--    }
    
--    data.project.rom = {
--        filename = f
--    }
    
--    print('Rom data loaded: "'..filename..'".')
--    print(string.format('%02x bytes',len(fileData)))
    
    data.project.rom = {
        filename = filename,
        data = fileData,
    }
    
    --ppUpdate()
    ppLoad()
end

function importMultiChr_cmd()
    local chrData, chrStart, nPrg, nChr
    local f = NESBuilder:openFile{filetypes={{"CHR", ".chr"}}}
    if f == "" then
        print("Open cancelled.")
        return
    end
    local fileData = NESBuilder:getFileAsArray(f)
    
    local nChr = len(fileData) / 0x1000
    
--    nPrg = fileData[4]
--    nChr = fileData[5]
--    chrStart = 0x10 + nPrg * 0x4000
    chrStart = 0
    
    -- wipe all chr
    data.project.chr = {index=0}
    local control = NESBuilder:getControl('CHRList')
    control.clear()
    
    for i = 0,(nChr*2)-1 do
        chrData = sliceList(fileData, chrStart + i * 0x1000, chrStart + i * 0x1000 + 0x1000)
        setChrData(NESBuilder:listToTable(chrData), i)
        --if i > control.count() -1 then addCHR_cmd() end
        addCHR_cmd()
    end
    
    refreshCHR()
    NESBuilder:setWorkingFolder()
end

function importAllChr()
    local chrData, chrStart, nPrg, nChr
    local fileData = NESBuilder:tableToList(data.project.rom.data,0)
    if not fileData then
        print('Could not import CHR data')
        return
    end
    nPrg = int(fileData[4])
    nChr = int(fileData[5])
    chrStart = 0x10 + nPrg * 0x4000
    
    -- wipe all chr
    data.project.chr = {index=0}
    local control = NESBuilder:getControl('CHRList')
    control.clear()
    
    for i = 0,(nChr*2)-1 do
        chrData = sliceList(fileData, chrStart + i * 0x1000, chrStart + i * 0x1000 + 0x1000)
        setChrData(chrData, i)
        addCHR_cmd()
    end
    
    refreshCHR()
    NESBuilder:setWorkingFolder()
end

function exportAllChr()
    local chrData, chrStart, nPrg, nChr
    local fileData = data.project.rom.data
    
    if not data.project.rom.data then return end
    
    nPrg = int(fileData[4])
    nChr = int(fileData[5])
    chrStart = 0x10 + nPrg * 0x4000
    
    print(string.format('PRG: %02x', nPrg))
    print(string.format('CHR: %02x', nChr))
    print(string.format('CHR Start: %04x', chrStart))
    
    -- remove all chr
    fileData = sliceList(fileData, 0, chrStart)
    
    local npConcat = python.eval("lambda x,y: np.concatenate([x,y])")
    
    for i = 0,(nChr*2)-1 do
        if getChrData(i) then
            fileData = npConcat(fileData, getChrData(i))
        end
    end
    
    local f = getOutputBinaryFilename(true)
    data.project.rom.outputFilename = data.project.rom.outputFilename or f
    -- For now, if output path not found, use default file.
    -- This will happen if a project folder is renamed
    if not NESBuilder:pathExists(NESBuilder:pathToFolder(data.project.rom.outputFilename)) then
        data.project.rom.outputFilename = f
    end
    NESBuilder:saveArrayToFile(data.project.rom.outputFilename, fileData)
    
end



function importAllChr_cmd(t)
    local chrData
    local f = NESBuilder:openFile{filetypes={{"NES Rom", ".nes"}}}
    if f == "" then
        print("Open cancelled.")
        return
    end
    local fileData = NESBuilder:getFileAsArray(f)
    
    nPrg = int(fileData[4])
    nChr = int(fileData[5])
    chrStart = 0x10 + nPrg * 0x4000
    
    -- wipe all chr
    data.project.chr = {index=0}
    local control = NESBuilder:getControl('CHRList')
    control.clear()
    
    for i = 0,(nChr*2)-1 do
        chrData = sliceList(fileData, chrStart + i * 0x1000, chrStart + i * 0x1000 + 0x1000)
        setChrData(chrData, i)
        --addCHR_cmd()
    end
    updateCHRList()
    
    refreshCHR()
end

function exportAllChr_cmd(t)
    local chrData
    local f = NESBuilder:saveFileAs{filetypes={{"NES Rom", ".nes"}}}
    if f == "" then
        print("Open cancelled.")
        return
    end
    local fileData = NESBuilder:getFileAsArray(f)
    
    nPrg = fileData[4]
    nChr = fileData[5]
    chrStart = 0x10 + nPrg * 0x4000
    
    -- remove all chr
    fileData = sliceList(fileData, 0, chrStart)
    
    for i = 0,(nChr*2)-1 do
        fileData = joinList(fileData, NESBuilder:tableToList(getChrData(i), 0))
    end
    NESBuilder:saveArrayToFile(f, fileData)
end

function getRomData()
    if data.project.rom and data.project.rom.data then
        return data.project.rom.data
    end
end

function getRomFilename()
    if data.project.rom and data.project.rom.filename then
        return data.project.rom.filename
    end
end

function ppAssembler_cmd(t)
    data.project.assembler = t.control.value
end

function hidePlugin(pluginName)
    local control = NESBuilder:getWindowQt()
    
    if not plugins[pluginName] then
        print(string.format("[hidePlugin] no such plugin: %s", pluginName))
        return
    end

    for i,v in ipairs(plugins[pluginName].tabs or {}) do
        -- hide plugin's generated tabs
        toggleTab(v, false)
        -- hide view menu entries
        control.menus['menuView'].actions[v].setVisible(false)
    end
    
    -- run callback for just this plugin
    if plugins[pluginName].onDisablePlugin then plugins[pluginName].onDisablePlugin() end
    
    plugins[pluginName].hide = true
end

function showPlugin(pluginName)
    local control = NESBuilder:getWindowQt()
    
    if not plugins[pluginName] then
        print(string.format("[showPlugin] no such plugin: %s", pluginName))
        return
    end

    for i,v in ipairs(plugins[pluginName].tabs or {}) do
        -- show plugin's generated tabs
        --toggleTab(v, false)
        
        -- show view menu entries
        control.menus['menuView'].actions[v].setVisible(true)
    end
    
    plugins[pluginName].hide = false
    
    -- run callback for just this plugin
    if plugins[pluginName].onEnablePlugin then plugins[pluginName].onEnablePlugin() end
end

function removePlugin(pluginName)
    if not plugins[pluginName] then
        print(string.format("[removePlugin] no such plugin: %s", pluginName))
        return
    end
    
    print('remove plugin '..pluginName)
    
    -- close plugin's generated tabs
    for i,v in ipairs(plugins[pluginName].tabs or {}) do
        closeTab(v)
    end
    
    -- remove view menu entries
    local control = NESBuilder:getWindowQt()
    local popItem = python.eval("lambda d,k: d.pop(k)")
    -- generate a list of keys to remove
    local keys = {}
    for k,v in iterItems(control.tabs) do
        if not v then
            control.menus['menuView'].removeAction(control.menus['menuView'].actions[k])
            table.insert(keys, k)
        end
    end
    
    -- remove empty entries from control.tabs
    for i, k in ipairs(keys) do
        popItem(control.tabs, k)
    end
    
    -- todo: remove generated menu items
    
    -- This is specifically for unloading a plugin
    -- Not for cleanup when exiting.
    handlePluginCallback("onUnload")
    
    -- remove plugin
    plugins[pluginName] = nil
end

function pluginsList()
    local l = cfgGet('plugins', 'list')
    if l == nil or l == '' then return list() end
    if type(l) ~= 'list' then
        l = python.eval('lambda x:[x]')(l)
    end
    return l
end


function testError_cmd(t)
    --doesntexist()
    print(reverseByte('potato'))
end


function exportPalettes(filename)
    local c = NESBuilder:getControl('PaletteList')
    
    filename = filename or "code/palettes.asm"
    filename = data.folders.projects..data.project.folder..filename
    local out=""
    
    out = out .. "; ========================================\n"
    out = out .. "; Palettes\n"
    out = out .. "; ========================================\n"
    out = out .. makePointerTableNoSplit('PaletteSets', 'PalSet', iLength(data.project.paletteSets))
    
    
    for k, pSet in ipairs(data.project.paletteSets) do
        local palNum = k-1
        out = out .. "; ----------------------------------------\n"
        out = out .. string.format("; %s\n",pSet.name)
        out = out .. "; ----------------------------------------\n"
        
        out = out .. makePointerTableNoSplit(string.format("PalSet%02x",palNum), string.format("PalSet%02x_",palNum), iLength(pSet.palettes))
        
        for index, pal in iterItems(pSet.palettes) do
            out=out..string.format("PalSet%02x_%02x: db ", palNum, index-1)
            for i=1,4 do
                out=out..string.format("$%02x",pal[i])
                if i==4 then
                    out=out.."\n"
                else
                    out=out..", "
                end
            end
        end
        out=out.."\n"
    end
    
    -- for compatability
--    local pSet = data.project.paletteSets[data.project.paletteSets.index+1]
--    out = out .. "; ========================================\n"
--    out = out .. string.format("; default palette / compatability\n; (%s)\n",pSet.name)
--    out = out .. "; ========================================\n"
    
--    out = out .. makePointerTable('Palettes', string.format("PalSet%02x_",pSet.index), iLength(pSet.palettes))
    
    out = out .. "; ----------------------------------------\n"
    out = out .. "; constants\n"
    out = out .. "; (copy these to your constants)\n"
    out = out .. "; ----------------------------------------\n"
    for k, pSet in ipairs(data.project.paletteSets) do
        out = out .. string.format(";%s = %s\n",makeSymbolName("palette", pSet.name), k-1)
    end
    
    
    print("File created "..filename)
    util.writeToFile(filename,0, out, true)
end

function askText(title, text, defaultText)
    local t = NESBuilder:askText(title or "Text Entry", text, defaultText)
    --if (not t) or t=='' then
    if (not t) then
        print('cancelled')
        return
    end
    return t
end

function makePointerTable(mainLabel, subLabel, nItems)
    local out = ''
    local lowHigh = {{"low","<"},{"high",">"}}
    
    subLabel = subLabel or mainLabel
    
    for i = 1,2 do
        out=out..string.format("%s_%s:\n",mainLabel, lowHigh[i][1])
        for itemIndex=0, nItems-1 do
            if itemIndex == 0 then
                out=out.."    .db "
            elseif itemIndex % 4 == 0 then
                out=out.."\n    .db "
            else
                out=out..", "
            end
            out=out..string.format("%s%s%02x",lowHigh[i][2], subLabel, itemIndex)
            if itemIndex==nItems-1 then
                out=out.."\n"
            end
        end
        out=out.."\n"
    end
    return out
end

function makePointerTableNoSplit(mainLabel, subLabel, nItems)
    local out = ''
    subLabel = subLabel or mainLabel
    
    out=out..string.format("%s:\n",mainLabel)
    for itemIndex=0, nItems-1 do
        if itemIndex == 0 then
            out=out.."    dw "
        elseif itemIndex % 4 == 0 then
            out=out.."\n    dw "
        else
            out=out..", "
        end
        out=out..string.format("%s%02x", subLabel, itemIndex)
        if itemIndex==nItems-1 then
            out=out.."\n"
        end
    end
    out=out.."\n"
    return out
end

function getNESPalette()
    local _nesPalette = NESBuilder.palette.get()
    
    local pal = {}
    for i=0,63 do
        pal[i] = {
            _nesPalette[i][0],
            _nesPalette[i][1],
            _nesPalette[i][2],
            index = i,
        }
    end
    
    -- compatability
    nespalette = pal
    
    return pal
end

function makeSymbolName(prefix, txt)
    txt = replace(txt, ' ','_')
    if prefix then
        prefix = replace(prefix, ' ','_')
        txt = prefix..'_'..txt
    end
    
    return txt
end

-- Get project folder
function getProjectFolder()
    return data.folders.projects..data.project.folder
end

-- Set working folder to project folder
function setProjectFolder()
    local folder = data.folders.projects..data.project.folder
    NESBuilder:setWorkingFolder(folder)
    
    -- returns folder as a convenience
    return folder
end