#include glang.ahk
gStr_PadRight(ByRef str, toWidth, char := " ") {
    myLen := StrLen(str)
    extras := toWidth - myLen
    if (extras <= 0) {
        return str
    }
    padding := gStr_Repeat(char, extras)
    result := str padding
    return result
}

gStr_PadLeft(ByRef str, toWidth, char := " ") {
    myLen := StrLen(str)
    extras := toWidth - myLen
    if (extras <= 0) {
        return str
    }
    padding := gStr_Repeat(char, extras)
    result := padding str 
    return result
}

gStr_ToChars(ByRef str) {
    list:=[]
    Loop, Parse, str 
    {
        list.Insert(A_LoopField)
    }
    return list
}

gStr_Indent(ByRef str, indent = " ", count = 1) {
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

gStr_StartsWith(ByRef where, ByRef what, caseSensitive = 0) {
    if (what == "") {
        return true
    }
    len := StrLen(what)
    initial := SubStr(where, 1, len)
    return caseSensitive ? initial == what : initial = what
}

gStr_EndsWith(ByRef where, ByRef what, caseSensitive = 0) {
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
    if (obj.MaxIndex() != "") {
        stringified := gArr_Map(obj, "gStr")
        return "[" gStr_Join(stringified, ", ") "]"
    }
    stringified := []
    for key, value in obj {
        stringified.Push(Format("{1}: {2}", key, gStr(value)))
    }
    return "{`n" gSTr_Indent(gStr_Join(stringified, ",`n"), " ", 1) "`n}"
}

gStr_Join(ByRef what, sep:="", omit:="") {
    for ix, value in what {
        if (!gStr_Is(value)) {
            value := gStr_Join(value, sep, omit)
        }
        if (A_Index != 1) {
            res .= sep
        }
        value := Trim(value, omit)
        res .= value
    }
    return res
}

gStr_Trim(ByRef what, chars := " `t") {
    return Trim(what, chars)
}

gStr_TrimLeft(ByRef what, chars := " `t") {
    return LTrim(what, chars)
}

gStr_TrimRight(ByRef what, chars := " `t") {
    return RTrim(what, chars)
}

gStr_Len(ByRef what) {
    return StrLen(what)
}

gStr_Repeat(ByRef what, count, delim := "") {
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

gStr_IndexesOf(ByRef where, ByRef what, case := false) {
    arr := []
    occur := 1
    last := ""
    Loop {
        if (last != "") {
            arr.Push(last)
        }
        last := gStr_IndexOf(where, what, case, A_Index)
    } until last = 0
    return arr
}

gStr_IndexOf(ByRef where, ByRef what, case := false, pos := 1, occurrence := 1) {
    return InStr(where, what, case, pos, occurrence)
}

gStr_Reverse(ByRef what) {
    str := ""
    Loop, Parse, % what 
    {
        str := A_LoopField str
    }

    return str
}

gStr_LastIndexOf(ByRef where, ByRef what, case := false, pos := 1) {
    cur := 0
    loop {
        last := cur
        cur := gStr_IndexOf(where, what, case, cur + 1)
    } until cur = 0
    return last
}

gStr_SplitAt(ByRef where, pos) {
    pos := __g_NormalizeIndex(pos, StrLen(where))
    first := gStr_Slice(where, pos - 1)
    last := gStr_Slice(where, pos + 1)
    return [first, last]
}

gStr_Slice(ByRef where, start := 1, end := 0) {
    start := __g_NormalizeIndex(start, StrLen(where))
    end := __g_NormalizeIndex(end, StrLen(where))
    return SubStr(where, start, end - start + 1)
}

gStr_Split(what, delimeters := "", omit := "", max := -1) {
    return StrSplit(what, delimeters, omit, max)
}

gStr_FromCodeArray(wArray) {
    result := ""
    for i, x in wArray {
        result .= chr(x)
    }
    return result
}

gStr_FromChars(cArray) {
    result := ""
    for i, x in cArray {
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

gStr_Lower(ByRef InputVar, T := "") {
    StringLower, v, InputVar, %T%
    Return, v
}

gStr_Upper(ByRef InputVar, T := "") {
    StringUpper, v, InputVar, %T%
    Return, v
}

gStr_Replace(ByRef InputVar, ByRef SearchText, ByRef ReplaceText, Limit := -1) {
    return StrReplace(InputVar, SearchText, ReplaceText, , Limit)
}

gStr_Has(ByRef where, ByRef what, Case := false, Start := 1) {
    return gStr_IndexOf(where, what, Case, Start) > 0
}

gStr_Is(ByRef what) {
    return !IsObject(what)
}

gStr_At(ByRef what, pos) {
    return SubStr(what, pos, 1)
}

gStr_Match(haystack, needle, options := "", pos := 1) {
    needle := options "O)" needle
    RegExMatch(haystack, needle, match, pos)
    return match
}

gStr_Matches(haystack, needle, options := "", pos := 1) {
    array:=[]
    needle := options "O)" needle
    while (pos := RegExMatch(haystack, needle, match, ((pos>=1) ? pos : 1)+StrLen(match))) {
        array.Push(match)
    }
    Return array
}

class gParsedPath extends gDeclaredMembersOnly {
    root := ""
    path := ""
    filename := ""
    dir := ""
    fileNoExt := ""
    ext := ""
    drive := ""
    __New(path) {
        SplitPath, % path, file, dir, ext, fileNoExt, drive
        this.filename := file
        this.dir := dir
        this.ext := ext
        this.fileNoExt := fileNoExt
        this.drive := drive
    }
}

gPath_Join(parts*) {
    return gStr_Join(gArr_Flatten(parts), "\")
}

gPath_Parse(path) {
    return new gParsedPath(path)
}

gPath_Resolve(parts*) {
    ; https://www.autohotkey.com/boards/viewtopic.php?t=67050
    joined := gPath_Join(parts*)
    cc := DllCall("GetFullPathName", "str", joined, "uint", 0, "ptr", 0, "ptr", 0, "uint")
    VarSetCapacity(buf, cc*(A_IsUnicode?2:1))
    DllCall("GetFullPathName", "str", joined, "uint", cc, "str", buf, "ptr", 0, "uint")
    return buf
}

gPath_Relative(from, to) {
    FILE_ATTRIBUTE_DIRECTORY := 0x10
    VarSetCapacity(outBuf, 300 * (A_IsUnicode ? 2 : 1))
    success := DllCall("Shlwapi.dll\PathRelativePathTo", "str", outBuf,  "str", from, "uint", FILE_ATTRIBUTE_DIRECTORY, "str", to, "uint", FILE_ATTRIBUTE_DIRECTORY, "uint")
    return outBuf
}