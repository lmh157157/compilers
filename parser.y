%{
	#include"tree.h"
	#include"parser.h"
	extern int yylex();
	int yyerror(const char* msg);
%}

%union{
	char* str;
	class Node* node;
}
%token<node>NUMBER
%token<node>ID
%token<node>RETURN SELFPLUS SELFMINUS LP RP PRINT IF FOR WHILE MAIN
%token RETURN MAIN VOID PLUS MINUS MULTIPLY DIVIDE POW MODEL PRINT
%token INT IF ELSE WHILE FOR PRINTF SCANF ASSIGN 
%token LP RP LBRACE RBRACE LMB RMB SEMICOLON ERROR
%token GREATER LESS NEQUAL EQUAL NOT GREATEREQ LESSEQ
%type<node> CompoundK Content Conclude Var Expr Type
%type<node> Opnum OpnumNull VarOpnum RepeatK Condition IDdec Const s ReturnStmt Writek ForHeader Readk

%nonassoc LOWEST //解决去掉一些东西后相关的冲突，额外定义的终结符
%right ASSIGN
%left EQUAL NEQUAL
%left GREATER LESS GREATEREQ LESSEQ
%left PLUS MINUS
%left MULTIPLY DIVIDE MODEL
%right POW
%nonassoc RETURN PRINT SCANF IF FOR WHILE INT RBRACE
%right SELFPLUS SELFMINUS NOT

%left LP RP
%nonassoc ID NUMBER //当读到return时用来先移进number和id后归约return
%nonassoc LBRACE
%nonassoc ELSE //解决else相关的冲突
%nonassoc SEMICOLON //解决去掉分号后的表达式归约移进相关的冲突

%%
 /* 开始符号 */
s : 	INT MAIN LP RP CompoundK 
{$$=$5;returnError($$, $$, true);print($$, 2);}
	|	INT MAIN RP CompoundK 
{$$=$4;returnError($$, $$, true);cout<<"need a '(' in line "<<$2->line<<" col "<<$2->col<<endl;print($$, 2);}
	|	INT MAIN LP CompoundK 
{$$=$4;returnError($$, $$, true);cout<<"need a ')' in line "<<$3->line<<" col "<<$3->col<<endl;print($$, 2);}
	|	INT MAIN CompoundK 
{$$=$3;returnError($$, $$, true);cout<<"need a '(' and a ')' in line "<<$2->line<<" col "<<$2->col<<endl;print($$, 2);}
	|	VOID MAIN LP RP CompoundK 
{$$=$5;returnError($$, $$, false);print($$, 2);}
	|	VOID MAIN RP CompoundK 
{$$=$4;returnError($$, $$, true);cout<<"need a '(' in line "<<$2->line<<" col "<<$2->col<<endl;print($$, 2);}
	|	VOID MAIN LP CompoundK 
{$$=$4;returnError($$, $$, true);cout<<"need a ')' in line "<<$3->line<<" col "<<$3->col<<endl;print($$, 2);}
	|	VOID MAIN CompoundK 
{$$=$3;returnError($$, $$, true);cout<<"need a '(' and a ')' in line "<<$2->line<<" col "<<$2->col<<endl;print($$, 2);}
	;


 /* 大括号包起来的部分*/
CompoundK :		LBRACE Content RBRACE {$$=$2;}
	|			LBRACE RBRACE {$$=new Node("CompoundK statement", 0);}
	/* 缺右括号 */
	|			LBRACE Content %prec LOWEST
	{$$=$2;cout<<"need a '}' in line "<<$$->line<<" col "<<$$->col<<endl;}
	|			LBRACE %prec LOWEST
	{$$=new Node("CompoundK statement", 0);cout<<"need a '}' in line "<<$$->line<<" col "<<$$->col<<endl;}
	
	;

 /* 大括号里包含的内容*/
Content :		Conclude		
		{$$=new Node("CompoundK statement", 0);insertChildren($$,$1,new Node("$", 0));}
	|			Content Conclude	
		{insertChildren($$,$2,new Node("$", 0));}
	;
 /* 大括号里包含的内容的具体归纳 */
Conclude :		Var	SEMICOLON		{$$=$1;}
	|			Var					{$$=$1;cout<<"need a ';' in line "<<$$->line<<" col "<<$$->col<<endl;}
	|			Opnum SEMICOLON		{$$=$1;}
	|			Opnum %prec LOWEST	{$$=$1;cout<<"need a ';' in line "<<$$->line<<" col "<<$$->col<<endl;}
	|			RepeatK				{$$=$1;}
	|			Condition			{$$=$1;}
	|			ReturnStmt			{$$=$1;}
	|			Writek				{$$=$1;}
	|			Readk				{$$=$1;}
	;
 
 /* 输出的语句 */
Writek :		PRINT OpnumNull SEMICOLON 
	{$$=new Node("Writek statement", 0);insertChildren($$, $2, new Node("$", 0));
	if($2->key == "NULL")cout<<"need a expr in line "<<$2->line<<" col "<<$2->col<<endl;}
	|			PRINT OpnumNull/*缺少分号*/
	{$$=new Node("Writek statement", 0);insertChildren($$, $2, new Node("$", 0));
	if($2->key == "NULL")cout<<"need a expr in line "<<$2->line<<" col "<<$2->col<<endl;
	cout<<"need a ';' in line "<<$2->line<<" col "<<$2->col<<endl;}
	;

Readk :			SCANF IDdec SEMICOLON
	{$$=new Node("Readk statement,", 0); insertChildren($$, $2, new Node("$", 0));}
	|			SCANF IDdec
	{$$=new Node("Readk statement,", 0); insertChildren($$, $2, new Node("$", 0));
	cout<<"need a ';' in line "<<$2->line<<" col "<<$2->col<<endl;}
 /* 返回的语句 */
 ReturnStmt :	RETURN SEMICOLON
		{$$=$1;$$->key="Return statement";}
	|			RETURN %prec LOWEST /*return后缺少了分号报错*/
		{$$=$1;$$->key="Return statement";cout<<"need a ';' in line "<<$$->line<<" col "<<$$->col<<endl;}
	|			RETURN Opnum SEMICOLON
		{$$=$1;$$->key="Return expr statement";insertChildren($$, $2,new Node("$", 0));}
	|			RETURN Opnum %prec LOWEST  /*return后缺少了分号报错*/
		{$$=$1;$$->key="Return expr statement";insertChildren($$, $2,new Node("$", 0));cout<<"need a ';' in line "<<$$->line<<" col "<<$$->col<<endl;}
 /* 条件结构 */
Condition :		IF LP Opnum RP CompoundK %prec LOWEST		
{$$=new Node("Condition statement,only if", 0);insertChildren($$,$3,$5,new Node("$", 0));}
	|			IF LP Opnum RP CompoundK ELSE CompoundK		
	{$$=new Node("Condition statement,with else", 0);insertChildren($$,$3,$5,$7,new Node("$", 0));}
	|			IF LP Opnum RP CompoundK ELSE Condition		
	{$$=new Node("Condition statement,with else if", 0);insertChildren($$,$3,$5,$7,new Node("$", 0));}
 	/* 缺左括号 */
	|			IF Opnum RP CompoundK %prec LOWEST		
{$$=new Node("Condition statement,only if", 0);insertChildren($$,$2,$4,new Node("$", 0));
cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;}
	|			IF Opnum RP CompoundK ELSE CompoundK		
	{$$=new Node("Condition statement,with else", 0);insertChildren($$,$2,$4,$6,new Node("$", 0));
	cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;}
	|			IF Opnum RP CompoundK ELSE Condition		
	{$$=new Node("Condition statement,with else if", 0);insertChildren($$,$2,$4,$6,new Node("$", 0));
	cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;}
	/* 缺右括号 */
	|			IF LP Opnum CompoundK %prec LOWEST		
{$$=new Node("Condition statement,only if", 0);insertChildren($$,$3,$4,new Node("$", 0));
cout<<"need a ')' in line "<<$3->line<<" col "<<$3->col<<endl;}
	|			IF LP Opnum CompoundK ELSE CompoundK		
	{$$=new Node("Condition statement,with else", 0);insertChildren($$,$3,$4,$6,new Node("$", 0));
	cout<<"need a ')' in line "<<$3->line<<" col "<<$3->col<<endl;}
	|			IF LP Opnum CompoundK ELSE Condition		
	{$$=new Node("Condition statement,with else if", 0);insertChildren($$,$3,$4,$6,new Node("$", 0));
	cout<<"need a ')' in line "<<$3->line<<" col "<<$3->col<<endl;}
	/* 缺两个括号 */
	|			IF Opnum CompoundK %prec LOWEST		
{$$=new Node("Condition statement,only if", 0);insertChildren($$,$2,$3,new Node("$", 0));
cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;
cout<<"need a ')' in line "<<$2->line<<" col "<<$2->col<<endl;}
	|			IF Opnum CompoundK ELSE CompoundK		
	{$$=new Node("Condition statement,with else", 0);insertChildren($$,$2,$3,$5,new Node("$", 0));
	cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;
	cout<<"need a ')' in line "<<$2->line<<" col "<<$2->col<<endl;}
	|			IF Opnum CompoundK ELSE Condition		
	{$$=new Node("Condition statement,with else if", 0);insertChildren($$,$2,$3,$5,new Node("$", 0));
	cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;
	cout<<"need a ')' in line "<<$2->line<<" col "<<$2->col<<endl;}
	;


 /* 循环体结构 */
RepeatK :		FOR LP ForHeader RP CompoundK
{$$=new Node("RepeatK statement, for ", 0);insertChildren($$, $3, $5, new Node("$", 0));}
	|			WHILE LP Opnum RP CompoundK
{$$=new Node("RepeatK statement, while ", 0);insertChildren($$,$3,$5,new Node("$", 0));
if($3->key == "NULL")cout<<"need a expr in line "<<$2->line<<" col "<<$2->col<<endl;}
	|			WHILE LP RP CompoundK
{$$=new Node("RepeatK statement, while ", 0);insertChildren($$,new Node("NULL", 0),$4,new Node("$", 0));
cout<<"need a expr in line "<<$2->line<<" col "<<$2->col<<endl;}
	/* 缺左括号 */
	|			FOR ForHeader RP CompoundK
{$$=new Node("RepeatK statement, for ", 0);insertChildren($$, $2, $4, new Node("$", 0));
cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;}
	|			WHILE OpnumNull RP CompoundK
{$$=new Node("RepeatK statement, while ", 0);insertChildren($$, $2, $4, new Node("$", 0));
if($2->key == "NULL")cout<<"need a expr in line "<<$1->line<<" col "<<$1->col<<endl;
cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;}
	/* 缺右括号 */
	|			FOR LP ForHeader CompoundK
{$$=new Node("RepeatK statement, for ", 0);insertChildren($$, $3, $4, new Node("$", 0));
cout<<"need a ')' in line "<<$3->line<<" col "<<$3->col<<endl;}
	|			WHILE LP OpnumNull CompoundK
{$$=new Node("RepeatK statement, while ", 0);insertChildren($$,$3,$4,new Node("$", 0));
if($3->key == "NULL")cout<<"need a expr in line "<<$2->line<<" col "<<$2->col<<endl;
cout<<"need a ')' in line "<<$2->line<<" col "<<$2->col<<endl;}
	/* 缺少两个括号 */
	|			FOR ForHeader CompoundK
{$$=new Node("RepeatK statement, for ", 0);insertChildren($$, $2, $3, new Node("$", 0));
cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;
cout<<"need a ')' in line "<<$2->line<<" col "<<$2->col<<endl;}
	|			WHILE OpnumNull CompoundK
{$$=new Node("RepeatK statement, while ", 0);insertChildren($$,$2,$3,new Node("$", 0));
if($2->key == "NULL")cout<<"need a expr in line "<<$1->line<<" col "<<$1->col<<endl;
cout<<"need a '(' in line "<<$1->line<<" col "<<$1->col<<endl;
cout<<"need a ')' in line "<<$1->line<<" col "<<$1->col<<endl;}
	;


 /* for循环小括号内三个表达式 */
ForHeader :		VarOpnum SEMICOLON OpnumNull SEMICOLON OpnumNull /* 不缺分号 */
	{$$=new Node("ForHeader", 0);insertChildren($$, $1, $3, $5, new Node("$", 0));}
	|			VarOpnum OpnumNull SEMICOLON OpnumNull /* 缺第一个分号 */
	{$$=new Node("ForHeader", 0);insertChildren($$, $1, $2, $4, new Node("$", 0));
	cout<<"need a ';' in line "<<$1->line<<" col "<<$1->col<<endl;}
	|			VarOpnum SEMICOLON OpnumNull OpnumNull /* 缺第二个分号 */
	{$$=new Node("ForHeader", 0);insertChildren($$, $1, $3, $4, new Node("$", 0));
	cout<<"need a ';' in line "<<$3->line<<" col "<<$3->col<<endl;}
	|			VarOpnum OpnumNull OpnumNull /* 缺两个分号 */
	{$$=new Node("ForHeader", 0);insertChildren($$, $1, $2, $3, new Node("$", 0));
	cout<<"need a ';' in line "<<$1->line<<" col "<<$1->col<<endl;
	cout<<"need a ';' in line "<<$2->line<<" col "<<$2->col<<endl;}
	;


 /* 声明变量 或者 声明变量并赋值 */
Var :		Type IDdec ASSIGN Opnum
{$$=new Node("Var Declaration with Assign", 0);insertChildren($$,$1,$2,$4,new Node("$", 0));}
	|		Type IDdec
{$$=new Node("Var Declaration ", 0);insertChildren($$,$1,$2,new Node("$", 0));}
	;


 /* 类型声明 */
Type :		INT {$$=new Node("Type Specifier, int", 0);}
	;


 /*声明或者表达式加上;*/
VarOpnum :	Var {$$=$1;}
	|		OpnumNull {$$=$1;} /*for循环第一个式子为opnum的情况*/
	;


 /*Opnum或者NULL*/
OpnumNull :		Opnum %prec LOWEST {$$=$1;}
	|			%prec LOWEST {$$=new Node("NULL", 0);}			
	;


 /* 表达式*/
Expr :		Opnum PLUS Opnum	
	{$$=new Node("Expr,op : +", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum MINUS Opnum		
	{$$=new Node("Expr,op : -", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum MULTIPLY Opnum		
	{$$=new Node("Expr,op : *", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum DIVIDE Opnum		
	{$$=new Node("Expr,op : /", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum MODEL Opnum		
	{$$=new Node("Expr,op : %", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum POW Opnum		
	{$$=new Node("Expr,op : ^", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum GREATER Opnum		
	{$$=new Node("Expr,op : >", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum GREATEREQ Opnum		
	{$$=new Node("Expr,op : >=", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum LESS Opnum		
	{$$=new Node("Expr,op : <", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum LESSEQ Opnum		
	{$$=new Node("Expr,op : <=", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum NEQUAL Opnum		
	{$$=new Node("Expr,op : !=", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum EQUAL Opnum		
	{$$=new Node("Expr,op : ==", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum ASSIGN Opnum		
	{$$=new Node("Expr,op : =", 0);insertChildren($$,$1,$3,new Node("$", 0));}
	|		Opnum SELFPLUS
	{$$=$2;$$->key="Expr,op : i++";insertChildren($$,$1,new Node("$", 0));}
	|		Opnum SELFMINUS
	{$$=$2;$$->key="Expr,op : i--";insertChildren($$,$1,new Node("$", 0));}
	|		SELFPLUS Opnum		
	{$$=new Node("Expr,op : ++i", 0);insertChildren($$,$2,new Node("$", 0));}
	|		SELFMINUS Opnum		
	{$$=new Node("Expr,op : --i", 0);insertChildren($$,$2,new Node("$", 0));}
	|		NOT Opnum		
	{$$=new Node("Expr,op : !", 0);insertChildren($$,$2,new Node("$", 0));}
	|		LP Opnum RP %prec LOWEST
	{$$=new Node("Expr,op : ()", 0);insertChildren($$,$2,new Node("$", 0));}
	;
 /*操作数*/
Opnum :		Const	{$$=$1;}
	|		IDdec	{$$=$1;}
	|		Expr 	{$$=$1;}
	;
 /* 标识符声明 */
IDdec :		ID		{$$=$1;$$->key = "ID declaration, " + $$->key;}
	;
 /*常量*/
Const :		NUMBER		{$$=$1;$$->key = "Const declaration, " + $$->key;}
	;
%%

int yyerror(const char* msg)
{
	printf("%s", msg);
	return 0;
}
int main()
{
	extern FILE* yyin;
	yyin=fopen("5.c", "r");
	yyparse();
}
