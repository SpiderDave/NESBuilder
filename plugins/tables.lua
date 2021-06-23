-- NESBuilder plugin
-- tables.lua

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
    
    --NESBuilder:makeTabQt{name="tabTableTools", text="Table Tools"}
    makeTab{name="tabTableTools", text="Table Tools"}
    NESBuilder:setTabQt("tabTableTools")
    
    control=NESBuilder:makeLabelQt{x=x,y=y,w=buttonWidth, clear=true,text="Sine Table Generator"}
    control.setFont("Verdana", 13)
    y = y + control.height + pad * 2
    
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
    
    control = NESBuilder:makeCheckbox{x=x,y=y,name="sine16Bit", text="Use 16-bit", value=0}
    y = y + control.height + pad
    
    x = pop()
    control = NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight,name="buttonSineTable",text="Generate"}
    push(x)
    x = x + control.width + pad
    
    control = NESBuilder:makeButton{x=x,y=y,w=100,h=buttonHeight,name="buttonSineTableClear",text="Clear"}
    x=pop()
    y = y + control.height + pad
    
    control = NESBuilder:makeTextEdit{x=x,y=y,w=700,h=450,name="textSineTable"}
    y = y + control.height + pad
end

function plugin.buttonSineTableClear_cmd(t)
    NESBuilder:getControl('textSineTable').clear()
    data.project.sineTables = {}
end

function plugin.onLoadProject()
    data.project.sineTables = data.project.sineTables or {}
    updateSineTables()
end

function plugin.buttonSineTable_cmd(t)
    local control
    local points, amp, label
    
    if not pcall(function()
        label = NESBuilder:getControl('sineLabel').text
        points = int(NESBuilder:getControl('sinePoints').text)
        amp = int(NESBuilder:getControl('sineAmplitude').text)
    end) then
        print('invalid value(s)')
        return
    end
    
    local t = {
        label = label,
        points = points,
        amp = amp,
    }
    table.insert(data.project.sineTables, t)
    
    -- This index will be used to handle duplicate labels
    labelCount = {}
    for i,v in ipairs(data.project.sineTables) do
        labelCount[v.label] = (labelCount[v.label] or 0) + 1
        v.i = labelCount[v.label]
    end
    
    updateSineTables()
end

function updateSineTables()
    local generateSineTable = NESBuilder:importFunction('plugins.tables','generateSineTable')
    local makeTableData = NESBuilder:importFunction('plugins.tables','makeTableData')
    
    local control = NESBuilder:getControl('textSineTable')
    control.clear()
    
    for i,v in ipairs(data.project.sineTables) do
        local t = generateSineTable(v.points, v.amp, 2)
        
        local labelBase = string.format('%s%s', v.label, v.i>1 and v.i or '')
        
        control.print(labelBase..'_low:')
        control.print(string.format('    ; Points per quarter cycle: %d', v.points))
        control.print(string.format('    ; Amplitude: %d', v.amp))
        control.print(makeTableData(t.q1Low))
        control.print()
        control.print(makeTableData(t.q2Low))
        control.print()
        control.print(makeTableData(t.q3Low))
        control.print()
        control.print(makeTableData(t.q4Low))
        control.print()
        control.print(labelBase..'_high:')
        control.print(makeTableData(t.q1High))
        control.print()
        control.print(makeTableData(t.q2High))
        control.print()
        control.print(makeTableData(t.q3High))
        control.print()
        control.print(makeTableData(t.q4High))
        control.print()
    end
end

function plugin.onBuild()
    local filename, out
    
    if #data.project.sineTables == 0 then return end
    
    filename = data.folders.projects..projectFolder.."code/tables.asm"
    out = NESBuilder:getControl('textSineTable').text
    util.writeToFile(filename, 0, out, true)
    
    print("File created: ".. filename)
end

return plugin