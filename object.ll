declare i8* @malloc(i32) nounwind

; Tag values:
; 0 - List
; 1 - Token
; 2 - Native Function
%object = type {
        i32,  ; Tag
        i8*   ; Value (may be bitcast, if it safely fits in a pointer)
}

define %object* @newObject(i32 %tag, i8* %val) {
       %objSizePtr = getelementptr %object, %object* null, i32 1
       %objSize = ptrtoint %object* %objSizePtr to i32

       %objSpace = call i8* @malloc(i32 %objSize)
       %objPtr = bitcast i8* %objSpace to %object*

       %tagPtr = getelementptr %object, %object* %objPtr, i32 0, i32 0
       store i32 %tag, i32* %tagPtr

       %valPtr = getelementptr %object, %object* %objPtr, i32 0, i32 1
       store i8* %val, i8** %valPtr

       ret %object* %objPtr
}

define i32 @tag(%object* %obj) {
       %tagPtr = getelementptr %object, %object* %obj, i32 0, i32 0
       %tag = load i32, i32* %tagPtr
       ret i32 %tag
}

define i8* @unbox(%object* %obj) {
       %valPtr = getelementptr %object, %object* %obj, i32 0, i32 1
       %val = load i8*, i8** %valPtr

       ret i8* %val
}
