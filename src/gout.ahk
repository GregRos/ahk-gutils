
class gOutFile {
    _fOut := ""
    _fErr := ""
    _stripAnsi := ""

    New(fOut, fErr) {
        return gLang_SmartProxy(new gOutFile(fOut, fErr))
    }
    
    __New(fOut, fErr){
        base.__New()
        this._fOut := fOut
        this._fErr := fErr
    }

    Out(args*) {
        this._fStdOut.WriteLine(z__gutils_strArgs(args, this._stripAnsi))
    }

    Err(args*) {
        this._fErr.WriteLine(z__gutils_strArgs(args, this._stripAnsi))
    }
}

class gOutDebug  {
    New() {
        return gLang_SmartProxy(new gOutDebug())
    }

    Out(args*) {
        OutputDebug, % z__gutils_strArgs(args, True)
    }

    Err(args*) {
        this.Out(args*)
    }
}

class gOutAll {
    _all := ""


    New(all) {
        return new gOutAll(all)
    }

    __New(all) {
        this._all := all
    }

    Out(args*) {
        for i, out in this._all {
            out.Out(args*)
        }
    }

    Err(args*) {
        for i, out in this._all {
            out.Err(args*)
        }
    }
}

z__gutils_strArgs(args, stripFormatting) {
    result := gArr_Join(gArr_Map(strs, "gStr"), " ")
    return RegExReplace(result, "i)\e")
}

z__gutils_encoding() {
    return A_IsUnicode ? "UTF-8" : ""
}

global z__gutils_stdOut := FileOpen("*", "w", z__gutils_encoding())
global z__gutils_stderr := FileOpen("**", "w", z__gutils_encoding())

gOut_Debug() {
    return new gOutDebug()
}

gOut_Std(ansiSupport := True) {
    return new gOutFile(z__gutils_stdOut, z__gutils_stderr, stripFormatting)
}

gOut_File(file, ansiSupport := False) {
    if (gType_Is(file, "File")) {
        gEx_Throw("Must be a file.")
    }
    return new gOutFile(file, file, ansiSupport)
}

z__gutils_getFormattingKws() {
    ; Based on chalk: https://github.com/chalk/chalk/blob/4d5c4795ad24c326ae16bfe0c39c826c732716a9/source/vendor/ansi-styles/index.js#L3
    styles := {reset: [0, 0]
        , bold: [1, 22]
        , dim: [2, 22]
        , italic: [2, 22]
        , underline: [4, 24]
        , overline: [53, 55]
        , inverse: [7, 27]
    , hidden: [8, 28]}

    for k, arr in styles {
        arr.Push("style")
    }
    gObj_Aliases(styles, {r: "reset"
            , b: "bold"
            , d: "dim"
            , i: "italic"
            , u: "underline"
            , o: "overline"
            , ii: "inverse"
    , h: "hidden"})

    colors := {black: [30, 39]
        , red: [31, 39]
        , green: [32, 39]
        , yellow: [33, 39]
        , blue: [34, 39]
        , magenta: [35, 39]
        , cyan: [36, 39]
    , white: [37, 39]}

    for k, arr in colors {
        arr.Push("color")
    }

    brights := {}
    for k, v in colors {
        ; The "bright" colors
        ; e.g black!
        xs := brights[k + "!"] := [v[1] + 60, v[2]]
        xs.Push("color")
    }
    bgColors := {}
    allColors := gObj_Merge(colors, brights)
    for k, v in allColors {
        ; the bg colors, e.g. bgblack
        xs := bgColors["bg" + k] := [v[1] + 10, 49]
        xs.Push("bgColor")
    }

    all := gObj_Merge(styles, colors, brights, bgColors)
    return all
}

gOut_ParseAnsi(input) {
    
}

; Std - log to std, 
gOut_Configure(modes*) {
    methods := []
    for i, mode in modes {
        if (mode = "std") {
            methods.Push(new gOutputMethod(""))
        }
    }
}

gOut(out) {
    OutputDebug, % gStr(Out)
}