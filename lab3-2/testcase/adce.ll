; ADCE 除了 DCE 中的基本优化，还加了对控制流程的优化
; 即如果一个有条件跳转，跳转到无论它的哪个后继，都不会对结果造成影响
; 那么这个跳转指令就可以改成无条件跳转
; ADCE 的具体实现中，会把它改为跳转到 “离返回点最近的” Basic Block

; 这个函数不会被优化
define i32 @test_adce_origin(i32 %a){
  %result.ptr = alloca i32
  %cmp = icmp slt i32 %a, 0  ; if a<0
  br i1 %cmp, label %if_true, label %if_false  ; 因为走不同的分支会对最后的 return 值造成影响，因此 ADCE 不会把这句改成 无条件跳转
if_true:
  store i32 -1, i32* %result.ptr
  br label %return
if_false:
  store i32 1, i32* %result.ptr
  br label %return
return:
  %result = load i32, i32* %result.ptr
  ret i32 %result
}

; 这个函数会被优化
define i32 @test_adce(i32 %a){
  %result.ptr = alloca i32
  %cmp = icmp slt i32 %a, 0  ; if a<0
  br i1 %cmp, label %if_true, label %if_false  ; 此时无论走哪个分支对结果都无影响，ADCE 会把这句改为无条件跳转
if_true:
  ; store i32 -1, i32* %result.ptr     ; 删除两个分支中对 result 的修改
  br label %return
if_false:
  ; store i32 1, i32* %result.ptr
  br label %return
return:
  %result = load i32, i32* %result.ptr
  ret i32 %result
}