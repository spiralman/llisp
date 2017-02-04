@.form_if = private unnamed_addr constant [ 3 x i8 ] c"if\00"

%object = type opaque

declare %object* @first(%object*)
declare %object* @rest(%object*)

declare i1 @isNil(%object*)

declare i32 @tag(%object*)
declare i8* @unbox(%object*)

define i1 @tokenMatches(%object* %token, i8* %match) {
       %str = call i8* @unbox(%object* %token)

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
       br i1 %is_nil, label %check_else, label %compare_val

compare_val:
       %is_valNil = call i1 @isNil(%object* %condRes)
       br i1 %is_valNil, label %check_else, label %eval_then

eval_then:
       %then = call %object* @first(%object* %branches)
       %thenRes = call %object* @eval(%object* %then)
       ret %object* %thenRes

check_else:
       %elseList = call %object* @rest(%object* %branches)

       %elseNil = call i1 @isNil(%object* %elseList)
       br i1 %elseNil, label %no_else, label %eval_else

no_else:
      ret %object* %elseList

eval_else:
       %else = call %object* @first(%object* %elseList)
       %elseRes = call %object* @eval(%object* %else)
       ret %object* %elseRes
}

define %object* @evalList(%object* %forms) {
       %is_nil = call i1 @isNil(%object* %forms)
       br i1 %is_nil, label %done, label %eval_forms

eval_forms:
       %head = call %object* @first(%object* %forms)
       %tail = call %object* @rest(%object* %forms)

       %match_if = getelementptr [3 x i8]* @.form_if, i32 0, i32 0
       %is_if = call i1 @tokenMatches(%object* %head, i8* %match_if)

       br i1 %is_if, label %eval_if, label %done

eval_if:
       %if_res = call %object* @evalIf(%object* %tail)
       ret %object* %if_res

done:
       ret %object* %forms
}

define %object* @eval(%object* %obj) {
       %tag = call i32 @tag(%object* %obj)

       %val = call i8* @unbox(%object* %obj)

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
