#include glang.ahk
gStr_PadRight(ByRef self, toWidth, char := " ") {
    myLen := StrLen(self)
    extras := toWidth - myLen
    if (extras <= 0) {
        return self
    }
    padding := gStr_Repeat(char, extras)
    result := self padding
    return result
}

gStr_PadLeft(ByRef self, toWidth, char := " ") {
    myLen := StrLen(self)
    extras := toWidth - myLen
    if (extras <= 0) {
        return self
    }
    padding := gStr_Repeat(char, extras)
    result := padding self 
    return result
}

gStr_ToChars(ByRef self) {
    list:=[]
    Loop, Parse, self 
    {
        list.Insert(A_LoopField)
    }
    return list
}

gStr_Indent(ByRef self, indent = " ", count = 1) {
    if (!self) {
        return self
    }
    indentStr := ""
    Loop, % count
    {
        indentStr.=indent
    }
    indented := ""

    StringReplace, indented, self, `n, `n%indentStr%, All
    indented:=indentStr indented
    return indented
}

gStr_StartsWith(ByRef self, ByRef what, caseSensitive = 0) {
    if (what == "") {
        return true
    }
    len := StrLen(what)
    initial := SubStr(self, 1, len)
    return caseSensitive ? initial == what : initial = what
}

gStr_EndsWith(ByRef self, ByRef what, caseSensitive = 0) {
    if (what == "") {
        return true
    }
    len := StrLen(what)
    final := gStr_Slice(self, -len+1)
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

gStr_Join(ByRef self, sep:="", omit:="") {
    for ix, value in self {
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

gStr_Trim(ByRef self, chars := " `t") {
    return Trim(self, chars)
}

gStr_TrimLeft(ByRef self, chars := " `t") {
    return LTrim(self, chars)
}

gStr_TrimRight(ByRef self, chars := " `t") {
    return RTrim(self, chars)
}

gStr_Len(ByRef self) {
    return StrLen(self)
}

gStr_Repeat(ByRef self, count, delim := "") {
    result := ""
    Loop, % count 
    {
        if (A_Index != 1) {
            result .= delim
        }
        result.= self
    }
    return result
}

gStr_IndexesOf(ByRef self, ByRef what, case := false) {
    arr := []
    occur := 1
    last := ""
    Loop {
        if (last != "") {
            arr.Push(last)
        }
        last := gStr_IndexOf(self, what, case, A_Index)
    } until last = 0
    return arr
}

gStr_IndexOf(ByRef self, ByRef what, case := false, pos := 1, occurrence := 1) {
    return InStr(self, what, case, pos, occurrence)
}

gStr_Reverse(ByRef self) {
    str := ""
    Loop, Parse, % self 
    {
        str := A_LoopField str
    }

    return str
}

gStr_LastIndexOf(ByRef self, ByRef what, case := false, pos := 1) {
    cur := 0
    loop {
        last := cur
        cur := gStr_IndexOf(self, what, case, cur + 1)
    } until cur = 0
    return last
}

gStr_SplitAt(ByRef self, pos) {
    pos := z__gutils_NormalizeIndex(pos, StrLen(self))
    first := gStr_Slice(self, pos - 1)
    last := gStr_Slice(self, pos + 1)
    return [first, last]
}

gStr_Slice(ByRef self, start := 1, end := 0) {
    start := z__gutils_NormalizeIndex(start, StrLen(self))
    end := z__gutils_NormalizeIndex(end, StrLen(self))
    return SubStr(self, start, end - start + 1)
}

gStr_Split(self, delimeters := "", omit := "", max := -1) {
    return StrSplit(self, delimeters, omit, max)
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

gStr_Lower(ByRef self, T := "") {
    StringLower, v, self, %T%
    Return, v
}

gStr_Upper(ByRef self, T := "") {
    StringUpper, v, self, %T%
    Return, v
}

gStr_Replace(ByRef self, ByRef SearchText, ByRef ReplaceText, Limit := -1) {
    return StrReplace(self, SearchText, ReplaceText, , Limit)
}

gStr_Has(ByRef self, ByRef what, Case := false, Start := 1) {
    return gStr_IndexOf(self, what, Case, Start) > 0
}

gStr_Is(ByRef self) {
    return !IsObject(self)
}

gStr_At(ByRef self, pos) {
    return SubStr(self, pos, 1)
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