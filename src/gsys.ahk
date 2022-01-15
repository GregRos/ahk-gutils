#include glang.ahk

; An invoker for handily invoking virtual methods.
class gVtableInvoker {
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

; Returns an invoker for COM vtable calls.
gSys_ComVTableInvoker(ref, dependencies := "") {
    return gLang_CreateMemberCheckingProxy(new gVtableInvoker(ref, dependencies))
}

; Get the current PID.
gSys_Pid() {
    return DllCall("GetCurrentProcessId")	
}

global z__gutils_wmi := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") 

; Returns info about process with `pid`, or the current process.
gSys_GetProcessInfo(pid := "") {
    if (pid = "") {
        pid := gSys_Pid()
    }
    query = Select * From Win32_Process where ProcessId = %pid%
    results := z__gutils_wmi.ExecQuery(query)._NewEnum()
    while results[proc]
    {
        return {Name: proc.Name
        ,PID: proc.ProcessId
        ,ParentPID: proc.ParentProcessId
        ,Path: proc.ExecutablePath}
    }
}

; Returns the parent process of `pid`.
gSys_GetParentPid(pid) {
    query = Select ParentProcessId From Win32_Process where ProcessId = %pid%
    results := z__gutils_wmi.ExecQuery(query)._NewEnum()
    while results[proc]
    {
        return proc.ParentProcessId
    }
}