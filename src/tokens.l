%option yylineno
%option nounput

%{
 #include <string>
 #include <vector>
 #include <iostream>
 #include "Structs.hpp"
 #include "parser.hpp"
 using namespace std;

 #define TOKEN(t) yylval.str = new string(yytext, yyleng) ; return t 

 extern "C" int yywrap() { return(1) ; }  

%}

%%
\(\*(\**[^*)]|\))*\*+\)                              ;
#([^#\n])*$                                          ;
[ \t\n]                                              ;
prog                                                 TOKEN(RPROGRAM);
int                                                  TOKEN(RINTEGER);
float                                                TOKEN(RFLOAT);
if                                                   TOKEN(RIF);
then                                                 TOKEN(RTHEN);
for                                                  TOKEN(RFOR);
forever                                              TOKEN(RFOREVER);
while                                                TOKEN(RWHILE);
loop                                                 TOKEN(RLOOP);
finally                                              TOKEN(RFINALLY);
exit                                                 TOKEN(REXIT);
read                                                 TOKEN(RREAD);
print                                                TOKEN(RPRINT);
println                                              TOKEN(RPRINTLN);
proc                                                 TOKEN(RPROC);
in                                                   TOKEN(RIN);
out                                                  TOKEN(ROUT);
and                                                  TOKEN(RAND);
or                                                   TOKEN(ROR);
not                                                  TOKEN(RNOT);
"*"                                                  TOKEN(TMUL);
"/"                                                  TOKEN(TDIV);
"="                                                  TOKEN(TASSIG);
";"                                                  TOKEN(TSEMIC);
":"                                                  TOKEN(TCOLON);
","                                                  TOKEN(TCOMMA);
"{"                                                  TOKEN(TLBRACE);
"}"                                                  TOKEN(TRBRACE);
"("                                                  TOKEN(TLPAREN);
")"                                                  TOKEN(TRPAREN);
"=="                                                 TOKEN(TCEQ);
">"                                                  TOKEN(TCGT);
"<"                                                  TOKEN(TCLT);
">="                                                 TOKEN(TCGE);
"<="                                                 TOKEN(TCLE);
"/="                                                 TOKEN(TCNE);
"+"                                                  TOKEN(TPLUS);
"-"                                                  TOKEN(TMINUS);
[a-zA-Z](_?[a-zA-Z0-9])*                             TOKEN(TIDENTIFIER) ; 
[0-9]+\.[0-9]+([Ee](\+|\-)?[0-9]+)?                  TOKEN(TFLOAT);
[0-9]+                                               TOKEN(TINTEGER); 

.                       { cout << "Token desconocido: " << yytext << endl; yyterminate();}
%%


