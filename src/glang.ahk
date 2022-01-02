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
