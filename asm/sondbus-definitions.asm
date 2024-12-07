;
; Internal contracts:
; - X will always contain a pointer to the 'sondbus' memory register struct
;

;
; Public interfaces / reserved memory registers
;
.equ SBR_STATE,             0x00
.equ SBR_BYTES_REMAINING,   0x01
.equ SBR_MY_ADDRESS,        0x02
.equ SBR_CUR_FRAME_TYPE,    0x03
.equ SBR_TEMP_CRC,          0x04
.equ SBR_GP_1,              0x05
.equ SBR_GP_2,              0x06

;
; Internal aliases for the memory registers
;
.equ SBR_GP_ADDRESS,        SBR_GP_1    ; The address of the frame

;
; General definitions
;
.equ SB_START_BYTE, 0x55		;	The start byte for sondbus
.equ SB_STATE_SIZE, 0x20        ;   The size of a state handler

;
; Frame types
;

.equ SB_FT_PING,            0x00        ; The PING frame type
