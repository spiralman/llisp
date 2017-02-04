declare i8* @malloc(i32) nounwind

%object = type opaque

declare %object* @newObject(i32, i8*)
declare i8* @unbox(%object*)

define %object* @newTokenObject(i32 %size) {
       %tokenSpace = call i8* @malloc(i32 %size)
       store i8 0, i8* %tokenSpace

       %objectPtr = call %object* @newObject(i32 1, i8* %tokenSpace)
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
