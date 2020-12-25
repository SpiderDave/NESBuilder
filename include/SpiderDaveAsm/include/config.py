# This is basically ConfigParser with some extra stuff
import os
import configparser

class Cfg(configparser.ConfigParser):
    folder = None
    filename = None
    def __init__(self, filename=None):
        # do the usual init
        super().__init__()
        if filename:
            self.folder = os.path.split(filename)[0]
            self.filename = os.path.split(filename)[1]
    def load(self, filename = None):
        filename = filename or self.filename
        self.read(os.path.join(self.folder, filename))
        self.filename = filename
    def save(self):
        with open(os.path.join(self.folder, self.filename), 'w') as configfile:
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
            return False
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
    def isFalse(self, v):
        return not self.isTrue(v)
    def isTrue(self, v):
        if type(v) == str:
            v = v.lower().strip()
            if v == "false": return False
            if v == '': return False
            return True
        if type(v) == int:
            if v>0: return True
        return False
    def setValue(self, section, key, value):
        # make sure section exists
        if not section in self.sections():
            self[section] = {}
        self.set(section, key, str(value))
