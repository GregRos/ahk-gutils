#include gstr.ahk
#include gpath.ahk
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
class gRegKey extends gMemberCheckingProxy {
    class Inner {
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

    __New(parts*) {
        inner := new this.inner(parts*)
        base.__New(inner)
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
