;Embedded microproccessor systems lab 1
; LAB1.1.asm
;Fotis Bampaniotis
; Created: 10/4/2020 9:17:28 PM
; 
;Device:ATmega16
;Clock frequency: 10MHz
;loop implementation


start:
    LDI R16,0      ;initializing the nested "counter"
	LDI R17,0xFF   ;setting r17 to FF for DDRA 
	LDI R18,207    ;setting r18 to 207 for the nested loop
	LDI R19,0      ;initializing the outer loop counter
	LDI R20,12     ;setting r20 to 12 for the outer loop 
	OUT DDRA,R17   ;setting PORTA as output

loop:             ;this is the start of the outer loop
	CBI PORTA, 7  ;setting output bit to zero (led)

internal:         ;this is the start of the nested loop
	INC R16       ;incrementing nested loop counter
	CP R16,R18    ;comparing nested loop counter to nested loop goal
	BRNE internal ;if counter reached goal branch is ignored, if not equal go to nested loop until counter reaches goal
	LDI R16,0     ;goal reached, we have to reset nested loop counter
	INC R19       ;increment outer loop counter
	CP R19,R20    ;compare outer loop counter to goal
	BRNE internal ;if counter reached goal branch is ignored, if not equal go to outer loop until counter reaches goal
	LDI R19,0     ;goal reached, reset outer loop counter
	SBI PORTA,7   ;setting bit 7 of PORTA to 1 (flashing led)

	RJMP loop     ;jump to outer loop start to count 1 more ms