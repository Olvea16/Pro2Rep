;
; Protokol_V1.asm
;
; Created: 21-04-2017 10:49:12
; Author : simon
;


; Replace with your application code
; Sidetal anviser sidenummer i ATmega32A datasheet uploadet på blackboard.

;Register
.DEF Temp1 = R16	;Midlertidigt register, bruges også til interrupts.
.DEF Temp2 = R17	;Midlertidigt register.
.DEF Arg = R18 ;Argumentregister
.DEF Ret1 = R19 ;Returregister.
.DEF InBesked = R20 ;Register til besked 
.DEF AccData = R21
.DEF SREG2 = R22
.DEF DistH = R23
.DEF DistL = R24
.DEF AccRefP = R25
.DEF AccRefN = R26
;Vi må ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29) Vi skal nok samle nogel af registeren og tjekker om vi ik kan bruge Temp og Ret. Evt lave Arg om til et register vi bruger til at give verdi til subrutiner med så EEPROMSave og LEDVerdi kan komme der ind
;--------------------------

;EEPROM
.EQU EEPROM_AccRefP = 0x000
.EQU EEPROM_AccRefN = 0x001
;Fra 0x000 til 0x3FF er gyldige  der med 1024 adresser 
;---------------------------

;Data Space

.EQU Intype_DatSpac = 0x00
.EQU InCmd_DatSpac = 0x01
.EQU InBesked_DatSpac = 0x02
.EQU ZStart = 0x04

;SREG2 Navngivning
.EQU StateCount0 = 0 
.EQU StateCount1 = 1
.EQU StateCount2 = 2
.EQU LEDTimeON = 3
.EQU LastState0 = 4 
.EQU LastState1 = 5 
.EQU State0 = 6
.EQU State1 = 7
;---------------------------

;
.EQU Straight = 0
.EQU Sving1 = 1
.EQU Sving2 = 2
;

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
.EQU Proto_Track = 0x16
;---------------------------

;LED
.EQU LED_Straight = 0b111111
.EQU LED_Sving1 = 0b000011
.EQU LED_Sving2 = 0b011000

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

.ORG INT0addr
JMP InteDist

.ORG ADCCaddr	;Dette er den for en ADC er færdig 
JMP ADCDone

.ORG OC1Aaddr	;Timer 1 compereA servisrutine
JMP Timer1CompereA	


.ORG 50			;Sætter adressen for denne linje til over 30, da dette ville være Straight efter 28+2.

Setup:

LDI SREG2,0

;Opsætning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader højeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader højeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 

;Opsætning af hardware inteerupt 
	LDI Temp1, (1<<INT0);|(1<<INT1)		;Tænder for INT0 og INT1
	OUT GICR, Temp1
	LDI Temp1, (1<<ISC01);|(1<<ISC11)	;Sætter INT0 og INT1 til at trigge på faldende signal 
	OUT MCUCR, Temp1
	SBI PORTD, 2 ;pull-up activated INT0
	;SBI PORTD, 3 ;pull-up activated INT1

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
;---------------------------------------
Auto:
SBIC UCSRA,RXC	
RJMP UAuto

StateMachine:
CP AccData, AccRefP
BRSH AccP ;Hopper hvis AccData er det samme eller højre end AccRefP
CP AccData, AccRefN
BRLO AccN ;Hopper hvis AccData er laver end AccRefN
	;Straight
		MOV Temp1, SREG2
		ANDI Temp1, 0b11000000
		CPI Temp1, Straight
		BREQ StateMachineEnd

		MOV Temp1, SREG2
		ANDI Temp1, 0b00110000
		CPI Temp1, (Straight<<State0)
		BRNE NewStateStraight
		MOV Temp1, SREG2
		ANDI Temp1, 0b00000111
		CPI Temp1, 7
		BREQ ChangeStateStraight
		INC SREG2
		RJMP StateMachineEnd
			
		NewStateStraight:
			LDI Temp1, (Straight<<LastState0)
			ANDI SREG2,0b11001000			;Ligger sving1 ind som last state og renser statecount 
			OR SREG2, Temp1
			RJMP StateMachineEnd

		ChangeStateStraight:
			CALL ChangeState 
			RJMP StateMachineEnd	

	AccP:
		MOV Temp1, SREG2
		ANDI Temp1, 0b11000000
		CPI Temp1, Sving2
		BREQ StateMachineEnd

		MOV Temp1, SREG2
		ANDI Temp1, 0b00110000
		CPI Temp1, (Sving2<<State0)
		BRNE NewStateSving2
		MOV Temp1, SREG2
		ANDI Temp1, 0b00000111
		CPI Temp1, 7
		BREQ ChangeStateSving2
		INC SREG2
		RJMP StateMachineEnd
			
		NewStateSving2:
			LDI Temp1, (Sving2<<LastState0)
			ANDI SREG2,0b11001000			;Ligger sving1 ind som last state og renser statecount 
			OR SREG2, Temp1
			RJMP StateMachineEnd

		ChangeStateSving2:
			CALL ChangeState 
			RJMP StateMachineEnd

	AccN:
		MOV Temp1, SREG2
		ANDI Temp1, 0b11000000
		CPI Temp1, Sving1
		BREQ StateMachineEnd

		MOV Temp1, SREG2
		ANDI Temp1, 0b00110000
		CPI Temp1, (Sving1<<State0)
		BRNE NewStateSving1
		MOV Temp1, SREG2
		ANDI Temp1, 0b00000111
		CPI Temp1, 7
		BREQ ChangeStateSving1
		INC SREG2
		RJMP StateMachineEnd
			
		NewStateSving1:
			LDI Temp1, (Sving1<<LastState0)
			ANDI SREG2,0b11001000			;Ligger sving1 ind som last state og renser statecount 
			OR SREG2, Temp1
			RJMP StateMachineEnd

		ChangeStateSving1:
			CALL ChangeState 
			RJMP StateMachineEnd

StateMachineEnd:
JMP Auto

UAuto:


StartOfProto:

SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN InBesked,UDR		;Hvis RXC er 1, skal programmet læse og fortolke dataen i UDR.

TypeCheck:
	LDS Ret1, Intype_DatSpac
	CPI Ret1,0x00	;Tjekker om InType er tom.
	BRNE CmdCheck	;Hvis InType ikke er tom, hopper programmet til CmdCheck.
	CALL IsType		;Hvis InType er tom, tjekker programmet om den modtagne besked i InBesked er en type med subroutinen IsType.
	JMP EndOfProto	;Derefter hopper programmet videre til efter telegramfortolkningen og fortsætter i næste omgang i main-løkken.

CmdCheck:
	LDS Ret1, InCmd_DatSpac
	CPI Ret1,0x00	;Tjekker om InCmd er tom.
	BRNE DataCheckInter	;Hvis InCmd ikke er tom, hopper programmet til DataCheck.
	CALL IsCmd		;Hvis InCmd derimod er tom, tjekker programmet om den modtagne besked i InBesked er en kommmando med subroutinen IsCom.
	LDS Ret1, Intype_DatSpac
	CPI Ret1, Proto_GET	;Derefter sammenligner programmet InType, altså telegrammets type, med 0xAA, altså et 'get'-telegram.
	BREQ IsGet		;Hvis telegramtypen er get, hopper programmet til IsGet.

	;Indsæt nye typer over dette punkt.
	
					;Hvis typen ikke er nogen af de ovenstående, antager programmet at typen er 0x55, altså et 'set'-telegram. 
	LDS Ret1, InCmd_DatSpac
	CPI Ret1, Proto_PWMStop
	BREQ CmdCheck_PWMStop
	CPI Ret1, Proto_Start	;Programmet sammenligner telegrammets kommando med 0x10, altså 'start' eller 'hastighed'.
	BREQ EndOfProtoInter	;Hvis kommandoen er 0x10, hopper programmet til slutningen af protokollen, så dataen til telegrammet 0x55, 0x10 kan hentes i næste omgang i løkken.
	CPI Ret1, Proto_PWMPre	;Programmet sammenligner telegrammets kommando med 0x12, altså PWM'ens prescaler.
	BREQ EndOfProtoInter ;Hvis kommandoen er 0x12, hopper programmet til slutningen af protokollen, så dataen til telegrammet 0x55, 0x12 kan hentes i næste omgang i løkken.
	CPI Ret1, Proto_AccRef
	BREQ EndOfProtoInter
	CPI Ret1, Proto_RGBLED
	BREQ EndOfProtoInter
	;Indsæt nye kommandoer over dette punkt. 
	
					;Hvis kommandoen er ingen af de ovenstående, antager programmet at kommandoen er 0x11, altså kommandoen 'stop'.
	CALL StopCar	;Kalder subroutinen StopCar, der sætter PWM'en til 0.
	LDI Arg, 0x10	
	CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et...
	JMP CleanupEndOfProto	;Hopper til efter telegramfortolkningen.

	CmdCheck_PWMStop:
		CALL StopCar
		JMP CleanupEndOfProto

DataCheckInter:
JMP DataCheck

	IsGet:
		LDS Ret1, InCmd_DatSpac
		CPI Ret1, Proto_PWMPre
		BREQ CmdCheck_IsGet_IsFreq
		CPI Ret1, Proto_AccRef
		BREQ SkipEndOfProtoInter
		CPI Ret1, Proto_RGBLED
		BREQ CmdCheck_IsGet_IsRGBLED
		CPI Ret1, Proto_Track
		BREQ CmdCheck_IsGet_Track
		CPI Ret1, Proto_Start
		BRNE Error			;Sætter fejl hvis typen 0x55 ikke er sat.
		CALL SendSpeed
		JMP CleanupEndOfProto

		CmdCheck_IsGet_IsFreq:
			CALL SendPrescaler
			JMP CleanupEndOfProto

		CmdCheck_IsGet_IsRGBLED:
			CALL GetLED
			LDI Arg,Proto_Reply
			CALL Send
			MOV Arg,Ret1
			CALL Send
			JMP CleanupEndOfProto

		CmdCheck_IsGet_Track:
			CALL SendTrack
			JMP CleanupEndOfProto

;Dette er en mellem station til EndOfProto
JMP	SkipEndOfProtoInter
EndOfProtoInter:
JMP EndOfProto
Error:
	CALL Cleanup
	;Indsæt hvad der ellers skal ske i Error her 
	JMP EndOfProto
SkipEndOfProtoInter:

DataCheck:
	;MOV InData,InBesked Slettes
	LDS Ret1, Intype_DatSpac
	CPI Ret1, Proto_GET
	BREQ GetWithData
	CPI Ret1, Proto_SET
	BRNE Error
	LDS Ret1, InCmd_DatSpac
	CPI Ret1, Proto_PWMPre
	BREQ SetFrequency
	CPI Ret1, Proto_AccRef
	BREQ SetAcceleration
	CPI Ret1, Proto_RGBLED
	BREQ SetRGBLED
	CPI Ret1, Proto_Start
	BRNE Error
	CALL SetSpeed
	LDI Arg, CmdIn_Start_LED	
	CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et...
	JMP CleanupEndOfProto

	GetWithData:
		LDS Ret1, InCmd_DatSpac
		CPI Ret1, Proto_AccRef
		BRNE Error
		CALL SendAccRef
		JMP CleanupEndOfProto

	SetFrequency:
		CPI InBesked,8
		BRGE Error
		CALL SetPrescaler
		LDI Arg, CmdIn_PWMPrescaler_LED	
		CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et...
		JMP CleanupEndOfProto

	SetAcceleration:
		CALL SetAccRef
		JMP CleanupEndOfProto

	SetRGBLED:
		MOV  Arg, InBesked
		CALL LED1SekSet
		JMP CleanupEndOfProto


CleanupEndOfProto:
	CALL Cleanup
EndOfProto:

JMP UAuto	;Hopper til starten af main

;Subroutines---------------------------------------
StopCar:
	LDI Temp1,0			;
	OUT OCR2,Temp1		;Sætter bilens hastighed til 0%
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR (det register som indeholder der der bliver sendt) er tom)
	RJMP Send			;Hvis UDRE er "0", hopper den tilbage til Send:, og dermed venter på at UDR er tom.
	OUT UDR,Arg		;Lægger Arg ind i den tomme UDR. Dermed vil Arg blive sendt.
	RET					;Subroutinen er færdig, returnerer til adressen efter subroutinen blev kaldet fra. 

SendSpeed:
	LDI Arg, Proto_REPLY	;
	CALL Send			;Sender Replytypen (0xBB)
	IN Arg,OCR2		;
	CALL Send			;Sender den nuværende hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	OUT OCR2,Ret1		;Sætter hastigheden på bilen til resultatet fra CalcOCR2.
	RET

SendPrescaler:
	LDI Arg, Proto_REPLY
	CALL Send
	IN Temp1,TCCR2
	ANDI Temp1,0b00000111
	MOV Arg,Temp1
	CALL Send
	RET

SetPrescaler:
	IN Temp1,TCCR2
	ANDI Temp1,0b11111000
	OR Temp1,InBesked
	OUT TCCR2,Temp1
	RET


SetAccRef:
	SBRC InBesked,0
	JMP SetAccRefN
	;AccRefP
		LSR InBesked
		LDI Temp1,127
		ADD InBesked,Temp1
		MOV AccRefP, InBesked
		MOV Arg, AccRefP
		LDI Temp1, HIGH(EEPROM_AccRefP)
		LDI Temp2, LOW(EEPROM_AccRefP)
		CALL SaveInEEPROM
		LDI Ret1, CmdIn_AccRefP_LED	
		CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et AccRefP
	RET

	SetAccRefN:
		LSR InBesked
		LDI Temp1,127
		SUB Temp1,InBesked
		MOV AccRefN, Temp1
		MOV Arg, AccRefN
		LDI Temp1, HIGH(EEPROM_AccRefN)
		LDI Temp2, LOW(EEPROM_AccRefN)
		CALL SaveInEEPROM
		LDI Ret1, CmdIn_AccRefN_LED	
		CALL LED1SekSet		;Tænder LED Værdien for at have modtaget et AccRefN
	RET

SendAccRef:
	CPI InBesked,1
	BREQ SendAccRefN
	LDI Arg, Proto_REPLY
	CALL Send
	MOV Arg, AccRefP
	CALL Send
	RET

	SendAccRefN:
	LDI Arg, Proto_REPLY
	CALL Send
	MOV Arg, AccRefN
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

	LDI Arg,0
	STS Intype_DatSpac, Arg
	RET

	wasType:
		;MOV InType,InBesked
		STS Intype_DatSpac, InBesked
		RET

IsCmd:
	CPI InBesked, Proto_Start		;0x10
	BREQ wasCommand
	CPI InBesked, Proto_Stop		;0x11
	BREQ wasCommand
	CPI InBesked, Proto_PWMPre		;0x12
	BREQ wasCommand
	CPI InBesked, Proto_AccRef		;0x13
	BREQ wasCommand
	CPI InBesked, Proto_RGBLED		;0x14
	BREQ wasCommand
	CPI InBesked, Proto_PWMStop		;0x15
	BREQ wasCommand
	CPI InBesked, Proto_Track		;0x16
	BREQ wasCommand

	;INDSÆT NYE TELEGRAMKOMMANDOER.

	LDI Arg,0
	STS InCmd_DatSpac, Arg
	RET

	wasCommand:
		STS InCmd_DatSpac, InBesked
		RET

Cleanup:
	;Renser Intype
	LDI Arg,0
	STS Intype_DatSpac, Arg
	;Renser InCmd
	STS InCmd_DatSpac, Arg
	;Renser InBesked
	LDI InBesked,0
	LDI Temp1, 0
	LDI Temp2, 0
	LDI Ret1, 0

	;Hvis der er flere der skal renses så ind her

	RET

CalcOCR2:
	MOV Temp1,InBesked
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
	OUT EEDR, Arg	;Giver EEPROM den som skal gemmes
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
	IN Ret1, EEDR		;Henter hvad der er i EEPROM ned i Ret1
RET

SetLED:
	SBRC SREG2, LEDTimeOn
	RJMP EndOfSetLED
	CPI Arg,64
	BRSH ERROREndOfSetLED	;Så hvis værdigen i LEDVerdi ikke svare til en værdig til LED'eren er der en fejl
	CALL ClearLED
	LSL Arg				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat på 
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, Arg			;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA
	ERROREndOfSetLED:
	EndOfSetLED:
RET

LED1SekSet:
	SBR SREG2, LEDTimeOn ;Sikre at LED'er ikke kan ændres på nær ved at kalde LED1Sek igen inden 1 sek
	;Tjekker om LEDVerdi er gyldig
	CPI Arg,64
	BRSH ErrorLED1SekSet	;Så hvis værdigen i LEDVerdi ikke svare til en værdig til LED'eren er der en fejl 
	;Tænder LED'er med værdi
	LSL Arg				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat på 
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, Arg			;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
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

ChangeState:
	CALL StoreTrack
	MOV Temp1, SREG2
	ANDI Temp1, 0b00110000
	LSL Temp1
	LSL Temp1
	ANDI SREG2, 0b00111111
	OR SREG2, Temp1
	;Midertidigt
	CALL StateLED
	;
RET

StateLED:
	MOV Temp1, SREG2
	ANDI Temp1, 0b11000000
	CPI Temp1, (Sving1<<State0)
	BREQ Sving1StateLED
	CPI Temp1, (Sving2<<State0)
	BREQ Sving2StateLED
	StraightStateLED:
	LDI Arg, LED_Straight
	CALL SetLED
	RET
	Sving1StateLED:
	LDI Arg, LED_Sving1
	CALL SetLED
	RET
	Sving2StateLED:
	LDI Arg, LED_Sving2
	CALL SetLED
	RET

StoreTrack:
	MOV Temp1, SREG2
	ANDI Temp1,0b11000000
	OR DistH, Temp1
	ST Z+, DistH
	ST Z+, DistL
	LDI DistH,0
	LDI DistL,0
RET

SendTrack:
	CALL StopCar
	LDI Arg, Proto_REPLY
	CALL Send
	CLI
	MOV Temp1, ZH
	MOV Temp2, ZL
	LDI ZH, HIGH(ZStart)
	LDI ZL, LOW(ZStart)
	ZTjek:
		CP Temp1, ZH
		BREQ ZTjek2
	ZTjek2B:
		LD Arg, Z+
		CALL Send
		JMP ZTjek
	ZTjek2:
		CP Temp2, ZL
		BRNE ZTjek2B
		SEI
RET
;Intarups -----------------------------------------------------------------

ADCDone:				
	;Når en ADC er færdig hopper den hertil
	IN	AccData, ADCL		;Indlæser den lave del af ADC
	IN  AccData, ADCH		;Indlæser den høje del af ADC
	SBI ADCSRA, ADSC	;Starter conversion igen 
RETI

Timer1CompereA:
	PUSH Temp1
	;Slukker LED'er
	CALL ClearLED
	;Stopper timer
	LDI Temp1, 0			;Timer fra
	OUT TCCR1B, Temp1		
	CBR SREG2, LEDTimeOn
	POP Temp1
RETI

InteDist:
	PUSH Temp1
	LDI Temp1, 1
	ADD DistL, Temp1
	LDI Temp1, 0
	ADC DistH, Temp1
	POP Temp1
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