# lab2

## 实验设计

根据 CMINUS 的语法规则，在 `syntax_analyzer.y` 里面加入语法规则。

语法规则中 `IDENTIFIER` 和 `NUMBER` 的值由 `yylval` 经词法分析后传入语法分析中。

由于要建立语法树，在每一条语法规则后需要对语法树做相应的补充。由于 `yacc` 采用的是 `LALR` 语法分析，对于每一条语法规则，产生式左边的非终结符建立语法树节点，并将产生式右边的节点添加为子节点。通过以上方法可以完整建立语法树。

## 遇到的问题及解决方案

在构建整个项目时，在 `lex` 和 `yacc` 的配合上出现了一些问题。

首先是对 `yacc` 里的 `token` 和 `type` 绑定属性，这时需要在 `syntax_analyzer.y` 的 `union` 中声明

```
%union {
	SyntaxTreeNode *node;
	char *string;
}
```

并且在 `lexical_analyzer.h` 里声明，也把 `YYSTYPE` 的类型改掉

```
typedef union
{
	SyntaxTreeNode *node;
    char *string;
}Type;

#define YYSTYPE Type
```

`syntax_analyzer.y` 需要 `yylval` 传递参数的值，所以需要在 `lexical_analyzer.l` 中声明

```
YYSTYPE yylval;
```

在词法分析中遇到对应的词时，将值拷贝到 `yylval` 中:

```
[a-zA-Z]+			{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); yylval.string = strdup(yytext); return IDENTIFIER; }
[0-9]+				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); yylval.string = strdup(yytext); return NUMBER; }
```

由于 `strdup` 不会自己释放内存。在语法分析中，给 `IDENTIFIER` 和 `NUMBER` 建立完语法树节点之后，需要将它们的内存 `free` 掉，避免内存泄露。

## 二义性文法处理

******************TODO******************.

## 新的测试用例

还是使用上一次的 `selection.cminus` 进行语法测试。

## 实验收获

通过本次实验掌握了将 `lex` 和 `yacc` 结合完成词法 + 语法分析的方法，熟悉了构建流程，建立了语法树。

## 实验建议

建议助教重新整理工程目录，将文档和代码分开，这样目录结构会更清晰一些。