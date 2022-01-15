#include gfunc.ahk
#Include gstack.ahk

; Returns a slice of elements from `self` that is `start` to `end`.
gArr_Slice(self, start := 1, end := 0) {
    result:=[]
    start:= z__gutils_NormalizeIndex(start, self.MaxIndex())
    end:= z__gutils_NormalizeIndex(end, self.MaxIndex())
    if (end < start) {
        return result
    }
    Loop, % end - start + 1
    {
        result.Insert(self[start + A_Index - 1])
    }
    return result
}

; Returns true if `var` refers to an existing variable.
gLang_VarExists(ByRef var) {
    return &var = &something ? 0 : var = "" ? 2 : 1 
}


z__gutils_NormalizeIndex(negIndex, length) {
    if (negIndex <= 0) {
        return length + negIndex
    }
    return negIndex
}


; Gets a value from an object, possibly deep. If the value is found, the byref out will be modified.
gObj_RawGet(what, key, deep := False, byref found := "") {
    if (z__gutils_getTypeName(what)) {
        found := False
        return ""
    }
    while (IsObject(what)) {
        if (ObjHasKey(what, key)) {
            found := True
            return ObjRawGet(what, key)
        }
        if (!deep) {
            return ""
        }
        what := ObjGetBase(what)
    }
}

gObj_Has(what, key, deep := False) {
    found := False
    gObj_RawGet(what, key, deep, found)
    return found
}

z__gutils_callableWith(what, args*) {
    typeName := z__gutils_getTypeName(value)
    
    if (typeName = "Primitive") {
        gEx_Throw(Format("Tried to call name '{1}', but it was a primitive."))
    }
    if (typeName = "BoundFunc") {
        ; Can't do any checking with BoundFuncs
        return True
    }
    if (typeName != "Func" && typeName != "gSpecFunction") {
        ; Custom objects will also behave in weird ways...
        if (gObj_Has(value, "Call")) {
            return True
        }
        ; But this one doesn't have 'Call'
        gEx_Throw(Format("Tried to call name '{1}', but it was an uncallable object."))
    }
    ; This is a Func then we can do some checks
    if (args.MaxIndex() < value.MinParams) {
        gEx_Throw(Format("Tried to call name '{1}'. It needs at least {2} params, got {3}.", name, value.MinParams, args.MaxIndex()))
    }
    if (args.MaxIndex() > value.MaxParams && !value.IsVariadic) {
        gEx_Throw(Format("Tried to call name '{1}'. It needs at most {2} params, got {3}.", name, value.MaxParams, args.MaxIndex()))
    }
    return True
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
    gEx_ThrowObj(new gOopsError(type, message, innerException, data), ignoreLastInTrace)
}

gEx_ThrowObj(ex, ignoreLastInTrace := 0) {
    if (!IsObject(ex)) {
        gEx_Throw(ex, , , , ignoreLastInTrace + 1) 
        return
    }
    ex.StackTrace := gLang_StackTrace(ignoreLastInTrace + 1)
    ex.What := ex.StackTrace[1].Function
    ex.Offset := ex.StackTrace[1].Offset
    ex.Line := ex.StackTrace[1].Line
    Throw ex
}

; Recursively determines if a is structurally equal to b and has the same
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
        if (ObjGetBase(a) != ObjGetBase(b)) {
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
