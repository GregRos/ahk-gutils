; ================================================================
; Contains utility commonly used utility functions.
; Meant to be reusable.
; ================================================================

#include garr.ahk
#include glang.ahk
#include gobj.ahk
#include gstr.ahk
#include gwin.ahk
#include gsys.ahk
#include greg.ahk
#include goops.ahk
#include gassert.ahk

gUtils(goops := False) {
    if (goops) {
        gOops_Setup()
    }
}