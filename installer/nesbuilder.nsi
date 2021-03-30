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
OutFile "NESBuilder_Install.exe"

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

!include StrFunc.nsh
${StrRep}

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

    ; make sure the install folder exists
    CreateDirectory $INSTDIR

    CreateDirectory $INSTDIR\tools
    CreateDirectory $INSTDIR\tools\xkas-plus
    CreateDirectory $INSTDIR\plugins
    CreateDirectory $INSTDIR\plugins\SMBLevelExtract
    CreateDirectory $INSTDIR\templates
    
    ; Set output path to the installation directory.
    SetOutPath $INSTDIR
    
    inetc::get \
        "${GitURL}tools/asm6.exe" "tools/asm6.exe"\
        "${GitURL}tools/xkas-plus/xkas.exe" "tools/xkas-plus/xkas.exe"\
        "${GitURL}plugins/samplePlugin.lua" "plugins/samplePlugin.lua"\
        "${GitURL}plugins/hello.py" "plugins/hello.py"\
        "${GitURL}plugins/smbthing.lua" "plugins/smbthing.lua"\
        "${GitURL}plugins/SMBLevelExtract/SMBLevelExtract.bat" "plugins/SMBLevelExtract/SMBLevelExtract.bat"\
        "${GitURL}plugins/SMBLevelExtract/SMBLevelExtract.py" "plugins/SMBLevelExtract/SMBLevelExtract.py"\
        "${GitURL}plugins/SMBLevelExtract/README.md" "plugins/SMBLevelExtract/README.md"\
        "${GitURL}plugins/rominfo.lua" "plugins/rominfo.lua"\
        "${GitURL}plugins/hash.py" "plugins/hash.py"\
        "${GitURL}plugins/debug.lua" "plugins/debug.lua"\
        "${GitURL}plugins/nesst.lua" "plugins/nesst.lua"\
        "${GitURL}plugins/nesst.py" "plugins/nesst.py"\
        "${GitURL}templates/codeTemplate.zip" "templates/codeTemplate.zip"\
        "${GitURL}templates/codeTemplate3.zip" "templates/codeTemplate3.zip"\
        "${GitURL}templates/romhack_xkasplus1.zip" "templates/romhack_xkasplus1.zip"\
        "${GitURL}templates/romhack_sdasm1.zip" "templates/romhack_sdasm1.zip"\
        /END
    Call checkDl
SectionEnd

; The stuff to install
Section "NESBuilder Executable"

    ;SectionIn RO
    SectionIn 1

    ; Set output path to the installation directory.
    SetOutPath $INSTDIR

    ; Put file there
    ;File "example2.nsi"

    inetc::get \
        "${GitURL}README.md" "README.md"\
        "${GitURL}dist/NESBuilder.exe" "NESBuilder.exe"\
        /END
    Call checkDl

SectionEnd

Section "NESBuilder Source"
    #SectionIn RO
    SectionIn 1

    ; Set output path to the installation directory.
    SetOutPath $INSTDIR

    CreateDirectory $INSTDIR\include
    CreateDirectory $INSTDIR\dist
    CreateDirectory $INSTDIR\cursors
    CreateDirectory $INSTDIR\icons
    CreateDirectory $INSTDIR\include\SpiderDaveAsm
    CreateDirectory $INSTDIR\include\SpiderDaveAsm\include

    inetc::get \
        "${GitURL}README.md" "README.md"\
        "${GitURL}main.lua" "main.lua"\
        "${GitURL}NESBuilder.py" "NESBuilder.py"\
        "${GitURL}makeVersion.py" "makeVersion.py"\
        "${GitURL}build.bat" "build.bat"\
        "${GitURL}build_console.bat" "build_console.bat"\
        "${GitURL}install dependencies.bat" "install dependencies.bat"\
        "${GitURL}run script.bat" "run script.bat"\
        "${GitURL}findpython.bat" "findpython.bat"\
        "${GitURL}include/__init__.py" "include/__init__.py"\
        "${GitURL}include/Tserial.lua" "include/Tserial.lua"\
        "${GitURL}include/util.lua" "include/util.lua"\
        "${GitURL}include/SMBLevelExtract.py" "include/SMBLevelExtract.py"\
        "${GitURL}include/QtDave.py" "include/QtDave.py"\
        "${GitURL}include/style.qss" "include/style.qss"\
        "${GitURL}include/config.py" "include/config.py"\
        "${GitURL}include/calc.py" "include/calc.py"\
        "${GitURL}include/ips.py" "include/ips.py"\
        "${GitURL}chr.png" "chr.png"\
        "${GitURL}icons/__init__.py" "icons/__init__.py"\
        "${GitURL}icons/folder32.png" "icons/folder32.png"\
        "${GitURL}icons/folderplus32.png" "icons/folderplus32.png"\
        "${GitURL}icons/gear32.png" "icons/gear32.png"\
        "${GitURL}icons/note32.png" "icons/note32.png"\
        "${GitURL}icons/clock32.png" "icons/clock32.png"\
        "${GitURL}icons/project.png" "icons/project.png"\
        "${GitURL}icons/icon.ico" "icons/icon.ico"\
        "${GitURL}cursors/__init__.py" "cursors/__init__.py"\
        "${GitURL}cursors/pencil.cur" "cursors/pencil.cur"\
        "${GitURL}cursors/LinkSelect.cur" "cursors/LinkSelect.cur"\
        "${GitURL}include/SpiderDaveAsm/__init__.py" "include/SpiderDaveAsm/__init__.py"\
        "${GitURL}include/SpiderDaveAsm/sdasm.py" "include/SpiderDaveAsm/sdasm.py"\
        "${GitURL}include/SpiderDaveAsm/README.md" "include/SpiderDaveAsm/README.md"\
        "${GitURL}include/SpiderDaveAsm/include/__init__.py" "include/SpiderDaveAsm/include/__init__.py"\
        "${GitURL}include/SpiderDaveAsm/include/config.py" "include/SpiderDaveAsm/include/config.py"\
        "${GitURL}include/SpiderDaveAsm/include/gg.py" "include/SpiderDaveAsm/include/gg.py"\
        "${GitURL}include/SpiderDaveAsm/include/ips.py" "include/SpiderDaveAsm/include/ips.py"\
        /END
    Call checkDl

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
        "${GitURL}installer/updater.nsi" "installer/updater.nsi"\
        "${GitURL}installer/README.md" "installer/readme.txt"\
        /END
    Call checkDl

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
    Delete $INSTDIR\makeVersion.py
    Delete $INSTDIR\build.bat
    Delete $INSTDIR\build_console.bat
    Delete "$INSTDIR\install dependencies.bat"
    Delete $INSTDIR\findpython.bat
    Delete "$INSTDIR\run script.bat"
    Delete $INSTDIR\build.bat
    Delete $INSTDIR\include
    Delete $INSTDIR\chr.png

    RMDir /r /REBOOTOK $INSTDIR\__pycache__
    RMDir /r /REBOOTOK $INSTDIR\build
    RMDir /r /REBOOTOK $INSTDIR\cursors
    RMDir /r /REBOOTOK $INSTDIR\icons
    RMDir /r /REBOOTOK $INSTDIR\dist
    RMDir /r /REBOOTOK $INSTDIR\include
    RMDir /r /REBOOTOK $INSTDIR\installer
    RMDir /r /REBOOTOK $INSTDIR\tools
    RMDir /r /REBOOTOK $INSTDIR\plugins
    RMDir /r /REBOOTOK $INSTDIR\templates
    Delete $INSTDIR\NESBuilder.exe.spec
    Delete $INSTDIR\uninstall.exe

    ; Remove shortcuts, if any
    Delete "$SMPROGRAMS\NESBuilder\*.lnk"

    ; Remove directories
    RMDir "$SMPROGRAMS\NESBuilder"
    RMDir "$INSTDIR"

SectionEnd

;Function .onInit
;    SetOutPath $TEMP
    
;    inetc::get \
;        "${GitURL}filelist.txt" "filelist.txt"\
;        /END
;    Pop $0
;FunctionEnd

; Make sure all files downloaded
Function checkDl
    Pop $0
    StrCmp $0 "OK" dlok
    DetailPrint "*** Error: Not all files were downloaded."
    dlok:
FunctionEnd

