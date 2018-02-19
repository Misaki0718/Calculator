%{
#include "y.tab.h"
#include "repo.h"
#include <math.h>
%}

%%

"PI"  { yylval.dval = 3.14;
        return NUMBER;}

([0-9]+|([0-9]*\.[0-9]+)([eE][-+]?[0-9]+)?)	{
				yylval.dval = atof(yytext);
				return NUMBER;  }

[ \t]		;  /* ignore white space */
         
concatenate|head|tail|uppercase|lowercase|substring  |   
[sS][0-9]  {  
      struct symchar *sc = sclook(yytext);
      yylval.symc = sc;
      return CHARACTER;
}

"if" { return IF;}

"++" { return SYM;}

[A-Za-z][A-Za-z0-9]*	{  /* return symbol pointer */
		  struct symtab *sp = symlook(yytext);
		  yylval.symp = sp;
		  return NAME; 
}

"$"		{ return 0;  /* end of input */ }

\n	|
.		return yytext[0];
%%
void yyerror(char *errmsg)
{
    fprintf(stderr,"ERROR: %s at %s\n", errmsg, yytext);
}
