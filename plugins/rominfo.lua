-- NESBuilder plugin
-- rominfo.lua

local plugin = {
    author = "SpiderDave",
}

function plugin.onInit()
    local x,y,control,pad
    local top,left,bottom
    
    pad=6
    left=pad*1.5
    top=pad*1.5
    bottom=0
    x,y=left,top
    
    local items = {
        {name="rominfoShow", text="Rom Info"},
    }
    control = NESBuilder:makeMenuQt{name="menuFile", menuItems=items}

end

function rominfoShow_cmd()
    local x,y,control,pad
    local top,left,bottom
    
    pad=6
    left=pad*2
    top=pad*2
    bottom=0
    x,y=left,top
    
--    local window = NESBuilder:makeWindow{x=0,y=0,w=700,h=450, name="rominfoWindow",title="Rom Info"}
--    NESBuilder:setWindow("rominfoWindow")
    
    --local window = NESBuilder.getWindowQt()
    
    control = NESBuilder:makeTabQt{x=x,y=y,w=config.width,h=config.height,name="romInfoTab",text="Rom Info"}
    NESBuilder:setTabQt("romInfoTab")
    
    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth, name="rominfoLoadRom",text="Load rom"}
    y = y + control.height + pad

    control = NESBuilder:makeTextEdit{x=x,y=y,w=700,h=400,name="rominfoOutput"}
    
    y = y + control.height + pad*8
    control=NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight,name="buttonRomInfoClose",text="close"}
    
    NESBuilder:switchTab('romInfoTab')
end

function buttonRomInfoClose_cmd() closeTab('romInfoTab', 'Launcher') end

function rominfoLoadRom_cmd()
    local control, c
    local f = NESBuilder:openFile{filetypes={{"NES rom", ".nes"}}}
    
    if f == "" then
        print("Open cancelled.")
        return
    end
    local c=NESBuilder:getControl('rominfoOutput')
    c.clear()
    
    --c = {print=print}
    --c.print = function(txt) c.print_(txt) end
    c.print = function(txt) c.appendPlainText((txt or '')) end
    
    c.print(f)
    local fileData = NESBuilder:getFileData(f)
    local getHash = NESBuilder:importFunction('plugins.hash','getHash')
    c.print()
    for _,method in pairs({'md5','sha1','sha256','crc32'}) do
        local hash = getHash(fileData, method)
        c.print(string.format('%6s: %s', method, hash))
    end
    c.print()
    
    
end

return plugin