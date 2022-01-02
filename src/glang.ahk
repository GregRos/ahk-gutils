gArr_Slice(arr, start := 1, end := 0) {
    result:=[]
    start:= z__gutils_NormalizeIndex(start, arr.MaxIndex())
    end:= z__gutils_NormalizeIndex(end, arr.MaxIndex())
    if (end < start) {
        return result
    }
    Loop, % end - start + 1
    {
        result.Insert(arr[start + A_Index - 1])
    }
    return result
}

gLang_VarExists(ByRef var) {
    return &var = &something ? 0 : var = "" ? 2 : 1 
}

gLang_Func(funcOrName) {
    if (IsObject(funcOrName)) {
        return funcOrName
    }
    result := Func(funcOrName)
    if (!result) {
        gEx_Throw("Name wasn't a known function.")
    }
    return result
}

gLang_Call(funcOrName, args*) {
    funcOrName := gLang_Func(funcOrName)
    if (funcOrName.MinParams > args.MaxIndex()) {
        gEx_Throw("Passed too few parameters for function.")
    }
    maxParams := funcOrName.MaxParams
    if (maxParams < args.MaxIndex()) {

        args := gArr_Slice(args, maxParams)
    }
    return funcOrName.Call(args*)
}

; Represents an entry in a stack trace.
class gStackFrame extends gDeclaredMembersOnly {
    File := ""
    Line := ""
    Function := ""
    Offset := ""
    __New(file, line, function, offset) {
        this.File := File
        this.Line := line
        this.Function := function
        this.Offset := offset
    }
}

z__gutils_entryToString(e) {
    x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
    return x
}

gLang_StackTrace(ignoreLast := 0) {
    obj := gLang_StackTraceObj(ignoreLast)
    stringify := gArr_Map(obj, "z__gutils_entryToString")
    return gStr_Join(stringify, "`n")
}

gLang_Is(ByRef what, type) {
    if what is %type%
        Return true
}

z__gutils_NormalizeIndex(negIndex, length) {
    if (negIndex <= 0) {
        return length + negIndex
    }
    return negIndex
}

gLang_Bool(bool, type := "TrueFalse") {
    if (type = "TrueFalse" || type = "") {
        if (bool = "Off") {
            return False
        }
        if (bool = "On") {
            return True
        }
        if (bool = 0) {
            return False
        }
        return bool ? True : False
    }
    result := gLang_Bool(bool, "TrueFalse")
    if (type = "OnOff") {
        out := result ? "On" : "Off"
        return out
    }
}

gLang_IsNameBuiltIn(name) {
    static z__gutils_builtInNames
    if (!z__gutils_builtInNames) {
        z__gutils_builtInNames:=["_NewEnum", "methods", "HasKey", "z__gutils_noVerification", "Clone", "GetAddress", "SetCapacity", "GetCapacity", "MinIndex", "MaxIndex", "Length", "Delete", "Push", "Pop", "InsertAt", "RemoveAt", "base", "__Set", "__Get", "__Call", "__New", "__Init", "_ahkUtilsIsInitialized"]
    }
    for i, x in z__gutils_builtInNames {
        if (x = name) {
            return True
        }
    }
    return False
}

; Base class that provides member name verification services.
; Basically, inherit from this if you want your class to only have declared members (methods, properties, and fields assigned in the initializer), so that unrecognized keys will result in an error.
; The class implements __Get, __Call, and __Set.
class gDeclaredMembersOnly {
    __Call(name, params*) {
        if (!gLang_IsNameBuiltIn(name) && !this.z__gutils_noVerification) {
            gEx_Throw("Tried to call undeclared method '" name "'.")
        } 
    }

    __New() {

    }

    __Init() {
        ; We want to disable name verification to allow the extending object's initializer to safely initialize the type's fields.
        if (this.z__gutils_noVerification) {
            return
        }
        this.z__gutils_noVerification := true

        this.__Init()
        this.Delete("z__gutils_noVerification")
    }

    __Get(name) {
        if (!gLang_IsNameBuiltIn(name) && !this.z__gutils_noVerification) {
            gEx_Throw("Tried to get the value of undeclared member '" name "'.")
        }
    }

    __Set(name, values*) {
        if (!gLang_IsNameBuiltIn(name) && !this.z__gutils_noVerification) {
            gEx_Throw("Tried to set the value of undeclared member '" name "'.")
        }
    }

    __DisableVerification() {
        ObjRawSet(this, "z__gutils_noVerification", true)
    }

    __EnableVerification() {
        this.Delete("z__gutils_noVerification")
    }

    __IsVerifying {
        get {
            return !this.HasKey("z__gutils_noVerification")
        }
    }

    __RawGet(name) {
        this.__DisableVerification()
        value := this[name]
        this.__EnableVerification()
        return value
    }
}

class gOopsError {
    type := ""
    message := ""
    innerEx := ""
    data := ""
    trace := []
    what := ""
    offset := ""
    function := ""
    line := ""
    __New(type, message, innerEx := "", extra := "") {
        this.Message := message
        this.InnerException := innerEx
        this.Extra := extra
        this.Type := type

    }
}

; Constructs a new exception with the specified arguments, and throws it. 
; ignoreLastInTrace - don't show the last N callers in the stack trace. Note that FancyEx methods don't appear.
gEx_Throw(message := "An exception has been thrown.", innerException := "", type := "Unspecified", data := "", ignoreLastInTrace := 0) {
    gEx_ThrowObj(new gOopsError(type, message, innerException, data), ignoreLastInTrace + 1)
}

gEx_ThrowObj(ex, ignoreLastInTrace := 0) {
    if (!IsObject(ex)) {
        gEx_Throw(ex, , , , ignoreLastInTrace + 1) 
        return
    }
    ex.StackTrace := gLang_StackTraceObj(ignoreLastInTrace + 1)
    ex.What := ex.StackTrace[1].Function
    ex.Offset := ex.StackTrace[1].Offset
    ex.Line := ex.StackTrace[1].Line
    Throw ex
}

gLang_StackTraceObj(ignoreLast := 0) {
    ; Originally by Coco in http://ahkscript.org/boards/viewtopic.php?f=6&t=6001
    frames := []
    Loop
    {
        offset := -A_Index + 1
        e := Exception(".", offset)
        if (e.What == offset && offset != 0) {
            break
        }
        frames.Push(new gStackFrame(e.File, e.Line, e.What, offset))
    }
    ; In this state, the File:Line refer to the place where execution entered What.
    ; That's actually not very useful. I want it to have What's location instead. So we nbeed
    ; to shuffle things a bit

    for i in frames {
        if (i >= frames.MaxIndex()) {
            break
        }
        frames[i].Function := frames[i+1].Function
    }
    Loop, % ignoreLast + 1
    {
        frames.RemoveAt(1)
    }
    return frames
}

gOut(out) {
    OutputDebug, % gStr(Out)
}

gLang_Equal(a, b, case := False) {
    if (!case && a = b) {
        return True
    }
    if (case && a == b) {
        return True
    }
    if (IsObject(a)) {
        if (!IsObject(b)) {
            return False
        }
        if (a.Count() != b.Count()) {
            return False
        }
        for k, v in a {
            if (!gLang_Equal(v, b[k], case)) {
                return False
            }
        }
        return True
    }
    return False
}