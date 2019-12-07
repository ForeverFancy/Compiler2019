# lab3-1实验报告

虞佳焕（队长）：PB17121687

张博文：PB17000215

彭定澜：PB17111607

## 实验要求

根据语法分析生成的语法树并结合 cminus 的语义，生成 llvm 中间代码。

## 实验难点

- 使用全局变量保存和传递信息；
- 普通数组和作为函数参数的数组的不同访问模式；
- if-else 语句及 well-formed basic block 设计。

## 实验设计

### 全局变量的设计

- `currentExpression` 和 `currentPointer` 均为函数对象，仅当需要时才进行求值；
  - `currentExpression` 是指向存储当前所计算的表达式值的指针，用来在后面的语句中使用前面表达式的值；
  - 在产生式 $`\text{expression} \rightarrow \text{var}\ \textbf{=}\ \text{expression}`$ 中需要使用$`\text{var}`$的地址，此时在 `currentPointer` 中存储所需的地址；

- `currentFunction`
  
  用来存储当前所在的函数信息，用于 `BasicBlock` 的创建；

- `currentParameter`
  
  当创建函数时，`llvm::Function` 对象在访问 `syntax_fun_declaration` 时创建，这时也可以得到形参的值，但给形参分配内存空间却在访问 `syntax_param` 中实现。因此需要通过一个全局变量使得访问 `syntax_param` 时可以得到形参的值，从而创建 `store` 指令；

- `currentValue`
  
  在声明数组 `type_specifier id[num]` 时, 创建数组需要得到 `num` 的值，但访问 `syntax_num` 之后程序在访问 `syntax_var_declaration` 时并不能直接得到这个值，因此需要通过一个全局变量传递；

- `isFunctionTopCompoundStatement`
  
  C- 中 `compound-stmt` 会产生一个新的作用域。如果这个 `compound-stmt` 是作为函数体的话，形参也应该加入此作用域。由此产生了何时调用 `scpoe.enter()` 的问题。
  
  为此设此一个判断 `coumpound-stmt` 是否是函数体的 `bool` 全局量：当此值为 `true` 时，在 `syntax_fun_declaration` 的访问中完成 scpoe 的管理，在 `syntax_compound_stmt` 中无需再使用 `scpoe.enter()`; 否则则在 `syntax_compound_stmt` 中使用 `scpoe.enter()` 和 `scope.exit()`.

### if-else 及 well-formed basic block 设计

- 如果当前函数的最后一条指令是终结指令，则不会生成跳转 bb_end 指令；
- 生成 bb_end 之后，为了防止之后没有指令出现（比如：if-else 均带有 return 语句），在 fun-declaration 函数最后多生成一条与函数类型相符的 return 语句，保证正确性；
- well-formed basic block 要求每个 basic block 的最后一条语句均为终结指令，经过仔细设计及验证，我们生成的代码符合这一规范。

### 数组访问模式的设计

C- 中共有 4 种使用数组的方式：

1. 通过 `arr[exp]` 的方式使用全局和局部数组；
2. 通过 `arr[exp]` 的方式使用作为函数形参的数组；
3. 全局或者局部数组的数组名作为函数实参，如 `call(arr)`；
4. 函数形参的数组作为函数实参；

参考 clang 生成的 IR 之后，我们总结出：

1. 访问全局和局部数组都是通过一个 `[n x i32]*` 的指针实现的，如

    ```llvm
    %value_ptr = getelementptr [n x i32], [n x i32]* %arr_ptr, i32 0, i32 %index
    ; %value_ptr 即是指向 arr[index] 的 i32* 指针
    ; 再通过 value_ptr 即可进行 load/store 操作
    ```

2. 形参数组在参数列表中的类型为 `i32*`, 因此在创建对应的局部存储后，得到一个 `i32**`, 通过 `load` 后解指针再计算偏移量的模式进行访问，如

    ```llvm
    %base_ptr = load i32*, i32** %param_arr_ptr
    ; 得到 base_ptr 是指向数组起始的 i32*
    %value_ptr = getelementptr i32, i32* %base_ptr, i32 %index
    ; 再通过 value_ptr 即可进行 load/store 操作
    ```

3. 全局和局部数组作为函数实参，则需要把 `[n x i32]*` 转化成 `i32*` 类型，clang 的做法如下：

    ```llvm
    ; base_ptr 即是指向数组基地址的 i32*
    %base_ptr = getelementptr [n x i32], [n x i32]* %arr_ptr, i32 0, i32 0
    ; 本质上是计算 arr[0] 的指针
    ```

4. 形参数组作为函数调用的实参，通过 `load` 操作把 `i32**` 转化成 `i32*`.

通过总结以上数组访问模式后，我们实现了 `syntax_var` 和中涉及数组的部分。

## 实验总结

- 进一步熟悉掌握了从语法树到中间代码的转换过程；
- 加深了对中间代码生成的理解；
- 增强了团队合作能力。

## 实验反馈

本次实验的目录结构清晰，文档简洁且覆盖重点难点，要求明确，给助教点赞。
