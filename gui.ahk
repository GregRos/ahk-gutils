gUi_ISappFullScreen(WinID := "") {
    ;checks if the specified window is full screen
    ;code from NiftyWindows source
    ;(with only slight modification)

    ;use WinExist of another means to get the Unique ID (HWND) of the desired window

    if ( !WinID ) {
        WinGet, WinID, ID, A
    }

    WinGet, WinMinMax, MinMax, ahk_id %WinID%
    WinGetPos, WinX, WinY, WinW, WinH, ahk_id %WinID%

    if (WinMinMax = 0) && (WinX = 0) && (WinY = 0) && (WinW = A_ScreenWidth) && (WinH = A_ScreenHeight) {
        WinGetClass, WinClass, ahk_id %WinID%
        WinGet, WinProcessName, ProcessName, ahk_id %WinID%
        SplitPath, WinProcessName, , , WinProcessExt

        if (WinClass != "Progman") && (WinProcessExt != "scr") {
            ;program is full-screen
            return true
        }
    }
    return false
}

gSys_IsMouseCursorVisible() {
    StructSize := A_PtrSize + 16
    VarSetCapacity(InfoStruct, StructSize)
    NumPut(StructSize, InfoStruct)
    DllCall("GetCursorInfo", UInt, &InfoStruct)
    Result := NumGet(InfoStruct, 8)
    return Result > 1
}