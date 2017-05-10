;
; Protokol_V1.asm
;
; Created: 21-04-2017 10:49:12
; Author : simon
;


; Replace with your application code
; Sidetal anviser sidenummer i ATmega32A datasheet uploadet på blackboard.

;--------------------------
.DEF Temp1 = R16	;Midlertidigt register til operationer i subroutiner.
.DEF Ret1 = R17		;Standard returværdi for subroutiner.
.DEF SendReg = R18	;Indeholder den værdi, der skal sendes.
.DEF InBesked = R19	;Loader nyligt læst data fra UDR.
.DEF InType	= R20	;Indeholder telegramtypen.
.DEF InCmd = R21	;Indeholder telegrammets kommando.
.DEF InData = R22	;Indeholder telegrammets data (parameter).
.DEF AccRefP = R23	;Indeholder accelerometerets referenceværdi til sving.
.DEF AccRefN = R24  
.DEF AccData = R25
.DEF Temp2 = R26	;Midlertidigt register til operationer i subroutiner.
;--------------------------


.ORG 0			;Vektoradresse for Reset.
RJMP Setup      ;Springer til setup. 

.ORG ADCCaddr	;Dette er den for en ADC er færdig 
RJMP ADCDone


.ORG 50			;Sætter adressen for denne linje til 30, da dette ville være lige efter 28+2.

Setup:
;Opsætning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader højeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader højeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 

;Opsætning af kommunikation
	LDI R16, (1<<TXEN)|(1<<RXEN);|(1<<RXCIE)	;Opsætter værdien til modtagelse og afsendelse af seriel data.
	OUT UCSRB, R16								;Sender værdien til opsætningsregisteret, UCSRB (s. 212).
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstilles mikrokontrolleren til 8 bit data, ingen parity bit og kun 1 stop bit.
	OUT UCSRC, R16								;Værdien sendes til registeret UCSRC (s. 214).
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz).
	OUT UBRRL, R16								;Værdien for baud rate sendes til registeret UBRRL (s. 216).

;Opsætning af PWM
	SBI DDRD,7		;PordtD Bit7 sættes og bliver output.
	LDI R16,0x63	;(0110 0011)
	OUT TCCR2,R16	;Opsætter PWM, sætter prescaleren til 1/32 (ca. 1 kHz), fasekorrekt, ikke-inverteret (s. 153).
	LDI R16,0		;
	OUT OCR2,R16	;Sætter PWM til 0, via. registeret OCR2 (OCR2 = PWM * 2.55)

;Opsætning af ADC
	LDI R16,0
	OUT DDRA, R16	;Sætter PortA 0 til indput
	LDI R16,0x8F	;Tænder ADC, interrupt på og ck/128 for max præcision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, R16
	LDI R16,0x60	;AVCC pin som Vref og det er højre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, R16

;Opsætning af RGB LED
	SBI DDRA, 1
	SBI DDRA, 2
	SBI DDRA, 3
	SBI DDRA, 4
	SBI DDRA, 5
	SBI DDRA, 6

SEI	;Enabler interrupts. 
		NOP
;Main---------------------------------------
Main:
AccBehandling:
	CP AccData, AccRefP
	BRGE AccP
	CP AccData, AccRefN
	BRLO AccN
		LDI Temp1, 0b010010
		LSL Temp1
		IN Temp2, PORTA
		ANDI Temp2, 0b00000001
		OR Temp2, Temp1
		OUT	PORTA, Temp2
		JMP EndAccBehandling

	AccP:
		LDI Temp1, 0b111000
		LSL Temp1
		IN Temp2, PORTA
		ANDI Temp2, 0b00000001
		OR Temp2, Temp1
		OUT	PORTA, Temp2
		JMP EndAccBehandling
	AccN:
		LDI Temp1, 0b000111
		LSL Temp1
		IN Temp2, PORTA
		ANDI Temp2, 0b00000001
		OR Temp2, Temp1
		OUT	PORTA, Temp2

EndAccBehandling:

StartOfProto:
	NOP
SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN InBesked,UDR		;Hvis RXC er 1, skal programmet læse og fortolke dataen i UDR.
			NOP
TypeCheck:
	CPI InType,0x00	;Tjekker om InType er tom.
	BRNE CmdCheck	;Hvis InType ikke er tom, hopper programmet til CmdCheck.
	CALL IsType		;Hvis InType er tom, tjekker programmet om den modtagne besked i InBesked er en type med subroutinen IsType.
	JMP EndOfProto	;Derefter hopper programmet videre til efter telegramfortolkningen og fortsætter i næste omgang i main-løkken.

CmdCheck:
	CPI InCmd,0x00	;Tjekker om InCmd er tom.
	BRNE DataCheck	;Hvis InCmd ikke er tom, hopper programmet til DataCheck.
	CALL IsCmd		;Hvis InCmd derimod er tom, tjekker programmet om den modtagne besked i InBesked er en kommmando med subroutinen IsCom.
	CPI InType,0xAA	;Derefter sammenligner programmet InType, altså telegrammets type, med 0xAA, altså et 'get'-telegram.
	BREQ IsGet		;Hvis telegramtypen er get, hopper programmet til IsGet.

	;Indsæt nye typer over dette punkt.
	
					;Hvis typen ikke er nogen af de ovenstående, antager programmet at typen er 0x55, altså et 'set'-telegram. 
	CPI InCmd,0x10	;Programmet sammenligner telegrammets kommando med 0x10, altså 'start' eller 'hastighed'.
	BREQ EndOfProto	;Hvis kommandoen er 0x10, hopper programmet til slutningen af protokollen, så dataen til telegrammet 0x55, 0x10 kan hentes i næste omgang i løkken.
	CPI InCmd,0x12	;Programmet sammenligner telegrammets kommando med 0x12, altså PWM'ens prescaler.
	BREQ EndOfProto ;Hvis kommandoen er 0x12, hopper programmet til slutningen af protokollen, så dataen til telegrammet 0x55, 0x12 kan hentes i næste omgang i løkken.
	CPI InCmd,0x13
	BREQ EndOfProto

	;Indsæt nye kommandoer over dette punkt. 
	
					;Hvis kommandoen er ingen af de ovenstående, antager programmet at kommandoen er 0x11, altså kommandoen 'stop'.
	CALL StopCar	;Kalder subroutinen StopCar, der sætter PWM'en til 0.
	JMP CleanupEndOfProto	;Hopper til efter telegramfortolkningen.

	IsGet:
		CPI InCmd,0x12
		BREQ IsFreq
		CPI InCmd,0x13
		BREQ EndOfProto
		CPI InCmd,0x10
		BRNE Error			;Sætter fejl hvis typen 0x55 ikke er sat.
		CALL SendSpeed
		JMP CleanupEndOfProto

		IsFreq:
			CALL SendPrescaler
			JMP CleanupEndOfProto

DataCheck:
		NOP
	CPI InData,0
	BRNE Error
	MOV InData,InBesked
	CPI InType,0xAA
	BREQ GetWithData
	CPI InType,0x55
	BRNE Error
	CPI InCmd,0x12
	BREQ SetFrequency
	CPI InCmd,0x13
	BREQ SetAcceleration
	CPI InCmd,0x10
	BRNE Error
	CALL SetSpeed
	JMP CleanupEndOfProto

	GetWithData:
		CPI InCmd,0x13
		BRNE Error
		CALL SendAccRef
		JMP CleanupEndOfProto

	SetFrequency:
		CPI InData,8
		BRGE Error
		CALL SetPrescaler
		JMP CleanupEndOfProto

	SetAcceleration:
		CALL SetAccRef
		JMP EndOfProto

Error:
	CALL Cleanup
	;Indsæt hvad der ellers skal ske i Error her 

CleanupEndOfProto:
	CALL Cleanup
EndOfProto:

JMP Main	;Hopper til starten af main

;Subroutines---------------------------------------
StopCar:
	LDI Temp1,0			;
	OUT OCR2,Temp1		;Sætter bilens hastighed til 0%
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR (det register som indeholder der der bliver sendt) er tom)
	RJMP Send			;Hvis UDRE er "0", hopper den tilbage til Send:, og dermed venter på at UDR er tom.
	OUT UDR,SendReg		;Lægger SendReg ind i den tomme UDR. Dermed vil SendReg blive sendt.
	RET					;Subroutinen er færdig, returnerer til adressen efter subroutinen blev kaldet fra. 

SendSpeed:
	LDI SendReg,0xBB	;
	CALL Send			;Sender Replytypen (0xBB)
	IN SendReg,OCR2		;
	CALL Send			;Sender den nuværende hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	OUT OCR2,Ret1		;Sætter hastigheden på bilen til resultatet fra CalcOCR2.
	RET

SendPrescaler:
	LDI SendReg,0xBB
	CALL Send
	IN Temp1,TCCR2
	ANDI Temp1,0b00000111
	MOV SendReg,Temp1
	CALL Send
	RET

SetPrescaler:
	IN Temp1,TCCR2
	ANDI Temp1,0b11111000
	OR Temp1,InData
	OUT TCCR2,Temp1
	RET


SetAccRef:
		NOP
	SBRC InData,0
	JMP SetAccRefN
	LSR InData
	LDI Temp1,127
	ADD InData,Temp1
	MOV AccRefP, InData
	RET

	SetAccRefN:
	JMP SetAccRefN
	LSR InData
	LDI Temp1,127
	SUB Temp1,InData
	MOV AccRefN, Temp1
	RET

SendAccRef:
		NOP
	CPI InData,1
	BREQ SendAccRefN
	LDI SendReg, 0xBB
	CALL Send
	MOV SendReg, AccRefP
	CALL Send
	RET

	SendAccRefN:
	LDI SendReg, 0xBB
	CALL Send
	MOV SendReg, AccRefN
	CALL Send
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

IsCmd:
	CPI InBesked,0x10
	BREQ wasCommand
	CPI InBesked,0x11
	BREQ wasCommand
	CPI InBesked,0x12
	BREQ wasCommand
	CPI InBesked,0x13
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


;Intarups -----------------------------------------------------------------

ADCDone:				;Når en ADC er færdig hopper den hertil
	IN	AccData, ADCL		;Indlæser den lave del af ADC
	IN  AccData, ADCH		;Indlæser den høje del af ADC
	SBI ADCSRA, ADSC	;Starter conversion igen 
	RETI
