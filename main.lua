config = {
    title="NESBuilder",
    width=850,
    height=700,
    upperHex=false,
    cellWidth=24,
    cellHeight=24,
    buttonWidth=20,
    buttonWidthSmall=4,
    aboutURL = "https://github.com/SpiderDave/NESBuilder",
    colors = {
        bk='#202036',
        bk2='#303046',
        bk3='#404050',      -- text background
        bk_hover='#454560',
        fg = '#eef',
        bk_menu_highlight='#606080',
    },
    pluginFolder = "plugins",
    launchText=[[
Created by SpiderDave
-------------------------------------------------------------------------------------------
To open a project select "Open Project" from the "File" menu.
To create a new project, do the same as above, but create a new folder.

Many things do not work yet.

Working:
    * loading, saving projects
    * Build Project
    * About
    * Most of the CHR tab
        - only 128x128 (4K) CHR banks at the moment
        - Fixed to 8 banks for now
        - you can click to change pixels on it, but it's just the 
          start of a proper editing mode
        - CHR refreshing is slow
Working, but really just for testing:
    * Extract Level - SMB Level Extractor
    * Make CHR - Makes chr from a .png with set colors for now
      (use chr.png to test)

Not working:
    * Cut, Copy, Paste

ToDo:
    * Show palette index
    * Ability to remove palettes
    * Palette sets and extra labels
    * More error handling
    * Replace this page with launcher
    * undo!
    * plugin support
]]
}

__print = print
print = function(txt)
    __print("[Lua] "..(txt or ''))
end


makeHex = function(n)
    if config.upperHex then
        return string.format("%02X",n)
    else
        return string.format("%02x",n)
    end
end

data = {selectedColor = 0x0f}
data.palettes = {}
data.settings = {}

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
    local x,y
    local x2,y2
    
    print("init")
    
    Python.incLua("Tserial")
    util = Python.incLua("util")
    
    -- make sure projects folder exists
    Python:makeDir(data.folders.projects)
    
    Python.setTab("Main")
    
    pad=6
    x=pad*1.5
    y=pad*1.5
    
    top = Python.y + pad*1.5
    left = pad*1.5

--    b=Python.makeButton{x=x,y=y,name="LoadProject",text="Load Project"}
--    y = y + b.height + pad
    
--    b=Python.makeButton{x=x,y=y,name="SaveProject",text="Save Project"}
--    y = y + b.height + pad
    
    b=Python.makeButton{x=x,y=y,w=config.buttonWidth, name="BuildProject",text="Build Project"}
    y = y + b.height + pad
    
    b=Python.makeButton{x=x,y=y,w=config.buttonWidth,name="ButtonLevelExtract",text="Extract Level"}
    y = y + b.height + pad
    
    b=Python.makeButton{x=x,y=y,w=config.buttonWidth,name="ButtonMakeCHR",text="Make CHR"}
    y = y + b.height + pad
    
    buttonHeight = b.height

--    for i=0,4 do
--        b=Python.makeButton{x=x,y=y,name="Button"..i,text="Button"..i}
--        y = y + b.height + pad
--    end
    
    --b=Python.makeText{x=x,y=y, lineHeight=20,lineWidth=80, name="Text1",text="Text1"}
    
    x2,y2=x,y
    b=Python.makeText{x=x,y=y,w=20, w=150,h=buttonHeight, name="Text1",text="Text1"}
    y = y + b.height + pad
    
    b=Python.makeButton{x=left+150+pad,y=y2,w=config.buttonWidth,name="ButtonSetText1",text="Set"}
    x=left
    y = y + b.height + pad
    
    
    Python.setTab("Palette")
    Python.setDirection("h")
    
    x,y=left,top
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    c=Python.makePaletteControl{x=pad*1.5,y=pad*1.5,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="Palette", palette=nespalette}
    
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    
    x2=Python.x+pad + 100
    y2=pad*1.5
    
    placeX = left
    placeY = top
    
    x=left
    y=top + 100+pad*1.5
    b=Python.makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonPrevPalette",text="<"}
    
    x = x + b.width + pad
    b=Python.makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonNextPalette",text=">"}
   
    x = x + b.width + pad
    b=Python.makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonAddPalette",text="+"}
    
    x = left
    y = y + b.height + pad
    
    x2,y2=x,y
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    c=Python.makePaletteControl{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="PaletteEntry", palette=palette}
    y = y + 32 + pad
    
    x=Python.x+pad
    c=Python.makeLabel{x=x,y=y2+3,name="PaletteEntryLabel",clear=true,text="foobar"}
    
    x = left
    
--    b=Python.makeText{x=x,y=y, lineHeight=16,lineWidth=80, name="Text1",text="Text1"}
--    y = y + b.height + pad
    
--    x=x2
--    y=y2
--    b=Python.makeList{x=x,y=y, name="PaletteList"}
--    b.append("palette00")
--    b.append("palette01")
--    b.append("palette02")
--    b.append("palette03")
    
    
    Python.setTab("Image")
    p = {[0]=0x0f,0x21,0x11,0x01}
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end

    x=pad
    y=pad+128*3+pad*1.5
    placeY = y
    c=Python.makePaletteControl{x=x,y=y,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="CHRPalette", palette=palette}
    
    x=left + 120
    y=placeY
    b=Python.makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonPrevPaletteCHR",text="<"}

    x=x+b.width+pad
    y=placeY
    b=Python.makeButton{x=x,y=y,w=config.buttonWidthSmall,name="ButtonNextPaletteCHR",text=">"}

    x=left
    
    y = y + 32 + pad
    b=Python.makeButton{x=x,y=y,w=config.buttonWidth,name="LoadCHRImage",text="Load Image"}

    y = y + b.height + pad
    b=Python.makeButton{x=x,y=y,w=config.buttonWidth,name="LoadCHRNESmaker",text="Load NESmaker Image"}

    y = y + b.height + pad
    
    --b=Python.makeButton{x=x,y=y,name="ButtonCHRTest1",text="test"}
    b=Python.makeButton{x=x,y=y,w=config.buttonWidth,name="LoadCHR",text="Load .chr"}
    y = y + b.height + pad
    
    
    
--    f="chr.png"
--    Python:loadImageToCanvas(f)
    
    -- Import the "LevelExtract" method from "SMBLevelExtract.py" and 
    -- add it to the "Python" table.
    --LevelExtract = Python:importFunction('include.SMBLevelExtract','LevelExtract')
    
    x=128*3+pad*3
    y=top
    c=Python.makeLabel{x=x,y=y,name="CHRNumLabel",clear=true,text="CHR"}
    y = y + buttonHeight
    
    --y=top
    x=128*3+pad*3
    for i=0,7 do
        b=Python.makeButton{x=x,y=y,w=config.buttonWidth,name="CHR"..i,text="CHR "..i}
        y = y + b.height + pad
    end
    
    loadSettings()
    
    LoadProject_cmd()
end

function loadSettings()
    filename = "settings.dat"
    data.settings = util.unserialize(util.getFileContents(filename)) or {project = data.projectID}
    
    -- Load last project
    data.projectID = data.settings.project or data.projectID
end

function saveSettings()
    data.settings.project = data.projectID
    
    filename = "settings.dat"
    util.writeToFile(filename,0, util.serialize(data.settings), true)
end


function doCommand(ctrl)
    if type(ctrl) == 'string' then
        print("doCommand "..ctrl)
    else
        print("doCommand "..ctrl.name)
    end
end

function Palette_cmd(t)
    if not t.cellNum then return end -- the frame was clicked.
    
    if t.event.num == 1 then
        print(string.format("Selected palette %02x",t.cellNum))
        data.selectedColor = t.cellNum
    end
end

function CHRPalette_cmd(t)
    if t.event.num == 1 then
        print(string.format("Selected palette %02x",t.cellNum))
        data.selectedColor = t.cellNum
        --data.drawColorIndex = t.cellNum
    elseif t.event.num == 3 then
        print(string.format("Set palette %02x",data.selectedColor or 0x0f))
        if t.set(t.cellNum, data.selectedColor) then
            refreshCHR()
            dataChanged()
        end
    end
end

function ButtonMakeCHR_cmd()
    f = Python:openFile({{"Images", ".png"}})
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        f2 = Python:saveFileAs({{"CHR", ".chr"}},'output.chr')
        if f2 == "" then
            print("Save cancelled.")
        else
            print("file: "..f2)
            Python:imageToCHR(f,f2,Python:getNESColors('0f211101'))
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
    
    c = Python.getControl('PaletteEntry')
    c.setAll(p)

    c = Python.getControl('CHRPalette')
    c.setAll(p)
    
    c = Python.getControl('PaletteEntryLabel')
    c.control.text = string.format("Palette%02x",data.project.palettes.index)
    
    refreshCHR()
end

function ButtonPrevPalette_cmd()
    c = Python.getControl('PaletteEntry')
    
    data.project.palettes.index = data.project.palettes.index-1
    --if data.project.palettes.index < 0 then data.project.palettes.index=#data.project.palettes end
    if data.project.palettes.index < 0 then data.project.palettes.index= 0 end
    print(data.project.palettes.index)
    
    PaletteEntryUpdate()
end

function ButtonNextPalette_cmd()
    c = Python.getControl('PaletteEntry')
    
    data.project.palettes.index = data.project.palettes.index+1
    --if data.project.palettes.index > #data.project.palettes then data.project.palettes.index=0 end
    if data.project.palettes.index > #data.project.palettes then data.project.palettes.index = #data.project.palettes end
    if data.project.palettes.index > 255 then data.project.palettes.index = 255 end
    print(data.project.palettes.index)
    
    PaletteEntryUpdate()
end

ButtonPrevPaletteCHR_cmd = ButtonPrevPalette_cmd
ButtonNextPaletteCHR_cmd = ButtonNextPalette_cmd

function ButtonLevelExtract_cmd()
    f = Python:openFile({{"NES rom", ".nes"}})
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        
        f2 = Python:saveFileAs({{"ASM", ".asm"}},'output.asm')
        if f2 == "" then
            print("Save cancelled.")
        else
            print("file: "..f2)
            SMBLevelExtract(f,f2)
        end
    end
end

function LoadProject_cmd()
    print("loading project "..data.projectID)
    
    projectFolder = data.projectID.."/"
    
    filename = data.folders.projects..projectFolder.."project.dat"
    data.project = util.unserialize(util.getFileContents(filename))
    
    if not data.project then
        data.project = {}
    end
    
    -- update project folder in case it's been moved
    data.project.folder = projectFolder
    
    -- use default palettes if not found
    data.project.palettes = data.project.palettes or util.deepCopy(data.palettes)
    
    
    data.project.chr = data.project.chr or {index=0}
    
    -- update palette entry
    data.project.palettes.index = 0
    PaletteEntryUpdate()
    
    
    
    
    dataChanged(false)
    
--    c = Python.getControl('PaletteList')
--    c.set(data.project.paletteIndex or 0)
    
--    f=data.folders.projects..projectFolder.."chr.png"
--    Python:loadImageToCanvas(f)
    
    updateTitle()
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
    
    Python:setTitle(string.format("%s - %s%s", config.title, data.projectID, changed))
end

function Build_cmd()
    BuildProject_cmd()
end

function BuildProject_cmd()
    -- make sure folder exists for this project
    Python:makeDir(data.folders.projects..data.project.folder)

    -- remove old format
    data.project.chrData = nil
    
    -- save CHR
    for i=0,#data.project.chr do
        if data.project.chr[i] then
            f = data.folders.projects..data.project.folder..string.format("chr%02x.chr",i)
            print("File created "..f)
            util.writeToFile(f, 0, data.project.chr[i], true)
        end
    end
    
--    if data.project.chrData then
--        f = data.folders.projects..data.project.folder.."output.chr"
--        print("File created "..f)
--        util.writeToFile(f, 0, data.project.chrData, true)
--    end

    c = Python.getControl('PaletteList')
    filename = data.folders.projects..projectFolder.."palettes.asm"

    out=""
    
    lowHigh = {{"low","<"},{"high",">"}}
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
        pal = data.project.palettes[palNum]
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
    
    util.writeToFile(filename,0, out, true)
    
    
    filename = data.folders.projects..projectFolder.."version.asm"
    
    t = os.date("*t")
    out=string.format("; %s.%s.%s %s:%s\n",t.year, t.month, t.day, t.hour, t.min)
    out=string.format('version:\n    .db "v%s.%s.%s"\n\n',t.year, t.month, t.day)
    
    util.writeToFile(filename,0, out, true)
    
end

function SaveProject_cmd()
    -- make sure folder exists for this project
    Python:makeDir(data.folders.projects..data.project.folder)

    filename = data.folders.projects..data.project.folder.."project.dat"
    util.writeToFile(filename,0, util.serialize(data.project), true)
    
    dataChanged(false)
    
    print(string.format("Project saved (%s)",data.projectID))
end

function Label1_cmd(name, label)
    print(name)
end


function PaletteEntry_cmd(t)
    if not t.cellNum then return end -- the frame was clicked.
    
    if t.event.num == 1 then
        print(string.format("Selected palette %02x",t.cellNum))
        data.selectedColor = t.cellNum
    elseif t.event.num == 3 then
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
    Python.exec(string.format("webbrowser.get('windows-default').open('%s')",config.aboutURL))
end

function Quit_cmd()
    Python.Quit()
end

function refreshCHR()
    p=data.project.palettes[data.project.palettes.index]
    
    --Python:loadCHRData(data.project.chrData, p)
    Python:loadCHRData(data.project.chr[data.project.chr.index], p)

    c = Python.getControl('CHRNumLabel')
    c.control.text = string.format("%02x", data.project.chr.index)
end

function LoadCHRImage_cmd()
    local CHRData
    f = Python:openFile(nil)
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        --Python:loadImageToCanvas(f)
        
        p=data.project.palettes[data.project.palettes.index]
        
        -- First we load the image into data
        CHRData = Python:imageToCHRData(f,Python:getNESColors(p))
        --CHRData = Python:imageToCHRData(f,Python:getNESmakerColors())
        
        data.project.chr[data.project.chr.index] = CHRData
        
        -- Load CHR data and display on canvas
        Python:loadCHRData(CHRData, p)

        c = Python.getControl('CHRPalette')
        c.setAll(p)
        
        dataChanged()
    end
end

function LoadCHRNESmaker_cmd()
    local CHRData
    f = Python:openFile(nil)
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        --Python:loadImageToCanvas(f)
        
        p=data.project.palettes[data.project.palettes.index]
        
        -- First we load the image into data
        --CHRData = Python:imageToCHRData(f,Python:getNESColors(p))
        CHRData = Python:imageToCHRData(f,Python:getNESmakerColors())
        
        data.project.chr[data.project.chr.index] = CHRData
        
        -- Load CHR data and display on canvas
        Python:loadCHRData(CHRData, p)

        c = Python.getControl('CHRPalette')
        c.setAll(p)
        
        dataChanged()
    end
end


function LoadCHR_cmd()
    f = Python:openFile(nil)
    if f == "" then
        print("Open cancelled.")
        return
    end
    
    p=data.project.palettes[data.project.palettes.index]
    data.project.chr[data.project.chr.index] = Python:loadCHRFile(f,p)
    
    c = Python.getControl('CHRPalette')
    c.setAll(p)
    
    dataChanged()
end

function Open_cmd()
    if data.project.changed then
        q= Python:askyesnocancel("", string.format("Save changes to %s?",data.projectID))
        
        -- cancel
        if q==nil then return end
        
        if q==true then
            SaveProject_cmd()
        end
    end
    
    f, projectID = Python:openFolder("projects")
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        --Python:loadImageToCanvas(f)
        data.projectID = projectID
        LoadProject_cmd()
    end
end

function Save_cmd()
    SaveProject_cmd()
--    f = Python:saveFileAs(nil)
--    if f == "" then
--        print("Save cancelled.")
--    else
--        print("file: "..f)
--    end
end

function Button0_cmd()
    Python:saveCanvasImage()
end

function onExit(cancel)
    print("onExit")
    
    if data.project.changed then
        q= Python:askyesnocancel("", string.format('Save changes to "%s?"',data.projectID))
        
        -- cancel
        if q==nil then return true end
        
        if q==true then
            SaveProject_cmd()
        end
    end
    
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
    local x = math.floor(t.event.x/3)
    local y = math.floor(t.event.y/3)
    local tileX = math.floor(x/8)
    local tileY = math.floor(y/8)
    local tileNum = tileY*0x10+tileX
    local tileOffset = 16*tileNum
    
--    for i=0,7 do
--        data.project.chr[data.project.chr.index][tileOffset+i+1]=0xff
--        data.project.chr[data.project.chr.index][tileOffset+i+1+8]=0
--    end
    
    local c = data.selectedColor
    local cBits = Python:numberToBitArray(c)
    
    for i=0, 1 do
        local b = data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8]
        local l=Python:numberToBitArray(b)
        l[x%8]=cBits[7-i]
        b = Python:bitArrayToNumber(l)
        data.project.chr[data.project.chr.index][tileOffset+1+(i*8)+y%8] = b
    end
    
    --print(string.format("(%03i, %03i)",x,y))
    --print(string.format("%02x",tileNum))

    dataChanged()
    refreshCHR()
end
