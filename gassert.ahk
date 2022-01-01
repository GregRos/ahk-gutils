#include gutils.ahk
__g_AssertLastFrame(entry) {
    return InStr(entry.Function, "gAssert")
}

__g_ParseParens(ByRef str, ByRef pos, outerParen := "") {
    arr := []
    cur := outerParen
    results := []

    while (pos <= StrLen(str)){
        char := gSTr_At(str, pos)
        pos += 1
        if (gArr_Has(["[", "(", "{"], char)) {
            if (cur) {
                results.Push(cur)
            }
            cur := ""
            result := __g_ParseParens(str, pos, char)
            results.Push(result)
        }
        else if (gArr_Has(["]", ")", "}"], char)) {
            cur .= char
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

__g_flattenParenBlock(what) {
    if (gStr_Is(what)) {
        return what
    }
    return gStr_Join(gArr_Map(what, "__g_flattenParenBlock"), "")
}

__g_TrimParens(x) {
    return Trim(x)
}

__g_nonEmpty(x) {
    return !!x
}

__g_interpertAsFunctionCall(what) {
    fName := what[1]
    args := what[2]
    realArgs := []
    curArg := ""
    for i, arg in args {
        if (gArr_Is(arg)) {
            curArg .= __g_flattenParenBlock(arg)
            continue
        }
        parts := gStr_Split(arg, ",")
        if (parts.MaxIndex() > 1) {
            for i, p in parts {
                curArg .= p
                if (curArg) {
                    realArgs.Push(curArg)
                }

                curArg := ""
            }
            continue
        }
        curArg .= arg
    }
    if (curArg) {
        realArgs.Push(curArg)
    }
    realArgs[1] := gStr_TrimLeft(realArgs[1], "(")
    realArgs[realArgs.MaxIndex()] := gStr_TrimRight(realArgs[realArgs.MaxIndex()], ")")
    realArgs.InsertAt(1, fName)
    realArgs := gArr_Map(realArgs, "__g_TrimParens")
    realArgs := gArr_Filter(realArgs, "__g_nonEmpty")
    return realArgs
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
    unparsed := __g_interpertAsFunctionCall(parsed)
    return unparsed
}

global __g_assertFormats := {}

__g_ReportAssert(success, actual) {
    assertLine := ""
    if (success) {
        assertLine .= "✅ "
    } else {
        assertLine .= "❌ "
    }

    args := __g_AssertGetArgs()
    format := __g_assertFormats[args[1]]
    if (!format) {
        Throw "You need to set a format for " args[1]
    }
    if (!success) {
        format .= " ACTUAL: " gStr(actual)

    }
    assertLine .= gStr_Indent(Format(format, args*))

    OutputDebug, % assertLine
}

__g_assertFormats.gAssert_True := "{2}"
gAssert_True(real) {
    __g_ReportAssert(real || Trim(real) != "", real)
}

__g_assertFormats.gAssert_False := "NOT {2}"
gAssert_False(real) {
    __g_ReportAssert(!real || Trim(real) = "", real)
}

__g_assertFormats.gAssert_Eq = "{2} == {3}"
gAssert_Eq(real, expected) {
    success := gLang_Equal(real, expected)
    __g_ReportAssert(success, real)
}

__g_assertFormats.gAssert_Has := "{2} HAS {3}"}
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
__g_assertFormats.gAssert_Gtr := "{2} > {3}"
gAssert_Gtr(real, expected) {
    __g_ReportAssert(real > expected, real)
}
