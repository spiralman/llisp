declare i8* @malloc(i32) nounwind

%object = type opaque

declare %object* @newObject(i32, i8*)
declare i32 @tag(%object*)
declare i8* @unbox(%object*)

define %object* @newEmptyToken(i32 %size) {
       %tokenSpace = call i8* @malloc(i32 %size)
       store i8 0, i8* %tokenSpace

       %objectPtr = call %object* @newObject(i32 1, i8* %tokenSpace)
       ret %object* %objectPtr
}

define %object* @newConstToken(i8* %val) {
       %objectPtr = call %object* @newObject(i32 1, i8* %val)
       ret %object* %objectPtr
}

define void @appendChar(%object* %obj, i32 %val) {
       %char = trunc i32 %val to i8

       %stringSpace = call i8* @unbox(%object* %obj)
       %stringPosPtr = alloca i32

       store i32 0, i32* %stringPosPtr
       br label %read_next

read_next:
       %stringPos = load i32* %stringPosPtr
       %stringPosInc = add i32 1, %stringPos
       %stringTail = getelementptr i8* %stringSpace, i32 %stringPos

       %stringVal = load i8* %stringTail

       %is_null = icmp eq i8 0, %stringVal
       br i1 %is_null, label %append_char, label %increment

increment:
       store i32 %stringPosInc, i32* %stringPosPtr
       br label %read_next

append_char:
       store i8 %char, i8* %stringTail
       %stringTailInc = getelementptr i8* %stringSpace, i32 %stringPosInc
       store i8 0, i8* %stringTailInc

       ret void
}

define i1 @tokenMatches(%object* %token, i8* %match) {
       %str = call i8* @unbox(%object* %token)

       %tokenPosPtr = alloca i32

       store i32 0, i32* %tokenPosPtr
       br label %check_next

check_next:
       %tokenPos = load i32* %tokenPosPtr
       %tokenTail = getelementptr i8* %str, i32 %tokenPos
       %matchTail = getelementptr i8* %match, i32 %tokenPos

       %tokenVal = load i8* %tokenTail
       %matchVal = load i8* %matchTail

       %is_eq = icmp eq i8 %matchVal, %tokenVal
       br i1 %is_eq, label %check_null, label %unequal

; Since they are equal, we only need to check one
check_null:
       %is_null = icmp eq i8 0, %tokenVal
       br i1 %is_null, label %equal, label %iterate

iterate:
       %tokenPosInc = add i32 1, %tokenPos
       store i32 %tokenPosInc, i32* %tokenPosPtr
       br label %check_next

equal:
       ret i1 true

unequal:
       ret i1 false
}

define i1 @tokenEq(%object* %lval, %object* %rval) {
       %ltag = call i32 @tag(%object* %lval)
       %rtag = call i32 @tag(%object* %rval)

       %tagEq = icmp eq i32 %ltag, %rtag
       br i1 %tagEq, label %match_tags, label %ret_false

match_tags:
       %rptr = call i8* @unbox(%object* %rval)
       %valEq = call i1 @tokenMatches(%object* %lval, i8* %rptr)
       ret i1 %valEq

ret_false:
       ret i1 false
}
