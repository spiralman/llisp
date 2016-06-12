@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"
@.space = private unnamed_addr constant i32 32
@.newline = private unnamed_addr constant i32 10
@.macro = private unnamed_addr constant i32 40
@.term = private unnamed_addr constant i32 41

@macro_table = linkonce global [ 256 x %object* (i8*, i32)* ] zeroinitializer

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

define %object* @start_list(i8* %input, i32 %char) {
       ret %object* null
}

define %object* @end_list(i8* %input, i32 %char) {
       ret %object* null
}

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
       br i1 %is_leading_nl, label %read_first, label %leading_macro_check

leading_macro_check:
       %leadingMacroFnPtrPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 %firstChar
       %leadingMacroFnValPtr = bitcast %object* (i8*, i32)** %leadingMacroFnPtrPtr to i8**
       %leadingMacroFnVal = load i8** %leadingMacroFnValPtr
       %is_not_leading_macro = icmp eq i8* null, %leadingMacroFnVal
       br i1 %is_not_leading_macro, label %start_token, label %leading_macro

leading_macro:
       %leadingMacroFnPtr = bitcast i8* %leadingMacroFnVal to %object* (i8*, i32)*
       %leading_macro_res = call %object* %leadingMacroFnPtr(i8* %input, i32 %firstChar)
       ret %object* %leading_macro_res

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
       br i1 %is_inner_nl, label %finalize_token, label %inner_macro_check

inner_macro_check:
       %innerMacroFnPtrPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 %nextChar
       %innerMacroFnValPtr = bitcast %object* (i8*, i32)** %innerMacroFnPtrPtr to i8**
       %innerMacroFnVal = load i8** %innerMacroFnValPtr
       %is_not_inner_macro = icmp eq i8* null, %innerMacroFnVal
       br i1 %is_not_inner_macro, label %append_token, label %inner_macro

inner_macro:
       call i32 @ungetc(i32 %nextChar, i8* %input)
       br label %finalize_token

append_token:
       call void @appendChar(%object* %token, i32 %nextChar)
       br label %read_token

finalize_token:
       ret %object* %token
}

define i32 @main(i32 %argc, i8** %argv) {
       %startListPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 40
       store %object* (i8*, i32)* @start_list, %object* (i8*, i32)** %startListPtr

       %endListPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 41
       store %object* (i8*, i32)* @end_list, %object* (i8*, i32)** %endListPtr

       %arg1Ptr = getelementptr i8** %argv, i64 1
       %arg1Addr = load i8** %arg1Ptr

       %cast_open_mode = getelementptr [2 x i8]* @.open_mode, i64 0, i64 0
       %input = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

       %token = call %object* @read(i8* %input)
       call void @printString(%object* %token)

       ret i32 0
}
