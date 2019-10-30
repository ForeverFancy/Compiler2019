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
    auto module = new Module("call", context);

    std::vector<Type *> Ints(1, TYPE32); // Declare type of function args.
    auto calleeFunction = Function::Create(FunctionType::get(TYPE32, Ints, false),
                                           GlobalValue::LinkageTypes::ExternalLinkage,
                                           "callee", module);

    auto entry = BasicBlock::Create(context, "entry", calleeFunction);
    // Begin: BasicBlock entry in calleeFunction.
    builder.SetInsertPoint(entry);

    // Get args.
    std::vector<Value *> args;
    for (auto arg = calleeFunction->arg_begin(); arg != calleeFunction->arg_end(); arg++)
    {
        args.push_back(arg);
    }

    auto mul = builder.CreateMul(CONST(2), args[0]);
    builder.CreateRet(mul); // End of calleeFunction.
    // End: BasicBlock entry in calleeFunction.

    auto mainFun = Function::Create(FunctionType::get(TYPE32, false), GlobalValue::LinkageTypes::ExternalLinkage, "main", module);
    entry = BasicBlock::Create(context, "entry", mainFun);
    // Begin: BasicBlock entry in mainFun.
    builder.SetInsertPoint(entry);

    auto call = builder.CreateCall(calleeFunction, {CONST(10)}); // Call the function.
    builder.CreateRet(call);
    // End: BasicBlock entry in mainFun.

    module->print(outs(), nullptr);
    delete module;
    return 0;
}