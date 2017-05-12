;
; LEDACCTEST.asm
;
; Created: 12-05-2017 17:35:47
; Author : Oliver
;


; Replace with your application code
.EQU LEDTimeOn = 3

.DEF Temp1 = R16
.DEF Temp2 = R17
.DEF Arg = R21
.DEF SREG2 = R22

	;Opsætning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader højeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader højeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 

	;Opsætning af ADC
	LDI R16,0
	OUT DDRA, R16	;Sætter PortA 0 til indput
	LDI R16,0x8F	;Tænder ADC, interrupt på og ck/128 for max præcision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, R16
	LDI R16,0x60	;AVCC pin som Vref og det er højre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, R16

main:
	IN	Temp1, ADCL		;Indlæser den lave del af ADC
	IN  Temp1, ADCH		;Indlæser den høje del af ADC
	SBI ADCSRA, ADSC		;Starter conversion igen 
	LSR Temp1
	LSR Temp1
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, Temp1			;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA
	JMP main


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

ClearLED:
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA som slukker alle LED'er
RET