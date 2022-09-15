-- NESBuilder plugin
-- debug.lua
--
-- Plugins starting with "_" are disabled.

local plugin = {
    author = "SpiderDave",
    default = true,
}

function plugin.onInit()
    local items = {
        {name="restart", text="\u{1f503} Restart"},
        {name="forceClose", text="\u{274e} Force Close"},
        {name="openMainFolder", text="\u{1f4c2} Open Main Folder"},
        {name="openPluginFolder", text="\u{1f4c2} Open Plugins Folder"},
        {name="copySdasm", text="\u{1f4cb} Copy sdasm for standalone project"}
    }
    control = NESBuilder:makeMenuQt{name="debugMenu", text="Debug", menuItems=items, prefix=true}
end

function debugMenu_restart_cmd()
    NESBuilder:restart()
end

function debugMenu_forceClose_cmd()
    NESBuilder:forceClose()
end

function debugMenu_openMainFolder_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    NESBuilder:shellOpen(workingFolder, "")
end

debugMenu_openProjectFolder_cmd = OpenProjectFolder_cmd

function debugMenu_openPluginFolder_cmd()
    local workingFolder = data.folders.projects..data.project.folder
    NESBuilder:shellOpen(workingFolder, data.folders.plugins)
end

function debugMenu_copySdasm_cmd()
    -- Use a closure here to help with local function recursion
    local getModuleFiles = function(path)
        local function inner(path)
            local files = list()
            local l = pythonEval(string.format("[x.name for x in list(pkgutil.iter_modules(['%s']))]", path))
            if l then
                for item in python.iter(l) do
                    local p = replace(path, '/', '.')
                    pcall(function()
                        local n = pythonEval(string.format('pathlib.Path(%s.%s.__file__).resolve()', p, item))
                        listAppend(files, str(n))
                    end)
                    
                    files = joinList(files, inner(path.."/"..item))
                end
            end
            return files
        end
        
        return inner(path)
    end
    
    local l = getModuleFiles('include/SpiderDaveAsm')
    
    local folder = data.folders.projects..data.project.folder
    
    NESBuilder:setWorkingFolder()
    
    -- make sure folders exist
    NESBuilder:makeDir(folder)
    NESBuilder:makeDir(folder.."sdasm")
    
    -- Make all subfolders
    local baseFolders = pythonEval('set()')
    
    for file in python.iter(l) do
        local baseFolder = pythonEval("lambda x:x.split('SpiderDaveAsm', 1)[-1][1:]")(file)
        baseFolder = pathSplit(baseFolder)[0]
        if baseFolder ~= '' then
            baseFolders.add(baseFolder)
        end
    end
    
    --sdasmFolder = fixPath('include/SpiderDaveAsm')
    --print(sdasmFolder)
    
    for baseFolder in python.iter(baseFolders) do
        NESBuilder:makeDir(folder.."sdasm/"..baseFolder)
    end
    
    NESBuilder:sleep(1)
    
    for file in python.iter(l) do
        local base = pythonEval("lambda x:x.split('SpiderDaveAsm', 1)[-1]")(file)
        NESBuilder:copyFile(file, fixPath(folder.."sdasm"..base))
    end
    
    NESBuilder:copyFile(fixPath('findpython.bat'), fixPath(folder..'findpython.bat'))
    
    local baseRom = getRomFilename()
    local baseRomString = ""
    if baseRom then
        baseRomString = string.format('-bin "%s" ', baseRom)
    end
out = [[
@echo off
rem -- Settings ----------------------------

rem pause when done
rem (note: errors will always pause)
set dopause=0

set script=sdasm/sdasm.py _baseRomString_project.asm

rem ----------------------------------------

rem default error
set errormessage=unspecified error

rem run this to fill the pycmd environment variable
call findpython.bat 1
if %errorlevel% NEQ 0 goto error

%pycmd% %script%
if %errorlevel% NEQ 0 set errormessage=script error&goto error

goto success

:error
echo.
echo.ERROR: %errormessage%
echo.
pause
goto theend

:success
if %dopause% NEQ 0 pause

:theend
]]
    out = replace(out, '_baseRomString_', baseRomString)

    local f = folder.."build.bat"
    if NESBuilder:fileExists(f) then
        if NESBuilder:getTextFileContents(f) == out then
            -- file is identical
        else
            print('Warning: Not creating '..f..'.  File already exists with different contents.')
        end
    else
        util.writeToFile(f, 0, out, true)
        print(f..' written.')
    end
end

return plugin