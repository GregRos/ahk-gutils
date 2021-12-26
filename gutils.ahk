; ================================================================
; Contains utility commonly used utility functions.
; Meant to be reusable.
; ================================================================
#include gutils-ex.ahk

__g_NormalizeIndex(negIndex, length) {
    if (negIndex <= 0) {
        return length + negIndex
    }
    return negIndex
}

; Base class that provides member name verification services.
; Basically, inherit from this if you want your class to only have declared members (methods, properties, and fields assigned in the initializer), so that unrecognized keys will result in an error.
; The class implements __Get, __Call, and __Set.
class gDeclaredMembersOnly {
    __Call(name, params*) {
        if (!gLang_IsNameBuiltIn(name) && !this._ahkUtilsDisableVerification) {
            FancyEx.Throw("Tried to call undeclared method '" name "'.")
        }
    }

    __New() {

    }

    __Init() {
        ; We want to disable name verification to allow the extending object's initializer to safely initialize the type's fields.
        if (this._ahkUtilsDisableVerification) {
            return
        }
        this._ahkUtilsDisableVerification := true
        this.methods := { }

        this.__Init()
        this.Delete("_ahkUtilsDisableVerification")
    }

    __Get(name) {
        if (!gLang_IsNameBuiltIn(name) && !this._ahkUtilsDisableVerification) {
            FancyEx.Throw("Tried to get the value of undeclared member '" name "'.")
        }
    }

    __Set(name, values*) {
        if (!gLang_IsNameBuiltIn(name) && !this._ahkUtilsDisableVerification) {
            FancyEx.Throw("Tried to set the value of undeclared member '" name "'.")
        }
    }

    __DisableVerification() {
        ObjRawSet(this, "_ahkUtilsDisableVerification", true)
    }

    __EnableVerification() {
        this.Delete("_ahkUtilsDisableVerification")
    }

    __IsVerifying[] {
        get {
            return !this.HasKey("_ahkUtilsDisableVerification")
        }
    }

    __RawGet(name) {
        this.__DisableVerification()
        value := this[name]
        this.__EnableVerification()
        return value
    }

}

class gComObjectInvoker extends gDeclaredMembersOnly {
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

; Provides read-only access to a process and its memory, can generate references to memory locations owned by the process.
class gProcessView extends gDeclaredMembersOnly {
    WindowTitle:="Uninit"
    ProcessHandle:=0
    Privilege:=0x1F0FFF

    ; Private
    _getBaseAddress(hWnd) {
        return DllCall( A_PtrSize = 4
            ? "GetWindowLong"
            : "GetWindowLongPtr"
            , "Ptr", hWnd
            , "Int", -6
        , "Int64") ; Use Int64 to prevent negative overflow when AHK is 32 bit and target process is 64bit
        ; If DLL call fails, returned value will = 0
    }

    WindowHandle[] {
        get {
            WinGet, hwnd, ID, % this.WindowTitle
            return hwnd
        }
    }

    BaseAddress[] {
        get {
            return this._getBaseAddress(this.WindowHandle)
        }
    }

    ProcessId[] {
        get {
            WinGet, pid, PID, %windowTitle%
            return pid
        }
    }

    __New(windowTitle) {
        this.WindowTitle := windowTitle
    }

    ; Reads from a memory location owned by the process.
    ; addr - An absolute address of the memory location to read.
    ; datatype - The datatype. Use int/uint for bytes.
    ; length - the number of bytes to be read from the location.
    Read(addr, datatype="int", length=4) {

        prcHandle := DllCall("OpenProcess", "Ptr", this.Privilege, "int", 0, "int", this.ProcessId)
        VarSetCapacity(readvalue,length, 0)
        DllCall("ReadProcessMemory","Ptr",prcHandle,"Ptr",addr,"Str",readvalue,"Uint",length,"Ptr *",0)
        finalvalue := NumGet(readvalue,0,datatype)
        DllCall("CloseHandle", "Ptr", prcHandle)
        if (finalvalue = 0 && A_LastError != 0) {
            format = %A_FormatInteger% 
            SetFormat, Integer, Hex 
            addr:=addr . ""
            msg=Tried to read memory at address '%addr%', but ReadProcessMemory failed. Last error: %A_LastError%. 

            FancyEx.Throw(msg)
        }
        return finalvalue
    }

    ; Reads from a memory location owned by the process, 
    ; the memory location being determined from a nested base pointer, and a list of offsets.
    ; address - the absolute address to read.
    ReadPointer(address, datatype, length, offsets) {
        B_FormatInteger := A_FormatInteger 
        for ix, offset in offsets
        {
            baseresult := this.Read(address, "Ptr", 8)
            Offset := offset
            SetFormat, integer, h
            address := baseresult + Offset
            SetFormat, integer, d
        }
        SetFormat, Integer, %B_FormatInteger%
        return this.Read(address,datatype,length)
    }

    ; Same as ReadPointer, except that the first parameter is an *offset* starting from the base address of the active window of the process.
    ReadPointerByOffset(baseOffset, datatype, length, offsets) {
        return this.ReadPointer(this.BaseAddress + baseOffset, datatype, length, offsets)
    }

    ; Returns a self-contained ProcessVariableReference that allows reading from the specified memory location (as ReadPointer).
    GetReference(baseOffsets, offsets, dataType, length, label := "") {
        return new this.ProcessVariableReference(this, baseOffsets, offsets, dataType, length, label) 				
    }	

    ; Closes the ProcessView. Further operations are undefined.
    Close() {
        r := DllCall("CloseHandle", "Ptr", hwnd)
        this.ProcessHandle := 0
    }

    ; Self-contained class for viewing a memory location owned by the process.
    class ProcessVariableReference extends gDeclaredMembersOnly {
        Process:="Uninit"
        BaseOffset:="Uninit"
        Offsets:="Uninit"
        DataType:="Uninit"
        Length:="Uninit"
        Label:="Uninit"

        __New(process, baseOffset, offsets, dataType, length, label := "") {
            this.Process:=Process
            this.BaseOffset:=baseOffset
            this.Offsets:=offsets
            this.DataType:=dataType
            this.Length:=length
            this.Label := label
        }

        Value[] {
            get {
                return this.Process.ReadPointerByOffset(this.BaseOffset, this.DataType, this.Length, this.Offsets)
            }
        }	
    }
}

gLang_VarExists(ByRef var) {
    return &var = &something ? 0 : var = "" ? 2 : 1 
}
__g_builtInNames:=["_NewEnum", "methods", "HasKey", "_ahkUtilsDisableVerification", "Clone", "GetAddress", "SetCapacity", "GetCapacity", "MinIndex", "MaxIndex", "Length", "Delete", "Push", "Pop", "InsertAt", "RemoveAt", "base", "__Set", "__Get", "__Call", "__New", "__Init", "_ahkUtilsIsInitialized"]

gLang_IsNameBuiltIn(name) {
    global __g_builtInNames
    return gArr_IndexOf(__g_builtInNames, name)
}

gLang_NormFunc(funcOrName) {
    if (IsObject(funcOrName)) {
        return funcOrName
    }
    result := Func(funcOrName)
    return result
}

gLang_Call(funcOrName, args*) {
    funcOrName := gLang_NormFunc(funcOrName)
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

gLang_StackTraceObj(ignoreLast := 0) {
    ; from Coco in http://ahkscript.org/boards/viewtopic.php?f=6&t=6001
    r := [], i := 0, n := 0
    Loop
    {
        e := Exception(".", offset := -(A_Index + n))
        if (e.What == offset)
            break
        r[++i] := new StackTraceEntry(e.File, e.Line, e.What, offset + n)
    }
    lastEntry:= r[1]
    for ix, entry in r {
        ; I want each entry to contain the *exit location*, not entry location, so it corresponds to part of the function.
        if (ix = 1) {
            continue	
        }
        tmp := lastEntry
        lastEntry := entry.Clone()
        entry.File := tmp.File
        entry.Line := tmp.Line
        entry.Offset := tmp.Offset
    }

    r.Insert(new StackTraceEntry(lastEntry.File, lastEntry.Line, " ", lastEntry.Offset))

    Loop, % ignoreLast + 1
    {
        r.Remove(1)
    }

    return r
}

gSys_ProcessView(winTitle) {
    return new gProcessView(winTitle)
}

gSys_ComInvoker(ref, dependencies := "") {
    return new gComObjectInvoker(ref, dependencies)
}

gSys_IsMouseCursorVisible() {
    StructSize := A_PtrSize + 16
    VarSetCapacity(InfoStruct, StructSize)
    NumPut(StructSize, InfoStruct)
    DllCall("GetCursorInfo", UInt, &InfoStruct)
    Result := NumGet(InfoStruct, 8)
    return Result > 1
}

gSys_CurrentPid() {
    return DllCall("GetCurrentProcessId")	
}

gSys_IsAppFullScreen(WinID := "") {
    ;checks if the specified window is full screen
    ;code from NiftyWindows source
    ;(with only slight modification)

    ;use WinExist of another means to get the Unique ID (HWND) of the desired window

    if ( !WinID ) {
        WinGet, WinID, ID, A
    }

    WinGet, WinMinMax, MinMax, ahk_id %WinID%
    WinGetPos, WinX, WinY, WinW, WinH, ahk_id %WinID%

    if (WinMinMax = 0) && (WinX = 0) && (WinY = 0) && (WinW = A_ScreenWidth) && (WinH = A_ScreenHeight) {
        WinGetClass, WinClass, ahk_id %WinID%
        WinGet, WinProcessName, ProcessName, ahk_id %WinID%
        SplitPath, WinProcessName, , , WinProcessExt

        if (WinClass != "Progman") && (WinProcessExt != "scr") {
            ;program is full-screen
            return true
        }
    }
    return false
}

gSys_GetGuid() {
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

gArr_Repeat(item, count) {
    arr:=[]
    Loop, %count%
    {
        arr.Insert(item)
    }
    return arr
}

gArr_IndexOf(arr, what) {
    for ix, value in arr {
        if(what = value) {
            return ix
        }
    }
    return 0	
}

gArr_Find(arr, func) {
    func := gLang_NormFunc(func)
    return gArr_Filter(arr, func)[1]
}

gArr_FindIndexes(arr, func) {
    results := []
    func := gLang_NormFunc(func)
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
    projection := gLang_NormFunc(projection)
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
    filter := gLang_NormFunc(filter)
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
    reverse := gStR_Reverse(where)
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

gRegEx_MultiMatchGroups(haystack, needle) {
    array:=[]
    Loop, 10 
    {
        match%A_Index% := [""]
    }
    while (pos := RegExMatch(haystack, needle, match, ((pos>=1) ? pos : 1)+StrLen(match))) {
        curArray:=[]
        Loop, 10
        {
            cur := match%A_Index%
            if (cur.MaxIndex() = 1) {
                break
            }
            curArray.Insert(cur)
        }
        array.Insert({text:match, groups:curArray})
    }
    Return array
}

gRegEx_MultiMatch(haystack, needle) {
    array:=[]
    while (pos := RegExMatch(haystack, needle, match, ((pos>=1) ? pos : 1)+StrLen(match))) {
        array[A_Index]:=match
    }
    Return array
}

gHotkey_Name(hotkeyName := "") {
    hotkeyName := hotkeyName == "" ? A_ThisHotkey : hotkeyName
    RegExMatch(A_ThisHotKey, "([$*+~^!#<>?]*)(.+)", hotkey)
    if (InStr(hotkey1, "+") && StrLen(hotkey2) = 1)
    {
        if hotkey is lower
        {
            StringUpper, hotkey2, hotkey2
        }
    }
    return hotkey2
}

gHotkey_RegUpDown(hk, downHandler, upHandler := "", options := "") {
    if (hk = "None") {
        return
    }
    gHotkey_Reg(hk, downHandler, options)
    if (upHandler) {
        gHotkey_Reg(hk " up", upHandler, options)
    }
}

; Holds down the key 'key' for 'ms' milliseconds. This is a string which is passed to SendInput, so use key names for things like Space.
; If ms = -1 (default), the 'up' command isn't transmited (the key is never released).
gHotkey_Hold(key, ms = -1) {
    if (key = "WheelDown" || key = "WheelUp") {
        SendInput, {%key%}
        return
    }
    SendInput, {%key% down}
    if (ms != -1) {
        Sleep, % ms
        SendInput, {%key% up}
    }
}

gHotkey_Reg(hk, handler, options := "") {
    if (hk = "None") {
        return
    }
    try {
        Hotkey, % hk, % handler, % options
    } catch ex {
        FancyEx.Throw("Failed to register hotkey", ex)
    }
}

gHotkey_RegAlias(hotkey, target, wheelDuration := 35) {
    if (hk = "None") {
        return
    }			

    if (hotkey = "WheelUp" || hotkey = "WheelDown") {
        gHotkey_Reg(hotkey, gSend_Hold.Bind(target, wheelDuration))
        return
    }
    method := gSend
    gHotkey_RegUpDown(hotkey, method.Bind("{" target " down}"), method.Bind("{" target " up}"))
}

gSend(inputs*) {
    ; ADD JOIN
    SendInput, % input
}

gSend_CopyPaste(input) {
    tmp:=ClipboardAll
    Clipboard:=input
    ClipWait
    SendInput, ^v
    Sleep 50
    Clipboard:=tmp
    return
}

gSend_Hold(key, ms = -1) {
    if (key = "WheelDown" || key = "WheelUp") {
        SendInput, {%key%}
        return
    }
    SendInput, {%key% down}
    if (ms != -1) {
        Sleep, % ms
        SendInput, {%key% up}
    }
}

; Holds down the list object 'keys' for a period of 'ms' milliseconds.
gSend_HoldMany(keys, ms = -1) {
    if (!IsObject(keys)) {
        keys:=gStr_ToChars(keys)
    }
    for ix, key in keys {
        gSend("{" key " down}")
    }
    if (ms != -1) {
        Sleep, % ms
        for ix, key in keys {
            gSend("{" key " up}")
        }
    }
}

gSend_HoldRepeat(key, count, holdDown, betweenPresses) {
    Loop, % count 
    {
        gSend_Hold(key, holdDown)
        Sleep, % betweenPresses
    }
}

gSend_StopHold(key) {
    if (GetKeyState(key, "T")) {
        SendInput, {%key% up}
    }
}

