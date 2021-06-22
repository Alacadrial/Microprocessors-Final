LIST P=16F877A
INCLUDE "P16F877A.INC"

;;ADDRESS DEFINITION BLOCK
SPEED_LVL EQU h'20'
DUTY_TIME EQU h'21'
OFF_TIME EQU h'22'
PWMCNT EQU h'23'
CNT1 EQU h'24'
CNT2 EQU h'25'
CNT3 EQU h'26'


;;CONFIG
CLRF PORTB ; 
CLRF PORTD ; Making sure all outputs are DC 0 at the start.		
CLRF PORTE ;
BSF STATUS, 5 	; Go to BANK 1
CLRF TRISB		
CLRF TRISD 		; Configure PORT B-D-E as output
CLRF TRISE		
MOVLW h'FF'		
MOVWF TRISA		; Configure PORTA as input
MOVLW h'06'		; 0000 011X to disable ADC on all ports
MOVWF ADCON1 	; Disable ADC
BCF STATUS, 5 	; Go to BANK 0

;_________________________________MAIN_______________________________________________
START_PR
CLRF SPEED_LVL			; SPEED_LVL = 0
BSF PORTE, 0 			; Power LED on
CALL SEG7TABLE			; Call the function and Return with W register (W register now contains hex value for 7SEG Display).
MOVWF PORTB				; Displays Speed on 7SEG Display

START_BUTTON_LOOP		; If button0 is pressed break out of this loop and motor starts
BTFSS PORTA, 0
GOTO START_BUTTON_LOOP

MOVLW h'01'				; Starting speed is 1
MOVWF SPEED_LVL
CALL SEG7TABLE			; Call the function and Return with W register (W register now contains hex value for 7SEG Display).
MOVWF PORTB				; Displays Speed on 7SEG Display
CALL SET_TIMES			; SET DUTY_TIME and OFF_TIME based on the speed level

SPEED_LOOP
BTFSC PORTA, 1			; If Button1 is pressed goto BUTTON1
GOTO BUTTON1
BTFSC PORTA, 2			; If Button2 is pressed goto BUTTON2
GOTO BUTTON2
BTFSC PORTA, 3			; If Button3 is pressed GOTO Start
GOTO START_PR 			; Else Nothing changed Run Motor with the current settings.
GOTO RUN_MOTOR

;------------------------------------------------------------------------------------------
;This section runs only once after every change for efficiency.
BUTTON1
CALL INC_SPEED
GOTO CORRECT_VALUES;		----------------------------------------
BUTTON2; 															|
CALL DEC_SPEED; 													|	
CORRECT_VALUES;													<---								
CALL SEG7TABLE			; Call the function and Return with W register (W register now contains hex value for 7SEG Display).
MOVWF PORTB				; Displays Speed on 7SEG Display
CALL SET_TIMES			; SET DUTY_TIME and OFF_TIME based on the speed level
CALL DELAY_GEN			; Go through a delay so that we don't give multiple inputs in one press.
;-------------------------------------------------------------------------------------------

RUN_MOTOR
BSF PORTD, 0			; RUN MOTOR
MOVF DUTY_TIME, W
CALL PWM_DELAY			; DUTY_TIME DELAY
BCF PORTD, 0			; STOP MOTOR
MOVF OFF_TIME, W
CALL PWM_DELAY			; OFF_TIME DELAY
GOTO SPEED_LOOP
;_________________________________________________________________________________

SET_TIMES
MOVF SPEED_LVL, W  		; Move Speed level to W register
SUBLW h'01'
BTFSC STATUS, 2			; IF SPEED_LVL == 1 goto TIME1 
GOTO TIME1
MOVF SPEED_LVL, W
SUBLW h'02'
BTFSC STATUS, 2			; IF SPEED_LVL == 2 goto TIME2 
GOTO TIME2
MOVF SPEED_LVL, W
SUBLW h'03'
BTFSC STATUS, 2			; IF SPEED_LVL == 3 goto TIME3 
GOTO TIME3				; else SPEED_LVL == 4 ; Error check is being made in inc and dec speed functions. Move One line below
MOVLW h'FF'				; %100 DUTY_TIME %0 OFF_TIME
MOVWF DUTY_TIME
MOVLW h'01'
MOVWF OFF_TIME
RETURN
TIME1					; %25 DUTY_TIME %75 OFF_TIME
MOVLW h'3F'				
MOVWF DUTY_TIME
MOVLW h'C0'
MOVWF OFF_TIME
RETURN
TIME2					; %50 DUTY_TIME %50 OFF_TIME
MOVLW h'7F'
MOVWF DUTY_TIME
MOVLW h'7F'
MOVWF OFF_TIME
RETURN
TIME3					; %75 DUTY_TIME %25 OFF_TIME
MOVLW h'C0'
MOVWF DUTY_TIME
MOVLW h'3F'
MOVWF OFF_TIME
RETURN


INC_SPEED
MOVF SPEED_LVL, W  		; Move Speed level to W register
ADDLW h'01'				; Add +1 to that current speed (W register) ---> W + 1
SUBLW h'04'				; Subtract that speed From 4 ---> 4 - W 
BTFSS STATUS, W			; If W <= 4 Carry flag is set.
RETURN 					; If carry flag is not set Current speed is already equal to 4 so do nothing
INCF SPEED_LVL, F		; Else increase speed level by one
RETURN


DEC_SPEED
DECFSZ SPEED_LVL, F 	; Decrease speed level by just one, and skip if it's already the lowest value. If lvl==1 skip  --|
RETURN 																													 |
INCF SPEED_LVL, F		; If SPEED_LVL was 1 increase it by one to keep it that way. (Nothing changes.)				   <-
RETURN


DELAY_GEN		; Generic Delay Function to ensure accurate button press.
MOVLW h'FF'		; h’FF’ >> CNT1
MOVWF CNT1
LOOP1
MOVLW h'0F'		; h’FF’ >> CNT2
MOVWF CNT2
LOOP2
MOVLW h'05'		; h’03’ >> CNT3
MOVWF CNT3
LOOP3
DECFSZ CNT3, F 	; If (CNT3 -1) = 0 jump
GOTO LOOP3
DECFSZ CNT2, F
GOTO LOOP2
DECFSZ CNT1, F
GOTO LOOP1
RETURN

PWM_DELAY		; Function used to delay the system for PWM, W register holds DUTY_TIME and OFF_TIME depending on where it is called.
MOVWF PWMCNT	; We assign W to a Temporary register so that we don't lose original DUTY_TIME or OFF_TIME
PWM_LOOP		; Then we do the regular loop.
DECFSZ PWMCNT, F
GOTO PWM_LOOP
RETURN			; We break out and return.

SEG7TABLE		
MOVF SPEED_LVL, W  		; Move Speed level to W register
ADDWF PCL, F 			; We ADD that value to the program counter and gives us the constant hex values for our 7SEG display.
RETLW h'3F'
RETLW h'06'
RETLW h'5B'
RETLW h'4F'
RETLW h'66'


END 			; End of the instructions





