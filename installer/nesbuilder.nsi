; NSIS Installer script
;--------------------------------
!define MUI_BGCOLOR "1c8585"
!define MUI_INSTFILESPAGE_COLORS "FFFFFF 000000" ;Two colors
!define MUI_HEADER_TRANSPARENT_TEXT
!define MUI_TEXTCOLOR  "FFFF00"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_HEADERIMAGE_BITMAP_STRETCH AspectFitHeight

!include "MUI2.nsh"
!include Sections.nsh

; The name of the installer
Name "NES Builder"

; The file to write
OutFile "NESBuilder_Setup.exe"

; Request application privileges for Windows Vista and higher
RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir $PROGRAMFILES\NESBuilder

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NESBuilder" "Install_Dir"

;--------------------------------

;!getdllversion "..\dist\NESBuilder.exe" expv_
;!define MUI_PAGE_HEADER_TEXT "         [v${expv_1}.${expv_2}.${expv_3}]"

!insertmacro MUI_LANGUAGE "English"

; Pages

!define MUI_TEXT_COMPONENTS_TITLE "1 MUI_TEXT_COMPONENTS_TITLE"
!define MUI_TEXT_COMPONENTS_SUBTITLE "2 MUI_TEXT_COMPONENTS_SUBTITLE"
;!define MUI_COMPONENTSPAGE_TEXT_COMPLIST "4 MUI_COMPONENTSPAGE_TEXT_COMPLIST"
;!define MUI_COMPONENTSPAGE_TEXT_INSTTYPE "5 MUI_COMPONENTSPAGE_TEXT_INSTTYPE"
;!define MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_TITLE "6 MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_TITLE"
;!define MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_INFO "7 MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_INFO"
;!define MUI_INNERTEXT_COMPONENTS_DESCRIPTION_TITLE "8 MUI_INNERTEXT_COMPONENTS_DESCRIPTION_TITLE"
;!define MUI_INNERTEXT_COMPONENTS_DESCRIPTION_INFO "9 MUI_INNERTEXT_COMPONENTS_DESCRIPTION_INFO"
;!define MUI_PAGE_HEADER_TEXT "         version alpha"
;!define MUI_PAGE_HEADER_SUBTEXT  "PAGE_HEADER_SUBTEXT"

!define MUI_COMPONENTSPAGE_NODESC

!define MUI_COMPONENTSPAGE_TEXT_TOP "Check the components you want to install and uncheck the components$\n\
you dont want to install.  Click Next to continue."

!insertmacro MUI_PAGE_COMPONENTS

;Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------
Icon "installicon.ico"

InstType "Full"

!define GitURL "https://raw.githubusercontent.com/SpiderDave/NESBuilder/master/"




; The - makes it hidden
Section "-Uninstaller"
    SectionIn RO

    ; make sure the install folder exists
    CreateDirectory $INSTDIR
    
    ; Write the installation path into the registry
    WriteRegStr HKLM SOFTWARE\NESBuilder "Install_Dir" "$INSTDIR"

    ; Write the uninstall keys for Windows
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NESBuilder" "DisplayName" "NESBuilder"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NESBuilder" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NESBuilder" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NESBuilder" "NoRepair" 1
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "-DefaultStuff"
    SectionIn RO

    CreateDirectory $INSTDIR\tools
    inetc::get \
        "${GitURL}tools/asm6.exe" "tools/asm6.exe"\
        /END
    Pop $0

SectionEnd

; The stuff to install
Section "NESBuilder Executable"

    ;SectionIn RO
    SectionIn 1

    ; Set output path to the installation directory.
    SetOutPath $INSTDIR

    ; Put file there
    ;File "example2.nsi"

    CreateDirectory $INSTDIR\cursors

    inetc::get \
        "${GitURL}README.md" "README.md"\
        "${GitURL}main.lua" "main.lua"\
        "${GitURL}cursors/pencil.cur" "cursors/pencil.cur"\
        "${GitURL}dist/NESBuilder.exe" "NESBuilder.exe"\
        /END
    Pop $0

SectionEnd

Section "NESBuilder Source"
    #SectionIn RO
    SectionIn 1

    ; Set output path to the installation directory.
    SetOutPath $INSTDIR

    CreateDirectory $INSTDIR\include
    CreateDirectory $INSTDIR\dist
    CreateDirectory $INSTDIR\cursors

    inetc::get \
        "${GitURL}README.md" "README.md"\
        "${GitURL}main.lua" "main.lua"\
        "${GitURL}cursors/pencil.cur" "cursors/pencil.cur"\
        "${GitURL}NESBuilder.py" "NESBuilder.py"\
        "${GitURL}icon.ico" "icon.ico"\
        "${GitURL}build.bat" "build.bat"\
        "${GitURL}build_console.bat" "build_console.bat"\
        "${GitURL}install dependencies.bat" "install dependencies.bat"\
        "${GitURL}run script and pause.bat" "run script and pause.bat"\
        "${GitURL}run script.bat" "run script.bat"\
        "${GitURL}include/__init__.py" "include/__init__.py"\
        "${GitURL}include/Tserial.lua" "include/Tserial.lua"\
        "${GitURL}include/util.lua" "include/util.lua"\
        "${GitURL}include/SMBLevelExtract.py" "include/SMBLevelExtract.py"\
        "${GitURL}chr.png" "chr.png"\
        /END
    Pop $0

SectionEnd

Section "Installer Source"
    SectionIn 1

    ; Set output path to the installation directory.
    SetOutPath $INSTDIR

    CreateDirectory $INSTDIR\installer

    inetc::get \
        "${GitURL}installer/nesbuilder.nsi" "installer/nesbuilder.nsi"\
        "${GitURL}installer/header.bmp" "installer/header.bmp"\
        "${GitURL}installer/header.xcf" "installer/header.xcf"\
        "${GitURL}installer/installicon.ico" "installer/installicon.ico"\
        /END
    Pop $0

SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"
        SectionIn 1
        CreateDirectory "$SMPROGRAMS\NESBuilder"
        CreateShortcut "$SMPROGRAMS\NESBuilder\Uninstall.lnk" "$INSTDIR\uninstall.exe"
        CreateShortcut "$SMPROGRAMS\NESBuilder\NESBuilder.lnk" "$INSTDIR\NESBuilder.exe"
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NESBuilder"
    DeleteRegKey HKLM SOFTWARE\NESBuilder

    ; Remove files and uninstaller
    Delete $INSTDIR\NESBuilder.exe
    Delete $INSTDIR\README.md
    Delete $INSTDIR\main.lua
    Delete $INSTDIR\cursors
    Delete $INSTDIR\NESBuilder.py
    Delete $INSTDIR\icon.ico
    Delete $INSTDIR\build.bat
    Delete $INSTDIR\build_console.bat
    Delete "$INSTDIR\install dependencies.bat"
    Delete "$INSTDIR\run script and pause.bat"
    Delete "$INSTDIR\run script.bat"
    Delete $INSTDIR\build.bat
    Delete $INSTDIR\include
    Delete $INSTDIR\chr.png

    RMDir /r /REBOOTOK $INSTDIR\__pycache__
    RMDir /r /REBOOTOK $INSTDIR\build
    RMDir /r /REBOOTOK $INSTDIR\cursors
    RMDir /r /REBOOTOK $INSTDIR\dist
    RMDir /r /REBOOTOK $INSTDIR\include
    RMDir /r /REBOOTOK $INSTDIR\installer
    RMDir /r /REBOOTOK $INSTDIR\tools
    Delete $INSTDIR\NESBuilder.exe.spec
    Delete $INSTDIR\uninstall.exe

    ; Settings and project files remain
    ;RMDir /r /REBOOTOK $INSTDIR\projects
    ;Delete $INSTDIR\settings.dat

    ; Remove shortcuts, if any
    Delete "$SMPROGRAMS\NESBuilder\*.lnk"

    ; Remove directories
    RMDir "$SMPROGRAMS\NESBuilder"
    RMDir "$INSTDIR"

SectionEnd
