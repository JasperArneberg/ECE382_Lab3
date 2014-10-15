;-------------------------------------------------------------------------------
;	Chris Coulston
;	Fall 2014
;	MSP430G2553
;	Draw a new vertical bar on the Nokia 1202 display everytime that SW3
;	is pressed and released.
;-------------------------------------------------------------------------------
	.cdecls C,LIST,"msp430.h"		; BOILERPLATE	Include device header file


LCD1202_SCLK_PIN:				.equ	20h		; P1.5
LCD1202_MOSI_PIN: 				.equ	80h		; P1.7
LCD1202_CS_PIN:					.equ	01h		; P1.0
LCD1202_BACKLIGHT_PIN:			.equ	10h
LCD1202_RESET_PIN:				.equ	01h
NOKIA_CMD:						.equ	00h
NOKIA_DATA:						.equ	01h

STE2007_RESET:					.equ	0xE2
STE2007_DISPLAYALLPOINTSOFF:	.equ	0xA4
STE2007_POWERCONTROL:			.equ	0x28
STE2007_POWERCTRL_ALL_ON:		.equ	0x07
STE2007_DISPLAYNORMAL:			.equ	0xA6
STE2007_DISPLAYON:				.equ	0xAF

 	.text								; BOILERPLATE	Assemble into program memory
	.retain								; BOILERPLATE	Override ELF conditional linking and retain current section
	.retainrefs							; BOILERPLATE	Retain any sections that have references to current section
	.global main						; BOILERPLATE

;-------------------------------------------------------------------------------
;           						main
;	R10		row value of cursor
;	R11		value of @R12
;
;	When calling writeNokiaByte
;	R12		1-bit	Parameter to writeNokiaByte specifying command or data
;	R13		8-bit	data or command
;
;	when calling setAddress
;	R12		row address
;	R13		column address
;-------------------------------------------------------------------------------
main:
	mov.w   #__STACK_END,SP				; Initialize stackpointer
	mov.w   #WDTPW|WDTHOLD, &WDTCTL  	; Stop watchdog timer
	dint								; disable interrupts

	call	#init						; initialize the MSP430
	call	#initNokia					; initialize the Nokia 1206
	call	#clearDisplay				; clear the display and get ready....

	mov		#4,			R10				; initialize row to middle
	mov		#48,		R11				; initizlize column to center

main_loop:
	;call	#basicFunctionality
	call	#btn_press

	mov		R10,		R12
	mov 	R11,		R13
	call	#draw8x8

	jmp		main_loop


;-------------------------------------------------------------------------------
;	Name:		basicFunctionality
;	Inputs:
;	Outputs:
;	Purpose:	waits until button is pressed and released, used in basic
;				functionality
;	Registers:
;-------------------------------------------------------------------------------
basicFunctionality:

while1:
	bit.b	#8, &P2IN					; bit 3 of P1IN set?
	jnz 	while1						; Yes, branch back and wait

while0:
	bit.b	#8, &P2IN					; bit 3 of P1IN clear?
	jz		while0						; Yes, branch back and wait

	ret

;-------------------------------------------------------------------------------
;	Name:		btn_press
;	Inputs:		column in R10 and row in R11
;	Outputs:
;	Purpose:	waits until button is pressed and released
;	Registers:
;-------------------------------------------------------------------------------
btn_press:
	bit.b	#32, 		&P2IN			; bit 5 of P2IN set?
	jz		btn_up
	bit.b	#16, 		&P2IN			; bit 4 of P2IN set?
	jz		btn_down
	bit.b 	#8, 		&P2IN			; bit 2 of P2IN set?
	jz		btn_sel
	bit.b	#4, 		&P2IN			; bit 2 of P2IN set?
	jz		btn_left
	bit.b	#2, 		&P2IN			; bit 1 of P2IN set?
	jz		btn_right
	jmp 	btn_press					; check for button presses again

btn_up:
	bit.b	#32, 		&P2IN
	jz		btn_up						; wait until button released
	call	#clear8x8
	sub		#1,			R10
	jmp		exit_sub

btn_down:
	bit.b	#16,		&P2IN			; wait until button released
	jz		btn_down
	call	#clear8x8
	add		#1,			R10
	jmp 	exit_sub

btn_sel:
	bit.b	#8,			&P2IN			; wait until button released
	jz		btn_sel
	call	#clearDisplay
	jmp		exit_sub

btn_left:
	bit.b	#4,			&P2IN			; wait until button released
	jz		btn_left
	call	#clear8x8
	sub		#8,			R11
	jmp		exit_sub

btn_right:
	bit.b	#2,			&P2IN			; wait until button released
	jz		btn_right
	call	#clear8x8
	add		#8,			R11
	jmp 	exit_sub

exit_sub:
	ret

;-------------------------------------------------------------------------------
;	Name:		draw8x8
;	Inputs:		starting row in r12 and column in r13
;	Outputs:	8x8 block on LCD screen
;	Purpose:	draw an 8x8 block in a specified location
;	Registers:	counting in R8, row cursor in R10, column cursor
;   			in R11
;-------------------------------------------------------------------------------
draw8x8:
	push 	R8
	push	R10
	push	R11
	push	R12
	push	R13

	mov		#8,			R8				;8 loops
	mov		R12,		R10				;row cursor
	mov		R13,		R11				;column cursor
loop8:
	mov		R10,		R12
	mov		R11,		R13
	inc		R11							;increment column cursor for next iteration

	call	#setAddress					;we draw

	mov		#NOKIA_DATA, R12
	mov		#0xFF, R13					;full 8x1 block
	call	#writeNokiaByte

	dec		R8
	jnz		loop8

	pop		R13
	pop		R12
	pop		R11
	pop		R10
	pop		R8
	ret

;-------------------------------------------------------------------------------
;	Name:		clear8x8
;	Inputs:		starting row in r12 and column in r13
;	Outputs:	clears 8x8 block on LCD screen
;	Purpose:	clear an 8x8 block in a specified location
;	Registers:	counting in R8, row cursor in R10, column cursor
;   			in R11
;-------------------------------------------------------------------------------
clear8x8:
	push 	R8
	push	R10
	push	R11
	push	R12
	push	R13

	mov		#8,			R8				;8 loops
	mov		R12,		R10				;row cursor
	mov		R13,		R11				;column cursor
clear_loop8:
	mov		R10,		R12
	mov		R11,		R13
	inc		R11							;increment column cursor for next iteration

	call	#setAddress					;we draw

	mov		#NOKIA_DATA, R12
	mov		#0x00, R13					;empty 8x1 block
	call	#writeNokiaByte

	dec		R8
	jnz		clear_loop8

	pop		R13
	pop		R12
	pop		R11
	pop		R10
	pop		R8
	ret


;-------------------------------------------------------------------------------
;	Name:		initNokia		68(rows)x92(columns)
;	Inputs:		none
;	Outputs:	none
;	Purpose:	Reset and initialize the Nokia Display
;
;	Registers:	R12 mainly used as the command specification for writeNokiaByte
;				R13 mainly used as the 8-bit command for writeNokiaByte
;-------------------------------------------------------------------------------
initNokia:
	push	R12
	push	R13

	bis.b	#LCD1202_CS_PIN, &P1OUT

	; This loop creates a nice delay for the reset low pulse
	bic.b	#LCD1202_RESET_PIN, &P2OUT
	mov		#0FFFFh, R12
delayNokiaResetLow:
	dec		R12
	jne		delayNokiaResetLow

	; This loop creates a nice delay for the reset high pulse
	bis.b	#LCD1202_RESET_PIN, &P2OUT
	mov		#0FFFFh, R12
delayNokiaResetHigh:
	dec		R12
	jne		delayNokiaResetHigh
	bic.b	#LCD1202_CS_PIN, &P1OUT

	; First write seems to come out a bit garbled - not sure cause
	; but it can't hurt to write a reset command twice
	mov		#NOKIA_CMD, R12
	mov		#STE2007_RESET, R13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, R12
	mov		#STE2007_RESET, R13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, R12
	mov		#STE2007_DISPLAYALLPOINTSOFF, R13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, R12
	mov		#STE2007_POWERCONTROL | STE2007_POWERCTRL_ALL_ON, R13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, R12
	mov		#STE2007_DISPLAYNORMAL, R13
	call	#writeNokiaByte

	mov		#NOKIA_CMD, R12
	mov		#STE2007_DISPLAYON, R13
	call	#writeNokiaByte

	pop		R13
	pop		R12

	ret

;-------------------------------------------------------------------------------
;	Name:		init
;	Inputs:		none
;	Outputs:	none
;	Purpose:	Setup the MSP430 to operate the Nokia 1202 Display
;-------------------------------------------------------------------------------
init:
	mov.b	#CALBC1_8MHZ, &BCSCTL1				; Setup fast clock
	mov.b	#CALDCO_8MHZ, &DCOCTL

	bis.w	#TASSEL_1 | MC_2, &TACTL
	bic.w	#TAIFG, &TACTL

	mov.b	#LCD1202_CS_PIN|LCD1202_BACKLIGHT_PIN|LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1OUT
	mov.b	#LCD1202_CS_PIN|LCD1202_BACKLIGHT_PIN|LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1DIR
	mov.b	#LCD1202_RESET_PIN, &P2OUT
	mov.b	#LCD1202_RESET_PIN, &P2DIR
	bis.b	#LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1SEL			; Select Secondary peripheral module function
	bis.b	#LCD1202_SCLK_PIN|LCD1202_MOSI_PIN, &P1SEL2			; by setting P1SEL and P1SEL2 = 1

	bis.b	#UCCKPH|UCMSB|UCMST|UCSYNC, &UCB0CTL0				; 3-pin, 8-bit SPI master
	bis.b	#UCSSEL_2, &UCB0CTL1								; SMCLK
	mov.b	#0x01, &UCB0BR0 									; 1:1
	mov.b	#0x00, &UCB0BR1
	bic.b	#UCSWRST, &UCB0CTL1

	; Buttons on the Nokia 1202
	;	S1		P2.1		Right
	;	S2		P2.2		Left
	;	S3		P2.3		Aux
	;	S4		P2.4		Bottom
	;	S5		P2.5		Up
	;
	;	7 6 5 4 3 2 1 0
	;	0 0 1 1 1 1 1 0		0x3E
	bis.b	#0x3E, &P2REN					; Pullup/Pulldown Resistor Enabled on P2.1 - P2.5
	bis.b	#0x3E, &P2OUT					; Assert output to pull-ups pin P2.1 - P2.5
	bic.b	#0x3E, &P2DIR

	ret

;-------------------------------------------------------------------------------
;	Name:		writeNokiaByte
;	Inputs:		R12 selects between (1) Data or (0) Command string
;				R13 the data or command byte
;	Outputs:	none
;	Purpose:	Write a command or data byte to the display using 9-bit format
;-------------------------------------------------------------------------------
writeNokiaByte:

	push	R12
	push	R13

	bic.b	#LCD1202_CS_PIN, &P1OUT							; LCD1202_SELECT
	bic.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL	; Enable I/O function by clearing
	bic.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL2	; LCD1202_DISABLE_HARDWARE_SPI;

	bit.b	#01h, R12
	jeq		cmd

	bis.b	#LCD1202_MOSI_PIN, &P1OUT						; LCD1202_MOSI_LO
	jmp		clock

cmd:
	bic.b	#LCD1202_MOSI_PIN, &P1OUT						; LCD1202_MOSI_HIGH

clock:
	bis.b	#LCD1202_SCLK_PIN, &P1OUT						; LCD1202_CLOCK		positive edge
	nop
	bic.b	#LCD1202_SCLK_PIN, &P1OUT						;					negative edge

	bis.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL	; LCD1202_ENABLE_HARDWARE_SPI;
	bis.b	#LCD1202_SCLK_PIN | LCD1202_MOSI_PIN, &P1SEL2	;

	mov.b	R13, UCB0TXBUF

pollSPI:
	bit.b	#UCBUSY, &UCB0STAT
	jz		pollSPI											; while (UCB0STAT & UCBUSY);

	bis.b	#LCD1202_CS_PIN, &P1OUT							; LCD1202_DESELECT

	pop		R13
	pop		R12

	ret


;-------------------------------------------------------------------------------
;	Name:		clearDisplay
;	Inputs:		none
;	Outputs:	none
;	Purpose:	Writes 0x360 blank 8-bit columns to the Nokia display
;-------------------------------------------------------------------------------
clearDisplay:
	push	R11
	push	R12
	push	R13

	mov.w	#0x00, R12			; set display address to 0,0
	mov.w	#0x00, R13
	call	#setAddress

	mov.w	#0x01, R12			; write a "clear" set of pixels
	mov.w	#0x00, R13			; to every byte on the display

	mov.w	#0x360, R11			; loop counter
clearLoop:
	call	#writeNokiaByte
	dec.w	R11
	jnz		clearLoop

	mov.w	#0x00, R12			; set display address to 0,0
	mov.w	#0x00, R13
	call	#setAddress

	pop		R13
	pop		R12
	pop		R11

	ret

;-------------------------------------------------------------------------------
;	Name:		setAddress
;	Inputs:		R12		row
;				R13		col
;	Outputs:	none
;	Purpose:	Sets the cursor address on the 9 row x 96 column display
;-------------------------------------------------------------------------------
setAddress:
	push	R12
	push	R13

	; Since there are only 9 rows on the 1202, we can select the row in 4-bits
	mov.w	R12, R13			; Write a command, setup call to
	mov.w	#NOKIA_CMD, R12
	and.w	#0x0F, R13			; mask out any weird upper nibble bits and
	bis.w	#0xB0, R13			; mask in "B0" as the prefix for a page address
	call	#writeNokiaByte

	; Since there are only 96 columns on the 1202, we need 2 sets of 4-bits
	mov.w	#NOKIA_CMD, R12
	pop		R13					; make a copy of the column address in R13 from the stack
	push	R13
	rra.w	R13					; shift right 4 bits
	rra.w	R13
	rra.w	R13
	rra.w	R13
	and.w	#0x0F, R13			; mask out upper nibble
	bis.w	#0x10, R13			; 10 is the prefix for a upper column address
	call	#writeNokiaByte

	mov.w	#0x00, R2			; Write a command, setup call to
	pop		R13					; make a copy of the top of the stack
	push	R13
	and.w	#0x0F, R13
	call	#writeNokiaByte

	pop		R13
	pop		R12

	ret


;-------------------------------------------------------------------------------
;           System Initialization
;-------------------------------------------------------------------------------
	.global __STACK_END					; BOILERPLATE
	.sect 	.stack						; BOILERPLATE
	.sect   ".reset"                	; BOILERPLATE		MSP430 RESET Vector
	.short  main						; BOILERPLATE

