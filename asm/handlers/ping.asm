.include "sondbus-definitions.asm"

.global sb_state_handler_ping_wait_for_payload
.global sb_state_handler_ping_wait_for_crc
.global sb_state_handler_ping_tx_start
.global sb_state_handler_ping_tx_type
.global sb_state_handler_ping_tx_address
.global sb_state_handler_ping_tx_length
.global sb_state_handler_ping_tx_crc

sb_state_handler_ping_wait_for_payload:
    call sb_update_crc

    adiw X, SBR_BYTES_REMAINING
    ld r23, X
    dec r23
    st X, r23
    sbiw X, SBR_BYTES_REMAINING

    cpi r23, 0
    breq rx_complete

    jmp sb_handle_return

rx_complete:
    jmp sb_next_state_and_return

sb_state_handler_ping_wait_for_crc:
    ; Check the CRC
    adiw X, SBR_TEMP_CRC
    ld r24, X
    sbiw X, SBR_TEMP_CRC

    call sb_crc8_finalize

    cp r24, r22
    breq crc_good

    ldi r22, 0
    jmp sb_new_state_and_return

crc_good:
    ; Return the first byte - the start byte
    sbr r25, 0b1
    ldi r24, SB_START_BYTE
    jmp sb_next_state_and_return

sb_state_handler_ping_tx_type:
    sbr r25, 0b1
    ldi r24, 0
    jmp sb_next_state_and_return

sb_state_handler_ping_tx_address:
    sbr r25, 0b1
    ldi r24, 0
    jmp sb_next_state_and_return

sb_state_handler_ping_tx_length:
    sbr r25, 0b1
    ldi r24, 0
    jmp sb_next_state_and_return

sb_state_handler_ping_tx_crc:
    sbr r25, 0b1
    ldi r24, 0
    ldi r22, 0
    jmp sb_new_state_and_return
