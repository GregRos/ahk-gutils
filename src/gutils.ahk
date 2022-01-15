; ================================================================
; Contains utility commonly used utility functions.
; Meant to be reusable.
; ================================================================
#include gfunc.ahk
#include gtype.ahk
#include gstack.ahk
#include glang.ahk
#include garr.ahk
#include gobj.ahk
#include gstr.ahk
#include gwin.ahk
#include gsys.ahk
#include greg.ahk
#include goops.ahk
#include gassert.ahk
#include gpath.ahk
#include gout.ahk
gUtils(goops := False) {
    if (goops) {
        gOops_Setup()
    }
}