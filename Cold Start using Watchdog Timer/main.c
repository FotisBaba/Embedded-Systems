#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <util/atomic.h>
#include <string.h>
#include <avr/wdt.h>
#include <stdint.h>

#define REGcounter r15			//define register for stim

uint8_t input_nums[8];			//allocating sram space
uint8_t seven_seg_values[11];	//for needed data
uint8_t last_trx;				//for saving last transmission
uint8_t chars_num = 0;			//for numbers received

register unsigned char REGcounter asm("r15");	//typecast





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
	
	WDTCR =  (1<<WDE) | (0<<WDP2) | (0<<WDP1) | (0<<WDP0) ;

	sei();	//enable global interrupts


	while (1){	//wait
	}
	
	
	return 0;
}



// timer1 compare match A
ISR(TIMER1_COMPA_vect, ISR_NAKED) {
	
	uint8_t cnt = 1;		//temporary for bit to be displayed
	uint8_t tmp = 0;		//offset for memory



	while(cnt>=128){		//until 8th bit is displayed
		PORTA = 0xFF;		//disable output
		PORTC = cnt;		//set correct bit
		PORTA = seven_seg_values[input_nums[tmp]]; //display number
		
		tmp++;		//increment offset
		cnt *= 2;	//left shift

	}


	reti();			//return enabling global interrupts
}
// receive complete interrupt
ISR(USART_RXC_vect, ISR_NAKED) {

	uint8_t curr_char = REGcounter;		//usart input
	//curr_char = input;
	//curr_char =REGcounter;			//for simulation
	
	
	switch(curr_char){

		case 0x41:              //A
		case 0x0D:              //<CR>
		case 0x54:              //T
		break;					//do nothing

		case 0x4E:              //N
		chars_num = 0;			//init numbers received
		
		case 0x43:              //C
		
		for (int i=0;i<8;i++){			//clear memory
			input_nums[i] =  0x0A;
		}
		
		break;

		case 0x0A:              //<LF>

		UDR = 0x4F;				//send O
		last_trx = 0x4F;		//save O
		TCNT2 = 0x4F;			//for simulation

		UCSRB = (1<<UDRIE) | (1<<RXCIE) | (1<<RXEN);		//enable interrupt, receiver and transmitter

		UCSRA = (1<<UDRE);				//set interupt flag for simulation
		
		break;
		
		default:					//numbers

		input_nums[chars_num] = curr_char & 0x0F;		//mask ascii input and save value
		chars_num++;									//increase offset for next input

		if (chars_num==8) chars_num=0;					//if max numbers are received init char_num

		break;

	}

	reti();					//return enabling global interrupts
}

//usart data register empty interrupt
ISR(USART_UDRE_vect, ISR_NAKED) {

	switch(last_trx){

		case 0x4F:              //O
		UDR = 0x4B;				//send K
		last_trx = 0x4B;
		TCNT2 = 0x4B;			//for simulation
		UCSRA = (1<<UDRE);		//set flag for simulation
		break;
		
		case 0x4B:              //K
		UDR = 0x0D;				//send <CR>
		last_trx = 0x0D;
		TCNT2 = 0x0D;			//for simulation
		UCSRA = (1<<UDRE);		//set flag for simulation
		break;

		case 0x0D:              //<CR>
		UDR = 0x0A;				//send <LF>
		last_trx = 0x0A;
		TCNT2 = 0x0A;			//for simulation
		UCSRA = (1<<UDRE);		//set flag for simulation
		break;
		
		case 0x0A:					//<LF>		transmission is over

		UCSRB = (1<<RXCIE) | (1<<RXEN) | (0<<UDRIE) | (1<<TXEN);		//enable interrupts, receiver and transmitter
		break;

	}

	reti();				//return enabling global interrupts
}
