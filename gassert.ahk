#include gutils.ahk
__g_AssertLastFrame(entry) {
    return InStr(entry.Function, "gAssert")
}

__g_ParseParens(ByRef str, ByRef pos) {
    arr := []
    cur := ""
    results := []
    while (pos < StrLen(str)){
        char := gSTr_At(str, pos)
        pos += 1
        if (char = "(") {
            if (cur) {
                results.Push(cur)
                cur := ""
            }
            result := __g_ParseParens(str, pos)
            results.Push(result)
        }
        else if (char = ")") {
            if (cur) {
                results.Push(cur)
            }
            return results
        } else {
            cur .= char
        }
    }
    if (cur) {
        results.Push(cur)
    }
    return results
}

__g_recParen(what) {
    if (gStr_Is(what)) {
        return Format("({1})", what)
    }
    return gStr_Join(gArr_Map(what, "__g_recParen"), "")
}

__g_reparse(what) {
    fName := what[1]
    args := what[2]
    realArgs := []
    curArg := ""
    for i, arg in args {
        if (gArr_Is(arg)) {
            curArg .= __g_recParen(arg)
            continue
        }
        parts := gStr_Split(arg, ",")
        if (parts.MaxIndex() > 1) {
            for i, p in parts {
                curArg .= p
                realArgs.Push(curArg)
                curArg := ""
            }
            continue
        }
        curArg .= arg
    }
    if (curArg) {
        realArgs.Push(curArg)
    }
    realArgs.InsertAt(1, fName)
    return realArgs
}

__g_splitByTopmostArgs(parsed) {
    args := []
    curArg := ""
    for i, v in parsed {
        if (gArr_Is(v)) {

        }
    }
}

__g_AssertGetArgs() {
    traces := gLang_StackTraceObj()
    lastAssertFrameIndex := gArr_FindLastIndex(traces, "__g_AssertLastFrame")
    lastAssertFrame := traces[lastAssertFrameIndex]
    callingFrame := traces[lastAssertFrameIndex + 1]
    FileReadLine, Outvar, % callingFrame.File, % callingFrame.Line
    groups := Func(lastAssertFrame.Function).MaxParams
    params := gStr_Repeat(",([^\)]*)", groups - 1)
    pos := 1
    parsed := __g_ParseParens(outVar, pos)
    unparsed := __g_reparse(parsed)
    return unparsed
}

__g_ReportAssert(success, actual) {
    assertFormats := {gAssert_Eq: "{2} == {3}"
        , gAssert_Gtr: "{2} > {3}"
        , gAssert_True: "{2}"
        , gAssert_False: "NOT {2}"
    , gAssert_Has: "{2} HAS {3}"}

    assertLine := ""
    if (success) {
        assertLine .= "✅ "
    } else {
        assertLine .= "❌ "
    }

    args := __g_AssertGetArgs()
    format := assertFormats[args[1]]
    if (!format) {
        Throw "You need to set a format for " args[1]
    }
    if (!success) {
        format .= " ACTUAL: " gStr(actual)

    }
    assertLine .= gStr_Indent(Format(format, args*))

    OutputDebug, % assertLine
}

gAssert_True(real) {
    __g_ReportAssert(real || Trim(real) != "", real)
}

gAssert_False(real) {
    __g_ReportAssert(!real || Trim(real) = "", real)
}

gAssert_Eq(real, expected) {
    success := gLang_Equal(real, expected)
    __g_ReportAssert(success, real)
}

gAssert_Has(real, expectedToContain) {
    if (gArr_Is(real)) {
        success := gArr_Has(real, expectedToContain)
    } else if (gStr_is(real)) {
        success := gSTr_Has(real, expectedToContain)
    } else {
        gEx_Throw("Assertion invalid for " gStr(real))
    }
    __g_ReportAssert(success, real)

}

gAssert_Gtr(real, expected) {
    __g_ReportAssert(real > expected, real)
}
