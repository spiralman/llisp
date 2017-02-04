@.form_if = private unnamed_addr constant [ 3 x i8 ] c"if\00"

%object = type {
        i32,  ; Tag
        i8*   ; Value (may be bitcast, if it safely fits in a pointer)
}

%list = type {
      %object*,  ; Value (null on last element)
      %object*   ; Next node (null on last element)
}

declare %object* @first(%object*)
declare %object* @rest(%object*)

declare void @print(%object*)

define i1 @tokenMatches(%object* %token, i8* %match) {
       %strPtr = getelementptr %object* %token, i32 0, i32 1
       %str = load i8** %strPtr

       %tokenPosPtr = alloca i32

       store i32 0, i32* %tokenPosPtr
       br label %check_next

check_next:
       %tokenPos = load i32* %tokenPosPtr
       %tokenTail = getelementptr i8* %str, i32 %tokenPos
       %matchTail = getelementptr i8* %match, i32 %tokenPos

       %tokenVal = load i8* %tokenTail
       %matchVal = load i8* %matchTail

       %is_eq = icmp eq i8 %matchVal, %tokenVal
       br i1 %is_eq, label %check_null, label %unequal

; Since they are equal, we only need to check one
check_null:
       %is_null = icmp eq i8 0, %tokenVal
       br i1 %is_null, label %equal, label %iterate

iterate:
       %tokenPosInc = add i32 1, %tokenPos
       store i32 %tokenPosInc, i32* %tokenPosPtr
       br label %check_next

equal:
       ret i1 true

unequal:
       ret i1 false
}

define %object* @evalIf(%object* %forms) {
       %cond = call %object* @first(%object* %forms)
       %branches = call %object* @rest(%object* %forms)

       %condRes = call %object* @eval(%object* %cond)

       %is_nil = icmp eq %object* %condRes, null
       br i1 %is_nil, label %eval_else, label %compare_val

compare_val:
       %valPtr = getelementptr %object* %condRes, i32 0, i32 1
       %val = load i8** %valPtr
       %is_valNil = icmp eq i8* %val, null
       br i1 %is_valNil, label %eval_else, label %eval_then

eval_then:
       %then = call %object* @first(%object* %branches)
       %thenRes = call %object* @eval(%object* %then)
       ret %object* %thenRes

eval_else:
       %else = call %object* @rest(%object* %branches)
       %elseRes = call %object* @eval(%object* %else)
       ret %object* null
}

define %object* @evalList(%object* %forms) {
       %head = call %object* @first(%object* %forms)
       %tail = call %object* @rest(%object* %forms)

       %match_if = getelementptr [3 x i8]* @.form_if, i32 0, i32 0
       %is_if = call i1 @tokenMatches(%object* %head, i8* %match_if)

       br i1 %is_if, label %eval_if, label %done

eval_if:
       %if_res = call %object* @evalIf(%object* %tail)
       ret %object* %if_res

done:
       ret %object* null
}

define %object* @eval(%object* %obj) {
       %is_nil = icmp eq %object* %obj, null
       br i1 %is_nil, label %eval_nil, label %decode_obj

eval_nil:
       ret %object* null

decode_obj:
       %tagPtr = getelementptr %object* %obj, i32 0, i32 0
       %tag = load i32* %tagPtr

       %valPtr = getelementptr %object* %obj, i32 0, i32 1
       %val = load i8** %valPtr

       switch i32 %tag, label %finalize [ i32 0, label %eval_list
                                          i32 1, label %eval_token ]

eval_list:
       %listRes = call %object* @evalList(%object* %obj)
       ret %object* %listRes

eval_token:
       ret %object* %obj

finalize:
       ret %object* null
}
