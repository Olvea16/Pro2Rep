.ORG 0			;Vektoradresse for Reset.
SBI DDRB,0 ;Sætter B0 til out
SBI PORTB,0 
Main:
JMP Main



