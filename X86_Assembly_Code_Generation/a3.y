%token INT CHAR FLOAT EQ IF ELSE DEQ LEQ GEQ NEQ WHILE RETURN POW OROR ANDAND MAIN HEADER VOID FOR

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
	vector<string>assembly;
	string function_name = "";
	string int_to_str(int num)
	{
		bool is_negative = false;
		if(num < 0)
		{
			is_negative = true;
			num *= -1;
		}
		string str = "";
		while(num)
		{
			str += (num%10) + '0';
			num /= 10;
		}
		reverse(str.begin(),str.end());
		if(is_negative)
		{
			str = "-" + str;
		}
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
	stack<map<string,int>>var_map;
	map<string,int>global_map;

	//
	// Don't forget to pop stack / clear map after the end of functions
	stack<map<string,int>>variables; // used to retrieve the location of variables - done
	map<int,vector<string>>assembly_program; // helps in booleans - done
	stack<int>fun_stack; // size of the program
	bool is_first = true;
	map<string,map<string,int>>fun_parameters_loc; 
	vector<string>printfstrings;
	map<string,bool>is_string; // quoted strings and in .data sections
	map<string,int>string_num;
	vector<string>fun_args;
	map<string,bool>is_global;

	// for char arrays
	map<string,int>scope_char_array; // this tells us whther it is global[1] or local[2] or function[3]
	map<string,int>size_char_array; // this tells us the size of the array
	string arg_name;
	//

	string get_var(string temp)
	{
		if(is_string[temp])
		{
			return "$str" + int_to_str(string_num[temp]);
		}
		else if(is_global[temp])
		{
			return temp;
		}
		int val = variables.top()[temp];
		string str;
		if(val > 0)
		str = "-" + int_to_str(val) + "(%ebp)";
		else if(val < 0)
		{
			str = int_to_str(-val) + "(%ebp)";
		}
		else
		{
			str = "(%ebp)";
		}
		return str;
	}
	bool is_char_assignment = false;
	bool dtypechar = false;
	vector<int>max_offset; // calc max offset of a function subtract from stack altogether store "pffset" in assemby vector and the print there :)
	//
	
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
%type <str> character_assignment
%type <str> variable_name_assignments
%type <num> expression_boolean
%type <num> functioncalls_boolean
%type <num> functioncalls_args_boolean
%type <num> functioncalls_args_help_boolean
%left OROR
%left ANDAND
%left '+' '-' 
%left '*' '/'
%right POW 
%right '!'
%nonassoc '('')'

%%


prog: 
	    HEADER
	  | dtype prog_help 
	  | prog dtype prog_help
	  | prog HEADER
;

prog_help: main_function | function_or_declaration
;

main_function: MAIN '('  
{
	tac.push_back("main:"); 
	param_count = 0;
	map<string,int>mp;
	var_map.push(mp);
	if(is_first)
	{
		is_first = false;
		assembly.push_back(".text");
	}
	assembly.push_back(".globl main");
	assembly.push_back("main:");
	assembly.push_back("pushl %ebp");
	assembly.push_back("movl %esp, %ebp");
	assembly.push_back("offset");
} main_function_help 
;

main_function_help: ')' '{'
	{
		fun_stack.push(0);
		map<string,int>m;
		variables.push(m);		
	} maincode '}' 
	{
		max_offset.push_back(fun_stack.top());
		fun_stack.pop();
		var_map.pop();
		variables.pop();
	} 
	| funargs ')'  '{'
	{
		fun_stack.push(0);
		map<string,int>m;
		variables.push(m);		
	} maincode '}' 
	{
		max_offset.push_back(fun_stack.top());
		fun_stack.pop();
		var_map.pop();
		variables.pop();
	}
;

function_or_declaration: VARIABLE {function_name = $1;} function_or_declaration_help;

function_or_declaration_help: function
{
	fun_args.clear();
}
 | global_declaration
;

global_declaration: 
	EQ 
	{
		tac.push_back("global " + function_name);
		//
		is_global[function_name] = true;
		//
	}
		 expression ';' 
	{
		global_map[function_name] = 1;
		string str = $3;
		tac.push_back(function_name + " = " + str);
	} 
  | ';' 
	{
		global_map[function_name] = 1;
		tac.push_back("global " + function_name);
		//
		is_global[function_name] = true;
		//
	}
	| '[' NUMBER ']' ';'
	{
		global_map[function_name] = 1;
		string str = $2;
		tac.push_back("global " + function_name);
		//
		is_global[function_name] = true;
		scope_char_array[function_name] = 1;
		size_char_array[function_name] = stoi(str);
		//
	}
;

function: 
   '(' 
	{
	if(is_first)
	{
		is_first = false;
		assembly.push_back(".text");
	}
	tac.push_back(function_name + ":"); 
	param_count = 0;
	map<string,int>mp;
	var_map.push(mp);
	assembly.push_back(".globl " + function_name);
	assembly.push_back(function_name + ":");
	assembly.push_back("pushl %ebp");
	assembly.push_back("movl %esp, %ebp");
	assembly.push_back("offset");
	
	fun_stack.push(0);
	map<string,int>m;
	variables.push(m);
	} 
	funargs ')' '{' 
	{	

	} maincode '}' 
	{
		max_offset.push_back(fun_stack.top());
		var_map.pop();
		fun_stack.pop();
		variables.pop();
	}
|  '(' 
	{
	if(is_first)
	{
		is_first = false;
		assembly.push_back(".text");
	}
	tac.push_back(function_name + ":");
	map<string,int>mp;
	var_map.push(mp);
	//
	assembly.push_back(".globl " + function_name);
	assembly.push_back(function_name + ":");
	assembly.push_back("pushl %ebp");
	assembly.push_back("movl %esp, %ebp");
	assembly.push_back("offset");
	//
	}
	 ')' '{'
	 {
		fun_stack.push(0);
		map<string,int>m;
		variables.push(m);		
	} maincode '}' 
	 {
		max_offset.push_back(fun_stack.top());
		var_map.pop();
		fun_stack.pop();
		variables.pop();
	 } 
;


funargs: funargs ',' arg | arg;
 
arg: dtype_fun VARIABLE arg_help {
	string str1 = $2;
	arg_name = str1;
	var_map.top()[str1] = 1;
	string str = $2;
	str = (str + " = param" + int_to_str(++param_count));
	tac.push_back(str);
	fun_args.push_back(str);
	variables.top()[str1] = 4*(1+fun_args.size());
	variables.top()[str1] *= (-1);
	if(dtypechar == true)
	{
		scope_char_array[str1] = 3;
	}
	dtypechar = false;
};

dtype_fun: INT | CHAR {dtypechar = true;}
;

arg_help: '['']' 
{
	scope_char_array[arg_name] = 3;
}
 | 
;

maincode1: maincode1 code | code;

maincode: maincode1 | ;

code: 
  functioncalls ';'
| printf ';'
| declarations ';' // done
| assignments ';' //
| {if_label.push(++temp_label_count);} if_else 
| loops
| return_statements ';'
;

functioncalls:
  VARIABLE {vector<string>v;funcarg.push(v);} '(' functioncalls_args_help ')' 
  {
	vector<string>v1 = funcarg.top();
	for(int i=0;i<v1.size();i++)
	{
		tac.push_back("param"+int_to_str(i+1)+" = "+v1[i]);
	}
	funcarg.pop();
	string strr = $1;
	tac.push_back("call " + strr);
	tac.push_back("t"+int_to_str(++temp_var_count)+" = retval");
	string str = ("t"+int_to_str(temp_var_count));
	$$ = strdup(str.c_str());
	//
	vector<string>v2;
	for(int i=0;i<v1.size();i++)
	{
		v2.push_back(v1[v1.size()-i-1]);
	}
	for(int i=0;i<v2.size();i++)
	{
		assembly.push_back("pushl " + get_var(v2[i]));
	}
	assembly.push_back("call " + strr);
	if(v2.size()!=0)
	assembly.push_back("addl $" + int_to_str(4*v2.size()) + ", %esp");
	int x = fun_stack.top();
	fun_stack.pop();
	fun_stack.push(x+4);
	variables.top()[str] = fun_stack.top();

	// assembly.push_back("subl $" + int_to_str(4) + ", %esp #stored the variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
	assembly.push_back("# stored the variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
	assembly.push_back("movl %eax, " + get_var(str));
	//
  }	
;

functioncalls_args_help: functioncalls_args | ;

functioncalls_args: 
	functioncalls_args ',' expression {vector<string>v1 = funcarg.top(); v1.push_back($3); funcarg.pop(); funcarg.push(v1);}  
  | expression {vector<string>v1 = funcarg.top(); v1.push_back($1); funcarg.pop(); funcarg.push(v1);}
;

printf: PRINT {vector<string>v;funcarg.push(v);} '(' PRINTFSTRINGS 
  {
	string ss = $4;
	printfstrings.push_back(ss);
	tac.push_back("t"+int_to_str(++temp_var_count)+" = "+$4);
	string str = ("t"+int_to_str(temp_var_count)); 
	is_string[str] = true;
	string_num[str] = printfstrings.size();
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
	//
	vector<string>v2;
	for(int i=0;i<v1.size();i++)
	{
		v2.push_back(v1[v1.size()-i-1]);
	}
	for(int i=0;i<v2.size();i++)
	{
		assembly.push_back("pushl " + get_var(v2[i]));
	}
	assembly.push_back("call " + str);
	if(v2.size()!=0)
	assembly.push_back("addl $" + int_to_str(4*v2.size()) + ", %esp");
	//
  }
;

printfarg_help	: printfargs |	
;

printfargs: 
	printfargs ',' expression { vector<string>v1 = funcarg.top(); v1.push_back($3); funcarg.pop(); funcarg.push(v1);} 
  | ',' expression { vector<string>v1 = funcarg.top(); v1.push_back($2); funcarg.pop(); funcarg.push(v1);} ;
;

declarations: 
	INT VARIABLE 
	{
		string str = $2;
		var_map.top()[str] = 1; // for undef variab
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();

		// assembly.push_back("subl $" + int_to_str(4) + ", %esp #stored the variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("# stored the variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
	}
  | CHAR VARIABLE '['NUMBER']'	// local declaration
  {
	string str = $2;
	string s = $4; 
	var_map.top()[str] = 2;
	//
	
	int x = fun_stack.top();
	fun_stack.pop();
	int y = stoi(s);
	fun_stack.push(x+y);
	variables.top()[str] = fun_stack.top();

	// assembly.push_back("subl $" + int_to_str(y) + ", %esp #stored the variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
	assembly.push_back("# stored the variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
	scope_char_array[str] = 2;
	
	//
}
  | INT VARIABLE EQ expression // won't be there
  {
	string str = $2; 
	var_map.top()[str] = 1;
	string str1 = $4;
	tac.push_back(str + " = " + str1);
  }


variable_name:
  VARIABLE 
  {
	$$ = strdup($1);
	string str = $1; 
	if((var_map.top()[str] == 0) && (global_map[str] == 0))
	{
		printf("undefined variable ");
		cout<<str<<endl;
		yyerror("hi");
	}
	}
;

expression: // covers everything from array to simple variables and complex exprsns
	  NUMBER 
	    {
		string str1 = $1;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl $" + str1 + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
		}
	| character_assignment 
		{
		$$ = strdup($1);
		}
	| variable_name 
		{
		string str1 = $1;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		// cout<<"str1 "<<str1<<endl;
		// cout<<"variable "<<variables.top()[str1]<<endl;
		assembly.push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		if(scope_char_array[str1] == 1)
		{
		assembly.push_back("leal " + get_var(str1) + ", %eax");
		}
		else if(scope_char_array[str1] == 2)
		{
		assembly.push_back("movl $0, %eax");
		assembly.push_back("addl %ebp, %eax");
		assembly.push_back("subl $" + int_to_str(variables.top()[str1]) + ", %eax");
		}
		else if(scope_char_array[str1] == 3)
		{
		assembly.push_back("movl $0, %eax");
		assembly.push_back("addl " + int_to_str(-1*variables.top()[str1]) + "(%ebp), %eax");
		}
		else
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
		}
	/* | '-' NUMBER 
		{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl $-" + str1 + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
		}
	| '+' NUMBER 
		{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl $" + str1 + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
		}
	| '-' variable_name 
		{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("imull $-1, %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
		}
	| '+' variable_name
		{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
		} */
	| functioncalls 
	{
		$$ = strdup($1);
	}
	| expression '+' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " + " + str2);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		// assembly.push_back("addl " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("addl " + get_var(str2) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
	}
	| expression '-' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " - " + str2);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("subl " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("subl " + get_var(str2) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
	}
	| expression '*' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " * " + str2);	
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("imull " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("imull " + get_var(str2) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
	}
	| expression '/' expression 
	{
		string str1 = $1;
		string str2 = $3;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1 + " / " + str2); 
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("idivl " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("cdq");
		assembly.push_back("idivl " + get_var(str2) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
	}
	| '-' expression
	{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl $0, %eax");
		assembly.push_back("subl " + get_var(str1) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
	}
	| '+' expression
	{
		string str1 = $2;
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly.push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
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
		$$ = strdup($2);
	}
	| PRINTFSTRINGS 
	{
		string str1 = $1;
		printfstrings.push_back(str1);
		tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		is_string[str] = true;
		string_num[str] = printfstrings.size();

		$$ = strdup(str.c_str());
	}
;

character_assignment: CHARACTER
{
	string str1 = $1;
	if(str1 == "\'\\0\'")
	{
		str1 = "0";
	}
	tac.push_back("t" + int_to_str(++temp_var_count) + " = " + str1); 
	string str = ("t"+int_to_str(temp_var_count)); 
	assembly.push_back("movb $" + str1 + ", %dl");
	$$ = strdup(str.c_str());
}
| VARIABLE '[' expression ']'
{
	string str1 = $1;
	string str2 = $3;
	
	string str = ("t"+int_to_str(++temp_var_count)); 

	// cout<<"hi hi "<<scope_char_array[str1]<<endl;
	// assembly.push_back("hi");
	
	if(scope_char_array[str1] == 1)
	{
		// global
		assembly.push_back("leal " + str1 + ", %eax");
		assembly.push_back("addl " + get_var(str2) + ", %eax");
	}
	else if(scope_char_array[str1] == 2) // same for funcall and locals 
	{
		// local / funcalls
		assembly.push_back("movl %ebp, %eax");
		assembly.push_back("subl $" + int_to_str(variables.top()[str1]) + ", %eax");
		assembly.push_back("addl " + get_var(str2) + ", %eax");
	}
	else
	{
		assembly.push_back("movl " + get_var(str1) + ", %eax");
		assembly.push_back("addl " + get_var(str2) + ", %eax");
	}

	int x = fun_stack.top();
	fun_stack.pop();
	fun_stack.push(x+1);
	variables.top()[str] = fun_stack.top();
	assembly.push_back("movb (%eax), %dl");
	$$ = strdup(str.c_str());
}
;

assignments: variable_name_assignments EQ expression 
{
	string str1 = $1;
	string str2 = $3;
	tac.push_back(str1 + " = " + str2);
	if(is_char_assignment)
	{
		// mov from t[i](expression number) to  al and al to var_name_assignments
		assembly.push_back("movb %dl, (%ebx)");
	}
	else
	{
	int val = variables.top()[str2];
	// cout<<"val "<<val<<endl;
	string str = "-"+int_to_str(val) + "(%ebp)";
	string ss = "movl " + str + ", ";
	// val = fun_declarations.top();
	// cout<<"val "<<val<<endl;
	// val -= variables.top()[str1];
	// str = "-" + int_to_str(val) + "(%ebp)";
	ss += get_var(str1);
	assembly.push_back("movl " + get_var(str2) + ", %eax");
	assembly.push_back("movl %eax, " + get_var(str1));
	}

	is_char_assignment = false;
};

variable_name_assignments:
  VARIABLE 
  {
	$$ = strdup($1);
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
// returns t[i] where ti has the address + offset
	string str = $1;
	string str1 = $3;
	// $$ = strdup(str2.c_str());
	if((var_map.top()[str] == 0) && (global_map[str] == 0))
	{
		printf("undefined variable ");
		cout<<str<<endl;
		yyerror("hi");
	}
	is_char_assignment = true;
	// we have the offset too in expression's t[i]
	if(scope_char_array[str] == 1)
	{
		// global
		assembly.push_back("leal " + str + ", %ebx");
		assembly.push_back("addl " + get_var(str1) + ", %ebx");
		$$ = strdup(str.c_str());
	}
	else if(scope_char_array[str] == 3)
	{
		assembly.push_back("movl " + get_var(str) + ", %ebx");
		assembly.push_back("addl " + get_var(str1) + ", %ebx");
	}
	else // same for funcall and locals 
	{
		// local / funcalls
		// assembly.push_back("movl %ebp, %eax");
		// assembly.push_back("subl $" + int_to_str(variables.top()[str]) + ", %eax");
		// assembly.push_back("addl " + get_var(str1) + ", %eax");

		assembly.push_back("movl " + get_var(str1) + ", %ebx");
		assembly.push_back("addl %ebp, %ebx");
		assembly.push_back("subl $" + int_to_str(variables.top()[str]) + ", %ebx");
		
		string str = ("t"+int_to_str(++temp_var_count));
		// int x = fun_stack.top();
		// fun_stack.pop();
		// fun_stack.push(x+4);
		// variables.top()[str] = fun_stack.top();
		// assembly.push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		$$ = strdup(str.c_str());
	}
		$$ = strdup(str.c_str());
}
;

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
	//
	for(auto it:assembly_program[x])
	{
		assembly.push_back(it);
	}
	assembly.push_back("." + true_label[x] + ":");
	//
}
  '{' maincode '}' 
  {
	tac.push_back("goto L" + int_to_str(if_label.top())); // corrrect
	//
	assembly.push_back("jmp .L" + int_to_str(if_label.top()));
	//
  }
  ;	

  if_end: 
    else_part 
  | 
  {
	tac.push_back(false_label[prev_var.top()] + ":");
	tac.push_back("goto L" + int_to_str(if_label.top()));
	tac.push_back("L" + int_to_str(if_label.top()) + ":");
	//
	assembly.push_back("." + false_label[prev_var.top()] + ":");
	assembly.push_back("jmp .L" + int_to_str(if_label.top()));
	assembly.push_back(".L" + int_to_str(if_label.top()) + ":");
	//
	if_label.pop();
  }

;

else_part: ELSE 
{
	tac.push_back(false_label[prev_var.top()] + ":");
	//
	assembly.push_back("." + false_label[prev_var.top()] + ":");
	//
}
	 else_help;

else_help: '{' maincode '}'
{
	tac.push_back("L" + int_to_str(if_label.top()) + ":");
	//
	assembly.push_back(".L" + int_to_str(if_label.top()) + ":");
	//
	if_label.pop();
}
 | if_else;

expression_boolean: // covers everything from array to simple variables and complex exprsns
// support strings too bcz they may be the parameter for functioncalls
	  NUMBER 
	    {
		string str1 = $1;
		$$ = ++temp_var_count;
		string str = ("t"+int_to_str(temp_var_count)); 
		map_program[$$].push_back("t"+int_to_str(temp_var_count)+" = "+str1);

		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly_program[$$].push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl $" + str1 + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		}
	| variable_name 
		{
		string str1 = $1;
		$$ = ++temp_var_count;
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		// cout<<"str1 "<<str1<<endl;
		// cout<<"variable "<<variables.top()[str1]<<endl;
		assembly_program[$$].push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		if(scope_char_array[str1] == 1)
		{
		assembly_program[$$].push_back("leal " + get_var(str1) + ", %eax");
		}
		else if(scope_char_array[str1] == 2)
		{
		assembly_program[$$].push_back("movl $0, %eax");
		assembly_program[$$].push_back("addl %ebp, %eax");
		assembly.push_back("subl $" + int_to_str(variables.top()[str1]) + ", %eax");
		}
		else if(scope_char_array[str1] == 3)
		{
			assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		}
		else
		{
			assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
	}

		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		}
	/* | '-' NUMBER 
		{
		string str1 = $2;
		$$ = ++temp_var_count;
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly_program[$$].push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl $-" + str1 + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		}
	| '+' NUMBER 
		{
		string str1 = $2;
		$$ = ++temp_var_count;
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly_program[$$].push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl $" + str1 + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		}
	| '-' variable_name 
		{
		string str1 = $2;
		$$ = ++temp_var_count;
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly_program[$$].push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		assembly_program[$$].push_back("imull $-1, %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		}
	| '+' variable_name
		{
		string str1 = $2;
		$$ = ++temp_var_count;
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = " + str1);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		assembly_program[$$].push_back("subl $" + int_to_str(4) + ", %esp #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
		} */
	| functioncalls_boolean 
	{
		$$ = $1;
	}
	| expression_boolean '+' expression_boolean 
	{
		string str1 = "t" + int_to_str($1);
		string str2 = "t" + int_to_str($3);
		$$ = ++temp_var_count;
		for(auto it:map_program[$1])
		{
			map_program[$$].push_back(it);
		}
		for(auto it:map_program[$3])
		{
			map_program[$$].push_back(it);
		}
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = " + str1 + " + " + str2);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		for(auto it:assembly_program[$1])
		{
			assembly_program[$$].push_back(it);
		}
		for(auto it:assembly_program[$3])
		{
			assembly_program[$$].push_back(it);
		}
		assembly_program[$$].push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		// assembly.push_back("addl " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("addl " + get_var(str2) + ", %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
	}
	| expression_boolean '-' expression_boolean 
	{
		string str1 = "t" + int_to_str($1);
		string str2 = "t" + int_to_str($3);
		$$ = ++temp_var_count;
		for(auto it:map_program[$1])
		{
			map_program[$$].push_back(it);
		}		
		for(auto it:map_program[$3])
		{
			map_program[$$].push_back(it);
		}
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = " + str1 + " - " + str2);
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		for(auto it:assembly_program[$1])
		{
			assembly_program[$$].push_back(it);
		}
		for(auto it:assembly_program[$3])
		{
			assembly_program[$$].push_back(it);
		}
		assembly_program[$$].push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("subl " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		assembly_program[$$].push_back("subl " + get_var(str2) + ", %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
	}
	| expression_boolean '*' expression_boolean 
	{
		string str1 = "t" + int_to_str($1);
		string str2 = "t" + int_to_str($3);
		$$ = ++temp_var_count;
		for(auto it:map_program[$1])
		{
			map_program[$$].push_back(it);
		}
		for(auto it:map_program[$3])
		{
			map_program[$$].push_back(it);
		}
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = " + str1 + " * " + str2);	
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		for(auto it:assembly_program[$1])
		{
			assembly_program[$$].push_back(it);
		}
		for(auto it:assembly_program[$3])
		{
			assembly_program[$$].push_back(it);
		}
		assembly_program[$$].push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("imull " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		assembly_program[$$].push_back("imull " + get_var(str2) + ", %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
	}
	| expression_boolean '/' expression_boolean 
	{
		string str1 = "t" + int_to_str($1);
		string str2 = "t" + int_to_str($3);
		$$ = ++temp_var_count;
		for(auto it:map_program[$1])
		{
			map_program[$$].push_back(it);
		}
		for(auto it:map_program[$3])
		{
			map_program[$$].push_back(it);
		}
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = " + str1 + " / " + str2); 
		string str = ("t"+int_to_str(temp_var_count)); 
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		for(auto it:assembly_program[$1])
		{
			assembly_program[$$].push_back(it);
		}
		for(auto it:assembly_program[$3])
		{
			assembly_program[$$].push_back(it);
		}		
		assembly_program[$$].push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("movl " + get_var(str1) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		// assembly.push_back("idivl " + get_var(str2) + ", -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		assembly_program[$$].push_back("cdq");
		assembly_program[$$].push_back("idivl " + get_var(str2) + ", %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
	}
	| '-' expression_boolean
	{
		string str1 = "t" + int_to_str($2);
		$$ = ++temp_var_count;
		for(auto it:map_program[$2])
		{
			map_program[$$].push_back(it);
		}	
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count));
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		for(auto it:assembly_program[$2])
		{
			assembly_program[$$].push_back(it);
		}

		assembly_program[$$].push_back("#stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl $0, %eax");
		assembly_program[$$].push_back("subl " + get_var(str1) + ", %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
	}
	| '+' expression_boolean
	{
		string str1 = "t" + int_to_str($2);
		$$ = ++temp_var_count;
		for(auto it:map_program[$2])
		{
			map_program[$$].push_back(it);
		}	
		map_program[$$].push_back("t" + int_to_str(temp_var_count) + " = -" + str1);
		string str = ("t"+int_to_str(temp_var_count));
		int x = fun_stack.top();
		fun_stack.pop();
		fun_stack.push(x+4);
		variables.top()[str] = fun_stack.top();
		for(auto it:assembly_program[$2])
		{
			assembly_program[$$].push_back(it);
		}

		assembly_program[$$].push_back(" #stored variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
		assembly_program[$$].push_back("movl " + get_var(str1) + ", %eax");
		assembly_program[$$].push_back("movl %eax, -" + int_to_str(fun_stack.top()) + "(%ebp)");
	}
	| '(' expression_boolean ')' 
	{
		$$ = $2;
	}
;

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

			//
			vector<string>code_assembly;
			for(auto it:assembly_program[x1])
			{
				code_assembly.push_back(it);
			}
			code_assembly.push_back("." + true_label[x1] + ":");
			for(auto it:assembly_program[x2])
			{
				code_assembly.push_back(it);
			}
			code_assembly.push_back("." + false_label[x1] + ":");
			code_assembly.push_back("jmp .L" + int_to_str(new_false_label));
			code_assembly.push_back("." + false_label[x2] + ":");
			code_assembly.push_back("jmp .L" + int_to_str(new_false_label));
			assembly_program[x] = code_assembly;
			//
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
		//
		vector<string>code_assembly;
		for(auto it:assembly_program[x1])
		{
			code_assembly.push_back(it);
		}
		code_assembly.push_back("." + true_label[x1] + ":");
		code_assembly.push_back("jmp .L" + int_to_str(new_true_label));
		code_assembly.push_back("." + false_label[x1] + ":");
		for(auto it:assembly_program[x2])
		{
			code_assembly.push_back(it);
		}
		code_assembly.push_back("." + true_label[x2] + ":");
		code_assembly.push_back("jmp .L" + int_to_str(new_true_label));
		code_assembly.push_back("." + false_label[x2] + ":");
		code_assembly.push_back("jmp .L" + int_to_str(new_false_label));
		assembly_program[x] = code_assembly;
		//

	  }
	  | expression_boolean comparators expression_boolean 
	  {
		string str1 = "t" + int_to_str($1);
		string str2 = "t" + int_to_str($3);
		int x = ++temp_var_count;
		true_label[x] = "L" + int_to_str(++temp_label_count);
		// cout<<true_label[x]<<endl;
		false_label[x] = "L" + int_to_str(++temp_label_count);
		for(auto it:map_program[$1])
		{
			map_program[x].push_back(it);
		}
		for(auto it:map_program[$3])
		{
			map_program[x].push_back(it);
		}
		map_program[x].push_back("t" + int_to_str(x) + " = " + str1 + " " + comparator + " " + str2);
		map_program[x].push_back("if (t" + int_to_str(x) + ") goto " + true_label[x]);
		map_program[x].push_back("goto " + false_label[x]);
		
		tempvarcnt[x] = int_to_str(x);
		//
		// No need to store the new temp variable here bcz direct condition evaluation is there
		for(auto it:assembly_program[$1])
		{
			assembly_program[x].push_back(it);
		}
		for(auto it:assembly_program[$3])
		{
			assembly_program[x].push_back(it);
		}
		if(comparator == "==")
		{
			assembly_program[x].push_back("movl " + get_var(str1) + ", %eax");
			assembly_program[x].push_back("cmpl " + get_var(str2) + ", %eax");
			assembly_program[x].push_back("je ." + true_label[x]);
			assembly_program[x].push_back("jmp ." + false_label[x]);
		}
		else if(comparator == "<")
		{
			assembly_program[x].push_back("movl " + get_var(str1) + ", %eax");
			assembly_program[x].push_back("cmpl " + get_var(str2) + ", %eax");
			assembly_program[x].push_back("jl ." + true_label[x]);
			assembly_program[x].push_back("jmp ." + false_label[x]);
		}
		else if(comparator == ">")
		{
			assembly_program[x].push_back("movl " + get_var(str1) + ", %eax");
			assembly_program[x].push_back("cmpl " + get_var(str2) + ", %eax");
			assembly_program[x].push_back("jg ." + true_label[x]);
			assembly_program[x].push_back("jmp ." + false_label[x]);
		}
		else if(comparator == "<=")
		{
			assembly_program[x].push_back("movl " + get_var(str1) + ", %eax");
			assembly_program[x].push_back("cmpl " + get_var(str2) + ", %eax");
			assembly_program[x].push_back("jle ." + true_label[x]);
			assembly_program[x].push_back("jmp ." + false_label[x]);
		}
		else if(comparator == ">=")
		{
			assembly_program[x].push_back("movl " + get_var(str1) + ", %eax");
			assembly_program[x].push_back("cmpl " + get_var(str2) + ", %eax");
			assembly_program[x].push_back("jge ." + true_label[x]);
			assembly_program[x].push_back("jmp ." + false_label[x]);
		}
		else if(comparator == "!=")
		{
			assembly_program[x].push_back("movl " + get_var(str1) + ", %eax");
			assembly_program[x].push_back("cmpl " + get_var(str2) + ", %eax");
			assembly_program[x].push_back("jne ." + true_label[x]);
			assembly_program[x].push_back("jmp ." + false_label[x]);
		}
		//
		$$ = x;
	  }

;

functioncalls_boolean:
  VARIABLE {vector<string>v;funcarg.push(v);} '(' functioncalls_args_help_boolean ')' 
  {
	$$ = ++temp_var_count;
	string str = ("t"+int_to_str(temp_var_count));
	vector<string>v1 = funcarg.top();
	for(int i=0;i<v1.size();i++)
	{
		map_program[$$].push_back("param"+int_to_str(i+1)+" = "+v1[i]);
	}
	funcarg.pop();
	string strr  = $1;
	map_program[$$].push_back("call " + strr);
	map_program[$$].push_back("t"+int_to_str(temp_var_count)+" = retval");
	//
	vector<string>v2;
	for(int i=0;i<v1.size();i++)
	{
		v2.push_back(v1[v1.size()-i-1]);
	}
	for(auto it:assembly_program[$4])
	{
		assembly_program[$$].push_back(it);
	}
	for(int i=0;i<v2.size();i++)
	{
		assembly_program[$$].push_back("pushl " + get_var(v2[i]));
	}
	assembly_program[$$].push_back("call " + strr);
	if(v2.size()!=0)
	assembly_program[$$].push_back("addl $" + int_to_str(4*v2.size()) + ", %esp");
	int x = fun_stack.top();
	fun_stack.pop();
	fun_stack.push(x+4);
	variables.top()[str] = fun_stack.top();

	assembly_program[$$].push_back(" #stored the variable " + str + " at -" + int_to_str(fun_stack.top()) + "(%ebp)");
	assembly_program[$$].push_back("movl %eax, " + get_var(str));
	//
  }	
;

functioncalls_args_help_boolean: functioncalls_args_boolean{$$ = $1;} | {$$ = ++temp_var_count;};

functioncalls_args_boolean: 
	functioncalls_args_boolean ',' expression_boolean 
	{
	vector<string>v1 = funcarg.top();
	v1.push_back("t"+int_to_str($3)); 
	funcarg.pop(); funcarg.push(v1);
	$$ = ++temp_var_count;
	for(auto it:assembly_program[$1])
	{
		assembly_program[$$].push_back(it);
	}
	for(auto it:assembly_program[$3])
	{
		assembly_program[$$].push_back(it);
	}
	}  
  | expression_boolean 
  {
	vector<string>v1 = funcarg.top(); 
	v1.push_back("t"+int_to_str($1)); 
	funcarg.pop(); 
	funcarg.push(v1);
	$$ = ++temp_var_count;
	for(auto it:assembly_program[$1])
	{
		assembly_program[$$].push_back(it);
	}
  }
;


dtype:INT|CHAR|FLOAT
;

loops: while_loop;

while_loop:
  WHILE 
  {
	while_label.push(++temp_label_count);
	tac.push_back("L" + int_to_str(while_label.top()) + ":");
	//
	assembly.push_back(".L" + int_to_str(while_label.top()) + ":");
	//
  }
   '(' boolean_expr ')' 
   {
	int x = $4;
	for(auto it:map_program[x])
	{
		tac.push_back(it);
	}
	tac.push_back(true_label[x] + ":");
	//
	for(auto it:assembly_program[x])
	{
		assembly.push_back(it);
	}
	assembly.push_back("." + true_label[x] + ":");
	//
   }
   '{' maincode '}'
   {
		tac.push_back("goto L" + int_to_str(while_label.top()));
		int x = $4;
		tac.push_back(false_label[x] + ":");
		//
		assembly.push_back("jmp .L" + int_to_str(while_label.top()));
		assembly.push_back("." + false_label[x] + ":");
		//
		while_label.pop();
   }
;

comparators: DEQ {comparator = "==";} | '<' {comparator = "<";} | '>' {comparator = ">";} | LEQ {comparator = "<=";} | GEQ{comparator = ">=";} | NEQ {comparator = "!=";};

return_statements: 
  RETURN expression 
  {
	string str = $2;
	tac.push_back("retval = " + str);
	tac.push_back("return");
	assembly.push_back("movl " + get_var(str) + ", %eax");
	assembly.push_back("leave");
	assembly.push_back("ret");
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
	/* for(auto it:tac)cout<<it<<endl; */
	cout<<".data"<<endl;
	cout<<"str0: .asciz \"CS3300\""<<endl;
	int cnt = 0;
	for(auto it:printfstrings)
	{
		cout<<"str"<<++cnt<<": .asciz "<<it<<""<<endl;
	}
	vector<string>temp;
	for(auto it: is_global)
	{
		if(it.second)
		{
			temp.push_back(it.first);
		}
	}
	if(temp.size() > 0)
	{
		cout<<".bss"<<endl;
		for(auto it:temp)
		{
			if(size_char_array[it] == 0)
			cout<<it<<": .space 4"<<endl;
			else cout<<it<<": .space "<<size_char_array[it]<<endl;
		}
	}
	int count = 0;
	for(auto it:assembly)
	{
		if(it == "offset")
		{
			cout<<"subl $" + int_to_str(max_offset[count++]) + ", %esp"<<endl;
		}
		else
		cout<<it<<endl;
	}
    return 0;
}