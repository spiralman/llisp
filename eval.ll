@.form_if = private unnamed_addr constant [ 3 x i8 ] c"if\00"
@.form_define = private unnamed_addr constant [ 7 x i8 ] c"define\00"
@.form_lambda = private unnamed_addr constant [ 7 x i8 ] c"lambda\00"
@.form_quote = private unnamed_addr constant [ 6 x i8 ] c"quote\00"

@.sym_false = private unnamed_addr constant [ 6 x i8 ] c"false\00"
@.sym_nil = private unnamed_addr constant [ 4 x i8 ] c"nil\00"
@.sym_true = private unnamed_addr constant [ 5 x i8 ] c"true\00"
@.sym_cons = private unnamed_addr constant [ 5 x i8 ] c"cons\00"
@.sym_first = private unnamed_addr constant [ 6 x i8 ] c"first\00"
@.sym_rest = private unnamed_addr constant [ 5 x i8 ] c"rest\00"
@.sym_print = private unnamed_addr constant [ 6 x i8 ] c"print\00"

@root_env = linkonce global %object* zeroinitializer
@val_nil = linkonce global %object* zeroinitializer

%object = type opaque

%nativeFn = type %object* (%object*)

declare %object* @first(%object*)
declare %object* @rest(%object*)
declare %object* @cons(%object*, %object*)

declare i1 @isNil(%object*)

declare i1 @tokenMatches(%object*, i8*)
declare i1 @tokenEq(%object*, %object*)
declare %object* @newConstToken(i8*)

declare %object* @newObject(i32, i8*)
declare i32 @tag(%object*)
declare i8* @unbox(%object*)

declare i32 @putchar(i32)
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

define %object* @resolveSymbol(%object* %symbol, %object* %env) {
       %is_rootEnv = call i1 @isNil(%object* %env)
       br i1 %is_rootEnv, label %search_global, label %search_inner

search_inner:
       %innerEnv = call %object* @first(%object* %env)
       %innerVal = call %object* @lookupSymbol(%object* %symbol, %object* %innerEnv)

       %is_notInInner = call i1 @isNil(%object* %innerVal)
       br i1 %is_notInInner, label %check_outer, label %ret_inner

ret_inner:
       ret %object* %innerVal

check_outer:
       %outerEnv = call %object* @rest(%object* %env)
       %is_outermost = call i1 @isNil(%object* %outerEnv)
       br i1 %is_outermost, label %search_global, label %search_outer

search_global:
       %globalEnvWrapper = load %object*, %object** @root_env
       %globalEnv = call %object* @first(%object* %globalEnvWrapper)
       %globalRes = call %object* @lookupSymbol(%object* %symbol, %object* %globalEnv)

       ret %object* %globalRes

search_outer:
       %outerRes = call %object* @resolveSymbol(%object* %symbol, %object* %outerEnv)

       ret %object* %outerRes
}

define %object* @evalIf(%object* %forms, %object* %env) {
       %cond = call %object* @first(%object* %forms)
       %branches = call %object* @rest(%object* %forms)

       %condRes = call %object* @evalEnv(%object* %cond, %object* %env)

       %is_nil = icmp eq %object* %condRes, null
       br i1 %is_nil, label %check_else, label %compare_val

compare_val:
       %is_valNil = call i1 @isNil(%object* %condRes)
       br i1 %is_valNil, label %check_else, label %eval_then

eval_then:
       %then = call %object* @first(%object* %branches)
       %thenRes = call %object* @evalEnv(%object* %then, %object* %env)
       ret %object* %thenRes

check_else:
       %elseList = call %object* @rest(%object* %branches)

       %elseNil = call i1 @isNil(%object* %elseList)
       br i1 %elseNil, label %no_else, label %eval_else

no_else:
      ret %object* %elseList

eval_else:
       %else = call %object* @first(%object* %elseList)
       %elseRes = call %object* @evalEnv(%object* %else, %object* %env)
       ret %object* %elseRes
}

define %object* @evalDefine(%object* %forms, %object* %env) {
       %nil = load %object*, %object** @val_nil
       %token = call %object* @first(%object* %forms)

       %expList = call %object* @rest(%object* %forms)
       %exp = call %object* @first(%object* %expList)
       %expRes = call %object* @evalEnv(%object* %exp, %object* %env)

       %oldEnvWrapper = load %object*, %object** @root_env
       %oldEnvOuter = call %object* @rest(%object* %oldEnvWrapper)
       %oldEnv = call %object* @first(%object* %oldEnvWrapper)

       %newEnv = call %object* @consEnv(%object* %token, %object* %expRes, %object* %oldEnv)

       %newEnvWrapper = call %object* @cons(%object* %newEnv, %object* %oldEnvOuter)

       store %object* %newEnvWrapper, %object** @root_env

       ret %object* %nil
}

define %object* @evalLambda(%object* %forms, %object* %env) {
       %fun = call %object* @cons(%object* %env, %object* %forms)
       ret %object* %fun
}

define %object* @evalQuote(%object* %forms, %object* %env) {
       %quoted = call %object* @first(%object* %forms)
       ret %object* %quoted
}

define %object* @evalBody(%object* %body, %object* %env) {
       %nextForm = call %object* @first(%object* %body)
       %nextRes = call %object* @evalEnv(%object* %nextForm, %object* %env)

       ret %object* %nextRes
}

define %object* @evalParams(%object* %params, %object* %env) {
       %is_end = call i1 @isNil(%object* %params)
       br i1 %is_end, label %ret_end, label %eval_params

ret_end:
       ret %object* %params

eval_params:
       %nextParam = call %object* @first(%object* %params)
       %paramVal = call %object* @evalEnv(%object* %nextParam, %object* %env)

       %restParams = call %object* @rest(%object* %params)
       %restVals = call %object* @evalParams(%object* %restParams, %object* %env)

       %nextVals = call %object* @cons(%object* %paramVal, %object* %restVals)
       ret %object* %nextVals
}

define %object* @bindParams(%object* %argList, %object* %params, %object* %curEnv, %object* %env) {
       %nil = load %object*, %object** @val_nil

       %is_end = call i1 @isNil(%object* %argList)
       br i1 %is_end, label %ret_end, label %bind_params

ret_end:
       ret %object* %curEnv

bind_params:
       %nextArg = call %object* @first(%object* %argList)
       %nextParam = call %object* @first(%object* %params)
       %paramVal = call %object* @evalEnv(%object* %nextParam, %object* %env)
       %paramEntry = call %object* @cons(%object* %paramVal, %object* %nil)
       %binding = call %object* @cons(%object* %nextArg, %object* %paramEntry)

       %newEnv = call %object* @cons(%object* %binding, %object* %curEnv)

       %restArgs = call %object* @rest(%object* %argList)
       %restParams = call %object* @rest(%object* %params)

       %nextEnv = call %object* @bindParams(%object* %restArgs, %object* %restParams, %object* %newEnv, %object* %env)
       ret %object* %nextEnv
}

define %object* @evalCall(%object* %funSym, %object* %params, %object* %env) {
       %nil = load %object*, %object** @val_nil

       %funDef = call %object* @evalEnv(%object* %funSym, %object* %env)

       %no_fun = call i1 @isNil(%object* %funDef)
       br i1 %no_fun, label %ret_nil, label %eval_fun

ret_nil:
       ret %object* %funDef

eval_fun:
       %fnTag = call i32 @tag(%object* %funDef)
       %is_native = icmp eq i32 3, %fnTag
       br i1 %is_native, label %eval_native, label %eval_lisp

eval_native:
       %fnPtr = call i8* @unbox(%object* %funDef)
       %nativeFn = bitcast i8* %fnPtr to %nativeFn*

       %evaledParams = call %object* @evalParams(%object* %params, %object* %env)
       %nativeRes = call %object* %nativeFn(%object* %evaledParams)

       ret %object* %nativeRes

eval_lisp:
       %defEnv = call %object* @first(%object* %funDef)
       %funForms = call %object* @rest(%object* %funDef)
       %argList = call %object* @first(%object* %funForms)
       %funEnv = call %object* @bindParams(%object* %argList, %object* %params, %object* %nil, %object* %env)

       %fullEnv = call %object* @cons(%object* %funEnv, %object* %defEnv)

       %body = call %object* @rest(%object* %funForms)

       %bodyRes = call %object* @evalBody(%object* %body, %object* %fullEnv)
       ret %object* %bodyRes
}

define %object* @evalList(%object* %forms, %object* %env) {
       %is_nil = call i1 @isNil(%object* %forms)
       br i1 %is_nil, label %ret_nil, label %eval_forms

ret_nil:
       ret %object* %forms

eval_forms:
       %head = call %object* @first(%object* %forms)
       %tail = call %object* @rest(%object* %forms)

       %match_if = getelementptr [3 x i8], [3 x i8]* @.form_if, i32 0, i32 0
       %is_if = call i1 @tokenMatches(%object* %head, i8* %match_if)

       br i1 %is_if, label %eval_if, label %check_define

eval_if:
       %if_res = call %object* @evalIf(%object* %tail, %object* %env)
       ret %object* %if_res

check_define:
       %match_define = getelementptr [7 x i8], [7 x i8]* @.form_define, i32 0, i32 0
       %is_define = call i1 @tokenMatches(%object* %head, i8* %match_define)

       br i1 %is_define, label %eval_define, label %check_lambda

eval_define:
       %define_res = call %object* @evalDefine(%object* %tail, %object* %env)
       ret %object* %define_res

check_lambda:
       %match_lambda = getelementptr [7 x i8], [7 x i8]* @.form_lambda, i32 0, i32 0
       %is_lambda = call i1 @tokenMatches(%object* %head, i8* %match_lambda)

       br i1 %is_lambda, label %eval_lambda, label %check_quote

eval_lambda:
       %lambda_res = call %object* @evalLambda(%object* %tail, %object* %env)
       ret %object* %lambda_res

check_quote:
       %match_quote = getelementptr [6 x i8], [6 x i8]* @.form_quote, i32 0, i32 0
       %is_quote = call i1 @tokenMatches(%object* %head, i8* %match_quote)

       br i1 %is_quote, label %eval_quote, label %eval_call

eval_quote:
       %quote_res = call %object* @evalQuote(%object* %tail, %object* %env)
       ret %object* %quote_res

eval_call:
       %call_res = call %object* @evalCall(%object* %head, %object* %tail, %object* %env)
       ret %object* %call_res
}

define %object* @evalEnv(%object* %obj, %object* %env) {
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
       %listRes = call %object* @evalList(%object* %obj, %object* %env)
       ret %object* %listRes

eval_token:
       %symbolVal = call %object* @resolveSymbol(%object* %obj, %object* %env)

       ret %object* %symbolVal

finalize:
       ret %object* null
}

define %object* @eval(%object* %obj) {
       %nil = load %object*, %object** @val_nil

       %res = call %object* @evalEnv(%object* %obj, %object* %nil)
       ret %object* %res
}

define %object* @consEnv(%object* %token, %object* %val, %object* %oldEnv) {
       %nil = load %object*, %object** @val_nil

       %valList = call %object* @cons(%object* %val, %object* %nil)
       %expEntry = call %object* @cons(%object* %token, %object* %valList)
       %newEnv = call %object* @cons(%object* %expEntry, %object* %oldEnv)

       ret %object* %newEnv
}

define %object* @updateEnv(i8* %sym, %object* %val, %object* %oldEnv) {
       %symToken = call %object* @newConstToken(i8* %sym)

       %newEnv = call %object* @consEnv(%object* %symToken, %object* %val, %object* %oldEnv)

       ret %object* %newEnv
}

define %object* @updateEnvBuiltin(i8* %sym, %nativeFn* %fn, %object* %oldEnv) {
       %fnPtr = bitcast %nativeFn* %fn to i8*
       %wrappedFn = call %object* @newObject(i32 3, i8* %fnPtr)

       %newEnv = call %object* @updateEnv(i8* %sym, %object* %wrappedFn, %object* %oldEnv)
       ret %object* %newEnv
}

define %object* @wrapCons(%object* %args) {
       %arg1 = call %object* @first(%object* %args)
       %tail = call %object* @rest(%object* %args)
       %arg2 = call %object* @first(%object* %tail)

       %res = call %object* @cons(%object* %arg1, %object* %arg2)
       ret %object* %res
}

define %object* @wrapFirst(%object* %args) {
       %arg = call %object* @first(%object* %args)

       %res = call %object* @first(%object* %arg)
       ret %object* %res
}

define %object* @wrapRest(%object* %args) {
       %arg = call %object* @first(%object* %args)

       %res = call %object* @rest(%object* %arg)
       ret %object* %res
}

define %object* @wrapPrint(%object* %args) {
       %arg = call %object* @first(%object* %args)

       call void @print(%object* %arg)
       call i32 @putchar(i32 10)

       %nil = load %object*, %object** @val_nil
       ret %object* %nil
}

define void @init_eval() {
       %nil = call %object* @cons(%object* null, %object* null)
       store %object* %nil, %object** @val_nil

       %falseStr = getelementptr [6 x i8], [6 x i8]* @.sym_false, i32 0, i32 0
       %falseEnv = call %object* @updateEnv(i8* %falseStr, %object* %nil, %object* %nil)

       %nilStr = getelementptr [4 x i8], [4 x i8]* @.sym_nil, i32 0, i32 0
       %nilEnv = call %object* @updateEnv(i8* %nilStr, %object* %nil, %object* %falseEnv)

       %trueStr = getelementptr [5 x i8], [5 x i8]* @.sym_true, i32 0, i32 0
       %trueToken = call %object* @newConstToken(i8* %trueStr)
       %trueEnv = call %object* @updateEnv(i8* %trueStr, %object* %trueToken, %object* %nilEnv)

       %consStr = getelementptr [5 x i8], [5 x i8]* @.sym_cons, i32 0, i32 0
       %consEnv = call %object* @updateEnvBuiltin(i8* %consStr, %nativeFn* @wrapCons, %object* %trueEnv)

       %firstStr = getelementptr [6 x i8], [6 x i8]* @.sym_first, i32 0, i32 0
       %firstEnv = call %object* @updateEnvBuiltin(i8* %firstStr, %nativeFn* @wrapFirst, %object* %consEnv)

       %restStr = getelementptr [5 x i8], [5 x i8]* @.sym_rest, i32 0, i32 0
       %restEnv = call %object* @updateEnvBuiltin(i8* %restStr, %nativeFn* @wrapRest, %object* %firstEnv)

       %printStr = getelementptr [6 x i8], [6 x i8]* @.sym_print, i32 0, i32 0
       %printEnv = call %object* @updateEnvBuiltin(i8* %printStr, %nativeFn* @wrapPrint, %object* %restEnv)

       %wrappedEnv = call %object* @cons(%object* %printEnv, %object* %nil)

       %rootPtr = getelementptr %object*, %object** @root_env, i32 0
       store %object* %wrappedEnv, %object** %rootPtr

       ret void
}
