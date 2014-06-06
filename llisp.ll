@.str = private unnamed_addr constant [13 x i8] c"define.llisp\00"
@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"
@.space = private unnamed_addr constant i32 32
@.newline = private unnamed_addr constant i32 10
@.macro = private unnamed_addr constant i32 40
@.term = private unnamed_addr constant i32 41

; Linked list, using int instead of char, since that's what getc gives
; us.
%string = type { %string*, i32 }

declare i8* @malloc(i32) nounwind

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @feof(i8* nocapture) nounwind
declare i32 @getc(i8* nocapture) nounwind
declare i32 @ungetc(i32, i8* nocapture) nounwind
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

define %string* @getNextToken(i8* %input, i32 %firstChar) {
entry:
       %space = load i32* @.space
       %newline = load i32* @.newline
       %macro = load i32* @.macro
       %term = load i32* @.term

       %tokenHead = alloca %string*
       %tokenTail = alloca %string*

       %newHead = call %string* @newString(i32 %firstChar)
       store %string* %newHead, %string** %tokenHead
       store %string* %newHead, %string** %tokenTail

       call i32 @putchar(i32 %firstChar)

       br label %first_macro

; This is mostly duplicated from check macro/terminating, below. Maybe
; some of this logic should be in read? I'll wait and see what is
; useful as we build out more of the code.
first_macro:
       %first_is_macro = icmp eq i32 %firstChar, %macro
       br i1 %first_is_macro, label %return, label %first_terminating

first_terminating:
       %first_is_term = icmp eq i32 %firstChar, %term
       br i1 %first_is_term, label %return, label %read_next

read_next:
       %next_char = call i32 @getc(i8* %input)

       %eof_ret = call i32 @feof(i8* %input)
       %is_eof = icmp ne i32 %eof_ret, 0
       br i1 %is_eof, label %return, label %check_space

check_space:
       %is_ws = icmp eq i32 %next_char, %space
       br i1 %is_ws, label %return, label %check_newline

check_newline:
       %is_nl = icmp eq i32 %next_char, %newline
       br i1 %is_nl, label %return, label %check_macro

; This will need to be configurable, in order to support reader
; macros.
check_macro:
       %is_macro = icmp eq i32 %next_char, %macro
       br i1 %is_macro, label %terminate, label %check_terminating

check_terminating:
       %is_term = icmp eq i32 %next_char, %term
       br i1 %is_term, label %terminate, label %process

terminate:
       call i32 @ungetc(i32 %next_char, i8* %input)
       br label %return

process:
       call i32 @putchar(i32 %next_char)

       %oldTail = load %string** %tokenTail
       %newTail = call %string* @appendChar(%string* %oldTail, i32 %next_char)
       store %string* %newTail, %string** %tokenTail
       br label %read_next

return:
       call i32 @putchar(i32 %newline)
       ret %string* %newHead
}

define void @read(i8* %input) {
entry:
       %space = load i32* @.space
       %newline = load i32* @.newline

       br label %read_next

read_next:
       %firstChar = call i32 @getc(i8* %input)

       %eof_ret = call i32 @feof(i8* %input)
       %is_eof = icmp ne i32 %eof_ret, 0
       br i1 %is_eof, label %return, label %check_space

check_space:
       %is_ws = icmp eq i32 %firstChar, %space
       br i1 %is_ws, label %read_next, label %check_newline

check_newline:
       %is_nl = icmp eq i32 %firstChar, %newline
       br i1 %is_nl, label %read_next, label %process

process:
       call %string* @getNextToken(i8* %input, i32 %firstChar)
       br label %read_next

return:
      ret void
}

define i32 @main() {
       %cast_filename = getelementptr [13 x i8]* @.str, i64 0, i64 0
       %cast_open_mode = getelementptr [2 x i8]* @.open_mode, i64 0, i64 0
       %input = call i8* @fopen(i8* %cast_filename, i8* %cast_open_mode)

       call void @read(i8* %input)

       ret i32 0
}
