;
; Protokol_V1.asm
;
; Created: 21-04-2017 10:49:12
; Author : simon
;


; Replace with your application code
; Sidetal anviser sidenummer i ATmega32A datasheet uploadet p� blackboard.

;--------------------------
.DEF Temp1 = R16	;Midlertidigt register til operationer i subroutiner.
.DEF Ret1 = R17		;Standard returv�rdi for subroutiner.
.DEF SendReg = R18	;Indeholder den v�rdi, der skal sendes.
.DEF InBesked = R19	;Loader nyligt l�st data fra UDR.
.DEF InType	= R20	;Indeholder telegramtypen.
.DEF InCmd = R21	;Indeholder telegrammets kommando.
.DEF InData = R22	;Indeholder telegrammets data (parameter).
.DEF AccRefP = R23	;Indeholder accelerometerets referencev�rdi til sving.
.DEF AccRefN = R24  
.DEF AccData = R25
.DEF Temp2 = R26	;Midlertidigt register til operationer i subroutiner.
.DEF LEDTimOn = R27	;Til at fort�lle om der er en timet LED igang
.DEF LEDVerdi = R28
.DEF EEPROMSave = R29
;Vi m� ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29) Vi skal nok samle nogel af registeren og tjekker om vi ik kan bruge Temp og Ret. Evt lave SendReg om til et register vi bruger til at give verdi til subrutiner med s� EEPROMSave og LEDVerdi kan komme der ind
;--------------------------
;Verdiger til EEPROM---------------------------
;Fra 0x000 til 0x400 er gyldige 
.EQU EEPROM_AccRefP = 0x000
.EQU EEPROM_AccRefN = 0x001

;---------------------------
;LED Verdier 
.EQU AccP_LED = 0b111000
.EQU AccN_LED = 0b010010
;---------------------------

.ORG 0			;Vektoradresse for Reset.
RJMP Setup      ;Springer til setup. 

.ORG ADCCaddr	;Dette er den for en ADC er f�rdig 
RJMP ADCDone


.ORG 50			;S�tter adressen for denne linje til 30, da dette ville v�re lige efter 28+2.

Setup:
;Ops�tning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader h�jeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader h�jeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 

;Indh�tning af verdier
LDI Temp1, HIGH(EEPROM_AccRefP)
LDI Temp2, LOW(EEPROM_AccRefP)
CALL LoadFromEEPROM
MOV AccRefP, Ret1
LDI Temp1, HIGH(EEPROM_AccRefN)
LDI Temp2, LOW(EEPROM_AccRefN)
CALL LoadFromEEPROM
MOV AccRefN, Ret1
;---

;Ops�tning af kommunikation
	LDI R16, (1<<TXEN)|(1<<RXEN);|(1<<RXCIE)	;Ops�tter v�rdien til modtagelse og afsendelse af seriel data.
	OUT UCSRB, R16								;Sender v�rdien til ops�tningsregisteret, UCSRB (s. 212).
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstilles mikrokontrolleren til 8 bit data, ingen parity bit og kun 1 stop bit.
	OUT UCSRC, R16								;V�rdien sendes til registeret UCSRC (s. 214).
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz).
	OUT UBRRL, R16								;V�rdien for baud rate sendes til registeret UBRRL (s. 216).

;Ops�tning af PWM
	SBI DDRD,7		;PordtD Bit7 s�ttes og bliver output.
	LDI R16,0x63	;(0110 0011)
	OUT TCCR2,R16	;Ops�tter PWM, s�tter prescaleren til 1/32 (ca. 1 kHz), fasekorrekt, ikke-inverteret (s. 153).
	LDI R16,0		;
	OUT OCR2,R16	;S�tter PWM til 0, via. registeret OCR2 (OCR2 = PWM * 2.55)

;Ops�tning af ADC
	LDI R16,0
	OUT DDRA, R16	;S�tter PortA 0 til indput
	LDI R16,0x8F	;T�nder ADC, interrupt p� og ck/128 for max pr�cision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, R16
	LDI R16,0x60	;AVCC pin som Vref og det er h�jre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, R16

;Ops�tning af RGB LED
	SBI DDRA, 1
	SBI DDRA, 2
	SBI DDRA, 3
	SBI DDRA, 4
	SBI DDRA, 5
	SBI DDRA, 6

SEI	;Enabler interrupts. 

;Main---------------------------------------
Main:
AccBehandling:
	CP AccData, AccRefP
	BRSH AccP
	CP AccData, AccRefN
	BRLO AccN
		LDI Temp1, AccN_LED
		LSL Temp1
		IN Temp2, PORTA
		ANDI Temp2, 0b00000001
		OR Temp2, Temp1
		OUT	PORTA, Temp2
		JMP EndAccBehandling

	AccP:
		LDI Temp1, AccP_LED
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

SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN InBesked,UDR		;Hvis RXC er 1, skal programmet l�se og fortolke dataen i UDR.

TypeCheck:
	CPI InType,0x00	;Tjekker om InType er tom.
	BRNE CmdCheck	;Hvis InType ikke er tom, hopper programmet til CmdCheck.
	CALL IsType		;Hvis InType er tom, tjekker programmet om den modtagne besked i InBesked er en type med subroutinen IsType.
	JMP EndOfProto	;Derefter hopper programmet videre til efter telegramfortolkningen og forts�tter i n�ste omgang i main-l�kken.

CmdCheck:
	CPI InCmd,0x00	;Tjekker om InCmd er tom.
	BRNE DataCheck	;Hvis InCmd ikke er tom, hopper programmet til DataCheck.
	CALL IsCmd		;Hvis InCmd derimod er tom, tjekker programmet om den modtagne besked i InBesked er en kommmando med subroutinen IsCom.
	CPI InType,0xAA	;Derefter sammenligner programmet InType, alts� telegrammets type, med 0xAA, alts� et 'get'-telegram.
	BREQ IsGet		;Hvis telegramtypen er get, hopper programmet til IsGet.

	;Inds�t nye typer over dette punkt.
	
					;Hvis typen ikke er nogen af de ovenst�ende, antager programmet at typen er 0x55, alts� et 'set'-telegram. 
	CPI InCmd,0x10	;Programmet sammenligner telegrammets kommando med 0x10, alts� 'start' eller 'hastighed'.
	BREQ EndOfProto	;Hvis kommandoen er 0x10, hopper programmet til slutningen af protokollen, s� dataen til telegrammet 0x55, 0x10 kan hentes i n�ste omgang i l�kken.
	CPI InCmd,0x12	;Programmet sammenligner telegrammets kommando med 0x12, alts� PWM'ens prescaler.
	BREQ EndOfProto ;Hvis kommandoen er 0x12, hopper programmet til slutningen af protokollen, s� dataen til telegrammet 0x55, 0x12 kan hentes i n�ste omgang i l�kken.
	CPI InCmd,0x13
	BREQ EndOfProto

	;Inds�t nye kommandoer over dette punkt. 
	
					;Hvis kommandoen er ingen af de ovenst�ende, antager programmet at kommandoen er 0x11, alts� kommandoen 'stop'.
	CALL StopCar	;Kalder subroutinen StopCar, der s�tter PWM'en til 0.
	JMP CleanupEndOfProto	;Hopper til efter telegramfortolkningen.

	IsGet:
		CPI InCmd,0x12
		BREQ IsFreq
		CPI InCmd,0x13
		BREQ EndOfProto
		CPI InCmd,0x10
		BRNE Error			;S�tter fejl hvis typen 0x55 ikke er sat.
		CALL SendSpeed
		JMP CleanupEndOfProto

		IsFreq:
			CALL SendPrescaler
			JMP CleanupEndOfProto

DataCheck:
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
	;Inds�t hvad der ellers skal ske i Error her 

CleanupEndOfProto:
	CALL Cleanup
EndOfProto:

JMP Main	;Hopper til starten af main

;Subroutines---------------------------------------
StopCar:
	LDI Temp1,0			;
	OUT OCR2,Temp1		;S�tter bilens hastighed til 0%
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver n�r UDR (det register som indeholder der der bliver sendt) er tom)
	RJMP Send			;Hvis UDRE er "0", hopper den tilbage til Send:, og dermed venter p� at UDR er tom.
	OUT UDR,SendReg		;L�gger SendReg ind i den tomme UDR. Dermed vil SendReg blive sendt.
	RET					;Subroutinen er f�rdig, returnerer til adressen efter subroutinen blev kaldet fra. 

SendSpeed:
	LDI SendReg,0xBB	;
	CALL Send			;Sender Replytypen (0xBB)
	IN SendReg,OCR2		;
	CALL Send			;Sender den nuv�rende hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	OUT OCR2,Ret1		;S�tter hastigheden p� bilen til resultatet fra CalcOCR2.
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
	SBRC InData,0
	JMP SetAccRefN
	LSR InData
	LDI Temp1,127
	ADD InData,Temp1
	MOV AccRefP, InData
	MOV EEPROMSave, AccRefP
	LDI Temp1, HIGH(EEPROMAccRefP)
	LDI Temp2, LOW(EEPROMAccRefP)
	CALL SaveInEEPROM
	RET

	SetAccRefN:
	JMP SetAccRefN
	LSR InData
	LDI Temp1,127
	SUB Temp1,InData
	MOV AccRefN, Temp1
	MOV EEPROMSave, AccRefN
	LDI Temp1, HIGH(EEPROMAccRefN)
	LDI Temp2, LOW(EEPROMAccRefN)
	CALL SaveInEEPROM
	RET

SendAccRef:
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
	
	;INDS�T NYE TELEGRAMTYPER

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

	;INDS�T NYE TELEGRAMKOMMANDOER.

	LDI InCmd,0
	RET

	wasCommand:
		MOV InCmd,InBesked	
		RET

Cleanup:
	LDI InType,0
	LDI InCmd,0
	LDI InData,0

	;Hvis der er flere der skal renses s� ind her

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


SaveInEEPROM:
	SBIC EECR, EEWE			;Tjekker om EEPROM er klar til at bruges 
	RJMP SaveInEEPROM
	OUT EEARH, Temp1		;S�tter lokationen i EEPROM 
	OUT EEARL, Temp2		;S�tter lokationen i EEPROM
	OUT EEDR, EEPROMSave	;Giver EEPROM den som skal gemmes
	CLI						;Stoper for intarups da de n�ste to ikke m� forstyres 
	SBI EECR, EEMWE			;S�tter Master Write til
	SBI EECR, EEWE			;S�tter write igang 
	SEI						;Starter intarups igen 
RET


LoadFromEEPROM:
	SBIC EECR, EEWE			;Tjekker om EEPROM er klar til at bruges 
	RJMP LoadFromEEPROM
	OUT EEARH, Temp1		;S�tter lokationen i EEPROM 
	OUT EEARL, Temp2		;S�tter lokationen i EEPROM
	SBI EECR, EERE			;S�tter Read til 
	IN Ret1, EEDR		;Henter hvad der er i EEPROM ned i EEPROMSave
RET

LEDSet:
	CPI LEDTimOn,1
	BREQ EndOfLEDSet
	CPI LEDVerdi,64
	BRSH ERROREndOfLEDSet	;S� hvis v�rdigen i LEDVerdi ikke svare til en v�rdig til LED'eren er der en fejl
	CALL ClearLED
	LSL LEDVerdi			;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat p� 
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, LEDVerdi		;or'er den v�rdi som skal v�re p� LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	ERROREndOfLEDSet:
	EndOfLEDSet:
RET

LED1SekSet:
	LDI LEDTimOn,1		;Sikre at LED'er ikke kan �ndres p� n�r ved at kalde LED1Sek igen inden 1 sek
	;Tjekker om LEDVerdi er gyldig
	CPI LEDVerdi,64
	BRSH ErrorLED1SekSet	;S� hvis v�rdigen i LEDVerdi ikke svare til en v�rdig til LED'eren er der en fejl 
	;T�nder LED'er med v�rdi
	LSL LEDVerdi			;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat p� 
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, LEDVerdi		;or'er den v�rdi som skal v�re p� LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	;Timer start p� 1 sek
	LDI Temp1,0
	OUT TCNT1H, Temp1
	OUT TCNT1L, Temp1
	LDI Temp1, (1<<WGM12)|(1<<CS12)|(1<<CS10)	;CTC, pre 1024 og t�nder for timer1 som er sat til 1 sek
	OUT TCCR1B, Temp1 
ErrorLED1SekSet:
RET

ClearLED:
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA som slukker alle LED'er
RET

;Intarups -----------------------------------------------------------------

ADCDone:				;N�r en ADC er f�rdig hopper den hertil
	IN	AccData, ADCL		;Indl�ser den lave del af ADC
	IN  AccData, ADCH		;Indl�ser den h�je del af ADC
	SBI ADCSRA, ADSC	;Starter conversion igen 
	RETI

Timer1CompereA:
	;Slukker LED'er
	CALL ClearLED
	;Stopper timer
	LDI Temp1, 0			;Timer fra
	OUT TCCR1B, Temp1		
	LDI LEDTimOn,0
RETI