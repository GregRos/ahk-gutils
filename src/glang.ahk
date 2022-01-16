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
    found := False
    if (z__gutils_getTypeName(what)) {
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
    ex.trace := gLang_StackTrace(ignoreLastInTrace + 1)
    ex.What := ex.trace[1].Function
    ex.Offset := ex.trace[1].Offset
    ex.Line := ex.trace[1].Line
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

class gObjectSchema {
    New(definitions) {
        self := new gObjectSchema()
        self._definitions := definitions
        return gObj_Checked(self)
    }

    CanGet(name) {
        schema := this._definitions[name]
        if (IsObject(schema)) {
            gEx_throw(Format("Name '{1}'' is a method.", name))
        }
        return gStr_IndexOf(name, "get")
    }

    CanSet(name) {
        schema := this._definitions[name]
        if (IsObject(schema)) {
            gEx_throw(Format("Name '{1}'' is a method.", name))
        }
        return gStr_IndexOf(name, "get")
    }
    
    CanCall(name, args*) {
        
    }
}