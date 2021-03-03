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
    colors = {
        bk='#202036',
        bk2='#303046',
        bk3='#404050',      -- text background
        bk4='#656570',
        bk_hover='#454560',
        fg = '#eef',
        menuBk='#404056',
        bk_menu_highlight='#606080',
        tkDefault='#656570',
        link='#88f',
        linkHover='white',
        borderLight='#56565a',
        borderDark='#101020',
        textInputBorder='#99a',
    },
    pluginFolder = "plugins", -- this one is for python
    nRecentFiles = 20,
    defaultAssembler = 'sdasm',
}

config.pad = 6
config.left = config.pad*1.5
config.top = config.pad*1.5


config.launchText=[[
Created by SpiderDave
-------------------------------------------------------------------------------------------
NESBuilder is a NES development tool.

The goal of NESBuilder is to make NES development easier, with a goal of
helping create a NES game from start to finish.

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

local foo=42
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
    plugins = config.pluginFolder.."/",
}

data.project = {chr={}}

nespalette={[0]=
{0x74,0x74,0x74},{0x24,0x18,0x8c},{0x00,0x00,0xa8},{0x44,0x00,0x9c},
{0x8c,0x00,0x74},{0xa8,0x00,0x10},{0xa4,0x00,0x00},{0x7c,0x08,0x00},
{0x40,0x2c,0x00},{0x00,0x44,0x00},{0x00,0x50,0x00},{0x00,0x3c,0x14},
{0x18,0x3c,0x5c},{0x00,0x00,0x00},{0x00,0x00,0x00},{0x00,0x00,0x00},
{0xbc,0xbc,0xbc},{0x00,0x70,0xec},{0x20,0x38,0xec},{0x80,0x00,0xf0},
{0xbc,0x00,0xbc},{0xe4,0x00,0x58},{0xd8,0x28,0x00},{0xc8,0x4c,0x0c},
{0x88,0x70,0x00},{0x00,0x94,0x00},{0x00,0xa8,0x00},{0x00,0x90,0x38},
{0x00,0x80,0x88},{0x00,0x00,0x00},{0x00,0x00,0x00},{0x00,0x00,0x00},
{0xfc,0xfc,0xfc},{0x3c,0xbc,0xfc},{0x5c,0x94,0xfc},{0xcc,0x88,0xfc},
{0xf4,0x78,0xfc},{0xfc,0x74,0xb4},{0xfc,0x74,0x60},{0xfc,0x98,0x38},
{0xf0,0xbc,0x3c},{0x80,0xd0,0x10},{0x4c,0xdc,0x48},{0x58,0xf8,0x98},
{0x00,0xe8,0xd8},{0x78,0x78,0x78},{0x00,0x00,0x00},{0x00,0x00,0x00},
{0xfc,0xfc,0xfc},{0xa8,0xe4,0xfc},{0xc4,0xd4,0xfc},{0xd4,0xc8,0xfc},
{0xfc,0xc4,0xfc},{0xfc,0xc4,0xd8},{0xfc,0xbc,0xb0},{0xfc,0xd8,0xa8},
{0xfc,0xe4,0xa0},{0xe0,0xfc,0xa0},{0xa8,0xf0,0xbc},{0xb0,0xfc,0xcc},
{0x9c,0xfc,0xf0},{0xc4,0xc4,0xc4},{0x00,0x00,0x00},{0x00,0x00,0x00},
}

for i=0,#nespalette do
    nespalette[i].index = i
end

function init()
    local x,y,pad
    local control, b, c
    local top,left
    pad=6
    top = pad*1.5
    left = pad*1.5
    x,y=left,top
    
    local buttonWidth = config.buttonWidth*7.5
    local buttonHeight = 27
    
    print("init")
    
    -- Tab close buttons aren't done yet.
    --if not devMode() then
    if true then
        local main = NESBuilder:getWindowQt()
        main.tabParent.self.setTabsClosable(false)
        main.update()
    end
    
    NESBuilder:incLua("Tserial")
    util = NESBuilder:incLua("util")
    
    ipairs_sparse = util.ipairs_sparse
    
    -- make sure projects folder exists
    NESBuilder:makeDir(data.folders.projects)
    
    statusBar=NESBuilder:makeLabelQt{x=x,y=y,text="Status bar"}
    statusBar.setFont("Verdana", 10)
    
    if cfgGet('alphawarning')==1 then
        control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Warning",text="Warning"}
    end
    
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Launcher",text="Launcher"}
    launchTab = control
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Palette",text="Palette"}
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Image",text="CHR"}
    control = NESBuilder:makeTab{x=x,y=y,w=config.width,h=config.height,name="Symbols",text="Symbols"}
    
    local items
    -- The separator and Quit items will be added
    -- in onReady() so plugins can add items before them.
    items = {
        {name="New", text="New Project"},
        {name="Open", text="Open Project"},
        {name="Save", text="Save Project"},
        {name="Preferences", text="Preferences"},
    }
    control = NESBuilder:makeMenuQt{name="menuFile", text="File", menuItems=items}
    
    items = {
        {name="hFlip", text="Flip tile horizontally"},
        {name="vFlip", text="Flip tile vertically"},
    }
    control = NESBuilder:makeMenuQt{name="menuEdit", text="Edit", menuItems=items}
    
    
    --control.control.setEnable(false)
    --local f = python.eval("lambda x: x[0]")
    --print(control)
    --print(f(control))
    
    items = {
        {name="Build", text="Build"},
        {name="BuildTest", text="Build and Test"},
        {name="TestRom", text="Re-Test Last"},
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
        b=NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight,name="buttonWarningClose",text="close"}

    end
    
    local items = {}
    control = NESBuilder:makeMenuQt{name="menuView",text="View", menuItems=items}
    
    NESBuilder:setTabQt("Image")
    x,y=8,8
    control=NESBuilder:makeCanvasQt{x=x,y=y,w=128,h=128,name="canvasQt", scale=3}
    --NESBuilder:setCanvas("canvas")
    --control.setCursor('pencil')
    --control.setCursor('ArrowCursor')
    --control.setCursor('OpenHandCursor')
    
    x=x+control.width
    y=y+control.height+pad
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=8,h=8,name="canvasTile", scale=8}
    control.setCursor('pencil')
    
    -- right align it with the above canvas
    control.move(x-control.width,y)
    
    x,y = left,top
    
    NESBuilder:setTabQt("Palette")
    NESBuilder:setDirection("h")
    x,y=left,top
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    control=NESBuilder:makePaletteControlQt{x=pad*1.5,y=pad*1.5,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="PaletteQt", palette=nespalette, upperHex=cfgGet('upperhex')}
    control.helpText = "Click to select a color"
    
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    
    placeX = left
    placeY = top
    
    x=left
    y=top + 100+pad*1.5
    local buttonHeight = config.buttonHeight
    
    control = NESBuilder:makeSideSpin{x=x,y=y,w=buttonHeight*3,h=buttonHeight, name="SpinChangePalette"}
    
    x = x + control.width + pad
    b=NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidthSmall*1.5,name="ButtonAddPalette",text="Add"}
    
    x = left
    y = y + b.height + pad
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    control=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="PaletteEntryQt", palette=palette}
    control.helpText = "Click to apply a color, right click to select a color"
    
    push(y+control.height+pad)

    x=x+control.width+pad
    c=NESBuilder:makeLabelQt{x=x,y=y+pad,name="PaletteEntryLabelQt",clear=true,text="foobar"}
    c.setFont("Verdana", 10)

    x=left
    y=pop()
    
    NESBuilder:setTabQt("Image")
    p = {[0]=0x0f,0x21,0x11,0x01}
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end

    x=pad
    y=pad+128*3+pad*1.5
    placeY = y
    c=NESBuilder:makePaletteControlQt{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="CHRPaletteQt", palette=palette}
    
    x=left + 120
    y=placeY
    b=NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidthSmall,name="ButtonPrevPaletteCHR",text="<"}

    x=x+b.width+pad
    y=placeY
    b=NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidthSmall,name="ButtonNextPaletteCHR",text=">"}

    x=left
    
    y = y + 32 + pad
    b=NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth,name="LoadCHRImage",text="Load Image"}

    y = y + b.height + pad
    b=NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth,name="LoadCHRNESmaker",text="Load NESmaker Image"}

    y = y + b.height + pad
    
    b=NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth,name="LoadCHR",text="Load .chr"}
    y = y + b.height + pad
    
    b=NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth,name="ExportCHR",text="Export"}
    y = y + b.height + pad
    
    x=128*3+pad*3
    y=top
    c=NESBuilder:makeLabelQt{x=x,y=y,name="CHRNumLabelQt",clear=true,text="CHR"}
    y = y + buttonHeight
    
    --y=top
    x=128*3+pad*3
    
    --  Yes, we're cheating with Python here.
    local l = python.eval('["CHR {0:02n}".format(x) for x in range(8)]')
    
    control = NESBuilder:makeList{x=x,y=y,w=buttonWidth,h=buttonHeight*12, name="CHRList",list = l}
    push(y + control.height + pad, x)
    
    x=x + control.width + pad*.5
    b=NESBuilder:makeButtonQt{x=x,y=y,w=30,name="addCHR",text="+"}
    
    x,y = pop(2)
    
    control = NESBuilder:makeLineEdit{x=x,y=y,w=control.width,h=inputHeight, name="CHRName"}
    y = y + control.height + pad
    
    NESBuilder:setTabQt("Symbols")
    left = pad*2
    top = pad*2
    x,y,pad = left,top,8
    control = NESBuilder:makeTable{x=x,y=y,w=buttonWidth*4,h=buttonHeight*20, name="symbolsTable1",rows=100, columns=3}
    control.setHorizontalHeaderLabels("Symbol", "Value", "Comment")
    y = y + control.height + pad
    
    NESBuilder:setTabQt("Launcher")
    left = pad*2
    top = pad*2
    x,y,pad = left,top,8
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
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=190,h=64, name="launcherButtonRecent",text="Recent Projects", image="icons/clock32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=190,h=64, name="launcherButtonOpen",text="Open Project", image="icons/folder32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=190,h=64, name="launcherButtonNew",text="New Project", image="icons/folderplus32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=190,h=64, name="launcherButtonTemplates",text="Templates", image="icons/folder32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=190,h=64, name="launcherButtonPreferences",text="Preferences", image="icons/gear32.png", iconMod=true}
    y = y + control.height + pad
    control = NESBuilder:makeButtonQt{x=x,y=y,w=190,h=64, name="launcherButtonInfo",text="About", image="icons/note32.png", iconMod=true}
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
    
    local columns = 5
    local rows = 4
    recentData = {}
    
    for i = 1,rows*columns do
        recentData[i-1]={}
        x = ((i-1) % columns)*105 + pad
        y = math.floor((i-1)/columns)*130
        
        control = NESBuilder:makeLauncherIcon{x=x,y=y,h=120, w=90, name="launcherRecentIcon", index=i-1}
        recentData[i-1].icon = control
        
        y=y+control.height-25
        control = NESBuilder:makeLabelQt{x=x,y=y, name="launcherRecentLabel",text="", class="launcherText"}
        control.autoSize = false
        control.width = 90
        control.height=20
        
        recentData[i-1].label = control
    end
    
    NESBuilder:setContainer(data.launchFrames.new)
    for i, item in ipairs(data.projectTypes) do
        --recentData[i-1]={}
        x = ((i-1) % columns)*105 + pad
        y = math.floor((i-1)/columns)*130
        
        control = NESBuilder:makeLauncherIcon{x=x,y=y,h=120, w=90, name="launcherProjectType", index=i-1}
        control.helpText = item.helpText

        y=y+control.height-25
        control = NESBuilder:makeLabelQt{x=x,y=y, name="launcherRecentLabel", text=item.text, class="launcherText"}
        control.autoSize = false
        control.width = 90
        control.height=20

    end
    
    NESBuilder:makeTab{name="Metatiles", text="Metatiles"}
    NESBuilder:setTabQt("Metatiles")
    
    x,y=left,top
    
    push(y)
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=128,h=128,name="tsaCanvasQt", scale=2}
    push(x+control.width+pad)
    
    x = left
    y=y + control.height + pad
    
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=8,h=8,name="tsaTileCanvasQt", scale=8, columns=1, rows=1}
    
    y=y + control.height + pad
    
--    push(y)
--    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidthSmall, name="tsaSquareoidPrev",text="<"}
--    y=pop()
--    x= x + control.width+pad
    
--    push(y)
--    control=NESBuilder:makeLineEdit{x=x,y=y,w=20,h=buttonHeight, name="tsaSquareoidNumber",text="0"}
--    y=pop()
--    x= x + control.width+pad
    
--    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidthSmall, name="tsaSquareoidNext",text=">"}
--    x = left
--    y = y + control.height + pad
    
--    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth, name="tsaTest",text="Update"}
    
    x = pop()
    y = pop()
    push(x)
    
    control = NESBuilder:makeCanvasQt{x=x,y=y,w=16,h=16,name="tsaCanvas2Qt", scale=6}
    y = y + control.height + pad
    
    push(y)
    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidthSmall, name="tsaSquareoidPrev",text="<"}
    y=pop()
    x= x + control.width+pad
    
    push(y)
    control=NESBuilder:makeLineEdit{x=x,y=y,w=20,h=buttonHeight, name="tsaSquareoidNumber",text="0"}
    y=pop()
    x= x + control.width+pad
    
    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidthSmall, name="tsaSquareoidNext",text=">"}
    --x = pop()
    --y = y + control.height + pad
    
    x = x + control.width + pad
    y = top
    push(y)
    
    control = NESBuilder:makeList{x=x,y=y,w=buttonWidth,h=buttonHeight*12, name="mTileList", list = l}
    x = x + control.width + pad
    y = pop()
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=30,name="addMTile",text="+"}
    
    --control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth, name="tsaTest",text="Update"}
    
    data.launchFrames.set('recent')
    
    loadSettings()
end

function onPluginsLoaded()
    handlePluginCallback("onInit")
end

function onReady()
    local items = {
        {text="-"},
        {name="Quit", text="Exit"},
    }
    control = NESBuilder:makeMenuQt{name="menuFile", text="File", menuItems=items}
    
    local items = {
        {text="-"},
        {name="openProjectFolder", text="Open Project Folder"},
        {name="projectProperties", text="Project Properties"},
    }
    control = NESBuilder:makeMenuQt{name="menuProject", text="Project", menuItems=items}
    
    local items = {
        {name="importAllChr", text="Import all CHR from .nes"},
        {name="exportAllChr", text="Export all CHR to .nes"},
        {name="importMultiChr", text="Import all CHR from .chr"},
    }
    control = NESBuilder:makeMenuQt{name="menuTools",text="Tools", menuItems=items}
    
    local items = {
        {name="About", text="About"},
    }
    control = NESBuilder:makeMenuQt{name="menuHelp", text="Help", menuItems=items}
    
    local items = {}
    local control = NESBuilder:getWindowQt()
    for k, v in iterItems(control.tabs) do
        table.insert(items, {name=k, text=v.title, action = function() toggleTab(k) end, checked = true})
    end
    control = NESBuilder:makeMenuQt{name="menuView",text="View", menuItems=items}
    
    handlePluginCallback("onReady")
    LoadProject()
    
    if cfgGet('autosave')==1 then
        local main = NESBuilder:getWindowQt()
        -- minimum auto save interval is 45 seconds
        main.setTimer(math.max(cfgGet('autosaveinterval'), 1000*45), autoSave, true)
    end
    
    -- Just remove Metatiles tab since it's broken.
    --if not devMode() then closeTab('Metatiles') end

    NESBuilder:switchTab("Launcher")
end

function toggleTab(n, visible)
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
        control.tabParent.insertTab(tab.index, tab, tab.title)
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
            print(string.format("(Plugin %s): %s",n,f))
            plugins[n][f](arg)
        end
    end
end

function loadSettings()
    data.projectID = NESBuilder:cfgGetValue("main", "project", data.projectID)

    -- load recent projects list
    local k,v
    for i=1, config.nRecentFiles do
        k = string.format("recentproject%d", i)
        v = NESBuilder:cfgGetValue("main", k, false)
        if not v then break end
        recentProjects.push(v)
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
        
        local functionName = t.functionName or t.name
        
        pcall(function()
            t.event.button = t.event.event.button()
        end)
        
        if t.event and (t.event.type == "ButtonPress" or t.event.type=="") then
            print("doCommand "..functionName)
        else
            print("doCommand "..functionName)
        end
        if t.plugin then
            if t.plugin[functionName.."_cmd"] then
                t.plugin[functionName.."_cmd"](t)
                return false
            end
        end
    end
    return true
end

function PaletteQt_cmd(t)
    local event = t.cell.event
    if event.button == 1 or event.button == 2 then
        print(string.format("Selected palette %02x",t.cellNum))
        data.selectedColor = t.cellNum
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

CHRPaletteQt_cmd = CHRPalette_cmd

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

function ButtonAddPalette_cmd()
    p = {0x0f,0x20,0x10,0x00}
    table.insert(data.project.palettes, p)

    local control = NESBuilder:getControlNew('SpinChangePalette')
    control.max = #data.project.palettes

    dataChanged()
end

function PaletteEntryUpdate()
    --print('PeltteEntryUpdate()')
    local control = NESBuilder:getControlNew('SpinChangePalette')
    control.max = #data.project.palettes
    control.value = data.project.palettes.index
    
    p=currentPalette()
    
--    c = NESBuilder:getControl('PaletteEntry')
--    c.setAll(p)
    
    NESBuilder:getControlNew('PaletteEntryQt').setAll(p)

--    c = NESBuilder:getControl('CHRPalette')
--    c.setAll(p)
    NESBuilder:getControlNew('CHRPaletteQt').setAll(p)
    
--    c = NESBuilder:getControl('PaletteEntryLabel')
--    c.control.text = string.format("Palette%02x",data.project.palettes.index)
    
    c = NESBuilder:getControlNew('PaletteEntryLabelQt')
    c.text = string.format("Palette%02x",data.project.palettes.index)
    --c.setText('blah')
    
    handlePluginCallback("onPaletteChange")

    refreshCHR()
end

function SpinChangePalette_cmd(t)
    t.control.max = #data.project.palettes
    t.control.refresh()
    
    data.project.palettes.index = t.control.value
    --print('------')
    PaletteEntryUpdate()
end

function ButtonPrevPalette_cmd()
    c = NESBuilder:getControl('PaletteEntry')
    
    data.project.palettes.index = data.project.palettes.index-1
    if data.project.palettes.index < 0 then data.project.palettes.index= 0 end
    print(data.project.palettes.index)
    
    PaletteEntryUpdate()
end

function ButtonNextPalette_cmd(t)
    c = NESBuilder:getControl('PaletteEntry')
    
    data.project.palettes.index = data.project.palettes.index+1
    if data.project.palettes.index > #data.project.palettes then data.project.palettes.index = #data.project.palettes end
    if data.project.palettes.index > 255 then data.project.palettes.index = 255 end
    print(data.project.palettes.index)
    
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

    n = NESBuilder:askText("New Project", "Please enter a name for the project")
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
    data.project.rom = nil
    
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
    data.launchFrames.set('templates')
end

function launcherProjectType_cmd(t)
    data.projectType = data.projectTypes[t.index+1].name
    if data.projectType == 'dev' then
        NewProject_cmd()
    elseif data.projectType == 'romhack' then
        NewProject_cmd()
    end
end

function projectProperties_cmd()
    local x,y,left,top,pad,control
    pad = 6
    left = pad*2
    top = pad*2
    x,y = left,top
    local buttonWidth = config.buttonWidth*7.5
    local buttonHeight = 27

--    NESBuilder:makeWindow{x=0,y=0,w=760,h=600, name="prefWindow",title="Preferences"}
--    NESBuilder:setWindow("prefWindow")
    
    NESBuilder:makeTabQt{name="tabProjectProperties",text="Project Properties"}
    setTab("tabProjectProperties")
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight, name="ppLoadRom",text="Load ROM"}
    x = x + control.width + pad
    push(y + control.height + pad)
    control = NESBuilder:makeLabelQt{x=x,y=y, name = "ppRomFile", clear=true, text=data.project.rom.filename}
    control.setFont("Verdana", 10)
    
    x=left
    y=pop()
    
    control = NESBuilder:makeCheckbox{x=x,y=y,name="ppRomDataInc", text="Save ROM data with project", value=bool(data.project.incRomData)}
    y = y + control.height + pad
    
    if devMode() then
        control = NESBuilder:makeLabelQt{x=x,y=y, clear=true, text="Assembler"}
        control.setFont("Verdana", 10)
        push(x)
        x = x + control.width + pad
        control = NESBuilder:makeComboBox{x=x,y=y,w=buttonWidth, name="ppAssembler", text="Test", itemList = {'sdasm','asm6','xkasplus'}}
        y = y + control.height + pad
        x=pop()
    end
    
    
    control.setByText(data.project.assembler)
    
--    control = NESBuilder:makeCheckbox{x=x,y=y,name="pptest1", text="Test", value=cfgGet('test')}
--    y = y + control.height + pad
    
    control = NESBuilder:makeTable{x=x,y=y,w=buttonWidth*4,h=buttonHeight*8, name="patchesTable",rows=100, columns=1}
    control.setHorizontalHeaderLabels("IPS patches")
    local header = control.horizontalHeader()
    header.setStretchLastSection(true)
    
    control.clear()
    for i,f in pairs(data.project.patches) do
        control.set(i,0,f)
    end
    
    y = y + control.height + pad
    
    y = y + pad*7
    b=NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight,name="ppClose",text="close"}
    
    NESBuilder:switchTab("tabProjectProperties")
end

function ppRomDataInc_cmd(t)
    data.project.incRomData = t.isChecked()
end

function launcherButtonPreferences_cmd()
    local x,y,left,top,pad,control
    pad = 6
    left = pad*2
    top = pad*2
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
    for file in python.iter(cfgGet('plugins', 'list')) do
        control = NESBuilder:makeCheckbox{x=x,y=y,name='prefPlugin_'.. replace(replace(file, '.','_'), '_lua', ''), text=file, value=cfgGet('plugins', file), file=file, functionName='prefEnablePlugin'}
        y = y + control.height + pad
    end
    x=pop()
    
    y = y + pad * 8
    control = NESBuilder:makeLabelQt{x=x,y=y, clear=true,text="Note: Some preferences may require a restart."}
    y = y + control.height + pad
    b=NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight,name="buttonPreferencesClose",text="close"}
    
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


function launcherButtonInfo_cmd()
    local x,y,left,top,pad
    pad = 6
    left = pad*2
    top = pad*2
    x,y = left,top

    NESBuilder:makeTab{name="infoTab", text="Info"}
    NESBuilder:setTabQt("infoTab")

--    NESBuilder:makeWindow{x=0,y=0,w=760,h=600, name="infoWindow",title="Info"}
--    NESBuilder:setWindow("infoWindow")

    control = NESBuilder:makeLabelQt{x=x,y=y,name="launchLabel",clear=true,text="NESBuilder"}
    control.setFont("Verdana", 24)
    
    y = y + control.height + pad*1.5
    
    control = NESBuilder:makeLabelQt{x=x,y=y,name="launchLabel2",clear=true,text=config.launchText}
    control.setFont("Verdana", 12)
    
    y = y + control.height + pad
    control = NESBuilder:makeLink{x=x,y=y,name="launcherLink",clear=true,text="NESBuilder on GitHub", url=config.aboutURL}
    control.setFont("Verdana", 12)
    
    y = y + control.height + pad*8
    b=NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight,name="buttonInfoClose",text="close"}
    
    NESBuilder:switchTab("infoTab")
end

function New_cmd()
    data.launchFrames.set('new')
    NESBuilder:switchTab("Launcher")
end

function OpenProject_cmd() Open_cmd() end
function BuildProjectTest_cmd() BuildTest_cmd() end
function Save_cmd() SaveProject() end

function openProjectFolder_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    NESBuilder:shellOpen(workingFolder, data.folders.projects..data.project.folder)
end

function Build_cmd() BuildProject() end

function BuildTest_cmd()
    BuildProject()
    TestRom_cmd()
end

function TestRom_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    local f = data.folders.projects..data.project.folder.."game.nes"
    print("shellOpen "..f)
    NESBuilder:shellOpen(workingFolder, f)
end

function BuildProject()
    ppUpdate()
    
    NESBuilder:setWorkingFolder()
    
    -- make sure folders exist for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."chr")
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."code")
    
    local folder = data.folders.projects..data.project.folder
    
    -- remove old game.nes
    NESBuilder:delete(folder.."game.nes")
    
    handlePluginCallback("onBuild")
    
    if data.project.type == 'dev' then
        BuildProject_cmd()
    elseif data.project.type == 'romhack' then
        -- export chr to rom and build game.nes
        exportAllChr()
        build_sdasm()
    end
end

function build_sdasm()
    local n
    
    local folder = data.folders.projects..data.project.folder
    
    NESBuilder:setWorkingFolder()
    
    saveChr()
    
    -- create default code
    if not NESBuilder:fileExists(folder.."project.asm") then
        print("project.asm not found, extracting code template...")
        --NESBuilder:extractAll('templates/romhack_xkasplus1.zip',folder)
        NESBuilder:extractAll('templates/romhack_sdasm1.zip',folder)
    end
    
    local filename = data.folders.projects..projectFolder.."code/symbols.asm"
    out=""
    local d = NESBuilder:getControlNew('symbolsTable1').getData()
    for i, row in python.enumerate(d) do
        k,v,comment = row[0],row[1],row[2]
        if k~='' then
            if comment~='' then
                out = out .. string.format("%s = %s ; %s\n",k,v or 0,comment)
            else
                out = out .. string.format("%s = %s\n",k,v or 0)
            end
        end
    end
    util.writeToFile(filename,0, out, true)
    
    -- Make metatilesXX.asm
    for tileSet=0, #data.project.mTileSets do
        if #data.project.mTileSets[tileSet] > 0 then
            filename = data.folders.projects..projectFolder..string.format("code/metatiles%02x.asm",tileSet)
            
            n = data.project.mTileSets[tileSet].name or string.format("Metatiles%02x",tileSet)
            out = string.format("    ; %s\n",n)
            for i=0, #data.project.mTileSets[tileSet] do
                local tile = data.project.mTileSets[tileSet][i]
                if tile then
                    out=out..string.format('    .db $%02x, $%02x, $%02x, $%02x\n',tile[0], tile[1], tile[2], tile[3])
                end
            end
            util.writeToFile(filename,0, out, true)
        end
    end
    
    -- Make metatiles.asm
    out = ''
    filename = data.folders.projects..projectFolder.."code/metatiles.asm"
    for tileSet=0, #data.project.mTileSets do
        if #data.project.mTileSets[tileSet] > 0 then
            n = data.project.mTileSets[tileSet].name or string.format("Metatiles%02x",tileSet)            
            out = out .. string.format("%s:\n",n)
            out = out .. string.format('include "code/metatiles%02x.asm"\n\n',tileSet)
        end
    end
    if out ~= '' then util.writeToFile(filename,0, out, true) end
    
    NESBuilder:setWorkingFolder(folder)
    
    if data.project.assembler == 'asm6' then
        local cmd = data.folders.tools.."asm6.exe"
        local args = "-L project.asm game.nes list.txt"
        print("Starting asm 6...")
        
        NESBuilder:run(folder, cmd, args)
    elseif data.project.assembler == 'xkasplus' then
        local cmd = data.folders.tools.."xkas-plus/xkas.exe"
        local args = "-o game.nes project.asm"
        print("Starting xkas plus...")
        
        NESBuilder:run(folder, cmd, args)
    elseif data.project.assembler == 'sdasm' then
    
        local sdasm = python.eval('sdasm')
        local fixPath = python.eval('fixPath2')
        local romData = data.project.rom.data
        
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
        
        -- Start assembling with sdasm
        print("Assembling with sdasm...")
        
        sdasm.assemble('project.asm', 'game.nes', 'output.txt', fixPath(data.folders.projects..projectFolder..'config.ini'), romData)
    else
        print('invalid assembler '..data.project.assembler)
    end
    
    print("done.")
end


function saveChr()
    if #data.project.chr == 0 then return end
    
    -- make sure folders exist for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."chr")
    --NESBuilder:makeDir(data.folders.projects..data.project.folder.."code")

    -- save CHR
    local filename = data.folders.projects..projectFolder.."chr/chr.asm"
    local out = 'chr 0\n'
    for i in ipairs_sparse(data.project.chr) do
        if data.project.chr[i] then
            local f = data.folders.projects..data.project.folder..string.format("chr/chr%02x.chr",i)
            print("File created "..f)
            print(data.project.chr[i][0])
            NESBuilder:saveArrayToFile(f, data.project.chr[i])
            out = out..string.format('    incbin "chr%02x.chr"  ; %s\n',i, data.project.chrNames[i])
        end
    end
    util.writeToFile(filename,0, out, true)
end

function BuildProject_cmd()
    local out = ""
    local filename
    print("building project...")
    
    refreshCHR()
    
    NESBuilder:setWorkingFolder()
    
    -- make sure folders exist for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."chr")
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."code")
    
    local folder = data.folders.projects..data.project.folder
    
    handlePluginCallback("onBuild")
    
    -- create default code
    if not NESBuilder:fileExists(folder.."project.asm") then
        print("project.asm not found, extracting code template...")
        --NESBuilder:extractAll('codeTemplate.zip',folder)
        --NESBuilder:extractAll('codeTemplate2.zip',folder)
        NESBuilder:extractAll('templates/codeTemplate3.zip',folder)
    end
    
    local out = ''
    
    saveChr()
    -- save CHR
--    for i=0,#data.project.chr do
--        if data.project.chr[i] then
--            local f = data.folders.projects..data.project.folder..string.format("chr/chr%02x.chr",i)
--            print("File created "..f)
--            print(data.project.chr[i][0])
--            NESBuilder:saveArrayToFile(f, data.project.chr[i])
--            out = out..string.format("    .incbin chr/chr%02x.chr\n",i)
--        end
--    end
    
    if #data.project.chr == 1 then
        -- add 3 more
        out = out..string.format("    .incbin chr/chr00.chr\n",i)
        out = out..string.format("    .incbin chr/chr00.chr\n",i)
        out = out..string.format("    .incbin chr/chr00.chr\n",i)
    elseif #data.project.chr == 2 then
        -- add 2 more
        out = out..string.format("    .incbin chr/chr00.chr\n",i)
        out = out..string.format("    .incbin chr/chr01.chr\n",i)
    end
    
    out = out .. '\n'
    
    filename = data.folders.projects..projectFolder.."code/chrlist.asm"
    util.writeToFile(filename,0, out, true)
    
    data.project.const.nChr = len(data.project.chr)
    if data.project.chr[0] then data.project.const.nChr = data.project.const.nChr+1 end
    
    local c = NESBuilder:getControl('PaletteList')
    filename = data.folders.projects..projectFolder.."code/palettes.asm"

    out=""
    
    local lowHigh = {{"low","<"},{"high",">"}}
    for i = 1,2 do
        out=out..string.format("Palettes_%s:\n",lowHigh[i][1])
        for palNum=0, #data.project.palettes do
            if palNum == 0 then
                out=out.."    .db "
            elseif palNum % 4 == 0 then
                out=out.."\n    .db "
            --elseif palNum~=#data.project.palettes then
            else
                out=out..", "
            end
            out=out..string.format("%sPalette%02x",lowHigh[i][2], palNum)
            if palNum==#data.project.palettes then
                out=out.."\n"
            end
        end
        out=out.."\n"
    end
    
    for palNum=0, #data.project.palettes do
        local pal = data.project.palettes[palNum]
        out=out..string.format("Palette%02x: .db ",palNum)
        for i=1,4 do
            out=out..string.format("$%02x",pal[i])
            if i==4 then
                out=out.."\n"
            else
                out=out..", "
            end
        end
    end
    
    print("File created "..filename)
    util.writeToFile(filename,0, out, true)
    
    local filename = data.folders.projects..projectFolder.."code/version.asm"
    
    local t = os.date("*t")
    out=string.format("; %s.%s.%s %s:%s\n",t.year, t.month, t.day, t.hour, t.min)
    out=string.format('version:\n    .db "v%s.%s.%s"\n\n',t.year, t.month, t.day)
    
    util.writeToFile(filename,0, out, true)
    
    out = "Metatiles:\n"
    filename = data.folders.projects..projectFolder.."code/tiles.asm"
    for i=0, #data.project.mTileSets[data.project.mTileSets.index] do
        local tile = data.project.mTileSets[data.project.mTileSets.index][i]
        if tile then
            out=out..string.format('    .db $%02x, $%02x, $%02x, $%02x\n',tile[0], tile[1], tile[2], tile[3])
        end
    end
    util.writeToFile(filename,0, out, true)
    
    local filename = data.folders.projects..projectFolder.."code/constauto.asm"
    out=""
    
    data.project.const.SELECTED_PALETTE = math.floor(data.project.palettes.index)
    data.project.const.CURRENT_CHR = math.floor(data.project.chr.index)
    for k,v in pairs(data.project.const) do
        out = out .. string.format("%s = $%02x\n",k, v)
    end

    util.writeToFile(filename,0, out, true)
    
    local filename = data.folders.projects..projectFolder.."code/symbols.asm"
    out=""
    
    local d = NESBuilder:getControlNew('symbolsTable1').getData()
    for i, row in python.enumerate(d) do
        k,v,comment = row[0],row[1],row[2]
        if k~='' then
            if comment~='' then
                out = out .. string.format("%s = %s ; %s\n",k,v or 0,comment)
            else
                out = out .. string.format("%s = %s\n",k,v or 0)
            end
        end
    end
    util.writeToFile(filename,0, out, true)
    
    -- assemble project
    
    -- make sure project.asm exists, or dont bother
    if NESBuilder:fileExists(folder.."project.asm") then
        -- remove old game.nes
        if NESBuilder:delete(folder.."game.nes") then
            NESBuilder:setWorkingFolder(folder)
            if data.project.assembler == 'asm6' then
                local cmd = data.folders.tools.."asm6.exe"
                local args = "-L project.asm game.nes list.txt"
                print("Starting asm 6...")
                
                NESBuilder:run(folder, cmd, args)
            elseif data.project.assembler == 'sdasm' then
                local sdasm = python.eval('sdasm')
                print("Starting sdasm...")
                
                local fixPath = python.eval('fixPath2')
                
                sdasm.assemble('project.asm', 'game.nes', 'output.txt', fixPath(data.folders.projects..projectFolder..'config.ini'))
            else
                print('invalid assembler '..data.project.assembler)
            end
        else
            print("Did not assemble project.")
        end
        print("done.")
    else
        print("no project.asm")
    end
    
    print("---- end of build ---")
    NESBuilder:setWorkingFolder()
end

function LoadProject_cmd()
    LoadProject()
end

function closePluginTabs()
    toggleTab('Palette', false)
    toggleTab('Image', false)
    toggleTab('Symbols', false)
    toggleTab('Metatiles', false)
    
    --toggleTab('tabProjectProperties', false)

    for _,p in pairs(plugins) do
        for _,tab in ipairs(p.tabs or {}) do
            toggleTab(tab, false)
        end
    end
end

function LoadProject()
    -- Close all plugin tabs by default
    closePluginTabs()
    
    handlePluginCallback("onPreLoadProject")
    
    NESBuilder:setWorkingFolder()
    print("loading project "..data.projectID)
    
    projectFolder = data.projectID.."/"
    
    local projectID = data.projectID
    
    local filename = data.folders.projects..projectFolder.."project.dat"
    data.project = util.unserialize(util.getFileContents(filename))
    
    data.projectID = projectID
    
    if not data.project then
        data.project = {type = data.projectType}
    end
    data.project.const = data.project.const or {}
    
    -- Add this to projects that didn't have a project type
    data.project.type = data.project.type or "dev"
    
    data.project.assembler = data.project.assembler or config.defaultAssembler
    
    -- update project folder in case it's been moved
    data.project.folder = projectFolder
    
    -- use default palettes if not found
    data.project.palettes = data.project.palettes or util.deepCopy(data.palettes)
    
    if not data.project.mTileSets then
        data.project.mTileSets = {index=0}
        
        -- convert old metatile format or make blank
        data.project.mTileSets[data.project.mTileSets.index] = data.project.metatiles or {index=0}
    end
    
    updateMTileList()
    
    data.project.chr = data.project.chr or {index=0}
    data.project.chrNames = data.project.chrNames or {}
    
    local converted = false
    local makeNp = python.eval("lambda x: np.array(x)")
    
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
    local control = NESBuilder:getControlNew('symbolsTable1')
    control.clear()
    data.project.constants = data.project.constants or {}
    for i,row in pairs(data.project.constants) do
        control.set(i,0,row.k)
        control.set(i,1,row.v)
        control.set(i,2,row.comment)
    end
    
    data.project.patches = data.project.patches or {}
    
--    NESBuilder:setWorkingFolder(data.folders.projects..data.project.folder)
--    if data.project.rom then
--        data.project.rom.data = NESBuilder:listToTable(NESBuilder:getFileAsArray(data.project.rom.filename))
--    end
--    NESBuilder:setWorkingFolder()
    
    data.project.rom = data.project.rom or {}
    
    if data.project.rom.filename and not data.project.rom.data then
        loadRom(data.project.rom.filename)
        print('loading rom data')
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
    
    handlePluginCallback("onLoadProject")
    
    PaletteEntryUpdate()
    
    -- refresh metatile tile canvas
    local control = NESBuilder:getControlNew('tsaTileCanvasQt')
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
    
    updateTitle()
end

function SaveProject()
    NESBuilder:setWorkingFolder()
    
    -- make sure folder exists for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    
    -- Convert python lists so they can be serialized.
--    print("converting chr...")
--    for i=0, #data.project.chr do
--        data.project.chr[i] = NESBuilder:listToTable(data.project.chr[i])
--    end
    for i,v in ipairs(data.project.palettes) do
        data.project.palettes[i] = NESBuilder:listToTable(data.project.palettes[i])
    end
    
    -- make sure project properties update if the tab is open
    ppUpdate()
    
    -- Convert symbols table
    print("converting symbols...")
    local d = NESBuilder:getControlNew('symbolsTable1').getData()
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
    
--    local romData
--    if data.project.rom then
--        romData = data.project.rom.data
--        data.project.rom.data = nil
--    end
    
    --local toBytes = python.eval("lambda x:bytes(x).decode('utf')")
    --if data.project.rom then
        --romData = data.project.rom.data
        --data.project.rom.data = toBytes(data.project.rom.data)
        --data.project.rom.data = nil
    --end
    
    -- Save tabs
    data.project.visibleTabs = {}
    data.project.tabsList = {}
    local control = NESBuilder:getWindowQt()
    for n in iterItems(control.menus['menuView'].actions) do
        table.insert(data.project.tabsList, n)
        data.project.visibleTabs[n] = control.tabParent.isTabVisible(control.tabParent.indexOf(control.getTab(n)))
    end
    
    handlePluginCallback("onSaveProject")
    
    --print(type(data.project.screenTool.nameTable))
    
    local time = python.eval("time.time")
    local t = time()
    
    local filename = data.folders.projects..data.project.folder.."project.dat"
    util.writeToFile(filename,0, util.serialize(data.project), true)
    
    --print(time()-t)
    
    --NESBuilder:writeToFile(filename, util.serialize(data.project))
    
--    local filename2 = data.folders.projects..data.project.folder.."project2.dat"
--    NESBuilder:writeToFile(filename2, util.serialize(data.rom))
--    util.writeToFile(filename2,0, util.serialize(data.rom), true)
    
    if data.project.rom then
        data.project.rom.data = romData
    end
    
    dataChanged(false)
    
    print(string.format("Project saved (%s)",data.projectID))
end

function Label1_cmd(name, label)
    print(name)
end

function PaletteEntry_cmd(t)
    if not t.cellNum then return end -- the frame was clicked.
    
    if t.event.button == 1 then
        print(string.format("Selected palette %02x",t.cellNum))
        data.selectedColor = t.cellNum
    elseif t.event.button == 3 then
        print(string.format("Set palette %02x",data.selectedColor or 0x0f))
        --t.set(t.cellNum, data.selectedColor)

        p=data.project.palettes[data.project.palettes.index]
        p[t.cellNum+1] = data.selectedColor
        t.setAll(p)
        refreshCHR()
        dataChanged()
    end
end

function PaletteEntryQt_cmd(t)
    local event = t.cell.event
    local p
    if event.button == 2 then
        print(string.format("Selected palette %02x",t.cellNum))
        p=currentPalette()
        data.selectedColor = p[t.cellNum+1]
    elseif event.button == 1 then
        print(string.format("Set palette %02x",data.selectedColor or 0x0f))
        p=data.project.palettes[data.project.palettes.index]
        p[t.cellNum+1] = data.selectedColor
        t.setAll(p)
        refreshCHR()
        dataChanged()
    end
end

function PaletteList_cmd(t)
    print(t.get())
end

function About_cmd()
    --NESBuilder:exec(string.format("webbrowser.get('windows-default').open('%s')",config.aboutURL))
    launcherButtonInfo_cmd()
end

function Quit_cmd()
    NESBuilder:Quit()
end

function refreshCHR()
    --print('refreshCHR()')
    local w,h
    local c = NESBuilder:getControl('CHRNumLabelQt')
    c.text = string.format("%02x", data.project.chr.index)
    
    
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
    
    
    control = NESBuilder:getControlNew("canvasTile")
    control.chrData = currentChr()
    control.drawTile(0,0, data.selectedTile, currentChr(), currentPalette(), control.columns, control.rows)
    control.update()
    control.copy()
    
    control = NESBuilder:getControl("tsaCanvasQt")
    if control then
        control.paste(surface)
    end
    
    
    handlePluginCallback("onCHRRefresh", surface)
end

function LoadCHRImage_cmd()
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

function mTileList_cmd(t)
    local index = t.getIndex()
    data.project.mTileSets.index = index
    data.project.mTileSets[data.project.mTileSets.index] = data.project.mTileSets[data.project.mTileSets.index] or {index=0}
    updateSquareoid()
    
    --print(data.project.mTileSets[data.project.mTileSets.index])
end

function addMTile_cmd()
    local tileIndex = 0
    local control = NESBuilder:getControl('mTileList')
    
    for i,v in ipairs_sparse(data.project.mTileSets) do
        if iKeys(v) then
            tileIndex = i +1
        end
    end
    
    data.project.mTileSets[tileIndex] = {index=0}
    
    local i = 99
    local n = string.format("MTile Set %02x", i)
    
    data.project.mTileSets[len(data.project.mTileSets)+1] = {index=0, name=n}
    
    control.addItem(n)
end

function CHRList_keyPress_cmd(t,test)
    local key = t.control.event.key
    local index = t.getIndex()
    if key == "Delete" then
        local chr = {}
        local chrNames = {}
        
        -- ToDo: handle removing of only chr (make blank?)
        
        table.remove(data.project.chr, index)
        table.remove(data.project.chrNames, index)
        local control = NESBuilder:getControl('CHRList')
        --control.takeItem(index)
        control.removeItem(index)
        
        CHRList_cmd(t)
    end
    --print(key)
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
    
    local p=data.project.palettes[data.project.palettes.index]
    
    if t.event.type == "ButtonPress" then
        if t.event.button == 1 then
            print(string.format("%02x", tileNum))
            
            local TileData = {}
            
            for i=0,15 do
                TileData[i+1] = t.chrData[tileOffset+i+1]
            end
            
            data.project.tileData = TileData
            data.project.tileNum = tileNum
            NESBuilder:getControlNew("tsaTileCanvas").loadCHRData(TileData, p)
        end
    end
end

function tsaCanvas2_cmd(t)
    local x = math.floor(t.event.x/t.scale)
    local y = math.floor(t.event.y/t.scale)
    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tileNum = tileY*2+tileX
    local tileOffset = 16*tileNum
    local CHRData, TileData
    
    if x<0 or y<0 or x>=128 or y>=128 then return end
    
    local p=data.project.palettes[data.project.palettes.index]
    
    if t.event.type == "ButtonPress" then
        if t.event.button == 1 then
            
            -- map the tiles to get the right offsets
            local mtileOffsets = {[0]=0,2,1,2+1}
            
            -- this is the tile index as in the main image
            local tileNum = data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index][mtileOffsets[tileNum]]
            
            NESBuilder:setCanvas("tsaTileCanvas")
            local TileData = {}
            
            control = NESBuilder:getCanvas('tsaCanvas')
            
            for i=0,15 do
                TileData[i+1] = control.chrData[16* tileNum +i+1]
            end
            
            data.project.tileData = TileData
            data.project.tileNum = tileNum
            
            NESBuilder:getControlNew("tsaTileCanvas").loadCHRData(TileData, p)
        elseif t.event.button == 3 and data.project.tileData then
            NESBuilder:setCanvas(t.name)
            
            if t.name == "tsaCanvas2" then
                for i=0,15 do
                    t.chrData[tileOffset+i+1] = data.project.tileData[i+1]
                end

                data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] = data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] or {[0]=0,0,0,0}
                if tileX<=1 and tileY<=1 then
                    -- 02
                    -- 13
                    data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index][tileX*2+tileY] = data.project.tileNum
                    data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index].palette = data.project.palettes.index
                end
                NESBuilder:getControlNew(t.name).loadCHRData{t.chrData, p, rows=2, columns=2}
            else
            end
            
            dataChanged()
        end
    end
end


function tsaSquareoidPrev_cmd()
    data.project.mTileSets[data.project.mTileSets.index].index = math.max(0, data.project.mTileSets[data.project.mTileSets.index].index - 1)
    updateSquareoid()
end
function tsaSquareoidNext_cmd()
    data.project.mTileSets[data.project.mTileSets.index].index = math.min(255, data.project.mTileSets[data.project.mTileSets.index].index + 1)
    updateSquareoid()
end

function tsaSquareoidNumber_cmd(t)
    if t.event and t.event.type == "KeyPress" and t.event.event.keycode==13 then
        data.project.mTileSets[data.project.mTileSets.index].index = tonumber(NESBuilder:getControl("tsaSquareoidNumber").getText())
    end
end

function updateSquareoid()
    local tileNum
    local tileOffset1, tileOffset2
    
    local controlFrom = NESBuilder:getControlNew("tsaCanvasQt")
    local controlTo = NESBuilder:getControlNew("tsaCanvas2Qt")
    
    local control = NESBuilder:getControlNew("mTileList")
    if control.count() == 0 then return end
    
    if data.project.mTileSets.index == -1 then
        data.project.mTileSets.index = 0
        control.setCurrentRow(0)
    end
    
    local control = NESBuilder:getControl("tsaSquareoidNumber")
    
    control.setText(string.format('%s',data.project.mTileSets[data.project.mTileSets.index].index))
    
    if not data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] then
        local m = currentMetatile()
        local mtileOffsets = {[0]=0,2,1,3}
        for i = 0,3 do
            controlTo.drawTile(i%2 *8,math.floor(i/2) *8, m[mtileOffsets[i]], currentChr(), p, controlTo.columns, controlTo.rows)
            controlTo.update()
        end

        return
    end
    
    data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] = data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index] or {[0]=0,0,0,0}
    
    --local p = data.project.metatiles[data.project.metatiles.index].palette or data.project.palettes[data.project.palettes.index]
    local p = data.project.palettes[data.project.mTileSets[data.project.mTileSets.index][data.project.mTileSets[data.project.mTileSets.index].index].palette or 0]
    
    
--    local mtileOffsets = {[0]=0,2,1,2+1}
--    for sqTileNum=0,3 do
--        tileNum = data.project.metatiles[data.project.metatiles.index][sqTileNum]
--        tileOffset1 = 16 * tileNum
--        tileOffset2 = 16 * mtileOffsets[sqTileNum]
        
--        for i=0,15 do
--            controlTo.chrData[tileOffset2+i+1] = controlFrom.chrData[tileOffset1+i+1]
--        end
--    end
    
    local m = currentMetatile()
    local mtileOffsets = {[0]=0,2,1,3}
    for i = 0,3 do
        controlTo.drawTile(i%2 *8,math.floor(i/2) *8, m[mtileOffsets[i]], currentChr(), p, controlTo.columns, controlTo.rows)
        controlTo.update()
    end
--    local mtileOffsets = {[0]=0,2,1,2+1}
--    for sqTileNum=0,3 do
--        t.control.drawTile(tileX*8,tileY*8, data.selectedTile, currentChr(), currentPalette(), t.control.columns, t.control.rows)
--        t.control.update()
        
--        local m = currentMetatile()
--        local mtileOffsets = {[0]=0,2,1,3}
--        m[tileX*2+tileY] = data.selectedTile
--        setMetatileData(m)
    --print(data.project.metatiles)
end


function tsaTest_cmd()
    local p=data.project.palettes[data.project.palettes.index]
    
    NESBuilder:getControlNew("tsaCanvas").loadCHRData(data.project.chr[data.project.chr.index], p)
end

--function onTabChanged_cmd(t)
--    local tab = t.tab()
--    if t.window.name == "Main" then
--        if tab == "tsa" then
--            local p=data.project.palettes[data.project.palettes.index]
            
--            local control = NESBuilder:getControlNew("tsaCanvas")
--            NESBuilder:getControlNew("tsaCanvas").loadCHRData(data.project.chr[data.project.chr.index], p)
            
--            updateSquareoid()
--        end
--    end
--    handlePluginCallback("onTabChanged", t)
--end

function updateRecentProjects()
    local stack = NESBuilder:newStack(recentProjects.stack)
    local id
    
    for _, control in pairs(recentData) do
        control.label.setText("")
    end
    
    for i=1, len(recentProjects.stack) do
        id = stack.pop()
        recentData[i-1].label.setText(id)
    end
end

function launcherRecentIcon_cmd(t)
    local id,n
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
    if t.event and t.event.button == 4 then
        print('middle click')
        --closeTab('tabPreferences', 'Launcher')
        print(t.control.currentWidget().name)
    elseif t.event and t.event.button == 2 then
        print('right click')
    else
        print('click')
        handlePluginCallback("onTabChanged", t.control.currentWidget())
    end
end

function hFlip_cmd()
    local tile = data.selectedTile
    local tileOffset = 16*tile
    
    local y=0
    local c=0
    for y=0,7 do
        for i = 0,1 do
            local b = data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8]
            data.project.chr[data.project.chr.index][tileOffset+((i)*8)+y%8] = reverseByte(b)
        end
    end
    refreshCHR()
end

function vFlip_cmd()
    local tile = data.selectedTile
    local tileOffset = 16*tile
    
    local y=0
    local c=0
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

function canvasTile_cmd(t)
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
        control.setPixel(x,y, nespalette[data.selectedColor])
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
    local event = t.control.event
    local x = math.floor(event.x/t.scale)
    local y = math.floor(event.y/t.scale)
    x = math.min(t.control.columns*8-1, math.max(0,x))
    y = math.min(t.control.rows*8-1, math.max(0,y))

    local control = NESBuilder:getControlNew(t.name)
    local p = currentPalette()
    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tile = tileY*control.columns+tileX
    local tileOffset = 16*tile
    --local cBits = NESBuilder:numberToBitArray(data.selectedColorIndex)
    
--    control.setPixel(x,y, nespalette[data.selectedColor])
--    control.update()
    
--    for i=0, 1 do
--        local b = data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8]
--        local l=NESBuilder:numberToBitArray(b)
--        l[x%8]=cBits[7-i]
--        b = NESBuilder:bitArrayToNumber(l)
--        data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8] = b
--    end
    
    
    
    control = NESBuilder:getControlNew("canvasTile")
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
    
    local control = NESBuilder:getControlNew('tsaTileCanvasQt')
    control.drawTile(0,0, tile, currentChr(), currentPalette(), control.columns, control.rows)
    control.update()
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
    
    if event.button == 1 then
        t.control.drawTile(tileX*8,tileY*8, data.selectedTile, currentChr(), currentPalette(), t.control.columns, t.control.rows)
        t.control.update()
        
        local m = currentMetatile()
        local mtileOffsets = {[0]=0,2,1,3}
        m[tileX*2+tileY] = data.selectedTile
        m.palette = data.project.palettes.index
        setMetatileData(m)
        print(data.project.mTileSets[data.project.mTileSets.index])
    elseif event.button == 2 then
        local m = currentMetatile()
        local mtileOffsets = {[0]=0,2,1,3}
        data.selectedTile = m[tileX*2+tileY]
        data.project.palettes.index = m.palette

        local control = NESBuilder:getControlNew('tsaTileCanvasQt')
        control.drawTile(0,0, data.selectedTile, currentChr(), currentPalette(), control.columns, control.rows)
        control.update()
    end
end
--tsaTileCanvasQt_cmd = canvasQt_cmd

function buttonWarningClose_cmd() closeTab('Warning', 'Launcher') end
function buttonPreferencesClose_cmd() closeTab('tabPreferences', 'Launcher') end
function buttonInfoClose_cmd() closeTab('infoTab', 'Launcher') end
function ppClose_cmd()
    ppUpdate()
    closeTab('tabProjectProperties', 'Launcher')
end

function ppUpdate()
    local control = NESBuilder:getControlNew('patchesTable')
    if not control then return end
    
    local d = control.getData()
    data.project.patches = {}
    for i, row in python.enumerate(d) do
        data.project.patches[i] = row[0]
    end
    
    local control = NESBuilder:getControl('ppRomFile')
    control.text=data.project.rom.filename
    
end

-- Convenience functions
function currentPalette(n) return data.project.palettes[n or data.project.palettes.index] end
function currentChr(n) return data.project.chr[n or data.project.chr.index] end
function setChr(n) data.project.chr.index = n end
function loadChr(f, n) data.project.chr[n or data.project.chr.index] = NESBuilder:getFileContents(f) end
function getChrData(n) return data.project.chr[n or data.project.chr.index] end
function setChrData(chrData, n) data.project.chr[n or data.project.chr.index]=chrData end
function boolNumber(v) if v then return 1 else return 0 end end
function devMode() return (cfgGet('dev')==1) end
function type(item) return NESBuilder:type(item) end
function currentMetatile() return data.project.mTileSets[data.project.mTileSets.index][n or data.project.mTileSets[data.project.mTileSets.index].index] or {[0]=0,0,0,0} end
function setMetatileData(mTileData, n) data.project.mTileSets[data.project.mTileSets.index][n or data.project.mTileSets[data.project.mTileSets.index].index]=mTileData end
function getControl(n) return NESBuilder:getControl(n) end



int = python.eval("lambda x:int(x)")
sliceList = python.eval("lambda x,y,z:x[y:z]")
joinList = python.eval("lambda x,y:x+y")
reverseByte = python.eval("lambda x:int(('{:08b}'.format(x))[::-1],2)")
replace = python.eval("lambda x,y,z:x.replace(y,z)")
list = python.eval("lambda *x:[item for item in x]")
set = python.eval("lambda *x:set([item for item in x])")
bool = python.eval("bool")

-- Get integer keys from a list (including 0, sparse arrays)
iKeys = python.eval("lambda l:sorted([x for x in l if type(x)==int]) or False")
max = python.eval("lambda x:max(x)")
min = python.eval("lambda x:min(x)")

pyItems = python.eval("lambda x: x.items()")
function iterItems(x)
    return python.iter(pyItems(x))
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
    NESBuilder:makeTabQt{name=t.name, text=t.text}
    
    -- Keep track of which plugin generated a tab
    local p = _getPlugin and plugins[_getPlugin().name]
    if p then
        p.tabs = p.tabs or {}
        table.insert(p.tabs, t.name)
    end
end

function setTab(tab)
    NESBuilder:setTabQt(tab)
end

function cfgGet(section, key)
    key, section = key or section, (key and section) or "main"
    return NESBuilder:cfgGetValue(section, key)
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

function autoSave()
    -- This is here just so the app doesn't stay open if something goes
    -- Wrong and it's running things while trying to close.  It's not a
    -- great solution, but at least it wont have a process open in the
    -- background forever.
    local main = NESBuilder:getControlNew('main')
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
    pcall(function() statusBar.text = control.helpText or "" end)
end

function addCHR_cmd()
    local control = NESBuilder:getControl('CHRList')
    
    local n = #data.project.chr+1
    data.project.chr[n] = NESBuilder:newCHRData()
    data.project.chrNames[n] = string.format("CHR %02x", n-1)
    control.addItem(data.project.chrNames[n])
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
        
        pathSplit = python.eval("lambda x:list(os.path.split(x))")
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
    
    local fileData = data.project.rom.data or NESBuilder:getFileAsArray(filename)
    --print(fileData)
    
    --print(NESBuilder:getLen(fileData))
    
--    data.rom = {
--        filename = f,
--        data = fileData,
--    }
    
--    data.project.rom = {
--        filename = f
--    }
    
    data.project.rom = {
        filename = filename,
        data = fileData,
    }
    ppUpdate()
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
    
    nPrg = int(fileData[4])
    nChr = int(fileData[5])
    chrStart = 0x10 + nPrg * 0x4000
    
    -- wipe all chr
    data.project.chr = {index=0}
    local control = NESBuilder:getControl('CHRList')
    control.clear()
    
    local sliceList = python.eval("lambda x,y,z:x[y:z]")
    for i = 0,(nChr*2)-1 do
        chrData = sliceList(fileData, chrStart + i * 0x1000, chrStart + i * 0x1000 + 0x1000)
        setChrData(chrData, i)
        --if i > control.count() -1 then addCHR_cmd() end
        addCHR_cmd()
    end
    
    refreshCHR()
    NESBuilder:setWorkingFolder()
end

function exportAllChr()
    local chrData, chrStart, nPrg, nChr
    local fileData = data.project.rom.data
    
    nPrg = int(fileData[4])
    nChr = int(fileData[5])
    chrStart = 0x10 + nPrg * 0x4000
    
    print(nPrg)
    print(nChr)
    print(chrStart)
    
    -- remove all chr
    fileData = sliceList(fileData, 0, chrStart)
    
    local npConcat = python.eval("lambda x,y: np.concatenate([x,y])")
    
    for i = 0,(nChr*2)-1 do
        fileData = npConcat(fileData, getChrData(i))
    end
    
    local f = data.folders.projects..data.project.folder.."game.nes"
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
        addCHR_cmd()
    end
    
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

function ppAssembler_cmd(t)
    data.project.assembler = t.control.value
end