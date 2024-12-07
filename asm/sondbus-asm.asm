;
; Assembly implementation of sondbus for AVR controllers
;

.include "sondbus-definitions.asm"

.section .data
.section .text

.global sondbus_rx

; Process an incoming byte from the sondbus interface
; Call Registers:
; - r22: Incoming byte
; - r24-25: Sondbus memory area pointer
; Returns
; - r24: Ougoing byte (if any)
; - r25: Status:
;       - 0: Outgoing byte is valid and can be sent
sondbus_rx:
    push r0
    push r1
    push r17
    push r18
    push XL
    push XH
    push YL
    push YH
    push ZL
    push ZH

    ; Move the address of sondbus-structures into X
    mov XL, r24
    mov XH, r25

    ldi r24, 0
    ldi r25, 0
    ;
    ; Calculate the jump table
    ;

    ; Load the first table entry into Z
    ldi ZH, pm_hi8(sondbus_state_trampoline)
    ldi ZL, pm_lo8(sondbus_state_trampoline)

    ; We multiply the current state (X) by the size of each state handler
    ld r18, X
    ldi r16, SB_STATE_SIZE / 2  ; We need to divide by two here, instructions are 2 bytes long
    mul r18, r16

    ; Add the offset to Z
    add ZL, r0
    adc ZH, r1

    ; Jump to Z
    ijmp

sondbus_rx_return:
    pop ZH
    pop ZL
    pop YH
    pop YL
    pop XH
    pop XL
    pop r18
    pop r17
    pop r1
    pop r0
    ret

sondbus_rx_next_state_and_return:
    ld r17, X
    inc r17
    st X, r17
    jmp sondbus_rx_return

sondbus_rx_new_state_and_return:
    ; Expects the new state in register 22
    st X, r22
    jmp sondbus_rx_return

;
; This is the start of the state matrix
;
sondbus_state_trampoline:

;
; Check if the incoming byte is the start byte.
; If it is, go to the next state, else stay.
;
sondbus_state_wait_for_start:

    ; Check if r17 is equal to the start byte
    cpi r22, SB_START_BYTE
    breq sondbus_state_wait_for_start_eq
    jmp sondbus_rx_return
sondbus_state_wait_for_start_eq:
    adiw X, SBR_TEMP_CRC
    ldi r24, SB_CRC_INIT
    call sb_crc8_update
    st X, r24
    sbiw X, SBR_TEMP_CRC

    jmp sondbus_rx_next_state_and_return

;
; Accept the incoming byte as the frame type
;
.org(sondbus_state_trampoline + (SB_STATE_SIZE))
sondbus_state_wait_for_type:
    call update_crc
    ldi r17, SBR_CUR_FRAME_TYPE
    ldi r18, 0
    add XL, r17
    adc XH, r18

    st X, r22

    sub XL, r17
    sbc XH, r18

    jmp sondbus_rx_next_state_and_return

;
; Accept the incoming byte as the address
;
.org(sondbus_state_trampoline + (SB_STATE_SIZE * 2))
sondbus_state_wait_for_address:
    call update_crc
    ldi r17, SBR_GP_ADDRESS
    ldi r18, 0
    add XL, r17
    adc XH, r18

    st X, r22

    sub XL, r17
    sbc XH, r18

    jmp sondbus_rx_next_state_and_return

;
; Accept the incoming byte as the payload length
;
.org(sondbus_state_trampoline + (SB_STATE_SIZE * 3))
sondbus_state_wait_for_length:
    call update_crc
    adiw X, SBR_BYTES_REMAINING
    st X, r22
    sbiw X, SBR_BYTES_REMAINING

    adiw X, SBR_CUR_FRAME_TYPE
    ld r22, X
    sbiw X, SBR_CUR_FRAME_TYPE

    cpi r22, 1

    brsh sondbus_state_wait_for_length_unknown_type

    ;call sondbus_handler_setup_ping

    ldi r22, 0x10
    st X, r22
    jmp sondbus_rx_return

sondbus_state_wait_for_length_unknown_type:
    ldi r22, 0
    st X, r22
    jmp sondbus_rx_return

;
; PING: Wait for the incoming payload bytes to pass by
;
.org(sondbus_state_trampoline + (SB_STATE_SIZE * 0x10))
sondbus_state_ping_rx:
    call update_crc
    adiw X, SBR_BYTES_REMAINING
    ld r22, X

    dec r22

    st X, r22
    sbiw X, SBR_BYTES_REMAINING

    cpi r22, 0

    breq sondbus_state_ping_rx_done
    jmp sondbus_rx_return

sondbus_state_ping_rx_done:
    jmp sondbus_rx_next_state_and_return

.org(sondbus_state_trampoline + (SB_STATE_SIZE * 0x11))
sondbus_state_ping_wait_for_crc:
    ; r22 holds the crc

    ; Load the temporary CRC
    adiw X, SBR_TEMP_CRC
    ld r24, X
    sbiw X, SBR_TEMP_CRC

    call sb_crc8_finalize

    cp r24, r22

    breq sondbus_state_ping_good_crc

    ; If the CRC is bad, go back to idle
    ldi r24, 0
    st X, r24

sondbus_state_ping_good_crc:
    sbr r25, 0b1
    ldi r24, SB_START_BYTE
    jmp sondbus_rx_next_state_and_return

.org(sondbus_state_trampoline + (SB_STATE_SIZE * 0x12))
sondbus_state_ping_type:
    sbr r25, 0b1
    ldi r24, SB_FT_PING
    jmp sondbus_rx_next_state_and_return

.org(sondbus_state_trampoline + (SB_STATE_SIZE * 0x13))
sondbus_state_ping_address:
    sbr r25, 0b1
    ldi r24, 0
    jmp sondbus_rx_next_state_and_return

.org(sondbus_state_trampoline + (SB_STATE_SIZE * 0x14))
sondbus_state_ping_length:
    sbr r25, 0b1
    ldi r24, 0
    jmp sondbus_rx_next_state_and_return

.org(sondbus_state_trampoline + (SB_STATE_SIZE * 0x15))
sondbus_state_ping_crc:
    sbr r25, 0b1
    ldi r24, 0
    st X, r24
    jmp sondbus_rx_return

; Expects new value at r22
update_crc:
    adiw X, SBR_TEMP_CRC
    ld r24, X
    call sb_crc8_update
    st X, r24
    sbiw X, SBR_TEMP_CRC
    ret
