;ELSE
; TestAfAccolemeter.asm
;
; Created: 23-03-2017 18:07:20
; Author : simon
;
/*
Send "w" for at modtage 100 Acc målinger 
*/
;Opsætning af interrupt	
.CSEG		    ;Angiver at dette tilhører program hukommelse. Markerer starten på et kodesegment med sin egen location counter.  
RJMP Setup      ;Springer til setup 
.ORG URXCaddr	;Dette er "USART, Receive complete" adresse (se Vector Tabel 1 s 365 i AVR Microcontroller and embedded systems)  
                ;Den kan også angives med "URXCaddr", og er en Interruptadresse. 
RJMP DataIndR17 ;Springer til DataIndR17
.ORG ADCCaddr	;Dette er den for en ADC er færdig 
RJMP ADCErFerdig
.ORG 50		;50 er bare støre end den sidste adresse i vector tabellen der kunne også bruges 30 da dette ville være lige efter 28+2 

.DEF Arg1 = R28
.DEF Arg2 = R29
.DEF Ret1 = R30
.DEF Ret2 = R31

Setup:
;Opsætning af stack
	LDI R16, HIGH(RAMEND)		;Loader højeste hukommelses adresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,R16					;Gennemer i stack pointer 
	LDI R16, LOW(RAMEND)		;Loader højeste hukommelses adresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,R16					;Gemmer i stack pointer 
	
;Opsætning af kommunikation
	LDI R16, (1<<TXEN)|(1<<RXEN)|(1<<RXCIE)		;Sætter modtage og sende igang
	OUT UCSRB, R16								;-||-
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstilles mikrokontrolleren til 8 bit data, ingen parity bit og kun 1 stop bit 
	OUT UCSRC, R16								;-||-
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz)
	OUT UBRRL, R16								;-||-

;Opsætning af PWM
	SBI DDRD,7		;PordtD Bit7 sættes og bliver output 
	LDI R16,0x63	;Prescaler=64, Phase correct, non inverted, 256 Hz (0b01100011)
	OUT TCCR2,R16	;
	LDI R16,0		;Køre med 0%
	OUT OCR2,R16

;Opsætning af ADC
	LDI R16,0
	OUT DDRA, R16	;Sætter PortA 0 til indput
	LDI R16,0x8F	;Tænder ADC, interrupt på og ck/128 for max præcision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, R16
	LDI R16,0x60	;AVCC pin som Vref og det er højre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, R16

SEI	;Intrups er tændt 
LDI R22,0
LDI R23,1

;Main program------------------------------------

Main:
;Laver ikke noget som helst så her kan komme alt muligt andet :)
;LDI R20,0
JMP Main


;Subrutie--------------------------------

FindOCR2R17:
	PUSH R18
	MOV R18, R17
	ADD R17,R18
	LSR R18
	ADD R17,R18
	LSR R18
	LSR R18
	LSR R18
	CLC
	ADD R17,R18
		BRCC Overflowikkesat
		LDI R17,255
	Overflowikkesat:
	POP R18
	RET

SendR18:				;Subrutinen "SendR18"
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR(Det register som indeholder det, der bliver sendt) er tom)
	RJMP SendR18		;Hvis UDRE er "0" hopper den tilbage til starten og dermed venter på at UDR er tom 
	OUT UDR,R18			;Ligger R17 ind i den tomme UDR. Dermed vil R18 blive sendt
	RET					;Subrutinen er færdig programcounteren vil blive sat til den adresse som var efter CALL 

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

;Interrupt "funktioner"
DataIndR17:
	IN	R17,UDR				;Henter hvad der var kommet ind og ligger det i R17
										
	;CPI R22,1				;Tjekker om 'w'(start med at modtage hastigheder) har blevet sendt allerede. (Hisv programmet lige er blevet tændt eller hvis en stop ('q') besked er blevet sendt vil det nulstille om start er blevet sendt
	;BREQ neste1w			;-||-
		CPI R17,'w'	;ASCII
		BRNE neste1w
			LDI R25,0
			SBI ADCSRA, ADSC		;Starter conversion (ADC)
			;LDI R18, '{'			;Sender "{"
			;CALL SendR18
			;LDI R20,0	;0% hastighed
			;CALL SetNyHastR20
			LDI R22,1	;nu kan man ikke sende start til bilen før man har sendt stop 
			RETI
	neste1w:

	CPI R17,'q'	;ASCII
		BRNE neste1q
		;LDI R18, '}'		;Sender ","
		;CALL SendR18
		;LDI R20,0	;0% hastighed
		;CALL SetNyHastR20
		;CBI ADCSRA, ADEN	;Stopper for ADC
		CBI ADCSRA, ADSC		;Stopper conversion (ADC)
		LDI R22,0	;Nu kan man igen sende start til bilen 
		RETI
	neste1q:

	;Hvor der ikke sende data 
	CPI R22,1
	BREQ neste1wUdata
		CPI R17,0x55	;
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

	
	CPI R17,0x10
	BRNE Hast
	LDI R23,2
	RJMP UdDataIndR17

	Hast:
	CPI R23,2
	BRNE UdDataIndR17
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
	LDI R23,1
	
	UdDataIndR17:
	RETI

;-----------------------------------------------------------------------------------------------
ADCErFerdig:	;Når en ADC er færdig hopper den hertil
	CPI R25,255
	BREQ StopACC
	INC R25
	IN	R18, ADCL		;Indlæser den lave del af ADC
	IN  R18, ADCH		;Indlæser den høje del af ADC
	CALL SendR18		;Sender høje del af ADC	
	SBI ADCSRA, ADSC	;Starter conversion igen 
	RETI
	StopACC:
	CBI ADCSRA, ADSC		;Stopper conversion (ADC)
	RETI
		

//Arg1 = Register der skal testes om det er en type.
isType:
	CPI Arg1,0x55
	BREQ wasType
	CPI Arg1,0xAA
	BREQ wasType
	CPI Arg1,0xBB
	BREQ wasType

	//INDSÆT NYE TELEGRAMTYPER

	LDI Ret1,0
	RET
wasType:
	LDI Ret1,1
	RET


//Arg1 = Register der skal testes om det er en kommando.
isCommand:
	CPI Arg1,0x10
	BREQ wasCommand
	CPI Arg1,0x11
	BREQ wasCommand

	//INDSÆT NYE TELEGRAMKOMMANDOER.

	LDI Ret1,0
	RET
wasCommand:
	LDI R19,1
	RET