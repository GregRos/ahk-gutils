#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#NoEnv

#include gutils.ahk
gAssert(title, what) {
    OutputDebug, % "title: " what
    if (!!what) {
        
    }
}

gAssert_GetCodeLine() {
    trace := gLang_VarExists()
}
gAssert_Eq(real, expected) {
    OutputDebug, % gLang_StackTrace()
    formatted = TEST %title%: %real% == %expected%
    OutputDebug, % formatted
}

gAssert_Gtr(title, real, expected) {

}

gFunc() {
    OutputDebug, % gLang_StackTrace()
}

gAssert_Eq(gLang_VarExists(bzzt), 0)
gAssert("NameBuiltIn", gLang_IsNameBuiltIn("HasKey"))
gAssert("NormFunc", gLang_NormFunc("gAssert").Call)
gAssert("MouseCursorVisible", gSys_IsMouseCursorVisible())
gAssert("CurrentPid", gSys_CurrentPid() > 100)
gAssert_Eq("IsAppFullScreen", gSys_IsAppFullScreen(), false)

