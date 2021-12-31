#include _common.ahk
gArr_Repeat(item, count) {
    arr:=[]
    Loop, %count%
    {
        arr.Insert(item)
    }
    return arr
}

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
    func := gLang_NormFunc(func)
    return gArr_Filter(arr, func)[1]
}

gArr_FindIndexes(arr, func) {
    results := []
    func := gLang_NormFunc(func)
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

gArr_Slice(arr, start := 1, end := 0) {
    result:=[]
    start:= __g_NormalizeIndex(start, arr.MaxIndex())
    end:= __g_NormalizeIndex(end, arr.MaxIndex())
    if (end < start) {
        return result
    }
    Loop, % end - start + 1
    {
        result.Insert(arr[start + A_Index - 1])
    }
    return result
}

gArr_Map(arr, projection) {
    projection := gLang_NormFunc(projection)
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
    filter := gLang_NormFunc(filter)
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


