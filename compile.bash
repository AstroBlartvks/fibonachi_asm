nasm -f elf64 main.asm -o linux/main.o
ld -s -o linux/main linux/main.o