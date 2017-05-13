LDI R16, 30
NOP
NewCalcOCR2:
	LDI R17,0b10100011		;2.55 som Q2.6 format
	MUL R16, R17				;Resutat ligger i R1:R0 på format Q8.5
	LSR R1
	ROR R0						;Resutat er nu på format Q8.5
	LSR R1
	ROR R0						;Resutat er nu på format Q8.4
	LSR R1
	ROR R0						;Resutat er nu på format Q8.3
	LSR R1
	ROR R0						;Resutat er nu på format Q8.2
	LSR R1
	ROR R0						;Resutat er nu på format Q8.1
	LSR R1
	ROR R0						;Resutat er nu på format Q8
	MOV R18, R0
RET