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
define %object* @mainFile(i32 %argc, i8** %argv) {
       %arg1Ptr = getelementptr i8** %argv, i64 1
       %arg1Addr = load i8** %arg1Ptr

       %cast_open_mode = getelementptr [2 x i8]* @.open_mode, i64 0, i64 0
       %input = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

       %token = call %object* @read(i8* %input)
       %result = call %object* @eval(%object* %token)

       ret %object* %result
}
