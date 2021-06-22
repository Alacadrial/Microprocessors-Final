LIST P=16F877A
INCLUDE "P16F877A.INC"

;;ADDRESS DEFINITION BLOCK
STATUS EQU h'03'
PORTA EQU h'05'
PORTB EQU h'06'
PORTD EQU h'08'
PORTE EQU h'09'
TRISA EQU h'85'
TRISB EQU h'86'
TRISD EQU h'88'
TRISE EQU h'89'
ADCON1 EQU h'9F'
SPEED_LVL EQU h'20'
DUTY_TIME EQU h'21'
OFF_TIME EQU h'22'
ON_DUTY EQU h'23'
TX EQU h'24'
CHANGE_FLAG EQU h'25'
CNT1 EQU h'26'
CNT2 EQU h'27'
CNT3 EQU h'28'



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
START
CLRF SPEED_LVL			; SPEED_LVL = 0
BSF PORTE, 0 			; Power LED on
CALL DISPLAY_SPEED		; Show Speed lvl

START_BUTTON_LOOP		; If button0 is pressed break out of this loop and motor starts
BTFSS PORTA, 0
GOTO START_BUTTON_LOOP

MOVLW h'01'				; Starting speed is 1
MOVWF SPEED_LVL
CALL DISPLAY_SPEED		; Show Speed lvl
CALL SET_TIMES			; SET DUTY_TIME and OFF_TIME based on the speed level

SPEED_LOOP
BSF ON_DUTY, 0
BTFSC PORTA, 1			; If Button1 or Button2 pressed, adjust speeds
GOTO BUTTON1
BTFSC PORTA, 2
GOTO BUTTON2
BTFSC PORTA, 3			; If Button3 pressed GOTO Start
GOTO START 				; Else Run Motor
GOTO RUN_MOTOR

BUTTON1
CALL INC_SPEED
GOTO CORRECT_VALUES
BUTTON2
CALL DEC_SPEED

CORRECT_VALUES
CALL DISPLAY_SPEED		; Show Speed lvl
CALL SET_TIMES			; SET DUTY_TIME and OFF_TIME based on the speed level
CALL DELAY_250

RUN_MOTOR
BSF PORTD, 0			; RUN MOTOR
CALL PWM_DELAY			; DUTY_TIME DELAY
BCF PORTD, 0			; STOP MOTOR
BCF ON_DUTY, 0
CALL PWM_DELAY			; OFF_TIME DELAY
GOTO SPEED_LOOP

;_________________________________________________________________________________

SET_TIMES
MOVF SPEED_LVL, 0  		; Move Speed level to W register
SUBLW h'01'
BTFSC STATUS, 2			; IF SPEED_LVL == 1 goto TIME1 
GOTO TIME1
MOVF SPEED_LVL, 0
SUBLW h'02'
BTFSC STATUS, 2			; IF SPEED_LVL == 2 goto TIME2 
GOTO TIME2
MOVF SPEED_LVL, 0
SUBLW h'03'
BTFSC STATUS, 2			; IF SPEED_LVL == 3 goto TIME3 
GOTO TIME3				; else SPEED_LVL == 4 ; check is being made in inc and dec speed functions. Move One line below
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
MOVF SPEED_LVL, 0  		; Move Speed level to W register
ADDLW h'01'				; Add +1 to that current speed (W register) ---> W + 1
SUBLW h'04'				; Subtract that speed From 4 ---> 4 - W
BTFSS STATUS, 0			; If W <= 4 Carry flag is set.
RETURN 					; If carry flag is not set Current speed is already equal to 4 so do nothing
INCF SPEED_LVL, 1		; Else increase speed level by one
RETURN


DEC_SPEED
MOVF SPEED_LVL, 0  		; Move Speed level to W register
SUBLW h'01'				; Subtract 1 From Current Speed and Store it in W
BTFSC STATUS, 2			; IF subtract result != 0; Decrease speed by 1
RETURN 					; Else Speed level is already at the minimum so return
DECF SPEED_LVL, 1		
RETURN


;; http://technology.niagarac.on.ca/staff/mboldin/18F_Instruction_Set/MOVF.html
DISPLAY_SPEED
MOVF SPEED_LVL, 0  		; Move Speed level to W register
SUBLW h'00'				
BTFSC STATUS, 2			; IF SPEED_LVL == 0 goto DISPLAY0
GOTO DISPLAY0
MOVF SPEED_LVL, 0
SUBLW h'01'
BTFSC STATUS, 2			; IF SPEED_LVL == 1 goto DISPLAY1 and so on
GOTO DISPLAY1
MOVF SPEED_LVL, 0
SUBLW h'02'
BTFSC STATUS, 2
GOTO DISPLAY2
MOVF SPEED_LVL, 0
SUBLW h'03'
BTFSC STATUS, 2			
GOTO DISPLAY3			; else SPEED_LVL == 4 ; check is being made in inc and dec speed functions. Move One line below
;MOVLW h'33'				; 7 Segment HEX Code for 4 		
MOVLW h'66'				; 7 Segment HEX Code for 4 		
MOVWF PORTB
RETURN
DISPLAY0
;MOVLW h'7E'				; 7 Segment HEX Code for 0			;abcdefg led order
MOVLW h'3F'				; 7 Segment HEX Code for 0				;reverse led order
MOVWF PORTB
RETURN
DISPLAY1
;MOVLW h'30'				; 7 Segment HEX Code for 1
MOVLW h'06'				; 7 Segment HEX Code for 1
MOVWF PORTB
RETURN
DISPLAY2
;MOVLW h'6D'				; 7 Segment HEX Code for 2
MOVLW h'5B'				; 7 Segment HEX Code for 2
MOVWF PORTB
RETURN
DISPLAY3
;MOVLW h'79'				; 7 Segment HEX Code for 3
MOVLW h'4F'				; 7 Segment HEX Code for 3
MOVWF PORTB
RETURN

DELAY_250
MOVLW h'FF'		; h’FF’ >> CNT1
MOVWF CNT1
LOOP1
MOVLW h'FF'		; h’FF’ >> CNT2
MOVWF CNT2
LOOP2
MOVLW h'03'		; h’03’ >> CNT3
MOVWF CNT3
LOOP3
DECFSZ CNT3, F 	; If (CNT3 -1) = 0 jump
GOTO LOOP3
DECFSZ CNT2, F
GOTO LOOP2
DECFSZ CNT1, F
GOTO LOOP1
RETURN

PWM_DELAY			; Delay subprogram
BTFSS ON_DUTY, 0		; If Duty flag is set goto off time part of the sub_program
GOTO OFF_SEC
MOVF DUTY_TIME, 0	; Move DUTY_TIME to W register.
MOVWF TX			; W >> TX
GOTO DELAY_LOOP
OFF_SEC
MOVF OFF_TIME, 0	; Move OFF_TIME to W register.
MOVWF TX			; W >> TX
DELAY_LOOP
DECF TX, 1 			; Dec by 1 each loop till it reaches zero then return 	
BTFSS STATUS, 2
GOTO DELAY_LOOP
RETURN



END 			; End of the instructions





