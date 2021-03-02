from math import cos, sin, pi

# points is number of points per quarter cycle
def generateSineTable(points = 20, amplitude = 100):
    quarter_sine_table = []
    half_sine_table = []
    sine_table = []

    for x in range(0, points):
        n = sin(2 * pi * (90/points * x) / 360)
        n = int(n * amplitude)
        quarter_sine_table.append(n)

    q1 = quarter_sine_table
    q2 = quarter_sine_table[::-1]
    q3 = [-x for x in q1]
    q4 = [-x for x in q2]
    
    return dict(q1=q1,q2=q2,q3=q3,q4=q4,full=q1+q2+q3+q4, half=q1+q2, quarter=q1)

def chunker(seq, size):
    res = []
    for el in seq:
        res.append(el)
        if len(res) == size:
            yield res
            res = []
    if res:
        yield res

def makeTable(data, indent=4, nItems=8):
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
        out+=' '*indent+'db '+', '.join(newData)+'\n'
    out = out.rstrip()
    return out
