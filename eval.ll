@.form_if = private unnamed_addr constant [ 3 x i8 ] c"if\00"
@.form_define = private unnamed_addr constant [ 7 x i8 ] c"define\00"
@.form_lambda = private unnamed_addr constant [ 7 x i8 ] c"lambda\00"

@.sym_false = private unnamed_addr constant [ 6 x i8 ] c"false\00"
@.sym_nil = private unnamed_addr constant [ 4 x i8 ] c"nil\00"
@.sym_true = private unnamed_addr constant [ 5 x i8 ] c"true\00"

@root_env = linkonce global %object* zeroinitializer
@val_nil = linkonce global %object* zeroinitializer

%object = type opaque

declare %object* @first(%object*)
declare %object* @rest(%object*)
declare %object* @cons(%object*, %object*)

declare i1 @isNil(%object*)

declare i1 @tokenMatches(%object*, i8*)
declare i1 @tokenEq(%object*, %object*)
declare %object* @newConstToken(i8*)

declare i32 @tag(%object*)
declare i8* @unbox(%object*)

declare i32 @putchar(i32) nounwind
declare void @print(%object*)

define %object* @lookupSymbol(%object* %symbol, %object* %env) {
       %is_end = call i1 @isNil(%object* %env)
       br i1 %is_end, label %ret_nil, label %check_head

ret_nil:
       ret %object* %env

check_head:
       %head = call %object* @first(%object* %env)
       %headSymbol = call %object* @first(%object* %head)
       %matches = call i1 @tokenEq(%object* %symbol, %object* %headSymbol)
       br i1 %matches, label %ret_match, label %continue

ret_match:
       %headTail = call %object* @rest(%object* %head)
       %headVal = call %object* @first(%object* %headTail)
       ret %object* %headVal

continue:
       %tail = call %object* @rest(%object* %env)
       %tailLookup = call %object* @lookupSymbol(%object* %symbol, %object* %tail)
       ret %object* %tailLookup
}

define %object* @evalIf(%object* %forms, %object** %env) {
       %cond = call %object* @first(%object* %forms)
       %branches = call %object* @rest(%object* %forms)

       %condRes = call %object* @evalEnv(%object* %cond, %object** %env)

       %is_nil = icmp eq %object* %condRes, null
       br i1 %is_nil, label %check_else, label %compare_val

compare_val:
       %is_valNil = call i1 @isNil(%object* %condRes)
       br i1 %is_valNil, label %check_else, label %eval_then

eval_then:
       %then = call %object* @first(%object* %branches)
       %thenRes = call %object* @evalEnv(%object* %then, %object** %env)
       ret %object* %thenRes

check_else:
       %elseList = call %object* @rest(%object* %branches)

       %elseNil = call i1 @isNil(%object* %elseList)
       br i1 %elseNil, label %no_else, label %eval_else

no_else:
      ret %object* %elseList

eval_else:
       %else = call %object* @first(%object* %elseList)
       %elseRes = call %object* @evalEnv(%object* %else, %object** %env)
       ret %object* %elseRes
}

define %object* @evalDefine(%object* %forms, %object** %env) {
       %nil = load %object** @val_nil
       %token = call %object* @first(%object* %forms)

       %expList = call %object* @rest(%object* %forms)
       %exp = call %object* @first(%object* %expList)
       %expRes = call %object* @evalEnv(%object* %exp, %object** %env)

       %expVal = call %object* @cons(%object* %expRes, %object* %nil)
       %expEntry = call %object* @cons(%object* %token, %object* %expVal)

       %oldEnv = load %object** %env
       %newEnv = call %object* @cons(%object* %expEntry, %object* %oldEnv)
       store %object* %newEnv, %object** %env

       ret %object* %nil
}

define %object* @evalLambda(%object* %forms, %object** %env) {
       ret %object* %forms
}

define %object* @evalBody(%object* %body, %object** %env) {
       %nextForm = call %object* @first(%object* %body)
       %nextRes = call %object* @evalEnv(%object* %nextForm, %object** %env)

       ret %object* %nextRes
}

define %object* @evalCall(%object* %funSym, %object* %forms, %object** %env) {
       %curEnvPtr = getelementptr %object** %env, i32 0
       %curEnv = load %object** %curEnvPtr
       %funDef = call %object* @lookupSymbol(%object* %funSym, %object* %curEnv)

       %no_fun = call i1 @isNil(%object* %funDef)
       br i1 %no_fun, label %ret_nil, label %eval_fun

ret_nil:
       ret %object* %funDef

eval_fun:
       %argList = call %object* @first(%object* %funDef)
       %body = call %object* @rest(%object* %funDef)

       %bodyRes = call %object* @evalBody(%object* %body, %object** %env)
       ret %object* %bodyRes
}

define %object* @evalList(%object* %forms, %object** %env) {
       %is_nil = call i1 @isNil(%object* %forms)
       br i1 %is_nil, label %ret_nil, label %eval_forms

ret_nil:
       ret %object* %forms

eval_forms:
       %head = call %object* @first(%object* %forms)
       %tail = call %object* @rest(%object* %forms)

       %match_if = getelementptr [3 x i8]* @.form_if, i32 0, i32 0
       %is_if = call i1 @tokenMatches(%object* %head, i8* %match_if)

       br i1 %is_if, label %eval_if, label %check_define

eval_if:
       %if_res = call %object* @evalIf(%object* %tail, %object** %env)
       ret %object* %if_res

check_define:
       %match_define = getelementptr [7 x i8]* @.form_define, i32 0, i32 0
       %is_define = call i1 @tokenMatches(%object* %head, i8* %match_define)

       br i1 %is_define, label %eval_define, label %check_lambda

eval_define:
       %define_res = call %object* @evalDefine(%object* %tail, %object** %env)
       ret %object* %define_res

check_lambda:
       %match_lambda = getelementptr [7 x i8]* @.form_lambda, i32 0, i32 0
       %is_lambda = call i1 @tokenMatches(%object* %head, i8* %match_lambda)

       br i1 %is_lambda, label %eval_lambda, label %eval_call

eval_lambda:
       %lambda_res = call %object* @evalLambda(%object* %tail, %object** %env)
       ret %object* %lambda_res

eval_call:
       %call_res = call %object* @evalCall(%object* %head, %object* %tail, %object** %env)
       ret %object* %call_res
}

define %object* @evalEnv(%object* %obj, %object** %env) {
       %is_nil = call i1 @isNil(%object* %obj)
       br i1 %is_nil, label %ret_nil, label %eval_obj

ret_nil:
       ret %object* %obj

eval_obj:
       %tag = call i32 @tag(%object* %obj)

       %val = call i8* @unbox(%object* %obj)

       switch i32 %tag, label %finalize [ i32 0, label %eval_list
                                          i32 1, label %eval_token ]

eval_list:
       %listRes = call %object* @evalList(%object* %obj, %object** %env)
       ret %object* %listRes

eval_token:
       %curEnvPtr = getelementptr %object** %env, i32 0
       %curEnv = load %object** %curEnvPtr
       %symbolVal = call %object* @lookupSymbol(%object* %obj, %object* %curEnv)

       ret %object* %symbolVal

finalize:
       ret %object* null
}

define %object* @eval(%object* %obj) {
       %root_env = getelementptr %object** @root_env, i32 0

       %res = call %object* @evalEnv(%object* %obj, %object** %root_env)
       ret %object* %res
}

define void @init_eval() {
       %baseEnv = call %object* @cons(%object* null, %object* null)
       %nil = call %object* @cons(%object* null, %object* null)
       store %object* %nil, %object** @val_nil

       %falseStr = getelementptr [6 x i8]* @.sym_false, i32 0, i32 0
       %falseToken = call %object* @newConstToken(i8* %falseStr)
       %falseVal = call %object* @cons(%object* %nil, %object* %nil)
       %falseEntry = call %object* @cons(%object* %falseToken, %object* %falseVal)
       %falseEnv = call %object* @cons(%object* %falseEntry, %object* %baseEnv)

       %nilStr = getelementptr [4 x i8]* @.sym_nil, i32 0, i32 0
       %nilToken = call %object* @newConstToken(i8* %nilStr)
       %nilVal = call %object* @cons(%object* %nilToken, %object* %nil)
       %nilEntry = call %object* @cons(%object* %nil, %object* %nilVal)
       %nilEnv = call %object* @cons(%object* %nilEntry, %object* %falseEnv)

       %trueStr = getelementptr [5 x i8]* @.sym_true, i32 0, i32 0
       %trueToken = call %object* @newConstToken(i8* %trueStr)
       %trueVal = call %object* @cons(%object* %trueToken, %object* %nil)
       %trueEntry = call %object* @cons(%object* %trueToken, %object* %trueVal)
       %trueEnv = call %object* @cons(%object* %trueEntry, %object* %nilEnv)

       %rootPtr = getelementptr %object** @root_env, i32 0
       store %object* %trueEnv, %object** %rootPtr

       ret void
}
