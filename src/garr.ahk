#include glang.ahk
; A module for working with arrays.



; Returns an array where `self` appears `count` times, e.g. `[self, self, ...]`
gArr_Repeat(self, count) {
    arr:=[]
    Loop, %count%
    {
        arr.Insert(self)
    }
    return arr
}

; Returns the position of the first occurence of `what` in `self`.
gArr_IndexOf(self, what, case := False) {
    z__gutils_assertArray(self)

    for ix, value in self {
        if((!case && what = value) || what == value) {
            return ix
        }
    }
    return 0	
}

; Returns true if `self` contains `what` as a substring.
gArr_Has(self, what) {
    z__gutils_assertArray(self)
    return gArr_IndexOf(self, what) > 0
}

; Returns the find element in `self` that match `predicate`. `predicate` can be a function name or function object.
gArr_Find(self, predicate) {
    z__gutils_assertArray(self)
    predicate := gLang_Func(predicate)
    if (!predicate) {

    }
    return gArr_Filter(self, predicate)[1]
}

; Returns the positions of all the elements matching `predicate`. `predicate` can be a function name or function object.
gArr_FindIndexes(self, predicate) {
    z__gutils_assertArray(self)
    results := []
    predicate := gLang_Func(predicate)
    for index, item in self {
        if (gLang_Call(predicate, item, index)) {
            results.push(index)
        }
    }
    return results
}

; Find first position of the element matching `predicate`. `predicate` can be a function name or object.
gArr_FindIndex(self, predicate) {
    z__gutils_assertArray(self)
    return gArr_FindIndexes(self, predicate)[1]
}

; Returns the array in sorted order, with the sorting options `options`.
gArr_Order(self, options := "N") {
    z__gutils_assertArray(self)
    str:= gStr_Join(self, "~")
    options .= " D~"
    Sort, str, %options%
    self:=[]
    Loop, Parse, str, ~ 
    {
        self.Insert(A_LoopField)
    }
    return self	
}

; Returns a new array that's a concatenation of all the arrays in `arrs`.
gArr_Concat(arrs*) {
    z__gutils_assertArray(arrs)
    c := []
    for i, self in arrs {
        for j, item in self {
            c.Push(item)
        }
    }
    return c
}

; returns a new array that's the result of applying `projection` on every element. `projection` can be a funciton name or object.
gArr_Map(self, projection) {
    z__gutils_assertArray(self)
    projection := gLang_Func(projection)
    result := []
    for index, item in self {
        result.Push(gLang_Call(projection, item, index))
    }
    return result
}

; Returns the first slice of `n` elements.
gArr_Take(self, n) {

    return gArr_Slice(self, 1, n)
}

; Returns a new array that's made of all the elements matching `filter`. `filter` can be a function name or object.
gArr_Filter(self, filter) {
    z__gutils_assertArray(self)
    filter := gLang_Func(filter)
    result := []
    for index, item in self {
        if (gLang_Call(filter, item, index)) {
            result.Push(item)
        }
    }
    return result
}

; Returns the last element matching `predicate`. `predicate` can be a function name or object.
gArr_FindLastIndex(self, predicate) {
    z__gutils_assertArray(self)
    self := gArr_FindIndexes(self, predicate)
    return self[self.MaxIndex()]
}

; Returns true if `self` is an array.
gArr_Is(self) {
    return IsObject(self) && self.MaxIndex() != ""
}

; Gets the element at position `pos`. Supports inverse indexing.
gArr_At(self, pos) {
    z__gutils_assertArray(self)
    nIndex := z__gutils_NormalizeIndex(pos, self.MaxIndex())
    return self[nIndex]
}

; Returns a new array that's `self` in reverse order.
gArr_Reverse(self) {
    z__gutils_assertArray(self)
    newArr := []
    Loop, % self.MaxIndex()
    {
        newArr.Push(self[self.MaxIndex() - A_Index + 1])
    }
    return newArr
}

; Recursively flattens an array with array elements into an array of non-array elements.
gArr_Flatten(self) {
    z__gutils_assertArray(self)
    total := []
    for i, item in self {
        if (gArr_Is(item)) {
            total.Push(gArr_Flatten(item)*)
        } else {
            total.Push(item)
        }
    }
    return total
}