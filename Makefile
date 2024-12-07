
all:
	@mkdir -p target
	avr-gcc -g -mmcu=atmega2560 -xassembler -c asm/sondbus-asm.asm -o target/sondbus-asm.asm.o
	avr-gcc -g -mmcu=atmega2560 -c test.c -o target/test.c.o
	avr-gcc -g -mmcu=atmega2560 -lm -o sondbus-asm target/test.c.o target/sondbus-asm.asm.o
