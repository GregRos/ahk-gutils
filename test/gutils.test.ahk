#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#NoEnv
#include ../
#include gutils.ahk
#include gutils-test.ahk
__g_findGreater5(x) {
    return x > 5
}

gAssert_Eq(gLang_VarExists(bzzt), 0)
gAssert_Eq(IsObject(gLang_NormFunc("gAssert_Gtr")), True)
gAssert_Eq(gSys_IsMouseCursorVisible(), True)
gAssert_Gtr(gSys_CurrentPid(), 1000)
gAssert_Eq(gSys_IsAppFullScreen(), False)
gAssert_Eq(gArr_Repeat("xyz", 3), ["xyz", "xyz", "xyz"])
gAssert_Eq(gArr_IndexOf([5, 6, 7], 6), 2)
gAssert_Eq(gArr_Find([5, 6, 7, 8], "__g_findGreater5"), 6)
gAssert_Eq(gArr_FIndIndexes([5, 6, 7, 8], "__g_findGreater5"), [2, 3, 4])
gAssert_Eq(gArr_FindIndex([5, 6, 7, 8], "__g_findGreater5"), 2)
gAssert_Eq(gArr_Order([5, 7, 6], "N"), [5, 6, 7])
gAssert_Eq(gArr_Concat([1, 2], [1], [3]), [1, 2, 1, 3])
gAssert_Eq(gArr_Slice([1, 2, 3, 4], -1, 0), [3, 4])
gAssert_Eq(gArr_Map([5, 6, 7], "__g_findGreater5"), [false, true, true])
gAssert_eq(gArr_Take([1, 2, 3], 2), [1, 2])
gAssert_Eq(gArr_Filter([1, 2, 3, 10], "__g_findGreater5"), [10])
gAssert_eq(gArr_FindLastIndex([5, 6, 7], "__g_findGreater5"), 3)
gAssert_Eq(gStr_PadRight("a", 3, "-"), "a--")
gAssert_Eq(gStr_PadLeft("a", 5, "-"), "----a")
gAssert_Eq(gStr_ToChars("abc"), ["a", "b", "c"])
gAssert_Eq(gStr_Indent("abc`nbcd", "_", 3), "___abc`n___bcd")
gAssert_Eq(gStr_StartsWith("bxyz", "bx"), True)
gAssert_Eq(gStr_Join([" 1", "x2", "3"], "_", "x "), "1_2_3")
gAssert_Eq(gStr_Repeat("x", 5, ","), "x,x,x,x,x")
gAssert_Eq(!!gSys_ProcessView(""), True)
gAssert_Eq(!!gSys_ComInvoker(0, ""), True)
ExitApp