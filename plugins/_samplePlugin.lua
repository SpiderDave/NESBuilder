-- NESBuilder plugin
-- samplePlugin.lua
--
-- To enable this plugin, remove the "_" from the start of the filename.

local plugin = {
    author = "SpiderDave",
}

function plugin.onInit()
    NESBuilder:createTab("sampleplugin", "Sample Plugin")
    NESBuilder:setTab("sampleplugin")
    
    local x,y,control,pad
    
    pad=6
    x=pad*1.5
    y=pad*1.5
    
    control = NESBuilder:makeLabel{x=x,y=y,name="samplePluginLabel",clear=true,text="This is a label."}
    y = y + control.height + pad

    -- Simple button test
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="samplePluginButton",text="Test"}
    y = y + control.height + pad

    -- import a method from a python module and run it.
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="samplePluginButton2",text="Test Python"}
    y = y + control.height + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=config.buttonWidth, name="samplePluginButton3",text="Test Window"}
    y = y + control.height + pad

    -- Make a popup menu for this tab
    local items = {
        {name="foo", text="Foo"},
        {name="bar", text="Bar"},
        {name="baz", text="Baz"},
    }
    control = NESBuilder:makePopupMenu{name="samplePluginPopup", items=items, prefix=true}
end

function plugin.onBuild()
    print "onBuild!"
end

function samplePluginPopup_foo_cmd()
    print("Foo!")
end

function samplePluginButton1_cmd()
    print("I'm a plugin button!")
end

function samplePluginButton2_cmd()
    -- import a method from a python module and run it.
    local hello = NESBuilder:importFunction('plugins.hello','hello')
    hello()
end

function samplePluginButton3_cmd()
    NESBuilder:makeWindow{x=0,y=0,w=600,h=400, name="samplePluginWindow",title="Window!"}
    NESBuilder:setWindow("samplePluginWindow")

    NESBuilder:makeTab("samplePluginWindowTab1", "Test")
    NESBuilder:setTab("samplePluginWindowTab1")

    NESBuilder:makeButton{x=0,y=0,w=config.buttonWidth,name="samplePluginWindowButton1",text="close"}
end

function samplePluginWindowButton1_cmd(t)
    c=NESBuilder:getControl("samplePluginWindow")
    c.close()
end

return plugin