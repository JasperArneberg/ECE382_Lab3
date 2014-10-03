;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------
		;Step 1- enable configuration
 		bis.b #UCSWRST, &UCA0CTL1

		;Step 2
        bis.b #UCCKPL|UCMSB|UCMST|UCSYNC, &UCA0CTL0     ; don't forget UCSYNC!

        bis.b #UCSSEL1, &UCA0CTL1                       ; select a clock to use!

		;Step 3
        bis.b #UCLISTEN, &UCA0STAT                      ; enables internal loopback

        bis.b #BIT4, &P1SEL                             ; make UCA0CLK available on P1.4
        bis.b #BIT4, &P1SEL2

        bis.b #BIT2, &P1SEL                             ; make UCA0SSIMO available on P1.2
        bis.b #BIT2, &P1SEL2

        bis.b #BIT1, &P1SEL                             ; make UCA0SSOMI available on P1.1
        bis.b #BIT1, &P1SEL2

		;Step 4- undoing Step 1
        bic.b #UCSWRST, &UCA0CTL1                       ; enable subsystem

		;Step 5- flags
send    mov.b r5, &UCA0TXBUF                          ; place a byte in the TX buffer
		inc		r5

wait    bit.b    #UCA0RXIFG, &IFG2                       ; wait for receive flag to be set (operation complete)
        jz     wait

        mov.b    &UCA0RXBUF, r4                          ; read RX buffer to clear flag
        jmp    send                                      ; send another byte

;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
