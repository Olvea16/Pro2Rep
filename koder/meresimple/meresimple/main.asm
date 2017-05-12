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

;Vi m� ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29) Vi skal nok samle nogel af registeren og tjekker om vi ik kan bruge Temp og Ret. Evt lave Arg om til et register vi bruger til at give verdi til subrutiner med s� EEPROMSave og LEDVerdi kan komme der ind
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

.ORG ADCCaddr	;Dette er den for en ADC er f�rdig 
JMP ADCDone

.ORG 50			;S�tter adressen for denne linje til over 30, da dette ville v�re Straight efter 28+2.


;Ops�tning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader h�jeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader h�jeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer

;Ops�tning af ADC
	LDI Temp1,0
	OUT DDRA, Temp1	;S�tter PortA 0 til indput
	LDI Temp1,0x8F	;T�nder ADC, interrupt p� og ck/128 for max pr�cision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, Temp1
	LDI Temp1,0x60	;AVCC pin som Vref og det er h�jre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, Temp1
;Ops�tning af RGB LED
	SBI DDRA, 1
	SBI DDRA, 2
	SBI DDRA, 3
	SBI DDRA, 4
	SBI DDRA, 5
	SBI DDRA, 6

;Ops�tning af PWM
	SBI DDRD,7		;PordtD Bit7 s�ttes og bliver output.
	LDI R16,0x63	;(0110 0011)
	OUT TCCR2,R16	;Ops�tter PWM, s�tter prescaleren til 1/32 (ca. 1 kHz), fasekorrekt, ikke-inverteret (s. 153).
	LDI R16,0		;
	OUT OCR2,R16	;S�tter PWM til 0, via. registeret OCR2 (OCR2 = PWM * 2.55)

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