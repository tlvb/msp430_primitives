softusart_tx.hex: softusart_tx.asm
	naken_asm -h -o $@ $<

.PHONY: install
install: softusart_tx.hex
	mspdebug rf2500 'prog $<'
