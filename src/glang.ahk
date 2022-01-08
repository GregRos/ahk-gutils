
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

z__gutils_isArray(what) {
    return IsObject(what) && what.MaxIndex() != ""
}

; Returns true if `var` refers to an existing variable.
gLang_VarExists(ByRef var) {
    return &var = &something ? 0 : var = "" ? 2 : 1 
}

gLang_InstanceOf(self, proto) {
    Loop 
    {
        if (self.base == proto) {
            return True
        }
        self := self.base
    } until !self.base
}


; Normalizes function names and objects.
gLang_Func(funcOrName) {
    if (IsObject(funcOrName)) {
        return funcOrName
    }
    result := Func(funcOrName)
    if (!result) {
        gEx_Throw("Name '" funcOrName "' wasn't a known function.")
    }
    return result
}

; Calls `funcOrName` with the arguments `args`. Will also call functions that need fewer arguments.
gLang_Call(funcOrName, args*) {
    funcOrName := gLang_Func(funcOrName)
    if (gLang_Is(funcOrName, "BoundFunc")) {
        return funcOrName.Call(args*)
    }
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

    ToString() {
        x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
        return x
    }
}

z__gutils_printStack(frames) {
    text := ""
    for i, frame in frames {
        if (i != 1) {
            text .= "`r`n"
        }
        text .= frame.ToString()
    }
}

z__gutils_entryToString(e) {
    x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
    return x
}

; Returns a textual stack trace.
gLang_StackTrace(ignoreLast := 0) {
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
        frames.RemoveAt(1, 1)
    }
    return frames
}
;https://autohotkey.com/boards/viewtopic.php?p=156419#p156419

; See the classic AHK is operator, but with extra supported predicates: 
; Func, BoundFunc, Object, Array, File, Enum, Primitive, or CLASS NAME.
gLang_Is(self, type) {
    static BoundFuncP := NumGet(&(_ := Func("gLang_Is").Bind()), "Ptr")
    static FileP := NumGet(&(_ := FileOpen("*", "r")), "Ptr")
    static EnumP := NumGet(&(_ := ObjNewEnum({})), "Ptr")
    if (type = "func") {
        return IsObject(self) && IsFunc(self)
    }
    if (type = "BoundFunc") {
        return NumGet(&self, "Ptr") == BoundFuncP
    }
    if (type = "Object") {
        return IsObject(self)
    }
    if (type = "primitive") {
        return !IsObject(self)
    }
    if (type = "array") {
        return IsObject(self) && self.MaxIndex() != ""
    }
    if (type = "file") {
        ; Only system objects can hae 
        return IsObject(self) && NumGet(&self, "Ptr") == FileP
    }
    if (type = "enum") {
        return IsObject(self) && NumGet(&self, "Ptr") == EnumP
    }
    if (IsObject(self)) {
        return self.__Class = type
    }
    if self is %type%
    {
        Return true
    }
}

z__gutils_NormalizeIndex(negIndex, length) {
    if (negIndex <= 0) {
        return length + negIndex
    }
    return negIndex
}

z_gutils_ToBool(value) {
    if (!value || value = "off" || value = "False" || ) {
        return False
    }
    if (value = True || value = "on") {
        return True
    }
    return !!value
}

; Parses a value as a boolean. `type` determines how to return it. Three modes - OnOff, TrueFalse, TrueFalseString.
gLang_Bool(bool, type := "TrueFalse") {
    trueBool := z_gutils_ToBool(bool)
    if (type = "TrueFalse" || !type) {
        return trueBool
    }
    if (type = "OnOff") {
        return trueBool ? "On" : "Off"
    }
    if (type = "TrueFalseString") {
        return trueBool ? "False" : "True"
    }
    gEx_Throw("Unknown normalization type " type)
}

; 0 - not a built-in name. 1 - built-in object name. 2 - meta function or other special member.
gLang_IsSpecialName(name) {
    static builtInNames := {__Call: 2, base : 2
        , __get: 2, __set: 2
        ,__new: 2, __gutils_noVerification: 2
        , __init: 2, __class: 2
        ,_NewEnum: 1, HasKey: 1
        ,Clone: 1, GetAddress: 1
        ,SetCapacity: 1, GetCapacity: 1
        ,MinIndex: 1, MaxIndex: 1
        ,Length: 1, Delete: 1
        ,Push: 1, Pop: 1
        ,InsertAt: 1,RemoveAt: 1
    ,Insert: 1, Remove: 1}

    return builtInNames.HasKey(name) ? builtInNames[name] : 0
}

; Utility class with name verification services.
; Inherit from this if you want your class to only have declared members (methods, properties, and fields assigned in the initializer), so that unrecognized keys will result in an error.
; The class implements __Get, __Call, and __Set.
class gDeclaredMembersOnly {

    __Call(name, params*) {
        if (!gLang_IsSpecialName(name) && !ObjRawGet(this, "__gutils_noVerification")) {
            gEx_Throw("Tried to call undeclared method '" name "'.")
        } 
    }

    __New() {

    }

    __Init() {
        ; We want to disable name verification to allow the extending object's initializer to safely initialize the type's fields.
        if (ObjRawGet(this, "__gutils_noVerification")) {
            return
        }
        ObjRawSet(this, "__gutils_memberVerification", true)
        ObjRawSet(this, "__gutils_noVerification", true)

        this.__Init()
        this.Delete("__gutils_noVerification")

    }

    __Get(name) {
        if (!gLang_IsSpecialName(name) && !ObjRawGet(this, "__gutils_noVerification")) {
            gEx_Throw("Tried to get the value of undeclared member '" name "'.")
        }
    }

    __Set(name, values*) {
        if (!gLang_IsSpecialName(name) && !ObjRawGet(this, "__gutils_noVerification")) {
            gEx_Throw("Tried to set the value of undeclared member '" name "'.")
        }
    }

    __DisableVerification() {
        ObjRawSet(this, "__gutils_noVerification", true)
    }

    __EnableVerification() {
        this.Delete("__gutils_noVerification")
    }

    __IsVerifying {
        get {
            return !ObjRawGet(this, "__gutils_noVerification")
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

; Recursively determines if a is structurally equal to b.
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

z__gutils_assertArray(obj) {
    if (!gArr_Is(obj)) {
        gEx_Throw("Input must be an array. Was: " obj)
    }
}

z__gutils__assertNotObject(objs*) {
    for i, obj in objs {
        if (IsObject(obj)) {
            gEx_Throw("Input expected not to be an object: " obj)
        }
    }
}

class gFuncList extends gDeclaredMembersOnly {

    __New(inner) {
        this._inner := inner
    }

    Call(args*) {
        arr := []
        for i, f in this._inner {
            arr.Push(f.Call(args*))
        }
        return arr
    }

}

gLang_FuncList(funcs*) {
    return new gFuncList(funcs)
}