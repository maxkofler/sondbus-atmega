.include "sondbus-definitions.asm"

.global sb_state_wait_for_start
.global sb_state_wait_for_type
.global sb_state_wait_for_address
.global sb_state_wait_for_length

;
;   Wait for the start byte
;
sb_state_wait_for_start:
    cpi r22, SB_START_BYTE
    breq start_byte_received
    jmp sb_handle_return

start_byte_received:
    ; Start the CRC calculation with the start byte
    ldi r24, SB_CRC_INIT

    call sb_crc8_update

    adiw X, SBR_TEMP_CRC
    st X, r24
    sbiw X, SBR_TEMP_CRC

    jmp sb_next_state_and_return

;
;   Wait for the frame type
;
sb_state_wait_for_type:
    call sb_update_crc
    adiw X, SBR_CUR_FRAME_TYPE
    st X, r22
    sbiw X, SBR_CUR_FRAME_TYPE

    jmp sb_next_state_and_return

sb_state_wait_for_address:
    call sb_update_crc
    adiw X, SBR_GP_1
    st X, r22
    sbiw X, SBR_GP_1

    jmp sb_next_state_and_return

sb_state_wait_for_length:
    call sb_update_crc
    adiw X, SBR_BYTES_REMAINING
    st X, r22
    sbiw X, SBR_BYTES_REMAINING

    ldi r22, sb_state_handler_ping
    jmp sb_new_state_and_return
