.data
.equ VGA_PIXEL_BUFFER, 0xC8000000
.equ VGA_CHAR_BUFFER, 0xC9000000

.equ PS2_DATA_REG, 0xFF200100
.equ PS2_CTR_REG, 0xFF200104

.text
.global _start
_start:
        bl      input_loop
end:
        b       end

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

// char buffer is 320 × 240 
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

/*
* PS/2 driver
*
* The subroutine will check the RVALID bit 
* in the PS/2 Data register. If valid, the 
* data from the register will be stored in 
* the pointer argument R0 and subroutine
* returns 1. If the RVALID bit is not set
* the subroutine returns 0.
*/
read_PS2_data_ASM:
	PUSH {R1, R2}
	LDR R1, =PS2_DATA_REG
	LDR R2, [R1]
	LDR R3, =0x8000 // 1 at the 15th bit
	ANDS R2, R3
	BEQ INVALID_read_PS2_data_ASM
	LDRB R2, [R1]
	STRB R2, [R0] // store in the pointer arg address
	MOV R0, #1
	B END_read_PS2_data_ASM
INVALID_read_PS2_data_ASM:
	MOV R0, #0
END_read_PS2_data_ASM:
	POP {R1, R2}
	BX LR


write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
