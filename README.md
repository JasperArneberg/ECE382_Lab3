ECE382_Lab3
===========

Lab 3: SPI, "I/O"

C2C Jasper Arneberg  
T5 ECE 382
Capt Trimble  

##Prelab


##Lab

####Writing to the Nokia 1202 Display
In the original lab3.asm, four calls were made to the writeNokiaByte subroutine. These four calls each sent a packet of data to the display.

| Line | R12            | R13    | Purpose                       |
|------|----------------|--------|-------------------------------|
| 66   | 1 (NOKIA_DATA) | 0xE7   | Pixel data (11100111)         |
| 276  | 0 (NOKIA_CMD)  | 0xBX   | Row address                   |
| 288  | 0 (NOKIA_CMD)  | 0x1X   | First part of column address (Most significant nibble) |
| 294  | 0 (NOKIA_CMD)  | 0x0X   | Second part of column address (Least significant nibble) |

####Logic Analyzer Results
The original lab3.asm file was looked at with a commercial logic analyzer. The following table is a summary of the results of the packets sent to the Nokia 1202 display. Note that this was for the very first press of the button, so the row and column values are both 1.

| Line | Command/Data | 8-bit packet |
|------|--------------|--------------|
| 66   | Data         | 11100111     |
| 276  | Command      | 10110001     |
| 288  | Command      | 00010000     |
| 294  | Command      | 00000001     |

The following four photographs capture the screen output of the logic analyzer. The two important signals are labeled with "My Bus." The first one is connected to the SCLK pin. The second is connected to the MOSI pin. 
######Line 66
![alt text](https://github.com/JasperArneberg/ECE382_Lab3/blob/master/line66.png?raw=true "Line 66")

######Line 276
![alt text](https://github.com/JasperArneberg/ECE382_Lab3/blob/master/line276.png?raw=true "Line 276")

######Line 288
![alt text](https://github.com/JasperArneberg/ECE382_Lab3/blob/master/line288.png?raw=true "Line 288")

######Line 294
![alt text](https://github.com/JasperArneberg/ECE382_Lab3/blob/master/line294.png?raw=true "Line 294")

####Speed Analysis
Lines 93 through 100 hold the reset line low as can be seen below:
```
	; This loop creates a nice delay for the reset low pulse
	bic.b	#LCD1202_RESET_PIN, &P2OUT
	mov		#0FFFFh, R12
delayNokiaResetLow:
	dec		R12
	jne		delayNokiaResetLow

	; This loop creates a nice delay for the reset high pulse
	bis.b	#LCD1202_RESET_PIN, &P2OUT
```
The logic analyzer was configured to capture the reset signal on the falling edge. This enabled measuring the time that the reset signal was held low during this initialization process. Here was the screen of the logic analyzer:

![alt text](https://github.com/JasperArneberg/ECE382_Lab3/blob/master/reset_time.png?raw=true "Reset low signal")

This reset signal was found to be low for 19.0625 msec, as the cursors in the image above show. Becasue 0xFFFF (65535) loops were executed, this means that each cycle took approximately 290.875 nsec to complete.

Each delay cycle takes 4 instructions to complete. Two cycles are used for the "dec R12" instruction, emulated as "sub #1, R12." Another two cycles are necessary for the "jne" instruction. This means that the clock speed is approximately 72.72 nsec per cycle, or 1.375 MHz.

####Writing Modes
The following image shows how bits can be manipulated on the LCD. Using different logical operators gives more options to the programmer.

![alt text](https://github.com/JasperArneberg/ECE382_Lab3/blob/master/bitblock_filled.bmp?raw=true "Writing Modes")

####A Functionality
The lab3.asm file was modified to draw an 8x8 block up, down, left, or right when the corresponding key was pressed. This allowed for visually appealing displays to be made, such as can be seen below.
![alt text](https://github.com/JasperArneberg/ECE382_Lab3/blob/master/hi_lcd.png?raw=true "Special Message")

####Debugging
In the original code, the setAddress routine was called after the writeNokiaByte for the data was called. This led to a curious error where one column of the 8x8 block was always at row 0. This error was fixed as soon as the call to setAddress was moved before the call to writeNokiaByte within the draw8x8 subroutine.

A second problem was encountered when polling for button pushes. The original code was as follows:
```
btn_press:
	bit.b	#00100000, &P2IN			; bit 5 of P2IN set?
	jz		btn_up
	bit.b	#00010000, &P2IN			; bit 4 of P2IN set?
	jz		btn_down
	bit.b #00001000, &P2IN			; bit 2 of P2In set?
	jz		btn_sel
	bit.b	#00000010, &P2IN			; bit 2 of P2IN set?
	jz		btn_left
	bit.b	#00000010, &P2IN			; bit 1 of P2IN set?
	jz		btn_right
	jmp 	btn_press					  ; check for button presses again
```
The problem with this code was that the numbers that were bit tested were still in decimal format, even though they were intended to be in binary. Once that was understood and the values were changed to decimal, it worked as expected:
```
btn_press:
	bit.b	#32, 		&P2IN			; bit 5 of P2IN set?
	jz		btn_up
	bit.b	#16, 		&P2IN			; bit 4 of P2IN set?
	jz		btn_down
	bit.b 	#8, 		&P2IN			; bit 2 of P2In set?
	jz		btn_sel
	bit.b	#4, 		&P2IN			; bit 2 of P2IN set?
	jz		btn_left
	bit.b	#2, 	  	&P2IN			; bit 1 of P2IN set?
	jz		btn_right
	jmp 	btn_press				; check for button presses again
```

##Documentation
C2C Hamza El-Saawy helped me configure the logic analyzer settings so that I could see the data getting written to the LCD during the writeNokiaByte subroutine.  
I used http://www.tablesgenerator.com/markdown_tables to generate markdwon tables efficiently.
