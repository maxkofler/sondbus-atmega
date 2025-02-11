#include <avr/io.h>

.section .text
.global USART0_RX_vect
USART0_RX_vect:
    reti
