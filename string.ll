@.newline = private unnamed_addr constant i32 10

declare i8* @malloc(i32) nounwind
declare i32 @putchar(i32) nounwind

; Linked list, using int instead of char, since that's what getc gives
; us.
%string = type { %string*, i32 }

define %string* @newString(i32 %char) {
       %stringSize = getelementptr %string* null, i32 1
       %stringSizeI = ptrtoint %string* %stringSize to i32

       %stringSpace = call i8* @malloc(i32 %stringSizeI)
       %stringPtr = bitcast i8* %stringSpace to %string*

       %nextPtr = getelementptr %string* %stringPtr, i32 0, i32 0
       store %string* null, %string** %nextPtr

       %charPtr = getelementptr %string* %stringPtr, i32 0, i32 1
       store i32 %char, i32* %charPtr

       ret %string* %stringPtr
}

; Returns new tail node of string
define %string* @appendChar(%string* %oldTail, i32 %char) {
       %newTail = call %string* @newString(i32 %char)

       %nextPtr = getelementptr %string* %oldTail, i32 0, i32 0
       store %string* %newTail, %string** %nextPtr

       ret %string* %newTail
}

define void @printString(%string* %head) {
       %newline = load i32* @.newline
       %curPtr = alloca %string*
       store %string* %head, %string** %curPtr

       br label %print

print:
       %curNode = load %string** %curPtr
       %charPtr = getelementptr %string* %curNode, i32 0, i32 1
       %charVal = load i32* %charPtr

       call i32 @putchar(i32 %charVal)

       %nextPtr = getelementptr %string* %curNode, i32 0, i32 0
       %nextVal = load %string** %nextPtr
       store %string* %nextVal, %string** %curPtr

       %is_end = icmp eq %string* %nextVal, null
       br i1 %is_end, label %done, label %print

done:
       call i32 @putchar(i32 %newline)
       ret void
}
