def getGG(ggString):
    try:
        ggString = ggString.strip().split(' ',1)[0].strip()

        # Used to map the GG characters to binary
        ggMap = dict(A="0000", P="0001", Z="0010", L="0011",
                     G="0100", I="0101", T="0110", Y="0111",
                     E="1000", O="1001", X="1010", U="1011",
                     K="1100", S="1101", V="1110", N="1111")

        if len(ggString) == 6:
            ggMap2=[0,5,6,7,20,1,2,3,None,13,14,15,16,21,22,23,4,9,10,11,12,17,18,19]
        elif len(ggString) == 8:
            ggMap2=[0,5,6,7,28,1,2,3,None,13,14,15,16,21,22,23,4,9,10,11,12,17,18,19,24,29,30,31,20,25,26,27]
        else:
            return

        # map to binary string
        binString = ''.join([ggMap[x.upper()] for x in ggString])
        # unscramble the binary string
        binString2 = ''.join([binString[ggMap2[i]] for i, x in enumerate(binString) if ggMap2[i] is not None])
        
        v = int(binString2[0:8], 2)
        a = int(binString2[9:24], 2)
        if len(ggString) == 8:
            c = int(binString2[24:32], 2)
            return dict(address = a, value = v, compare = c)
        return dict(address = a, value = v)
    except:
        return

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) == 1:
        print('Usage: gg.py <gg code>')
    else:
        gg = getGG(sys.argv[1])
        if gg:
            print('{:04x}:{:02x} {:02x}'.format(gg.get('address'), gg.get('value'), gg.get('compare', 0)))
        else:
            print('bad gg code')
        
        
        
        
