;Fotios Bampaniotis
;LAB3.asm
;Clock frequency: 10MHz
;Target device: ATMega16
;Embedded microprocessor systems lab 3
;USART implementation



.org $0000
rjmp reset                     ;setting reset 
.org $000C                     ;compare match interupt
jmp TIMER1_COMPA               ;address
.org $0016                     ;receive interupt
jmp USART_RXC                  ;address
.org $0018                     ;usart data register empty interupt
jmp USART_UDRE                 ;address

;main
reset:
	LDI R16, HIGH(RAMEND)      ; Upper byte
	OUT SPH, R16               ; to stack pointer
	LDI R16, LOW(RAMEND)       ; Lower byte
	OUT SPL, R16               ; to stack pointer

	LDI R17,0xFF           ;setting r17 to FF for DDRA and DDRC
	OUT DDRA,R17           ;setting PORTA as output 
	OUT DDRC,R17           ;setting PORTC as output

	;pointer X will drive pointer Y depending on digit received so corrent value is displayed

	LDI XL, low($0060)         ;setting pointer X
	LDI XH, high($0060)        ;to least significant bit received

	LDI ZL, low($0060)         ;setting pointer Z
	LDI ZH, high($0060)        ;to next bit to be received

	LDI YL, low($0070)         ;setting pointer Y
	LDI YH, high($0070)        ;to 7 segment value for digit 0

	;saving values for digits received and 7 segment codes to sram

	;these address slots save the correct 7 segment codes for each digit to be displayed
	;received digits(BCD codes) will be added to pointer 
	;so that each BCD code will point to the appropriate value for the 7 segment

	LDI R23, 0xC0              ;seven segment value for 0
	STS $0070, R23             ;saving to SRAM
     
	LDI R23, 0xF9              ;seven segment value for 1
	STS $0071, R23             ;saving to SRAM
     
	LDI R23, 0xA4              ;seven segment value for 2
	STS $0072, R23             ;saving to SRAM
     
	LDI R23, 0xB0              ;seven segment value for 3
	STS $0073, R23             ;saving to SRAM
     
	LDI R23, 0x99              ;seven segment value for 4
	STS $0074, R23             ;saving to SRAM
     
	LDI R23, 0x92              ;seven segment value for 5
	STS $0075, R23             ;saving to SRAM
     
	LDI R23, 0x82              ;seven segment value for 6
	STS $0076, R23             ;saving to SRAM
     
	LDI R23, 0xF8              ;seven segment value for 7
	STS $0077, R23             ;saving to SRAM
     
	LDI R23, 0x80              ;seven segment value for 8
	STS $0078, R23             ;saving to SRAM
     
	LDI R23, 0x90              ;seven segment value for 9
	STS $0079, R23             ;saving to SRAM
     
	LDI R23, 0xFF              ;seven segment value for not digit not received
	STS $007A, R23             ;this value will be pointed if 7 segment needs to be off

	;wipe ram data for display
	LDI R16, 0

initloop:
	LDI R23, 0x0A              ;offset for pointer to $007A for no display output
	ST X, R23                  ;saving to SRAM
	ADIW X, 1			       ;increment pointer
	INC R16				       ;increment counter
	CPI R16, 8			       ;compare to target
	BRNE initloop		       ;if not equal repeat else proceed

	LDI XL, low($0060)         ;setting pointer X
	LDI XH, high($0060)        ;to least significant bit received

	LDI R23,0xFF               ;setting r17 to FF for DDRA and DDRC
	OUT DDRA,R17               ;setting PORTA as output 
	OUT DDRC,R17               ;setting PORTC as output
    
	LDI R16, 0x10              ;need to set 4th bit of TIMSK 
	OUT TIMSK, R16             ;enable output compare A match interupt enable
    
	LDI R16, 0x10              ;setting COM1A1 and COM1A0 to 1
	OUT TCCR1A,R16             ;so the interupt flag is active high
	    
	LDI R16, 0x1C              ;setting WGM13 and WGM12 to 1 / also setting CS12 CS11 CS10 to
	OUT TCCR1B,R16             ;so TCNT1 is compared to ICR1 / 100 for 256 prescaler 
    
	LDI R16, 0x00              ;setting TCNT1H and TCNT1L to all zeroes
	OUT TCNT1H,R16             ;counter will start from 0
	LDI R16, 0x00              ;and increment every timer/counter cycle
	OUT TCNT1L,R16             ;timer/counter frequency is proccessor_frequency/2x256x2
	

	CBI UCSRA, 1		       ;disable usart double transmission speed
	CBI UCSRA, 2		       ;disable MPCM

	LDI R16, (1<<RXCIE) | (1<<RXEN) | (1<<TXEN)			;setting RX complete interupt enable,
	OUT UCSRB,R16										;receiver and transmiter enable in UCSRB register

	LDI R16, (1<<URSEL) | (1<<UCSZ1) | (1<<UCSZ0)       ;setting RX complete interupt enable, data register empty interupt enable
	OUT UCSRC,R16										;receiver and transmiter enable in UCSRB register

	LDI R16, 0b01000000								    ;setting UBBR to 64 for
	OUT UBRRL, R16									    ;9600bps baud rate


	LDI r16, 0x00              ;setting ICR1H to 00
	OUT ICR1H,r16              ;setting ICR1L to 28
	LDI r16, 0x28              ;to count 40 time hence ~10000 cycles
	OUT ICR1L,r16              ;based on prescaler 256
	SEI

	
forever:
	RJMP forever


	

TIMER1_COMPA:	            ;interupt handler when 1ms has passed

	LDI R16,0x01		    ;temp counter for digit to be displayed
	LDI R18,128			    ;when 8th bit is displayed we need to reset

loop:
	LD R19, X			    ;load offset from memory to add to Y
	ADD YL,R19			    ;add offset to Y to get correct 7 segment value to be displayed
	LD R19, Y			    ;load 7 segment value to R19
	LDI R17, 0xFF   
	OUT PORTA, R17          ;clear output content
	OUT PORTC, R16          ;set output active at current ring digit
	OUT PORTA, R19	        ;output pointer nonzero value to 7 segment
	ADIW X,1                ;increment pointer so it points to the next desired value 
	LDI YL, low($0070)      ;setting pointer Y
	LDI YH, high($0070)     ;to 7 segment value for digit 0
	LSL R16                 ;left shift tmp ring counter
	CPI R16, 0x00		    ;if temp counter did full cycle, reset
	BRNE next1              ;if tmp ring counter is zero 
	LDI XL, low($0060)      ;setting pointer X
	LDI XH, high($0060)     ;to least significant bit received
	LDI R16, 0x01           ;reinitialize loop tmp ring counter
	RETI
next1:
	RJMP loop


;interupt handler for receive complete
USART_RXC:

	IN R16, UDR		        ;read received byte
	IN R16, UDR		        ;read received byte--for simulation
        
	MOV R16, R15            ;copy data--for simulation

	CPI R16, 0x41           ;if byte is char A
	BREQ chara

	CPI R16, 0x43           ;if byte is char C
	BREQ charc

	CPI R16, 0x4E           ;if byte is char N
	BREQ charn

	CPI R16, 0x0D           ;if byte is char <CR>
	BREQ charcr

	CPI R16, 0x54           ;if byte is char T
	BREQ chart

	CPI R16, 0x0A           ;if byte is char <LF>
	BREQ charlf

	ANDI R16, 0x0F          ;keep only 4 least significant bits so offset is correct

	;here masked numbers received will be saved

	ST Z, R16		        ;save where Z points
	ADIW Z, 1		        ;increment pointer 
        
	CPI ZL, 0x68	        ;if Z is pointing to $0068
	BRNE nxt		        ;8 bytes have been received
	LDI ZL, 0x60	        ;and reinitialization is needed

nxt:
	RETI

charn:
	LDI ZL, low($0060)      ;setting pointer Z
	LDI ZH, high($0060)     ;to next bit to be received

charc:
	STS $0068, R16          ;save received char to $0068

	;if byte is C or N
	;wipe ram data for display

	LDI R18, 0

clear:
	LDI R23, 0x0A           ;offset for pointer to $007A for no display output
	ST X, R23               ;saving to SRAM
	ADIW X, 1			    ;increment pointer
	INC R18				    ;increment counter
	CPI R18, 8			    ;compare to target
	BRNE clear			    ;if not equal repeat else proceed

	LDI XL, low($0060)      ;setting pointer X
	LDI XH, high($0060)     ;to least significant bit received

	RETI

;if A, T or <CR> is received return and wait for next byte
chara:
chart:
charcr:
	RETI


charlf:

;begin transmision by sending O
	LDI R18, 0x4F		    ;load char O to register r18 for transmision
	;OUT UDR, R18		    ;send data to transmit register
	OUT TCNT2, R18		    ;send data to transmit register--for simulation

	STS $0069, R18					                            ;save transmited char to $0069
	LDI R18, (1<<UDRIE) | (1<<RXCIE) | (1<<RXEN)                ;setting data register empty interupt enable and RX complete interupt enable
	OUT UCSRB,R18                                               ;at UCSRB register 
	LDI R18, (1<<UDRE)				                            ;setting data register empty flag active
	OUT UCSRA,R18					                            ;at UCSRA register -- for simulation
	
	RETI






;interupt handler for UDR empty
;will be called when TXD has no data after first transmission

USART_UDRE:
	LDS R19, $0069        ;load from ram the last char that was transmited
     
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

	STS $0069, R18        ;save transmited char to $0069

	LDI R18, (1<<UDRE)    ;setting data register empty flag active
	OUT UCSRA,R18         ;at UCSRA register -- for simulation

	RETI


trchark:
	LDI R18, 0x0D		  ;load char <CR> to register r18 for transmision
	;OUT UDR, R18		  ;send data to transmit register
	OUT TCNT2, R18		  ;send data to transmit register-- for simulation

	STS $0069, R18        ;save transmited char to $0069

	LDI R18, (1<<UDRE)    ;setting data register empty flag active
	OUT UCSRA,R18         ;at UCSRA register -- for simulation

	RETI


trcharcr:
	LDI R18, 0x0A		  ;load char <LF> to register r18 for transmision
	;OUT UDR, R18		  ;send data to transmit register
	OUT TCNT2, R18		  ;send data to transmit register-- for simulation

	STS $0069, R18        ;save transmited char to $0069

	LDI R18, (1<<UDRE)    ;setting data register empty flag active
	OUT UCSRA,R18         ;at UCSRA register -- for simulation

	RETI



trcharlf:
	CBI UCSRB, 5
	LDI R16,  (1<<RXCIE) | (1<<RXEN) | (1<<TXEN)				;setting RX complete interupt enable,
	OUT UCSRB,R16												;receiver and transmiter enable in UCSRB register
	RETI
