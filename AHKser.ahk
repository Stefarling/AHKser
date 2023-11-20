#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
; TITLE AHKser Script Manager
; VERSION 1.0.2
; AUTHOR Stefarling
; DESCRIPTION Use to manage AHK scripts from central GUI.
; CATEGORY Utility

/*
HELPBEGIN
This is the AHKser Script Manager.
HELPEND
*/


; Hotkeys
F11::ListVars


; Program Variables
ProgramName             := "AHKser Script Manager"
ConfigFile              := "AHKserSettings.ini"


; Global Variables
FocusedScript           := ""


; Global Symbols
StatusRunning                 := "✓"
StatusStopped                 := "X"
StatusUnknown                 := "?"

; Custom Script Class
class Script {

    title               := "Unknown"
    version             := "Unknown"
    targetApp           := "Unknown"
    targetVersion       := "Unknown"
    targetResolution    := "Unknown"    
    author              := "Unknown"
    description         := "Unknown"
    mainCategory        := "Unknown"
    subCategory         := "Unknown"
    release             := "Experimental"
    status              := StatusStopped


}

; Program
Persistent
SetWorkingDir A_ScriptDir

TargetResolution        := IniRead(ConfigFile, "TargetAppSettings", "TargetAppResolution", "Any")
ShowUniversal           := IniRead(ConfigFile, "AHKserSettings", "ShowUniversal", true)
ShowFavorites           := IniRead(ConfigFile, "AHKserSettings", "ShowFavorites", true)
ShowExperimental        := IniRead(ConfigFile, "AHKserSettings", "ShowExperimental", false)
dirScripts           := IniRead(ConfigFile, "AHKserSettings", "ScriptsFolder", A_ScriptDir "\Scripts")
ResolutionsArray        := []
AppArray                := []
CategoriesArray         := []
SubCategoriesArray      := []
ScriptsArray            := []
AppFilter               := " "
CategoryFilter          := " "
SubCategoryFilter       := " "


; Settings - Tray
TraySetIcon A_ScriptDir "\assets\AHKser-icon.ico"
A_AllowMainWindow   := false
A_IconTip           := ProgramName
TrayMenu            := A_TrayMenu
TrayMenu.Delete()
TrayMenu.Add("Open", OpenGui)
TrayMenu.Add("Help", OpenHelp)
TrayMenu.Add()
TrayMenu.Add("Start Favourites", NoAction)
TrayMenu.Disable("Start Favourites")
TrayMenu.Add("Stop all scripts", NoAction)
TrayMenu.Disable("Stop all scripts")
TrayMenu.Add()
TrayMenu.Add("Exit AHKser", CloseAHKser)
TrayMenu.Default :="Open"


; Settings - BarMenu
FileMenu    := Menu()
FileMenu.Add "E&xit", CloseAHKser
Menus   := MenuBar()
Menus.Add "&File", FileMenu
Menus.Add "&Settings", (*) => OpenSettings()



; MainGui
MainGui                 := Gui("-Parent +Resize +MinSize455x150 +OwnDialogs")
MainGui.Title           := ProgramName
MainGui.MenuBar         := Menus


; Gui ListView
MainGui.Add("Text", "Section", "App:")
AppSelector         := MainGui.Add("ComboBox", "XP", AppArray)
MainGui.Add("Text","Section YS", "Category:")
CategorySelector  := MainGui.Add("ComboBox","XP",CategoriesArray)
MainGui.Add("Text","Section YS", "Sub-Category:")
SubCategorySelector := MainGui.Add("ComboBox","XP",SubCategoriesArray)
RefreshScriptsButton    := MainGui.Add("Button"," YP r1", "Refresh")

ListView := MainGui.Add("ListView", "Section XM -multi  r10 W450",[" ", "Script Name", "App", "Category", "Sub-Category"])

StatusBar               := MainGui.Add("StatusBar",,)



; MainGui OnEvents
ListView.OnEvent("ItemFocus", ScriptFocused)
ListView.OnEvent("DoubleClick", ToggleScriptStatus)
MainGui.OnEvent("Size", Gui_Size)
AppSelector.OnEvent("Change",FilterApps)
CategorySelector.OnEvent("Change",FilterCategory)
SubCategorySelector.OnEvent("Change",FilterSubCategory)
MainGui.OnEvent("Close",CloseAHKser)


; SettingsGui
SettingsGui := Gui("-Resize +ToolWindow +Owner" MainGui.Hwnd)
SettingsGui.Add("CheckBox", "vUniversalShow","Always show universal scripts.")
SettingsGui.Add("CheckBox", "vFavoriteShow","Always show favorite scripts.")
SettingsGui.Add("CheckBox", "vExperimentalShow","Show experimental scripts.")

SettingsGui.Add("Text", "XP YP+20","Resolution")
ResolutionSelector      := SettingsGui.Add("ComboBox", "XP+0 YP+15", ResolutionsArray)
ResolutionSelector.Text := TargetResolution

ScriptsFolderButton     := SettingsGui.Add("Button","Section r2 w60","Scripts`nFolder")
AppFolderButton         := SettingsGui.Add("Button","YS XP+65 r2 w60","App`nFolder")



SettingsGui.Add("Text","Section XS YS+60","Press Escape to close this window.")

; SettingsGui OnEvents
SettingsGui.OnEvent("Close", CloseSettings)
SettingsGui.OnEvent("Escape", CloseSettings)
ScriptsFolderButton.OnEvent("Click", OpenScriptsFolder)
AppFolderButton.OnEvent("Click", OpenAppFolder)

; Functions

FilterApps(obj, info){

    if(obj.Value > 0){
        global AppFilter := AppArray[obj.Value]
    }else{
        global AppFilter := " "
    }

    ListScripts



}

FilterCategory(obj, info){

    if(obj.Value > 0){
        global CategoryFilter := CategoriesArray[obj.Value]
    }else{
        global CategoryFilter := " "
    }
    ListScripts


}

FilterSubCategory(obj, info){

    if(obj.Value > 0){
        global SubCategoryFilter := SubCategoriesArray[obj.Value]
    }else{
        global SubCategoryFilter := " "
    }
    ListScripts


}

FilterResolution(obj, info){
    if ( obj.Value > 0){
        global TargetResolution := ResolutionsArray[obj.Value]
    }else{
        global TargetResolution := " "
    }
    ListScripts
}

OpenSettings(){
    MainGui.Opt("+Disabled")
    ResolutionSelector.Text := TargetResolution

    ; OnEvents    
    ResolutionSelector.OnEvent("Change", FilterResolution )


    SettingsGui.Show
}

CloseSettings(thisgui){
    MainGui.Opt("-Disabled")
    SettingsGui.Hide
    return true
}

NoAction(*){
    ; For when we don't want to do anything today
}

OpenGui(*){
    MainGui.Show()
}

OpenHelp(*){
    Run "https://github.com/Stefarling/AHKser/wiki"
}

ToggleScriptStatus(GuiCtrlObj, Info){
    global FocusedScript := ScriptsArray[Info].path

    if(ScriptsArray[Info].status = StatusStopped){
        StartScript()
    }else{
        StopScript()

    }

}

StartScript(*){
    
    if(FocusedScript = ""){
        ; Do nothing
    }else{
        Run FocusedScript
    }

}

StopScript(*){
    DetectHiddenWindows "On"
    DetectHiddenText "On"

        if(FocusedScript = ""){
            ; DO NOTHING
        }else{

            scriptie := RegExReplace(FocusedScript, "^.*\\")

            WinClose(scriptie)
            
        }

    DetectHiddenText "Off"
    DetectHiddenWindows "Off"
    
}

ScriptFocused(obj, item){
       global FocusedScript := ListView.GetText(item, 2)
}

AdjustColumns(){
    ListView.ModifyCol(1, "20")
    ListView.ModifyCol(2, "150")
    ListView.ModifyCol(3, "125")
    
}

OpenScriptsFolder(*){
    try {
        DirCreate("Scripts\Universal")
        Run "explore " A_WorkingDir "\Scripts"        
    }
}

OpenAppFolder(*){    
    try {
    Run "explore " A_WorkingDir       
    }

}

FindScripts(){
    Loop Files, dirScripts "\*ahk", "R"
        {
            fileText        := FileRead(A_LoopFileFullPath)
            cls             := Script.Call()

            Loop Parse fileText,";|`n",A_Space A_Tab{
                if(InStr(A_LoopField, "TITLE", "On")){
                    cls.title := RTrim(RegExReplace(A_LoopField, "TITLE "))
                }
                if(InStr(A_LoopField, "SCRIPTVERSION", "On")){
                    cls.version := RTrim(RegExReplace(A_LoopField, "SCRIPTVERSION "))
                }
                if(InStr(A_LoopField, "TARGETAPP", "On")){
                    cls.targetApp := RTrim(RegExReplace(A_LoopField, "TARGETAPP "))
                    UpdateApps(cls.targetApp)
                }
                if(InStr(A_LoopField, "TARGETVERSION", "On")){
                    cls.targetVersion := RTrim(RegExReplace(A_LoopField, "TARGETVERSION "))
                }
                if(InStr(A_LoopField, "TARGETRESOLUTION", "On")){
                    cls.targetResolution := RTrim(RegExReplace(A_LoopField, "TARGETRESOLUTION "))
                    UpdateResolutions(cls.targetResolution)
                }
                if(InStr(A_LoopField, "AUTHOR", "On")){
                    cls.author := RegExReplace(A_LoopField, "AUTHOR ")
                }
                if(InStr(A_LoopField, "DESCRIPTION", "On")){
                    cls.description := RTrim(RegExReplace(A_LoopField, "DESCRIPTION "))
                }
                if(InStr(A_LoopField, "MAINCATEGORY", "On")){
                    cls.mainCategory := RTrim(RegExReplace(A_LoopField, "MAINCATEGORY "))
                    UpdateCategories(cls.mainCategory)
                }
                if(InStr(A_LoopField, "SUBCATEGORY", "On")){
                    cls.subCategory := RTrim(RegExReplace(A_LoopField, "SUBCATEGORY "))
                    UpdateSubCategories(cls.subCategory)
                }
                if(InStr(A_LoopField, "RELEASE", "On")){
                    cls.release := RTrim(RegExReplace(A_LoopField, "RELEASE "))
                }
                cls.path := A_LoopFileFullPath
                cls.status := StatusStopped
            }

            ScriptsArray.Push(cls)
        }

}

UpdateApps(app){
    found := false

    for k, v in AppArray{
        if(app = v){
            found := true
        }
    }

    if(found){
        ; Do nothing
    }else{
        AppArray.Push(app)
        AppSelector.Delete()
        AppSelector.Add(AppArray)
    }

}

UpdateCategories(category){
    found := false

    for k, v in CategoriesArray{
        if(category = v){
            found := true
        }
    }

    if(found){
        ; Do nothing
    }else{
        CategoriesArray.Push(category)
        CategorySelector.Delete()
        CategorySelector.Add(CategoriesArray)
    }

}

UpdateSubCategories(category){
    found := false

    for k, v in SubCategoriesArray{
        if(category = v){
            found := true
        }
    }

    if(found){
        ; Do nothing
    }else{
        SubCategoriesArray.Push(category)
        SubCategorySelector.Delete()
        SubCategorySelector.Add(SubCategoriesArray)
    }

}

UpdateResolutions(resolution){
    found := false

    for k, v in ResolutionsArray{
        if(resolution = v or resolution = "Unknown"){
            found := true
        }
    }

    if(found){
        ; Do nothing
    }else{
        ResolutionsArray.Push(resolution)
        ResolutionSelector.Delete()
        ResolutionSelector.Add(ResolutionsArray)
    }
}

ListScripts(){

    ListView.Opt("-Redraw")
    ListView.Delete()

    for k, v in ScriptsArray{

            if((AppFilter = v.targetApp or AppFilter = " ") 
                and (CategoryFilter = v.mainCategory or CategoryFilter = " ") 
                and (SubCategoryFilter = v.subCategory  or SubCategoryFilter = " ")
                and (TargetResolution = v.targetResolution or v.targetResolution = "Any" or TargetResolution = "Any")
            ){
                    ListView.Add(,v.status, v.title, v.targetApp, v.mainCategory, v.subCategory)    
            }
    }


    AdjustColumns()

    ListView.Opt("+Redraw")    
}

UpdateScriptsStatus(){
    DetectHiddenWindows "On"
    scriptsRunning := 0
    ListView.Modify(0,, StatusStopped)

    scriptsList := WinGetList("ahk_class AutoHotkey")
    for k, v in  scriptsList{
        title := WinGetTitle(scriptsList[k])
        title := RegExReplace(title, " - AutoHotkey v[\.0-9]+$")
        
        for k, v in ScriptsArray{
            if(title = v.path){
                v.status := StatusRunning
                scriptsRunning++
            }
        }        
        
    }
    
    ListView.ModifyCol(1,, scriptsRunning)
    if(scriptsRunning>0){
        UpdateGuiStatus
    }
    DetectHiddenWindows "Off"
}

UpdateGuiStatus(){

    Loop ListView.GetCount(){
        ListView.Modify(A_Index,,ScriptsArray[A_Index].status)
    }

    ListView.ModifyCol()

}

UpdateStatus(){
    ListView.Opt("-Redraw")
    UpdateScriptsStatus()
    Sleep 1
    ListView.Opt("+Redraw")  
}

InitializeScript(){

    FindScripts
    ListScripts
    UpdateStatus

    ListView.ModifyCol(2, "Sort")


}

CloseAHKser(*){
    IniWrite(TargetResolution, ConfigFile, "TargetAppSettings", "TargetAppResolution")
    IniWrite(ShowUniversal, ConfigFile, "AHKserSettings", "ShowUniversal")
    IniWrite(ShowFavorites, ConfigFile, "AHKserSettings", "ShowFavorites")
    IniWrite(ShowExperimental, ConfigFile, "AHKserSettings", "ShowExperimental")
    IniWrite(ShowUniversal, ConfigFile, "AHKserSettings", "ShowUniversal")
    IniWrite(dirScripts, ConfigFile, "AHKserSettings", "ScriptsFolder")

    ExitApp 0
}

Gui_Size(thisGui, MinMax, Width, Height)  ; Expand/Shrink ListView in response to the user's resizing.
{
    if MinMax = -1  ; The window has been minimized. No action needed.
        return
    ; Otherwise, the window has been resized or maximized. Resize the ListView to match.
    ListView.Move(,, Width - 20, Height - 80)
}


; Button Events


; Run the script
MainGui.Show()
InitializeScript()
SetTimer(UpdateStatus, 500)