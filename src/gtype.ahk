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
        tn := z__gutils_getTypeName(target)
        if (tn != "") {
            gEx_Throw(Format("Can't create a proxy for '{1}', it's a built-in object.", tn))
        }
        this.__gproxy_target := target
        this.__gproxy_modes := modes
        this.__gproxy_checking := True
    }

    __gproxy_target_get(name, byref found) {
        target := ObjRawGet(this, "__gproxy_target")
        z := gObj_RawGet(target, name, True, found)
        return z
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
            found := 0
            value := this.__gproxy_target_get(name, found)
            if (!found && !value) {
                gEX_Throw(Format("Tried to call name '{1}', but it doesn't exist.", name))
            }
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
            found := False
            property := this.__gproxy_target_get(name, found)
            if (!found) {
                gEx_Throw(Format("Tried to set name '{1}', but it wasn't defined.", name))
            }
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
            found := False
            prop := this.__gproxy_target_get(name, found)
            if (!found) {
                gEx_Throw(Format("Tried to get name '{1}', but it wasn't defined.", name))
            }
            if (gType_Is(prop, "Property") && !prop.get) {
                gEx_Throw(Format("Tried to get name '{1}', but it was a property with no setter.", name))
            }
            return target[name, keys*]
        }
    }
}

gObj_Checked(target) {
    return new gMemberCheckingProxy(target)
}