gArr_Slice(arr, start := 1, end := 0) {
    result:=[]
    start:= __g_NormalizeIndex(start, arr.MaxIndex())
    end:= __g_NormalizeIndex(end, arr.MaxIndex())
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
        Throw "Passed too few parameters for function."
    }
    maxParams := funcOrName.MaxParams
    if (maxParams < args.MaxIndex()) {

        args := gArr_Slice(args, maxParams)
    }
    return funcOrName.Call(args*)
}

; Represents an entry in a stack trace.
class StackTraceEntry extends gDeclaredMembersOnly {
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

__g_entryToString(e) {
    x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
    return x
}

gLang_StackTrace(ignoreLast := 0) {
    obj := gLang_StackTraceObj(ignoreLast)
    stringify := gArr_Map(obj, "__g_entryToString")
    return gStr_Join(stringify, "`n")
}

gLang_Is(ByRef what, type) {
    if what is %type%
        Return true
}

__g_NormalizeIndex(negIndex, length) {
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
    static __g_builtInNames
    if (!__g_builtInNames) {
        __g_builtInNames:=["_NewEnum", "methods", "HasKey", "__g_noVerification", "Clone", "GetAddress", "SetCapacity", "GetCapacity", "MinIndex", "MaxIndex", "Length", "Delete", "Push", "Pop", "InsertAt", "RemoveAt", "base", "__Set", "__Get", "__Call", "__New", "__Init", "_ahkUtilsIsInitialized"]
    }
    for i, x in __g_builtInNames {
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
        if (!gLang_IsNameBuiltIn(name) && !this.__g_noVerification) {
            gEx_Throw("Tried to call undeclared method '" name "'.")
        } 
    }

    __New() {

    }

    __Init() {
        ; We want to disable name verification to allow the extending object's initializer to safely initialize the type's fields.
        if (this.__g_noVerification) {
            return
        }
        this.__g_noVerification := true

        this.__Init()
        this.Delete("__g_noVerification")
    }

    __Get(name) {
        if (!gLang_IsNameBuiltIn(name) && !this.__g_noVerification) {
            gEx_Throw("Tried to get the value of undeclared member '" name "'.")
        }
    }

    __Set(name, values*) {
        if (!gLang_IsNameBuiltIn(name) && !this.__g_noVerification) {
            gEx_Throw("Tried to set the value of undeclared member '" name "'.")
        }
    }

    __DisableVerification() {
        ObjRawSet(this, "__g_noVerification", true)
    }

    __EnableVerification() {
        this.Delete("__g_noVerification")
    }

    __IsVerifying {
        get {
            return !this.HasKey("__g_noVerification")
        }
    }

    __RawGet(name) {
        this.__DisableVerification()
        value := this[name]
        this.__EnableVerification()
        return value
    }

}

; Class primarily for reference, demonstrating the fields FancyEx supports/cares about for exceptions.
; The Extra field is used internally and you shouldn't use it.
; Any additional fields are also printed, using 
class gOopsError {
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
    ; from Coco in http://ahkscript.org/boards/viewtopic.php?f=6&t=6001
    r := [], i := 0, n := 0
    Loop
    {
        e := Exception(".", offset := -(A_Index + n))
        if (e.What == offset)
            break
        r[++i] := new StackTraceEntry(e.File, e.Line, e.What, offset + n)
    }
    lastEntry:= r[1]
    if (!lastEntry) return []
    for ix, entry in r {
        ; I want each entry to contain the *exit location*, not entry location, so it corresponds to part of the function.
        if (ix = 1) {
            continue	
        }
        tmp := lastEntry
        lastEntry := entry.Clone()
        entry.File := tmp.File
        entry.Line := tmp.Line
        entry.Offset := tmp.Offset
    }

    r.Insert(new StackTraceEntry(lastEntry.File, lastEntry.Line, " ", lastEntry.Offset))

    Loop, % ignoreLast + 1
    {
        r.Remove(1)
    }

    return r
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