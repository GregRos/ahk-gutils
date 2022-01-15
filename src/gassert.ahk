#include garr.ahk
#include gstr.ahk
#include glang.ahk

global z__gutils_assertResults = {fail: 0, pass: 0}

z__gutils_assertOut(line) {
    e := Chr("0x001b")
    line := gStr_Replace(line, "\e", e)

    FileAppend, % "`r`n" line, *, UTF-8
}
z__gutils_reportAssertionResults(z := "") {
    fail := z__gutils_assertResults.fail
    pass := z__gutils_assertResults.pass
    line := gStr_Repeat("═", 50)
    len1 := gStr_Repeat(" ", 0)
    len2 := gStr_Repeat(" ", 13)
    finishLine := gStr_Repeat(" ", 18) "🏁 FINISHED 🏁"
    summaryLine := Format(len1 "\e[31;1m {3} Assertions:    ❌ {1} Failed    ✅ Passed {2}", fail, pass, fail + pass)
        warningLine := fail > 0 ? "SOME ASSERTIONS FAILED" : ""
        lines := [line
        , finishLine
        , line
        , summaryLine]

        if (fail > 0) {
            lines.Push("`r`n" len2 "❌ \e[31;1m" warningLine " ❌")
                lines.Push(line)
            }

            z__gutils_AssertOut(gArr_Join(lines, "`r`n"))

        }

        z__gutils_AssertLastFrame(entry) {
            return InStr(entry.Function, "gAssert")
        }

        z__gutils_ParseParens(ByRef str, ByRef pos, outerParen := "") {
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
                    result := z__gutils_ParseParens(str, pos, char)
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

        z__gutils_flattenParenBlock(what) {
            if (gStr_Is(what)) {
                return what
            }
            return gArr_Join(gArr_Map(what, "z__gutils_flattenParenBlock"), "")
        }

        z__gutils_TrimParens(x) {
            return Trim(x)
        }

        z__gutils_nonEmpty(x) {
            return !!x
        }

        z__gutils_interpertAsFunctionCall(what) {
            fName := what[1]
            args := what[2]
            realArgs := []
            curArg := ""
            for i, arg in args {
                if (gArr_Is(arg)) {
                    curArg .= z__gutils_flattenParenBlock(arg)
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
            realArgs := gArr_Map(realArgs, "z__gutils_TrimParens")
            realArgs := gArr_Filter(realArgs, "z__gutils_nonEmpty")
            return realArgs
        }

        z__gutils_AssertGetArgs() {
            traces := gLang_StackTrace()
            lastAssertFrameIndex := gArr_FindLastIndex(traces, "z__gutils_AssertLastFrame")
            lastAssertFrame := traces[lastAssertFrameIndex]
            callingFrame := traces[lastAssertFrameIndex + 1]
            FileReadLine, Outvar, % callingFrame.File, % callingFrame.Line
            groups := Func(lastAssertFrame.Function).MaxParams
            params := gStr_Repeat(",([^\)]*)", groups - 1)
            pos := 1
            parsed := z__gutils_ParseParens(outVar, pos)
            unparsed := z__gutils_interpertAsFunctionCall(parsed)
            justFileName := gPath_Parse(callingFrame.File).filename
            unparsed.Push(Format("{1}:{2}", justFileName, callingFrame.Line))
            return unparsed
        }

        global z__gutils_assertFormats := {}
        z__gutils_ReportAssert(success, actual) {
            assertLine := ""
            if (z__gutils_assertResults.fail = 0 && z__gutils_assertResults.pass = 0) {
                OnExit(Func("z__gutils_reportAssertionResults"))
            }
            if (success) {
                assertLine .= "✅ "
                z__gutils_assertResults.pass += 1
            } else {
                assertLine .= "❌ "
                z__gutils_assertResults.fail += 1
            }

            args := z__gutils_AssertGetArgs()
            format := z__gutils_assertFormats[args[1]]
            if (!format) {
                gEx_Throw("You need to set a format for " args[1])
            }
            if (!success) {
                format .= " ACTUAL: " gStr(actual)

            }
            assertLine .= gStr_Indent(Format(format " [{4}]", args*))

            z__gutils_assertOut(assertLine)
        }

        z__gutils_assertFormats.gAssert_True := "{2}"
        gAssert_True(real) {
            z__gutils_ReportAssert(real || Trim(real) != "", real)
        }

        z__gutils_assertFormats.gAssert_False := "NOT {2}"
        gAssert_False(real) {
            z__gutils_ReportAssert(!real || Trim(real) = "", real)
        }

        z__gutils_assertFormats.gAssert_Eq := "{2} == {3}"
        gAssert_Eq(real, expected) {
            success := gLang_Equal(real, expected)
            z__gutils_ReportAssert(success, real)
        }

        z__gutils_assertFormats.gAssert_Has := "{2} HAS {3}"
        gAssert_Has(real, expectedToContain) {
            if (gArr_Is(real)) {
                success := gArr_Has(real, expectedToContain)
            } else if (gStr_is(real)) {
                success := gSTr_Has(real, expectedToContain)
            } else {
                gEx_Throw("Assertion invalid for " gStr(real))
            }
            z__gutils_ReportAssert(success, real)

        }
        z__gutils_assertFormats.gAssert_Gtr := "{2} > {3}"
        gAssert_Gtr(real, expected) {
            z__gutils_ReportAssert(real > expected, real)
        }
