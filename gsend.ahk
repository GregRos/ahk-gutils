
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

