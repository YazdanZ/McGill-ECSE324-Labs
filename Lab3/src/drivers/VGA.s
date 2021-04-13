.data 
.equ VGA_PIXEL_BUFFER, 0xC8000000
.equ VGA_CHAR_BUFFER, 0xC9000000

.text 

.global VGA_draw_point_ASM
.global VGA_clear_pixelbuff_ASM
.global VGA_write_char_ASM
.global VGA_clear_charbuff_ASM

/*
* C prototypes of implemented VGA display drivers 
*
* void VGA_draw_point_ASM(int x, int y, short c);
* void VGA_clear_pixelbuff_ASM();
* void VGA_write_char_ASM(int x, int y, char c);
* void VGA_clear_charbuff_ASM();
*/


/*
* VGA display driver
* 
* Draws a point on the screen with 
* the color indicated in the third
* argument by accessing the pixel 
* buffer memory. First and Second
* arguments specify the coordinates 
* on the pixel
*/
VGA_draw_point_ASM:
	PUSH {R3}

// pixel buffer is 320 × 240 
// so 0 <= x < 320 and 0 <= y < 240
VALIDATE_BOUNDS_draw:
	CMP R0, #0
	BLT END_VGA_draw_point_ASM // x < 0
	LDR R3, =#320
	CMP R0, R3
	BGE END_VGA_draw_point_ASM // x >= 320

	CMP R1, #0
	BLT END_VGA_draw_point_ASM // y < 0
	CMP R1, #240
	BGE END_VGA_draw_point_ASM // y >= 240
	
VGA_draw_point:
	LDR R3, =VGA_PIXEL_BUFFER
	// compute address
	ADD R3, R3, R0, LSL #1 // shift x left by 1 
	ADD R3, R3, R1, LSL #10 // shift y left by 10
	STRH R2, [R3] // half word store
	
END_VGA_draw_point_ASM:
	POP {R3}
	BX LR

/*
* VGA display driver 
* 
* Clears all the valid memory 
* locations in the pixel buffer
*/
VGA_clear_pixelbuff_ASM:
	PUSH {R0-R3, LR}
	LDR R3, =#320 // x upper bound
	MOV R2, #0 // HEX color black
	MOV R0, #0 // x counter 

// a nested loop through all pixels
XLOOP_clear_pixel_buff:
	MOV R1, #0 // y counter 
YLOOP_clear_pixel_buff:
	BL VGA_draw_point_ASM
	ADD R1, R1, #1
	CMP R1, #240
	BEQ XLOOP_clear_pixel_buff_END
	B YLOOP_clear_pixel_buff
XLOOP_clear_pixel_buff_END:
	ADD R0, R0, #1
	CMP R0, R3
	BEQ END_VGA_clear_pixelbuff_ASM
	B XLOOP_clear_pixel_buff
END_VGA_clear_pixelbuff_ASM:
	POP {R0-R3, LR}
	BX LR
	
/*
* VGA display driver 
* 
* Write the ASCII code passed
* in the third arguments to the
* screen coordinates specified 
* by the first and second argu-
* ments. This subroutine only
* accesses the char buffer memory
*/
VGA_write_char_ASM:
	PUSH {R3}

// char buffer is 80 × 60 
// so 0 <= x < 80 and 0 <= y < 60 
VALIDATE_BOUNDS_char:
	CMP R0, #0
	BLT END_VGA_write_char_ASM // x < 0
	CMP R0, #80
	BGE END_VGA_write_char_ASM // x >= 80

	CMP R1, #0
	BLT END_VGA_write_char_ASM // y < 0
	CMP R1, #60
	BGE END_VGA_write_char_ASM // y >= 60
	
VGA_write_char:
	LDR R3, =VGA_CHAR_BUFFER
	// compute address
	ADD R3, R3, R0
	ADD R3, R3, R1, LSL #7 // shift y left by 7
	STRB R2, [R3] // half word store
	
END_VGA_write_char_ASM:
	POP {R3}
	BX LR

/*
* VGA display driver 
*
* Clears all the valid memory
* locations in the character 
* buffer
*/
VGA_clear_charbuff_ASM:
	PUSH {R0-R3, LR}
	MOV R2, #0 
	MOV R0, #0 // x counter 

// a nested loop through all chars 
XLOOP_clear_charbuff:
	MOV R1, #0 // y counter 
YLOOP_clear_charbuff:
	BL VGA_write_char_ASM
	ADD R1, R1, #1
	CMP R1, #60
	BEQ XLOOP_clear_charbuff_END
	B YLOOP_clear_charbuff
XLOOP_clear_charbuff_END:
	ADD R0, R0, #1
	CMP R0, #80
	BEQ END_VGA_clear_pixelbuff_ASM
	B XLOOP_clear_charbuff
END_VGA_clear_charbuff_ASM:
	POP {R0-R3, LR}