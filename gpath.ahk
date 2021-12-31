#include garr.ahk
#include gstr.ahk

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
    if (!success) {

    }
    return outBuf
}
