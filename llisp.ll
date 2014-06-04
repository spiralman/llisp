@.str = private unnamed_addr constant [13 x i8] c"define.llisp\00"
@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"
@.space = private unnamed_addr constant i32 32
@.newline = private unnamed_addr constant i32 10

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @feof(i8* nocapture) nounwind
declare i32 @getc(i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

define void @getNextToken(i8* %input) {
entry:
       %pos_ptr = alloca i64
       store i64 0, i64* %pos_ptr

       %space = load i32* @.space
       %newline = load i32* @.newline
       br label %read_space

read_space:
       %first_char = call i32 @getc(i8* %input)

       %is_ws = icmp eq i32 %first_char, %space
       br i1 %is_ws, label %read_space, label %check_newline

check_newline:
       %is_wc = icmp eq i32 %first_char, %newline
       br i1 %is_ws, label %read_space, label %print

print:
       call i32 @putchar(i32 %first_char)
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
