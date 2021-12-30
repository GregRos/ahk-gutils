#include _common.ahk
#include garr.ahk
__g_isObject(name, obj, canBeArray := False) {
    if (!isObject(obj)) {
        gEx_Throw("Parameter " name " is not an object: " obj)
    }
    if (!canBeArray) {
        if (obj.MaxIndex() > 0) {
            gEx_Throw("Parameter " name " is an array.")
        }
    }
}

gObj_Is(obj) {
    return IsObject(obj)
}

gObj_HasAnyKey(obj, keys*) {
    __g_isObject("obj", obj, True)
    for i, k in keys {
        if (obj.HasKey(k)) {
            return True
        }
    }
    return False
}

gObj_Keys(obj) {
    __g_isObject("obj", obj, True)
    keys := []
    for k in obj {
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

gObj_Pick(obj, keys*) {
    result := {}
    for i, k in keys {
        result[k] := obj[k]
    }
    return result
}

gObj_FromKeys(keys, value := True) {
    result := {}
    for i, k in keys {
        result[k] := value
    }
    return result
}

gObj_Omit(obj, keys*) {
    result := {}
    keysObj := gObj_FromKeys(keys)
    for i, k in obj {
        if (!keysObj.HasKey(k)) {
            result[k] := obj[k]
        }
    }
    return result
}