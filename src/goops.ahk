#include glang.ahk
#include garr.ahk
#include json.ahk

global z__gutils__nonObjectBase := "".base
z__gutils_setupNonObjectCheck() {
    rawBase := "".base
    rawBase.__Get := Func("z__gutils_UnknownGet")
    rawBase.__Set := Func("z__gutils_UnknownSet")
    rawBase.__Call := Func("z__gutils_UnknownCall")
}
global z__gutils_currentError := ""
global z__gutils_vsCodeProcess := ""

z__gutils_UnknownGet(nonobj, name) {
    if (name == "base" || name == "__Call") {
        return z__gutils__nonObjectBase
    }
    gEx_Throw(Format("Tried to get property '{1}' from non-object value '{2}',", name, nonobj))
}

z__gutils_UnknownSet(nonobj, name, values*) {
    gEx_Throw(Format("Tried to set property '{1}' on non-object value '{2}'.", name, nonobj))
}

z__gutils_UnknownCall(nonobj, name, args*) {
    gEx_Throw(Format("Tried to call method '{1}' on non-object value '{2}'.", name, nonobj))
}

z__gutils_detectVsCode() {
    ; We need to get the topmost vscode process...
    processInfo := gSys_GetProcessInfo()
    ; Find the outermost code.exe process that's the parent of this process
    Loop {
        last := processInfo
        processInfo := gSys_GetProcessInfo(processInfo.ParentPid)

    } until (!(processInfo && processInfo.Name = "code.exe"))
    z__gutils_vsCodeProcess := last
}

gEx_Print(ex) {
    clone := ex.Clone()
    stackTraceLines := []
    if (ex.trace) {
        for ix, entry in ex.trace {
            stackTraceLines.Push(entry.Function " (" entry.File ":" entry.Line ")")
        }
    }
    clone.trace := stackTraceLines
    return JSON.Dump(clone,,2)
}

z__gutils_ex_gui_clickedList() {

    if (A_GuiEvent = "DoubleClick" && z__gutils_vsCodeProcess.Pid) {
        try {
            Gui, z__gutils_errorBox: +Disabled
            row := "a"
            row := LV_GetNext()
            if (!row) {
                Return
            }
            stackEntry := z__gutils_currentError.trace[row]
            latestCodeWindow := gWin_Get({title: "ahk_pid " z__gutils_vsCodeProcess.Pid})
            latestCodeWindow.Activate()
            sourceLocation := stackEntry.File
            SendInput, % "^P{Backspace}" stackEntry.File
            Sleep 150
            SendInput, % ":" stackEntry.Line "{Enter}"
        } finally {
            Gui, z__gutils_errorBox: -Disabled

        }
    }
}

z__gutils_ex_gui_pressedOk() {
    Gui, z__gutils_errorBox: Cancel

}

z__gutils_ex_gui_copyDetails() {
    Clipboard:=gEx_Print(z__gutils_currentError)
}

z__gutils_errorBoxOnClose() {
    z__gutils_currentError := ""
}

z__gutils_openExceptionGuiFor(ex) {

    try {
        if (z__gutils_currentError) {
            return
        }
        z__gutils_currentError := ex
        static imageList := ""
        if (!IsObject(ex) || ObjGetBase(ex) !== gOopsError) {
            return
        }
        if (!imageList && z__gutils_vsCodeProcess) {
            imageList := IL_Create()
            Loop, 10
            {
                IL_add(imageList, z__gutils_vsCodeProcess.Path, 1)
            }
        }
        Gui, z__gutils_errorBox: New, , An error has occurred!
        Gui, z__gutils_errorBox: +AlwaysOnTop
        Gui, z__gutils_errorBox: Font, S10 CDefault, Verdana
        Gui, z__gutils_errorBox: Add, Text, x12 y9 w240 h20 , An error has occurred in the script:
        Gui, z__gutils_errorBox: Add, Edit, x272 y9 w190 h20 ReadOnly, %A_ScriptName%

        Gui, z__gutils_errorBox: Add, Text, x13 y33 w82 h20 , Error Type:
        Gui, z__gutils_errorBox: Add, Edit, x101 y34 w361 h20 ReadOnly, % ex.Type

        Gui, z__gutils_errorBox: Add, Text, x12 y56 w68 h16 , Message:
        Gui, z__gutils_errorBox: Add, Edit, x11 y76 w453 h103 ReadOnly, % ex.Message

        Gui, z__gutils_errorBox: Add, Text, x11 y183 w180 h18 , Inner Exception Message:

        innerExContent := "(No inner exception)"

        if (IsObject(ex.InnerException)) {
            innerExContent := ex.InnerException.Message
        } else if (ex.InnerException) {
            innerExContent := ex.InnerException
        }
        Gui, z__gutils_errorBox: Add, Edit, x12 y203 w452 h87 ReadOnly, % innerExContent
        Gui, z__gutils_errorBox: Add, Button, x375 y466 w89 h25 gz__gutils_ex_gui_pressedOk Default, OK

        stackTraceLabel:="Stack Trace:"
        if (A_IsCompiled) {
            stackTraceLabel.= " (is compiled)"
        }
        Gui, z__gutils_errorBox: Add, Text, x12 y293 w500 h17 , % stackTraceLabel
        Gui, z__gutils_errorBox: Add, ListView, x12 y313 w453 h146 gz__gutils_ex_gui_clickedList, Pos|Function|File|Ln#|Offset
        Gui, Add, Button, x12 y466 w89 h25 gz__gutils_ex_gui_copyDetails, Copy Details
        if (imageList) {
            LV_SetImageList(imageList)
        }
        for ix, entry in ex.trace {
            SplitPath, % entry.File, filename
            LV_Add("", ix, entry.Function, filename, entry.Line, entry.Offset)
        }
        Loop, 5
        {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
        Gui, z__gutils_errorBox: Show, w477 h505
    } catch ex {
        Gui, z__gutils_errorBox: Destroy
        z__gutils_currentError := ""
        throw ex
    }
}

global z__gutils_oopsSetup := False

gOops_Setup() {
    if (z__gutils_oopsSetup) {
        return
    }
    z__gutils_oopsSetup := True
    z__gutils_setupNonObjectCheck()
    z__gutils_detectVsCode()
    OnError(Func("z__gutils_openExceptionGuiFor"))
}