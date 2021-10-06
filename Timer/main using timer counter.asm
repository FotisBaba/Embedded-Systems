;Embedded microproccessor systems lab 1
; LAB1.1.asm
;Fotis Bampaniotis
; Created: 10/4/2020 9:17:28 PM
; 
;Device:ATmega16
;Clock frequency: 10MHz
;timer/counter implementation


rjmp reset                 ;setting reset 
.org $000C                 ;and compare match interupt
jmp TIMER1_COMPA           ;address

reset:
	LDI r16, HIGH(RAMEND)  ; Upper byte
	OUT SPH,r16            ; to stack pointer
	LDI r16, LOW(RAMEND)   ; Lower byte
	OUT SPL,r16            ; to stack pointer

	LDI R17,0xFF           ;setting r17 to FF for DDRA and DDRD
	OUT DDRA,R17           ;setting PORTA as output 
	OUT DDRD,R17           ;setting PORTD as output

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

loop:
	SEI			          ;enable global interupts
	CBI PORTA, 7          ;set output bit to 0 (led)

	LDI r16, 0x00         ;setting ICR1H to 00
	OUT ICR1H,r16         ;setting ICR1L to 28
	LDI r16, 0x28         ;to count 40 time hence ~10000 cycles
	OUT ICR1L,r16         ;based on prescaler 256

	wait:				  ;waiting for 
	rjmp wait             ;interupt




TIMER1_COMPA:	          ;interupt handler when output compare A match is hit
	SBI PORTA,7			  ;flashing led
	reti				  ;return 