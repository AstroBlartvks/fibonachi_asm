nasm -f win64 main.asm -o windows/main.o
ld windows/main.o -o windows/main.exe