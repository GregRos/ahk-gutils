; ================================================================
; Contains utility commonly used utility functions.
; Meant to be reusable.
; ================================================================
#include gutils-ex.ahk



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


gSys_ProcessView(winTitle) {
    return new gProcessView(winTitle)
}

gSys_ComInvoker(ref, dependencies := "") {
    return new gVtableInvoker(ref, dependencies)
}

gSys_CurrentPid() {
    return DllCall("GetCurrentProcessId")	
}

