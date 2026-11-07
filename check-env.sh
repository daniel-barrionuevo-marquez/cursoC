#!/usr/bin/env bash
# check-env.sh — verifica el entorno del curso de C
set -u
ok=0; ko=0
pass() { printf '  [OK]    %s\n' "$1"; ok=$((ok+1)); }
fail() { printf '  [FALLO] %s\n' "$1"; ko=$((ko+1)); }

echo "1. Herramientas"
for t in gcc clang make gdb valgrind strace ltrace objdump nm readelf \
         clang-tidy cppcheck git man; do
    if command -v "$t" >/dev/null 2>&1; then pass "$t"; else fail "$t no instalado"; fi
done

echo "2. Paginas de manual"
if man -w 3 printf  >/dev/null 2>&1; then pass "man 3 printf";  else fail "faltan manpages-dev"; fi
if man -w 3p printf >/dev/null 2>&1; then pass "man 3p printf"; else fail "faltan manpages-posix-dev"; fi

echo "3. Compilacion de prueba"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/t.c" <<'C'
#include <stdio.h>
int main(void) { printf("entorno listo\n"); return 0; }
C
for cc in gcc clang; do
    if $cc -std=c17 -Wall -Wextra -Wpedantic -Werror -g \
           -fsanitize=address,undefined "$tmp/t.c" -o "$tmp/t_$cc" 2>"$tmp/err" \
       && [ "$("$tmp/t_$cc")" = "entorno listo" ]; then
        pass "$cc con sanitizadores"
    else
        fail "$cc con sanitizadores: $(head -1 "$tmp/err")"
    fi
done

echo "4. Sanitizador detecta errores"
cat > "$tmp/bug.c" <<'C'
#include <stdlib.h>
int main(void) { int *p = malloc(4 * sizeof *p); p[4] = 1; free(p); return 0; }
C
gcc -g -fsanitize=address "$tmp/bug.c" -o "$tmp/bug" 2>/dev/null
if "$tmp/bug" 2>&1 | grep -q heap-buffer-overflow; then pass "ASan detecta desbordamiento"
else fail "ASan no funciona (en WSL1 no funciona: usa WSL2)"; fi

echo "5. Sistema"
case "$PWD" in /mnt/*) fail "estas en /mnt (disco de Windows): trabaja en ~";;
               *)      pass "directorio de trabajo en Linux";; esac

echo
echo "Resultado: $ok correctos, $ko fallos"
[ "$ko" -eq 0 ]
