#include glang.ahk
#include garr.ahk
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

