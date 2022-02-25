; NSIS Installer script
;--------------------------------
!define MUI_BGCOLOR "1c8585"
!define MUI_INSTFILESPAGE_COLORS "FFFFFF 000000" ;Two colors
!define MUI_HEADER_TRANSPARENT_TEXT
!define MUI_TEXTCOLOR  "FFFF00"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_HEADERIMAGE_BITMAP_STRETCH AspectFitHeight

var err

!include "MUI2.nsh"
!include Sections.nsh

;!include LogicLib.nsh
RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)

; Download a file
!macro dl source
    !define UniqueID ${__LINE__}
    inetc::get "${GitURL}${source}" "${source}"
    Pop $0
    StrCmp $0 "OK" dlok2_${UniqueID}
    DetailPrint "*** Error: Could not download ${source}."
    strcpy $err "error"
    dlok2_${UniqueID}:
    !undef UniqueID
!macroend

; Download a file and give it a different name
!macro dlrename source dest
    !define UniqueID ${__LINE__}
    inetc::get "${GitURL}${source}" "${dest}"
    Pop $0
    StrCmp $0 "OK" dlok2_${UniqueID}
    DetailPrint "*** Error: Could not download ${source}."
    strcpy $err "error"
    dlok2_${UniqueID}:
    !undef UniqueID
!macroend

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
    CreateDirectory $INSTDIR\plugins\gfxGenerator
    CreateDirectory $INSTDIR\templates
    
    ; Set output path to the installation directory.
    SetOutPath $INSTDIR
    
    ; Download files
    !insertmacro dl "tools/asm6.exe"
    !insertmacro dl "tools/xkas-plus/xkas.exe"
    !insertmacro dl "plugins/samplePlugin.lua"
    !insertmacro dl "plugins/hello.py"
    !insertmacro dl "plugins/smbthing.lua"
    !insertmacro dl "plugins/SMBLevelExtract/SMBLevelExtract.bat"
    !insertmacro dl "plugins/SMBLevelExtract/SMBLevelExtract.py"
    !insertmacro dl "plugins/SMBLevelExtract/README.md"
    !insertmacro dl "plugins/gfxGenerator.lua"
    !insertmacro dl "plugins/gfxGenerator/brick.lua"
    !insertmacro dl "plugins/rominfo.lua"
    !insertmacro dl "plugins/hash.py"
    !insertmacro dl "plugins/debug.lua"
    !insertmacro dl "plugins/nesst.lua"
    !insertmacro dl "plugins/nesst.py"
    !insertmacro dl "plugins/ca65.lua"
    !insertmacro dl "plugins/ca65.py"
    !insertmacro dl "templates/codeTemplate.zip"
    !insertmacro dl "templates/codeTemplate3.zip"
    !insertmacro dl "templates/romhack_xkasplus1.zip"
    !insertmacro dl "templates/romhack_sdasm1.zip"
SectionEnd

;Section "test"
;    SectionIn 1
;    SetOutPath $INSTDIR
;    !insertmacro dl "README.md"
;    !insertmacro dl "blah"
;    !insertmacro dlrename "README.md" "blah.md"
;SectionEnd

; The stuff to install
Section "NESBuilder Executable"

    ;SectionIn RO
    SectionIn 1

    ; Set output path to the installation directory.
    SetOutPath $INSTDIR

    ; Put file there
    ;File "example2.nsi"

    ; Download files
    !insertmacro dl "README.md"
    !insertmacro dlrename "dist/NESBuilder.exe" "NESBuilder.exe"

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

    ; Download files
    !insertmacro dl "README.md"
    !insertmacro dl "main.lua"
    !insertmacro dl "NESBuilder.py"
    !insertmacro dl "makeVersion.py"
    !insertmacro dl "build.bat"
    !insertmacro dl "build_console.bat"
    !insertmacro dl "install dependencies.bat"
    !insertmacro dl "run script.bat"
    !insertmacro dl "findpython.bat"
    !insertmacro dl "include/__init__.py"
    !insertmacro dl "include/Tserial.lua"
    !insertmacro dl "include/util.lua"
    !insertmacro dl "include/QtDave.py"
    !insertmacro dl "include/style.qss"
    !insertmacro dl "include/config.py"
    !insertmacro dl "include/calc.py"
    !insertmacro dl "include/ips.py"
    !insertmacro dl "include/random.py"
    !insertmacro dl "include/noise.py"
    !insertmacro dl "chr.png"
    !insertmacro dl "icons/__init__.py"
    !insertmacro dl "icons/folder32.png"
    !insertmacro dl "icons/folderplus32.png"
    !insertmacro dl "icons/gear32.png"
    !insertmacro dl "icons/note32.png"
    !insertmacro dl "icons/clock32.png"
    !insertmacro dl "icons/project.png"
    !insertmacro dl "icons/icon.ico"
    !insertmacro dl "icons/close.png"
    !insertmacro dl "icons/close_hover.png"
    !insertmacro dl "cursors/__init__.py"
    !insertmacro dl "cursors/pencil.cur"
    !insertmacro dl "cursors/crosshair.cur"
    !insertmacro dl "cursors/LinkSelect.cur"
    !insertmacro dl "include/SpiderDaveAsm/__init__.py"
    !insertmacro dl "include/SpiderDaveAsm/sdasm.py"
    !insertmacro dl "include/SpiderDaveAsm/README.md"
    !insertmacro dl "include/SpiderDaveAsm/include/__init__.py"
    !insertmacro dl "include/SpiderDaveAsm/include/config.py"
    !insertmacro dl "include/SpiderDaveAsm/include/gg.py"
    !insertmacro dl "include/SpiderDaveAsm/include/ips.py"
    !insertmacro dl "include/SpiderDaveAsm/include/ld65cfg.py"

SectionEnd

Section "Installer Source"
    SectionIn 1

    ; Set output path to the installation directory.
    SetOutPath $INSTDIR

    CreateDirectory $INSTDIR\installer

    ; Download files
    !insertmacro dl "installer/nesbuilder.nsi"
    !insertmacro dl "installer/header.bmp"
    !insertmacro dl "installer/header.xcf"
    !insertmacro dl "installer/installicon.ico"
    !insertmacro dl "installer/updater.nsi"
    !insertmacro dlrename "installer/README.md" "installer/readme.txt"

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

Function .onInstSuccess
    StrCmp "${err}" "error" 0 noerror
    MessageBox MB_OK|MB_ICONINFORMATION 'Error: not all files were downloaded.!'
    goto skipdependencies
    noerror:
    IfFileExists "$INSTDIR\install dependencies.bat" 0 skipdependencies
    ExpandEnvStrings $0 %COMSPEC%
    ExecWait '"$0" /C "$INSTDIR\install dependencies.bat"'
    skipdependencies:
FunctionEnd

;Function .onInit
;UserInfo::GetAccountType
;pop $0
;${If} $0 != "admin" ;Require admin rights on NT4+
;    MessageBox mb_iconstop "Administrator rights required!"
;    SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
;    Quit
;${EndIf}
;FunctionEnd
