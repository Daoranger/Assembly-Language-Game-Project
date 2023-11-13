;HOW TO RUN THE ASM CODE:
;1. MASM /A PONG.ASM
;2. ;
;3. LINK PONG
;4. ;
;5. PONG
STACK SEGMENT PARA STACK
	DB 64 DUP (' ') 
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	; DW, 16 bits of information because we using 16 bits registers (CX, DX)
	BALL_X DW 0Ah  ; X position (column) of the ball
	BALL_Y DW 0AH  ; Y position (line) of the ball
	BALL_SIZE DW 04h ;size of the ball (how many pixels does the ball have in width and height)
	
	
DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK ;assume as code, data, and stack segments the respective registers
	PUSH DS							;push to the stack the DS segment
	SUB AX,AX						;clean the AX registers
	PUSH AX							;push AX to the STACK
	MOV AX,DATA 					; save on the AX register the contents of the DATA SEGMENT
	MOV DS,AX						;save on the DS segment the contents of AX
	POP AX							;release the top item from the stack to the AX register
	POP AX							;release the top item from the stack to the AX register
	
		MOV AH,00h ;set the configuration to video mode
		MOV AL,13h ;choose the video mode
		INT 10h	   ;execute the configuration
		
		MOV AH,0Bh ;set the configuration		
		MOV BH,00h ;to the background color
		MOV BL,00h ;choose black as background color
		INT 10h	   ;execute the configuration
		
		CALL DRAW_BALL
		
		RET
		
	MAIN ENDP
	
	;DRAW_BALL Procedure
	;this part of the code draw the ball
	DRAW_BALL PROC NEAR
		MOV CX,BALL_X ;set the initial column (X)
		MOV DX,BALL_Y ;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch ;set the configuration to writing a pixel
			MOV AL,0Fh ; choose white as color
			MOV BH,00h ; set the page number
			INT 10h	   ; execute the configuration
			
			INC CX	   ;CX = CX + 1
			MOV AX, CX		   ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line, N -> We continue to the next column)
			SUB AX, BALL_X
			CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX, BALL_X ;the CX register goes back to the initial clumn
			INC DX		   ;we advance one line
			
			MOV AX, DX		;DX - BALL_Y > BALL_SIZE (Y -> we exit this Procedure, N -> we countinute to the next line)
			SUB AX, BALL_Y
			CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		RET	
	DRAW_BALL ENDP
CODE ENDS
END