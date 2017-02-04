declare i8* @malloc(i32) nounwind

; Tag values:
; 0 - List
; 1 - Token
%object = type {
        i32,  ; Tag
        i8*   ; Value (may be bitcast, if it safely fits in a pointer)
}

%list = type {
      %object*,  ; Value (null on last element)
      %object*   ; Next node (null on last element)
}

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

define %object* @newTokenObject(i32 %size) {
       %tokenSpace = call i8* @malloc(i32 %size)
       store i8 0, i8* %tokenSpace

       %objectPtr = call %object* @newObject(i32 1, i8* %tokenSpace)
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

define i32 @tag(%object* %obj) {
       %tagPtr = getelementptr %object* %obj, i32 0, i32 0
       %tag = load i32* %tagPtr
       ret i32 %tag
}

define i8* @unbox(%object* %obj) {
       %valPtr = getelementptr %object* %obj, i32 0, i32 1
       %val = load i8** %valPtr

       ret i8* %val
}

define i1 @isNil(%object* %obj) {
       %head = call %object* @first(%object* %obj)
       %is_nil = icmp eq %object* %head, null

       ret i1 %is_nil
}

; returns:
; Object: tag list
;         value -> List: value -> head
;                        next -> tail (Object)
;
; Cons A with null to create a new list
define %object* @cons(%object* %head, %object* %tail) {
       %listSize = getelementptr %list* null, i32 1
       %listSizeI = ptrtoint %list* %listSize to i32

       %listSpace = call i8* @malloc(i32 %listSizeI)
       %listPtr = bitcast i8* %listSpace to %list*

       %valPtr = getelementptr %list* %listPtr, i32 0, i32 0
       store %object* %head, %object** %valPtr

       %nextPtr = getelementptr %list* %listPtr, i32 0, i32 1
       store %object* %tail, %object** %nextPtr

       %objectPtr = call %object* @newObject(i32 0, i8* %listSpace)
       ret %object* %objectPtr
}

define %object* @first(%object* %obj) {
       %valPtr = getelementptr %object* %obj, i32 0, i32 1
       %val = load i8** %valPtr

       %cellPtr = bitcast i8* %val to %list*

       %headPtr = getelementptr %list* %cellPtr, i32 0, i32 0
       %head = load %object** %headPtr

       ret %object* %head
}

define %object* @rest(%object* %obj) {
       %valPtr = getelementptr %object* %obj, i32 0, i32 1
       %val = load i8** %valPtr

       %cellPtr = bitcast i8* %val to %list*

       %tailPtr = getelementptr %list* %cellPtr, i32 0, i32 1
       %tail = load %object** %tailPtr

       ret %object* %tail
}
