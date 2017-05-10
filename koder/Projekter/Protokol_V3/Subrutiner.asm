StopCar:
	LDI Temp1,0			;Se?
	OUT OCR2,Temp1		;Sætter bilen hastighed til 0%
	RET

Send:
	SBIS UCSRA,UDRE		;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1"
	RJMP Send			;Hvis UDRE er "0" hopper den tilbage til Send: og dermed venter på at UDR er tom 
	OUT UDR,SendReg		;Ligger SendReg ind i den tomme UDR. Dermed vil SendReg blive sendt
	RET					;Subrutinen er færdig programcounteren vil blive sat til den adresse som var efter CALL 

SendSpeed:
	LDI SendReg,0xBB	;Se?
	CALL Send			;Sender Reply (0xBB)
	IN OCR2,SendReg		;Se?
	CALL Send			;Sender den nuværnde hastighed 
	RET

SetSpeed:
	CALL CalcOCR2		;Kalder en subrutine der udregner OCR2 (Dens resutat ligger i Ret1)
	OUT OCR2,Ret1		;Sætter hastigheden på bilen til hvad der kom i Ret1 efter udregningen 
	RET

IsType:
	CPI Arg1,0x55
	BREQ wasType
	CPI Arg1,0xAA
	BREQ wasType
	CPI Arg1,0xBB
	BREQ wasType
	
	;INDSÆT NYE TELEGRAMTYPER

	LDI Ret1,0
	RET

	wasType:
		LDI Ret1,1
		MOV InType,InBesked	;Har jeg tilført #(Slet denne kometar)#
		RET

IsCommand:
	CPI Arg1,0x10
	BREQ wasCommand
	CPI Arg1,0x11
	BREQ wasCommand

	//INDSÆT NYE TELEGRAMKOMMANDOER.

	LDI Ret1,0
	RET
	wasCommand:
		LDI R19,1
		MOV InCmd,InBesked	;Har jeg tilført #(Slet denne kometar)#
		RET

Cleanup:
	LDI InType,0
	LDI InCom,0
	LDI InData,0
	RET

CalcOCR2:
	MOV Temp1,InData
	MOV Ret1,Temp1
	ADD Ret1,Temp1
	LSR Temp1
	ADD Ret1,Temp1
	LSR Temp1
	LSR Temp1
	LSR Temp1
	ADD Ret1,Temp1
	LSR Temp1
	SUB Ret1,Temp1
	LSR Temp1
	ADD Ret1,Temp1
	;Hvis den nu bliver sent 100 ender det så også med 255? #(Slet denne kometar)#
	RET