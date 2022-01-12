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
    cls := z__gutils_getTypeCode(z__gutils_example)
    prop := z__gutils_getTypeCode(ObjRawGet(z__gutils_example, "get"))
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