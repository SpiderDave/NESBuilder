config = {
    title="NESBuilder",
    width=850,
    height=700,
    upperHex=false,
    cellWidth=24,
    cellHeight=24,
    buttonWidth=20,
    buttonWidthSmall=4,
    aboutURL = "https://github.com/SpiderDave/NESBuilder#readme",
    colors = {
        bk='#202036',
        bk2='#303046',
        bk3='#404050',      -- text background
        bk_hover='#454560',
        fg = '#eef',
        bk_menu_highlight='#606080',
    },
    pluginFolder = "plugins", -- this one is for python
    nRecentFiles = 20,
}

config.launchText=[[
Created by SpiderDave
-------------------------------------------------------------------------------------------
NESBuilder is a NES development tool.

Notes:
    General:
        Lots of work to do!
    
    CHR Tab:
        - only 128x128 (4K) CHR banks at the moment
        - Fixed to 8 banks for now
        - you can click to change pixels on it, but it's just the 
          start of a proper editing mode (export and use your
          favorite editor and re-import for now).
        - CHR refreshing is slow

ToDo:
    * Ability to remove palettes
    * Palette sets and extra labels
    * Replace this page with launcher
    * undo!
    * ability to add/remove/replace with popup menus
    * better docs
]]

-- global stacks
stack, push, pop = NESBuilder:newStack()
recentProjects = NESBuilder:newStack{maxlen=config.nRecentFiles}

len = function(item) return NESBuilder:getLen(item) end

plugins = {}

-- Overriding print and adding all sorts of neat things.
-- This is really complicated and should probably move to
-- the Python side of things.
__print = print
local prefix = "[Lua] "
print = function(item)
    if type(item)=="userdata" then
        __print(prefix..NESBuilder:getPrintable(item))
    elseif type(item)=="table" then
        print("{")
        for k,v in pairs(item) do
            if type(v) == "function" then
                -- It's a Lua function
                v = "<function>"
            elseif NESBuilder:type(v) == "function" then
                -- It's a Python function
                v = "<function>"
            else
                v = NESBuilder:repr(v)
            end
            print("  "..k .. "=" .. v..",")
        end
        print("}")
    elseif type(item)=="number" then
        -- seems like this would do nothing but it actually changes
        -- python numbers that would display like "42.0" to "42".
        if item == math.floor(item) then item = math.floor(item) end
        __print(prefix..item)
    else
        __print(prefix..(item or ''))
    end
end

makeHex = function(n)
    if config.upperHex then
        return string.format("%02X",n)
    else
        return string.format("%02x",n)
    end
end

data = {selectedColor = 0}
data.palettes = {}

data.palettes = {
    index=0,
    [0]={0x0f,0x21,0x11,0x01},
    {0x0f,0x26,0x16,0x06},
    {0x0f,0x29,0x19,0x09},
    {0x0f,0x30,0x10,0x00},
}

data.projectID = "project1" -- this determines the folder that it will load the project data from
--data.projectID = "newproject"
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
    local x,y,x2,y2,pad
    local control, b, c
    local top,left
    
    print("init")
    
    NESBuilder:incLua("Tserial")
    util = NESBuilder:incLua("util")
    
    -- make sure projects folder exists
    NESBuilder:makeDir(data.folders.projects)
    
    NESBuilder:setWindow("Main")
    NESBuilder:makeTab("Launcher", "Launcher")
    NESBuilder:makeTab("Main", "Main")
    NESBuilder:makeTab("Palette", "Palette")
    NESBuilder:makeTab("Image", "CHR")
    
    local items = {
        {name="New", text="New Project"},
        {name="Open", text="Open Project"},
        {name="Save", text="Save Project"},
        {name="Build", text="Build Project"},
        {name="BuildTest", text="Build Project and Test"},
        {text="-"},
        {name="Quit", text="Exit"},
    }
    control = NESBuilder:makeMenu{name="menuFile", text="File", items=items, prefix=false}
    
    local items = {
        {name="Cut", text="Cut"},
        {name="Copy", text="Copy"},
        {name="Paste", text="Paste"},
    }
    control = NESBuilder:makeMenu{name="menuEdit", text="Edit", items=items, prefix=false}
    
    local items = {
        {name="About", text="About"},
    }
    control = NESBuilder:makeMenu{name="menuHelp", text="Help", items=items, prefix=false}
    
    NESBuilder:setTab("Image")
    NESBuilder:makeCanvas{x=8,y=8,w=128,h=128,name="canvas", scale=3}
    NESBuilder:setCanvas("canvas")
    
    pad=6
    top = pad*1.5
    left = pad*1.5
    x,y = left,top
    
    
    NESBuilder:setTab("Main")
    x,y = left,top
    
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="NewProject",text="New Project"}
    y = y + b.height + pad
    
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="OpenProject",text="Open Project"}
    y = y + b.height + pad

    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="SaveProject",text="Save Project"}
    y = y + b.height + pad

    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="BuildProject",text="Build Project"}
    y = y + b.height + pad
    
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="BuildProjectTest",text="Build Project and Test"}
    y = y + b.height + pad
    
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="OpenProjectFolder",text="Open Project Folder"}
    y = y + b.height + pad

--    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth,name="ButtonLevelExtract",text="Extract Level"}
--    y = y + b.height + pad
    
--    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth,name="ButtonMakeCHR",text="Make CHR"}
--    y = y + b.height + pad
    
    buttonHeight = b.height

--    for i=0,4 do
--        b=NESBuilder:makeButton{x=x,y=y,name="Button"..i,text="Button"..i}
--        y = y + b.height + pad
--    end
    
    --b=NESBuilder:makeText{x=x,y=y, lineHeight=20,lineWidth=80, name="Text1",text="Text1"}
    
--    x2,y2=x,y
--    b=NESBuilder:makeText{x=x,y=y,w=20, w=150,h=buttonHeight, name="Text1",text="Text1"}
--    y = y + b.height + pad
    
--    b=NESBuilder:makeButton{x=left+150+pad,y=y2,w=config.buttonWidth,name="ButtonSetText1",text="Set"}
--    x=left
--    y = y + b.height + pad
    
    
    NESBuilder:setTab("Palette")
    NESBuilder:setDirection("h")
    x,y=left,top
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    c=NESBuilder:makePaletteControl{x=pad*1.5,y=pad*1.5,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="Palette", palette=nespalette}
    
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    
    x2=NESBuilder.x+pad + 100
    y2=pad*1.5
    
    placeX = left
    placeY = top
    
    x=left
    y=top + 100+pad*1.5
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonPrevPalette",text="<"}
    
    x = x + b.width + pad
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonNextPalette",text=">"}
   
    x = x + b.width + pad
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonAddPalette",text="+"}
    
    x = left
    y = y + b.height + pad
    
    x2,y2=x,y
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    c=NESBuilder:makePaletteControl{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="PaletteEntry", palette=palette}
    y = y + 32 + pad
    
    x=NESBuilder.x+pad
    c=NESBuilder:makeLabel{x=x,y=y2+3,name="PaletteEntryLabel",clear=true,text="foobar"}
    
    x = left
    
--    b=NESBuilder:makeText{x=x,y=y, lineHeight=16,lineWidth=80, name="Text1",text="Text1"}
--    y = y + b.height + pad
    
--    x=x2
--    y=y2
--    b=NESBuilder:makeList{x=x,y=y, name="PaletteList"}
--    b.append("palette00")
--    b.append("palette01")
--    b.append("palette02")
--    b.append("palette03")
    
    
    NESBuilder:setTab("Image")
    p = {[0]=0x0f,0x21,0x11,0x01}
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end

    x=pad
    y=pad+128*3+pad*1.5
    placeY = y
    c=NESBuilder:makePaletteControl{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="CHRPalette", palette=palette}
    
    x=left + 120
    y=placeY
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonPrevPaletteCHR",text="<"}

    x=x+b.width+pad
    y=placeY
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonNextPaletteCHR",text=">"}

    x=left
    
    y = y + 32 + pad
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth,name="LoadCHRImage",text="Load Image"}

    y = y + b.height + pad
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth,name="LoadCHRNESmaker",text="Load NESmaker Image"}

    y = y + b.height + pad
    
    --b=NESBuilder:makeButton{x=x,y=y,name="ButtonCHRTest1",text="test"}
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth,name="LoadCHR",text="Load .chr"}
    y = y + b.height + pad
    
    b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth,name="ExportCHRImage",text="Export to .png"}
    y = y + b.height + pad
    
--    f="chr.png"
--    NESBuilder:loadImageToCanvas(f)
    
    -- Import the "LevelExtract" method from "SMBLevelExtract.py" and 
    -- add it to the "Python" table.
    --LevelExtract = NESBuilder:importFunction('include.SMBLevelExtract','LevelExtract')
    
    x=128*3+pad*3
    y=top
    c=NESBuilder:makeLabel{x=x,y=y,name="CHRNumLabel",clear=true,text="CHR"}
    y = y + buttonHeight
    
    --y=top
    x=128*3+pad*3
    for i=0,7 do
        b=NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth,name="CHR"..i,text="CHR "..i}
        y = y + b.height + pad
    end
    
    
    NESBuilder:setTab("Launcher")
    left = pad*2
    top = pad*2
    x,y,pad = left,top,8
    local startY
    
    control = NESBuilder:makeLabel{x=x,y=y,name="launcherRecentTitle",clear=true,text="NESBuilder"}
    control.setFont("Verdana", 28)
    
    y = y + control.height + pad
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
    control = NESBuilder:makeButton{x=x,y=y,w=190,h=64, name="launcherButtonInfo",text="Info", image="icons/note32.png", iconMod=true}
    y = y + control.height + pad
    
    x=x+control.width+pad
    y=top
    startY=pop()
    
    local c = {
        {text="Days"},
        {text="go"},
        {text="by"},
        {text="and"},
        {text="still"},
        {text="I"},
        {text="think"},
        {text="of"},
        {text="you."},
        {text="Days"},
        {text="when"},
        {text="I"},
        {text="couldn't"},
        {text="live"},
        {text="my"},
        {text="life"},
        {text="without"},
        {text="you."},
        {text="Without"},
        {text="you."},
    }
    local columns = 5
    recentData = {}
    for i, item in pairs(c) do
        recentData[i-1]={}
        x = 250+((i-1) % columns)*100
        y = startY+math.floor((i-1)/columns)*150
        
        control = NESBuilder:makeLabel{x=x,y=y,h=110, w=80, name="launcherRecentIcon",text="", index=i-1}
        recentData[i-1].icon = control
        y = y + control.height + pad*.5
        control = NESBuilder:makeLabel{x=x,y=y,name="launcherRecent",clear=true,text=item.text, index=i-1}
        recentData[i-1].label = control
        control.setFont("Verdana", 10)
        y = y + control.height + pad
        
    end
    
    
    NESBuilder:makeTab("tsa", "TSA")
    NESBuilder:setTab("tsa")
    x,y=left,top
    
    push(y)
    control = NESBuilder:makeCanvas{x=x,y=y,w=128,h=128,name="tsaCanvas", scale=2}
    push(x+control.width+pad)
    --p=data.project.palettes[data.project.palettes.index]
    
    --NESBuilder:setCanvas("tsaCanvas")
    --NESBuilder:loadCHRFile{"smb_new.chr", p, start=0x1000} 
    
    --CHRData = NESBuilder:imageToCHRData("chr.png",NESBuilder:getNESColors(p))
    --NESBuilder:loadCHRData(CHRData, p)
    
    x = left
    y=y + control.height + pad
    
    control = NESBuilder:makeCanvas{x=x,y=y,w=16,h=16,name="tsaCanvas2", scale=6}
    NESBuilder:setCanvas("tsaCanvas2")
    NESBuilder:loadCHRData(nil, p)
    
    y=y + control.height + pad
    
    push(y)
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall, name="tsaSquareoidPrev",text="<"}
    y=pop()
    x= x + control.width+pad
    
    push(y)
    control=NESBuilder:makeEntry{x=x,y=y,w=20,h=buttonHeight, name="tsaSquareoidNumber",text="0"}
    y=pop()
    x= x + control.width+pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidthSmall, name="tsaSquareoidNext",text=">"}
    x = left
    y = y + control.height + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="tsaTest",text="Update"}
    
    x= pop()
    y = pop()
    control = NESBuilder:makeCanvas{x=x,y=y,w=8,h=8,name="tsaTileCanvas", scale=8}

    
    loadSettings()
end

function onPluginsLoaded()
    handlePluginCallback("onInit")
end

function onReady()
    LoadProject_cmd()
end

function handlePluginCallback(f)
    local keys={}
    for k,v in pairs(plugins) do
        table.insert(keys,k)
    end
    table.sort(keys)
    
    for _,n in pairs(keys) do
        if plugins[n][f] then
            print(string.format("(Plugin %s): %s",n,f))
            plugins[n][f]()
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
        print("doCommand "..t)
        print("****")
    else
        if t.event.type == "ButtonPress" or t.event.type=="" then
            print("doCommand "..t.name)
        else
            print("doCommand "..t.name)
        end
    end
end

function Palette_cmd(t)
    if not t.cellNum then return end -- the frame was clicked.
    
    if t.event.button == 1 then
        print(string.format("Selected palette %02x",t.cellNum))
        data.selectedColor = t.cellNum
    end
end

function CHRPalette_cmd(t)
    if t.event.button == 1 then
        print(string.format("Selected palette %02x",t.cellNum))
        data.selectedColor = t.cellNum
        --data.drawColorIndex = t.cellNum
    elseif t.event.button == 3 then
        print(string.format("Set palette %02x",data.selectedColor or 0x0f))
        if t.set(t.cellNum, data.selectedColor) then
            refreshCHR()
            dataChanged()
        end
    end
end

function ButtonMakeCHR_cmd()
    local f = NESBuilder:openFile({{"Images", ".png"}})
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        f2 = NESBuilder:saveFileAs({{"CHR", ".chr"}},'output.chr')
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
    dataChanged()
end


function PaletteEntryUpdate()
    p=data.project.palettes[data.project.palettes.index]
    
    c = NESBuilder:getControl('PaletteEntry')
    c.setAll(p)

    c = NESBuilder:getControl('CHRPalette')
    c.setAll(p)
    
    c = NESBuilder:getControl('PaletteEntryLabel')
    c.control.text = string.format("Palette%02x",data.project.palettes.index)
    
    refreshCHR()
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
    local f = NESBuilder:openFile({{"NES rom", ".nes"}})
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
end

function NewProject_cmd()
    if data.project.changed then
        q= NESBuilder:askyesnocancel("", string.format("Save changes to %s?",data.projectID))
        
        -- cancel
        if q==nil then return end
        
        if q==true then
            SaveProject_cmd()
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
         local q= NESBuilder:askyesnocancel("", string.format('The project folder "%s" already exists.  Load it instead?', n))
         -- cancel
        if q==nil then return end
        
        -- no
        if q==false then return end

        -- yes
        data.projectID = n
        LoadProject_cmd()
        return
    end
    
    print(string.format('Creating new project "%s"',n))
    data.projectID = n
    LoadProject_cmd()
end


function notImplemented()
    NESBuilder:showError("Error", "Not yet implemented.")
end

function Cut_cmd() notImplemented() end
function Copy_cmd() notImplemented() end
function Paste_cmd() notImplemented() end

function launcherButtonOpen_cmd() Open_cmd() end
function launcherButtonNew_cmd() NewProject_cmd() end
function launcherButtonRecent_cmd() notImplemented() end
function launcherButtonTemplates_cmd() notImplemented() end
function launcherButtonPreferences_cmd() notImplemented() end

function launcherButtonInfo_cmd()
    local x,y,left,top,pad
    pad = 6
    left = pad*2
    top = pad*2
    x,y = left,top


    NESBuilder:makeWindow{x=0,y=0,w=760,h=600, name="infoWindow",title="Info"}
    NESBuilder:setWindow("infoWindow")

    control = NESBuilder:makeLabel{x=x,y=y,name="launchLabel",clear=true,text="NESBuilder"}
    control.setFont("Verdana", 24)
    
    -- Getting wrong height here for some reason.  Doesn't happen in a plugin.
    control.height = 26
    
    y = y + control.height + pad*1.5
    
    control = NESBuilder:makeLabel{x=x,y=y,name="launchLabel2",clear=true,text=config.launchText}
    control.setFont("Verdana", 12)
    control.setJustify("left")


end

function New_cmd()
    NewProject_cmd()
end
function OpenProject_cmd()
    Open_cmd()
end
function SaveProject_cmd()
    Save_cmd()
end
function BuildProjectTest_cmd()
    BuildTest_cmd()
end

function OpenProjectFolder_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    NESBuilder:shellOpen(workingFolder, data.folders.projects..data.project.folder)
end

function Build_cmd()
    BuildProject_cmd()
end

function BuildTest_cmd()
    BuildProject_cmd()

    local workingFolder = data.folders.projects..data.project.folder
    local f = data.folders.projects..data.project.folder.."game.nes"
    print("shellOpen "..f)
    NESBuilder:shellOpen(workingFolder, f)
end

function BuildProject_cmd()
    local out = ""
    print("building project...")
    
    refreshCHR()
    
    NESBuilder:setWorkingFolder()
    
    -- make sure folders exist for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."chr")
    NESBuilder:makeDir(data.folders.projects..data.project.folder.."code")
    
    handlePluginCallback("onBuild")
    
    -- save CHR
    for i=0,#data.project.chr do
        if data.project.chr[i] then
            local f = data.folders.projects..data.project.folder..string.format("chr/chr%02x.chr",i)
            print("File created "..f)
            util.writeToFile(f, 0, data.project.chr[i], true)
        end
    end
    
    
    local filename = data.folders.projects..projectFolder.."code/constauto.asm"
    
--    if NESBuilder:delete(filename) then
--        print("deleted "..filename)
--    end
    
    print("index = "..data.project.palettes.index)
    out=""
    out=out..string.format("SELECTED_PALETTE = $%02x\n\n", math.floor(data.project.palettes.index))
    
    util.writeToFile(filename,0, out, true)
    --NESBuilder:writeToFile(filename, out)
    
    local c = NESBuilder:getControl('PaletteList')
    local filename = data.folders.projects..projectFolder.."code/palettes.asm"

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
    for i=0, #data.project.squareoids do
        local tile = data.project.squareoids[i]
        out=out..string.format('    .db $%02x, $%02x, $%02x, $%02x\n',tile[0], tile[1], tile[2], tile[3])
    end
    util.writeToFile(filename,0, out, true)
    
    -- assemble project
    local folder = data.folders.projects..data.project.folder
    
    -- make sure project.asm exists, or dont bother
    --if util.fileExists(folder.."project.asm") then
    if NESBuilder:fileExists(folder.."project.asm") then
        -- remove old game.nes
        if NESBuilder:delete(folder.."game.nes") then
            local cmd = data.folders.tools.."asm6.exe"
            local args = "-L project.asm game.nes list.txt"
            print("starting asm 6...")
            NESBuilder:setWorkingFolder(folder)
            NESBuilder:run(folder, cmd, args)
            --NESBuilder:shellOpen(folder, cmd.." "..args)
        else
            print("Did not assemble project.")
        end
        print("done.")
    else
        print("no project.asm")
    end
    print("---- end of build ---")
end

function LoadProject_cmd()
    print("loading project "..data.projectID)
    
    projectFolder = data.projectID.."/"
    
    local filename = data.folders.projects..projectFolder.."project.dat"
    data.project = util.unserialize(util.getFileContents(filename))
    
    if not data.project then
        data.project = {}
    end
    
    -- Wipe data stored on the canvas control
    NESBuilder:setCanvas('tsaCanvas')
    NESBuilder:loadCHRData()
    
    -- reset selected tile canvas
    NESBuilder:setCanvas("tsaTileCanvas")
    NESBuilder:loadCHRData({0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, {[0]=0x0f,0x0f,0x0f,0x0f})
    
    -- update project folder in case it's been moved
    data.project.folder = projectFolder
    
    -- use default palettes if not found
    data.project.palettes = data.project.palettes or util.deepCopy(data.palettes)
    
    data.project.squareoids = data.project.squareoids or {index=0}
    
    data.project.chr = data.project.chr or {index=0}
    
    handlePluginCallback("onLoadProject")
    
    -- update palette entry
    data.project.palettes.index = 0
    PaletteEntryUpdate()
    
    dataChanged(false)
    
    --recentProjects.stack.push(42)
    
    recentProjects.remove(data.projectID)
    recentProjects.push(data.projectID)
    updateRecentProjects()
    
--    c = NESBuilder:getControl('PaletteList')
--    c.set(data.project.paletteIndex or 0)
    
--    f=data.folders.projects..projectFolder.."chr.png"
--    NESBuilder:loadImageToCanvas(f)
    
    updateTitle()
end

function SaveProject_cmd()
    -- make sure folder exists for this project
    NESBuilder:makeDir(data.folders.projects..data.project.folder)
    
    handlePluginCallback("onSaveProject")
    
    local filename = data.folders.projects..data.project.folder.."project.dat"
    util.writeToFile(filename,0, util.serialize(data.project), true)
    
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

function PaletteList_cmd(t)
    print(t.get())
end

function About_cmd()
    NESBuilder:exec(string.format("webbrowser.get('windows-default').open('%s')",config.aboutURL))
end

function Quit_cmd()
    NESBuilder:Quit()
end

function refreshCHR()
    local p=data.project.palettes[data.project.palettes.index]
    
    NESBuilder:setCanvas("canvas")
    NESBuilder:loadCHRData(data.project.chr[data.project.chr.index], p)

    local c = NESBuilder:getControl('CHRNumLabel')
    c.control.text = string.format("%02x", data.project.chr.index)
end

function LoadCHRImage_cmd()
    local CHRData
    local f = NESBuilder:openFile(nil)
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        p=data.project.palettes[data.project.palettes.index]
        
        -- Load the image into data
        CHRData = NESBuilder:imageToCHRData(f,NESBuilder:getNESColors(p))
        
        -- Store in selected project bank
        data.project.chr[data.project.chr.index] = CHRData
        
        -- Load CHR data and display on canvas
        NESBuilder:setCanvas("canvas")
        NESBuilder:loadCHRData(CHRData, p)

        c = NESBuilder:getControl('CHRPalette')
        c.setAll(p)
        
        dataChanged()
    end
end

function ExportCHRImage_cmd()
    local filename = string.format("chr%02x_export.png",data.project.palettes.index)
    local f = NESBuilder:saveFileAs({{"PNG", ".png"}},filename)
    if f == "" then
        print("Export cancelled.")
    else
        print("file: "..f)
    end
    
    p=data.project.palettes[data.project.palettes.index]
    chrData = data.project.chr[data.project.chr.index]
    NESBuilder:setCanvas("canvas")
    NESBuilder:exportCHRDataToImage(f, chrData, p)
end

function LoadCHRNESmaker_cmd()
    local CHRData
    local f = NESBuilder:openFile(nil)
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        p=data.project.palettes[data.project.palettes.index]
        
        -- First we load the image into data
        CHRData = NESBuilder:imageToCHRData(f,NESBuilder:getNESmakerColors())
        
        data.project.chr[data.project.chr.index] = CHRData
        
        -- Load CHR data and display on canvas
        NESBuilder:setCanvas("canvas")
        NESBuilder:loadCHRData(CHRData, p)

        c = NESBuilder:getControl('CHRPalette')
        c.setAll(p)
        
        dataChanged()
    end
end

function LoadCHR_cmd()
    local f = NESBuilder:openFile(nil)
    if f == "" then
        print("Open cancelled.")
        return
    end
    
    NESBuilder:setCanvas("canvas")
    p=data.project.palettes[data.project.palettes.index]
    data.project.chr[data.project.chr.index] = NESBuilder:loadCHRFile{f,p}
    
    --NESBuilder:loadCHRFile{"smb_new.chr", p, start=0x1000} 
    
    c = NESBuilder:getControl('CHRPalette')
    c.setAll(p)
    
    dataChanged()
end

function Open_cmd()
    if data.project.changed then
        q= NESBuilder:askyesnocancel("", string.format("Save changes to %s?",data.projectID))
        
        -- cancel
        if q==nil then return end
        
        if q==true then
            SaveProject_cmd()
        end
    end
    
    local f, projectID = NESBuilder:openFolder("projects")
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        data.projectID = projectID
        LoadProject_cmd()
    end
end

function Save_cmd()
    SaveProject_cmd()
end

function onExit(cancel)
    print("onExit")
    
    if data.project.changed then
        q= NESBuilder:askyesnocancel("", string.format('Save changes to "%s?"',data.projectID))
        
        -- cancel
        if q==nil then return true end
        
        if q==true then
            SaveProject_cmd()
        end
    end
    
    handlePluginCallback("onExit")
    
    saveSettings()
    
end

function CHR_cmd(t)
    local n = tonumber(t.name:sub(4))
    data.project.chr.index = n
    
    refreshCHR()
end

CHR0_cmd = CHR_cmd
CHR1_cmd = CHR_cmd
CHR2_cmd = CHR_cmd
CHR3_cmd = CHR_cmd
CHR4_cmd = CHR_cmd
CHR5_cmd = CHR_cmd
CHR6_cmd = CHR_cmd
CHR7_cmd = CHR_cmd

function canvas_cmd(t)
    local x = math.floor(t.event.x/t.scale)
    local y = math.floor(t.event.y/t.scale)
    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tileNum = tileY*0x10+tileX
    local tileOffset = 16*tileNum
    
    data.selectedColor = data.selectedColor or 0
    local c = data.selectedColor
    local cBits = NESBuilder:numberToBitArray(c)
    
    
    if not data.project.chr[data.project.chr.index] then
        -- Load in blank CHR if drawing on empty CHR.
        NESBuilder:setCanvas("canvas")
        data.project.chr[data.project.chr.index] = NESBuilder:loadCHRData()
    end
    
    if x<0 or y<0 or x>=128 or y>=128 then return end
    
    for i=0, 1 do
        local b = data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8]
        local l=NESBuilder:numberToBitArray(b)
        l[x%8]=cBits[7-i]
        b = NESBuilder:bitArrayToNumber(l)
        data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8] = b
    end
    
    NESBuilder:setCanvas("canvas")
    
    local p=data.project.palettes[data.project.palettes.index][data.selectedColor+1]
    NESBuilder:canvasPaint(x,y,p)
    
    dataChanged()
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
            
            NESBuilder:setCanvas("tsaTileCanvas")
            local TileData = {}
            
            for i=0,15 do
                TileData[i+1] = t.chrData[tileOffset+i+1]
            end
            
            data.project.tileData = TileData
            data.project.tileNum = tileNum
            
            NESBuilder:loadCHRData(TileData, p)
        elseif t.event.button == 3 and data.project.tileData then
            for i=0,15 do
                t.chrData[tileOffset+i+1] = data.project.tileData[i+1]
            end
            NESBuilder:setCanvas(t.name)
            
            if t.name == "tsaCanvas2" then
                data.project.squareoids[data.project.squareoids.index] = data.project.squareoids[data.project.squareoids.index] or {[0]=0,0,0,0}
                if tileX<=1 and tileY<=1 then
                    -- 02
                    -- 13
                    data.project.squareoids[data.project.squareoids.index][tileX*2+tileY] = data.project.tileNum
                    data.project.squareoids[data.project.squareoids.index].palette = data.project.palettes.index
                    print(data.project.squareoids[data.project.squareoids.index])
                end
            end
            NESBuilder:loadCHRData(t.chrData, p)
            dataChanged()
        end
    end
end

tsaCanvas2_cmd = tsaCanvas_cmd

function tsaSquareoidPrev_cmd()
    data.project.squareoids.index = math.max(0, data.project.squareoids.index - 1)
    updateSquareoid()
end
function tsaSquareoidNext_cmd()
    data.project.squareoids.index = math.min(255, data.project.squareoids.index + 1)
    updateSquareoid()
end

function tsaSquareoidNumber_cmd(t)
    if t.event.type == "KeyPress" and t.event.event.keycode==13 then
        data.project.squareoids.index = tonumber(NESBuilder:getControl("tsaSquareoidNumber").getText())
    end
end

function updateSquareoid()
    local tileNum
    local tileOffset1, tileOffset2
    
    local controlFrom = NESBuilder:getControlNew("tsaCanvas")
    local controlTo = NESBuilder:getControlNew("tsaCanvas2")
    
    data.project.squareoids[data.project.squareoids.index] = data.project.squareoids[data.project.squareoids.index] or {[0]=0,0,0,0}
    
    --local p = data.project.squareoids[data.project.squareoids.index].palette or data.project.palettes[data.project.palettes.index]
    local p = data.project.palettes[data.project.squareoids[data.project.squareoids.index].palette or 0]
    
    
    squareoidTileOffsets = {[0]=0,0x10,1,0x11}
    for sqTileNum=0,3 do
        tileNum = data.project.squareoids[data.project.squareoids.index][sqTileNum]
        tileOffset1 = 16 * tileNum
        tileOffset2 = 16 * squareoidTileOffsets[sqTileNum]
        
        for i=0,15 do
            controlTo.chrData[tileOffset2+i+1] = controlFrom.chrData[tileOffset1+i+1]
        end
    end
    
    NESBuilder:setCanvas(controlTo.name)
    NESBuilder:loadCHRData(controlTo.chrData, p)
    
    local control = NESBuilder:getControl("tsaSquareoidNumber")
    control.setText(data.project.squareoids.index)
end


function tsaTest_cmd()
    local p=data.project.palettes[data.project.palettes.index]
    NESBuilder:setCanvas("tsaCanvas")
    NESBuilder:loadCHRData(data.project.chr[data.project.chr.index], p)

    --NESBuilder:loadCHRFile{"smb_new.chr", p, start=0x1000} 
end

function onTabChanged_cmd(t)
    local tab = t.tab()
    if t.window.name == "Main" then
        if tab == "tsa" then
            local p=data.project.palettes[data.project.palettes.index]
            
            local control = NESBuilder:getControlNew("tsaCanvas")
            NESBuilder:setCanvas("tsaCanvas")
            --NESBuilder:loadCHRData(control.chrData, p)
            NESBuilder:loadCHRData(data.project.chr[data.project.chr.index], p)
            
            updateSquareoid()
        end
    end
end

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
    --if t.index<len(recentProjects.stack)-1 then
    if t.index<=len(recentProjects.stack)-1 then
        n = len(recentProjects.stack)- 1 - t.index
        id = recentProjects.stack[n]

        if data.project.changed then
            q= NESBuilder:askyesnocancel("", string.format("Save changes to %s?",data.projectID))
            
            -- cancel
            if q==nil then return end
            
            if q==true then
                SaveProject_cmd()
            end
        end
        
        data.projectID = id
        LoadProject_cmd()
    end
end