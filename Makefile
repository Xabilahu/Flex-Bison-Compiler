CFLAGS=-Wall -g
TESTDIR=Pruebas
SRCDIR=src

all: $(SRCDIR)/parser prueba

clean:
	rm $(SRCDIR)/parser.cpp $(SRCDIR)/parser.hpp $(SRCDIR)/parser $(SRCDIR)/tokens.cpp 

$(SRCDIR)/parser.cpp: $(SRCDIR)/parser.y $(SRCDIR)/Codigo.hpp
	bison -d -o $@ $<

$(SRCDIR)/tokens.cpp: $(SRCDIR)/tokens.l $(SRCDIR)/parser.hpp
	lex -o $@ $^

$(SRCDIR)/parser: $(SRCDIR)/parser.cpp $(SRCDIR)/main.cpp $(SRCDIR)/tokens.cpp $(SRCDIR)/Codigo.hpp
	g++ $(CFLAGS) -o $@ $(SRCDIR)/*.cpp 

prueba:  $(SRCDIR)/parser  $(TESTDIR)/PruebaBuena1.in $(TESTDIR)/PruebaBuena2.in $(TESTDIR)/PruebaBuena3.in $(TESTDIR)/PruebaBuena4.in $(TESTDIR)/PruebaMala1.in $(TESTDIR)/PruebaMala2.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena1.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena2.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena3.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaBuena4.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala1.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala2.in
	$(SRCDIR)/parser < $(TESTDIR)/PruebaMala3.in
