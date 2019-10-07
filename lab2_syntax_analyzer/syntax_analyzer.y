%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common/common.h"
#include "syntax_tree/SyntaxTree.h"

#include "lab1_lexical_analyzer/lexical_analyzer.h"

// external functions from lex
extern int yylex();
extern int yyparse();
extern int yyrestart();
extern FILE * yyin;

// external variables from lexical_analyzer module
extern int lines;
extern char * yytext;

// Global syntax tree.
SyntaxTree * gt;

void yyerror(const char * s);
%}

%union {
	SyntaxTreeNode *node;
	char *string;
/********** TODO: Fill in this union structure *********/
}

/********** TODO: Your token definition here ***********/
%token ERROR
%token <string> ADD
%token <string> SUB
%token <string> MUL
%token <string> DIV
%token <string> LT
%token <string> LTE
%token <string> GT
%token <string> GTE
%token <string> EQ
%token <string> NEQ
%token <string> ASSIN
%token <string> SEMICOLON
%token <string> COMMA
%token <string> LPARENTHESE
%token <string> RPARENTHESE
%token <string> LBRACKET
%token <string> RBRACKET
%token <string> LBRACE
%token <string> RBRACE
%token <string> ELSE
%token <string> IF
%token <string> INT
%token <string> RETURN
%token <string> VOID
%token <string> WHILE
%token <string> IDENTIFIER
%token <string> NUMBER
%token <string> ARRAY
%token <string> LETTER
%token EOL
%token COMMENT
%token BLANK

%type <node> program
%type <node> declaration-list
%type <node> declaration 
%type <node> var-declaration 
%type <node> type-specifier 
%type <node> fun-declaration
%type <node> param-list
%type <node> param 
%type <node> compound-stmt 
%type <node> local-declarations 
%type <node> statement-list 
%type <node> statement
%type <node> expression-stmt
%type <node> selection-stmt
%type <node> iteration-stmt
%type <node> return-stmt
%type <node> expression
%type <node> var
%type <node> simple-expression
%type <node> relop
%type <node> additive-expression 
%type <node> addop
%type <node> term
%type <node> mulop
%type <node> factor
%type <node> call
%type <node> args
%type <node> arg-list
/* compulsory starting symbol */
%start program

%%
/*************** TODO: Your rules here *****************/

program : declaration-list;

declaration-list : declaration-list declaration 
				| declaration 
				;

declaration : var-declaration 
			| fun-declaration 
			;

var-declaration : type-specifier IDENTIFIER  SEMICOLON { printf("ID %s\n",$2); } | type-specifier IDENTIFIER LBRACKET NUMBER RBRACKET SEMICOLON { printf("ID %s\n",$2); };

type-specifier : INT | VOID ;

fun-declaration : type-specifier IDENTIFIER LPARENTHESE params RPARENTHESE compound-stmt ;

params : param-list | VOID ;

param-list: param-list COMMA param | param ;

param : type-specifier IDENTIFIER | type-specifier IDENTIFIER ARRAY ;

compound-stmt : LBRACE local-declarations statement-list RBRACE ;

local-declarations : local-declarations var-declaration | /* empty */ ;

statement-list : statement-list statement | /* empty */;

statement : expression-stmt | compound-stmt| selection-stmt | iteration-stmt | return-stmt ;

expression-stmt : expression SEMICOLON | SEMICOLON ;

selection-stmt : IF LPARENTHESE expression RPARENTHESE statement | IF LPARENTHESE expression RPARENTHESE statement ELSE statement ;

iteration-stmt : WHILE LPARENTHESE expression RPARENTHESE statement ;

return-stmt : RETURN SEMICOLON | RETURN expression SEMICOLON ;

expression : var ASSIN expression | simple-expression ;

var : IDENTIFIER | IDENTIFIER LBRACKET expression RBRACKET ;

simple-expression : additive-expression relop additive-expression | additive-expression ;

relop : LTE | LT | GT | GTE | EQ | NEQ ;

additive-expression : additive-expression addop term | term ;

addop : ADD | SUB ;

term : term mulop factor | factor ;

mulop : MUL | DIV ;

factor : LPARENTHESE expression RPARENTHESE | var | call | NUMBER ;

call : IDENTIFIER LPARENTHESE args RPARENTHESE ;

args : arg-list | /* empty */;

arg-list : arg-list COMMA expression | expression ;

%%

void yyerror(const char * s)
{
	// TODO: variables in Lab1 updates only in analyze() function in lexical_analyzer.l
	//       You need to move position updates to show error output below
	fprintf(stderr, "%s:%d syntax error for %s\n", s, lines, yytext);
}

/// \brief Syntax analysis from input file to output file
///
/// \param input basename of input file
/// \param output basename of output file
void syntax(const char * input, const char * output)
{
	gt = newSyntaxTree();

	char inputpath[256] = "./testcase/";
	char outputpath[256] = "./syntree/";
	strcat(inputpath, input);
	strcat(outputpath, output);

	if (!(yyin = fopen(inputpath, "r"))) {
		fprintf(stderr, "[ERR] Open input file %s failed.", inputpath);
		exit(1);
	}
	yyrestart(yyin);
	printf("[START]: Syntax analysis start for %s\n", input);
	FILE * fp = fopen(outputpath, "w+");
	if (!fp)	return;

	// yyerror() is invoked when yyparse fail. If you still want to check the return value, it's OK.
	// `while (!feof(yyin))` is not needed here. We only analyze once.
	yyparse();

	printf("[OUTPUT] Printing tree to output file %s\n", outputpath);
	//printSyntaxTree(fp, gt);
	//deleteSyntaxTree(gt);
	gt = 0;

	fclose(fp);
	printf("[END] Syntax analysis end for %s\n", input);
}

/// \brief starting function for testing syntax module.
///
/// Invoked in test_syntax.c
int syntax_main(int argc, char ** argv)
{
	char filename[10][256];
	char output_file_name[256];
	const char * suffix = ".syntax_tree";
	int fn = getAllTestcase(filename);
	for (int i = 0; i < fn; i++) {
			strcpy(output_file_name,filename[i]);
			strcpy(output_file_name+strlen(filename[i])-7,suffix);
			syntax(filename[i], output_file_name);
	}
	return 0;
}
