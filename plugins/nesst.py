from binascii import hexlify, unhexlify

keyTypes=dict(
    RLE = (
        'VarCHRSelected',
        'Palette',
        'PalUndo',
        'CHRMain',
        'CHRCopy',
        'CHRUndo',
        'NameTable',
        'NameCopy',
        'NameUndo',
        'AttrTable',
        'AttrCopy',
        'AttrUndo',
        'MetaSprites',
        'Checkpoint_Palette',
        'Checkpoint_PalUndo',
        'Checkpoint_CHRMain',
        'Checkpoint_CHRUndo',
        'Checkpoint_NameTable',
        'Checkpoint_NameUndo',
        'Checkpoint_AttrTable',
        'Checkpoint_AttrUndo',
        'Checkpoint_MetaSprites',
        ),
    text = (
        'FileNameCHR',
        'FileNameName',
        'FileNameAttr',
        'FileNamePal',
        'FileNameMetaSpriteBank',
        'MetaSprite0',
        'MetaSpriteBankName',
        'FileNameCHR',
        'FileNameName',
        'FileNamePal',
        'FileNameMetaSpriteBank',
        ),
)
def getData(filename):
    d = dict()
    file=open(filename,"r")
    lines = [line.strip() for line in file.readlines()]
    
    d.update(id = lines[0])
    
    for line in lines:
        if "=" in line:
            k,v = line.split("=",1)
            if k in keyTypes.get('RLE'):
                v = unRLE(v)
            elif k in keyTypes.get('text'):
                pass
            else:
                try:
                    v = int(v)
                except:
                    pass
            d.update({k:v})
    
    d.update(CHRBank = d.get('VarBankActive')/4096)
    
    #chr = bytearray.fromhex(d.get('CHRMain'))
    chr = d.get('CHRMain')
    d.update(CHR = [list(chr[0:0x1000]),list(chr[0x1000:])])
    
    return d

def unRLE(d):
    #print('unrle type =', type(d))
    out = ""
    lastHex = "00"
    while True:
        hex = d[:2]
        if "[" in hex:
            d = d[1:] # remove the "["
            l = int(d.split("]", 1)[0], 16)
            d = (lastHex * (int(d.split("]", 1)[0], 16)-1)) + d.split("]", 1)[1]
        else:
            out+=hex
            d=d[2:]
        lastHex=hex
        if d=='':
            break
    #print('unrle out type =', type(out))
    out = list(unhexlify(out))
    return out

def RLE(data):
    out = ""
    prev = -1
    count = 1
    for item in data:
        if item == prev:
            count += 1
        else:
            if count >1:
                out += '[{:x}]'.format(count)
                count = 1
            out += str(hexlify(bytes([item])), 'utf8')
            prev = item
    if count >1:
        out += '[{:x}]'.format(count)
    return out


nssTemplate = """
NSTssTXT

BtnTiles=1
BtnChecker=0
BtnSelTiles=0
BtnChrBank1=1
BtnChrBank2=0
BtnGridAll=0
BtnGridTile=0
BtnGridAtr=0
BtnGridBlock=0
BtnPal=1
BtnTypeIn=0
BtnFrameAll=0
BtnFrameSelected=0
BtnFrameNone=1
BtnSpriteSnap=1
BtnSprite8x16=0
MenuBestOffsets=0
MenuLossy=0
MenuThreshold=0
MenuNoColorData=0
MenuMetaSprAutoInc=0
MenuMetaSprSkipZero=0
MenuMetaSprMerge=0
MenuSaveIncName=0
MenuSaveIncAttr=0
MenuSaveRLE=0
VarBgPalCur=1
VarPalActive=0
VarTileActive=83
VarBankActive=4096
VarPPUMask=0
VarPPUMaskSet0=0
VarPPUMaskSet1=128
VarPPUMaskSet2=128
VarPPUMaskSet3=128
VarPalBank=0
VarMetaSpriteActive=0
VarSpriteActive=0
VarSpriteGridX=64
VarSpriteGridY=64
VarNameW=32
VarNameH=30

Palette=

CHRMain=

NameTable=

AttrTable=

FilterCHR=1
FilterName=1
FileNameCHR=
FileNameName=
FileNamePal=
FileNameMetaSpriteBank=
""".lstrip()

def createNss(arg={}):
    nt =  arg.get('nameTable', [0] * 0x3c0)
    at =  arg.get('attrTable', [0] * 0x40)
    chr = arg.get('chr', [0] * 0x2000)
    
    chr = list(chr)
    
    if len(chr) == 0x1000:
        chr = chr + chr
    
    palette = arg.get('palette', [0x0f, 0x01, 0x11, 0x20] * 4 * 4)
    if len(chr) == 2:
        chr = chr[0] + chr[1]
    
    
    out = nssTemplate
    out = out.replace('Palette=', 'Palette=' + RLE(palette))
    #out = out.replace('Palette=', 'Palette=' + '0f1605200f1302200f14033b0f1627101220103012362706121000091228180801201000010f0f0f01281706012b1a0a0c2020210c0121310c3c211c0c312111')
    out = out.replace('CHRMain=', 'CHRMain=' + RLE(chr))
    out = out.replace('NameTable=', 'NameTable=' + RLE(nt))
    out = out.replace('AttrTable=', 'AttrTable=' + RLE(at))
    
    with open(arg.get('filename'), "w") as file:
        file.write(out)
    
#    print(hex(len(nt)))
#    print(hex(len(at)))
#    print(hex(len(chr)))
#    print(hex(len(palette)))

def getFileContentsAsList(filename):
    with open(filename, 'rb') as file:
        data = file.read()
    return list(data)
def getFileContentsAsHex(filename):
    with open(filename, 'rb') as file:
        data = file.read()
    return str(hexlify(data), 'utf8')

if __name__ == '__main__':
    
    filename = r"J:\svn\NESBuilder\cv3test.nss"
    nt = getFileContentsAsList(r"J:\svn\NESBuilder\projects\Castlevania3\nametable\screenTool.nt")
    at = getFileContentsAsList(r"J:\svn\NESBuilder\projects\Castlevania3\nametable\screenTool.attr")
    chr = getFileContentsAsList(r"J:\svn\NESBuilder\projects\Castlevania3\chr\screenTool.custom.chr")
    palette = list(unhexlify("0f1605200f1302200f14033b0f162710" * 4))
    chr = chr + [0] * 0x1000
    
    arg = dict(filename = filename, nt=nt, at=at, chr=chr, palette=palette)
    
    createNss(arg)
    
    
    
#    out = nssTemplate
    #out = out.replace('Palette=', 'Palette=' + RLE(palette))
#    out = out.replace('Palette=', 'Palette=' + '0f1605200f1302200f14033b0f1627101220103012362706121000091228180801201000010f[3]01281706012b1a0a0c20[2]210c0121310c3c211c0c312111')
#    out = out.replace('CHRMain=', 'CHRMain=' + RLE(chr))
#    out = out.replace('NameTable=', 'NameTable=' + RLE(nt))
#    out = out.replace('AttrTable=', 'AttrTable=' + RLE(at))
    
#    with open(r"J:\svn\NESBuilder\cv3test.nss", "w") as file:
#        file.write(out)
    
    
#    nt = 'ff[13]00ff[a]00[2]ff[2]d1ff[9]d1ff[3]d0ff[2]00ff[4]d1ff[2]00ff00[3]ff[8]d0ff[a]00ff[2]00[4]ff00d000[3]ff[3]d0ffd1ff[d]00ff[4]00ff[5]d100ff00ff00[2]ff00ff[6]d0ff[3]d1ff[3]00ffd0ff[2]00[6]ffd100[3]ffd100[2]ff00[16]ff[2]00[2]d1ff[3]00ff00ff[2]00[e]d1ff[3]00ff[2]00[2]ff[5]00[10]ff[3]00ff00[2]ff[2]00[5]ff[2]8081[c]82ff[6]00[3]ff[2]00[5]ff[2]904e[2]45534275696c646572009200[5]ff00[4]ff[2]00[4]ff[2]a0a1[c]a200[5]ff[2]00[2]ff[2]00[5]ff[4]00[6]ff[3]00[7]ff00ff00[2]ff[3]00[4]ff[8]00[2]ff[3]00[7]ff00ff00[2]ff[3]00[b]ff00ff[5]00ff[2]00[2]ff00ff00[3]ff[3]00[2]ff00[8]ff[2]00[3]ff00[9]ff00[2]ff[2]00[d]ff[5]00[7]ff00[4]ff[3]00[19]ff00[4]ff00[15]e8e9e6eaffe700[3]ff[3]00[2]ff00[10]e4e5e4e5e4e5e4e500[3]ff00[3]ff00[10]f2f3f2f3f2f3f2f300[3]ff[2]00[2]ff[2]00[f]e2e3e2e3e2e3e2e300[3]e6e7e6e800e6e700e6e9e700e800e700[6]f2f3f2f3f2f3f2f300[2]f7e1e0e1e0e1e0e1e0e1[3]e0e1e0e1e0f500[4]e2e3e2e3e2e3e2e3ff00f6f1f0f1f0f1f0f1f0f1f0f1f0f1f0f1f0f400[4]f2f3f2f3f2f3f2f3ff00f601[10]f400[4]e2e3e2e3e2e3e2e3ff00f601[10]f400[4]f2f3f2f3f2f3f2f3ff00f601[10]f400[4]e2e3e2e3e2e3e2e3ff00f601[10]f400[4]f2f3f2f3f2f3f2f3ff00f601[10]f400[4]e2e3e2e3e2e3e2e3ff00f601[10]f400[4]f2f3f2f3f2f3f2f3ff00'
#    at = '00[18]55[d]9da367ff[4]7599aa66ff[5]99aa660f[5]090a06'
#    chr = '00[10]7e87bf[2]fd[2]e17e[2]ff[2]e7[2]ff[2]7e00[13]8000[7]8000[f]8000[7]8000[ae]1e1c[2]1e00[2]381c1e3b[2]1e1c3800[2]1edc[2]1e00[2]381c1e3b[2]1e1c3800[2]08[2]9c08[2]00[3]1834e2341800[4]ff00[8]ff00[4]02[2]fe02[3]00[2]067d01fd7d0600[9]ff81[6]ff00[a1]1e7039701e00[2]0e1f7f1f7f1f0e00[19]ff81[6]ff00[70]07181020383d2d25071f[2]3f[3]373f00c04020e0[2]a02000c0[2]e0[3]60e000[40]0118f4b2ce4cb12a3f5b09377bf937d600[8]ff81[6]ff00[41]010002000100[2]0103[5]0100[2]e0387038e000[2]c0e0f8e0f8e0c000[21]10080700[5]1f0f0700[5]408000[6]c08000[6]317b4a0a00[4]317b5b0a00[4]80c04000[5]80c04000[2d]ff81[6]ff00[8]ff81[6]ff00[1e]80c000[54]07080f0800[2]0c07[2]0f0c0f00[4]80e000e000[4]80e080e000[58]ff81[6]ff00[10]010002[2]0300[3]01[2]03[3]01[2]00e0380c608000[3]e0f8fce0[2]c08000[16]0100[7]0100[7]c000[7]f0e0c000[20]0700[7]07[2]0c00[5]8000[7]8000[a5]01[2]00[e]80c000[52]0f[2]080700[2]0c070f0c0f07[2]0c00[2]e000e08000[4]e080e08000[72]01000200[2]020001[3]0300[2]0301[2]e0386000[2]6038e0[2]f8e000[2]e0f8e000[12]3c4778[2]473c30383c7f64[2]7f3c00[17]0100[7]0100[7]fc00[7]fc00[e]030100[e]80c000[42]01[6]00[8]808101[4]f98700[9]01[6]c100[10]01[2]00[e]c08000[1e]383000[1f]0100[6]1000[7]f08000[6]01[4]00[4]0103[2]01[2]0300[2]e0c0[2]e000[4]e0b0[2]e0c08000[42]01[6]00[a]01[4]008000[a]01[4]00[2d]40[3]004000[119]0300[e]e01800[af]0100[7]c100[6]ffc300[6]80[2]00[6]80[2]00[18]0204[2]020300[b]0804[2]0818e000[aa]0302[6]0302400040[2]0b0102fe44f4d4[2]ff07fe80[6]00[2]80[6]00[3b2]ff[10]00[8]ff[10]00[b]ff[2]00[b]18[8]00[8]ff[10]00[1a0]183c[3]18[2]001800[8]6c[3]00[d]6c[2]fe6cfe6c[2]00[9]307cc0780cf83000[a]c6cc183066c600[9]386c3876dccc7600[9]60[2]c000[d]183060[3]301800[9]603018[3]306000[a]663cff3c6600[b]30[2]fc30[2]00[f]30[2]6000[b]fc00[11]30[2]00[9]060c183060c08000[9]384cc6[3]643800[9]183818[4]7e00[9]7cc60e3c78e0fe00[9]7e0c183c06c67c00[9]1c3c6cccfe0c[2]00[9]fcc0fc06[2]c67c00[9]3c60c0fcc6[2]7c00[9]fec60c1830[3]00[9]7cc6[2]7cc6[2]7c00[9]7cc6[2]7e060c7800[a]30[2]00[2]30[2]00[a]30[2]00[2]30[2]6000[8]183060c060301800[b]fc00[2]fc00[a]6030180c18306000[9]78cc0c1830003000[9]7cc6de[3]c07800[9]386cc6[2]fec6[2]00[9]fcc6[2]fcc6[2]fc00[9]3c66c0[3]663c00[9]f8ccc6[3]ccf800[9]fec0[2]fcc0[2]fe00[9]fec0[2]fcc0[3]00[9]3e60c0cec6663e00[9]c6[3]fec6[3]00[9]7e18[5]7e00[9]1e06[3]c6[2]7c00[9]c6ccd8f0f8dcce00[9]60[6]7e00[9]c6eefe[2]d6c6[2]00[9]c6e6f6fedecec600[9]7cc6[5]7c00[9]fcc6[3]fcc0[2]00[9]7cc6[3]decc7a00[9]fcc6[2]cef8dcce00[9]78ccc07c06c67c00[9]7e18[6]00[9]c6[6]7c00[9]c6[3]ee7c381000[9]c6[2]d6fe[2]eec600[9]c6ee7c387ceec600[9]66[3]3c18[3]00[9]fe0e1c3870e0fe00[9]7860[5]7800[9]c06030180c060200[9]7818[5]7800[9]10386cc600[13]ff00[8]30[2]1800[f]3c66[3]3b00[9]60[2]7c66[3]7c00[b]3e60[3]3e00[9]06[2]3e66[3]3e00[b]3c667e603e00[9]0e18[2]7e18[3]00[b]3e66[2]3e063c00[8]60[3]7c66[3]00[a]180018[4]00[a]060006[3]663c00[8]60[2]6264687c6600[9]18[7]00[b]766b[4]00[b]7c66[4]00[b]3c66[3]3c00[b]7c66[2]7c60[2]00[a]3e66[2]3e06[2]00[a]6e7060[3]00[b]3c403c067c00[9]30[2]fc30[3]1c00[b]66[4]3c00[b]66[3]241800[b]636b[3]3600[b]63361c366300[b]66[2]2c18306000[a]7e0c18307e00[9]1c30[2]e030[2]1c00[9]18[3]0018[3]00[9]e030[2]1c30[2]e000[9]76dc00[f]10386cc6[2]fe00[a]3f7f7060[4]00[9]ff[2]00[e]fcfe0e06[4]00[10]ff81[6]ff00[c0]60[8]00[18]06[8]00[10]ff81[6]ff00[c0]60[4]707f3f00[e]ff[2]00[9]06[4]0efefc00[11]ff81[6]ff00[21]10[3]001000[d2]ff81[6]ff00[c2]1e1c[2]1e00[2]381c1e3b[2]1e1c3800[8]ff81[6]ff00[8]ff81[6]ff00[8]ff81[6]ff00[20]3c42998581[2]423c[2]7ee7fbff[2]7e3c00245a0400422400[2]3c667a7e[2]3c00[2]245a3c[2]5a2400[2]3c6642[2]663c00[72]10381000[12]2000[e9]5d08ff[2]eb415024fff700[2]14beafdb6511ff[2]d7024410ffee00[2]28fdbbefffdf8c88d8f81c0fffeff7ff[3]eff7e0[2]f17f[2]337bdeff[2]7fbfbbfdffefcd952288d8f81c0f32ffddff[3]eff7de8a246160317fde21ffdbbebfff[2]ef00[3]08008000[6]10[2]50[2]00[5]10044200[6]103c2000[2]01008000[3]202628[3]a8[2]00[3]205020000800[4]200020[2]00[5]182e4500[5]18367b00[50]0415ddffbbff[b]0555ffdffffbff[a]0f070ffbe1c1c0e1f7ff[2]fdfe[2]ff[2]8e0607878ffbf1e0f7fb[2]ff[2]fdfeff8cec74d4ec[2]e4ecf4d4ec[2]f4b4dcf4c030c8e8a40cac14c0f038185cfc54ec31372e2b37[2]27372f2b37[2]2f2d3b2f030c131725303528030f1c183a3f2a3700[80]'
#    palette = '11303d001121010f11271707112919091220103012362706121000091228180801201000010f[3]01281706012b1a0a0c20[2]210c0121310c3c211c0c312111'
    
#    print(hex(len(unRLE(nt))))
#    print(hex(len(unRLE(at))))
#    print(hex(len(unRLE(chr))))
#    print(hex(len(unRLE(palette))))
    
#    data = 'ff[13]00ff[a]00[2]ff[2]d1ff[9]d1ff[3]d0ff[2]00ff[4]d1ff[2]00ff00[3]ff[8]d0ff[a]00ff[2]00[4]ff00d000[3]ff[3]d0ffd1ff[d]00ff[4]00ff[5]d100ff00ff00[2]ff00ff[6]d0ff[3]d1ff[3]00ffd0ff[2]00[6]ffd100[3]ffd100[2]ff00[16]ff[2]00[2]d1ff[3]00ff00ff[2]00[e]d1ff[3]00ff[2]00[2]ff[5]00[10]ff[3]00ff00[2]ff[2]00[5]ff[2]8081[c]82ff[6]00[3]ff[2]00[5]ff[2]904e[2]45534275696c646572009200[5]ff00[4]ff[2]00[4]ff[2]a0a1[c]a200[5]ff[2]00[2]ff[2]00[5]ff[4]00[6]ff[3]00[7]ff00ff00[2]ff[3]00[4]ff[8]00[2]ff[3]00[7]ff00ff00[2]ff[3]00[b]ff00ff[5]00ff[2]00[2]ff00ff00[3]ff[3]00[2]ff00[8]ff[2]00[3]ff00[9]ff00[2]ff[2]00[d]ff[5]00[7]ff00[4]ff[3]00[19]ff00[4]ff00[15]e8e9e6eaffe700[3]ff[3]00[2]ff00[10]e4e5e4e5e4e5e4e500[3]ff00[3]ff00[10]f2f3f2f3f2f3f2f300[3]ff[2]00[2]ff[2]00[f]e2e3e2e3e2e3e2e300[3]e6e7e6e800e6e700e6e9e700e800e700[6]f2f3f2f3f2f3f2f300[2]f7e1e0e1e0e1e0e1e0e1[3]e0e1e0e1e0f500[4]e2e3e2e3e2e3e2e3ff00f6f1f0f1f0f1f0f1f0f1f0f1f0f1f0f1f0f400[4]f2f3f2f3f2f3f2f3ff00f601[10]f400[4]e2e3e2e3e2e3e2e3ff00f601[10]f400[4]f2f3f2f3f2f3f2f3ff00f601[10]f400[4]e2e3e2e3e2e3e2e3ff00f601[10]f400[4]f2f3f2f3f2f3f2f3ff00f601[10]f400[4]e2e3e2e3e2e3e2e3ff00f601[10]f400[4]f2f3f2f3f2f3f2f3ff00'
#    data = '00[18]55[d]9da367ff[4]7599aa66ff[5]99aa660f[5]090a06'
#    print(data)
#    print()
#    print(str(hexlify(bytes(unRLE(data))), 'utf8'))
    

