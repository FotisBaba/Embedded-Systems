//Fotios Bampaniotis
//LAB9.c
//Clock frequency: 10MHz
//Target device: ATMega16
//Embedded microprocessor systems lab 9
//SPDT debounce implementation with polling

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <util/atomic.h>
#include <string.h>
#include <stdint.h>


uint8_t prev0 = 0;  //A last value
uint8_t prev1 = 0;	//A' last value
uint8_t curr0 = 0;	//A current value
uint8_t curr1 = 0;	//A' current value
uint8_t out0 = 0;	//A counter
uint8_t out1 = 0;	//A' counter
uint8_t stable0 = 0;	//A stability variable
uint8_t stable1 = 0;	//A' stability variable
uint8_t final = 0;		//final value

int main(void)
{
	DDRA =  0x00;           //setting PORTA as input
	TIMSK = (1<<OCIE1A);			//need to set 4th bit of TIMSK
    								//enable output compare A match interrupt enable
    TCCR1A = (1<<COM1A1) | (1<<COM1A0);			//setting COM1A1 and COM1A0 to 1
    											//so the interrupt flag is active high
    TCNT1 = 0;			//setting TCNT1 to zero so counter will start from 0
	
	ICR1 = 40;					//setting ICR1 to count 40 times hence ~10000 cycles based on prescaler 256
		
	TCCR1B = (1<<WGM13) | (1<<WGM12) | (1<<CS12);		//setting WGM13 and WGM12 to 1 | also setting CS12 CS11 CS10 to
														//so TCNT1 is compared to ICR1 | 100 for 256 prescaler
	sei();	//enable global interrupts
		
	while(1){}
	
	
}

// timer1 compare match A
ISR(TIMER1_COMPA_vect, ISR_NAKED) {
	
	prev0 = curr0;				//move current PA0 value to previous
	prev1 = curr1;				//move current PA1 value to previous
	curr0 = PORTA & 0x01;		//mask byte to receive LSB
	curr1 = (PORTA & 0x02)/2;	//mask byte to receive 2nd LSB

	if(prev0!=curr0){
		out0++;			//increment A counter
		stable0 = 0;	//reinit variable
	}else if(prev1!=curr1){
		out1++;			//increment A' counter
		stable1 = 0;	//reinit variable
	}

	if(prev0==curr0){
		stable0++;		//increment variable
	}
	if(prev1==curr1){
		stable1++;		//increment variable
	}

	if(out0>out1 && stable0>2){
		final = curr0;		//save final value
		stable0 = 0;		//reinit variable
		stable1 = 0;		//reinit variable
		out0 = 0;			//reinit counter
		out1 = 0;			//reinit counter
	}else if(out0<out1 && stable1>2){
		final = curr1;		//save final value
		stable0 = 0;		//reinit variable
		stable1 = 0;		//reinit variable
		out0 = 0;			//reinit counter
		out1 = 0;			//reinit counter
	}

	reti();			//return enabling global interrupts
}