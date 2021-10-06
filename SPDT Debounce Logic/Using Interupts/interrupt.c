//Fotios Bampaniotis
//LAB9.c
//Clock frequency: 10MHz
//Target device: ATMega16
//Embedded microprocessor systems lab 9
//SPDT debounce implementation with external interrupts

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <util/atomic.h>
#include <string.h>
#include <stdint.h>

uint8_t out = 0;
uint8_t final;

int main(void)
{

	DDRD =  0x00;           //setting PORTD as input	
	
	TCCR1A = (1<<COM1A1) | (1<<COM1A0);			//setting COM1A1 and COM1A0 to 1
												//so the interrupt flag is active high
	TCNT1 = 0;					//setting TCNT1 to zero so counter will start from 0
	
	TCCR1B = (1<<WGM13) | (1<<WGM12) | (1<<CS12);		//setting WGM13 and WGM12 to 1 | also setting CS12 CS11 CS10 to
														//so TCNT1 is compared to ICR1 | 100 for 256 prescaler
	
	GICR = (1<<INT0) | (1<<INT1);				//enable external interrupts 0 and 1
	
	MCUCR = (1<<ISC10) | (1<<ISC00);			//for interrupts to trigger on any logical change
	
	ICR1 = 200;					//setting ICR1 to count 200 times hence ~50000 cycles based on prescaler 256
	
	sei();	//enable global interrupts	
	
	while(1){}
	
	
}



// external interrupt 0 ISR
ISR(INT0_vect, ISR_NAKED) {
	
	out = (PORTD & 0x04)/4;		//mask byte to receive 3rd LSB

	TCNT1 = 0;		//reinit timer counter
		
	TIMSK = (1<<OCIE1A);			//need to set 4th bit of TIMSK
									//enable output compare A match interrupt enable
	
	reti();			//return enabling global interrupts
}



// external interrupt 1 ISR
ISR(INT1_vect, ISR_NAKED) {
	
	out = (PORTD & 0x08)/8;		//mask byte to receive 4th LSB
	
	TCNT1 = 0;		//reinit timer counter
	
	TIMSK = (1<<OCIE1A);			//need to set 4th bit of TIMSK
									//enable output compare A match interrupt enable

	reti();			//return enabling global interrupts
}

// timer1 compare match A
ISR(TIMER1_COMPA_vect, ISR_NAKED) {
	
	final = out;		//save final value
	out = 0;			//reinit out variable
	TIMSK = (0<<OCIE1A);			//need to clear 4th bit of TIMSK
									//disable output compare A match interrupt enable
	//final = 0;
	
	reti();			//return enabling global interrupts
}