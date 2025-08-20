del main.exe
del main.obj

nasm -f elf32 -g -F dwarf -o main.o main.asm
gcc -m32 main.o -o main.exe -Wl,-subsystem,console -lkernel32 -luser32