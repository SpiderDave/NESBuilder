# parse a ld65 configuration file and return a dictionary
# The items in each section will use an OrderedDict()
# https://cc65.github.io/doc/ld65.html#s5
def read(filename='ld65.cfg', outputFileName = 'output'):
    import re
    from collections import OrderedDict
    
    try:
        with open(filename) as file:
            fileContents = file.read().strip()
    except:
        return False
    
    d = dict(
        memory = {},
        segments = {},
        files = {},
        format = {},
        features = {},
        symbols = {},
    )

    for sectionId in d.keys():
        try:
            section = re.findall(sectionId + '\s*?{(.*?)}', fileContents, re.DOTALL | re.IGNORECASE)
            section = [x.strip() for x in section[0].strip().split(';') if x.strip() != '']

            for line in section:
                id = line.split(':')[0].strip()
                data = line.split(':')[1].strip()

                data = re.split('\s*[,\n]+\s*', data, re.DOTALL | re.IGNORECASE)
                
                d[sectionId].update({id:OrderedDict()})
                
                for item in data:
                    k, v = re.split('(?:\s*=\s*|\s+)', item, re.DOTALL | re.IGNORECASE)
                    k = k.strip().lower()
                    v = v.strip()
                    
                    # force some specific values lowercase
                    if v.lower() in ('yes','no','ro','rw','bss','zp','overwrite'):
                        v = v.lower()
                    if '%O' in v:
                        v = v.replace('%O', outputFileName)
                    if v.startswith('$'):
                        v = int(v[1:],16)
                    d[sectionId][id].update({k:v})
        except:
            pass
    
    # remove empty sections
    d = {k:v for k,v in d.items() if v}
    
    return d
