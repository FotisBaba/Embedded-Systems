;Embedded microproccessor systems lab 1
; LAB2.asm
;Fotis Bampaniotis
; 
;Device:ATmega16
;Clock frequency: 10MHz
;ring counter implementation


rjmp reset                 ;setting reset 
.org $000C                 ;and compare match interupt
jmp TIMER1_COMPA           ;address
sevseg_vals:			   ;table with desired values for each 7 segment display digits
.db 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90

reset:
	LDI r16, HIGH(RAMEND)  ; Upper byte
	OUT SPH,r16            ; to stack pointer
	LDI r16, LOW(RAMEND)   ; Lower byte
	OUT SPL,r16            ; to stack pointer

	LDI R17,0xFF           ;setting r17 to FF for DDRA and DDRC
	OUT DDRA,R17           ;setting PORTA as output 
	OUT DDRC,R17           ;setting PORTC as output

	LDI r16, 0x10           ;need to set 4th bit of TIMSK 
	OUT TIMSK, r16         ;enable output compare A match interupt enable

	LDI r16, 0x10          ;setting COM1A1 and COM1A0 to 1
	OUT TCCR1A,r16         ;so the interupt flag is active high
	
	LDI r16, 0x1C          ;setting WGM13 and WGM12 to 1 / also setting CS12 CS11 CS10 to
	OUT TCCR1B,r16         ;so TCNT1 is compared to ICR1 / 100 for 256 prescaler 

	LDI r16, 0x00         ;setting TCNT1H and TCNT1L to all zeroes
	OUT TCNT1H,r16        ;counter will start from 0
	LDI r16, 0x00         ;and increment every timer/counter cycle
	OUT TCNT1L,r16        ;timer/counter frequency is proccessor_frequency/2x256x2

	;;lab2

	LDI R23, 1            ;set active digit value
	STS $0071, R23	      ;and save it to SRAM
	
	LDI ZL, low(2*sevseg_vals)         ;setting pointer Z
	LDI ZH, high(2*sevseg_vals)        ;to start of table with digit values

	LDI R23, 0xC0                      ;seven segment value for 0
	ADIW Z,1                           ;increment pointer to point to decimal 1 for output

	LDI R18, 7                         ;declare target goal 
	LDI R21, 0x01                      ;initialize register for ring counter active digit
	STS $0070, R21                     ;saving ring counter active digit to SRAM

	LDI r16, 0x00                      ;setting ICR1H to 00
	OUT ICR1H,r16                      ;setting ICR1L to 28
	LDI r16, 0x28                      ;to count 40 time hence ~10000 cycles
	OUT ICR1L,r16                      ;based on prescaler 256

	

intret:
	SEI			         ;enable global interupts	
	LDS R21, 0x70        ;load active digit
	LPM R24, Z           ;set R24 as output register for pointer value
	

loopreset:

	LDI R19, 0           ;initialize counter
	LDI R20, 0x01        ;initialize loop tmp ring counter

loop:

	CP R20, R21          ;compare active digit and loop tmp ring counter
	BRNE zero            ;if not a match display a zero

nonzero:
	OUT PORTA, R17       ;clear output content
	OUT PORTC, R20       ;set output active at current ring digit
	OUT PORTA, R24	     ;output pointer nonzero value to 7 segment
	LSL R20              ;left shift tmp ring counter

	CPI R20, 0x00        ;compare tmp ring counter with 0
	BRNE next1           ;if tmp ring counter is zero 
	LDI R20, 0x01        ;reinitialize loop tmp ring counter
next1:
	INC R19              ;increment tmp counter
	CP R19, R18          ;compare tmp counter with 7
	BREQ loopreset       ;and reset loop if compare is equal



zero:
	OUT PORTA, R17       ;clear output content
	OUT PORTC, R20       ;set output active at current ring digit
	OUT PORTA, R23       ;output zero to 7 segment
	LSL R20              ;left shift tmp ring counter

	CPI R20, 0x00        ;compare tmp ring counter with 0
	BRNE next2           ;if tmp ring counter is zero 
	LDI R20, 0x01        ;reinitialize loop tmp ring counter
next2:
	INC R19              ;increment tmp counter
	CP R19, R18          ;compare tmp counter with 7
	BREQ loopreset       ;and reset loop if compare is equal

	RJMP loop            ;restart loop

	

TIMER1_COMPA:	          ;interupt handler when 1ms has passed
	
	LDS R25, 0x70        ;load active digit
	LSL R25              ;left shift ring counter active digit
	CPI R25, 0x00        ;if left shift produces zero
	BRNE intnxt1         ;reinitialize to  
	ADIW Z,1             ;increment pointer so it points to the next desires value 
	LDI R25,0x01         ;0x01

	LDS R25, 0x71                      ;load ring counter decimal value from SRAM
	INC R25                            ;increment decimal value
	CPI R25, 10                        ;and compare it to 10
	BRNE intnxt2                       ;if it is equal to 10
	LDI ZL, low(2*sevseg_vals)         ;set pointer Z to start of table
	LDI ZH, high(2*sevseg_vals)        ;and increment so it points to
	ADIW Z,1                           ;second element of table
	LPM R24, Z                         ;output pointer value to R24
	LDI R25, 1                         ;reinitialize ring counter decimal value

intnxt2:
	STS $0071, R25       ;save ring counter active digit to SRAM

intnxt1:                 ;else
	STS $0070, R25       ;save ring counter active digit to SRAM

	


	RJMP intret		     ;return      ;return(jump) to start of main loop