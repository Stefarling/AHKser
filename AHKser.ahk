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


; Program Variables
ProgramName             := "AHKser Script Manager"
ConfigFile              := "AHKserSettings.ini"
Debug                   := true
DebugLog                := "debug.log"
ShortTime               := "HH:mm:ss"




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

OnExit Shutdown

if(Debug){

FileAppend(FormatTime(,ShortTime) " ____________________________________________________________________`n", DebugLog)
FileAppend(FormatTime(,ShortTime) " |``- Starting AHKser.`n", DebugLog)
}

TargetAppResolution     := IniRead(ConfigFile, "TargetAppSettings", RTrim("TargetAppResolution", "`r`n"), "Universal")
ShowFavorites           := IniRead(ConfigFile, "AHKserSettings", RTrim("ShowFavorites", "`r`n"), true)
ShowExperimental        := IniRead(ConfigFile, "AHKserSettings", RTrim("ShowExperimental", "`r`n"), false)
dirScripts              := IniRead(ConfigFile, "AHKserSettings", RTrim("ScriptsFolder", "`r`n"), A_ScriptDir "\Scripts")
ResolutionsArray        := []
AppArray                := []
CategoriesArray         := []
SubCategoriesArray      := []
ScriptsArray            := []
FavortieScripts         := []
AppFilter               := ""
CategoryFilter          := ""
SubCategoryFilter       := ""


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
TrayMenu.Add("Exit AHKser", StopAHKser)
TrayMenu.Default :="Open"


; Settings - BarMenu
FileMenu    := Menu()
FileMenu.Add("E&xit", StopAHKser)
Menus   := MenuBar()
Menus.Add("&File", FileMenu)
Menus.Add("&Settings", OpenSettings)
Menus.Add("&Help", OpenHelp)



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

ListView := MainGui.Add("ListView", "Section XM -multi  r10 W450",[" ", "Script Name", "App", "Branch", "Resolution", "Category", "Sub-Category"])

StatusBar               := MainGui.Add("StatusBar",,)



; MainGui OnEvents
ListView.OnEvent("ItemFocus", NoAction)
ListView.OnEvent("DoubleClick", ToggleScriptStatus)
MainGui.OnEvent("Size", Gui_Size)
AppSelector.OnEvent("Change",FilterApps)
CategorySelector.OnEvent("Change",FilterCategory)
SubCategorySelector.OnEvent("Change",FilterSubCategory)
MainGui.OnEvent("Close", StopAHKser)


; SettingsGui
SettingsGui := Gui("-Resize +ToolWindow +Owner" MainGui.Hwnd)
ShowFavoritesCheckbox       := SettingsGui.Add("CheckBox", "vFavoriteShow","Show favorite scripts.")
ShowFavoritesCheckbox.Visible := false
ShowExperimentalCheckbox    := SettingsGui.Add("CheckBox", "vExperimentalShow","Show experimental scripts.")

SettingsGui.Add("Text", "XP YP+20","Resolution")
ResolutionSelector      := SettingsGui.Add("ComboBox", "XP+0 YP+15", ResolutionsArray)
ResolutionSelector.Text := TargetAppResolution

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

    debugString := FormatTime(,ShortTime) " |- Filtering Apps: " 
    
    if(obj.Value > 0){
        global AppFilter := AppArray[obj.Value]
        debugString .= "AppFilter is now " AppFilter "`n"
    }else{
        global AppFilter := ""
        debugString .= "AppFilter is now " AppFilter "`n"

    } 
    
        if(Debug){
            FileAppend(debugString, DebugLog)
        }
    
    ListScripts
}

FilterCategory(obj, info){

    debugString := FormatTime(,ShortTime) " |- Filtering Category: " 

    if(obj.Value > 0){
        global CategoryFilter := CategoriesArray[obj.Value]
        debugString .= "CategoryFilter is now " CategoryFilter "`n"
        
    }else{
        global CategoryFilter := ""
        debugString .= "CategoryFilter is now " CategoryFilter "`n"
    }

    if(Debug){
        FileAppend(debugString, DebugLog)
    }

    ListScripts


}

FilterSubCategory(obj, info){
    
    debugString := FormatTime(,ShortTime) " |- Filtering Sub-Category: " 

    if(obj.Value > 0){
        global SubCategoryFilter := SubCategoriesArray[obj.Value]
        debugString .= "SubCategoryFilter is now " SubCategoryFilter "`n"
    }else{
        global SubCategoryFilter := ""
        debugString .= "SubCategoryFilter is now " SubCategoryFilter "`n"
    }

    if(Debug){
        FileAppend(debugString, DebugLog)
    }
    ListScripts


}

FilterResolution(obj, info, resolution := TargetAppResolution){

    debugString := FormatTime(,ShortTime) " |- Filtering Resolutions: " 
    
    if(obj = ""){
        debugString .= FormatTime(,ShortTime) " |- Param was blank. Defaulting."        

    }else{
        try{
            
            if ( obj.Value > 0){
                global TargetAppResolution := ResolutionsArray[obj.Value]
                debugString .= "ResolutionFilter is now " TargetAppResolution "`n"
            }else{
                global TargetAppResolution := ""
                debugString .= "ResolutionFilter is now " TargetAppResolution "`n"
            }
            }
        }
            if(Debug){
                FileAppend(debugString, DebugLog)
            }
    
    ListScripts
}

OpenSettings(*){
    debugString := FormatTime(,ShortTime) " |- Opening Settings GUI.`n" 
    MainGui.Opt("+Disabled")
    ResolutionSelector.Text := TargetAppResolution
    ShowExperimentalCheckbox.value := ShowExperimental

    ; OnEvents    
    ResolutionSelector.OnEvent("Change", FilterResolution )
    ShowExperimentalCheckbox.OnEvent("Click", UpdateShowExperimental)
    ShowFavoritesCheckbox.OnEvent("Click", UpdateShowFavorites)


    SettingsGui.Show

    if(Debug){
        FileAppend(debugString, DebugLog)
    }
}

UpdateShowExperimental(obj, info){
    global ShowExperimental := obj.Value
    debugString := FormatTime(,ShortTime) " |- Toggling ShowExperimental to " ShowExperimental ".`n" 
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
    
    ListScripts

}

UpdateShowFavorites(obj, info){
    global ShowFavorites := obj.Value
    debugString := FormatTime(,ShortTime) " |- Toggling ShowFavorites to " ShowFavorites ".`n" 
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
    
    ListScripts

}

CloseSettings(thisgui){
    debugString := FormatTime(,ShortTime) " |``- Closing Settings GUI.`n" 
    MainGui.Opt("-Disabled")
    SettingsGui.Hide
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
    return true
}

NoAction(*){
    ; For when we don't want to do anything today
    debugString := FormatTime(,ShortTime) " |- Not implemented yet.`n" 
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
}

OpenGui(*){
    debugString := FormatTime(,ShortTime) " ,- Opening main GUI.`n" 
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
    MainGui.Show()
}

OpenHelp(*){
    debugString := FormatTime(,ShortTime) " |- Opening help URL.`n" 
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
    Run "https://github.com/Stefarling/AHKser/wiki"
}

ToggleScriptStatus(obj, index){
    debugString := FormatTime(,ShortTime) " |- Toggling script status: `n" 
    try{
        row := ScriptsArray[index]
        
        if(row.status = StatusStopped){
            debugString .= "Attempting to run " row.path ".`n"            
            if(Debug){
                FileAppend(debugString, DebugLog)
            }
            StartScript(row)
        }else{
            debugString .= "Attempting to stop " row.path ".`n"
            
            if(Debug){
                FileAppend(debugString, DebugLog)
            }
            StopScript(row)        
        }
        
    }
}

StartScript(row){
    debugString := FormatTime(,ShortTime) " |- ..." 
    
    if(row.path = ""){
        debugString .= "Failed, no script specified.`n" 
        ; Do nothing
    }else{
        Run row.path
        row.status := StatusRunning
        debugString .= "Success!`n"
    }
        
    if(Debug){
        FileAppend(debugString, DebugLog)
    }

}

StopScript(row){
    debugString := FormatTime(,ShortTime) " |- ..." 
    DetectHiddenWindows "On"
    DetectHiddenText "On"

        if(row.path = ""){
            debugString .= "Failed, no script specified.`n" 
            ; DO NOTHING
        }else{
            WinClose(RegExReplace(row.path,"^.*\\"))
            row.status := StatusStopped
            debugString .= "Success!`n"
        }
           
                
    if(Debug){
        FileAppend(debugString, DebugLog)
    }

    DetectHiddenText "Off"
    DetectHiddenWindows "Off"
    
}


AdjustColumns(){
    
    ListView.ModifyCol()
    
}

OpenScriptsFolder(*){
    debugString := FormatTime(,ShortTime) " |- Opening Scripts folder..." 
    try {
        DirCreate("Scripts\Universal")
        Run "explore " A_WorkingDir "\Scripts"     
        debugString .= " Success!`n"   
    }
               
                
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
}

OpenAppFolder(*){    
    debugString := FormatTime(,ShortTime) " |- Opening App folder..." 

    try {
    Run "explore " A_WorkingDir         
        debugString .= " Success!`n"      
    }       
    if(Debug){
        FileAppend(debugString, DebugLog)
    }

}

FindScripts(){
    
    debugString := FormatTime(,ShortTime) " |``- Finding scripts...`n"     
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
    debugString := ""

    Loop Files, dirScripts "\*ahk", "R"
        {
            debugString .= FormatTime(,ShortTime) " |`n"  
            debugString .= FormatTime(,ShortTime) " |- Examining " A_LoopFileFullPath ".`n"  

            fileText        := FileRead(A_LoopFileFullPath)
            cls             := Script.Call()

            Loop Parse fileText,";|`n",A_Space A_Tab{
                if(InStr(A_LoopField, "TITLE", "On")){
                    cls.title := RTrim(RegExReplace(A_LoopField, "TITLE "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: Title: " cls.title "`n"  
                }
                if(InStr(A_LoopField, "SCRIPTVERSION", "On")){
                    cls.version := RTrim(RegExReplace(A_LoopField, "SCRIPTVERSION "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: Version " cls.version "`n"  
                }
                if(InStr(A_LoopField, "TARGETAPP", "On")){
                    cls.targetApp := RTrim(RegExReplace(A_LoopField, "TARGETAPP "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: Target: " cls.targetApp "`n"  
                    UpdateApps(cls.targetApp)
                }
                if(InStr(A_LoopField, "TARGETVERSION", "On")){
                    cls.targetVersion := RTrim(RegExReplace(A_LoopField, "TARGETVERSION "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: TargVersion: " cls.targetVersion "`n"  
                }
                if(InStr(A_LoopField, "TARGETRESOLUTION", "On")){
                    cls.targetResolution := RTrim(RegExReplace(A_LoopField, "TARGETRESOLUTION "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: TargResolution: " cls.targetResolution "`n"  
                    UpdateResolutions(cls.targetResolution)
                }
                if(InStr(A_LoopField, "AUTHOR", "On")){
                    cls.author := RTrim(RegExReplace(A_LoopField, "AUTHOR "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: Author: " cls.author "`n"  
                }
                if(InStr(A_LoopField, "DESCRIPTION", "On")){
                    cls.description := RTrim(RegExReplace(A_LoopField, "DESCRIPTION "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: Description: " cls.description "`n"  
                }
                if(InStr(A_LoopField, "MAINCATEGORY", "On")){
                    cls.mainCategory := RTrim(RegExReplace(A_LoopField, "MAINCATEGORY "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: Category: " cls.mainCategory "`n"  
                    UpdateCategories(cls.mainCategory)
                }
                if(InStr(A_LoopField, "SUBCATEGORY", "On")){
                    cls.subCategory := RTrim(RegExReplace(A_LoopField, "SUBCATEGORY "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: SubCategory: " cls.subCategory "`n"  
                    UpdateSubCategories(cls.subCategory)
                }
                if(InStr(A_LoopField, "RELEASE", "On")){
                    cls.release := RTrim(RegExReplace(A_LoopField, "RELEASE "), "`r`n")
                    debugString .= FormatTime(,ShortTime) " |-: Release: " cls.release "`n"  
                }
                cls.path := A_LoopFileFullPath
                cls.status := StatusStopped
            }
            debugString .= FormatTime(,ShortTime) " |-: Adding " cls.title " to ScriptsArray.`n"
            
            
            ScriptsArray.Push(cls)
        }
        
        debugString .= FormatTime(,ShortTime) " |`n"
        debugString .= FormatTime(,ShortTime) " ``- Done finding scripts.`n"   
               
    if(Debug){
        FileAppend(debugString, DebugLog)
    }

}

UpdateApps(app){
    
    found := false
    debugString .= FormatTime(,ShortTime) " |- " app " app found, "
    
    for k, v in AppArray{
        if(app = v){
            found := true
        }
    }
    
    if(found){
        debugString .= "skipping.`n"
    }else{
        debugString .= "adding.`n"
        AppArray.Push(app)
        AppSelector.Delete()
        AppSelector.Add(AppArray)
    }


    if(Debug){
        FileAppend(debugString, DebugLog)
    }

}

UpdateCategories(category){

    found := false
    debugString .= FormatTime(,ShortTime) " |- " category " category found, "

    for k, v in CategoriesArray{
        if(category = v){
            found := true
        }
    }

    if(found){
        debugString .= "skipping.`n"
    }else{
        debugString .= "adding.`n"
        CategoriesArray.Push(category)
        CategorySelector.Delete()
        CategorySelector.Add(CategoriesArray)
    }

    if(Debug){
        FileAppend(debugString, DebugLog)
    }
}

UpdateSubCategories(category){
    found := false
    debugString .= FormatTime(,ShortTime) " |- " category " subcategory found, "

    for k, v in SubCategoriesArray{
        if(category = v){
            found := true
        }
    }

    if(found){
        debugString .= "skipping.`n"
    }else{
        debugString .= "adding.`n"
        SubCategoriesArray.Push(category)
        SubCategorySelector.Delete()
        SubCategorySelector.Add(SubCategoriesArray)
    }    

    if(Debug){
        FileAppend(debugString, DebugLog)
    }

}

UpdateResolutions(resolution){
    found := false
    debugString .= FormatTime(,ShortTime) " |- " resolution " resolution found, "

    for k, v in ResolutionsArray{
        if(resolution = v or resolution = "Unknown"){
            found := true
        }
    }

    if(found){
        debugString .= "skipping.`n"
    }else{
        debugString .= "adding.`n"
        ResolutionsArray.Push(resolution)
        ResolutionSelector.Delete()
        ResolutionSelector.Add(ResolutionsArray)
    }    

    if(Debug){
        FileAppend(debugString, DebugLog)
    }
}

ListScripts(){
    debugString := FormatTime(,ShortTime) " |,-  Adding scripts to Gui: `n" 
    debugString .= FormatTime(,ShortTime) " |- Disabling redraw and clearing list.`n"
    ListView.Opt("-Redraw")
    if(Debug){
        FileAppend(debugString, DebugLog)
    }


    ListView.Delete()
    

    Loop ScriptsArray.Length{
        loopScript := ScriptsArray[A_Index]
        loopString := FormatTime(,ShortTime) " |,- Should we list " loopScript.title "?`n"

        if(AppFilter = loopScript.targetApp or AppFilter = ""){
            
            loopString .= FormatTime(,ShortTime) " |- " loopScript.targetApp " isn't filtered.`n"
            if(CategoryFilter = loopScript.mainCategory 
                or CategoryFilter = ""){
                
                loopString .= FormatTime(,ShortTime) " |- " loopScript.mainCategory " isn't filtered.`n"
                if(SubCategoryFilter = loopScript.subCategory 
                    or SubCategoryFilter = ""){
                    
                    loopString .= FormatTime(,ShortTime) " |- " loopScript.subCategory " isn't filtered.`n"
                    if(TargetAppResolution = loopScript.targetResolution 
                        or TargetAppResolution = "" 
                        or loopScript.targetResolution = "Universal"){

                        loopString .= FormatTime(,ShortTime) " |- " loopScript.targetResolution " isn't filtered.`n"
                        if(loopScript.release = "Stable"){
                            
                            loopString .= FormatTime(,ShortTime) " |- " loopScript.release " isn't filtered.`n"
                            loopString .= FormatTime(,ShortTime) " |``- Listing " loopScript.title "`n"
                                
                            ListView.Add(,
                                loopScript.status, 
                                loopScript.title, 
                                loopScript.targetApp, 
                                loopScript.release, 
                                loopScript.targetResolution, 
                                loopScript.mainCategory, 
                                loopScript.subCategory
                            )    


                        }else{
                             if(ShowExperimental){

                                loopString .= FormatTime(,ShortTime) " |- " loopScript.release " isn't filtered.`n"
                                loopString .= FormatTime(,ShortTime) " |``- Listing " loopScript.title "`n"
                                ListView.Add(,
                                    loopScript.status, 
                                    loopScript.title, 
                                    loopScript.targetApp, 
                                    loopScript.release, 
                                    loopScript.targetResolution, 
                                    loopScript.mainCategory, 
                                    loopScript.subCategory
                                )   
                            }else{                                
                                loopString .= FormatTime(,ShortTime) " |- Filtered " loopScript.release ".`n"
                            }
                        }
                    }else{
                        loopString .= FormatTime(,ShortTime) " |``- Filtered " loopScript.targetResolution ".`n"
                    }
                }else{
                    loopString .= FormatTime(,ShortTime) " |``- Filtered " loopScript.subCategory ".`n"
                }               
            }else{
                loopString .= FormatTime(,ShortTime) " |``- Filtered " loopScript.mainCategory ".`n"
            }
        }else{
            loopString .= FormatTime(,ShortTime) " |``- Filtered " loopScript.targetApp ".`n"
        }

        if(Debug){
            FileAppend(loopString, DebugLog)
        }
    }
    AdjustColumns()

    debugString := FormatTime(,ShortTime) " |-  Done adding scripts to Gui. `n" 
    debugString := FormatTime(,ShortTime) " ``-  Enabling redraw. `n" 
    ListView.Opt("+Redraw")
    
    if(Debug){
        FileAppend(debugString, DebugLog)
    }
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
    FilterResolution("","",TargetAppResolution)
    UpdateStatus

    ListView.ModifyCol(2, "Sort")


}

StopAHKser(*){

    ExitApp(0)

}

Shutdown(*){
    debugString := FormatTime(,ShortTime) " |-  Shutting down " ProgramName ".`n" 
    debugString .= FormatTime(,ShortTime) " |- Writing to ini.`n"
    IniWrite(RTrim(TargetAppResolution,"`r`n"), ConfigFile, "TargetAppSettings", "TargetAppResolution")
    IniWrite(RTrim(ShowFavorites,"`r`n"), ConfigFile, "AHKserSettings", "ShowFavorites")
    IniWrite(RTrim(ShowExperimental,"`r`n"), ConfigFile, "AHKserSettings", "ShowExperimental")
    IniWrite(RTrim(dirScripts,"`r`n"), ConfigFile, "AHKserSettings", "ScriptsFolder")
    
    
    debugString .= FormatTime(,ShortTime) " ``- Bye!`n"
    if(Debug){
        FileAppend(debugString, DebugLog)
    }

    return 0
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
InitializeScript
OpenGui
SetTimer(UpdateStatus, 500)