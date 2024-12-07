
MCU=atmega2560

CC=avr-gcc
AS=${CC}
LD=${CC}

CCFLAGS=-g -mmcu=${MCU}
ASFLAGS=-g -mmcu=${MCU} -xassembler -Iasm
LDFLAGS=-g -mmcu=${MCU}

ASMFILES+=asm/sondbus-asm.asm.o
ASMFILES+=asm/crc8.asm.o

CFILES+=test.c.o

sondbus-asm: ${ASMFILES} ${CFILES}
	${LD} ${LDFLAGS} -o $@ $(foreach wrd,$^,target/$(wrd))

%.asm.o: %.asm
	@mkdir -p target/$(dir $@)
	${AS} ${ASFLAGS} -c $^ -o target/$@

%.c.o: %.c
	@mkdir -p target/$(dir $@)
	${CC} ${CCFLAGS} -c $^ -o target/$@

target_dir:
	@mkdir -p target
