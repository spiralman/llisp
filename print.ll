@.nil_repr = private unnamed_addr constant [4 x i8] c"nil\00"

declare i32 @putchar(i32) nounwind

%object = type opaque
declare %object* @first(%object*)
declare %object* @rest(%object*)

declare i32 @tag(%object*)
declare i8* @unbox(%object*)

; (foo) -> (cons foo (cons nil nil))
; obj -> list -> obj -> foo
;                obj -> list -> null
;                               null

; (foo bar) -> (cons foo (cons bar (cons nil nil)))
; obj -> list -> obj -> foo
;                obj -> list -> obj -> bar
;                               obj -> list -> null
;                                              null

define void @printListElems(%object* %obj) {
       %head = call %object* @first(%object* %obj)
       %is_end = icmp eq %object* %head, null
       br i1 %is_end, label %finalize, label %print_next

print_next:
       call i32 @putchar(i32 32)
       call void @print(%object* %head)

       %tail = call %object* @rest(%object* %obj)

       call void @printListElems(%object* %tail)
       br label %finalize

finalize:
       ret void
}

define void @printList(%object* %obj) {
       %head = call %object* @first(%object* %obj)
       %is_nil = icmp eq %object* %head, null
       br i1 %is_nil, label %print_nil, label %print_list

print_nil:
       %nil_repr = getelementptr [4 x i8]* @.nil_repr, i32 0, i32 0
       call void @printToken(i8* %nil_repr)
       br label %finalize

print_list:
       call i32 @putchar(i32 40)
       call void @print(%object* %head)

       %tail = call %object* @rest(%object* %obj)
       call void @printListElems(%object* %tail)
       call i32 @putchar(i32 41)
       br label %finalize

finalize:
       ret void
}

define void @printToken(i8* %str) {
       %tokenPosPtr = alloca i32

       store i32 0, i32* %tokenPosPtr
       br label %put_next

put_next:
       %tokenPos = load i32* %tokenPosPtr
       %tokenTail = getelementptr i8* %str, i32 %tokenPos

       %tokenVal = load i8* %tokenTail

       %is_null = icmp eq i8 0, %tokenVal
       br i1 %is_null, label %done, label %print

print:
       %tokenI = zext i8 %tokenVal to i32
       call i32 @putchar(i32 %tokenI)

       %tokenPosInc = add i32 1, %tokenPos
       store i32 %tokenPosInc, i32* %tokenPosPtr
       br label %put_next

done:
       ret void
}

define void @print(%object* %obj) {
       %is_nil = icmp eq %object* %obj, null
       br i1 %is_nil, label %finalize, label %decode_obj

decode_obj:
       %tag = call i32 @tag(%object* %obj)

       %val = call i8* @unbox(%object* %obj)

       switch i32 %tag, label %finalize [ i32 0, label %print_list
                                          i32 1, label %print_token ]

print_list:
       call void @printList(%object* %obj)
       br label %finalize

print_token:
       call void @printToken(i8* %val)
       br label %finalize

finalize:
       ret void
}
