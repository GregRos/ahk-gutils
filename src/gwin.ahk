#include glang.ahk

; Returns true if the window identified by `winTitle` is full screen.
gWin_IsFullScreen(winTitle := "") {
    ;checks if the specified window is full screen
    ;code from NiftyWindows source
    ;(with only slight modification)

    ;use WinExist of another means to get the Unique ID (HWND) of the desired window

    if ( !winTitle ) {
        WinGet, winTitle, ID, A
    }

    WinGet, WinMinMax, MinMax, ahk_id %winTitle%
    WinGetPos, WinX, WinY, WinW, WinH, ahk_id %winTitle%

    if (WinMinMax = 0) && (WinX = 0) && (WinY = 0) && (WinW = A_ScreenWidth) && (WinH = A_ScreenHeight) {
        WinGetClass, WinClass, ahk_id %winTitle%
        WinGet, WinProcessName, ProcessName, ahk_id %winTitle%
        SplitPath, WinProcessName, , , WinProcessExt

        if (WinClass != "Progman") && (WinProcessExt != "scr") {
            ;program is full-screen
            return true
        }
    }
    return false
}

; Returns true if the mouse cursor is visible.
gWin_IsMouseCursorVisible() {
    StructSize := A_PtrSize + 16
    VarSetCapacity(InfoStruct, StructSize)
    NumPut(StructSize, InfoStruct)
    DllCall("GetCursorInfo", UInt, &InfoStruct)
    Result := NumGet(InfoStruct, 8)
    return Result > 1
}

z__gutils_MatchingInfoKeys := ["speed", "mode", "hiddenWindows", "hiddenText", "title", "text", "excludeTitle", "excludeText"]
global z__gutils_MatchingInfoValidator := gObj_NewValidator("MatchingInfo", [], z__gutils_MatchingInfoKeys)

; Returns the matching info of the current thread, e.g. A_DetectHiddenWindows.
gWin_GetMatchingInfo() {
    return {hiddenWindows: A_DetectHiddenWindows, hiddenText: A_DetectHiddenText, speed: A_TitleMatchModeSpeed, mode: A_TitleMatchMode}
}

z__gutils_maybeSetMatchingInfo(obj) {
    if (obj = False) {
        return
    }
    return gWin_SetMatchingInfo(obj)
}

; Sets the current matching info from `infoObj`.
gWin_SetMatchingInfo(infoObj) {
    z__gutils_MatchingInfoValidator.Assert(infoObj)
    modified := False
    old := gWin_GetMatchingInfo()
    if (infoObj.HasKey("mode")) {
        SetTitleMatchMode, % infoObj.mode
        modified := True
    }
    if (infoObj.HasKey("speed")) {
        SetTitleMatchMode, % infoObj.speed
        modified := True
    }
    if (infoObj.HasKey("hiddenWindows")) {
        DetectHiddenWindows, % gLang_Bool(infoObj.hiddenWindows, "OnOff")
        modified := True
    }
    if (infoObj.HasKey("hiddenText")) {
        DetectHiddenText, % gLang_Bool(infoObj.hiddenText, "OnOff")
        modified := True
    }
    return modified ? old : False
}

z__gutils_WinGet(hwnd, subCommand) {
    WinGet, v, % subCommand, ahk_id %hwnd%
    return v
}

; A reference to a specific window that lets you gets info about it.
class gWinInfo {
    hwnd := ""

    __New(hwnd) {
        this.hwnd := hwnd
        return gObj_Checked(this)
    }

    _winTitle() {
        return "ahk_id " this.hwnd
    }

    _winGet(subCommand) {
        WinGet, v, % subCommand, % this._winTitle()
        return v
    }

    ; The window's owner process PID.
    PID {
        get {
            return this._winGet("PID")
        }
    }

    ; The name of the window's owner process.
    ProcessName {
        get {
            return this._winGet("ProcessName")
        }
    }

    ; The path to the window's owner process.
    ProcessPath {
        get {
            return this._winGet("ProcessPath")
        }
    }

    Transparent {
        get {
            return this._winGet("Transparent")
        }
    }

    TransColor {
        get {
            return this._winGet("TransColor")
        }
    }

    Style {
        get {
            return this._winGet("Style")
        }
    }

    ExStyle {
        get {
            return this._winGet("ExStyle")
        }
    }

    ; Whether the window if minimized or maximized.
    MinMax {
        get {
            return this._winGet("MinMax")
        }
    }

    ; The window's title.
    Title {
        get {
            WinGetTitle, v, % this._winTitle()
            return v
        }
    }

    ; The window's class.
    Class {
        get {
            WinGetClass, v, % this._winTitle()
            return v
        }
    }

    ; The window's position and size info.
    Pos {
        get {
            WinGetPos, X, Y, Width, Height, % this._winTitle()
            return {X: X
                ,Y: Y
                ,Width:Width
            ,Height:Height}
        }
    }

    ; Whether the window is active.
    IsActive {
        get {
            return WinActive(this._winTitle())
        }
    }

    ; The window's text.
    Text {
        get {
            WinGetText, v, % this._winTitle()
            return v
        }
    }

    ; The window's Hwnd.
    ID {
        get {
            return this.hwnd
        }
    }

    ; Whether the window still exists.
    Exists {
        get {
            return WinExist(this._winTitle()) > 0
        }
    }

    ; Hides the window.
    Hide() {
        WinHide, % this._winTitle()
    }

    ; Unhides the window.
    Show() {
        WinShow, % this._winTitle()
    }

    ; Kills the window.
    Kill() {
        WinKill, % this._winTitle()
    }

    Maximize() {
        WinMaximize, % this._winTitle()
    }

    Minimize() {
        WinMinimize, % this._winTitle()
    }

    Move(X, Y, Width:= "", Height := "") {
        WinMove, % this._winTitle(), , % X, % Y, % Width, % Height
    }

    Restore() {
        WinRestore, % this._winTitle()
    }

    Set(subCommand, value := "") {
        WinSet, % subCommand, % value, % this._winTitle()
    }

    Activate() {
        WinActivate, % this._winTitle()
    }

}

; Performs a query on windows given query object `query`, returning the first matching window.
gWin_Get(query) {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        hwnd := WinExist(query.title, query.text, query.excludeTitle, query.excludeText)
        if (hwnd = 0) {
            return ""
        }
        return new gWinInfo(hwnd)
    } finally {
        z__gutils_maybeSetMatchingInfo(old)
    }
}

; Performs a window query and returns all matching window objects.
gWin_List(query) {
    z__gutils_MatchingInfoValidator.Assert(query)
    WinGet, win, List, % query.title, % query.text, % query.excludeTitle, % query.excludeText
    arr := []
    Loop, % win 
    {
        arr.push(new gWinInfo(win%A_index%))
    }
    v := arr
}

; WinWait on the first window matching the query.
gWin_Wait(query, timeout := "") {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWait, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        hwnd:=WinExist()
        return new gWinInfo(hwnd)
    } finally {
        z__gutils_maybeSetMatchingInfo(old)
    }

}

gWin_WaitActive(query, active := 1, timeout := "") {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        if (active) {
            WinWaitActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        } else {
            WinWaitNotActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        }
        hwnd:=WinExist()
        return new gWinInfo(hwnd)
    } finally {
        z__gutils_maybeSetMatchingInfo(old)
    }
}

gWin_WaitClose(query, timeout := "") {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWaitClose, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
    } finally {
        z__gutils_maybeSetMatchingInfo(obj)
    }

}