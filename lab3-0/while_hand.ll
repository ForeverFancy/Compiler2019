; ModuleID = 'while.c'
source_filename = "while.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @main() {
entry:
    %a = alloca i32, align 4
    %i = alloca i32, align 4      ; 定义 a, i

    store i32 10, i32* %a, align 4
    store i32 0, i32* %i, align 4   ; 赋初值

    %0 = load i32, i32* %i, align 4

    %cmp = icmp slt i32 %0, 10     ; i<10 ?
    br i1 %cmp, label %loop, label %return
    
loop:
    %1 = load i32, i32* %i, align 4
    %2 = load i32, i32* %a, align 4
    %inc = add i32 %1, 1                
    store i32 %inc, i32* %i, align 4    ;i = i + 1
    %add = add i32 %inc, %2             
    store i32 %add, i32* %a, align 4    ; a = a + i

    %3 = icmp slt i32 %inc, 10          ; i<10?
    br i1 %3, label %loop, label %return

return:
    %retval = load i32, i32* %a, align 4;return a
    ret i32 %retval
}