# -------------------------------------------------------------------------------------
# Konami RLE compression (as used in Life Force)
#
# Start with a 2 byte PPU address (little endian), then zero or more operations:
#
# 00        Read another byte, and write it to the output 256 times
# 01-7E     Read another byte, and write it to the output n times.
# 7F        Read another two bytes for a new PPU address
# 80        Read another byte, and write it to the output 255 times
# 81-FE     Copy n - 128 bytes from input to output.
# FF        End of data
#
# Notes:
#           00 is never used.  Sometimes listed as copy 0 bytes.  Avoiding.
#           80 can be inconsistant/invalid/error on some games.  Avoiding.
#
# References:
#           https://datacrystal.romhacking.net/wiki/Blades_of_Steel:ROM_map
#           https://www.nesdev.org/wiki/Tile_compression#Konami_RLE
# -------------------------------------------------------------------------------------

# Kemoko RLE compression (as used in Bugs Bunny Crazy Castle)
#
# Uses a rudimentary RLE compression.
#
# FF xx yy  Output tile xx yy times.
# 00-FE     Copy input to output.
# FF FF 00  End of data.  The second byte can be anything, but FF is used.
#-------------------------------------------------------------------------------------
#
# Select Screen data:
# 03:d7d6 (file offset 0xd7e6)
# 0x33d bytes


# -------------------------------------------------------------------------------------
# ToDo:
# -------------------------------------------------------------------------------------
#   * make this a class
#   * limit or redefine opcodes
# Command line:
#   * choose files to output with various file types
#   * output multiple files
#   * choose files to join together
#   * auto detect nametable from ppu writes
#   * specify ppu address for writing when compressing

from itertools import groupby

# get file contents as a list
def getFileContents(filename):
    with open(filename, 'rb') as file:
        return list(file.read())

# write list to file as bytes
def writeToFile(filename, data):
    with open(filename, 'wb') as file:
        file.write(bytes(data))
        print(f'file "{filename}" written.')

# list to int
def toInt(data, endian='little'):
    return int.from_bytes(bytes(data), endian, signed=False)

# address to list
def addrToList(n, endian='little'):
    return list((n).to_bytes(2, endian))

# get the consecutive repetitions of the first element in a list
def getRep(l):
    return [sum(1 for x in group) for x, group in groupby(l)][0]

# decompress data compressed with Konami RLE format
#
# arguments are supplied in the form of a dict
#   data:       data to decompress
#   offset:     decompress data at the given offset
#
# returns a dict:
#   details:            text details of decompression
#   ppu:                dict containing elements of generated ppu
#       full            full ppu
#       patternTable    a list containing pattern tables
#       nameTable       a list containing name tables (without attributes)
#       attrTable    a list containing attribute tables
#       palettes        palettes
def decompressKonamiRLE(arg = {}):
    data = arg.get('data')
    offset = arg.get('offset', 0)
    
    txtOut = ""
    txtOut += "\n* * decompress * *\n\n"
    
    data = list(data)
    
    data = data[offset:]
    originalData = data[:]
    
    ppu = [0] * 0x4000
    
    # track the length of compressed data
    dataLength = 0
    
    # get initial ppu address
    address = toInt(data[:2])
    txtOut += "address (0x{:04x}): {:02x} {:02x}\n".format(address, data[0], data[1])
    data = data[2:]
    dataLength += 2
    
    while data:
        op = data.pop(0)
        dataLength += 1
        
        if op == 0:
            # Read another byte, and write it to the output 256 times
            txtOut += "repeat ({:d}): {:02x} {:02x}\n".format(256, op, data[0])
            ppu[address:address + 256] = [data.pop(0)] * 256
            address += 256
            dataLength += 1
        elif op >= 1 and op <= 0x7e:
            # Read another byte, and write it to the output n times
            txtOut += "repeat ({:d}): {:02x} {:02x}\n".format(op, op, data[0])
            ppu[address:address + op] = [data.pop(0)] * op
            address += op
            dataLength += 1
        elif op == 0x7f:
            # Read another two bytes for a new PPU address
            address = toInt(data[:2])
            txtOut += "address (0x{:04x}): {:02x} {:02x} {:02x}\n".format(address, op, data[0], data[1])
            data = data[2:]
            dataLength += 2
        elif op == 0x80:
            # Read another byte, and write it to the output 255 times
            txtOut += "repeat ({:d}): {:02x} {:02x}\n".format(255, op, data[0])
            ppu[address:address + 255] = [data.pop(0)] * 255
            address += 255
            dataLength += 1
        elif op >= 0x81 and op <= 0xfe:
            # Copy n - 128 bytes from input to output.
            
            txtOut += "copy ({:d}): {:02x} ".format(op-128, op)
            txtOut += ' '.join(['{:02x}'.format(x) for x in data[:op-128]])
            txtOut += '\n'
            
            ppu[address:address + op-128] = data[:op-128]
            data = data[op-128:]
            address += op-128
            dataLength += op-128
        elif op == 0xff:
            txtOut += "end: {:02x}\n".format(op)
            break
    
    d = dict(
        offset = offset,
        length = dataLength,
        inputLength=dataLength,
        ppu = dict(
            full = ppu,
            patternTable = [ppu[0:0+0x1000], ppu[0x1000:0x1000+0x1000]],
            nameTable = [ppu[0x2000:0x2000+0x3c0], ppu[0x2400:0x2400+0x3c0], ppu[0x2800:0x2800+0x3c0], ppu[0x2c00:0x2c00+0x3c0]],
            attrTable = [ppu[0x23c0:0x23c0+0x40], ppu[0x27c0:0x27c0+0x40], ppu[0x2bc0:0x2bc0+0x40], ppu[0x2fc0:0x2fc0+0x40]],
            palette = ppu[0x3f00:0x3f00+0x20],
            ),
        details=txtOut,
        data = originalData[:dataLength],
        )
    return d

# compress using Konami RLE format
#
# arguments are supplied in the form of a dict
#   data:       data to compress
#   address:    ppu address (defaults to 0x2000)
#
# returns a dict:
#   details:            text details of compression
#   data:               compressed data
def compressKonamiRLE(arg = {}):
    data = arg.get('data')
    offset = arg.get('offset', 0)
    address = arg.get('address', 0x2000)
    
    data = list(data)
    data = data[offset:]
    inputLength = len(data)
    
    txtOut = ""
    txtOut += "\n* * compress * *\n\n"

    out = []
    
    # output initial ppu address
    out.extend(addrToList(address))
    
    firstLoop = True
    
    while data:
        rep = getRep(data)
        
        if rep > 0x7e:
            txtOut += "repeat ({:d}): {:02x} {:02x}\n".format(0x7e, 0x7e, data[0])
            out.append(0x7e)
            out.append(data[0])
            data = data[0x7e:]
        elif (rep >= 3):
            txtOut += "repeat ({:d}): {:02x} {:02x}\n".format(rep, rep, data[0])
            out.append(rep)
            out.append(data[0])
            data = data[rep:]
        else:
            d = []
            while data:
                if getRep(data) >= 4: # repeat threshold here is 4
                    break
                d.append(data.pop(0))
                if len(d) > 0x7e:
                    break
            txtOut += "copy ({:d}): {:02x} ".format(len(d), 0x80 + len(d))
            txtOut += ' '.join(['{:02x}'.format(x) for x in d])
            txtOut += '\n'
    
            out.append(0x80 + len(d))
            out.extend(d)
    txtOut += "end: {:02x}\n".format(0xff)
    out.append(0xff)
    
    d = dict(length = len(out), inputLength=inputLength, data=out, details=txtOut)
    return d

# compress using Kemko RLE format
#
# arguments are supplied in the form of a dict
#   data:       data to compress
#   address:    ppu address (defaults to 0x2000)
#
# returns a dict:
#   details:            text details of compression
#   data:               compressed data
def compressKemkoRLE(arg = {}):
    data = arg.get('data')
    offset = arg.get('offset', 0)
    address = arg.get('address', 0x2000)
    
    data = list(data)
    data = data[offset:]
    inputLength = len(data)
    
    txtOut = ""
    txtOut += "\n* * compress * *\n\n"

    out = []
    
    firstLoop = True
    
    while data:
        rep = getRep(data)
        
        if rep > 0xfe:
            txtOut += "repeat ({:d}): {:02x} {:02x} {:02x}\n".format(0xfe, 0xff, data[0], 0xfe)
            out.append(0xff)
            out.append(data[0])
            data = data[0xfe:]
        elif (rep >= 3):
            txtOut += "repeat ({:d}): {:02x} {:02x} {:02x}\n".format(rep, 0xff, data[0], rep)
            out.append(0xff)
            out.append(data[0])
            out.append(rep)
            data = data[rep:]
        elif data[0] == 0xff:
            # handle literal 0xff
            out.append(0xff)
            out.append(0xff)
            out.append(rep)
            data = data[rep:]
        else:
            d = []
            count = 0
            while data:
                if data[0] == 0xff:
                    # handle a literal 0xff elsewhere
                    break
                rep = getRep(data)
                if rep >= 4: # repeat threshold here is 4
                    break
                d.append(data.pop(0))
                count += 1
                
                # handle literal 0xff
#                if d[-1] == 0xff:
#                    data = data[rep:]
#                    d.append(0xff)
#                    d.append(rep)
                
            txtOut += "copy ({:d}): ".format(count)
            txtOut += ' '.join(['{:02x}'.format(x) for x in d])
            txtOut += '\n'
            
            out.extend(d)
    txtOut += "end: {:02x} {:02x} {:02x}\n".format(0xff, 0xff, 0x00)
    out.append(0xff)
    out.append(0xff)
    out.append(0x00)
    
    d = dict(length = len(out), inputLength=inputLength, data=out, details=txtOut)
    return d

# decompress data compressed with Kemko RLE format
#
# arguments are supplied in the form of a dict
#   data:       data to decompress
#   offset:     decompress data at the given offset
#
# returns a dict:
#   details:            text details of decompression
#   ppu:                dict containing elements of generated ppu
#       full            full ppu
#       patternTable    a list containing pattern tables
#       nameTable       a list containing name tables (without attributes)
#       attrTable       a list containing attribute tables
#       palettes        palettes
def decompressKemkoRLE(arg = {}):
    data = arg.get('data')
    offset = arg.get('offset', 0)
    
    # initial ppu address
    address = arg.get('address', 0x2000)
    
    txtOut = ""
    txtOut += "\n* * decompress * *\n\n"
    
    data = list(data)
    
    data = data[offset:]
    originalData = data[:]
    
    ppu = [0] * 0x4000
    
    # track the length of compressed data
    dataLength = 0
    
    while data:
        op = data.pop(0)
        dataLength += 1
        
        if op == 0xff:
            # Read two bytes for (value, len) and write value to output len times
            
            d = data.pop(0)
            l = data.pop(0)
            
            # Writing 0 times signals end of data
            if l == 0:
                txtOut += "end: {:02x} {:02x} {:02x}\n".format(op, d, l)
                dataLength += 2
                break
            else:
                txtOut += "repeat ({:d}): {:02x} {:02x} {:02x}\n".format(l, op, d, l)
            
            ppu[address:address + l] = [d] * l
            address += l
            dataLength += 2
        else: # 0x00 - 0xfe
            # Copy bytes from input to output.
            
            # copy until we find another 0xff
            d = [op] + data[:data.index(0xff)]
            l = len(d)
            
            txtOut += "copy ({:d}): ".format(l)
            txtOut += ' '.join(['{:02x}'.format(x) for x in d])
            txtOut += '\n'
            
            ppu[address:address + l] = d
            data = data[l-1:]
            address += l
            dataLength += l-1
    
    d = dict(
        offset = offset,
        length = dataLength,
        inputLength=dataLength,
        ppu = dict(
            full = ppu,
            patternTable = [ppu[0:0+0x1000], ppu[0x1000:0x1000+0x1000]],
            nameTable = [ppu[0x2000:0x2000+0x3c0], ppu[0x2400:0x2400+0x3c0], ppu[0x2800:0x2800+0x3c0], ppu[0x2c00:0x2c00+0x3c0]],
            attrTable = [ppu[0x23c0:0x23c0+0x40], ppu[0x27c0:0x27c0+0x40], ppu[0x2bc0:0x2bc0+0x40], ppu[0x2fc0:0x2fc0+0x40]],
            palette = ppu[0x3f00:0x3f00+0x20],
            ),
        details=txtOut,
        data = originalData[:dataLength],
        )
    return d

def compressNatsume(arg = {}):
    pass

def decompressNatsume(arg = {}):
    data = arg.get('data')
    offset = arg.get('offset', 0)
    dictOffset = arg.get('dictOffset', 0x9700)
    dictEntries = arg.get('dictEntries', 0x15)
    
    # initial ppu address
    address = arg.get('address', 0x2000)
    
    txtOut = ""
    txtOut += "\n* * decompress * *\n\n"
    
    data = list(data)
    
    originalData = data[:]
    data = data[offset:]
    
    # get dictionary
    dictionary = []
    a = dictOffset
    for i in range(dictEntries):
        l = originalData[a]
        dictionary.append(originalData[a+1:a+1+l])
        a = a + l + 1
    
    ppu = [0] * 0x4000
    
    # track the length of compressed data
    dataLength = 0

    while data:
        op = data.pop(0)
        dataLength += 1
        l = 0
        vertical = False
        
        if op == 0:
            # end of data
            txtOut += "end: {:02x}\n".format(0x00)
            dataLength += 1
            break
        
        if op & 0x80:
            # vertical
            vertical = True
        
        if op & 0x40:
            # ppu address
            address = toInt(data[:2], 'big')
            txtOut += "address (0x{:04x}): {:02x} {:02x}\n".format(address, data[0], data[1])
            data = data[2:]
            dataLength += 2
            
        if op & 0x20:
            # dict entry
            entry = op & ~0xe0
            if entry > len(dictionary):
                # invalid entry
                return
            d = dictionary[entry]
            l = len(d)
            txtOut += "dict ({:d}): {:02x} ".format(entry, l)
            txtOut += ' '.join(['{:02x}'.format(x) for x in d])
            txtOut += '\n'
            
            if vertical:
                for byte in d:
                    ppu[address] = byte
                    address += 0x20
            else:
                ppu[address:address + l] = d
                address += l
        else:
            # copy bytes
            l = op & ~0xe0
            
            d = data[:l]
            
            txtOut += "copy ({:d}): ".format(l)
            txtOut += ' '.join(['{:02x}'.format(x) for x in d])
            txtOut += '\n'
            
            if vertical:
                for byte in d:
                    ppu[address] = byte
                    address += 0x20
            else:
                ppu[address:address + l] = d
                address += l
            
            data = data[l:]
            dataLength += l
    d = dict(
        offset = offset,
        length = dataLength,
        inputLength=dataLength,
        ppu = dict(
            full = ppu,
            patternTable = [ppu[0:0+0x1000], ppu[0x1000:0x1000+0x1000]],
            nameTable = [ppu[0x2000:0x2000+0x3c0], ppu[0x2400:0x2400+0x3c0], ppu[0x2800:0x2800+0x3c0], ppu[0x2c00:0x2c00+0x3c0]],
            attrTable = [ppu[0x23c0:0x23c0+0x40], ppu[0x27c0:0x27c0+0x40], ppu[0x2bc0:0x2bc0+0x40], ppu[0x2fc0:0x2fc0+0x40]],
            palette = ppu[0x3f00:0x3f00+0x20],
            ),
        details=txtOut,
        dictionary = dictionary[:],
        data = originalData[:dataLength],
        )
    return d


if __name__ == '__main__':
    import argparse
    
    def strToInt(s):
        s=s.strip()
        if s.startswith('0x'):
            return int(s, 16)
        else:
            return int(s)

    parser = argparse.ArgumentParser(description='Compression')
    
    group = parser.add_mutually_exclusive_group(required = True)
    group.add_argument('-c', action='store_true',
                        help='Compress')
    group.add_argument('-d', action='store_true',
                        help='Decompress')
    
    parser.add_argument('-offset', type=strToInt, nargs='?',
                        help='Input file offset')
    
    parser.add_argument('inputfile', type=str, metavar="<input file>",
                        help='Input file')
    parser.add_argument('outputfile', type=str, metavar="<output file>",
                        help='Output file')
    
    version = dict(
        name = 'NES Compression',
        version = '2022.10.01',
        author = 'SpiderDave',
    )
    print('\n{} {} by {}\n'.format(version.get('name'), version.get('version'), version.get('author')))
    
    args = parser.parse_args()
    
    filename = args.inputfile
    
    with open(filename, 'rb') as file:
        data = list(file.read())
    
    offset = args.offset or 0
    
    #filename = r"J:\svn\NESBuilder\projects\Castlevania3\Castlevania III - Dracula's Curse (USA).nes"
    #offset = 0xb580
    
#    filename = r"J:\svn\NESBuilder\projects\BugsBunnyCrazyCastle\Bugs Bunny Crazy Castle, The (USA).nes"
#    offset = 0xd7e6
    
#    if args.d:
#        d = decompressKonamiRLE(dict(data=data, offset=offset))
#    else:
#        d = compressKonamiRLE(dict(data=data, offset=offset))
    if args.d:
        d = decompressKemkoRLE(dict(data=data, offset=offset))
    else:
        d = compressKemkoRLE(dict(data=data, offset=offset))
    
    print(f'    input filename: "{args.inputfile}"')
    print('    file offset: {}'.format(hex(offset)))
    print('    length: {}'.format(hex(d.get('inputLength'))))
    print()
    print('    {}compressing --->'.format(args.d and 'de' or ''))
    print()
    print(f'    output filename: "{args.outputfile}"')
    print(d.get('details'))
    
    if args.d:
        ppu = d.get('ppu')
        
        # for now, just writes nametable 0 with attributes.
        data = ppu.get('nameTable')[0] + ppu.get('attrTable')[0]
        
    else:
        data = d.get('data')
    
    print('    length: {}'.format(hex(len(data))))
    
    with open(args.outputfile, 'wb') as file:
        file.write(bytes(data))

    print('\ndone.\n')