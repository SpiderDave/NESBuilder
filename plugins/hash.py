import hashlib, zlib

def getHash(fileData, method):
    if method in ('md5', 'sha1', 'sha256'):
        return getattr(hashlib, method)(bytes(fileData)).hexdigest()
    if method in ('crc32'):
        return '{0:08x}'.format(getattr(zlib, method)(bytes(fileData)))
