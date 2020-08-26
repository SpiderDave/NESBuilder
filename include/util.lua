local util = {}

-- Remove all spaces from a string
util.stripSpaces = function(s)
    return string.gsub(s, "%s", "")
end


util.serialize = function(t)
    if not t then return end
    return Tserial.pack(t)
end
util.unserialize = function(s)
    if not s then return end
    return Tserial.unpack(s)
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


return util