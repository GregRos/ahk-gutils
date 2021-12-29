
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