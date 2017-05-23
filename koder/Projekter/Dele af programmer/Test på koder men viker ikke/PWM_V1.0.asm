.INCLUDE "M32DEF.INC"
.EQU D7=7

.ORG 0
;-----Stack opsætning-------
LDI	R16, HIGH(RAMEND)	;Loder højste hukommelse adresse (D8 til D15)(The last on-chip RAM address)
OUT	SPH, R16			;Gennemer i stack pointer 
LDI	R16, LOW(RAMEND)	;Loder højste hukommelse adresse (D0 til D7)(The last on-chip RAM address)
OUT	SPL, R16			;Gennemer i stack pointer 
;---------------------------
;Port opsætning
SBI	DDRD, D7			;Sætter PortD D7 til at være output 
;-------------
PWM:
LDI	R17,10				;De procent duty cycle der skal være
LDI R16,100				;Loder R16 med "100%"
SUB R16,R17				;Finder hvor meget der skal være slukket så 100%-"sændt"="slukket" 
SBI	PORTD, D7			;Sætter D7(PortD) til "1"
ON:
CALL DELAY_10us			;Kalder DELAY_10us(Der med er der ca et delay på 10 us)
DEC R17					;Tæller ned på hvor mange gange der skal være tændt 
BRNE ON					;Hopper til ON hvis R17 ikke er 0
CBI PORTD, D7			;Sætter D7(PortD) til "0"
OFF:
CALL DELAY_10us			;Kalder DELAY_10us(Der med er der ca et delay på 10 us)	
DEC R16					;Tæller ned på hvor mange gange der skal være slukket 
BRNE OFF				;Hopper til OFF hvis R16 ikke er 0
JMP PWM

;----------------DELAY_1ms-------Bruges ikke men gem den til hvis vi skal bruge 1 ms------------
DELAY_1ms:
PUSH R18				;Sikre R18 værdig ved at ligge den i stak
PUSH R19				;Sikre R19 værdig ved at ligge den i stak
LDI  r18, 21
LDI  r19, 199
L1_1ms: DEC  r19
    BRNE L1_1ms
    DEC  r18
    BRNE L1_1ms
POP R18					;Gennem den værdig som R18 havde får i R18 igen
POP R19					;Gennem den værdig som R19 havde får i R19 igen
RET

;----------------DELAY_10us------------------------------
DELAY_10us:
PUSH R18				;Sikre R18 værdig ved at ligge den i stak
    LDI  r18, 53
L1_10us: DEC  r18
    BRNE L1_10us
    NOP
POP R18					;Gennem den værdig som R18 havde får i R18 igen
RET