@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare void @init() nounwind
declare %object* @mainFile(i32, i8**)
declare void @print(%object*)

define i32 @main(i32 %argc, i8** %argv) {
       call void @init()

       %result = call %object* @mainFile(i32 %argc, i8** %argv)
       call void @print(%object* %result)
       call i32 @putchar(i32 10)

       ret i32 0
}
