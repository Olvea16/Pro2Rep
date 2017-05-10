;
; Kominaktion med Rx og Tx.asm
;
; Created: 11-03-2017 17:34:14
; Author : simon
;


;Opsætning af stack
	LDI R16, HIGH(RAMEND)		;Loder højste hukommelse adresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,R16					;Gennemer i stack pointer 
	LDI R16, LOW(RAMEND)		;Loder højste hukommelse adresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,R16					;Gennemer i stack pointer 

;Opsætning af kominaktion
	LDI R16, (1<<TXEN)|(1<<RXEN)				;Sætter modtage og sende igang
	OUT UCSRB, R16								;-||-
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstiller jeg den til at det er 8 bit data, ingen parity bit og kun 1 stop bit 
	OUT UCSRC, R16								;-||-
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz)
	OUT UBRRL, R16								;-||-

	;Venter på besked 
	VentPaaBesked:				
	SBIS UCSRA, RXC				;Tjætter om RXC er "1" da dette vil betyde der er ny data der er kommet ind 
	RJMP VentPaaBesked			;Hvis RXC ikke var "1" (Der med "0") hopper den til "VentPaaBesked" og der med tjekker igen (Hvilket føre til den vil vente på ny data)
	IN R16, UDR					;Henter den data der er kommet og ligger den ind i R16 
	
	;Sending af svar 
	LDI R17, 'D'				;Ligger "D" som ASCII ind i R17
	CALL SendR17				;Kalder subrutiene "Send" som dender R17
	LDI R17, 'u'				;Ligger "u" som ASCII ind i R17
	CALL SendR17				;Kalder subrutiene "Send" som dender R17
	LDI R17, ' '				;Ligger " "(mellem rum) som ASCII ind i R17
	CALL SendR17				;Kalder subrutiene "Send" som dender R17
	LDI R17, 'h'
	CALL SendR17 
	LDI R17, 'a'
	CALL SendR17 
	LDI R17, 'r'
	CALL SendR17 
	LDI R17, ' '
	CALL SendR17 
	LDI R17, 's'
	CALL SendR17 
	LDI R17, 'e'
	CALL SendR17 
	LDI R17, 'n'
	CALL SendR17 
	LDI R17, 'd'
	CALL SendR17 
	LDI R17, 't'
	CALL SendR17 
	LDI R17, ' '
	CALL SendR17 
	MOV R17, R16
	CALL SendR17
	LDI R17, ' '
	CALL SendR17
	;Dette vil sende "Du har sendt >R16< " 
	JMP VentPaaBesked			;Hopper tilbage til at vente på et svar 

	SendR17:			;Subrutienen "SendR17"
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR(Det register som indeholder der der bliver sendt) er tom)
	RJMP SendR17		;Hvis UDRE er "0" hopper den tilbage til starten og der med venter på UDR er tom 
	OUT UDR,R17			;Ligger R17 ind i den tomme UDR. Der med vil R17 blive sendt
	RET					;Subrutienen er færdig programconteren vil blive sat til den adresse som var efter CALL 