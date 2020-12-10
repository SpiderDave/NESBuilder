"""
ToDo:
    * allow strings in instructions:
        lda "A"-$4b
    * create large test .asm
    * text mapping
    * option to automatically localize labels in macros
    * rept ... endr
"""


import math, os, sys
from . import include
Cfg = include.Cfg
import time
from datetime import datetime

import pathlib
import operator

import random

#try: import numpy as np
#except: np = False

# need better code for slicing with numpy.
# just disable for now.
np = False

def inScriptFolder(f):
    return os.path.join(os.path.dirname(os.path.realpath(__file__)),f)


class Assembler():
    currentFolder = None
    initialFolder = None
    currentTextMap = 'default'
    textMap = {}

    def __init__(self):
        pass
    def dummy(self):
        pass
    def mapText(self, text):
        #print("Mapping text:", text)
        textMap = self.textMap.get(self.currentTextMap, {})
        
        return [textMap.get(x, ord(x)) for x in text]
    def setTextMap(self, name):
        self.currentTextMap = name
    def getTextMap(self):
        return self.currentTextMap
    def clearTextMap(self, name=False):
        if not name:
            name = self.currentTextMap
        if name in self.textMap:
            self.textMap.pop(name)
    def setTextMapData(self, chars, mapTo):
        textMap = self.textMap.get(self.currentTextMap, {})
        textMap.update(dict(zip(chars,bytearray.fromhex(mapTo))))
        
        self.textMap[self.currentTextMap] = textMap
    def findFile(self, filename):
        
        # Search for files in this order:
        #   Exact match
        #   Relative to current script folder
        #   Relative to initial script folder
        #   Relative to current working folder
        #   Relative to top level of initial script folder
        #   Relative to executable folder
        files = [
            filename,
            os.path.join(self.currentFolder,filename),
            os.path.join(self.initialFolder,filename),
            os.path.join(os.getcwd(),filename),
            os.path.join(str(pathlib.Path(*pathlib.Path(self.initialFolder).parts[:1])),filename),
            os.path.join(os.path.dirname(os.path.realpath(__file__)),filename),
        ]
        
        for f in files:
            if os.path.isfile(f): return f
        
        return False

assembler = Assembler()


operations = {
#    '-':operator.sub,
#    '+':operator.add,
    '/':operator.truediv,
    '&':operator.and_,
    '^':operator.xor,
    '~':operator.invert,
    '|':operator.or_,
    '**':operator.pow,
    '<<':operator.lshift,
    '>>':operator.rshift,
    '%':operator.mod,
    '*':operator.mul,
}


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

directives = [
    'org','base','pad','align','fill', 'fillvalue',
    'include','incsrc','includeall','incbin','bin',
    'db','dw','byte','byt','word','hex','dc.b','dc.w',
    'dsb','dsw','ds.b','ds.w','dl','dh',
    'enum','ende','endenum',
    'print','warning','error',
    'setincludefolder',
    'macro','endm','endmacro',
    'if','ifdef','ifndef','else','elseif','endif','iffileexist','iffile',
    'arch',
    'index','mem','bank','banksize','header','define',
    '_find',
    'seed','outputfile','listfile','textmap','text',
]

asm=[
Map(opcode = 'adc', mode = 'Immediate', byte = 105, length = 2),
Map(opcode = 'adc', mode = 'Zero Page', byte = 101, length = 2),
Map(opcode = 'adc', mode = 'Zero Page, X', byte = 117, length = 2),
Map(opcode = 'adc', mode = 'Absolute', byte = 109, length = 3),
Map(opcode = 'adc', mode = 'Absolute, X', byte = 125, length = 3),
Map(opcode = 'adc', mode = 'Absolute, Y', byte = 121, length = 3),
Map(opcode = 'adc', mode = '(Indirect, X)', byte = 97, length = 2),
Map(opcode = 'adc', mode = '(Indirect), Y', byte = 113, length = 2),
Map(opcode = 'and', mode = 'Immediate', byte = 41, length = 2),
Map(opcode = 'and', mode = 'Zero Page', byte = 37, length = 2),
Map(opcode = 'and', mode = 'Zero Page, X', byte = 53, length = 2),
Map(opcode = 'and', mode = 'Absolute', byte = 45, length = 3),
Map(opcode = 'and', mode = 'Absolute, X', byte = 61, length = 3),
Map(opcode = 'and', mode = 'Absolute, Y', byte = 57, length = 3),
Map(opcode = 'and', mode = '(Indirect, X)', byte = 33, length = 2),
Map(opcode = 'and', mode = '(Indirect), Y', byte = 49, length = 2),
Map(opcode = 'asl', mode = 'Accumulator', byte = 10, length = 1),
Map(opcode = 'asl', mode = 'Zero Page', byte = 6, length = 2),
Map(opcode = 'asl', mode = 'Zero Page, X', byte = 22, length = 2),
Map(opcode = 'asl', mode = 'Absolute', byte = 14, length = 3),
Map(opcode = 'asl', mode = 'Absolute, X', byte = 30, length = 3),
Map(opcode = 'bcc', mode = 'Relative', byte = 144, length = 2),
Map(opcode = 'bcs', mode = 'Relative', byte = 176, length = 2),
Map(opcode = 'beq', mode = 'Relative', byte = 240, length = 2),
Map(opcode = 'bit', mode = 'Zero Page', byte = 36, length = 2),
Map(opcode = 'bit', mode = 'Absolute', byte = 44, length = 3),
Map(opcode = 'bmi', mode = 'Relative', byte = 48, length = 2),
Map(opcode = 'bne', mode = 'Relative', byte = 208, length = 2),
Map(opcode = 'bpl', mode = 'Relative', byte = 16, length = 2),
Map(opcode = 'brk', mode = 'Implied', byte = 0, length = 1),
Map(opcode = 'bvc', mode = 'Relative', byte = 80, length = 2),
Map(opcode = 'bvs', mode = 'Relative', byte = 112, length = 2),
Map(opcode = 'clc', mode = 'Implied', byte = 24, length = 1),
Map(opcode = 'cld', mode = 'Implied', byte = 216, length = 1),
Map(opcode = 'cli', mode = 'Implied', byte = 88, length = 1),
Map(opcode = 'clv', mode = 'Implied', byte = 184, length = 1),
Map(opcode = 'cmp', mode = 'Immediate', byte = 201, length = 2),
Map(opcode = 'cmp', mode = 'Zero Page', byte = 197, length = 2),
Map(opcode = 'cmp', mode = 'Zero Page, X', byte = 213, length = 2),
Map(opcode = 'cmp', mode = 'Absolute', byte = 205, length = 3),
Map(opcode = 'cmp', mode = 'Absolute, X', byte = 221, length = 3),
Map(opcode = 'cmp', mode = 'Absolute, Y', byte = 217, length = 3),
Map(opcode = 'cmp', mode = '(Indirect, X)', byte = 193, length = 2),
Map(opcode = 'cmp', mode = '(Indirect), Y', byte = 209, length = 2),
Map(opcode = 'cpx', mode = 'Immediate', byte = 224, length = 2),
Map(opcode = 'cpx', mode = 'Zero Page', byte = 228, length = 2),
Map(opcode = 'cpx', mode = 'Absolute', byte = 236, length = 3),
Map(opcode = 'cpy', mode = 'Immediate', byte = 192, length = 2),
Map(opcode = 'cpy', mode = 'Zero Page', byte = 196, length = 2),
Map(opcode = 'cpy', mode = 'Absolute', byte = 204, length = 3),
Map(opcode = 'dec', mode = 'Zero Page', byte = 198, length = 2),
Map(opcode = 'dec', mode = 'Zero Page, X', byte = 214, length = 2),
Map(opcode = 'dec', mode = 'Absolute', byte = 206, length = 3),
Map(opcode = 'dec', mode = 'Absolute, X', byte = 222, length = 3),
Map(opcode = 'dex', mode = 'Implied', byte = 202, length = 1),
Map(opcode = 'dey', mode = 'Implied', byte = 136, length = 1),
Map(opcode = 'eor', mode = 'Immediate', byte = 73, length = 2),
Map(opcode = 'eor', mode = 'Zero Page', byte = 69, length = 2),
Map(opcode = 'eor', mode = 'Zero Page, X', byte = 85, length = 2),
Map(opcode = 'eor', mode = 'Absolute', byte = 77, length = 3),
Map(opcode = 'eor', mode = 'Absolute, X', byte = 93, length = 3),
Map(opcode = 'eor', mode = 'Absolute, Y', byte = 89, length = 3),
Map(opcode = 'eor', mode = '(Indirect, X)', byte = 65, length = 2),
Map(opcode = 'eor', mode = '(Indirect), Y', byte = 81, length = 2),
Map(opcode = 'inc', mode = 'Zero Page', byte = 230, length = 2),
Map(opcode = 'inc', mode = 'Zero Page, X', byte = 246, length = 2),
Map(opcode = 'inc', mode = 'Absolute', byte = 238, length = 3),
Map(opcode = 'inc', mode = 'Absolute, X', byte = 254, length = 3),
Map(opcode = 'inx', mode = 'Implied', byte = 232, length = 1),
Map(opcode = 'iny', mode = 'Implied', byte = 200, length = 1),
Map(opcode = 'jmp', mode = 'Indirect', byte = 108, length = 3),
Map(opcode = 'jmp', mode = 'Absolute', byte = 76, length = 3),
Map(opcode = 'jsr', mode = 'Absolute', byte = 32, length = 3),
Map(opcode = 'lda', mode = 'Immediate', byte = 169, length = 2),
Map(opcode = 'lda', mode = 'Zero Page', byte = 165, length = 2),
Map(opcode = 'lda', mode = 'Zero Page, X', byte = 181, length = 2),
Map(opcode = 'lda', mode = 'Absolute', byte = 173, length = 3),
Map(opcode = 'lda', mode = 'Absolute, X', byte = 189, length = 3),
Map(opcode = 'lda', mode = 'Absolute, Y', byte = 185, length = 3),
Map(opcode = 'lda', mode = '(Indirect, X)', byte = 161, length = 2),
Map(opcode = 'lda', mode = '(Indirect), Y', byte = 177, length = 2),
Map(opcode = 'ldx', mode = 'Zero Page', byte = 166, length = 2),
Map(opcode = 'ldx', mode = 'Zero Page, Y', byte = 182, length = 2),
Map(opcode = 'ldx', mode = 'Absolute', byte = 174, length = 3),
Map(opcode = 'ldx', mode = 'Absolute, Y', byte = 190, length = 3),
Map(opcode = 'ldx', mode = 'Immediate', byte = 162, length = 2),
Map(opcode = 'ldy', mode = 'Immediate', byte = 160, length = 2),
Map(opcode = 'ldy', mode = 'Zero Page', byte = 164, length = 2),
Map(opcode = 'ldy', mode = 'Zero Page, X', byte = 180, length = 2),
Map(opcode = 'ldy', mode = 'Absolute', byte = 172, length = 3),
Map(opcode = 'ldy', mode = 'Absolute, X', byte = 188, length = 3),
Map(opcode = 'lsr', mode = 'Accumulator', byte = 74, length = 1),
Map(opcode = 'lsr', mode = 'Zero Page', byte = 70, length = 2),
Map(opcode = 'lsr', mode = 'Zero Page, X', byte = 86, length = 2),
Map(opcode = 'lsr', mode = 'Absolute', byte = 78, length = 3),
Map(opcode = 'lsr', mode = 'Absolute, X', byte = 94, length = 3),
Map(opcode = 'nop', mode = 'Implied', byte = 234, length = 1),
Map(opcode = 'ora', mode = 'Immediate', byte = 9, length = 2),
Map(opcode = 'ora', mode = 'Zero Page', byte = 5, length = 2),
Map(opcode = 'ora', mode = 'Zero Page, X', byte = 21, length = 2),
Map(opcode = 'ora', mode = 'Absolute', byte = 13, length = 3),
Map(opcode = 'ora', mode = 'Absolute, X', byte = 29, length = 3),
Map(opcode = 'ora', mode = 'Absolute, Y', byte = 25, length = 3),
Map(opcode = 'ora', mode = '(Indirect, X)', byte = 1, length = 2),
Map(opcode = 'ora', mode = '(Indirect), Y', byte = 17, length = 2),
Map(opcode = 'pha', mode = 'Implied', byte = 72, length = 1),
Map(opcode = 'php', mode = 'Implied', byte = 8, length = 1),
Map(opcode = 'pla', mode = 'Implied', byte = 104, length = 1),
Map(opcode = 'plp', mode = 'Implied', byte = 40, length = 1),
Map(opcode = 'rol', mode = 'Accumulator', byte = 42, length = 1),
Map(opcode = 'rol', mode = 'Zero Page', byte = 38, length = 2),
Map(opcode = 'rol', mode = 'Zero Page, X', byte = 54, length = 2),
Map(opcode = 'rol', mode = 'Absolute', byte = 46, length = 3),
Map(opcode = 'rol', mode = 'Absolute, X', byte = 62, length = 3),
Map(opcode = 'ror', mode = 'Accumulator', byte = 106, length = 1),
Map(opcode = 'ror', mode = 'Zero Page', byte = 102, length = 2),
Map(opcode = 'ror', mode = 'Zero Page, X', byte = 118, length = 2),
Map(opcode = 'ror', mode = 'Absolute', byte = 110, length = 3),
Map(opcode = 'ror', mode = 'Absolute, X', byte = 126, length = 3),
Map(opcode = 'rti', mode = 'Implied', byte = 64, length = 1),
Map(opcode = 'rts', mode = 'Implied', byte = 96, length = 1),
Map(opcode = 'sbc', mode = 'Immediate', byte = 233, length = 2),
Map(opcode = 'sbc', mode = 'Zero Page', byte = 229, length = 2),
Map(opcode = 'sbc', mode = 'Zero Page, X', byte = 245, length = 2),
Map(opcode = 'sbc', mode = 'Absolute', byte = 237, length = 3),
Map(opcode = 'sbc', mode = 'Absolute, X', byte = 253, length = 3),
Map(opcode = 'sbc', mode = 'Absolute, Y', byte = 249, length = 3),
Map(opcode = 'sbc', mode = '(Indirect, X)', byte = 225, length = 2),
Map(opcode = 'sbc', mode = '(Indirect), Y', byte = 241, length = 2),
Map(opcode = 'sec', mode = 'Implied', byte = 56, length = 1),
Map(opcode = 'sed', mode = 'Implied', byte = 248, length = 1),
Map(opcode = 'sei', mode = 'Implied', byte = 120, length = 1),
Map(opcode = 'sta', mode = 'Zero Page', byte = 133, length = 2),
Map(opcode = 'sta', mode = 'Zero Page, X', byte = 149, length = 2),
Map(opcode = 'sta', mode = 'Absolute', byte = 141, length = 3),
Map(opcode = 'sta', mode = 'Absolute, X', byte = 157, length = 3),
Map(opcode = 'sta', mode = 'Absolute, Y', byte = 153, length = 3),
Map(opcode = 'sta', mode = '(Indirect, X)', byte = 129, length = 2),
Map(opcode = 'sta', mode = '(Indirect), Y', byte = 145, length = 2),
Map(opcode = 'stx', mode = 'Zero Page', byte = 134, length = 2),
Map(opcode = 'stx', mode = 'Zero Page, Y', byte = 150, length = 2),
Map(opcode = 'stx', mode = 'Absolute', byte = 142, length = 3),
Map(opcode = 'sty', mode = 'Zero Page', byte = 132, length = 2),
Map(opcode = 'sty', mode = 'Zero Page, X', byte = 148, length = 2),
Map(opcode = 'sty', mode = 'Absolute', byte = 140, length = 3),
Map(opcode = 'tax', mode = 'Implied', byte = 170, length = 1),
Map(opcode = 'tay', mode = 'Implied', byte = 168, length = 1),
Map(opcode = 'tsx', mode = 'Implied', byte = 186, length = 1),
Map(opcode = 'txa', mode = 'Implied', byte = 138, length = 1),
Map(opcode = 'txs', mode = 'Implied', byte = 154, length = 1),
Map(opcode = 'tya', mode = 'Implied', byte = 152, length = 1),
]


# Converting to dictionary removes duplicates
opcodes = list(dict.fromkeys([x.opcode for x in asm]))

implied = [x.opcode for x in asm if x.mode=='Implied']
accumulator = [x.opcode for x in asm if x.mode=="Accumulator"]
ifDirectives = ['if','endif','else','elseif','ifdef','ifndef','iffileexist','iffile']

mergeList = lambda a,b: [(a[i], b[i]) for i in range(min(len(a),len(b)))]
makeHex = lambda x: '$'+x.to_bytes(((x.bit_length()|1  + 7) // 8),"big").hex()

specialSymbols = ['sdasm','bank','randbyte','randword']
timeSymbols = ['year','month','day','hour','minute','second']

specialSymbols+= timeSymbols

def assemble(filename, outputFilename = 'output.bin', listFilename = False, configFile=False, fileData=False, binFile=False):
    if not configFile:
        configFile = inScriptFolder('config.ini')
    
    cfg = False
    # create our config parser
    cfg = Cfg(configFile)

    # read config file if it exists
    cfg.load()

    # number of bytes to show when generating list
    cfg.setDefault('main', 'list_nBytes', 8)
    cfg.setDefault('main', 'comment', ';,//')
    cfg.setDefault('main', 'commentBlockOpen', '/*')
    cfg.setDefault('main', 'commentBlockClose', '*/')
    cfg.setDefault('main', 'nestedComments', True)
    cfg.setDefault('main', 'fillValue', '$00')
    cfg.setDefault('main', 'localPrefix', '@')
    cfg.setDefault('main', 'debug', False)
    cfg.setDefault('main', 'varOpen', '{')
    cfg.setDefault('main', 'varClose', '}')
    cfg.setDefault('main', 'labelSuffix', ':')

    # save configuration so our defaults can be changed
    cfg.save()

    _assemble(filename, outputFilename, listFilename, cfg=cfg, fileData=fileData, binFile=binFile)

def _assemble(filename, outputFilename, listFilename, cfg, fileData, binFile):
    def bytesForNumber(n):
        return len(hex(n))-1 >>1
    
    def getValueAsString(s):
        return getString(getValue(s))
    
    def getString(s, strip=True):
        if type(s) is list:
            s = bytes(s).decode()
        
        if strip:
            s=s.strip()
        
        quotes = ['"""','"',"'"]
        for q in quotes:
            #if s.startswith(q) and s.endswith(q):
            if s.strip().startswith(q) and s.strip().endswith(q):
                s=s.strip()
                s=s[len(q):-len(q)]
                return s
        return s
    
    def getSpecial(s):
        if s == 'sdasm':
            v = 1
        elif s == 'bank':
            if bank == None:
                return ''
            else:
                return makeHex(bank)
        elif s == 'randbyte':
            return makeHex(random.randrange(0x100))
        elif s == 'randword':
            #return makeHex(random.randrange(0x10000))
            return '${:04x}'.format(random.randrange(0x10000))
        elif s in timeSymbols:
            v = list(datetime.now().timetuple())[timeSymbols.index(s)]
        if type(v) in (int,float):
            return makeHex(v)
        else:
            return v
    def findFile(filename):
        return assembler.findFile(filename)
    
    def makeList(item):
        if type(item)!=list:
            return [item]
        else:
            return item
    
    def isImmediate(v):
        if v.startswith("#"):
            return True
        else:
            return False

    def isNumber(v):
        return all([x in "0123456789" for x in str(v)])

    def getValueAndLength(v, mode=False, param=False, hint=False):
        if type(v) is int:
            l = 1 if v <=256 else 2
            return v,l
        
        if v.startswith("[") and v.endswith("]"):
            v = v[1:-1]
        
        v = v.strip()
        l = False
        
        v=v.replace(", ",",").replace(" ,",",")
        if v.startswith("(") and v.endswith(")"):
            v = v[1:-1]
        if v.endswith(",x"):
            v = v.split(",x")[0]
        if v.endswith(",y"):
            v = v.split(",y")[0]
        if v.startswith("(") and v.endswith(")"):
            v = v[1:-1]
        
        if v=='':
            return 0,0
        
        
        if ',' in v:
            v = [getValue(x) for x in v.split(',')]
            l = len(v)
            if mode == 'shuffle':
                random.shuffle(v)
            elif mode == 'choose':
                random.shuffle(v)
                v=v[0]
                l=1
                
            return v,l
        if v.startswith('-'):
            label = v.split(' ',1)[0]
            if len(aLabels) > 0:
                return [x[1] for x in aLabels if x[0]==label and x[1]<currentAddress][-1], 2
            else:
                # negative number?
                return -1, 0
        if v.startswith('+'):
            label = v.split(' ',1)[0]
            try:
                return [x[1] for x in aLabels if x[0]==label and x[1]>=currentAddress][0], 2
            except:
                return 0,0
        
        if v.startswith('"') and v.endswith('"'):
            v = list(bytes(v[1:-1], 'utf-8'))
            l=len(v)
            return v, l
        # ToDo: tokenize, allow (), implement proper order of operations.
        if '+' in v:
            v = v.split('+')
            left, right = getValue(v[0]), getValue(v[1])
            if type(left)==type(right):
                v = left + right
            elif type(left)==list:
                v = [x+right for x in left]
                return v,len(v)
            else:
                return 0, 1
            l = 1 if v <=256 else 2
            return v,l
        if '-' in v:
            v = v.split('-')
            left, right = getValue(v[0]), getValue(v[1])
            if type(left)==type(right):
                v = left - right
            elif type(left)==list:
                v = [x-right for x in left]
                return v,len(v)
            else:
                return 0, 1
            l = 1 if v <=256 else 2
            return v,l
        
        if v.startswith("<"):
            v = getValue(v[1:]) % 0x100
            l = 1
            return v,l
        if v.startswith(">"):
            v = getValue(v[1:]) >> 8
            l = 1
            return v,l
        
        if v == '$' or v.lower() == 'pc':
            v = currentAddress
            l=2
        elif v.lower() == 'randbyte':
            v = random.randrange(0,256)
            l=1
        elif v.startswith("$"):
            v = int(v[1:],16)
            l = bytesForNumber(v)
        elif v.startswith("%"):
            l = 1
            v = int(v[1:],2)
        elif any(x in v for x in operations):
            for op in operations:
                if op in v:
                    v = v.split(op)
                    v = operations[op](getValue(v[0]), getValue(v[1]))
                    l = 1 if v <=256 else 2
                    return v,l
        elif isNumber(v):
            l = 1 if int(v,10) <=256 else 2
            v = int(v,10)
        elif v.lower() in symbols:
            v, l = getValueAndLength(symbols[v.lower()])
        elif v.lower() in specialSymbols:
            v, l = getValueAndLength(getSpecial(v.lower()))
        else:
            if passNum==2:
                #errorText= 'invalid value: {}'.format(v)
                #print('*** '+errorText)
                pass
            v = 0
            l = -1
        
        if mode == 'getbyte':
            # this looks like the right result but i don't know why
            # i have to subtract the 0x4000
            if bank:
                fileOffset = v - 0x8000 + (bank * bankSize) + headerSize - 0x4000
            else:
                fileOffset = v - 0x8000 + headerSize - 0x4000
            v = int(out[fileOffset])
            l = 1
        if mode == 'getword':
            if bank:
                fileOffset = v - 0x8000 + (bank * bankSize) + headerSize - 0x4000
            else:
                fileOffset = v - 0x8000 + headerSize - 0x4000
            v = int(out[fileOffset]) + int(out[fileOffset+1]) * 0x100
            l = 2
        
        if mode == 'hexstring':
            v = "test"
            l=len(v)
#        if mode == 'format':
#            fmtString = '{:' + param + '}'
#            print('v = ',v)
#            v = fmtString.format(v)
#            l=len(v)
        return v, l

    def getValue(v, mode=False, param=False, hint=False):
        return getValueAndLength(v, mode=mode, param=param, hint=hint)[0]
    def getLength(v, mode=False, param=False, hint=False):
        return getValueAndLength(v, mode=mode, param=param, hint=hint)[1]

    def getOpWithMode(opcode,mode):
        ops = [x for x in asm if x.opcode==opcode]
        if mode in [x.mode for x in ops]:
            return [x for x in ops if x.mode==mode][0]
        else:
            return False

    commentSep = makeList(cfg.getValue('main', 'comment'))
    commentBlockOpen = makeList(cfg.getValue('main', 'commentBlockOpen'))
    commentBlockClose = makeList(cfg.getValue('main', 'commentBlockClose'))
    fillValue = getValue(cfg.getValue('main', 'fillValue'))
    localPrefix = makeList(cfg.getValue('main', 'localPrefix'))
    debug = cfg.isTrue(cfg.getValue('main', 'debug'))
    varOpen = makeList(cfg.getValue('main', 'varOpen'))
    varClose = makeList(cfg.getValue('main', 'varClose'))
    varOpenClose = mergeList(varOpen,varClose)
    labelSuffix = makeList(cfg.getValue('main', 'labelSuffix'))
    
    try:
        file = open(filename, "r")
    except:
        print("Error: could not open file.")
        exit()
    
    print('sdasm')
    print(filename)
    
    assembler.initialFolder = os.path.split(filename)[0]
    assembler.currentFolder = assembler.initialFolder
    print(assembler.findFile('list.txt'))

    # Doing it this way removes the line endings
    lines = file.read().splitlines()
    originalLines = lines

    symbols = Map()
    equ = Map()
    
    # Allow lda.b, lda.w, etc.
    # It wont set the byte size but this is better than nothing.
    def alias(opcode):
        equ[opcode+'.b']=opcode
        equ[opcode+'.w']=opcode
    
    for o in opcodes:
        alias(o)
    
    aLabels = []
    lLabels = []
    macros = Map()
    blockComment = 0
    
    if binFile:
        binFile = findFile(binFile)
        with open(binFile,'rb') as file:
            fileData = file.read()
    
    for passNum in (1,2):
        lines = originalLines
        addr = 0
        oldAddr = 0
        
        noOutput = False
        
        macro = False
        currentAddress = addr
        mode = ""
        showAddress = False
        out = []
        
        if type(fileData) != bool:
            out = list(fileData)
        
        if np:
            out = np.array([],dtype="B")
        
        outputText = ''
        startAddress = False
#        assembler.currentFolder = ''
#        assembler.currentFolder = os.path.split(filename)[0]
        assembler.currentFolder = assembler.initialFolder
        ifLevel = 0
        ifData = Map()
        arch = 'nes.cpu'
        headerSize = 0
        bankSize = 0x10000
        bank = None
        
        fileList = []
        print('pass {}...'.format(passNum))
        
        for i in range(10000000):
            if i>len(lines)-1:
                break
            line = lines[i]
            
            hide = False
            
            #currentAddress = addr
            originalLine = line
            errorText = False
            
            #print(originalLine)
            
            # change tabs to spaces
            line = line.replace("\t"," ")
            
            # remove single line comments
            for sep in commentSep:
                line = line.strip().split(sep,1)[0].strip()
            
            # remove comment blocks
            for sep in commentBlockOpen:
                if sep in line:
                    line = line.strip().split(sep,1)[0].strip()
                    blockComment+=1
            for sep in commentBlockClose:
                if sep in line:
                    line = line.strip().split(sep,1)[1].strip()
                    blockComment-=1
                    if cfg.isFalse(cfg.getValue('main', 'nestedComments')):
                        blockComment = 0
            if blockComment>0:
                line = ''
            
            # "EQU" replacement
            for item in equ:
                line = line.replace(item, equ[item])
            
            # {var} replacement
            for o,c in varOpenClose:
                if o in line and c in line:
                    while o+":" in line:
                        start = line.find('{:')
                        end = line.find('}', start)
                        
                        line = line.replace(line[start:end+1], str(getValue(line[start+2:end])))
                    
                    for item in specialSymbols:
                        if o+item+c in line:
                            s = getSpecial(item)
                            line = line.replace(o+item+c, s)
                    
                    for item in ['shuffle','getbyte','getword','choose','hexstring','format']:
                        while o+item+":" in line:
                            start = line.find('{'+item+':')
                            end = line.find('}', start)
                            
                            if item == 'format':
                                fmtStart = line.find(':',start)+1
                                fmtEnd = line.find(':',fmtStart)
                                fmtString = '{:' + line[fmtStart:fmtEnd] + '}'
                                l = getValue(line[fmtEnd+1:end])
                                l = fmtString.format(l)
                            else:
                                l = getValue(line[start+2+len(item):end], mode=item)
                            
                            if type(l) is int:
                                l = str(l)
                            elif type(l) is list:
                                l = ','.join([str(x) for x in l])
                            line = line.replace(line[start:end+1], l)
                    
                    while o in line:
                        start = line.find(o)
                        end = line.find(c, start)
                        
                        line = line.replace(line[start:end+1], str(getValue(line[start+1:end])))
            
            if ifLevel:
                if ifLevel>1 and ifData[ifLevel-1].bool == False:
                    ifData[ifLevel].bool = False
                    ifData[ifLevel].done = True

                if ifData[ifLevel].bool == False:
                    
                    key = line.split(" ",1)[0].strip().lower()
                    if key.startswith('.'):
                        key = key[1:]
                    
                    if key not in ifDirectives:
                        ifData.line = line
                        line = ''
            
            if macro:
                if line.split(" ",1)[0].strip().lower() not in ['endm','endmacro','.endm','.endmacro']:
                    macros[macro].lines.append(originalLine)
                    line = ''
            
            b=[]
            k = line.split(" ",1)[0].strip().lower()
            
            if k!='' and (k=="-"*len(k) or k=="+"*len(k)):
#                if not [k,addr] in aLabels:
#                    aLabels.append([k, addr])
                if not [k,currentAddress] in aLabels:
                    aLabels.append([k, currentAddress])
                    
                    # update so rest of line can be processed
                    line = (line.split(" ",1)+[''])[1].strip()
                    k = line.split(" ",1)[0].strip().lower()
            
            # This is really complicated but we have to check to see
            # if this is a label without a suffix somehow.
            if k!='' and not (k.startswith('.') and k[1:] in directives) and not k.endswith(tuple(labelSuffix)) and ' equ ' not in line.lower() and '=' not in line and k not in list(directives)+list(macros)+list(opcodes):
                if debug: print('label without suffix: {}'.format(k))
                k=k+labelSuffix[0]
            if k.endswith(tuple(labelSuffix)):
                symbols[k[:-1].lower()] = str(currentAddress)
                
                # remove all local labels
                if not k.startswith(tuple(localPrefix)):
                    symbols = {k:v for (k,v) in symbols.items() if not k.startswith(tuple(localPrefix))}
                
                # update so rest of line can be processed
                line = (line.split(" ",1)+[''])[1].strip()
                k = line.split(" ",1)[0].strip().lower()
            
            # prefix is optional for valid directives
            if k.startswith(".") and k[1:] in directives:
                k=k[1:]
            
            if k == 'ifdef':
                ifLevel+=1
                ifData[ifLevel] = Map()
                
                data = line.split(" ",1)[1].strip().replace('==','=').lower()
                if data in symbols:
                    ifData[ifLevel].bool = True
                    ifData[ifLevel].done = True
                else:
                    ifData[ifLevel].bool = False
            elif k == 'ifndef':
                ifLevel+=1
                ifData[ifLevel] = Map()
                
                data = line.split(" ",1)[1].strip().replace('==','=').lower()
                
                if data in symbols:
                    ifData[ifLevel].bool = False
                else:
                    ifData[ifLevel].bool = True
                    ifData[ifLevel].done = True
            elif k == 'elseif':
                if ifData[ifLevel].done:
                    ifData[ifLevel].bool=False
                else:
                    k = 'if'
            elif k == 'iffileexist' or k == 'iffile':
                ifLevel+=1
                ifData[ifLevel] = Map()
                
                data = line.split(" ",1)[1].strip()
                data = getString(data)
                if findFile(data):
                    ifData[ifLevel].bool = True
                    ifData[ifLevel].done = True
                else:
                    ifData[ifLevel].bool = False
                #print('ifLevel',ifLevel)
            if k == 'if':
#                print(line)
#                print('***ifLevel',ifLevel)
                ifLevel+=1
                ifData[ifLevel] = Map()
                
                data = line.split(" ",1)[1].strip().replace('==','=')
                
                if '=' in data:
                    l,r = data.split('=')
                    if getValue(l) == getValue(r):
                        ifData[ifLevel].bool = True
                        ifData[ifLevel].done = True
                    else:
                        ifData[ifLevel].bool = False
                else:
                    if getValue(data):
                        ifData[ifLevel].bool = True
                        ifData[ifLevel].done = True
                    else:
                        ifData[ifLevel].bool = False
#                if ifLevel>1 and ifData[ifLevel-1].done == True:
#                    ifData[ifLevel].bool = False

            if k == 'else':
                ifData[ifLevel].bool = not ifData[ifLevel].done
            elif k == 'endif':
                ifLevel-=1
            elif k == 'arch':
                arch = line.split(" ")[1].strip().lower()
                if debug:
                    print('  Architecture: {}'.format(arch))
            elif k == 'header':
                headerSize = 16
            elif k == 'banksize':
                bankSize = getValue(line.split(" ")[1].strip())
            elif k == 'bank':
                bank = getValue(line.split(" ")[1].strip())
#                if debug:
#                    print('  Bank: {}'.format(bank))
            
            elif k == 'seed':
                v = getValue(line.split(" ")[1].strip())
                random.seed(v)
            elif k == 'textmap':
                data = line.split(' ',1)[1]
                
                if data.lower() == 'clear':
                    assembler.clearTextMap()
                else:
                    data = data.split()
                    if data[0].lower() == 'space':
                        data[0] = ' '
                    elif '...' in data[0]:
                        c1,c2 = data[0].split('...')
                        data[0] = ''.join([chr(c) for c in range(ord(c1), ord(c2)+1)])
                        
                        n1 = int(data[1],16)
                        data[1] = ''.join(['{:02x}'.format(x) for x in range(n1,n1+len(data[0]))])
                    
                    if data[0].lower() == 'set':
                        assembler.setTextMap(data[1])
                    else:
                        assembler.setTextMapData(data[0], data[1])
            elif k == 'outputfile':
                outputFilename = getValueAsString(line.split(" ",1)[1].strip())
            elif k == 'listfile':
                listFilename = getValueAsString(line.split(" ",1)[1].strip())
                
                if listFilename.lower() in ('false','0','none', ''):
                    listFilename = False
            
            # hidden internally used directive used with include paths
            if k == "setincludefolder":
                assembler.currentFolder = (line.split(" ",1)+[''])[1].strip()
                hide = True
            
            elif k == "incbin" or k == "bin":
                filename = line.split(" ",1)[1].strip()
                filename = getString(filename)
                filename = findFile(filename)
                
                b=False
                try:
                    with open(filename, 'rb') as file:
                        b = list(file.read())
                except:
                    print("Could not open file.")
                if b:
                    fileList.append(filename)
                    lines = lines[:i]+['']+['setincludefolder '+assembler.currentFolder]+lines[i+1:]
            elif k == "include" or k=="incsrc":
                filename = line.split(" ",1)[1].strip()
                filename = getString(filename)
                filename = findFile(filename)
                
                newLines = False
                try:
                    with open(filename, 'r') as file:
                        newLines = file.read().splitlines()
                except:
                    print("Could not open file.")
                
                if newLines:
                    fileList.append(filename)
                    folder = os.path.split(filename)[0]
                    
                    newLines = ['setincludefolder '+folder]+newLines+['setincludefolder '+assembler.currentFolder]
                    assembler.currentFolder = folder
                    
                    lines = lines[:i]+['']+newLines+lines[i+1:]
            elif k == 'includeall':
                folder = line.split(" ",1)[1].strip()
                files = [x for x in os.listdir(folder) if os.path.splitext(x.lower())[1] in ['.asm']]
                files = [x for x in files if not x.startswith('_')]
                lines = lines[:i]+['']+['include {}/{}'.format(folder, x) for x in files]+lines[i+1:]
            
            elif k == 'print' and passNum==2:
                v = line.split(" ",1)[1].strip()
                print(getString(v))
            elif k == 'warning' and passNum==2:
                v = line.split(" ",1)[1].strip()
                print('warning: ' + v)
            elif k == 'error' and passNum==2:
                v = line.split(" ",1)[1].strip()
                print('Error: ' + v)
                exit()
            
            elif k == '_find':
                data = line.split(' ',1)[1]
                findData = list(bytes.fromhex(''.join(['0'*(len(x)%2) + x for x in data.split()])))
                #b = b + list(bytes.fromhex(''.join(['0'*(len(x)%2) + x for x in data.split()])))
                result = [i for i in range(len(out)-len(findData)+1) if out[i:i+len(findData)]==findData]
                a = result[0]
                print([hex(x-headerSize) for x in result])
                
                a = (a-headerSize)
                resultBank = math.floor(a/bankSize)
                a=a-resultBank*bankSize+0x8000
                print('{:02x}:{:04x}'.format(resultBank,a))
                
            elif k == 'macro':
                v = line.split(" ")[1].strip()
                macro = v.lower()
                macros[macro]=Map()
                data = line.split(" ", 2)
                macros[macro].params = (data+[''])[2].replace(',',' ').split()
                macros[macro].lines = []
                noOutput = True
            elif k == 'endm' or k == 'endmacro':
                macro = False
                noOutput = False
            
            if k in macros:
                params = (line.split(" ",1)+[''])[1].replace(',',' ').split()
                
                for item in macros[k].params:
                    if item.lower() in symbols:
                        symbols.pop(item.lower())
                
                for item in mergeList(macros[k].params, params):
                    symbols[item[0].lower()] = item[1]
                
                lines = lines[:i]+['']+macros[k].lines+lines[i+1:]
                
            if k == 'enum':
                oldAddr = addr
                addr = getValue(v)
                currentAddress = addr
                noOutput = True
            elif k == 'ende' or k == 'endenum':
                addr = oldAddr
                currentAddress = addr
                noOutput = False
            
            elif k == 'base':
                addr = getValue(line.split(' ',1)[1])
                if startAddress == False:
                    startAddress = addr
                currentAddress = addr
            
            elif k == 'org':
                addr = getValue(line.split(' ',1)[1])
                
                currentAddress = addr
                
                if bank != None:
                    addr = addr % bankSize
                
                if startAddress==False:
                    startAddress = addr
                    k = 'pad'
                    line = 'pad ${:04x}'.format(addr)
                
            if k == 'pad':
                data = line.split(' ',1)[1]
                
                fv = fillValue
                if ',' in data:
                    fv = getValue(data.split(',')[1])
                a = getValue(data.split(',')[0])
                b = b + ([fv] * (a-currentAddress))
            elif k == 'fill':
                data = line.split(' ',1)[1]
                
                fv = fillValue
                if ',' in data:
                    fv = getValue(data.split(',')[1])
                n = getValue(data.split(',')[0])
                
                b = b + ([fv] * n)
            elif k == 'align':
                data = line.split(' ',1)[1]
                
                fv = fillValue
                if ',' in data:
                    fv = getValue(data.split(',')[1])
                a = getValue(data.split(',')[0])
                
                b = b + ([fv] * ((a-currentAddress%a)%a))
                
            elif k == 'hex':
                data = line.split(' ',1)[1]
                b = b + list(bytes.fromhex(''.join(['0'*(len(x)%2) + x for x in data.split()])))
            
            elif k == 'dsb' or k == 'ds.b':
                data = line.split(' ',1)[1]
                n = getValue(data.split(",")[0])
                v = getValue((data.split(",")+['0'])[1])
                b = b + [v] * n
                
            elif k == 'dsw' or k == 'ds.w':
                data = line.split(' ',1)[1]
                n = getValue(data.split(",")[0])
                v = getValue((data.split(",")+['0'])[1])
                b = b + [v % 0x100, v>>8] * n
                
            elif k == "dl":
                values = line.split(' ',1)[1].split(",")
                values = [x.strip() for x in values]
                
                for v in [getValue(x) % 0x100 for x in values]:
                    b = b + makeList(v)
            
            elif k == "dh":
                values = line.split(' ',1)[1].split(",")
                values = [x.strip() for x in values]
                
                for v in [getValue(x) >>8 for x in values]:
                    b = b + makeList(v)
            
            elif k == 'text':
                values = line.split(' ',1)[1]
                values = getValue(values)
                values = assembler.mapText(getString(values, strip=False))
                #values = getValue(values)
                b = b + makeList(values)
            elif k == 'db' or k=='byte' or k == 'byt' or k == 'dc.b':
                values = line.split(' ',1)[1]
                values = getValue(values)
                b = b + makeList(values)
                
#                for v in [getValue(x) for x in values]:
#                    b = b + makeList(v)
                
#                values = line.split(' ',1)[1].split(",")
#                values = [x.strip() for x in values]
                
#                for v in [getValue(x) for x in values]:
#                    b = b + makeList(v)
                
            elif k == "dw" or k=="word" or k=='dbyt' or k == 'dc.w':
                values = line.split(' ',1)[1].split(",")
                values = [x.strip() for x in values]
                values = [getValue(x) for x in values]
                
                for value in values:
                    b = b + [value % 0x100, value>>8]
                
            elif k in opcodes:
                # Special handling for pseudo opcode
                # Example:
                # nop $06 ; 6 nop instructions
                if k == 'nop':
                    v = (line.split(" ",1)+[''])[1].strip()
                    if v:
                        op = getOpWithMode(k, "Implied") # op will be set to False below
                        b=b+([op.byte] * getValue(v))
                    
                v = "0"
                if k in implied and k.strip() == line.strip().lower():
                    op = getOpWithMode(k, "Implied")
                elif k in accumulator and k.strip() == line.strip().lower():
                    op = getOpWithMode(k, "Accumulator")
                elif line.strip().lower() in [x+' a' for x in accumulator]:
                    op = getOpWithMode(k, "Accumulator")
                else:
                    op = False
                    ops = [x for x in asm if x.opcode==k]
                    
                    v = (line.split(" ",1)+[''])[1].strip()
                    v=v.replace(', ',',').replace(' ,',',')
                    
                    if k == "jmp" and v.startswith("("):
                        op = getOpWithMode(k, 'Indirect')
                    elif v.endswith('),y'):
                        op = getOpWithMode(k, '(Indirect), Y')
                    elif v.endswith(',x)'):
                        op = getOpWithMode(k, '(Indirect, X)')
                    elif v.endswith(',x'):
                        v = v.split(',x',1)[0]
                        if getLength(v)==1 and getOpWithMode(k, 'Zero Page, X'):
                            op = getOpWithMode(k, 'Zero Page, X')
                        elif getOpWithMode(k, 'Absolute, X'):
                            op = getOpWithMode(k, 'Absolute, X')
                    elif v.endswith(',y'):
                        v = v.split(',y',1)[0]
                        if getLength(v)==1 and getOpWithMode(k, 'Zero Page, Y'):
                            op = getOpWithMode(k, 'Zero Page, Y')
                        elif getOpWithMode(k, 'Absolute, Y'):
                            op = getOpWithMode(k, 'Absolute, Y')
                    elif v.startswith("#"):
                        v = v[1:]
                        op = getOpWithMode(k, 'Immediate')
                    else:
                        if getLength(v)==1 and getOpWithMode(k, 'Zero Page'):
                            op = getOpWithMode(k, "Zero Page")
                        elif getOpWithMode(k, "Absolute"):
                            op = getOpWithMode(k, "Absolute")
                        elif getOpWithMode(k, "Relative"):
                            op = getOpWithMode(k, "Relative")
                if op:
                    if op.mode == 'Relative' and passNum==2:
                        if getValue(v) > currentAddress+op.length:
                            v = getValue(v) - (currentAddress+op.length)
                            v='${:02x}'.format(v)
                        else:
                            v = (currentAddress+op.length) - getValue(v)
                            v='${:02x}'.format(0x100 - v)
                    
                    v,l = getValueAndLength(v)
                    l = bytesForNumber(v)
                    
                    if (op.length>1) and l>op.length-1:
                        b = [op.byte] + [0] * (op.length-1)
                        #errorText= 'out of range: {} {} {}'.format(op.length, hex(v),l)
                        errorText= 'branch out of range: {}'.format(hex(v))
                    else:
                        b = [op.byte]
                        if op.length == 2:
                            b.append(v % 0x100)
                        elif op.length == 3:
                            b.append(v % 0x100)
                            b.append(math.floor(v/0x100))
            
            if k == 'define':
                k = line.split(" ")[1].strip()
                v = line.split(" ",2)[-1].strip()
                if k == '$':
                    addr = getValue(v)
                    if startAddress == False:
                        startAddress = addr
                    currentAddress = addr
                else:
                    symbols[k.lower()] = v
                k=''

            
            if ' equ ' in line.lower():
                k = line[:line.lower().find(' equ ')]
                v = line[line.lower().find(' equ ')+len(' equ '):]
                equ[k] = v
            elif (line.split('=')+[''])[1]:
                k = line.split("=",1)[0].strip()
                v = line.split("=",1)[1].strip()
                if k == '$':
                    addr = getValue(v)
                    if startAddress == False:
                        startAddress = addr
                    currentAddress = addr
                else:
                    symbols[k.lower()] = v
                k=''
            
            if len(b)>0:
                showAddress = True
                if noOutput==False and passNum == 2:
                    
#                    if True:
#                         if any(x > 255 for x in b):
#                            errorText = 'byte out of range:\n    '+line
#                         if any(x < 0 for x in b):
#                            errorText = 'byte out of range:\n    '+line
                    
                    if bank == None:
                        if np:
                            out = np.append(out, np.array(b, dtype='B'))
                        else:
                            out = out + b
                    else:
                        #fileOffset = addr % bankSize + bank*bankSize+headerSize
                        fileOffset = addr + bank * bankSize + headerSize
                        
                        if fileOffset == len(out):
                            # We're in the right spot, just append

                            if np:
                                out = np.append(out, np.array(b, dtype='B'))
                            else:
                                out = out + b
                        elif fileOffset>len(out):
                            fv = fillValue
                            if np:
                                out = np.append(out, np.array(([fv] * (fileOffset-len(out))), dtype='B'))
                                out = np.append(out, np.array(b, dtype='B'))
                            else:
                                out = out + ([fv] * (fileOffset-len(out))) + b
                        elif fileOffset<len(out):
                            out = out[:fileOffset]+b+out[fileOffset+len(b):]
                addr = addr + len(b)
                currentAddress = currentAddress + len(b)
            
            if passNum == 2 and not hide:
                nBytes = cfg.getValue('main', 'list_nBytes')
                
                #outputText+='{:05x} '.format(len(out)-len(b))
                
                if startAddress:
                    outputText+="{:05X} ".format(currentAddress)
                else:
                    outputText+=' '*6
                
                if nBytes == 0:
                    outputText+="{}\n".format(originalLine)
                else:
                    listBytes = False
                    if noOutput:
                        listBytes = ' '*(3*nBytes+1)
                    else:
                        listBytes = ' '.join(['{:02X}'.format(x) for x in b[:nBytes]]).ljust(3*nBytes-1) + ('..' if len(b)>nBytes else '  ')
                    outputText+="{} {}\n".format(listBytes, originalLine)
                if errorText:
                    outputText+='*** {}\n'.format(errorText)
                    print(line)
                    print('*** {}\n'.format(errorText))
                    errorText = False
            if k==".org": showAddress = True
    if passNum == 2:
        if listFilename:
            with open(listFilename, 'w') as file:
                print(outputText, file=file)
                print('{} written.'.format(listFilename))

        with open(outputFilename, "wb") as file:
            file.write(bytes(out))
            print('{} written.'.format(outputFilename))

        if debug:
            f = 'debug_symbols.txt'
            with open(f, "w") as file:
                for k,v in symbols.items():
                    print('{} = {}'.format(k,v), file=file)
            print('{} written.'.format(f))
        if debug:
            f = 'debug_files.txt'
            with open(f, "w") as file:
                file.writelines(fileList)
            print('{} written.'.format(f))
        print()
if __name__ == '__main__':
    # This stuff doesn't work because I need to get the relative
    # imports more organized.
    
    import argparse

    parser = argparse.ArgumentParser(description='ASM 6502 Assembler made in Python')
    
    parser.add_argument('-l', type=str, nargs=1, metavar="<file>",
                        help='Create a list file')
    parser.add_argument('-bin', type=str, nargs=1, metavar="<file>",
                        help='Include binary file')
#    parser.add_argument('-q', action='store_true',
#                        help='Quiet mode')

    parser.add_argument('sourcefile', type=str,
                        help='The file to assemble')
    parser.add_argument('outputfile', type=str, nargs='?',
                        help='The output file')

    args = parser.parse_args()

    filename = args.sourcefile
    outputFilename = args.outputfile
    listFilename = args.l
    configFile = args.configfile
    binFile = args.bin # not implemented
    
    start = time.time()
    
    exit()
    assemble(filename, outputFilename = outputFilename, listFilename = listFilename, configFile = configFile, binFile = binFile)

    end = time.time()-start
    if end>=3:
        print(time.strftime('Finished in %Hh %Mm %Ss.',time.gmtime(end)))
