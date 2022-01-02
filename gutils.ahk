﻿; ================================================================
; Contains utility commonly used utility functions.
; Meant to be reusable.
; ================================================================
gArr_Repeat(item, count) {
    arr:=[]
    Loop, %count%
    {
        arr.Insert(item)
    }
    return arr
}

; Gets the index of the item `what` in `arr`
gArr_IndexOf(arr, what) {
    for ix, value in arr {
        if(what = value) {
            return ix
        }
    }
    return 0	
}

gArr_Has(arr, what) {
    return gArr_IndexOf(arr, what) > 0
}

gArr_Find(arr, func) {
    func := gLang_Func(func)
    return gArr_Filter(arr, func)[1]
}

gArr_FindIndexes(arr, func) {
    results := []
    func := gLang_Func(func)
    for index, item in arr {
        if (gLang_Call(func, item, index)) {
            results.push(index)
        }
    }
    return results
}

gArr_FindIndex(arr, func) {
    return gArr_FindIndexes(arr, func)[1]
}

gArr_Order(what, options := "N") {
    str:= gStr_Join(what, "~")
    options .= " D~"
    Sort, str, %options%
    arr:=[]
    Loop, Parse, str, ~ 
    {
        arr.Insert(A_LoopField)
    }
    return arr	
}

gArr_Concat(arrs*) {
    c := []
    for i, arr in arrs {
        for j, item in arr {
            c.Push(item)
        }
    }
    return c
}

gArr_Slice(arr, start := 1, end := 0) {
    result:=[]
    start:= __g_NormalizeIndex(start, arr.MaxIndex())
    end:= __g_NormalizeIndex(end, arr.MaxIndex())
    if (end < start) {
        return result
    }
    Loop, % end - start + 1
    {
        result.Insert(arr[start + A_Index - 1])
    }
    return result
}

gArr_Map(arr, projection) {
    projection := gLang_Func(projection)
    result := []
    for index, item in arr {
        result.Push(gLang_Call(projection, item, index))
    }
    return result
}

gArr_Take(arr, n) {
    return gArr_Slice(arr, 1, n)
}

gArr_Filter(arr, filter) {
    filter := gLang_Func(filter)
    result := []
    for index, item in arr {
        if (gLang_Call(filter, item, index)) {
            result.Push(item)
        }
    }
    return result
}

gArr_FindLastIndex(arr, filter) {
    arr := gArr_FindIndexes(arr, filter)
    return arr[arr.MaxIndex()]
}

gArr_Is(arr) {
    return IsObject(arr) && arr.MaxIndex() != ""
}

gArr_Reverse(arr) {
    newArr := []
    Loop, % arr.MaxIndex()
    {
        newArr.Push(arr[arr.MaxIndex() - A_Index + 1])
    }
    return newArr
}

gArr_Flatten(arr) {
    total := []
    for i, item in arr {
        if (gArr_Is(item)) {
            total.Push(gArr_Flatten(item)*)
        } else {
            total.Push(item)
        }
    }
    return total
}

gLang_VarExists(ByRef var) {
    return &var = &something ? 0 : var = "" ? 2 : 1 
}

gLang_Func(funcOrName) {
    if (IsObject(funcOrName)) {
        return funcOrName
    }
    result := Func(funcOrName)
    if (!result) {
        gEx_Throw("Name wasn't a known function.")
    }
    return result
}

gLang_Call(funcOrName, args*) {
    funcOrName := gLang_Func(funcOrName)
    if (funcOrName.MinParams > args.MaxIndex()) {
        Throw "Passed too few parameters for function."
    }
    maxParams := funcOrName.MaxParams
    if (maxParams < args.MaxIndex()) {
        args := gArr_Take(args, maxParams)
    }
    return funcOrName.Call(args*)
}

; Represents an entry in a stack trace.
class StackTraceEntry {
    __New(file, line, function, offset) {
        this.File := File
        this.Line := line
        this.Function := function
        this.Offset := offset
    }
}

__g_entryToString(e) {
    x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
    return x
}

gLang_StackTrace(ignoreLast := 0) {
    obj := gLang_StackTraceObj(ignoreLast)
    stringify := gArr_Map(obj, "__g_entryToString")
    return gStr_Join(stringify, "`n")
}

gLang_Is(ByRef what, type) {
    if what is %type%
        Return true
}


__g_isObject(name, obj, canBeArray := False) {
    if (!isObject(obj)) {
        gEx_Throw("Parameter " name " is not an object: " obj)
    }
    if (!canBeArray) {
        if (obj.MaxIndex() > 0) {
            gEx_Throw("Parameter " name " is an array.")
        }
    }
}

gObj_Is(obj) {
    return IsObject(obj)
}

gObj_HasAnyKey(obj, keys*) {
    __g_isObject("obj", obj, True)
    for i, k in keys {
        if (obj.HasKey(k)) {
            return True
        }
    }
    return False
}

gObj_Keys(obj) {
    __g_isObject("obj", obj, True)
    keys := []
    for k in obj {
        keys.Push(k)
    }
    return keys 
}

class gObjValidator extends gDeclaredMembersOnly {
    requiredKeys := ""
    optionalKeys := False
    name := ""
    __New(name, requiredKeys, optionalKeys := False) {
        this.name := name
        this.requiredKeys := requiredKeys
        this.optionalKeys := optionalKeys
    }

    Assert(obj) {
        result := this.Check(obj)
        if (!result.valid) {
            gEx_Throw(Format("{1} - {2}", this.name, result.reason))
        }
    }

    Check(obj) {
        if (!gObj_Is(obj)) {
            return {valid: False, reason: "Input not an object: " obj}
        }
        if (gArr_Is(obj)) {
            return {valid: False, reason: "Object is an array."}
        }
        keys := this.requiredKeys
        for i, k in keys {
            if (!obj.HasKey(k)) {
                return {valid: False, reason: Format("Required key '{1}'' is missing.", k)}
            }
        }
        if (this.optionalKeys != True) {
            for k, v in obj {
                if (!gArr_IndexOf(this.optionalKeys, k)) {
                    return {valid: False, reason: Format("Unknown key '{1}'.", k)}
                }
            }
        }
        return {valid: True}
    }
}

gObj_NewValidator(name, requiredKeys := "", optionalKeys := True) {
    return new gObjValidator(name, requiredKeys, optionalKeys)
}

gObj_Pick(obj, keys*) {
    result := {}
    for i, k in keys {
        result[k] := obj[k]
    }
    return result
}

gObj_FromKeys(keys, value := True) {
    result := {}
    for i, k in keys {
        result[k] := value
    }
    return result
}

gObj_Omit(obj, keys*) {
    result := {}
    keysObj := gObj_FromKeys(keys)
    for i, k in obj {
        if (!keysObj.HasKey(k)) {
            result[k] := obj[k]
        }
    }
    return result
}

gObj_Assign(target, sources*) {
    for i, source in sources {
        for k, v in source {
            target[k] = source[v]
        }
    }
}

gObj_Defaults(target, sources*) {
    sources := gArr_Reverse(sources)
    sources.Push(target)
    obj := gObj_Assign({}, sources*)
    return obj
}

gObj_Merge(sources*) {
    return gObj_Assign({}, sources*)
}

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
    __New(path) {
        SplitPath, % path, file, dir, ext, fileNoExt, drive
        this.filename := filename
        this.dir := dir
        this.extension := ext
        this.fileNoExit := fileNoExt
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


gWin_IsFullScreen(winTitle := "") {
    ;checks if the specified window is full screen
    ;code from NiftyWindows source
    ;(with only slight modification)

    ;use WinExist of another means to get the Unique ID (HWND) of the desired window

    if ( !winTitle ) {
        WinGet, winTitle, ID, A
    }

    WinGet, WinMinMax, MinMax, ahk_id %winTitle%
    WinGetPos, WinX, WinY, WinW, WinH, ahk_id %winTitle%

    if (WinMinMax = 0) && (WinX = 0) && (WinY = 0) && (WinW = A_ScreenWidth) && (WinH = A_ScreenHeight) {
        WinGetClass, WinClass, ahk_id %winTitle%
        WinGet, WinProcessName, ProcessName, ahk_id %winTitle%
        SplitPath, WinProcessName, , , WinProcessExt

        if (WinClass != "Progman") && (WinProcessExt != "scr") {
            ;program is full-screen
            return true
        }
    }
    return false
}

gWin_IsMouseCursorVisible() {
    StructSize := A_PtrSize + 16
    VarSetCapacity(InfoStruct, StructSize)
    NumPut(StructSize, InfoStruct)
    DllCall("GetCursorInfo", UInt, &InfoStruct)
    Result := NumGet(InfoStruct, 8)
    return Result > 1
}

__g_MatchingInfoKeys := ["speed", "mode", "hiddenWindows", "hiddenText", "title", "text", "excludeTitle", "excludeText"]
global __g_MatchingInfoValidator := gObj_NewValidator("MatchingInfo", [], __g_MatchingInfoKeys)

gWin_GetMatchingInfo() {
    return {hiddenWindows: A_DetectHiddenWindows, hiddenText: A_DetectHiddenText, speed: A_TitleMatchModeSpeed, mode: A_TitleMatchMode}
}

__g_maybeSetMatchingInfo(obj) {
    if (obj = False) {
        return
    }
    return gWin_SetMatchingInfo(obj)
}

gWin_SetMatchingInfo(infoObj) {
    __g_MatchingInfoValidator.Assert(infoObj)
    modified := False
    old := gWin_GetMatchingInfo()
    if (infoObj.HasKey("mode")) {
        SetTitleMatchMode, % infoObj.mode
        modified := True
    }
    if (infoObj.HasKey("speed")) {
        SetTitleMatchMode, % infoObj.speed
        modified := True
    }
    if (infoObj.HasKey("hiddenWindows")) {
        DetectHiddenWindows, % gLang_Bool(infoObj.hiddenWindows, "OnOff")
        modified := True
    }
    if (infoObj.HasKey("hiddenText")) {
        DetectHiddenText, % gLang_Bool(infoObj.hiddenText, "OnOff")
        modified := True
    }
    return modified ? old : False
}

__g_WinGet(hwnd, subCommand) {
    WinGet, v, % subCommand, ahk_id %hwnd%
    return v
}

class gWinInfo extends gDeclaredMembersOnly {
    hwnd := ""

    __New(hwnd) {
        this.hwnd := hwnd
    }

    _winTitle() {
        return "ahk_id " this.hwnd
    }

    _winGet(subCommand) {
        WinGet, v, % subCommand, % this._winTitle()
        return v
    }

    PID {
        get {
            return this._winGet("PID")
        }
    }

    ProcessName {
        get {
            return this._winGet("ProcessName")
        }
    }

    ProcessPath {
        get {
            return this._winGet("ProcessPath")
        }
    }

    Transparent {
        get {
            return this._winGet("Transparent")
        }
    }

    TransColor {
        get {
            return this._winGet("TransColor")
        }
    }

    Style {
        get {
            return this._winGet("Style")
        }
    }

    ExStyle {
        get {
            return this._winGet("ExStyle")
        }
    }

    MinMax {
        get {
            return this._winGet("MinMax")
        }
    }

    Title {
        get {
            WinGetTitle, v, % this._winTitle()
            return v
        }
    }

    Class {
        get {
            WinGetClass, v, % this._winTitle()
            return v
        }
    }

    Pos {
        get {
            WinGetPos, X, Y, Width, Height, % this._winTitle()
            return {X: X
                ,Y: Y
                ,Width:Width
            ,Height:Height}
        }
    }

    IsActive {
        get {
            return WinActive(this._winTitle())
        }
    }

    Text {
        get {
            WinGetText, v, % this._winTitle()
            return v
        }
    }

    ID {
        get {
            return this.hwnd
        }
    }

    Exists {
        get {
            return WinExist(this._winTitle()) > 0
        }
    }

    Hide() {
        WinHide, % this._winTitle()
    }

    Show() {
        WinShow, % this._winTitle()
    }

    Kill() {
        WinKill, % this._winTitle()
    }

    Maximize() {
        WinMaximize, % this._winTitle()
    }

    Minimize() {
        WinMinimize, % this._winTitle()
    }

    Move(X, Y, Width:= "", Height := "") {
        WinMove, % this._winTitle(), , % X, % Y, % Width, % Height
    }

    Restore() {
        WinRestore, % this._winTitle()
    }

    Set(subCommand, value := "") {
        WinSet, % subCommand, % value, % this._winTitle()
    }

    Activate() {
        WinActivate, % this._winTitle()
    }

}

gWin_Get(query) {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        hwnd := WinExist(query.title, query.text, query.excludeTitle, query.excludeText)
        if (hwnd = 0) {
            return ""
        }
        return new gWinInfo(hwnd)
    } finally {
        __g_maybeSetMatchingInfo(old)
    }
}

gWin_List(query) {
    __g_MatchingInfoValidator.Assert(query)
    WinGet, win, List, % query.title, % query.text, % query.excludeTitle, % query.excludeText
    arr := []
    Loop, % win 
    {
        arr.push(win%A_Index%)
    }
    v := arr
}

gWin_Wait(query, timeout := "") {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWait, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
    } finally {
        __g_maybeSetMatchingInfo(old)
    }

}

gWin_WaitActive(query, active := 1, timeout := "") {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        if (active) {
            WinWaitActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        } else {
            WinWaitNotActive, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
        }
    } finally {
        __g_maybeSetMatchingInfo(old)
    }
}

gWin_WaitClose(query, timeout := "") {
    __g_MatchingInfoValidator.Assert(query)
    old := gWin_SetMatchingInfo(query)
    try {
        WinWaitClose, % query.title, % query.text, % Timeout, % query.excludeTitle, % query.excludeText
    } finally {
        __g_maybeSetMatchingInfo(obj)
    }

}

class gVtableInvoker extends gDeclaredMembersOnly {
    _ref := ""
    _onDispose := []
    __New(ref, dependencies = "") {
        this._ref := ref
        for i, v in dependencies {
            this._onDispose.Push(v)
        }
    }

    AddDependencies(dependencies*) {
        for i, v in dependencies {
            this._onDispose.Push(v)
        }
    }

    VtableCall(slot, args*) {
        x:= slot*A_PtrSize
        DllCall(NumGet(NumGet(this._ref+0)+slot*A_PtrSize) , "UPtr", this._ref + 0, args*)
    }

    Dispose() {
        ObjRelease(this._ref)
        for i, v in this._onDispose {
            ObjRelease(v)
        }
    }
}

gSys_ComInvoker(ref, dependencies := "") {
    return new gVtableInvoker(ref, dependencies)
}

gSys_Pid() {
    return DllCall("GetCurrentProcessId")	
}

global __g_wmi := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") 

gSys_GetProcessInfo(pid := "") {
    if (pid = "") {
        pid := gSys_Pid()
    }
    query = Select * From Win32_Process where ProcessId = %pid%
    results := __g_wmi.ExecQuery(query)._NewEnum()
    while results[proc]
    {
        return {Name: proc.Name
        ,PID: proc.ProcessId
        ,ParentPID: proc.ParentProcessId
        ,Path: proc.ExecutablePath}
    }
}

gSys_GetParentPid(pid) {
    query = Select ParentProcessId From Win32_Process where ProcessId = %pid%
    results := __g_wmi.ExecQuery(query)._NewEnum()
    while results[proc]
    {
        return proc.ParentProcessId
    }
}

; ; Provides read-only access to a process and its memory, can generate references to memory locations owned by the process.
; class gProcessView extends gDeclaredMembersOnly {
;     WindowTitle:="Uninit"
;     ProcessHandle:=0
;     Privilege:=0x1F0FFF

;     ; Private
;     _getBaseAddress(hWnd) {
;         return DllCall( A_PtrSize = 4
;             ? "GetWindowLong"
;             : "GetWindowLongPtr"
;             , "Ptr", hWnd
;             , "Int", -6
;         , "Int64") ; Use Int64 to prevent negative overflow when AHK is 32 bit and target process is 64bit
;         ; If DLL call fails, returned value will = 0
;     }

;     WindowHandle[] {
;         get {
;             WinGet, hwnd, ID, % this.WindowTitle
;             return hwnd
;         }
;     }

;     BaseAddress[] {
;         get {
;             return this._getBaseAddress(this.WindowHandle)
;         }
;     }

;     ProcessId[] {
;         get {
;             WinGet, pid, PID, %windowTitle%
;             return pid
;         }
;     }

;     __New(windowTitle) {
;         this.WindowTitle := windowTitle
;     }

;     ; Reads from a memory location owned by the process.
;     ; addr - An absolute address of the memory location to read.
;     ; datatype - The datatype. Use int/uint for bytes.
;     ; length - the number of bytes to be read from the location.
;     Read(addr, datatype="int", length=4) {

;         prcHandle := DllCall("OpenProcess", "Ptr", this.Privilege, "int", 0, "int", this.ProcessId)
;         VarSetCapacity(readvalue,length, 0)
;         DllCall("ReadProcessMemory","Ptr",prcHandle,"Ptr",addr,"Str",readvalue,"Uint",length,"Ptr *",0)
;         finalvalue := NumGet(readvalue,0,datatype)
;         DllCall("CloseHandle", "Ptr", prcHandle)
;         if (finalvalue = 0 && A_LastError != 0) {
;             format = %A_FormatInteger% 
;             SetFormat, Integer, Hex 
;             addr:=addr . ""
;             msg=Tried to read memory at address '%addr%', but ReadProcessMemory failed. Last error: %A_LastError%. 

;             FancyEx.Throw(msg)
;         }
;         return finalvalue
;     }

;     ; Reads from a memory location owned by the process, 
;     ; the memory location being determined from a nested base pointer, and a list of offsets.
;     ; address - the absolute address to read.
;     ReadPointer(address, datatype, length, offsets) {
;         B_FormatInteger := A_FormatInteger 
;         for ix, offset in offsets
;         {
;             baseresult := this.Read(address, "Ptr", 8)
;             Offset := offset
;             SetFormat, integer, h
;             address := baseresult + Offset
;             SetFormat, integer, d
;         }
;         SetFormat, Integer, %B_FormatInteger%
;         return this.Read(address,datatype,length)
;     }

;     ; Same as ReadPointer, except that the first parameter is an *offset* starting from the base address of the active window of the process.
;     ReadPointerByOffset(baseOffset, datatype, length, offsets) {
;         return this.ReadPointer(this.BaseAddress + baseOffset, datatype, length, offsets)
;     }

;     ; Returns a self-contained ProcessVariableReference that allows reading from the specified memory location (as ReadPointer).
;     GetReference(baseOffsets, offsets, dataType, length, label := "") {
;         return new this.ProcessVariableReference(this, baseOffsets, offsets, dataType, length, label) 				
;     }	

;     ; Closes the ProcessView. Further operations are undefined.
;     Close() {
;         r := DllCall("CloseHandle", "Ptr", hwnd)
;         this.ProcessHandle := 0
;     }

;     ; Self-contained class for viewing a memory location owned by the process.
;     class ProcessVariableReference extends gDeclaredMembersOnly {
;         Process:="Uninit"
;         BaseOffset:="Uninit"
;         Offsets:="Uninit"
;         DataType:="Uninit"
;         Length:="Uninit"
;         Label:="Uninit"

;         __New(process, baseOffset, offsets, dataType, length, label := "") {
;             this.Process:=Process
;             this.BaseOffset:=baseOffset
;             this.Offsets:=offsets
;             this.DataType:=dataType
;             this.Length:=length
;             this.Label := label
;         }

;         Value[] {
;             get {
;                 return this.Process.ReadPointerByOffset(this.BaseOffset, this.DataType, this.Length, this.Offsets)
;             }
;         }	
;     }
; }

; gSys_ProcessView(winTitle) {
;     return new gProcessView(winTitle)
; }


__g_noramlizeRoot(root) {
    static __g_roots
    if (!__g_roots) {
        __g_roots := {"HKLM" : "HKEY_LOCAL_MACHINE"
            ,"HKCR": "HKEY_CLASSES_ROOT"
            ,"HKU": "HKEY_USERS"
            ,"HKCU" : "HKEY_CURRENT_USER"
        ,"HPD": "HKEY_PERFORMANCE_DATA"}

        ; This is needed so the normalizer is idempotent and also to normalize case
        for key, v in __g_roots {
            __g_roots[v] := v
        }
    }
    return __g_roots[root]
}

__g_splitRegPath(path) {
    if (Trim(path) = "") {
        gEx_Throw("Empty string not a valid registry path.")
    }
    normalizedAsRoot := __g_noramlizeRoot(path)
    if (normalizedAsRoot) {
        return [normalizedAsRoot, ""]
    }
    parsed := gStr_Split(path, "\", , 2)
    root := ""
    subkey := ""
    if (parsed.MaxIndex() = 2) {
        normalizedRoot := __g_noramlizeRoot(parsed[1])
        if (!normalizedRoot) {
            return ["", path]
        }
        return [normalizedRoot, parsed[2]]
    } else {
        return ["", path]
    }
}

__g_normalizeRootInPath(path) {
    return gPath_Join(__g_splitRegPath(path))
}

__g_resolveRegPath(parts*) {
    ; Format the registry path like an fs path and use the syscall to resolve it
    parts.InsertAt(1, "C:")
    resolved := gPath_Resolve(parts*)
    noDrive := gStr_Slice(resolved, 4)
    resolvedRoot := gStr_Trim(__g_normalizeRootInPath(noDrive))
    return resolvedRoot
}

__g_checkKeyExists(rootedKey) {
    if (rootedKey = "") {
        gEx_Throw("Empty key not a legal registry path.")
    }
    Loop, Reg, % rootedKey, KVR
    {
        return True
    }
    rootedKey := __g_normalizeRootInPath(rootedKey)
    parent := __g_resolveRegPath(rootedKey, "..")
    Loop, Reg, % parent, K
    {
        curFullKey := gPath_Join(A_LoopRegKey, A_LoopRegSubkey, A_LoopRegName)
        if (curFullKey = rootedKey) {
            return True
        }
    }
    return False
}

class gRegKey extends gDeclaredMembersOnly {
    root := ""
    subKey := ""
    __New(parts*) {
        root := parts[1]
        this.root := __g_noramlizeRoot(root)
        this.subkey := gPath_Join(gArr_Slice(parts, 2))
        if (!this.root) {
            gEX_Throw("Root was empty.")
        }
    }

    IsKey {
        get {
            return True
        }
    }

    IsRoot {
        get {
            return this.subkey == ""
        }
    }

    Key {
        get {
            if (!this.subkey) {
                return this.root
            }
            return gPath_Join(this.root, this.subkey)
        }
    }

    ; Gets a subkey 
    ; @param subkeys ...string[] Path components that appear in order. They will be rooted at the current key.
    Child(parts*) {
        joined := gPath_Join(parts*)
        resolved := __g_resolveRegPath(this.Key, joined)
        if (!__g_checkKeyExists(resolved)) {
            return ""
        }
        parts := __g_splitRegPath(resolved)
        child := new gRegKey(parts*)
        return child
    }

    Parent {
        get {
            if (this.IsRoot) {
                gEx_Throw("Can't get parent of root.")
            }
            parent := __g_resolveRegPath(this.Key, "..")
            parsed := __g_splitRegPath(parent)
            return new gRegKey(parsed[1], parsed[2])
        }
    }

    Children() {
        arr := []
        Loop, Reg, % this.key, K
        {
            arr.Push(new gRegKey(A_LoopRegKey, A_LoopRegSubkey, A_LoopRegName))
        }
        return arr
    }

    Values() {
        values := {}
        Loop, Reg, % this.Key, V
        {
            RegRead, X
            values[A_LoopRegName] := X
        }
        ObjSetBase(values, gDeclaredMembersOnly)
        return values
    }

    EraseValue(name) {
        if (name = "") {
            gEx_Throw("The value name cannot be empty.")
        }
        try {
            RegDelete, % this.Key, % name
        } catch err {
            gEx_ThrowObj(err)
        }
    }

    Erase() {
        if (this.IsRoot) {
            gEx_Throw("You can't delete a root.")
        }
        try {
            RegDelete, % this.key
        }  catch err {
            gEx_ThrowObj(err)
        }
    }

    Create(parts*) {
        fullKey := __g_resolveRegPath(this.Key, parts*)
        if (__g_checkKeyExists(fullKey)) {
            gEx_Throw(Format("Key '{1}' already exists.", fullKey))
        }
        ; We need to create this dummy key because RegWrite can't actually create empty keys
        fakeKey := gPath_Join(fullKey, "ahk-gutils-DELETE-THIS")
        try {
            RegWrite, REG_SZ, % fakeKey
            RegDelete, % fakeKey
        }  catch err {
            gEx_ThrowObj(err)
        }
        parsed := __g_splitRegPath(fullKey)
        return new gRegKey(parsed[1], parsed[2])
    }

    Has(parts*) {
        parts.InsertAt(1, this.key)
        return __g_checkKeyExists(gPath_Join(parts))
    }

    HasV(name) {
        Loop, Reg, % this.Key, V
        {
            if (A_LoopRegName = name) {
                return True
            }
        }
    }

    Get(name := "") {
        try {
            RegRead, X, % this.Key, % name
            return X
        }  catch err {
            return ""
        }
    }

    Set(name, type, value) {
        if (!gArr_Has(["REG_SZ", "REG_EXPAND_SZ", "REG_MULTI_SZ", "REG_DWORD", "REG_BINARY"], type)) {
            gEx_Throw("Type " type " is not a legal regisry value type.")
        }
        try {
            RegWrite, % type, % this.Key, % name, % value
        }  catch err {
            gEx_ThrowObj(err)
        }
    }

}

gReg(key) {
    if (!__g_checkKeyExists(key)) {
        gEx_Throw(Format("Key '{1}' doesn't exist.", key))
    }
    parsed := __g_splitRegPath(key)
    return new gRegKey(parsed[1], parsed[2])
}

gReg_Is(obj) {
    return obj.base = gRegKey
}




