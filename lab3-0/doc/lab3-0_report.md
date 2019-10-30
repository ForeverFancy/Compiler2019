## lab3-0实验报告

张博文

PB17000215

### 实验要求

- 手动编译 llvm；
- 熟悉 llvm IR 的结构及基本指令，并手写 4 个文件的中间表示代码；
- 熟悉使用 C++ 生成中间代码的基本过程，构建 4 个 Cpp 文件来将源程序翻译为中间代码。

### 实验结果

描述你的代码片段和每一个BasicBlock的对应关系

assign_generator.cpp

```cpp
    auto bb = BasicBlock::Create(context, "entry", mainFun);
    // Begin: BasicBlock entry.
    builder.SetInsertPoint(bb);

    auto a = builder.CreateAlloca(TYPE32);
    a->setAlignment(4);                 //Allocate a.
    builder.CreateStore(CONST(1), a)->setAlignment(4);                  // Store the value to a.

    auto retval = builder.CreateLoad(a);
    retval->setAlignment(4);            // Load the value to retval.

    builder.CreateRet(retval);          // Return.
    // End: BasicBlock entry.
```
代码中只有 `entry` 一个 `BasicBlock`。

if_generator.cpp:

```cpp
    auto bb = BasicBlock::Create(context, "entry", mainFun);
    // Begin: BasicBlock entry.
    builder.SetInsertPoint(bb);

    auto truebb = BasicBlock::Create(context, "truebb", mainFun);
    auto falsebb = BasicBlock::Create(context, "falsebb", mainFun);

    auto icmp = builder.CreateICmpSGT(CONST(2), CONST(1));              // ? 2>1.

    auto br = builder.CreateCondBr(icmp, truebb, falsebb);              // Create conditional branch.
    // End: BasicBlock entry.

    // Begin: BasicBlock truebb.
    builder.SetInsertPoint(truebb);
    builder.CreateRet(CONST(1));    // Return 1 in true branch.
    // End: BasicBlock truebb.

    // Begin: BasicBlock falsebb.
    builder.SetInsertPoint(falsebb);
    builder.CreateRet(CONST(0));    // Return 0 in false branch.
    // End: BasicBlock falsebb.
```
代码中共有 3 个 `BasicBlock`，分别是 `entry, truebb, falsebb`，对应关系在注释中给出。

call_generator.cpp:

```cpp
    std::vector<Type *> Ints(1, TYPE32);    // Declare type of function args.
    auto calleeFunction = Function::Create(FunctionType::get(TYPE32, Ints, false),
                                    GlobalValue::LinkageTypes::ExternalLinkage,
                                    "callee", module);

    auto entry = BasicBlock::Create(context, "entry",calleeFunction);
    // Begin: BasicBlock entry in calleeFunction.
    builder.SetInsertPoint(entry);

    // Get args.
    std::vector<Value *> args;
    for (auto arg = calleeFunction->arg_begin(); arg != calleeFunction->arg_end(); arg++)
    {
        args.push_back(arg);
    }

    auto mul = builder.CreateMul(CONST(2), args[0]);
    builder.CreateRet(mul);         // End of calleeFunction.
    // End: BasicBlock entry in calleeFunction.

    auto mainFun = Function::Create(FunctionType::get(TYPE32, false), GlobalValue::LinkageTypes::ExternalLinkage, "main", module);
    entry = BasicBlock::Create(context, "entry", mainFun);
    // Begin: BasicBlock entry in mainFun.
    builder.SetInsertPoint(entry);

    auto call = builder.CreateCall(calleeFunction, {CONST(10)});    // Call the function.
    builder.CreateRet(call);
    // End: BasicBlock entry in mainFun.
```
代码中共有两个`BasicBlock`，都叫做`entry`，但是存在于不同的函数中，对应关系见注释。

while_generator.cpp:

```cpp
    auto bb = BasicBlock::Create(context, "entry", mainFun);
    builder.SetInsertPoint(bb);             // Entry.
    // Begin: BasicBlock entry
    auto a = builder.CreateAlloca(TYPE32);
    auto i = builder.CreateAlloca(TYPE32);

    builder.CreateStore(CONST(10), a);
    builder.CreateStore(CONST(0), i);

    auto loop = BasicBlock::Create(context, "loop", mainFun);
    auto truebb =BasicBlock::Create(context, "truebb", mainFun);
    auto ret = BasicBlock::Create(context, "ret", mainFun);
    builder.CreateBr(loop);                 // Jump to loop.
    // End: BasicBlock entry

    // BasicBlock: BasicBlock loop
    builder.SetInsertPoint(loop);

    auto iLoad = builder.CreateLoad(i);
    auto aLoad = builder.CreateLoad(a);
    auto icmp = builder.CreateICmpSLT(iLoad, CONST(10)); // See if should break.
    builder.CreateCondBr(icmp,truebb,ret);
    // End: BasicBlock loop

    // Begin: BasicBlock truebb
    builder.SetInsertPoint(truebb);
    auto inc = builder.CreateAdd(iLoad, CONST(1));
    auto tempa = builder.CreateAdd(inc, aLoad);
    builder.CreateStore(inc, i);
    builder.CreateStore(tempa, a); // i = i + 1; a = a + i;
    builder.CreateBr(loop);
    // End: BasicBlock truebb

    // Begin: BasicBlock ret
    builder.SetInsertPoint(ret);
    auto retval = builder.CreateLoad(a);
    builder.CreateRet(retval); // Return a
    // End: BasicBlock ret
```
代码中共有 4 个`basicBlock`，分别是`entry, loop, truebb, ret`，对应关系见注释。

### 实验难点

开始时对 LLVM IR 的基本指令不是很熟悉，阅读了参考资料[1]有了一个大体的了解，随后遇到想要使用的指令时就根据自动补全的提示或者查询参考资料[2]，最终完成了第一部分实验。

第二部分实验没有什么太大问题，注意声明和使用`basicBlock`，以及函数调用时声明参数类型及个数即可。

### 实验总结

熟悉了 LLVM IR 的基本指令，熟悉和掌握了使用 Cpp 构建生成 LLVM IR 代码的基本过程。

另：本次实验文档简单易懂，（需求很明确），目录结构也很清晰，体验较好，给助教点赞。

## 参考资料

[1. A Tour to LLVM IR（上）.](https://zhuanlan.zhihu.com/p/66793637)

[2. LLVM Language Reference Manual.](https://releases.llvm.org/2.7/docs/LangRef.html#i_br)