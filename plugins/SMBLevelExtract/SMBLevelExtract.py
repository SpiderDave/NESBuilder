# by SpiderDave
#
# ToDo:
#   * Add comments for world and level for area and level data.
#   * Detect number of worlds.

import os, sys, datetime
import math, re, textwrap
from binascii import hexlify, unhexlify

import pprint
pp = pprint.PrettyPrinter(indent=4, compact=True)

from textwrap import dedent
from copy import deepcopy

outputFilename = 'output.asm'
outputFilename2 = 'output2.asm'

# can change this to prefered data directive
# (including just removing the . if supported)
db = '.db'

# Split the output into two files
splitOutput = False

def Error(txt="(Unspecified error)"):
    print("{1}\nError: {0}\n{1}".format(txt,'='*35))

def chunker(seq, size):
    res = []
    for el in seq:
        res.append(el)
        if len(res) == size:
            yield res
            res = []
    if res:
        yield res

def makeData(data, indent=0, nItems=16):
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

def LevelExtract(filename, outputFilename, outputFilename2=False):

    PY3 = sys.version_info > (3,)
    if not PY3:
        print("This script requires Python 3.")
        return

    try:
        file = open(filename, "rb")
    except:
        Error("Could not open file ({0}).".format(filename))
        return

    # read data from .nes file
    fileData = file.read()
    file.close()
    ret = ProcessLevelData(fileData, 1)
    if not ret:
        Error()
        return
    elif ret.get('error'):
        ret.update(castleEndsWorld=True)
        ret = ProcessLevelData(fileData, 1, ret)
        if not ret:
            Error()
            return
        elif ret.get('error'):
            print('1b')
            Error(ret.get('errorText'))
            return
        
    ret = ProcessLevelData(fileData, 2, ret)
    if not ret:
        Error()
        return
    elif ret.get('error'):
        print('2')
        Error(ret.get('errorText'))
        return
    
    outputFile = open(outputFilename, 'w')
    outputFile2 = False
    if outputFilename2:
        outputFile2 = open(outputFilename2, 'w')
    
    #print(pprint.pformat(ret, compact=True), file=outputFile)
    
    AreaTypes = ["Water", "Ground", "Underground", "Castle"]
    
    out = ""

    out="; GAME LEVELS DATA\n"
    out+="; "+"-"*35+"\n"
    out+="; {0}\n".format(os.path.basename(filename))
    out+="; {0}\n".format(datetime.datetime.now())
    out+="; SMBLevelExtract.py by SpiderDave\n".format(datetime.datetime.now())
    out+="; "+"-"*35+"\n"
    out+="\n"
    
    FileTopper = out

    out+='WorldAddrOffsets:\n'
    
    out+= makeData(['World{0}Areas-AreaAddrOffsets'.format(x) for x in range(1,ret['nWorlds']+1)], indent=6, nItems=2)
    out+="\n"
    
    out+="AreaAddrOffsets:\n"
    for w, data in enumerate(ret['AreaAddrOffsets']):
        out+="World{0}Areas: {1}".format(w+1, makeData(data)) 
    out+="\n"
    
    halfwayOut = '.ifdef SMBBASE\n'
    
    halfwayOut+='HalfwayDataOffsets:\n'
    halfwayOut+= makeData(['HalfwayDataW{0}-HalfwayData'.format(x) for x in range(1,ret['nWorlds']+1)], indent=6, nItems=2)
    halfwayOut+="\n"
    
    halfwayOut+="HalfwayData:\n"
    for w, data in enumerate(ret['HalfwayData']):
        halfwayOut+="      HalfwayDataW{0}: {1}".format(w+1, makeData(data)) 
    
    halfwayOut+=".else\n"
    halfwayOut+= '    .ifdef IncludeHalfwayPageData\n'
    halfwayOut+= '        HalfwayPageNybbles:\n'
    
    for w, data in enumerate(ret['HalfwayData']):
        halfwayOut+="        {1}".format(w+1, makeData([data[0]*0x10+data[1],data[2]*0x10+data[3]])) 
    
    halfwayOut+="    .endif\n"
    halfwayOut+=".endif\n"
    halfwayOut+="\n"
    
    if ret['Halfway'] == False:
        halfwayOut = dedent("""
         Halfway data was not found.
         Uncomment and modify the data below or you can leave it commented out
         and defaults will be used.
        \n""") + halfwayOut
        halfwayOut= '\n'.join(';'+x for x in halfwayOut.strip().splitlines()).replace(';\n','\n')+"\n\n"
    
    out+=halfwayOut
    
    if outputFile2:
        print("Writing to file: {0}".format(outputFilename2))
        print(out, file=outputFile2)
        outputFile2.close()
        out = FileTopper
    
    for ea in [('Enemy','E', 'Addr'),('Area','L','Data')]:
        out+=dedent("""\
        {0}{1}HOffsets:
              {2} {0}DataAddrLow_WaterStart - {0}DataAddrLow          ; Water
              {2} {0}DataAddrLow_GroundStart - {0}DataAddrLow         ; Ground
              {2} {0}DataAddrLow_UndergroundStart - {0}DataAddrLow    ; Underground
              {2} {0}DataAddrLow_CastleStart - {0}DataAddrLow         ; castle
        \n""".format(ea[0],ea[2], db))

        for lh in [('<','Low'),('>','High')]:
            out+="{0}DataAddr{1}:\n".format(ea[0], lh[1])
            for areaTypeNum, areaText in enumerate(AreaTypes):
                out+="      ; {0}\n".format(areaText)
                if lh[1]=='Low': out+="      {0}DataAddr{1}_{2}Start:\n".format(ea[0],lh[1],areaText)
                out+=makeData(['{0}{1}_{2}Area{3}'.format(lh[0],ea[1], areaText, x) for x in range(1,len(ret['AreaData'][areaTypeNum])+1)], indent=6, nItems=6)
            out+="\n"
    
    for ea in [('Enemy','E'),('Area','L')]:
        for areaTypeNum, data in enumerate(ret['{0}Data'.format(ea[0])]):
            for i, areaData in enumerate(data):
                out+="{0}_{1}Area{2}:\n".format(ea[1], AreaTypes[areaTypeNum],i+1)
                out+=makeData(areaData[:-1], indent=6, nItems=10)
                out+=makeData(areaData[-1], indent=6) # separate line for terminator
                out+="\n"
    
    print("Writing to file: {0}".format(outputFilename))
    print(out, file=outputFile)
    outputFile.close()

def ProcessLevelData(fileData, passNum=1, pass1Data=False):
    #print("pass",passNum)
    def getFileData(a, l=1, bank=0):
        a+=bank*0x4000
        return fileData[a:a+l]
    def getInt(a, l=1, bank=0):
        a=a+bank*0x4000
        return int.from_bytes(fileData[a:a+l], byteorder='little')

    ret = {}

    AreaTypes = ["Water", "Ground", "Underground", "Castle"]

    def PrintAddrVar(v):
        print("{0}={1:05x}".format(v,eval(v)))

    romType = ""
    
    # make sure it's a nes rom by checking for iNES header
    if fileData[0:4] == b'NES\x1a':
        pass
    elif fileData[0:4] == b'FDS\x1a':
        # fds file with header
        Error("FDS not supported.")
        return
    elif fileData[1:1+14] == b'*NINTENDO-HVC*':
        # fds file without header
        Error("FDS not supported.")
        return
    else:
        if hexlify(fileData[0x00:0x00+0x20]) == b'12360e0e0e3232320a26402aa96b0ccb0c159c891ccc1d099d6b0cf51c6ba9ab':
            romType = "VSSMB"
        else:
            #print(fileData[0:4])
            Error("iNES header not found (Is this a .nes file?).")
            return

    # remove the header
    fileData = fileData[0x10:]

    adjust = 0

    # check vectors to detect a GreatEd rom
    if hexlify(fileData[0x1fff9:0x1fff9+6]) == b'40e2ffe5fff9':
        romType = "GreatEd"
        adjust = 0x6000
        #print("; Detected: GreatEd\n")

    # check vectors to detect original rom
    if hexlify(fileData[0x7ff9:0x7ff9+6]) == b'1f82800080f0':
        #print("; Detected: original\n")
        romType = "original"
    
    # check for SMB Base metadata
    m = re.search(b'METADATA_START', fileData)
    if m:
        metaData = {}
        l = 0
        i = m.start()-1
        
        while True:
            i=i+l
            l = fileData[i]
            i=i+1
            key = fileData[i:i+l].decode("utf-8")

            i=i+l
            l = fileData[i]
            i=i+1
            if l==0:
                data = True
            elif l==1:
                data = int.from_bytes(fileData[i:i+l], byteorder='little')
            elif l==2:
                data = int.from_bytes(fileData[i:i+l], byteorder='little')
            else:
                data = fileData[i:i+l].decode("utf-8")
            metaData[key] = data
            if key == 'METADATA_END':
                break
        romType = "SMBBase"
        if metaData['About'] and passNum==1:
            print(metaData['About'] + '\n')
    # Default number of worlds
    nWorlds = 8

    HalfwayDataOffsets = False
    if romType == "SMBBase":
        # This is what bank WorldAddrOffsets is in
        prgBank = metaData.get('Bank_Levels', 0)

        WorldAddrOffsets = metaData['WorldAddrOffsets']-0x8000
        AreaAddrOffsets = metaData['AreaAddrOffsets']-0x8000
        EnemyAddrHOffsets = metaData['EnemyAddrHOffsets']-0x8000
        EnemyDataAddrLow = metaData['EnemyDataAddrLow']-0x8000
        EnemyDataAddrHigh = metaData['EnemyDataAddrHigh']-0x8000
        AreaDataHOffsets = metaData['AreaDataHOffsets']-0x8000
        AreaDataAddrLow = metaData['AreaDataAddrLow']-0x8000
        AreaDataAddrHigh = metaData['AreaDataAddrHigh']-0x8000
        HalfwayDataOffsets = metaData['HalfwayDataOffsets']-0x8000
        HalfwayData = metaData['HalfwayData']-0x8000
        
        nWorlds = AreaAddrOffsets - WorldAddrOffsets
#        for item in metaData:
#            if type(metaData.get(item)) is str:
#                print('{0} = "{1}"'.format(item, metaData.get(item)))
#            else:
#                print('{0} = {1:04x}'.format(item, metaData.get(item)))
    else:

        # search for StoreStyle subroutine
        m = re.search(re.escape(unhexlify('8d3307a5e718690285e7a5e8690085e860')), fileData)

        if not m:
            Error('Could not locate WorldAddrOffsets.')
            return

        # assume WorldAddrOffsets directly follows it
        # assume there are 8 entries (one for each world)
        WorldAddrOffsets = m.start()+0x11

        # This is what bank WorldAddrOffsets was found in
        prgBank = math.floor(WorldAddrOffsets/0x4000)
        
        WorldAddrOffsets = WorldAddrOffsets % 0x4000

        # search for "sty WorldNumber ldx" (part of HandlePipeEntry)
        m = re.search(re.escape(unhexlify('8c5f07be')), fileData)
        if m:
            AreaAddrOffsets = (fileData[m.start()+0x07] + fileData[m.start()+0x08] * 0x100) % 0x4000
            nWorlds = AreaAddrOffsets - WorldAddrOffsets
            if nWorlds not in range(1,255):
                # Number of worlds doesn't make sense; fall back
                nWorlds = 8
                # Assume AreaAddrOffsets immediately follows WorldAddrOffsets
                AreaAddrOffsets = WorldAddrOffsets + 8
        else:
            # Assume AreaAddrOffsets immediately follows WorldAddrOffsets
            AreaAddrOffsets = WorldAddrOffsets + 8

        # part of GetAreaDataAddrs
        m = re.search(re.escape(unhexlify('a8ad5007291f8d')), fileData)

        # Get all these based on the above
        EnemyAddrHOffsets = fileData[m.start()+0x0a] + fileData[m.start()+0x0b] * 0x100 - 0x8000
        EnemyDataAddrLow = fileData[m.start()+0x12] + fileData[m.start()+0x13] * 0x100 - 0x8000
        EnemyDataAddrHigh = fileData[m.start()+0x17] + fileData[m.start()+0x18] * 0x100 - 0x8000
        AreaDataHOffsets = fileData[m.start()+0x1f] + fileData[m.start()+0x20] * 0x100 - 0x8000
        AreaDataAddrLow = fileData[m.start()+0x27] + fileData[m.start()+0x28] * 0x100 - 0x8000
        AreaDataAddrHigh = fileData[m.start()+0x2c] + fileData[m.start()+0x2d] * 0x100 - 0x8000

    if HalfwayDataOffsets:
        AreaAddrOffsets_length = HalfwayDataOffsets - AreaAddrOffsets
    else:
        AreaAddrOffsets_length = EnemyAddrHOffsets - AreaAddrOffsets
        

    Halfway = False

    if romType == "SMBBase":
        a = HalfwayData
        Halfway = []
        for i in range(0,nWorlds*4):
            Halfway.append(getInt(a+i, bank=prgBank)*1)
    elif romType == "GreatEd":
        a = 0x11bd # assume halfway data is always at this spot.
        Halfway = []
        for i in range(0,nWorlds*2):
            Halfway.append(math.floor(getInt(a+i, bank=prgBank) / 0x10))
            Halfway.append(getInt(a+i, bank=prgBank) % 0x10)
    elif romType == "VSSMB":
        pass
    else:
        # some code in PlayerLoseLife related to halfway page data.
        m = re.search(re.escape(unhexlify('0aaaad5c072902f001e8bc')), fileData)
        if m:
            a = m.start()+11
            p = a-(a % 0x4000)
            a = (fileData[a+1] * 0x100 + fileData[a]) % 0x4000 + p
            HalfwayPageNybbles = a
            Halfway = []
            for i in range(0,nWorlds*2):
                Halfway.append(math.floor(fileData[a+i] / 0x10))
                Halfway.append(fileData[a+i] % 0x10)

    wOffset = getFileData(WorldAddrOffsets, nWorlds, bank=prgBank)
    eOffsets = getFileData(EnemyAddrHOffsets, 4, bank=prgBank)
    aDataOffsets = getFileData(AreaDataHOffsets, 4, bank=prgBank)
    
    areas = [{},{},{},{}]
    for w in range(0,nWorlds):
        for a in range(0,100):
            b = getFileData(AreaAddrOffsets+wOffset[w]+a, bank=prgBank)[0]
            if b >= 0x80:
                b = b - 0x80
            if b >= 0x60:
                b = b - 0x60
                aType = 3
            elif b >= 0x40:
                b = b - 0x40
                aType = 2
            elif b >= 0x20:
                b = b - 0x20
                aType = 1
            else:
                aType = 0
            
            areas[aType][b] = True
            
            #print("  W{0} {1:02x} {2}".format(w+1,a+1, AreaTypes[aType]))
            if ret.get('castleEndsWorld') and (aType==3):
                #print('castle ends world')
                break
            if w<nWorlds-1 and a>=wOffset[w+1]:
                break
            elif wOffset[w]+a>=AreaAddrOffsets_length-1:
                break
            
        #print("W{0} {1:02x} l={2:02x}".format(w+1,a+1, AreaAddrOffsets_length))
    #print()

    #if romType == "original":
    
    #areas[0][0x00] = True #water area (5-2/6-2)    - 00
    #areas[0][0x02] = True #water area (8-4)        - 02
    #areas[1][0x0f] = True #warp zone area (4-2)    - 2f
    #areas[1][0x0b] = True #cloud area 1 (day)      - 2b
    #areas[1][0x14] = True #cloud area 2 (night)    - 34
    #areas[2][0x02] = True #underground bonus area  - c2
    
    if pass1Data:
        for i, v in enumerate(pass1Data['extraAreas']):
            areas[i].update(v)

    # Fill in any gaps
    for area in range(0,4):
        if len(areas[area])>0:
            for a in range(0, max(areas[area])+1):
                if a not in areas[area].keys(): 
                    areas[area][a]=True

    ret.update(AreaAddrOffsets = [])

    for w in range(0,nWorlds):
        ret['AreaAddrOffsets'].append([])
        for a in range(0,100):
            b = getFileData(AreaAddrOffsets+wOffset[w]+a, bank=prgBank)[0]
            ret['AreaAddrOffsets'][w].append(b)
            if b in range (0x60,0x6f):
                break
    
    if Halfway:
        ret.update(Halfway = True, HalfwayData = [])
        i=0
        for w in range(0,nWorlds):
            ret['HalfwayData'].append([])
            for l in range(0,4):
                ret['HalfwayData'][w].append(Halfway[i])
                i=i+1
    else:
        ret.update(Halfway=False, 
                   HalfwayData = [[5,6,4,0], [6,5,7,0], [6,6,4,0], [6,6,4,0], [6,6,4,0], [6,6,6,0], [6,5,7,0], [0,0,0,0]])

    enemyOrArea = ["Enemy","Area"]
    enemyOrArea2 = ["EnemyAddr","AreaData"]
    eOrA = ["E","L"]
    
    for j in range(0,2):
        ret.update({'{0:s}Data'.format(enemyOrArea[j]):[[],[],[],[]]})

    terminator=[0xff,0xfd]
    for j in range(0,2):
        for area in range(0,4):
            if len(areas[area])>0:
                for a in range(0, max(areas[area])+1):
                    ret['{0:s}Data'.format(enemyOrArea[j])][area].append([])
                    
                    if j==0:
                        aData = getInt(EnemyDataAddrHigh+eOffsets[area]+a, bank=prgBank) * 0x100 + getInt(EnemyDataAddrLow+eOffsets[area]+a, bank=prgBank)
                    else:
                        aData = getInt(AreaDataAddrHigh+aDataOffsets[area]+a, bank=prgBank) * 0x100 + getInt(AreaDataAddrLow+aDataOffsets[area]+a, bank=prgBank)
                    data = fileData[aData -0x8000 + prgBank*0x4000 + adjust:].split(bytes(terminator[j]))[0]
                    data = bytearray(data)
                    data.append(terminator[j])

                    for i in range(0, len(data)):
                        ret['{0:s}Data'.format(enemyOrArea[j])][area][a].append(int(data[i]))
                        if data[i] == terminator[j]:
                            break

    ret.update(extraAreas = [{},{},{},{}])
    for areaTypeNum, enemyData in enumerate(ret['EnemyData']):
        for areaNum, data in enumerate(enemyData):
            i= 0
            while True:
                try:
                    b = data[i]
                except:
                    ret.update(error = 1, errorText='could not read data')
                    ret.update(nWorlds=nWorlds)
                    return ret
                if b == 0xff:
                    break
                row = b % 0x10
                if row == 0x0e:
                    b = data[i+1]
                    if b >= 0x80:
                        b = b - 0x80
                    if b >= 0x60:
                        b = b - 0x60
                        aType = 3
                    elif b >= 0x40:
                        b = b - 0x40
                        aType = 2
                    elif b >= 0x20:
                        b = b - 0x20
                        aType = 1
                    else:
                        aType = 0
                    if (b % 0x80 not in areas[aType].keys()) or (not areas[aType][b % 0x80]):
                        areas[aType].update({0x80:True})
                        if not ret['extraAreas'][aType].get(b % 0x80):
                            ret['extraAreas'][aType][b % 0x80] = True
                            #print('    found area: {0}Area{1}'.format(AreaTypes[aType], b+1))
                    i=i+3
                else:
                    i=i+2

    #ret.update(romType=romType)
    ret.update(nWorlds=nWorlds)
    #ret.update(areas=areas)
    
    return ret

if __name__== "__main__":
    if len(sys.argv) <2 or sys.argv[1]=='':
        Error("no file specified.")
        sys.exit()

    filename = " ".join(sys.argv[1:])
    
    if splitOutput:
        LevelExtract(filename, os.path.join(sys.path[0], outputFilename), os.path.join(sys.path[0], outputFilename2))
    else:
        LevelExtract(filename, os.path.join(sys.path[0], outputFilename))
    
