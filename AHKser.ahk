#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
#ErrorStdOut

CompanyName := "Stefarling"
;@Ahk2Exe-Let U_companyName = %A_PriorLine~U)^(CompanyName \:\= \")(.+?)+(\")$~$2%
;@Ahk2Exe-SetCompanyName %U_companyName%

Copyright := "The Unlicense"
;@Ahk2Exe-Let U_copyright = %A_PriorLine~U)^(Copyright \:\= \")(.+?)+(\")$~$2%
;@Ahk2Exe-SetCopyright %U_copyright%

Description := "AHKser Script Manager"
;@Ahk2Exe-Let U_description = %A_PriorLine~U)^(Description \:\= \")(.+?)+(\")$~$2%
;@Ahk2Exe-SetDescription %U_description%

FileVersion := "2.1"
;@Ahk2Exe-Let U_fileVersion = %A_PriorLine~U)^(FileVersion \:\= \")(.+?)+(\")$~$2%
;@Ahk2Exe-SetFileVersion %U_fileVersion%

ProductName := "AHKser Script Manager"
;@Ahk2Exe-Let U_productName = %A_PriorLine~U)^(ProductName \:\= \")(.+?)+(\")$~$2%
;@Ahk2Exe-SetName %U_productName%

ProductVersion := "1.0.10.0"
;@Ahk2Exe-Let U_productVersion = %A_PriorLine~U)^(ProductVersion \:\= \")(.+?)+(\")$~$2%
;@Ahk2Exe-SetProductVersion %U_productVersion%

;@Ahk2Exe-SetMainIcon assets\appIcon.ico
;@Ahk2Exe-Base ..\v2\AutoHotkey64.exe, compiled\
;@Ahk2Exe-ExeName %A_ScriptName%

;@Ahk2Exe-IgnoreBegin
TraySetIcon(A_ScriptDir "\assets\appIcon.ico")
;@Ahk2Exe-IgnoreEnd

; #ANCHOR Settings - Program
Persistent
SetWorkingDir A_ScriptDir
OnExit SaveProgramState

F11::ListVars

; #ANCHOR Variables - Program
ProgramTitle := ProductName
ConfigFile := "AHKserSettings.ini"
Debug := true
DebugLog := "debug.log"
ShortTime := "HH:mm:ss"

; #ANCHOR Text Formatting
FontText                := "s10 Norm"
FontHeading             := "s11 Bold"


; #ANCHOR Settings - Program
TargetAppResolution := IniRead(ConfigFile, "TargetAppSettings", RTrim("TargetAppResolution", "`r`n"), "Universal")
ScriptsFolder := IniRead(ConfigFile, "AHKserSettings", RTrim("ScriptsFolder", "`r`n"), A_ScriptDir "\Scripts")
ShowFavorites := IniRead(ConfigFile, "AHKserSettings", RTrim("ShowFavorites", "`r`n"), true)
ShowExperimental := IniRead(ConfigFile, "AHKserSettings", RTrim("ShowExperimental", "`r`n"), false)
ShowOSD := IniRead(ConfigFile, "AHKserSettings", RTrim("ShowOSD", "`r`n"), true)
OSDx := IniRead(ConfigFile, "AHKserSettings", RTrim("OSDx", "`r`n"), 250)
OSDy := IniRead(ConfigFile, "AHKserSettings", RTrim("OSDy", "`r`n"), 250)
MainGuiX := IniRead(ConfigFile, "AHKserSettings", RTrim("MainGuiX", "`r`n"), 250)
MainGuiY := IniRead(ConfigFile, "AHKserSettings", RTrim("MainGuiY", "`r`n"), 250)
FavoritesFolder := A_ScriptDir "\Favorites"
ShowRunningScriptsReminderAnchor := false

ScriptsArray := []
ScriptsStarted := []
AppsArray := []
ResolutionsArray := []
CategoriesArray := []
SubCategoriesArray := []
FavoriteScriptsArray := []
ScriptsRunning := 0
TargetAppFilter := ""
TargetCategoryFilter := ""
TargetSubCategoryFilter := ""


; #ANCHOR Settings - Tray
A_AllowMainWindow := false
A_IconTip := ProgramTitle
TMenu := A_TrayMenu
TMenu.Delete()
TMenu.Add("Open", OpenGui)
TMenu.Add("Help", OpenHelp)
TMenu.Add()
TMenu.Add("Exit AHKser", StopAHKser)
TMenu.Default := "Open"

; #ANCHOR Settings - BarMenu
FMenu := Menu()
FMenu.Add()
FMenu.Add("E&xit", StopAHKser)
BMenu := MenuBar()
Bmenu.Add("&File", FMenu)
BMenu.Add("&Settings", OpenSettings)
BMenu.Add("&Help", OpenHelp)

; #ANCHOR GUI - Main
MainGui := Gui("-Parent +Resize +MinSize455x150 +OwnDialogs")
MainGuiIsDirty := true
MainGui.Title := ProgramTitle
MainGui.MenuBar := BMenu

MainGui.Add("Text", "Section", "App:")
MainGuiAppFilterButton := MainGui.Add("ComboBox", "XP", AppsArray)
MainGui.Add("Text", "Section YS", "Category:")
MainGuiCategoryFilterButton := MainGui.Add("ComboBox", "XP", CategoriesArray)
MainGui.Add("Text", "Section YS", "Sub-Category:")
MainGuiSubCategoryFilterButton := MainGui.Add("ComboBox", "XP", SubCategoriesArray)

RescanButton := MainGui.Add("Button","YP","Rescan")

ListViewColumns := [" ", "Script Name", "App", "Branch", "Resolution", "Category", "Sub-Category", "Path"]
MainGuiListView := MainGui.Add("ListView", "Section XM -multi r10 W450", ListViewColumns)

StsBar := MainGui.Add("StatusBar", ,)


; #ANCHOR GUI - Main - OnEvent
MainGuiListView.OnEvent("DoubleClick", ToggleScriptStatus)
MainGui.OnEvent("Size", GuiResize)
MainGuiAppFilterButton.OnEvent("Change", FilterApps)
MainGuiCategoryFilterButton.OnEvent("Change", FilterCategory)
MainGuiSubCategoryFilterButton.OnEvent("Change", FilterSubCategory)
MainGui.OnEvent("Close", HideAHKser)
MainGuiListView.OnEvent("ContextMenu", ShowContextMenu)
RescanButton.OnEvent("Click", RescanScripts)


; #ANCHOR Gui - Settings
SettingsGui := Gui("-Resize +ToolWindow +Owner")
SettingsGui.Title := "Settings"
SettingsGuiIsDirty := false

textBlock :="
(
    Preferred Resolution:
)"
SettingsGui.Add("Text", "Section", textBlock)
SettingsGuiResolutionFilterButton := SettingsGui.Add("ComboBox", "XP", ResolutionsArray)
SettingsGuiResolutionFilterButton.Text := TargetAppResolution


SettingsGuiFavoriteCheckbox := SettingsGui.Add("CheckBox", "XS+0 vFavoriteShow", "Show favorite scripts.")

textBlock :="
(
    Show Experimental Scripts?
    (Using experimental scripts can cause unexpected things to happen.)
)"
SettingsGuiExperimentalCheckbox := SettingsGui.Add("CheckBox", "XS vExperimentalShow", textBlock)



SettingsGuiToggleOSDCheckbox   := SettingsGui.Add("Checkbox","XP", "Toggle OSD Script Reminder")
SettingsGuiToggleOSDAnchorButton := SettingsGui.Add("Button", "XP", "Show OSD Anchor")

textBlock :="
(
    Scripts: 
)"
SettingsGuiScriptLocationText := SettingsGui.Add("Text","Section vScriptLocation", textBlock . ScriptsFolder )
ScriptFolderButton := SettingsGui.Add("Button", "XS r1 w60", "Browse")
ScriptSelectButton := SettingsGui.Add("Button", "YP r1 w60", "Change...")

textBlock :="
(
    App: 
)"
SettingsGui.Add("Text","Section XS",textBlock . A_ScriptDir )
AppFolderButton := SettingsGui.Add("Button", "r1 w60", "Browse...")

SettingsGui.Add("Text", "Section XS YP+60", "Press Escape to close this window.")


; #ANCHOR Gui - ContextMenu
ContextMenu := Menu()
ContextMenu.Add("&Toggle Script", ContextToggleScript)
ContextMenu.Add()
ContextMenu.Add("&Edit", ContextEdit)
ContextMenu.Add("&Properties", ContextProperties)
ContextMenu.Add("Toggle &Favorite", ContextToggleFavorite)
ContextMenu.Add()
ContextMenu.Add("&Delete", ContextDeleteScript)
ContextMenu.Default := "1&"

; #ANCHOR Gui - ContextMenu - OnEvents


; #ANCHOR OSD
OSD := Gui(OSDx " " OSDy)
OSD.Title := "Anchor"
OSD.MarginX := 0
OSD.MarginY := 0
OSD.BackColor := "000000"
OSD.SetFont("s36 bold")
OSD.Add("Picture", "Section XM-0 YM-0 w64 h64 BackgroundTrans",  A_InitialWorkingDir "\assets\appIcon.ico")
OSDtext := OSD.Add("Text","XP+22 YP+18 BackgroundTrans cff0000",ScriptsRunning)
WinSetTransColor(OSD.BackColor " 225", OSD)
OSD.Opt("+AlwaysOnTop -Resize +ToolWindow -Caption -SysMenu +E0x20")
OSD.Opt("+Disabled")
if(ShowOSD = true){
OSD.Show( "X" OSDx " Y" OSDY " NoActivate")
}

; #ANCHOR OSD - OnEvent
OSD.OnEvent("Escape", LockOSD)

; #ANCHOR Symbols - Status
Running := "✓"
Stopped := "X"
Unknown := "?"


; #ANCHOR Script Class
class Script {
    title := unknown
    version := unknown
    author := unknown
    targetApp := unknown
    targetVersion := unknown
    targetResolution := unknown
    description := unknown
    mainCategory := unknown
    subCategory := unknown
    release := unknown
    status := unknown
    path := unknown
    reference := unknown
}


; #ANCHOR Functions
OpenScriptsFolder(*) {
    try {
        DirCreate(ScriptsFolder)
        Run "explore " ScriptsFolder
    } catch {
        MsgBox "Couldn't create " ScriptsFolder
    }
}

SelectScriptsFolder(*) {
    try {
        global ScriptsFolder := DirSelect( A_ScriptDir, 3, "Select Scripts location...")
        FindScripts
        local textBlock :="
        (
            Scripts: 
        )"
        SettingsGuiScriptLocationText.Text := textBlock "" ScriptsFolder 
        global MainGuiIsDirty := true
        global SettingsGuiIsDirty := true
    } catch {
        MsgBox "Couldn't do what you wanted. Sorry!"
    }
}

OpenAppFolder(*) {

    try {
        Run "explore " A_WorkingDir
    } catch {
        MsgBox "Couldn't open " A_WorkingDir
    }

}

FilterApps(ctrl, *) {
    if (ctrl.Value > 0) {
        global TargetAppFilter := AppsArray[ctrl.Value]
    } else {
        global TargetAppFilter := ""
    }

    global MainGuiIsDirty := true
    UpdateGui
}

FilterCategory(ctrl, *) {
    if (ctrl.Value > 0) {
        global TargetCategoryFilter := CategoriesArray[ctrl.Value]
    } else {
        global TargetCategoryFilter := ""
    }

    global MainGuiIsDirty := true
    UpdateGui
}

FilterSubCategory(ctrl, *) {
    if (ctrl.Value > 0) {
        global TargetSubCategoryFilter := SubCategoriesArray[ctrl.Value]
    } else {
        global TargetSubCategoryFilter := ""
    }

    global MainGuiIsDirty := true
    UpdateGui
}

FilterResolution(obj, info, resolution := TargetAppResolution) {
    if (obj != "") {
        if (obj.Value > 0) {
            global TargetAppResolution := ResolutionsArray[obj.Value]
        } else {
            global TargetAppResolution := ""
        }
    }

    global MainGuiIsDirty := true
    UpdateGui
}

GuiResize(thisGui, MinMax, Width, Height)  ; Expand/Shrink ListView in response to the user's resizing.
{
    if MinMax = -1  ; The window has been minimized. No action needed.
        return
    ; Otherwise, the window has been resized or maximized. Resize the ListView to match.
    MainGuiListView.Move(, , Width - 20, Height - 80)
}

ShowContextMenu(listView, item, isRightClick, x, y){
    if (item > listView.GetCount()) ; Not sure why the header returns 12 atm #FIXME
        return
    if not item  ; For now, only select scripts
        return ; Do nothing if no item was focused
    if(listView.GetText(item) = Running){
        newText := "&Stop Script"
        ContextMenu.Rename("1&", newText)
        ContextMenu.Default := newText
    }else if(listView.GetText(item) = Stopped or Unknown){
        newText := "&Start Script"
        ContextMenu.Rename("1&", newText)
        ContextMenu.Default := newText
    }
    ; Show the menu at the provided coordinates, X and Y.  These should be used
    ; because they provide correct coordinates even if the user pressed the Apps key:
    ContextMenu.Show(X, Y)

}

ContextEdit(*){
    ; #TODO Add editor
    MsgBox "Not implemented yet. Sorry!"

}

ContextDeleteScript(null, *){
    focusedRowNumber := MainGuiListView.GetNext(0, "F")
    if not focusedRowNumber ; No row is focused
        return
    fileName := MainGuiListView.GetText(focusedRowNumber, 8)
    msgString := "Really delete " fileName "?"
    choice := MsgBox( msgString, "Confirm delete?", "+Owner +YesNo" )
    if(choice = "Yes"){        
                if (WinExist(fileName)) {
                    WinClose
                }
                FileRecycle fileName
                FindScripts
                UpdateStatus
    }
}

ContextProperties(*){
    ; #TODO Add Properties dialog
    MsgBox "Not implemented yet. Sorry!"

}

ContextToggleFavorite(*){
    ; #TODO Add favorites
    MsgBox "Not implemented yet. Sorry!"

}

ContextToggleScript(null, *){
    focusedRowNumber := MainGuiListView.GetNext(0, "F")
    if not focusedRowNumber ; No row is focused
        return
    fileName := MainGuiListView.GetText(focusedRowNumber, 2)

    ToggleScriptStatus(, focusedRowNumber)
}

ToggleScriptStatus(ctrl?, index := 0) {

    if (index > 0) {

        scriptStatus := MainGuiListView.GetText(index, 1)
        scriptPath := MainGuiListView.GetText(index, 8)

        runningScripts := WinGetList("ahk_class AutoHotkey")

        if (scriptStatus != Running) {    ; We wanna run it
            try {
                Run(scriptPath)
                global MainGuiIsDirty := true
                UpdateStatus
            } catch {
                MsgBox "Couldn't start " scriptPath
            }
        } else {                          ; We wanna stop it
            try {
                if (WinExist(scriptPath)) {
                    WinClose
                    MainGuiIsDirty := true
                    UpdateStatus
                }
            } catch {
                MsgBox "Couldn't stop " scriptPath
            }
        }
    }
}

OpenHelp(*) {
    try {
        Run "https://github.com/Stefarling/AHKser/wiki"
    } catch {
        MsgBox "Couldn't open https://github.com/Stefarling/AHKser/wiki"
    }
}


OpenSettings(*) {
    MainGui.Opt("+Disabled")
    SettingsGuiResolutionFilterButton.Text := TargetAppResolution
    SettingsGuiExperimentalCheckbox.value := ShowExperimental
    SettingsGuiToggleOSDCheckbox.value := ShowOSD

    if(ShowRunningScriptsReminderAnchor = true){
        SettingsGuiToggleOSDAnchorButton.Text := "Lock OSD Anchor"
    }else{
        SettingsGuiToggleOSDAnchorButton.Text := "Unlock OSD Anchor"
    }

    SettingsGui.OnEvent("Close", CloseSettings)
    SettingsGui.OnEvent("Escape", CloseSettings)
    ScriptFolderButton.OnEvent("Click", OpenScriptsFolder)
    ScriptSelectButton.OnEvent("Click", SelectScriptsFolder)
    AppFolderButton.OnEvent("Click", OpenAppFolder)
    SettingsGuiResolutionFilterButton.OnEvent("Change", FilterResolution)
    SettingsGuiExperimentalCheckbox.OnEvent("Click", UpdateShowExperimental)
    SettingsGuiFavoriteCheckbox.OnEvent("Click", UpdateShowFavorites)
    SettingsGuiToggleOSDCheckbox.OnEvent("Click", ToggleOSD)
    SettingsGuiToggleOSDAnchorButton.OnEvent("Click", ToggleOSDAnchor)

    SettingsGui.Show
}

ToggleOSD(*){
    if(ShowOSD = true){
        global ShowOSD := false
        OSD.Hide
    }else{
        OSD.Show("X" OSDx " Y" OSDy "NoActivate")
        global ShowOSD := true
    }
}

LockOSD(*){
    if(ShowRunningScriptsReminderAnchor = true){
        OSD.Opt("+Disabled -Caption +E0x20")    
        SettingsGuiToggleOSDAnchorButton.Text := "Unlock OSD Anchor"
        global ShowRunningScriptsReminderAnchor := false
        global SettingsGuiIsDirty := true
    }
}

ToggleOSDAnchor(*){
    if(ShowRunningScriptsReminderAnchor = true){
        OSD.Opt("+Disabled -Caption +E0x20")    
        SettingsGuiToggleOSDAnchorButton.Text := "Unlock OSD Anchor"
        global ShowRunningScriptsReminderAnchor := false
        global SettingsGuiIsDirty := true
    }else{
        OSD.Opt("+Caption -Disabled -E0x20 +MinSize100x100")
        x := 0
        y := 0
        WinGetPos(&x, &y,,,OSD)
        OSD.Move(,, 80, 100)
        SettingsGuiToggleOSDAnchorButton.Text := "Lock OSD Anchor"
        global ShowRunningScriptsReminderAnchor := true
        global SettingsGuiIsDirty := true
    }
}

UpdateOSD(*){
    OSDtext.Text := ScriptsRunning
}

CloseSettings(thisgui) {
    MainGui.Opt("-Disabled")
    SettingsGui.Hide
}

UpdateShowExperimental(ctrl, *) {
    global ShowExperimental := ctrl.Value

    global MainGuiIsDirty := true
    UpdateGui
}

UpdateShowFavorites(ctrl, *) {
    global ShowFavorites := ctrl.Value

    global MainGuiIsDirty := true
    UpdateGui
}

UpdateStatus(*) {
    DetectHiddenWindows "On"
    DetectHiddenText "On"
    oldScriptsRunning := ScriptsRunning
    global ScriptsRunning := 0

    Loop ScriptsArray.Length {
        scriptIndice := A_Index
        title := ScriptsArray[scriptIndice].path
        if (WinExist(title)) {
            if (ScriptsArray[scriptIndice].status != Running) {
                ScriptsArray[scriptIndice].status := Running
                global MainGuiIsDirty := true
            }
            global ScriptsRunning := ScriptsRunning + 1

        }

        if (ScriptsArray[scriptIndice].status = Running
            and !WinExist(title)) {
                ScriptsArray[scriptIndice].status := Stopped
                global MainGuiIsDirty := true
        }

        if (ScriptsArray[scriptIndice].status = Unknown
            and !WinExist(title)) {
                ScriptsArray[scriptIndice].status := Stopped
                global MainGuiIsDirty := true


        }
    }
    if(oldScriptsRunning != ScriptsRunning){
        UpdateOSD
    }
    UpdateGui
    DetectHiddenText "Off"
    DetectHiddenWindows "Off"
}

UpdateGui(*) {
    MainGuiListView.ModifyCol(1, , ScriptsRunning)
    if (MainGuiIsDirty = true) {
        MainGuiListView.Opt("-Redraw")

        ListScripts

        Sleep 1
        MainGuiListView.Opt("+Redraw")
        global MainGuiIsDirty := false
    }

    if (SettingsGuiIsDirty = true){
        global SettingsGuiIsDirty := false
    }

}


RescanScripts(*){
    ; #TODO Implement automatic refresh on folder modified.
    FindScripts
}

FindScripts() {
    RescanButton.Enabled := false

    
    global ScriptsArray := []
    Loop Files, ScriptsFolder "\*ahk", "R"
    {
        fileText := FileRead(A_LoopFileFullPath)
        cls := Script.Call()

        Loop Parse fileText, ";|`n", A_Space A_Tab {
            if (InStr(A_LoopField, "TITLE", "On")) {
                cls.title := RTrim(RegExReplace(A_LoopField, "TITLE "), "`r`n")
            }
            if (InStr(A_LoopField, "SCRIPTVERSION", "On")) {
                cls.version := RTrim(RegExReplace(A_LoopField, "SCRIPTVERSION "), "`r`n")
            }
            if (InStr(A_LoopField, "TARGETAPP", "On")) {
                cls.targetApp := RTrim(RegExReplace(A_LoopField, "TARGETAPP "), "`r`n")
                UpdateApps(cls.targetApp)
            }
            if (InStr(A_LoopField, "TARGETVERSION", "On")) {
                cls.targetVersion := RTrim(RegExReplace(A_LoopField, "TARGETVERSION "), "`r`n")
            }
            if (InStr(A_LoopField, "TARGETRESOLUTION", "On")) {
                cls.targetResolution := RTrim(RegExReplace(A_LoopField, "TARGETRESOLUTION "), "`r`n")
                UpdateResolutions(cls.targetResolution)
            }
            if (InStr(A_LoopField, "AUTHOR", "On")) {
                cls.author := RTrim(RegExReplace(A_LoopField, "AUTHOR "), "`r`n")
            }
            if (InStr(A_LoopField, "DESCRIPTION", "On")) {
                cls.description := RTrim(RegExReplace(A_LoopField, "DESCRIPTION "), "`r`n")
            }
            if (InStr(A_LoopField, "MAINCATEGORY", "On")) {
                cls.mainCategory := RTrim(RegExReplace(A_LoopField, "MAINCATEGORY "), "`r`n")
                UpdateCategories(cls.mainCategory)
            }
            if (InStr(A_LoopField, "SUBCATEGORY", "On")) {
                cls.subCategory := RTrim(RegExReplace(A_LoopField, "SUBCATEGORY "), "`r`n")
                UpdateSubCategories(cls.subCategory)
            }
            if (InStr(A_LoopField, "RELEASE", "On")) {
                cls.release := RTrim(RegExReplace(A_LoopField, "RELEASE "), "`r`n")
            }
            cls.path := A_LoopFileFullPath
            cls.status := Unknown
            cls.reference := &cls
        }
        ScriptsArray.Push(cls)
    }
    
    RescanButton.Enabled := true
}

UpdateApps(app) {

    found := false

    for k, v in AppsArray {
        if (app = v) {
            found := true
        }
    }

    if (!found) {
        AppsArray.Push(app)
        MainGuiAppFilterButton.Delete()
        MainGuiAppFilterButton.Add(AppsArray)
    }
}

UpdateCategories(category) {

    found := false

    for k, v in CategoriesArray {
        if (category = v) {
            found := true
        }
    }

    if (!found) {
        CategoriesArray.Push(category)
        MainGuiCategoryFilterButton.Delete()
        MainGuiCategoryFilterButton.Add(CategoriesArray)
    }
}

UpdateSubCategories(category) {
    found := false

    for k, v in SubCategoriesArray {
        if (category = v) {
            found := true
        }
    }

    if (!found) {
        SubCategoriesArray.Push(category)
        MainGuiSubCategoryFilterButton.Delete()
        MainGuiSubCategoryFilterButton.Add(SubCategoriesArray)
    }

}

UpdateResolutions(resolution) {
    found := false

    for k, v in ResolutionsArray {
        if (resolution = v or resolution = "Unknown") {
            found := true
        }
    }

    if (!found) {
        ResolutionsArray.Push(resolution)
        SettingsGuiResolutionFilterButton.Delete()
        SettingsGuiResolutionFilterButton.Add(ResolutionsArray)
    }

}

ListScripts() {
    MainGuiListView.Delete()

    Loop ScriptsArray.Length {
        loopScript := ScriptsArray[A_Index]

        if (TargetAppFilter = loopScript.targetApp or TargetAppFilter = "") {

            if (TargetCategoryFilter = loopScript.mainCategory
                or TargetCategoryFilter = "") {

                    if (TargetSubCategoryFilter = loopScript.subCategory
                        or TargetSubCategoryFilter = "") {

                            if (TargetAppResolution = loopScript.targetResolution
                                or TargetAppResolution = ""
                                or loopScript.targetResolution = "Universal") {

                                    if (loopScript.release = "Stable") {
                                        MainGuiListView.Add(,
                                            loopScript.status,
                                            loopScript.title,
                                            loopScript.targetApp,
                                            loopScript.release,
                                            loopScript.targetResolution,
                                            loopScript.mainCategory,
                                            loopScript.subCategory,
                                            loopScript.path
                                        )


                                    } else {
                                        if (ShowExperimental) {

                                            MainGuiListView.Add(,
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
    AdjustColumns
}

InitializeAHKser() {

    FindScripts
    UpdateStatus
    FilterResolution("", "", TargetAppResolution)
    MainGuiListView.ModifyCol(2, "Sort")
    MainGuiListView.ModifyCol(8, "0")
}

AdjustColumns(*) {
    Loop MainGuiListView.GetCount("Column") {
        MainGuiListView.ModifyCol(A_Index, "+AutoHdr")
    }
    MainGuiListView.ModifyCol(8, "-AutoHdr 0")
}

SaveProgramState(*) {    ; Saves current program state to drive

    x := 0
    y := 0
    w := 0
    h := 0
    WinGetPos &x, &y, &w, &h, OSD
    IniWrite(RTrim(x, "`r`n"), ConfigFile, "AHKserSettings", "OSDx")
    IniWrite(RTrim(y, "`r`n"), ConfigFile, "AHKserSettings", "OSDy")
    IniWrite(RTrim(ShowOSD, "`r`n"), ConfigFile, "AHKserSettings", "ShowOSD")

    WinGetPos &x, &y, &w, &h, MainGui
    IniWrite(RTrim(x, "`r`n"), ConfigFile, "AHKserSettings", "MainGuiX")
    IniWrite(RTrim(y, "`r`n"), ConfigFile, "AHKserSettings", "MainGuiY")


    IniWrite(RTrim(TargetAppResolution, "`r`n"), ConfigFile, "TargetAppSettings", "TargetAppResolution")
    IniWrite(RTrim(ShowFavorites, "`r`n"), ConfigFile, "AHKserSettings", "ShowFavorites")
    IniWrite(RTrim(ShowExperimental, "`r`n"), ConfigFile, "AHKserSettings", "ShowExperimental")
    IniWrite(RTrim(ScriptsFolder, "`r`n"), ConfigFile, "AHKserSettings", "ScriptsFolder")

}

HideAHKser(*){
    MainGui.Hide
    TrayTip("AHKser minimized to tray.",,"Mute")
}

OpenGui(*) {

    MainGui.Show("X" MainGuiX " Y" MainGuiY)
}

StopAHKser(*) {
    ExitApp(0)
}

InitializeAHKser
OpenGui
SetTimer(UpdateStatus, 500)