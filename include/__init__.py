from . import SMBLevelExtract

def __exportToLua(lua, module, n=None):
    if n is None:
        n = module.__name__
    lua_func = lua.eval('function(o) {0} = o return o end'.format(n))
    lua_func(module)

def init(lua):
    # export the LevelExtract method to lua as SMBLevelExtract
    __exportToLua(lua, SMBLevelExtract.LevelExtract, "SMBLevelExtract")
