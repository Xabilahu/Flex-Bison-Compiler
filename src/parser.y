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

programa: RPROGRAM TIDENTIFIER {codigo.anadirInstruccion(*$1 + " " + *$2 + ";");} bloqueppl 
		{
			codigo.anadirInstruccion("halt;");
			codigo.escribir();
			codigo.desempilar();
		} ;

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
		$$->clase = Codigo::NUMERO_INT;
		}
     | RFLOAT {
		$$ = new tipostruct;
		$$->clase = Codigo::NUMERO_FLOAT;
		}
     ;

decl_de_subprogs : decl_de_subprograma decl_de_subprogs 
		 | %empty 
		 ;
		 
decl_de_subprograma : RPROC TIDENTIFIER {codigo.declararProcedimiento(*$2);} argumentos bloqueppl {codigo.finProcedimiento();} ;

argumentos : TLPAREN lista_de_param TRPAREN
	   | %empty 
	   ;
	   
lista_de_param : tipo lista_de_ident TCOLON clase_par { codigo.anadirParametros($2->lnom,$4->tipo,$1->clase); delete $1; delete $2; delete $4; } resto_lis_de_param ;

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
		try {
			string tmp;
			string tipoVar = codigo.obtenerTipo($1->nom);

			if (codigo.esTipo(tipoVar, Codigo::NUMERO_INT) && codigo.esTipo($3->tipo, Codigo::NUMERO_FLOAT)){
				tmp = codigo.nuevoId();
				codigo.anadirInstruccion(tmp + " := real2ent " + $3->nom + ";");
			} else if (codigo.esTipo(tipoVar, Codigo::NUMERO_FLOAT) && codigo.esTipo($3->tipo, Codigo::NUMERO_INT)) {
				tmp = codigo.nuevoId();
				codigo.anadirInstruccion(tmp + " := ent2real " + $3->nom + ";");
			} else if (! codigo.esTipo(tipoVar, $3->tipo)){
				yyerror(string("Error semántico. No se puede asignara una variable de tipo " + $3->tipo + " a otra de tipo " + tipoVar + ".").c_str());
			} else {
				tmp = $3->nom;
			}

			codigo.anadirInstruccion($1->nom + " := " + tmp + ";");
			$$ = new sentenciastruct;
			$$->exits = codigo.iniLista(0);
			delete $1; delete $3;
		} catch (string s) {
			yyerror(s.c_str());
		}
	  }
	  | RIF expresion RTHEN M bloque M TSEMIC 
	  {
		try {
			codigo.comprobarTipos($2->tipo, Codigo::BOOLEANO);
			codigo.completarInstrucciones($2->trues, $4->ref);
			codigo.completarInstrucciones($2->falses, $6->ref);
			$$ = new sentenciastruct; $$->exits = $5->exits;
			delete $2; delete $4; delete $5; delete $6;
		} catch (string s) {
			yyerror("Error semántico. La condición de la estructura IF debe ser de tipo Codigo::BOOLEANO.");
		}
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
		try {
			codigo.comprobarTipos($3->tipo, Codigo::BOOLEANO);
			codigo.completarInstrucciones($3->trues,$5->ref);
			codigo.completarInstrucciones($3->falses,$10->ref);
			codigo.completarInstrucciones($6->exits,$10->ref);
			codigo.completarInstrucciones($11->exits,$12->ref);
			vector<int> tmp = codigo.iniLista($7->ref);
			codigo.completarInstrucciones(tmp,$2->ref);
			$$ = new sentenciastruct;
			$$->exits = codigo.iniLista(0);
			delete $2; delete $3; delete $5; delete $6; delete $7; delete $10; delete $11; delete $12;
		} catch (string s) {
			yyerror("Error semántico. La condición de la estructura IF debe ser de tipo Codigo::BOOLEANO.");
		}
	  }
	  | REXIT RIF expresion M TSEMIC
	  {
		try {
			codigo.comprobarTipos($3->tipo, Codigo::BOOLEANO);
			codigo.completarInstrucciones($3->falses, $4->ref);
			$$ = new sentenciastruct; $$->exits = $3->trues;
			delete $3; delete $4;
		} catch (string s) {
			yyerror("Error semántico. La condición de la estructura IF debe ser de tipo Codigo::BOOLEANO.");
		}
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
	  | RFOR TLPAREN tipo TIDENTIFIER TASSIG expresion 
	  {
		  try{
			  codigo.comprobarTipos($6->tipo, $3->clase);
			  codigo.anadirDeclaraciones(codigo.iniLista(*$4), $3->clase);
			  codigo.anadirInstruccion(*$4 + " := " + $6->nom + ";");
		  } catch (string s){
			  yyerror(s.c_str());
		  }
	  }
	  TSEMIC M expresion M TSEMIC variable TASSIG expresion TRPAREN bloque M TSEMIC
	  {
		try{
			codigo.comprobarTipos($10->tipo, Codigo::BOOLEANO);
			codigo.comprobarTipos($13->tipo, $15->tipo);
			codigo.anadirInstruccion($13->nom + " := " + $15->nom + ";");
			codigo.anadirInstruccion("goto " + to_string($9->ref) + ";");
			codigo.completarInstrucciones($10->trues, $11->ref);
			codigo.completarInstrucciones($10->falses, $18->ref + 2);
			codigo.completarInstrucciones($17->exits, $18->ref + 2);
			$$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
			delete $3; delete $6; delete $9; delete $10; delete $11; delete $13; delete $15; delete $17; delete $18;
		} catch (string s){
			yyerror(s.c_str());
		}
	  }
	  ;

M: %empty { $$ = new mstruct; $$->ref = codigo.obtenRef(); } ;

variable: TIDENTIFIER 
	{ 	try {
			string tipo = codigo.obtenerTipo(*$1);
			$$ = new variablestruct; 
	  		$$->nom = *$1;
			$$->tipo = tipo;
		} catch (string s) {
			yyerror(s.c_str());
		}
	  
	} ;

expresion : expresion TCEQ expresion
	  {
		  try{
			codigo.comprobarTipos($1->tipo, $3->tipo);
			$$ = new expresionstruct;
			$$->nom = codigo.iniNom();
			$$->tipo = Codigo::BOOLEANO;
			$$->trues = codigo.iniLista(codigo.obtenRef());
			$$->falses = codigo.iniLista(codigo.obtenRef()+1);
			codigo.anadirInstruccion("if " + $1->nom + " = " + $3->nom + " goto");
			codigo.anadirInstruccion("goto");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  }
	  | expresion TCGT expresion
	  {
		  try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
			$$ = new expresionstruct;
			$$->nom = codigo.iniNom();
			$$->tipo = Codigo::BOOLEANO;
			$$->trues = codigo.iniLista(codigo.obtenRef());
			$$->falses = codigo.iniLista(codigo.obtenRef()+1);
			codigo.anadirInstruccion("if " + $1->nom + " > " + $3->nom + " goto");
			codigo.anadirInstruccion("goto");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  } 
	  | expresion TCLT expresion
	  {
		  try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
			$$ = new expresionstruct;
			$$->nom = codigo.iniNom();
			$$->tipo = Codigo::BOOLEANO;
			$$->trues = codigo.iniLista(codigo.obtenRef());
			$$->falses = codigo.iniLista(codigo.obtenRef()+1);
			codigo.anadirInstruccion("if " + $1->nom + " < " + $3->nom + " goto");
			codigo.anadirInstruccion("goto");
			delete $1; delete $3;
		 } catch (string s) {
			  yyerror(s.c_str());
		 }
	  } 
	  | expresion TCGE expresion
	  {
		  try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
			$$ = new expresionstruct;
			$$->nom = codigo.iniNom();
			$$->tipo = Codigo::BOOLEANO;
			$$->trues = codigo.iniLista(codigo.obtenRef());
			$$->falses = codigo.iniLista(codigo.obtenRef()+1);
			codigo.anadirInstruccion("if " + $1->nom + " >= " + $3->nom + " goto");
			codigo.anadirInstruccion("goto");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  }
	  | expresion TCLE expresion
	  {
		  try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
			$$ = new expresionstruct;
			$$->nom = codigo.iniNom();
			$$->tipo = Codigo::BOOLEANO;
			$$->trues = codigo.iniLista(codigo.obtenRef());
			$$->falses = codigo.iniLista(codigo.obtenRef()+1);
			codigo.anadirInstruccion("if " + $1->nom + " <= " + $3->nom + " goto");
			codigo.anadirInstruccion("goto");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  } 
	  | expresion TCNE expresion
	  {
		  try{
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
			$$ = new expresionstruct;
			$$->nom = codigo.iniNom();
			$$->tipo = Codigo::BOOLEANO;
			$$->trues = codigo.iniLista(codigo.obtenRef());
			$$->falses = codigo.iniLista(codigo.obtenRef()+1);
			codigo.anadirInstruccion("if " + $1->nom + " != " + $3->nom + " goto");
			codigo.anadirInstruccion("goto");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  } 
	  | expresion TPLUS expresion
	  {
		  try{
			$$ = new expresionstruct;
			codigo.operacionAritmetica($$, *$1, *$3, *$2);
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  } 
	  | expresion TMINUS expresion
	  {
		  try{
			$$ = new expresionstruct;
			codigo.operacionAritmetica($$, *$1, *$3, "-");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  } 
	  | expresion TMUL expresion
	  {
		  try{
			$$ = new expresionstruct;
			codigo.operacionAritmetica($$, *$1, *$3, "*");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
	  } 
	  | expresion TDIV expresion
	  {
		  try{
			$$ = new expresionstruct;
			codigo.anadirInstruccion("if " + $3->nom + " = 0 goto ErrorDiv0;");
			codigo.operacionAritmetica($$, *$1, *$3, "/");
			delete $1; delete $3;
		  } catch (string s) {
			  yyerror(s.c_str());
		  }
			
	  } 
	  | variable
	  {
		  $$ = new expresionstruct;
		  $$->nom = $1->nom;
		  $$->tipo = $1->tipo;
		  $$->trues = codigo.iniLista(0);
		  $$->falses = codigo.iniLista(0);
		  delete $1;
	  }
	  | TINTEGER 
	  {
		$$ = new expresionstruct;
		$$->nom = *$1;
		$$->tipo = Codigo::NUMERO_INT;
		$$->trues = codigo.iniLista(0);
		$$->falses = codigo.iniLista(0);
	  }
	  | TFLOAT 
	  {
		$$ = new expresionstruct;
		$$->nom = *$1;
		$$->tipo = Codigo::NUMERO_FLOAT;
		$$->trues = codigo.iniLista(0);
		$$->falses = codigo.iniLista(0);
	  }
	  | TLPAREN expresion TRPAREN {$$ = $2;}
	  ;

%%