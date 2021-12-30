
gLang_VarExists(ByRef var) {
    return &var = &something ? 0 : var = "" ? 2 : 1 
}
__g_builtInNames:=["_NewEnum", "methods", "HasKey", "_ahkUtilsDisableVerification", "Clone", "GetAddress", "SetCapacity", "GetCapacity", "MinIndex", "MaxIndex", "Length", "Delete", "Push", "Pop", "InsertAt", "RemoveAt", "base", "__Set", "__Get", "__Call", "__New", "__Init", "_ahkUtilsIsInitialized"]

gLang_IsNameBuiltIn(name) {
    global __g_builtInNames
    return gArr_IndexOf(__g_builtInNames, name)
}

gLang_NormFunc(funcOrName) {
    if (IsObject(funcOrName)) {
        return funcOrName
    }
    result := Func(funcOrName)
    return result
}

gLang_Call(funcOrName, args*) {
    funcOrName := gLang_NormFunc(funcOrName)
    if (funcOrName.MinParams > args.MaxIndex()) {
        Throw "Passed too few parameters for function."
    }
    maxParams := funcOrName.MaxParams
    if (maxParams < args.MaxIndex()) {
        args := gArr_Take(args, maxParams)
    }
    return funcOrName.Call(args*)
}

; Represents an entry in a stack trace.
class StackTraceEntry {
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
