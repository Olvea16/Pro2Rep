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

;Vi må ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29) Vi skal nok samle nogel af registeren og tjekker om vi ik kan bruge Temp og Ret. Evt lave Arg om til et register vi bruger til at give verdi til subrutiner med så EEPROMSave og LEDVerdi kan komme der ind
;--------------------------

.EQU LEDTimeOn = 3

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
;---------------------------



;---------/\/\/\Navngivning/\/\/\---------------------------\/\/\/Kode\/\/\/---------------------------------------------------------------------------------------------------------------------------------------------------------

.ORG 0			;Vektoradresse for Reset.
RJMP Setup      ;Springer til setup.

.ORG ADCCaddr	;Dette er den for en ADC er færdig 
JMP ADCDone

.ORG 50			;Sætter adressen for denne linje til over 30, da dette ville være Straight efter 28+2.


;Opsætning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader højeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader højeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer

;Opsætning af ADC
	LDI Temp1,0
	OUT DDRA, Temp1	;Sætter PortA 0 til indput
	LDI Temp1,0x8F	;Tænder ADC, interrupt på og ck/128 for max præcision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, Temp1
	LDI Temp1,0x60	;AVCC pin som Vref og det er højre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, Temp1
;Opsætning af RGB LED
	SBI DDRA, 1
	SBI DDRA, 2
	SBI DDRA, 3
	SBI DDRA, 4
	SBI DDRA, 5
	SBI DDRA, 6

;Opsætning af PWM
	SBI DDRD,7		;PordtD Bit7 sættes og bliver output.
	LDI R16,0x63	;(0110 0011)
	OUT TCCR2,R16	;Opsætter PWM, sætter prescaleren til 1/32 (ca. 1 kHz), fasekorrekt, ikke-inverteret (s. 153).
	LDI R16,0		;
	OUT OCR2,R16	;Sætter PWM til 0, via. registeret OCR2 (OCR2 = PWM * 2.55)

LDI AccRefP,(127 + 15)
LDI AccRefN,(127 - 17)

StartOp:
LDI Temp1, 0x7D
OUT OCR2, Temp1

LDI Arg,0b111111
CALL SetLED

Lige:
CP AccData, AccRefP
BRSH Sving
CP AccData, AccRedN
BRLO Sving
JMP Lige
Sving:
LDI Temp1, (0x7D - 0x10)
OUT OCR2, Temp1
LDI Arg,0b100100
CALL SetLED
SvingTjek:
CP AccData, AccRefP
BRLO 





















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