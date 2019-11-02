; ModuleID = 'call.c'
source_filename = "call.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @callee(i32 %a) {
    %mul = mul i32 2, %a
    ret i32 %mul
}

define i32 @main() {
    %retval = call i32 @callee(i32 10)
    ret i32 %retval
}