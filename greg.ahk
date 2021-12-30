__g_parentKeyPath(key) {
    finalSlash := gStr_LastIndexOf(key, "\")
    initialPath := gStr_Slice(key, 1, finalSlash - 1)
    return initialPath
}

__g_rootKeyNormalizer := {"HKLM" : "HKEY_LOCAL_MACHINE", 
"HKCR": "HKEY_CLASSES_ROOT",
"HKU": "HKEY_USERS",
"HKCU" : "HKEY_CURRENT_USER",
"HPD": "HKEY_PERFORMANCE_DATA"}

for key, v in __g_rootKeyNormalizer {
    __g_rootKeyNormalizer[v] = v
}

__g_normalizeRoot(key) {
    global __g_rootKeyNormalizer
    for key, v in 
}

class gRegEntry extends gDeclaredMembersOnly {
    name := ""
    type := ""
    key := ""
    modified := ""
    IsKey[] {
        get {
            return this.type = "KEY"
        }
    }

    __New(name, type, key, modified := "") {
        this.name := name
        this.type := type
        this.key := key
        this.modifier := modifier
    }

    _normalizeSubkey(otherKey) {
        if (gStr_IndexOf(otherKey, "\")) {
            if (!gSTr_IndexOf(otherKey, this.root)) {
                return this.root "\" otherKey
            }
            return otherKey
        } else {
            return this.key "\" otherKey
        }
    }

    Root[] {
        get {
            return gStr_Split(this.key, "\", "", 2)[1]
        }
    }

    Subkey[] {
        get {
            return gStr_Split(this.key, "\", "", 2)[2]
        }
    }

    IsRoot[] {
        get {
            return this.Root = this.key
        }
    }

    Get() {
        if (this.Kind = "KEY") {
            gEx_Throw("Cannot get the value of a key.")
        }
        if (!this.IsKey) {
            valueName := this.name
        }
        try {
            RegRead, x, % this.key, % this.name
            return x
        } catch ex {
            throw ex
        }
    }

    Set(newValue := "") {
        if (this.IsKey) {
            gEx_Throw("Cannot set value of a key.")
        }
        try {
            RegWrite, % this.type, % this.key, % this.name, % newValue
        } catch ex {
            throw ex
        }
    }


    Parent() {
        if (this.IsKey) {
            parentPath := __g_parentKeyPath(this.Key)
            return new gRegEntry("", "KEY", parentPath, "")
        } else {
            return new gRegEntry("", "KEY", this.key, "")
        }
    }

    GetSubkey(keyName) {
        if (!this.IsKey) {
            gEx_Throw("Cannot GetSubkey from a value.")
        }
        keyName := this._normalizeSubkey(keyName)
        for i, regE in this.List("K") 
        {
            if (keyName = regE.key) {
                return regE
            }
        }
        return ""
    }

    GetValue(value) {
        if (!this.IsKey) {
            gEx_Throw("Cannot GetValue from a value.")
        }
        for i, regV in this.List("V")
        {
            if (regV.name = value) {
                return regV
            }
        }
        return ""
    }

    Exists() {
        Loop, Reg, % this.key, KV
        {
            return true
        }
        return this.Parent().HasSubkey(this.key)
    }

    List(mode := "") {
        if (!this.IsKey) {
            gEx_Throw("Cannot list the contents of a value.")
        }
        arr := []
        Loop, Reg, % this.key, % mode
        {
            subkey := A_LoopRegSubkey
            type := A_LoopRegType
            if (type = "KEY") {
                subkey := A_LoopRegName
            }
            name := A_LoopRegType = "KEY" ? "" : A_LoopRegName
            key := A_LoopRegKey "\" subkey
            modified := A_LoopRegTimeModified
            arr.Push(new gRegEntry(name, type, key, modified))
        }
        return arr
    }
}

gReg(key, valueName := "") {
    entry := new gRegEntry("", "KEY", key)
    if (!entry.Exists()) {
        gEx_Throw("Registry key not found.")
    }
    if (valueName) {
        return entry.GetValue(valueName)
    }
    return entry
}
