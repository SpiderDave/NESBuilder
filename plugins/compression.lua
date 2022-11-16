-- NESBuilder plugin
-- compression.lua

local plugin = {
    author = "SpiderDave",
    name = "compression",
    default = true,
}

function plugin.onInit()
    -- Create table for compression methods and
    -- import appropriate functions.
    plugin.compression = {
        ["Konami RLE"] = {
            name = "Konami RLE",
            compress = NESBuilder:importFunction('plugins.compression','compressKonamiRLE'),
            decompress = NESBuilder:importFunction('plugins.compression','decompressKonamiRLE'),
        },
        ["Kemko RLE"] = {
            name = "Kemko RLE",
            compress = NESBuilder:importFunction('plugins.compression','compressKemkoRLE'),
            decompress = NESBuilder:importFunction('plugins.compression','decompressKemkoRLE'),
        },
        ["Natsume"] = {
            name = "Natsume",
            decompress = NESBuilder:importFunction('plugins.compression','decompressNatsume'),
        },
        ["SMB"] = {
            name = "SMB",
            decompress = NESBuilder:importFunction('plugins.compression','decompressSMB'),
        },
    }
end


function plugin.onRegisterCompression()
    -- Register compression methods
    for k, v in pairs(plugin.compression) do
        data.compression[k] = v
    end
end


function plugin.compress(method, arg)
    arg = arg or {}
    for k, v in pairs(plugin.compression) do
        if method == k then
            if not v.compress then return end
            printf("compress %s", method)
            return v.compress(toDict(arg))
        end
    end
end

function plugin.decompress(method, arg)
    arg = arg or {}
    for k, v in pairs(plugin.compression) do
        if method == k then
            if not v.decompress then return end
            printf("decompress %s", method)
            return v.decompress(toDict(arg))
        end
    end
end


return plugin