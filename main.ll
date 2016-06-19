@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"

@macro_table = available_externally global [ 256 x %object* (i8*, i32)* ] zeroinitializer

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare %object* @read(i8*) nounwind
declare %object* @read_list(i8*, i32) nounwind
declare %object* @end_list(i8*, i32) nounwind
declare void @print(%object*)


define i32 @main(i32 %argc, i8** %argv) {
       %startListPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 40
       store %object* (i8*, i32)* @read_list, %object* (i8*, i32)** %startListPtr

       %endListPtr = getelementptr [ 256 x %object* (i8*, i32)* ]* @macro_table, i32 0, i32 41
       store %object* (i8*, i32)* @end_list, %object* (i8*, i32)** %endListPtr

       %arg1Ptr = getelementptr i8** %argv, i64 1
       %arg1Addr = load i8** %arg1Ptr

       %cast_open_mode = getelementptr [2 x i8]* @.open_mode, i64 0, i64 0
       %input = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

       %token = call %object* @read(i8* %input)
       call void @print(%object* %token)
       call i32 @putchar(i32 10)

       ret i32 0
}
