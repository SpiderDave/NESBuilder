from . import SMBLevelExtract
from . import calc
from . import config
#from .ips import ips

__all__ = [
            'SMBLevelExtract',
            'Calculator',
            'Cfg',
#            'ips',
          ]

Calculator = calc.Calculator
Cfg = config.Cfg

def _exportToLua(lua, module, n=None):
    if n is None:
        n = module.__name__
    lua_func = lua.eval('function(o) {0} = o return o end'.format(n))
    lua_func(module)

def init(lua):
    # export the LevelExtract method to lua as SMBLevelExtract
    _exportToLua(lua, SMBLevelExtract.LevelExtract, "SMBLevelExtract")
