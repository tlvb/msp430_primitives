.include "msp430g2x31.inc"
; vim: set syntax=msp:

dly_dit equ 0x4fff
dly_dah equ 0xeffd

usout equ P1OUT
usdir equ P1DIR
ustxp equ 0x40
usbitdly equ 0x65




org 0xfffe
interrupt_table:																; {{{
; --------------------------------------------------------------------------------------------------------------------------------
						dw			MAIN_ENTRY_POINT							; set reset vector to point to the MAIN_ENTRY_POINT label
; }}}
org 0xf800

configure_i2c_master:															; {{{
; --------------------------------------------------------------------------------------------------------------------------------
						bis.b		#USISWRST, &USICTL0							; put in reset mode
						bis.b		#(USIPE6|USIPE7|USIMST), &USICTL0			; port enable and master transmit mode
						bis.b		#USII2C, &USICTL1							; enable i2c mode
						bis.b		#(USIDIV_5|USISSEL_2|USICKPL), &USICKCTL	; clock prescaler source and polarity select
						bic.b		#USISWRST, &USICTL0
						ret
; }}}
transmit_byte_get_ack:															; {{{
;						ARG:		r4: ack aggregate so far
;						RET:		r4: r4 shifted left | last ack value
; --------------------------------------------------------------------------------------------------------------------------------
						bis.b		#0x02, &P1OUT

						bis.b		#USIOE, &USICTL0							; enable output
						mov.b		#0x08, &USICNT								; send 8 bits
transmit_byte_wait0:	bit.b		#USIIFG, &USICTL1							; check if flag is set
						jz			transmit_byte_wait0							; loop if not

						bic.b		#USIOE, &USICTL0							; disable output
						mov.b		#0x01, &USICNT								; receive one bit
transmit_byte_wait1:	bit.b		#USIIFG, &USICTL1							; check if flag is set
						jz			transmit_byte_wait1							; loop if not
						bis.b		#USIOE, &USICTL0							; enable output

						add.w		r4, r4										; shift r4 to left
						bis.b		&USISRL, r4

						bic.b		#0x02, &P1OUT
						ret
; }}}
receive_byte_set_ack:	; and receive_byte_set_nack:												; {{{
;						ARG:		- none -
;						RET:		r5: received data
; --------------------------------------------------------------------------------------------------------------------------------
						push		r6
						mov.b		#0x00, r6
						jmp			receive_byte_set_acknack
receive_byte_set_nack:
						push		r6
						mov.b		#0xff, r6
receive_byte_set_acknack:
						bis.b		#0x02, &P1OUT

						bic.b		#USIOE, &USICTL0							; disable output
						mov.b		#0x08, &USICNT								; receive eight bits
receive_one_byte_wait0:	bit.b		#USIIFG, &USICTL1							; check if flag is set
						jz			receive_one_byte_wait0						; loop if not
						mov.b		&USISRL, r5									; harvest received data

						bis.b		#USIOE, &USICTL0							; enable output
						mov.b		r6, &USISRL									; ack or nack bit
						mov.b		#0x01, &USICNT								; write one bit
receive_one_byte_wait1:	bit.b		#USIIFG, &USICTL1							; check if flag is set
						jz			receive_one_byte_wait1						; loop if not

						bic.b		#0x02, &P1OUT
						pop			r6
						ret
; }}}
generate_start:																	; {{{
;
;          0
; ____.____.    .
;     .    \____. SCA
;     .    .
; ____.____.____.
;     .    .    . SCL
;          |
;
; --------------------------------------------------------------------------------------------------------------------------------
						mov.b		#0x00, &USISRL								; msb = 0
						bis.b		#(USIOE|USIGE), &USICTL0					; transparent latch (0)
						bic.b		#USIGE, &USICTL0							; disable latch
						ret
; }}}
generate_restart:																	; {{{
;
;          0
;     .____.    .
; XXXX.    \____. SCA
;     .    .
; ____.____.____.
;     .    .    . SCL
;          |
;
; --------------------------------------------------------------------------------------------------------------------------------
						bis.b		#USIOE, &USICTL0							; output enable
						mov.b		#0xff, &USISRL								; msb = 1
						mov.b		#0x01, &USICNT								; one bit to send (0)
generate_restart_wait:	bit.b		#USIIFG, &USICTL1							; check if flag is set
						jz			generate_restart_wait							; loop if not
						mov.b		#0x00, &USISRL								; msb = 0
						bis.b		#USIGE, &USICTL0							; make latch transparent (1)
						bic.b		#(USIGE|USIOE), &USICTL0					; disable output
						ret
; }}}
generate_stop:																	; {{{
;
;     00000000001111122222
;     .    .    .____.____.
; XXXX.____.____/    .    . SCA
;     .    .    .    .
;     .    .____.____.____.
; ____.____/    .    .    . SCL
;               |
;
; --------------------------------------------------------------------------------------------------------------------------------
						bis.b		#USIOE, &USICTL0							; output enable
						mov.b		#0x00, &USISRL								; msb = 0
						mov.b		#0x01, &USICNT								; one bit to send (0)
generate_stop_wait:		bit.b		#USIIFG, &USICTL1							; check if flag is set
						jz			generate_stop_wait							; loop if not
						mov.b		#0xff, &USISRL								; msb = 1
						bis.b		#USIGE, &USICTL0							; make latch transparent (1)
						bic.b		#(USIGE|USIOE), &USICTL0					; disable output

						ret
; }}}






