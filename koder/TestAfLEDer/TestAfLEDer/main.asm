;Dette program er lavet for at test RGB LED'er til bilen 
;Via seriel kommunikation kan man sende en værdig 0<=verdi<64 hvilket vil give RGB LED værdigen ind til andet er givet
;Der kan også sendes en værdig mellem 64<=Verdi<127
;
;
;
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
.DEF LEDTimOn = R27	;Til at fortælle om der er en timet LED igang
.DEF LEDVerdi = R28
;Vi må ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29)
;--------------------------

.ORG 0			;Vektoradresse for Reset.
RJMP Setup      ;Springer til setup. 
.ORG OC1Aaddr
JMP Timer1CompereA	;Timer 1 overflow servisrutine
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

;Main---------------------------------------
Main:



;MiniPorto
StartMiniPorto:
SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfMiniProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN LEDVerdi,UDR		;Hvis RXC er 1, skal programmet læse og fortolke dataen i UDR.
CPI LEDVerdi,64
BRSH TimerLED
	CALL LEDSet
	JMP EndOfMiniProto

TimerLED:
	SUBI LEDVerdi,63
	CPI LEDVerdi,64
	BRSH EndOfMiniProto
	CALL LED1SekSet
EndOfMiniProto:

JMP Main	;Hopper til starten af main

;Subrutine-------------

LEDSet:
	CPI LEDTimOn,1
	BREQ EndOfLEDSet
	CPI LEDVerdi,64
	BRSH ERROREndOfLEDSet	;Så hvis værdigen i LEDVerdi ikke svare til en værdig til LED'eren er der en fejl
	CALL ClearLED
	LSL LEDVerdi			;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat på 
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, LEDVerdi		;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA
	ERROREndOfLEDSet:
	EndOfLEDSet:
RET


LED1SekSet:
	LDI LEDTimOn,1		;Sikre at LED'er ikke kan ændres på nær ved at kalde LED1Sek igen inden 1 sek
	;Tjekker om LEDVerdi er gyldig
	CPI LEDVerdi,64
	BRSH ErrorLED1SekSet	;Så hvis værdigen i LEDVerdi ikke svare til en værdig til LED'eren er der en fejl 
	;Tænder LED'er med værdi
	LSL LEDVerdi			;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat på 
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OR Temp2, LEDVerdi		;or'er den værdi som skal være på LED'eren sammen med det der allerede var på PORTA
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA
	;Timer start på 1 sek
	LDI Temp1,0
	OUT TCNT1H, Temp1
	OUT TCNT1L, Temp1
	LDI Temp1, (1<<WGM12)|(1<<CS12)|(1<<CS10)	;CTC, pre 1024 og tænder for timer1 som er sat til 1 sek
	OUT TCCR1B, Temp1 
ErrorLED1SekSet:
RET

ClearLED:
	IN Temp2, PORTA			;Loader PORTA ind for at undgå kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at ændre værdiger for ADC og ubrugt pin 7 
	OUT	PORTA, Temp2		;Sender den nye værdig ud på PORTA som slukker alle LED'er
RET

;Intarubt-------------

Timer1CompereA:
	;Slukker LED'er
	CALL ClearLED
	;Stopper timer
	LDI Temp1, 0			;Timer fra
	OUT TCCR1B, Temp1		
	LDI LEDTimOn,0
RETI