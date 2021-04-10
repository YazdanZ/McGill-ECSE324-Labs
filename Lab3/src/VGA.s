.data 
.equ VGA_PIXEL_BUFFER, 0xC8000000
.equ VGA_CHAR_BUFFER, 0xC9000000

.text 

.global _start
_start:
        bl      draw_test_screen
end:
        b       end

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
	
	
draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
