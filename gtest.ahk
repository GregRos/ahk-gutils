#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#NoEnv

#include gutils.ahk

OutputDebug, % "hi"
OutputDebug, % gStr({a: 1})

_g_currentTest := ""
_g_textCount := 0
_g_failed := 0
_gTest_Out(what) {
    what := gArr_Map(what, gStr)
    what := gStr_Join(what, " ")
    what := gStr_Indent(what)
    OutputDebug, % what
}

gTest_Title(title) {
    title := IsObject(title) ? title.Name : title
    global _g_currentTest, _g_textCount, _g_failed
    if (_g_currentTest) {
        result := _g_failed > 0 ? "FAILURE" : "SUCCESS"
    }
    _g_currentTest := title
    _g_testCount++
formatted = %_g_testCount%) TEST %title%
OutputDebug, % "title: " what 
}

gTest_AssertFormat(success, real, expected, template) {
    global _g_failed
    out := []
    if (real == expected) {
        out.Push("✅")
    } else {
        _g_failed += 1
        out.Push("❌")
    }
    out.Push(Format(template, gStr(real), gStr(expected)))
    formatted := gStr_Indent(gStr_Join(out, " "))
    OutputDebug, % formatted
}

gAssert_Eq( real, expected) {
    OutputDebug, % gLang_StackTrace()
    gTest_AssertFormat(real == expected, real, expected, "{1} == {2}")
}

gAssert_Gtr(real, expected) {
    gTest_AssertFormat(real == expected, real, expected, "{1} == {2}")
}

gFunc() {
    OutputDebug, % gLang_StackTrace()
}
gTesT_Title(gLang_VarExists)
gAssert_Eq(gLang_VarExists(bzzt), 0)



