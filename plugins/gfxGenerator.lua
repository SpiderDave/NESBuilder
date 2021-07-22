-- NESBuilder plugin
-- gfxGenerator.lua

local plugin = {
    author = "SpiderDave",
    default = false,
}

function plugin.onInit()
    local buttonWidth = config.buttonWidth*7.5
    local buttonHeight = 27
    local inputWidth = buttonWidth*2
    local inputHeight = 29
    local control
    local pad=6
    local left = pad * 1.5
    local top = pad * 1.5
    local x,y = left, top
    local colX = 170
    
    plugin.rng = pythonEval('RNG()')
    
    makeTab{name="tabGfxGenerator", text="GFX Generator"}
    NESBuilder:setTabQt("tabGfxGenerator")
    
    local generatorNames = {}
    NESBuilder:setWorkingFolder(data.folders.plugins.."gfxGenerator/")
    local startsWith = pythonEval("lambda x,y: x.startswith(y)")
    plugin.generators = {}
    for f in python.iter(NESBuilder:files('./*.lua')) do
        local n = stem(f)
        if not startsWith(n, '_') then
            plugin.generators[n] = require(n)
            plugin.generators[n].rng = plugin.rng
            table.insert(generatorNames, n)
        end
    end
    NESBuilder:setWorkingFolder()
    
    push(x)
    control = NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight,name="buttonGfxGenerate",text="Generate"}
    x = x + control.width + pad
    control = NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight,name="buttonGfxSave",text="Save"}
    x = pop()
    y = y + control.height + pad
    
    control = NESBuilder:makeComboBox{x=x,y=y,w=buttonWidth, name="gfxList", itemList = generatorNames}
    y = y + control.height + pad
    
    control=NESBuilder:makeCanvasQt{x=x,y=y,w=16,h=16,name="canvasGfxGen", scale=16}
    y = y + control.height + pad
    
    plugin.outputCanvasSmall = {}
    for i = 0,4 do
        control=NESBuilder:makeCanvasQt{x=x,y=y,w=16,h=16,name="canvasGfxGenSmall"..i, scale=3}
        plugin.outputCanvasSmall[i] = control
        if i == 0 then
            x = x + control.width + pad
        else
            x = x + control.width
        end
    end
end

function buttonGfxGenerate_cmd()
    local brick, surface
    
    pythonEval("random.seed()")
    local seed = plugin.rng.random(100000)
    
    local types = {'single', 'left', 'middle', 'middle2', 'right'}
    for i,v in pairs(types) do
        brick = plugin.generators[getControl('gfxList').value].make({type=v, seed = seed})
        surface = brick.surface
        plugin.outputCanvasSmall[i-1].paste(surface)
    end
    
    getControl("canvasGfxGenSmall1").copy()
    getControl("canvasGfxGen").paste()
    
end

function buttonGfxSave_cmd()
    local f
    for i,control in pairs(plugin.outputCanvasSmall) do
        f = data.folders.plugins..string.format('gfxGenerator/brick%02x.png', i+1)
        print(f)
        control.save(f)
    end
end

return plugin