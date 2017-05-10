.CSEG		    
.ORG 0	

Main:
SBIC UCSRA,RXC
JMP MainEnd
IN InBesked,UDR

TypeCheck:
	CPI InType,0x00
	BRNE CmdCheck
	CALL IsType
	JMP CmdCheck

CmdCheck:
	CPI InCmd,0x00
	BRNE DataCheck
	CALL IsCom
	CPI InType,0xAA
	BREQ Reply
	CPI InCom,0x10
	BREQ MainEnd
	CALL StopCar
	Call Cleanup
	JMP MainEnd

	Reply:
		CPI InCom,0x10
		BRNE Error			//Sætter fejl hvis typen 0x55 ikke er set.
		CALL SendSpeed
		CALL Cleanup
		JMP MainEnd

DataCheck:
	CPI InData,0x00
	BRNE Error
	MOV InData,InBesked
	CPI InType,0x55
	BRNE Error
	CPI InCom,0x10
	BRNE Error
	CALL SetSpeed
	CALL Cleanup
	CALL MainEnd

MainEnd:
JMP Main

//Arg1 = Register der skal testes om det er en type.
isType:
	CPI Arg1,0x55
	BREQ wasType
	CPI Arg1,0xAA
	BREQ wasType
	CPI Arg1,0xBB
	BREQ wasType

	//INDSÆT NYE TELEGRAMTYPER

	LDI Ret1,0
	RET
wasType:
	LDI Ret1,1
	RET


//Arg1 = Register der skal testes om det er en kommando.
isCommand:
	CPI Arg1,0x10
	BREQ wasCommand
	CPI Arg1,0x11
	BREQ wasCommand

	//INDSÆT NYE TELEGRAMKOMMANDOER.

	LDI Ret1,0
	RET
wasCommand:
	LDI R19,1
	RET


StopCar:
	
	RET

CleanUp:
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
	RET