from datetime import datetime
date = datetime.now()

version = dict(
    v1=date.year,
    v2=date.month,
    v3=date.day,
    v4=0,
    stage = "alpha",
    author = "SpiderDave",
    name = "NESBuilder",
    )

data = """
# http://msdn.microsoft.com/en-us/library/ms646997.aspx
VSVersionInfo(
  ffi=FixedFileInfo(
# filevers and prodvers should be always a tuple with four items: (1, 2, 3, 4)
# Set not needed items to zero 0.
filevers=({v1}, {v2}, {v3}, {v4}),
prodvers=({v1}, {v2}, {v3}, {v4}),
# Contains a bitmask that specifies the valid bits 'flags'r
mask=0x3f,
# Contains a bitmask that specifies the Boolean attributes of the file.
flags=0x0,
# The operating system for which this file was designed.
# 0x4 - NT and there is no need to change it.
OS=0x4,
# The general type of file.
# 0x1 - the file is an application.
fileType=0x1,
# The function of the file.
# 0x0 - the function is not defined for this fileType
subtype=0x0,
# Creation date and time stamp.
date=(0, 0)
),
  kids=[
StringFileInfo(
  [
  StringTable(
    u'040904B0',
    [StringStruct(u'CompanyName', u'{author}'),
    StringStruct(u'FileDescription', u'{name} ({stage})'),
    StringStruct(u'FileVersion', u'{v1}.{v2}.{v3}'),
    StringStruct(u'InternalName', u'{name}'),
    StringStruct(u'LegalCopyright', u'Copyright (c) {author}'),
    StringStruct(u'OriginalFilename', u'{name}.exe'),
    StringStruct(u'ProductName', u'{name}'),
    StringStruct(u'ProductVersion', u'{v1}.{v2}.{v3} {stage}')])
  ]), 
VarFileInfo([VarStruct(u'Translation', [1033, 1200])])
  ]
)
""".format(**version)

f=open('version.py',"w")
f.write(data)
f.close()
