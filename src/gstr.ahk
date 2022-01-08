#include glang.ahk

; Returns a new string that's padded to the end, to the width toWidth, using the padding `padding`.
gStr_PadRight(ByRef self, toWidth, padding := " ") {
    z__gutils__assertNotObject(self, toWidth, padding)
    myLen := StrLen(self)
    extras := toWidth - myLen
    if (extras <= 0) {
        return self
    }
    padding := gStr_Repeat(padding, extras)
    result := self padding
    return result
}

; Returns a string that's padded to the left, toWidth, using the given padding.
gStr_PadLeft(ByRef self, toWidth, padding := " ") {
    z__gutils__assertNotObject(self, toWidth, padding)
    myLen := StrLen(self)
    extras := toWidth - myLen
    if (extras <= 0) {
        return self
    }
    padding := gStr_Repeat(padding, extras)
    result := padding self 
    return result
}

; Returns an array of the ANSI characters or codepoints in `self`.
gStr_ToChars(ByRef self) {
    z__gutils__assertNotObject(self)
    list:=[]
    Loop, Parse, self 
    {
        list.Insert(A_LoopField)
    }
    return list
}

; Returns this strint indented using `indent` to `level`. Handles multi-line strings.
gStr_Indent(ByRef self, indent := " ", level := 1) {
    z__gutils__assertNotObject(self, indent, level)
    if (!self) {
        return self
    }
    indentStr := ""
    Loop, % level
    {
        indentStr.=indent
    }
    indented := ""

    StringReplace, indented, self, `n, `n%indentStr%, All
    indented:=indentStr indented
    return indented
}

; Returns true if `self` starts with `what`.
gStr_StartsWith(ByRef self, ByRef what, caseSensitive = 0) {
    z__gutils__assertNotObject(self, what, caseSensitive)
    if (what == "") {
        return true
    }
    len := StrLen(what)
    initial := SubStr(self, 1, len)
    return caseSensitive ? initial == what : initial = what
}

; Returns true if `self` ends with `what`.
gStr_EndsWith(ByRef self, ByRef what, caseSensitive = 0) {
    z__gutils__assertNotObject(self, what, caseSensitive)
    if (what == "") {
        return true
    }
    len := StrLen(what)
    final := gStr_Slice(self, -len+1)
    return caseSensitive ? final == what : final = what
}

; Semi-intelligently stringifies an object.
gStr(obj) {
    if (!IsObject(obj)) {
        return "" + obj
    }
    if (obj.MaxIndex() != "") {
        stringified := gArr_Map(obj, "gStr")
        return "[" gArr_Join(stringified, ", ") "]"
    }
    stringified := []
    for key, value in obj {
        stringified.Push(Format("{1}: {2}", key, gStr(value)))
    }
    return "{`n" gSTr_Indent(gArr_Join(stringified, ",`n"), " ", 1) "`n}"
}

gStr_Trim(ByRef self, chars := " `t") {
    z__gutils__assertNotObject(self, chars)
    return Trim(self, chars)
}

gStr_TrimLeft(ByRef self, chars := " `t") {
    z__gutils__assertNotObject(self, chars)
    return LTrim(self, chars)
}

gStr_TrimRight(ByRef self, chars := " `t") {
    z__gutils__assertNotObject(self, chars)
    return RTrim(self, chars)
}

gStr_Len(ByRef self) {
    z__gutils__assertNotObject(self)
    return StrLen(self)
}

; Returns a string that's `self` repeated `count` times, deparated by `delim`.
gStr_Repeat(ByRef self, count, delim := "") {
    z__gutils__assertNotObject(self, count, delim)
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

; Returns the positions of substring `what` in `this`.
gStr_IndexesOf(ByRef self, ByRef what, case := false) {
    z__gutils__assertNotObject(self, what, case)
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

; Returns the position of the first occurence of `what`.
gStr_IndexOf(ByRef self, ByRef what, case := false, pos := 1) {
    z__gutils__assertNotObject(self, what, case, pos)
    return InStr(self, what, case, pos)
}

; Returns a reversed string.
gStr_Reverse(ByRef self) {
    z__gutils__assertNotObject(self)
    str := ""
    Loop, Parse, % self 
    {
        str := A_LoopField str
    }

    return str
}

; Returns the last position of `what` in `self`.
gStr_LastIndexOf(ByRef self, ByRef what, case := false, pos := 1) {
    z__gutils__assertNotObject(self, what, case)
    cur := 0
    indexes := gStr_IndexesOf(self, what, pos)
    return indexes[indexes.MaxIndex()]
}

; Splits `self` in two at `pos` and returns the two parts.
gStr_SplitAt(ByRef self, pos) {
    z__gutils__assertNotObject(self, pos)
    pos := z__gutils_NormalizeIndex(pos, StrLen(self))
    first := gStr_Slice(self, pos - 1)
    last := gStr_Slice(self, pos + 1)
    return [first, last]
}

; Returns a substring starting at `start` and ending at `end`
gStr_Slice(ByRef self, start := 1, end := 0) {
    z__gutils__assertNotObject(self, start, end)
    start := z__gutils_NormalizeIndex(start, StrLen(self))
    end := z__gutils_NormalizeIndex(end, StrLen(self))
    return SubStr(self, start, end - start + 1)
}

; Splits `self`.
gStr_Split(ByRef self, delimeters := "", omit := "", max := -1) {
    z__gutils__assertNotObject(self, delimeters, omit, max)
    return StrSplit(self, delimeters, omit, max)
}

; Returns from an array of numeric char codes.
gStr_OfCodes(wArray) {
    z__gutils_assertArray(wArray)
    result := ""
    for i, x in wArray {
        result .= chr(x)
    }
    return result
}

; Returns a string from an array of strings.
gStr_OfChars(cArray) {
    z__gutils_assertArray(cArray)
    result := ""
    for i, x in cArray {
        result .= x
    }
    return result
}

; Returns a string GUID.
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

; Returns `self` in lowercase.
gStr_Lower(ByRef self, T := "") {
    z__gutils__assertNotObject(self, T)
    StringLower, v, self, % T
    Return, v
}

; Returns `self` in uppercase.
gStr_Upper(ByRef self, T := "") {
    z__gutils__assertNotObject(self, T)
    StringUpper, v, self, %T%
    Return, v
}

; Returns a new replaced string.
gStr_Replace(ByRef self, ByRef SearchText, ByRef ReplaceText, Limit := -1) {
    z__gutils__assertNotObject(self, searchText, replaceText, limit)
    return StrReplace(self, SearchText, ReplaceText, , Limit)
}

; True if `what` is in `self`
gStr_Has(ByRef self, ByRef what, Case := false, Start := 1) {
    z__gutils__assertNotObject(self, what, case, start)
    return gStr_IndexOf(self, what, Case, Start) > 0
}

; True if `self` is not an object.
gStr_Is(ByRef self) {
    return !IsObject(self)
}

; Returns the char at position `pos`.
gStr_At(ByRef self, pos) {
    z__gutils__assertNotObject(self, pos)
    pos := z__gutils_NormalizeIndex(pos, StrLen(self))s
    return SubStr(self, pos, 1)
}

class gRegEx {
    search := ""
    options := ""
    __New(search, options := "") {
        this.search := search
        this.options := options
        if (!gStr_IndexOf(options, "O")) {
            this.options := "O"
        }
    }

    First(ByRef haystack, pos := 1) {
        z__gutils__assertNotObject(haystack, pos)
        needle := options "O)" needle
        RegExMatch(self, needle, match, pos)
        return match
    }

    All(ByRef haystack, pos := 1) {
        z__gutils__assertNotObject(haystack, pos)
        array:=[]
        needle := options "O)" needle
        while (pos := RegExMatch(self, needle, match, ((pos>=1) ? pos : 1)+StrLen(match.Len(0)))) {
            array.Push(match)
        }
        Return array
    }

    
}

; Returns a match object.
gStr_Match(ByRef self, needle, options := "", pos := 1) {
    z__gutils__assertNotObject(self, needle, options, pos)
    needle := options "O)" needle
    RegExMatch(self, needle, match, pos)
    return match
}

; Returns an array of match objects.
gStr_Matches(ByRef self, needle, options := "", pos := 1) {
    z__gutils__assertNotObject(self, needle, options, pos)
    array:=[]
    needle := options "O)" needle
    while (pos := RegExMatch(self, needle, match, ((pos>=1) ? pos : 1)+StrLen(match))) {
        array.Push(match)
    }
    Return array
}

gStr_RegReplace(ByRef self, needle, replacement := "", pos := 1) {

}

; A path that's been parsed into its components.
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

