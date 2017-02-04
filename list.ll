declare i8* @malloc(i32) nounwind

%object = type opaque

declare %object* @newObject(i32, i8*)
declare i32 @tag(%object*)
declare i8* @unbox(%object*)

%list = type {
      %object*,  ; Value (null on last element)
      %object*   ; Next node (null on last element)
}

define i1 @isNil(%object* %obj) {
       %tag = call i32 @tag(%object* %obj)

       %is_list = icmp eq i32 %tag, 0
       br i1 %is_list, label %check_nil, label %not_nil

not_nil:
       ret i1 false

check_nil:
       %head = call %object* @first(%object* %obj)
       %is_nil = icmp eq %object* %head, null

       ret i1 %is_nil
}

; returns:
; Object: tag list
;         value -> List: value -> head (Object or nil)
;                        next -> tail (Object of type list)
;
; Cons null with null to create an empty list/nil.
; Cons Obj with nil to create a list of 1 element.
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
       %val = call i8* @unbox(%object* %obj)

       %cellPtr = bitcast i8* %val to %list*

       %headPtr = getelementptr %list* %cellPtr, i32 0, i32 0
       %head = load %object** %headPtr

       ret %object* %head
}

define %object* @rest(%object* %obj) {
       %val = call i8* @unbox(%object* %obj)

       %cellPtr = bitcast i8* %val to %list*

       %tailPtr = getelementptr %list* %cellPtr, i32 0, i32 1
       %tail = load %object** %tailPtr

       ret %object* %tail
}
