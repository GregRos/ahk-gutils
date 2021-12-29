; Class primarily for reference, demonstrating the fields FancyEx supports/cares about for exceptions.
; The Extra field is used internally and you shouldn't use it.
; Any additional fields are also printed, using 
class FancyException {
    __New(type, message, innerEx := "", data := "") {
        this.Message := message
        this.InnerException := innerEx
        this.Data := data
        this.Type := type
    }
}

; Constructs a new exception with the specified arguments, and throws it. 
; ignoreLastInTrace - don't show the last N callers in the stack trace. Note that FancyEx methods don't appear.
gEx_Throw(message := "An exception has been thrown.", innerException := "", type := "Unspecified", data := "", ignoreLastInTrace := 0) {
    gEx_ThrowObj(new FancyException(type, message, innerException, data), ignoreLastInTrace + 1)
}

gEx_ThrowObj(ex, ignoreLastInTrace := 0) {
    if (!IsObject(ex)) {
        gEx_Throw(ex, , , , ignoreLastInTrace + 1) 
        return
    }
    ex.StackTrace := gLang_StackTrace(ignoreLastInTrace + 1)
    ex.What := ex.StackTrace[1].Function
    ex.Offset := ex.StackTrace[1].Offset
    ; We're planting a GUID inside the exception to identify its unhandled exception message box later on.
    ex.InstanceGuid := gSys_GetGuid()
    ex.Line := ex.StackTrace[1].Line
    Throw ex
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

    __g_openExceptionGuiFor(ex) {
        Gui, FancyEx_ErrorBox: New, , An error has occurred!
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

        Gui, FancyEx_ErrorBox: Add, Button, x375 y466 w89 h25 gFancyEx_PressedOk Default, OK

        stackTraceLabel:="Stack Trace:"
        if (A_IsCompiled) {
            stackTraceLabel.= " (is compiled)"
        }
        Gui, FancyEx_ErrorBox: Add, Text, x12 y293 w500 h17 , % stackTraceLabel
        Gui, FancyEx_ErrorBox: Add, ListView, x12 y313 w453 h146 , Pos|Function|File|Ln#|Offset
        Gui, Add, Button, x12 y466 w89 h25 gFancyEx_CopyDetails, Copy Details

        for ix, entry in ex.StackTrace {
            SplitPath, % entry.File, filename
            LV_Add("", ix, entry.Function, filename, entry.Line, entry.Offset)
        }
        Loop, 5
        {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
        Gui, FancyEx_ErrorBox: Show, w477 h505

        return
        FancyEx_ErrorBoxGuiClose:
        FancyEx_PressedOk:
            Gui, FancyEx_ErrorBox: Cancel
        return
        FancyEx_CopyDetails:
            Clipboard:=gEx_Print(ex)
        return
    }

    gEx_FancyInit() {
        OnError(__g_openExceptionGuiFor)
    }
