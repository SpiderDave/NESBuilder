# needs lupa, pyinstaller, pillow, anything else?
'''
ToDo:
    * use @makeControl decorator on most/all control generating methods
    * make return value of control generating methods more consistant
    * makeCanvas method
    * clean up color variable names, add more
'''
#test
import sys
import lupa
from lupa import LuaRuntime
lua = LuaRuntime(unpack_returned_tuples=True)

from tkinter import filedialog
from tkinter import messagebox
from tkinter import messagebox as msg
import tkinter as tk
from tkinter import ttk
from tkinter import *
#from tkinter.ttk import *
from PIL import ImageTk, Image, ImageDraw
from PIL import ImageOps

import numpy as np

from shutil import copyfile

#from textwrap import dedent

import math
import webbrowser

from binascii import hexlify, unhexlify

import os
script_path = os.path.dirname(os.path.abspath( __file__ ))

import importlib
#mod = importlib.import_module(testName)
#mod.HelloWorld()

# import our include folder
import include 

# Handle exporting some stuff from python scripts to lua
include.init(lua)


frozen = (getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'))

controls={}

tab1=None
tab2=None
tab3=None

color_bk='#202036'
color_bk2='#303046'
color_bk3='#404050' # text background
color_bk_hover='#454560'
color_fg = '#eef'
color_bk_menu_highlight='#606080'

import pkgutil

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


class Text(tk.Text):
    def setText(self, text):
        self.clear()
        self.insert(tk.END, text)

    def clear(self):
        self.delete("1.0", tk.END)

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


    # decorator
    def makeControl(func):
        def inner(t):
            this=ForLua
            if this.direction.lower() in ("v","vertical"):
                x=coalesce(t.x, this.x, 0)
                y=coalesce(t.y, this.y+this.h, 0)
            else:
                x=coalesce(t.x, this.x+this.w, 0)
                y=coalesce(t.y, this.y, 0)
            w=coalesce(t.w, this.w, 16)
            h=coalesce(t.h, this.h, 16)
            this.x=x
            this.y=y
            this.w=w
            this.h=h

            t = func(t, (x,y,w,h,this))
            
            return t
        return inner

    def numberToBitArray(self, n):
        return [int(x) for x in "{:08b}".format(n)]
    def bitArrayToNumber(self, l):
        return int("".join(str(x) for x in l), 2) 
    def askyesnocancel(self, title, message):
        q = messagebox.askyesnocancel(title, message)
        print(q)
        return q
        #return messagebox.askyesnocancel(title, message)
    def messageBox(self, title, message):
        return messagebox.askyesno(title, message)
    def incLua(n):
        filedata = pkgutil.get_data( 'include', n+'.lua' )
        return lua.execute(filedata)
    def getTab(tab=None):
        return tabs.get(coalesce(tab, ForLua.tab))
    def setDirection(d):
        ForLua.direction=d
    def setTab(tab):
        ForLua.tab=tab
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
        this=ForLua
        m = importlib.import_module(mod)
        setattr(this, f, getattr(m, f))
        
        
        #return getattr(this,f)
        return getattr(m,f)
        
    def _levelExtract(self, f, out):
        LevelExtract(f,os.path.join(script_path, out))
    def copyfile(self, src,dst):
        copyfile(src,dst)
    def saveCanvasImage(self, f='test.png'):
        pass
        #canvas.im.save(f,"PNG")
        #grabcanvas=ImageGrab.grab(bbox=canvas)
        #.save("test.png")
        #ttk.grabcanvas.save("test.png")

        #print("loadImageToCanvas: {0}".format(f))
#        Image.save(
#        canvas.image.save(f)
        #canvas.create_image(2, 2, image=canvas.image, anchor=NW)
        #canvas.to_file(f)
    def loadImageToCanvas(self, f):
        print("loadImageToCanvas: {0}".format(f))
        try:
            with Image.open(f) as im:
                px = im.load()
            displayImage = ImageOps.scale(im, 3.0, resample=Image.NEAREST)
            canvas.image = ImageTk.PhotoImage(displayImage)
            canvas.create_image(0, 0, image=canvas.image, anchor=NW)
            canvas.configure(highlightthickness=0, borderwidth=0)
        except:
            print("error loading image")
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
    def makeTable(self, t):
        print(t)
        t = lua.table(t)
        return t
    def imageToCHR(self, f, outputfile="output.chr", colors=False):
        this = ForLua
        print('imageToCHR')
        data = this.imageToCHRData(self, f, colors)
        
        print('Tile data written to {0}.'.format(outputfile))
        f=open(outputfile,"wb")
        f.write(bytes(data))
        f.close()
        
    def imageToCHRData(self, f, colors=False):
        this = ForLua
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
        
        # return a string for easy serialiaztion
        #ret = ''.join([chr(x) for x in out])
        
        #ret = lua.table(out)
        ret = lua.table_from(out)
        
        return ret
    
    def getFileData(self, f=None):
        file=open(f,"rb")
        #file.seek(0x1000)
        fileData = file.read()
        file.close()
        
        return list(fileData)

    def loadCHRFile(self, f='chr.chr', colors=(0x0f,0x21,0x11,0x01)):
        this=ForLua
        
        file=open(f,"rb")
        #file.seek(0x1000)
        fileData = file.read()
        file.close()
        
        fileData = list(fileData)
        
        ret = this.loadCHRData(self,fileData,colors)
        return ret

    def loadCHRData(self, fileData=False, colors=(0x0f,0x21,0x11,0x01)):
        this=ForLua
        
        if not fileData:
            fileData = "\x00" * 0x1000
        
        if type(fileData) is str:
            fileData = [ord(x) for x in fileData]
        elif lupa.lua_type(fileData)=="table":
            #fileData = [fileData[x] for x in fileData]
            fileData = list([fileData[x] for x in fileData])
            
        # convert and re-index lua table
        if lupa.lua_type(colors)=="table":
            colors = [colors[x] for x in colors]
        
        img=Image.new("RGB", size=(256,256))
        
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
        
        # return a string for easy serialiaztion
        #ret = ''.join([chr(x) for x in fileData])
        
        #ret = lua.table(fileData)
        ret = lua.table_from(fileData)
        
        photo = ImageTk.PhotoImage(ImageOps.scale(img, 3.0, resample=Image.NEAREST))
        
        canvas.chrImage = photo # keep a reference
        
        canvas.create_image(0,0, image=photo, state="normal", anchor=NW)
        canvas.configure(highlightthickness=0, borderwidth=0)
        
        return ret
    def Quit():
        onExit()
    def exec(s):
        exec(s)
    def eval(s):
        # store the eval return value so we can pass return value to lua space.
        exec('ForLua.execRet = {0}'.format(s))
        return ForLua.execRet
    def getControl(n):
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
        
    def makeButton(t):
        this=ForLua
        if this.direction.lower() in ("v","vertical"):
            x=coalesce(t.x, this.x, 0)
            y=coalesce(t.y, this.y+this.h, 0)
        else:
            x=coalesce(t.x, this.x+this.w, 0)
            y=coalesce(t.y, this.y, 0)
        w=coalesce(t.w, this.w, 16)
        h=coalesce(t.h, this.h, 16)
        this.x=x
        this.y=y
        this.w=w
        this.h=h

        #w=20
        h=1

        i=5
        b = HoverButton(this.getTab(), text=t.text, activebackground=color_bk2, activeforeground=color_fg, takefocus = 0)
        b.config(width=w, height=h, fg=color_fg, bg=color_bk2)
        b.place(x=t.x, y=t.y)
        #b.place(width=w, height=h)

        controls.update({t.name:b})
        controls[t.name].update() # make sure things like winfo_height return the value we want
        c=controls[t.name]
        control = c
        #return {"control":c,"height":c.winfo_height(), "width":c.winfo_width()}

        t=lua.table(name=t.name,
                    control=control,
                    height=c.winfo_height(),
                    width=c.winfo_width(),
                    )
        
        control.bind( "<ButtonRelease-1>", makeCmdNew(t))
        
        return t


    def setText(c,txt):
        c.setText(txt)
    def makeList(t):
        this=ForLua
        if this.direction.lower() in ("v","vertical"):
            x=coalesce(t.x, this.x, 0)
            y=coalesce(t.y, this.y+this.h, 0)
        else:
            x=coalesce(t.x, this.x+this.w, 0)
            y=coalesce(t.y, this.y, 0)
        w=coalesce(t.w, this.w, 16 * 10)
        h=coalesce(t.h, this.h, 16)
        this.x=x
        this.y=y
        this.w=w
        this.h=h

        control = tk.Listbox(this.getTab())
        control.config(fg=color_fg, bg=color_bk2)
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
        
        # This is a lua table used for the callback and
        # also as a return value for this method.
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
    def makeText(t):
        this=ForLua
        
        #b = tk.Text(this.getTab(), borderwidth=1, relief="solid",height=t.lineHeight,width=t.lineWidth)
        b = Text(this.getTab(), borderwidth=0, relief="solid",height=t.lineHeight)
        b.config(fg=color_fg, bg=color_bk3)
        
        if this.direction.lower() in ("v","vertical"):
            x=coalesce(t.x, this.x, 0)
            y=coalesce(t.y, this.y+this.h, 0)
        else:
            x=coalesce(t.x, this.x+this.w, 0)
            y=coalesce(t.y, this.y, 0)
        w=coalesce(t.w, this.w, 16)
        h=coalesce(t.h, this.h, 16)
        this.x=x
        this.y=y
        this.w=w
        this.h=h
        
        b.insert(tk.END, t.text)
        #b.place(x=x, y=y, height=h, width=w)
        b.place(x=x, y=y)
        if not t.lineHeight:
            b.place(height=h)
        b.place(width=w)
        
        
        b.bind( "<Button-1>", makeCmd(t.name, {'foo':42}))
        controls.update({t.name:b})
        controls[t.name].update()
        c=controls[t.name]
        return controls[t.name]
    
    @makeControl
    def makeLabel(t, variables):
        x,y,w,h,this = variables
        
        b = tk.Label(this.getTab(), text=t.text, borderwidth=1, background="white", relief="solid")
        b.config(fg=color_fg, bg=color_bk2)
        if t.clear:
            b.config(fg=color_fg, bg=color_bk, borderwidth=0)
        if t.clear:
            b.place(x=x, y=y)
        else:
            b.place(x=x, y=y, height=h, width=w)
        
        
        control=b
        
        # This is a lua table used for the callback and
        # also as a return value for this method.
        t=lua.table(name=t.name,
                    control=control,
                    )
        
        controls.update({t.name:t})
        control.bind( "<Button-1>", makeCmdNew(t))
        return t
        
    def _makeLabel(t):
        this=ForLua
        
        #b = tk.Label(root, text=t.text, borderwidth=1, background="white", relief="solid")
        b = tk.Label(this.getTab(), text=t.text, borderwidth=1, background="white", relief="solid")
        #b.config(fg="red", bg="blue")
        b.config(fg=color_fg, bg=color_bk2)
        
        if t.clear:
            b.config(fg=color_fg, bg=color_bk, borderwidth=0)
        
        #l1 = Label(root, text="This", borderwidth=2, relief="groove")
        
        if this.direction.lower() in ("v","vertical"):
            x=coalesce(t.x, this.x, 0)
            y=coalesce(t.y, this.y+this.h, 0)
        else:
            x=coalesce(t.x, this.x+this.w, 0)
            y=coalesce(t.y, this.y, 0)
        w=coalesce(t.w, this.w, 16)
        h=coalesce(t.h, this.h, 16)
        this.x=x
        this.y=y
        this.w=w
        this.h=h
        
        
        if t.clear:
            b.place(x=x, y=y)
        else:
            b.place(x=x, y=y, height=h, width=w)
        
        b.bind( "<Button-1>", makeCmd(t.name, {'foo':42}))
        controls.update({t.name:b})
        controls[t.name].update()
        c=controls[t.name]
        return controls[t.name]
    def makePaletteControl(t):
        this=ForLua

        pw=len(t.palette) %0x10+1
        ph=math.floor(len(t.palette) /0x10)+1
        
        w=coalesce(t.cellWidth, 30)
        h=coalesce(t.cellHeight, 30)
        
        control = tk.Frame(this.getTab(), width=pw*(w+1)+1, height=ph*(h+1)+1, name="_{0}_frame".format(t.name))
        control.place(x=t.x,y=t.y)
        
        control.cellNum = 0
        
        def cellClick(ev):
            control.cellNum = ev.widget.index
            ev.index = ev.widget.index
            #control.cellEvent = ev
            
            print(ev)
            
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
                #print(n)
                control.allCells.append(l)
        this.x = t.x+pw*(w+1)+1
        this.y = t.y+ph*(h+1)+1
        this.w=pw*(w+1)+1
        this.h=ph*(h+1)+1
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
        
        # This is a lua table used for the callback and
        # also as a return value for this method.
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
    def setTitle(self, title=''):
        root.title(title)



# Return it from eval so we can execute it with a 
# Python object as argument.  It will then add "Python"
# to Lua
lua_func = lua.eval('function(o) {0} = o return o end'.format('Python'))
lua_func(ForLua)


lua_func = lua.eval('function(o) {0} = o return o end'.format('nesPalette'))
lua_func(lua.table(nesPalette))


#lua.execute("if init then init() end")

def coalesce(*arg): return next((a for a in arg if a is not None), None)


def makeCmd(buttonName, *args):
    if args and (type(args[0]) is dict):
        #return lambda *x:doCommand(buttonName, args.update(x))
        return lambda *x:doCommand(buttonName, x,args)
    return lambda *x:doCommand(buttonName, x)

def makeCmdNew(*args):
    return lambda x:doCommandNew(args, ev = x)

# a single lua table is passed
def doCommandNew(*args, ev=False):
    args = args[0][0]
    try:
        for k,v in ev.extra.items():
            args[k]=v
        ev.extra = False
    except:
        pass
    args.event = ev # store the event in the table
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

#    print("if doCommand then doCommand('{0}',Python.getControl('{0}'),{1}) end".format(ctrl,a))
#    print("if {0}_command then {0}_command('{0}',Python.getControl('{0}'),{1}) end".format(ctrl,a))
#    print("if {0}_cmd then {0}_cmd('{0}',Python.getControl('{0}'),{1}) end".format(ctrl,a))


    lua.execute("if doCommand then doCommand('{0}',Python.getControl('{0}'),{1}) end".format(ctrl,a))
    lua.execute("if {0}_command then {0}_command('{0}',Python.getControl('{0}'),{1}) end".format(ctrl,a))
    lua.execute("if {0}_cmd then {0}_cmd('{0}',Python.getControl('{0}'),{1}) end".format(ctrl,a))
def onExit():
    if lua.eval('type(onExit)') == 'function':
        if lua.eval('onExit()') != True:
            root.destroy()
    else:
        root.destroy()

#def test():
#    redbutton['text']="foobar"

def hello():
    pass


root = Tk()
#root.geometry("{0}x{1}".format(coalesce(config.width, 800), coalesce(config.height, 400)))
root.protocol( "WM_DELETE_WINDOW", onExit )
root.configure(bg=color_bk)
root.iconbitmap(sys.executable)
root.title("Some sort of tool 1.0")

if not frozen:
    photo = ImageTk.PhotoImage(file = "icon.ico")
    root.iconphoto(False, photo)

tab_parent = ttk.Notebook(root)

s = ttk.Style()
s.configure('new.TFrame', background=color_bk)

tabLaunch = ttk.Frame(tab_parent, style='new.TFrame')
tab1 = ttk.Frame(tab_parent, style='new.TFrame')
tab2 = ttk.Frame(tab_parent, style='new.TFrame')
tab3 = ttk.Frame(tab_parent, style='new.TFrame')
tabs={'Launch':tabLaunch,'Main':tab1,'Palette':tab2,'Image':tab3}

tab_parent.add(tabLaunch, text="Launcher")
tab_parent.add(tab1, text="Main")
tab_parent.add(tab2, text="Palette")
tab_parent.add(tab3, text="CHR")
tab_parent.pack(expand=1, fill='both')

menubar = Menu(root)

filemenu = Menu(menubar, tearoff=0)
filemenu.add_command(label="Open Project", command=lambda: doCommand("Open"))
filemenu.add_command(label="Save Project", command=lambda: doCommand("Save"))
filemenu.add_command(label="Build Project", command=lambda: doCommand("Build"))
filemenu.add_separator()
filemenu.add_command(label="Exit", command=lambda: doCommand("Quit"))
menubar.add_cascade(label="File", menu=filemenu)

editmenu = Menu(menubar, tearoff=0)
editmenu.add_command(label="Cut", command=lambda: doCommand("Cut"))
editmenu.add_command(label="Copy", command=lambda: doCommand("Copy"))
editmenu.add_command(label="Paste", command=lambda: doCommand("Paste"))
menubar.add_cascade(label="Edit", menu=editmenu)

helpmenu = Menu(menubar, tearoff=0)
helpmenu.add_command(label="About", command=lambda: doCommand("About"))
menubar.add_cascade(label="Help", menu=helpmenu)

for item in (filemenu,editmenu,helpmenu):
    item.config(bg=color_bk2,fg=color_fg, activebackground=color_bk_menu_highlight)

filemenu["borderwidth"] = 0

root.config(menu=menubar)

# create a popup menu
menu = Menu(root, tearoff=0)
menu.add_command(label="Undo", command=hello)
menu.add_command(label="Redo", command=hello)

def popup(event):
    #menu.post(event.x_root, event.y_root)
    messagebox.showerror("Error", "Computer says no.")

#tab1.bind("<Button-3>", popup)

#filename =  filedialog.askopenfilename(initialdir = "/",title = "Select file",filetypes = (("jpeg files","*.jpg"),("all files","*.*")))
#print (filename)


#photo = PhotoImage(file=R"file.png")

#frame = Frame(root, width=800,height=400)
#frame.pack(side = LEFT, anchor=NW)
#frame.place(x=0,y=0)

#photo = PhotoImage(file=R"1.png")
#l = Label(root, width=900-14,height=600-8,image = photo)
#l = Label(root, text="label")
#l.place(x=0,y=0)

class HoverButton(tk.Button):
    def __init__(self, master, **kw):
        tk.Button.__init__(self,master=master,**kw)
        self.defaultBackground = self["background"]
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)

    def on_enter(self, e):
        #self['background'] = self['activebackground']
        self['background'] = color_bk_hover

    def on_leave(self, e):
        #self['background'] = self.defaultBackground
        self['background'] = color_bk2
        

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


#from PIL import Image
#with Image.open('hopper.jpg') as im:
#    px = im.load()
#print (px[4,4])
#px[4,4] = (0,0,0)
#print (px[4,4])


#canvas = Canvas(tab3, width=300, height=300, bg='black')
canvas = Canvas(tab3, width=1, height=1, bg='black',name="canvas")
#c.bind("<Button-1>", makeCmd(t.name, {'foo':42}))
# store x and y so we can use them to place when image is loaded
canvas.place(x=8,y=8, width=128*3, height=128*3)

control=canvas
t=lua.table(name="canvas",
            control=control,
            )
control.bind( "<ButtonPress-1>", makeCmdNew(t))

canvas.config(cursor="top_left_arrow")

try:
    canvas.config(cursor="@cursors/pencil.cur")
except:
    try:
        canvas.config(cursor="@_cursors/pencil.cur")
    except:
        pass



try:
    f = open("main.lua","r")
    lua.execute(f.read())
    f.close()
except:
    print("Error: Could not open/execute main.lua")
    sys.exit()

config  = lua.eval('config or {}')
config.title = config.title or "SpideyGUI"
root.title(config.title)

#image = Image.open("logo.png")
#logo = ImageTk.PhotoImage(image)

#b = tk.Label(tabs.get('Launch'), text='???', borderwidth=1, background="white", relief="solid", image = logo)
#b.image = logo # keep a reference!
#b.place(x=8, y=8)

b = tk.Label(tabs.get('Launch'), text=config.title, borderwidth=0, foreground=color_fg, background=color_bk)
b.config(font=(False, 24))
b.place(x=8, y=8)

if config.launchText:
    txt = config.launchText.strip()
    b = tk.Label(tabs.get('Launch'), text=txt, borderwidth=0, foreground=color_fg, background=color_bk, justify=tk.LEFT)
    b.config(font=("Verdana", 12))
    b.place(x=8, y=48)

print("This console is for debugging purposes.\n")

lua.execute("if init then init() end")

# load lua plugins
dir = config.pluginFolder
dir = fixPath(script_path + "/" + dir)
if os.path.exists(dir):
    lua.execute("""
    local _plugin
    """)
    for file in os.listdir(dir):
        if file.endswith(".lua") and not file.startswith("_"):
            print("Loading plugin: "+file)

            code = """
                _plugin = require("{0}.{1}")
                if type(_plugin) =="table" then
                    plugins[_plugin.name or "{1}"]=_plugin
                    _plugin.file = "{2}"
                end
            """.format(config.pluginFolder,os.path.splitext(file)[0], file)
            #print(fancy(code))
            lua.execute(code)
    lua.execute("if onPluginsLoaded then onPluginsLoaded() end")
root.geometry("{0}x{1}".format(coalesce(config.width, 800), coalesce(config.height, 400)))
root.mainloop()