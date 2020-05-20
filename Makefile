CFLAGS=-Wall -g
TESTDIR=Pruebas
SRCDIR=src

all: install test

$(SRCDIR)/parser.cpp: $(SRCDIR)/parser.y $(SRCDIR)/Codigo.hpp
	bison -d -o $@ $<

$(SRCDIR)/tokens.cpp: $(SRCDIR)/tokens.l $(SRCDIR)/parser.hpp
	lex -o $@ $^

install: $(SRCDIR)/parser.cpp $(SRCDIR)/main.cpp $(SRCDIR)/tokens.cpp $(SRCDIR)/Codigo.cpp $(SRCDIR)/PilaTablaSimbolos.cpp $(SRCDIR)/TablaSimbolos.cpp
	g++ $(CFLAGS) -o $(SRCDIR)/parser $^

clean:
	rm $(SRCDIR)/parser.cpp $(SRCDIR)/parser.hpp $(SRCDIR)/parser $(SRCDIR)/tokens.cpp 

test: $(SRCDIR)/parser $(TESTDIR)/*.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena1.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena2.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena3.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena4.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena5.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena6.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena7.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala1.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala2.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala3.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala4.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala5.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala6.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala7.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala8.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala9.in
