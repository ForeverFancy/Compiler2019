#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Type.h>
#include <llvm/IR/Verifier.h>

#include <iostream>
#include <memory>

#ifdef DEBUG                                             // 用于调试信息,大家可以在编译过程中通过" -DDEBUG"来开启这一选项
#define DEBUG_OUTPUT std::cout << __LINE__ << std::endl; // 输出行号的简单示例
#else
#define DEBUG_OUTPUT
#endif

using namespace llvm;

#define CONST(num) ConstantInt::get(context, APInt(32, num))

int main()
{
    LLVMContext context;
    Type *TYPE32 = Type::getInt32Ty(context);
    IRBuilder<> builder(context);
    auto module = new Module("while", context);

    auto mainFun = Function::Create(FunctionType::get(TYPE32, false), GlobalValue::ExternalLinkage, "main", module);

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

    module->print(outs(), nullptr);
    delete module;
    return 0;
}