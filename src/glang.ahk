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
    if (gType_Is(funcOrName, "BoundFunc")) {
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
class gStackFrame {

    ToString() {
        x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
        return x
    }

    New(file, line, function, offset) {
        frame := new gStackFrame()
        frame.File := file
        frame.Line := line
        frame.Function := function
        frame.Offset := offset
        return gLang_SmartProxy(frame)
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
        frames.Push(gStackFrame.New(e.File, e.Line, e.What, offset))
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

z__gutils_NormalizeIndex(negIndex, length) {
    if (negIndex <= 0) {
        return length + negIndex + 1
    }
    return negIndex
}

z__gutils_ToBool(value) {
    if (!value || value = "off" || value = "False" || ) {
        return False
    }
    if (value = True || value = "on") {
        return True
    }
    return !!value
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

; Parses a value as a boolean. `type` determines how to return it. Three modes - OnOff, TrueFalse, TrueFalseString.
gLang_Bool(bool, type := "TrueFalse") {
    trueBool := z__gutils_ToBool(bool)
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

z__gutils_callableWith(what, args*) {
    typeName := z__gutils_getTypeName(value)
    if (typeName = "Primitive") {
        gEx_Throw(Format("Tried to call name '{1}', but it was a primitive."))
    }
    if (typeName = "BoundFunc") {
        ; Can't do any checking with BoundFuncs
        return True
    }
    if (typeName != "Func") {
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

; 0 - not a built-in name. 1 - built-in object name. 2 - meta function or other special member.
gType_IsSpecialName(name) {
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

class gMemberCheckingProxy {
    _target := ""
    _state := 0
    __New(target) {
        if (!target) {
            gEx_Throw(Format("Error - target is empty: '{1}'.", target))
        }
        tn := z__gutils_getTypeName(target)
        if (tn != "") {
            gEx_Throw(Format("Can't create a proxy for '{1}', it's a built-in object.", tn))
        }
        this._target := target
        this._checking := True
    }

    __Call(name, args*) {
        target := ObjRawGet(this, "_target")
        checking := ObjRawGet(this, "_checking")
        if (!checking || gType_IsSpecialName(name)) {
            return target[name].Call(target, args*)
        }
        if (target.__Call) {
            return target.__Call.Call(target, name, args*)
        }
        if (gType_IsSpecialName(name)) {
            ; Can't do checking for special names without hardcoding them
            return target[name].Call(target, args*)
        }
        value := gObj_RawGet(target, name, True, found)
        if (!found) {
            gEX_Throw(Format("Tried to call name '{1}', but it doesn't exist.", name))
        }
        z__gutils_callableWith(value, args*)
        return value.Call(target, args*)
    }

    __Set(name, args*) {
        value := args.Pop()
        keys := args
        target := ObjRawGet(this, "_target")
        if (!target) {
            return ObjRawSet(this, name, value)
        }
        checking := ObjRawGet(this, "_checking")
        if (target.__Set) {
            args.Push(value)
            return target.__Set.Call(target, name, args*)
        }
        if (!checking || gType_IsSpecialName(name)) {
            return target[name, keys*] := value
        }
        property := gObj_RawGet(target, name, True, found)
        if (!found) {
            gEx_Throw(Format("Tried to set name '{1}', but it wasn't defined.", name))
        }
        if (gType_Is(property, "Property") && !property.set) {
            gEx_Throw(Format("Tried to set name '{1}', but it was a property with no setter."))
        }
        ; It's defined and settable
        target[name, keys*] := value
        return value
    }

    __Get(name, keys*) {
        target := ObjRawGet(this, "_target")
        if (!target) {
            return ObjRawGet(this, name)
        }
        checking := ObjRawGet(this, "_checking")
        if (target.__Get) {
            return target.__Get.Call(target, name, keys*)
        }
        if (!checking || gType_IsSpecialName(name)) {
            return target[name, keys*]
        }
        prop := gObj_RawGet(target, name, True, found)
        if (!found) {
            gEx_Throw(Format("Tried to get name '{1}', but it wasn't defined."))
        }
        if (gType_Is(prop, "Property") && !prop.get) {
            gEx_Throw(Format("Tried to get name '{1}', but it was a property with no setter."))
        }
        return target[name, keys*]
    }
}

gLang_SmartProxy(target) {
    return new gMemberCheckingProxy(target)
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
