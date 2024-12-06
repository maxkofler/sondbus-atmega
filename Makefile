
all:
	avr-as -m avr6 --gstabs+ sondbus-asm.asm -o target/sondbus-asm.asm.o
	avr-ld -m avr6 -o sondbus-asm target/sondbus-asm.asm.o
