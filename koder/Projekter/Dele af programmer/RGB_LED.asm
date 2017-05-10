.ORG OC1Aaddr
JMP Timer1CompereA	;Timer 1 overflow servisrutine
 
.ORG 50
;Ops�tning af LED pins PORTA pin 1 til 6 til output
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


;SBI er kravet
;Stack er kravet
;s 342/336 timer 1
;s 374/368 inta
;15625-1 = 1 sek med 1024 pre

;Subrutine-------------

LEDSet:
	CPI RGBLEDTimOn,1
	BREQ EndOfLEDSet
	LSL Temp1				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat p� 
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, Temp1			;or'er den v�rdi som skal v�re p� LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	EndOfLEDSet:
RET


LED1SekSet:
	LDI RGBLEDTimOn,1		;Sikre at LED'er ikke kan �ndres p� n�r ved at kalde LED1Sek igen inden 1 sek
	;Tjekker om Temp1 er gyldig
	CPI Temp1,64
	BRSH Error				;S� hvis v�rdigen i Temp1 ikke svare til en v�rdig til LED'eren er der en fejl 
	;T�nder LED'er med v�rdi
	LSL Temp1				;Rykker LED infoen en til venstre for at der kommer til at passe med hvor de er sat p� 
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, Temp1			;or'er den v�rdi som skal v�re p� LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	;Timer start p� 1 sek
	LDI Temp1,0
	OUT TCNT1H, Temp1
	OUT TCNT1L, Temp1
	LDI Temp1, (1<<WGM12)|(1<<CS12)|(1<<CS10)	;CTC, pre 1024 og t�nder for timer1 som er sat til 1 sek
	OUT TCCR1B, Temp1 
RET

;Intarubt-------------

Timer1CompereA:
	;Slukker LED'er
	LDI Temp1,0
	IN Temp2, PORTA			;Loader PORTA ind for at undg� kompliktation med ADC
	ANDI Temp2, 0b10000001	;Udmasker bit 0 og 7 for ikke at �ndre v�rdiger for ADC og ubrugt pin 7 
	OR Temp2, Temp1			;or'er den v�rdi som slukker for LED'eren sammen med det der allerede var p� PORTA
	OUT	PORTA, Temp2		;Sender den nye v�rdig ud p� PORTA
	;Stopper timer
	LDI Temp1, 0			;Timer fra
	OUT TCCR1B, Temp1		
	LDI RGBLEDTimOn,0
RETI

