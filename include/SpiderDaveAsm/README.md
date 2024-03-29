# SpiderDaveAsm
ASM 6502 Assembler made in Python

------------------------------------------------------------
WARNING: This project is currently in alpha stage.
Some features may be incomplete, have bugs, or change.
------------------------------------------------------------


## Command line ##

Usage:
    py sdasm.py [-h] [-l <file>] [-bin <file>] [-cfg <file>] [-fulltb]
                [-d <symbol>] [-q] [-symbols <file>]
                sourcefile [outputfile]

## Features ##
* Supports all (official) 6502 opcodes
* Anonymous labels, local labels
* macros, functions

# Syntax #

Configuration:
    After running once, a config.ini will be generated.  Some syntax may be changed with configuration.

Opcodes:
    Standard 6502 ocodes are supported.

Comments:
    Comments start with ";" or "//", and can also be used at the end of a line.
    Block-level comments are enclosed in "/*" "*/".
    
```
    ; This is a comment
    // This is also a comment
    /*
        This is a block level comment
    */
```

Line Continuation:
    A \ at the end of a line may be used as a line continuation.  Whitespace
    after the character will be ignored.
    
    A , may also be used, but will preserve the , character.

## Labels ##
    Labels may end in a colon.  Code can be placed on the same line as labels.
    Anonymous labels are 1 or more "-" or "+" characters.  These labels will only
    search backwards for "-" and forwards for "+".  Named directional labels can
    also be made by prefixing with "-" or "+".  Labels starting with '@' are
    local labels.  They have limited scope, visible only between non-local labels.
    
    
```
    Start:
    - lda PPUSTATUS     ; wait one frame
    bpl -
    
    - lda PPUSTATUS     ; wait another frame
    bpl -
    
    ldx #$05
    -loopstart
    dex
    bne -loopstart
    
    label1:
    @tmp1:
    @tmp2:
    
    label2:
    @tmp1:
    @tmp2:
```

## Numbers and Symbols ##
    Hexadecimal numbers start with "$".  Binary numbers start with "%".
    A "$" by itself may be used to get or set the current address.
    
```
    lda #$00        ; The "#" indicates an "immediate" value.
    ora #%00001100
    sta $4002
```

    Symbols and expressions enclosed in {} can be used to insert them
    anywhere, even in text.
    
```
    file = foobar
    include "{file}.asm"
```

## Lists ##
    Lists can be used in most places.  List indexes start with 0.

```
    list = [1,2,3]          ; Create a list
    list = 1,2,3            ; Create a list
    list[2]                 ; Set the value of a list item.
    list = {concat:list, 5} ; Add an item to the end of list
```

## Filters ##
    
    There are a number of special "filters" using the format {filter: data}
    
    shuffle
        Shuffle a list of bytes.
    
```
    db {shuffle:$00, $01, $02, $03, $04}    ; outputs 5 bytes in random order
    
    a = 1,2,3,4,5                           ; Create list
    a = {shuffle:a}                         ; Shuffle list
```
    
    choose
        Choose a random item from a list.
    
```
    db {choose:$01, $02, $03} ; outputs either $01, $02 or $03
```
    
    random
        Generate a random number.
    
```
    db {random:256} ; outputs a random number from 0 to 255.
    db {random:5,10} ; outputs a random number from 5 to 9.
```
    
    range
        Generate a range of numbers.
    
```
    db {range:3} ; outputs 0,1,2,3
    db {range:5,10} ; outputs 5,6,7,8,9,10
    db {range:0,10,2} ; outputs 0,2,4,6,8,10
    db {range:5,0,-1} ; outputs 5,4,3,2,1,0
```
    
    getbyte
        Get a byte at given address.
    
```
    print {getbyte:$9015} ; print the byte at $9015 in current bank.
```
    
    getword
        Get a word at given address.
    
```
    print {getword:$9015} ; print the word at $9015 in current bank.
```
    
    format
        Format to a string
    
```
    print {$04x:99} ; prints $0063.
```
    
    textmap
        Apply textmap to a string
    
```
    db {textmap:"HELLO"} ; Works the same as text "HELLO"
```
    
    astext
        Force value to format value as text.  Useful if you have a symbol displaying as an array.
    
```
    test = "hello"
    print test          ; prints "test"
    print {test}        ; prints "[104, 101, 108, 108, 111]"
    print {astext:test} ; prints "hello"
```
    
    concat
        Concatenate data.
    
```
    print {concat:"foo","bar",0}    ; prints "102,111,111,98,97,114,0"
```
    
## Special Symbols ##
    
    sdasm
        always 1
    
    bank
        current bank
    
    lastbank
        last prg bank
    
    lastchr
        last chr bank
    
    banksize
        current bank size
    
    prgbanks
        number of prg banks
    
    chrbanks
        number of chr banks
    
    fileoffset
        current file offset
    
    year, month, day, hour, minute, second
        appropriate numerical time value
        
    randbyte
        random byte
    
    randword
        random word
    
    reptindex
        loop index for a rept block

## Strings ##
    
    String values are partially supported.

```
    foo = "bar"             ; works
    .db foo, "ABC", $00     ; works
    lda "A"                 ; works
    .db "ABC"+1             ; works (adds 1 to each character)
    .db "A"+"A"             ; does not work
```

## Operators ##

| op  | description                       |
|:---:|-----------------------------------|
|  %  | Modulo                            |
|  &  | Bitwise AND                       |
|  |  | Bitwise OR                        |
|  ^  | Bitwise XOR                       |
|  ~  | Invert                            |
|  << | Shift bits left                   |
|  >> | Shift bits right                  |
|  ** | Exponentiation                    |
|  *  | multiplication                    |
|  /  | division                          |
|  +  | addition                          |
|  -  | subtraction                       |
|  <  | prefix to give lower byte of word |
|  >  | prefix to give upper byte of word |    

## Directives ##
    Most directives may optionally be prefixed with a ".".

header / noheader

    Used to indicate the rom contains a 16-byte iNES header.  This is used
    for calculating addresses.
    
```
    header      ; rom contains a header
    
    noheader    ; rom does not contain a header
```
    
stripheader

    Used to indicate the rom contains a header, but it should be removed when
    generating the final binary.
    
```
    stripheader ; rom contains a header, but it should be removed after assembling.
```
    
=
define

    Used to define a symbol.  Symbol names are case-insensitive by default.
    
```
    foo = $42
    define bar $43
```
    
org
    
    Set the starting address if it hasn't been assigned yet, otherwise
    org functions like pad.
    
```
    org $8000  ; start assembling at $8000
    .
    .
    .
    org $fffa, $80 ;equivalent to PAD $fffa, $80
```

base
    
        Set the program address.  This is useful for relocatable code,
        multiple code banks, etc.
    
```
    base $8000
```

pad / fillto
    
    Fill memory from the current address to a specified address.  A fill
    value may also be specified.
    
```
    pad $FFFA
    pad $FFFA, $ea
```

fill
    
    Fill memory with specified number of bytes.  A fill value may also be specified.
    
```
    fill $20        ; output $20 bytes using current fillvalue
    fill $20, $ff   ; output $20 bytes using $ff
```

align
    
    Fill memory from the current address to specified byte boundary.  A fill
    value may also be specified.
    
```
    align 256
    align 256, $ea
```

banksize
    
    Set the size of each PRG bank.
    
chrsize
    
    Set the size of each CHR bank.
    
bank
    
    Set the current bank.

```
    incbin "smb.nes"

    banksize $8000
    header

    bank 0
    org $9069
        lda #$08 ; start with 9 lives
```

chr
    
    Set the current chr bank.  Internally, this will set the bank to the
    chr area and adjust the address.

```
    chr 0   ; Start of chr area
```

loadld65cfg
    
    load a ld65 configuration file.

```
    loadld65cfg "file.cfg"    ; load and parse "file.cfg"
    loadld65cfg               ; use default filename "ld65.cfg"
```

segment
    
    Set the current segment.  Requires loading a ld65 configuration file first.

```
    loadld65cfg         ; use default filename "ld65.cfg"
    segment "VECTORS"   ; use defined segment "VECTORS"
```

fillvalue

    Change the default filler for pad, align, etc.
    
```
    fillvalue $ff
```

insert

    Insert bytes at the current position.  A fill value may also be specified.
    
```
    insert $10          ; Insert $10 bytes using current fill value
    insert $10, $ff     ; Insert $10 bytes using $ff
```

delete

    Delete bytes at the current position.
    
```
    delete $10          ; Delete $10 bytes
```

truncate

    Delete everything at or beyond current position.
    
```
    truncate        ; The file ends here now.
```

enum
ende / endenum

    Reassign PC and suppress assembly output.  Useful for defining
    variables in RAM.
    
```
    enum $200
    foo:    db 0
    foo2:   db 0
    ende
```

db / byte / byt / dc.b
    
    Output bytes.  Multiple items are separated by commas.
    
```
    db $00, $01, $ff
```

dw / word / dbyt / dc.w
    
    Output words.  Multiple items are separated by commas.
    
```
    dw $8012, $8340
```

dl
    
    Similar to db, but outputs only the least significant byte of each value.

```
    dl $8012, $8340 ; equivalent to db <$8012, <$8340
```

dh
    
    Similar to db, but outputs only the most significant byte of each value.

```
    dh $8012, $8340 ; equivalent to db >$8012, >$8340
```

dsb
dsw
    
    Define storage bytes or words.  First argument is size, second is fill value.
    
```
    dsb 4           ; equivalent to db 0, 0, 0, 0
    dsb 4, $ff      ; equivalent to db $ff, $ff, $ff, $ff
    dsw 3, $1000    ; equivalent to dw $1000, $1000, $1000
```

hex

    Compact way of laying out a table of hex values.  Only raw hex values
    are allowed, no expressions.  Spaces can be used to separate numbers.

```
    hex 456789ABCDEF  ;equivalent to db $45,$67,$89,$AB,$CD,$EF
    hex 0 1 23 4567   ;equivalent to db $00,$01,$23,$45,$67
```

include / incsrc / include? / require
    
    Assemble another source file as if it were part of the source.
    Include? will not generate an error if the file does not exist.
    Require will abort assembly if the file does not exist.
    
```
    include foobar.asm
    include? optional.asm
    require important.asm
```

includeall
    
    Include all .asm files in a folder.  Files starting with "_" will be ignored.
    
```
    includeall code/macros
```

incbin / bin
    
    Add a file to the assembly as raw data.  A start offset and size may be
    specified, as well as a symbol to fill the data with instead of adding it
    to the output.
    
```
    ; include whole file
    incbin "chr00.chr"
    
    ; include 32 bytes from file.dat starting at file offset 16.
    incbin "file.dat", $10, $20
    
    ; get 32 bytes from file.dat starting at file offset 16 and 
    ; fill the symbol "foobar" with it.
    incbin "file.dat", $10, $20, foobar
```
    
incchr
    
    Include an image file as chr data.  The palette used should be set with
    setpalette as an index of the palette loaded with loadpalette (or the
    default palette, which is identical to FCEUX.pal).
    
```
    setpalette $22, $16, $27, $18
    
    chr 0
    incchr "smbchr0.png"
    incchr "smbchr0.png", 5, 2  ; include image starting at coordinates 5,2
    incchr "smbchr0.png", 5, 2, 16, 1  ; include 16 columns and 1 row starting at coordinates 5,2
```
    
start tilemap ... end tilemap
    
    Define a tilemap.  Before the main tilemap entries, you can define gridsize, chr, org, palette.
    
    gridsize = <size>
    chr <chr page>
    org <offset>
    palette = <hexidecimal palette>
    
    Each main entry uses hexidecimal for each tile id, x, y, and then flags of 
    either "h", "v", or "hv", to flip the tile horizontally, vertically, or both.
    
    Note: Syntax of this directive will likely change to something more consistant.
    
```
    start tilemap Mario_select1
        gridsize = 1
        chr $0c
        org $0
        palette = 0f271601
        00 00 00
        01 00 08
        00 08 00 h
        01 08 08 h
        02 00 10
        03 00 18
        02 08 10 h
        03 08 18 h
    end tilemap
```
    
importmap
exportmap
    
    Import image file data using a tilemap.  The tilemap may have its own chr bank, org, palette
    set.  exportmap works the same but exports using a tilemap to an image file.
    
```
    importmap "Mario_select1", "Mario_select1.png"            ; import using default coordinates (0,0)
    importmap $00, $00, "Mario_select1", "Mario_select1.png"  ; import using set coordinates
    exportmap "Mario_select1", "Mario_select1.png"            ; export using default coordinates (0,0)
    exportmap $00, $00, "Mario_select1", "Mario_select1.png"  ; export using set coordinates
```
    
assemble
    
    Assemble a file.  This is useful to assemble things in multiple stages, or to create a base
    binary and include it conditionally, etc.  The output file, etc can't be specified here, but
    the directives to do so are available from the file to assemble.
    
```
    assemble "test2.asm"
```
    
loadpalette
    
    Load a palette file (.pal).  Palette files should be 192 bytes--3 bytes per color, 64 colors.
    
```
    loadpalette "FCEUX.pal"
```
    
loadtable / table
    
    Load a table file (.tbl).
    
```
    loadtable "text.tbl"
    table text.tbl
```
    
cleartable
    
    clear current text mapping.
    
```
    cleartable
    textmap clear   ; This does the same thing as above
```
    
textmap
    
    Create a textmap.
    
```
    textmap set title       ; Set current textmap to "title"
    textmap clear           ; clear current textmap
    textmap abcd 00010203   ; Map characters a,b,c,d to $00,$01,$02,$03
    textmap 0...9 00        ; Map characters from 0 to 9 to tiles starting at $00
    textmap A...Z 0a        ; Map characters A-Z to tiles starting at $0a
    textmap space 24        ; Map a space to $24
```
    
outputfile
    
    Set the output filename.
    
```
    outputfile "game.nes"
```
    
listfile
    
    Set the list filename.
    
```
    outputfile "list.txt"
```
    
export
    
    Export a symbol to a file.
    
```
    ; Write the contents of foobar to foobar.dat
    export foobar, "foobar.dat"
```
    
diff
    
    Generate a diff between the current data and a file.
    
```
    diff original.nes               ; display differences as asm data
    diff original.nes, "data.asm"   ; output differences to data.asm
```
    
ips
    
    Apply IPS patch.
    
```
    ips "patch.ips"                 ; apply ips patch.
```
    
print
    
    Print a message
    
```
    print Hello World!
```

warning
    
    Print a warning message.  The message will start with "Warning: ".
    
```
    warning missing data!
```

error
    
    Print an error message and stops the assembler.  The message will start with "Error: ".
    
```
    error file not found!
```

macro
endm / endmacro

    MACRO name args...

    Define a macro.  Macro arguments are separated by commas or spaces.
    Note: symbols are not local.

```
    macro setAXY x,y,z
        lda #x
        ldx #y
        ldy #z
    macro

    setAXY $12,$34,$56
            ;expands to lda #$12
            ;           ldx #$34
            ;           ldy #$56
```

function
endf / endfunction

    Define a function.  Function arguments are separated by commas.
    Functions create a namespace with the function's name.

```
    function splitByte(a)
        ; to access this symbol outside of this function
        ; use splitByte.foo or change the namespace with
        ; namespace splitByte
        foo = 42 
        return >a, <a
    endfunction
    
    h,l = splitByte($42)

```

if
ifdef
elseif
else
endif

        Process a block of code if an expression is true (nonzero).

```
    if foobar = 3
        db 0
    elseif foobar = 5
        db 1
    else
        db $ff
    endif
```

ifdef / ifndef
elseif
else
endif

        ifdef will process a block of code if a symbol has been defined.
        ifndef will process a block of code if a symbol has not been defined.

```
    ifdef foobar
        db foobar
    else
        db 0
    endif
```

iffileexist / iffile
elseif
else
endif

        Process a block of code if given file exists.

```
    macro includeIfExist _file
        iffile {_file}
            include {_file}
        endif
    endm

    includeIfExist file.asm
```

seed
    
    Set the random number seed for use with anything that uses random values.
    
```
    seed $42
    db {shuffle:$00, $01, $02, $03, $04, $05}
```

mapdb
    
    Allows db directive to map text like the text directive.
    
```
    mapdb           ; turn on
    mapdb on        ; turn on
    mapdb true      ; turn on
    mapdb 1         ; turn on
    mapdb off       ; turn off
    mapdb false     ; turn off
    mapdb 0         ; turn off
```

clampdb
    
    Allows db directive to use numbers outside of byte range, clamping them to fit.
    
```
    clampdb         ; turn on
    clampdb on      ; turn on
    clampdb true    ; turn on
    clampdb 1       ; turn on
    clampdb off     ; turn off
    clampdb false   ; turn off
    clampdb 0       ; turn off
```

rept
endr / endrept

    Repeat block of code specified number of times.
    The special symbol {reptindex} can be used to get the loop index.
    Recursion is currently not supported.

```
    rept 5
        print This is rept loop {reptindex}.
    endr
```

findtext

    Search for text using the current textmap, starting at the current position.
    If found, the resulting bank and address will be printed, and the symbols
    "resultbank" and "resultaddress" will be filled.  If not found, the symbols
    will be false.
    
```
    lastpass        ; skip to final pass
```

lastpass

    Skip to final pass.  This will likely cause issues, but can be useful if you
    know the result will be ok.
    
```
    lastpass        ; skip to final pass
```