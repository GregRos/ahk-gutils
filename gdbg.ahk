#include _common.ahk
gEx_FancyInit()
"".base.__Get := "".base.__Set := "".base.__Call := Func("__g_UnknownMethod")

__g_UnknownMethod(nonobj, p1="", p2="", p3="", p4="") {
    if (p1 = "MaxIndex") {
        return
    }
    gEx_Throw(Format("Tried to treat value '{0}' as an object.", nonobj))
}