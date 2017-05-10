;
; SerielcominaktionMedIntrups.asm
;
; Created: 20-03-2017 16:12:36
; Author : simon
;


; Replace with your application code
;.INCLUDE "M32DEF.INC"	
;Opsætning af udskiftning variable
.EQU SET_Type ='S' ;(Skal være 0x55)
.EQU GET_Type ='G' ;(Skal være 0xAA)
.EQU REPLY_Type ='R' ;(Skal være 0xBB)
.EQU Start_Com ='F' ;(Skal være 0x10)
.EQU Stop_Com ='T' ;(Skal være 0x11)
;---
;Opsætning af interrupt	
.CSEG		;Angiver at dette tilhøre program hukommelse 
.ORG 0
RJMP Setop 
.ORG 0x001A	;Dette er "USART, Receive complete" adresse (se Vector Tabel 1 s 365) Den kan også angives med "URXCaddr" 
RJMP DatamodtagetIntaInR17BrugerR18R19
.ORG 50		;50 er bare støre end den sidste adresse i vector tabellen der kunne også bruges 30 da dette ville være lige efter 28+2 
;---
Setop: 
;Opsætning af stack
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16
;---
;Opsætning af kominaktion
	LDI R16, (1<<TXEN)|(1<<RXEN)				;Sætter modtage og sende igang
	OUT UCSRB, R16								;-||-
	LDI R16, (1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;Her indstiller jeg den til at det er 8 bit data, ingen parity bit og kun 1 stop bit 
	OUT UCSRC, R16								;-||-
	LDI R16, 0x67								;Her indstilles baud rate til 9600 (ved 16 MHz)
	OUT UBRRL, R16								;-||-
;---
;Opsætning af registor
LDI R18,0
;---
;Godkender interrupt
SEI
;---
MainProgram:


JMP MainProgram


;Subrutines-------------------------------------------------------
SendR17:			;Subrutienen "SendR17"
	SBIS UCSRA,UDRE									;Tjekker om der stadig er noget der er ved at blive sent ved at se om UDRE er "1" (hvilket den bliver når UDR(Det register som indeholder der der bliver sendt) er tom)
	RJMP SendR17									;Hvis UDRE er "0" hopper den tilbage til starten og der med venter på UDR er tom 
	OUT UDR,R17										;Ligger R17 ind i den tomme UDR. Der med vil R17 blive sendt
	RET
													;Subrutienen er færdig programconteren vil blive sat til den adresse som var efter CALL
SendERROR:
	LDI R17,'E'
	CALL SendR17
	LDI R17,'R'
	CALL SendR17
	LDI R17,'R'
	CALL SendR17
	LDI R17,'O'
	CALL SendR17
	LDI R17,'R'
	CALL SendR17
	RET
;Interrupts-----------------------------------------------------
DatamodtagetIntaInR17BrugerR18R19:
	IN	R17,UDR										;Henter hvad der var kommet ind og ligger det i R17
	;Test
	CALL SendERROR
	RETI
	;---
	CPI	R18,1
	BREQ COMMAND
	CPI R18,2
	BREQ Parameter
	;Hvis den ikke hopper var det så 0 (eller 3) men så går den til type
	;---
	TYPE:
	CPI R17,SET_Type
	BRNE SETHopOver
	LDI R19,1 ;Til senere at vide der var et set
	RJMP UdDatamodtagetIntaR17
	SETHopOver:

	CPI R17,GET_Type
	BRNE GETHopOver
	LDI R19,2 ;Til senere at vide der var et get
	RJMP UdDatamodtagetIntaR17
	GETHopOver:

	CALL SendERROR
	RJMP UdUdenINCR18

	;---
	COMMAND:
	CPI R19,1
	BREQ HvisDetVarSet
	CPI R19,2
	BREQ HvisDetVarGet
	CALL SendERROR
	RJMP UdUdenINCR18

	HvisDetVarSet:
	CPI R17,Start_Com
	BRNE StartOver
	LDI R19,1
	RJMP UdDatamodtagetIntaR17
	StartOver:

	CPI R17,Stop_Com
	BRNE StopOver
	;CALL STOOOOOP ;Denne er ikke lavet endnu men den skal stoppe bilen 
	LDI R17,'S'
	CALL SendR17
	LDI R17,'t'
	CALL SendR17
	LDI R17,'o'
	CALL SendR17
	LDI R17,'p'
	CALL SendR17
	;Sender "Stop"
	RJMP UdDatamodtagetIntaR17
	StopOver:

	CALL SendERROR
	RJMP UdUdenINCR18

	HvisDetVarGet:
	;Da der ikke er lavet nogle Get komandoder sender den bare noget lige nu
	LDI R17,'H'
	CALL SendR17
	LDI R17,'e'
	CALL SendR17
	LDI R17,'j'
	CALL SendR17
	LDI R17,'G'
	CALL SendR17
	;Sender "HejG"
	LDI R18,3 ;Da der ikke er nogel parameter lige nu 
	RJMP UdDatamodtagetIntaR17



	;---
	Parameter:

	CPI R19,1
	BREQ HvisComVarStart
	CALL SendERROR
	LDI R18,0
	RJMP UdUdenINCR18

	HvisComVarStart:
	;CALL SetHastighed Denne er ikke lavet endnu Så sender bare noget istedt
	MOV R19,R17;Gemmer bare lig R17 i R19
	LDI R17,'H'
	CALL SendR17
	LDI R17,'a'
	CALL SendR17
	LDI R17,'s'
	CALL SendR17
	LDI R17,'t'
	CALL SendR17
	LDI R17,' '
	CALL SendR17
	LDI R17,'s'
	CALL SendR17
	LDI R17,'a'
	CALL SendR17
	LDI R17,'t'
	CALL SendR17
	LDI R17,' '
	CALL SendR17
	LDI R17,'t'
	CALL SendR17
	LDI R17,'i'
	CALL SendR17
	LDI R17,'l'
	CALL SendR17
	MOV R17,R19
	CALL SendR17
	RJMP UdDatamodtagetIntaR17

	;---
	UdDatamodtagetIntaR17:
	INC R18				;Tælder op så det næste gang bliver comando eller parameter 
	CPI R18,3			;Hvis den er kommet op på 3 skal den sættes til 0 da der så er endt en hel type->comando->parameter
	BRLO UdUdenINCR18		;Hopper hvis den er laver end 3
	LDI R18,0
	UdUdenINCR18:
	RETI											;Interrupt er færdig og andre interrupt bliver godkendte igen