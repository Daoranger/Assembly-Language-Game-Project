STACK SEGMENT PARA STACK
	DB 64 DUP (' ') 
STACK ENDS

DATA SEGMENT PARA 'DATA'

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
		
		MOV AH,00h
		MOV AL,13h
		INT 10h
		
		MOV AH, 0Bh
		MOV BH, 11h
		MOV BL, 01h
		INT 10h
		
		MOV AH,0Ch
		MOV AL,0Fh
		MOV BH,00h
		MOV CX,0Ah
		MOV DX,0Ah
		INT 10h
		
		RET
		
	MAIN ENDP

CODE ENDS
END