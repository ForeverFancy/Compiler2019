; ModuleID = 'if.c'
source_filename = "if.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @main() {
entry:
    %cmp = icmp sgt i32 2, 1           ; 比较 2 是否大于 1，结果赋给 %cmp
    br i1 %cmp, label %if.then, label %if.end  ; 分支指令，如果 %cmp 为真，则跳转 %if.then 否则 %if.end

if.then:
    ret i32 1               ;返回
if.end:
    ret i32 0               ;返回

}