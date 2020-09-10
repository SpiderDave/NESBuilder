
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
        ),
    text = (
        'FileNameCHR',
        'FileNameName',
        'FileNameAttr',
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
                v = int(v)
            d.update({k:v})
    return d

def unRLE(d):
    out =""
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
    return out