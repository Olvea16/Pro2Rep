.DEF Temp1 = R16	;Midlertidigt register, bruges også til interrupts.
.DEF Temp2 = R17	;Midlertidigt register.
.DEF AccData = R21
.DEF AccRefP = R25
.DEF AccRefN = R26
;"Nye"-------
.DEF AccSumH = R27
.DEF AccSumL = R28
.DEF DivCounter = R29
.EQU AntalDiv = 255
;


AccDiv:
	CPI DivCounter, AntalDiv
	BREQ SidsteGangAccSum
		;Addere hvor mange gange der er blevet sumeret 
		INC DivCounter
		;
		;Summere AccData
		ADD AccSumL, AccData
		LDI Temp1,0
		ADC AccSumH, Temp1
		;
		JMP EndOfSum

	SidsteGangAccSum:
		;Summere AccData
		ADD AccSumL, AccData
		LDI Temp1,0
		ADC AccSumH, Temp1
		;
		;Nulstiller antal div
		LDI DivCounter, 0
		;
		;Dividere med 256 for at få gennemsnit af 256 Acc værdiger
		LSR AccSumH
		ROR AccSumL		;Div 2
		LSR AccSumH
		ROR AccSumL		;Div 4
		LSR AccSumH
		ROR AccSumL		;Div 8
		LSR AccSumH
		ROR AccSumL		;Div 16
		LSR AccSumH
		ROR AccSumL		;Div 32
		LSR AccSumH
		ROR AccSumL		;Div 64
		LSR AccSumH
		ROR AccSumL		;Div 128
		LSR AccSumH
		ROR AccSumL		;Div 256
		;
		MOV Ret1, AccSumL
		LDI AccSumH, 0
		LDI AccSumL, 0
EndOfSum:
RET 

;---------------------------------------------------------------------

ADCDone:				
	;Når en ADC er færdig hopper den hertil
	IN	AccData, ADCL		;Indlæser den lave del af ADC
	IN  AccData, ADCH		;Indlæser den høje del af ADC
	SBI ADCSRA, ADSC		;Starter conversion igen 
	SET						;Sætter T Falg til 1 for at sige AccData er klar 
RETI