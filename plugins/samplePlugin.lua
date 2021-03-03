-- NESBuilder plugin
-- samplePlugin.lua

local plugin = {
    author = "SpiderDave",
}

function plugin.onInit()
    makeTab{name="sampleplugin", text="Sample Plugin"}
    setTab("sampleplugin")
    
    local x,y,control,pad
    
    pad=6
    x=pad*1.5
    y=pad*1.5
    
    control = NESBuilder:makeLabelQt{x=x,y=y,name="samplePluginLabel",clear=true,text="This is a label."}
    y = y + control.height + pad

    -- Simple button test
    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth, name="samplePluginButton1",text="Test"}
    y = y + control.height + pad

    -- import a method from a python module and run it.
    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth, name="samplePluginButton2",text="Test Python"}
    y = y + control.height + pad
    
    -- not re-implemented yet
--    control = NESBuilder:makeButton2{x=x,y=y,w=config.buttonWidth, name="samplePluginButton3",text="Test Window"}
--    y = y + control.height + pad

    -- Make a popup menu for this tab
--    local items = {
--        {name="foo", text="Foo"},
--        {name="bar", text="Bar"},
--        {name="baz", text="Baz"},
--    }
--    control = NESBuilder:makePopupMenu{name="samplePluginPopup", items=items, prefix=true}
end

function plugin.onBuild()
    print "onBuild!"
end

function samplePluginPopup_foo_cmd()
    print("Foo!")
end

function plugin.samplePluginButton1_cmd()
    print("I'm a plugin button!")
end

function plugin.samplePluginButton2_cmd()
    -- import a method from a python module and run it.
    local hello = NESBuilder:importFunction('plugins.hello','hello')
    hello()
end

function plugin.samplePluginButton3_cmd()
    NESBuilder:makeWindow{x=0,y=0,w=600,h=400, name="samplePluginWindow",title="Window!"}
    NESBuilder:setWindow("samplePluginWindow")

    NESBuilder:makeTabQt("samplePluginWindowTab1", "Test")
    NESBuilder:setTabQt("samplePluginWindowTab1")

    NESBuilder:makeButton{x=0,y=0,w=config.buttonWidth,name="samplePluginWindowButton1",text="close"}
end

function plugin.samplePluginWindowButton1_cmd(t)
    c=NESBuilder:getControl("samplePluginWindow")
    c.close()
end

return plugin