#Requires AutoHotkey v2.0
; AHKser Script Manager
; Version 1.0.0
; Use to manage AHK scripts from central GUI


; Hotkeys
; None yet

; Variables
ProgramName             := "AHKser Script Manager"
Resolutions             := ["1920x1080", "2560x1440"]
Scripts                 := []
Resolution              := ""
FocusedScript           := ""

Running                 := "✓"
Stopped                 := "X"
Unknown                 := "?"

AlwaysShowUniversal     := true
CategoriesArray         := []


; Settings
Persistent
SetWorkingDir A_ScriptDir


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






; Gui
MainGui                 := Gui()
MainGui.Title           := ProgramName

; Gui Controls
ResolutionGuiLabel      := MainGui.Add("Text", "Section","Resolution")
ResolutionComboBox      := MainGui.Add("ComboBox", "", Resolutions)

StartButton             := MainGui.Add("Button", "Section Y+5 r2 w60", "Start`nScript")
ScriptsFolderButton     := MainGui.Add("Button","r2 w60","Scripts`nFolder")
StopButton              := MainGui.Add("Button", "YP r2 w60", "Stop`nScript")



; Gui ListView
ListView                := MainGui.Add("ListView", "Section XM+150 YM+0 h150 w300 -multi",["", "Script Name", "Path"])



; Gui OnEvents
ResolutionComboBox.OnEvent("Change", UpdateResolution )
StartButton.OnEvent("Click", StartScript)
StopButton.OnEvent("Click", StopScript)
ScriptsFolderButton.OnEvent("Click", OpenScriptsFolder)
ListView.OnEvent("ItemFocus", ScriptFocused)
ListView.OnEvent("DoubleClick", ToggleScriptStatus)


; Functions
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
        global Resolution := Resolutions[obj.Value]
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