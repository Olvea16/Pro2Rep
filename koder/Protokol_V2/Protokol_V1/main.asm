;
; Protokol_V1.asm
;
; Created: 21-04-2017 10:49:12
; Author : simon
;


; Replace with your application code


;--------------------------
.DEF Temp1 = R16	;Midlertidigt register til operationer i subroutiner
.DEF Ret1 = R17		;Returværdi for subroutiner
.DEF SendReg = R18	;Indeholder den værdig der skal sendes
.DEF InBesked = R19	;lder nyligt læst data fra UDR
.DEF InType	= R20	;Indeholder telegramtypen
.DEF InCmd = R21	;Indeholder telegrammets kommando
.DEF InData = R22	;Indeholder telegrammets data (Parameter)
;--------------------------

.CSEG		    ;Angiver at dette tilhører program hukommelse. Markerer starten på et kodesegment med sin egen location counter.  
.ORG 0			;Vektor adresse for Reset
RJMP Setup      ;Springer til setup 

.ORG 30		; 30 da dette ville være lige efter 28+2 

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
	LDI R16,0x63	;
	OUT TCCR2,R16	;Prescaler=64, Phase correct, non inverted, ca 1 kHz (0b01100011)
	LDI R16,0		;
	OUT OCR2,R16	;Køre med 0%

;SEI	;Intrups er tændt 

;Main---------------------------------------
;NOP;slet mig(Debug ting)
Main:

StartOfProto:

SBIS UCSRA,RXC
JMP EndOfProto
;IN InBesked,UDR
;NOP ;Indsæt modtaget værdig til simu i R24 (InBesked) (Debug ting)

TypeCheck:
	CPI InType,0x00
	BRNE CmdCheck
	CALL IsType
	JMP EndOfProto

CmdCheck:
	CPI InCmd,0x00
	BRNE DataCheck
	CALL IsCom
	CPI InType,0xAA
	BREQ IsGet
	;Indsæt nye typper over dette punkt 
	CPI InCmd,0x10
	BREQ EndOfProto
	;Hvis nye Cmd indsæt over dette 
	CALL StopCar
	CALL Cleanup
	JMP EndOfProto

	IsGet:
		CPI InCmd,0x10
		BRNE Error			//Sætter fejl hvis typen 0x55 ikke er set.
		CALL SendSpeed
		CALL Cleanup
		JMP EndOfProto

DataCheck:
	CPI InData,0x00
	BRNE Error
	MOV InData,InBesked
	CPI InType,0x55
	BRNE Error
	CPI InCmd,0x10
	BRNE Error
	CALL SetSpeed
	CALL Cleanup
	JMP EndOfProto

Error:
	CALL Cleanup
	;Indsæt hvad der ellers skal ske i Error her 

EndOfProto:
JMP Main	;Hopper til starten af main

;Subruines---------------------------------------
StopCar:
	LDI Temp1,0			;
	OUT OCR2,Temp1		;Sætter bilen hastighed til 0%
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR(Det register som indeholder der der bliver sendt) er tom)
	RJMP Send			;Hvis UDRE er "0" hopper den tilbage til Send: og dermed venter på at UDR er tom 
	;MOV R31,SendReg		;Til Debug(Debug ting)
	OUT UDR,SendReg		;Ligger SendReg ind i den tomme UDR. Dermed vil SendReg blive sendt
	RET					;Subrutinen er færdig programcounteren vil blive sat til den adresse som var efter CALL 

SendSpeed:
	LDI SendReg,0xBB	;
	CALL Send			;Sender Reply (0xBB)
	IN SendReg,OCR2		;
	CALL Send			;Sender den nuværnde hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	;MOV R31,Ret1		;Til Debug(Debug ting)
	OUT OCR2,Ret1		;Sætter hastigheden på bilen til hvad der kom i Ret1 efter udregningen 
	RET

IsType:
	CPI InBesked,0x55
	BREQ wasType
	CPI InBesked,0xAA
	BREQ wasType
	CPI InBesked,0xBB
	BREQ wasType
	
	;INDSÆT NYE TELEGRAMTYPER

	LDI InType,0
	RET

	wasType:
		MOV InType,InBesked	
		RET

IsCom:
	CPI InBesked,0x10
	BREQ wasCommand
	CPI InBesked,0x11
	BREQ wasCommand

	;INDSÆT NYE TELEGRAMKOMMANDOER.

	LDI InCmd,0
	RET

	wasCommand:
		MOV InCmd,InBesked	
		RET

Cleanup:
	LDI InType,0
	LDI InCmd,0
	LDI InData,0
	;Hvis der er flere der skal renses så ind her
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
	RET