#include _common.ahk
#include garr.ahk
gEx_FancyInit()

__g_setupNonObjectCheck() {
    rawBase := "".base
    rawBase.__Get := Func("__g_UnknownGet")
    rawBase.__Set := Func("__g_UnknownSet")
    rawBase.__Call := Func("__g_UnknownCall")
}

__g_setupNonObjectCheck()
__g_UnknownGet(nonobj, name) {
    gEx_Throw(Format("Tried to get property '{1}' from non-object value '{2}',", name, nonobj))
}

__g_UnknownSet(nonobj, name, values*) {
    gEx_Throw(Format("Tried to set property '{1}' on non-object value '{2}'.", name, nonobj))
}

__g_UnknownCall(nonobj, name, args*) {
    gEx_Throw(Format("Tried to call method '{1}' on non-object value '{2}'.", name, nonobj))
}
