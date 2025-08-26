%token INT CHAR FLOAT EQ NUMBER PRINT IF ELSE DEQ LEQ GEQ NEQ WHILE FOR VOID RETURN POW
%token PRINTFSTRINGS COMMENTS FLOATNUMBER CHARACTER
%{
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include <bits/stdc++.h>
	using namespace std;
	void yyerror(char *);
	int yylex(void);
	char mytext[500];
	char var[100];
	int num = 0;
	extern char *yytext;
	int line_num = 0;
	map<string,int>mp;
	char* var_name;
	bool chk = true;
	char* var_name1 = nullptr;
%}


%union
{
	char str[500];
}

%token<str> VARIABLE
%type<str> declarations_varname
%type<str> if_variable_name_start
%left '+' '-' 
%left '*' '/'
%right POW 

%%

prog: prog global | global
;
global: function | COMMENTS | declarations ';'
// declarations are present bcz they might be global
;

function: 
  dtype VARIABLE '(' funargs ')' '{' maincode '}'
| dtype VARIABLE '(' ')' '{' maincode '}'
| VOID VARIABLE '(' funargs ')' '{' maincode '}'
| VOID VARIABLE '(' ')' '{' maincode '}'
;
// things to do in code: for loops, if-else, declarations, printf;
// funargs can be simple int/char/flt var or array ones
funargs: funargs ',' arg | arg;
 
arg: dtype VARIABLE | arrayargs;

arrayargs:
  dtype VARIABLE '['']' array_end
| dtype VARIABLE '['expression']' array_end
;

maincode: maincode code | code;

code: 
  functioncalls ';'
| printf ';'
| declarations ';'
| assignments ';'
| conditionals
| loops
| return_statements ';'
| COMMENTS
;

functioncalls:
  VARIABLE '(' functioncalls_args ')' 
| VARIABLE '('')'

;

functioncalls_args: functioncalls_args ',' expression | expression 
;

// supported function calls and functions, now printf

printf:
  PRINT '(' PRINTFSTRINGS printfargs ')'
| PRINT '(' PRINTFSTRINGS ')'
;

printfargs: printfargs ',' expression | ',' expression;

// printf done :-)

// declarations cases to be handled: multiple args x,y,z, equality ones
declarations: dtype declarations_help;

declarations_help: declarations_help ',' declarations_variables | declarations_variables
;

declarations_variables: declarations_variable_name | declarations_variable_name EQ expression
;
 
declarations_variable_name: 
  declarations_varname '['declarations_array_size']'
  {
	mp[string($1)] = 2;
  }
| declarations_varname '['declarations_array_size']' '['declarations_array_size']'
{
	mp[string($1)] = 3;
}
| declarations_varname
{
	mp[string($1)] = 1;
}
;

declarations_array_size: expression |
;

declarations_varname: VARIABLE
{
	strcpy($$,mytext);
}
;

variable_name:
  VARIABLE
| VARIABLE '['expression']' array_end
;

array_end: 
  '['expression']' | 
;

// assignment can be equal to function calls too :)

// variable initialisation and assignment done

// the main part comes: expression :p

expression: // covers everything from array to simple variables and complex exprsns
	  NUMBER
	| FLOATNUMBER
	| CHARACTER
	| variable_name
	| '-' NUMBER
	| '-' FLOATNUMBER
	| '-' variable_name
	| functioncalls
	| expression '+' expression
	| expression '-' expression
	| expression '*' expression
	| expression '/' expression
	| expression POW expression
	| '(' expression ')'
;

assignments: variable_name EQ expression
;

conditionals: ifbody | ifbody elsebody;

ifbody: 
  IF '(' boolean_expr ')' '{' ifelsecode '}' 
| IF '(' boolean_expr ')' ifelsecode;


elsebody: 
  ELSE '{'ifelsecode'}'
| ELSE ifelsecode
;

ifelsecode: maincode |
; // this is to handle the case for empty body

boolean_expr: boolean_condition | ;
; // this is to handle the case for empty condition

boolean_condition: if_expression comparators if_expression | if_expression
;

if_expression:
	  NUMBER
	| FLOATNUMBER
	| CHARACTER
	| if_variable_name
	| '-' NUMBER
	| '-' FLOATNUMBER
	| '-' if_variable_name
	| functioncalls
	| if_expression '+' if_expression
	| if_expression '-' if_expression
	| if_expression '*' if_expression
	| if_expression '/' if_expression
	| if_expression POW if_expression 
	| '(' if_expression ')'
;

if_variable_name:
  if_variable_name_start '['if_expression']'
  {
	if(mp[string($1)] == 0 || mp[string($1)] == 2)
	{

	}
	else yyerror("hi");
  }
| if_variable_name_start '['if_expression']' '['if_expression']'
{
	if(mp[string($1)] == 0 || mp[string($1)] == 3)
	{

	}
	else yyerror("hi");
}
| if_variable_name_start
{
	if(mp[string($1)] == 0 || mp[string($1)] == 1)
	{

	}
	else yyerror("hi");
}
;
if_variable_name_start: VARIABLE
{
	strcpy($$,mytext);
}
;

dtype:INT|CHAR|FLOAT
;

loops: while_loop | for_loop;

while_loop:
  WHILE '(' boolean_expr ')' '{' ifelsecode '}'
| WHILE '(' boolean_expr ')' ifelsecode;

for_loop:
  FOR '(' for_arg_1 ';' boolean_expr ';' for_arg_3 ')' '{' ifelsecode '}' 
| FOR '(' for_arg_1 ';' boolean_expr ';' for_arg_3 ')' ifelsecode;

for_arg_1: for_arg_1_help | 
;

for_arg_1_help: 
  assignments | expression | for_arg_1_declaration
;

for_arg_1_declaration: dtype declarations_variables
;

for_arg_3: for_arg_1_help | 
;

changing_condition:VARIABLE EQ expression '+' expression | VARIABLE EQ expression '-' expression;
// this^ takes care of v = v + 12 or v = v - 12 or v = 12,.....
 
comparators: DEQ | '<' | '>' | LEQ | GEQ | NEQ;

funtype: VOID | dtype;

return_statements: 
  RETURN expression
| RETURN
;

%%

void yyerror(char *s) {
    /* fprintf(stderr, "%s\n", s); */
    fprintf(stderr, "%d\n", line_num+1);
	exit(0);
}

int main(void) {
    yyparse();
    return 0;
}
