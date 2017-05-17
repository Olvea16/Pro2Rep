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
.DEF AccSumH = R27
.DEF AccSumL = R28
.DEF DivCounter = R29
;Vi må ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29) Vi skal nok samle nogel af registeren og tjekker om vi ik kan bruge Temp og Ret. Evt lave Arg om til et register vi bruger til at give verdi til subrutiner med så EEPROMSave og LEDVerdi kan komme der ind
;--------------------------

;EEPROM
.EQU EEPROM_AccRefP = 0x000
.EQU EEPROM_AccRefN = 0x001
;Fra 0x000 til 0x3FF er gyldige  der med 1024 adresser 
;---------------------------

;Data Space

.EQU InType_DataSpace = 0x00
.EQU InCmd_DataSpace = 0x01
.EQU InBesked_DataSpace = 0x02
.EQU ZStart = 4+379			;Random data i starten af dataspace

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
.EQU Hyst = 10
.EQU Straight = 0
.EQU Turn1 = 1
.EQU Turn2 = 2

.EQU AccRefN_Konst = 100
.EQU AccRefP_Konst = 160
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
.EQU LED_Turn1 = 0b000011
.EQU LED_Turn2 = 0b011000

.EQU LED_InCmd_RGBLEDTest = 3
.EQU LED_InCmd_AccRefP = 4
.EQU LED_InCmd_AccRefN = 5
.EQU LED_InCmd_Start = 6
.EQU LED_InCmd_Stop = 7
.EQU LED_InCmd_PWMPrescaler = 8
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


.ORG 50			;Sætter adressen for denne linje til over 30, da dette ville være lige efter 28+2.

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
	LDI Temp1, (1<<TXEN)|(1<<RXEN)				;Opsætter værdien til modtagelse og afsendelse af seriel data.
	OUT UCSRB, Temp1								;Sender værdien til opsætningsregisteret, UCSRB (s. 409).
	LDI Temp1, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstilles mikrokontrolleren til 8 bit data, ingen parity bit og kun 1 stop bit.
	OUT UCSRC, Temp1								;Værdien sendes til registeret UCSRC (s. 410).
	LDI Temp1, 103								;Her indstilles baud rate til 9600 (ved 16 MHz)(s. 405).
	OUT UBRRL, Temp1								;Værdien for baud rate sendes til registeret UBRRL 

;Opsætning af PWM
	SBI DDRD,7		;PordtD Bit7 sættes og bliver output.
	LDI Temp1, (1<<WGM00)|(1<<COM01)|(1<<CS00) 
	OUT TCCR2, Temp1	;Opsætter PWM, sætter prescaleren til 1, fasekorrekt, ikke-inverteret (s. 153).
	LDI Temp1, 0		;
	OUT OCR2, Temp1	;Sætter PWM til 0, via. registeret OCR2 (OCR2 = PWM * 2.55)

;Opsætning af ADC
	CBI DDRA, 0		;Sætter PortA 0 til indput
	LDI Temp1, (1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)	;Tænder ADC, interrupt på og ck/128 for max præcision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, Temp1 
	LDI Temp1, (1<<REFS0)|(1<<ADLAR)	;AVCC pin som Vref og det er venstre justified
	OUT ADMUX, Temp1

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

LDI AccRefN, 150
LDI AccRefP, 100

LDI ZH, HIGH(ZStart)
LDI ZL, LOW(ZStart)

IN Temp1, UDR

Auto:
SBIC UCSRA,RXC	
RJMP UAuto

BRBS 6, StateMachine

JMP AutoEnd

	StateMachine:
	CALL AvgAcc
	CPI DivCounter, 0
	BRNE AutoEnd

	CPI Ret1, AccRefP_Konst
	BRSH StateMachine_Turn1

	CPI Ret1, AccRefN_Konst
	BRLO StateMachine_Turn2

	CPI Ret1, (AccRefP_Konst - Hyst)
	BRSH AutoEnd

	CPI Ret1, (AccRefN_Konst + Hyst)
	BRLO AutoEnd

		StateMachine_Straight:
		MOV Temp1,SREG2
		ANDI Temp1,0b11000000
		CPI Temp1,(Straight<<State0)
		BREQ AutoEnd

		CALL StoreTrack

		MOV Temp1, SREG2
		ANDI Temp1, 0b00111111
		ORI Temp1, (Straight<<State0)
		MOV SREG2, Temp1

		LDI Arg, LED_Straight
		CALL SetLED
		JMP AutoEnd

		StateMachine_Turn1:
		MOV Temp1,SREG2
		ANDI Temp1,0b11000000
		CPI Temp1,(Turn1<<State0)
		BREQ AutoEnd

		CALL StoreTrack

		MOV Temp1, SREG2
		ANDI Temp1, 0b00111111
		ORI Temp1, (Turn1<<State0)
		MOV SREG2, Temp1

		LDI Arg, LED_Turn1
		CALL SetLED
		JMP AutoEnd

		StateMachine_Turn2:
		MOV Temp1,SREG2
		ANDI Temp1,0b11000000
		CPI Temp1,(Turn2<<State0)
		BREQ AutoEnd

		CALL StoreTrack

		MOV Temp1, SREG2
		ANDI Temp1, 0b00111111
		ORI Temp1, (Turn2<<State0)
		MOV SREG2, Temp1

		LDI Arg, LED_Turn2
		CALL SetLED
		JMP AutoEnd

AutoEnd:

JMP Auto

AvgAcc:	
	CLT
	ADD AccSumL, AccData
	LDI Temp1,0
	ADC AccSumH, Temp1

	;Hvis tælleren er nået 255, altså 256 additioner, skal programmet gå til den sidste del af udregningen.
	CPI DivCounter, 255
	BREQ AvgAccRet 

	INC DivCounter
	JMP AvgAccEnd

	AvgAccRet:
		;Flytter resultatet, AccSumH, til returregisteret.
		MOV Ret1, AccSumH

		;Nulstiller tæller og variabler.
		LDI DivCounter, 0
		LDI AccSumH, 0
		LDI AccSumL, 0
AvgAccEnd:
RET 

UAuto:


StartOfProto:

SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN InBesked,UDR		;Hvis RXC er 1, skal programmet læse og fortolke dataen i UDR.

TypeCheck:
	LDS Ret1, InType_DataSpace
	CPI Ret1,0x00	;Tjekker om InType er tom.
	BRNE CmdCheck	;Hvis InType ikke er tom, hopper programmet til CmdCheck.
	CALL IsType		;Hvis InType er tom, tjekker programmet om den modtagne besked i InBesked er en type med subroutinen IsType.
	JMP EndOfProto	;Derefter hopper programmet videre til efter telegramfortolkningen og fortsætter i næste omgang i main-løkken.

CmdCheck:
	LDS Ret1, InCmd_DataSpace
	CPI Ret1,0x00	;Tjekker om InCmd er tom.
	BRNE DataCheckInter	;Hvis InCmd ikke er tom, hopper programmet til DataCheck.
	CALL IsCmd		;Hvis InCmd derimod er tom, tjekker programmet om den modtagne besked i InBesked er en kommmando med subroutinen IsCom.
	LDS Ret1, InType_DataSpace
	CPI Ret1, Proto_GET	;Derefter sammenligner programmet InType, altså telegrammets type, med 0xAA, altså et 'get'-telegram.
	BREQ IsGet		;Hvis telegramtypen er get, hopper programmet til IsGet.

	;Indsæt nye typer over dette punkt.
	
					;Hvis typen ikke er nogen af de ovenstående, antager programmet at typen er 0x55, altså et 'set'-telegram. 
	LDS Ret1, InCmd_DataSpace
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
	CALL PulseLED		;Tænder LED Værdien for at have modtaget et...
	JMP CleanupEndOfProto	;Hopper til efter telegramfortolkningen.

	CmdCheck_PWMStop:
		CALL StopCar
		JMP CleanupEndOfProto

DataCheckInter:
JMP DataCheck

	IsGet:
		LDS Ret1, InCmd_DataSpace
		CPI Ret1, Proto_PWMPre
		BREQ CmdCheck_IsGet_IsFreq
		CPI Ret1, Proto_AccRef
		BREQ EndOfProtoInter
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
	LDS Ret1, InType_DataSpace
	CPI Ret1, Proto_GET
	BREQ GetWithData
	CPI Ret1, Proto_SET
	BRNE Error
	LDS Ret1, InCmd_DataSpace
	CPI Ret1, Proto_PWMPre
	BREQ SetFrequency
	CPI Ret1, Proto_AccRef
	BREQ SetAcceleration
	CPI Ret1, Proto_RGBLED
	BREQ SetRGBLED
	CPI Ret1, Proto_Start
	BRNE Error
	CALL SetSpeed
	LDI Arg, LED_InCmd_Start	
	CALL PulseLED		;Tænder LED Værdien for at have modtaget et...
	JMP CleanupEndOfProto

	GetWithData:
		LDS Ret1, InCmd_DataSpace
		CPI Ret1, Proto_AccRef
		BRNE Error
		CALL SendAccRef
		JMP CleanupEndOfProto

	SetFrequency:
		CPI InBesked,8
		BRGE Error
		CALL SetPrescaler
		LDI Arg, LED_InCmd_PWMPrescaler	
		CALL PulseLED		;Tænder LED Værdien for at have modtaget et...
		JMP CleanupEndOfProto

	SetAcceleration:
		CALL SetAccRef
		JMP CleanupEndOfProto

	SetRGBLED:
		MOV  Arg, InBesked
		CALL PulseLED
		JMP CleanupEndOfProto


CleanupEndOfProto:
	CALL Cleanup
EndOfProto:

JMP UAuto	;Hopper til starten af main

;Subroutines---------------------------------------
StopCar:
	LDI Temp1,0			;
	OUT OCR2,Temp1		;Sætter bilens hastighed til 0%
	LDI Arg,LED_InCmd_Stop
	CALL PulseLED
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR (det register som indeholder der der bliver sendt) er tom)
	RJMP Send			;Hvis UDRE er "0", hopper den tilbage til Send:, og dermed venter på at UDR er tom.
	OUT UDR,Arg		;Lægger Arg ind i den tomme UDR. Dermed vil Arg blive sendt.
	RET					;Subroutinen er færdig, returnerer til adressen efter subroutinen blev kaldet fra. 

SendSpeed:
	LDI Arg, Proto_REPLY	;
	CALL Send			;Sender Replytypen (0xBB)
	LDI Arg, Proto_Start	;
	CALL Send			;Sender command Start (0x10)
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
	LDI Arg, Proto_PWMPre
	CALL Send
	IN Temp1,TCCR2
	ANDI Temp1,0b00000111
	MOV Arg,Temp1
	CALL Send
	RET

SetPrescaler:
	CPI InBesked,8
	BRGE DoNotSetPre
	CPI InBesked,0
	BREQ DoNotSetPre
	IN Temp1,TCCR2
	ANDI Temp1,0b11111000
	OR Temp1,InBesked
	OUT TCCR2,Temp1
	DoNotSetPre:
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
		LDI Arg, LED_InCmd_AccRefP	
		CALL PulseLED		;Tænder LED Værdien for at have modtaget et AccRefP
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
		LDI Arg, LED_InCmd_AccRefN	
		CALL PulseLED		;Tænder LED Værdien for at have modtaget et AccRefN
	RET

SendAccRef:
	CPI InBesked,1
	BREQ SendAccRefN
	LDI Arg, Proto_REPLY
	CALL Send
	LDI Arg, Proto_AccRef
	CALL Send
	MOV Arg, AccRefP
	CALL Send
	RET

	SendAccRefN:
	LDI Arg, Proto_REPLY
	CALL Send
	LDI Arg, Proto_AccRef
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

	/*
	Behøves ikke da der allered er tjekket om den er 0
	LDI Arg,0
	STS InType_DatSpac, Arg
	*/
	RET

	wasType:
		;MOV InType,InBesked
		STS InType_DataSpace, InBesked
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

	/*
	Behøves ikke da der allered er tjekket om den er 0
	LDI Arg,0
	STS InCmd_DatSpac, Arg
	*/
	RET

	wasCommand:
		STS InCmd_DataSpace, InBesked
		RET

Cleanup:
	;Renser Intype
	LDI Arg,0
	STS InType_DataSpace, Arg
	;Renser InCmd
	STS InCmd_DataSpace, Arg
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
	;CALL ClearLED Vi skal lige se om den behøves efter ny metode 
	LSL Arg				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat på 
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, Arg			;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA
	ERROREndOfSetLED:
	EndOfSetLED:
RET

PulseLED:
	;Tjekker om LEDVerdi er gyldig
	CPI Arg,64
	BRSH ErrorPulseLED	;Så hvis værdigen i LEDVerdi ikke svare til en værdig til LED'eren er der en fejl 
	SBR SREG2, LEDTimeOn ;Sikre at LED'er ikke kan ændres på nær ved at kalde LED1Sek igen inden 1 sek
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
ErrorPulseLED:
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
	CPI Temp1, (Turn1<<State0)
	BREQ Turn1StateLED
	CPI Temp1, (Turn2<<State0)
	BREQ Turn2StateLED
	StraightStateLED:
	LDI Arg, LED_Straight
	CALL SetLED
	RET
	Turn1StateLED:
	LDI Arg, LED_Turn1
	CALL SetLED
	RET
	Turn2StateLED:
	LDI Arg, LED_Turn2
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
		CP ZH, Temp1
		BRSH ZTjek2
	ZTjek2B:
		LD Arg, Z+
		CALL Send
		JMP ZTjek
	ZTjek2:
		CP ZL, Temp2
		BRLO ZTjek2B
		SEI
RET
;Intarups -----------------------------------------------------------------

ADCDone:				
	;Når en ADC er færdig hopper den hertil
	IN	AccData, ADCL		;Indlæser den lave del af ADC
	IN  AccData, ADCH		;Indlæser den høje del af ADC
	SBI ADCSRA, ADSC	;Starter conversion igen 
	SET
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











*/