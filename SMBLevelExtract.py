# by SpiderDave
#
# ToDo:
#   * Remove all the extra file reading and work from fileData only.
#   * Add comments for world and level for area and level data.
#   * Detect number of worlds.

import os, sys, datetime

def Error(txt):
    print("Error: {0}".format(txt))

def LevelExtract(filename, outputFileName):

    PY3 = sys.version_info > (3,)
    if not PY3:
        print("This script requires Python 3.")
        return

    import math, re, textwrap
    from binascii import hexlify, unhexlify

    AreaTypes = ["Water", "Ground", "Underground", "Castle"]

    def PrintAddrVar(v):
        print("{0}={1:05x}".format(v,eval(v)))

    try:
        file = open(filename, "rb")
    except:
        Error("Could not open file ({0}).".format(filename))
        return

    # read data from .nes file
    fileData = file.read()

    out="; GAME LEVELS DATA\n"
    out+="; "+"-"*35+"\n"
    out+="; {0}\n".format(os.path.basename(filename))
    out+="; {0}\n".format(datetime.datetime.now())
    out+="; SMBLevelExtract.py by SpiderDave\n".format(datetime.datetime.now())
    out+="; "+"-"*35+"\n"
    out+="\n"

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
        #print(fileData[0:4])
        Error("iNES header not found (Is this a .nes file?).")
        return

    # remove the header
    fileData = fileData[0x10:]

    #greated 40e2ffe5fff9      1fffa
    #original 1f82800080f0    7ffa

    romType = ""
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
                data = int.from_bytes(fileData[i:i+l])
            elif l==2:
                data = int.from_bytes(fileData[i:i+l], byteorder='little')
            else:
                data = fileData[i:i+l].decode("utf-8")
            metaData[key] = data
            if key == 'METADATA_END':
                break
        
        romType = "SMBBase"

    # Default number of worlds
    nWorlds = 8

    if romType == "SMBBase":
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
        
        # This is what bank WorldAddrOffsets is in
        prgBank = math.floor(WorldAddrOffsets/0x8000)
    else:

        # search for StoreStyle subroutine
        m = re.search(re.escape(unhexlify('8d3307a5e718690285e7a5e8690085e860')), fileData)

        # assume WorldAddrOffsets directly follows it
        # assume there are 8 entries (one for each world)
        WorldAddrOffsets = m.start()+0x11

        # This is what bank WorldAddrOffsets was found in
        prgBank = math.floor(WorldAddrOffsets/0x8000)

        # search for "sty WorldNumber ldx" (part of HandlePipeEntry)
        m = re.search(re.escape(unhexlify('8c5f07be')), fileData)
        if m:
            AreaAddrOffsets = fileData[m.start()+0x07] + fileData[m.start()+0x08] * 0x100 - 0x8000 + prgBank*0x8000
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
        EnemyAddrHOffsets = fileData[m.start()+0x0a] + fileData[m.start()+0x0b] * 0x100 - 0x8000 + prgBank*0x8000
        EnemyDataAddrLow = fileData[m.start()+0x12] + fileData[m.start()+0x13] * 0x100 - 0x8000 + prgBank*0x8000
        EnemyDataAddrHigh = fileData[m.start()+0x17] + fileData[m.start()+0x18] * 0x100 - 0x8000 + prgBank*0x8000
        AreaDataHOffsets = fileData[m.start()+0x1f] + fileData[m.start()+0x20] * 0x100 - 0x8000 + prgBank*0x8000
        AreaDataAddrLow = fileData[m.start()+0x27] + fileData[m.start()+0x28] * 0x100 - 0x8000 + prgBank*0x8000
        AreaDataAddrHigh = fileData[m.start()+0x2c] + fileData[m.start()+0x2d] * 0x100 - 0x8000 + prgBank*0x8000

    Halfway = False

    if romType == "SMBBase":
        a = HalfwayData
        Halfway = []
        for i in range(0,nWorlds*4):
            Halfway.append(fileData[a+i]*1)
    elif romType == "GreatEd":
        a = 0x11bd # assume halfway data is always at this spot.
        Halfway = []
        for i in range(0,nWorlds*2):
            Halfway.append(math.floor(fileData[a+i] / 0x10))
            Halfway.append(fileData[a+i] % 0x10)
    else:
        # some code in PlayerLoseLife related to halfway page data.
        m = re.search(re.escape(unhexlify('0aaaad5c072902f001e8bc')), fileData)
        if m:
            a = m.start()+11
            p = a-(a % 0x8000)
            a = (fileData[a+1] * 0x100 + fileData[a]) % 0x8000 + p
            HalfwayPageNybbles = a
            Halfway = []
            for i in range(0,nWorlds*2):
                Halfway.append(math.floor(fileData[a+i] / 0x10))
                Halfway.append(fileData[a+i] % 0x10)

    file.seek(WorldAddrOffsets+0x10)
    wOffset = file.read(nWorlds)

    file.seek(EnemyAddrHOffsets+0x10)
    eOffsets = file.read(4)

    file.seek(AreaDataHOffsets+0x10)
    aDataOffsets = file.read(4)

    areas = [{},{},{},{}]
    for w in range(0,nWorlds):
        for a in range(0,100):
            file.seek(AreaAddrOffsets+wOffset[w]+a+0x10)
            b = file.read(1)[0]
            #out+="${0:02x}".format(b)
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
            
            if aType == 3:
                break

    areas[0][0x00] = True #water area (5-2/6-2)    - 00
    areas[0][0x02] = True #water area (8-4)        - 02
    areas[1][0x0f] = True #warp zone area (4-2)    - 2f
    areas[1][0x0b] = True #cloud area 1 (day)      - 2b
    areas[1][0x14] = True #cloud area 2 (night)    - 34
    areas[2][0x02] = True #underground bonus area  - c2

    # Fill in any gaps
    for area in range(0,4):
        for a in range(0, max(areas[area])+1):
            if a not in areas[area].keys(): 
                areas[area][a]=True

    out+="WorldAddrOffsets:\n"
    out+="      .db World1Areas-AreaAddrOffsets, World2Areas-AreaAddrOffsets\n"
    out+="      .db World3Areas-AreaAddrOffsets, World4Areas-AreaAddrOffsets\n"
    out+="      .db World5Areas-AreaAddrOffsets, World6Areas-AreaAddrOffsets\n"
    out+="      .db World7Areas-AreaAddrOffsets, World8Areas-AreaAddrOffsets\n"
    out+="\n"
    out+="AreaAddrOffsets:\n"

    for w in range(0,nWorlds):
        out+="World{0:d}Areas: .db ".format(w+1)
        for a in range(0,100):
            file.seek(AreaAddrOffsets+wOffset[w]+a+0x10)
            b = file.read(1)[0]
            out+="${0:02x}".format(b)
            if b in range (0x60,0x6f):
                break
            else:
                out+=", "
        out+="\n"
    out+="\n"



    if Halfway:
        out+="HalfwayDataOffsets:\n"
        for w in range(0,nWorlds):
            if w % 2 == 0:
                out+="      .db "
            else:
                out+=", "
            out+="HalfwayDataW{0}-HalfwayData".format(w+1)
            if w % 2 == 1  or (w==nWorlds-1):
                out+="\n"
        out+="\n"
        out+="HalfwayData:\n"
        i=0
        for w in range(0,nWorlds):
            out+="      HalfwayDataW{0}: .db ".format(w+1)
            for l in range(0,4):
                out+="${0:02x}".format(Halfway[i])
                if l==3:
                    out+="\n"
                else:
                    out+=", "
                i=i+1
        out+="\n"
    else:
        out+="""; Halfway data was not found.
    ; Uncomment and modify the data below or you can leave it commented out
    ; and defaults will be used.

    ;HalfwayDataOffsets:
    ;      .db HalfwayDataW1-HalfwayData, HalfwayDataW2-HalfwayData
    ;      .db HalfwayDataW3-HalfwayData, HalfwayDataW4-HalfwayData
    ;      .db HalfwayDataW5-HalfwayData, HalfwayDataW6-HalfwayData
    ;      .db HalfwayDataW7-HalfwayData, HalfwayDataW8-HalfwayData

    ;HalfwayData:
    ;      HalfwayDataW1: .db $05, $06, $04, $00
    ;      HalfwayDataW2: .db $06, $05, $07, $00
    ;      HalfwayDataW3: .db $06, $06, $04, $00
    ;      HalfwayDataW4: .db $06, $06, $04, $00
    ;      HalfwayDataW5: .db $06, $06, $04, $00
    ;      HalfwayDataW6: .db $06, $06, $06, $00
    ;      HalfwayDataW7: .db $06, $05, $07, $00
    ;      HalfwayDataW8: .db $00, $00, $00, $00
    """
        out+="\n"


    enemyOrArea = ["Enemy","Area"]
    enemyOrArea2 = ["EnemyAddr","AreaData"]
    eOrA = ["E","L"]
    for j in range(0,2):
        out+="{0:s}HOffsets:\n".format(enemyOrArea2[j])
        out+="      .db {0:s}DataAddrLow_WaterStart - {0:s}DataAddrLow          ; Water\n".format(enemyOrArea[j])
        out+="      .db {0:s}DataAddrLow_GroundStart - {0:s}DataAddrLow         ; Ground\n".format(enemyOrArea[j])
        out+="      .db {0:s}DataAddrLow_UndergroundStart - {0:s}DataAddrLow    ; Underground\n".format(enemyOrArea[j])
        out+="      .db {0:s}DataAddrLow_CastleStart - {0:s}DataAddrLow         ; castle\n".format(enemyOrArea[j])
        
        for i in range(0,2):
            if i==0:
                out+="\n{0:s}DataAddrLow:\n".format(enemyOrArea[j])
            else:
                out+="\n{0:s}DataAddrHigh:\n".format(enemyOrArea[j])
            
            for area in range(0,4):
                out+="      ; {0:s}\n".format(AreaTypes[area])
                
                if i==0:
                    out+="      {0:s}DataAddrLow_{1:s}Start:\n".format(enemyOrArea[j], AreaTypes[area])
                
                out+="      .db "
                for a in range(0, max(areas[area])+1):
                    if i==0:
                        out+="<"
                    else:
                        out+=">"

                    out+="{0:s}_{1:s}Area{2:d}".format(eOrA[j], AreaTypes[area], a+1)
                    if a == max(areas[area]):
                        out+="\n"
                    elif a % 6==5:
                        out+="\n      .db "
                    else:
                        out+=", "
        out+="\n"

    terminator=[0xff,0xfd]
    for j in range(0,2):
        for area in range(0,4):
            for a in range(0, max(areas[area])+1):
                out+="{0:s}_{1:s}Area{2:d}:\n".format(eOrA[j], AreaTypes[area], a+1)
                
                if j==0:
                    aData = fileData[EnemyDataAddrHigh+eOffsets[area]+a] * 0x100 + fileData[EnemyDataAddrLow+eOffsets[area]+a]
                else:
                    aData = fileData[AreaDataAddrHigh+aDataOffsets[area]+a] * 0x100 + fileData[AreaDataAddrLow+aDataOffsets[area]+a]
                data = fileData[aData -0x8000 + prgBank*0x8000 + adjust:].split(bytes(terminator[j]))[0]
                data = bytearray(data)
                data.append(terminator[j])

                out+="      .db "
                for i in range(0, len(data)):
                    if (data[i] == terminator[j]) and (out[-2:]==", "):
                        out=out[:-2] # remove comma and space
                        out+="\n      .db ${0:02x}".format(data[i])
                    else:
                        out+="${0:02x}".format(data[i])
                    if data[i] == terminator[j]:
                        out+="\n"
                        break
                    if i == len(data)-1:
                        out+="\n"
                    elif i % 10==9:
                        out+="\n      .db "
                    else:
                        out+=", "
                    
                out+="\n"

    #outputFileName = os.path.join(sys.path[0], 'output.asm')
    print("Writing to file: {0}".format(outputFileName)) 
    outputFile = open(outputFileName, 'w')
    print(out, file=outputFile)
    outputFile.close()

    file.close()

if __name__== "__main__":
    if len(sys.argv) <2:
        Error("no file specified.")
        exit()

    filename = " ".join(sys.argv[1:])
    outputFileName = os.path.join(sys.path[0], 'output.asm')
    
    LevelExtract(filename, outputFileName)
