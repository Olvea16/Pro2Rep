;Register
.DEF Temp1 = R16	;Midlertidigt register, bruges ogs� til interrupts.
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
.DEF AccCounter = R29

;Vi m� ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29) Vi skal nok samle nogel af registeren og tjekker om vi ik kan bruge Temp og Ret. Evt lave Arg om til et register vi bruger til at give verdi til subrutiner med s� EEPROMSave og LEDVerdi kan komme der ind
;--------------------------

.EQU LEDTimeOn = 3

;EEPROM
.EQU EEPROM_AccRefP = 0x000
.EQU EEPROM_AccRefN = 0x001
;Fra 0x000 til 0x3FF er gyldige  der med 1024 adresser 
;---------------------------

;Data Space

.EQU AccRefP_Konst = 0x8B
.EQU AccRefN_Konst = 0x7B

.EQU Intype_DatSpac = 0x00
.EQU InCmd_DatSpac = 0x01
.EQU InBesked_DatSpac = 0x02
.EQU ZStart = 0x04

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

.EQU CmdIn_RGBLEDTest_LED = 3
.EQU CmdIn_AccRefP_LED = 4
.EQU CmdIn_AccRefN_LED = 5
.EQU CmdIn_Start_LED = 6
.EQU CmdIn_Stop_LED = 7
.EQU CmdIn_PWMPrescaler_LED = 8

.EQU AccSumHAntalBit = 4
.EQU AccSumAntalDiv = 15

.EQU AccCount = 255
;---------------------------



;---------/\/\/\Navngivning/\/\/\---------------------------\/\/\/Kode\/\/\/---------------------------------------------------------------------------------------------------------------------------------------------------------

.ORG 0			;Vektoradresse for Reset.
RJMP Setup      ;Springer til setup.

.ORG ADCCaddr	;Dette er den for en ADC er f�rdig 
JMP ADCDone

.ORG OC1Aaddr	;Timer 1 compereA servisrutine
JMP Timer1CompereA	


.ORG 50			;S�tter adressen for denne linje til over 30, da dette ville v�re Straight efter 28+2.

Setup:

LDI SREG2,0

;Ops�tning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader h�jeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader h�jeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 


;Indh�tning af verdier fra EEPROM
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

;Ops�tning af noget af timere1
	LDI Temp1, 0
	OUT TCCR1A, Temp1 
	LDI Temp1,(1<<OCIE1A)	;Timer 1 comber med OCR1A 
	OUT TIMSK,Temp1
	LDI Temp1, HIGH(15625-1)	;Hvor meget der skal til f�r at f� 1 sek 
	OUT	OCR1AH,Temp1
	LDI Temp1, LOW(15625-1)		;Hvor meget der skal til f�r at f� 1 sek 
	OUT	OCR1AL,Temp1

SBI DDRB,0 ;S�tter B0 til out
SEI	;Enabler interrupts. 
SBI ADCSRA, ADSC		;Starter conversion (ADC)
;---------------------------------------

LDI AccRefP, 0x8B
;Midt = 84
LDI AccRefN, 0x7B

LDI Arg,63
CALL SetLED
CLT

StraightInit:
;Set hastighed til 50
LDI AccCounter,0
LDI Arg, 60
CALL CalcOCR2
OUT OCR2, Ret1

;Sluk elektromagnet
SBI PORTB,0

;T�nd hvidt lys
LDI Arg,0b111111
CALL SetLED

Straight:
/*SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP UAuto*/
;Tester Accelerometerdata

CALL AccSumSub
CPI Ret1,0
BREQ Straight

CP Ret1, AccRefP
BRSH Turn1Tick
CP Ret1, AccRefN
BRLO Turn2Tick
RJMP Straight

	Turn1Tick:
	CPI AccCounter, AccCount
	BRSH Turn1Init
	INC AccCounter
	JMP Straight

	Turn2Tick:
	CPI AccCounter, AccCount
	BRSH Turn2Init
	INC AccCounter
	JMP Straight

Turn1Init:
;Set hastighed til 32
LDI AccCounter,0
LDI Arg, 32
CALL CalcOCR2
OUT OCR2, Ret1

;T�nd elektromagnet
CBI PORTB,0

;T�nd gult lys
LDI Arg,0b000011
CALL SetLED

Turn1:
/*SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP UAuto*/
;Tester Accelerometerdata

CALL AccSumSub
CPI Ret1,0
BREQ Turn1

CPI Ret1, (AccRefP_Konst-5)
BRSH Turn1
RJMP StraightTick1

	StraightTick1:
		CPI AccCounter, AccCount
		BRSH StraightInit
		INC AccCounter
		JMP Turn1

RJMP OverIntStraightInit
IntStraightInit:
JMP StraightInit
OverIntStraightInit:

Turn2Init:
;Set hastighed til 32
LDI AccCounter,0
LDI Temp1, 0x50
OUT OCR2, Temp1

;T�nd elektromagnet
CBI PORTB,0

;T�nd gult lys
LDI Arg,0b011000
CALL SetLED

Turn2:
/*SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP UAuto*/
;Tester Accelerometerdata

CALL AccSumSub
CPI Ret1,0
BREQ Turn2

CPI Ret1, (AccRefN_Konst+5)
BRLO Turn2
RJMP StraightTick2

	StraightTick2:
		CPI AccCounter, AccCount
		BRSH IntStraightInit
		INC AccCounter
		JMP Turn2












UAuto:
StartOfProto:

SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN InBesked,UDR		;Hvis RXC er 1, skal programmet l�se og fortolke dataen i UDR.

TypeCheck:
	LDS Ret1, Intype_DatSpac
	CPI Ret1,0x00	;Tjekker om InType er tom.
	BRNE CmdCheck	;Hvis InType ikke er tom, hopper programmet til CmdCheck.
	CALL IsType		;Hvis InType er tom, tjekker programmet om den modtagne besked i InBesked er en type med subroutinen IsType.
	JMP EndOfProto	;Derefter hopper programmet videre til efter telegramfortolkningen og forts�tter i n�ste omgang i main-l�kken.

CmdCheck:
	LDS Ret1, InCmd_DatSpac
	CPI Ret1,0x00	;Tjekker om InCmd er tom.
	BRNE DataCheckInter	;Hvis InCmd ikke er tom, hopper programmet til DataCheck.
	CALL IsCmd		;Hvis InCmd derimod er tom, tjekker programmet om den modtagne besked i InBesked er en kommmando med subroutinen IsCom.
	LDS Ret1, Intype_DatSpac
	CPI Ret1, Proto_GET	;Derefter sammenligner programmet InType, alts� telegrammets type, med 0xAA, alts� et 'get'-telegram.
	BREQ IsGet		;Hvis telegramtypen er get, hopper programmet til IsGet.

	;Inds�t nye typer over dette punkt.
	
					;Hvis typen ikke er nogen af de ovenst�ende, antager programmet at typen er 0x55, alts� et 'set'-telegram. 
	LDS Ret1, InCmd_DatSpac
	CPI Ret1, Proto_PWMStop
	BREQ CmdCheck_PWMStop
	CPI Ret1, Proto_Start	;Programmet sammenligner telegrammets kommando med 0x10, alts� 'start' eller 'hastighed'.
	BREQ EndOfProtoInter	;Hvis kommandoen er 0x10, hopper programmet til slutningen af protokollen, s� dataen til telegrammet 0x55, 0x10 kan hentes i n�ste omgang i l�kken.
	CPI Ret1, Proto_PWMPre	;Programmet sammenligner telegrammets kommando med 0x12, alts� PWM'ens prescaler.
	BREQ EndOfProtoInter ;Hvis kommandoen er 0x12, hopper programmet til slutningen af protokollen, s� dataen til telegrammet 0x55, 0x12 kan hentes i n�ste omgang i l�kken.
	CPI Ret1, Proto_AccRef
	BREQ EndOfProtoInter
	CPI Ret1, Proto_RGBLED
	BREQ EndOfProtoInter
	;Inds�t nye kommandoer over dette punkt. 
	
					;Hvis kommandoen er ingen af de ovenst�ende, antager programmet at kommandoen er 0x11, alts� kommandoen 'stop'.
	CALL StopCar	;Kalder subroutinen StopCar, der s�tter PWM'en til 0.
	LDI Arg, 0x10	
	CALL LED1SekSet		;T�nder LED V�rdien for at have modtaget et...
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
		BREQ EndOfProtoInter
		CPI Ret1, Proto_RGBLED
		BREQ CmdCheck_IsGet_IsRGBLED
		CPI Ret1, Proto_Start
		BRNE Error			;S�tter fejl hvis typen 0x55 ikke er sat.
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

;Dette er en mellem station til EndOfProto
JMP	SkipEndOfProtoInter
EndOfProtoInter:
JMP EndOfProto
Error:
	CALL Cleanup
	;Inds�t hvad der ellers skal ske i Error her 
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
	CALL LED1SekSet		;T�nder LED V�rdien for at have modtaget et...
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
		CALL LED1SekSet		;T�nder LED V�rdien for at have modtaget et...
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
	OUT OCR2,Temp1		;S�tter bilens hastighed til 0%
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver n�r UDR (det register som indeholder der der bliver sendt) er tom)
	RJMP Send			;Hvis UDRE er "0", hopper den tilbage til Send:, og dermed venter p� at UDR er tom.
	OUT UDR,Arg		;L�gger Arg ind i den tomme UDR. Dermed vil Arg blive sendt.
	RET					;Subroutinen er f�rdig, returnerer til adressen efter subroutinen blev kaldet fra. 

SendSpeed:
	LDI Arg, Proto_REPLY	;
	CALL Send			;Sender Replytypen (0xBB)
	MOV Arg,AccData		;
	CALL Send			;Sender den nuv�rende hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	OUT OCR2,Ret1		;S�tter hastigheden p� bilen til resultatet fra CalcOCR2.
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
		LDI Arg, CmdIn_AccRefP_LED	
		CALL LED1SekSet		;T�nder LED V�rdien for at have modtaget et AccRefP
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
		LDI Arg, CmdIn_AccRefN_LED	
		CALL LED1SekSet		;T�nder LED V�rdien for at have modtaget et AccRefN
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
	
	;INDS�T NYE TELEGRAMTYPER

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

	;INDS�T NYE TELEGRAMKOMMANDOER.

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

	;Hvis der er flere der skal renses s� ind her

	RET

CalcOCR2:
	MOV Temp1,Arg
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
	OUT EEDR, Arg	;Giver EEPROM den som skal gemmes
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
	IN Ret1, EEDR		;Henter hvad der er i EEPROM ned i Ret1
RET

SetLED:
	SBRC SREG2, LEDTimeOn
	RJMP EndOfSetLED
	CPI Arg,64
	BRSH ERROREndOfSetLED	;S� hvis v�rdigen i LEDVerdi ikke svare til en v�rdig til LED'eren er der en fejl
	CALL ClearLED
	LSL Arg				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat p� 
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, Arg			;or'er den v�rdi som skal v�re p� LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	ERROREndOfSetLED:
	EndOfSetLED:
RET

LED1SekSet:
	SBR SREG2, LEDTimeOn ;Sikre at LED'er ikke kan �ndres p� n�r ved at kalde LED1Sek igen inden 1 sek
	;Tjekker om LEDVerdi er gyldig
	CPI Arg,64
	BRSH ErrorLED1SekSet	;S� hvis v�rdigen i LEDVerdi ikke svare til en v�rdig til LED'eren er der en fejl 
	;T�nder LED'er med v�rdi
	LSL Arg				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat p� 
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, Arg			;or'er den v�rdi som skal v�re p� LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	;Timer1 start (Den er p� 1 sek)
	LDI Temp1,0
	OUT TCNT1H, Temp1
	OUT TCNT1L, Temp1
	LDI Temp1, (1<<WGM12)|(1<<CS12)|(1<<CS10)	;CTC, pre 1024 og t�nder for timer1 som er sat til 1 sek
	OUT TCCR1B, Temp1 
ErrorLED1SekSet:
RET

ClearLED:
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA som slukker alle LED'er
RET
	
GetLED:
	IN Ret1, PORTA			;Loader PORTA ind 
	ANDI Ret1, 0b01111110	;Udmasker bit 0 og 7 
	LSR Ret1				;Rykker Ret1 en til h�jre s� det passer med at LED verdi er mellem 0 og 63 
RET

AccSumSub:
	MOV Temp1, AccSumH
	ANDI Temp1, 0b11110000
	CPI Temp1, (AccSumAntalDiv<<AccSumHAntalBit)
	BREQ SidsteGangAccSum
		;Addere hvor mange gange der er blevet sumeret 
		LDI Temp2, 0b00010000
		ADD Temp1, Temp2
		ANDI AccSumH, 0b00001111
		OR AccSumH, Temp1
		;
		;Summere AccData
		ADD AccSumL, AccData
		LDI Temp2,0
		ADC AccSumH, Temp2
		;
		LDI Ret1, 0
		JMP EndOfSum

	SidsteGangAccSum:
		;Summere AccData
		ADD AccSumL, AccData
		LDI Temp2,0
		ADC AccSumH, Temp2
		;
		;Nulstiller antal div
		ANDI AccSumH, 0b00001111
		;
		;Dividere med 16 for at f� gennemsnit
		LSR AccSumH
		ROR AccSumL		;Div 2
		LSR AccSumH
		ROR AccSumL		;Div 4
		LSR AccSumH
		ROR AccSumL		;Div 8
		LSR AccSumH
		ROR AccSumL		;Div 16
		;
		MOV Ret1, AccSumL
		LDI AccSumH, 0
		LDI AccSumL, 0
		RJMP EndOfSum
EndOfSum:
RET

;Intarups -----------------------------------------------------------------

ADCDone:				
	;N�r en ADC er f�rdig hopper den hertil
	IN	AccData, ADCL		;Indl�ser den lave del af ADC
	IN  AccData, ADCH		;Indl�ser den h�je del af ADC
	SBI ADCSRA, ADSC		;Starter conversion igen 
	SET						;S�tter T Falg til 1 for at sige AccData er klar 
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