
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
    New() {
        x := new gFuncSchema()
        x.name := ""
        x.args := []
        return gObj_Checked(x)
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
    schema := gFuncSchema.New()
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

class gCheckedCallable {
    _callable := ""
    _schema := ""

    AssertCallable(args*) {
        schema := this._schema
        if (args.MaxIndex() < schema.MinParams) {
            gEx_Throw(Format("Tried to call function '{1}'. It needs at least {2} params, got {3}.", schema.Name, schema.MinParams, args.MaxIndex()))
        }
        if (args.MaxIndex() > schema.MaxParams && !schema.IsVariadic) {
            gEx_Throw(Format("Tried to call function '{1}'. It needs at most {2} params, got {3}.", schema.name, schema.MaxParams, args.MaxIndex()))
        }
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

    New(target, schema) {
        cur := new gCheckedCallable()
        cur._callable := target
        cur._schema := schema
        return gObj_Checked(cur)
    }
}

gFunc_Checked(what, schema := "") {
    if (!schema) {
        if (!gType_Is(what, "Func")) {
            gEx_Throw(Format("Input is not a Func, and no param signatures were specified."))
        }
        return gCheckedCallable.New(what, what)
    }
    result := z__gutils_parseSchema(schema)
    return gCheckedCallable.New(what, result)
}