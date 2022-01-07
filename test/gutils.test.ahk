#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#NoEnv

#include ../src/
#include gutils.ahk
gUtils(True)
z__gutils_findGreater5(x) {
    return x > 5
}


z__gutils_test() {
    gAssert_Eq(gLang_VarExists(bzzt), 0)
    gAssert_Eq(IsObject(gLang_Func("gAssert_Gtr")), True)
    gAssert_Eq(gArr_Repeat("xyz", 3), ["xyz", "xyz", "xyz"])
    gAssert_Eq(gArr_IndexOf([5, 6, 7], 6), 2)
    gAssert_Eq(gArr_Find([5, 6, 7, 8], "z__gutils_findGreater5"), 6)
    gAssert_Eq(gArr_FIndIndexes([5, 6, 7, 8], "z__gutils_findGreater5"), [2, 3, 4])
    gAssert_Eq(gArr_FindIndex([5, 6, 7, 8], "z__gutils_findGreater5"), 2)
    gAssert_Eq(gArr_Order([5, 7, 6], "N"), [5, 6, 7])
    gAssert_Eq(gArr_Concat([1, 2], [1], [3]), [1, 2, 1, 3])
    gAssert_Eq(gArr_Slice([1, 2, 3, 4], -1, 0), [3, 4])
    gAssert_Eq(gArr_Map([5, 6, 7], "z__gutils_findGreater5"), [false, true, true])
    gAssert_eq(gArr_Take([1, 2, 3], 2), [1, 2])
    gAssert_Eq(gArr_Filter([1, 2, 3, 10], "z__gutils_findGreater5"), [10])
    gAssert_eq(gArr_FindLastIndex([5, 6, 7], "z__gutils_findGreater5"), 3)

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
    gAssert_Eq(gStr_Has("abc", "b"), True)
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

    testObj := {a: 1, b: 1, c: 3}
    gAssert_Eq(gObj_HasAnyKey(testObj, "x", "b"), True)
    gAssert_Eq(gObj_Keys(testObj), ["a", "b", "c"])
    gAssert_Eq(gObj_Pick(testObj, "a", "b"), {a: 1, b:1})
    gAssert_Eq(gObj_FromKeys(["a", "b"]), {a: 1, b: 1})
    gAssert_Eq(gObj_Omit(testObj, "b", "c"), {b:1, c:3})
    a := {c: 4}
    b := {a: 1, b: 2}
    gObj_Assign(a, b)
    gAssert_eq(a, {a: 1, b: 2, c: 4})
    gAssert_Eq(!!gSys_ComInvoker(0, ""), True)
    gAssert_Gtr(gSys_Pid(), 1000)

    gAssert_Eq(gWin_IsMouseCursorVisible(), True)
    gAssert_Eq(gWin_IsFullScreen(), False)
    gWin_SetMatchingInfo({mode: 2})
    win := gWin_Get({title: "Code", excludeTitle:"Started"})
    gAssert_Eq(win.ProcessName, "code.exe")
    gAssert_Has(win.Title, "Visual Studio Code")
    gAssert_Has(win.ProcessPath, "\code.exe")
    gAssert_Eq(win.MinMax, 1)
    gAssert_Eq(win.Class, "Chrome_WidgetWin_1")

    dllKey := gReg("HKCR\.dll")
    gAssert_eq(gReg_Is(dllKey), True)
    gAssert_eq(gReg_Is([]), False)
    gAssert_Eq(dllKey.IsKey, True)
    gAssert_eq(dllKey.Get(), "dllfile")
    gAssert_Eq(dllKey.Get("Content Type"), "application/x-msdownload")
    parent := dllKey.Parent
    gAssert_Eq(parent.Key, "HKEY_CLASSES_ROOT")
    gAssert_Eq(parent.IsRoot, True)
    exeKey := parent.Child(".exe")
    gAssert_Eq(exeKey.IsKey, True)
    gAssert_Eq(exeKey.IsRoot, False)
    gAssert_Eq(exeKey.Get(), "exefile")
    testSubkey := gReg("HKEY_CURRENT_USER\System").Create("test-key")
    gAssert_Eq(testSubkey.IsKey, True)
    gAssert_Eq(IsObject(gReg("HKCU\System\test-key")), True)
    testSubkey.Set("should_be_100", "REG_DWORD", 100)
    gAssert_Eq(testSubkey.Get("should_be_100"), 100)
    gAssert_Eq(testSubkey.HasV("should_be_100"), True)
    testSubkey.EraseValue("should_be_100")
    gAssert_Eq(testSubkey.Get("should_be_100"), "")
    
    testSubkey.Erase()

    ExitApp
}

z__gutils_test()
