
; Represents an entry in a stack trace.
class gStackFrame {

    ToString() {
        x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
        return x
    }

    New(file, line, function, offset) {
        frame := new gStackFrame()
        frame.File := file
        frame.Line := line
        frame.Function := function
        frame.Offset := offset
        return gLang_SmartProxy(frame)
    }
}

z__gutils_printStack(frames) {
    text := ""
    for i, frame in frames {
        if (i != 1) {
            text .= "`r`n"
        }
        text .= frame.ToString()
    }
}

z__gutils_entryToString(e) {
    x := Format("{1}:{2} {4}+{3} ", e.File, e.Line, e.Function, e.Offset)
    return x
}

; Returns a textual stack trace.
gLang_StackTrace(ignoreLast := 0) {
    ; Originally by Coco in http://ahkscript.org/boards/viewtopic.php?f=6&t=6001
    frames := []
    Loop
    {
        offset := -A_Index + 1
        e := Exception(".", offset)
        if (e.What == offset && offset != 0) {
            break
        }
        frames.Push(gStackFrame.New(e.File, e.Line, e.What, offset))
    }
    ; In this state, the File:Line refer to the place where execution entered What.
    ; That's actually not very useful. I want it to have What's location instead. So we nbeed
    ; to shuffle things a bit

    for i in frames {
        if (i >= frames.MaxIndex()) {
            break
        }
        frames[i].Function := frames[i+1].Function
    }
    Loop, % ignoreLast + 1
    {
        frames.RemoveAt(1, 1)
    }
    return frames
}