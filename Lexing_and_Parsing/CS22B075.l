%{
	#include <stdlib.h>
	#include <bits/stdc++.h>
	using namespace std;
	#include "y.tab.h"
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

printf		{ return PRINT; }

if		{ return IF;}

else		{ return ELSE;}

while		{ return WHILE;}

for			{ return FOR;}

return		{return RETURN;}

[a-zA-Z_][a-zA-Z_0-9]*	{var_name = strdup(yytext);strcpy(mytext,yytext);return VARIABLE; }

"="		{ return EQ; }

"=="	{ return DEQ;}

"!="	{ return NEQ;}

">="	{ return GEQ;}

"<="	{ return LEQ;}

"**"	{return POW;} 

[\+\*\-\/]		{ return *yytext; }

[0-9]+		{ return NUMBER; }

[0-9]+[.][0-9]+	{return FLOATNUMBER;}

[\{\}]		{ return *yytext;}

[\(\)]		{ return *yytext;}

[\[\]]		{ return *yytext;}

[\!\<\>]		{ return *yytext;}

\;		{ return ';'; }

\,		{ return ','; }

\"[^"]*\"		{return PRINTFSTRINGS;} 

\/\/.*			{return COMMENTS;}

\'[^\']\'		{return CHARACTER;}

[\n]	{line_num++;}

[ \t\r]	{}

.	{yyerror("unknown character");}
%%

int yywrap(void) {
    return 1;
}

