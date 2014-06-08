declare i8* @malloc(i32) nounwind

%list = type { %list*, i8* }

define %list* @newList(i8* %val) {
       %listSize = getelementptr %list* null, i32 1
       %listSizeI = ptrtoint %list* %listSize to i32

       %listSpace = call i8* @malloc(i32 %listSizeI)
       %listPtr = bitcast i8* %listSpace to %list*

       %nextPtr = getelementptr %list* %listPtr, i32 0, i32 0
       store %list* null, %list** %nextPtr

       %valPtr = getelementptr %list* %listPtr, i32 0, i32 1
       store i8* %val, i8** %valPtr

       ret %list* %listPtr
}

; Returns new tail node of list
define %list* @appendVal(%list* %oldTail, i8* %val) {
       %newTail = call %list* @newList(i8* %val)

       %nextPtr = getelementptr %list* %oldTail, i32 0, i32 0
       store %list* %newTail, %list** %nextPtr

       ret %list* %newTail
}
