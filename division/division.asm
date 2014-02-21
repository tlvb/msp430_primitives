.include "msp430g2x31.inc"
; vim: set syntax=msp:
divide:																			; {{{
; Divides two numbers, I the result should be in q8.8 notation
; --------------------------------------------------------------------------------------------------------------------------------
						push		r4
						push		r5
						push		r6
						push		r7
						mov.w		&NUMERATOR, r6
						mov.w		&DIVISOR, r5
						mov.w		#0x0000, r4

						tst.w		r5
						jz			divider_ret

						mov.w		#0x0100, r7

dec_until_lo:			cmp			r5, r6										; r5 >= r6?
						jlo			next_power									; nope
						sub.w		r5, r6										; yes, so subtract it
						add.w		r7, r4										; increase r4 by current bit value
						jmp			dec_until_lo:

next_power:				clrc
						rrc.w		r7
						clrc
						rrc.w		r5
						tst			r7
						jnz			dec_until_lo

divider_ret:			mov.w		r4, &QUOTIENT
						pop			r7
						pop			r6
						pop			r5
						pop			r4
						ret
; }}}
