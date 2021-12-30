#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#NoEnv
#include ../
#include gutils.ahk
gEx_FancyInit()
__g_findGreater5(x) {
    return x > 5
}

gAssert_Eq(gLang_VarExists(bzzt), 0)
gAssert_Eq(IsObject(gLang_NormFunc("gAssert_Gtr")), True)

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
gAssert_Eq(gStR_IndexOf("abc", "b"), 2)
gAssert_Eq(gStr_Reverse("abc"), "cba")
gAssert_eq(gStr_LastIndexOf("abcabca", "a"), 7)
gAssert_Eq(gStr_Contains("abc", "b"), True)
gAssert_eq(gStr_EndsWith("abc", "bc"), True)
gAssert_eq(gStr_StartsWith("abc", "ab"), True)
gAssert_Eq(gStr_Upper("abc"), "ABC")
gAssert_Eq(gStr_Lower("ABC"), "abc")
gAssert_Eq(gStr_Len("abc"), 3)
gAssert_eq(gStr_Trim("aba", "a"), "b")
gAssert_eq(gStr_TrimLeft("aba", "a"), "ba")
gAssert_Eq(gStr_TrimRight("aba", "a"), "ab")
gAssert_eq(gStr_FromChars(["a", "b", "c"]), "abc")
gAssert_Eq(gStr_FromCodeArray([asc("a"), asc("b"), asc("c")]), "abc")
gAssert_Eq(gStr_Replace("aaabbb", "a", "b", 2), "bbabbb")
gAssert_Eq(gStr_ToChars("abc"), ["a", "b", "c"])

gAssert_Eq(!!gSys_ProcessView(""), True)
gAssert_Eq(!!gSys_ComInvoker(0, ""), True)
gAssert_Gtr(gSys_CurrentPid(), 1000)

gAssert_Eq(gWin_IsMouseCursorVisible(), True)
gAssert_Eq(gWin_IsFullScreen(), False)
gAssert_eq(gWin_GetId({title: "Code", excludeTitle:"Started", mode: 2}), WinExist("A"))
gWin_GetId({mode: 2, speed: "Slow", hiddenWindows: True, hiddenText: True})
gAssert_Eq((A_TitleMatchMode), 1)
gAssert_Eq((A_TitleMatchModeSpeed), "Fast")
gAssert_Eq((A_DetectHiddenText), False)
gAssert_Eq((A_DetectHiddenWindows), False)
ExitApp