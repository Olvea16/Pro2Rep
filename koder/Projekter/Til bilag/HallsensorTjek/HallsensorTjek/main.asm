.DEF Temp1 = R16
.DEF Temp2 = R17
.DEF Arg = R24

.ORG 0			;Vektoradresse for Reset.

.ORG INT0addr
JMP InteDist
.ORG INT1addr
JMP InteDist

.ORG 300

LDI Temp1, HIGH(RAMEND)
OUT SPH,Temp1	
LDI Temp1, LOW(RAMEND)
OUT SPL,Temp1

;Ops�tning af hardware inteerupt 
	LDI Temp1, (1<<INT1)|(1<<INT0)		;T�nder for INT0 og INT1
	OUT GICR, Temp1
	LDI Temp1, (1<<ISC11)|(1<<ISC01)	;S�tter INT0 og INT1 til at trigge p� faldende signal 
	OUT MCUCR, Temp1
	SBI PORTD, 2 ;pull-up activated INT0
	SBI PORTD, 3 ;pull-up activated INT1

;Ops�tning af kommunikation
	LDI Temp1, (1<<TXEN)|(1<<RXEN)				;Ops�tter v�rdien til modtagelse og afsendelse af seriel data.
	OUT UCSRB, Temp1							;Sender v�rdien til ops�tningsregisteret, UCSRB (s. 212).
	LDI Temp1, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstilles mikrokontrolleren til 8 bit data, ingen parity bit og kun 1 stop bit.
	OUT UCSRC, Temp1							;V�rdien sendes til registeret UCSRC (s. 214).
	LDI Temp1, 103								;Her indstilles baud rate til 9600 (ved 16 MHz).
	OUT UBRRL, Temp1							;V�rdien for baud rate sendes til registeret UBRRL (s. 216).


SEI

Main:
JMP Main

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver n�r UDR (det register som indeholder der der bliver sendt) er tom)
	RJMP Send			;Hvis UDRE er "0", hopper den tilbage til Send:, og dermed venter p� at UDR er tom.
	OUT UDR,Arg		;L�gger Arg ind i den tomme UDR. Dermed vil Arg blive sendt.
	RET	

InteDist:
    LDI Arg, 0x75
	CALL Send
	RETI