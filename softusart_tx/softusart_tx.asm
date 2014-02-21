.include "msp430g2x31.inc"
; vim: set syntax=msp:

dly_dit equ 0x4fff
dly_dah equ 0xeffd

SUS_TXPIN equ 0x42
SUS_TXDIR equ P1DIR
SUS_TXOUT equ P1OUT
// static softusart variables
SUS_TXB equ 0x0200
SUS_TXS equ 0x0202

org 0xfff2
interrupt_table:																; {{{
; --------------------------------------------------------------------------------------------------------------------------------
						dw			SUS_TACCR0_CCIFG_HANDLER
						dw			MAIN_ENTRY_POINT
						dw			MAIN_ENTRY_POINT
						dw			MAIN_ENTRY_POINT
						dw			MAIN_ENTRY_POINT
						dw			MAIN_ENTRY_POINT
						dw			MAIN_ENTRY_POINT							; set reset vector to point to the MAIN_ENTRY_POINT label
; }}}
org 0xf800
MAIN_ENTRY_POINT:																; {{{
; --------------------------------------------------------------------------------------------------------------------------------
						mov.w		#0x0280, sp									; set up stack
						mov.w		#(WDTPW|WDTHOLD), &WDTCTL					; disable watchdog

						;bis.b		#0x10, &P1DIR								; smclck output on P1:4 for debugging
						;bis.b		#0x10, &P1SEL

						;bis.b		#0x41, &P1DIR								; red and green led as outputs

						mov.b		#0x00, &DCOCTL								; clock setup, SMCLK using DCO 1MHz
						mov.b		&0x10ff, &BCSCTL1							; the CAL**_1MHz mnemonics does not exist in my include file
						mov.b		&0x10fe, &DCOCTL							; so I have yanked the addresses directly from the datasheet

						call		#sus_setup									; setup softusart
						eint
						mov.b		#0x00, r5

IDLE_LOOP_START:		tst			&SUS_TXS									; check if transmission going on
						jnz			IDLE_LOOP_START

						mov.b		r5, &SUS_TXB
						call		#sus_transmit
						inc.b		r5

						mov.w		#0xffff, r4
delay:					dec			r4
						jnz			delay
						jmp			IDLE_LOOP_START
; }}}
sus_setup:																	; {{{
; --------------------------------------------------------------------------------------------------------------------------------
						mov.w		#0x0000, &SUS_TXS
						bis.b		#SUS_TXPIN, &SUS_TXDIR
						bis.b		#SUS_TXPIN, &SUS_TXOUT
						clr.w		&TACCR0
						clr.w		&TACCTL0
						clr.w		&TACTL
						ret
; }}}
sus_transmit:																	; {{{
; --------------------------------------------------------------------------------------------------------------------------------
						mov.b		#0x0a, &SUS_TXS								; clear state
						clrc
						rlc.w		&SUS_TXB									; 0000 000x xxxx xxx0
						bis.w		&0x0200, &SUS_TXB							; 0000 001x xxxx xxx0 start bit is 0, stop bit is 1
						bis.w		#MC_1, &TACTL
						mov.w		#(TASSEL_2|MC_1), &TACTL					; use DCO, no prescaler, counting up mode
						mov.w		#(CCIE), &TACCTL0							; TACCR0 CCIFG interrupt enable
						mov.w		#0x1a0, &TACCR0								; period of 1e6/2400 ticks
						ret
; }}}
SUS_TACCR0_CCIFG_HANDLER:														; {{{
; --------------------------------------------------------------------------------------------------------------------------------
						tst.b		&SUS_TXS
						jz			sus_disable_interrupt
						dec.b		&SUS_TXS
						rrc.w		&SUS_TXB
						jnc			sus_zout
						bis.b		#SUS_TXPIN, &SUS_TXOUT
						reti
sus_zout:				bic.b		#SUS_TXPIN, &SUS_TXOUT
						reti
sus_disable_interrupt:	clr.w		&TACCR0
						clr.w		&TACCTL0
						clr.w		&TACTL
						reti
; }}}
