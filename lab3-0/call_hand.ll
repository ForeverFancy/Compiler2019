; ModuleID = 'call.c'
source_filename = "call.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @callee(i32 %a) {    ; 声明 callee 函数.
    %mul = mul i32 2, %a
    ret i32 %mul                ; 返回 2 * a.
}

define i32 @main() {
    %retval = call i32 @callee(i32 10)  ; 调用函数.
    ret i32 %retval                     ; 返回.
}