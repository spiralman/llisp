declare i8* @malloc(i32) nounwind
declare i32 @puts(i8*) nounwind

; Tag values:
; 0 - List
; 1 - String
%object = type { i32, i8* }

%list = type { %list*, %object*, i32 }

define %object* @newObject(i32 %tag, i8* %val) {
       %objSizePtr = getelementptr %object* null, i32 1
       %objSize = ptrtoint %object* %objSizePtr to i32

       %objSpace = call i8* @malloc(i32 %objSize)
       %objPtr = bitcast i8* %objSpace to %object*

       %tagPtr = getelementptr %object* %objPtr, i32 0, i32 0
       store i32 %tag, i32* %tagPtr

       %valPtr = getelementptr %object* %objPtr, i32 0, i32 1
       store i8* %val, i8** %valPtr

       ret %object* %objPtr
}

define %object* @newListObject(%list* %val) {
       %genericVal = bitcast %list* %val to i8*
       %objectPtr = call %object* @newObject(i32 0, i8* %genericVal)
       ret %object* %objectPtr
}

define %object* @newStringObject(i32 %size) {
       %stringSpace = call i8* @malloc(i32 %size)
       store i8 0, i8* %stringSpace

       %objectPtr = call %object* @newObject(i32 1, i8* %stringSpace)
       ret %object* %objectPtr
}

define void @appendChar(%object* %obj, i32 %val) {
       %char = trunc i32 %val to i8
       %stringSpacePtr = getelementptr %object* %obj, i32 0, i32 1
       %stringSpace = load i8** %stringSpacePtr
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

define void @printString(%object* %obj) {
       %stringSpacePtr = getelementptr %object* %obj, i32 0, i32 1
       %stringSpace = load i8** %stringSpacePtr

       call i32 @puts(i8* %stringSpace)

       ret void
}

define %list* @newList(%object* %val) {
       %listSize = getelementptr %list* null, i32 1
       %listSizeI = ptrtoint %list* %listSize to i32

       %listSpace = call i8* @malloc(i32 %listSizeI)
       %listPtr = bitcast i8* %listSpace to %list*

       %nextPtr = getelementptr %list* %listPtr, i32 0, i32 0
       store %list* null, %list** %nextPtr

       %valPtr = getelementptr %list* %listPtr, i32 0, i32 1
       store %object* %val, %object** %valPtr

       ret %list* %listPtr
}

; Returns new tail node of list
define %list* @appendVal(%list* %oldTail, %object* %val) {
       %newTail = call %list* @newList(%object* %val)

       %nextPtr = getelementptr %list* %oldTail, i32 0, i32 0
       store %list* %newTail, %list** %nextPtr

       ret %list* %newTail
}
