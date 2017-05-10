;Dette program er lavet for at test RGB LED'er til bilen 
;Via seriel kommunikation kan man sende en v�rdig 0<=verdi<64 hvilket vil give RGB LED v�rdigen ind til andet er givet
;Der kan ogs� sendes en v�rdig mellem 64<=Verdi<127
;
;
;
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
;Vi m� ikke tage R30 og R31 hvis vi gerne vil have Z (X og Y er R26 til R29)
;--------------------------

.ORG 0			;Vektoradresse for Reset.
RJMP Setup      ;Springer til setup. 
.ORG OC1Aaddr
JMP Timer1CompereA	;Timer 1 overflow servisrutine
.ORG 50			;S�tter adressen for denne linje til 30, da dette ville v�re lige efter 28+2.

Setup:
;Ops�tning af stack
	LDI Temp1, HIGH(RAMEND)			;Loader h�jeste hukommelsesadresse (D8 til D15)(The last on-chip RAM address)
	OUT SPH,Temp1					;Gemmer i stack pointer 
	LDI Temp1, LOW(RAMEND)			;Loader h�jeste hukommelsesadresse (D0 til D7)(The last on-chip RAM address)
	OUT SPL,Temp1					;Gemmer i stack pointer 

;Ops�tning af kommunikation
	LDI R16, (1<<TXEN)|(1<<RXEN);|(1<<RXCIE)	;Ops�tter v�rdien til modtagelse og afsendelse af seriel data.
	OUT UCSRB, R16								;Sender v�rdien til ops�tningsregisteret, UCSRB (s. 212).
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstilles mikrokontrolleren til 8 bit data, ingen parity bit og kun 1 stop bit.
	OUT UCSRC, R16								;V�rdien sendes til registeret UCSRC (s. 214).
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz).
	OUT UBRRL, R16								;V�rdien for baud rate sendes til registeret UBRRL (s. 216).

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


SEI	;Enabler interrupts.

;Main---------------------------------------
Main:



;MiniPorto
StartMiniPorto:
SBIS UCSRA,RXC		;Tester bitten RXC, der viser, om mikrocontrolleren har modtaget en besked, i registeret UCSRA.
JMP EndOfMiniProto		;Hvis RXC er 0, skal programmet hoppe over telegramfortolkningen.
IN LEDVerdi,UDR		;Hvis RXC er 1, skal programmet l�se og fortolke dataen i UDR.
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

;Intarubt-------------

Timer1CompereA:
	;Slukker LED'er
	CALL ClearLED
	;Stopper timer
	LDI Temp1, 0			;Timer fra
	OUT TCCR1B, Temp1		
	LDI LEDTimOn,0
RETI