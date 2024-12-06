
all:
	@mkdir -p target
	avr-gcc -g -mmcu=atmega2560 -xassembler -c sondbus-asm.asm -o target/sondbus-asm.asm.o
	avr-gcc -g -mmcu=atmega2560 -c test.c -o target/test.c.o
# avr-ld -m avr6 -o sondbus-asm target/sondbus-asm.asm.o target/test.c.o
	avr-gcc -g -mmcu=atmega2560 -lm -o sondbus-asm target/test.c.o target/sondbus-asm.asm.o

asm-only:
# avr-gcc -mmcu=atmega2560 -xassembler -c sondbus-asm.asm -o target/sondbus-asm.asm.o
	@mkdir -p target
	avr-as -m avr6 --gstabs+ sondbus-asm.asm -o target/sondbus-asm.asm.o
	avr-ld -m avr6 -o sondbus-asm target/sondbus-asm.asm.o