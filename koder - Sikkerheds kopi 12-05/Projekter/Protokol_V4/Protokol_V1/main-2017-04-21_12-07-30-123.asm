;
; Protokol_V1.asm
;
; Created: 21-04-2017 10:49:12
; Author : simon
;


; Replace with your application code


;--------------------------
.DEF Temp1 = R16	;Midlertidigt register til operationer i subroutiner
.DEF Ret1 = R18		;Returværdi for subroutiner
.DEF SendReg = R23	;Indeholder den værdig der skal sendes
.DEF InBesked = R24	;lder nyligt læst data fra UDR
.DEF InType	= R25	;Indeholder telegramtypen
.DEF InCmd = R26	;Indeholder telegrammets kommando
.DEF InData = R27	;Indeholder telegrammets data (Parameter)
;--------------------------

.CSEG		    ;Angiver at dette tilhører program hukommelse. Markerer starten på et kodesegment med sin egen location counter.  
.ORG 0			;Vektor adresse for Reset
RJMP Setup      ;Springer til setup 

.ORG 50		;50 er bare støre end den sidste adresse i vector tabellen der kunne også bruges 30 da dette ville være lige efter 28+2 

Setup:
;Opsætning af stack
	LDI R16, HIGH(RAMEND)		;Loader højeste hukommelses adresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,R16					;Gennemer i stack pointer 
	LDI R16, LOW(RAMEND)		;Loader højeste hukommelses adresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,R16					;Gemmer i stack pointer 

;Opsætning af kommunikation
	LDI R16, (1<<TXEN)|(1<<RXEN);|(1<<RXCIE)	;Sætter modtage og sende igang
	OUT UCSRB, R16								;-||-
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstilles mikrokontrolleren til 8 bit data, ingen parity bit og kun 1 stop bit 
	OUT UCSRC, R16								;-||-
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz)
	OUT UBRRL, R16								;-||-

;Opsætning af PWM
	SBI DDRD,7		;PordtD Bit7 sættes og bliver output 
	LDI R16,0x63	;Se?
	OUT TCCR2,R16	;Prescaler=64, Phase correct, non inverted, ca 1 kHz (0b01100011)
	LDI R16,0		;Se?
	OUT OCR2,R16	;Køre med 0%

;SEI	;Intrups er tændt 

;Main---------------------------------------
Main:

StartOfProto:

;Protokold ind her 

EndOfProto:

JMP Main

;Subruines---------------------------------------
StopCar:
	LDI Temp1,0			;Se?
	OUT OCR2,Temp1		;Sætter bilen hastighed til 0%
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1"
	RJMP Send			;Hvis UDRE er "0" hopper den tilbage til Send: og dermed venter på at UDR er tom 
	OUT UDR,SendReg		;Ligger SendReg ind i den tomme UDR. Dermed vil SendReg blive sendt
	RET					;Subrutinen er færdig programcounteren vil blive sat til den adresse som var efter CALL 

SendSpeed:
	LDI SendReg,0xBB	;Se?
	CALL Send			;Sender Reply (0xBB)
	IN OCR2,SendReg		;Se?
	CALL Send			;Sender den nuværnde hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	OUT OCR2,Ret1		;Sætter hastigheden på bilen til hvad der kom i Ret1 efter udregningen 
	RET

IsType:
	CPI Arg1,0x55
	BREQ wasType
	CPI Arg1,0xAA
	BREQ wasType
	CPI Arg1,0xBB
	BREQ wasType
	
	;INDSÆT NYE TELEGRAMTYPER

	LDI Ret1,0
	RET

	wasType:
		LDI Ret1,1
		MOV InType,InBesked	;Har jeg tilført #(Slet denne kometar)#
		RET

IsCommand:
	CPI Arg1,0x10
	BREQ wasCommand
	CPI Arg1,0x11
	BREQ wasCommand

	//INDSÆT NYE TELEGRAMKOMMANDOER.

	LDI Ret1,0
	RET
	wasCommand:
		LDI R19,1
		MOV InCmd,InBesked	;Har jeg tilført #(Slet denne kometar)#
		RET

Cleanup:
	LDI InType,0
	LDI InCom,0
	LDI InData,0
	RET

CalcOCR2:
	MOV Temp1,InData
	MOV Ret1,Temp1
	ADD Ret1,Temp1
	LSR Temp1
	ADD Ret1,Temp1
	LSR Temp1
	LSR Temp1
	LSR Temp1
	ADD Ret1,Temp1
	LSR Temp1
	SUB Ret1,Temp1
	LSR Temp1
	ADD Ret1,Temp1
	;Hvis den nu bliver sent 100 ender det så også med 255? #(Slet denne kometar)#
	RET