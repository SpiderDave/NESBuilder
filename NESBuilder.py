# needs lupa, PyInstaller, Pillow, PyQt5, numpy
'''
ToDo:
    * make return value of control generating methods more consistant
    * makeCanvas method
    * clean up color variable names, add more
    * phase out controls and use controlsNew, then rename controlsNew
    * per-project plugins
'''

import os, sys, time
frozen = (getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'))

# if the first argument is -asm, run sdasm with 
# everything after it as arguments.
if len(sys.argv) > 1 and sys.argv[1].lower() == '-asm':
    if frozen:
        logFile = open('log.txt', 'w')
        sys.stdout = logFile
        sys.stderr = logFile

    print('running sdasm\n')
    # sdasm will detect this rewritten sys.argv[0]
    sys.argv = ['NESBuilder:asm'] + sys.argv[2:]
    from include import sdasm
    sys.exit()

# From here we'll use argparse
import argparse
parser = argparse.ArgumentParser(description='NESBuilder')
parser.add_argument('mainfile', nargs='?', type=str,
                    help='use external main file')
parser.add_argument('-asm', action='store_true',
                    help='Assemble file with sdasm and exit')
cmdArgs = parser.parse_args()

if cmdArgs.asm:
    print('Error: -asm must be the first argument.  Everything after it will be passed as arguments to sdasm.')
    sys.exit()

import pathlib
from glob import glob
import pathlib

def badImport(m):
    print('Error: Could not import {0}.  Please run "install dependencies.bat".'.format(m))
    sys.exit(1)


import pickle as pickle2

try: import lupa
except: badImport('lupa')
from lupa import LuaRuntime
from lupa import LuaError
lua = LuaRuntime(unpack_returned_tuples=True)

try: import PyQt5
except: badImport('PyQt5')

try:
    import PyQt5.QtWidgets
except Exception as e:
    print('Error: Could not import {0}.'.format('PyQt5.QtWidgets'))
    print('***', str(e))
    sys.exit(1)

try: from PIL import ImageTk, Image, ImageDraw,ImageOps
except: badImport('Pillow')
from collections import deque
import re

import random
from random import randrange

import time

def dummyDecoratorFactory(message=None, *arg, **kwarg):
    def decorator(func):
        def wrapped_func(*args, **kwargs):
            return func(*args, **kwargs)
        return wrapped_func
    return decorator

try:
    # This is probably pointless as it will only work on
    # Linux.  Need to replace it and leave the fallback in.
    
    #from timeout_decorator import timeout
    from func_timeout import func_timeout, FunctionTimedOut, func_set_timeout
    
    @func_set_timeout(1)
    def f():
        pass
    f()
except:
    timeout = dummyDecoratorFactory

timeout = dummyDecoratorFactory

#@timeout(3)
#def mytest():
#    print("Start")
#    for i in range(5):
#        time.sleep(1)
#        print(i)

#mytest()

from io import BytesIO

import string
import textwrap

try: import numpy as np
except: badImport('numpy')

#import pickle

import shutil
from shutil import copyfile, copy2

import subprocess
import traceback

from tempfile import NamedTemporaryFile

import math
import webbrowser

import binascii
from binascii import hexlify, unhexlify

import importlib, pkgutil
from zipfile import ZipFile

# import our include folder
import include 

# This helps make things work in the frozen version
# All that python imports here is an empty init file.
try:    import icons
except: pass
try:    import cursors
except: pass

# import with convenient names
from include import *

script_path = os.path.dirname(os.path.abspath( __file__ ))
initialFolder = os.getcwd()

def pathToFolder(p):
    return fixPath2(os.path.split(p)[0])

def fixPath2(p):
    if ":" not in p:
        p = script_path+"/"+p
    return p.replace("/",os.sep).replace('\\',os.sep)
    
def fixPath(p):
    return p.replace("/",os.sep).replace('\\',os.sep)

# create our config parser
cfg = Cfg(filename=fixPath2("NESBuilder.ini"))

# read config file if it exists
cfg.load()

cfg.setDefault('main', 'project', "newProject")
cfg.setDefault('main', 'upperhex', 0)
cfg.setDefault('main', 'alphawarning', 1)
cfg.setDefault('main', 'loadplugins', 1)
cfg.setDefault('main', 'breakonpythonerrors', 0)
cfg.setDefault('main', 'breakonluaerrors', 0)
cfg.setDefault('main', 'autosave', 1)
cfg.setDefault('main', 'autosaveinterval', 1000 * 60 * 5) # 5 minutes
cfg.setDefault('main', 'dev', 0)
cfg.setDefault('main', 'oldbuild', 0)
cfg.setDefault('plugins', 'debug', 0)
cfg.setDefault('main', 'defaultpalettefile', 'default.pal')
cfg.setDefault('main', 'defaultpalettefolder', 'palettes')

cfg.setDefault('main', 'QT_AUTO_SCREEN_SCALE_FACTOR', 1)
cfg.setDefault('main', 'QT_SCREEN_SCALE_FACTORS', 1)
cfg.setDefault('main', 'QT_SCALE_FACTOR', 1)

os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = str(cfg.getValue("main","QT_AUTO_SCREEN_SCALE_FACTOR"))
os.environ["QT_SCREEN_SCALE_FACTORS"] = str(cfg.getValue("main","QT_SCREEN_SCALE_FACTORS"))
os.environ["QT_SCALE_FACTOR"] = str(cfg.getValue("main","QT_SCALE_FACTOR"))

app = QtDave.App()
main = QtDave.MainWindow()

import configparser, atexit

# Handle exporting some stuff from python scripts to lua
include.init(lua)

true, false = True, False

application_path = False
if frozen:
    application_path = sys._MEIPASS
else:
    application_path = os.path.dirname(os.path.abspath(__file__))

# make cfg available to lua
lua_func = lua.eval('function(o) {0} = o return o end'.format('cfg'))
lua_func(cfg)

controls={}
controlsNew={}

controlsNew.update({"main":main})

# have to manually define hotspots
cursorData = dict(
    pencil=dict(hotspot=[0,31]),
    crosshair=dict(hotspot=[15,12]),
)
for k,v in cursorData.items():
    if v:
        cursorName = "cursors\\"+k
        folder, file = os.path.split(cursorName)
        d = os.path.dirname(sys.modules[folder].__file__)
        cursorData[k].update(filename = os.path.join(d, file))

QtDave.loadCursors(cursorData)

# getKeyPress function (renamed from getChar)
#    https://stackoverflow.com/questions/510357/how-to-read-a-single-character-from-the-user
def getKeyPress():
    # figure out which function to use once, and store it in _func
    if "_func" not in getKeyPress.__dict__:
        try:
            # for Windows-based systems
            import msvcrt # If successful, we are on Windows
            getKeyPress._func=msvcrt.getch

        except ImportError:
            # for POSIX-based systems (with termios & tty support)
            import tty, sys, termios # raises ImportError if unsupported

            def _ttyRead():
                fd = sys.stdin.fileno()
                oldSettings = termios.tcgetattr(fd)

                try:
                    tty.setcbreak(fd)
                    answer = sys.stdin.read(1)
                finally:
                    termios.tcsetattr(fd, termios.TCSADRAIN, oldSettings)

                return answer

            getKeyPress._func=_ttyRead

    return getKeyPress._func()

def fancy(text):
    return "*"*60+"\n"+text+"\n"+"*"*60

def depreciated(func):
    def wrapper(*args, **kwargs):
        plugin = lua.eval("_getPlugin and _getPlugin().name or 'main'")
        print('(Plugin {}): Depreciated function {}()'.format(plugin, func.__name__))
        func(*args, **kwargs)
    return wrapper

def depreciated2(func, alternate):
    plugin = lua.eval("_getPlugin and _getPlugin().name or 'main'")
    print('(Plugin {}): Depreciated function {}()'.format(plugin, func.__name__), end='')
    if alternate:
        print(f' Use {alternate} instead.')
    else:
        print()


class Stack(deque):
    def push(self, *args):
        for arg in args:
            self.append(arg)
    def pop(self, n=0):
        if n > 0:
            ret = []
            for i in range(n):
                ret.append(super().pop())
            return tuple(ret)
        else:
            return super().pop()
    def remove(self,value):
        try:
            super().remove(value)
            return True
        except:
            return False
    def asList(self):
        return list(self)

# Make stuff in this class available to lua
# so we can do Python stuff rom lua.
class ForLua:
    x=0
    y=0
    w=16
    h=16
    direction="v"
    window="Main"
    canvas=False
    images={}
    images2=[]
    config = cfg
    anonCounter = 1
    loading = 0
    windowQt = main
    tabQt = main
    Qt = True
    
    RNG = RNG
    
    palette = QtDave.nesPalette
    
    def QtWrapper(func):
        def inner(self, t=None):
            return t
        return inner
    
    # decorator
    def makeControl(func):
        def addStandardProp(t):
            def _config(cfg):
                t.control.config(dict(cfg))
            def update():
                t.control.update()
                t.height = t.control.winfo_height()
                t.width = t.control.winfo_width()
            t.config = _config
            t.update = update
            t.plugin = lua.eval("_getPlugin and _getPlugin() or false")
            return t
        def inner(self, t=None):
            # This is some patchwork stuff for methods
            # that lack the self argument
            if self!=ForLua:
                t=self
                self=ForLua
                #print("Warning: created {0} without : syntax.".format(t.name))
            
            # This is used in makeWindow to avoid
            # creating the same window over and over.
            if t.alreadyCreated: return t
            
            if self.direction.lower() in ("v","vertical"):
                x=coalesce(t.x, self.x, 0)
                y=coalesce(t.y, self.y+self.h, 0)
            else:
                x=coalesce(t.x, self.x+self.w, 0)
                y=coalesce(t.y, self.y, 0)
            w=coalesce(t.w, self.w, 16)
            h=coalesce(t.h, self.h, 16)
            self.x=x
            self.y=y
            self.w=w
            self.h=h
            
            index = t.index
            
            anonymous = False
            if not t.name:
                anonymous = True
            
            t = func(self, t, (x,y,w,h))
            t = addStandardProp(t)
            if t.control:
                t.control.update()
                t.height=t.control.winfo_height()
                t.width=t.control.winfo_width()
            
            t.index = index
            
            if not t.name:
                t.name = "anonymous{0}".format(self.anonCounter)
                self.anonCounter = self.anonCounter + 1
                t.anonymous=True

            return t
        return inner
    def decorate(self):
        decorator = lupa.unpacks_lua_table_method
        for method_name in dir(self):
            m = getattr(self, method_name)
            if m.__class__.__name__ == 'function':
                # these are control creation functions
                # makedir
                makers = ['makeCanvas', 'makeEntry', 'makeLabel', "makeTree",
                          'makeMenu', 'makePaletteControl',
                          'makeText', 'makeWindow', 'makeSpinBox',
                          ]
                QtWidgets = ['makeButton', 'makeButtonQt', 'makeLabelQt', 'makeTabQt', 'makeTab', 'makeCanvasQt', 'makeSideSpin', 'makeCheckbox', 'makeLink', 'makeTextEdit', 'makeConsole', 'makeList']
                
                if method_name in makers:
                    attr = getattr(self, method_name)
                    wrapped = self.makeControl(attr)
                    setattr(self, method_name, wrapped)
                elif method_name in QtWidgets:
                    attr = getattr(self, method_name)
                    wrapped = self.QtWrapper(attr)
                    setattr(self, method_name, wrapped)
                elif method_name in ['getNESColors', 'makeControl', 'getLen', 'makeMenuQt','makeNESPixmap','listToTable','tableToList','print','type', 'executeLuaFile', 'getPrintable', '_getPrintable']:
                    # getNESColors: excluded because it may have a table as its first parameter
                    # makeControl: excluded because it's a decorator
                    pass
                elif method_name in ['cfgNew']:
                    pass
                
                else:
                    #print(method_name, m.__class__)
                    if method_name.startswith('make') and method_name not in ['makeDir', 'makeIps', 'makeData']:
                        print("possible function to exclude from decorator: ", method_name, m.__class__)
                    attr = getattr(self, method_name)
                    wrapped = decorator(attr)
                    setattr(self, method_name, wrapped)
    # can't figure out item access from lua with cfg,
    # so we'll define some methods here too.
    def cfgLoad(self, filename = "NESBuilder.ini"):
        return cfg.load(filename)
    def cfgSave(self):
        return cfg.save()
    def cfgMakeSections(self, *sections):
        return cfg.makeSections(*sections)
    def cfgGetValue(self, section, key, default=None, hint=None):
        return cfg.getValue(section, key, default, hint=hint)
    def cfgSetValue(self, section, key, value):
        return cfg.setValue(section, key, value)
    def cfgSetDefault(self, section,key,value):
        return cfg.setDefault(section,key,value)
    def repr(self, item):
        return repr(item)
    def type(self, item):
        if type(item) == None: return "None"
        if type(item) == bool: return "boolean"
        if type(item) == float: return "number"
        if type(item) == int: return "number"
        if type(item) == str: return "string"
        
        if lupa.lua_type(item):
            return lupa.lua_type(item)
        return item.__class__.__name__
    def getInt(self, n):
        try:
            return int(n)
        except:
            return 0
    def calc(self, s):
        @func_set_timeout(2)
        def calcWrap(s):
            calc = Calculator()
            return calc(s)
        try:
            return calcWrap(s)
        except FunctionTimedOut:
            return 0
    def getPrintable(self, *args):
        ret = ''
        for arg in args:
            ret = ret + self._getPrintable(self, arg)
        return ret
    def _getPrintable(self, item, indent=0, *args, **kwargs):
        limit=5
        #indent=0
        if type(item) == np.ndarray:
            return('{}{}'.format(" "*indent, item))
        elif (item==None) or (type(item) == bool):
            return('{}{}'.format(" "*indent, item))
        elif lupa.lua_type(item) == "None":
            return('{}{}'.format(" "*indent, item))
        elif (type(item)==str) or (lupa.lua_type(item) == "string"):
            
            # This should be changed to make everything printable too
            if args:
                item = item.format(*args)
            
            return('{}{}'.format(" "*indent, item))
        elif lupa.lua_type(item) == "function":
            return('{}()'.format(" "*indent))
        elif lupa.lua_type(item) == "table":
            ret = '{\n'
            #l = len(list(item))
            n=0
            for i, (k,v) in enumerate(item.items()):
                if n>=limit:
                    ret+='{}...\n'.format(" "*(indent+2))
                    break
                if type(k) != str:
                    k = '[{}]'.format(k)
                    n=n+1
                if lupa.lua_type(v)=="function":
                    # Dont need to show a value for functions
                    ret+='{}{}(),\n'.format(" "*(indent+2), k)
                elif type(v)==str:
                    ret+='{}{} = {},\n'.format(" "*(indent+2), k, repr(v))
                else:
                    ret+='{}{} = {},\n'.format(" "*(indent+2), k, self._getPrintable(self, v, indent=indent+2).lstrip())
            ret+= '{}}}'.format(" "*(indent))
            return ret
        else:
            if str(item).startswith('<include.QtDave.'):
                return('{}<{}>'.format(" "*indent, item.__class__.__name__))
            return('{}{}'.format(" "*indent, item))
        return

    def print(self, item='', *args, indent=0,limit=5, returnString=False):
        def getPrintable(item, indent=0):
            if type(item) == np.ndarray:
                return('{}{}'.format(" "*indent, item))
            elif (item==None) or (type(item) == bool):
                return('{}{}'.format(" "*indent, item))
            elif lupa.lua_type(item) == "None":
                return('{}{}'.format(" "*indent, item))
            elif (type(item)==str) or (lupa.lua_type(item) == "string"):
                
                # This should be changed to make everything printable too
                if args:
                    item = item.format(*args)
                
                return('{}{}'.format(" "*indent, item))
            elif lupa.lua_type(item) == "function":
                return('{}()'.format(" "*indent))
            elif lupa.lua_type(item) == "table":
                ret = '{\n'
                #l = len(list(item))
                n=0
                for i, (k,v) in enumerate(item.items()):
                    if n>=limit:
                        ret+='{}...\n'.format(" "*(indent+2))
                        break
                    if type(k) != str:
                        k = '[{}]'.format(k)
                        n=n+1
                    if lupa.lua_type(v)=="function":
                        # Dont need to show a value for functions
                        ret+='{}{}(),\n'.format(" "*(indent+2), k)
                    elif type(v)==str:
                        ret+='{}{} = {},\n'.format(" "*(indent+2), k, repr(v))
                    else:
                        ret+='{}{} = {},\n'.format(" "*(indent+2), k, getPrintable(v, indent+2).lstrip())
                ret+= '{}}}'.format(" "*(indent))
                return ret
            else:
                if str(item).startswith('<include.QtDave.'):
                    return('{}<{}>'.format(" "*indent, item.__class__.__name__))
                return('{}{}'.format(" "*indent, item))
            return
        if returnString:
            return getPrintable(item)
        print(getPrintable(item))
    def printNoPrefix(self, item):
        if repr(item).startswith("<"):
            print(repr(item))
        else:
            print(item)
    def files(self, pattern=False):
        if not pattern:
            pattern = fixPath2('')+'*'
        return glob(pattern)
    def findFile(self, filename, folderList=[]):
        # Search for files in this order:
        #   Exact match
        #   Relative to folders in folderList
        #   Relative to current working folder
        #   Relative to folders in folderList one level up
        
        if not filename:
            return None
        
        files = [
            filename,
        ]
        
        folderList = [x for x in folderList if x]
        
        for folder in folderList:
            files.append(os.path.join(folder, filename))
        files.append(os.path.join(os.getcwd(),filename))
        for folder in folderList:
            files.append(os.path.join(str(pathlib.Path(*pathlib.Path(folder).parts[:1])),filename))
        
        for f in files:
            if os.path.isfile(f):
                return os.path.abspath(f)
                
        return None
    def getKeyPress(self):
        return getKeyPress()
    def getFileSize(self, f):
        f = fixPath2(f)
        return os.path.getsize(f)
    def fileExists(self, f):
        #f = fixPath(script_path+"/"+f)
        f = fixPath2(f)
        return os.path.isfile(f)
    def pathToFolder(self, path):
        return pathToFolder(path)
    def pathExists(self, f):
        f = fixPath(script_path+"/"+f)
        return os.path.exists(f)
    def setWorkingFolder(self, f=""):
        workingFolder = fixPath2(f)
        os.chdir(workingFolder)
    def getWorkingFolder(self):
        return os.getcwd()
    def getDataFromArchive(self, zipFilename, filename):
        zip=ZipFile(zipFilename)
        if filename in zip.namelist():
            return zip.read(filename)
    def getTextFromArchive(self, zipFilename, filename):
        zip=ZipFile(zipFilename)
        if filename in zip.namelist():
            return zip.read(filename).decode()
    def extractAll(self, file, folder, exclude=False):
        file = fixPath2(file)
        #if self.fileExists(self, file):
        if True:
            folder = fixPath2(folder)
            print(file, folder)
            with ZipFile(file, mode='r') as zip:
                #zip.extractall(folder)
                members = zip.namelist()
                if exclude:
                    members = [x for x in members if x not in list(exclude)]
                for z in members:
                    zip.extract(z, folder)
            return True
        else:
            print("File does not exist: {}".format(file))
            return False
    def sleep(self, t):
        time.sleep(t)
    def rename(self, filename, newFilename):
        filename = fixPath2(filename)
        newFilename = fixPath2(newFilename)
        
        print(filename)
        print(newFilename)
        print(os.path.exists(filename))
        print(os.path.exists(newFilename))
        
        if os.path.exists(filename) and os.path.exists(newFilename)==False:
            os.rename(filename, newFilename)
            print("Rename "+filename + " --> "+newFilename)
    def delete(self, filename):
        #filename = fixPath(script_path+"/"+filename)
        filename = fixPath2(filename)
        try:
            if os.path.exists(filename):
                os.remove(filename)
            else:
                print(filename + " does not exist.")
            return True
        except:
            print("Could not delete "+filename)
            return False
    def noise(self, *args):
        
        n = opensimplex.OpenSimplex()
        
        if len(args) == 2:
            return n.noise2d(*args)
        elif len(args) == 3:
            return n.noise3d(*args)
        elif len(args) == 4:
            return n.noise4d(*args)
        else:
            return False
    def run(self, workingFolder, cmd, args, input=None, capture=False):
        try:
            if input:
                input = bytes(input, 'utf-8')
            cmd = fixPath(script_path+"/"+cmd)
            #workingFolder = fixPath(script_path+"/"+workingFolder)
            workingFolder = fixPath2(workingFolder)
            os.chdir(workingFolder)
            p = subprocess.run([cmd]+ args.split(), capture_output=capture, input=input)
            if capture:
                return '\n'.join(p.stdout.decode().splitlines())
            print()
            return True
        except:
            print("could not run " + cmd)
            return False
    def shellOpen(self, workingFolder, cmd):
        cmd = fixPath2(cmd)
        workingFolder = pathToFolder(workingFolder)
        try:
            os.chdir(workingFolder)
            os.startfile(cmd, 'open')
            return True
        except:
            print("could not open " + cmd)
            return False
    def numberToBitArray(self, n):
        return [int(x) for x in "{:08b}".format(n)]
    def bitArrayToNumber(self, l):
        return int("".join(str(x) for x in l), 2) 
    def showError(self, title="Error", text=""):
        d = QtDave.Dialog()
        d.showError(text)
    def showInfo(self, title="Info2", text=""):
        d = QtDave.Dialog()
        d.showInfo(text, title)
    def askText(self, title, text, defaultText=''):
        d = QtDave.Dialog()
        return d.askText(title, text, defaultText)
    def isAlphaNumeric(self, txt):
        return txt.isalnum()
    def regexMatch(self,reString, txt):
        if re.match(reString, txt):
            return True
        else:
            return None
    def askyesnocancel(self, title="NESBuilder", message=""):
        print("WARNING: deprecated; use askYesNoCancel instead of askyesnocancel.")
        m = QtDave.Dialog()
        return m.askYesNo(title, message)
    def askYesNoCancel(self, title="NESBuilder", message=""):
        m = QtDave.Dialog()
        return m.askYesNoCancel(title, message)
    def incLua(self, n):
        filedata = pkgutil.get_data( 'include', n+'.lua' )
        return lua.execute(filedata)
    def executeLuaFile(self, filename, folders=[]):
        try:
            f = self.findFile(self, filename, folders)
            file = open(f,"rb")
            lua.execute(file.read())
            file.close()
            #lua.execute('loadfile("{filename}")()')
        except LuaError as err:
            handleLuaError(err)
        except Exception as err:
            handlePythonError(err)
    def setDirection(self, d):
        self.direction=d
    def getWindow(self, window=None):
        return windows.get(coalesce(window, self.window))
    def setWindow(self, window):
        self.window=window
    def getWindowQt(self, name=None):
        # needs an upgrade to get only windows not controls
        if name:
            return controlsNew[name]
        return self.windowQt
    def getTabQt(self, name=None):
        # todo: add parameter to get tab by name
        return self.tabQt
    def setTab(self, tab):
        window = controls[self.window]
        window.tab = tab
        self.tab=tab
    def setContainer(self, widget=None):
        window = self.windowQt
        if widget == None:
            self.tabQt = window
            return
        self.tabQt = widget
    def setTabQt(self, tab=None):
        window = self.windowQt
        if tab == None:
            self.tabQt = window
            return
        self.tabQt = window.tabs.get(tab)
    def switchTab(self, tab):
        window = self.windowQt
        window.tabParent.setCurrentWidget(window.tabs.get(tab))
    def setWindowQt(self, window):
        if type(window)==str:
            window = controlsNew[window]
        
        self.windowQt=window
    def getCanvas(self, canvas=None):
        return controlsNew[coalesce(canvas, self.canvas)]
    def setCanvas(self, canvas):
        self.canvas = canvas
    def makeDir(self,dir):
        dir = fixPath(script_path + "/" + dir)
        print('makedir:',dir, end='')
        if not os.path.exists(dir):
            os.makedirs(dir)

        for _ in range(10):
            if os.path.exists(dir):
                break
            else:
                print('.',end='')
                time.sleep(0.05)
        else:
            print('\ntimeout.')
        print('')

    def openFolder(self, initial=None):
        initial = fixPath(script_path + "/" + initial)
        m = QtDave.Dialog()
        foldername =  m.openFolder(initial=initial)
        return foldername, os.path.split(foldername)[1]
    def openFile(self, filetypes, initial=None, parent=None):
        initial = fixPath(script_path + "/" + coalesce(initial,''))
        m = QtDave.Dialog()
        return coalesce(m.openFile(filetypes=filetypes, initial=initial), '')
    def saveFileAs(self, filetypes, initial=None):
        initial = fixPath(script_path + "/" + coalesce(initial,''))
        m = QtDave.Dialog()
        file, ext, filter = m.saveFile(filetypes=filetypes, initial=initial)
        file = coalesce(file, '')
        ext = coalesce(ext, '')
        return (file, ext, filter)
    def lift(self, window=None):
        window = self.getWindow(self, window)
        window.control.lift()
        window.control.focus_force()
    def importFunction(self, mod, f):
        m = importlib.import_module(mod)
        setattr(self, f, getattr(m, f))
        
        return getattr(m,f)
    def copyFolder(self, src, dst):
        src = fixPath2(src)
        dst = fixPath2(dst)
        
        def ignore(folder, contents):
            contents = [x for x in contents]
            print(folder, contents)
            return (folder, contents)
        
        #shutil.copytree(src, dst, symlinks=False, ignore=None, copy_function=copy2, ignore_dangling_symlinks=False)
        shutil.copytree(src, dst, symlinks=False, ignore=ignore, copy_function=copy2, ignore_dangling_symlinks=False, dirs_exist_ok=True)
    def copyFile(self, src,dst):
        print('copyfile:\n  {} -->\n  {}\n'.format(src, dst))
        copyfile(src,dst)
    def canvasPaint(self, x,y, c):
        canvas = self.getCanvas(self)
        c = "#{0:02x}{1:02x}{2:02x}".format(self.palette.get()[c][0],self.palette.get()[c][1],self.palette.get()[c][2])
        canvas.control.create_rectangle(x*canvas.scale, y*canvas.scale, x*canvas.scale+canvas.scale-1, y*canvas.scale+canvas.scale-1,
                           width=1, outline=c, fill=c,
                           )
    def newStack(self, arg=[], maxlen=None):
        stack = Stack(arg, maxlen)
        t = lua.table(
                        stack=stack,
                        push=stack.push,
                        pop=stack.pop,
                        remove=stack.remove,
                        asList=stack.asList,
                     )
        return t, stack.push, stack.pop
    def getNESmakerColors(self):
        return [
            [0,0,0],
            [0,255,0],
            [255,0,0],
            [0,0,255],
            ]
    def getNESColors(self, c):
        if type(c) is str:
            c=c.replace(' ','').strip()
            c = [self.palette.get()[x] for x in unhexlify(c)]
            if len(c) == 1:
                return c[0]
            return c
        else:
            c = [self.palette.get()[v] for i,v in sorted(c.items())]
            if len(c) == 1:
                return c[0]
            return c
    def getAttribute(self, attrTable, tileX,tileY):
        attrIndex = math.floor(tileY / 4) * 8 + math.floor(tileX / 4)
        return math.floor(attrTable[attrIndex]/(2**(((math.floor(tileY/2) % 2)*2 + math.floor(tileX/2) % 2)*2))) % 4
        #return (attrTable[attrIndex]>>(tileY%2*2+tileX)*2)%4
    def setAttribute(self, attrTable, tileX,tileY, pal):
        
        attrIndex = math.floor(tileY / 4) * 8 + math.floor(tileX / 4)
        
        b=lambda x:"{0:08b}".format(x)
        before = attrTable[attrIndex]
        #attrTable[attrIndex] = attrTable[attrIndex] & 0xff^(3<<(tileY%2*2+tileX%2)*2) | pal<<(tileY%2*2+tileX%2)*2
        
        masks = [0b11111100, 0b11110011, 0b11001111, 0b00111111]
        mTileMap = [0,1,2,3]
        
        
        
        attr = attrTable[attrIndex]
        i = math.floor(tileY/2)%2*2+math.floor(tileX/2)%2
        
        attr = (attr & masks[i]) | (pal<<mTileMap[i]*2)
        
        attrTable[attrIndex] = attr
        after = attr
        
        #print(' tilexy=({},{}) attrIndex={} i={} pal={} {}-->{}'.format(attrTable[0], tileX,tileY, attrIndex,i, pal,b(before),b(after)))
        
        return attrIndex, attrTable[attrIndex]
    def imageToCHR(self, f, outputfile="output.chr", colors=False):
        print('imageToCHR')
        data = self.imageToCHRData(self, f, colors)
        
        print('Tile data written to {0}.'.format(outputfile))
        f=open(outputfile,"wb")
        f.write(bytes(data))
        f.close()
    def getLen(self, item):
        # todo: make work for lua stuff
        if type(item) == np.ndarray:
            return item.size

        if not item:
            return 0
        return len(item)
    def npTest(self):
        size = 0x1000
        #size = 10
        dType = [
            ('name', 'U30'),
            ('data', ('B',size)),
        ]

        data = np.array(
            [('Test', np.zeros((1,size))), ('Test2', np.ones((1,size)))],
            dtype=dType
            )
        return data
    def tableToList(self, t,base=1):
        if t.__class__.__name__ == '_LuaTable':
            ret = [t[x] for x in list(t)]
            if base==1:
                ret = [None]+ret
                ret = np.array(ret)
            return ret
        else:
            return t
    def hexToList(self, s, base=1):
        return list(bytearray.fromhex(s))
    def listToTable(self, l, base=1):
        if lupa.lua_type(l)=='table': return l
        
        if type(l) == np.ndarray:
            # This is here because the comparison to None will fail
            # with np arrays with more than one element.
            pass
        elif l==None:
            return l
        
        if type(l) is int: return None
        
        if base==0:
            t = lua.table()
            for i, item in enumerate(l):
                t[i] = item
            return t
        
        return lua.table_from(l)
    def imageToCHRData(self, f, colors=False):
        print('imageToCHRData')
        
        # convert and re-index lua table
        if lupa.lua_type(colors)=="table":
            colors = [colors[x] for x in colors]
        
        try:
            with Image.open(f) as im:
                px = im.load()
        except:
            print("error loading image")
            return
        
        width, height = im.size
        
        w = math.floor(width/8)*8
        h = math.floor(height/8)*8
        nTiles = int(w/8 * h/8)
        
        out = []
        for t in range(nTiles):
            tile = [[]]*16
            for y in range(8):
                tile[y] = 0
                tile[y+8] = 0
                for x in range(8):
                    for i in range(4):
                        if list(px[x+(t*8) % w, y + math.floor(t/(w/8))*8]) == colors[i]:
                            tile[y] += (2**(7-x)) * (i%2)
                            tile[y+8] += (2**(7-x)) * (math.floor(i/2))
            
            for i in range(16):
                out.append(tile[i])
        
        ret = lua.table_from(out)
        
        return ret
    def _try(self, f):
        try:
            return f()
        except:
            return None
    def applyIps(self, ipsData, fileData):
        return ips.applyIps(ipsData, fileData)
    def screenshotTest(self):
        main.screenshot(main)
    def updateApp(self):
        app.processEvents()
    def getFileData(self, f=None):
        file=open(f,"rb")
        #file.seek(0x1000)
        fileData = file.read()
        file.close()
        return list(fileData)
    def getFileAsArray(self, f):
        f = fixPath2(f)
        return np.fromfile(f, dtype='B')
    def _getFileAsArray(self, f):
        file=open(f,"rb")
        fileData = file.read()
        file.close()
        fileData = list(fileData)
        return fileData
    def saveArrayToFile(self, f, fileData):
        fileData = self.tableToList(self, fileData, base=0)
        f = fixPath2(f)
        file=open(f,"wb")
        
        if type(fileData) == np.ndarray:
            file.write(bytes(list(fileData)))
        else:
            file.write(bytes(fileData))
        file.close()
        return True
    def writeToFile(self, f, fileData):
        if not fileData or fileData==True:
            print('Nothing to write.')
            return False
#        if type(fileData) == np.ndarray:
#            fileData = list(fileData)
        
        f = fixPath2(f)
        file=open(f,"w")
        file.write(fileData)
        file.close()
        return True
    def parseTemplateData(self, data, section=False, key=False):
        if not data:
            return
        d = dict(main=dict(itemList=[],itemDict={}))
        s = 'main'
        for line in data.splitlines():
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                # create section if it doesn't exist
                s = line.split('[',1)[1].split(']',1)[0].strip().lower()
                d.update({s:d.get(s, dict(itemList=[],itemDict={}))})
            elif line and not line.startswith((';','#','//')):
                i = min((line+'= ').find('='), (line+'= ').find(' '))
                if i == line.find('='):
                    d.get(s).get('itemDict').update({line[:i]:line[i+1:]})
                else:
                    d.get(s).get('itemList').append([line[:i], line[i+1:]])
        if section or key:
            if key=='list' or not key:
                return d.get(section, d.get('main')).get('itemList')
            elif key=='dict':
                return d.get(section, d.get('main')).get('itemDict')
            elif key:
                return d.get(section, d.get('main')).get('itemDict').get(key)
        else:
            return d
    def unHex(self, s):
        return unhexlify(str(s))
    def hexStringToList(self, s):
        return list(unhexlify(s))
    def makeData(self, data, indent=0, nItems=16):
        def chunker(seq, size):
            res = []
            for el in seq:
                res.append(el)
                if len(res) == size:
                    yield res
                    res = []
            if res:
                yield res

        # make sure it's a list, tuple, etc
        if type(data) in (int, str):
            data = [data]
        
        out=''
        for chunk in chunker(data, nItems):
            newData = []
            for i, item in enumerate(chunk):
                if type(item) is int:
                    newData.append('${0:02x}'.format(item))
                else:
                    newData.append(item)
            out+=' '*indent+db+' '+', '.join(newData)+"\n"
        return out
    def getFileContents(self, f, start=0):
        # returns a list
        file=open(f,"rb")
        file.seek(start)
        fileData = file.read()
        file.close()
        
        return list(fileData)
    def getTextFileContents(self, f):
        with open(f, "r") as file:
            text = file.read()
        return text
    def loadCHRFile(self, f='chr.chr', colors=(0x0f,0x21,0x11,0x01), start=0):
        file=open(f,"rb")
        file.seek(start)
        fileData = file.read()
        file.close()
        fileData = list(fileData)
        
        ret = self.loadCHRData(self,fileData,colors)
        return ret
#    def newCHRData(self, nTiles=16*16):
#        return lua.table_from("\x00" * (nTiles * 16))
    def newCHRData(self, columns=16,rows=16):
        imageData = lua.table()
        for i in range(0, 16*columns*rows):
            imageData[i+1] = 0
        return imageData
    def loadCHRData(self, fileData=False, colors=(0x0f,0x21,0x11,0x01), columns=16, rows=16, fromHexString=False):
        print('DEPRECIATED: loadCHRData')
        control = self.getCanvas(self)
        
        canvas = control.control
        
        if fromHexString:
            fileData = list(unhexlify(fileData))
        
        if not fileData:
            fileData = "\x00" * (16 * columns * rows)
        
        if type(fileData) is str:
            fileData = [ord(x) for x in fileData]
        elif lupa.lua_type(fileData)=="table":
            fileData = [fileData[x] for x in fileData]
        
        # convert and re-index lua table
        if lupa.lua_type(colors)=="table":
            colors = [colors[x] for x in colors]
        
        img=Image.new("RGB", size=(columns*8,rows*8))
        
        a = np.asarray(img).copy()
        
        for tile in range(math.floor(len(fileData)/16)):
            if tile >= (columns * rows):
                break
            for y in range(8):
                for x in range(8):
                    c=0
                    x1=(tile % columns)*8+(7-x)
                    y1=math.floor(tile/columns)*8+y
                    if (fileData[tile*16+y] & (1<<x)):
                        c=c+1
                    if (fileData[tile*16+y+8] & (1<<x)):
                        c=c+2
                    a[y1][x1] = self.palette.get()[colors[c]]
        
        img = Image.fromarray(a)
        
        #img = img.crop((0,0,50,50))
        
        ret = lua.table_from(fileData)
        
        photo = ImageTk.PhotoImage(ImageOps.scale(img, control.scale, resample=Image.NEAREST))
        
        canvas.chrImage = photo # keep a reference
        
        canvas.create_image(0,0, image=photo, state="normal", anchor=tk.NW)
        canvas.configure(highlightthickness=0, borderwidth=0)
        
        control.chrData = lua.table_from(fileData)
        
        return ret
    def exportCHRDataToImage(self, filename="export.png", fileData=False, colors=(0x0f,0x21,0x11,0x01)):
        colors=(0x0f,0x21,0x11,0x01)
        
        if not fileData:
            print('no filedata')
            fileData = "\x00" * 0x1000
        
        if type(fileData) is str:
            fileData = [ord(x) for x in fileData]
        elif lupa.lua_type(fileData)=="table":
            #fileData = [fileData[x] for x in fileData]
            fileData = list([fileData[x] for x in fileData])
            
        # convert and re-index lua table
        if lupa.lua_type(colors)=="table":
            colors = [colors[x] for x in colors]
        
        img=Image.new("RGB", size=(128,128))
        
        a = np.asarray(img).copy()
        
        for tile in range(256):
            for y in range(8):
                for x in range(8):
                    c=0
                    x1=tile%16*8+(7-x)
                    y1=math.floor(tile/16)*8+y
                    if (fileData[tile*16+y] & (1<<x)):
                        c=c+1
                    if (fileData[tile*16+y+8] & (1<<x)):
                        c=c+2
                    a[y1][x1] = self.palette.get()[colors[c]]
        
        img = Image.fromarray(a)
        img.save(filename)
    def Quit(self):
#        app.quit()
#        main.destroy()
        #onExit()
        print("Quit selected")
        main.close()
    def switch(self):
        if qt:
            app.quit()
            main.destroy()
        else:
            self.restart(self)
    def exec(self, s):
        exec(s)
#    def eval(s):
        # store the eval return value so we can pass return value to lua space.
#        exec('ForLua.execRet = {0}'.format(s))
#        return ForLua.execRet
    def embedTest(self):
        import subprocess
        import time
        import win32gui
        
        print('embed test')

        # create a process
        #exePath = "C:\\Windows\\system32\\calc.exe"
        exePath = r"J:\Games\Nes\fceux-2.2.3-win32\fceux.exe"
        subprocess.Popen(exePath)
        #hwnd = win32gui.FindWindowEx(0, 0, "CalcFrame", "Calculator")
        #hwnd = win32gui.FindWindowEx(0, 0, 0, "FCEUX 2.2.3-interim git9cd4b59cb3e02f911e9a96ba8f01fa0a95bc2f0c")
        hwnd = win32gui.FindWindow(0, "FCEUX 2.2.3-interim git9cd4b59cb3e02f911e9a96ba8f01fa0a95bc2f0c")
        #hwnd = win32gui.FindWindowEx(0, 0, "CalcFrame", None)
        #hwnd = win32gui.FindWindow(0, "Calculator")
        time.sleep(0.05)
        #time.sleep(0.15)
        #time.sleep(2)
        m = QtDave.QWidget()
        layout = QtDave.QVBoxLayout(m)
        #layout = main.layout()
        
        window = QtDave.QWindow.fromWinId(hwnd)
        window.setFlags(QtDave.Qt.FramelessWindowHint)
        #widget = QtDave.QWidget.createWindowContainer(window, controlsNew.get('testTab'))
        widget = QtDave.QWidget.createWindowContainer(window)
        #widget = QtDave.QWidget.createWindowContainer(window, main)
        #widget = main.createWindowContainer(window, main)
        #widget.show()
        #widget.resize(800,800)
        #main.addWidget(widget, 'test')
        #layout.addWidget(widget)
        #main.layout().addWidget(widget)
        #layout = QtDave.QVBoxLayout()
        #main.setCentralWidget(widget)
        layout.addWidget(widget)
        #widget.setLayout(layout)
        #main.setLayout(layout)
        m.show()
        
#        self.setGeometry(500, 500, 450, 400)
#        self.setWindowTitle('File dialog')
#        self.show()
    def getControlNew(self, n):
        if not n:
            return controlsNew
        else:
            if n in controlsNew:
                return controlsNew[n]
            elif "_"+n in controlsNew:
                return controlsNew["_"+n]
    def getControl(self, n):
        if not n:
            return controls
        else:
            if n in controls:
                return controls[n]
            elif "_"+n in controls:
                return controls["_"+n]
        return self.getControlNew(self, n)
    def removeControl(c):
        controls[c].destroy()
    def hideControl(c):
        x = controls[c].winfo_x()
        if x<0:
            x=x+1000
        else:
            x=x-1000
        controls[c].place(x=x)
    def makeNESPixmap(self, width=128,height=128):
        return QtDave.NESPixmap(width, height)
    @lupa.unpacks_lua_table
    def makeCanvasQt(self, t):
        t.scale = t.scale or 3
        t.w=t.w*t.scale
        t.h=t.h*t.scale
        
        ctrl = QtDave.Canvas(self.tabQt)
        ctrl.init(t)
        t.control = ctrl
        
        ctrl.onMouseMove = makeCmdNew(t)
        ctrl.onMousePress = makeCmdNew(t)
        ctrl.onMouseRelease = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    
    @lupa.unpacks_lua_table
    @depreciated
    def makeTabQt(self, t):
        return self.makeTab(self, t) 
    @lupa.unpacks_lua_table
    def makeTab(self, t):
        window = self.windowQt
        
        #if t.name in self.windowQt.tabs:
        if self.windowQt.tabs.get(t.name):
            print('Not creating tab "{}" (already exists).'.format(t.name))
            return self.getControlNew(self, t.name)
        
        
        
        ctrl = QtDave.Widget()
        ctrl.title = t.text
        ctrl.name = t.name
        window.tabParent.addTab(ctrl, t.text)
        
        ctrl.index = window.tabParent.indexOf(ctrl)
        
        window.repaint()
        ctrl.init(t)
        
        # hard code dummy tab to not appear in list
        if t.showInList == None:
            t.showInList = True
        
        if t.showInList:
            window.tabs.update({t.name:ctrl})
        
        ctrl.mousePressEvent = makeCmdNew(t)
        
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeButtonQt(self, t):
        depreciated2(self.makeButtonQt, 'makeButton()')
        return self.makeButton(self, t)
    @lupa.unpacks_lua_table
    def makeButton2(self, t):
        depreciated2(self.makeButton2, 'makeButton() using w * 7.5, h * 7.5')
        
        if t.w:
            t.w=t.w*7.5
        
        if t.h:
            t.h=t.h*7.5
        
        return self.makeButton(self, t)
    @lupa.unpacks_lua_table
    def makeTable(self, t):
        ctrl = QtDave.Table(self.tabQt)
        ctrl.init(t)
        
        ctrl.setRowCount(t.rows)
        ctrl.setColumnCount(t.columns)
        ctrl.verticalHeader().hide()
        
        t.control = ctrl
        #ctrl.onChange = makeCmdNoEvent(t)
        
        #ctrl.itemChanged.connect(makeCmdNew(t))
        ctrl.itemChanged.connect(ctrl._changed)
        
        #ctrl.currentItemChanged.connect(makeCmdNew(t))
        #ctrl.currentItemChanged.connect(ctrl._changed)
        
        #ctrl.clicked.connect(makeCmdNew(t))
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeSideSpin(self, t):
        ctrl = QtDave.SideSpin(self.tabQt)
        ctrl.init(t)
        
        #ctrl.onChange = lambda:print('test')
        t.control = ctrl
        ctrl.onChange = makeCmdNoEvent(t)
        
        #ctrl.clicked.connect(makeCmdNew(t))
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeButton(self, t):
        ctrl = QtDave.Button(t.text, self.tabQt)
        ctrl.init(t)
        
#        if t.image:
            #image = Image.open(t.image.replace(".png", "_white.png"))
            #t.image = t.image.replace(".png", "_white.png")
#            image = Image.open(t.image)
#            print(ctrl.setIcon(image))
        
        if t.image:
            folder, file = os.path.split(t.image)
            if sys.modules.get(folder):
                d = os.path.dirname(sys.modules[folder].__file__)
                filename = os.path.join(d, file)
                ctrl.setIcon(filename)
            else:
                ctrl.setIcon(t.image)
                
        ctrl.clicked.connect(makeCmdNew(t))
        #ctrl.onMouseRelease = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    def getCursorFile(self, cursorName):
        
        cursorName = "cursors\\"+cursorName
        folder, file = os.path.split(cursorName)
        d = os.path.dirname(sys.modules[folder].__file__)
        filename = os.path.join(d, file)
        return filename
    @lupa.unpacks_lua_table
    def makeComboBox(self, t):
        ctrl = QtDave.ComboBox(self.tabQt)
        #t.text = coalesce(t.text, '')
        #ctrl.addItems(t.items)
        #lua_func = lua.eval('function(o) {0} = o return o end'.format('NESBuilder'))
        if t.itemList:
            ctrl.addItems(t.itemList.values())
        
        t.control = ctrl
        ctrl.init(t)
        
        ctrl.activated.connect(makeCmdNoEvent(t))
        
        #ctrl.textChanged.connect(makeCmdNoEvent(t))
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeLineEdit(self, t):
        ctrl = QtDave.LineEdit(self.tabQt)
        t.text = coalesce(t.text, '')
        t.control = ctrl
        ctrl.init(t)
        
        #ctrl.clicked.connect(makeCmdNew(t))
        #ctrl.textChanged.connect(makeCmdNew(t))
        ctrl.textChanged.connect(makeCmdNoEvent(t))
        #ctrl.onKeyPress = makeCmdNew(t, functionName = t.name+"_keyPress")
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeNumberEdit(self, t):
        ctrl = QtDave.NumberEdit(self.tabQt)
        t.text = coalesce(t.text, '')
        t.control = ctrl
        ctrl.init(t)
        ctrl.textChanged.connect(makeCmdNoEvent(t))
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeCodeEdit(self, t):
        #ctrl = QtDave.CodeEdit(t.text, self.tabQt)
        ctrl = QtDave.CodeEdit(self.tabQt)
        ctrl.init(t)
        #ctrl.clicked.connect(makeCmdNew(t))
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeConsole(self, t):
        ctrl = QtDave.Console(t.text, self.tabQt)
        ctrl.init(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeTextEdit(self, t):
        ctrl = QtDave.TextEdit(t.text, self.tabQt)
        ctrl.init(t)
        #ctrl.clicked.connect(makeCmdNew(t))
        ctrl.textChanged.connect(ctrl._changed)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeFrame(self, t):
        ctrl = QtDave.Frame(self.tabQt)
        ctrl.init(t)
        #ctrl.clicked.connect(makeCmdNew(t))
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeScrollFrame(self, t):
        ctrl = QtDave.ScrollFrame(self.tabQt)
        ctrl.init(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeList(self, t):
        ctrl = QtDave.ListWidget(self.tabQt)
        ctrl.setSortingEnabled(False)
        ctrl.init(t)
        
        #t.currentItem = lambda: ctrl.currentItem().text()
        t.getIndex = ctrl.currentRow
        t.getItem = lambda: ctrl.currentItem().text()
        
        if t.list:
            ctrl.setList(t.list)
        t.control = ctrl
        
        #ctrl.currentItemChanged.connect(makeCmdNew(t, extra = {'functionName':t.name}))
        ctrl.currentItemChanged.connect(makeCmdNew(t, functionName = t.name))
        ctrl.onKeyPress = makeCmdNew(t, functionName = t.name+"_keyPress")
        
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeCheckbox(self, t):
        ctrl = QtDave.CheckBox(t.text, self.tabQt)
        ctrl.init(t)
        
        t.control = ctrl
        t.isChecked = ctrl.isChecked
        t.setChecked = ctrl.setChecked
        
        if t.value: ctrl.setChecked(True)
        
        if t.image:
            try:
                # the frozen version will still try to load it manually first
                ctrl.setIcon(fixPath2(t.image))
            except:
                folder, file = os.path.split(t.image)
                ctrl.setIcon(BytesIO(pkgutil.get_data(folder, file)))
        
        ctrl.clicked.connect(makeCmdNoEvent(t))
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeLauncherIcon(self, t):
        ctrl = QtDave.LauncherIcon(self.tabQt)
        ctrl.init(t)
        
        ctrl.iconCtrl.onMousePress = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeLink(self, t):
        ctrl = QtDave.Link(t.text, self.tabQt)
        t.control = ctrl
        t.cancel = ctrl.cancel
        t.getUrl = ctrl.getUrl
        t.setUrl = ctrl.setUrl
        t.openUrl = ctrl.openUrl
        
        ctrl.init(t)
        
        cmd = makeCmdNew(t)
        def openUrl(*args, **kwargs):
            cmd(*args, **kwargs)
            if ctrl._cancel == True:
                ctrl._cancel = False
            else:
                ctrl.openUrl()
        
        ctrl.mousePressEvent = openUrl
        
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeLabelQt(self, t):
        ctrl = QtDave.Label(t.text, self.tabQt)
        t.control = ctrl
        ctrl.init(t)
        ctrl.onMouseMove = makeCmdNew(t)
        ctrl.onMousePress = makeCmdNew(t)
        ctrl.onMouseRelease = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        ctrl.update()
        return ctrl
    @lupa.unpacks_lua_table
    def makeMenuQt(self, t):
        window = self.getWindowQt(self)
        
        # We'll turn this into a dictionary so our class library
        # doesn't have to handle any lua.
        menuItems = [dict(x) for _,x in t.menuItems.items()]
        for i, item in enumerate(menuItems):
            if item.get('name', False):
                if not item.get('action',False):
                    t2 = lua.table()
                    
                    if t.prefix:
                        t2.name = t.name + "_" + item.get('name', str(i))
                    else:
                        t2.name = item.get('name', "_"+str(i))
                    
                    menuItems[i].update(action = makeCmdNew(t2))
        
        return window.addMenu(t.name, t.text, menuItems)
    def setText(c,txt):
        c.setText(txt)
    def makeWindow(self, t, variables):
        x,y,w,h = variables
        
        if controls.get(t.name):
            if controls.get(t.name).exists():
                # If the window already exists, bring it to the front
                # and return its table.
                t = controls.get(t.name)
                t.alreadyCreated = True
                t.control.deiconify()
                t.control.lift()
                return t
        
        window = tk.Toplevel(root)
        window.title(t.title or "Window")
        window.geometry("{0}x{1}".format(w,h))
        
        def close():
            del controls[t.name]
            window.destroy()
        def front():
            window.focus_force()
        def exists():
            return window.winfo_exists()
            #return window.winfo_ismapped()
        window.protocol( "WM_DELETE_WINDOW", close)
        
        tabParent = ttk.Notebook(window)
        tabs={}
        
        window.configure(bg=config.colors.bk)
        
        # Set the window icon and override when applicable in this order:
        # 1. executable icon 
        # 2. external icon if not frozen
        # 3. custom icon
        # 4. custom icon relative to plugins folder
        window.iconbitmap(sys.executable)
        if not frozen:
            try:
                photo = ImageTk.PhotoImage(file = fixPath2("icon.ico"))
                window.iconphoto(False, photo)
            except:
                pass
        if t.icon:
            try:
                photo = ImageTk.PhotoImage(file = fixPath2(t.icon))
                window.iconphoto(False, photo)
            except:
                try:
                    photo = ImageTk.PhotoImage(file = fixPath2(config.pluginFolder+"/"+t.icon))
                    window.iconphoto(False, photo)
                except:
                    pass

        control = window
        t=lua.table(name=t.name,
                    control=control,
                    tabParent=tabParent,
                    tabs=tabs,
                    close=close,
                    front=front,
                    exists=exists,
                    )
        
        controls.update({t.name:t})
        windows.update({t.name:t})
        #windows.update({t.name:window})
        
        #control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        return t
    @lupa.unpacks_lua_table
    def makePaletteControlQt(self, t):
        ctrl = QtDave.PaletteControl(self.tabQt)
        ctrl.init(t)
        #ctrl.mousePressEvent = makeCmdNew(t)
        
        for cell in ctrl.cells:
            t2 = lua.table(
                name = t.name,
                cellNum = cell.cellNum,
                cell = cell,
                control = ctrl,
                cells = ctrl.cells,
                set = ctrl.set,
                setAll = ctrl.setAll,
            )
            #cell.mousePressEvent = makeCmdNew(t2)
            #cell.onMouseMove = makeCmdNew(t2)
            cell.onMousePress = makeCmdNew(t2)
            #cell.onMouseRelease = makeCmdNew(t2)

        
        
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    def selectTab(self, tab):
        window = self.getWindow(self)
        window.tabParent.select(list(window.tabs).index(tab))
        print(list(window.tabParent.tabs))
    def forceClose(self):
        sys.exit()
    def restart(self):
        if onExit():
            print("\n"+"*"*20+" RESTART "+"*"*20+"\n")
            
            main.close()
            
            os.chdir(initialFolder)
            if frozen:
                subprocess.Popen(sys.argv)
            else:
                subprocess.Popen([sys.executable]+ sys.argv)
            os.system('cls')

    def setTitle(self, title=''):
        main.setWindowTitle(title)
    
# Return it from eval so we can execute it with a 
# Python object as argument.  It will then add "NESBuilder"
# to Lua
ForLua.decorate(ForLua)
lua_func = lua.eval('function(o) {0} = o return o end'.format('NESBuilder'))
lua_func(ForLua)

#lua_func = lua.eval('function(o) {0} = o return o end'.format('nesPalette'))
#lua_func(lua.table(QtDave.nesPalette.get()))

def coalesce(*arg): return next((a for a in arg if a is not None), None)

def makeCmdNew(*args, extra = False, functionName=False):
    if not args[0].name:
        # no name specified, dont create a function
        return
    if args[0].anonymous:
        print('anon')
    if not extra:
        extra = dict()

    if functionName:
        extra.update(functionName = functionName)
    
    extra.update(plugin = lua.eval("_getPlugin and _getPlugin() or false"))

    return lambda x:doCommandNew(args, ev = x, extra = extra)
def makeCmdNoEvent(*args, extra = False):
    if extra:
        return lambda :doCommandNew(args, ev = lua.table(extra=extra))
    return lambda :doCommandNew(args)


# a single lua table is passed
def doCommandNew(*args, ev=False, extra = False):
    args = args[0][0]
    try:
        for k,v in ev.extra.items():
            args[k]=v
        ev.extra = False
    except:
        pass
    
    # now try items from the "extra" argument
    try:
        for k,v in extra.items():
            args[k]=v
    except:
        pass
    
    if ev and (ev.__class__.__name__ == "QMouseEvent"):
        event = dict(
            event = ev,
            x = ev.x,
            y = ev.y,
            button = ev.button,
            type = ev.type,
        )
        if callable(ev.type):
            b = dict({
                2:'ButtonPress',
                3:'ButtonRelease',
                4:'ButtonDblClick',
                5:'Move',
                })
            event.update(type=b.get(ev.type()))
        
        args.event = event
    elif ev and (ev.__class__.__name__ == "QListWidgetItem"):
        # ev exists, but isn't an event
        args.selectedWidget = ev
    # doCommand is a command preprocessor thing.  If 
    # It returns true then it moves on to name_command
    # if it exists, or name_cmd otherwise.
    lua_func = lua.eval("""function(o)
        local status=true
        if doCommand then status = doCommand(o) end
        if status then
            if main.{0}_cmd then
                print('yay '*10)
                main.{0}_cmd(o)
            elseif {0}_command then
                {0}_command(o)
            elseif {0}_cmd then
                {0}_cmd(o)
            end
        end
    end""".format(coalesce(args.functionName, args.name)))
    try:
        lua_func(args)
    except LuaError as err:
        handleLuaError(err)
    except Exception as err:
        handlePythonError(err)

def handlePythonError(err=None, exit=False):
    print("-"*79)
    e = traceback.format_exc().splitlines()
    e = "\n".join([x for x in e if "lupa\_lupa.pyx" not in x])

    lua_func = lua.eval("function(e) if handlePythonError then handlePythonError(e) end end")
    if lua_func(e) != True:
        print(e)
        print("-"*79)
    
    if exit or cfg.getValue("main","breakonpythonerrors"):
        sys.exit(1)

def onExit(skipCallback=False):
    print('onExit')
    exit = True
    if skipCallback:
        pass
    elif lua.eval('type(onExit)') == 'function':
        exit = not lua.eval('onExit()')
    if exit:
        exitCleanup()
        app.quit()
        return true

main.onClose = onExit

def exitCleanup():
    x = main.x()
    y = main.y()
    w = main.width
    h = main.height
    
    if w>=500 and h>=400 and x>0 and y>0:
        cfg.setValue('main','x', x)
        cfg.setValue('main','y', y)
        cfg.setValue('main','w', w)
        cfg.setValue('main','h', h)
    cfg.save()

# run function on exit
#atexit.register(exitCleanup)

ctrl = QtDave.TabWidget(main)
main.tabParent = ctrl
t = lua.table(name = main.name+"tabs", y=main.menuBar().height(), control=ctrl)
ctrl.init(t)
ctrl.mousePressEvent = makeCmdNew(t)
main.tabParent.currentChanged.connect(makeCmdNoEvent(t))

ctrl.onCloseTab = makeCmdNew(lua.table(name = 'closeTabButton', control=ctrl))

#if cfg.getValue("main","dev"):
#    toolbar = main.addToolBar("File")
#    toolbar.addAction(QtDave.QAction('test', toolbar))

windows={}


def handleLuaError(err):
    err = str(err).replace('error loading code: ','')
    err = err.replace('[string "<python>"]',"[main.lua]")
    err = err.replace('[C]',"[lua]")
    err = err.replace("stack traceback:","\nstack traceback:")
    
    err = [line.strip() for line in err.splitlines()]
    if err[0].startswith("error loading module "):
        err.pop(0)
        line = err[0].split(":")
        line[0]=line[0].replace(".\\","").replace("\\","")
        line[0]="["+line[0]+"]"
        line = ":".join(line)
        err[0] = line
    
    indent = 0
    for i, line in enumerate(err):
        err[i]=" "*indent+line
        if line.startswith("stack traceback:"):
            indent = 4
    
    err = "\n".join(err)
    err = textwrap.indent(err, " "*4)
    
    lua_func = lua.eval("function(e) if handleLuaError then return handleLuaError(e) end end")
    if lua_func(err) != True:
        print("-"*80)
        print("*LuaError:\n")
        print(err)
        print()
        print("-"*80)


    if cfg.getValue("main","breakonluaerrors"):
        sys.exit(1)


lua.execute("True, False = true, false")
lua.execute("len = function(item) return NESBuilder:getLen(item) end")

gotError = False

try:
    if cmdArgs.mainfile:
        # use file specified in argument
        f = open(cmdArgs.mainfile,"r")
        lua.execute(f.read())
        f.close()
    elif frozen:
        # use internal main.lua
        filedata = pkgutil.get_data('include', 'main.lua' )
        lua.execute(filedata)
    else:
        # use external main.lua
        f = open("main.lua","r")
        lua.execute(f.read())
        f.close()
    pass
except LuaError as err:
    handleLuaError(err)
    gotError = True
    
if gotError:
    sys.exit(1)
    
    
    
config  = lua.eval('config or {}')

config.title = config.title or "SpideyGUI"
main.setWindowTitle(config.title)

print("This console is for debugging purposes.\n")

try:
    lua.execute("if init then init() end")
except LuaError as err:
    print("*** init() Failed")
    handleLuaError(err)
except Exception as err:
    handlePythonError(err, exit=True)

lua.execute("plugins = {}")

# load lua plugins
if cfg.getValue("main","loadplugins"):
    folder = config.pluginFolder
    folder = fixPath(script_path + "/" + folder)
    if os.path.exists(folder):
        lua.execute("""
        local _plugin
        """)
        pluginList = []
        for file in os.listdir(folder):
            if file.endswith(".lua") and not file.startswith("_"):
                pluginList.append(file)
                cfg.setDefault("plugins", file, 1)
        
        cfg.setValue("plugins","list", ', '.join(pluginList))
        
        for file in pluginList:
            if cfg.getValue("plugins",file, 1)==1:
                print("Loading plugin: "+file)
                code = """
                    NESBuilder:setWorkingFolder()
                    _plugin = require("{0}.{1}")
                    _plugin.dontPrintThis = true
                    if type(_plugin) =="table" then
                        plugins[_plugin.name or "{1}"]=_plugin
                        _plugin.file = "{2}"
                        _plugin.name = _plugin.name or "{1}"
                        _plugin.data = _plugin.data or {{}}
                    end
                """.format(config.pluginFolder,os.path.splitext(file)[0], file)
                #print(fancy(code))
                try:
                    lua.execute(code)
                except LuaError as err:
                    print("*** Failed to load plugin: "+file)
                    handleLuaError(err)
                
        try:
            lua.execute("if onPluginsLoaded then onPluginsLoaded() end")
        except LuaError as err:
            print("*** onPluginsLoaded() Failed")
            handleLuaError(err)
        except Exception as err:
            handlePythonError(err)
try:
    lua.execute("if onReady then onReady() end")
except LuaError as err:
    print("*** onReady() Failed")
    handleLuaError(err)
except Exception as err:
    handlePythonError(err)

w = cfg.getValue('main', 'w', default=coalesce(config.width, 800))
h = cfg.getValue('main', 'h', default=coalesce(config.height, 800))

x,y = cfg.getValue('main', 'x'), cfg.getValue('main', 'y')

main.setGeometry(x,y,w,h)


s = pkgutil.get_data('include', 'style.qss').decode('utf8')
r = dict(
    bk=config.colors.bk,
    bk2=config.colors.bk2,
    bk3=config.colors.bk3,
    bk4=config.colors.bk4,
    bkMenuHighlight=config.colors.bk_menu_highlight,
    bkHighlight=config.colors.bk_highlight,
    menuBk=config.colors.menuBk,
    fg=config.colors.fg,
    borderLight=config.colors.borderLight,
    borderDark=config.colors.borderDark,
    bkHover=config.colors.bk_hover,
    link=config.colors.link,
    linkHover=config.colors.linkHover,
    textInputBorder=config.colors.textInputBorder,
)
for (k,v) in r.items():
    s = s.replace("_"+k+"_", v)

if frozen:
    folder = os.path.dirname(sys.modules['icons'].__file__)
    s=s.replace("url('icons/","url('"+folder.replace("\\","/")+"/")
    #print(s)

app.setStyleSheet(s)

try:
    folder = os.path.dirname(sys.modules['icons'].__file__)
    file = os.path.join(folder, 'icon.ico')
    main.setIcon(fixPath2(file))
except:
    # let's not break this over an icon
    pass

def onResize(width,height,oldWidth,oldHeight):
    for tab in main.tabs.values():
        #print(tab.name,tab.width,tab.height)
        
#        if tab.width!=0 and tab.height!=0:
#            tab.resize(tab.width+(width-oldWidth),tab.height+(height-oldHeight))
        pass
    try:
        lua.execute("if onResize then onResize({},{},{},{}) end".format(width,height,oldWidth,oldHeight))
    except LuaError as err:
        print("*** onResize() Failed")
        handleLuaError(err)
    except Exception as err:
        handlePythonError(err)
main.onResize = onResize


def onHoverWidget(widget):
    try:
        lua_func = lua.eval('function(o) if onHover then onHover(o) end end')
        lua_func(widget)
    except LuaError as err:
        print("*** onHoverWidget() Failed")
        handleLuaError(err)
    except Exception as err:
        handlePythonError(err)
main.onHoverWidget = onHoverWidget


main.show()
try:
    lua.execute("if onShow then onShow() end")
except LuaError as err:
    print("*** onShow() Failed")
    handleLuaError(err)
except Exception as err:
    handlePythonError(err)


app.mainloop()


