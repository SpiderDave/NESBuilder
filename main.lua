config = {
    width=800,
    height=600,
    upperHex=false,
    cellWidth=24,
    cellHeight=24,
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

data = {selectedColor = {}}
data.palettes = {}


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
    print("init")
    
    Python.setTab("Main")
    
    pad=6
    x=pad*1.5
    y=pad*1.5

    b=Python.makeButton{x=x,y=y,name="ButtonLevelExtract",text="Extract Level"}
    y = y + b.height + pad


    for i=0,4 do
        b=Python.makeButton{x=x,y=y,name="Button"..i,text="Button"..i}
        y = y + b.height + pad
    end
    
    Python.setTab("Palette")
    Python.setDirection("h")
    
    p = {[0]=0x0f,0x21,0x11,0x01}
    c=Python.makePaletteControl{x=pad*1.5,y=pad*1.5,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name="Palette", palette=nespalette}
    
    palette = {}
    for i=0,#p do
        palette[i] = nespalette[p[i]]
    end
    
    top = Python.y + pad*1.5
    left = pad*1.5
    
    placeX = left
    placeY = top
    
    for y = 0,1 do
        for x = 0,3 do
            Python.makePaletteControl{x=placeX,y=placeY,cellWidth=config.cellWidth,cellHeight=config.cellHeight, name=string.format("Pal%x",y*4+x), palette=palette,text="AA"}
            placeX = Python.x+pad*1.5
        end
        placeX = left
        placeY = Python.y+pad
    end
    
    f="chr.png"
    Python:loadImageToCanvas(f)
    
    -- Import the "LevelExtract" method from "SMBLevelExtract.py" and 
    -- add it to the "Python" table.
    Python:importFunction('SMBLevelExtract','LevelExtract')
end

function doCommand(ctrl)
    if ctrl then
        print("doCommand "..ctrl)
    end
end

function Palette_cmd(name, dummy,t)
    t.cell = Python.getControl(t.cellName)
    if t.num ==1 then
        data.selectedColor.bg = t.cell.bg
        data.selectedColor.fg = t.cell.fg
        data.selectedColor.text = t.cell.text
        print(string.format("Selected palette %02x",t.cellNum))
    end
end


f = function(name, dummy,t)
    t.cell = Python.getControl(t.cellName)
    t.palNum = tonumber(string.sub(name, -1))
    Pal_cmd(name,dummy,t)
end

Pal0_cmd = f
Pal1_cmd = f
Pal2_cmd = f
Pal3_cmd = f
Pal4_cmd = f
Pal5_cmd = f
Pal6_cmd = f
Pal7_cmd = f

function Pal_cmd(name, dummy,t)
    if t.num==3 then
        t.cell.bg = data.selectedColor.bg
        t.cell.fg = data.selectedColor.fg
        t.cell.text = data.selectedColor.text
    elseif t.num==1 then
        data.selectedColor.bg = t.cell.bg
        data.selectedColor.fg = t.cell.fg
        data.selectedColor.text = t.cell.text
        print(string.format("Selected palette %02x",t.cellNum))
    end
end


function Button0_cmd()
    --Python.exec("print('hello world!')")
    --Python.exec("root.geometry('400x400')")
    --Python.exec("controls['Button0'].place(x=0,y=0)")
    --Python.exec("controls['Button0']['text'] = 'foo'")
    --controls = Python.exec("ForLua.execRet = lambda: controls")
--    controls = Python.eval("controls['Button0']['text']")
--    print(controls)
    
    -- Import the "LevelExtract" method from "SMBLevelExtract.py" and 
    -- add it to the "Python" table.
    --Python:importFunction('SMBLevelExtract','LevelExtract')
    
    --Python.LevelExtract('smbGreatEd.nes','outputtest.asm')
end

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
            Python.LevelExtract(f,f2)
        end
    end
end


function Label1_cmd(name, label)
    print(name)
end

function About_cmd()
    Python.exec("webbrowser.get('windows-default').open('https://github.com/SpiderDave/SpideyGui')")
end

function Quit_cmd()
    Python.Quit()
end

function Open_cmd()
    f = Python:openFile(nil)
    if f == "" then
        print("Open cancelled.")
    else
        print("file: "..f)
        Python:loadImageToCanvas(f)
    end
end

function Save_cmd()
    f = Python:saveFileAs()
    if f == "" then
        print("Save cancelled.")
    else
        print("file: "..f)
    end
end


function onExit(cancel)
    print("onExit")
end