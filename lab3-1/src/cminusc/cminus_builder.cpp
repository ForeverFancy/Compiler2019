#include "cminus_builder.hpp"
#include <iostream>
#include <functional>

// You can define global variables here
// to store state
std::function<llvm::Value *()> currentExpression;
std::function<llvm::Value *()> currentPointer;
llvm::Value *current_expr;

void CminusBuilder::visit(syntax_program &node)
{
    std::cout << "Visiting program " << std::endl;
    for (auto &declaration : node.declarations)
    {
        declaration->accept(*this);
        std::cout << declaration->type << std::endl;
        std::cout << declaration->id << std::endl;
    }
}

void CminusBuilder::visit(syntax_num &node)
{
    std::cout << "Visiting num" << std::endl;
}

void CminusBuilder::visit(syntax_var_declaration &node)
{
    std::cout << "Visiting var_declaration" << std::endl;
}

void CminusBuilder::visit(syntax_fun_declaration &node)
{
    std::cout << "Visiting fun_declaration" << std::endl;
    for (auto &param : node.params)
    {
        param->accept(*this);
    }
    node.compound_stmt->accept(*this);
}

void CminusBuilder::visit(syntax_param &node)
{
    std::cout << "Visiting param" << std::endl;
}

void CminusBuilder::visit(syntax_compound_stmt &node)
{
    std::cout << "Visiting compound_stmt" << std::endl;
    for (auto &local_declaration : node.local_declarations)
    {
        local_declaration->accept(*this);
    }
    for (auto &statement : node.statement_list)
    {
        statement->accept(*this);
    }
}

void CminusBuilder::visit(syntax_expresion_stmt &node)
{
    std::cout << "Visiting expression_stmt" << std::endl;
}

void CminusBuilder::visit(syntax_selection_stmt &node)
{
    std::cout << "Visiting selection_stmt" << std::endl;
}

void CminusBuilder::visit(syntax_iteration_stmt &node)
{
    std::cout << "Visiting iteration_stmt" << std::endl;
}

void CminusBuilder::visit(syntax_return_stmt &node)
{
    std::cout << "Visiting return_stmt" << std::endl;
    if (node.expression == nullptr)
        builder.CreateRet(nullptr);
    else
        builder.CreateRet(currentExpression());
}

void CminusBuilder::visit(syntax_var &node)
{ // current_expr
    std::cout << "Visiting var" << std::endl;
    if (node.expression == nullptr)
        current_expr = scope.find(node.id);
}

void CminusBuilder::visit(syntax_assign_expression &node)
{
    std::cout << "Visiting assign_expression" << std::endl;
}

void CminusBuilder::visit(syntax_simple_expression &node)
{ // current_expr
    std::cout << "Visiting simple_expression" << std::endl;
    if (node.additive_expression_l == nullptr)
        node.additive_expression_r->accept(*this);
    else
    {
        node.additive_expression_l->accept(*this);
        auto additive_expression_l = currentExpression();
        node.additive_expression_r->accept(*this);
        auto additive_expression_r = currentExpression();

        if (node.op == OP_LE)
            currentExpression = [&]() { return builder.CreateICmpSLE(additive_expression_l, additive_expression_r); };
        else if (node.op == OP_LT)
            currentExpression = [&]() { return builder.CreateICmpSLT(additive_expression_l, additive_expression_r); };
        else if (node.op == OP_GT)
            currentExpression = [&]() { return builder.CreateICmpSGT(additive_expression_l, additive_expression_r); };
        else if (node.op == OP_GE)
            currentExpression = [&]() { return builder.CreateICmpSGE(additive_expression_l, additive_expression_r); };
        else if (node.op == OP_EQ)
            currentExpression = [&]() { return builder.CreateICmpEQ(additive_expression_l, additive_expression_r); };
        else if (node.op == OP_NEQ)
            currentExpression = [&]() { return builder.CreateICmpNE(additive_expression_l, additive_expression_r); };
        // else handle error.
    }
}

void CminusBuilder::visit(syntax_additive_expression &node)
{
    std::cout << "Visiting additive_expression" << std::endl;
    if (node.additive_expression == nullptr)
        node.term->accept(*this);
    else
    {
        node.additive_expression->accept(*this);
        auto additive_expression = currentExpression();
        node.term->accept(*this);
        auto term_expression = currentExpression();
        if (node.op == OP_PLUS)
            currentExpression = [&]() { return builder.CreateAdd(additive_expression, term_expression); };
        else if (node.op == OP_MINUS)
            currentExpression = [&]() { return builder.CreateSub(additive_expression, term_expression); };
        // else handle error.
    }
}

void CminusBuilder::visit(syntax_term &node)
{
    std::cout << "Visiting term" << std::endl;
}

void CminusBuilder::visit(syntax_call &node)
{
    std::cout << "Visiting call" << std::endl;
    std::vector<llvm::Value *> arg_list;
    for (auto &arg : node.args)
    {
        arg->accept(*this);
        arg_list.push_back(currentExpression());
    }
    auto callee = scope.find(node.id);
    auto res = builder.CreateCall(callee, arg_list);
    currentExpression = [&]() { return res; }; // use llvm value
}
