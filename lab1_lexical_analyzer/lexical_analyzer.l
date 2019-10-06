%option noyywrap
%{
/*****************声明和选项设置  begin*****************/
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <regex.h>
#include <stdlib.h>

#include "lab1_lexical_analyzer/lexical_analyzer.h"
#include "common/common.h"

#ifndef LAB1_ONLY
#include "syntax_analyzer.h"
#endif

int files_count = 0;
int lines = 1;
int pos_start = 1;
int pos_end = 1;

/*****************声明和选项设置  end*****************/

%}

commentPattern "/*"([^\*]|(\*)*[^\*/])*(\*)*"*/"
digitPattern [0-9]
numberPattern (0|[1-9]{digitPattern}*)
identifierPattern [a-zA-Z][a-zA-Z]*

%%

 /******************TODO*********************/
 /****请在此补全所有flex的模式与动作  start******/
\n					{ lines += 1; pos_start = 1; pos_end = 1; }
\t					{ pos_end += 1; }
" "					{ pos_end += 1; }
"/*"([^\*]|(\*)[^\/])*\*+\/	{ 	pos_end = pos_start; 
								int length = strlen(yytext); 
								for(int i = 0; i < length; i++)
								{
									pos_end++;
									if( yytext[i] == '\n')
									{
										lines++;
										pos_end = 1;
									}
								} 
								return COMMENT; 
							}
([0-9]+[a-zA-Z]+|[a-zA-Z]+[0-9]+)*		{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return ERROR; }
\[\]				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return ARRAY; }
"+"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return ADD; }
"-"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return SUB; }
"*"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return MUL; }
"/"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return DIV; }
"<"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return LT; }
"<="				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return LTE; }
">"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return GT; }
">="				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return GTE; }
"=="				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return EQ; }
"!="				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return NEQ; }
"="					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return ASSIN; }
";"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return SEMICOLON; }
","					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return COMMA; }
"("					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return LPARENTHESE; }
")"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return RPARENTHESE; }
"["					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return LBRACKET; }
"]"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return RBRACKET; }
"{"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return LBRACE; }
"}"					{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return RBRACE; }
"else"				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return ELSE; }
"if"				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return IF; }
"int"				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return INT; }
"return"			{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return RETURN; }
"void"				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return VOID; }
"while"				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return WHILE; }
[a-zA-Z]+			{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return IDENTIFIER; }
[0-9]+				{ pos_start = pos_end; pos_end = pos_start + strlen(yytext); return NUMBER; }
. 					{ return ERROR; }



 /****请在此补全所有flex的模式与动作  end******/
%%
/****************C代码 start*************/

/// \brief analysize a *.cminus file
///
///	\param input_file_name
/// \param output_file_name
void analyzer(char* input_file_name, char* output_file_name){
	lines = 1;
	pos_start = 1;
	pos_end = 1;
	char input_path[256] = "./testcase/";
	strcat(input_path, input_file_name);
	char output_path[256] = "./tokens/";
	strcat(output_path, output_file_name);
	if(!(yyin = fopen(input_path,"r"))){
		printf("[ERR] No input file\n");
		exit(1);
	}
	printf("[START]: Read from: %s\n", input_file_name);
	FILE *fp = fopen(output_path,"w+");

	int token;
	while(token = yylex()){
		pos_start = pos_end;
		pos_end += strlen(yytext);
		switch(token){
			case ERROR:
				fprintf(fp, "[ERR]: unable to analysize %s at %d line, from %d to %d\n", yytext, lines, pos_start, pos_end);
				break;
			case COMMENT:
				//printf("comment: %s\n",yytext);
				break;
			case BLANK:
				break;
			case EOL:
				pos_start = 1,pos_end = 1;
				break;
			case NUMBER:
				fprintf(fp, "%d\t%d\t%d\t%d\t%d\n",atoi(yytext), token, lines, pos_start, pos_end);
				break;
			default :
				fprintf(fp, "%s\t%d\t%d\t%d\t%d\n",yytext, token, lines, pos_start, pos_end);
		}
	}
	fclose(fp);
	printf("[END]: Analysis completed.\n");
	lines = 1;
	pos_start = 1;
	pos_end = 1;
}

/// \brief get all file paths under 'testcase' directory
///
/// under 'testcase' directory, there could be many *.cminus files.
/// \todo student should fill this function
int getAllTestcase(char filename[][256]){
	DIR *dp;
	struct dirent *dirp;
	regex_t re;
	const char pattern[] = "^.*\.cminus$";
	if (regcomp(&re, pattern, REG_EXTENDED | REG_NOSUB) != 0)
		perror("compile pattern failed");
	if ((dp = opendir("./testcase")) == NULL)
		perror("could not open dir");
	while ((dirp = readdir(dp)) != NULL)
	{
		int status = regexec(&re, dirp->d_name, 0, NULL, 0);
		if (status == 0)
		{	
			if(dirp -> d_type == DT_REG)
			{
				strcpy(filename[files_count], dirp->d_name);
				files_count++;
			}
		}
	}
	// printf("%s\n", dirp->d_name);
	regfree(&re);
	closedir(dp);
	return files_count;
}

/// \brief process all *.cminus file
///
/// note that: use relative path for all i/o operations
///	process all *.cminus files under 'testcase' directory,
/// then create *.tokens files under 'tokens' directory
/// \todo student should fill this function
int lex_main(int argc, char **argv){
	char filename[10][256];
	char output_file_name[256];
	char suffix[] = ".tokens";
	files_count = getAllTestcase(filename);
	for(int i = 0; i < files_count; i++){
		strcpy(output_file_name,filename[i]);
		strcpy(output_file_name+strlen(filename[i])-7,suffix);
		analyzer(filename[i],output_file_name);
	}
	return 0;
}
/****************C代码 end*************/
