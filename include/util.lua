local util = {}

-- Remove all spaces from a string
util.stripSpaces = function(s)
    return string.gsub(s, "%s", "")
end

util.pythonEval = function(s)
    out =    "try:\n"
    out=out.."  "..s.."\n"
    out=out.."except LuaError as err:\n"
    out=out.."  handleLuaError(err)\n"
    out=out.."except Exception as err:\n"
    out=out.."  handlePythonError(err)\n"
    return python.eval(s)
end

util.serializeHelper = function(data)
    local f = util.pythonEval("lambda x:'base64pickle:'+ binascii.b2a_base64(x.dumps(), newline=False).decode()")
    return f(data)
end

util.serialize = function(t)
    if not t then return end
    return Tserial.pack(t, util.serializeHelper)
end

util.unpickleAll = function(t)
    local startsWith = util.pythonEval("lambda x,y: x.startswith(y)")
    --local unpickle = util.pythonEval("lambda x: pickle.loads(binascii.a2b_base64(x.split('base64pickle:')[1]))")
    -- no idea why the imports disappear but this is a hacky fix.
    local unpickle = util.pythonEval("lambda x: __import__('pickle').loads(__import__('binascii').a2b_base64(x.split('base64pickle:')[1]))")

    for k,v in pairs(t) do
        if type(v) == "string" and startsWith(v,'base64pickle:') then
            t[k]=unpickle(t[k])
        elseif type(v) == "table" then
            util.unpickleAll(t[k])
        end
    end
end

util.unserialize = function(s)
    if not s then return end
    local ret = Tserial.unpack(s)
    
    util.unpickleAll(ret)
    
    return ret
end

function util.writeToFile(file,address, data, wipe)
    if wipe==true or (not util.fileExists(file)) then
        local f=io.open(file,"w")
        if not f then return nil end
        f:close()
    end
    if not data then return nil end
    
    if type(data) == "table" then
        newData = ''
        for i=1,#data do
            newData = newData..string.char(data[i])
        end
        data = newData
    end
    
    local f = io.open(file,"r+b")
    if not f then return nil end
    f:seek("set",address)
    f:write(data)
    f:close()
    return true
end

function util.getFileContents(path)
    local file = io.open(path,"rb")
    if file==nil then return nil end
    io.input(file)
    local ret=io.read("*a")
    io.close(file)
    return ret
end

function util.fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function util.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[util.deepCopy(orig_key)] = util.deepCopy(orig_value)
        end
        setmetatable(copy, util.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function util.bin2hex(str)
    local output = ""
    for i = 1, #str do
        local c = string.byte(str:sub(i,i))
        output=output..string.format("%02x", c)
    end
    return output
end

function util.hex2bin(str)
    str = util.stripSpaces(str)
    
    local output = ""
    for i = 1, (#str/2) do
        local c = str:sub(i*2-1,i*2)
        
        -- Not a hex digit, return nil
        if not tonumber(c, 16) then return end
        
        output=output..string.char(tonumber(c, 16))
    end
    return output
end

function util.hexToTable(str)
    str = util.stripSpaces(str)
    
    local output = {}
    for i = 1, (#str/2) do
        local c = str:sub(i*2-1,i*2)
        
        -- Not a hex digit, return nil
        if not tonumber(c, 16) then return end
        
        table.insert(output, tonumber(c, 16))
    end
    return output
end

function util.tableToHex(t)
    local output = ""
    for _,v in pairs(t) do
        output=output..string.format("%02x", v)
    end
    return output
end


function util.ipairs_sparse(t)
    local tmpIndex = {}
    local index, _ = next(t)
    while index do
        if type(index) == 'number' then
            -- skip non-numerical indexes
            tmpIndex[#tmpIndex+1] = index
        end
        index, _ = next(t, index)
    end

    table.sort(tmpIndex)
    local j = 1

    return function()
        local i = tmpIndex[j]
        j = j + 1
        if i then return i, t[i] end
    end
end

-- Zero-based, works on sparse
function util.maxTableIndex(t)
    local index = 0
    local i
    index = next(t)
    while index do
        if type(index) == "number" then
            i = index
        end
        index = next(t, index)
    end
    return i
end

-- Zero based
function util.tableAppendSparse(t, item)
    t[(util.maxTableIndex(t) or -1)+1] = item
    return t
end

return util