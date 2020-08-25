-- NESBuilder plugin
-- rominfo.lua
--
-- To enable this plugin, remove the "_" from the start of the filename.

local plugin = {
    author = "SpiderDave",
}

function plugin.onInit()
    local stack, push, pop = NESBuilder:newStack()
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
    control = NESBuilder:makeMenu{name="menuFile", text="Test", items=items, prefix=false, subMenu = "menuHelp"}

end

function rominfoShow_cmd()
    local stack, push, pop = NESBuilder:newStack()
    local x,y,control,pad
    local top,left,bottom
    
    pad=6
    left=pad*2
    top=pad*2
    bottom=0
    x,y=left,top
    
    local window = NESBuilder:makeWindow{x=0,y=0,w=700,h=450, name="rominfoWindow",title="Rom Info"}
    NESBuilder:setWindow("rominfoWindow")
    
    plugin.window = window
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="rominfoLoadRom",text="Load rom"}
    y = y + control.height + pad

    control = NESBuilder:makeText{x=x,y=y,w=window.width-left*2,h=400, name="rominfoOutput",clear=true,text=""}
    y = y + control.height + pad
end

function rominfoLoadRom_cmd()
    
    local f = NESBuilder:openFile({{"NES rom", ".nes"}})
    plugin.window.front()
    
    if f == "" then
        print("Open cancelled.")
        return
    end
    local c=NESBuilder:getControl('rominfoOutput')
    c.clear()
    
    c.print(f)
    local fileData = NESBuilder:getFileData(f)
    local getHash = NESBuilder:importFunction('plugins.hash','getHash')
    c.print()
    for _,method in pairs({'md5','sha1','sha256','crc32'}) do
        local hash = getHash(fileData, method)
        c.print(string.format('%6s: %s', method, hash))
    end
    
    
end

return plugin