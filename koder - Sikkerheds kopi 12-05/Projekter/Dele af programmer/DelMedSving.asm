;AccRefP
;AccRefN
.CSEG		    ;Angiver at dette tilh�rer program hukommelse. Markerer starten p� et kodesegment med sin egen location counter.  
.ORG 0
RJMP Setup      ;Springer til setup 
.ORG ADCCaddr	;Dette er den for en ADC er f�rdig 
RJMP ADCDone

SEI	;Intrups er t�ndt 

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

	

ADCDone:				;N�r en ADC er f�rdig hopper den hertil
	IN	AccData, ADCL		;Indl�ser den lave del af ADC
	IN  AccData, ADCH		;Indl�ser den h�je del af ADC
	SBI ADCSRA, ADSC	;Starter conversion igen 
	RETI