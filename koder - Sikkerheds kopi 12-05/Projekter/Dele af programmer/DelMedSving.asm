;AccRefP
;AccRefN
.CSEG		    ;Angiver at dette tilhører program hukommelse. Markerer starten på et kodesegment med sin egen location counter.  
.ORG 0
RJMP Setup      ;Springer til setup 
.ORG ADCCaddr	;Dette er den for en ADC er færdig 
RJMP ADCDone

SEI	;Intrups er tændt 

AccHandling: 

CP AccData,AccRefP

JMP EndOfAccHandling
Turning:


EndOfAccHandling:


SetAccRef:
	SBRC InData,0
	JMP SetAccRefN
	LSR InData
	LDI Temp1,127
	ADD InData,Temp1
	MOV AccRefP, InData
	RET

	SetAccRefN:
	JMP SetAccRefN
	LSR InData
	LDI Temp1,127
	SUB Temp1,InData
	MOV AccRefN, Temp1
	RET

SendAccRef:
	CPI InData,1
	BREQ SendAccRefN
	LDI SendReg, 0xBB
	CALL Send
	MOV SendReg, AccRefP
	CALL Send
	RET

	SendAccRefN:
	LDI SendReg, 0xBB
	CALL Send
	MOV SendReg, AccRefN
	CALL Send
	RET

	

ADCDone:				;Når en ADC er færdig hopper den hertil
	IN	AccData, ADCL		;Indlæser den lave del af ADC
	IN  AccData, ADCH		;Indlæser den høje del af ADC
	SBI ADCSRA, ADSC	;Starter conversion igen 
	RETI