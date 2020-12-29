# SpiderDaveAsm
ASM 6502 Assembler made in Python

------------------------------------------------------------
WARNING: This project is currently in alpha stage.
Some features may be incomplete, have bugs, or change.
------------------------------------------------------------


## Command line ##

Usage:
    py sdasm.py <asm file>
    
Currently, creates output.txt and output.bin.


## Features ##
* Supports all (official) 6502 opcodes
* Anonymous labels, local labels
* macros

# Syntax #

Configuration:
    After running once, a config.ini will be generated.  Some syntax may be changed with configuration.

Opcodes:
    Standard 6502 ocodes are supported.  Opcodes are case-insensitive.

Comments:
    Comments start with a semicolon or "//", and can also be used at the end of a line.
    Block-level comments are enclosed in "/*" "*/" and may be nested.
    
```
    ; This is a comment
    // This is also a comment
    /*
        This is a block level comment
    */
```

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

    Symbols enclosed in {} can be used to insert them anywhere.
    {:expression} can be used to insert an expression anywhere.
    
```
    file = foobar
    include {file}.asm
```

## Filters ##
    
    There are a number of special "filters" using the format {filter: data}
    
    shuffle
        Shuffle a list of bytes.
    
```
    db {shuffle:$00, $01, $02, $03, $04} ; outputs 5 bytes in random order
```
    
    choose
        Choose a random item from a list.
    
```
    db {choose:$00, $01, $02} ; outputs either $01, $02 or $03
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
        format to a string
    
```
    print {$04x:99} ; prints $0063.
```
    
    textmap
        apply textmap to a string
    
```
    db {textmap:"HELLO"} ; Works the same as text "HELLO"
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

fillvalue

    Change the default filler for pad, align, etc.
    
```
    fillvalue $ff
```

enum
ende

    Reassign PC and suppress assembly output.  Useful for defining
    variables in RAM.
    
```
    enum $200
    foo:    db 0
    foo2:   db 0
    enum
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
    include code/macros
```

incbin / bin
    
    Add a file to the assembly as raw data.  A start offset and size may also
    be specified
    
```
    ; include whole file
    incbin "chr00.chr"
    
    ; include 32 bytes from file.dat starting at file offset 16.
    incbin "file.dat", $10, $20
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