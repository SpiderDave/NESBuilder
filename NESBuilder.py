# needs lupa, pyinstaller, pillow, anything else?
'''
ToDo:
    * move to pyQt5!
    * make return value of control generating methods more consistant
    * makeCanvas method
    * clean up color variable names, add more
    * phase out controls and use controlsNew, then rename controlsNew
    * per-project plugins
'''

import os, sys, time

def badImport(m):
    print('Error: Could not import {0}.  Please run "install dependencies.bat".'.format(m))
    sys.exit(1)



try: import lupa
except: badImport('lupa')
from lupa import LuaRuntime
from lupa import LuaError
lua = LuaRuntime(unpack_returned_tuples=True)
try: import PyQt5.QtWidgets
except: badImport('PyQt5')
from tkinter import simpledialog, filedialog, messagebox
from tkinter import EventType
import tkinter as tk
from tkinter import ttk
#from tkinter import *
#from tkinter.ttk import *
try: from PIL import ImageTk, Image, ImageDraw
except: badImport('pillow')
from PIL import ImageOps
from PIL import ImageGrab
from collections import deque
import re

from random import randrange

from io import BytesIO

import textwrap

try: import numpy as np
except: badImport('numpy')

from shutil import copyfile
import subprocess

#from textwrap import dedent

import math
import webbrowser

from binascii import hexlify, unhexlify

import importlib, pkgutil

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

app = QtDave.App()
main = QtDave.MainWindow()

import configparser, atexit

# Handle exporting some stuff from python scripts to lua
include.init(lua)

true, false = True, False

script_path = os.path.dirname(os.path.abspath( __file__ ))
initialFolder = os.getcwd()

frozen = (getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'))

application_path = False
if frozen:
    application_path = sys._MEIPASS
else:
    application_path = os.path.dirname(os.path.abspath(__file__))

nesPalette=[
[0x74,0x74,0x74],[0x24,0x18,0x8c],[0x00,0x00,0xa8],[0x44,0x00,0x9c],
[0x8c,0x00,0x74],[0xa8,0x00,0x10],[0xa4,0x00,0x00],[0x7c,0x08,0x00],
[0x40,0x2c,0x00],[0x00,0x44,0x00],[0x00,0x50,0x00],[0x00,0x3c,0x14],
[0x18,0x3c,0x5c],[0x00,0x00,0x00],[0x00,0x00,0x00],[0x00,0x00,0x00],
[0xbc,0xbc,0xbc],[0x00,0x70,0xec],[0x20,0x38,0xec],[0x80,0x00,0xf0],
[0xbc,0x00,0xbc],[0xe4,0x00,0x58],[0xd8,0x28,0x00],[0xc8,0x4c,0x0c],
[0x88,0x70,0x00],[0x00,0x94,0x00],[0x00,0xa8,0x00],[0x00,0x90,0x38],
[0x00,0x80,0x88],[0x00,0x00,0x00],[0x00,0x00,0x00],[0x00,0x00,0x00],
[0xfc,0xfc,0xfc],[0x3c,0xbc,0xfc],[0x5c,0x94,0xfc],[0xcc,0x88,0xfc],
[0xf4,0x78,0xfc],[0xfc,0x74,0xb4],[0xfc,0x74,0x60],[0xfc,0x98,0x38],
[0xf0,0xbc,0x3c],[0x80,0xd0,0x10],[0x4c,0xdc,0x48],[0x58,0xf8,0x98],
[0x00,0xe8,0xd8],[0x78,0x78,0x78],[0x00,0x00,0x00],[0x00,0x00,0x00],
[0xfc,0xfc,0xfc],[0xa8,0xe4,0xfc],[0xc4,0xd4,0xfc],[0xd4,0xc8,0xfc],
[0xfc,0xc4,0xfc],[0xfc,0xc4,0xd8],[0xfc,0xbc,0xb0],[0xfc,0xd8,0xa8],
[0xfc,0xe4,0xa0],[0xe0,0xfc,0xa0],[0xa8,0xf0,0xbc],[0xb0,0xfc,0xcc],
[0x9c,0xfc,0xf0],[0xc4,0xc4,0xc4],[0x00,0x00,0x00],[0x00,0x00,0x00],
]

def pathToFolder(p):
    return fixPath2(os.path.split(p)[0])

def fixPath2(p):
    if ":" not in p:
        p = script_path+"/"+p
    return p.replace("/",os.sep).replace('\\',os.sep)
    
def fixPath(p):
    return p.replace("/",os.sep).replace('\\',os.sep)


# create our config parser
cfg = Cfg(filename=fixPath2("config.ini"))

# read config file if it exists
cfg.load()

cfg.setDefault('main', 'stylemenus', 1)
cfg.setDefault('main', 'project', "newProject")
cfg.setDefault('main', 'upperhex', 0)
cfg.setDefault('main', 'alphawarning', 1)
cfg.setDefault('main', 'loadplugins', 1)

# make cfg available to lua
lua_func = lua.eval('function(o) {0} = o return o end'.format('cfg'))
lua_func(cfg)

controls={}
controlsNew={}

# set up our lua function
lua_func = lua.eval('function(o) {0} = o return o end'.format('tkConstants'))
# get all the constants from tk.constants but leave out builtins, etc.
d= dict(enumerate([x for x in dir(tk.constants) if not x.startswith('_')]))
# flip keys and values
d = {v:k for k,v in d.items()}
# export to lua.  the values will still be python
lua_func(lua.table_from(d))

def fancy(text):
    return "*"*60+"\n"+text+"\n"+"*"*60


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
                t.name = "anonymous{0}".format(ForLua.anonCounter)
                ForLua.anonCounter = ForLua.anonCounter + 1
                t.anonymous=True

            return t
        return inner
    def decorate(self):
        decorator = lupa.unpacks_lua_table_method
        for method_name in dir(self):
            m = getattr(self, method_name)
            if m.__class__.__name__ == 'function':
                # these are control creation functions
                # makedir maketab
                makers = ['makeButton', 'makeCanvas', 'makeEntry', 'makeLabel', "makeTree",
                          'makeList', 'makeMenu', 'makePaletteControl', 'makePopupMenu',
                          'makeText', 'makeWindow', 'makeSpinBox',
                          ]
                QtWidgets = ['makeButtonQt', 'makeLabelQt', 'makeTabQt', 'makeCanvasQt', 'makeSideSpin', 'makeCheckbox', 'makeLink']
                
                if method_name in makers:
                    attr = getattr(self, method_name)
                    wrapped = self.makeControl(attr)
                    setattr(self, method_name, wrapped)
                elif method_name in QtWidgets:
                    attr = getattr(self, method_name)
                    wrapped = self.QtWrapper(attr)
                    setattr(self, method_name, wrapped)
                elif method_name in ['getNESColors', 'makeControl', 'getLen', 'makeMenuQt','makeNESPixmap']:
                    # getNESColors: excluded because it may have a table as its first parameter
                    # makeControl: excluded because it's a decorator
                    pass
                else:
                    #print(method_name, m.__class__)
                    if method_name.startswith('make') and method_name not in ['makeDir', 'makeTab', 'makeIps']:
                        print("possible function to exclude from decorator: ", method_name, m.__class__)
                    attr = getattr(self, method_name)
                    wrapped = decorator(attr)
                    setattr(self, method_name, wrapped)
    
    # can't figure out item access from lua with cfg,
    # so we'll define some methods here too.
    def cfgLoad(self, filename = "config.ini"):
        return cfg.load(filename)
    def cfgSoad(self):
        return cfg.save()
    def cfgMakeSections(self, *sections):
        return cfg.makeSections(*sections)
    def cfgGetValue(self, section, key, default=None):
        return cfg.getValue(section, key, default)
    def cfgSetValue(self, section, key, value):
        return cfg.setValue(section, key, value)
    def cfgSetDefault(self, section,key,value):
        return cfg.setDefault(section,key,value)
    def repr(self, item):
        return repr(item)
    def type(self, item):
        return item.__class__.__name__
    def calc(self, s):
        calc = Calculator()
        return calc(s)
    def getPrintable(self, item):
        if type(item) is str: return item
        if repr(item).startswith("<"):
            return repr(item)
        else:
            return str(item)
    def printNoPrefix(self, item):
        if repr(item).startswith("<"):
            print(repr(item))
        else:
            print(item)
    def print(self, prefix, item):
        print(prefix, end="")
        if repr(item).startswith("<"):
            print(repr(item))
        else:
            print(item)
    def fileExists(self, f):
        f = fixPath(script_path+"/"+f)
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
    def sleep(self, t):
        time.sleep(t)
    def delete(self, filename):
        filename = fixPath(script_path+"/"+filename)
        try:
            if os.path.exists(filename):
                os.remove(filename)
            return True
        except:
            print("Could not delete "+filename)
            return False
    def run(self, workingFolder, cmd, args):
        try:
            cmd = fixPath(script_path+"/"+cmd)
            workingFolder = fixPath(script_path+"/"+workingFolder)
            os.chdir(workingFolder)
            subprocess.run([cmd]+ args.split())
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
    def askText(self, title, text):
        d = QtDave.Dialog()
        return d.askText(title, text)
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
    def setDirection(self, d):
        self.direction=d
    def getWindow(self, window=None):
        return windows.get(coalesce(window, ForLua.window))
    def setWindow(self, window):
        self.window=window
    def getTab(self, tab=None):
        window = controls[ForLua.window]
        tab = window.tabs.get(coalesce(tab, window.tab, False))
        if not tab:
            tab = window.control
        return tab
        #return tabs.get(coalesce(tab, ForLua.tab))
    def getWindowQt(self, name=None):
        # todo: add parameter to get window by name
        return self.windowQt
    def getTabQt(self, name=None):
        # todo: add parameter to get tab by name
        return self.tabQt
    def setTab(self, tab):
        window = controls[self.window]
        window.tab = tab
        self.tab=tab
    def setTabQt(self, tab):
        window = self.windowQt
        #window.tabParent.setCurrentWidget(window.tabs.get(tab))
        self.tabQt = window.tabs.get(tab)
    def switchTab(self, tab):
        window = self.windowQt
        window.tabParent.setCurrentWidget(window.tabs.get(tab))
    def setWindowQt(self, window):
        self.windowQt=window
    def getCanvas(self, canvas=None):
        return controlsNew[coalesce(canvas, self.canvas)]
    def setCanvas(self, canvas):
        self.canvas = canvas
    def makeDir(self,dir):
        dir = fixPath(script_path + "/" + dir)
        print(dir)
        if not os.path.exists(dir):
            os.makedirs(dir)
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
        return coalesce(m.saveFile(filetypes=filetypes, initial=initial), '')
    def lift(self, window=None):
        window = self.getWindow(self, window)
        window.control.lift()
        window.control.focus_force()
    def _saveFileAs(self, filetypes, initial=None):
        types = list()
        
        if filetypes:
            for t in filetypes:
                types.append([filetypes[t][1],filetypes[t][2]])
        
        types.append(["All files","*.*"])
        filename =  filedialog.asksaveasfilename(title = "Select file",filetypes = types, initialfile=initial, parent=root.getTopWindow())
        return filename
    def importFunction(self, mod, f):
        m = importlib.import_module(mod)
        setattr(self, f, getattr(m, f))
        
        return getattr(m,f)
    def copyfile(self, src,dst):
        copyfile(src,dst)
    def canvasPaint(self, x,y, c):
        canvas = self.getCanvas(self)
        c = "#{0:02x}{1:02x}{2:02x}".format(nesPalette[c][0],nesPalette[c][1],nesPalette[c][2])
        canvas.control.create_rectangle(x*canvas.scale, y*canvas.scale, x*canvas.scale+canvas.scale-1, y*canvas.scale+canvas.scale-1,
                           width=1, outline=c, fill=c,
                           )

    def saveCanvasImage(self, f='test.png'):
        canvas = self.getCanvas(self).control
        grabcanvas=ImageGrab.grab(bbox=canvas)
        ttk.grabcanvas.save(f)
    def loadImageToCanvas(self, f):
        c = self.getCanvas(self).control
        canvas = c.control
        print("loadImageToCanvas: {0}".format(f))
        try:
            with Image.open(f) as im:
                px = im.load()
            
            displayImage = ImageOps.scale(im, c.scale, resample=Image.NEAREST)
            canvas.image = ImageTk.PhotoImage(displayImage)
            
            canvas.create_image(0, 0, image=canvas.image, anchor=tk.NW)
            canvas.configure(highlightthickness=0, borderwidth=0)
        except:
            print("error loading image")
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
            c = [nesPalette[x] for x in unhexlify(c)]
            if len(c) == 1:
                return c[0]
            return c
        else:
            c = [nesPalette[v] for i,v in sorted(c.items())]
            if len(c) == 1:
                return c[0]
            return c
    def imageToCHR(self, f, outputfile="output.chr", colors=False):
        print('imageToCHR')
        data = self.imageToCHRData(self, f, colors)
        
        print('Tile data written to {0}.'.format(outputfile))
        f=open(outputfile,"wb")
        f.write(bytes(data))
        f.close()
    def getLen(self, item):
        # todo: make work for lua stuff
        return len(item)
    def test(self, x=0,y=0):
        canvas = self.getCanvas(self, 'tsaTileCanvas')
        f = r"J:\svn\NESBuilder\mtile.png"
        img = Image.open(f)
        photo = ImageTk.PhotoImage(ImageOps.scale(img, 2, resample=Image.NEAREST))
        self.images2.append(photo)
        canvas = self.getCanvas(self, 'testCanvas')
        canvas.control.create_image(x, y, image=photo, anchor=tk.NW)
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
    def screenshotTest(self):
        main.screenshot(main)
    def getFileData(self, f=None):
        file=open(f,"rb")
        #file.seek(0x1000)
        fileData = file.read()
        file.close()
        
        return list(fileData)
    def getFileAsArray(self, f):
        file=open(f,"rb")
        fileData = file.read()
        file.close()
        fileData = list(fileData)
        return fileData
    def saveArrayToFile(self, fileData, f):
        f = fixPath2(f)
        file=open(f,"wb")
        file.write(bytes(fileData))
        file.close()
        return True
    def writeToFile(self, f, fileData):
        f = fixPath2(f)
        file=open(f,"w")
        file.write(fileData)
        file.close()
        return True
    def unHex(self, s):
        return unhexlify(str(s))
    def hexStringToList(self, s):
        return list(unhexlify(s))
    def getFileContents(self, f, start=0):
        # returns a list
        file=open(f,"rb")
        file.seek(start)
        fileData = file.read()
        file.close()
        
        return list(fileData)
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
                    a[y1][x1] = nesPalette[colors[c]]
        
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
                    a[y1][x1] = nesPalette[colors[c]]
        
        img = Image.fromarray(a)
        img.save(filename)
#    def makeIps(self, originalFile, modifiedFile, patchFile):
#        originalFile = fixPath2(originalFile)
#        modifiedFile = fixPath2(modifiedFile)
#        patchFile = fixPath2(patchFile)
#        ips.createPatch(originalFile, modifiedFile, patchFile)
    def Quit(self):
#        app.quit()
#        main.destroy()
        onExit()
    def switch(self):
        if qt:
            app.quit()
            main.destroy()
        else:
            self.restart(self)
    def exec(self, s):
        exec(s)
    def eval(s):
        # store the eval return value so we can pass return value to lua space.
        exec('ForLua.execRet = {0}'.format(s))
        return ForLua.execRet
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
        
        ctrl.mousePressEvent = makeCmdNew(t)
        ctrl.mouseMoveEvent = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    def makeCanvas(self, t, variables):
        x,y,w,h = variables
        
        t.scale = t.scale or 3
        w=w*t.scale
        h=h*t.scale
        
        canvas = tkDave.Canvas(self.getTab(self), width=1, height=1, bg='black',name=t.name)
        canvas.configure(highlightthickness=0, borderwidth=0)
        canvas.place(x=x,y=y, width=w, height=h)
        control=canvas
        
        photo = False
        
        def setCursor(cursor):
            if not cursor.lower().endswith(".cur"):
                cursor = cursor+".cur"
            try:
                d = os.path.dirname(sys.modules["cursors"].__file__)
                f = os.path.join(d, cursor).replace("\\","/")
                canvas.config(cursor="@"+f)
            except:
                pass
        
        
        def removeSplits():
            pass
        #@lupa.unpacks_lua_table
        
        def drawSplit(splits):
            control = self.getControlNew(self, t.name)
            canvas = control.control
            splits = [splits[x] for x in splits if splits[x]>0]
            
            for i, l in enumerate(splits):
                if control.lines.get(i):
                    for item in control.lines[i]:
                        canvas.delete(item)
                control.lines[i] = [
                    canvas.create_line(0, l*control.scale+0, control.width, l*control.scale+0, fill="white", activefill="red", width=2, dash=(8,3)),
                ]
            canvas.update_idletasks()
        def _drawSplit(splits):
            # makes a stack overflow, dont know why :(
            
            control = self.getControlNew(self, t.name)
            canvas = control.control
            
            control.splits = splits
            splits = [splits[x] for x in splits]
            print(splits)
            print(control.lines)
            
            img=False
            photo=False
            a=False
            
            for i, l in enumerate(splits):
                if control.lines.get(i):
                    canvas.delete(control.lines[i][0])
                    del control.lines[i]

                img=Image.new("RGB", size=(control.width,2))
                a = np.asarray(img).copy()
                for y in range(2):
                    for x in range(control.width):
                        if x%8 <5:
                            a[y][x] = [255,255,255]
                        else:
                            a[y][x] = [100,100,100]
                img = Image.fromarray(a)
                photo = ImageTk.PhotoImage(img)
                
#                control.lines.update({i:photo})
#                canvas.create_image(0,l*control.scale, image=photo, state="normal", anchor=tk.NW)
                control.lines[i] = [canvas.create_image(0,l*control.scale, image=photo, state="normal", anchor=tk.NW), photo]
        @lupa.unpacks_lua_table
        def drawTile(x=0,y=0, tile=0, colors=(0x0f,0x23,0x13,0x03), useCache=False, chrData=False):
            placeX,placeY = x,y
            control = self.getControlNew(self, t.name)
            canvas = control.control
            
            # convert and re-index lua table
            if lupa.lua_type(colors)=="table":
                colors = [colors[x] for x in colors]
            
            rows, columns = t.rows, t.columns
            
            imageData = False
            if useCache and control.imageDataCache:
                imageData = control.imageDataCache
            elif chrData:
                control.chrData = chrData
                imageData = control.chrData
                imageData = [imageData[x] for x in list(imageData)]
                control.imageDataCache = imageData
            else:
                imageData = control.chrData
                imageData = [imageData[x] for x in list(imageData)]
                control.imageDataCache = imageData
            
            img=Image.new("RGB", size=(8,8))
            a = np.asarray(img).copy()
            
            
            for y in range(8):
                for x in range(8):
                    c=0
                    x1=(tile % columns)*8+(7-x)
                    y1=math.floor(tile/columns)*8+y
                    if (imageData[tile*16+y] & (1<<x)):
                        c=c+1
                    if (imageData[tile*16+y+8] & (1<<x)):
                        c=c+2
                    a[y][(7-x)] = nesPalette[colors[c]]
                    
            img = Image.fromarray(a)
            #photo = ImageTk.PhotoImage(ImageOps.scale(img, control.scale, resample=Image.NEAREST))
            #photo = ImageTk.PhotoImage(img.resize((8*control.scale,8*control.scale), resample = Image.NEAREST ))
            #photo = ImageTk.PhotoImage(img.resize((8*control.scale,8*control.scale), resample = Image.NEAREST, reducing_gap=1 ))
            #photo = ImageTk.PhotoImage(img)
            photo = ImageTk.PhotoImage(img.resize((8*control.scale,8*control.scale), resample = Image.NEAREST, reducing_gap=1))
            control.tiles.update({"{0},{1}".format(placeX,placeY): photo})
            canvas.create_image(placeX*control.scale,placeY*control.scale, image=photo, state="normal", anchor=tk.NW)
            
            # This makes everything responsive while it's updating
            root.update()
        @lupa.unpacks_lua_table
        def loadCHRData(imageData=False, colors=(0x0f,0x21,0x11,0x01), columns=16, rows=16):
            
            if not imageData:
                imageData = lua.table()
                for i in range(0, columns*rows):
                    imageData[i+1] = 0
            
            if lupa.lua_type(imageData)!="table":
                print('bad imageData for loadCHRData')
                return False
            
            control = self.getControlNew(self, t.name)
            canvas = control.control
            
            control.columns = columns
            control.rows = rows
            
            control.chrData = imageData
            imageData = [imageData[x] for x in list(imageData)]
            
            # convert and re-index lua table
            if lupa.lua_type(colors)=="table":
                colors = [colors[x] for x in colors]
            
            control.colors = colors
            img=Image.new("RGB", size=(columns*8,rows*8))
            a = np.asarray(img).copy()
            for tile in range(math.floor(len(imageData)/16)):
                if tile >= (columns * rows):
                    break
                for y in range(8):
                    for x in range(8):
                        c=0
                        x1=(tile % columns)*8+(7-x)
                        y1=math.floor(tile/columns)*8+y
                        if (imageData[tile*16+y] & (1<<x)):
                            c=c+1
                        if (imageData[tile*16+y+8] & (1<<x)):
                            c=c+2
                        a[y1][x1] = nesPalette[colors[c]]
            img = Image.fromarray(a)
            #photo = ImageTk.PhotoImage(ImageOps.scale(img, t.scale, resample=Image.NEAREST))
            photo = ImageTk.PhotoImage(ImageOps.scale(img, control.scale, resample=Image.NEAREST))
            control.photo = photo
            canvas.create_image(0,0, image=photo, state="normal", anchor=tk.NW)
            canvas.configure(highlightthickness=0, borderwidth=0)
        
        t=lua.table(name=t.name,
                    control=control,
                    scale=t.scale,
                    loadCHRData=loadCHRData,
                    drawTile=drawTile,
                    tiles={},
                    drawSplit = drawSplit,
                    setCursor = setCursor,
                    lines = {},
                    tool = False,
                    button=0,
                    )
        
        control.bind("<ButtonPress-1>", makeCmdNew(t, extra=dict(press=True, button=1)))
        control.bind("<ButtonRelease-1>", makeCmdNew(t, extra=dict(press=False, button=1)))
        control.bind("<ButtonPress-3>", makeCmdNew(t, extra=dict(press=True, button=3)))
        control.bind("<ButtonRelease-3>", makeCmdNew(t, extra=dict(press=False, button=3)))
        control.bind("<B1-Motion>", makeCmdNew(t, extra = dict(button=1)))
        control.bind("<B3-Motion>", makeCmdNew(t, extra = dict(button=3)))

        canvas.config(cursor="top_left_arrow")
        
        t.setCursor("pencil")
        
        if not self.canvas:
            # set as default canvas
            self.setCanvas(self, t.name)
        
        controls.update({t.name:control})
        controlsNew.update({t.name:t})
        
        return t
    @lupa.unpacks_lua_table
    def makeTabQt(self, t):
        window = self.windowQt
        
        #if t.name in self.windowQt.tabs:
        if self.windowQt.tabs.get(t.name):
            print('Not creating tab "{}" (already exists).'.format(t.name))
            return self.getControlNew(self, t.name)
        
        ctrl = QtDave.Widget()
        window.tabParent.addTab(ctrl, t.text)
        window.repaint()
        ctrl.init(t)
        
        window.tabs.update({t.name:ctrl})
        
        ctrl.mousePressEvent = makeCmdNew(t)
        
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeButton2(self, t):
        
        if t.w:
            t.w=t.w*7.5
        
        if t.h:
            t.h=t.h*7.5
        
        return self.makeButtonQt(self, t)
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
    def makeButtonQt(self, t):
        ctrl = QtDave.Button(t.text, self.tabQt)
        ctrl.init(t)
        
#        if t.image:
            #image = Image.open(t.image.replace(".png", "_white.png"))
            #t.image = t.image.replace(".png", "_white.png")
#            image = Image.open(t.image)
#            print(ctrl.setIcon(image))
        
        if t.image:
            try:
                # the frozen version will still try to load it manually first
                ctrl.setIcon(fixPath2(t.image))
            except:
                folder, file = os.path.split(t.image)
                ctrl.setIcon(BytesIO(pkgutil.get_data(folder, file)))
        
        ctrl.clicked.connect(makeCmdNew(t))
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
        ctrl.mousePressEvent = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeLink(self, t):
        ctrl = QtDave.Link(t.text, self.tabQt)
        ctrl.init(t)
        ctrl.mousePressEvent = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeLabelQt(self, t):
        ctrl = QtDave.Label(t.text, self.tabQt)
        ctrl.init(t)
        ctrl.mousePressEvent = makeCmdNew(t)
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    @lupa.unpacks_lua_table
    def makeMenuQt(self, t):
        window = self.getWindowQt(self)
        
        # We'll turn this into a dictionary so our little class library
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
    def _makeButton(self, t, variables):
        x,y,w,h = variables
        imgctrl = False
        
        img = None
        image = None
        inverted_image = None
        control = False
        if t.image:
            try:
                # the frozen version will still try to load it manually first
                image = Image.open(t.image)
            except:
                folder, file = os.path.split(t.image)
                image = Image.open(BytesIO(pkgutil.get_data(folder, file)))
            
            if t.iconMod:
                image = ImageOps.expand(image, border=5)
                image = ImageTk.PhotoImage(image)
            else:
                image = ImageTk.PhotoImage(file=t.image)
            
            control = tkDave.Button(self.getTab(self), text=t.text, takefocus = 0, image=image, compound=tk.LEFT, anchor=tk.W, justify=tk.LEFT)
        else:
            if t.toggle:
                control = tkDave.ToggleButton(self.getTab(self), text=t.text, takefocus = 0)
            else:
                control = tkDave.Button(self.getTab(self), text=t.text, takefocus = 0)
        
        control.config(width=w,
                       fg=config.colors.fg,
                       bg=config.colors.bk2,
                       activebackground=config.colors.bk2,
                       activeforeground=config.colors.fg,
                      )
                      
        control.setHoverColor(config.colors.bk_hover, "white")
        control.place(x=t.x, y=t.y)
        if t.h:
            control.place(height = t.h)
        if t.w and t.trueWidth:
            control.place(width = t.w)
        controls.update({t.name:control})
        
        t=lua.table(name=t.name,
                    control=control,
                    imageRef=image,
                    text = t.text,
                    toggle = t.toggle,
                    )
        
        if t.toggle:
            t.getValue = control.getValue
            t.setValue = control.setValue
        
        control.bind( "<ButtonRelease-1>", makeCmdNew(t), add="+")
        
        controlsNew.update({t.name:t})
        return t

    def setText(c,txt):
        c.setText(txt)
    
    def makePopupMenu(self, t, variables):
        x,y,w,h = variables
        
        # create a popup menu
        tab = self.getTab(self)
        menu = tk.Menu(tab, tearoff=0)
        
        if cfg.getValue("main","styleMenus"):
            menu.config(bg=config.colors.bk2,fg=config.colors.fg, activebackground=config.colors.bk_menu_highlight)
        
        def popup(event):
            controls[t.name].event = event
            menu.post(event.x_root, event.y_root)
        
        control = menu
        controls.update({t.name:control})

        t=lua.table(name=t.name,
                    control=control,
                    items=t['items'],
                    prefix=t.prefix,
                    )

        for i, item in t['items'].items():
            name = item.name or str(i)
            t2=lua.table(name=t.name+"_"+name,
                        control=control,
                        items=t['items'],
                        )
            if not t.prefix:
                if item.name:
                    t2.name = name
                else:
                    t2.name = "_"+name
            
            entry = dict(index=i, entry = item)
            menu.add_command(label=item.text, command=makeCmdNoEvent(t2, extra=entry))

        tab.bind("<Button-3>", popup)
        
        return t
    def makeMenu(self, t, variables):
        x,y,w,h = variables
        
        window = self.getWindow(self)
        if not window.menu:
            menubar = tk.Menu(window.control)
            window.menu = menubar
            window.control.config(menu = menubar)
        
        tab = self.getTab(self)
        
        menu = False
        control = False
        
        if controls.get(t.name):
            # menu already exists, add to it instead.
            menu = controls.get(t.name)
            control = menu
            
            t=lua.table(name=t.name,
                        control=control,
                        items=t['items'],
                        prefix=t.prefix,
                        )
        else:
            # create menu
            menu = tk.Menu(tab, tearoff=0)
            
            if cfg.getValue("main","styleMenus"):
                menu.config(bg=config.colors.bk2,fg=config.colors.fg, activebackground=config.colors.bk_menu_highlight)
            
            window.menu.add_cascade(label=t.text, menu=menu)

            control = menu
            controls.update({t.name:control})

            t=lua.table(name=t.name,
                        control=control,
                        items=t['items'],
                        prefix=t.prefix,
                        )

        for i, item in t['items'].items():
            name = item.name or str(i)
            t2=lua.table(name=t.name+"_"+name,
                        control=control,
                        items=t['items'],
                        )
            if not t.prefix:
                if item.name:
                    t2.name = name
                else:
                    t2.name = "_"+name
            
            entry = dict(index=i, entry = item)
            if item.text == "-":
                menu.add_separator()
            else:
                menu.add_command(label=item.text, command=makeCmdNoEvent(t2, extra=entry))
        
        return t
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
        
    def makeList(self, t, variables):
        x,y,w,h = variables
        
        control = tk.Listbox(self.getTab(self))
        control.config(fg=config.colors.fg, bg=config.colors.bk2)
        control.place(x=x, y=y)
        
        def getIndex():
            selection = control.curselection()
            if not selection:
                return
            return selection[0]
        def get(index=False):
            selection = control.curselection()
            if not selection:
                return
            index = index or selection[0]
            return control.get(index)
        def set(index=0):
            control.select_clear(0, "end")
            control.selection_set(index)
            control.see(index)
            control.activate(index)
        
        t=lua.table(name=t.name,
                    control=control,
                    insert=control.insert,
                    append=lambda x:control.insert(tk.END,x),
                    getSelection = lambda:control.curselection(),
                    get = get,
                    set = set,
                    getIndex = getIndex,
                    )

        controls.update({t.name:t})

        #control.bind( "<Button-1>", makeCmdNew(t))
        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        
        return t
    def makeText(self, t, variables):
        x,y,w,h = variables
        
        control = tkDave.Text(self.getTab(self), borderwidth=0, relief="solid",height=t.lineHeight)
        control.config(fg=config.colors.fg, bg=config.colors.bk3)
        
        control.insert(tk.END, t.text)
        control.place(x=x, y=y)
        if not t.lineHeight:
            control.place(height=h)
        control.place(width=w)
        
        def setText(text):
            control.delete(1.0, tk.END)
            control.insert(tk.END, text)
        def addText(text):
            control.insert(tk.END, text)
        def print(text=''):
            text=str(text)
            control.insert(tk.END, text+"\n")
        def clear():
            control.delete(1.0, tk.END)
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    setText = setText,
                    addText = addText,
                    print = print,
                    clear = clear,
                    )

        controls.update({t.name:t})

        #control.bind( "<Button-1>", makeCmdNew(t))
        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        control.bind( "<Return>", makeCmdNew(t))
        
        return t
    def makeSpinBox(self, t, variables):
        x,y,w,h = variables
        control=None
        padX=5
        padY=1
        frame = tk.Frame(self.getTab(self), borderwidth=0, relief="solid")
        frame.config(bg=config.colors.bk3)
        frame.place(x=x,y=y, width=w, height=h)
        
        control = tkDave.SpinBox(self.getTab(self), borderwidth=0, relief="solid", buttondownrelief="solid", buttonuprelief="solid", insertontime=0)
        #control.config(fg=config.colors.fg, bg=config.colors.bk3, insertbackground = config.colors.fg, from_=0, to=255, state="readonly", readonlybackground=config.colors.bk3)
        control.config(fg=config.colors.fg, bg=config.colors.bk3, insertbackground = config.colors.fg, from_=0, to=255, takefocus = 0)
        control.place(x=x+padX, y=y+padY)
        
        control.place(height=h-padY*2)
        control.place(width=w-padX)
        def set(value):
            control.delete(0, tk.END)
            control.insert(0, value)
        def get():
            return int(control.get())
            
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    get=get,
                    set=set,
                    )
        
        cmd = makeCmdNew(t)
        control.config(command=lambda: cmd(t))
        
        controls.update({t.name:t})
        
#        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
#        control.bind( "<Return>", makeCmdNew(t))
        
        return t
    def makeEntry(self, t, variables):
        x,y,w,h = variables
        control=None
        padX=5
        padY=1
        frame = tk.Frame(self.getTab(self), borderwidth=0, relief="solid")
        frame.config(bg=config.colors.bk3)
        frame.place(x=x,y=y, width=w, height=h)
        
        control = tkDave.Entry(self.getTab(self), borderwidth=0, relief="solid",height=t.lineHeight)
        control.config(fg=config.colors.fg, bg=config.colors.bk3, insertbackground = config.colors.fg)
        control.insert(tk.END, t.text)
        control.place(x=x+padX, y=y+padY)
        if not t.lineHeight:
            control.place(height=h-padY*2)
        control.place(width=w-padX*2)
        
        def setText(text=""):
            control.delete(0, tk.END)
            control.insert(tk.END, text)
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    clear = lambda:setText(),
                    setText = setText,
                    getText = control.get,
                    )
        
        controls.update({t.name:t})

        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        control.bind( "<Return>", makeCmdNew(t))
        
        return t
    def makeTree(self, t, variables):
        x,y,w,h = variables
        
        style.configure('new.Treeview', background=config.colors.bk, fg=config.colors.fg)
        
        control = ttk.Treeview(self.getTab(self), style = "new.Treeview")
        control.place(x=x, y=y)
        #control.place(x=x, y=y, height=h, width=w)
        
        tree = control
        tree["columns"]=("one","two","three")
        tree['show'] = 'headings'
        tree.column("#0", width=50, minwidth=50, stretch=tk.NO)
        tree.column("one", width=50, minwidth=50, stretch=tk.NO)
        tree.column("two", width=50, minwidth=50, stretch=tk.NO)
        tree.column("three", width=50, minwidth=50, stretch=tk.NO)
        
        tree.heading(0, text ="Foo") 
        tree.heading(1, text ="Bar") 
        tree.heading(2, text ="Baz")
        
        id = tree.insert("", 'end', "test", text ="test1",  values =("a", "b", "c")) 
        tree.insert("", '0', "test2", text ="test2",  values =("a", "b", "c")) 
        tree.insert("", 'end', "test3", text ="test3",  values =("a", "b", "c")) 
        tree.insert(id, 'end', "test4", text ="test4",  values =("a", "b", "c")) 
        
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    )
        controls.update({t.name:t})

        control.bind( "<Button-1>", makeCmdNew(t))
        return t
    def _makeLink(self, t, variables):
        x,y,w,h = variables
        control = tkDave.Link(self.getTab(self), text=t.text, borderwidth=1, background="white", relief="solid")
        control.config(fg=config.colors.link, borderwidth=0)
        control.setHoverColor(hoverforeground=config.colors.linkHover)
        control.place(x=x, y=y)
        
        def setFont(fontName="Verdana", size=12):
            control.config(font=(fontName, size))
            t.update()
        def setText(text):
            control.config(text=text)
        def setJustify(j):
            t = {
                "left":tk.LEFT,
                "right":tk.RIGHT
                }
            control.config(justify=t.get(j, tk.LEFT))
        
        try:
            d = os.path.dirname(sys.modules["cursors"].__file__)
            f = os.path.join(d, "LinkSelect.cur").replace("\\","/")
            control.config(cursor="@"+f)
        except:
            print('nope')
            pass
        
        control.setUrl(t.url)
        
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    setText = setText,
                    setFont = setFont,
                    setJustify = setJustify,
                    url = t.url
                    )
        
        controls.update({t.name:t})

        #if t.name: control.bind( "<Button-1>", makeCmdNew(t))
        return t

    def makeLabel(self, t, variables):
        x,y,w,h = variables
        
        control = tkDave.Label(self.getTab(self), text=t.text, borderwidth=0, background="white", relief="solid")
        control.config(fg=config.colors.fg, bg=config.colors.bk2)
        
        if t.clear:
            control.config(fg=config.colors.fg, bg=config.colors.bk, borderwidth=0)
        if t.clear:
            control.place(x=x, y=y)
        else:
            control.place(x=x, y=y, height=h, width=w)
        
        def setFont(fontName="Verdana", size=12):
            control.config(font=(fontName, size))
            t.update()
        def setText(text):
            control.config(text=text)
        def setJustify(j="left"):
            t = {
                "left":tk.LEFT,
                "right":tk.RIGHT
                }
            control.config(justify=t.get(j, tk.LEFT))
            control.place()
        
        #tkDave.make_draggable(control)
        
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    setText = setText,
                    setFont = setFont,
                    setJustify = setJustify,
                    )
        
        controls.update({t.name:t})

        if t.name: control.bind( "<Button-1>", makeCmdNew(t))
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
            cell.mousePressEvent = makeCmdNew(t2)
        
        controlsNew.update({ctrl.name:ctrl})
        return ctrl
    def makePaletteControl(self, t, variables):
        x,y,w,h = variables

        pw=len(t.palette) %0x10+1
        ph=math.floor(len(t.palette) /0x10)+1
        
        w=coalesce(t.cellWidth, 30)
        h=coalesce(t.cellHeight, 30)
        
        control = tk.Frame(self.getTab(self), width=pw*(w+1)+1, height=ph*(h+1)+1, name="_{0}_frame".format(t.name))
        
        control.place(x=t.x,y=t.y)
        
        control.cellNum = 0
        
        
        def cellClick(ev):
            control.cellNum = ev.widget.index
            ev.index = ev.widget.index
            #control.cellEvent = ev
            
            # This stuff is just taking a ride on the event
            # but will be on the main table
            ev.extra = dict(cellEvent = ev, cellNum = ev.widget.index)
            
            ev.widget.parent.cmd(ev)
        
        def highlight(highlight=False):
            if highlight:
                control.config(bg=config.colors.fg)
            else:
                control.config(bg=config.colors.bk)
        #t.name="Palette"
        control.allCells = []
        for y in range(0,ph):
            for x in range(0,pw):
                i=y*0x10+x
                bg = "#{0:02x}{1:02x}{2:02x}".format(t.palette[i][1],t.palette[i][2],t.palette[i][3])
        
                n="{0}_{1:02x}".format(t.name,i)
                
                # These values are the first white text of each row
                fg = 'white' if x>=(0x00,0x01,0x0d,0x0e)[y] else 'black'
                
                if cfg.getValue("main","upperhex")==1:
                    l = tk.Label(control, text="{0:02X}".format(t.palette[i].index), borderwidth=0, bg=bg, fg=fg, relief="solid")
                else:
                    l = tk.Label(control, text="{0:02x}".format(t.palette[i].index), borderwidth=0, bg=bg, fg=fg, relief="solid")
                
                l.place(x=1+x*(w+1), y=1+y*(h+1), height=h, width=w)
                
                l.bind("<Button>", cellClick)
                
                l.index=i
                l.parent = control
                
                controls.update({n:l})
                controls[n].update()
                control.allCells.append(l)
        self.x = t.x+pw*(w+1)+1
        self.y = t.y+ph*(h+1)+1
        self.w=pw*(w+1)+1
        self.h=ph*(h+1)+1
        def set(index, p):
            changed = False
            cell = control.allCells[index]
            colorIndex = p
            
            # These values are the first white text of each row
            fg = 'white' if (colorIndex % 16)>=(0x00,0x01,0x0d,0x0e)[math.floor(colorIndex/16)] else 'black'
            
            c = '#{0:02x}{1:02x}{2:02x}'.format(nesPalette[colorIndex][0],nesPalette[colorIndex][1],nesPalette[colorIndex][2])
            
            text="{0:02x}".format(colorIndex)
            if cfg.getValue("main","upperhex")==1:
                text=text.upper()
            if cell['text'] != text:
                changed = True
            cell.config(bg=c, fg=fg, text=text)
            return changed
        def setAll(p):
            changed = False
            for i, cell in enumerate(control.allCells):
                colorIndex = p[i+1]
                
                # These values are the first white text of each row
                fg = 'white' if (colorIndex % 16)>=(0x00,0x01,0x0d,0x0e)[math.floor(colorIndex/16)] else 'black'
                
                c = '#{0:02x}{1:02x}{2:02x}'.format(nesPalette[colorIndex][0],nesPalette[colorIndex][1],nesPalette[colorIndex][2])
                text="{0:02x}".format(colorIndex)
                if cfg.getValue("main","upperhex")==1:
                    text=text.upper()

                if cell['text'] != text:
                    changed = True
                cell.config(bg=c, fg=fg, text=text)
            return changed
        def setAllRGB(p):
            base = 0
            if not p[0]:
                base = 1
            for i, cell in enumerate(control.allCells):
                c = '#{0:02x}{1:02x}{2:02x}'.format(p[i+base][0],p[i+base][1],p[i+base][2])
                cell.config(bg=c)
        def getCellNum():
            return control.cellNum
        def getCellEvent():
            # This is a way to get the event for each cell from the parent frame
            print(control.cellEvent)
            control.cellEvent.index = control.cellNum
            return control.cellEvent
        
        t=lua.table(name=t.name,
                    control=control,
                    getCellNum = getCellNum,
                    getCellEvent = getCellEvent,
                    set = set,
                    setAll = setAll,
                    noParentEvent = True,
                    highlight=highlight,
                    )

        controls.update({t.name:t})

        control.cmd = makeCmdNew(t)
        control.bind( "<ButtonRelease-1>", control.cmd)
        
        return t
    def createTab(self, name, text):
        window = controls[self.window]
        if name in window.tabs:
            print('Not creating tab "{}" (already exists).'.format(name))
        else:
            tab = ttk.Frame(window.tabParent, style='new.TFrame')
            window.tabs.update({name:tab})
            window.tabParent.add(tab, text=text)
            window.tabParent.pack(expand=1, fill='both')
    def selectTab(self, tab):
        window = self.getWindow(self)
        window.tabParent.select(list(window.tabs).index(tab))
        print(list(window.tabParent.tabs))
    def makeTab(self, name, text):
        self.createTab(self, name, text)
    def forceClose(self):
        atexit.unregister(exitCleanup)
        sys.exit()
    def restart(self):
        app.quit()
        main.destroy()
        
        #if onExit(skipCallback=True):
        if onExit():
            print("\n"+"*"*20+" RESTART "+"*"*20+"\n")
            os.chdir(initialFolder)
            if frozen:
                subprocess.Popen(sys.argv)
            else:
                subprocess.Popen([sys.executable]+ sys.argv)
            os.system('cls')

    def setTitle(self, title=''):
        root.title(title)
        main.setWindowTitle(title)
    
# Return it from eval so we can execute it with a 
# Python object as argument.  It will then add "NESBuilder"
# to Lua
ForLua.decorate(ForLua)
lua_func = lua.eval('function(o) {0} = o return o end'.format('NESBuilder'))
lua_func(ForLua)

lua_func = lua.eval('function(o) {0} = o return o end'.format('nesPalette'))
lua_func(lua.table(nesPalette))

def coalesce(*arg): return next((a for a in arg if a is not None), None)

def makeCmdNew(*args, extra = False):
    if not args[0].name:
        # no name specified, dont create a function
        return
    if args[0].anonymous:
        print('anon')
    if not extra:
        extra = dict()
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
    
    if ev:
        event = False
        try:
            event = dict(
                event = ev,
                button = ev.num,
                x = ev.x,
                y = ev.y,
            )
        except:
            event = dict(
                event = ev,
                x = ev.x,
                y = ev.y,
            )
        try:
            event.type = ev.type.name
        except:
            event.update(type=str(ev.type))
        
        args.event = event
    
    # doCommand is a command preprocessor thing.  If 
    # It returns true then it moves on to name_command
    # if it exists, or name_cmd otherwise.
    lua_func = lua.eval("""function(o)
        local status=true
        if doCommand then status = doCommand(o) end
        if status then
            if {0}_command then
                {0}_command(o)
            elseif {0}_cmd then
                {0}_cmd(o)
            end
        end
    end""".format(args.name))
    try:
        lua_func(args)
    except LuaError as err:
        handleLuaError(err)

def onExit(skipCallback=False):
    print('onExit')
    exit = True
    if (not skipCallback) and lua.eval('type(onExit)') == 'function':
        exit = not lua.eval('onExit()')
    if exit:
        exitCleanup()
        app.quit()
        return true

main.onClose = onExit

def exitCleanup():
    x = max(0, main.x())
    y = max(0, main.y())
    w = max(500, main.width)
    h = max(400, main.height)
    
    if w>=500 and h>=400 and x>0 and y>0:
        cfg.setValue('main','x', x)
        cfg.setValue('main','y', y)
        cfg.setValue('main','w', w)
        cfg.setValue('main','h', h)
    cfg.save()

# run function on exit
atexit.register(exitCleanup)

ctrl = QtDave.TabWidget(main)
main.tabParent = ctrl
t = lua.table(name = main.name+"tabs", y=main.menuBar().height(), control=ctrl)
ctrl.init(t)
ctrl.mousePressEvent = makeCmdNew(t)

main.tabParent.currentChanged.connect(makeCmdNoEvent(t))


#root = tk.Tk()
root = tkDave.Tk()

# hide the window until it's ready
root.withdraw()
root.protocol( "WM_DELETE_WINDOW", onExit )
root.iconbitmap(sys.executable)

if not frozen:
    photo = ImageTk.PhotoImage(file = fixPath2("icon.ico"))
    root.iconphoto(False, photo)

tab_parent = ttk.Notebook(root)

windows={}

tab_parent.pack(expand=1, fill='both')

var = tk.IntVar()
def on_click():
    print(var.get())

style = ttk.Style()
style.configure('new.TFrame')


def handleLuaError(err):
    err = str(err).replace('error loading code: ','')
    err = err.replace('[string "<python>"]',"[main.lua]")
    err = err.replace('[C]',"[lua]")
    err = err.replace("stack traceback:","\nstack traceback:")
    #err = '\n'.join(textwrap.wrap(err, width=70))
    #err = textwrap.indent(err, " "*4)
    
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
    
    print("-"*80)
    print("LuaError:\n")
    print(err)
    print()
    print("-"*80)

lua.execute("True, False = true, false")
lua.execute("len = function(item) return NESBuilder:getLen(item) end")

gotError = False

try:
    if len(sys.argv)>1:
        # use file specified in argument
        f = open(sys.argv[1],"r")
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

style.configure('new.TFrame', background=config.colors.bk, fg=config.colors.fg)

config.title = config.title or "SpideyGUI"
root.title(config.title)
root.configure(bg=config.colors.bk)
root.tk_setPalette(config.colors.tkDefault)

main.setWindowTitle(config.title)

t=lua.table(name="Main",
            control=root,
            tabParent=tab_parent,
            tabs={},
            tab="Main",
            )
controls.update({"Main":t})
windows.update({"Main":t})

t2=lua.table(name="onTabChanged",
            control=tab_parent,
            window = t,
            tab = lambda:list(t.tabs)[tab_parent.index("current")]
            )

root.bind("<<NotebookTabChanged>>", makeCmdNew(t2))

print("This console is for debugging purposes.\n")

try:
    lua.execute("if init then init() end")
except LuaError as err:
    print("*** init() Failed")
    handleLuaError(err)

lua.execute("plugins = {}")

# load lua plugins
if cfg.getValue("main","loadplugins"):
    folder = config.pluginFolder
    folder = fixPath(script_path + "/" + folder)
    if os.path.exists(folder):
        lua.execute("""
        local _plugin
        """)
        for file in os.listdir(folder):
            if file.endswith(".lua") and not file.startswith("_"):
                print("Loading plugin: "+file)
                code = """
                    NESBuilder:setWorkingFolder()
                    _plugin = require("{0}.{1}")
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
try:
    lua.execute("if onReady then onReady() end")
except LuaError as err:
    print("*** onReady() Failed")
    handleLuaError(err)

w = cfg.getValue('main', 'w', default=coalesce(config.width, 800))
h = cfg.getValue('main', 'h', default=coalesce(config.height, 800))

x,y = cfg.getValue('main', 'x'), cfg.getValue('main', 'y')
if x and y:
    root.geometry("{0}x{1}+{2}+{3}".format(w,h, x,y))
else:
    root.geometry("{0}x{1}".format(w,h))

main.setGeometry(x,y,w,h)

s = pkgutil.get_data('include', 'style.qss').decode('utf8')
r = dict(
    bk=config.colors.bk,
    bk2=config.colors.bk2,
    bk3=config.colors.bk3,
    bk4=config.colors.bk4,
    bkMenuHighlight=config.colors.bk_menu_highlight,
    menuBk=config.colors.menuBk,
    fg=config.colors.fg,
    borderLight=config.colors.borderLight,
    borderDark=config.colors.borderDark,
    bkHover=config.colors.bk_hover,
    link=config.colors.link,
    linkHover=config.colors.linkHover,
)
for (k,v) in r.items():
    s = s.replace("_"+k+"_", v)

app.setStyleSheet(s)

if not frozen:
    main.setIcon(fixPath2('icon.ico'))


controlsNew.update({main.name:main})

main.show()
app.mainloop()


