STACK SEGMENT PARA STACK
	DB 64 DUP (' ') 
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	; DW, 16 bits of information because we using 16 bits registers (CX, DX)
	BALL_X DW 0Ah  ; X position (column) of the ball
	BALL_Y DW 0AH  ; Y position (line) of the ball
DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
		
		MOV AH,00h ;set the configuration to video mode
		MOV AL,13h ;choose the video mode
		INT 10h	   ;execute
		
		MOV AH, 0Bh
		MOV BH, 11h
		MOV BL, 01h
		INT 10h
		
		MOV AH,0Ch
		MOV AL,0Fh
		MOV BH,00h
		MOV CX,BALL_X
		MOV DX,BALL_Y
		INT 10h
		
		RET
		
	MAIN ENDP

CODE ENDS
END