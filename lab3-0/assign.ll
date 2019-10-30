; ModuleID = 'assign.c'
source_filename = "assign.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @main() {
    %a = alloca i32, align 4        ; 在栈上给 a 分配内存
    store i32 1, i32* %a, align 4   ; 在 a 的地址里写入 1
    %retval = load i32, i32* %a, align 4 ; 从 a 的地址里读出返回值
    ret i32 %retval                 ; 返回
}