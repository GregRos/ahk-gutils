# AHK gutils

This repo contains a set of utilities for AHK. Some of these are function versions of commands and others do the same thing, but with a different interface.

Is partially unit tested in `test/gutils.test.ahk`

Include everything by including `gutils`

## Common

Use `gDeclaredMembersOnly` to make it an error to call, set, or get things that haven't been declared during the init phase of an object.

`gOut(whatever)` lets you pipe out `OutputDebug`

`gLang_Equal` - checks for structural equality.

`gLang_StackTraceObj` - Returns a stack trace as an object.

## gArr

`garr.ahk`

Contains utility functions for working with arrays.

`gArr_Map` - Maps array elements with a function.

`gArr_Filter` - Filters array elements with a function.

## gAssert

Utilities for unit testing.

`gAssert_eq(real, expected)` - real is equal to expected.

## gDbg

Some debugging stuff.

1. Register an error handler that makes a better exception popup.
2. Disables calling properties/methods on non-objects

## gEx

Exception-related stuff.

`gEx_Throw("whatever")` - throws an exception with extra info.

## gLang

Lang-related stuff.

`gLang_Call(f)` - Calls `f` intelligently.

## gObj

Object-related stuff.

`gObj_Pick(o, "key1", "key2")` - Returns a subset of the object with the given keys.

## gReg

Doesn't work.

## gStr

String utility functions.

`gStr_Repeat(what, count)` - Repeats `what`, `count` times.

## gSys

Misc system related functions.

`gSys_ComInvoker` - Creates an invoker that can be used to invoke COM vtable methods.

## gUtils

includes everything.

## gWin

Window-related functions.

### query

These methods use "WinTitle query objects", which are objects with one or more of the properites:

1. `title`
2. `text`
3. `excludeTitle`
4. `excludeText`

This object is used instead of the standard signature when trying to find windows.

### gWinInfo

Calling `gWin_Get(query)` returns an object that stores the `hwnd` of the window, and lets you check its information using methods and properties.

