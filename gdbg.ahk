#include _common.ahk
#include garr.ahk

__g_setupNonObjectCheck() {
    rawBase := "".base
    rawBase.__Get := Func("__g_UnknownGet")
    rawBase.__Set := Func("__g_UnknownSet")
    rawBase.__Call := Func("__g_UnknownCall")
}

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

gEx_Print(ex) {
    msg:=ex.Message, type:=ex.Type
    type:=type ? type : "Generic"
    msg:= gStr_Indent(msg, "`t", 1)
    stackTrace:=""
    if (ex.StackTrace) {
        for ix, entry in ex.StackTrace
        {
            stackTrace.="� " entry.Function " [" entry.File " ln#" entry.Line "]" "`r`n"
        }
    }
    else {
        stackTrace:="Unknown"
    }
    stackTrace:=gStr_Indent(stackTrace, "`t", 1)
    data:=""
    if (IsObject(ex.Data)) {
        if (ex.Data.Length() > 0) {
            for key, value in ex.Data
            {
                data.="� " key " = """ value """`r`n"
            }
        }
        else {
            data:="None"
        }
    } else if (ex.Data) {
        data:=ex.Data
    } else {
        data:="None"
    }
    data:=gStr_Indent(data, "`t", 1)
    props:=""
    for key, value in ex
    {
        if (key = "StackTrace" || key = "Data" || key = "InnerException" || key = "Message" || key = "Type") {
            continue
        }
        props.="� " key " = """ value """`r`n"
    }
    props:=gStr_Indent(props, "`t", 1)
    innerEx:=""
    if (IsObject(ex.InnerException)) {
        innerEx:=gEx_Print(ex.InnerException)
    } else if (ex.InnerException) {
        innerEx:=ex.InnerException
    } else {
        innerEx:="None"
    }
    innerEx:=gStr_Indent(innerEx, "`t", 1)

    text=
    (
        Type: %type%
        Message: 
            %msg%
        Stack Trace:
            %stackTrace%
        Additional Data:
            %data%
        Other Properties:
            %props%
        Inner Exception:
            %innerEx%
        )
        return text
    }

    global __g_curEx := ""
    global __g_isRunningInVsCode := ""

    __g_FancyExListEvent() {
        if (A_GuiEvent = "DoubleClick" && __g_isRunningInVsCode) {
            row := "a"
            row := LV_GetNext()
            if (!row) {
                Return
            }
            stackEntry := __g_curEx.StackTrace[row]
            fname := stackEntry.filename
            latestCodeWindow := gWin_Get({title: "Visual Studio Code", mode: 2})
            latestCodeWindow.Activate()
            Sleep 10
            sourceLocation := Format("{1}:{2}", stackEntry.File, stackEntry.Line)
            SendInput, {LCtrl down}P{LCtrl up}{Backspace}%sourceLocation%{Enter}

        }
    }

    __g_ex_gui_pressedOk() {
        Gui, FancyEx_ErrorBox: Cancel
        
    }

    __g_ex_gui_copyDetails() {
        Clipboard:=gEx_Print(__g_curEx)
    }

    __g_openExceptionGuiFor(ex) {
        __g_curEx := ex
        Gui, __g_errorErrorBox: New, , An error has occurred!
        Gui, FancyEx_ErrorBox: +AlwaysOnTop
        Gui, FancyEx_ErrorBox: Font, S10 CDefault, Verdana

        Gui, FancyEx_ErrorBox: Add, Text, x12 y9 w240 h20 , An error has occurred in the script:
        Gui, FancyEx_ErrorBox: Add, Edit, x272 y9 w190 h20 ReadOnly, %A_ScriptName%

        Gui, FancyEx_ErrorBox: Add, Text, x13 y33 w82 h20 , Error Type:
        Gui, FancyEx_ErrorBox: Add, Edit, x101 y34 w361 h20 ReadOnly, % ex.Type

        Gui, FancyEx_ErrorBox: Add, Text, x12 y56 w68 h16 , Message:
        Gui, FancyEx_ErrorBox: Add, Edit, x11 y76 w453 h103 ReadOnly, % ex.Message

        Gui, FancyEx_ErrorBox: Add, Text, x11 y183 w180 h18 , Inner Exception Message:

        innerExContent := "(No inner exception)"

        if (IsObject(ex.InnerException)) {
            innerExContent := ex.InnerException.Message
        } else if (ex.InnerException) {
            innerExContent := ex.InnerException
        }
        Gui, FancyEx_ErrorBox: Add, Edit, x12 y203 w452 h87 ReadOnly, % innerExContent

        Gui, FancyEx_ErrorBox: Add, Button, x375 y466 w89 h25 g__g_ex_gui_pressedOk Default, OK

        stackTraceLabel:="Stack Trace:"
        if (A_IsCompiled) {
            stackTraceLabel.= " (is compiled)"
        }
        Gui, FancyEx_ErrorBox: Add, Text, x12 y293 w500 h17 , % stackTraceLabel
        Gui, FancyEx_ErrorBox: Add, ListView, x12 y313 w453 h146 g__g_FancyExListEvent, Pos|Function|File|Ln#|Offset
        Gui, Add, Button, x12 y466 w89 h25 g__g_ex_gui_copyDetails, Copy Details

        for ix, entry in ex.StackTrace {
            SplitPath, % entry.File, filename
            LV_Add("", ix, entry.Function, filename, entry.Line, entry.Offset)
        }
        Loop, 5
        {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
        Gui, FancyEx_ErrorBox: Show, w477 h505

        FancyEx_CopyDetails:

        return
        FancyEx_ListEvent:
        }

        OnError(Func("__g_openExceptionGuiFor"))
