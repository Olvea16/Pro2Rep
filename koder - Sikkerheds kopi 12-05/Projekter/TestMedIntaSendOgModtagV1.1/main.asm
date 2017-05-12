;Ops�tning af interrupt	
.CSEG		;Angiver at dette tilh�re program hukommelse 
RJMP Setop 
.ORG URXCaddr	;Dette er "USART, Receive complete" adresse (se Vector Tabel 1 s 365) Den kan ogs� angives med "URXCaddr" 
RJMP DataIndR17
.ORG 50		;50 er bare st�re end den sidste adresse i vector tabellen der kunne ogs� bruges 30 da dette ville v�re lige efter 28+2 
;---
Setop: 
;Ops�tning af stack
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16
;---
;Ops�tning af kominaktion
	LDI R16, (1<<TXEN)|(1<<RXEN)|(1<<RXCIE)				;S�tter modtage og sende igang samt interrupt for modtaglse
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
LDI R16,0
JMP MainProgram



;Subrutines-------------------------------------------------------
SendR17:			;Subrutienen "SendR17"
	SBIS UCSRA,UDRE									;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver n�r UDR(Det register som indeholder der der bliver sendt) er tom)
	RJMP SendR17									;Hvis UDRE er "0" hopper den tilbage til starten og der med venter p� UDR er tom 
	OUT UDR,R17										;Ligger R17 ind i den tomme UDR. Der med vil R17 blive sendt
	RET
													;Subrutienen er f�rdig programconteren vil blive sat til den adresse som var efter CALL


DataIndR17:
	IN	R17,UDR										;Henter hvad der var kommet ind og ligger det i R17
	LDI R16,1
	RETI