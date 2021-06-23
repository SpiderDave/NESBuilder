-- NESBuilder plugin
-- samplePlugin.lua

local plugin = {
    author = "SpiderDave",
    default = true,
}

function plugin.onInit()
    makeTab{name="sampleplugin", text="Sample Plugin"}
    setTab("sampleplugin")
    
    local x,y,control,pad
    
    pad=6
    x=pad*1.5
    y=pad*1.5
    
    control = NESBuilder:makeLabelQt{x=x, y=y, clear=true, text="This is a label."}
    y = y + control.height + pad
    
    -- Simple button test
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="Button1", text="Test"}
    control.helpText = "This is Button1"
    y = y + control.height + pad

    -- import a method from a python module and run it.
    control = NESBuilder:makeButton{x=x, y=y,w=config.buttonWidthNew, name="Button2", text="Test Python"}
    control.helpText = "This is Button2"
    y = y + control.height + pad
    
end

function plugin.onBuild()
    print "onBuild!"
end

function plugin.Button1_cmd()
    print("I'm a plugin button!")
end

function plugin.Button2_cmd()
    -- import a method from a python module and run it.
    local hello = NESBuilder:importFunction('plugins.hello','hello')
    hello()
end

return plugin