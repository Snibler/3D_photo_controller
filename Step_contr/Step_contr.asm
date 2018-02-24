/* Program for controlling stepper motor driver and shutter of camera to make 3D photo of goods
 * controller ATtiny2313A
 * internal oscillator used, configured for 8MHz
 * ratio factor from motor shaft to platform thru gears 1/20
 * signals from controller to driver are:
 *				pin 14 (PB2) - CLK
 *				pin 13 (PB1) - DIRECTION
 *				pin 11 (PD6) - ENABLE
 *				pin 16 (PB4) - SHUTTER OF CAMERA
 * keyboard for controlling options:
 *				pin 2 (PD0)	 - 8 pictures around
 *				pin 17 (PB5) - 16 pictures around
 *				pin 18 (PB6) - 32 pict around
 *				pin 19 (PB7) - 50 pict around
 *				pin 3 (PD1)  - Reversal
 *				pin 6 (PD2)  - one step Clockwise
 *				pin 7 (PD3)	 - one step Counterclockise
 *				pin 8 (PD4)	 - Enable/Disable
 *				pin 12 (PB0) - Stop
 *  Created: 28.11.2013 13:48:31
 *  Author: Snibler
 */ 

.include"tn2313Adef.inc"
;----------Makroassembler------------------------------------
.def temp   = r16
.def rabH   = r31			;ZH container for amoung of clk pulses
.def rabL   = r30			;ZL
.def stepsH = r29			;YH container for full_turn_steps amount
.def stepsL = r28			;YL
.def countH = r27			;XH container for needed steps between photo
.def countL = r26			;XL
.equ steps_8_pict	 = 500	;8 pictures	- 45 deg *20/1,8 = 500 full_turn_steps of motor
.equ steps_16_pict	 = 250	;16	pict	- 22,5*20/1,8 = 250
.equ steps_32_pict	 = 125	;32	pict	- 11,25*20/1,8 = 125
.equ steps_50_pict	 = 80	;50 pict	- 80						(64 pict - 5,625*20/1,8 = 62,5)
.equ pause_for_pict  = 250	;max 65535;	pause for taking a picture
.equ pulse_duty		 = 5	;max 255;	pulse width and duty cycle
.equ full_turn_steps = 4000	;4000 full_turn_steps of 1.8 deg motor shaft for 360 degrees rotation of platform with ratio 1/20
;--------Start of program code----------------------------------
.cseg						
.org 0x0000					
;--------Define interrupts--------------------------------------
start:	rjmp init			;
		reti				;INT0
		reti				;INT1
		reti				;ICP1
		reti 				;OC1A
		reti				;OVF1
		reti				;OVF0
		reti				;URXC0
		reti				;UDRE0
		reti				;UTXC0
		reti				;ACI
		rjmp STOP			;PCINT
		reti				;OC1B
		reti				;OC0A
		reti				;OC0B
		reti				;USI_START
		reti				;USI_OVF
		reti				;ERDY
		reti				;WDT

;------Initialisation module-------------------------------------------
init: 
	;-----RAM init------
	ldi temp, low(RAMEND)	
	out SPL, temp
	;-----I/O init------
	ldi temp, 0b00011111	
	out DDRB, temp			;1-an output pin, 0-an input pin.
	ldi temp, 0b11111111	
	out PORTB, temp			;turn on pull-up resistor

	ldi temp, 0b1000000		
	out DDRD, temp			;1-an output pin, 0-an input pin.
	ldi temp, 0b1111111		
	out PORTD, temp			;turn on pull-up resistor
	;---------8-bit Timer/Counter0	init----		
	ldi temp, (1<<CS02)|(0<<CS01)|(1<<CS00)			;clkI/O/1024 (From prescaler)
	out TCCR0B, temp														
	;---------16-bit Timer/Counter1 init----
	ldi temp, (1<<CS12)|(0<<CS11)|(1<<CS10)			;clkI/O/1024 (From prescaler)
	out TCCR1B, temp
	;---------Comparator init----------------------
	ldi temp, (1<<ACD)		;Analog comparator disable
	out ACSR, temp
	;-----External interrupts init----------------------
	ldi temp, (1<<PCIE)
	out GIMSK, temp
	ldi temp, (1<<PCINT0)	;Enable interrupt by change on any pin
	out PCMSK, temp

	ldi stepsH, high(full_turn_steps)	;
	ldi stepsL, low(full_turn_steps)
	sbi PortD, 6			;Disable stepper driver
	cbi PortB, 3			;Full step mode
	cbi PortB, 1			;clockwise direction
	sei
;---------Main programm-------------------------------------------------
main:
	sbic PortD,6
	rjmp m2
;-----Scan option keys-------------------------------------------
	sbic PIND,0			;knob - make full Circle and make 8 photo
	rjmp m13
	ldi countH,high(steps_8_pict)
	ldi countL,low(steps_8_pict)
	rjmp m21
m13:
	sbic PINB,5			;knob - make full Circle and make 16 photo
	rjmp m11
	ldi countH,high(steps_16_pict)
	ldi countL,low(steps_16_pict)
	rjmp m21
m11:
	sbic PINB,6			;knob - make full Circle and make 32 photo
	rjmp m12
	ldi countH,high(steps_32_pict)
	ldi countL,low(steps_32_pict)
	rjmp m21
m12:
	sbic PINB,7			;knob - make full Circle and make 50 photo
	rjmp m2
	ldi countH,high(steps_50_pict)
	ldi countL,low(steps_50_pict)
m21:
	cbi PortB,4				;signal for first photo to shutter
	rcall wait_long			
	sbi PortB,4
	rcall wait_long			;pause for taking a picture
m8:
	rcall wait_short
	cp countH,stepsH
	brlo m6
	cp countL,stepsL
	brlo m6
	mov rabH,stepsH
	mov rabL,stepsL
	cpi rabL,0
	breq m2
	rcall imp
	rjmp m2
m6:
	sub stepsL,countL		;full_turn_steps-Y,count-X
	sbc stepsH,countH
	cpi stepsH,0
	brne m17
	cpi stepsL,0
	breq m5
m17:
	mov rabH,countH
	mov rabL,countL
	rcall imp
	rcall wait_long			
	cbi PortB,4				;signal to shutter
	rcall wait_long			
	sbi PortB,4
	rcall wait_long			;pause for taking a picture
	rjmp m8
m5:
	mov rabH,countH
	mov rabL,countL			;load quantity of full_turn_steps
	rcall imp

;-------------------------------------------------------------------------

m2:
	ldi stepsH,high(full_turn_steps)
	ldi stepsL,low(full_turn_steps)
	sbic PIND,1				;knob reversal
	rjmp m3
	rcall wait_long
	sbis PortB,1
	rjmp m9
	rjmp m10
m9:	
	sbi PortB,1				;counterclockwise direction
	rjmp m3
m10:
	cbi PortB,1				;clockwise direction
;-------------------------------------------------------------------------

m3:
	sbic PIND,4				;knob Enable/Disable
	rjmp m14
	rcall wait_long
	sbis PortD,6
	rjmp m15
	rjmp m16
m15:	
	sbi PortD,6				;Enable stepper controller
	rjmp m3
m16:
	cbi PortD,6				;Disable stepper controller

;------------------------------------------------------------------------
m14:
	sbic PortD,6
	rjmp m2
	sbic PIND,2				;knob make 1 step clockwise
	rjmp m4
	rcall wait_long			;pause between 1 grad of big circle
	cbi PortB,1				;clockwise direction
	clr rabH
	ldi rabL,11				;1 degree big circle
	rcall imp
	sbis PIND,2
	rjmp m3
	rcall wait_long			
	cbi PortB,4				;signal to shutter
	rcall wait_long
	sbi PortB,4
	rcall wait_long			;pause for taking a picture
;------------------------------------------------------------------------
m4:
	sbic PIND,3				;knob make 1 step counterclockwise
	rjmp main
	rcall wait_long			;pause between 1 grad of big circle
	sbi PortB,1				;counterclockwise direction
	clr rabH
	ldi rabL,11				;1 degree big circle
	rcall imp
	sbis PIND,3
	rjmp m4
	rcall wait_long			
	cbi PortB,4				;signal to shutter
	rcall wait_long
	sbi PortB,4
	rcall wait_long			;pause for taking a picture

	rjmp main

;-----------One CLK Pulse--------------
imp:
	cpi rabH,0
	brne start_CLK
	cpi rabL,0
	breq stop_CLK
start_CLK:
	cbi PortB,2
	rcall wait_short
	sbi PortB,2
	rcall wait_short
	cpi rabH,0
	brne next_CLK
	cpi rabL,0
	breq stop_CLK
next_CLK:
	sbiw Z,1
	rjmp imp
stop_CLK:
	sbi PortB,2
ret

;----------STOP----------------------
STOP:
	sbic PINB,0			;knob STOP
	rjmp exit_STOP
	clr rabH
	clr rabL
	clr stepsH
	clr stepsL
	clr countH
	clr countL
exit_STOP:
reti
;-----------Wait long-------------
wait_long:	
	clr temp
	out TCNT1H, temp
	out TCNT1L, temp
wt1:in temp, TCNT1L
	cpi temp, low(pause_for_pict)
	brlo wt1
	in temp, TCNT1H
	cpi temp, high(pause_for_pict)
	brlo wt1
ret
;-----------Wait short-------------
wait_short:	
	clr temp
	out TCNT0,temp
wt2:in temp, TCNT0
	cpi temp,pulse_duty
	brlo wt2
ret
