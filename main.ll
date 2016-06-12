@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"
@.space = private unnamed_addr constant i32 32
@.newline = private unnamed_addr constant i32 10
@.macro = private unnamed_addr constant i32 40
@.term = private unnamed_addr constant i32 41

%string = type opaque
%list = type opaque
%object = type opaque

declare i8* @malloc(i32) nounwind

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @feof(i8* nocapture) nounwind
declare i32 @getc(i8* nocapture) nounwind
declare i32 @ungetc(i32, i8* nocapture) nounwind

declare %object* @newStringObject(i32)
declare void @appendChar(%object*, i32)
declare void @printString(%object*)

declare i32 @putchar(i32) nounwind

define %object* @read(i8* %input) {
       %space = load i32* @.space
       %newline = load i32* @.newline
       %macro = load i32* @.macro
       %term = load i32* @.term

       br label %read_first

read_first:
       %firstChar = call i32 @getc(i8* %input)
       br label %leading_space

leading_space:
       %is_leading_ws = icmp eq i32 %firstChar, %space
       br i1 %is_leading_ws, label %read_first, label %leading_newline

leading_newline:
       %is_leading_nl = icmp eq i32 %firstChar, %newline
       br i1 %is_leading_nl, label %read_first, label %start_token

; TODO: Check for leading macro/term i.e. ( or )
; leading_macro:
;        %is_leading_macro = icmp eq i32 %firstChar, %macro
;        br i1 %is_leading_macro, label %start_macro, label %leading_term

; start_macro:
;       %macro_result = call %string* @start_macro(i8* %input, i32 %firstChar)
;       ret %string* %macro_result

; leading_term:
;        %is_leading_term = icmp eq i32 %firstChar, %term
;        br i1 %is_leading_term, label %start_term, label %start_token

; start_term:
;       %term_result = call %string* @start_term(i8* %input, i32 %firstChar)
;       ret %string* %term_result

start_token:
       %token = call %object* @newStringObject(i32 64)
       call void @appendChar(%object* %token, i32 %firstChar)

       br label %read_token

read_token:
       %nextChar = call i32 @getc(i8* %input)
       br label %inner_space

inner_space:
       %is_inner_ws = icmp eq i32 %nextChar, %space
       br i1 %is_inner_ws, label %finalize_token, label %inner_newline

inner_newline:
       %is_inner_nl = icmp eq i32 %nextChar, %newline
       br i1 %is_inner_nl, label %finalize_token, label %append_token

append_token:
       call void @appendChar(%object* %token, i32 %nextChar)
       br label %read_token

finalize_token:
       ret %object* %token
}

define i32 @main(i32 %argc, i8** %argv) {
       %arg1Ptr = getelementptr i8** %argv, i64 1
       %arg1Addr = load i8** %arg1Ptr

       %cast_open_mode = getelementptr [2 x i8]* @.open_mode, i64 0, i64 0
       %input = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

       %token = call %object* @read(i8* %input)
       call void @printString(%object* %token)

       ret i32 0
}
