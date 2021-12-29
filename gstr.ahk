﻿#include _internals.ahk
gStr_PadRight(str, toWidth, char := " ") {
    myLen := StrLen(str)
    extras := toWidth - myLen
    if (extras <= 0) {
        return str
    }
    padding := gStr_Repeat(char, extras)
    result := str padding
    return result
}

gStr_PadLeft(str, toWidth, char := " ") {
    myLen := StrLen(str)
    extras := toWidth - myLen
    if (extras <= 0) {
        return str
    }
    padding := gStr_Repeat(char, extras)
    result := padding str 
    return result
}

gStr_ToChars(str) {
    list:=[]
    Loop, Parse, str 
    {
        list.Insert(A_LoopField)
    }
    return list
}

gStr_Indent(str, indent = " ", count = 1) {
    if (!str) {
        return str
    }
    indentStr := ""
    Loop, % count
    {
        indentStr.=indent
    }
    indented := ""

    StringReplace, indented, str, `n, `n%indentStr%, All
    indented:=indentStr indented
    return indented
}

gStr_StartsWith(where, what, caseSensitive = 0) {
    if (what == "") {
        return true
    }
    len := StrLen(what)
    initial := SubStr(where, 1, len)
    return caseSensitive ? initial == what : initial = what
}

gStr_EndsWith(where, what, caseSensitive = 0) {
    if (what == "") {
        return true
    }
    len := StrLen(what)
    final := gStr_Slice(where, -len+1)
    return caseSensitive ? final == what : final = what
}

gStr(obj) {
    if (!IsObject(obj)) {
        return "" + obj
    }
    if (obj.MaxIndex()) {
        stringified := gArr_Map(obj, "gStr")
        return "[" gStr_Join(stringified, ", ") "]"
    }
    stringified := []
    for key, value in obj {
        stringified.Push(Format("{1}: {2}", key, gStr(value)))
    }
    return "{`n" gSTr_Indent(gStr_Join(stringified, ",`n"), " ", 1) "`n}"
}

gStr_Join(what, sep:="", omit:="") {
    for ix, value in what {
        if (A_Index != 1) {
            res .= sep
        }
        value := Trim(value, omit)
        res .= value
    }
    return res
}

gStr_Repeat(what, count, delim := "") {
    result := ""
    Loop, % count 
    {
        if (A_Index != 1) {
            result .= delim
        }
        result.= what
    }
    return result
}

gStr_IndexOf(where, what, case := false, pos := 1, occurrence := 1) {
    return InStr(where, what, case, pos, occurrence)
}

gStr_Reverse(what) {
    str := ""
    Loop, Parse, % what 
    {
        str := A_LoopField str
    }

    return str
}

gStr_LastIndexOf(where, what, case := false, pos := 1) {
    reverse := gStr_Reverse(where)
    return StrLen(where) - gStR_IndexOf(where, what, case, pos) + 1
}

gStr_Slice(where, start := 1, end := 0) {
    start := __g_NormalizeIndex(start, StrLen(where))
    end := __g_NormalizeIndex(end, StrLen(where))
    return SubStr(where, start, end - start + 1)
}

gStr_Split(what, delimeters, omit := "", max := 0) {
    return StrSplit(what, delimeters, omit, max)
}

gStr_FromWArray(wArray) {
    result := ""
    for x in wArray {
        result .= chr(x)
    }
    return result
}

gStr_FromChars(cArray) {
    result := ""
    for x in cArray {
        result .= x
    }
    return result
}

gStr_Guid() {
    ; from https://gist.github.com/ijprest/3845947
    format = %A_FormatInteger% ; save original integer format 
    SetFormat Integer, Hex ; for converting bytes to hex 
    VarSetCapacity(A,16) 
    DllCall("rpcrt4\UuidCreate","Str",A) 
    Address := &A 
    Loop 16 
    { 
        x := 256 + *Address ; get byte in hex, set 17th bit 
        StringTrimLeft x, x, 3 ; remove 0x1 
        h = %x%%h% ; in memory: LS byte first 
        Address++ 
    } 
    SetFormat Integer, %format% ; restore original format 
    h := SubStr(h,1,8) . "-" . SubStr(h,9,4) . "-" . SubStr(h,13,4) . "-" . SubStr(h,17,4) . "-" . SubStr(h,21,12)
    return h
}