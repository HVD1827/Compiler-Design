%{
	#include <stdlib.h>
	#include <bits/stdc++.h>
	using namespace std;
	#include "a2.tab.h"
	void yyerror(char *);
	extern char mytext[];
	extern int line_num;
	extern char* var_name;
%}

%%

void		{ return VOID;}

int		{ return INT;}

char		{ return CHAR;}

float		{ return FLOAT;}

printf		{ yylval.str = strdup(yytext); return PRINT; }

if		{ return IF;}

else		{ return ELSE;}

while		{ return WHILE;}

for			{ return FOR;}

return		{return RETURN;}

main		{ return MAIN;}

[a-zA-Z_][a-zA-Z_0-9]*	{yylval.str = strdup(yytext);strcpy(mytext,yytext);return VARIABLE; }

"="		{ return EQ; }

"=="	{ return DEQ;}

"!="	{ return NEQ;}

">="	{ return GEQ;}

"<="	{ return LEQ;}

"**"	{return POW;} 

"||"	{return OROR;}

"&&"	{return ANDAND;}

[\+\*\-\/]		{ return *yytext; }

[0-9]+		{ yylval.str = strdup(yytext);return NUMBER; }

[\{\}]		{ return *yytext;}

[\(\)]		{ return *yytext;}

[\[\]]		{ return *yytext;}

[\!\<\>]		{ return *yytext;}

\;		{ return ';'; }

\,		{ return ','; }

\"[^"]*\"		{yylval.str = strdup(yytext); return PRINTFSTRINGS;} 

\/\/.*			{return COMMENTS;}

\'[^\']\'		{yylval.str = strdup(yytext);return CHARACTER;}

[\n]	{line_num++;}

[ \t\r]	{}

.	{yyerror("unknown character");}
%%

int yywrap(void) {
    return 1;
}
