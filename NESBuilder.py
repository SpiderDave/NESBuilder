# needs lupa, pyinstaller, pillow, anything else?
'''
ToDo:
    * use @makeControl decorator on most/all control generating methods
    * make return value of control generating methods more consistant
    * makeCanvas method
    * clean up color variable names, add more
    * phase out controls and use controlsNew, then rename controlsNew
    * per-project plugins
'''

import os, sys, time
import lupa
from lupa import LuaRuntime
from lupa import LuaError
lua = LuaRuntime(unpack_returned_tuples=True)

from tkinter import simpledialog, filedialog, messagebox
from tkinter import EventType
import tkinter as tk
from tkinter import ttk
#from tkinter import *
#from tkinter.ttk import *
from PIL import ImageTk, Image, ImageDraw
from PIL import ImageOps
from PIL import ImageGrab
from collections import deque
import re

import textwrap

import numpy as np

from shutil import copyfile
import subprocess

#from textwrap import dedent

import math
import webbrowser

from binascii import hexlify, unhexlify

import importlib, pkgutil

# import our include folder
import include 

import configparser, atexit

# Handle exporting some stuff from python scripts to lua
include.init(lua)


true, false = True, False

script_path = os.path.dirname(os.path.abspath( __file__ ))
initialFolder = os.getcwd()

frozen = (getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'))

class Cfg(configparser.ConfigParser):
    def __init__(self):
        # do the usual init
        super().__init__()
        # can do extra stuff here
    def load(self, filename = "config.ini"):
        self.read(os.path.join(script_path, filename))
        self.filename = filename
    def save(self):
        with open(os.path.join(script_path, self.filename), 'w') as configfile:
            self.write(configfile)
    def makeSections(self, *sections):
        for section in sections:
            if not section in self.sections():
                self[section] = {}
    # Set a default value only if it doesn't already exist.
    # Also creates a section if it doesn't exist.
    def setDefault(self, section,key,value):
        if not section in self.sections():
            self[section] = {}
        if type(value) is not str:
            value = str(value)
        self.set(section, key, self[section].get(key, value))
    # Check if given string is a number, including
    # negative numbers and decimals.
    def isnumber(self, s):
        s = str(s).strip()
        if len(s)==0:
            return false
        if s[0]=='-' or s[0] == '+':
            s = s[1:]
        if s.find('.') == s.rfind('.'):
            s = s.replace('.', '')
        return s.isdigit()
    # Interprets and formats a value
    def makeValue(self, value):
        if type(value) is not str:
            return value
        if ',' in value:
            value = value.split(',')
            for k,v in enumerate(value):
                v=v.strip()
                if v.startswith('0x'):
                    value[k] = int(v, 16)
                elif v.startswith('-0x'):
                    value[k] = 0-int(v[1:], 16)
                else:
                    if self.isnumber(v):
                        if '.' in v:
                            value[k] = float(v)
                        else:
                            value[k] = int(v)
                    else:
                        value[k] = v
            return value
        else:
            value=value.strip()
            if value.startswith('0x'):
                value = int(value, 16)
            elif value.startswith('-0x'):
                value = 0-int(value[1:], 16)
            else:
                if self.isnumber(value):
                    if '.' in value:
                        value = float(value)
                    else:
                        value = int(value)
            return value
    def getValue(self, section, key, default=None):
        return self.makeValue(self[section].get(key, default))
    def setValue(self, section, key, value):
        # make sure section exists
        if not section in self.sections():
            self[section] = {}
        self.set(section, key, str(value))


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


# create our config parser
cfg = Cfg()

# read config file if it exists
cfg.load()

cfg.setDefault('main', 'stylemenus', 1)
cfg.setDefault("main", "tearoff", 0)
cfg.setDefault('main', 'project', "newProject")
#cfg.setDefault('main', 'nespalette', nesPalette)

#cfg.setDefault('foo', 'bar', 'baz')
#print(cfg.getValue('palettes', 'Mario'))
#print(cfg.getValue('offsets', 'mariopalette'))
#cfg.setValue('foo','bar','bip')
#cfg.makeSections('hello','world')

# make cfg available to lua
lua_func = lua.eval('function(o) {0} = o return o end'.format('cfg'))
lua_func(cfg)

#nesPalette = cfg.getValue('main', 'nespalette')


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

class Text(tk.Text):
    def setText(self, text):
        self.clear()
        self.insert(tk.END, text)

    def clear(self):
        self.delete("1.0", tk.END)

def pathToFolder(p):
    return fixPath2(os.path.split(p)[0])

def fixPath2(p):
    if ":" not in p:
        p = script_path+"/"+p
    return p.replace("/",os.sep).replace('\\',os.sep)
    
def fixPath(p):
    return p.replace("/",os.sep).replace('\\',os.sep)

# Make stuff in this class available to lua
# so we can do Python stuff rom lua.
class ForLua:
    x=0
    y=0
    w=16
    h=16
    direction="v"
    tab="Main"
    window="Main"
    canvas=False
    
    config = cfg
    
    # decorator
    def makeControl(func):
        def addStandardProp(t):
            def _config(cfg):
                t.control.config(dict(cfg))
#            def getEventType():
#                if not controls.get(t.name).event:
#                    return False
#                return controls.get(t.name).event.type.name
            def update():
                t.control.update()
                t.height = t.control.winfo_height()
                t.width = t.control.winfo_width()
            t.config = _config
            t.update = update
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
            
            t = func(self, t, (x,y,w,h))
            t = addStandardProp(t)
            t.control.update()
            
            t.height=t.control.winfo_height()
            t.width=t.control.winfo_width()
            
            return t
        return inner
    def decorate(self):
        decorator = lupa.unpacks_lua_table_method
        for method_name in dir(self):
            m = getattr(self, method_name)
            if m.__class__.__name__ == 'function':
                # these are control creation functions
                # makedir maketab
                makers = ['makeButton', 'makeCanvas', 'makeEntry', 'makeLabel',
                          'makeList', 'makeMenu', 'makePaletteControl', 'makePopupMenu',
                          'makeText', 'makeWindow']
                
                if method_name in makers:
                    attr = getattr(self, method_name)
                    wrapped = self.makeControl(attr)
                    setattr(self, method_name, wrapped)
                    pass
                elif method_name in ['getNESColors', 'makeControl']:
                    # getNESColors: excluded because it may have a table as its first parameter
                    # makeControl: excluded because it's a decorator
                    pass
                else:
                    #print(method_name, m.__class__)
                    if method_name.startswith('make') and method_name not in ['makeDir', 'makeTab']:
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
    def pathExists(self, f):
        f = fixPath(script_path+"/"+f)
        return os.path.exists(f)
    def setWorkingFolder(self, f=""):
        workingFolder = fixPath(script_path+"/"+f)
        os.chdir(workingFolder)
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
    def showError(self, title, text):
        answer = messagebox.showerror(title, text)
        return answer
    def askText(self, title, text):
        answer = simpledialog.askstring(title, text, parent=root)
        if answer:
            answer=answer.strip()
        if answer == '': answer=None
        return answer
    def isAlphaNumeric(self, txt):
        return txt.isalnum()
    def regexMatch(self,reString, txt):
        if re.match(reString, txt):
            return True
        else:
            return None
    def askyesnocancel(self, title, message):
        q = messagebox.askyesnocancel(title, message)
        print(q)
        return q
        #return messagebox.askyesnocancel(title, message)
    def messageBox(self, title, message):
        return messagebox.askyesno(title, message)
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
    def setTab(self, tab):
        window = controls[self.window]
        window.tab = tab
        self.tab=tab
    def getCanvas(self, canvas=None):
        return controlsNew[coalesce(canvas, self.canvas)]
    def setCanvas(self, canvas):
        self.canvas = canvas
    def fileTest(self):
        filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("jpeg files","*.jpg"),("all files","*.*")))
        return filename
    def makeDir(self,dir):
        dir = fixPath(script_path + "/" + dir)
        print(dir)
        if not os.path.exists(dir):
            os.makedirs(dir)
    def openFolder(self, initial=None):
        initial = fixPath(script_path + "/" + initial)
        foldername =  filedialog.askdirectory(initialdir = initial, title = "Select folder")
        return foldername, os.path.split(foldername)[1]
    def openFile(self, filetypes, initial=None):
        types = list()
        if filetypes:
            for t in filetypes:
                types.append([filetypes[t][1],filetypes[t][2]])
        
        types.append(["All files","*.*"])
        #filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("all files","*.*"),))
        filename =  filedialog.askopenfilename(title = "Select file",filetypes = types)
        return filename
    def saveFileAs(self, filetypes, initial=None):
        types = list()
        
        if filetypes:
            for t in filetypes:
                types.append([filetypes[t][1],filetypes[t][2]])
        
        types.append(["All files","*.*"])
        filename =  filedialog.asksaveasfilename(title = "Select file",filetypes = types, initialfile=initial)
        return filename
    def importFunction(self, mod, f):
        m = importlib.import_module(mod)
        setattr(self, f, getattr(m, f))
        
        return getattr(m,f)
        
#    def _levelExtract(self, f, out):
#        LevelExtract(f,os.path.join(script_path, out))
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
    def newStack(self, arg=[]):
        stack = Stack(arg)
        return stack, stack.push, stack.pop
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
    def test(self, foo=1, bar=2):
        print(foo,bar)
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
    def loadCHRFile(self, f='chr.chr', colors=(0x0f,0x21,0x11,0x01)):
        file=open(f,"rb")
        #file.seek(0x1000)
        fileData = file.read()
        file.close()
        
        fileData = list(fileData)
        
        ret = self.loadCHRData(self,fileData,colors)
        return ret
    def newCHRData(self):
        return lua.table_from("\x00" * 0x1000)
    def loadCHRData(self, fileData=False, colors=(0x0f,0x21,0x11,0x01)):
        control = self.getCanvas(self)
        canvas = control.control
        
        if not fileData:
            fileData = "\x00" * 0x1000
        
        if type(fileData) is str:
            fileData = [ord(x) for x in fileData]
        elif lupa.lua_type(fileData)=="table":
            fileData = list([fileData[x] for x in fileData])
        
        # convert and re-index lua table
        if lupa.lua_type(colors)=="table":
            colors = [colors[x] for x in colors]
        
        img=Image.new("RGB", size=(256,256))
        
        a = np.asarray(img).copy()
        
        math.floor(len(fileData)/16)
        
        #for tile in range(256):
        for tile in range(math.floor(len(fileData)/16)):
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
    def Quit(self):
        onExit()
    def exec(self, s):
        exec(s)
    def eval(s):
        # store the eval return value so we can pass return value to lua space.
        exec('ForLua.execRet = {0}'.format(s))
        return ForLua.execRet
    def getControl(self, n):
        if not n:
            return controls
        else:
            if n in controls:
                return controls[n]
            elif "_"+n in controls:
                return controls["_"+n]
    def removeControl(c):
        controls[c].destroy()
    def hideControl(c):
        controls[c].foobar ='baz'
        x = controls[c].winfo_x()
        if x<0:
            x=x+1000
        else:
            x=x-1000
        controls[c].place(x=x)
        print(controls[c].foobar)
    def makeCanvas(self, t, variables):
        x,y,w,h = variables
        
        t.scale = t.scale or 3
        w=w*t.scale
        h=h*t.scale
        
        canvas = tk.Canvas(self.getTab(self), width=1, height=1, bg='black',name=t.name)
        canvas.place(x=x,y=y, width=w, height=h)
        control=canvas
        t=lua.table(name=t.name,
                    control=control,
                    scale=t.scale,
                    )
        
        control.bind("<ButtonPress-1>", makeCmdNew(t, extra=dict(press=True)))
        control.bind("<ButtonRelease-1>", makeCmdNew(t, extra=dict(press=False)))
        control.bind("<ButtonPress>", makeCmdNew(t))
        control.bind("<ButtonRelease>", makeCmdNew(t))
        control.bind("<B1-Motion>", makeCmdNew(t))

        canvas.config(cursor="top_left_arrow")

        try:
            canvas.config(cursor="@cursors/pencil.cur")
        except:
            try:
                canvas.config(cursor="@_cursors/pencil.cur")
            except:
                pass
        
        if not self.canvas:
            # set as default canvas
            self.setCanvas(self, t.name)
        
        controls.update({t.name:control})
        controlsNew.update({t.name:t})
        
        return t
    def makeButton(self, t, variables):
        x,y,w,h = variables

        #w=20
        h=1

        control = HoverButton(self.getTab(self), text=t.text, takefocus = 0)
        control.config(width=w, 
                       fg=config.colors.fg,
                       bg=config.colors.bk2,
                       activebackground=config.colors.bk2,
                       activeforeground=config.colors.fg
                      )
        control.place(x=t.x, y=t.y)

        controls.update({t.name:control})

        t=lua.table(name=t.name,
                    control=control,
                    )
        
        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        
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
        
        # create a popup menu
        tab = self.getTab(self)
        menu = tk.Menu(tab, tearoff=tearoff)
        
        if cfg.getValue("main","styleMenus"):
            menu.config(bg=config.colors.bk2,fg=config.colors.fg, activebackground=config.colors.bk_menu_highlight)
        
        menubar.add_cascade(label=t.text, menu=menu)

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
        
        return t
    def makeWindow(self, t, variables):
        x,y,w,h = variables
        
        if controls.get(t.name):
            # If the window already exists, bring it to the front
            # and return its table.
            t = controls.get(t.name)
            t.alreadyCreated = True
            t.control.lift()
            return t
        
        window = tk.Toplevel(root)
        window.title(t.title or "Window")
        window.geometry("{0}x{1}".format(w,h))
        
        def close():
            del controls[t.name]
            window.destroy()
        window.protocol( "WM_DELETE_WINDOW", close)
        
        tabParent = ttk.Notebook(window)
        tabs={}
        
        window.configure(bg=config.colors.bk)
        window.iconbitmap(sys.executable)
        if not frozen:
            photo = ImageTk.PhotoImage(file = fixPath2("icon.ico"))
            window.iconphoto(False, photo)
        
        control = window
        t=lua.table(name=t.name,
                    control=control,
                    tabParent=tabParent,
                    tabs=tabs,
                    close=close,
                    )
        
        controls.update({t.name:t})
        windows.update({t.name:window})
        
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
        
        control = Text(self.getTab(self), borderwidth=0, relief="solid",height=t.lineHeight)
        control.config(fg=config.colors.fg, bg=config.colors.bk3)
        
        control.insert(tk.END, t.text)
        control.place(x=x, y=y)
        if not t.lineHeight:
            control.place(height=h)
        control.place(width=w)
        
        def setText(text):
            control.delete(1.0, tk.END)
            control.insert(tk.END, text)
            
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    setText = setText,
                    )

        controls.update({t.name:t})

        #control.bind( "<Button-1>", makeCmdNew(t))
        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        control.bind( "<Return>", makeCmdNew(t))
        
        return t
    def makeEntry(self, t, variables):
        x,y,w,h = variables
        
        control = tk.Entry(self.getTab(self), borderwidth=0, relief="solid",height=t.lineHeight)
        control.config(fg=config.colors.fg, bg=config.colors.bk3)
        
        control.insert(tk.END, t.text)
        control.place(x=x, y=y)
        if not t.lineHeight:
            control.place(height=h)
        control.place(width=w)
        
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

        #control.bind( "<Button-1>", makeCmdNew(t))
        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        control.bind( "<Return>", makeCmdNew(t))
        
        return t

    def makeLabel(self, t, variables):
        x,y,w,h = variables
        
        control = tk.Label(self.getTab(self), text=t.text, borderwidth=1, background="white", relief="solid")
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
            
        def setJustify(j):
            t = {
                "left":tk.LEFT,
                "right":tk.RIGHT
                }
            control.config(justify=t.get(j, tk.LEFT))
        
        t=lua.table(name=t.name,
                    control=control,
                    height=h,
                    width=w,
                    setFont = setFont,
                    setJustify = setJustify,
                    )
        
        controls.update({t.name:t})

        control.bind( "<Button-1>", makeCmdNew(t))
        return t
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
        
        #t.name="Palette"
        control.allCells = []
        for y in range(0,ph):
            for x in range(0,pw):
                i=y*0x10+x
                bg = "#{0:02x}{1:02x}{2:02x}".format(t.palette[i][1],t.palette[i][2],t.palette[i][3])
        
                n="{0}_{1:02x}".format(t.name,i)
                
                # These values are the first white text of each row
                fg = 'white' if x>=(0x00,0x01,0x0d,0x0e)[y] else 'black'
                
                if config.upperHex:
                    l = tk.Label(control, text="{0:02X}".format(t.palette[i].index), borderwidth=0, bg=bg, fg=fg, relief="solid")
                else:
                    l = tk.Label(control, text="{0:02x}".format(t.palette[i].index), borderwidth=0, bg=bg, fg=fg, relief="solid")
                
                l.place(x=1+x*(w+1), y=1+y*(h+1), height=h, width=w)
                
                #l.bind("<Button>", makeCmd(t.name, {'cellNum':i,'cellName':n}))
                #l.bind("<Button>", cellClick)
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
            text="{0:02X}".format(colorIndex)
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
                text="{0:02X}".format(colorIndex)
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
                    )

        controls.update({t.name:t})

        #control.bind( "<Button-1>", makeCmdNew(t))
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
    def makeTab(self, name, text):
        self.createTab(self, name, text)
    def forceClose(self):
        atexit.unregister(exitCleanup)
        sys.exit()
    def restart(self):
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
    
    #m = [func for func in dir(ForLua) if callable(getattr(ForLua, func)) and not func.startswith("__")]
    #m = [func for func in dir(vars()) if callable(getattr(vars(), func)) and not func.startswith("__")]
    
#    for item in ['test', 'setTitle']:
#        vars()[item] = lupa.unpacks_lua_table_method(vars()[item])
    
    #method_list = [func for func in dir(ForLua) if callable(getattr(ForLua, func)) and not func.startswith("__")]
    #vars()['test'] = lupa.unpacks_lua_table_method(vars()['test'])
    #test = lupa.unpacks_lua_table_method(test)
    #imageToCHRData = lupa.unpacks_lua_table_method(imageToCHRData)
    
# Return it from eval so we can execute it with a 
# Python object as argument.  It will then add "NESBuilder"
# to Lua
ForLua.decorate(ForLua)
lua_func = lua.eval('function(o) {0} = o return o end'.format('NESBuilder'))
lua_func(ForLua)

lua_func = lua.eval('function(o) {0} = o return o end'.format('nesPalette'))
lua_func(lua.table(nesPalette))

def coalesce(*arg): return next((a for a in arg if a is not None), None)

def makeCmd(buttonName, *args):
    if args and (type(args[0]) is dict):
        return lambda *x:doCommand(buttonName, x,args)
    return lambda *x:doCommand(buttonName, x)

def makeCmdNew(*args, extra = False):
    if extra:
        return lambda x:doCommandNew(args, ev = x, extra = extra)
    return lambda x:doCommandNew(args, ev = x)
def makeCmdNoEvent(*args, extra = False):
    if extra:
        return lambda :doCommandNew(args, ev = lua.table(extra=extra))
    #return lambda :doCommandNew(args, ev = lua.table(test=42,extra=lua.table(config=args[0].control.config(), foobar='baz',a=1)))
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
        event = dict(
            event = ev,
            button = ev.num,
            x = ev.x,
            y = ev.y,
        )
        
        try:
            event.type = ev.type.name
        except:
            event.update(type=str(ev.type))
        
        args.event = event
    
    lua_func = lua.eval('function(o) if doCommand then doCommand(o) end end'.format(args.name))
    lua_func(args)
    lua_func = lua.eval('function(o) if {0}_command then {0}_command(o) end end'.format(args.name))
    lua_func(args)
    lua_func = lua.eval('function(o) if {0}_cmd then {0}_cmd(o) end end'.format(args.name))
    lua_func(args)

def doCommand(ctrl, *args):
    # process the tkinter event
    if args and args[0]:
        e = args[0][0]
        a = "x={0},y={1},num={2}".format(e.x, e.y, e.num)
        comma = ', '

        # merge with a passed dictionary argument
        if args[1] and args[1][0]:
            for k,v in args[1][0].items():
                # we're using repr here to wrap strings in quotes, but it will
                # fail on many circumstances.
                a=a+", {0}={1}".format(k,repr(v))
        a = "{"+a+"}"
    else:
        a = 'nil'
        comma = ''

    lua.execute("if doCommand then doCommand('{0}',NESBuilder:getControl('{0}'),{1}) end".format(ctrl,a))
    lua.execute("if {0}_command then {0}_command('{0}',NESBuilder:getControl('{0}'),{1}) end".format(ctrl,a))
    lua.execute("if {0}_cmd then {0}_cmd('{0}',NESBuilder:getControl('{0}'),{1}) end".format(ctrl,a))
def onExit(skipCallback=False):
    print('onExit')
    exit = True
    if (not skipCallback) and lua.eval('type(onExit)') == 'function':
        exit = not lua.eval('onExit()')
    if exit:
        exitCleanup()
        root.quit()
        return true

def exitCleanup():
    w,h = root.winfo_width(), root.winfo_height()
    if w==200 and h==200: return
    
    cfg.setValue('main','x', root.winfo_x())
    cfg.setValue('main','y', root.winfo_y())
    cfg.setValue('main','w', root.winfo_width())
    cfg.setValue('main','h', root.winfo_height())
    cfg.save()

# run function on exit
atexit.register(exitCleanup)

root = tk.Tk()

# hide the window until it's ready
root.withdraw()
root.protocol( "WM_DELETE_WINDOW", onExit )
root.iconbitmap(sys.executable)

if not frozen:
    photo = ImageTk.PhotoImage(file = fixPath2("icon.ico"))
    root.iconphoto(False, photo)

tab_parent = ttk.Notebook(root)

windows={'Main':root}

tab_parent.pack(expand=1, fill='both')

tearoff = cfg.getValue("main","tearoff")

menubar = tk.Menu(root)

filemenu = tk.Menu(menubar, tearoff=tearoff)
filemenu.add_command(label="New Project", command=lambda: doCommand("New"))
filemenu.add_command(label="Open Project", command=lambda: doCommand("Open"))
filemenu.add_command(label="Save Project", command=lambda: doCommand("Save"))
filemenu.add_command(label="Build Project", command=lambda: doCommand("Build"))
filemenu.add_command(label="Build Project and Test", command=lambda: doCommand("BuildTest"))
filemenu.add_separator()
filemenu.add_command(label="Exit", command=lambda: doCommand("Quit"))
menubar.add_cascade(label="File", menu=filemenu)

editmenu = tk.Menu(menubar, tearoff=tearoff)
editmenu.add_command(label="Cut", command=lambda: doCommand("Cut"))
editmenu.add_command(label="Copy", command=lambda: doCommand("Copy"))
editmenu.add_command(label="Paste", command=lambda: doCommand("Paste"))
menubar.add_cascade(label="Edit", menu=editmenu)

helpmenu = tk.Menu(menubar, tearoff=tearoff)
helpmenu.add_command(label="About", command=lambda: doCommand("About"))
menubar.add_cascade(label="Help", menu=helpmenu)

root.config(menu=menubar)

class HoverButton(tk.Button):
    def __init__(self, master, **kw):
        tk.Button.__init__(self,master=master,**kw)
        self.defaultBackground = self["background"]
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)

    def on_enter(self, e):
        self['background'] = config.colors.bk_hover

    def on_leave(self, e):
        self['background'] = config.colors.bk2
        

var = tk.IntVar()
def on_click():
    print(var.get())

#x=160
#y=0
#w=10
#b = Checkbutton(root, text="Check", command=lambda:doCommand("Check"), variable=var, onvalue=1, offvalue=0)
#b = Checkbutton(root, text="I Want Candy", command=on_click, variable=var, onvalue=1, offvalue=0, selectcolor=color_bk, activebackground=color_bk, activeforeground=color_fg)
#b.config(width=w, height=h, fg=color_fg, bg=color_bk)
#b.place(x=x, y=y)

style = ttk.Style()
style.configure('new.TFrame')

lua.execute("True, False = true, false")

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
    gotError = True

if gotError:
    sys.exit(1)
    
config  = lua.eval('config or {}')
config.title = config.title or "SpideyGUI"
root.title(config.title)
root.configure(bg=config.colors.bk)

if cfg.getValue("main","styleMenus"):
    for item in (filemenu,editmenu,helpmenu):
        item.config(bg=config.colors.bk2,fg=config.colors.fg, activebackground=config.colors.bk_menu_highlight)

style.configure('new.TFrame', background=config.colors.bk, fg=config.colors.fg)

t=lua.table(name="Main",
            control=root,
            tabParent=tab_parent,
            tabs={},
            tab="Main",
            )

controls.update({"Main":t})

print("This console is for debugging purposes.\n")

lua.execute("if init then init() end")

# load lua plugins
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
                _plugin = require("{0}.{1}")
                if type(_plugin) =="table" then
                    plugins[_plugin.name or "{1}"]=_plugin
                    _plugin.file = "{2}"
                    _plugin.name = _plugin.name or "{1}"
                end
            """.format(config.pluginFolder,os.path.splitext(file)[0], file)
            #print(fancy(code))
            lua.execute(code)
    lua.execute("if onPluginsLoaded then onPluginsLoaded() end")

w = cfg.getValue('main', 'w', default=coalesce(config.width, 800))
h = cfg.getValue('main', 'h', default=coalesce(config.height, 800))

x,y = cfg.getValue('main', 'x'), cfg.getValue('main', 'y')
if x and y:
    root.geometry("{0}x{1}+{2}+{3}".format(w,h, x,y))
else:
    root.geometry("{0}x{1}".format(w,h))


# show the window
root.deiconify()

root.mainloop()