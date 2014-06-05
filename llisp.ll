@.str = private unnamed_addr constant [13 x i8] c"define.llisp\00"
@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"
@.space = private unnamed_addr constant i32 32
@.newline = private unnamed_addr constant i32 10

; Linked list, using int instead of char, since that's what getc gives
; us.
%string = type { %string*, i32 }

declare i8* @malloc(i32) nounwind

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @feof(i8* nocapture) nounwind
declare i32 @getc(i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

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

define void @getNextToken(i8* %input) {
entry:
       %space = load i32* @.space
       %newline = load i32* @.newline

       %tokenHead = alloca %string*
       store %string* null, %string** %tokenHead

       %tokenTail = alloca %string*
       store %string* null, %string** %tokenTail

       br label %read_space

read_space:
       %first_char = call i32 @getc(i8* %input)

       %is_ws = icmp eq i32 %first_char, %space
       br i1 %is_ws, label %read_space, label %check_newline

check_newline:
       %is_nl = icmp eq i32 %first_char, %newline
       br i1 %is_nl, label %read_space, label %process

process:
       call i32 @putchar(i32 %first_char)

       %currentHead = load %string** %tokenHead
       %isFirstChar = icmp eq %string* null, %currentHead
       br i1 %isFirstChar, label %initialize_token, label %append_char

initialize_token:
       %newHead = call %string* @newString(i32 %first_char)
       store %string* %newHead, %string** %tokenHead
       store %string* %newHead, %string** %tokenTail
       br label %continue

append_char:
       %newTail = call %string* @appendChar(%string* %currentHead, i32 %first_char)
       store %string* %newTail, %string** %tokenTail
       br label %continue

; Need to move the EOF check out of this function into a read
; function, and make this read just one token.
continue:
       %eof_ret = call i32 @feof(i8* %input)
       %is_eof = icmp ne i32 %eof_ret, 0
       br i1 %is_eof, label %eof, label %read_space

eof:
       ret void
}

define i32 @main() {
       %cast_filename = getelementptr [13 x i8]* @.str, i64 0, i64 0
       %cast_open_mode = getelementptr [2 x i8]* @.open_mode, i64 0, i64 0
       %input = call i8* @fopen(i8* %cast_filename, i8* %cast_open_mode)

       call void @getNextToken(i8* %input)

       ret i32 0
}
