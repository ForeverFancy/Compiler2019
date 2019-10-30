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
    auto module = new Module("if", context);

    auto mainFun = Function::Create(FunctionType::get(TYPE32, false), GlobalValue::ExternalLinkage, "main", module);

    auto bb = BasicBlock::Create(context, "entry", mainFun);
    // Begin: BasicBlock entry
    builder.SetInsertPoint(bb);

    auto truebb = BasicBlock::Create(context, "truebb", mainFun);
    auto falsebb = BasicBlock::Create(context, "falsebb", mainFun);

    auto icmp = builder.CreateICmpSGT(CONST(2), CONST(1)); // ? 2>1.

    auto br = builder.CreateCondBr(icmp, truebb, falsebb); // Create conditional branch.
    // End: BasicBlock entry

    // Begin: BasicBlock truebb
    builder.SetInsertPoint(truebb);
    builder.CreateRet(CONST(1)); // Return 1 in true branch.
    // End: BasicBlock truebb

    // Begin: BasicBlock falsebb
    builder.SetInsertPoint(falsebb);
    builder.CreateRet(CONST(0)); // Return 0 in false branch.
    // End: BasicBlock falsebb

    module->print(outs(), nullptr);
    delete module;
    return 0;
}