%define parse.error verbose

%{
   #include <stdio.h>
   #include <iostream>
   #include <vector>
   #include <string>
   using namespace std; 

   extern int yylex();
   extern int yylineno;
   extern char *yytext;
   void yyerror (const char *msg) {
     printf("Line %d: %s\n", yylineno, msg) ;
   }

   #include "Codigo.hpp"

   void printVector(vector<int> &vec);
   Codigo codigo;

%}

/* 
   qué atributos tienen los símbolos 
*/
%union {
    std::string *str ;
	bloquestruct *blq;
	lista_de_identstruct *lident;
	resto_lista_idstruct *rlident;
	tipostruct *tp;
	clase_parstruct *cp;
	lista_de_sentenciasstruct *lsent;
	sentenciastruct *sent;
	mstruct *m;
	variablestruct *var;
	expresionstruct *expr;
}

/* 
   declaración de tokens. Esto debe coincidir con tokens.l 
*/

%token <str> TIDENTIFIER TINTEGER TFLOAT
%token <str> TMUL TDIV TPLUS TMINUS
%token <str> TCEQ TCGT TCLT TCGE TCLE TCNE
%token <str> TSEMIC TCOMMA TCOLON TASSIG TLBRACE TRBRACE TLPAREN TRPAREN
%token <str> RPROGRAM RINTEGER RFLOAT RIF RTHEN RWHILE RFOR RFOREVER RLOOP 
%token <str> RFINALLY REXIT RREAD RPRINT RPROC RIN ROUT RINOUT 

%nonassoc TCEQ TCGT TCLT TCGE TCLE TCNE
%left TPLUS TMINUS
%left TMUL TDIV

/* 
   declaración de no terminales.
*/

%type <blq> bloque
%type <lident> lista_de_ident
%type <rlident> resto_lista_id
%type <tp> tipo
%type <cp> clase_par
%type <lsent> lista_de_sentencias
%type <sent> sentencia
%type <var> variable
%type <expr> expresion
%type <m> M

%start programa

%%

programa: RPROGRAM TIDENTIFIER {codigo.anadirInstruccion(*$1 + " " + *$2 + ";");} bloqueppl {codigo.anadirInstruccion("halt;"); codigo.escribir();} ;

bloqueppl : TLBRACE declaraciones decl_de_subprogs lista_de_sentencias TRBRACE {delete $4;} ;

bloque : TLBRACE declaraciones lista_de_sentencias TRBRACE {$$ = new bloquestruct; $$->exits = $3->exits; delete $3;} ;

declaraciones: tipo lista_de_ident {codigo.anadirDeclaraciones($2->lnom,$1->clase); delete $1; delete $2;} TSEMIC declaraciones 
	      | %empty 
	      ;

lista_de_ident : TIDENTIFIER resto_lista_id 
				{   
					$$ = new lista_de_identstruct;
					$$->lnom = codigo.iniLista(*$1);
					$$->lnom = *codigo.unir($$->lnom,$2->lnom);
					delete $2;
				}

resto_lista_id : TCOMMA TIDENTIFIER resto_lista_id {
				$$ = new resto_lista_idstruct;
				$$->lnom = codigo.iniLista(*$2);
				$$->lnom = *codigo.unir($$->lnom,$3->lnom);
				delete $3;
			} 
	       | %empty { 
			   $$ = new resto_lista_idstruct;
			   $$->lnom = codigo.iniLista(""); }
	       ;

tipo : RINTEGER { 
		$$ = new tipostruct;
		$$->clase = "ent";
		}
     | RFLOAT {
		$$ = new tipostruct;
		$$->clase = "real";
		}
     ;

decl_de_subprogs : decl_de_subprograma decl_de_subprogs 
		 | %empty 
		 ;
		 
decl_de_subprograma : RPROC TIDENTIFIER {codigo.anadirInstruccion(*$1 + " " + *$2 + ";");} argumentos bloqueppl { codigo.anadirInstruccion("endproc;");} ;

argumentos : TLPAREN lista_de_param TRPAREN
	   | %empty 
	   ;
	   
lista_de_param : tipo lista_de_ident TCOLON clase_par { codigo.anadirParametros($2->lnom,$4->tipo,$1->clase); delete $1; delete $2; delete $4;} resto_lis_de_param ;

clase_par : RIN {
			$$ = new clase_parstruct;
			$$->tipo = "val";
		}
	  | ROUT {
		  	$$ = new clase_parstruct;
			$$->tipo = "ref";
			}
	  | RIN ROUT {
		  	$$ = new clase_parstruct;
			$$->tipo = "ref";
			}
	  ;

resto_lis_de_param : TSEMIC tipo lista_de_ident TCOLON clase_par { codigo.anadirParametros($3->lnom,$5->tipo,$2->clase); delete $2; delete $3; delete $5;} resto_lis_de_param 
	  	   | %empty 
	           ;

lista_de_sentencias : sentencia lista_de_sentencias {$$ = new lista_de_sentenciasstruct; $$->exits = *codigo.unir($1->exits, $2->exits); delete $1; delete $2;}
		    | %empty {$$ = new lista_de_sentenciasstruct; $$->exits = codigo.iniLista(0);}
		    ;
		    
sentencia : variable TASSIG expresion TSEMIC
	  { 
		codigo.anadirInstruccion($1->nom + " := " + $3->nom + ";");
		$$ = new sentenciastruct;
		$$->exits = codigo.iniLista(0);
		delete $1; delete $3;
	  }
	  | RIF expresion RTHEN M bloque M TSEMIC 
	  {
	  	codigo.completarInstrucciones($2->trues, $4->ref);
		codigo.completarInstrucciones($2->falses, $6->ref);
		$$ = new sentenciastruct; $$->exits = $5->exits;
		delete $2; delete $4; delete $5; delete $6;
	  }
	  | RWHILE RFOREVER M bloque M TSEMIC
	  {
		codigo.anadirInstruccion("goto" + to_string($3->ref) + ";");
		codigo.completarInstrucciones($4->exits,$5->ref + 1);
		$$ = new sentenciastruct;
		$$->exits = codigo.iniLista(0);
		delete $3; delete $4; delete $5;
	  }
	  | RWHILE M expresion RLOOP M bloque M {codigo.anadirInstruccion("goto");} RFINALLY M bloque M TSEMIC 
	  {
		codigo.completarInstrucciones($3->trues,$5->ref);
		codigo.completarInstrucciones($3->falses,$10->ref);
		codigo.completarInstrucciones($6->exits,$10->ref);
		codigo.completarInstrucciones($11->exits,$12->ref);
		vector<int> tmp = codigo.iniLista($7->ref);
		codigo.completarInstrucciones(tmp,$2->ref);
		$$ = new sentenciastruct;
		$$->exits = codigo.iniLista(0);
		delete $2; delete $3; delete $5; delete $6; delete $7; delete $10; delete $11; delete $12;
	  }
	  | REXIT RIF expresion M TSEMIC
	  {
		codigo.completarInstrucciones($3->falses, $4->ref);
		$$ = new sentenciastruct; $$->exits = $3->trues;
		delete $3; delete $4;
	  } 
	  | RREAD TLPAREN variable TRPAREN TSEMIC 
	  {
		  codigo.anadirInstruccion("read " + $3->nom + ";");
		  $$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
		  delete $3;
	  }
	  | RPRINT TLPAREN expresion TRPAREN TSEMIC
	  {
		  codigo.anadirInstruccion("write " + $3->nom + ";");
		  codigo.anadirInstruccion("writeln;");
		  $$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
		  delete $3;
	  }
	  | RFOR TLPAREN tipo variable TASSIG expresion 
	  {
		  codigo.anadirDeclaraciones(codigo.iniLista($4->nom), $3->clase);
		  codigo.anadirInstruccion($4->nom + " := " + $6->nom + ";");
	  }
	  TSEMIC M expresion M TSEMIC variable TASSIG expresion TRPAREN bloque M TSEMIC
	  {
		  codigo.anadirInstruccion($13->nom + " := " + $15->nom + ";");
		  codigo.anadirInstruccion("goto " + to_string($9->ref) + ";");
		  codigo.completarInstrucciones($10->trues, $11->ref);
		  codigo.completarInstrucciones($10->falses, $18->ref + 2);
		  codigo.completarInstrucciones($17->exits, $18->ref + 2);
		  $$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
		  delete $3; delete $4; delete $6; delete $9; delete $10; delete $11; delete $13; delete $15; delete $17; delete $18;
	  }
	  ;

M: %empty { $$ = new mstruct; $$->ref = codigo.obtenRef(); } ;

variable: TIDENTIFIER { $$ = new variablestruct; $$->nom = *$1; } ;

expresion : expresion TCEQ expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.iniNom();
		  $$->trues = codigo.iniLista(codigo.obtenRef());
		  $$->falses = codigo.iniLista(codigo.obtenRef()+1);
		  codigo.anadirInstruccion("if " + $1->nom + " = " + $3->nom + " goto");
		  codigo.anadirInstruccion("goto");
		  delete $1; delete $3;
	  }
	  | expresion TCGT expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.iniNom();
		  $$->trues = codigo.iniLista(codigo.obtenRef());
		  $$->falses = codigo.iniLista(codigo.obtenRef()+1);
		  codigo.anadirInstruccion("if " + $1->nom + " > " + $3->nom + " goto");
		  codigo.anadirInstruccion("goto");
		  delete $1; delete $3;
	  } 
	  | expresion TCLT expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.iniNom();
		  $$->trues = codigo.iniLista(codigo.obtenRef());
		  $$->falses = codigo.iniLista(codigo.obtenRef()+1);
		  codigo.anadirInstruccion("if " + $1->nom + " < " + $3->nom + " goto");
		  codigo.anadirInstruccion("goto");
		  delete $1; delete $3;
	  } 
	  | expresion TCGE expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.iniNom();
		  $$->trues = codigo.iniLista(codigo.obtenRef());
		  $$->falses = codigo.iniLista(codigo.obtenRef()+1);
		  codigo.anadirInstruccion("if " + $1->nom + " >= " + $3->nom + " goto");
		  codigo.anadirInstruccion("goto");
		  delete $1; delete $3;
	  }
	  | expresion TCLE expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.iniNom();
		  $$->trues = codigo.iniLista(codigo.obtenRef());
		  $$->falses = codigo.iniLista(codigo.obtenRef()+1);
		  codigo.anadirInstruccion("if " + $1->nom + " <= " + $3->nom + " goto");
		  codigo.anadirInstruccion("goto");
		  delete $1; delete $3;
	  } 
	  | expresion TCNE expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.iniNom();
		  $$->trues = codigo.iniLista(codigo.obtenRef());
		  $$->falses = codigo.iniLista(codigo.obtenRef()+1);
		  codigo.anadirInstruccion("if " + $1->nom + " != " + $3->nom + " goto");
		  codigo.anadirInstruccion("goto");
		  delete $1; delete $3;
	  } 
	  | expresion TPLUS expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.nuevoId();
		  codigo.anadirInstruccion($$->nom + " := " + $1->nom + " + " + $3->nom + ";");
		  $$->trues = codigo.iniLista(0);
		  $$->falses = codigo.iniLista(0);
		  delete $1; delete $3;
	  } 
	  | expresion TMINUS expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.nuevoId();
		  codigo.anadirInstruccion($$->nom + " := " + $1->nom + " - " + $3->nom + ";");
		  $$->trues = codigo.iniLista(0);
		  $$->falses = codigo.iniLista(0);
		  delete $1; delete $3;
	  } 
	  | expresion TMUL expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.nuevoId();
		  codigo.anadirInstruccion($$->nom + " := " + $1->nom + " * " + $3->nom + ";");
		  $$->trues = codigo.iniLista(0);
		  $$->falses = codigo.iniLista(0);
		  delete $1; delete $3;
	  } 
	  | expresion TDIV expresion
	  {
		  $$ = new expresionstruct;
		  $$->nom = codigo.nuevoId();
		  codigo.anadirInstruccion($$->nom + " := " + $1->nom + " / " + $3->nom + ";");
		  $$->trues = codigo.iniLista(0);
		  $$->falses = codigo.iniLista(0);
		  delete $1; delete $3;
	  } 
	  | variable
	  {
		  $$ = new expresionstruct;
		  $$->nom = $1->nom;
		  $$->trues = codigo.iniLista(0);
		  $$->falses = codigo.iniLista(0);
		  delete $1;
	  }
	  | TINTEGER 
	  {
		$$ = new expresionstruct;
		$$->nom = *$1;
		$$->trues = codigo.iniLista(0);
		$$->falses = codigo.iniLista(0);
	  }
	  | TFLOAT 
	  {
		$$ = new expresionstruct;
		$$->nom = *$1;
		$$->trues = codigo.iniLista(0);
		$$->falses = codigo.iniLista(0);
	  }
	  | TLPAREN expresion TRPAREN {$$ = $2; delete $2;}
	  ;

%%