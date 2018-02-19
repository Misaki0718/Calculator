%{
#include <stdio.h>
#include <stdlib.h>
#include "repo.h"
#include <string.h>
#include <math.h>
#include <ctype.h>
%}

%{
int a=1;
%}
%union {
	double dval;
  char* ch;
	struct symtab *symp;
  struct symchar *symc;
}

%token <symp> NAME
%token <dval> NUMBER
%token <symc> CHARACTER
%token IF
%token SYM
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <dval> expression
%type <ch> cter 

%%

statement_list:	statement '\n' { a = 1; }
  |       statement ':'
 	|	statement_list statement '\n' { a = 1;}
  | statement_list statement ':'
	;

statement:	NAME '=' expression	{ if(a==1)$1->value = $3; }
  | cter   { if(a==1)printf("= %s\n", $1);}
  | CHARACTER '=' cter  { if(a==1)$1->character = $3;}
	|	expression		{ if(a==1)printf("= %g\n", $1); }
  | ifsentence statement_list
  | NAME SYM { if(a==1)$1->value = $1->value + 1;}
  	;

expression: expression '+' expression	{ if(a==1)$$ = $1 + $3; }
	|   expression '-' expression	{ if(a==1)$$ = $1 - $3; }
	|   expression '*' expression	{ if(a==1)$$ = $1 * $3; }
	|   expression '/' expression	{ if(a==1){if($3==0.0){ yyerror("Divide by Zero"); exit(1);}
					  else $$ = $1 / $3;  }}
	|   '-' expression %prec UMINUS	{ if(a==1)$$ = -$2; }
	|   '(' expression ')'		{ if(a==1)$$ = $2; }
	|   NUMBER			{ if(a==1)$$ = $1; }
	|   NAME			{ if(a==1)$$ = $1->value; }
	|   NAME '(' expression ')'	{ if(a==1){if( $1->funcptr ) $$ = ($1->funcptr)($3);
					  else {
						printf("%s not a function.\n", $1->name);
                           exit(1);
					  }
					}
     }
  |   NAME '(' expression ',' expression ')'	{ if(a==1){if( $1->funcptr ) $$ = ($1->funcptr)($3,$5);
					  else {
						printf("%s not a function.\n", $1->name);
					  }
					}
     }
  |   NAME '(' expression ',' expression ',' expression ')'	{ if(a==1){if( $1->funcptr ) $$ = ($1->funcptr)($3,$5,$7);
					  else {
						printf("%s not a function.\n", $1->name);
					  }
					}
     }
  |   NAME '(' cter ')'  { if(a==1){if( $1->funcptr) $$ = ($1->funcptr)($3);
            else {
            printf("%s not a string function.\n", $1->name);
            exit(1);
            }
        }
     }
	;
 
cter: '"' NAME '"' { if(a==1)$$ = $2->name;}
  |   CHARACTER    { if(a==1)$$ = $1->character; }
  |   CHARACTER '(' cter ')'  { if(a==1){if( $1->funcptr) $$ = ($1->funcptr)($3);
            else {
            printf("%s not a function.\n", $1->name);
            exit(1);
            }
        }
  }
  |   CHARACTER '(' cter ',' cter ')'  { if(a==1){if( $1->funcptr) $$ = ($1->funcptr)($3,$5); 
            else {
            printf("%s not a function.\n", $1->name);
            exit(1);
            }
        }
  }
  |   CHARACTER '(' cter ',' expression ')'  { if(a==1){if( $1->funcptr) $$ = ($1->funcptr)($3,$5);
            else {
            printf("%s not a function.\n", $1->name);
            exit(1);
            }
        }
  }
  |   CHARACTER '(' cter ',' expression ',' expression ')'  { if(a==1){if( $1->funcptr) $$ = ($1->funcptr)($3,$5,$7);
            else {
            printf("%s not a function.\n", $1->name);
            exit(1);
            }
        }
  }
;

ifsentence: IF '(' expression '<' expression ')' { if($3 >= $5) a = 0;}
    |       IF '(' expression '<' '=' expression ')' { if($3 > $6) a=0;}
    |       IF '(' expression '>' expression ')' { if($3 <= $5) a=0;}
    |       IF '(' expression '>' '=' expression ')' {if($3 < $6) a=0;}
    |       IF '(' expression '=' '=' expression ')' {if($3 != $6) a=0;}
    |       IF '(' cter '=' '=' cter ')' { if(strcmp($3,$6)) a=0;} 
    ;

%%

/* look up a symbol table entry, add if not present */
struct symtab *symlook(char *s)
{
	char *p;
	struct symtab *sp;

	for(sp=symtab; sp<&symtab[NSYMS]; sp++) {
		/* is it already here? */
		if( sp->name && !strcmp(sp->name, s) )  return sp;

		/* is it free */
		if( !sp->name ) {
			sp->name = strdup(s);
			return sp;
		}
		
		/* otherwise continue to next */
	}
	yyerror("Too many symbols");
	exit(1);   /* cannot continue */
} /* end of symlook */

struct symchar *sclook(char *s)
{
  char *p;
  struct symchar *sc;
  
  for(sc=symchar; sc<&symchar[NSYMS]; sc++){
    if(sc->name && !strcmp(sc->name,s)) return sc;
    if(!sc->name){
      sc->name = strdup(s);
      return sc;
    }
  }
  yyerror("Too many symbols");
  exit(1);
}

void addfunc(char *name, double (*func)())
{
	struct symtab *sp = symlook(name);
	sp->funcptr = func;
}

void addfunc2(char *name, char *(*func)())
{
  struct symchar *sc = sclook(name);
  sc->funcptr = func;
}

double triangle(double a,double h){
  return a * h / 2;
}

double trapezoid(double a,double b,double h){
  return (a + b ) / 2 * h;
}

char* concatenate(char* s1, char* s2){
  char* s = (char*)malloc(sizeof(strlen(s1)+strlen(s2)+1));
  strcpy(s,s1);
  strcat(s,s2);
  return s;
}

char* head(char* s1,double a){
  char* s = (char*)malloc(sizeof(strlen(s1)+1));
  strcpy(s,s1);
  s[(int)a] = '\0';
  return s;
}

double length(char* s1){
  double size = strlen(s1);
  return size;
}

char* tail(char* s1,double a){
  int size = length(s1) - (int)a;
  char* s = (char*)malloc((int)a);
  strncpy(s,s1 + size,a);
  return s;
}

char* uppercase(char* s1){
  char* s = (char*)malloc(sizeof(strlen(s1)+1));
  for(int i = 0; i < strlen(s1); i++)
    {
       s[i] = toupper(s1[i]);
    }
  return s;
}

char* lowercase(char* s1){
  char* s = (char*)malloc(sizeof(strlen(s1)+1));
  for(int i = 0; i < strlen(s1); i++)
    {
       s[i] = tolower(s1[i]);
    }
  return s;
}

char* substring(char* s1,double a,double b){
  char* s = (char*)malloc((int)b);
  strncpy(s,s1+(int)a-1,(int)b);
  return s;
}

int main()
{
  extern double sqrt(), exp(), log(), sin(), cos(),pow();

	addfunc("sqrt", sqrt);
	addfunc("exp",  exp);
	addfunc("log",  log);
	addfunc("sin",  sin);
	addfunc("cos",  cos);
  addfunc("tan",  tan);
  addfunc("sinh", sinh);
  addfunc("cosh", cosh);
  addfunc("tanh", tanh);
  addfunc("log",  log);
  addfunc("rint", rint);
  addfunc("pow",  pow);
	addfunc("triangle",  triangle);
	addfunc("trapezoid",  trapezoid);
  addfunc2("concatenate",concatenate);
  addfunc2("head", head);
  addfunc("length", length);
  addfunc2("tail",tail);
  addfunc2("uppercase", uppercase);
  addfunc2("lowercase", lowercase);
  addfunc2("substring",substring);

	yyparse();

        return 0;
}
