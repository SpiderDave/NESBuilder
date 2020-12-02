# Apply IPS patch given ips file data and target file data.
# Returns patched file data or False.
def applyIps(ipsData, fileData):
    if type(ipsData) == str:
        ipsData = list(ipsData.encode())
    if type(fileData) == str:
        fileData = list(fileData.encode())
        
    # Check for IPS header
    if bytes(ipsData[:5]) == b'PATCH':
        ipsData = ipsData[5:]
    else:
        print('Error: Invalid IPS header')
        return False
    
    loopLimit = 90000
    loopCount = 0
    
    while True:
        loopCount+=1
        if loopCount>=loopLimit:
            print('Error: Loop limit exceeded.')
            return False
        
        # "EOF" marker
        if bytes(ipsData[:3]) == b'EOF':
            # Check for IPS format exension "truncate" feature after EOF
            ipsData = ipsData[3:]
            truncate = int.from_bytes(ipsData[:4], 'big', signed=False)
            ipsData = ipsData[4:]
            if truncate == 0:
                # Doesn't usually make sense to truncate the whole file via ips patch.
                pass
            elif truncate == len(fileData):
                # It's already the right size, do nothing
                pass
            elif truncate > len(fileData):
                # Expand file
                fileData = fileData + [0] * (truncate - len(fileData))
            else:
                # Truncate file
                fileData = fileData[:truncate]
            break
        
        if len(ipsData) == 0:
            # end of data
            break
        
        offset = int.from_bytes(ipsData[:3], 'big', signed=False)
        ipsData = ipsData[3:]
        
        chunkSize = int.from_bytes(ipsData[:2], 'big', signed=False)
        ipsData = ipsData[2:]
        
        if chunkSize == 0:
            # RLE
            chunkSize = int.from_bytes(ipsData[:2], 'big', signed=False)
            ipsData = ipsData[2:]
            
            if chunkSize == 0:
                print('Error: Bad RLE size')
                return False
            
            replaceData = ipsData[:1] * chunkSize
            ipsData = ipsData[1:]
        else:
            replaceData = ipsData[:chunkSize]
            ipsData = ipsData[chunkSize:]
        
        # Apply the new data
        for i,b in enumerate(replaceData):
            fileData[offset+i] = b
    
    return fileData
