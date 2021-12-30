gRegEx_MultiMatchGroups(haystack, needle) {
    array:=[]
    Loop, 10 
    {
        match%A_Index% := [""]
    }
    while (pos := RegExMatch(haystack, needle, match, ((pos>=1) ? pos : 1)+StrLen(match))) {
        curArray:=[]
        Loop, 10
        {
            cur := match%A_Index%
            if (cur.MaxIndex() = 1) {
                break
            }
            curArray.Insert(cur)
        }
        array.Insert({text:match, groups:curArray})
    }
    Return array
}

gRegEx_MultiMatch(haystack, needle) {
    array:=[]
    while (pos := RegExMatch(haystack, needle, match, ((pos>=1) ? pos : 1)+StrLen(match))) {
        array[A_Index]:=match
    }
    Return array
}