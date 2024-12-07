;
; Assembly implementation of sondbus for AVR controllers
;

.include "sondbus-definitions.asm"

.section .data
.section .text

.global sondbus_handle

.global sb_update_crc
.global sb_handle_return
.global sb_next_state_and_return
.global sb_new_state_and_return

.global sb_state_handler_ping
.equ sb_state_handler_ping, ((state_handler_ping - state_trampoline) / 2)

; Process an incoming byte from the sondbus interface
; Call Registers:
; - r22: Incoming byte
; - r24-25: Sondbus memory area pointer
; Returns
; - r24: Ougoing byte (if any)
; - r25: Status:
;       - 0: Outgoing byte is valid and can be sent
sondbus_handle:
    ;Registers available: 22, 23, 24, 25
    push XL
    push XH
    push YL
    push YH
    push ZL
    push ZH

;   --- Setup

    mov XL, r24
    mov XH, r25

    ldi r24, 0
    ldi r25, 0

    ; Load the current state into r23
    ld r23, X

    ; Check that the state is not out-of-bounds
    cpi r23, (sb_handle_return - state_trampoline) / 2
    brsh sondbus_state_out_of_bounds

    ldi ZH, pm_hi8(state_trampoline)
    ldi ZL, pm_lo8(state_trampoline)

    add ZL, r23
    ldi r23, 0
    adc ZH, r23

    ijmp

state_trampoline:
    rjmp sb_state_wait_for_start
    rjmp sb_state_wait_for_type
    rjmp sb_state_wait_for_address
    rjmp sb_state_wait_for_length
state_handler_ping:
    rjmp sb_state_handler_ping_wait_for_payload
    rjmp sb_state_handler_ping_wait_for_crc
    rjmp sb_state_handler_ping_tx_type
    rjmp sb_state_handler_ping_tx_address
    rjmp sb_state_handler_ping_tx_length
    rjmp sb_state_handler_ping_tx_crc

;   --- Return
sb_handle_return:

    pop ZH
    pop ZL
    pop YH
    pop YL
    pop XH
    pop XL

    ret

;   Moves the state counter one up and returns
;   Uses r22 to do so
sb_next_state_and_return:
    ld r22, X
    inc r22
    st X, r22
    jmp sb_handle_return

;   Stores r22 into the state field and returns
sb_new_state_and_return:
    st X, r22
    jmp sb_handle_return

sb_update_crc:
    push r24

    adiw X, SBR_TEMP_CRC
    ld r24, X

    call sb_crc8_update

    st X, r24
    sbiw X, SBR_TEMP_CRC

    pop r24
    ret

sondbus_state_out_of_bounds:
    ; TODO: Handle this
    ldi r22, 0
    jmp sb_new_state_and_return
