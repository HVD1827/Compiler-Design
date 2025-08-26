%token INT CHAR FLOAT EQ IF ELSE DEQ LEQ GEQ NEQ WHILE FOR VOID RETURN POW OROR ANDAND MAIN
%token COMMENTS 
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
	map<string,int>type_map; // 0 for int and 1 for string
	map<string,int>size_map; 
	int temp_var_count = 0;
	int temp_label_count = 0;
	int param_count = 0;
	string cur_var = "";
	vector<string>tac;
	string function_name = "";
	string int_to_str(int num)
	{
		string str = "";
		while(num)
		{
			str += (num%10) + '0';
			num /= 10;
		}
		reverse(str.begin(),str.end());
		return str;
	}
	stack<vector<string>>funcarg;
	map<int,vector<string>>map_program;
	map<int,string>true_label;
	map<int,string>false_label;
	map<int,string>tempvarcnt;
	string comparator;
	stack<int>prev_var;
	stack<int>if_label;
	stack<int>while_label;
	stack<int>for_label;
	stack<int>for_start;
	stack<int>for_end;
	stack<map<string,int>>var_map;
	map<string,int>global_map;
%}


%union
{
	char *str;
	int num;
}

%token <str> NUMBER
%token <str> PRINT
%token <str> CHARACTER	
%token <str> VARIABLE
%token <str> PRINTFSTRINGS
%type <str> variable_name
%type <str> expression
%type <str> functioncalls
%type <num> boolean_expr
%left OROR
%left ANDAND
%right '!'
%left '+' '-' 
%left '*' '/'
%right POW 
%nonassoc '('')'

%%

prog: 
		COMMENTS 
	  | dtype prog_help 
	  | prog COMMENTS
	  | prog dtype prog_help
;

prog_help: main_function | function_or_declaration
;

main_function: MAIN '('  
{
	tac.push_back("main:"); 
	param_count = 0;
	map<string,int>mp;
	var_map.push(mp);
} main_function_help 
;

main_function_help: ')' '{' maincode '}' {var_map.pop();} | 
funargs ')'  '{' maincode '}' {var_map.pop();}
;

function_or_declaration: VARIABLE {function_name = $1;} function_or_declaration_help;

function_or_declaration_help: function | global_declaration
;

global_declaration: 
	EQ {tac.push_back("global " + function_name);} expression ';' 
	{
		global_map[function_name] = 1;
		string str = $3;
		tac.push_back(function_name + " = " + str);
	} 
  | ';' 
	{
		global_map[function_name] = 1;
		tac.push_back("global " + function_name);
	}
	| '[' expression ']' ';'
	{
		global_map[function_name] = 1;
		string str = $2;
		tac.push_back("global " + function_name);
	}
;

function: 
   '(' 
	{
	tac.push_back(function_name + ":"); 
	param_count = 0;
	map<string,int>mp;
	var_map.push(mp);
	} 
	funargs ')' '{' maincode '}' {var_map.pop();}
|  '(' 
	{
	tac.push_back(function_name + ":");
	map<string,int>mp;
	var_map.push(mp);
	}
	 ')' '{' maincode '}' {var_map.pop();} 
;


funargs: funargs ',' arg | arg;
 
arg: dtype VARIABLE arg_help {
	string str1 = $2;
	var_map.top()[str1] = 1;
	string str = $2;
	str = (str + " = param" + int_to_str(++param_count));
	tac.push_back(str);
};

arg_help: '['']' | '['expression']' | 
;

maincode1: maincode1 code | code;

maincode: maincode1 | ;

code: 
  functioncalls ';'
| printf ';'
| declarations ';'
| assignments ';'
| {if_label.push(++temp_label_count);} if_else 
| loops
| return_statements ';'
| COMMENTS
;

functioncalls:
  VARIABLE {vector<string>v;funcarg.push(v);} '(' functioncalls_args_help ')' 
  {
	vector<string>v1 = funcarg.top();
	for(int i=0;i<v1.size();i++)
	{
		// cout<<"param"<<(i+1)<<" = "<<v1[i]<<endl;
		tac.push_back("param"+int_to_str(i+1)+" = "+v1[i]);
	}
	funcarg.pop();
	string strr = $1;
	tac.push_back("call " + strr);
	// cout<<"call "<<$1<<endl;
	tac.push_back("t"+int_to_str(++temp_var_count)+" = retval");
	// cout<<"t"<<(++temp_var_count)<<" = retval"<<endl;
	string str = ("t"+int_to_str(temp_var_count));
	$$ = strdup(str.c_str());
  }	
;

functioncalls_args_help: functioncalls_args | ;

functioncalls_args: 
	functioncalls_args ',' expression {vector<string>v1 = funcarg.top(); v1.push_back($3); funcarg.pop(); funcarg.push(v1);}  
  | expression {vector<string>v1 = funcarg.top(); v1.push_back($1); funcarg.pop(); funcarg.push(v1);}
;



printf:
  PRINT {vector<string>v;funcarg.push(v);} '(' PRINTFSTRINGS 
  {
	tac.push_back("t"+int_to_str(++temp_var_count)+" = "+$4);
	string str = ("t"+int_to_str(temp_var_count)); 
	vector<string>v1 = funcarg.top(); 
	v1.push_back(str); 
	funcarg.pop(); 
	funcarg.push(v1);
} 
	printfarg_help ')'
  {
	vector<string>v1 = funcarg.top();
	for(int i=0;i<v1.size();i++)
	{
		tac.push_back("param"+int_to_str(i+1)+" = "+v1[i]);
	}
	funcarg.pop();
	string str = $1;
	tac.push_back("call " + str);
  }
;

printfarg_help	: printfargs |	
;

printfargs: 
	printfargs ',' expression { vector<string>v1 = funcarg.top(); v1.push_back($3); funcarg.pop(); funcarg.push(v1);} 
  | ',' expression { vector<string>v1 = funcarg.top(); v1.push_back($2); funcarg.pop(); funcarg.push(v1);} ;


declarations: 
	INT VARIABLE {string str = $2; var_map.top()[str] = 1;}
  | CHAR VARIABLE '['NUMBER']'	{string str = $2; var_map.top()[str] = 2;}
  | INT VARIABLE EQ expression 
  {
	string str = $2; 
	var_map.top()[str] = 1;
	string str1 = $4;
	tac.push_back(str + " = " + str1);
  }


variable_name:
  VARIABLE 
  {
	$$ = $1;
	string str = $1; 
	if((var_map.top()[str] == 0) && (global_map[str] == 0))
	{
		printf("undefined variable ");
		cout<<str<<endl;
		yyerror("hi");
	}
	}
| VARIABLE '['expression']' 
{
	string str = $1;
	string str1 = $3;
	string str2 = str + "[" + str1 + "]";
	$$ = strdup(str2.c_str());
	if((var_map.top()[str] == 0) && (global_map[str] == 0))
	{
		printf("undefined variable ");
		cout<<str<<endl;
		yyerror("hi");
	}
}
;

// assignment can be equal to function calls too :)

// variable initialisation and assignment done

// the main part comes: expression :p

expression: // covers everything from array to simple variables and complex exprsns
	  NUMBER 
	  {
		string str1 = $1;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| CHARACTER 
	{
		string str1 = $1;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1); 
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| variable_name 
	{
		string str1 = $1;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| '-' NUMBER 
	{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| '-' variable_name 
	{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| functioncalls 
	{
		$$ = $1;
	}
	| expression '+' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " + " + str2);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| expression '-' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " - " + str2);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| expression '*' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " * " + str2);	
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| expression '/' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " / " + str2); 
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| expression POW expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " ** " + str2);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
	| '(' expression ')' 
	{
		$$ = $2;
		}
	| PRINTFSTRINGS 
	{
		string str1 = $1;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		$$ = strdup(str.c_str());
		}
;

assignments: variable_name EQ expression 
{
	string str1 = $1;
	string str2 = $3;
	tac.push_back(str1 + " = " + str2);
};

if_else: if_start if_end {prev_var.pop();}
;

if_start: IF '(' boolean_expr ')' 
{
	int x = $3;
	prev_var.push(x);
	for(auto it:map_program[x])
	{
		tac.push_back(it);
	}
	tac.push_back(true_label[x] + ":");
}
  '{' maincode '}' 
  {
	tac.push_back("goto L" + int_to_str(if_label.top())); // corrrect
	// tac.push_back(false_label[prev_var] + ":");
  }
  ;	

  if_end: 
    else_part 
  | 
  {
	tac.push_back(false_label[prev_var.top()] + ":");
	tac.push_back("goto L" + int_to_str(if_label.top()));
	tac.push_back("L" + int_to_str(if_label.top()) + ":");
	if_label.pop();
  }

;

else_part: ELSE {tac.push_back(false_label[prev_var.top()] + ":");} else_help;

else_help: '{' maincode '}'
{
	tac.push_back("L" + int_to_str(if_label.top()) + ":");
	if_label.pop();
}
 | if_else;


boolean_expr: 
		boolean_expr ANDAND boolean_expr 
		{
			int x1 = $1;
			int x2 = $3;
			int x = ++temp_var_count;
			vector<string>code;
			for(auto it:map_program[x1])
			{
				code.push_back(it);
			}
			code.push_back(true_label[x1] + ":");
			for(auto it:map_program[x2])
			{
				code.push_back(it);
			}
			int new_false_label = (++temp_label_count);
			code.push_back(false_label[x1] + ":");
			code.push_back("goto L"+int_to_str(new_false_label));
			code.push_back(false_label[x2] + ":");
			code.push_back("goto L"+int_to_str(new_false_label));
			$$ = x;
			tempvarcnt[x] = int_to_str(x);
			map_program[x] = code;
			true_label[x] = true_label[x2];
			false_label[x] = "L" + int_to_str(new_false_label);
		}
	  |	'!' boolean_expr
	  {
		$$ = $2;
		int x = $2;
		string str = true_label[x];
		true_label[x] = false_label[x];
		false_label[x] = str;
	  }
	  | '(' boolean_expr ')'
	  {
		$$ = $2;
	  }
	  | boolean_expr OROR boolean_expr  
	  {
		int x1 = $1;
		int x2 = $3;
		int x = ++temp_var_count; 
		vector<string>code;
		for(auto it:map_program[x1])
		{
			code.push_back(it);
		}
		code.push_back(true_label[x1] + ":");
		int new_true_label = ++temp_label_count;
		code.push_back("goto L" + int_to_str(new_true_label));
		code.push_back(false_label[x1] + ":");
		for(auto it:map_program[x2])
		{
			code.push_back(it);
		}
		code.push_back(true_label[x2] + ":");
		code.push_back("goto L" + int_to_str(new_true_label));
		code.push_back(false_label[x2] + ":");
		int new_false_label = ++temp_label_count;
		code.push_back("goto L" + int_to_str(new_false_label));

		$$ = x;
		tempvarcnt[x] = "t"+int_to_str(x);
		map_program[x] = code;
		true_label[x] = "L" + int_to_str(new_true_label);
		false_label[x] = "L" + int_to_str(new_false_label);


	  }
	  | expression comparators expression 
	  {
		string str1 = $1;
		string str2 = $3;
		int x = ++temp_var_count;
		true_label[x] = "L" + int_to_str(++temp_label_count);
		// cout<<true_label[x]<<endl;
		false_label[x] = "L" + int_to_str(++temp_label_count);

		map_program[x].push_back("t" + int_to_str(x) + " = " + str1 + " " + comparator + " " + str2);
		map_program[x].push_back("if (t" + int_to_str(x) + ") goto " + true_label[x]);
		map_program[x].push_back("goto " + false_label[x]);
		
		tempvarcnt[x] = int_to_str(x);
		$$ = x;
	  }

;

dtype:INT|CHAR|FLOAT
;

loops: while_loop | for_loop;

while_loop:
  WHILE 
  {
	while_label.push(++temp_label_count);
	tac.push_back("L" + int_to_str(while_label.top()) + ":");
	}
   '(' boolean_expr ')' 
   {
	int x = $4;
	for(auto it:map_program[x])
	{
		tac.push_back(it);
	}
	tac.push_back(true_label[x] + ":");
   }
   '{' maincode '}'
   {
		tac.push_back("goto L" + int_to_str(while_label.top()));
		while_label.pop();
		int x = $4;
		tac.push_back(false_label[x] + ":");
   }
;

for_loop:
  FOR '(' for_arg_1 ';' 
  {
	for_label.push(++temp_label_count);
	tac.push_back("L" + int_to_str(for_label.top()) + ":");
  } 
  boolean_expr
  {
	int x = $6;
	for(auto it:map_program[x])
	{
		tac.push_back(it);
	}
	// tac.push_back(true_label[x] + ":"); 
	for_start.push(tac.size());				
  }
   ';' for_arg_3  ')' {for_end.push(tac.size());} '{' maincode '}'
   {
		int diff = (for_end.top() - for_start.top());
		vector<string>temp;
		for(int i=0;i<diff;i++)
		{
			temp.push_back(tac[for_start.top()]);
			tac.erase(tac.begin() + for_start.top());
		}
		vector<string>temp1;
		while(tac.size() > for_start.top())
		{
			temp1.push_back(tac[for_start.top()]);
			tac.erase(tac.begin() + for_start.top());
		}
		int x = $6;
		tac.push_back(true_label[x] + ":");
		for(auto it:temp1)
		{
			tac.push_back(it);
		}
		for(auto it:temp)
		{
			tac.push_back(it);
		}
		tac.push_back("goto L" + int_to_str(for_label.top()));
		for_label.pop();
		tac.push_back(false_label[x] + ":");
		for_start.pop();
		for_end.pop();
   } 

for_arg_1: for_arg_1_help | 
;

for_arg_1_help: 
  assignments
;

for_arg_3: for_arg_3_help | 
;

for_arg_3_help: assignments

 
comparators: DEQ {comparator = "==";} | '<' {comparator = "<";} | '>' {comparator = ">";} | LEQ {comparator = "<=";} | GEQ{comparator = ">=";} | NEQ {comparator = "!=";};

return_statements: 
  RETURN expression 
  {
	string str = $2;
	tac.push_back("retval = " + str);
	tac.push_back("return");
	}
;

%%
 
void yyerror(char *s) {
    /* fprintf(stderr, "%s\n", s); */
    /* fprintf(stderr, "%d\n", line_num+1); */
	exit(0);
}

int main(void) {
    yyparse();
	for(auto it:tac)
	{
		if  ( it != "breaking string")
		cout<<it<<endl;
	}
    return 0;
}