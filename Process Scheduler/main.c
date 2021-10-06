//Fotios Bampaniotis
//LAB8.c
//Clock frequency: 10MHz
//Target device: ATMega16
//Embedded microprocessor systems lab 8
//scheduler implementation

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <util/atomic.h>
#include <string.h>
#include <stdint.h>

#define REGcounter r15			//define register for sim


void inc_p1();			//declare process 1
void dec_p2();			//declare process 2
void shft_p3();			//declare process 3

	uint8_t chck=0;
uint8_t last_trx;					//for saving last transmission
uint8_t timerccnt = 0;				//for counting 100 times 1msec for a total of 100msec
uint8_t last_rcx;					//for saving last reception
uint8_t exists = 0;					//flag for already activated process
uint8_t placed = 0;					//flag for currently activated process
uint8_t num;						//received process number
uint8_t empty = 1;

uint8_t p3down = 0;				//flag for shifting right or left

uint8_t active[3] = {0,0,0};	//active process table

uint8_t pdata[3] = {0,255,1};	//process data table


register unsigned char REGcounter asm("r15");	//typecast


int main(void)
{
	
	//PORTS A+C for UART, PORTS B+D for processes
	DDRA =  0xFF;           //setting PORTA as output
	DDRB =  0xFF;           //setting PORTB as output
	DDRC =  0xFF;           //setting PORTC as output
	
	
	TIMSK = (1<<OCIE1A);			//need to set 4th bit of TIMSK
	//enable output compare A match interrupt enable


	TCCR1A = (1<<COM1A1) | (1<<COM1A0);			//setting COM1A1 and COM1A0 to 1
	//so the interrupt flag is active high

	

	TCNT1 = 0;			//setting TCNT1 to zero so counter will start from 0

	UCSRB = (1<<RXCIE) | (1<<RXEN) | (1<<TXEN);		//setting RX complete interrupt enable, receiver and transmitter enable in UCSRB

	UCSRC = (1<<URSEL) | (1<<UCSZ1) | (1<<UCSZ0);		//setting RX complete interrupt enable, data register empty interrupt enable

	UBRRL = 0b01000000;				//setting UBBR to 64 for 9600bps baud rate

	ICR1 = 40;					//setting ICR1 to count 40 times hence ~10000 cycles based on prescaler 256

	
	TCCR1B = (1<<WGM13) | (1<<WGM12) | (1<<CS12);		//setting WGM13 and WGM12 to 1 | also setting CS12 CS11 CS10 to
	//so TCNT1 is compared to ICR1 | 100 for 256 prescaler
	

	sei();	//enable global interrupts


	while (1){	//loop
		
		
		
		if (active[0]==1){
			inc_p1();	//execute process 1
		}else if(active[0]==2){
			dec_p2();	//execute process 2
		}else if(active[0]==3){
			shft_p3();	//execute process 3
		}else{
			chck++;
		}
		
	}
	
	
	return 0;	//return
}



// timer1 compare match A
ISR(TIMER1_COMPA_vect, ISR_NAKED) {
	timerccnt++;				//inrement counter
	
	if(timerccnt==100){
		uint8_t tmp;		//declare temp
		timerccnt = 0;		//reinit counter
		
		if(active[0]==0 && active[1]==0 && active[2]==0){	//if no active processes
			reti();			//return enabling global interrupts
		}else{
			if(active[1]!=0){				//if second element not empty(0) 
				tmp = active[0];			//save value of first element
				active[0] = active[1];		//save value of second element on first element
				if(active[2]!=0){			//if third element not empty
					active[1] = active[2];	//save value of third element on second element
					active[2] = tmp;		//save value of first element on third element
				}else{						//else
					active[1] = tmp;		//save value of first element on second element
				}
			}			
		}		
	}

	reti();			//return enabling global interrupts
}


// receive complete interrupt
ISR(USART_RXC_vect, ISR_NAKED) {

	uint8_t curr_char = REGcounter;		//usart input
	
	switch(curr_char){
		
		case 0x41:              //A
		case 0x0D:              //<CR>
		case 0x54:              //T
		break;					//do nothing

		case 0x53:              //S
		case 0x51:              //Q

		last_rcx = curr_char;	//save received char
		break;

		case 0x0A:              //<LF>

		UDR = 0x4F;				//send O
		last_trx = 0x4F;		//save O
		TCNT2 = 0x4F;			//for simulation

		UCSRB = (1<<UDRIE) | (1<<RXCIE) | (1<<RXEN);		//enable interrupt, receiver and transmitter

		UCSRA = (1<<UDRE);				//set interupt flag for simulation
		
		break;
		
		default:					//numbers

		num = curr_char & 0x0F;		//mask ascii input and save value
		
		switch(last_rcx){
			case 0x53:		//if S, activate process by adding it on table
			for(int i=0;i<3;i++){
				if(active[i]==num) exists=1;	//check if its already on table
			}

			if (!exists){		//if not on table
				uint8_t j=0;
				while(j<3 && !placed){	//while process not activated
					if(active[j]==0){
						active[j]=num;	//save value on table
						placed=1;		//set activated flag
					}
					j++;	//increment temporary
				}
			}
			placed=0;		//clear activated flag
			break;

			case 0x51:								//if Q

			for(int i=0;i<3;i++){					//look for process number
				if(active[i]==num){
				
					active[i] = 0;						//and replace with 0 if found
					uint8_t tmp = i + 1;				//index for next element
					while(tmp<3){						//while index < 3
						if(active[tmp]!=0){				//if value not zero
							active[i]=active[tmp];		//shift value to previous index
							active[tmp]=0;				//replace value of index with zero
							i++;
						}
						tmp++;
					}
					break;
				}
			}

			break;
			
			default:
			break;

		}

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


void inc_p1(){

	PORTB = pdata[0];	//send value to PORTB
	pdata[0]++;			//increment value
	if (pdata[0]==256) pdata[0] = 0;	//if limit reached reinitialize

}


void dec_p2(){

	PORTB = pdata[1];	//send value to PORTB
	pdata[1]--;			//decrement value
	if (pdata[1]==-1) pdata[1] = 255;	//if limit reached reinitialize
	
}


void shft_p3(){

	if(p3down==0){			//if shifting left
		PORTB = pdata[2];	//send value to PORTB
		pdata[2]*=2;		//multiply value by 2
		if (pdata[2]==0){	//if shifted left to 0
			p3down=1;		//set flag to shift right next execution
			pdata[2]=64;	//reinitialize to correct value to be displayed
		}
		}else{					//if shifting right
		PORTB = pdata[2];	//send value to PORTB
		pdata[2]/=2;		//devide value by 2
		if (pdata[2]==0){	//if shifted right to 0
			p3down=0;		//clear flag to shift left next execution
			pdata[2]=2;		//reinitialize to correct value to be displayed
		}
	}

}