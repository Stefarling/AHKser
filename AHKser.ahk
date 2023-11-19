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
; None yet


; Program Variables
ProgramName             := "AHKser Script Manager"
ConfigFile              := "AHKserSettings.ini"


; Global Variables
FocusedScript           := ""


; Global Symbols
Running                 := "✓"
Stopped                 := "X"
Unknown                 := "?"



; Program
Persistent
SetWorkingDir A_ScriptDir
FileAppend("", ConfigFile)

SupportedResolutions    := ["1280x720", "1920x1080", "2560x1440"]
Resolution              := IniRead(ConfigFile, "TargetAppSettings", "TargetAppResolution", "")
AlwaysShowUniversal     := IniRead(ConfigFile, "AHKserSettings", "AlwaysShowUniversal", true)
AlwaysShowFavorites     := IniRead(ConfigFile, "AHKserSettings", "AlwaysShowFavorites", true)
AlwaysShowExperimental  := IniRead(ConfigFile, "AHKserSettings", "AlwaysShowExperimental", false)
CategoriesArray         := []



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
TrayMenu.Add("Exit AHKser", QuitProgram)
TrayMenu.Default :="Open"


; Settings - BarMenu
FileMenu    := Menu()
FileMenu.Add "E&xit", (*) => ExitApp()
Menus   := MenuBar()
Menus.Add "&File", FileMenu
Menus.Add "&Settings", (*) => OpenSettings()



; MainGui
MainGui                 := Gui("-Parent -Resize +OwnDialogs")
MainGui.Title           := ProgramName
MainGui.MenuBar         := Menus


; Gui ListView
ListView                := MainGui.Add("ListView", "Section -multi  r10 W450",["", "Script Name", "Path"])

StatusBar               := MainGui.Add("StatusBar",,)



; MainGui OnEvents
ListView.OnEvent("ItemFocus", ScriptFocused)
ListView.OnEvent("DoubleClick", ToggleScriptStatus)


; SettingsGui
SettingsGui := Gui("-Resize +ToolWindow +Owner" MainGui.Hwnd)
SettingsGui.Add("CheckBox", "vUniversalShow","Always show universal scripts.")
SettingsGui.Add("CheckBox", "vFavoriteShow","Always show favorite scripts.")
SettingsGui.Add("CheckBox", "vExperimentalShow","Show experimental scripts.")

SettingsGui.Add("Text", "XP YP+20","Resolution")
ResolutionComboBox      := SettingsGui.Add("ComboBox", "XP+0 YP+15", SupportedResolutions)
ResolutionComboBox.Text := Resolution

ScriptsFolderButton     := SettingsGui.Add("Button","Section r2 w60","Scripts`nFolder")
AppFolderButton         := SettingsGui.Add("Button","YS XP+65 r2 w60","App`nFolder")



SettingsGui.Add("Text","Section XS YS+60","Press Escape to close this window.")

; SettingsGui OnEvents
SettingsGui.OnEvent("Close", CloseSettings)
SettingsGui.OnEvent("Escape", CloseSettings)
ScriptsFolderButton.OnEvent("Click", OpenScriptsFolder)
AppFolderButton.OnEvent("Click", OpenAppFolder)

; Functions
OpenSettings(){
    MainGui.Opt("+Disabled")

    ; OnEvents    
    ResolutionComboBox.OnEvent("Change", UpdateResolution )


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

QuitProgram(*){
    ExitApp 0
}

OpenGui(*){
    MainGui.Show()
}

OpenHelp(*){
    Run "https://github.com/Stefarling/AHKser/wiki"
}

ToggleScriptStatus(GuiCtrlObj, Info){
    global FocusedScript := ListView.GetText(Info, 3)

    if(ListView.GetText(Info, 1) = Stopped){
        StartScript()
    }else{
        StopScript()

    }

}

UpdateResolution(obj, info){
    if ( obj.Value > 0){
        global Resolution := SupportedResolutions[obj.Value]
        IniWrite Resolution, ConfigFile, "TargetAppSettings", "TargetAppResolution"
    }

    ListScripts()
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
       global FocusedScript := ListView.GetText(item, 3)
}

ListScripts(){
    scriptsUniversalPath    := A_ScriptDir "\Scripts\Universal"
    scriptsResolutionPath   := A_ScriptDir "\Scripts\Palia\" Resolution

    ListView.Delete()
    ListView.Opt("-Redraw")

    Loop Files, scriptsUniversalPath "\*.ahk"
        ListView.Add(,Unknown, A_LoopFileName, A_LoopFilePath)

    Loop Files, scriptsResolutionPath "\*ahk"
        ListView.Add(,Unknown, A_LoopFileName, A_LoopFilePath)
    

    AdjustColumns()

    ListView.Opt("+Redraw")    
}

UpdateScriptsStatus(){
    DetectHiddenWindows "On"
    ListView.Opt("-Redraw")
    scriptsRunning := 0
    ListView.Modify(0,, Stopped)

    scriptsList := WinGetList("ahk_class AutoHotkey")
    for k, v in  scriptsList{
        title := WinGetTitle(scriptsList[k])
        title := RegExReplace(title, " - AutoHotkey v[\.0-9]+$")
        Loop ListView.GetCount(){
            if (title == ListView.GetText(A_Index, 3)){
                ListView.Modify(A_Index,, Running )
                scriptsRunning++
            }
        }
    }
    
    ListView.ModifyCol(1,, scriptsRunning)
    DetectHiddenWindows "Off"
    ListView.Opt("+Redraw")  
}

UpdateGui(){
    UpdateScriptsStatus()
}


; Button Events


; Run the script
ListScripts()
ListView.ModifyCol(2, "Sort")
SetTimer(UpdateGui, 1000)
MainGui.Show()