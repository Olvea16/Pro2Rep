.INCLUDE "M32DEF.INC"
.EQU D1=1

.ORG 0
;-----Stack opsætning-------
LDI	R16, HIGH(RAMEND)	;Loder højste hukommelse adresse (D8 til D15)(The last on-chip RAM address)
OUT	SPH, R16			;Gennemer i stack pointer 
LDI	R16, LOW(RAMEND)	;Loder højste hukommelse adresse (D0 til D7)(The last on-chip RAM address)
OUT	SPL, R16			;Gennemer i stack pointer 
;---------------------------
;Skal nok flyttes til starten af program 
SBI DDRD, D1			;Sætter Prot D bit D1 til outpudt 
;---------------------------------------

LDI R20, 0b10101010			;Den værdig jeg vil sende
CALL SendR20			;Kalder SendR20		
;-----------Evigt hold----------------
HOLD:		
JMP HOLD				;Eving loop som stop 
;-------------------------------------

SendR20:
PUSH R16				;Sikre R16 værdig ved at ligge den i stak
CLC						;Clear flag C
LDI	R16,8				;Tæller er 8 da det er 8 bit data 
;SBI	PORTD, D1			;Sender "1" Som start bit 

Igen:					;Flag til at gentage sending 
	ROR R20				;Sender D0 ud til flag C 
	BRCS En				;Hvis C er "1" hopper den til "En"
	CBI PORTD, D1		;Bit 0 af PortD bliver sat til "0" 
	JMP Neste 
En:	SBI PORTD, D1		;Bit 1 af PortB bliver sat til "1"
Neste:					;Flag til at behandle tælder 
	DEC	R16				;R16=R16-1 Tælder ned med 1 så der holdes øje med hvornår der er sendt 8 bit 
	CPI R16, 0
	BRNE Igen			;Hvis der ikke er snedt 8 bit (R16 ikke = 0) hopper den til igen og der med sendes næste bit
;SBI PORTD, D1			;Sætter slut bittet til 1 
POP R16					;Gennem den værdig som R16 havde får i R16 igen
RET
