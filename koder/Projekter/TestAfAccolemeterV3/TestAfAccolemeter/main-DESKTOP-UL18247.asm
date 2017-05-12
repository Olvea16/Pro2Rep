;ELSE
; TestAfAccolemeter.asm
;
; Created: 23-03-2017 18:07:20
; Author : simon
;
;Opsætning af interrupt	
.CSEG		    ;Angiver at dette tilhører program hukommelse. Markerer starten på et kodesegment med sin egen location counter.  
RJMP Setup      ;Springer til setup 
.ORG URXCaddr	;Dette er "USART, Receive complete" adresse (se Vector Tabel 1 s 365 i AVR Microcontroller and embedded systems)  
                ;Den kan også angives med "URXCaddr", og er en Interruptadresse. 
RJMP DataIndR17 ;Springer til DataIndR17
.ORG ADCCaddr	;Dette er den for en ADC er færdig 
RJMP ADCErFerdig
.ORG 50		;50 er bare støre end den sidste adresse i vector tabellen der kunne også bruges 30 da dette ville være lige efter 28+2 


Setup:
;Opsætning af stack
	LDI R16, HIGH(RAMEND)		;Loader højste hukommelse adresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,R16					;Gennemer i stack pointer 
	LDI R16, LOW(RAMEND)		;Loader højste hukommelse adresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,R16					;Gennemer i stack pointer 
	
	


;Opsætning af kominaktion
	LDI R16, (1<<TXEN)|(1<<RXEN)|(1<<RXCIE)				;Sætter modtage og sende igang
	OUT UCSRB, R16								;-||-
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstiller jeg den til at det er 8 bit data, ingen parity bit og kun 1 stop bit 
	OUT UCSRC, R16								;-||-
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz)
	OUT UBRRL, R16								;-||-

;Opsætning af PWM
	SBI DDRD,7		;PordtD Bit7 bliver output 
	LDI R16,0x63	;Prescaler=64, Phase correct, non inverted, 256 Hz (0b01100011)
	OUT TCCR2,R16	;
	LDI R16,0		;Køre med 0%
	OUT OCR2,R16

;Opsætning af ADC
	LDI R16,0
	OUT DDRA, R16	;Sætter PortA 0 til indput
	LDI R16,0x8F	;Tænder ADC, intrup på og ck/128 for max præsision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, R16
	LDI R16,0x40	;AVCC pin som Vref og det er højre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, R16

SEI	;Intrups er tændt 
LDI R22,0

;Maine program------------------------------------

Main:
;Laver ikke noget som helst så her kan komme alt muligt andet :)
LDI R20,0
JMP Main


;Subrutie--------------------------------

FindOCR2R17:
	PUSH R18		;Laver en sikkerhed kopi af R18
	MOV R18, R17	;Flytter R17 ind i R18
	ADD R17,R18		;Ligger R18 til R17 (Ganger R17 med 2)
	LSR R18			;Dividere R18 med 2
	ADD R17,R18		;Ligger 2*a+a/2
	LSR R18			;Dividere med 2 (oppe på 4)
	LSR R18			;Dividere med 2	(oppe på 8)
	LSR R18			;Dividere med 2 (oppe på 16)
	CLC				;Renser crerry flaget 
	ADD R17,R18		;Ligger a/16 til 2*a+a/2 (Nu er det så 2*a+a/2+a/16)
		BRCC Overflowikkesat	;Hvis crerry flaget ikke blev sat i ADD (Hvis den ADD ikke gik over 0xFF) hopper den til Overflowikkesat
		LDI R17,255				;Loader R17 med 255 da ADD gik over 0xFF så har R17 til at starte med været 100 (100% hastighed) og der for sættes R17 til 0xFF for den højste hastighed
	Overflowikkesat:
	POP R18			;henter sikkerhedskopien ind i R18 igen
	RET				;Afslutter rutinen 

SendR18:				;Subrutienen "SendR18"
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR(Det register som indeholder der der bliver sendt) er tom)
	RJMP SendR18		;Hvis UDRE er "0" hopper den tilbage til starten og der med venter på UDR er tom 
	OUT UDR,R18			;Ligger R17 ind i den tomme UDR. Der med vil R18 blive sendt
	RET					;Subrutienen er færdig programconteren vil blive sat til den adresse som var efter CALL 

SetNyHastR20:
	OUT OCR2,R20		;Værdien i R20 kommer i PWM OCR2
	RET

SendHastighReplyR23:
	LDI R18, 'H'		;Sender 
	CALL SendR18
	LDI R18, '='		;Sender 
	CALL SendR18
	MOV R18, R23		;Sender 
	CALL SendR18
	LDI R18, '0'		;Sender 
	CALL SendR18
	LDI R18, '%'		;Sender 
	CALL SendR18
	RET

;Intarup "funktioner"
DataIndR17:
	IN	R17,UDR				;Henter hvad der var kommet ind og ligger det i R17
										
	CPI R22,1
	BREQ neste1w
		CPI R17,'w'	;ASCII
		BRNE neste1w
			SBI ADCSRA, ADSC		;Starter conversion (ADC)
			LDI R18, '{'			;Sender "{"
			CALL SendR18
			LDI R20,0	;0% hastighed
			CALL SetNyHastR20
			LDI R22,1	;nu kan man ikke sende start til bilen før man har sendt stop 
			RETI
	neste1w:

	CPI R17,'q'	;ASCII
		BRNE neste1q
		LDI R18, '}'		;Sender ","
		CALL SendR18
		LDI R20,0	;0% hastighed
		CALL SetNyHastR20
		;CBI ADCSRA, ADEN	;Stopper for ADC
		CBI ADCSRA, ADSC		;Starter conversion (ADC)
		LDI R22,0	;Nu kan man igen sende start til bilen 
		RETI
	neste1q:

	;Hvor der ikke sende data 
	CPI R22,1
	BREQ neste1wUdata
		CPI R17,0x99	;
		BRNE neste1wUdata
			LDI R20,0	;0% hastighed
			CALL SetNyHastR20
			LDI R22,1	;nu kan man ikke sende start til bilen før man har sendt stop 
			RETI
	neste1wUdata:

	CPI R17,0x88	;
		BRNE neste1qUdata
		LDI R20,0	;0% hastighed
		CALL SetNyHastR20
		LDI R22,0	;Nu kan man igen sende start til bilen 
		RETI
	neste1qUdata:

	;Sætning og udregning af OCR2
	CPI R22,1
	BRNE UdDataIndR17
	CPI R17,101
	BRSH UdDataIndR17
	RCALL FindOCR2R17
	MOV R20,R17
	OUT OCR2,R20		;Værdien i R20 kommer i PWM OCR2 (udbyt med CALL SetNyHastR20)
	;CALL SetNyHastR20
	MOV R18,R17
	CALL SendR18
	
	UdDataIndR17:
	RETI

ADCErFerdig:	;Når en ADC er færdig hopper den her til
	IN	R19, ADCL		;Indlæser den lave del af ADC
	IN  R18, ADCH		;Indlæser den høje del af ADC
	CALL SendR18		;Sender høje del af ADC
	MOV R18,R19
	CALL SendR18		;Sender lave del af ADC så det bliver ADCH:ADCL,
	LDI R18, ','		;Sender ","
	CALL SendR18	
	SBI ADCSRA, ADSC	;Starter conversion igen 
	RETI