
 #define _SFR_ASM_COMPAT 1 
 #define __SFR_OFFSET 0          // Use 0 for the I/O register offset
 #include <avr/io.h>
 #include <avr/interrupt.h>
 

 .global TIMER1_COMPA
TIMER1_COMPA:	            ;interupt handler when 1ms has passed
	PUSH R31
	PUSH R30
	PUSH R29
	PUSH R28
	PUSH R27
	PUSH R26

	LDI ZL, lo8(0x0068)     ;setting pointer Y
	LDI ZH, hi8(0x0068)     ;to 7 segment value for digit 0
	LDI XL, lo8(0x0060)     ;setting pointer X
	LDI XH, hi8(0x0060)     ;to least significant bit received
	LDI R20,0x01		    ;temp counter for digit to be displayed
	LDI R18,128			    ;when 8th bit is displayed we need to reset

loop:
	LD R19, X			    ;load offset from memory to add to Y
	ADD YL,R19			    ;add offset to Y to get correct 7 segment value to be displayed
	LD R19, Y			    ;load 7 segment value to R19
	LDI R21, 0xFF   
	OUT PORTA, R21          ;clear output content
	OUT PORTC, R20          ;set output active at current ring digit
	OUT PORTA, R19	        ;output pointer nonzero value to 7 segment
	ADIW X,1                ;increment pointer so it points to the next desired value 
	LDI ZL, lo8(0x0068)     ;setting pointer Y
	LDI ZH, hi8(0x0068)     ;to 7 segment value for digit 0
	LSL R20                 ;left shift tmp ring counter
	CPI R20, 0x00		    ;if temp counter did full cycle, reset
	BRNE next1              ;if tmp ring counter is zero 
	LDI XL, lo8(0x0060)      ;setting pointer X
	LDI XH, hi8(0x0060)     ;to least significant bit received
	LDI R20, 0x01           ;reinitialize loop tmp ring counter
	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31
	RETI
next1:
	RJMP loop


;interupt handler for receive complete
 .global USART_RXC

USART_RXC:
	PUSH R31
	PUSH R30
	PUSH R29
	PUSH R28
	PUSH R27
	PUSH R26

	
	LDI XL, lo8(0x0060)     ;setting pointer X
	LDI XH, hi8(0x0060)     ;to least significant bit received
	LDI ZL, lo8(0x0073)     ;setting pointer Z
	LDI ZH, hi8(0x0073)     ;to next bit to be received

	LD R20, Z 				;load offset to R20


	IN R19, UDR		        ;read received byte
	IN R19, UDR		        ;read received byte--for simulation
        
	MOV R19, R25            ;copy data--for simulation

	CPI R19, 0x41           ;if byte is char A
	BREQ chara

	CPI R19, 0x43           ;if byte is char C
	BREQ charc

	CPI R19, 0x4E           ;if byte is char N
	BREQ charn

	CPI R19, 0x0D           ;if byte is char <CR>
	BREQ charcr

	CPI R19, 0x54           ;if byte is char T
	BREQ chart

	CPI R19, 0x0A           ;if byte is char <LF>
	BREQ charlf

	ANDI R19, 0x0F          ;keep only 4 least significant bits so offset is correct

	;here masked numbers received will be saved

	ADD XL, R20				;add offset to start of X

	ST X, R19		        ;save where Z points
	INC R20					;increment offset
	ST Z, R20		        ;save new offset
        
	CPI R20, 9	        ;if offset is 9
	BRNE nxt		    ;8 bytes have been received
	LDI R24, 0
	ST Z, R24        	;and reinitialization is needed

nxt:
	
	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI

charn:
	LDI R24, 0
	ST Z, R24        	;reinitialization is needed

charc:
	//STS 0x0068, R19          ;save received char to 0x0068

	;if byte is C or N
	;wipe ram data for display

	LDI R18, 0

clear:
	LDI R23, 0x0A           ;offset for pointer to 0x007A for no display output
	ST X, R23               ;saving to SRAM
	ADIW X, 1			    ;increment pointer
	INC R18				    ;increment counter
	CPI R18, 8			    ;compare to target
	BRNE clear			    ;if not equal repeat else proceed

	LDI XL, lo8(0x0060)      ;setting pointer X
	LDI XH, hi8(0x0060)     ;to least significant bit received
	
	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI

;if A, T or <CR> is received return and wait for next byte
chara:
chart:
charcr:

	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI


charlf:

;begin transmision by sending O
	LDI R18, 0x4F		    ;load char O to register r18 for transmision
	;OUT UDR, R18		    ;send data to transmit register
	OUT TCNT2, R18		    ;send data to transmit register--for simulation

	STS 0x0074, R18					                            ;save transmited char to 0x0074
	LDI R18, (1<<UDRIE) | (1<<RXCIE) | (1<<RXEN)                ;setting data register empty interupt enable and RX complete interupt enable
	OUT UCSRB,R18                                               ;at UCSRB register 
	LDI R18, (1<<UDRE)				                            ;setting data register empty flag active
	OUT UCSRA,R18					                            ;at UCSRA register -- for simulation
	
	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI







;interupt handler for UDR empty
;will be called when TXD has no data after first transmission
.global USART_UDRE
USART_UDRE:

	PUSH R31
	PUSH R30
	PUSH R29
	PUSH R28
	PUSH R27
	PUSH R26


	LDS R19, 0x0074        ;load from ram the last char that was transmited
     
	CPI R19, 0x4F         ;if byte is char O
	BREQ trcharo     
     
	CPI R19, 0x4B         ;if byte is char K
	BREQ trchark     
     
	CPI R19, 0x0D         ;if byte is char <CR>
	BREQ trcharcr     
     
	CPI R19, 0x0A         ;if byte is char <LF>
	BREQ trcharlf

trcharo:
	LDI R18, 0x4B		  ;load char K to register r18 for transmision
	;OUT UDR, R18		  ;send data to transmit register
	OUT TCNT2, R18		  ;send data to transmit register-- for simulation

	STS 0x0074, R18        ;save transmited char to 0x0074

	LDI R18, (1<<UDRE)    ;setting data register empty flag active
	OUT UCSRA,R18         ;at UCSRA register -- for simulation

	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI


trchark:
	LDI R18, 0x0D		  ;load char <CR> to register r18 for transmision
	;OUT UDR, R18		  ;send data to transmit register
	OUT TCNT2, R18		  ;send data to transmit register-- for simulation

	STS 0x0074, R18        ;save transmited char to 0x0074

	LDI R18, (1<<UDRE)    ;setting data register empty flag active
	OUT UCSRA,R18         ;at UCSRA register -- for simulation

	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI


trcharcr:
	LDI R18, 0x0A		  ;load char <LF> to register r18 for transmision
	;OUT UDR, R18		  ;send data to transmit register
	OUT TCNT2, R18		  ;send data to transmit register-- for simulation

	STS 0x0074, R18        ;save transmited char to 0x0074

	LDI R18, (1<<UDRE)    ;setting data register empty flag active
	OUT UCSRA,R18         ;at UCSRA register -- for simulation

	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI



trcharlf:
	CBI UCSRB, 5
	LDI R20,  (1<<RXCIE) | (1<<RXEN) | (1<<TXEN)				;setting RX complete interupt enable,
	OUT UCSRB,R20												;receiver and transmiter enable in UCSRB register
	
	POP R26
	POP R27
	POP R28
	POP R29
	POP R30
	POP R31

	RETI