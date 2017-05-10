;Opsætning af interrupt	
.CSEG		;Angiver at dette tilhøre program hukommelse 
RJMP Setop 
.ORG URXCaddr	;Dette er "USART, Receive complete" adresse (se Vector Tabel 1 s 365) Den kan også angives med "URXCaddr" 
RJMP DataIndR17
.ORG 50		;50 er bare støre end den sidste adresse i vector tabellen der kunne også bruges 30 da dette ville være lige efter 28+2 
;---
Setop: 
;Opsætning af stack
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16
;---
;Opsætning af kominaktion
	LDI R16, (1<<TXEN)|(1<<RXEN)|(1<<RXCIE)				;Sætter modtage og sende igang samt interrupt for modtaglse
	OUT UCSRB, R16								;-||-
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstiller jeg den til at det er 8 bit data, ingen parity bit og kun 1 stop bit 
	OUT UCSRC, R16								;-||-
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz)
	OUT UBRRL, R16								;-||-
;---
;Godkender interrupt
SEI
;---
LDI R16,0
MainProgram:
CALL SendLaverIkkeNoget
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CALL DELAY
CPI R16,1
BRNE MainProgram
MOV R18,R17
LDI	R17,'H'
CALL SendR17
LDI R17,'e'
CALL SendR17
LDI R17,'j'
CALL SendR17
LDI R17,' '
CALL SendR17
MOV R17,R18
CALL SendR17
LDI R17,' '
CALL SendR17
CALL SendR17
CALL SendR17
CALL SendR17
CALL SendR17
CALL SendR17
CALL SendR17
CALL SendR17
CALL SendR17
CALL SendR17
LDI R16,0
JMP MainProgram



;Subrutines-------------------------------------------------------
SendLaverIkkeNoget:
LDI R17,'L'
CALL SendR17
LDI R17,'a'
CALL SendR17
LDI R17,'v'
CALL SendR17
LDI R17,'e'
CALL SendR17
LDI R17,'r'
CALL SendR17
LDI R17,' '
CALL SendR17
LDI R17,'i'
CALL SendR17
LDI R17,'k'
CALL SendR17
LDI R17,'k'
CALL SendR17
LDI R17,'e'
CALL SendR17
LDI R17,' '
CALL SendR17
LDI R17,'n'
CALL SendR17
LDI R17,'o'
CALL SendR17
LDI R17,'g'
CALL SendR17
LDI R17,'e'
CALL SendR17
LDI R17,'t'
CALL SendR17
LDI R17,' '
CALL SendR17
RET

SendR17:			;Subrutienen "SendR17"
	SBIS UCSRA,UDRE									;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR(Det register som indeholder der der bliver sendt) er tom)
	RJMP SendR17									;Hvis UDRE er "0" hopper den tilbage til starten og der med venter på UDR er tom 
	OUT UDR,R17										;Ligger R17 ind i den tomme UDR. Der med vil R17 blive sendt
	RET
													;Subrutienen er færdig programconteren vil blive sat til den adresse som var efter CALL
DELAY:
LDI R20, -254		;R20 = 0x10
OUT TCNT2, R20			;load Timer2
LDI R20, 0x07
OUT TCCR2, R20			;Timer2, Normal mode, int clk, prescaler 1024
AGAIN:IN R20, TIFR		;read TIFR
SBRS R20, TOV2			;if T0V2 is set skip next instruction
RJMP AGAIN
LDI R20, 0x0
OUT TCCR2, R20			;stop Timer2
LDI R20, 1<<TOV2
OUT TIFR, R20			;clear T0V2 flag
RET


;Intarup-----------------
DataIndR17:
	IN	R17,UDR										;Henter hvad der var kommet ind og ligger det i R17
	LDI R16,1
	RETI

