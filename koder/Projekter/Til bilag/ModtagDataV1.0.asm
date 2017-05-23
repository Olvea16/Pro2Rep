.INCLUDE "M32DEF.INC"
.EQU D0=0

.ORG 0
;-----Stack opsætning-------
LDI	R16, HIGH(RAMEND)	;Loder højste hukommelse adresse (D8 til D15)(The last on-chip RAM address)
OUT	SPH, R16			;Gennemer i stack pointer 
LDI	R16, LOW(RAMEND)	;Loder højste hukommelse adresse (D0 til D7)(The last on-chip RAM address)
OUT	SPL, R16			;Gennemer i stack pointer 
;---------------------------
;Skal nok flyttes til starten af program 
CBI DDRD, D0			;bit D0 af Port D som input
;---------------------------------------
CALL ModtagLigIR21			;Kalder SendR20		
;-----------Evigt hold----------------
HOLD:		
JMP HOLD				;Eving loop som stop 
;-------------------------------------


ModtagLigIR21:
PUSH R16				;Sikre R16 værdig ved at ligge den i stak
;Opsætning af port, tælle værdig (R16) og R21 som der gennems i 
LDI R16, 8				;R16 = 8 Da der er 8 bit 
LDI R21, 0				;R20 = 0 Den der bliver gemt til 

Igen:
;Hvis der kommer "1" ind 
SBIC PIND, D0			;Hopper til næste linje OVER hvis D0 i Port D er "0"(Da SBIC=Skip if Bit in I/O Register is Cleared)
SEC						;set carry flag to one
;Hvis der kommer "0" ind
SBIS PIND, D0			;Hopper til næste linje OVER hvis D0 i Port D er "1" (Da SBIC=Skip if Bit in I/O Register is Set)
CLC						;Sætter FlagC til "0"
;Gemmer værdigen i R21
ROR R21					;Flytter FlagC ind i R21 (MSB) ved at rotere 
DEC R16					;R16=R16-1(Tæller ned så der bliver kørt 8 bit igennem)
BRNE Igen				;Hvis R16 ikke er blevet 0 går den proccesen igen (Hvis den er 0 er der kørt gennem 8 bit)
;Hopper ud af "ModtagLigIR21" igen
POP R16					;Gennem den værdig som R16 havde får i R16 igen
RET