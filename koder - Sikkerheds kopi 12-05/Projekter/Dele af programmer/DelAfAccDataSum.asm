.DEF Temp1 = R16	;Midlertidigt register, bruges også til interrupts.
.DEF Temp2 = R17	;Midlertidigt register.
.DEF AccData = R21
.DEF AccRefP = R25
.DEF AccRefN = R26
.DEF AccSumH = R27
.DEF AccSumL = R28


.EQU AccSumHAntalBit = 4
.EQU AccSumAntalDiv = 15




BRTC StateMachineEnd	;Hvis T flag ikke er sat hopper over denne del og state machine
MOV Temp1, AccSumH
ANDI Temp1, 0b11110000
CPI Temp1, (AccSumAntalDiv<<AccSumHAntalBit)
BREQ SidsteGangAccSum
	;Addere hvor mange gange der er blevet sumeret 
	LDI Temp2, 0b00010000
	ADD Temp1, Temp2
	ANDI AccSumH, 0b00001111
	OR AccSumH, Temp1
	;
	;Summere AccData
	ADD AccSumL, AccData
	LDI Temp2,0
	ADC AccSumH, Temp2
	;
	JMP EndOfSum

SidsteGangAccSum:
	;Summere AccData
	ADD AccSumL, AccData
	LDI Temp2,0
	ADC AccSumH, Temp2
	;
	;Nulstiller antal div
	ANDI AccSumH, 0b00001111
	;
	;Dividere med 16 for at få gennemsnit
	LSR AccSumH
	ROR AccSumL		;Div 2
	LSR AccSumH
	ROR AccSumL		;Div 4
	LSR AccSumH
	ROR AccSumL		;Div 8
	LSR AccSumH
	ROR AccSumL		;Div 16
	;
	RJMP StateMachine

EndOfSum:

;---------------------------------------------------------------------

ADCDone:				
	;Når en ADC er færdig hopper den hertil
	IN	AccData, ADCL		;Indlæser den lave del af ADC
	IN  AccData, ADCH		;Indlæser den høje del af ADC
	SBI ADCSRA, ADSC		;Starter conversion igen 
	SET						;Sætter T Falg til 1 for at sige AccData er klar 
RETI