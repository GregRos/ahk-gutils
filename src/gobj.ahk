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

gObj_Is(self) {
    return IsObject(self)
}

gObj_HasAnyKey(self, keys*) {
    z__gutils_isObject("self", self, True)
    for i, k in keys {
        if (self.HasKey(k)) {
            return True
        }
    }
    return False
}

gObj_Keys(self) {
    z__gutils_isObject("self", self, True)
    keys := []
    for k in self {
        keys.Push(k)
    }
    return keys 
}

class gObjValidator extends gDeclaredMembersOnly {
    requiredKeys := ""
    optionalKeys := False
    name := ""
    __New(name, requiredKeys, optionalKeys := False) {
        this.name := name
        this.requiredKeys := requiredKeys
        this.optionalKeys := optionalKeys
    }

    Assert(obj) {
        result := this.Check(obj)
        if (!result.valid) {
            gEx_Throw(Format("{1} - {2}", this.name, result.reason))
        }
    }

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

gObj_NewValidator(name, requiredKeys := "", optionalKeys := True) {
    return new gObjValidator(name, requiredKeys, optionalKeys)
}

gObj_Pick(self, keys*) {
    result := {}
    for i, k in keys {
        result[k] := self[k]
    }
    return result
}

gObj_FromKeys(self, value := True) {
    result := {}
    for i, k in self {
        result[k] := value
    }
    return result
}

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

gObj_Assign(self, sources*) {
    for i, source in sources {
        for k, v in source {
            self[k] := v
        }
    }
}

gObj_Defaults(self, sources*) {
    sources := gArr_Reverse(sources)
    sources.Push(self)
    self := gObj_Assign({}, sources*)
    return self
}

gObj_Merge(sources*) {
    return gObj_Assign({}, sources*)
}