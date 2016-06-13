@.nil_repr = private unnamed_addr constant [4 x i8] c"nil\00"

declare i8* @malloc(i32) nounwind
declare i32 @putchar(i32) nounwind

; Tag values:
; 0 - List
; 1 - String
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

define void @printList(i8* %listPtr) {
       %cellPtr = bitcast i8* %listPtr to %list*

       %headPtr = getelementptr %list* %cellPtr, i32 0, i32 0
       %head = load %object** %headPtr

       call void @print(%object* %head)

       %tailPtr = getelementptr %list* %cellPtr, i32 0, i32 1
       %tail = load %object** %tailPtr

       %is_end = icmp eq %object* %tail, null
       br i1 %is_end, label %finalize, label %print_next

print_next:
       call i32 @putchar(i32 32)

       %tailValPtr = getelementptr %object* %tail, i32 0, i32 1
       %tailVal = load i8** %tailValPtr

       call void @printList(i8* %tailVal)
       br label %finalize

finalize:
       ret void
}

define void @printString(i8* %str) {
       %stringPosPtr = alloca i32

       store i32 0, i32* %stringPosPtr
       br label %put_next

put_next:
       %stringPos = load i32* %stringPosPtr
       %stringTail = getelementptr i8* %str, i32 %stringPos

       %stringVal = load i8* %stringTail

       %is_null = icmp eq i8 0, %stringVal
       br i1 %is_null, label %done, label %print

print:
       %stringI = zext i8 %stringVal to i32
       call i32 @putchar(i32 %stringI)

       %stringPosInc = add i32 1, %stringPos
       store i32 %stringPosInc, i32* %stringPosPtr
       br label %put_next

done:
       ret void
}

define void @print(%object* %obj) {
       %is_nil = icmp eq %object* %obj, null
       br i1 %is_nil, label %print_nil, label %decode_obj

print_nil:
       %nil_repr = getelementptr [4 x i8]* @.nil_repr, i32 0, i32 0
       call void @printString(i8* %nil_repr)
       br label %finalize

decode_obj:
       %tagPtr = getelementptr %object* %obj, i32 0, i32 0
       %tag = load i32* %tagPtr

       %valPtr = getelementptr %object* %obj, i32 0, i32 1
       %val = load i8** %valPtr

       switch i32 %tag, label %finalize [ i32 0, label %print_list
                                          i32 1, label %print_string ]

print_list:
       call i32 @putchar(i32 40)
       call void @printList(i8* %val)
       call i32 @putchar(i32 41)
       br label %finalize

print_string:
       call void @printString(i8* %val)
       br label %finalize

finalize:
       ret void
}

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
