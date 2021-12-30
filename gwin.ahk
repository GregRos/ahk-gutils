#include _internals.ahk

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

gWin_IsMouseCursorVisible() {
    StructSize := A_PtrSize + 16
    VarSetCapacity(InfoStruct, StructSize)
    NumPut(StructSize, InfoStruct)
    DllCall("GetCursorInfo", UInt, &InfoStruct)
    Result := NumGet(InfoStruct, 8)
    return Result > 1
}

__g_MatchingInfoKeys := ["hiddenWindows", "hiddenText", "speed", "mode", "title", "text", "excludeTitle", "excludeText"]
__g_MatchingInfoValidator := gObj_NewValidator("MatchingInfo", [], __g_MatchingInfoKeys)

gWin_GetMatchingInfo() {
    return {hiddenWindows: A_DetectHiddenWindows, hiddenText: A_DetectHiddenText, speed: A_TitleMatchModeSpeed, mode: A_TitleMatchMode}
}

__g_maybeSetMatchingInfo(obj) {
    if (obj = False) {
        return
    }
    return gWin_SetMatchingInfo(obj)
}

gWin_SetMatchingInfo(infoObj) {
    __g_MatchingInfoValidator.Assert(infoObj)
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

gWin_GetId(query) {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        return WinExist(query.title, query.text, query.excludeTitle, query.excludeText)
    } finally {
        __g_maybeSetMatchingInfo(old)
    }
}

gWin_GetIds(query) {
    return gWin_Get("List", query)
}

gWin_Get(Cmd, query) {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinGet, v, % Cmd , % WinTitle, % WinText, % ExcludeTitle, % ExcludeText
        if (Cmd = "list") {
            arr := []
            Loop, % v 
            {
                arr.push(v%A_Index%)
            }
            v := arr
        }
        Return v
    } finally {
        __g_maybeSetMatchingInfo(old)
    }

}

__g_getId(hwnd) {
    return "ahk_id " hwnd
}

gWin_GetClass(hwnd) {
    WinGetClass, v, % __g_getId(hwnd)
    Return, v
}

gWin_GetText(hwnd) {
    WinGetText, v, % __g_getId(hwnd)
    Return, v
}

gWin_GetTitle(hwnd) {
    WinGetTitle, v, % __g_getId(hwnd)
    Return, v
}

gWin_GetPos(hwnd) {
    WinGetPos, X, Y, Width, Height, % __g_getId(hwnd)
    return {X: X
        ,Y: Y
        ,Width:Width
    ,Height:Height}
}

gWin_Hide(hwnd) {
    WinHide, % __g_getId(hwnd)
}

gWin_Kill(hwnd, SecondsToWait := "") {
    WinKill, % __g_getId(hwnd), , % SecondsToWait
}

gWin_Maximize(hwnd) {
    WinMaximize, % __g_getId(hwnd)
}

gWin_Minimize(hwnd) {
    WinMinimize, % __g_getId(hwnd)
}

gWin_Move(hwnd, X, Y, Width := "", Height := "") {
    WinMove, % __g_getId(hwnd), , % X, % Y, % Width, % Height
}

gWin_Restore(hwnd) {
    WinRestore, % __g_getId(hwnd)
}

gWin_Set(hwnd, SubCommand, Value := "") {
    WinSet, % SubCommand, % Value, % __g_getId(hwnd)
}

gWin_Show(hwnd) {
    WinShow, % __g_getId(hwnd)
}

gWin_Activate(hwnd) {
    WinActivate, % __g_getId(hwnd)
}

gWin_IsActive(hwnd) {
    return !!WinActive(__g_getId(hwnd))
}

gWin_Wait(query, timeout := "") {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWait, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
    } finally {
        __g_maybeSetMatchingInfo(old)
    }

}

gWin_WaitActive(query, active := 1, timeout := "") {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        if (active) {
            WinWaitActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        } else {
            WinWaitNotActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        }
    } finally {
        __g_maybeSetMatchingInfo(old)
    }
}

gWin_WaitClose(query, timeout := "") {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWaitClose, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
    } finally {
        __g_maybeSetMatchingInfo(obj)
    }
    
}

