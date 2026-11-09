# CLASE 0 — EL ENTORNO DE TRABAJO

El entorno será Ubuntu LTS dentro de Windows 11 mediante WSL2. Se chequea configuración mediante el guion `check-env.sh`.

Se instalan las siguientes herramientas:

| Paquete | Qué aporta | Dónde lo usarás |
| --- | --- | --- |
| `build-essential` | `gcc`, `make`, cabeceras de la libc, `binutils` | Todo el curso |
| `clang`, `clang-tidy` | Segundo compilador y análisis estático | Desde el Tema 1; Tema 19 |
| `libclang-rt-dev` | Bibliotecas de los sanitizadores para `clang`; sin él, `clang -fsanitize=address` no enlaza | Desde el Tema 1 |
| `gdb` | Depurador | Desde el Tema 1; Tema 18 |
| `valgrind` | Detección de errores de memoria y perfilado | Tema 10 en adelante |
| `strace`, `ltrace` | Trazar llamadas al sistema y a bibliotecas | Temas 18 y 30 |
| `cppcheck` | Análisis estático | Tema 19 |
| `git` | Control de versiones | Desde hoy |
| `manpages-dev`, `manpages-posix-dev`, `man-db` | Manual de la biblioteca de C y de POSIX | Desde hoy |

## Compiler Explorer

godbolt.org compila en el navegador y muestra el ensamblador al lado del fuente, con colores q relacionan cada línea de C con sus instrucciones.

=====================================================================

# CLASE 1 — EL LENGUAJE Y SU CADENA DE HERRAMIENTAS

## 1.1. POR QUÉ EXISTE C

C no nació de un comité ni de una teoría: nación porque Ken Thompson y Denis Ritchie necesitaban un lenguaje en el q escribir un SO q no quedara atado a una sola máquina. Entender ese origen explica casi todas las decisiones del lenguaje q parecerán extrañas.

### 1.1.1. De BCPL a B, y de B a C

- BCPL (Martin Richards, 1967): lenguaje de sistemas sin tipos. Todo era una “palabra” de máquina.
- B (Ken Thompson, hacia 1969): BCPL reducido para caber en el PDP-7 donde nació Unix. Seguía sin tipos.
- El problema del PDP-11 (1970): una máquina direccionable por bytes, con enteros de 16 bits y, más tarde, coma flotante. Un lenguaje donde todo es una palabra no puede distinguir un caracter de un entero ni de un flotante, y la aritmética de punteros por palabras no encaja con direcciones por bytes.
- C (1971 - 1973): B con tipos (`char`, `int`, `float`), `structs` y una aritmética de punteros q escala por el tamaño del tipo. Esa última idea — q `p+1` avance `sizeof(*p)` bytes — viene directamente de este problema.

### 1.1.2. Unix reescrito en C

En 1973 reescriben el núcleo de Unix en C. Hasta entonces se daba por hecho q un SO se escribía en ensamblador. La consecuencia fue la portabilidad: llevar Unix a otra máquina pasó a significar escribir un compilador de C para ella y adaptar una pequeña parte dependiente del hardware, no reescribirlo todo.

### 1.1.3. Los estándares

| Año | Estándar | Lo esencial que aportó |
| --- | --- | --- |
| 1978 | K&R (1.ª edición del libro) | Definición de facto del lenguaje durante una década |
| 1989/1990 | ANSI C / C89 / C90 | Prototipos de función, `void`, `const`, biblioteca estándar definida |
| 1999 | C99 | `long long`, `//`, `<stdint.h>`, `inline`, `_Bool`, inicializadores designados, VLA |
| 2011 | C11 | `_Generic`, hilos y atómicos, `_Static_assert`, structs y uniones anónimos |
| 2018 | C17 | Sólo correcciones de C11; la base de este curso |
| 2024 | C23 | `nullptr`, `constexpr`, `typeof`, `#embed`, `bool` como palabra clave (Tema 47) |

La segunda edición de K&R (1988) describe ANSI C y sigue siendo el libro del curso: el núcleo del lenguaje apenas ha cambiado desde entonces.

### 1.1.4. La filosofía

El documento de justificación del estándar ANSI recogió lo q llamó el espíritu de C. Resumido en palabras:

1. Confía en el programador. El lenguaje no te impide hacer lo q necesitas hacer.
2. Mantén el lenguaje pequeño y simple. Lo q puede ser una función de biblioteca no entra en el lenguaje.
3. Una sola forma de hacer cada operación, en lo posible.
4. Q sea rápido, aunq no se garantice q sea portable. El compilador traduce a la operación natural de la máquina.

El precio de estos principios es q C no te protege. Por eso este curso dedica tanto espacio a herramientas (sanitizadores, Valgrind, avisos del compilador) y, en la Parte VI, al comportamiento indefinido: la libertad q da C hay q pagarla con disciplina.

## 1.2. DEL FUENTE AL EJECUTABLE

La orden `gcc hola.c -o hola` no es un programa: es un directo q llama a 4 programas seguidos, y al ejecutar el resultado intervienen otros 2. Las salidas de esta sección son reales, obtenidas con `GCC 13.3` en `Ubuntu 24.04`.

!image.png

Cada etapa puede detenerse con una opción de gcc para inspeccionar su fichero; las subsecciones siguientes recorren el diagrama de arriba abajo.

1. El programa de trabajo, `hola.c` .
2. Preprocesado: `gcc -E hola.c -o hola.i` .
    1. Trabaja sobre texto, sin saber nada de C.
3. Compilación a ensamblador: `gcc -S -fno-asynchronous-unwind-tables -fno-pie hola.c -o hola.s` .
4. Ensamblado a código objeto: `gcc -c hola.c -o hola.o` .
    1. `hola.o` es un fichero ELF (*Executable and Linkeable Format*) reubicable: código máquina con huecos.
5. Enlazado: `gcc hola.o -o hola.exe` .
    1. El enlazador junta `hola.o` con piezas como el código de arranque y cierre del programa.
6. Carga y ejecución: `./hola.exe` .

| Fichero | Tamaño medido | Qué contiene | Cómo inspeccionarlo |
| --- | --- | --- | --- |
| `hola.c` | 111 B | Tu código fuente | `cat` |
| `hola.i` | 21 318 B | Fuente preprocesado: cabeceras copiadas, macros sustituidas | `less` |
| `hola.s` | 665 B | Ensamblador x86-64 | `less` |
| `hola.o` | 1 496 B | Código máquina reubicable, con huecos | `nm`, `objdump -d -r`, `readelf` |
| `hola` | 15 960 B | Ejecutable ELF enlazado dinámicamente | `readelf -h`, `ldd`, `strace` |

## 1.3. TU PRIMER PROGRAMA, LÍNEA A LÍNEA

Cinco líneas de C contienen 3 contratos: con el compilador (la declaración), con el SO (el valor de retorno) y con la biblioteca (la cadena de formato). Romper cualquiera de ellos tiene consecuencias q conviene ver una vez.

### 1.3.1. `#include <stdio.h>`: declarar no es definir

- Una cabecera declara: dice q `printf`  existe, q tipo devuelve y q argumentos recibe. No contiene su código.
- La biblioteca define: el código de `printf` está en `libc.so.6` y llega en el enlazado.
- `<…>` frente a `“…”`: los ángulos buscan en los directorios del sistema; las comillas buscan primero junto a tu fichero. Usa ángulos para la biblioteca estándar y comillas para tus cabeceras.

Si quitas el `#include` e intentas compilar, da error.

### 1.3.2. `int main(void)`: el contrato con el sistema

- Las dos formas q el estándar garantiza: `int main(void)` y `int main(int argc, char *argv[])`. Cualquier otra (`void main()`) no es C estándar.
- `(void)` frente a `()`: hasta C17, `int main()` significa `“argumentos no especificados”`, no `“sin argumentos”`. Escribe siempre `(void)`.
- El valor de retorno es el estado de salida del proceso: `0` o `EXIT_SUCCESS` indica éxito; `EXIT_FAILURE` indica fallo. Ambas macros están en `<stdlib.h>`.
- Regla especial de `main`: si la ejecución llega a la `}` final sin `return`, desde C99 equivale a `return 0`. Solo vale para `main`; en cualquier otra función q devuelva un valor es un error. Aun así, en este curso escribiremos el `return` explicícito.

### 1.3.3. `printf`: una cadena de formato es un programa pequeño

- La cadena de formato mezcla testo literal y especificadores (`%d`, `%s`, `%f`, …). Cada especificador consume un argumento del tipo exacto q indica.
- `printf` es `variádica`: su prototipo termina en `…`, así q el compilador no puede convertir los argumentos al tipo correcto. Si el tipo no coincide, el comportamiento es indefinido.

### 1.3.4. Estilo

El formato de este programa es el de K&R: llave de la función en su propia línea, llaves de bloque en la misma línea q la sentencia, sangría de 4 espacios, un espacio tras las palabras clave (`if ()`, no `if()`). No hay un estilo correcto, pero sí uno coherente: elige este y no mezcles.
