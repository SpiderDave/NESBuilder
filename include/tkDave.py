import tkinter as tk
from tkinter import ttk, font

import math
import webbrowser


class Tk(tk.Tk):
    def __init__(self, **kw):
        super().__init__(**kw)

    def getTopWindow(self, includeRoot=True):
        def stackorder(self):
            c = self.children
            s = self.tk.eval('wm stackorder {}'.format(self))
            L = [x.lstrip('.') for x in s.split()]
            return [(c[x] if x else self) for x in L]

        L = stackorder(self)
        if includeRoot:
            return L[-1]
        else:
            return L[-2] if L[-1] is self else L[-1]

class Hover():
    def __init__(self, master, **kw):
        super().__init__(master, **kw)
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
    
    def setHoverColor(self, hoverbackground=None, hoverforeground=None):
        if hoverbackground: self.hoverbackground = hoverbackground
        if hoverforeground: self.hoverforeground = hoverforeground
    
    def on_enter(self, e):
        self['background'] = getattr(self, 'hoverbackground', self['background'])
        self['foreground'] = getattr(self, 'hoverforeground', self['foreground'])

    def on_leave(self, e):
        self['background'] = self['activebackground']
        self['foreground'] = self['activeforeground']


class Draggable():
    def __init__(self, master, **kw):
        super().__init__(master, **kw)
        self.snap = 8
        self.make_draggable(self)

    def make_draggable(self, widget):
        widget.bind("<Button-2>", self.on_drag_start)
        widget.bind("<B2-Motion>", self.on_drag_motion)
        widget.bind("<ButtonRelease-2>", self.on_drag_end)

    def on_drag_start(self, event):
        widget = event.widget
        widget._drag_start_x = event.x
        widget._drag_start_y = event.y

    def on_drag_end(self, event):
        widget = event.widget
        x = widget.winfo_x()
        y = widget.winfo_y()
        
        x=math.floor((x +self.snap/2)/self.snap)*self.snap
        y=math.floor((y +self.snap/2)/self.snap)*self.snap
        
        widget.place(x=x, y=y)

    def on_drag_motion(self, event):
        widget = event.widget
        x = widget.winfo_x() - widget._drag_start_x + event.x
        y = widget.winfo_y() - widget._drag_start_y + event.y
        widget.place(x=x, y=y)

class Label(Draggable, tk.Label): pass
class Entry(Draggable, tk.Entry): pass
class SpinBox(Draggable, tk.Spinbox): pass
class Canvas(Draggable, tk.Canvas): pass
class CheckBox(Draggable, tk.Checkbutton): pass


class Text(Draggable, tk.Text):
    def __init__(self, master, **kw):
        super().__init__(master, **kw)
    
    def setText(self, text):
        self.clear()
        self.insert(tk.END, text)
    
    def clear(self):
        self.delete("1.0", tk.END)

class Button(Draggable, tk.Button):
    def __init__(self, master, **kw):
        super().__init__(master, **kw)
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
    
    def setHoverColor(self, hoverbackground=None, hoverforeground=None):
        if hoverbackground: self.hoverbackground = hoverbackground
        if hoverforeground: self.hoverforeground = hoverforeground
    
    def on_enter(self, e):
        self['background'] = getattr(self, 'hoverbackground', self['background'])
        self['foreground'] = getattr(self, 'hoverforeground', self['foreground'])

    def on_leave(self, e):
        self['background'] = self['activebackground']
        self['foreground'] = self['activeforeground']


class ToggleButton(Hover, Label):
    def __init__(self, master, **kw):
        super().__init__(master, **kw)
        self.toggleValue = 0
        self.bind("<ButtonRelease-1>", self.toggle)
        self.configure(relief = tk.RAISED)
    def toggle(self, e):
        if getattr(self, 'toggleValue')==0:
            self.configure(relief = tk.SUNKEN)
        else:
            self.configure(relief = tk.RAISED)
        setattr(self, 'toggleValue', 1-getattr(self, 'toggleValue'))
    def getValue(self):
        return getattr(self, 'toggleValue')
    def setValue(self, v):
        setattr(self, 'toggleValue', v)
        if v==1:
            self.configure(relief = tk.SUNKEN)
        else:
            self.configure(relief = tk.RAISED)


class Link(Draggable, tk.Label):
    def __init__(self, master, **kw):
        super().__init__(master, **kw)
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
        
        try:
            s = ttk.Style()
            bg = s.lookup(master.cget('style'), 'background')
            self.configure(bg = bg)
        except:
            bg = master.cget('background')
            self.configure(bg = bg)
    
    def setHoverColor(self, hoverbackground=None, hoverforeground=None):
        if hoverbackground: self.hoverbackground = hoverbackground
        if hoverforeground: self.hoverforeground = hoverforeground
    
    def setUrl(self, url=None):
        self.url = url
        self.bind("<Button-1>", self.openUrl)
    
    def openUrl(self, url=None):
        webbrowser.get('windows-default').open(self.url)
    
    def on_enter(self, e):
        self._background = self['background']
        self._foreground = self['foreground']
        self['background'] = getattr(self, 'hoverbackground', self['background'])
        self['foreground'] = getattr(self, 'hoverforeground', self['foreground'])
        f = font.Font(self, self.cget("font"))
        f.configure(underline=True)
        self.configure(font=f)

    def on_leave(self, e):
        self['background'] = getattr(self, '_background')
        self['foreground'] = getattr(self, '_foreground')
        f = font.Font(self, self.cget("font"))
        f.configure(underline=False)
        self.configure(font=f)

