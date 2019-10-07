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
extern int pos_start;
extern int pos_end;
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
%type <node> params 
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
// Precedences go increasing, so that then < else
%nonassoc "then"
%nonassoc ELSE
%start program

%%
/*************** TODO: Your rules here *****************/

program : declaration-list 
		{ 
			$$ = newSyntaxTreeNode("program"); 
			gt -> root = $$;
			SyntaxTreeNode_AddChild($$, $1); 
		};

declaration-list : declaration-list declaration 
				{
					$$ = newSyntaxTreeNode("declaration-list");
					SyntaxTreeNode_AddChild($$, $1);
					SyntaxTreeNode_AddChild($$, $2);
				}
				| declaration 
				{
					$$ = newSyntaxTreeNode("declaration-list");
					SyntaxTreeNode_AddChild($$, $1);
				}
				;

declaration : var-declaration 
			{
				$$ = newSyntaxTreeNode("declaration");
				SyntaxTreeNode_AddChild($$,$1);
			}
			| fun-declaration 
			{
				$$ = newSyntaxTreeNode("declaration");
				SyntaxTreeNode_AddChild($$,$1);
			}
			;

var-declaration : type-specifier IDENTIFIER  SEMICOLON 
				{ 
					// printf("ID %s\n",$2); 
					SyntaxTreeNode * temp1 = newSyntaxTreeNode($2);
					SyntaxTreeNode * temp2 = newSyntaxTreeNode(";");
					$$ = newSyntaxTreeNode("var-declaration");
					SyntaxTreeNode_AddChild($$,$1);
					SyntaxTreeNode_AddChild($$,temp1);
					SyntaxTreeNode_AddChild($$,temp2);
					free($2);
				} 
				| type-specifier IDENTIFIER LBRACKET NUMBER RBRACKET SEMICOLON 
				{ 
					// printf("ID %s\n",$2);
					SyntaxTreeNode * temp1 = newSyntaxTreeNode($2);
					SyntaxTreeNode * temp2 = newSyntaxTreeNode("[");
					SyntaxTreeNode * temp3 = newSyntaxTreeNode($4);
					SyntaxTreeNode * temp4 = newSyntaxTreeNode("]");
					SyntaxTreeNode * temp5 = newSyntaxTreeNode(";");
					$$ = newSyntaxTreeNode("var-declaration");
					SyntaxTreeNode_AddChild($$,$1);
					SyntaxTreeNode_AddChild($$,temp1);
					SyntaxTreeNode_AddChild($$,temp2);
					SyntaxTreeNode_AddChild($$,temp3);
					SyntaxTreeNode_AddChild($$,temp4);
					SyntaxTreeNode_AddChild($$,temp5);
					free($2);
					free($4);
				}
				;

type-specifier : INT 
				{
					// printf("Find int.\n");
					SyntaxTreeNode * temp = newSyntaxTreeNode("int");
					$$ = newSyntaxTreeNode("type-specifier");
					SyntaxTreeNode_AddChild($$,temp);
				}
				| VOID 
				{
					SyntaxTreeNode * temp = newSyntaxTreeNode("void");
					$$ = newSyntaxTreeNode("type-specifier");
					SyntaxTreeNode_AddChild($$,temp);
				}
				;

fun-declaration : type-specifier IDENTIFIER LPARENTHESE params RPARENTHESE compound-stmt 
				{ 
					// printf("ID %s\n",$2);
					$$ = newSyntaxTreeNode("fun-declaration");
					SyntaxTreeNode * temp1 = newSyntaxTreeNode($2);  // ID
					SyntaxTreeNode * temp2 = newSyntaxTreeNode("("); // (
					SyntaxTreeNode * temp3 = newSyntaxTreeNode(")"); // )
					SyntaxTreeNode_AddChild($$, $1);
					SyntaxTreeNode_AddChild($$, temp1);
					SyntaxTreeNode_AddChild($$, temp2);
					SyntaxTreeNode_AddChild($$, $4);
					SyntaxTreeNode_AddChild($$, temp3);
					SyntaxTreeNode_AddChild($$, $6);
					free($2);
				}
				;

params : param-list 
		{
			$$ = newSyntaxTreeNode("params");
			SyntaxTreeNode_AddChild($$, $1);
		}
		| VOID 
		{
			$$ = newSyntaxTreeNode("params");
			SyntaxTreeNode * temp = newSyntaxTreeNode("void");
			SyntaxTreeNode_AddChild($$, temp);
		}
		;

param-list: param-list COMMA param 
			{
				$$ = newSyntaxTreeNode("param-list");
				SyntaxTreeNode * temp = newSyntaxTreeNode(",");
				SyntaxTreeNode_AddChild($$, $1);
				SyntaxTreeNode_AddChild($$, temp);
				SyntaxTreeNode_AddChild($$, $3);
			}
			| param 
			{
				$$ = newSyntaxTreeNode("param-list");
				SyntaxTreeNode_AddChild($$, $1);
			}
			;

param : type-specifier IDENTIFIER 
		{ 
			// printf("ID %s\n",$2);
			$$ = newSyntaxTreeNode("param");
			SyntaxTreeNode * temp = newSyntaxTreeNode($2);
			SyntaxTreeNode_AddChild($$, $1);
			SyntaxTreeNode_AddChild($$, temp);
			free($2);
		}
		| type-specifier IDENTIFIER ARRAY 
		{ 
			// printf("ID %s\n",$2); 
			$$ = newSyntaxTreeNode("param");
			SyntaxTreeNode * temp1 = newSyntaxTreeNode($2);
			SyntaxTreeNode * temp2 = newSyntaxTreeNode("[]");
			SyntaxTreeNode_AddChild($$, $1);
			SyntaxTreeNode_AddChild($$, temp1);
			SyntaxTreeNode_AddChild($$, temp2);
			free($2);
		}
		;

compound-stmt : LBRACE local-declarations statement-list RBRACE 
				{
					SyntaxTreeNode * temp1 = newSyntaxTreeNode("{");
					SyntaxTreeNode * temp2 = newSyntaxTreeNode("}");
					$$ = newSyntaxTreeNode("compound-stmt");
					SyntaxTreeNode_AddChild($$, temp1);
					SyntaxTreeNode_AddChild($$, $2);
					SyntaxTreeNode_AddChild($$, $3);
					SyntaxTreeNode_AddChild($$, temp2);
				}
				;

local-declarations : local-declarations var-declaration 
					{
						$$ = newSyntaxTreeNode("local-declarations");
						SyntaxTreeNode_AddChild($$, $1);
						SyntaxTreeNode_AddChild($$, $2);
					}
					| /* empty */ 
					{
						$$ = newSyntaxTreeNode("local-declarations");
						SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("epsilon"));
					}
					;

statement-list : statement-list statement 
				{
					$$ = newSyntaxTreeNode("statement-list");
					SyntaxTreeNode_AddChild($$, $1);
					SyntaxTreeNode_AddChild($$, $2);
				}
				| /* empty */
				{
					$$ = newSyntaxTreeNode("statement-list");
					SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("epsilon"));
				}
				;

statement : expression-stmt 
		{
			$$ = newSyntaxTreeNode("statement");
			SyntaxTreeNode_AddChild($$, $1);
		}
		| compound-stmt
		{
			$$ = newSyntaxTreeNode("statement");
			SyntaxTreeNode_AddChild($$, $1);
		}
		| selection-stmt 
		{
			$$ = newSyntaxTreeNode("statement");
			SyntaxTreeNode_AddChild($$, $1);
		}
		| iteration-stmt 
		{
			$$ = newSyntaxTreeNode("statement");
			SyntaxTreeNode_AddChild($$, $1);
		}
		| return-stmt 
		{
			$$ = newSyntaxTreeNode("statement");
			SyntaxTreeNode_AddChild($$, $1);
		}
		;

expression-stmt : expression SEMICOLON 
				{
					$$ = newSyntaxTreeNode("expression-stmt");
					SyntaxTreeNode_AddChild($$, $1);
					SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
				}
				| SEMICOLON 
				{
					$$ = newSyntaxTreeNode("expression-stmt");
					SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
				}
				;

selection-stmt : IF LPARENTHESE expression RPARENTHESE statement    			%prec "then"
				{
					SyntaxTreeNode * temp1 = newSyntaxTreeNode("if");
					SyntaxTreeNode * temp2 = newSyntaxTreeNode("(");
					SyntaxTreeNode * temp3 = newSyntaxTreeNode(")");
					$$ = newSyntaxTreeNode("selection-stmt");
					SyntaxTreeNode_AddChild($$, temp1);
					SyntaxTreeNode_AddChild($$, temp2);
					SyntaxTreeNode_AddChild($$, $3);
					SyntaxTreeNode_AddChild($$, temp3);
					SyntaxTreeNode_AddChild($$, $5);
				}
				| IF LPARENTHESE expression RPARENTHESE statement ELSE statement 
				{
					SyntaxTreeNode * temp1 = newSyntaxTreeNode("if");
					SyntaxTreeNode * temp2 = newSyntaxTreeNode("(");
					SyntaxTreeNode * temp3 = newSyntaxTreeNode(")");
					SyntaxTreeNode * temp4 = newSyntaxTreeNode("else");
					$$ = newSyntaxTreeNode("selection-stmt");
					SyntaxTreeNode_AddChild($$, temp1);
					SyntaxTreeNode_AddChild($$, temp2);
					SyntaxTreeNode_AddChild($$, $3);
					SyntaxTreeNode_AddChild($$, temp3);
					SyntaxTreeNode_AddChild($$, $5);
					SyntaxTreeNode_AddChild($$, temp4);
					SyntaxTreeNode_AddChild($$, $7);
				}
				;

iteration-stmt : WHILE LPARENTHESE expression RPARENTHESE statement 
				{
					$$ = newSyntaxTreeNode("iteration-stmt");
					SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("while"));
					SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
					SyntaxTreeNode_AddChild($$, $3);
					SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
					SyntaxTreeNode_AddChild($$, $5);
				}
				;

return-stmt : RETURN SEMICOLON 
			{
				$$ = newSyntaxTreeNode("return-stmt");
				SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("return"));
				SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
			}
			| RETURN expression SEMICOLON 
			{
				$$ = newSyntaxTreeNode("return-stmt");
				SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("return"));
				SyntaxTreeNode_AddChild($$, $2);
				SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
			}
			;

expression : var ASSIN expression 
			{
				$$ = newSyntaxTreeNode("expression");
				SyntaxTreeNode_AddChild($$, $1);
				SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("="));
				SyntaxTreeNode_AddChild($$, $3);
			}
			| simple-expression 
			{
				$$ = newSyntaxTreeNode("expression");
				SyntaxTreeNode_AddChild($$, $1);
			}
			;

var : IDENTIFIER 
	{ 
		// printf("ID %s\n",$1);
		$$ = newSyntaxTreeNode("var");
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1)); 
		free($1);
	}
	| IDENTIFIER LBRACKET expression RBRACKET 
	{ 
		// printf("ID %s\n",$1); 
		$$ = newSyntaxTreeNode("var");
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1)); 
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("[")); 
		SyntaxTreeNode_AddChild($$, $3);
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("]")); 
		free($1);
	}
	;

simple-expression : additive-expression relop additive-expression 
					{
						$$ = newSyntaxTreeNode("simple-expression");
						SyntaxTreeNode_AddChild($$, $1);
						SyntaxTreeNode_AddChild($$, $2);
						SyntaxTreeNode_AddChild($$, $3);
					}
					| additive-expression 
					{
						$$ = newSyntaxTreeNode("simple-expression");
						SyntaxTreeNode_AddChild($$, $1);
					}
					;

relop : LTE 
		{
			$$ = newSyntaxTreeNode("relop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("<="));
		}
		| LT 
		{
			$$ = newSyntaxTreeNode("relop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("<"));
		}
		| GT 
		{
			$$ = newSyntaxTreeNode("relop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(">"));
		}
		| GTE 
		{
			$$ = newSyntaxTreeNode("relop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(">="));
		}
		| EQ 
		{
			$$ = newSyntaxTreeNode("relop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("=="));
		}
		| NEQ 
		{
			$$ = newSyntaxTreeNode("relop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("!="));
		}
		;

additive-expression : additive-expression addop term 
					{
						$$ = newSyntaxTreeNode("additive-expression");
						SyntaxTreeNode_AddChild($$, $1);
						SyntaxTreeNode_AddChild($$, $2);
						SyntaxTreeNode_AddChild($$, $3);
					}
					| term 
					{
						$$ = newSyntaxTreeNode("additive-expression");
						SyntaxTreeNode_AddChild($$, $1);
					}
					;

addop : ADD 
		{
			$$ = newSyntaxTreeNode("addop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("+"));
		}
		| SUB 
		{
			$$ = newSyntaxTreeNode("addop");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("-"));
		}
		;

term : term mulop factor 
	{
		$$ = newSyntaxTreeNode("term");
		SyntaxTreeNode_AddChild($$, $1);
		SyntaxTreeNode_AddChild($$, $2);
		SyntaxTreeNode_AddChild($$, $3);
	}
	| factor 
	{
		$$ = newSyntaxTreeNode("term");
		SyntaxTreeNode_AddChild($$, $1);
	}
	;

mulop : MUL 
	{
		$$ = newSyntaxTreeNode("mulop");
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("*"));
	}
	| DIV 
	{
		$$ = newSyntaxTreeNode("mulop");
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("/"));
	}
	;

factor : LPARENTHESE expression RPARENTHESE 
		{
			$$ = newSyntaxTreeNode("factor");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
			SyntaxTreeNode_AddChild($$, $2);
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
		}
		| var 
		{
			$$ = newSyntaxTreeNode("factor");
			SyntaxTreeNode_AddChild($$, $1);
		}
		| call 
		{
			$$ = newSyntaxTreeNode("factor");
			SyntaxTreeNode_AddChild($$, $1);
		}
		| NUMBER 
		{
			$$ = newSyntaxTreeNode("factor");
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
			free($1);
		}
		;

call : IDENTIFIER LPARENTHESE args RPARENTHESE 
	{ 
		// printf("ID %s\n",$1); 
		$$ = newSyntaxTreeNode("call");
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
		SyntaxTreeNode_AddChild($$, $3);
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
		free($1);
	}
	;

args : arg-list 
	{
		$$ = newSyntaxTreeNode("args");
		SyntaxTreeNode_AddChild($$, $1);
	}
	| /* empty */
	{
		$$ = newSyntaxTreeNode("args");
		SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("epsilon"));
	}
	;

arg-list : arg-list COMMA expression 
		{
			$$ = newSyntaxTreeNode("arg-list");
			SyntaxTreeNode_AddChild($$, $1);
			SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(","));
			SyntaxTreeNode_AddChild($$, $3);
		}
		| expression 
		{
			$$ = newSyntaxTreeNode("arg-list");
			SyntaxTreeNode_AddChild($$, $1);
		}
		;

%%

void yyerror(const char * s)
{
	// TODO: variables in Lab1 updates only in analyze() function in lexical_analyzer.l
	//       You need to move position updates to show error output below
	fprintf(stderr, "%s:syntax error for %s in line: %d, pos_start: %d, pos_end:%d \n", s, yytext, lines, pos_start, pos_end);
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
	printSyntaxTree(fp, gt);
	deleteSyntaxTree(gt);
	gt = NULL;

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
