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
										
	WINDOW_WIDTH DW 140H				;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 0C8h				;the height of the window (200 pixels)
	WINDOW_BOUNDS DW 6					;variable used to check collisions early
	
	TIME_AUX DB 0  						;variable used when checking if the time has changed
	
										;DWORD, 16 bits of information because we using 16 bits registers (CX, DX)
	BALL_ORIGINAL_X DW 0A0h				;x position where the ball spawn beginning of game
	BALL_ORIGINAL_Y DW 64h				;y position where the ball spawn beginning of game
	BALL_X DW 0A0h  					;X position (column) of the ball
	BALL_Y DW 64h  						;Y position (line) of the ball
	BALL_SIZE DW 04h 					;size of the ball (how many pixels does the ball have in width and height)
	BALL_VELOCITY_X DW 05h 				;X VELOCITY of the ball
	BALL_VELOCITY_Y DW 02h 				;Y VELOCITY of the ball

	PADDLE_LEFT_X DW 0Ah				;X position of the left paddle
	PADDLE_LEFT_Y DW 0Ah				;Y position of the left paddle
	PADDLE_LEFT_POINTS DB 0				;current points of the left player (P1)
	
	PADDLE_RIGHT_X DW 130h				;X position of the right paddle
	PADDLE_RIGHT_Y DW 0Ah				;Y position of the right paddle
	PADDLE_RIGHT_POINTS DB 0			;current points of the right player (P2)
	
	PADDLE_WIDTH DW 05h					;default paddle width
	PADDLE_HEIGHT DW 1Fh				;default paddle height
	PADDLE_VELOCITY DW 10h				;default paddle velocity (how fast we move the paddles)
	
DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK 	;assume as code, data, and stack segments the respective registers
	PUSH DS								;push to the stack the DS segment
	SUB AX,AX							;clean the AX registers
	PUSH AX								;push AX to the STACK
	MOV AX,DATA 						; save on the AX register the contents of the DATA SEGMENT
	MOV DS,AX							;save on the DS segment the contents of AX
	POP AX								;release the top item from the stack to the AX register
	POP AX								;release the top item from the stack to the AX register
	
		CALL CLEAR_SCREEN				;set the initial video mode configurations
		
		CHECK_TIME:
			
			MOV AH, 2Ch 				;get the system time
			INT 21h						;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL, TIME_AUX			;is the current time equal to the previous one (TIME_AUX)?
			JE CHECK_TIME				;if it is the same, check again		
			
;			If it reaches this point, it is because the time has passed
			MOV TIME_AUX, DL 			;if not update time
			
			CALL CLEAR_SCREEN			;clear the screen by restarting video mode
			
			CALL MOVE_BALL				;move the ball
			CALL DRAW_BALL				;draw the ball
				
			CALL MOVE_PADDLES			;move paddles
			CALL DRAW_PADDLES			;draw paddles

			
			JMP CHECK_TIME ;after everyhing checks time again
		
		RET
		
	MAIN ENDP
	
	MOVE_BALL PROC NEAR					;process the movement of the ball
		MOV AX, BALL_VELOCITY_X		
		ADD BALL_X, AX					;move the ball horizontally 

;		Move the ball horizontally
		MOV AX,WINDOW_BOUNDS			;Border bounds
		CMP BALL_X,AX					;Move it to the ball position
		JL GIVE_POINT_TO_PLAYER_TWO		;if is less. give one point to the player two and reset ball position
		
;		Check if the ball has passed the right boundarie  (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
;		If is colliding, restart its position
		MOV AX,WINDOW_WIDTH				
		SUB AX,BALL_SIZE	
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX 					;Ball is compared with the right boudarie of the screen (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS(Y -> collided)
		JG GIVE_POINT_TO_PLAYER_ONE		;If it is greater, give one point to the player one and reset ball position
		JMP MOVE_BALL_VERTICALLY
		
		GIVE_POINT_TO_PLAYER_ONE:		;give one point to the player on and reset ball position
			INC PADDLE_LEFT_POINTS		;increment player one points
			CALL RESET_BALL_POSITION	;reset the ball position to the center of the screen
			
			CMP PADDLE_LEFT_POINTS, 05h
			JGE GAME_OVER
			RET	
			
		GIVE_POINT_TO_PLAYER_TWO:
			INC PADDLE_RIGHT_POINTS
			CALL RESET_BALL_POSITION	;reset the ball position to the center of the screen
			
			CMP PADDLE_RIGHT_POINTS, 05h
			JGE GAME_OVER
			RET	
		
		GAME_OVER:							;someone has reached 5 points
			MOV PADDLE_LEFT_POINTS, 00h		;restart player one points
			MOV PADDLE_RIGHT_POINTS, 00h	;restart player two points
			RET
		;RESET_POSITION:
			;CALL RESET_BALL_POSITION	;reset the ball position to the center of the screen
			;RET	

;		Move the ball vertically
		MOVE_BALL_VERTICALLY:
			MOV AX, BALL_VELOCITY_Y
			ADD BALL_Y, AX
;		Move the ball vertically
		MOV AX, BALL_VELOCITY_Y			;move the ball vertically
		ADD BALL_Y,AX

;		Check if the ball has appsed the top boundarie (BALL_Y < 0 + WINDOW_BOUNDS)
;		If is colliding, reverse the velocity in Y
		MOV AX, WINDOW_BOUNDS
		CMP BALL_Y,AX					;BALL_Y is compared with the top boundarie of the screen 0 + WINDOW_BOUNDS
		JL NEG_VELOCITY_Y				;if is greater reverse the velocity in Y
			
										
;		Check if the ball has appsed the bottom boundarie (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
;		If is colliding, reverse the velocity in Y
		MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX					;BALL_Y is compared with the bottom boundarie of the scnreen BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS (Y -> collided)	
		JG NEG_VELOCITY_Y				;if it is greater reverse the velocity in Y	
		
;		Check if the ball is colliding with the right paddle
;				maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
;				BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH 
;    			&& BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE	; if there's no collision check for the left paddle collisions
		
		MOV AX, PADDLE_RIGHT_X
		ADD AX, PADDLE_WIDTH
		CMP BALL_X, AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE	;if there's no collision check for the left paddle collisions
		
		MOV AX, BALL_Y
		ADD AX, BALL_SIZE
		CMP AX, PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE	;if there's no collision check for the left paddle collisions
		
		MOV AX, PADDLE_RIGHT_Y
		ADD AX, PADDLE_HEIGHT
		CMP BALL_Y, AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE	;if there's no collision check for the left paddle collisions
		
;		If it reaches this point, the ball is colliding with the right paddle
		
		JMP	NEG_VELOCITY_X						;reverse the horizontal velocity of the ball
												;exit this procedure (because there's no collision witht he left paddle)
		
;		Check if the ball is colliding with the left paddle
		CHECK_COLLISION_WITH_LEFT_PADDLE:
		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_LEFT_X
		JNG EXIT_COLLISION_CHECK	;if there's no collision check exit procedure
		
		MOV AX, PADDLE_LEFT_X
		ADD AX, PADDLE_WIDTH
		CMP BALL_X, AX
		JNL EXIT_COLLISION_CHECK	;if there's no collision check exit procedure
		
		MOV AX, BALL_Y
		ADD AX, BALL_SIZE
		CMP AX, PADDLE_LEFT_Y
		JNG EXIT_COLLISION_CHECK	;if there's no collision check exit procedure
		
		MOV AX, PADDLE_LEFT_Y
		ADD AX, PADDLE_HEIGHT
		CMP BALL_Y, AX
		JNL EXIT_COLLISION_CHECK	;if there's no collision check exit procedure
		
		JMP NEG_VELOCITY_X
				
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y 		;reverse tje ve;pcoty om Y of the ball (BALL_VELOCITY_Y = - BALL_VELOCITY_Y)
			RET
		NEG_VELOCITY_X:
			NEG BALL_VELOCITY_X
			RET
		EXIT_COLLISION_CHECK:
			RET
	MOVE_BALL ENDP

;	left paddle movement
	MOVE_PADDLES PROC NEAR

;		check if any key is being pressed (if not exit procedure)
		MOV AH, 01h
		INT 16h ;set keyboard stroke
		JZ CHECK_RIGHT_PADDLE_MOVEMENT	;ZF = 1, a key is not pressed, JZ-> jump if zero
		
		;check which key is being pressed (AL = ASCII character)
		MOV AH, 00h
		INT 16h
		
		;if it is 'w' or 'W' move up
		CMP AL, 77h ; 'w'
		JE MOVE_LEFT_PADDLE_UP
		CMP AL, 57h ; 'W'
		JE MOVE_LEFT_PADDLE_UP
		
		;if it is 's' or 'S' move up
		CMP AL, 73h ; 's'
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL, 53h ; 'S'
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX, PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX 		;sub = up
			
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_LEFT_Y, AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX, PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX 		;add = down
			MOV AX, WINDOW_HEIGHT
			SUB AX, WINDOW_BOUNDS
			SUB AX, PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y, AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y, AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		;right paddle movement
		CHECK_RIGHT_PADDLE_MOVEMENT:
			;if it is 'p' or 'P' move up
			CMP AL,70h ;'p'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL, 50h ; 'P'
			JE MOVE_RIGHT_PADDLE_UP
			
			;if it is 'l' or 'L' move up
			CMP AL, 6Ch ; 'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL, 4Ch ; 'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_UP:
				MOV AX, PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX 	;sub = up
			
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y, AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX, PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX 	;add = down
				MOV AX, WINDOW_HEIGHT
				SUB AX, WINDOW_BOUNDS
				SUB AX, PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y, AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_RIGHT_Y, AX
					JMP EXIT_PADDLE_MOVEMENT
		
		EXIT_PADDLE_MOVEMENT:
			RET
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR
		
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
		
		RET
	RESET_BALL_POSITION ENDP
	
;	DRAW_BALL Procedure
;	this part of the code draw the ball
	DRAW_BALL PROC NEAR
		MOV CX,BALL_X 					;set the initial column (X)
		MOV DX,BALL_Y 					;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch 					;set the configuration to writing a pixel
			MOV AL,0Fh 					;choose white as color
			MOV BH,00h 					;set the page number
			INT 10h	   					;execute the configuration
			
			INC CX	   					;CX = CX + 1
			MOV AX, CX		   			;CX - BALL_X > BALL_SIZE (Y -> We go to the next line, N -> We continue to the next column)
			SUB AX, BALL_X
			CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX, BALL_X 				;the CX register goes back to the initial clumn
			INC DX		   				;we advance one line
			
			MOV AX, DX					;DX - BALL_Y > BALL_SIZE (Y -> we exit this Procedure, N -> we countinute to the next line)
			SUB AX, BALL_Y
			CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		RET	
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR
		MOV CX, PADDLE_LEFT_X				;set the initial column (X)
		MOV DX, PADDLE_LEFT_Y				;set the inital line (y)
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0Ch 						;set the configuration to writing a pixel
			MOV AL,0Fh 						;choose white as color
			MOV BH,00h 						;set the page number
			INT 10h	   						;execute the configuration
			
			INC CX	   						;CX = CX + 1
			MOV AX, CX		   				;CX - BALL_X > BALL_SIZE (Y -> We go to the next line, N -> We continue to the next column)
			SUB AX, PADDLE_LEFT_X
			CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			MOV CX, PADDLE_LEFT_X 			;the CX register goes back to the initial clumn
			INC DX		   					;we advance one line
			
			MOV AX, DX						;DX - BALL_Y > PADDLE_LEFT_Y (Y -> we exit this Procedure, N -> we countinute to the next line)
			SUB AX, PADDLE_LEFT_Y
			CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			
		
		MOV CX, PADDLE_RIGHT_X				;set the initial column (X)
		MOV DX, PADDLE_RIGHT_Y				;set the inital line (y)
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
			MOV AH,0Ch 						;set the configuration to writing a pixel
			MOV AL,0Fh 						;choose white as color
			MOV BH,00h 						;set the page number
			INT 10h	   						;execute the configuration
			
			INC CX	   						;CX = CX + 1
			MOV AX, CX		   				;CX - BALL_X > BALL_SIZE (Y -> We go to the next line, N -> We continue to the next column)
			SUB AX, PADDLE_RIGHT_X
			CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			MOV CX, PADDLE_RIGHT_X 			;the CX register goes back to the initial clumn
			INC DX		   					;we advance one line
			
			MOV AX, DX						;DX - BALL_Y > PADDLE_RIGHT we exit this Procedure, N -> we countinute to the next line)
			SUB AX, PADDLE_RIGHT_Y
			CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
		RET
	DRAW_PADDLES ENDP
	
	
	CLEAR_SCREEN PROC NEAR
			MOV AH,00h 						;set the configuration to video mode
			MOV AL,13h 						;choose the video mode
			INT 10h	   						;execute the configuration
			
			MOV AH,0Bh 						;set the configuration		
			MOV BH,00h 						;to the background color
			MOV BL,00h 						;choose black as background color
			INT 10h	   						;execute the configuration
			RET
	CLEAR_SCREEN ENDP
	
CODE ENDS
END