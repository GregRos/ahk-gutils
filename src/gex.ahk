#include _common.ahk

#include _common.ahk
#include garr.ahk
#include json.ahk
__g_setupNonObjectCheck() {
    rawBase := "".base
    rawBase.__Get := Func("__g_UnknownGet")
    rawBase.__Set := Func("__g_UnknownSet")
    rawBase.__Call := Func("__g_UnknownCall")
}
global __g_curEx := ""
global __g_vsCodeProcess := ""
__g_setupNonObjectCheck()
__g_UnknownGet(nonobj, name) {
    gEx_Throw(Format("Tried to get property '{1}' from non-object value '{2}',", name, nonobj))
}

__g_UnknownSet(nonobj, name, values*) {
    gEx_Throw(Format("Tried to set property '{1}' on non-object value '{2}'.", name, nonobj))
}

__g_UnknownCall(nonobj, name, args*) {
    gEx_Throw(Format("Tried to call method '{1}' on non-object value '{2}'.", name, nonobj))
}

__g_detectVsCode() {
    ; We need to get the topmost vscode process...
    processInfo := gSys_GetProcessInfo()
    ; Find the outermost code.exe process that's the parent of this process
    Loop {
        last := processInfo
        processInfo := gSys_GetProcessInfo(processInfo.ParentPid)

    } until (!(processInfo && processInfo.Name = "code.exe"))
    __g_vsCodeProcess := last
}

gEx_Print(ex) {
    clone := ex.Clone()
    stackTraceLines := []
    if (ex.StackTrace) {
        for ix, entry in ex.StackTrace {
            stackTraceLines.Push(entry.Function " (" entry.File ":" entry.Line ")")
        }
    }
    clone.StackTrace := stackTraceLines
    return JSON.Dump(clone,,2)
}

__g_ex_gui_clickedList() {
    if (A_GuiEvent = "DoubleClick" && __g_vsCodeProcess.Pid) {
        row := "a"
        row := LV_GetNext()
        if (!row) {
            Return
        }
        stackEntry := __g_curEx.StackTrace[row]
        latestCodeWindow := gWin_Get({title: "ahk_pid " __g_vsCodeProcess.Pid})
        latestCodeWindow.Activate()
        sourceLocation := stackEntry.File
        SendInput, % "^P{Backspace}" stackEntry.File
        Sleep 150
        SendInput, % ":" stackEntry.Line "{Enter}"

    }
}

__g_ex_gui_pressedOk() {
    Gui, __g_errorErrorBox: Cancel

}

__g_ex_gui_copyDetails() {
    Clipboard:=gEx_Print(__g_curEx)
}

__g_openExceptionGuiFor(ex) {
    static imageList := ""
    if (!imageList && __g_vsCodeProcess) {
        imageList := IL_Create()
        Loop, 10
        {
            IL_add(imageList, __g_vsCodeProcess.Path, 1)
        }
    }
    __g_curEx := ex
    Gui, __g_errorErrorBox: New, , An error has occurred!
    Gui, __g_errorErrorBox: +AlwaysOnTop
    Gui, __g_errorErrorBox: Font, S10 CDefault, Verdana

    Gui, __g_errorErrorBox: Add, Text, x12 y9 w240 h20 , An error has occurred in the script:
    Gui, __g_errorErrorBox: Add, Edit, x272 y9 w190 h20 ReadOnly, %A_ScriptName%

    Gui, __g_errorErrorBox: Add, Text, x13 y33 w82 h20 , Error Type:
    Gui, __g_errorErrorBox: Add, Edit, x101 y34 w361 h20 ReadOnly, % ex.Type

    Gui, __g_errorErrorBox: Add, Text, x12 y56 w68 h16 , Message:
    Gui, __g_errorErrorBox: Add, Edit, x11 y76 w453 h103 ReadOnly, % ex.Message

    Gui, __g_errorErrorBox: Add, Text, x11 y183 w180 h18 , Inner Exception Message:

    innerExContent := "(No inner exception)"

    if (IsObject(ex.InnerException)) {
        innerExContent := ex.InnerException.Message
    } else if (ex.InnerException) {
        innerExContent := ex.InnerException
    }
    Gui, __g_errorErrorBox: Add, Edit, x12 y203 w452 h87 ReadOnly, % innerExContent

    Gui, __g_errorErrorBox: Add, Button, x375 y466 w89 h25 g__g_ex_gui_pressedOk Default, OK

    stackTraceLabel:="Stack Trace:"
    if (A_IsCompiled) {
        stackTraceLabel.= " (is compiled)"
    }
    Gui, __g_errorErrorBox: Add, Text, x12 y293 w500 h17 , % stackTraceLabel
    Gui, __g_errorErrorBox: Add, ListView, x12 y313 w453 h146 g__g_ex_gui_clickedList, Pos|Function|File|Ln#|Offset
    Gui, Add, Button, x12 y466 w89 h25 g__g_ex_gui_copyDetails, Copy Details
    if (imageList) {
        LV_SetImageList(imageList)
    }
    for ix, entry in ex.StackTrace {
        SplitPath, % entry.File, filename
        LV_Add("", ix, entry.Function, filename, entry.Line, entry.Offset)
    }
    Loop, 5
    {
        LV_ModifyCol(A_Index, "AutoHdr")
    }
    Gui, __g_errorErrorBox: Show, w477 h505
}

__g_detectVsCode()
OnError(Func("__g_openExceptionGuiFor"))
