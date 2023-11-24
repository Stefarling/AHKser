#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
#ErrorStdOut

; Shenanigans in the RegEx required 4 version numbers.
CodeVersion := "1.0.3.0", company := "My Company"
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-Let U_company = %A_PriorLine~U)^(.+"){3}(.+)".*$~$2%
;@Ahk2Exe-SetMainIcon assets\appIcon.ico
;@Ahk2Exe-SetName AHKser
;@Ahk2Exe-SetVersion %U_version%
;@Ahk2Exe-SetFileVersion %U_version%
;@Ahk2Exe-Base ..\v2\AutoHotkey64.exe, compiled\
;@Ahk2Exe-ExeName %A_ScriptName~(\.ahk){1}%-V%U_version%
;@Ahk2Exe-PostExec

;@Ahk2Exe-IgnoreBegin
TraySetIcon(A_ScriptDir "\assets\appIcon.ico")
;@Ahk2Exe-IgnoreEnd




; #ANCHOR - Settings - Program 
Persistent
SetWorkingDir A_ScriptDir
OnExit SaveProgramState


; #ANCHOR Variables - Program
ProgramTitle            := "AHKser Script Manager"
ConfigFile              := "AHKserSettings.ini"
Debug                   := true
DebugLog                := "debug.log"
ShortTime               := "HH:mm:ss"


; #ANCHOR Settings - Program
TargetAppResolution     := IniRead(ConfigFile, "TargetAppSettings", RTrim("TargetAppResolution", "`r`n"), "Universal")
ScriptsFolder           := IniRead(ConfigFile, "AHKserSettings", RTrim("ScriptsFolder", "`r`n"), A_ScriptDir "\Scripts")
ShowFavorites           := IniRead(ConfigFile, "AHKserSettings", RTrim("ShowFavorites", "`r`n"), true)
ShowExperimental        := IniRead(ConfigFile, "AHKserSettings", RTrim("ShowExperimental", "`r`n"), false)

ScriptsArray            := []
ScriptsStarted          := []
AppsArray               := []
ResolutionsArray        := []
CategoriesArray         := []
SubCategoriesArray      := []
FavoriteScriptsArray    := []
ScriptsRunning          := 0
TargetAppFilter         := ""
TargetCategoryFilter    := ""
TargetSubCategoryFilter := ""


; #ANCHOR Settings - Tray
A_AllowMainWindow   := false
A_IconTip           := ProgramTitle
TMenu                  := A_TrayMenu
TMenu.Delete()
TMenu.Add("Open", OpenGui)
TMenu.Add("Open", OpenSettings)
TMenu.Add("Help", OpenHelp)
TMenu.Add()
TMenu.Add("Stop all scripts", StopAllScripts)
TMenu.Disable("Stop all scripts")
TMenu.Add()
TMenu.Add("Exit AHKser", StopAHKser)
TMenu.Default :="Open"

; #ANCHOR Settings - BarMenu
FMenu           := Menu()
FMenuScriptBtn  := FMenu.Add("&Start", StartScript)
FMenu.Disable("&Start")
FMenu.Add()
FMenu.Add("E&xit", StopAHKser)
BMenu           := MenuBar()
Bmenu.Add("&File", FMenu)
BMenu.Add("&Settings", OpenSettings)
BMenu.Add("&Help", OpenHelp)

; #ANCHOR - GUI - Main
MGui                 := Gui("-Parent +Resize +MinSize455x150 +OwnDialogs")
MGuiIsDirty          := true
MGui.Title           := ProgramTitle
MGui.MenuBar         := BMenu

MGui.Add("Text", "Section", "App:")
MGuiAppFltrBtn          := MGui.Add("ComboBox", "XP", AppsArray)
MGui.Add("Text","Section YS", "Category:")
MGuiCtgryFltrBtn     := MGui.Add("ComboBox","XP", CategoriesArray)
MGui.Add("Text","Section YS", "Sub-Category:")
MGuiSCtgryFltrBtn    := MGui.Add("ComboBox","XP", SubCategoriesArray)

LVColumns := [" ", "Script Name", "App", "Branch", "Resolution", "Category", "Sub-Category", "Path"]
LV := MGui.Add("ListView", "Section XM -multi  r10 W450", LVColumns)

StsBar               := MGui.Add("StatusBar",,)


; #ANCHOR - GUI - Main - OnEvent
LV.OnEvent("ItemFocus", SetFocus)
LV.OnEvent("DoubleClick", ToggleScriptStatus)
MGui.OnEvent("Size", GuiResize)
MGuiAppFltrBtn.OnEvent("Change", FilterApps)
MGuiCtgryFltrBtn.OnEvent("Change", FilterCategory)
MGuiSCtgryFltrBtn.OnEvent("Change", FilterSubCategory)
MGui.OnEvent("Close", StopAHKser)

; #ANCHOR - Gui - Settings
SGui := Gui("-Resize +ToolWindow +Owner" MGui.Hwnd)
FvritChkbox         := SGui.Add("CheckBox", "vFavoriteShow","Show favorite scripts.")
FvritChkbox.Visible := false
ExplChkbox          := SGui.Add("CheckBox", "vExperimentalShow","Show experimental scripts.")

SGui.Add("Text", "XP YP+20","Resolution")
SGuiResFltrBtn      := SGui.Add("ComboBox", "XP+0 YP+15", ResolutionsArray)
SGuiResFltrBtn.Text := TargetAppResolution

ScrDirBtn               := SGui.Add("Button","Section r2 w60","Scripts`nFolder")
AppDirBtn               := SGui.Add("Button","YS XP+65 r2 w60","App`nFolder")

SGui.Add("Text","Section XS YS+60","Press Escape to close this window.")

; #ANCHOR - Gui - Settings - OnEvents
SGui.OnEvent("Close", CloseSettings)
SGui.OnEvent("Escape", CloseSettings)
ScrDirBtn.OnEvent("Click", OpenScriptsFolder)
AppDirBtn.OnEvent("Click", OpenAppFolder)


; #ANCHOR - Symbols - Status
Running                 := "✓"
Stopped                 := "X"
Unknown                 := "?"


; #ANCHOR - Script Class
class Script{
    title               := unknown
    version             := unknown
    author              := unknown
    targetApp           := unknown
    targetVersion       := unknown
    targetResolution    := unknown
    description         := unknown
    mainCategory        := unknown
    subCategory         := unknown
    release             := unknown
    status              := unknown
    path                := unknown
    reference           := unknown
}


; #ANCHOR - Functions
OpenScriptsFolder(*){
    try {
        DirCreate("Scripts\Universal")
        Run "explore " ScriptsFolder
    }catch{
        MsgBox "Couldn't create " ScriptsFolder
    }
}

OpenAppFolder(*){

    try {
    Run "explore " A_WorkingDir
    }catch{
        MsgBox "Couldn't open " A_WorkingDir
    }

}

FilterApps(ctrl, *){    
    if(ctrl.Value > 0){
        global TargetAppFilter := AppsArray[ctrl.Value]
    }else{
        global TargetAppFilter := ""
    } 

    global MGuiIsDirty := true
    UpdateGui
}

FilterCategory(ctrl, *){    
    if(ctrl.Value > 0){
        global TargetCategoryFilter := CategoriesArray[ctrl.Value]
    }else{
        global TargetCategoryFilter := ""
    } 

    global MGuiIsDirty := true
    UpdateGui
}

FilterSubCategory(ctrl, *){    
    if(ctrl.Value > 0){
        global TargetSubCategoryFilter := SubCategoriesArray[ctrl.Value]
    }else{
        global TargetSubCategoryFilter := ""
    } 

    global MGuiIsDirty := true
    UpdateGui
}

FilterResolution(obj, info, resolution := TargetAppResolution){
    if(obj != ""){
            if ( obj.Value > 0){
                global TargetAppResolution := ResolutionsArray[obj.Value]
            }else{
                global TargetAppResolution := ""
            }
        }

        global MGuiIsDirty := true
        UpdateGui
}

GuiResize(thisGui, MinMax, Width, Height)  ; Expand/Shrink ListView in response to the user's resizing.
{
    if MinMax = -1  ; The window has been minimized. No action needed.
        return
    ; Otherwise, the window has been resized or maximized. Resize the ListView to match.
    LV.Move(,, Width - 20, Height - 80)
}

ToggleScriptStatus(ctrl, index){

    if (index > 0) {

            if (ScriptsArray[index].status != Running) {
                
                ; Run it
                Run(ScriptsArray[index].path)

                ; Update the script status and refresh the GUI
                ScriptsArray[index].status := Running
                global MGuiIsDirty := true
            }else{
                DetectHiddenWindows "On"
                DetectHiddenText "On"
                ; Stop it
                WinClose(ScriptsArray[index].path)
                
                DetectHiddenText "Off"
                DetectHiddenWindows "Off"

                ; Update the script status and refresh the GUI
                ScriptsArray[index].status := Stopped
                global MGuiIsDirty := true
            }
    }
}

SetFocus(*){

}


StartScript(*){         ; Saves current program state to drive

}


StopAllScripts(*){      ; Saves current program state to drive

}

OpenHelp(*){            ; Saves current program state to drive
    try{
    Run "https://github.com/Stefarling/AHKser/wiki"
    }catch{
        MsgBox "Couldn't open https://github.com/Stefarling/AHKser/wiki"
    }
}

OpenGui(*){             ; Saves current program state to drive
    MGui.Show()
}

OpenSettings(*){        ; Saves current program state to drive
    MGui.Opt("+Disabled")
    SGuiResFltrBtn.Text := TargetAppResolution
    ExplChkbox.value    := ShowExperimental

    SGuiResFltrBtn.OnEvent("Change", FilterResolution )
    ExplChkbox.OnEvent("Click", UpdateShowExperimental)
    FvritChkbox.OnEvent("Click", UpdateShowFavorites)

    SGui.Show
}

CloseSettings(thisgui){
    MGui.Opt("-Disabled")
    SGui.Hide
    SaveProgramState
    return true
}

UpdateShowExperimental(ctrl, *){
    global ShowExperimental := ctrl.Value

    global MGuiIsDirty := true
    UpdateGui
}

UpdateShowFavorites(ctrl, *){
    global ShowFavorites := ctrl.Value

    global MGuiIsDirty := true
    UpdateGui
}

UpdateStatus(*) {
    DetectHiddenWindows "On"
    DetectHiddenText "On"

    for k, v in ScriptsArray{ ; Iterate known scripts
        this_script := ScriptsArray[k]
        if(this_script.status = Running ){ ; If a script is supposed to be running
            found := false

            scriptsList := WinGetList("ahk_class AutoHotkey")
            for k2, v2 in  scriptsList{
                title := WinGetTitle(scriptsList[k2])
                title := RegExReplace(title, " - AutoHotkey v[\.0-9]+$")

                if(title = this_script.path){
                    found := true
                    break
                }
            }
            
            if(found = true){
                break
            }else{
                ScriptsArray[k].status := Stopped
                global MGuiIsDirty := true
                break
            }
        }
        if(this_script.status != Running){
            found := false

            scriptsList := WinGetList("ahk_class AutoHotkey")
            for k3, v3 in  scriptsList{
                title := WinGetTitle(scriptsList[k3])
                title := RegExReplace(title, " - AutoHotkey v[\.0-9]+$")

                if(title = this_script.path){
                    found := true
                    break
                }
            }
            
            if(found = true){
                ScriptsArray[k].status := Running
                global MGuiIsDirty := true
                break
            }else{
                ScriptsArray[k].status := Stopped
            }
        }
    }
        UpdateGui
        DetectHiddenText "Off"
        DetectHiddenWindows "Off"
}

UpdateGui(*){
    if(MGuiIsDirty = true){
        LV.Opt("-Redraw")
        LV.ModifyCol(1,, ScriptsRunning)

        ListScripts

        Sleep 1
        LV.Opt("+Redraw")
        global MGuiIsDirty := false
    }

}

FindScripts(){

    Loop Files, ScriptsFolder "\*ahk", "R"
        {
            fileText        := FileRead(A_LoopFileFullPath)
            cls             := Script.Call()

            Loop Parse fileText,";|`n",A_Space A_Tab{
                if(InStr(A_LoopField, "TITLE", "On")){
                    cls.title := RTrim(RegExReplace(A_LoopField, "TITLE "), "`r`n")
                }
                if(InStr(A_LoopField, "SCRIPTVERSION", "On")){
                    cls.version := RTrim(RegExReplace(A_LoopField, "SCRIPTVERSION "), "`r`n")
                }
                if(InStr(A_LoopField, "TARGETAPP", "On")){
                    cls.targetApp := RTrim(RegExReplace(A_LoopField, "TARGETAPP "), "`r`n")
                    UpdateApps(cls.targetApp)
                }
                if(InStr(A_LoopField, "TARGETVERSION", "On")){
                    cls.targetVersion := RTrim(RegExReplace(A_LoopField, "TARGETVERSION "), "`r`n")
                }
                if(InStr(A_LoopField, "TARGETRESOLUTION", "On")){
                    cls.targetResolution := RTrim(RegExReplace(A_LoopField, "TARGETRESOLUTION "), "`r`n")
                    UpdateResolutions(cls.targetResolution)
                }
                if(InStr(A_LoopField, "AUTHOR", "On")){
                    cls.author := RTrim(RegExReplace(A_LoopField, "AUTHOR "), "`r`n")
                }
                if(InStr(A_LoopField, "DESCRIPTION", "On")){
                    cls.description := RTrim(RegExReplace(A_LoopField, "DESCRIPTION "), "`r`n")
                }
                if(InStr(A_LoopField, "MAINCATEGORY", "On")){
                    cls.mainCategory := RTrim(RegExReplace(A_LoopField, "MAINCATEGORY "), "`r`n")
                    UpdateCategories(cls.mainCategory)
                }
                if(InStr(A_LoopField, "SUBCATEGORY", "On")){
                    cls.subCategory := RTrim(RegExReplace(A_LoopField, "SUBCATEGORY "), "`r`n")
                    UpdateSubCategories(cls.subCategory)
                }
                if(InStr(A_LoopField, "RELEASE", "On")){
                    cls.release := RTrim(RegExReplace(A_LoopField, "RELEASE "), "`r`n")
                }
                cls.path := A_LoopFileFullPath
                cls.status := Unknown
                cls.reference := &cls
            }
            ScriptsArray.Push(cls)
        }
}

UpdateApps(app){
    
    found := false
    
    for k, v in AppsArray{
        if(app = v){
            found := true
        }
    }
    
    if(!found){
        AppsArray.Push(app)
        MGuiAppFltrBtn.Delete()
        MGuiAppFltrBtn.Add(AppsArray)
    }
}

UpdateCategories(category){

    found := false

    for k, v in CategoriesArray{
        if(category = v){
            found := true
        }
    }

    if(!found){
        CategoriesArray.Push(category)
        MGuiCtgryFltrBtn.Delete()
        MGuiCtgryFltrBtn.Add(CategoriesArray)
    }
}

UpdateSubCategories(category){
    found := false

    for k, v in SubCategoriesArray{
        if(category = v){
            found := true
        }
    }

    if(!found){
        SubCategoriesArray.Push(category)
        MGuiSCtgryFltrBtn.Delete()
        MGuiSCtgryFltrBtn.Add(SubCategoriesArray)
    }

}

UpdateResolutions(resolution){
    found := false

    for k, v in ResolutionsArray{
        if(resolution = v or resolution = "Unknown"){
            found := true
        }
    }

    if(!found){
        ResolutionsArray.Push(resolution)
        SGuiResFltrBtn.Delete()
        SGuiResFltrBtn.Add(ResolutionsArray)
    }

}

ListScripts(){
    LV.Delete()

    Loop ScriptsArray.Length{
        loopScript := ScriptsArray[A_Index]

        if(TargetAppFilter = loopScript.targetApp or TargetAppFilter = ""){

            if(TargetCategoryFilter = loopScript.mainCategory 
                or TargetCategoryFilter = ""){
                
                if(TargetSubCategoryFilter = loopScript.subCategory 
                    or TargetSubCategoryFilter = ""){
                    
                    if(TargetAppResolution = loopScript.targetResolution
                        or TargetAppResolution = "" 
                        or loopScript.targetResolution = "Universal"){

                        if(loopScript.release = "Stable"){
                            
                                
                            LV.Add(,
                                loopScript.status, 
                                loopScript.title, 
                                loopScript.targetApp, 
                                loopScript.release, 
                                loopScript.targetResolution, 
                                loopScript.mainCategory, 
                                loopScript.subCategory,
                                loopScript.path
                            )    


                        }else{
                             if(ShowExperimental){

                                LV.Add(,
                                    loopScript.status, 
                                    loopScript.title, 
                                    loopScript.targetApp, 
                                    loopScript.release, 
                                    loopScript.targetResolution, 
                                    loopScript.mainCategory, 
                                    loopScript.subCategory,
                                    loopScript.path
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    LV.ModifyCol()
}

InitializeAHKser(){

    FindScripts
    UpdateStatus
    FilterResolution("","",TargetAppResolution)
    LV.ModifyCol(2, "Sort")
}

SaveProgramState(*){    ; Saves current program state to drive
    IniWrite(RTrim(TargetAppResolution,"`r`n"), ConfigFile, "TargetAppSettings", "TargetAppResolution")
    IniWrite(RTrim(ShowFavorites,"`r`n"), ConfigFile, "AHKserSettings", "ShowFavorites")
    IniWrite(RTrim(ShowExperimental,"`r`n"), ConfigFile, "AHKserSettings", "ShowExperimental")
    IniWrite(RTrim(ScriptsFolder,"`r`n"), ConfigFile, "AHKserSettings", "ScriptsFolder")

}

StopAHKser(*){
        SaveProgramState
        ExitApp(0)
}

InitializeAHKser
OpenGui
SetTimer(UpdateStatus, 500)