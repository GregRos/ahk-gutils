#include gpath.ahk
__g_parentKeyPath(key) {
    finalSlash := gStr_LastIndexOf(key, "\")
    initialPath := gStr_Slice(key, 1, finalSlash - 1)
    return initialPath
}

__g_roots := {"HKLM" : "HKEY_LOCAL_MACHINE"
    ,"HKCR": "HKEY_CLASSES_ROOT"
    ,"HKU": "HKEY_USERS"
    ,"HKCU" : "HKEY_CURRENT_USER"
,"HPD": "HKEY_PERFORMANCE_DATA"}

; This is needed so the normalizer is idempotent and also to normalize case
for key, v in __g_roots {
    __g_roots[v] := v
}

__g_noramlizeRoot(root) {
    global __g_roots
    return __g_roots[root]
}

__g_parseRegPath(path) {
    normalizedAsRoot := __g_noramlizeRoot(path)
    if (normalizedAsRoot) {
        return [normalizedAsRoot, ""]
    }
    parsed := gStr_Split(path, "\", , 2)
    root := ""
    subkey := ""
    if (parsed.MaxIndex() = 2) {
        normalizedRoot := __g_noramlizeRoot(parsed[1])
        if (!normalizedRoot) {
            return ["", path]
        }
        return [normalizedRoot, parsed[2]]
    } else {
        return ["", path]
    }
}

__g_resolveRegPath(parts*) {
    ; Format the registry path like an fs path and use the syscall to resolve it
    parts.InsertAt(1, "C:")
    resolved := gPath_Resolve(parts*)
    noDrive := gStr_Slice(resolved, 4)
    resolvedRoot := gStr_Trim(gPath_Join(__g_parseRegPath(noDrive)), "\")
    return resolvedRoot
}

__g_checkKeyExists(rootedKey) {
    parsed := __g_parseRegPath(rootedKey)
    if (!parsed[2]) {
        return True
    }
    Loop, Reg, % rootedKey, KVR
    {
        return True
    }
    parent := __g_resolveRegPath(rootedKey, "..")
    Loop, Reg, % parent, K
    {
        curFullKey := gPath_Join(A_LoopRegKey, A_LoopRegSubkey, A_LoopRegName)
        if (curFullKey = ) {
            return True
        }
    }
    return False
}

class gRegValue extends gDeclaredMembersOnly {
    name := ""
    type := ""
    Parent := ""
    IsKey {
        get {
            return False
        }
    }

    __New(parent, name, type := "") {
        this.name := name
        this.type := type
        this.Parent := parent
    }

    Get() {
        try {
            RegRead, X, % this.Parent.Key, % this.name
            return X
        } catch ex {
            throw ex
        }
    }

    Set(newValue := "") {
        try {
            RegWrite, % this.type, % this.key, % this.name, % newValue
        } catch ex {
            throw ex
        }
    }

    Remove() {
        if (this.name = "") {
            gEx_Throw("You can't delete the default value.")
        }
        try {
            ; RegDelete, % this.Parent.Key, % this.Name
            gOut("Will delete " this.parent.key ":" this.name)

        } catch ex {
            throw ex
        }
    }
}

class gRegKey extends gDeclaredMembersOnly {
    root := ""
    subKey := ""
    __New(parts*) {
        root := parts[1]
        this.root := __g_noramlizeRoot(root)
        this.subkey := gPath_Join(gArr_Slice(parts, 2))
        if (!this.root) {
            gEX_Throw("Root was empty.")
        }
        if (!this.key) {
            gEX_Throw("Subkey was empty.")
        }
    }

    IsKey {
        get {
            return True
        }
    }

    IsRoot {
        get {
            return this.subkey = ""
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
        resolved := __g_resolveRegPath(this.Key, joined)
        if (!__g_checkKeyExists(resolved)) {
            return ""
        }
        parts := __g_parseRegPath(resolved)
        child := new gRegKey(parts*)
        return child
    }

    Parent {
        get {
            if (this.IsRoot) {
                gEx_Throw("Can't get parent of root.")
            }
            parent := __g_resolveRegPath(this.Key, "..")
            parsed := __g_parseRegPath(parent)
            return new gRegKey(parsed[1], parsed[2])
        }
    }

    Value(name := "") {
        Loop, Reg, % this.key, V
        {
            if (A_LoopRegName = name) {
                return new gRegValue(this, name, A_LoopRegType)
            }
        }
        return ""
    }

    Children() {
        arr := []
        Loop, Reg, % this.key, "K"
        {
            arr.Push(new gRegKey(A_LoopRegKey, A_LoopRegSubkey, A_LoopRegName))
        }
        return arr
    }

    Values() {
        arr := []
        Loop, Reg, % this.Key, V
        {
            arr.Push(new gRegValue(this, A_LoopRegName, A_LoopRegType))
        }
        return arr
    }

    Remove() {
        if (this.IsRoot) {
            gEx_Throw("You can't delete a root.")
        }
        try {
            gOut("Will delete " this.Key)
            ;RegDelete, % this.Key
        } catch err {
            throw err
        }
    }

    CreateSubkey(subkey) {
        fullKey := __g_resolveRegPath(this.Key, subkey)
        if (__g_checkKeyExists(fullKey)) {
            gEx_Throw(Format("Key '{1}' already exists.", fullKey))
        }
        RegWrite, REG_DWORD, % fullKey
        parsed := __g_parseRegPath(fullKey)
        return new gRegKey(parsed[1], parsed[2])

    }

    CreateValue(type, name, value) {
        RegWrite, % type, % this.Key, % name, % value
        return new gRegValue(this, name, type)
    }
}

gReg(key) {
    if (!__g_checkKeyExists(key)) {
        gEx_Throw(Format("Key '{1}' doesn't exist.", key))
    }
    parsed := __g_parseRegPath(key)
    return new gRegKey(parsed[1], parsed[2])
}
