; ================================================================
; Contains utility commonly used utility functions.
; Meant to be reusable.
; ================================================================

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

class gFuncSchema {
    __New(name) {
        this.name := name
        this.args := []
    }

    IsVariadic {
        get {
            for i, p in this.args {
                if (p.IsVariadic) {
                    return True
                }
            }
            return False
        }
    }

    MinParams {
        get {
            for i, p in this.args {
                if (p.IsOptional) {
                    return i
                }
            }
            return i
        }
    }

    MaxParams {
        get {
            return this.args.MaxIndex()
        }
    }

}

z__gutils_parseSchema(str) {
    param_regex := "^(?<prefix>[^\w_]*)(?<name>[\w_])(?<postfix>[^\w_]*)$"
    split := gStr_Split(str, ",:")
    schema := new gFuncSchema("")
    params := []
    for i, v in split {
        trimmed := gStr_Trim(v)
        if (!trimmed) {
            continue
        }
        if (i = 1) {
            schema.name := trimmed
            continue
        }
        RegExMatch(trimmed, param_regex, match_)
        arg := {name: match_name}
        for i, char in match_prefix {
            if (char = "?") {
                arg.IsOptional := true
            } else {
                gEx_Throw(Format("Unknown prefix schema flag '{1}'.", char))
            }
        }
        for i, char in match_postfix {
            if (char = "*") {
                arg.IsVariadic := true
            } else {
                gEx_Throw(Format("Unknown postfix schema flag '{1}'.", char))
            }
        }
        schema.args.Push(gObj_Checked(arg))
    }
    return schema
}

z__gutils_assertCallable(schema, args*) {
    if (args.MaxIndex() < schema.MinParams) {
        gEx_Throw(Format("Tried to call function '{1}'. It needs at least {2} params, got {3}.", schema.Name, schema.MinParams, args.MaxIndex()))
    }
    if (args.MaxIndex() > schema.MaxParams && !schema.IsVariadic) {
        gEx_Throw(Format("Tried to call function '{1}'. It needs at most {2} params, got {3}.", schema.name, schema.MaxParams, args.MaxIndex()))
    }
}

class gCheckedCallable {
    _callable := ""
    _schema := ""
    __New(target, schema) {
        this._callable := target
        this._schema := schema
        return gObj_Checked(this)
    }
    
    AssertCallable(args*) {
        z__gutils_assertCallable(this._schema, args*)
    }

    Call(args*) {
        this.AssertCallable(args*)
        return this._callable.Call(args*)
    }

    Validate() {
        minArgs := ""
        isOptional := False
        for i, a in this._schema.args {
            if (!a.IsOptional && isOptional) {
                gEx_Throw(Format("Optional arguments invalid."))
            }
        }
    }
}

gFunc_Checked(what, schema := "") {
    if (!schema) {
        if (gType_Is(what, gCheckedCallable)) {
            return what
        }
        if (!gType_Is(what, "Func")) {
            gEx_Throw(Format("Input is not a Func, and no param signatures were specified."))
        }
        return new gCheckedCallable(what, what)
    }
    if (gType_Is(what, gCheckedCallable)) {
        gEx_Throw("Cannot apply schema to a Checked function.")
    }
    result := z__gutils_parseSchema(schema)
    return new gCheckedCallable(what, result)
}

class z__gutils_example {
    Prop {
        get {

        }
        set {

        }
    }

    Method() {

    }
}

z__gutils_getTypeCode(self) {
    ptr := NumGet(&self, "Ptr")
    return ptr
}

z__gutils_getTypeCodes() {
    ;https://autohotkey.com/boards/viewtopic.php?p=156419#p156419
    func := z__gutils_getTypeCode(Func("z__gutils_getTypeCodes"))
    bFunc := z__gutils_getTypeCode(Func("z__gutils_getTypeCodes").Bind())
    file := z__gutils_getTypeCode(FileOpen("*", "r"))
    enum := z__gutils_getTypeCode(ObjNewEnum({}))
    prop := z__gutils_getTypeCode(ObjRawGet(z__gutils_example, "Prop"))
    RegExMatch("1", "O)1", m)
    Match := z__gutils_getTypeCode(m)
    ; String ints are handled differently from ints
    return { ("" func): "Func"
        , ("" bfunc): "BoundFunc"
        , ("" file): "File"
        , ("" enum): "Enumerator"
        , ("" match): "Match"
        , ("" cls): "Class"
    , ("" prop): "Property"}
}

z__gutils_getTypeName(self) {
    tc := z__gutils_getTypeCode(self)
    return z__gutils_typeCodes["" tc]
}

global z__gutils_typeCodes := z__gutils_getTypeCodes()
global z__gutils_doesntExistCode := &z__gutils_nonExistent

; Values - "Func", "BoundFunc", "File", "Enumerator", "Match", "Class", "Property", "Object" , "Primitive", or __Class
gType(self) {
    if (!IsObject(self)) {
        return "Primitive"
    }
    knownType := z__gutils_getTypeName(self)
    if (knownType) {
        return knownType
    }
    if (self.__Class) {
        return self.__Class
    }
    return "Object"
}

; See the classic AHK is operator, but with extra  object indicators
gType_Is(self, type) {
    if (IsObject(self)) {
        if (type = "Object") {
            return True
        }
        typeCode := z__gutils_getTypeName(self)
        if (typeCode) {
            ; If it has a type code, just check if it's the same as the type
            return type = typeCode
        }
        ; We check if self instanceof type
        while (IsObject(self)) {
            ; type could be a base object
            if (self.__Class = type || self = type) {
                return True
            }
            self := ObjGetBase(self)
        }
    } else {
        if (type = "Primitive") {
            return True
        }
        ; Try the classic if to see if it matches
        if self is %type%
        {
            return True
        }
    }
    return False

}

gType_IsCallable(what) {
    if (!IsObject(what)) {
        return False
    }
    tn := z__gutils_getTypeName(what)
    if (tn = "Func" || tn = "BoundFunc") {
        return True
    }

    return gType_IsCallable(what.Call)
}

z__gutils_assertType(obj, expectedType) {
    if (!gType_Is(obj, expectedType)) {
        gEx_Throw(Format("Input must be a '{1}'. Was {2}.", expectedType, gType(obj)))
    }
}

z__gutils__assertNotObject(objs*) {
    for i, obj in objs {
        z__gutils_assertType(obj, "Primitive")
    }
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

; 0 - not a built-in name. 1 - built-in object name. 2 - meta function or other special member.
gType_IsSpecialName(name) {
    static builtInNames := {__Call: 2, base : 2
        , __get: 2, __set: 2
        ,__new: 2
        , __init: 2, __class: 2
        ,_NewEnum: 1, HasKey: 1
        ,Clone: 1, GetAddress: 1
        ,SetCapacity: 1, GetCapacity: 1
        ,MinIndex: 1, MaxIndex: 1
        ,Length: 1, Delete: 1
        ,Push: 1, Pop: 1
        ,InsertAt: 1,RemoveAt: 1
        ,Call:1
    ,Insert: 1, Remove: 1}

    has := ObjHasKey(builtInNames, name)
    return has ? builtInNames[name] : 0
}

class gMemberCheckingProxy {
    __gproxy_target := ""
    __gproxy_checking := False
    __gproxy_modes := ""

    ; Modes - f[rozen], 
    __New(target, modes := "") {
        if (!target) {
            gEx_Throw(Format("Error - target is empty: '{1}'.", target))
        }
        this.__gproxy_target := target
        this.__gproxy_modes := modes
        this.__gproxy_checking := True
    }

    __gproxy_target_get(context, name) {
        target := ObjRawGet(this, "__gproxy_target")
        z := gObj_RawGet(target, name, True, found)
        return found ? {value: z} : ""
    }

    __Call(name, args*) {
        if (!gStr_StartsWith(name, "__gproxy_")) {
            target := ObjRawGet(this, "__gproxy_target")
            checking := ObjRawGet(this, "__gproxy_checking")
            if (!checking || gType_IsSpecialName(name)) {
                return target[name].Call(target, args*)
            }
            if (target.__Call) {
                return target.__Call.Call(target, name, args*)
            }
            isSpec := gType_IsSpecialName(name)
            if (isSpec) {
                ; Can't do checking for special names without hardcoding them
                return target[name].Call(target, args*)
            }
            value := this.__gproxy_target_get("call", name)
            if (!value) {
                gEX_Throw(Format("Tried to call name '{1}', but it doesn't exist.", name))
            }
            value := ObjRawGet(value, "value")
            return gFunc_Checked(value).Call(target, args*)
        }
    }

    __Set(name, args*) {
        if (!gStr_StartsWith(name, "__gproxy_")) {
            value := args.Pop()
            keys := args
            target := ObjRawGet(this, "__gproxy_target")
            if (!target) {
                return ObjRawSet(this, name, value)
            }
            if (target.__Set) {
                args.Push(value)
                return target.__Set.Call(target, name, args*)
            }
            checking := ObjRawGet(this, "__gproxy_checking")
            if (!checking || gType_IsSpecialName(name)) {
                return target[name, keys*] := value
            }
            result := this.__gproxy_target_get("set", name)
            if (!result) {
                gEx_Throw(Format("Tried to set name '{1}', but it wasn't defined.", name))
            }
            property := ObjRawGet(result, "value")
            if (gType_Is(property, "Property") && !property.set) {
                gEx_Throw(Format("Tried to set name '{1}', but it was a property with no setter.", name))
            }
            ; It's defined and settable
            target[name, keys*] := value
            return value
        }
    }

    __Get(name, keys*) {
        if (!gStr_StartsWith(name, "__gproxy_")) {
            target := ObjRawGet(this, "__gproxy_target")
            if (!target) {
                return ObjRawGet(this, name)
            }
            checking := ObjRawGet(this, "__gproxy_checking")
            if (target.__Get) {
                return target.__Get.Call(target, name, keys*)
            }
            if (!checking || gType_IsSpecialName(name)) {
                return target[name, keys*]
            }
            prop := this.__gproxy_target_get("get", name)
            if (!prop) {
                gEx_Throw(Format("Tried to get name '{1}', but it wasn't defined.", name))
            }
            prop := ObjRawGet(prop, "value")
            if (gType_Is(prop, "Property") && !prop.get) {
                gEx_Throw(Format("Tried to get name '{1}', but it was a property with no setter.", name))
            }
            return target[name, keys*]
        }
    }
}

gObj_Checked(target) {
    tn := z__gutils_getTypeName(target)
    if (tn != "") {
        gEx_Throw(Format("Can't create a proxy for '{1}', it's a built-in object.", tn))
    }
    return new gMemberCheckingProxy(target)
}


; Represents an entry in a stack trace.
class gStackFrame {
    ToString() {
        x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
        return x
    }

    __New(file, line, function, offset) {
        frame := this
        frame.File := file
        frame.Line := line
        frame.Function := function
        frame.Offset := offset
        return gObj_Checked(frame)
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

; A module for working with arrays.



; Returns an array where `self` appears `count` times, e.g. `[self, self, ...]`
gArr_Repeat(self, count) {
    arr:=[]
    Loop, %count%
    {
        arr.Insert(self)
    }
    return arr
}

; Returns the position of the first occurence of `what` in `self`.
gArr_IndexOf(self, what, case := False) {
    z__gutils_assertType(self, "Object")

    for ix, value in self {
        if((!case && what = value) || what == value) {
            return ix
        }
    }
    return 0	
}

; Returns true if `self` contains `what` as a substring.
gArr_Has(self, what) {
    z__gutils_assertType(self, "Object")
    return gArr_IndexOf(self, what) > 0
}

; Returns the find element in `self` that match `predicate`. `predicate` can be a function name or function object.
gArr_Find(self, predicate) {
    z__gutils_assertType(self, "Object")
    predicate := gLang_Func(predicate)
    if (!predicate) {

    }
    return gArr_Filter(self, predicate)[1]
}

; Returns the positions of all the elements matching `predicate`. `predicate` can be a function name or function object.
gArr_FindIndexes(self, predicate) {
    z__gutils_assertType(self, "Object")
    results := []
    predicate := gLang_Func(predicate)
    for index, item in self {
        if (gLang_Call(predicate, item, index)) {
            results.push(index)
        }
    }
    return results
}

; Find first position of the element matching `predicate`. `predicate` can be a function name or object.
gArr_FindIndex(self, predicate) {
    z__gutils_assertType(self, "Object")
    return gArr_FindIndexes(self, predicate)[1]
}

; Returns the array in sorted order, with the sorting options `options`.
gArr_Order(self, options := "N") {
    z__gutils_assertType(self, "Object")
    str:= gArr_Join(self, "~")
    options .= " D~"
    Sort, str, %options%
    self:=[]
    Loop, Parse, str, ~ 
    {
        self.Insert(A_LoopField)
    }
    return self	
}

; Returns a new array that's a concatenation of all the arrays in `arrs`.
gArr_Concat(arrs*) {
    z__gutils_assertType(arrs, "Object")
    c := []
    for i, self in arrs {
        for j, item in self {
            c.Push(item)
        }
    }
    return c
}

; returns a new array that's the result of applying `projection` on every element. `projection` can be a funciton name or object.
gArr_Map(self, projection) {
    z__gutils_assertType(self, "Object")
    projection := gLang_Func(projection)
    result := []
    for index, item in self {
        result.Push(gLang_Call(projection, item, index))
    }
    return result
}

; Returns the first slice of `n` elements.
gArr_Take(self, n) {

    return gArr_Slice(self, 1, n)
}

; Returns a new array that's made of all the elements matching `filter`. `filter` can be a function name or object.
gArr_Filter(self, filter) {
    z__gutils_assertType(self, "Object")
    filter := gLang_Func(filter)
    result := []
    for index, item in self {
        if (gLang_Call(filter, item, index)) {
            result.Push(item)
        }
    }
    return result
}

; Returns the last element matching `predicate`. `predicate` can be a function name or object.
gArr_FindLastIndex(self, predicate) {
    z__gutils_assertType(self, "Object")
    self := gArr_FindIndexes(self, predicate)
    return self[self.MaxIndex()]
}

; Returns true if `self` is an array.
gArr_Is(self) {
    return IsObject(self) && self.MaxIndex() != ""
}

; Gets the element at position `pos`. Supports inverse indexing.
gArr_At(self, pos) {
    z__gutils_assertType(self, "Object")
    nIndex := z__gutils_NormalizeIndex(pos, self.MaxIndex())
    return self[nIndex]
}

; Returns a new array that's `self` in reverse order.
gArr_Reverse(self) {
    z__gutils_assertType(self, "Object")
    newArr := []
    Loop, % self.MaxIndex()
    {
        newArr.Push(self[self.MaxIndex() - A_Index + 1])
    }
    return newArr
}

; Recursively flattens an array with array elements into an array of non-array elements.
gArr_Flatten(self) {
    z__gutils_assertType(self, "Object")
    total := []
    for i, item in self {
        if (gArr_Is(item)) {
            total.Push(gArr_Flatten(item)*)
        } else {
            total.Push(item)
        }
    }
    return total
}

; Joins an array of strings `self`, with separator `self`.
gArr_Join(self, sep:="", omit:="") {
    z__gutils__assertNotObject(sep, omit)
    z__gutils_assertType(self, "Object")
    for ix, value in self {
        if (!gStr_Is(value)) {
            value := gStr(value)
        }
        if (A_Index != 1) {
            res .= sep
        }
        value := Trim(value, omit)
        res .= value
    }
    return res
}

z__gutils_isObject(name, self, canBeArray := False) {
    if (!isObject(self)) {
        gEx_Throw("Parameter " name " is not an object: " self)
    }
    if (!canBeArray) {
        if (self.MaxIndex() > 0) {
            gEx_Throw("Parameter " name " is an array.")
        }
    }
}

; True if `self` is an object.
gObj_Is(self) {
    return IsObject(self)
}

; Returns an array of the object's keys.
gObj_Keys(self, inherited := False) {
    z__gutils_isObject("self", self, True)
    if (z__gutils_getTypeName(self)) {
        return []
    }
    keys := []
    while (IsObject(self)) {
        for k in self {
            keys.Push(k)
        }
        if (!inherited) {
            return keys
        }
        self := ObjGetBase(self)
    }
    return keys 
}

; A class for validating object inputs.
class gObjValidator {
    requiredKeys := ""
    optionalKeys := False
    name := ""
    __New(name, requiredKeys, optionalKeys := False) {
        this.name := name
        this.requiredKeys := requiredKeys
        this.optionalKeys := optionalKeys
        return gObj_Checked(this)
    }

    ; Asserts the input passes this validator.
    Assert(obj) {
        result := this.Check(obj)
        if (!result.valid) {
            gEx_Throw(Format("{1} - {2}", this.name, result.reason))
        }
    }

    ; Returns if the input passes this validator.
    Check(obj) {
        if (!gObj_Is(obj)) {
            return {valid: False, reason: "Input not an object: " obj}
        }
        if (gArr_Is(obj)) {
            return {valid: False, reason: "Object is an array."}
        }
        keys := this.requiredKeys
        for i, k in keys {
            if (!obj.HasKey(k)) {
                return {valid: False, reason: Format("Required key '{1}'' is missing.", k)}
            }
        }
        if (this.optionalKeys != True) {
            for k, v in obj {
                if (!gArr_IndexOf(this.optionalKeys, k)) {
                    return {valid: False, reason: Format("Unknown key '{1}'.", k)}
                }
            }
        }
        return {valid: True}
    }
}

; Returns a new validator. Use Validator.Check and Validator.Assert.
gObj_NewValidator(name, requiredKeys := "", optionalKeys := True) {
    return new gObjValidator(name, requiredKeys, optionalKeys)
}

; Returns a subset of `self` including only keys from `keys`.
gObj_Pick(self, keys*) {
    result := {}
    for i, k in keys {
        result[k] := self[k]
    }
    return result
}

; Creates an object with all the keys in `keys`, all having the value `value`.
gObj_FromKeys(keys, value := True) {
    result := {}
    for i, k in keys {
        result[k] := value
    }
    return result
}

; Returns a subset of `self` without keys from `keys`.
gObj_Omit(self, keys*) {
    result := {}
    keysObj := gObj_FromKeys(keys)
    for i, k in self {
        if (!keysObj.HasKey(k)) {
            result[k] := self[k]
        }
    }
    return result
}

; Assigns all the keys from sources, in order, to `self`.
gObj_Assign(self, sources*) {
    for i, source in sources {
        for k, v in source {
            self[k] := v
        }
    }
}

; Returns a new object with defaults from `sources`.
gObj_Defaults(self, sources*) {
    sources := gArr_Reverse(sources)
    sources.Push(self)
    self := gObj_Assign({}, sources*)
    return self
}

; Returns an object with all the key-value pairs in `sources`.
gObj_Merge(sources*) {
    return gObj_Assign({}, sources*)
}

gObj_Aliases(target, aliases) {
    for k, v in aliases {
        target[k] := target[v]
    }
}

gObj_Describe(self) {

}



; Returns a new string that's padded to the end, to the width toWidth, using the padding `padding`.
gStr_PadRight(ByRef self, toWidth, padding := " ") {
    z__gutils__assertNotObject(self, toWidth, padding)
    myLen := StrLen(self)
    extras := toWidth - myLen
    if (extras <= 0) {
        return self
    }
    padding := gStr_Repeat(padding, extras)
    result := self padding
    return result
}

; Returns a string that's padded to the left, toWidth, using the given padding.
gStr_PadLeft(ByRef self, toWidth, padding := " ") {
    z__gutils__assertNotObject(self, toWidth, padding)
    myLen := StrLen(self)
    extras := toWidth - myLen
    if (extras <= 0) {
        return self
    }
    padding := gStr_Repeat(padding, extras)
    result := padding self 
    return result
}

; Returns an array of the ANSI characters or codepoints in `self`.
gStr_ToChars(ByRef self) {
    z__gutils__assertNotObject(self)
    list:=[]
    Loop, Parse, self 
    {
        list.Insert(A_LoopField)
    }
    return list
}

; Returns this strint indented using `indent` to `level`. Handles multi-line strings.
gStr_Indent(ByRef self, indent := " ", level := 1) {
    z__gutils__assertNotObject(self, indent, level)
    if (!self) {
        return self
    }
    indentStr := ""
    Loop, % level
    {
        indentStr.=indent
    }
    indented := ""

    StringReplace, indented, self, `n, `n%indentStr%, All
    indented:=indentStr indented
    return indented
}

; Returns true if `self` starts with `what`.
gStr_StartsWith(ByRef self, ByRef what, caseSensitive = 0) {
    z__gutils__assertNotObject(self, what, caseSensitive)
    if (what == "") {
        return true
    }
    len := StrLen(what)
    initial := SubStr(self, 1, len)
    return caseSensitive ? initial == what : initial = what
}

; Returns true if `self` ends with `what`.
gStr_EndsWith(ByRef self, ByRef what, caseSensitive = 0) {
    z__gutils__assertNotObject(self, what, caseSensitive)
    if (what == "") {
        return true
    }
    len := StrLen(what)
    final := gStr_Slice(self, -len+1)
    return caseSensitive ? final == what : final = what
}

; Semi-intelligently stringifies an object.
gStr(obj) {
    if (!IsObject(obj)) {
        return "" + obj
    }
    tn := z__gutils_getTypeName(obj)
    if (tn) {
        return tn
    }
    if (gType_Is(obj, gMemberCheckingProxy)) {
        obj := ObjRawGet(obj, "__gproxy_target")
    }
    if (obj.MaxIndex() != "") {
        stringified := gArr_Map(obj, "gStr")
        return "[" gArr_Join(stringified, ", ") "]"
    }
    stringified := []
    for key, value in obj {
        stringified.Push(Format("{1}: {2}", key, gStr(value)))
    }
    return "{`n" gSTr_Indent(gArr_Join(stringified, ",`n"), " ", 1) "`n}"
}

gStr_Trim(ByRef self, chars := " `t") {
    z__gutils__assertNotObject(self, chars)
    return Trim(self, chars)
}

gStr_TrimLeft(ByRef self, chars := " `t") {
    z__gutils__assertNotObject(self, chars)
    return LTrim(self, chars)
}

gStr_TrimRight(ByRef self, chars := " `t") {
    z__gutils__assertNotObject(self, chars)
    return RTrim(self, chars)
}

gStr_Len(ByRef self) {
    z__gutils__assertNotObject(self)
    return StrLen(self)
}

; Returns a string that's `self` repeated `count` times, deparated by `delim`.
gStr_Repeat(ByRef self, count, delim := "") {
    z__gutils__assertNotObject(self, count, delim)
    result := ""
    Loop, % count 
    {
        if (A_Index != 1) {
            result .= delim
        }
        result.= self
    }
    return result
}

; Returns the positions of substring `what` in `this`.
gStr_IndexesOf(ByRef self, ByRef what, case := false) {
    z__gutils__assertNotObject(self, what, case)
    arr := []
    occur := 1
    last := ""
    Loop {
        if (last != "") {
            arr.Push(last)
        }
        last := gStr_IndexOf(self, what, case, A_Index)
    } until last = 0
    return arr
}

; Returns the position of the first occurence of `what`.
gStr_IndexOf(ByRef self, ByRef what, case := false, pos := 1) {
    z__gutils__assertNotObject(self, what, case, pos)
    return InStr(self, what, case, pos)
}

; Returns a reversed string.
gStr_Reverse(ByRef self) {
    z__gutils__assertNotObject(self)
    str := ""
    Loop, Parse, % self 
    {
        str := A_LoopField str
    }

    return str
}

; Returns the last position of `what` in `self`.
gStr_LastIndexOf(ByRef self, ByRef what, case := false, pos := 1) {
    z__gutils__assertNotObject(self, what, case)
    cur := 0
    indexes := gStr_IndexesOf(self, what, pos)
    return indexes[indexes.MaxIndex()]
}

; Splits `self` in two at `pos` and returns the two parts.
gStr_SplitAt(ByRef self, pos) {
    z__gutils__assertNotObject(self, pos)
    pos := z__gutils_NormalizeIndex(pos, StrLen(self))
    first := gStr_Slice(self, pos - 1)
    last := gStr_Slice(self, pos + 1)
    return [first, last]
}

; Returns a substring starting at `start` and ending at `end`
gStr_Slice(ByRef self, start := 1, end := 0) {
    z__gutils__assertNotObject(self, start, end)
    start := z__gutils_NormalizeIndex(start, StrLen(self))
    end := z__gutils_NormalizeIndex(end, StrLen(self))
    return SubStr(self, start, end - start + 1)
}

; Splits `self`.
gStr_Split(ByRef self, delimeters := "", omit := "", max := -1) {
    z__gutils__assertNotObject(self, delimeters, omit, max)
    return StrSplit(self, delimeters, omit, max)
}

; Returns from an array of numeric char codes.
gStr_OfCodes(wArray) {
    z__gutils_assertType(wArray, "Object")
    result := ""
    for i, x in wArray {
        result .= chr(x)
    }
    return result
}

; Returns a string from an array of strings.
gStr_OfChars(cArray) {
    z__gutils_assertType(cArray, "Object")
    result := ""
    for i, x in cArray {
        result .= x
    }
    return result
}

; Returns a string GUID.
gStr_Guid() {
    ; from https://gist.github.com/ijprest/3845947
    format = %A_FormatInteger% ; save original integer format 
    SetFormat Integer, Hex ; for converting bytes to hex 
    VarSetCapacity(A,16) 
    DllCall("rpcrt4\UuidCreate","Str",A) 
    Address := &A 
    Loop 16 
    { 
        x := 256 + *Address ; get byte in hex, set 17th bit 
        StringTrimLeft x, x, 3 ; remove 0x1 
        h = %x%%h% ; in memory: LS byte first 
        Address++ 
    } 
    SetFormat Integer, %format% ; restore original format 
    h := SubStr(h,1,8) . "-" . SubStr(h,9,4) . "-" . SubStr(h,13,4) . "-" . SubStr(h,17,4) . "-" . SubStr(h,21,12)
    return h
}

; Returns `self` in lowercase.
gStr_Lower(ByRef self, T := "") {
    z__gutils__assertNotObject(self, T)
    StringLower, v, self, % T
    Return, v
}

; Returns `self` in uppercase.
gStr_Upper(ByRef self, T := "") {
    z__gutils__assertNotObject(self, T)
    StringUpper, v, self, %T%
    Return, v
}

; Returns a new replaced string.
gStr_Replace(ByRef self, ByRef SearchText, ByRef ReplaceText, Limit := -1) {
    z__gutils__assertNotObject(self, searchText, replaceText, limit)
    return StrReplace(self, SearchText, ReplaceText, , Limit)
}

; True if `what` is in `self`
gStr_Has(ByRef self, ByRef what, Case := false, Start := 1) {
    z__gutils__assertNotObject(self, what, case, start)
    return gStr_IndexOf(self, what, Case, Start) > 0
}

; True if `self` is not an object.
gStr_Is(ByRef self) {
    return !IsObject(self)
}

; Returns the char at position `pos`.
gStr_At(ByRef self, pos) {
    z__gutils__assertNotObject(self, pos)
    return SubStr(self, pos, 1)
}

class gMatch {
    _target := ""
    __New(mObject) {
        if (!gType_Is(mObject, "Match")) {
            gEx_Throw("Expected match object.")
        }
        this._target := mObject
    }
}

class gRegEx {
    search := ""
    options := ""
    __New(search, options := "") {
        this.search := search
        this.options := options
        if (!gStr_IndexOf(options, "O")) {
            this.options .= "O"
        }
        return gObj_Checked(this)
    }

    Value {
        get {
            return gArr_Join([this.options, this.search], ")")
        }
    }

    First(ByRef haystack, pos := 1) {
        z__gutils__assertNotObject(haystack, pos)
        needle := this.Value
        RegExMatch(haystack, needle, match, pos)
        return match
    }

    Replace(ByRef haystack, replacement := "", pos := 1, limit := -1) {
        arr := []
        for i, m in this.All(haystack, pos, limit) {
            untouched := gStr_Slice(haystack, pos, m.Pos() - 1)
            arr.Push(untouched)
            if (gType_Is(replacement, "Primitive")) {
                arr.Push(replacement)
            }
            else if (replacement.Call || gType_Is(replacement, "Func")) {
                arr.Push(replacement.Call(m))
            } else {
                gEx_Throw("Invalid replacement value " replacement)
            }
            pos := m.Pos() + m.Len()
        }
        arr.Push(gStr_Slice(haystack, pos))
        return gArr_Join(arr, "")
    }

    All(ByRef haystack, pos := 1, limit := -1) {
        z__gutils__assertNotObject(haystack, pos)
        array:=[]

        while (1) {
            if (limit > 0 && limit < A_Index) {
                break
            }
            pos := RegExMatch(haystack, this.Value, match, pos)

            if (!pos) {
                break
            }
            array.Push(match)
            pos += match.Len()
        }
        Return array
    }

    Split(byref haystack, pos := 1, limit := -1) {
        array := []
        for i, match in this.All(haystack, pos, limit) {
            array.Push(gStr_Slice(haystack, pos, match.Pos() - 1))
            Loop, % match.Count()
            {
                array.Push(match.Value(A_Index))
            }
            pos := match.Pos() + match.Len()
        }
        array.Push(gStr_Slice(haystack, pos))
        return array
    }

}

gStr_Regex(search, options := "") {
    return new gRegEx(search, options)
}

; Returns a match object.
gStr_Match(ByRef self, needle, options := "", pos := 1) {
    z__gutils__assertNotObject(self, needle, options, pos)
    needle := options "O)" needle
    RegExMatch(self, needle, match, pos)
    return match
}

; Returns an array of match objects.
gStr_Matches(ByRef self, needle, options := "", pos := 1) {
    z__gutils__assertNotObject(self, needle, options, pos)
    array:=[]
    needle := options "O)" needle
    while (pos := RegExMatch(self, needle, match, ((pos>=1) ? pos : 1)+StrLen(match))) {
        array.Push(match)
    }
    Return array
}




; Returns true if the window identified by `winTitle` is full screen.
gWin_IsFullScreen(winTitle := "") {
    ;checks if the specified window is full screen
    ;code from NiftyWindows source
    ;(with only slight modification)

    ;use WinExist of another means to get the Unique ID (HWND) of the desired window

    if ( !winTitle ) {
        WinGet, winTitle, ID, A
    }

    WinGet, WinMinMax, MinMax, ahk_id %winTitle%
    WinGetPos, WinX, WinY, WinW, WinH, ahk_id %winTitle%

    if (WinMinMax = 0) && (WinX = 0) && (WinY = 0) && (WinW = A_ScreenWidth) && (WinH = A_ScreenHeight) {
        WinGetClass, WinClass, ahk_id %winTitle%
        WinGet, WinProcessName, ProcessName, ahk_id %winTitle%
        SplitPath, WinProcessName, , , WinProcessExt

        if (WinClass != "Progman") && (WinProcessExt != "scr") {
            ;program is full-screen
            return true
        }
    }
    return false
}

; Returns true if the mouse cursor is visible.
gWin_IsMouseCursorVisible() {
    StructSize := A_PtrSize + 16
    VarSetCapacity(InfoStruct, StructSize)
    NumPut(StructSize, InfoStruct)
    DllCall("GetCursorInfo", UInt, &InfoStruct)
    Result := NumGet(InfoStruct, 8)
    return Result > 1
}

z__gutils_MatchingInfoKeys := ["speed", "mode", "hiddenWindows", "hiddenText", "title", "text", "excludeTitle", "excludeText"]
global z__gutils_MatchingInfoValidator := gObj_NewValidator("MatchingInfo", [], z__gutils_MatchingInfoKeys)

; Returns the matching info of the current thread, e.g. A_DetectHiddenWindows.
gWin_GetMatchingInfo() {
    return {hiddenWindows: A_DetectHiddenWindows, hiddenText: A_DetectHiddenText, speed: A_TitleMatchModeSpeed, mode: A_TitleMatchMode}
}

z__gutils_maybeSetMatchingInfo(obj) {
    if (obj = False) {
        return
    }
    return gWin_SetMatchingInfo(obj)
}

; Sets the current matching info from `infoObj`.
gWin_SetMatchingInfo(infoObj) {
    z__gutils_MatchingInfoValidator.Assert(infoObj)
    modified := False
    old := gWin_GetMatchingInfo()
    if (infoObj.HasKey("mode")) {
        SetTitleMatchMode, % infoObj.mode
        modified := True
    }
    if (infoObj.HasKey("speed")) {
        SetTitleMatchMode, % infoObj.speed
        modified := True
    }
    if (infoObj.HasKey("hiddenWindows")) {
        DetectHiddenWindows, % gLang_Bool(infoObj.hiddenWindows, "OnOff")
        modified := True
    }
    if (infoObj.HasKey("hiddenText")) {
        DetectHiddenText, % gLang_Bool(infoObj.hiddenText, "OnOff")
        modified := True
    }
    return modified ? old : False
}

z__gutils_WinGet(hwnd, subCommand) {
    WinGet, v, % subCommand, ahk_id %hwnd%
    return v
}

; A reference to a specific window that lets you gets info about it.
class gWinInfo {
    hwnd := ""

    __New(hwnd) {
        this.hwnd := hwnd
        return gObj_Checked(this)
    }

    _winTitle() {
        return "ahk_id " this.hwnd
    }

    _winGet(subCommand) {
        WinGet, v, % subCommand, % this._winTitle()
        return v
    }

    ; The window's owner process PID.
    PID {
        get {
            return this._winGet("PID")
        }
    }

    ; The name of the window's owner process.
    ProcessName {
        get {
            return this._winGet("ProcessName")
        }
    }

    ; The path to the window's owner process.
    ProcessPath {
        get {
            return this._winGet("ProcessPath")
        }
    }

    Transparent {
        get {
            return this._winGet("Transparent")
        }
    }

    TransColor {
        get {
            return this._winGet("TransColor")
        }
    }

    Style {
        get {
            return this._winGet("Style")
        }
    }

    ExStyle {
        get {
            return this._winGet("ExStyle")
        }
    }

    ; Whether the window if minimized or maximized.
    MinMax {
        get {
            return this._winGet("MinMax")
        }
    }

    ; The window's title.
    Title {
        get {
            WinGetTitle, v, % this._winTitle()
            return v
        }
    }

    ; The window's class.
    Class {
        get {
            WinGetClass, v, % this._winTitle()
            return v
        }
    }

    ; The window's position and size info.
    Pos {
        get {
            WinGetPos, X, Y, Width, Height, % this._winTitle()
            return {X: X
                ,Y: Y
                ,Width:Width
            ,Height:Height}
        }
    }

    ; Whether the window is active.
    IsActive {
        get {
            return WinActive(this._winTitle())
        }
    }

    ; The window's text.
    Text {
        get {
            WinGetText, v, % this._winTitle()
            return v
        }
    }

    ; The window's Hwnd.
    ID {
        get {
            return this.hwnd
        }
    }

    ; Whether the window still exists.
    Exists {
        get {
            return WinExist(this._winTitle()) > 0
        }
    }

    ; Hides the window.
    Hide() {
        WinHide, % this._winTitle()
    }

    ; Unhides the window.
    Show() {
        WinShow, % this._winTitle()
    }

    ; Kills the window.
    Kill() {
        WinKill, % this._winTitle()
    }

    Maximize() {
        WinMaximize, % this._winTitle()
    }

    Minimize() {
        WinMinimize, % this._winTitle()
    }

    Move(X, Y, Width:= "", Height := "") {
        WinMove, % this._winTitle(), , % X, % Y, % Width, % Height
    }

    Restore() {
        WinRestore, % this._winTitle()
    }

    Set(subCommand, value := "") {
        WinSet, % subCommand, % value, % this._winTitle()
    }

    Activate() {
        WinActivate, % this._winTitle()
    }

}

; Performs a query on windows given query object `query`, returning the first matching window.
gWin_Get(query) {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        hwnd := WinExist(query.title, query.text, query.excludeTitle, query.excludeText)
        if (hwnd = 0) {
            return ""
        }
        return new gWinInfo(hwnd)
    } finally {
        z__gutils_maybeSetMatchingInfo(old)
    }
}

; Performs a window query and returns all matching window objects.
gWin_List(query) {
    z__gutils_MatchingInfoValidator.Assert(query)
    WinGet, win, List, % query.title, % query.text, % query.excludeTitle, % query.excludeText
    arr := []
    Loop, % win 
    {
        arr.push(new gWinInfo(win%A_index%))
    }
    v := arr
}

; WinWait on the first window matching the query.
gWin_Wait(query, timeout := "") {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWait, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
    } finally {
        z__gutils_maybeSetMatchingInfo(old)
    }

}

gWin_WaitActive(query, active := 1, timeout := "") {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        if (active) {
            WinWaitActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        } else {
            WinWaitNotActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        }
    } finally {
        z__gutils_maybeSetMatchingInfo(old)
    }
}

gWin_WaitClose(query, timeout := "") {
    z__gutils_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWaitClose, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
    } finally {
        z__gutils_maybeSetMatchingInfo(obj)
    }

}


; An invoker for handily invoking virtual methods.
class gVtableInvoker {
    _ref := ""
    _onDispose := []
    __New(ref, dependencies = "") {
        this._ref := ref
        for i, v in dependencies {
            this._onDispose.Push(v)
        }
    }

    AddDependencies(dependencies*) {
        for i, v in dependencies {
            this._onDispose.Push(v)
        }
    }

    VtableCall(slot, args*) {
        x:= slot*A_PtrSize
        DllCall(NumGet(NumGet(this._ref+0)+slot*A_PtrSize) , "UPtr", this._ref + 0, args*)
    }

    Dispose() {
        ObjRelease(this._ref)
        for i, v in this._onDispose {
            ObjRelease(v)
        }
    }
}

; Returns an invoker for COM vtable calls.
gSys_ComVTableInvoker(ref, dependencies := "") {
    return gObj_Checked(new gVtableInvoker(ref, dependencies))
}

; Get the current PID.
gSys_Pid() {
    return DllCall("GetCurrentProcessId")	
}

global z__gutils_wmi := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") 

; Returns info about process with `pid`, or the current process.
gSys_GetProcessInfo(pid := "") {
    if (pid = "") {
        pid := gSys_Pid()
    }
    query = Select * From Win32_Process where ProcessId = %pid%
    results := z__gutils_wmi.ExecQuery(query)._NewEnum()
    while results[proc]
    {
        return {Name: proc.Name
        ,PID: proc.ProcessId
        ,ParentPID: proc.ParentProcessId
        ,Path: proc.ExecutablePath}
    }
}

; Returns the parent process of `pid`.
gSys_GetParentPid(pid) {
    query = Select ParentProcessId From Win32_Process where ProcessId = %pid%
    results := z__gutils_wmi.ExecQuery(query)._NewEnum()
    while results[proc]
    {
        return proc.ParentProcessId
    }
}

z__gutils_noramlizeRoot(root) {
    static z__gutils_roots
    if (!z__gutils_roots) {
        z__gutils_roots := {"HKLM" : "HKEY_LOCAL_MACHINE"
            ,"HKCR": "HKEY_CLASSES_ROOT"
            ,"HKU": "HKEY_USERS"
            ,"HKCU" : "HKEY_CURRENT_USER"
        ,"HPD": "HKEY_PERFORMANCE_DATA"}

        ; This is needed so the normalizer is idempotent and also to normalize case
        for key, v in z__gutils_roots {
            z__gutils_roots[v] := v
        }
    }
    return z__gutils_roots[root]
}

z__gutils_splitRegPath(path) {
    if (Trim(path) = "") {
        gEx_Throw("Empty string not a valid registry path.")
    }
    normalizedAsRoot := z__gutils_noramlizeRoot(path)
    if (normalizedAsRoot) {
        return [normalizedAsRoot, ""]
    }
    parsed := gStr_Split(path, "\", , 2)
    root := ""
    subkey := ""
    if (parsed.MaxIndex() = 2) {
        normalizedRoot := z__gutils_noramlizeRoot(parsed[1])
        if (!normalizedRoot) {
            return ["", path]
        }
        return [normalizedRoot, parsed[2]]
    } else {
        return ["", path]
    }
}

z__gutils_normalizeRootInPath(path) {
    return gPath_Join(z__gutils_splitRegPath(path))
}

z__gutils_resolveRegPath(parts*) {
    ; Format the registry path like an fs path and use the syscall to resolve it
    parts.InsertAt(1, "C:")
    resolved := gPath_Resolve(parts*)
    noDrive := gStr_Slice(resolved, 4)
    resolvedRoot := gStr_Trim(z__gutils_normalizeRootInPath(noDrive))
    return resolvedRoot
}

z__gutils_checkKeyExists(rootedKey) {
    if (rootedKey = "") {
        gEx_Throw("Empty key not a legal registry path.")
    }
    Loop, Reg, % rootedKey, KVR
    {
        return True
    }
    rootedKey := z__gutils_normalizeRootInPath(rootedKey)
    parent := z__gutils_resolveRegPath(rootedKey, "..")
    Loop, Reg, % parent, K
    {
        curFullKey := gPath_Join(A_LoopRegKey, A_LoopRegSubkey, A_LoopRegName)
        if (curFullKey = rootedKey) {
            return True
        }
    }
    return False
}

; A registry key.
class gRegKey {
    root := ""
    subKey := ""
    ; Create a new gRegKey. parts - one or more path parts of the key. Path must be rooted.
    __New(parts*) {
        root := parts[1]
        this.root := z__gutils_noramlizeRoot(root)
        this.subkey := gPath_Join(gArr_Slice(parts, 2))
        if (!this.root) {
            gEX_Throw("Root was empty.")
        }
        return gObj_Checked(this)
    }

    ; Gets if this object is a registry key.
    IsKey {
        get {
            return True
        }
    }

    ; Gets if this key is a root key.
    IsRoot {
        get {
            return this.subkey == ""
        }
    }

    ; Gets the complete, joined form of this key.
    Key {
        get {
            if (!this.subkey) {
                return this.root
            }
            return gPath_Join(this.root, this.subkey)
        }
    }

    ; Gets a subkey relative to this tree. Parts - the parts of the path from this key. You can use '..'.
    Child(parts*) {
        joined := gPath_Join(parts*)
        resolved := z__gutils_resolveRegPath(this.Key, joined)
        if (!z__gutils_checkKeyExists(resolved)) {
            return ""
        }
        parts := z__gutils_splitRegPath(resolved)
        child := new gRegKey(parts*)
        return child
    }

    ; Gets the key that's the parent of this key, or throws if this key is a root.
    Parent {
        get {
            if (this.IsRoot) {
                gEx_Throw("Can't get parent of root.")
            }
            parent := z__gutils_resolveRegPath(this.Key, "..")
            parsed := z__gutils_splitRegPath(parent)
            return new gRegKey(parsed[1], parsed[2])
        }
    }

    ; Gets all the direct child keys of this key.
    Children() {
        arr := []
        Loop, Reg, % this.key, K
        {
            arr.Push(new gRegKey(A_LoopRegKey, A_LoopRegSubkey, A_LoopRegName))
        }
        return arr
    }

    ; Gets an object consisting of all the values of this key.
    Values() {
        values := {}
        Loop, Reg, % this.Key, V
        {
            RegRead, X
            values[A_LoopRegName] := X
        }
        return values
    }

    ; Removes a value from this key. Cannot remove the default value.
    EraseValue(name) {
        if (name = "") {
            gEx_Throw("The value name cannot be empty.")
        }
        try {
            RegDelete, % this.Key, % name
        } catch err {
            gEx_ThrowObj(err)
        }
    }

    ; Deletes this key and all its data.
    Erase() {
        if (this.IsRoot) {
            gEx_Throw("You can't delete a root.")
        }
        try {
            RegDelete, % this.key
        } catch err {
            gEx_ThrowObj(err)
        }
    }

    ; Creates a child key with the path from `parts`.
    Create(parts*) {
        fullKey := z__gutils_resolveRegPath(this.Key, parts*)
        if (z__gutils_checkKeyExists(fullKey)) {
            gEx_Throw(Format("Key '{1}' already exists.", fullKey))
        }
        ; We need to create this dummy key because RegWrite can't actually create empty keys
        fakeKey := gPath_Join(fullKey, "ahk-gutils-DELETE-THIS")
        try {
            RegWrite, REG_SZ, % fakeKey
            RegDelete, % fakeKey
        } catch err {
            gEx_ThrowObj(err)
        }
        parsed := z__gutils_splitRegPath(fullKey)
        return new gRegKey(parsed[1], parsed[2])
    }

    ; True if this key has a child key with the path from `parts`.
    Has(parts*) {
        parts.InsertAt(1, this.key)
        return z__gutils_checkKeyExists(gPath_Join(parts))
    }

    ; True if this key has a value called `name`.
    HasV(name) {
        Loop, Reg, % this.Key, V
        {
            if (A_LoopRegName = name) {
                return True
            }
        }
    }

    ; Gets the value of `name`.
    Get(name := "") {
        try {
            RegRead, X, % this.Key, % name
            return X
        } catch err {
            return ""
        }
    }

    ; Overwrites a value named `name` on this key.
    Set(name, type, value) {
        if (!gArr_Has(["REG_SZ", "REG_EXPAND_SZ", "REG_MULTI_SZ", "REG_DWORD", "REG_BINARY"], type)) {
            gEx_Throw("Type " type " is not a legal regisry value type.")
        }
        try {
            RegWrite, % type, % this.Key, % name, % value
        } catch err {
            gEx_ThrowObj(err)
        }
    }

}

; Returns an object referencing the given key.
gReg(parts*) {
    key := gPath_Join(parts*)
    if (!z__gutils_checkKeyExists(key)) {
        gEx_Throw(Format("Key '{1}' doesn't exist.", key))
    }
    parsed := z__gutils_splitRegPath(key)
    return new gRegKey(parsed[1], parsed[2])
}



global z__gutils__nonObjectBase := "".base
z__gutils_setupNonObjectCheck() {
    rawBase := "".base
    rawBase.__Get := Func("z__gutils_UnknownGet")
    rawBase.__Set := Func("z__gutils_UnknownSet")
    rawBase.__Call := Func("z__gutils_UnknownCall")
}
global z__gutils_currentError := ""
global z__gutils_vsCodeProcess := ""

z__gutils_UnknownGet(nonobj, name) {
    if (name == "base" || name == "__Call") {
        return z__gutils__nonObjectBase
    }
    gEx_Throw(Format("Tried to get property '{1}' from non-object value '{2}',", name, nonobj))
}

z__gutils_UnknownSet(nonobj, name, values*) {
    gEx_Throw(Format("Tried to set property '{1}' on non-object value '{2}'.", name, nonobj))
}

z__gutils_UnknownCall(nonobj, name, args*) {
    gEx_Throw(Format("Tried to call method '{1}' on non-object value '{2}'.", name, nonobj))
}

z__gutils_detectVsCode() {
    ; We need to get the topmost vscode process...
    processInfo := gSys_GetProcessInfo()
    ; Find the outermost code.exe process that's the parent of this process
    Loop {
        last := processInfo
        processInfo := gSys_GetProcessInfo(processInfo.ParentPid)

    } until (!(processInfo && processInfo.Name = "code.exe"))
    z__gutils_vsCodeProcess := last
}

gEx_Print(ex) {
    clone := ex.Clone()
    stackTraceLines := []
    if (ex.trace) {
        for ix, entry in ex.trace {
            stackTraceLines.Push(entry.Function " (" entry.File ":" entry.Line ")")
        }
    }
    clone.trace := stackTraceLines
    return JSON.Dump(clone,,2)
}

z__gutils_ex_gui_clickedList() {

    if (A_GuiEvent = "DoubleClick" && z__gutils_vsCodeProcess.Pid) {
        try {
            Gui, z__gutils_errorBox: +Disabled
            row := "a"
            row := LV_GetNext()
            if (!row) {
                Return
            }
            stackEntry := z__gutils_currentError.trace[row]
            latestCodeWindow := gWin_Get({title: "ahk_pid " z__gutils_vsCodeProcess.Pid})
            latestCodeWindow.Activate()
            sourceLocation := stackEntry.File
            SendInput, % "^P{Backspace}" stackEntry.File
            Sleep 150
            SendInput, % ":" stackEntry.Line "{Enter}"
        } finally {
            Gui, z__gutils_errorBox: -Disabled

        }
    }
}

z__gutils_ex_gui_pressedOk() {
    Gui, z__gutils_errorBox: Cancel

}

z__gutils_ex_gui_copyDetails() {
    Clipboard:=gEx_Print(z__gutils_currentError)
}

z__gutils_errorBoxOnClose() {
    z__gutils_currentError := ""
}

z__gutils_openExceptionGuiFor(ex) {

    try {
        if (z__gutils_currentError) {
            return
        }
        z__gutils_currentError := ex
        static imageList := ""
        if (!IsObject(ex) || ObjGetBase(ex) !== gOopsError) {
            return
        }
        if (!imageList && z__gutils_vsCodeProcess) {
            imageList := IL_Create()
            Loop, 10
            {
                IL_add(imageList, z__gutils_vsCodeProcess.Path, 1)
            }
        }
        Gui, z__gutils_errorBox: New, , An error has occurred!
        Gui, z__gutils_errorBox: +AlwaysOnTop
        Gui, z__gutils_errorBox: Font, S10 CDefault, Verdana
        Gui, z__gutils_errorBox: Add, Text, x12 y9 w240 h20 , An error has occurred in the script:
        Gui, z__gutils_errorBox: Add, Edit, x272 y9 w190 h20 ReadOnly, %A_ScriptName%

        Gui, z__gutils_errorBox: Add, Text, x13 y33 w82 h20 , Error Type:
        Gui, z__gutils_errorBox: Add, Edit, x101 y34 w361 h20 ReadOnly, % ex.Type

        Gui, z__gutils_errorBox: Add, Text, x12 y56 w68 h16 , Message:
        Gui, z__gutils_errorBox: Add, Edit, x11 y76 w453 h103 ReadOnly, % ex.Message

        Gui, z__gutils_errorBox: Add, Text, x11 y183 w180 h18 , Inner Exception Message:

        innerExContent := "(No inner exception)"

        if (IsObject(ex.InnerException)) {
            innerExContent := ex.InnerException.Message
        } else if (ex.InnerException) {
            innerExContent := ex.InnerException
        }
        Gui, z__gutils_errorBox: Add, Edit, x12 y203 w452 h87 ReadOnly, % innerExContent
        Gui, z__gutils_errorBox: Add, Button, x375 y466 w89 h25 gz__gutils_ex_gui_pressedOk Default, OK

        stackTraceLabel:="Stack Trace:"
        if (A_IsCompiled) {
            stackTraceLabel.= " (is compiled)"
        }
        Gui, z__gutils_errorBox: Add, Text, x12 y293 w500 h17 , % stackTraceLabel
        Gui, z__gutils_errorBox: Add, ListView, x12 y313 w453 h146 gz__gutils_ex_gui_clickedList, Pos|Function|File|Ln#|Offset
        Gui, Add, Button, x12 y466 w89 h25 gz__gutils_ex_gui_copyDetails, Copy Details
        if (imageList) {
            LV_SetImageList(imageList)
        }
        for ix, entry in ex.trace {
            SplitPath, % entry.File, filename
            LV_Add("", ix, entry.Function, filename, entry.Line, entry.Offset)
        }
        Loop, 5
        {
            LV_ModifyCol(A_Index, "AutoHdr")
        }
        Gui, z__gutils_errorBox: Show, w477 h505
    } catch ex {
        Gui, z__gutils_errorBox: Destroy
        z__gutils_currentError := ""
        throw ex
    }
}

global z__gutils_oopsSetup := False

gOops_Setup() {
    if (z__gutils_oopsSetup) {
        return
    }
    z__gutils_oopsSetup := True
    z__gutils_setupNonObjectCheck()
    z__gutils_detectVsCode()
    OnError(Func("z__gutils_openExceptionGuiFor"))
}


global z__gutils_assertResults = {fail: 0, pass: 0}

z__gutils_assertOut(line) {
    e := Chr("0x001b")
    line := gStr_Replace(line, "\e", e)

    FileAppend, % "`r`n" line, *, UTF-8
}
z__gutils_reportAssertionResults(z := "") {
    fail := z__gutils_assertResults.fail
    pass := z__gutils_assertResults.pass
    line := gStr_Repeat("═", 50)
    len1 := gStr_Repeat(" ", 0)
    len2 := gStr_Repeat(" ", 13)
    finishLine := gStr_Repeat(" ", 18) "🏁 FINISHED 🏁"
    summaryLine := Format(len1 "\e[31;1m {3} Assertions:    ❌ {1} Failed    ✅ Passed {2}", fail, pass, fail + pass)
        warningLine := fail > 0 ? "SOME ASSERTIONS FAILED" : ""
        lines := [line
        , finishLine
        , line
        , summaryLine]

        if (fail > 0) {
            lines.Push("`r`n" len2 "❌ \e[31;1m" warningLine " ❌")
                lines.Push(line)
            }

            z__gutils_AssertOut(gArr_Join(lines, "`r`n"))

        }

        z__gutils_AssertLastFrame(entry) {
            return InStr(entry.Function, "gAssert")
        }

        z__gutils_ParseParens(ByRef str, ByRef pos, outerParen := "") {
            arr := []
            cur := outerParen
            results := []

            while (pos <= StrLen(str)){
                char := gSTr_At(str, pos)
                pos += 1
                if (gArr_Has(["[", "(", "{"], char)) {
                    if (cur) {
                        results.Push(cur)
                    }
                    cur := ""
                    result := z__gutils_ParseParens(str, pos, char)
                    results.Push(result)
                }
                else if (gArr_Has(["]", ")", "}"], char)) {
                    cur .= char
                    if (cur) {
                        results.Push(cur)
                    }
                    return results
                } else {
                    cur .= char
                }
            }
            if (cur) {
                results.Push(cur)
            }
            return results
        }

        z__gutils_flattenParenBlock(what) {
            if (gStr_Is(what)) {
                return what
            }
            return gArr_Join(gArr_Map(what, "z__gutils_flattenParenBlock"), "")
        }

        z__gutils_TrimParens(x) {
            return Trim(x)
        }

        z__gutils_nonEmpty(x) {
            return !!x
        }

        z__gutils_interpertAsFunctionCall(what) {
            fName := what[1]
            args := what[2]
            realArgs := []
            curArg := ""
            for i, arg in args {
                if (gArr_Is(arg)) {
                    curArg .= z__gutils_flattenParenBlock(arg)
                    continue
                }
                parts := gStr_Split(arg, ",")
                if (parts.MaxIndex() > 1) {
                    for i, p in parts {
                        curArg .= p
                        if (curArg) {
                            realArgs.Push(curArg)
                        }

                        curArg := ""
                    }
                    continue
                }
                curArg .= arg
            }
            if (curArg) {
                realArgs.Push(curArg)
            }
            realArgs[1] := gStr_TrimLeft(realArgs[1], "(")
            realArgs[realArgs.MaxIndex()] := gStr_TrimRight(realArgs[realArgs.MaxIndex()], ")")
            realArgs.InsertAt(1, fName)
            realArgs := gArr_Map(realArgs, "z__gutils_TrimParens")
            realArgs := gArr_Filter(realArgs, "z__gutils_nonEmpty")
            return realArgs
        }

        z__gutils_AssertGetArgs() {
            traces := gLang_StackTrace()
            lastAssertFrameIndex := gArr_FindLastIndex(traces, "z__gutils_AssertLastFrame")
            lastAssertFrame := traces[lastAssertFrameIndex]
            callingFrame := traces[lastAssertFrameIndex + 1]
            FileReadLine, Outvar, % callingFrame.File, % callingFrame.Line
            groups := Func(lastAssertFrame.Function).MaxParams
            params := gStr_Repeat(",([^\)]*)", groups - 1)
            pos := 1
            parsed := z__gutils_ParseParens(outVar, pos)
            unparsed := z__gutils_interpertAsFunctionCall(parsed)
            justFileName := gPath_Parse(callingFrame.File).filename
            unparsed.Push(Format("{1}:{2}", justFileName, callingFrame.Line))
            return unparsed
        }

        global z__gutils_assertFormats := {}
        z__gutils_ReportAssert(success, actual) {
            assertLine := ""
            if (z__gutils_assertResults.fail = 0 && z__gutils_assertResults.pass = 0) {
                OnExit(Func("z__gutils_reportAssertionResults"))
            }
            if (success) {
                assertLine .= "✅ "
                z__gutils_assertResults.pass += 1
            } else {
                assertLine .= "❌ "
                z__gutils_assertResults.fail += 1
            }

            args := z__gutils_AssertGetArgs()
            format := z__gutils_assertFormats[args[1]]
            if (!format) {
                gEx_Throw("You need to set a format for " args[1])
            }
            if (!success) {
                format .= " ACTUAL: " gStr(actual)

            }
            assertLine .= gStr_Indent(Format(format " [{4}]", args*))

            z__gutils_assertOut(assertLine)
        }

        z__gutils_assertFormats.gAssert_True := "{2}"
        gAssert_True(real) {
            z__gutils_ReportAssert(real || Trim(real) != "", real)
        }

        z__gutils_assertFormats.gAssert_False := "NOT {2}"
        gAssert_False(real) {
            z__gutils_ReportAssert(!real || Trim(real) = "", real)
        }

        z__gutils_assertFormats.gAssert_Eq := "{2} == {3}"
        gAssert_Eq(real, expected) {
            success := gLang_Equal(real, expected)
            z__gutils_ReportAssert(success, real)
        }

        z__gutils_assertFormats.gAssert_Throws := "{2} to throw error"
        gAssert_Throws(funcOrName, args*) {
            funcOrName := gLang_Func(funcOrName)
            hit := False
            try {
                funcOrName.Call(args*)
            } catch err {
                hit := True
            }
            z__gutils_ReportAssert(hit, "Error")
        }

        z__gutils_assertFormats.gAssert_MethodThrows := "{3} to throw error"

        gAssert_MethodThrows(self, name, args*) {
            method := ObjBindMethod(self, name)
            try {
                method.Call(args*)
            } catch err {
                hit := True
            }
            z__gutils_ReportAssert(hit, "Error")
        }

        z__gutils_assertFormats.gAssert_Has := "{2} HAS {3}"
        gAssert_Has(real, expectedToContain) {
            if (gArr_Is(real)) {
                success := gArr_Has(real, expectedToContain)
            } else if (gStr_is(real)) {
                success := gSTr_Has(real, expectedToContain)
            } else {
                gEx_Throw("Assertion invalid for " gStr(real))
            }
            z__gutils_ReportAssert(success, real)

        }
        z__gutils_assertFormats.gAssert_Gtr := "{2} > {3}"
        gAssert_Gtr(real, expected) {
            z__gutils_ReportAssert(real > expected, real)
        }



; A path that's been parsed into its components.
class gParsedPath {
    root := ""
    path := ""
    filename := ""
    dir := ""
    fileNoExt := ""
    ext := ""
    drive := ""
    __New(path) {
        SplitPath, % path, file, dir, ext, fileNoExt, drive
        this.filename := file
        this.dir := dir
        this.ext := ext
        this.fileNoExt := fileNoExt
        this.drive := drive
        return gObj_Checked(this)
    }
}

; Joins parts of a path with the right separator '\'.
gPath_Join(parts*) {
    return gArr_Join(gArr_Flatten(parts), "\")
}

; Parses a rooted or non-rooted path `path`.
gPath_Parse(path) {
    z__gutils__assertNotObject(path)
    return new gParsedPath(path)
}

; Resolves relative parts `parts`. Each segment is resolved based on the segment before it, until reaching the CWD. 
gPath_Resolve(parts*) {
    z__gutils__assertNotObject(parts*)
    ; https://www.autohotkey.com/boards/viewtopic.php?t=67050
    joined := gPath_Join(parts*)
    cc := DllCall("GetFullPathName", "str", joined, "uint", 0, "ptr", 0, "ptr", 0, "uint")
    VarSetCapacity(buf, cc*(A_IsUnicode?2:1))
    DllCall("GetFullPathName", "str", joined, "uint", cc, "str", buf, "ptr", 0, "uint")
    return buf
}

; Returns a relative file path based on `from` to the file `to`.
gPath_Relative(from, to) {
    z__gutils__assertNotObject(from, to)
    FILE_ATTRIBUTE_DIRECTORY := 0x10
    VarSetCapacity(outBuf, 300 * (A_IsUnicode ? 2 : 1))
    success := DllCall("Shlwapi.dll\PathRelativePathTo", "str", outBuf, "str", from, "uint", FILE_ATTRIBUTE_DIRECTORY, "str", to, "uint", FILE_ATTRIBUTE_DIRECTORY, "uint")
    return outBuf
}


class gOutFile {
    _fOut := ""
    _fErr := ""
    _stripAnsi := ""

    New(fOut, fErr) {
        return gObj_Checked(new gOutFile(fOut, fErr))
    }
    
    __New(fOut, fErr){
        base.__New()
        this._fOut := fOut
        this._fErr := fErr
    }

    Out(args*) {
        this._fStdOut.WriteLine(z__gutils_strArgs(args, this._stripAnsi))
    }

    Err(args*) {
        this._fErr.WriteLine(z__gutils_strArgs(args, this._stripAnsi))
    }
}

class gOutDebug  {
    New() {
        return gObj_Checked(new gOutDebug())
    }

    Out(args*) {
        OutputDebug, % z__gutils_strArgs(args, True)
    }

    Err(args*) {
        this.Out(args*)
    }
}

class gOutAll {
    _all := ""


    New(all) {
        return new gOutAll(all)
    }

    __New(all) {
        this._all := all
    }

    Out(args*) {
        for i, out in this._all {
            out.Out(args*)
        }
    }

    Err(args*) {
        for i, out in this._all {
            out.Err(args*)
        }
    }
}

z__gutils_strArgs(args, stripFormatting) {
    result := gArr_Join(gArr_Map(strs, "gStr"), " ")
    return RegExReplace(result, "i)\e")
}

z__gutils_encoding() {
    return A_IsUnicode ? "UTF-8" : ""
}

global z__gutils_stdOut := FileOpen("*", "w", z__gutils_encoding())
global z__gutils_stderr := FileOpen("**", "w", z__gutils_encoding())

gOut_Debug() {
    return new gOutDebug()
}

gOut_Std(ansiSupport := True) {
    return new gOutFile(z__gutils_stdOut, z__gutils_stderr, stripFormatting)
}

gOut_File(file, ansiSupport := False) {
    if (gType_Is(file, "File")) {
        gEx_Throw("Must be a file.")
    }
    return new gOutFile(file, file, ansiSupport)
}

z__gutils_getFormattingKws() {
    ; Based on chalk: https://github.com/chalk/chalk/blob/4d5c4795ad24c326ae16bfe0c39c826c732716a9/source/vendor/ansi-styles/index.js#L3
    styles := {reset: [0, 0]
        , bold: [1, 22]
        , dim: [2, 22]
        , italic: [2, 22]
        , underline: [4, 24]
        , overline: [53, 55]
        , inverse: [7, 27]
    , hidden: [8, 28]}

    for k, arr in styles {
        arr.Push("style")
    }
    gObj_Aliases(styles, {r: "reset"
            , b: "bold"
            , d: "dim"
            , i: "italic"
            , u: "underline"
            , o: "overline"
            , ii: "inverse"
    , h: "hidden"})

    colors := {black: [30, 39]
        , red: [31, 39]
        , green: [32, 39]
        , yellow: [33, 39]
        , blue: [34, 39]
        , magenta: [35, 39]
        , cyan: [36, 39]
    , white: [37, 39]}

    for k, arr in colors {
        arr.Push("color")
    }

    brights := {}
    for k, v in colors {
        ; The "bright" colors
        ; e.g black!
        xs := brights[k + "!"] := [v[1] + 60, v[2]]
        xs.Push("color")
    }
    bgColors := {}
    allColors := gObj_Merge(colors, brights)
    for k, v in allColors {
        ; the bg colors, e.g. bgblack
        xs := bgColors["bg" + k] := [v[1] + 10, 49]
        xs.Push("bgColor")
    }

    all := gObj_Merge(styles, colors, brights, bgColors)
    return all
}

gOut_ParseAnsi(input) {
    
}

; Std - log to std, 
gOut_Configure(modes*) {
    methods := []
    for i, mode in modes {
        if (mode = "std") {
            methods.Push(new gOutputMethod(""))
        }
    }
}

gOut(out) {
    OutputDebug, % gStr(Out)
}

gUtils(goops := False) {
    if (goops) {
        gOops_Setup()
    }
}