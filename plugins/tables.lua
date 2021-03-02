-- NESBuilder plugin
-- tables.lua

local plugin = {
    author = "SpiderDave",
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
    
    --NESBuilder:makeTabQt{name="tabTableTools", text="Table Tools"}
    makeTab{name="tabTableTools", text="Table Tools"}
    NESBuilder:setTabQt("tabTableTools")
    
    control=NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, clear=true,text="Label:"}
    control.setFont("Verdana", 12)
    push(x)
    x = colX
    control = NESBuilder:makeLineEdit{x=x,y=y,w=inputWidth*.5,h=inputHeight, name="sineLabel", text='sineTable'}
    y = y + control.height + pad
    
    x = pop()
    control=NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, clear=true,text="Points per quarter:"}
    control.setFont("Verdana", 12)
    push(x)
    x = colX
    control = NESBuilder:makeLineEdit{x=x,y=y,w=32,h=inputHeight, name="sinePoints", text='16'}
    y = y + control.height + pad
    
    x = pop()
    control=NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, clear=true,text="Amplitude: "}
    control.setFont("Verdana", 12)
    push(x)
    x = colX
    control = NESBuilder:makeLineEdit{x=x,y=y,w=32,h=inputHeight, name="sineAmplitude", text='100'}
    y = y + control.height + pad
    
    x = pop()
    control = NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight,name="buttonSineTable",text="Sine Table"}
    push(x)
    x = x + control.width + pad
    
    control = NESBuilder:makeButtonQt{x=x,y=y,w=100,h=buttonHeight,name="buttonSineTableClear",text="clear"}
    x=pop()
    y = y + control.height + pad
    
    control = NESBuilder:makeTextEdit{x=x,y=y,w=700,h=500,name="textSineTable"}
    y = y + control.height + pad
    
    plugin.data.sineTables = {}
end

function plugin.buttonSineTableClear_cmd(t)
    NESBuilder:getControl('textSineTable').clear()
    plugin.data.sineTables = {}
end

function plugin.buttonSineTable_cmd(t)
    local control
--    local generateSineTable = NESBuilder:importFunction('plugins.tables','generateSineTable')
--    local makeTable = NESBuilder:importFunction('plugins.tables','makeTable')
    local points, amp, label
    
    if not pcall(function()
        label = NESBuilder:getControl('sineLabel').text
        points = int(NESBuilder:getControl('sinePoints').text)
        amp = int(NESBuilder:getControl('sineAmplitude').text)
    end) then
        print('invalid value(s)')
        return
    end
    
--    control = NESBuilder:getControl('textSineTable')
    
--    local t = generateSineTable(points, amp)
    
--    if plugin.nTables > 0 then
--        control.print()
--        control.print(string.format('%s%d:', label, plugin.nTables))
--    else
--        control.print(string.format('%s:', label))
--    end
    
--    control.print('    ; half sine wave')
--    control.print(string.format('    ; table size: %d', points*2))
--    control.print(string.format('    ; period: %d (quarter cycle = %d, half cycle = %d)', points*4, points, points*2))
--    control.print(string.format('    ; amplitude %d', amp))
    
--    control.print(makeTable(t.q1))
--    control.print(makeTable(t.q2))
    
--    plugin.nTables = plugin.nTables + 1
    
    local t = {
        label = label,
        points = points,
        amp = amp,
    }
    table.insert(plugin.data.sineTables, t)
    
    labelCount = {}
    for i,v in ipairs(plugin.data.sineTables) do
        labelCount[v.label] = (labelCount[v.label] or 0) + 1
        v.i = labelCount[v.label]
    end
    
    updateSineTables()
    
--    print(plugin.data.sineTables)
--    print(labelCount)
end

function updateSineTables()
    local generateSineTable = NESBuilder:importFunction('plugins.tables','generateSineTable')
    local makeTable = NESBuilder:importFunction('plugins.tables','makeTable')

    local control = NESBuilder:getControl('textSineTable')
    control.clear()
    
    for i,v in ipairs(plugin.data.sineTables) do
        local t = generateSineTable(v.points, v.amp)
        
        if i>1 then control.print() end
        
        if v.i >1 then
            control.print(string.format('%s%d:', v.label, v.i))
        else
            control.print(string.format('%s:', v.label))
        end
        control.print(string.format('    ; Table size: %d (half cycle)', v.points*2))
        control.print(string.format('    ; Amplitude %d', v.amp))
        
        control.print(makeTable(t.q1))
        control.print(makeTable(t.q2))
    end
end

return plugin