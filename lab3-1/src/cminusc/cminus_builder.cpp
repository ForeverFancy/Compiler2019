#include "cminus_builder.hpp"
#include <iostream>
#include <string>
#include <functional>

// You can define global variables here
// to store state

std::function<llvm::Value *()> currentExpression;
std::function<llvm::Value *()> currentPointer;
llvm::Function *currentFunction; // 当前函数
llvm::Value *currentParameter;   // 声明函数时创建 alloca 时使用
int currentValue;
bool isFunctionTopCompoundStatement;

#define Const(value) llvm::ConstantInt::get(context, llvm::APInt(32, value))

#define TyInt32 llvm::Type::getInt32Ty(context)

#define TyInt32Ptr llvm::Type::getInt32PtrTy(context)

#define TyVoid llvm::Type::getVoidTy(context)

#define TyInt32Array(len) llvm::ArrayType::get(TyInt32, len)

void CminusBuilder::visit(syntax_program &node)
{
    std::cout << "Visiting program" << std::endl;
    assert(!node.declarations.empty()); // 必须要有一个声明
    for (auto &declaration : node.declarations)
    {
        declaration->accept(*this);
    }
}

void CminusBuilder::visit(syntax_num &node)
{
    std::cout << "Visiting num" << std::endl;
    currentExpression = [&]() -> llvm::Value * {
        return Const(node.value);
    };
    currentValue = node.value;
}

void CminusBuilder::visit(syntax_var_declaration &node)
{
    std::cout << "Visiting var declaration" << std::endl;

    assert(node.type != TYPE_VOID); // 只能是 int 或 int[] 类型

    if (node.num)
    { // 数组
        node.num->accept(*this);
        auto type = TyInt32Array(currentValue);
        if (scope.in_global())
        { // 全局数组
            module->getOrInsertGlobal(node.id, type);
            auto arr = module->getNamedGlobal(node.id);
            arr->setInitializer(llvm::ConstantArray::get(type, Const(0)));
            arr->setExternallyInitialized(llvm::GlobalValue::LinkageTypes::ExternalLinkage);
            scope.push(node.id, arr);
        }
        else
        { // 局部数组
            auto arr = builder.CreateAlloca(type);
            scope.push(node.id, arr);
        }
    }
    else
    { // int
        if (scope.in_global())
        { // 全局变量
            module->getOrInsertGlobal(node.id, TyInt32);
            auto var = module->getNamedGlobal(node.id);
            var->setInitializer(Const(0));
            var->setExternallyInitialized(llvm::GlobalValue::LinkageTypes::ExternalLinkage);
            scope.push(node.id, var);
        }
        else
        { // 局部变量
            auto var = builder.CreateAlloca(TyInt32);
            scope.push(node.id, var);
        }
    }
}

void CminusBuilder::visit(syntax_fun_declaration &node)
{
    std::cout << "Visiting function declaration" << std::endl;

    auto ret_type = node.type == TYPE_INT ? TyInt32 : TyVoid;
    std::vector<llvm::Type *> params_type;
    for (auto &param : node.params)
    {
        assert(param->type != TYPE_VOID);
        if (param->isarray)
        {
            params_type.push_back(TyInt32Ptr);
        }
        else
        {
            params_type.push_back(TyInt32);
        }
    }

    // create function
    auto fun = llvm::Function::Create(
        llvm::FunctionType::get(ret_type, params_type, false),
        llvm::GlobalVariable::LinkageTypes::ExternalLinkage,
        node.id, module.get());
    scope.push(node.id, fun);
    currentFunction = fun;
    scope.enter();

    // 不加 entry label 无法创建 alloca
    auto entry = llvm::BasicBlock::Create(context, "entry", fun);
    builder.SetInsertPoint(entry);

    // 访问参数列表
    size_t i = 0;
    for (auto &&param : fun->args())
    {
        currentParameter = &param;
        node.params[i]->accept(*this);
        ++i;
    }

    // 访问函数体
    isFunctionTopCompoundStatement = true;
    node.compound_stmt->accept(*this);
    isFunctionTopCompoundStatement = false;

    // 解决多余的空 bb 问题
    auto last_bb = &fun->back();
    if (last_bb && !last_bb->getTerminator())
    {
        if (node.type == TYPE_INT)
        {
            builder.CreateRet(Const(0));
        }
        else
        {
            builder.CreateRetVoid();
        }
    }

    scope.exit();
    currentFunction = nullptr;
}

void CminusBuilder::visit(syntax_param &node)
{
    std::cout << "Visiting param" << std::endl;
    auto var = node.isarray ? builder.CreateAlloca(TyInt32Ptr) : builder.CreateAlloca(TyInt32);
    builder.CreateStore(currentParameter, var);
    scope.push(node.id, var);
}

void CminusBuilder::visit(syntax_compound_stmt &node)
{
    std::cout << "Visiting compound_stmt" << std::endl;

    bool will_enter_scope = isFunctionTopCompoundStatement;
    isFunctionTopCompoundStatement = false;

    if (will_enter_scope)
    {
        scope.enter();
    }
    for (auto &&declaration : node.local_declarations)
    {
        declaration->accept(*this);
    }
    for (auto &&statement : node.statement_list)
    {
        statement->accept(*this);
    }
    if (will_enter_scope)
    {
        scope.exit();
    }
}

void CminusBuilder::visit(syntax_expresion_stmt &node)
{
    std::cout << "Visiting expression_stmt" << std::endl;
    if (node.expression)
    {
        node.expression->accept(*this);
    }
}

void CminusBuilder::visit(syntax_selection_stmt &node)
{
    std::cout << "Visiting selection_stmt" << std::endl;
    if (node.else_statement)
    {
        auto bb_true = llvm::BasicBlock::Create(context);
        auto bb_false = llvm::BasicBlock::Create(context);
        auto bb_end = llvm::BasicBlock::Create(context);
        node.expression->accept(*this);
        auto condition = currentExpression();
        if (condition->getType()->isIntegerTy(1))
        {
            builder.CreateCondBr(condition, bb_true, bb_false);
        }
        else
        {
            auto condition_bit = builder.CreateICmpNE(condition, Const(0));
            builder.CreateCondBr(condition_bit, bb_true, bb_false);
        }
        bb_true->insertInto(currentFunction);
        builder.SetInsertPoint(bb_true);
        node.if_statement->accept(*this);
        if (!currentFunction->back().getTerminator())
        {
            builder.CreateBr(bb_end);
        }
        bb_false->insertInto(currentFunction);
        builder.SetInsertPoint(bb_false);
        if (node.else_statement)
        {
            node.else_statement->accept(*this);
        }
        if (!currentFunction->back().getTerminator())
        {
            builder.CreateBr(bb_end);
        }
        bb_end->insertInto(currentFunction);
        builder.SetInsertPoint(bb_end);
    }
    else
    {
        auto bb_true = llvm::BasicBlock::Create(context);
        auto bb_end = llvm::BasicBlock::Create(context);
        node.expression->accept(*this);
        auto condition = currentExpression();
        if (condition->getType()->isIntegerTy(1))
        {
            builder.CreateCondBr(condition, bb_true, bb_end);
        }
        else
        {
            auto condition_bit = builder.CreateICmpNE(condition, Const(0));
            builder.CreateCondBr(condition_bit, bb_true, bb_end);
        }
        bb_true->insertInto(currentFunction);
        builder.SetInsertPoint(bb_true);
        node.if_statement->accept(*this);
        if (!currentFunction->back().getTerminator())
        {
            builder.CreateBr(bb_end);
        }
        bb_end->insertInto(currentFunction);
        builder.SetInsertPoint(bb_end);
    }
}

void CminusBuilder::visit(syntax_iteration_stmt &node)
{
    std::cout << "Visiting iteration_stmt" << std::endl;

    auto bb_condition = llvm::BasicBlock::Create(context);
    auto bb_loop = llvm::BasicBlock::Create(context);
    auto bb_end = llvm::BasicBlock::Create(context);

    builder.CreateBr(bb_condition);
    bb_condition->insertInto(currentFunction);
    builder.SetInsertPoint(bb_condition);
    node.expression->accept(*this);
    auto condition = currentExpression();
    if (condition->getType()->isIntegerTy(1))
    {
        builder.CreateCondBr(condition, bb_loop, bb_end);
    }
    else
    {
        auto condition_bit = builder.CreateICmpNE(condition, Const(0));
        builder.CreateCondBr(condition_bit, bb_loop, bb_end);
    }
    bb_loop->insertInto(currentFunction);
    builder.SetInsertPoint(bb_loop);
    node.statement->accept(*this);
    if (!currentFunction->back().getTerminator())
    {
        builder.CreateBr(bb_condition);
    }
    bb_end->insertInto(currentFunction);
    builder.SetInsertPoint(bb_end);
}

void CminusBuilder::visit(syntax_return_stmt &node)
{
    std::cout << "Visiting return_stmt" << std::endl;
    if (!node.expression)
    {
        builder.CreateRetVoid();
    }
    else
    {
        node.expression->accept(*this);
        builder.CreateRet(currentExpression());
    }
}

void CminusBuilder::visit(syntax_var &node)
{
    std::cout << "Visiting var" << std::endl;
    llvm::Value *var_pointer = scope.find(node.id);
    if (node.expression)
    { // arr[exp] 数组元素访问

        node.expression->accept(*this);
        auto index = currentExpression();

        // underflow 检查
        auto bb_underflow = llvm::BasicBlock::Create(context);
        auto bb_end = llvm::BasicBlock::Create(context);
        auto check_result = builder.CreateICmpSLT(
            index, llvm::ConstantInt::get(context, llvm::APInt(32, 0)));
        builder.CreateCondBr(check_result, bb_underflow, bb_end);
        bb_underflow->insertInto(currentFunction);
        builder.SetInsertPoint(bb_underflow);
        builder.CreateCall(scope.find("neg_idx_except"));
        builder.CreateBr(bb_end);
        bb_end->insertInto(currentFunction);
        builder.SetInsertPoint(bb_end);

        llvm::Value *ptr;
        if (var_pointer->getType()->getPointerElementType()->isArrayTy())
        { // [n x i32]*
            ptr = builder.CreateGEP(var_pointer, {Const(0), index});
        }
        else
        { // i32**
            var_pointer = builder.CreateLoad(var_pointer);
            ptr = builder.CreateGEP(var_pointer, index);
        }
        currentExpression = [=]() -> llvm::Value * {
            return this->builder.CreateLoad(ptr);
        };
        currentPointer = [ptr]() -> llvm::Value * { return ptr; };
    }
    else
    {
        // arr 作为函数实参 只能是 [n x i32]*
        if (var_pointer->getType()->getPointerElementType()->isArrayTy())
        {
            currentExpression = [=]() -> llvm::Value * {
                return var_pointer;
            };
        }
        else
        { // 其他 var
            currentExpression = [=]() -> llvm::Value * {
                return this->builder.CreateLoad(var_pointer);
            };
        }
        currentPointer = [var_pointer]() -> llvm::Value * { return var_pointer; };
    }
}

void CminusBuilder::visit(syntax_assign_expression &node)
{
    std::cout << "Visiting assign_expression" << std::endl;
    node.var->accept(*this);
    auto ptr = currentPointer();
    node.expression->accept(*this);
    builder.CreateStore(currentExpression(), ptr);
}

void CminusBuilder::visit(syntax_simple_expression &node)
{
    std::cout << "Visiting simple_expression" << std::endl;
    if (node.additive_expression_r == nullptr)
        node.additive_expression_l->accept(*this);
    else
    {
        node.additive_expression_l->accept(*this);
        auto additive_expression_l = currentExpression();
        node.additive_expression_r->accept(*this);
        auto additive_expression_r = currentExpression();
        llvm::Value *expression;
        switch (node.op)
        {
        case OP_LE:
            expression = builder.CreateICmpSLE(additive_expression_l, additive_expression_r);
            break;
        case OP_LT:
            expression = builder.CreateICmpSLT(additive_expression_l, additive_expression_r);
            break;
        case OP_GT:
            expression = builder.CreateICmpSGT(additive_expression_l, additive_expression_r);
            break;
        case OP_GE:
            expression = builder.CreateICmpSGE(additive_expression_l, additive_expression_r);
            break;
        case OP_EQ:
            expression = builder.CreateICmpEQ(additive_expression_l, additive_expression_r);
            break;
        case OP_NEQ:
            expression = builder.CreateICmpNE(additive_expression_l, additive_expression_r);
            break;
        }
        currentExpression = [expression]() { return expression; };
    }
}

void CminusBuilder::visit(syntax_additive_expression &node)
{
    std::cout << "Visiting additive_expression" << std::endl;
    if (!node.additive_expression)
    {
        node.term->accept(*this);
    }
    else
    {
        node.additive_expression->accept(*this);
        llvm::Value *additive_expression = currentExpression();
        node.term->accept(*this);
        llvm::Value *term_expression = currentExpression();
        if (node.op == OP_PLUS)
            currentExpression = [=]() { return this->builder.CreateAdd(additive_expression, term_expression); };
        else if (node.op == OP_MINUS)
            currentExpression = [=]() { return this->builder.CreateSub(additive_expression, term_expression); };
        // else handle error.
    }
}

void CminusBuilder::visit(syntax_term &node)
{
    std::cout << "Visiting term" << std::endl;
    if (node.term)
    {
        node.term->accept(*this);
        llvm::Value *term_expression = currentExpression();
        node.factor->accept(*this);
        llvm::Value *factor_expression = currentExpression();
        if (node.op == OP_MUL)
        {
            currentExpression = [=]() -> llvm::Value * {
                return this->builder.CreateMul(term_expression, factor_expression);
            };
        }
        else if (node.op == OP_DIV)
        {
            currentExpression = [=]() -> llvm::Value * {
                return this->builder.CreateSDiv(term_expression, factor_expression);
            };
        }
    }
    else
    {
        node.factor->accept(*this);
    }
}

void CminusBuilder::visit(syntax_call &node)
{
    std::cout << "Visiting call" << std::endl;
    std::vector<llvm::Value *> arg_list;
    for (auto &arg : node.args)
    {
        arg->accept(*this);
        llvm::Value *expression = currentExpression();
        llvm::Type *type = expression->getType();
        // 数组作为形参，单独处理
        if (type->isPointerTy() && type->getPointerElementType()->isArrayTy())
        {
            auto ptr = builder.CreateGEP(expression, {Const(0), Const(0)});
            arg_list.push_back(ptr);
        }
        else
        {
            arg_list.push_back(expression);
        }
    }
    auto callee = scope.find(node.id);
    llvm::Value *res = builder.CreateCall(callee, arg_list);
    currentExpression = [res]() { return res; }; // use llvm value
}
