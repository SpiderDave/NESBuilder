import os
import math
from random import randrange
import numpy as np

import webbrowser
import re

from zipfile import ZipFile

from PIL.ImageQt import ImageQt

from PyQt5 import QtGui
from PyQt5.QtGui import QIcon, QPainter, QColor, QImage, QBrush, QPixmap, QPen, QCursor, QWindow, QFont, QIntValidator
from PyQt5.QtCore import QDateTime, Qt, QTimer, QCoreApplication, QSize, QRect, QPoint
from PyQt5.QtWidgets import (QApplication, QCheckBox, QComboBox, QDateTimeEdit,
        QDial, QDialog, QGridLayout, QGroupBox, QHBoxLayout, QLabel, QLineEdit,
        QProgressBar, QPushButton, QRadioButton, QScrollBar, QSizePolicy,
        QSlider, QSpinBox, QStyleFactory, QTableWidget, QTabWidget, QTextEdit,
        QVBoxLayout, QWidget, QAction, QMainWindow, QMessageBox, QFileDialog, 
        QInputDialog, QErrorMessage, QFrame, QPlainTextEdit, QListWidget, QListWidgetItem,
        QVBoxLayout,QTableWidgetItem, QMenu, QScrollArea, QListView
        )

#from PyQt5.QtWidgets import QColorDialog
from PyQt5.QtWidgets import QFontDialog
from PyQt5.Qt import QStaticText

from PyQt5.Qsci import QsciScintilla, QsciLexerCustom


#Warning: QT_DEVICE_PIXEL_RATIO is deprecated. Instead use:
#   QT_AUTO_SCREEN_SCALE_FACTOR to enable platform plugin controlled per-screen f
#actors.
#   QT_SCREEN_SCALE_FACTORS to set per-screen DPI.
#   QT_SCALE_FACTOR to set the application global scale factor.

#QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
#os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "3"
#QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, False)
#os.environ["QT_DEVICE_PIXEL_RATIO"] = "2"
#qputenv("QT_DEVICE_PIXEL_RATIO",QByteArray("2"));

#os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "2"
#os.environ["QT_SCREEN_SCALE_FACTORS"] = "1.5"
#os.environ["QT_SCALE_FACTOR"] = "1.5"


opcodes = [
    'adc', 'and', 'asl', 'bcc', 'bcs', 'beq', 'bit', 'bmi', 'bne', 'bpl', 'brk', 'bvc', 'bvs', 'clc',
    'cld', 'cli', 'clv', 'cmp', 'cpx', 'cpy', 'dec', 'dex', 'dey', 'eor', 'inc', 'inx', 'iny', 'jmp',
    'jsr', 'lda', 'ldx', 'ldy', 'lsr', 'nop', 'ora', 'pha', 'php', 'pla', 'plp', 'rol', 'ror', 'rti',
    'rts', 'sbc', 'sec', 'sed', 'sei', 'sta', 'stx', 'sty', 'tax', 'tay', 'tsx', 'txa', 'txs', 'tya'
]

directives = [
    'if', 'elseif', 'else', 'endif', 'ifdef', 'ifndef', 'equ', 'org', 'base', 'pad',
    'include', 'incsrc', 'incbin', 'bin', 'hex', 'word', 'dw', 'dcw', 'dc.w', 'byte',
    'db', 'dcb', 'dc.b', 'dsw', 'ds.w', 'dsb', 'ds.b', 'align', 'macro', 'rept',
    'endm', 'endr', 'enum', 'ende', 'ignorenl', 'endinl', 'fillvalue', 'dl', 'dh',
    'error', 'inesprg', 'ineschr', 'inesmir', 'inesmap', 'nes2chrram', 'nes2prgram',
    'nes2sub', 'nes2tv', 'nes2vs', 'nes2bram', 'nes2chrbram', 'unstable', 'hunstable'
]

opcodes = opcodes + [x.upper() for x in opcodes]
directives = directives + ['.'+x for x in directives]
directives = directives + [x.upper() for x in directives]

# keys are numerical, data is text
keyConstMap = dict([(getattr(Qt,item),item[4:]) for item in dir(Qt) if item.startswith('Key_')])

# black, green, red, blue
basePalette = [
    [0,0,0],
    [0,255,0],
    [255,0,0],
    [0,0,255],
    ]

basePens = [QColor(*basePalette[x]) for x in range(4)]

# ToDo: use a dict of multiple palettes loaded
class Palette():
    palette=[
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
    def load(self, filename):
        try:
            size = os.path.getsize(filename)
            if size != 192:
                print(f'Incorrect size of palette file {filename} ({size})')
                return
            with open(filename, "rb") as file:
                fileData = list(file.read())
            self.palette = [fileData[i * 3:(i + 1) * 3] for i in range((len(fileData) + 3 - 1) // 3 )] 
            print(f'palette loaded from {filename}')
        except:
            print(f'Could not load palette file {filename}')
            return
    def get(self):
        return self.palette

nesPalette = Palette()


# This is something to reformat lua tables from lupa into 
# lists if needed.  I'd like to avoid importing lupa here
# to keep things reasonably seperate.
def fix(item):
    if item.__class__.__name__ == '_LuaTable':
        return [item[x] for x in list(item)]
    else:
        return item

def numericTableOrList(item):
    if item.__class__.__name__ == '_LuaTable':
        return [y for x,y in item.items() if type(x) == int]
    else:
        return item

def filetypesToFilter(filetypes):
    types = list()
    if filetypes:
        for t in filetypes:
            l= fix(filetypes[t])
            ext = ' '.join(l[1:])
            ext = ext.replace('.', '*.')
            types.append([l[0], ext])
        types.append(["All files","*.*"])
        filter = ";;".join([x+" ("+y+")" for x,y in types])
        filter = filter.replace('(.', '(*.')
        filter = filter.replace(' .', ' *.')
#        print(filter)
    else:
        filter="All Files (*.*)"
    
    return filter


clamp = lambda value, minv, maxv: max(min(value, maxv), minv)
def coalesce(*arg): return next((a for a in arg if a is not None), None)

clip = {}
cursors = False

def loadCursors(c):
    global cursors
    cursors = c


class Map(dict):
    """
    Example:
    m = Map({'first_name': 'Eduardo'}, last_name='Pool', age=24, sports=['Soccer'])
    """
    def __init__(self, *args, **kwargs):
        super(Map, self).__init__(*args, **kwargs)
        for arg in args:
            if isinstance(arg, dict):
                for k, v in arg.items():
                    self[k] = v

        if kwargs:
            for k, v in kwargs.items():
                self[k] = v

    def __getattr__(self, attr):
        return self.get(attr)

    def __setattr__(self, key, value):
        self.__setitem__(key, value)

    def __setitem__(self, key, value):
        super(Map, self).__setitem__(key, value)
        self.__dict__.update({key: value})

    def __delattr__(self, item):
        self.__delitem__(item)

    def __delitem__(self, key):
        super(Map, self).__delitem__(key)
        del self.__dict__[key]

class App(QApplication):
    def __init__(self, args=[], **kw):
        super().__init__(args, **kw)
    def mainloop(self):
        super().exec_()
    def quit(self):
        QCoreApplication.quit()


class Base_Light():
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.control = self # backwards compatability
        self.anonymous = False
        self.data = dict()
        self.statusBarText = ""
        self.onMouseMove = False
        self.onMouseHover = False
        self.onMousePress = False
        self.onMouseRelease = False
        self.onClick = False
        self.onChange = False
        self.helpText = False
        self.action = False
        self.functionName = False
        try: self.setMouseTracking(True)
        except: pass
    def init(self, t):
        self.name = t.name
        self.tooltip=t.tooltip
        self.move(t.x,t.y)
        self.resize(t.w, t.h)
        self.text = t.text
        self.scale = t.scale or 1
        self.functionName = t.functionName or False
    def __getattribute__(self, key):
        if key == 'tooltip':
            return self.toolTip()
        if key == 'width':
            return super().width()
        if key == 'height':
            return super().height()
        return super().__getattribute__(key)
    def __setattr__(self, key, v):
        if key == 'tooltip':
            self.setToolTip(v)
        if key == 'width':
            self.resize(v, super().height())
        if key == 'height':
            self.resize(super().width(), v)
        else:
            super().__setattr__(key,v)
    def setCssClass(self, value):
        super().setProperty('class', value.strip())
    def getCssClass(self):
        return super().property('class')
    def addCssClass(self, value):
        value = value.strip()
        classes = super().property('class') or ''
        
        if value.lower() in classes.lower().split():
            pass
        else:
            super().setProperty('class', classes+" "+value)
            self.update()
    def removeCssClass(self, value):
        value = value.strip()
        classes = super().property('class') or ''
        
        if value.lower() in classes.lower().split():
            classes = ' '.join([x for x in classes.split() if x.lower()!=value.lower()])
            super().setProperty('class', classes)
            self.update()


class Sizing():
    def move(self, x,y):
        if not x:
            x = 0
        if not y:
            y = 0
        super().move(int(x),int(y))
    def resize(self, w=False,h=False):
        if not w:
            w = self.sizeHint().width()*1.5
        if not h:
            h = self.sizeHint().height()*1.2
        super().resize(int(w),int(h))


class Base():
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.control = self # backwards compatability
        self.anonymous = False
        self.data = dict()
        self.statusBarText = ""
        self.onMouseMove = False
        self.onMouseHover = False
        self.onMousePress = False
        self.onMouseRelease = False
        self.onContextMenu = False
        self.onClick = False
        self.onChange = False
        self.helpText = False
        self.keyEvent = False
        self.closable = True
        self.action = False
        self.functionName = False
        try: self.setMouseTracking(True)
        except: pass
        
    def init(self, t):
        self.name = t.name
        self.tooltip=t.tooltip
        self.move(t.x,t.y)
        self.resize(t.w, t.h)
        self.text = t.text
        self.scale = t.scale or 1
        self.contextMenuItems = t.contextMenuItems or False
        self.functionName = t.functionName or False
 
        if t['class']:
            self.addCssClass(t['class'])
    def keyPressEvent(self, event):
        if getattr(self, 'onKeyPress', False):
            k = keyConstMap.get(event.key(),event.text())
            
            ev = Map(
                key = k,
                type = "KeyPress",
            )
            self.event = ev
            self.onKeyPress(event)
        else:
            super().keyPressEvent(event)
    def mousePressEvent(self, event):
        if getattr(self, 'clicked', False):
            super().mousePressEvent(event)
            return
        if self.onMousePress:
            b = dict({
                2:'ButtonPress',
                3:'ButtonRelease',
                4:'ButtonDblClick',
                5:'Move',
                })
            ev = Map(
                x = event.x(),
                y = event.y(),
                button = int(event.buttons()),
                type = b.get(event.type()),
            )
            self.event = ev
            self.onMousePress(ev)
        else:
            super().mousePressEvent(event)
    def mouseReleaseEvent(self, event):
        if getattr(self, 'clicked', False):
            super().mouseReleaseEvent(event)
            return
        if self.onMouseRelease:
            b = dict({
                2:'ButtonPress',
                3:'ButtonRelease',
                4:'ButtonDblClick',
                5:'Move',
                })
            ev = Map(
                x = event.x(),
                y = event.y(),
                button = int(event.buttons()),
                type = b.get(event.type()),
            )
            self.event = ev
            self.onMouseRelease(ev)
        else:
            super().mousePressEvent(event)
    def mouseMoveEvent(self, event):
        if int(event.buttons()) == 0:
            self.window().setHoveredWidget(self)
            if self.onMouseHover:
                self.onMouseHover(event)
        elif self.onMouseMove:
            b = dict({
                2:'ButtonPress',
                3:'ButtonRelease',
                4:'ButtonDblClick',
                5:'Move',
                })
            ev = Map(
                x = event.x(),
                y = event.y(),
                button = int(event.buttons()),
                type = b.get(event.type()),
            )
            #self.onMouseMove(event)
            
            self.event = ev
            self.onMouseMove(ev)
        else:
            super().mouseMoveEvent(event)
    def move(self, x,y):
        if not x:
            x = 0
        if not y:
            y = 0
        super().move(int(x),int(y))
    def setGeometry(self, x,y,w,h):
        self.move(x,y)
        self.resize(w,h)
    def resize(self, w=False,h=False):
        if not w:
            w = self.sizeHint().width()*1.5
        if not h:
            h = self.sizeHint().height()*1.2
        super().resize(int(w),int(h))
    def setCursor(self,cursor=None):
        if not cursor:
            super().setCursor(QCursor())
            return
        
        if not cursors:
            print('no cursors.')
            return
        
        c = cursors.get(cursor)
        if c:
            filename = c.get('filename', False)
            #print(filename)
            if filename:
                x,y = c.get('hotspot')
                super().setCursor(QtGui.QCursor(QtGui.QPixmap(filename),x,y))
        else:
            super().setCursor(QCursor(getattr(Qt,cursor)))
    def setFont(self, fontName, size):
        super().setFont(QtGui.QFont(fontName, size))
        self.adjustSize()
    def setCssClass(self, value):
        super().setProperty('class', value.strip())
    def getCssClass(self):
        return super().property('class')
    def addCssClass(self, value):
        value = value.strip()
        #super().setProperty('CssClass', value)
        classes = super().property('class') or ''
        
        if value.lower() in classes.lower().split():
            pass
        else:
            super().setProperty('class', classes+" "+value)
            self.update()
    def removeCssClass(self, value):
        value = value.strip()
        classes = super().property('class') or ''
        
        if value.lower() in classes.lower().split():
            classes = ' '.join([x for x in classes.split() if x.lower()!=value.lower()])
            super().setProperty('class', classes)
            self.update()
    def __getattribute__(self, key):
        if key == 'tooltip':
            return self.toolTip()
        if key == 'width':
            return super().width()
        if key == 'height':
            return super().height()
        return super().__getattribute__(key)
    def __setattr__(self, key, v):
        if key == 'tooltip':
            self.setToolTip(v)
        if key == 'width':
            self.resize(v, super().height())
        if key == 'height':
            self.resize(super().width(), v)
        else:
            super().__setattr__(key,v)
    def screenshot(self):
        try:
            screen = QApplication.primaryScreen()
            screenshot = screen.grabWindow( self.winId() )
            screenshot.save('shot.jpg', 'jpg')
        except: pass
    def contextMenuEvent(self, event):
        contextMenu = QMenu(self)
        if self.contextMenuItems:
            d = {}
            for k,v in self.contextMenuItems.items():
                if isinstance(v, str):
                    contextMenu.addAction(v)
                    d.update({v: {}})
                else:
                    # assumes a mapping
                    contextMenu.addAction(v.name)
                    d.update({v.name: dict(action=v.action)})
            action = contextMenu.exec_(self.mapToGlobal(event.pos()))
            if action:
                func = d[action.text()].get('action', False)
                if self.onContextMenu:
                    if not self.onContextMenu(action.text(), func):
                        # a specific function exists, and the onContextMenu
                        # handler didn't return True (meaning cancel)
                        if func:
                            func()
                else:
                    if func:
                        func()

class ComboBox(Sizing, Base_Light, QComboBox):
    def __getattribute__(self, key):
        if key == 'value':
            return super().currentText()
        elif key == 'index':
            return super().currentIndex()
        else:
            return super().__getattribute__(key)
    def setByText(self, txt=''):
        try:
            self.setCurrentIndex(self.findText(txt))
        except:
            pass
    def showEvent(self, *args, **kwargs):
        # this is awkward.  fixes some display issues, but
        # breaks getting the proper height
#        w = self.width
#        self.resize(w)
        super().showEvent(*args, **kwargs)

class MenuBox(ComboBox):
    def __getattribute__(self, key):
        if key == 'helpText':
            return self.labelCtrl.helpText
        else:
            return super().__getattribute__(key)
    def menuActivate(self, event):
        self.setCurrentIndex(-1)
        self.hidePopup()
        self.showPopup()
    def init(self, t):
        view = QListView()
        view.setFixedWidth(200)
        self.setView(view)
        self.SizeAdjustPolicy(QComboBox.AdjustToContentsOnFirstShow)
        super().init(t)
        
        self.addCssClass('menubox')
        self.hide()
        
        ctrl = Label(t.text or '', self.parent())
        ctrl.autoSize = False
        ctrl.removeCssClass("label")
        ctrl.init(t)
        ctrl.resize(None, self.height)
        ctrl.addCssClass("menubox_menu")
        ctrl.onMousePress = self.menuActivate
        self.labelCtrl = ctrl
    def showEvent(self, *args, **kwargs):
        self.resize(w)
        super().showEvent(*args, **kwargs)


class LineEdit(Base, QLineEdit):
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
    def __getattribute__(self, key):
        if key == 'text':
            return super().text()
        else:
            return super().__getattribute__(key)
    def __setattr__(self, key, v):
        if key == 'text':
            super().setText(str(v))
        else:
            super().__setattr__(key,v)

class NumberEdit(Base, QLineEdit):
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.setValidator(QIntValidator())
    def init(self, t):
        super().init(t)
        self.value = t.value or 0
    def __getattribute__(self, key):
        if key == 'value':
            try:
                return int(super().text())
            except:
                return 0
        else:
            return super().__getattribute__(key)
    def __setattr__(self, key, v):
        if key == 'value':
            try:
                v = int(v)
            except:
                v = 0
            super().setText(str(v))
        else:
            super().__setattr__(key,v)


class TextEdit(Base, QPlainTextEdit):
    changed = False
    def print(self, txt=''):
        self.appendPlainText(str(txt))
    def setText(self, txt=''):
        self.setPlainText(str(txt))
    def save(self, filename):
        try:
            with open(filename, "w") as file:
                file.write(self.toPlainText())
        except:
            pass
    def load(self, filename):
        try:
            with open(filename, "r") as file:
                self.setPlainText(file.read())
        except:
            print("Error: Could not load file "+filename)

    def __getattribute__(self, key):
        if key == 'text':
            return super().toPlainText()
        else:
            return super().__getattribute__(key)
    def _changed(self):
        if self.onChange:
            self.onChange()

class Console(TextEdit):
    def init(self, t):
        super().init(t)
        self.addCssClass('console')

    def print(self, txt=''):
        self.appendPlainText(str(txt))
        #self.ensureCursorVisible()
        #self.setCenterOnScroll(True)
        self.scrollContentsBy(0,100)


class CodeEdit(Base_Light, QsciScintilla):
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.setLexer(None)
        self.setUtf8(True)
        self.setFont("Verdana",12)
        self.setLexer(MyLexer(self))
        
        self.setCaretForegroundColor(QColor("white"))
        self.setMarginsBackgroundColor(QColor("#404050"))
    def setFont(self, fontName, size):
        super().setFont(QtGui.QFont(fontName, size))
        self.adjustSize()
    def __getattribute__(self, key):
        if key == 'text':
            return super().text()
        else:
            return super().__getattribute__(key)
    def __setattr__(self, key, v):
        if key == 'text':
            super().setText(str(v))
        else:
            super().__setattr__(key,v)
    def print(self, txt=''):
        self.text = self.text + txt + '\n'


class Button(Base, QPushButton):
    def setIcon(self, f):
        try:
            super().setIcon(QIcon(f))
            self.setIconSize(QSize(64, 64))
            super().setProperty('hasIcon', True)
            return True
        except:
            return False
    def setIconFromArchive(self, zipFilename, filename):
        try:
            zip=ZipFile(zipFilename)
            if filename in zip.namelist():
                data = zip.read(filename)
                pm = QtGui.QPixmap()
                pm.loadFromData(data)
                super().setIcon(QIcon(pm))
                self.setIconSize(QSize(64, 64))
                super().setProperty('hasIcon', True)
                return True
            return False
        except:
            return False
    def setIconFromData(self, data):
        try:
            pm = QtGui.QPixmap
            pm.loadFromData(data)
            super.setIcon(pm.QIcon())
            self.setIconSize(QSize(64, 64))
            super().setProperty('hasIcon', True)
            return True
        except:
            return False

class Label(Base, QLabel):
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.autoSize = True
    def init(self, t):
        self.addCssClass("label")
        self.addCssClass("defaultfont")
        super().init(t)
        
    def setFont(self, *args, **kw):
        self.removeCssClass("defaultfont")
        super().setFont(*args, **kw)
    
    def setText(self, txt, autoSize = False):
        super().setText(txt)
        if autoSize or self.autoSize:
            self.adjustSize()
    def __getattribute__(self, key):
        if key == 'text':
            return self.getText()
        return super().__getattribute__(key)
    def __setattr__(self, key, v):
        if key == 'text':
            self.setText(v, autoSize=self.autoSize)
        else:
            super().__setattr__(key,v)
    def showEvent(self, event: QtGui.QShowEvent):
        if self.autoSize:
            self.adjustSize()


class Link(Label):
    def init(self, t):
        super().init(t)
        self.addCssClass("link")
        self.setOpenExternalLinks(True)
        self.linkHovered.connect(self._linkHovered)
        self.linkActivated.connect(self._linkClicked)
        self._cancel = False
        self.url = t.url
        t.url = None
        
        self.setCursor('PointingHandCursor')
    def _linkHovered(self):
        pass
    def _linkClicked(self):
        pass
    def cancel(self, c=True):
        self._cancel = c
    def getUrl(self):
        return self.url
    def setUrl(self, url):
        self.url = url
    def openUrl(self, url = False):
        if not url:
            url = self.url
        webbrowser.open(url)
        

class CheckBox(Base, QCheckBox): pass

class Frame(Base, QFrame): pass

class ScrollFrame(Base, QScrollArea):
    frame = False
    def init(self, t):
        super().init(t)
        self.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.frame = QFrame()
        self.setWidget(self.frame)
        self.frame.resize(self.width, 1000)
        self.frame.move(0,0)
        self.setWidget(self.frame)

class LauncherIcon(Frame):
    def init(self, t):
        super().init(t)
        
        self.addCssClass("launcherFrame")
        
        ctrl = Label("", self)
        ctrl.autoSize = False
        ctrl.removeCssClass("label")
        t.text = ""
        ctrl.init(t)
        ctrl.resize(self.width, self.height)
        ctrl.move(0,0)
        ctrl.addCssClass("launcherIcon")
        
        self.iconCtrl = ctrl
    def setText(self, text):
        #self.label.text = text
        pass

class TabWidget(Base, QTabWidget):
    def init(self, t):
        super().init(t)
        self.width = 1000
        self.height = 1000
        self.self = self
        self.setTabsClosable(True)
        self.tabCloseRequested.connect(lambda index: self.closeTab(index))
        self.onCloseTab = False
        self.closingWidget = False
    def closeTab(self, index):
        if self.tabsClosable():
            if self.widget(index).closable:
                if self.onCloseTab:
                    self.closingWidget = self.widget(index)
                    self.onCloseTab(self.widget(index))
                self.removeTab(index)
    def setIcon(self, tabIndex, f):
        try:
            super().setTabIcon(tabIndex, QIcon(f))
            #self.setIconSize(QSize(64, 64))
            super().setProperty('hasIcon', True)
            return True
        except:
            return False


class Widget(Base, QWidget): pass
QWidget = Widget

class MainWindow(Base, QMainWindow):
    def __init__(self):
        super().__init__()
        self.initUI()
        self.tabParent = False
        self.name = "MainQt"
        self.tabs = dict()
        self.menus = dict()
        self.loaded = False
        self.onClose = False
        self.onResize = False
        self.onHoverWidget = False
        self.timer = QTimer(self)
        self.closing = False
        self.onKeyPress = False
        
        #self.setFixedSize(1000,1000)
        #self.setFixedSize(16777215,16777215)
        #self.setFixedSize(Qt.QWIDGETSIZE_MAX(), Qt.QWIDGETSIZE_MAX())
        #self.setFixedSize(self.sizeHint())
        #minimumSizeHint()
        
        
        QTimer.singleShot(1,self.onDisplay)
    def setHoveredWidget(self, widget):
        self.hoveredWidget = widget
        if self.onHoverWidget:
            self.onHoverWidget(widget)
    def resizeEvent(self, event: QtGui.QResizeEvent):
        super().resizeEvent(event)
        width = event.size().width()
        height = event.size().height()
        oldWidth = event.oldSize().width()
        oldHeight = event.oldSize().height()
        if self.onResize:
            self.onResize(width, height, oldWidth, oldHeight)
    def onDisplay(self):
        self.loaded = True
        
    def hideMenuItem(self, menuName, menuItem=None):
        if not self.menus.get(menuName, False):
            return
        if not menuItem:
            # hide entire menu
            m.menuAction().setVisible(False)
            return
        m = self.menus.get(menuName)
        m.actions.get(menuItem).setVisible(False)
    def showMenuItem(self, menuName, menuItem=None):
        if not self.menus.get(menuName, False):
            return
        if not menuItem:
            # hide entire menu
            m.menuAction().setVisible(True)
            return
        m = self.menus.get(menuName)
        m.actions.get(menuItem).setVisible(True)
    def addMenu(self, menuName, menuText, menuItems):
        if not self.menus.get(menuName, False):
            menu = Menu(menuText)
            self.menuBar().addMenu(menu)
            self.menus.update({menuName:menu})
        
        m = self.menus.get(menuName)
        
        for i, item in enumerate(menuItems):
            name = item.get('name', str(i))
            txt = item.get('text', "?")
            checked = item.get('checked', None)
            # check if text is any number of -
            if txt.startswith('-') and txt == txt[0]*len(txt):
                m.addSeparator()
            else:
                action = QAction(item.get('text'), self)
                m.actions.update({name:action})
                if checked is not None:
                    action.setCheckable(True)
                    action.setChecked(checked)
                if item.get('action', False):
                    action.triggered.connect(item.get('action'))
                m.addAction(action)
        return m
    def contextMenuEvent(self, event):
        print("popup")
        if True: return
        contextMenu = QMenu(self)
        newAct = contextMenu.addAction("New")
        openAct = contextMenu.addAction("Open")
        quitAct = contextMenu.addAction("Quit")
        action = contextMenu.exec_(self.mapToGlobal(event.pos()))
        if action == quitAct:
            self.close()
    def setIcon(self, filename):
        self.setWindowIcon(QtGui.QIcon(filename))
        
    def initUI(self):
        self.setGeometry(300, 300, 300, 220)
    def closeEvent(self, event):
        if self.onClose:
            if self.onClose():
                self.closing=True
                event.accept()
            else:
                event.ignore()
            return
        self.closing=True
        event.accept()
    def setTimer(self, t, f, repeating=False):
        if repeating:
            self.timer.timeout.connect(f)
            self.timer.start(t)
        else:
            self.timer.singleShot(t, f)
    def getTab(self, name):
        return self.tabs.get(name, False)


class Dialog():
    def askYesNo(self, title="", message=""):
        m = QMessageBox()
        reply = m.question(m, title, message, QMessageBox.Yes | QMessageBox.No)
        if reply == QMessageBox.Yes:
            return True
        else:
            return False
    def askYesNoCancel(self, title="", message=""):
        m = QMessageBox()
        reply = m.question(m, title, message, QMessageBox.Yes | QMessageBox.No |QMessageBox.Cancel , QMessageBox.Cancel)
        if reply == QMessageBox.Yes:
            return True
        elif reply == QMessageBox.No:
            return False
        else:
            return
    def openFolder(self, title="Select Folder", initial=None):
        d = QFileDialog()
        return str(d.getExistingDirectory(None, title, initial)) 
    def openFile(self, filetypes=None, initial=None, title="Select File", filter="All Files (*.*)"):
        d = QFileDialog()
        
        if filetypes:
            filter = filetypesToFilter(filetypes)
        
        file, _ = d.getOpenFileName(None, title, initial, filter)
        return file
    def saveFile(self, filetypes=None, initial=None, title="Save As...", filter="All Files (*.*)"):
        d = QFileDialog()
        
        if filetypes:
            filter = filetypesToFilter(filetypes)
        
        file, selectedFilter = d.getSaveFileName(None, title, initial, filter)
        if file:
            return file, os.path.splitext(file)[1].lower(), selectedFilter
        return None, None, None
    def askText(self, title="Enter Text", label=None, defaultText=None):
        # trims whitespace and returns false on the empty string.
        
        d = QInputDialog(None, Qt.WindowCloseButtonHint)
        
        text, okPressed = d.getText(None, title, label, QLineEdit.Normal, defaultText)
        
        #if okPressed and text != '':
        if okPressed:
            return text.strip()
        else:
            return False
    def showError(self, text=None):
        d = QMessageBox()
        d.setText(text)
        d.setIcon(3)
        d.setStyleSheet(".QLabel {padding:1em;}")
        d.setWindowTitle("Error")
        d.exec_()
    def showInfo(self, text=None, title="Info"):
        d = QMessageBox()
        d.setText(text)
        d.setIcon(2)
        d.setStyleSheet(".QLabel {padding:1em;}")
        d.setWindowTitle(title)
        d.exec_()
        
        
class Painter(QPainter):
    def test(self):
        self.setPen(QColor(168, 34, 3))
    def test2(self):
        for i in range(20000):
            self.setPen(QColor(randrange(0,255), randrange(0,255), randrange(0,255)))
            self.drawLine(randrange(0,255), randrange(0,255), randrange(0,255), randrange(0,255))
    def test3(self):
        for x in range(256):
            for y in range(256):
                self.setPen(QColor(randrange(0,255), randrange(0,255), randrange(0,255)))
                self.drawPoint(x, y)
    def test4(self):
        self.setPen(QColor(168,34,3))
        self.setFont(QFont('Decorative', 10))
        self.drawText("test")

QPixmap = QPixmap

class ClipOperations():
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
    def save(self, f, fmt="PNG"):
        if hasattr(self, 'scale'):
            self.pixmap().scaled(int(self.width/self.scale), int(self.height/self.scale)).save(f, fmt)
        else:
            self.pixmap().scaled(self.width, self.height).save(f, fmt)
    def copy(self, x=0, y=0, w=False, h=False):
        """
        Copy pixmap to a "clipboard" type thing to later be
        pasted.  Also returns the pixmap to use directly.
        """
        pix = self.pixmap().scaled(int(self.width/self.scale), int(self.height/self.scale))
        
        if w == False:
            w = self.width
        if h == False:
            h = self.height
        
        pix = pix.copy(QRect(x,y,w,h))
        
        return clip.update(pix=pix)
    def paste(self, pix=False):
        """
        Sets a pixmap with automatic resizing.  The pixmap
        can be supplied via parameter or use the one stored
        from a "copy" operation above.
        """
        if not pix:
            pix = clip.get('pix')
        self.setPixmap(pix.scaledToWidth(self.width))

class Canvas(ClipOperations, Base, QLabel):
    def init(self, t):
        self.mask = False
        super().init(t)
        canvas=QPixmap(self.width,self.height)
        self.setPixmap(canvas)
        painter = Painter(self.pixmap())
        painter.setPen(QColor(0, 0, 0))
        painter.brushColor = QColor(Qt.black)
        painter.fillRect(0,0,self.width,self.height,QBrush(Qt.black))
        painter.end()
        self.columns = (self.width/self.scale)/8
        self.rows = (self.height/self.scale)/8
    def reset(self, columns=16,rows=16):
        self.columns = columns
        self.rows = rows
        w = columns * 8 * self.scale
        h = rows * 8 * self.scale
        self.width = w
        self.height = h
        
        canvas=QPixmap(w,h)
        self.setPixmap(canvas)
    def setNameTable(self, nameTable=False):
        if not nameTable:
            nameTable = [0]*math.floor(self.columns*self.rows)
        self.nameTable = nameTable
        return nameTable
    def setAttrTable(self, attrTable=False):
        if not attrTable:
            attrTable = [0]*(8*8)
        self.attrTable = attrTable
        return attrTable
    def clear(self):
        painter = Painter(self.pixmap())
        painter.setPen(QColor(0, 0, 0))
        painter.brushColor = QColor(Qt.black)
        painter.fillRect(0,0,self.width,self.height,QBrush(Qt.black))
        painter.end()
    def paintTest(self):
        painter = Painter(self.pixmap())
        painter.test3()
        painter.end()
    def drawLine(self, x,y,x2,y2):
        # needs work
        painter = Painter(self.pixmap())
        painter.scale(self.scale, self.scale)
        painter.setPen(QPen(Qt.white,  5, Qt.DotLine))
        painter.drawLine(x,y,x2,y2)
        painter.end()
    def drawLine2(self, x,y,x2,y2):
        # needs work
        painter = Painter(self.pixmap())
        #painter.scale(self.scale, self.scale)
        lineWidth = 4
        c = QColor(255,255,255,150)
        pen = QPen(c, lineWidth, Qt.DotLine)
        #pen.setDashOffset(1)
        #painter.setPen(QPen(Qt.white,  1, Qt.DotLine))
        painter.setPen(pen)
        #painter.drawLine(x,y,x2,y2)
        #painter.drawLine(x*self.scale-self.scale*.5,y*self.scale-self.scale*.5,x2*self.scale-self.scale*.5,y2*self.scale-self.scale*.5)
        painter.drawLine(x*self.scale+self.scale*.5,y*self.scale+self.scale*.5,x2*self.scale+self.scale*.5,y2*self.scale+self.scale*.5)
        painter.end()
    def horizontalLine(self, y):
        painter = Painter(self.pixmap())
        painter.scale(self.scale, self.scale)
        pen = QPen()
        pen.setColor(QColor("white"))
        painter.setPen(pen)
        painter.drawLine(0,y,self.width,y)
        painter.end()
    def setPixel(self, x,y, c=[0,0,0]):
        painter = Painter(self.pixmap())
        painter.scale(self.scale, self.scale)
        painter.fillRect(x,y,1,1,QBrush(QColor(c[1],c[2],c[3])))
        painter.end()
    def test(self, chr):
        pix = NESPixmap(8*16,8*16)
        pix.loadCHR(chr)
        p=Painter(self.pixmap())
        p.drawPixmap(QRect(0,0,self.width,self.height), pix)
        p.end()
        self.repaint()
    def testText(self, font = None):
        if not font:
            #font = QFont('Decorative', 10)
            font = QFont('MV Boli', 24)
        painter = Painter(self.pixmap())
        painter.scale(self.scale, self.scale)
        painter.setPen(QColor(255,255,255))
        painter.setFont(font)
        #painter.drawText(QRect(0,0,self.width,self.height), Qt.AlignTop | Qt.AlignLeft, 'test')
        painter.drawStaticText(0,0, QStaticText('test'))
        painter.end()
        self.repaint()
    def changeColor(self):
        pix = self.pixmap()
        if not self.mask:
            self.mask = pix.createMaskFromColor(QColor(0, 0, 0), Qt.MaskOutColor)
        
        mask = self.mask
        
        p = Painter(pix)
        p.setPen(QColor(randrange(0,255),randrange(0,255),randrange(0,255)))
        p.drawPixmap(pix.rect(), mask, mask.rect())
        p.end()
        self.repaint()
    def drawTile(self, x,y, tile, imageData, colors=None, columns=16, rows=16):
        painter = Painter(self.pixmap())
        
        if not colors:
            colors=[0x0f,0x21,0x11,0x01]
        else:
            colors = fix(colors)
        
        imageData = fix(imageData)
        
        originX=x*self.scale
        originY=y*self.scale
        
        #a = np.zeros((8,8,3))
        
        # Optimize solid tiles for speed
        if 1:
            tileData = imageData[tile*16:tile*16+16]
            if np.all((tileData == 0)) or np.all((tileData == 0xff)):
                c = tileData[0] & 3
                brushColor = QColor(nesPalette.palette[colors[c]][0], nesPalette.palette[colors[c]][1], nesPalette.palette[colors[c]][2])
                painter.fillRect(originX,originY,self.scale*8,self.scale*8,QBrush(brushColor))
                painter.end()
                return

            if np.all((tileData[:8] == 0)) and np.all((tileData[8:] == 0xff)):
                c = 2
                brushColor = QColor(nesPalette.palette[colors[c]][0], nesPalette.palette[colors[c]][1], nesPalette.palette[colors[c]][2])
                painter.fillRect(originX,originY,self.scale*8,self.scale*8,QBrush(brushColor))
                painter.end()
                return

            if np.all((tileData[:8] == 0xff)) and np.all((tileData[8:] == 0x00)):
                c = 1
                brushColor = QColor(nesPalette.palette[colors[c]][0], nesPalette.palette[colors[c]][1], nesPalette.palette[colors[c]][2])
                painter.fillRect(originX,originY,self.scale*8,self.scale*8,QBrush(brushColor))
                painter.end()
                return
        
        brushColors = []
        for c in range(4):
            brushColors.append(QColor(nesPalette.palette[colors[c]][0], nesPalette.palette[colors[c]][1], nesPalette.palette[colors[c]][2]))
        
        for y in range(8):
            for x in range(8):
                c=0
                x1=(tile % columns)*8+(7-x)
                y1=math.floor(tile/columns)*8+y
                if (imageData[tile*16+y] & (1<<x)):
                    c=c+1
                if (imageData[tile*16+y+8] & (1<<x)):
                    c=c+2
                #a[y][(7-x)] = nesPalette.palette[colors[c]]
                painter.fillRect(originX+(7-x)*self.scale,originY+y*self.scale,self.scale,self.scale,QBrush(brushColors[c]))
        painter.end()

class PaletteButton(Label):
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.autoSize = False
    def init(self, t, width=30, height=30):
        super().init(t)
        self.addCssClass('paletteCell')
        self.resize(width, height)
    def mouseMoveEvent(self, event: QtGui.QResizeEvent):
        if int(event.buttons()) == 0:
            self.window().setHoveredWidget(self.parent())
            if self.onMouseHover:
                self.onMouseHover(event)
        elif self.onMouseMove:
            self.onMouseMove(event)
        else:
            super().mouseMoveEvent(event)
        
# todo: always use indexed palettes
class PaletteControl(Base, QFrame):
    upperHex = False
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.__class__.cls = self.__class__
    def init(self, t):
        super().init(t)
        
        if t.upperHex in (True, False):
            self.upperHex = self.cls.upperHex = t.upperHex
        else:
            self.upperHex = t.upperHex = self.cls.upperHex
        
        self.addCssClass('paletteControl')
        
        palette = [fix(x) for x in fix(t.palette)]
        
        pw = min(len(palette), 0x10)
        ph = math.ceil(len(palette) / 0x10)
        
        self.width = pw * 26+2
        self.height = ph * 26+2
        #self.height = max(28, self.height)
        self.cells = []
        
        for i, p in enumerate(palette):
            x = i % 0x10
            y = i // 0x10
            
            ctrl = PaletteButton("00", self)
            ctrl.init(t, width=26, height=26)
            ctrl.name = "{0}_Cell{1:02x}".format(t.name, i)
            ctrl.cellNum = i
            ctrl.move(x*26+1, y*26+1)
            if self.cls.upperHex:
                ctrl.setText("{0:02X}".format(i), autoSize=False)
            else:
                ctrl.setText("{0:02x}".format(i), autoSize=False)
            bg = "#{0:02x}{1:02x}{2:02x}".format(*palette[i-1])
            fg = 'white' if x>=(0x00,0x01,0x0d,0x0e)[y] else 'black'
            ctrl.setStyleSheet("""
            background-color :{};
            color :{};
            """.format(bg, fg))
            self.cells.append(ctrl)
    def setAll(self, colors):
        if not colors:
            return
        
        # strip away non-numeric entries if it was a lua table
        colors = numericTableOrList(colors)
        
        for i, c in enumerate(colors):
            self.set(index=i, c=c)
    def highlight(self, h=False, cellNum=False):
        # this just doesn't work.  i hate it.
        if h:
            self.setProperty('highlight', 'true')
            self.addCssClass('highlight')
        else:
            self.setProperty('highlight', 'false')
            self.removeCssClass('highlight')
    def clear(self):
        self.setVisible(False)
    def set(self, index=0, c=0x0f):
        self.setVisible(True)
        if not (0 <= c < len(nesPalette.get())):
            print('Invalid palette index {}'.format(c))
            c = 0
        
        cell = self.cells[index]
        
        bg = "#{0:02x}{1:02x}{2:02x}".format(*nesPalette.get()[c])
        x,y = c%0x10, c>>4
        fg = 'white' if x>=(0x00,0x01,0x0d,0x0e)[y] else 'black'
        
        cell.setStyleSheet("""
        background-color :{};
        color :{};
        """.format(bg, fg))
        if self.cls.upperHex:
            cell.setText("{0:02X}".format(c), autoSize=False)
        else:
            cell.setText("{0:02x}".format(c), autoSize=False)
        
class SideSpin(Base, QFrame):
    initialized = False
    def init(self, t):
        super().init(t)
        self.format = "{0:02x}"
        if t.format in ("hex", "hexidecimal"):
            self.format = "{:02x}"
        if t.format in ("dec", "decimal"):
            self.format = "{}"
        
        self._value = 0
        self.min = 0
        self.max = 255
        self.onChange = False
        #self.leftButton = l = Button(u"\u25C0", self)
        self.leftButton = l = Button("-", self)
        l.init(t)
        l.move(0,0)
        l.resize(self.height, self.height)
        l.clicked.connect(self._onLeft)
        self.label = m = Label(self)
        self.label.autoSize = False
        m.init(t)
        m.text=self.format.format(0)
        m.setFont("Verdana",12)
        m.move(l.width,0)
        #m.resize(self.width/3, self.height)
        m.resize(self.width-self.height*2, self.height)
        m.addCssClass("sideSpinLabel")
        #self.rightButton = r = Button(u"\u25B6", self)
        self.rightButton = r = Button("+", self)
        r.init(t)
        r.resize(self.height, self.height)
        r.move(self.width-r.width,0)
        r.clicked.connect(self._onRight)
        self.addCssClass('sideSpin')
        self.initialized = True
        
        QTimer.singleShot(400, self.refresh)
    def _onLeft(self):
        self._value = v = self._value - 1
        self.refresh()
        if self.onChange and (self._value ==v):
            self.onChange()
    def _onRight(self):
        self._value = v = self._value + 1
        self.refresh()
        if self.onChange and (self._value ==v):
            self.onChange()
    def refresh(self):
        self._value = clamp(self._value, self.min, self.max)
        self.label.text = self.format.format(self._value)
    
    def _changed(self):
        if self.onChange:
            self.onChange()
    def __setattr__(self, key, v):
        if self.initialized and key == 'helpText':
            self.leftButton.helpText = v
            self.rightButton.helpText = v
            self.label.helpText = v
        super().__setattr__(key,v)
    
    @property
    def value(self):
        return self._value
    
    @value.setter
    def value(self, v):
        if self._value != v:
            self._value = v
            self.refresh()
            # no idea why this crashes if i dont use a timer here
            QTimer.singleShot(1, self._changed)

class NESPixmap(ClipOperations, Base, QPixmap):
    """
    An off-screen image representation and drawing surface with
    NES-specific things.
    """
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        
        # This is just to give it a pixmap function so it works with 
        # ClipOperations
        self.pixmap = lambda:self
        self.rows=None
        self.columns=None
    def loadCHRFromImage(self, filename, colors = False):
        colors = fix(colors)
        
        img = None
        if filename:
            if isinstance(filename, str):
                if not self.load(filename):
                    print("could not load image")
                    return False
                img = self.toImage()
            else:
                img = filename
        
        w = math.floor(self.width/8)*8
        h = math.floor(self.height/8)*8
        nTiles = int(w/8 * h/8)
        
        out = []
        for t in range(nTiles):
            tile = [[]]*16
            for y in range(8):
                tile[y] = 0
                tile[y+8] = 0
                for x in range(8):
                    for i in range(4):
                        color = img.pixelColor(x+(t*8) % w, y + math.floor(t/(w/8))*8)
                        if list(color.getRgb()[:-1]) == colors[i]:
                            tile[y] += (2**(7-x)) * (i%2)
                            tile[y+8] += (2**(7-x)) * (math.floor(i/2))
            
            for i in range(16):
                out.append(tile[i])
        ret = out
        
        self.columns = math.floor(w/8)
        self.rows = math.floor(h/8)
        
        return ret
    def mapPixels(self, f):
        for x in range(self.width):
            for y in range(self.height):
                c = f(x, y, self.getPixel(x,y))
                c = max(c, 0)
                c = min(c, 3)
                c = math.floor(c+.5)
                self.setPixel(x,y, c)
    def setPixel(self, x, y, c):
        painter = Painter(self)
        painter.setPen(basePens[c])
        painter.drawPoint(x,y)
        painter.end()
    def getPixel(self, x, y):
        img = self.toImage()
        c = basePens.index(img.pixelColor(x,y))
        return c
    def getChr(self):
        return self.loadCHR(self)
    def loadCHR(self, imageData=None, columns=None, rows=None):
        """Loads CHR data using 4 preset base colors."""
        painter = Painter(self)
        
        columns = self.columns = coalesce(columns, self.columns, 16)
        rows = self.rows = coalesce(rows, self.rows, 16)
        
        try:
            if not imageData:
                imageData = [0] * (16*columns*rows)
        except:
            pass
        
        imageData = fix(imageData)
        
        for tile in range(math.floor(len(imageData)/16)):
            for y in range(8):
                for x in range(8):
                    tileX=(tile % columns)
                    tileY=math.floor(tile/columns)
                    c=0
                    x1=tileX * 8 + (7-x)
                    y1=tileY * 8 + y
                    if (imageData[tile*16+y] & (1<<x)):
                        c=c+1
                    if (imageData[tile*16+y+8] & (1<<x)):
                        c=c+2
                    #a[y][(7-x)] = basePalette[c]
                    painter.setPen(basePens[c])
                    painter.drawPoint(tileX*8+(7-x),tileY*8+y)
        painter.end()

    def applyPalette(self, palette=False):
        painter = Painter(self)
        
        # black, green, red, blue
        colors = [
            [0,0,0],
            [0,255,0],
            [255,0,0],
            [0,0,255],
            ]
        
        palette = numericTableOrList(palette)
        #palette = fix(palette)
        palette = [nesPalette.palette[x] for x in palette]
        pens = [QColor(*palette[x]) for x in range(4)]
        masks = []
        for i, c in enumerate(colors):
            masks.append(self.createMaskFromColor(QColor(*colors[i]), Qt.MaskOutColor))
        
        for x in range(8):
            for y in range(8):
        
                for i, mask in enumerate(masks):
                    painter.setPen(pens[i])
                    r = QRect(x*16,y*16,16,16)
                    painter.drawPixmap(r, mask, r)
        painter.end()
    def testText(self, font = None, text='', x=0, y=0, color=False):
        if not font:
            font = QFont('MV Boli', 24)
            font.setStyleStrategy(QFont.NoAntialias)
        painter = Painter(self)
#        painter.scale(self.scale, self.scale)
        painter.setPen(QColor(*color))
        painter.setFont(font)
        #painter.drawText(QRect(0,0,self.width,self.height), Qt.AlignTop | Qt.AlignLeft, 'test')
        painter.drawStaticText(x,y, QStaticText(text))
        painter.end()
#        self.repaint()

class listItemLabel(Label, QListWidgetItem):pass

class ListWidget(Base, QListWidget):
    def addCustomItem(self, t):
        for i in range(5):
            item = QListWidgetItem()
            fmt = '<span style="color:{}; width:5px;">\u2588</span>'
            txt = '{}{}{}{} {}'.format(fmt.format("black"),fmt.format("red"),fmt.format("green"),fmt.format("blue"), '<span class="paletteListText">Test</span>')
            widget = Label(txt)
            widget.addCssClass('paletteListItem')
            super().addItem(item)
            self.setItemWidget(item, widget)
    def setList(self, items):
        self.clear()
        for item in fix(items):
            super().addItem(QListWidgetItem(item))
    def setCurrentRow(self, row):
        return super().setCurrentRow(int(row))
    def getIndex(self):
        return super().currentRow()
    def getItem(self):
        return super().currentItem().text()
    def addItem(self, text):
        super().addItem(QListWidgetItem(text))
    def removeItem(self, index):
        self.takeItem(index)
    def keyPressEvent(self, event):
        if getattr(self, 'onKeyPress', False):
            k = keyConstMap.get(event.key(),event.text())
            ev = Map(
                key = k,
                type = "KeyPress",
            )
            self.event = ev
            # We still call the original event unless
            # cancel is true, so list navigation still
            # works.
            cancel = self.onKeyPress(event)
            if not cancel:
                super(QListWidget, self).keyPressEvent(event)
        else:
            super(QListWidget).keyPressEvent(event)

class Table(Base, QTableWidget):
    ignoreChanges = False
    def set(self, x,y, text):
        self.setItem(x,y, QTableWidgetItem(text))
    def setHorizontalHeaderLabels(self, *args):
        args = fix(args)
        super().setHorizontalHeaderLabels(args)
    def setColumnWidth(self, column, width):
        super().setColumnWidth(column, int(width))
    def getRow(self, row=0):
        l=[]
        for i in range(self.columnCount()):
            if self.item(row, i):
                l.append(self.item(row, i).text())
            else:
                l.append(None)
        return l
    def getData(self):
        l=[]
        for i in range(self.rowCount()):
            l.append(self.getRow(i))
        return l
    def clear(self):
        for r in range(self.rowCount()):
            for c in range(self.columnCount()):
                self.set(r,c,None)
    def _changed(self):
        if self.ignoreChanges:
            return
        if self.onChange:
            self.onChange()

class MyLexer(QsciLexerCustom):
    def __init__(self, parent):
        super(MyLexer, self).__init__(parent)
        self.parent = parent
        self.setDefaultColor(QColor("#ff000000"))
        self.setDefaultPaper(QColor("#303046"))
        self.setDefaultFont(QFont("Consolas", 14))

        colors = [
            "#e0e0f0", # 0 default
            "#8090ff", # 1 opcodes 
            "#60a060", # 2 text
            "#708090", # 3 comments
            "#ffa0e0", # 4 hex numbers (immediate)
            "#800000", # 5 dec numbers (immediate)
            "#d080f0", # 6 bin numbers (immediate)
            "#a08020", # 7 directives
            "#c0d0f0", # 8 hex number
            "#ff5050", # 9 dec number
        ]
        
        
        for i, color in enumerate(colors):
            self.setColor(QColor(color), i)
            self.setPaper(QColor("#303046"), i)
            
            if i == 1:
                self.setFont(QFont("Consolas", 12, weight=QFont.Normal), i)
            else:
                self.setFont(QFont("Consolas", 12, weight=QFont.Normal), i)
        
        self.colors = colors
    def styleText(self, start, end):
            colors = self.colors
            self.startStyling(start)
            
            text = self.parent.text[start:end]
            p = re.compile(r""";.*|".*?"|#\$[0-9a-fA-F]+|#%[0-1]{8}|#[0-9]+|\$[0-9a-fA-F]+|\.\w+|\s+|\w+|\W""")
            
            token_list = [ (token, len(bytearray(token, "utf-8"))) for token in p.findall(text)]
            # -> 'token_list' is a list of tuples: (token_name, token_len)

            for i, token in enumerate(token_list):
                if token[0].startswith(r"#$"):
                    self.setStyling(token[1], 4)
                elif token[0].startswith(r"#%"):
                    self.setStyling(token[1], 6)
                elif token[0].startswith(r"#"):
                    self.setStyling(token[1], 5)
                elif token[0].startswith("$"):
                    self.setStyling(token[1], 8)
                elif token[0].isnumeric():
                    self.setStyling(token[1], 9)
                elif token[0].startswith('"'):
                    self.setStyling(token[1], 2)
                elif token[0] in directives:
                    self.setStyling(token[1], 7)
                elif token[0].startswith(";"):
                    self.setStyling(token[1], 3)
                elif token[0] in opcodes:
                    self.setStyling(token[1], 1)
                else:
                    self.setStyling(token[1], 0)

    def description(self, style):
        if style <=len(self.colors):
            return "myStyle_{}".format(style)
        else:
            return ""


class Menu(QMenu):
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)
        self.actions = dict()

def makePoint(x,y):
    print('test')
    return QPoint(x,y)
