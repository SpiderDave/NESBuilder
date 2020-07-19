# needs lupa, pyinstaller, pillow, anything else?

import sys
import lupa
from lupa import LuaRuntime
lua = LuaRuntime(unpack_returned_tuples=True)

from tkinter import filedialog
from tkinter import messagebox
import tkinter as tk
from tkinter import ttk
from tkinter import *
#from tkinter.ttk import *
from PIL import ImageTk, Image
from PIL import ImageOps

import math
import webbrowser

import os
script_path = os.path.dirname(os.path.abspath( __file__ ))

import importlib
#mod = importlib.import_module(testName)
#mod.HelloWorld()

controls={}

tab1=None
tab2=None
tab3=None

color_bk='#202036'
color_bk2='#303046'
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


class Text(tk.Text):
    def setText(self, text):
        self.clear()
        self.insert(tk.END, text)

    def clear(self):
        self.delete("1.0", tk.END)

# Make stuff in this class available to lua
# so we can do Python stuff rom lua.
class ForLua:
    x=0
    y=0
    w=16
    h=16
    direction="v"
    tab="Main"
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
    def loadImageToCanvas(self, f):
        print("loadImageToCanvas: {0}".format(f))
        
        try:
        
            with Image.open(f) as im:
                px = im.load()
    #        for y in range(5,10):
    #            for x in range(5,10):
    #                px[x,y] = (255,255,255)

            displayImage = ImageOps.scale(im, 3.0, resample=Image.NEAREST)

            #canvas.image = ImageTk.PhotoImage(file=f) # Keep a reference
            canvas.image = ImageTk.PhotoImage(displayImage)
            canvas.create_image(0, 0, image=canvas.image, anchor=NW)
            canvas.configure(highlightthickness=0, borderwidth=0)
            #canvas.place(x=canvas.x, y=canvas.y)
        except:
            print("error loading image")

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
        w=20
        h=1

        i=5
        b = HoverButton(this.getTab(), text=t.text, command=makeCmd(t.name), activebackground=color_bk2, activeforeground=color_fg)
        b.config(width=w, height=h, fg=color_fg, bg=color_bk2)
        b.place(x=t.x, y=t.y)

        controls.update({t.name:b})
        controls[t.name].update() # make sure things like winfo_height return the value we want
        c=controls[t.name]
        return {"control":c,"height":c.winfo_height(), "width":c.winfo_width()}
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
        control.bind( "<Button-1>", makeCmd(t.name,{}))
        
        return lua.table(control=control, 
               insert=control.insert,
               append=lambda x:control.insert(tk.END,x)),
    def makeText(t):
        this=ForLua
        
        #b = tk.Text(this.getTab(), borderwidth=1, relief="solid",height=t.lineHeight,width=t.lineWidth)
        b = Text(this.getTab(), borderwidth=1, relief="solid",height=t.lineHeight,width=t.lineWidth)
        b.config(fg=color_fg, bg=color_bk2)
        
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
        
        b.insert(tk.END, t.text)
        #b.place(x=x, y=y, height=h, width=w)
        b.place(x=x, y=y)
        if not t.lineHeight:
            b.place(height=h)
        if not t.lineWidth:
            b.place(width=w)
        
        
        b.bind( "<Button-1>", makeCmd(t.name, {'foo':42}))
        controls.update({t.name:b})
        controls[t.name].update()
        c=controls[t.name]
        return controls[t.name]
    def makeLabel(t):
        this=ForLua
        
        #b = tk.Label(root, text=t.text, borderwidth=1, background="white", relief="solid")
        b = tk.Label(this.getTab(), text=t.text, borderwidth=1, background="white", relief="solid")
        #b.config(fg="red", bg="blue")
        b.config(fg=color_fg, bg=color_bk2)
        
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
        
        frame = tk.Frame(this.getTab(), width=pw*(w+1)+1, height=ph*(h+1)+1, name="_{0}_frame".format(t.name))
        frame.place(x=t.x,y=t.y)
        
        #t.name="Palette"
        for x in range(0,pw):
            for y in range(0,ph):
                i=y*0x10+x
                bg = "#{0:02x}{1:02x}{2:02x}".format(t.palette[i][1],t.palette[i][2],t.palette[i][3])
        
                n="{0}_{1:02x}".format(t.name,i)
                
                # These values are the first white text of each row
                fg = 'white' if x>=(0x00,0x01,0x0d,0x0e)[y] else 'black'
                
                if config.upperHex:
                    l = tk.Label(frame, text="{0:02X}".format(t.palette[i].index), borderwidth=0, bg=bg, fg=fg, relief="solid")
                else:
                    l = tk.Label(frame, text="{0:02x}".format(t.palette[i].index), borderwidth=0, bg=bg, fg=fg, relief="solid")
                
                l.place(x=1+x*(w+1), y=1+y*(h+1), height=h, width=w)
                
                
                
                
                l.bind("<Button>", makeCmd(t.name, {'cellNum':i,'cellName':n}))
                
                controls.update({n:l})
                controls[n].update()
                #print(n)

        this.x = t.x+pw*(w+1)+1
        this.y = t.y+ph*(h+1)+1
        this.w=pw*(w+1)+1
        this.h=ph*(h+1)+1

        # This should probably return a frame object


# Return it from eval so we can execute it with a 
# Python object as argument.  It will then add "Python"
# to Lua
lua_func = lua.eval('function(o) {0} = o return o end'.format('Python'))
lua_func(ForLua)

#lua.execute("if init then init() end")

def coalesce(*arg): return next((a for a in arg if a is not None), None)


def makeCmd(buttonName, *args):
    if args and (type(args[0]) is dict):
        #return lambda *x:doCommand(buttonName, args.update(x))
        return lambda *x:doCommand(buttonName, x,args)
    return lambda *x:doCommand(buttonName, x)

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



tab_parent = ttk.Notebook(root)

s = ttk.Style()
s.configure('new.TFrame', background=color_bk)

tab1 = ttk.Frame(tab_parent, style='new.TFrame')
tab2 = ttk.Frame(tab_parent, style='new.TFrame')
tab3 = ttk.Frame(tab_parent, style='new.TFrame')
tabs={'Main':tab1,'Palette':tab2,'Image':tab3}

tab_parent.add(tab1, text="Main")
tab_parent.add(tab2, text="Palette")
tab_parent.add(tab3, text="Image")
tab_parent.pack(expand=1, fill='both')


menubar = Menu(root)

filemenu = Menu(menubar, tearoff=0)
filemenu.add_command(label="Open", command=lambda: doCommand("Open"))
filemenu.add_command(label="Save", command=lambda: doCommand("Save"))
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
canvas = Canvas(tab3, width=1, height=1, bg='black')
#c.bind("<Button-1>", makeCmd(t.name, {'foo':42}))
# store x and y so we can use them to place when image is loaded
canvas.place(x=8,y=8, width=128*3, height=128*3)


try:
    f = open("main.lua","r")
    lua.execute(f.read())
    f.close()
except:
    print("Error: Could not open/execute main.lua")
    sys.exit()

import include # this is the include folder
config  = lua.eval('config or {}')

lua.execute("if init then init() end")

root.geometry("{0}x{1}".format(coalesce(config.width, 800), coalesce(config.height, 400)))
root.mainloop()