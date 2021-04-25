import math
from math import cos, sin, pi

# points is number of points per quarter cycle
def generateSineTable(points = 20, amplitude = 100, intSize = 1):
    quarter_sine_table = []
    half_sine_table = []
    sine_table = []

    for x in range(0, points):
        n = sin(2 * pi * (90/points * x) / 360)
        n = int(n * amplitude)
        quarter_sine_table.append(n)
    
#    def diffSine(sineTable):
#        newT = []
#        for i, t in enumerate(sineTable):
#            if i > 0:
#                t = t-sineTable[i-1]
#            if t<0:
#                t = t % 256
#            newT.append(t-sineTable[i-1])
#        return newT
    
    if amplitude>256:
        intSize = 2
    
    diffSine = lambda t: [(x-t[i-1]) % (256**intSize) if i>0 else 0 for i, x in enumerate(t)]
    q1 = quarter_sine_table
    q2 = quarter_sine_table[::-1]
    
    q3 = [-x % (256**intSize) for x in q1]
    q4 = [-x % (256**intSize) for x in q2]
    q1Diff=diffSine(q1)
    q2Diff=diffSine(q2)
    q3Diff=diffSine(q3)
    q4Diff=diffSine(q4)
    
    low = lambda t: [x % 256 for x in t]
    high = lambda t: [math.floor(x / 256) for x in t]
    
    
    q1Low = low(q1)
    q1High = high(q1)
    q2Low = low(q2)
    q2High = high(q2)
    q3Low = low(q3)
    q3High = high(q3)
    q4Low = low(q4)
    q4High = high(q4)
    
    return dict(
        q1=q1,
        q2=q2,
        q3=q3,
        q4=q4,
        q1Low=q1Low,
        q1High=q1High,
        q2Low=q2Low,
        q2High=q2High,
        q3Low=q3Low,
        q3High=q3High,
        q4Low=q4Low,
        q4High=q4High,
        full=q1+q2+q3+q4,
        half=q1+q2,
        quarter=q1,
        
        q1Diff=q1Diff,
        q2Diff=q2Diff,
        q3Diff=q3Diff,
        q4Diff=q4Diff,
        fullDiff=q1Diff+q2Diff+q3Diff+q4Diff,
        halfDiff=q1Diff+q2Diff,
        quarterDiff=q1Diff,
        
        intSize = intSize,
    )

def chunker(seq, size):
    res = []
    for el in seq:
        res.append(el)
        if len(res) == size:
            yield res
            res = []
    if res:
        yield res

def makeTableData(data, intSize=1, indent=4, nItems=8):
    # make sure it's a list, tuple, etc
    if type(data) in (int, str):
        data = [data]
    out=''
    
    try:
        if max(data) > 256:
            intSize = 2
    except:
        pass
    
    for chunk in chunker(data, nItems):
        newData = []
        for i, item in enumerate(chunk):
            if type(item) is int:
                newData.append('${0:02x}'.format(item))
            else:
                newData.append(item)
        if intSize > 1:
            out+=' '*indent+'dw '+', '.join(newData)+'\n'
        else:
            out+=' '*indent+'db '+', '.join(newData)+'\n'
    out = out.rstrip()
    return out
