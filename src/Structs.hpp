#ifndef STRUCTS_HPP_
#define STRUCTS_HPP_
struct bloquestruct{
	std::vector<int> exits;
};

struct lista_de_identstruct{
	std::vector<std::string> lnom;
};

struct resto_lista_idstruct{
	std::vector<std::string> lnom;
};

struct tipostruct{
	std::string clase;
};

struct clase_parstruct{
	std::string tipo;	
};

struct lista_de_sentenciasstruct
{
	std::vector<int> exits;
};

struct sentenciastruct{
	std::vector<int> exits;	
};

struct mstruct{
	int ref;	
};

struct variablestruct{
	std::string nom;
	std::string tipo;
};

struct expresionstruct {
  std::string nom ;
  std::string tipo ;
  std::vector<int> trues ;
  std::vector<int> falses ;
};
#endif /* STRUCTS_HPP_ */
