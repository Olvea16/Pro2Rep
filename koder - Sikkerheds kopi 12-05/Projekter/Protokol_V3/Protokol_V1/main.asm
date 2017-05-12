;
; Protokol_V1.asm
;
; Created: 21-04-2017 10:49:12
; Author : simon
;


; Replace with your application code
; Sidetal anviser sidenummer i ATmega32A datasheet uploadet på blackboard.

;Register
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
.DEF LEDTimOn = R27	;Til at fortælle om der er en timet LED igang
.DEF EEPROMSave = R28
;Vi må ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29) Vi skal nok samle nogel af registeren og tjekker om vi ik kan bruge Temp og Ret. Evt lave SendReg om til et register vi bruger til at give verdi til subrutiner med så EEPROMSave og LEDVerdi kan komme der ind
;--------------------------

;EEPROM
.EQU EEPROM_AccRefP = 0x000
.EQU EEPROM_AccRefN = 0x001
;Fra 0x000 til 0x3FF er gyldige  der med 1024 adresser 
;---------------------------

;Data Space
/*
.EQU Intype_DatSpac = 0x0000
.EQU InCmd_DatSpac = 0x0001

;.EQU ZStart = "Indsæt den sidste af dem for oven her +1
*/
;---------------------------

;Protokol 
.EQU Proto_SET = 0x55
.EQU Proto_GET = 0xAA
.EQU Proto_REPLY = 0xBB

.EQU Proto_Start = 0x10
.EQU Proto_Stop = 0x11
.EQU Proto_PWMPre = 0x12
.EQU Proto_AccRef = 0x13
.EQU Proto_RGBLED = 0x14
.EQU Proto_PWMStop = 0x15
;---------------------------

;LED
.EQU Acc0_LED = 0b111111
.EQU AccN_LED = 0b000011
.EQU AccP_LED = 0b011000

.EQU CmdIn_RGBLEDTest_LED = 3
.EQU CmdIn_AccRefP_LED = 4
.EQU CmdIn_AccRefN_LED = 5
.EQU CmdIn_Start_LED = 6
.EQU CmdIn_Stop_LED = 7
.EQU CmdIn_PWMPrescaler_LED = 8
;---------------------------

;---------/\/\/\Navngivning/\/\/\---------------------------\/\/\/Kode\/\/\/---------------------------------------------------------------------------------------------------------------------------------------------------------

.ORG 0			;Vektoradresse for Reset.
RJMP Setup      ;Springer til setup. 

.ORG ADCCaddr	;Dette er den for en ADC er færdig 
JMP ADCDone

.ORG OC1Aaddr	;Timer 1 compereA servisrutine
JMP Timer1CompereA	


.ORG 50			;Sætter adressen for denne linje til 30, da dette ville være lige efter 28+2.

Setup:
;Opsætning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader højeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader højeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 

;Indhætning af verdier fra EEPROM
LDI Temp1, HIGH(EEPROM_AccRefP)
LDI Temp2, LOW(EEPROM_AccRefP)
CALL LoadFromEEPROM
MOV AccRefP, Ret1
LDI Temp1, HIGH(EEPROM_AccRefN)
LDI Temp2, LOW(EEPROM_AccRefN)
CALL LoadFromEEPROM
MOV AccRefN, Ret1
;---

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

;Opsætning af noget af timere1
	LDI Temp1, 0
	OUT TCCR1A, Temp1 
	LDI Temp1,(1<<OCIE1A)	;Timer 1 comber med OCR1A 
	OUT TIMSK,Temp1
	LDI Temp1, HIGH(15625-1)	;Hvor meget der skal til får at få 1 sek 
	OUT	OCR1AH,Temp1
	LDI Temp1, LOW(15625-1)		;Hvor meget der skal til får at få 1 sek 
	OUT	OCR1AL,Temp1

SEI	;Enabler interrupts. 
SBI ADCSRA, ADSC		;Starter conversion (ADC)

;Main---------------------------------------
Main:
AccBehandling:
	CP AccData, AccRefP
	BRSH AccP
	CP AccData, AccRefN
	BRLO AccN
		LDI Temp1, Acc0_LED
		CALL LEDSet
		JMP EndAccBehandling

	AccP:
		LDI Temp1, AccP_LED
		CALL LEDSet
		JMP EndAccBehandling
	AccN:
		LDI Temp1, AccN_LED
		CALL LEDSet

EndAccBehandling:

StartOfProto:

SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN InBesked,UDR		;Hvis RXC er 1, skal programmet læse og fortolke dataen i UDR.

TypeCheck:
	CPI InType,0x00	;Tjekker om InType er tom.
	BRNE CmdCheck	;Hvis InType ikke er tom, hopper programmet til CmdCheck.
	CALL IsType		;Hvis InType er tom, tjekker programmet om den modtagne besked i InBesked er en type med subroutinen IsType.
	JMP EndOfProto	;Derefter hopper programmet videre til efter telegramfortolkningen og fortsætter i næste omgang i main-løkken.

CmdCheck:
	CPI InCmd,0x00	;Tjekker om InCmd er tom.
	BRNE DataCheck	;Hvis InCmd ikke er tom, hopper programmet til DataCheck.
	CALL IsCmd		;Hvis InCmd derimod er tom, tjekker programmet om den modtagne besked i InBesked er en kommmando med subroutinen IsCom.
	CPI InType, Proto_GET	;Derefter sammenligner programmet InType, altså telegrammets type, med 0xAA, altså et 'get'-telegram.
	BREQ IsGet		;Hvis telegramtypen er get, hopper programmet til IsGet.

	;Indsæt nye typer over dette punkt.
	
					;Hvis typen ikke er nogen af de ovenstående, antager programmet at typen er 0x55, altså et 'set'-telegram. 
	CPI InCmd, Proto_Start	;Programmet sammenligner telegrammets kommando med 0x10, altså 'start' eller 'hastighed'.
	BREQ EndOfProtoInter	;Hvis kommandoen er 0x10, hopper programmet til slutningen af protokollen, så dataen til telegrammet 0x55, 0x10 kan hentes i næste omgang i løkken.
	CPI InCmd, Proto_PWMPre	;Programmet sammenligner telegrammets kommando med 0x12, altså PWM'ens prescaler.
	BREQ EndOfProtoInter ;Hvis kommandoen er 0x12, hopper programmet til slutningen af protokollen, så dataen til telegrammet 0x55, 0x12 kan hentes i næste omgang i løkken.
	CPI InCmd, Proto_AccRef
	BREQ EndOfProtoInter

	;Indsæt nye kommandoer over dette punkt. 
	
					;Hvis kommandoen er ingen af de ovenstående, antager programmet at kommandoen er 0x11, altså kommandoen 'stop'.
	CALL StopCar	;Kalder subroutinen StopCar, der sætter PWM'en til 0.
	LDI Temp1, CmdIn_Stop_LED	
	CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et...
	JMP CleanupEndOfProto	;Hopper til efter telegramfortolkningen.

	IsGet:
		CPI InCmd, Proto_PWMPre
		BREQ IsFreq
		CPI InCmd, Proto_AccRef
		BREQ EndOfProto
		CPI InCmd, Proto_Start
		BRNE Error			;Sætter fejl hvis typen 0x55 ikke er sat.
		CALL SendSpeed
		JMP CleanupEndOfProto

		IsFreq:
			CALL SendPrescaler
			JMP CleanupEndOfProto
;Dette er en mellem station til EndOfProto
JMP	SkipEndOfProtoInter
EndOfProtoInter:
JMP EndOfProto
SkipEndOfProtoInter:

DataCheck:
	CPI InData,0
	BRNE Error
	MOV InData,InBesked
	CPI InType, Proto_GET
	BREQ GetWithData
	CPI InType, Proto_SET
	BRNE Error
	CPI InCmd, Proto_PWMPre
	BREQ SetFrequency
	CPI InCmd, Proto_AccRef
	BREQ SetAcceleration
	CPI InCmd, Proto_Start
	BRNE Error
	CALL SetSpeed
	LDI Temp1, CmdIn_Start_LED	
	CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et...
	JMP CleanupEndOfProto

	GetWithData:
		CPI InCmd, Proto_AccRef
		BRNE Error
		CALL SendAccRef
		JMP CleanupEndOfProto

	SetFrequency:
		CPI InData,8
		BRGE Error
		CALL SetPrescaler
		LDI Temp1, CmdIn_PWMPrescaler_LED	
		CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et...
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
	LDI SendReg, Proto_REPLY	;
	CALL Send			;Sender Replytypen (0xBB)
	IN SendReg,OCR2		;
	CALL Send			;Sender den nuværende hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	OUT OCR2,Ret1		;Sætter hastigheden på bilen til resultatet fra CalcOCR2.
	RET

SendPrescaler:
	LDI SendReg, Proto_REPLY
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
	;AccRefP
		LSR InData
		LDI Temp1,127
		ADD InData,Temp1
		MOV AccRefP, InData
		MOV EEPROMSave, AccRefP
		LDI Temp1, HIGH(EEPROM_AccRefP)
		LDI Temp2, LOW(EEPROM_AccRefP)
		CALL SaveInEEPROM
		LDI Temp1, CmdIn_AccRefP_LED	
		CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et AccRefP
	RET

	SetAccRefN:
		LSR InData
		LDI Temp1,127
		SUB Temp1,InData
		MOV AccRefN, Temp1
		MOV EEPROMSave, AccRefN
		LDI Temp1, HIGH(EEPROM_AccRefN)
		LDI Temp2, LOW(EEPROM_AccRefN)
		CALL SaveInEEPROM
		LDI Temp1, CmdIn_AccRefN_LED	
		CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et AccRefN
	RET

SendAccRef:
	CPI InData,1
	BREQ SendAccRefN
	LDI SendReg, Proto_REPLY
	CALL Send
	MOV SendReg, AccRefP
	CALL Send
	RET

	SendAccRefN:
	LDI SendReg, Proto_REPLY
	CALL Send
	MOV SendReg, AccRefN
	CALL Send
	RET

IsType:
	CPI InBesked, Proto_SET
	BREQ wasType
	CPI InBesked, Proto_GET
	BREQ wasType
	CPI InBesked, Proto_REPLY
	BREQ wasType
	
	;INDSÆT NYE TELEGRAMTYPER

	LDI InType,0
	RET

	wasType:
		MOV InType,InBesked	
		RET

IsCmd:
	CPI InBesked, Proto_Start
	BREQ wasCommand
	CPI InBesked, Proto_Stop
	BREQ wasCommand
	CPI InBesked, Proto_PWMPre
	BREQ wasCommand
	CPI InBesked, Proto_AccRef
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


SaveInEEPROM:
	SBIC EECR, EEWE			;Tjekker om EEPROM er klar til at bruges 
	RJMP SaveInEEPROM
	OUT EEARH, Temp1		;Sætter lokationen i EEPROM 
	OUT EEARL, Temp2		;Sætter lokationen i EEPROM
	OUT EEDR, EEPROMSave	;Giver EEPROM den som skal gemmes
	CLI						;Stoper for intarups da de næste to ikke må forstyres 
	SBI EECR, EEMWE			;Sætter Master Write til
	SBI EECR, EEWE			;Sætter write igang 
	SEI						;Starter intarups igen 
RET


LoadFromEEPROM:
	SBIC EECR, EEWE			;Tjekker om EEPROM er klar til at bruges 
	RJMP LoadFromEEPROM
	OUT EEARH, Temp1		;Sætter lokationen i EEPROM 
	OUT EEARL, Temp2		;Sætter lokationen i EEPROM
	SBI EECR, EERE			;Sætter Read til 
	IN Ret1, EEDR		;Henter hvad der er i EEPROM ned i EEPROMSave
RET

LEDSet:
	CPI LEDTimOn,1
	BREQ EndOfLEDSet
	CPI Temp1,64
	BRSH ERROREndOfLEDSet	;Så hvis værdigen i LEDVerdi ikke svare til en værdig til LED'eren er der en fejl
	CALL ClearLED
	LSL Temp1				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat på 
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, Temp1			;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA
	ERROREndOfLEDSet:
	EndOfLEDSet:
RET

LED1SekSet:
	LDI LEDTimOn,1			;Sikre at LED'er ikke kan ændres på nær ved at kalde LED1Sek igen inden 1 sek
	;Tjekker om LEDVerdi er gyldig
	CPI Temp1,64
	BRSH ErrorLED1SekSet	;Så hvis værdigen i LEDVerdi ikke svare til en værdig til LED'eren er der en fejl 
	;Tænder LED'er med værdi
	LSL Temp1				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat på 
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, Temp1			;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA
	;Timer1 start (Den er på 1 sek)
	LDI Temp1,0
	OUT TCNT1H, Temp1
	OUT TCNT1L, Temp1
	LDI Temp1, (1<<WGM12)|(1<<CS12)|(1<<CS10)	;CTC, pre 1024 og tænder for timer1 som er sat til 1 sek
	OUT TCCR1B, Temp1 
ErrorLED1SekSet:
RET

ClearLED:
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA som slukker alle LED'er
RET
	
GetLED:
	IN Ret1, PORTA			;Loader PORTA ind 
	ANDI Ret1, 0b01111110	;Udmasker bit 0 og 7 
	LSR Ret1				;Rykker Ret1 en til højre så det passer med at LED verdi er mellem 0 og 63 
RET

;Intarups -----------------------------------------------------------------

ADCDone:				
	;Når en ADC er færdig hopper den hertil
	IN	AccData, ADCL		;Indlæser den lave del af ADC
	IN  AccData, ADCH		;Indlæser den høje del af ADC
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





;----------------------\/\/\/Junk jart\/\/\/ ----------------------



/*
;Tænder LED for modtaget Cmd 1 sek
		LDI Temp1, CmdIn_LED
		CALL LED1SekSet
;
*/

/*
LDI Temp1, CmdIn_LED	
CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et...
*/