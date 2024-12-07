
.global sb_crc8_init
.global sb_crc8_update
.global sb_crc8_finalize
.global SB_CRC_INIT

; Values for CRC8 AUTOSAR
.equ    SB_CRC_INIT,           0xFF
.equ    SB_CRC_POLY,           0x2F
.equ    SB_CRC_XOR_OUT,        0xFF

; Return registers
; - r24: Initial temporary CRC
sb_crc8_init:
    ldi r24, SB_CRC_INIT
    ret

; Call registers
; - r24: Temporary CRC
; - r22: Data
; Return registers
; - r24: Temporary CRC
sb_crc8_update:
    eor r24, r22

    push r22
    call sb_crc_step
    call sb_crc_step
    call sb_crc_step
    call sb_crc_step
    call sb_crc_step
    call sb_crc_step
    call sb_crc_step
    call sb_crc_step
    pop r22

    ret

sb_crc_step:
    sbrs r24, 7
    jmp sb_crc_step_bit_7_clear
    jmp sb_crc_step_bit_7_set

sb_crc_step_bit_7_clear:
    lsl r24
    ret

sb_crc_step_bit_7_set:
    lsl r24
    ldi r22, SB_CRC_POLY
    eor r24, r22
    ret


; Call registers
; - r24: Input CRC
; Return registers
; - r24: Finalized CRC
sb_crc8_finalize:
    ldi r25, SB_CRC_XOR_OUT
    eor r24, r25
    ret
