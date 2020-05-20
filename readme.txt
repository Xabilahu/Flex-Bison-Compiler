Práctica realizada por Xabier Lahuerta Vázquez

La parte grupal ha sido realizada en conjunto por el grupo DAX.o.
Integrantes:
    - Ainhoa Serrano
    - Daniel Cañadilas
    - Xabier Lahuerta

######### Estructura de Ficheros ##########

+-- Practica_XLahuerta
|   +-- Pruebas (Ficheros con los programas de prueba)
|   |   +-- PruebaBuenaX.in (Programa sin errores de compilación)
|   |   +-- PruebaMalaX.in (Programa con errores de compilación)
|   +-- src (Directorio con los ficheros fuente)
|   |   +-- Codigo.cpp (Implementación de las abstracciones funcionales)
|   |   +-- Codigo.hpp (Especificación de las abstracciones funcionales)
|   |   +-- main.cpp (Punto de entrada del compilador)
|   |   +-- parser.y (Implementación para Bison del ETDS)
|   |   +-- PilaTablaSimbolos.cpp (Implementación de las operaciones de la pila de tablas de símbolos)
|   |   +-- PilaTablaSimbolos.hpp (Especificación de las operaciones de la pila de tablas de símbolos)
|   |   +-- Structs.hpp (Especificación de las estructuras que almacenarán la información de los atributos)
|   |   +-- TablaSimbolos.cpp (Implementación de las operaciones de la tabla de símbolos)
|   |   +-- TablaSimbolos.hpp (Especificación de las operaciones de la tabla de símbolos)
|   |   +-- tokens.l (Especificación LEX de los símbolos que conforman la gramática)
|   +-- Makefile (Fichero Make para compilar y ejecutar el compilador)
|   +-- Documentacion_XLahuerta.pdf (Documentación de la práctica)
|   +-- readme.txt

############# Cómo se ejecuta #############

# Para compilar, desde la carpeta Practica_XLahuerta (donde se sitúa el Makefile), se debe ejecutar:
    $ make install

# Una vez compilado, se puede ejecutar el compilador sobre cualquier programa de pruebas así:
    $ ./src/parser < Pruebas/PruebaBuena1.in

# Se pueden ejecutar todas las pruebas del directorio Pruebas de esta manera:
    $ make test

# Se puede compilar y ejecutar con un solo comando:
    $ make

# Se pueden eliminar todos los ficheros generados por la compilación ejecutando:
    $ make clean

############### Dependencias ##############

- flex
    $ sudo apt install flex

- bison
    $ sudo apt install bison

- g++
    $ sudo apt install build-essential

################# Pruebas #################

Todos los ficheros de prueba contienen un comentario que explica el significado de la misma.
