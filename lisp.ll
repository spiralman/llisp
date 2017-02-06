@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare void @init_reader()
declare void @init_eval()

declare %object* @read(i8*)
declare %object* @eval(%object*)
declare void @print(%object*)

define void @init() {
       call void @init_reader()
       call void @init_eval()
       ret void
}

; Returns the evaluation of the last form
define %object* @evalFile(i8* %input) {
       %resultPtr = alloca %object*
       store %object* null, %object** %resultPtr

       br label %read_eval

read_eval:
       %token = call %object* @read(i8* %input)
       %is_eof = icmp eq %object* null, %token
       br i1 %is_eof, label %ret_result, label %eval_token

eval_token:
       %result = call %object* @eval(%object* %token)
       store %object* %result, %object** %resultPtr
       br label %read_eval

ret_result:
       %finalResult = load %object** %resultPtr
       ret %object* %finalResult
}
