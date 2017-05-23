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

	;Ops�tning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader h�jeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader h�jeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 

	;Ops�tning af ADC
	LDI R16,0
	OUT DDRA, R16	;S�tter PortA 0 til indput
	LDI R16,0x8F	;T�nder ADC, interrupt p� og ck/128 for max pr�cision 0x8F(0b10001111)   0x89(10001001)=ck/2
	OUT ADCSRA, R16
	LDI R16,0x60	;AVCC pin som Vref og det er h�jre justified 0x40(0b?01000000?) 0xC0for2.45 vref
	OUT ADMUX, R16

main:
	IN	Temp1, ADCL		;Indl�ser den lave del af ADC
	IN  Temp1, ADCH		;Indl�ser den h�je del af ADC
	SBI ADCSRA, ADSC		;Starter conversion igen 
	LSR Temp1
	LSR Temp1
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, Temp1			;or'er den v�rdi som skal v�re p� LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	JMP main


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

ClearLED:
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker alt andet end bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA som slukker alle LED'er
RET