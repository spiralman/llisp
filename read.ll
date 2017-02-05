@.space = private unnamed_addr constant i32 32
@.newline = private unnamed_addr constant i32 10
@.macro = private unnamed_addr constant i32 40
@.term = private unnamed_addr constant i32 41

@macro_table = linkonce global [ 256 x %object* (i8*, i32)* ] zeroinitializer

%list = type opaque
%object = type opaque

declare i8* @malloc(i32) nounwind

declare i32 @feof(i8* nocapture) nounwind
declare i32 @getc(i8* nocapture) nounwind
declare i32 @ungetc(i32, i8* nocapture) nounwind

declare %object* @newEmptyToken(i32)
declare void @appendChar(%object*, i32)
declare %object* @newObject(i32, i8*)
declare %object* @cons(%object*, %object*)

define %object* @read_list(i8* %input, i32 %char) {
       %nextHead = call %object* @read(i8* %input)
       %is_end = icmp eq %object* %nextHead, null
       br i1 %is_end, label %at_end, label %read_tail
at_end:
       %nil = call %object* @cons(%object* null, %object* null)
       ret %object* %nil

read_tail:
       %nextTail = call %object* @read_list(i8* %input, i32 %char)
       %list = call %object* @cons(%object* %nextHead, %object* %nextTail)

       ret %object* %list
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

       %firstEOF = call i32 @feof(i8* %input)
       %is_not_firstEOF = icmp eq i32 0, %firstEOF
       br i1 %is_not_firstEOF, label %leading_space, label %leading_eof

leading_eof:
       ret %object* null

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
       %token = call %object* @newEmptyToken(i32 64)
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

define void @init_reader() {
       ;; This could be done statically, but this is less typing
       %startListPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 40
       store %object* (i8*, i32)* @read_list, %object* (i8*, i32)** %startListPtr

       %endListPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 41
       store %object* (i8*, i32)* @end_list, %object* (i8*, i32)** %endListPtr

       ret void
}