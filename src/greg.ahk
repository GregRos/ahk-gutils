#include gstr.ahk

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

class gRegKey extends gDeclaredMembersOnly {
    root := ""
    subKey := ""
    __New(parts*) {
        root := parts[1]
        this.root := z__gutils_noramlizeRoot(root)
        this.subkey := gPath_Join(gArr_Slice(parts, 2))
        if (!this.root) {
            gEX_Throw("Root was empty.")
        }
    }

    IsKey {
        get {
            return True
        }
    }

    IsRoot {
        get {
            return this.subkey == ""
        }
    }

    Key {
        get {
            if (!this.subkey) {
                return this.root
            }
            return gPath_Join(this.root, this.subkey)
        }
    }

    ; Gets a subkey 
    ; @param subkeys ...string[] Path components that appear in order. They will be rooted at the current key.
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

    Children() {
        arr := []
        Loop, Reg, % this.key, K
        {
            arr.Push(new gRegKey(A_LoopRegKey, A_LoopRegSubkey, A_LoopRegName))
        }
        return arr
    }

    Values() {
        values := {}
        Loop, Reg, % this.Key, V
        {
            RegRead, X
            values[A_LoopRegName] := X
        }
        ObjSetBase(values, gDeclaredMembersOnly)
        return values
    }

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

    Erase() {
        if (this.IsRoot) {
            gEx_Throw("You can't delete a root.")
        }
        try {
            RegDelete, % this.key
        }  catch err {
            gEx_ThrowObj(err)
        }
    }

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
        }  catch err {
            gEx_ThrowObj(err)
        }
        parsed := z__gutils_splitRegPath(fullKey)
        return new gRegKey(parsed[1], parsed[2])
    }

    Has(parts*) {
        parts.InsertAt(1, this.key)
        return z__gutils_checkKeyExists(gPath_Join(parts))
    }

    HasV(name) {
        Loop, Reg, % this.Key, V
        {
            if (A_LoopRegName = name) {
                return True
            }
        }
    }

    Get(name := "") {
        try {
            RegRead, X, % this.Key, % name
            return X
        }  catch err {
            return ""
        }
    }

    Set(name, type, value) {
        if (!gArr_Has(["REG_SZ", "REG_EXPAND_SZ", "REG_MULTI_SZ", "REG_DWORD", "REG_BINARY"], type)) {
            gEx_Throw("Type " type " is not a legal regisry value type.")
        }
        try {
            RegWrite, % type, % this.Key, % name, % value
        }  catch err {
            gEx_ThrowObj(err)
        }
    }

}

gReg(key) {
    if (!z__gutils_checkKeyExists(key)) {
        gEx_Throw(Format("Key '{1}' doesn't exist.", key))
    }
    parsed := z__gutils_splitRegPath(key)
    return new gRegKey(parsed[1], parsed[2])
}

gReg_Is(obj) {
    return obj.base = gRegKey
}