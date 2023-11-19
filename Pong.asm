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
	
	WINDOW_WIDTH DW 140H		;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 0C8h		;the height of the window (200 pixels)
	WINDOW_BOUNDS DW 6			;variable used to check collisions early
	
	TIME_AUX DB 0  ;variable used when checking if the time has changed
	
	BALL_ORIGINAL_X DW 0A0h
	BALL_ORIGINAL_Y DW 64h
	
	; DW, 16 bits of information because we using 16 bits registers (CX, DX)
	BALL_X DW 0A0h  ; X position (column) of the ball
	BALL_Y DW 64h  ; Y position (line) of the ball
	BALL_SIZE DW 04h ;size of the ball (how many pixels does the ball have in width and height)
	BALL_VELOCITY_X DW 05h ;X VELOCITY of the ball
	BALL_VELOCITY_Y DW 02h ;Y VELOCITY of the ball

	PADDLE_LEFT_X DW 0Ah
	PADDLE_LEFT_Y DW 0Ah
	
	PADDLE_RIGHT_X DW 130h
	PADDLE_RIGHT_Y DW 0Ah
	
	PADDLE_WIDTH DW 05h
	PADDLE_HEIGHT DW 1Fh
	
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
	
		CALL CLEAR_SCREEN
		
		CHECK_TIME:
			
			MOV AH, 2Ch ;get the system time
			INT 21h		;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL, TIME_AUX	;is the current time equal to the previous one (TIME_AUX)?
			JE CHECK_TIME	;if it is the same, check again		
			
			;if it is different, then draw, move, etc.
			MOV TIME_AUX, DL ;update time
			
			
			CALL CLEAR_SCREEN
			
			CALL MOVE_BALL
			
			CALL DRAW_BALL
			
			CALL DRAW_PADDLES

			
			JMP CHECK_TIME ;after everyhing checks time again
		
		RET
		
	MAIN ENDP
	
	MOVE_BALL PROC NEAR
		MOV AX, BALL_VELOCITY_X		
		ADD BALL_X, AX				;move the ball horizontally 
				
		MOV AX,WINDOW_BOUNDS
		CMP BALL_X,AX			
		JL RESET_POSITION			;BALL_X < 0 + WINDOW_BOUNDS(Y -> collided)
		
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX 				;BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS(Y -> collided)
		JG RESET_POSITION
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		MOV AX, BALL_VELOCITY_Y		;move the ball vertically
		ADD BALL_Y,AX
							
		MOV AX, WINDOW_BOUNDS
		CMP BALL_Y,AX			
		JL NEG_VELOCITY_Y			;BALL_Y < 0 + WINDOW_BOUNDS(Y -> collided)
						
		MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX
		JG NEG_VELOCITY_Y			;BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS (Y -> collided)		
		
		RET
									
		RESET_POSITION:
			CALL RESET_BALL_POSITION
			RET
		
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y 	;BALL_VELOCITY_Y = - BALL_VELOCITY_Y
			RET
		
	MOVE_BALL ENDP
	
	RESET_BALL_POSITION PROC NEAR
		
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
		
		RET
	RESET_BALL_POSITION ENDP
	
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
	
	DRAW_PADDLES PROC NEAR
		MOV CX, PADDLE_LEFT_X	;set the initial column (X)
		MOV DX, PADDLE_LEFT_Y	;set the inital line (y)
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0Ch ;set the configuration to writing a pixel
			MOV AL,0Fh ; choose white as color
			MOV BH,00h ; set the page number
			INT 10h	   ; execute the configuration
			
			INC CX	   ;CX = CX + 1
			MOV AX, CX		   ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line, N -> We continue to the next column)
			SUB AX, PADDLE_LEFT_X
			CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			MOV CX, PADDLE_LEFT_X ;the CX register goes back to the initial clumn
			INC DX		   ;we advance one line
			
			MOV AX, DX		;DX - BALL_Y > PADDLE_LEFT_Y (Y -> we exit this Procedure, N -> we countinute to the next line)
			SUB AX, PADDLE_LEFT_Y
			CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			
		
		MOV CX, PADDLE_RIGHT_X	;set the initial column (X)
		MOV DX, PADDLE_RIGHT_Y	;set the inital line (y)
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
			MOV AH,0Ch ;set the configuration to writing a pixel
			MOV AL,0Fh ; choose white as color
			MOV BH,00h ; set the page number
			INT 10h	   ; execute the configuration
			
			INC CX	   ;CX = CX + 1
			MOV AX, CX		   ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line, N -> We continue to the next column)
			SUB AX, PADDLE_RIGHT_X
			CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			MOV CX, PADDLE_RIGHT_X ;the CX register goes back to the initial clumn
			INC DX		   ;we advance one line
			
			MOV AX, DX		;DX - BALL_Y > PADDLE_RIGHT we exit this Procedure, N -> we countinute to the next line)
			SUB AX, PADDLE_RIGHT_Y
			CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
		RET
	DRAW_PADDLES ENDP
	
	
	CLEAR_SCREEN PROC NEAR
			MOV AH,00h ;set the configuration to video mode
			MOV AL,13h ;choose the video mode
			INT 10h	   ;execute the configuration
			
			MOV AH,0Bh ;set the configuration		
			MOV BH,00h ;to the background color
			MOV BL,00h ;choose black as background color
			INT 10h	   ;execute the configuration
			RET
	CLEAR_SCREEN ENDP
	
CODE ENDS
END