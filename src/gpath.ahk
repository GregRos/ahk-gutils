
; A path that's been parsed into its components.
class gParsedPath  {
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

    New(path) {
        return gLang_CreateMemberCheckingProxy(new gParsedPath(path))
    }
}


; Joins parts of a path with the right separator '\'.
gPath_Join(parts*) {
    return gArr_Join(gArr_Flatten(parts), "\")
}

; Parses a rooted or non-rooted path `path`.
gPath_Parse(path) {
    z__gutils__assertNotObject(path)
    return gParsedPath.New(path)
}

; Resolves relative parts `parts`. Each segment is resolved based on the segment before it, until reaching the CWD. 
gPath_Resolve(parts*) {
    z__gutils__assertNotObject(parts*)
    ; https://www.autohotkey.com/boards/viewtopic.php?t=67050
    joined := gPath_Join(parts*)
    cc := DllCall("GetFullPathName", "str", joined, "uint", 0, "ptr", 0, "ptr", 0, "uint")
    VarSetCapacity(buf, cc*(A_IsUnicode?2:1))
    DllCall("GetFullPathName", "str", joined, "uint", cc, "str", buf, "ptr", 0, "uint")
    return buf
}

; Returns a relative file path based on `from` to the file `to`.
gPath_Relative(from, to) {
    z__gutils__assertNotObject(from, to)
    FILE_ATTRIBUTE_DIRECTORY := 0x10
    VarSetCapacity(outBuf, 300 * (A_IsUnicode ? 2 : 1))
    success := DllCall("Shlwapi.dll\PathRelativePathTo", "str", outBuf,  "str", from, "uint", FILE_ATTRIBUTE_DIRECTORY, "str", to, "uint", FILE_ATTRIBUTE_DIRECTORY, "uint")
    return outBuf
}