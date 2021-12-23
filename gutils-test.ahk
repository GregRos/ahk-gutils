#include gutils.ahk
__g_AssertLastFrame(entry) {
    return InStr(entry.Function, "gAssert")
}

__g_AssertGetArgs() {
    traces := gLang_StackTraceObj()
    lastAssertFrameIndex := gArr_FindLastIndex(traces, "__g_AssertLastFrame")
    lastAssertFrame := traces[lastAssertFrameIndex]
    callingFrame := traces[lastAssertFrameIndex + 1]
    FileReadLine, Outvar, % callingFrame.File, % callingFrame.Line
    groups := Func(lastAssertFrame.Function).MaxParams
    params := gStr_Repeat(",([^\)]*)", groups - 1)
    regex := "Oi)^\s*" lastAssertFrame.Function "\((.*\))" params "\)\s*"
    res := RegExMatch(outVar, regex, OutStuff)
    count := OutStuff.Count()
    result := [lastAssertFrame.Function]
    Loop, % count
    {
        result.Push(Trim(OutStuff.Value(A_Index)))
    }
    return result
}

__g_ReportAssert(success, actual) {
    assertFormats := {gAssert_Eq: "{2} == {3}"
        , gAssert_Gtr: "{2} > {3}"
        , gAssert_True: "{2}"
    , gAssert_False: "NOT {2}"}

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
    success := true
    if (IsObject(real)) {
        if (real.MaxIndex()) {
            success := expected.MaxIndex() == real.MaxIndex()
            for index, value in real {
                success := value = expected[index]
                if (!success) {
                    break
                }
            }
        } else {
            success := false
        }
    } else {
        success := real == expected
    }
    __g_ReportAssert(success, real)
}

gAssert_Gtr(real, expected) {
    __g_ReportAssert(real > expected, real)
}

