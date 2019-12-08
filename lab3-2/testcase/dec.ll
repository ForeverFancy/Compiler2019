define i32 @some_func(){
  ret i32 1
}

; DCE 执行基本的死代码删除：
; LLVM IR 是 SSA 的，
; 因此 IR 中一个量有且只有一次赋值 (量被定义时即完成赋值)，
; 因此 IR 中一个量如果未被使用，即代表是死代码，
; DCE 即执行对这些死代码的删除，
; 以上准则有一个例外
; 如果初始化一个量的指令有潜在的额外作用
; 则此赋值不能被删除
define i32 @test_dce(){
  %used_alloca.ptr = alloca i32
  %unused_alloca.ptr = alloca i32               ; DCE 中会被删除
  %unused_tmp = load i32, i32* %used_alloca.ptr ; DCE 中会被删除
  %tmp_wont_delete = call i32 @some_func()     ; 调用函数可能会造成额外作用，因此这句不能能删除
  store i32 0, i32* %used_alloca.ptr
  %ret_val = load i32, i32* %used_alloca.ptr
  ret i32 %ret_val
}

