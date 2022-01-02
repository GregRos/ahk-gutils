﻿#include glang.ahk
gArr_Repeat(item, count) {
    arr:=[]
    Loop, %count%
    {
        arr.Insert(item)
    }
    return arr
}

; Gets the index of the item `what` in `arr`
gArr_IndexOf(arr, what) {
    for ix, value in arr {
        if(what = value) {
            return ix
        }
    }
    return 0	
}

gArr_Has(arr, what) {
    return gArr_IndexOf(arr, what) > 0
}

gArr_Find(arr, func) {
    func := gLang_Func(func)
    return gArr_Filter(arr, func)[1]
}

gArr_FindIndexes(arr, func) {
    results := []
    func := gLang_Func(func)
    for index, item in arr {
        if (gLang_Call(func, item, index)) {
            results.push(index)
        }
    }
    return results
}

gArr_FindIndex(arr, func) {
    return gArr_FindIndexes(arr, func)[1]
}

gArr_Order(what, options := "N") {
    str:= gStr_Join(what, "~")
    options .= " D~"
    Sort, str, %options%
    arr:=[]
    Loop, Parse, str, ~ 
    {
        arr.Insert(A_LoopField)
    }
    return arr	
}

gArr_Concat(arrs*) {
    c := []
    for i, arr in arrs {
        for j, item in arr {
            c.Push(item)
        }
    }
    return c
}


gArr_Map(arr, projection) {
    projection := gLang_Func(projection)
    result := []
    for index, item in arr {
        result.Push(gLang_Call(projection, item, index))
    }
    return result
}

gArr_Take(arr, n) {
    return gArr_Slice(arr, 1, n)
}

gArr_Filter(arr, filter) {
    filter := gLang_Func(filter)
    result := []
    for index, item in arr {
        if (gLang_Call(filter, item, index)) {
            result.Push(item)
        }
    }
    return result
}

gArr_FindLastIndex(arr, filter) {
    arr := gArr_FindIndexes(arr, filter)
    return arr[arr.MaxIndex()]
}

gArr_Is(arr) {
    return IsObject(arr) && arr.MaxIndex() != ""
}

gArr_Reverse(arr) {
    newArr := []
    Loop, % arr.MaxIndex()
    {
        newArr.Push(arr[arr.MaxIndex() - A_Index + 1])
    }
    return newArr
}

gArr_Flatten(arr) {
    total := []
    for i, item in arr {
        if (gArr_Is(item)) {
            total.Push(gArr_Flatten(item)*)
        } else {
            total.Push(item)
        }
    }
    return total
}