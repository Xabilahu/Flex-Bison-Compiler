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

   extern bool hayError;
   void yyerror (const char *msg) {
	 hayError = true;
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
	argumentostruct *arg;
}

/* 
   declaración de tokens. Esto debe coincidir con tokens.l 
*/

%token <str> TIDENTIFIER TINTEGER TFLOAT
%token <str> TMUL TDIV TPLUS TMINUS
%token <str> TCEQ TCGT TCLT TCGE TCLE TCNE
%token <str> TSEMIC TCOMMA TCOLON TASSIG TLBRACE TRBRACE TLPAREN TRPAREN
%token <str> RPROGRAM RINTEGER RFLOAT RIF RTHEN RWHILE RFOR RFOREVER RLOOP 
%token <str> RFINALLY REXIT RREAD RPRINT RPRINTLN RPROC RIN ROUT RINOUT RAND ROR RNOT

%right RAND ROR
%left RNOT
%left TCEQ TCGT TCLT TCGE TCLE TCNE
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
%type <arg> lista_de_argumentos
%type <arg> resto_lista_argumentos

%start programa

%%
programa: RPROGRAM TIDENTIFIER {codigo.anadirInstruccion(*$1 + " " + *$2 + ";");} bloqueppl 
		{
			codigo.anadirInstruccion("halt;");
			if (!hayError) codigo.escribir();
			codigo.desempilar();
		} ;

bloqueppl : TLBRACE declaraciones decl_de_subprogs lista_de_sentencias TRBRACE 
		{
			// if (!codigo.esVacia($4->exits)){ // Salta undefined reference ¿?
			if (!$4->exits.empty()) {
				yyerror("Error semántico. Hay algún exit fuera de un bucle.");
				YYABORT;
			}
			delete $4;
		} ;

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
		} catch (string s) {}
		$$ = new sentenciastruct;
		$$->exits = codigo.iniLista(0);
		delete $1; delete $3;
	  }
	  | RIF expresion RTHEN M bloque M TSEMIC 
	  {
		try {
			codigo.comprobarTipos($2->tipo, Codigo::BOOLEANO);
			codigo.completarInstrucciones($2->trues, $4->ref);
			codigo.completarInstrucciones($2->falses, $6->ref);
		} catch (string s) {
			yyerror("Error semántico. La condición de la estructura IF debe ser de tipo booleano.");
		}
		$$ = new sentenciastruct; $$->exits = $5->exits;
		delete $2; delete $4; delete $5; delete $6;
	  }
	  | RWHILE RFOREVER M bloque M TSEMIC
	  {
		codigo.anadirInstruccion("goto " + to_string($3->ref) + ";");
		codigo.completarInstrucciones($4->exits,$5->ref + 1);
		$$ = new sentenciastruct;
		$$->exits = codigo.iniLista(0);
		delete $3; delete $4; delete $5;
	  }
	  | RWHILE M expresion 
	  {
		try {
			codigo.comprobarTipos($3->tipo, Codigo::BOOLEANO);
		} catch (string s) {
			yyerror("Error semántico. La condición de parada debe ser de tipo booleano.");
		}
	  } 
	  RLOOP M bloque M {codigo.anadirInstruccion("goto");} RFINALLY M bloque M TSEMIC 
	  {
		codigo.completarInstrucciones($3->trues,$6->ref);
		codigo.completarInstrucciones($3->falses,$11->ref);
		codigo.completarInstrucciones($7->exits,$11->ref);
		codigo.completarInstrucciones($12->exits,$13->ref);
		vector<int> tmp = codigo.iniLista($8->ref);
		codigo.completarInstrucciones(tmp,$2->ref);
		
		$$ = new sentenciastruct;
		$$->exits = codigo.iniLista(0);
		delete $2; delete $3; delete $6; delete $7; delete $8; delete $11; delete $12; delete $13;
	  }
	  | REXIT RIF expresion M TSEMIC
	  {
		try {
			codigo.comprobarTipos($3->tipo, Codigo::BOOLEANO);
			codigo.completarInstrucciones($3->falses, $4->ref);
		} catch (string s) {
			yyerror("Error semántico. La condición de la estructura EXIT IF debe ser de tipo booleano.");
		}
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
		$$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
		delete $3;
	  }
	  | RPRINTLN TLPAREN expresion TRPAREN TSEMIC
	  {
		codigo.anadirInstruccion("write " + $3->nom + ";");
		codigo.anadirInstruccion("writeln;");
		$$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
		delete $3;
	  }
	  | RFOR TLPAREN tipo TIDENTIFIER TASSIG expresion 
	  {
		string variableAsignar;
		try{
			codigo.comprobarTipos($6->tipo, $3->clase);
			variableAsignar = $6->nom;
		} catch (string s){
			if (codigo.esTipo($3->clase, Codigo::NUMERO_INT)) {
				variableAsignar = codigo.nuevoId();
				codigo.anadirInstruccion(variableAsignar + " := real2ent " + $6->nom + ";");
			} else if (codigo.esTipo($3->clase, Codigo::NUMERO_FLOAT)) {
				variableAsignar = codigo.nuevoId();
				codigo.anadirInstruccion(variableAsignar + " := ent2real " + $6->nom + ";");
			} else {
				yyerror(s.c_str());
			}
		}
		TablaSimbolos ts;
		codigo.empilar(ts);
		codigo.anadirDeclaraciones(codigo.iniLista(*$4), $3->clase);
		codigo.anadirInstruccion(*$4 + " := " + variableAsignar + ";");
	  }
	  TSEMIC M expresion
	  {
		try {
			codigo.comprobarTipos($10->tipo, Codigo::BOOLEANO);
		} catch (string s) {
			yyerror("Error semántico. La condición de parada debe ser de tipo booleano.");
		}
	  }
	  M TSEMIC variable TASSIG expresion TRPAREN bloque M TSEMIC
	  {
		try{
			codigo.comprobarTipos($14->tipo, $16->tipo);
			codigo.anadirInstruccion($14->nom + " := " + $16->nom + ";");
			codigo.anadirInstruccion("goto " + to_string($9->ref) + ";");
			codigo.completarInstrucciones($10->trues, $12->ref);
			codigo.completarInstrucciones($10->falses, $19->ref + 2);
			codigo.completarInstrucciones($18->exits, $19->ref + 2);
		} catch (string s){
			yyerror(s.c_str());
		}
		codigo.desempilar();
		$$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
		delete $3; delete $6; delete $9; delete $10; delete $12; delete $14; delete $16; delete $18; delete $19;
	  }
	  | TIDENTIFIER TLPAREN lista_de_argumentos TRPAREN TSEMIC
	  {
		try {
			codigo.llamadaProcedimiento(*$1, $3->lparam);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new sentenciastruct; $$->exits = codigo.iniLista(0);
		delete $3;
	  }
	  ;

lista_de_argumentos : expresion resto_lista_argumentos
		{
			$$ = new argumentostruct;
			$$->lparam = codigo.iniLista($1->nom, $1->tipo);
			$$->lparam = *codigo.unir($$->lparam, $2->lparam);
			delete $1; delete $2;
		} ;

resto_lista_argumentos : TCOMMA expresion resto_lista_argumentos
		{
			$$ = new argumentostruct;
			$$->lparam = codigo.iniLista($2->nom, $2->tipo);
			$$->lparam = *codigo.unir($$->lparam, $3->lparam);
			delete $2; delete $3;
		}
		| %empty {$$ = new argumentostruct; $$->lparam = codigo.iniLista("", "");}
		;

M: %empty { $$ = new mstruct; $$->ref = codigo.obtenRef(); } ;

variable: TIDENTIFIER 
	{ 	
		string tipo;
		try {
			tipo = codigo.obtenerTipo(*$1);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new variablestruct; 
		$$->nom = *$1;
		$$->tipo = tipo;
	} ;

expresion : expresion TCEQ expresion
	  {
		try{
			codigo.comprobarTipos($1->tipo, $3->tipo);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		$$->trues = codigo.iniLista(codigo.obtenRef());
		$$->falses = codigo.iniLista(codigo.obtenRef()+1);
		codigo.anadirInstruccion("if " + $1->nom + " = " + $3->nom + " goto");
		codigo.anadirInstruccion("goto");
		delete $1; delete $3;
	  }
	  | expresion TCGT expresion
	  {
		try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		$$->trues = codigo.iniLista(codigo.obtenRef());
		$$->falses = codigo.iniLista(codigo.obtenRef()+1);
		codigo.anadirInstruccion("if " + $1->nom + " > " + $3->nom + " goto");
		codigo.anadirInstruccion("goto");
		delete $1; delete $3;
	  } 
	  | expresion TCLT expresion
	  {
		try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		$$->trues = codigo.iniLista(codigo.obtenRef());
		$$->falses = codigo.iniLista(codigo.obtenRef()+1);
		codigo.anadirInstruccion("if " + $1->nom + " < " + $3->nom + " goto");
		codigo.anadirInstruccion("goto");
		delete $1; delete $3;
	  } 
	  | expresion TCGE expresion
	  {
		try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		$$->trues = codigo.iniLista(codigo.obtenRef());
		$$->falses = codigo.iniLista(codigo.obtenRef()+1);
		codigo.anadirInstruccion("if " + $1->nom + " >= " + $3->nom + " goto");
		codigo.anadirInstruccion("goto");
		delete $1; delete $3;
	  }
	  | expresion TCLE expresion
	  {
		try{
			codigo.comprobarTipos($1->tipo, Codigo::NUMERO);
			codigo.comprobarTipos($3->tipo, Codigo::NUMERO);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		$$->trues = codigo.iniLista(codigo.obtenRef());
		$$->falses = codigo.iniLista(codigo.obtenRef()+1);
		codigo.anadirInstruccion("if " + $1->nom + " <= " + $3->nom + " goto");
		codigo.anadirInstruccion("goto");
		delete $1; delete $3;
	  } 
	  | expresion TCNE expresion
	  {
		try{
			codigo.comprobarTipos($1->tipo, $3->tipo);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		$$->trues = codigo.iniLista(codigo.obtenRef());
		$$->falses = codigo.iniLista(codigo.obtenRef()+1);
		codigo.anadirInstruccion("if " + $1->nom + " != " + $3->nom + " goto");
		codigo.anadirInstruccion("goto");
		delete $1; delete $3;
	  }
	  | expresion RAND M expresion
	  {
		try {
			codigo.comprobarTipos($1->tipo, Codigo::BOOLEANO);
			codigo.comprobarTipos($4->tipo, Codigo::BOOLEANO);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		codigo.completarInstrucciones($1->trues, $3->ref);
		$$->trues = $4->trues;
		$$->falses = *codigo.unir($1->falses, $4->falses);
		delete $1; delete $3;
	  }
	  | expresion ROR M expresion
	  {
		try {
			codigo.comprobarTipos($1->tipo, Codigo::BOOLEANO);
			codigo.comprobarTipos($4->tipo, Codigo::BOOLEANO);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		codigo.completarInstrucciones($1->falses, $3->ref);
		$$->trues = *codigo.unir($1->trues, $4->trues);
		$$->falses = $4->falses;
		delete $1; delete $3;
	  }
	  | RNOT expresion
	  {
		try {
			codigo.comprobarTipos($2->tipo, Codigo::BOOLEANO);
		} catch (string s) {
			yyerror(s.c_str());
		}
		$$ = new expresionstruct;
		$$->nom = codigo.iniNom();
		$$->tipo = Codigo::BOOLEANO;
		$$->trues = $2->falses;
		$$->falses = $2->trues;
	  }
	  | expresion TPLUS expresion
	  {
		$$ = new expresionstruct;
		try{
			codigo.operacionAritmetica($$, *$1, *$3, *$2);
		} catch (string s) {
			yyerror(s.c_str());
			$$->nom = codigo.iniNom();
			$$->tipo = $1->tipo;
			$$->trues = codigo.iniLista(0);
			$$->falses = codigo.iniLista(0);
		}
		delete $1; delete $3;
	  } 
	  | expresion TMINUS expresion
	  {
		$$ = new expresionstruct;
		try{
			codigo.operacionAritmetica($$, *$1, *$3, "-");
		} catch (string s) {
			yyerror(s.c_str());
			$$->nom = codigo.iniNom();
			$$->tipo = $1->tipo;
			$$->trues = codigo.iniLista(0);
			$$->falses = codigo.iniLista(0);
		}
		delete $1; delete $3;
	  } 
	  | expresion TMUL expresion
	  {
		$$ = new expresionstruct;
		try{
			codigo.operacionAritmetica($$, *$1, *$3, "*");
		} catch (string s) {
			yyerror(s.c_str());
			$$->nom = codigo.iniNom();
			$$->tipo = $1->tipo;
			$$->trues = codigo.iniLista(0);
			$$->falses = codigo.iniLista(0);
		}
		delete $1; delete $3;
	  } 
	  | expresion TDIV expresion
	  {
		$$ = new expresionstruct;
		codigo.anadirInstruccion("if " + $3->nom + " = 0 goto ErrorDiv0;");
		try{
			codigo.operacionAritmetica($$, *$1, *$3, "/");
		} catch (string s) {
			yyerror(s.c_str());
			$$->nom = codigo.iniNom();
			$$->tipo = $1->tipo;
			$$->trues = codigo.iniLista(0);
			$$->falses = codigo.iniLista(0);
		}
		delete $1; delete $3;
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