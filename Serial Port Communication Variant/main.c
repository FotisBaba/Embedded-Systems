
#include <avr/io.h>
#include <avr/interrupt.h>

extern void TIMER1_COMPA();	//declaring external 
extern void USART_RXC();	//functions from
extern void USART_UDRE();	//.S file

// timer1 overflow
ISR(TIMER1_COMPA_vect) {
	// process the timer1 compare match here
	TIMER1_COMPA(); //call to .S
	return;
}

// receive complete interrupt
ISR(USART_RXC_vect) {
	// process the receive complete interrupt here
	USART_RXC(); //call to .S
	return;
}

// usart data register empty interrupt
ISR(USART_UDRE_vect) {
	// process the usart data register empty interrupt here
	USART_UDRE(); //call to .S
	return;
}

uint8_t input_nums[8];			//allocating sram space
uint8_t seven_seg_values[11];	//for needed data


int main(void)
{
	DDRA =  0xFF;           //setting PORTA as output 
	DDRC =  0xFF;           //setting PORTC as output
	
	//saving values for digits received and 7 segment codes to sram
	//these address slots save the correct 7 segment codes for each digit to be displayed
	//received digits(BCD codes) will be added to pointer 
	//so that each BCD code will point to the appropriate value for the 7 segment

	seven_seg_values[0] = 0xC0; //seven segment value for 0 
	seven_seg_values[1] = 0xF9; //seven segment value for 1
	seven_seg_values[2] = 0xA4; //seven segment value for 2
	seven_seg_values[3] = 0xB0; //seven segment value for 3
	seven_seg_values[4] = 0x99; //seven segment value for 4
	seven_seg_values[5] = 0x92; //seven segment value for 5
	seven_seg_values[6] = 0x82; //seven segment value for 6
	seven_seg_values[7] = 0xF8; //seven segment value for 7
	seven_seg_values[8] = 0x80; //seven segment value for 8
	seven_seg_values[9] = 0x90; //seven segment value for 9
	seven_seg_values[10] = 0xFF; //seven segment value for not digit not received
								//this value will be pointed if 7 segment needs to be off
	
	//wipe ram data for display
	int i;
	for (i=0;i<8;i++){
		input_nums[i] =  0x0A;
	}

	
	
	TIMSK = (1<<OCIE1A);			//need to set 4th bit of TIMSK 
									//enable output compare A match interrupt enable


	TCCR1A = (1<<COM1A1) | (1<<COM1A0);			//setting COM1A1 and COM1A0 to 1
												//so the interrupt flag is active high

	

	TCNT1 = 0;			//setting TCNT1 to zero so counter will start from 0

	UCSRB = (1<<RXCIE) | (1<<RXEN) | (1<<TXEN);		//setting RX complete interrupt enable, receiver and transmitter enable in UCSRB

	UCSRC = (1<<URSEL) | (1<<UCSZ1) | (1<<UCSZ0);		//setting RX complete interrupt enable, data register empty interrupt enable

	UBRRL = 0b01000000;				//setting UBBR to 64 for 9600bps baud rate

	ICR1 = 40;					//setting ICR1 to count 40 times hence ~10000 cycles based on prescaler 256

	
	TCCR1B = (1<<WGM13) | (1<<WGM12) | (1<<CS12);		//setting WGM13 and WGM12 to 1 / also setting CS12 CS11 CS10 to
														//so TCNT1 is compared to ICR1 / 100 for 256 prescaler 

	sei();	//enable global interrupts


    while (1){	//wait
	}
	
	
	return 0;
}


