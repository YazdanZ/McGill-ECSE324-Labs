.data
FX: .word 183, 207, 128, 30, 109, 0, 14, 52, 15, 210
	.word 228, 76, 48, 82, 179, 194, 22, 168, 58, 116
	.word 228, 217, 180, 181, 243, 65, 24, 127, 216, 118
	.word 64, 210, 138, 104, 80, 137, 212, 196, 150, 139
	.word 155, 154, 36, 254, 218, 65, 3, 11, 91, 95
	.word 219, 10, 45, 193, 204, 196, 25, 177, 188, 170
	.word 189, 241, 102, 237, 251, 223, 10, 24, 171, 71
	.word 0, 4, 81, 158, 59, 232, 155, 217, 181, 19
	.word 25, 12, 80, 244, 227, 101, 250, 103, 68, 46
	.word 136, 152, 144, 2, 97, 250, 47, 58, 214, 51 // 2D image
	
KX: .word 1, 1, 0, -1, -1
	.word 0, 1, 0, -1, 0
	.word 0, 0, 1, 0, 0
	.word 0, -1, 0, 1, 0
	.word -1, -1, 0, 1, 1 // Kernel
	
OUT: .space 400 // Output result

IW: .word 10 // Img width 
IH: .word 10 // Img height
KW: .word 5 // Kernel width 
KH: .word 5 // Kernel height
KSW: .word 2 // Kernel width stride
KHW: .word 2 // Kernel height stride

.text
.global _start

_start:
	// Load program values 
	LDR R0, =IH
	LDR R1, =IW
	LDR R2, =KW
	LDR R3, =KH
	LDR R4, =KSW
	LDR R5, =KHW
	LDR R0, [R0] // R0 = ih
	LDR R1, [R1] // R1 = iw
	LDR R2, [R2] // R2 = KW
	LDR R3, [R3] // R3 = KH
	LDR R4, [R4] // R4 = KSW
	LDR R5, [R5] // R5 = KHW
	
	LDR R8, =FX
	LDR R7, =KX
	LDR R6, =OUT
	PUSH {R6-R8}
	
	MOV R6, #0 // Initialize y (R6 = y)

LOOP1:
	CMP R0, R6
	BLE END
	MOV R7, #0 // initialize x (R7 = x)

LOOP2: 
	CMP R1, R7
	BLE ENDLOOP1 
	MOV R8, #0 // R8 = sum 
	MOV R9, #0 // R9 = i 

LOOP3: 
	CMP R2, R9
	BLE ENDLOOP2
	MOV R10, #1 // R10 = j

LOOP4: 
	CMP R3, R10
	BLE ENDLOOP3
	
	ADD R11, R7, R10 // temp1 = x + j 
	SUB R11, R11, R4 // temp1 -= ksw
	
	ADD R12, R6, R9 // temp2 = y + i 
	SUB R12, R12, R5 // temp2 -= khw
	
	CMP R11, #0 
	BLT ENDLOOP4
	CMP R11, #9
	BGT ENDLOOP4
	CMP R12, #0
	BLT ENDLOOP4
	CMP R12, #9
	BGT ENDLOOP4
		
	// Body of the if statement 
	// get fx[temp1][temp2]
	PUSH {R0, R12}
	PUSH {R12}
	MUL R0, R0, #4 	// Row size 
	MUL R11, R11, R0 // Row offset
	MUL R12, R12, #4 // Column offset 
	ADD R11, R11, R12 // Total offset 
	POP {R12, R0}
	
	POP {R12} // pop FX into R12	
	LDR R11, [R12, R11] // R11 = fx[temp1][temp2]
	
	POP {R12} // pop KX into R12
	
	PUSH {R10}
	PUSH {R2}
	MUL R2, R2, #4 	// Row size 
	MUL R11, R11, R0 // Row offset

	POP {R2}
	POP {R10}
	
	
ENDLOOP4:
	ADD R10, R10, #1 // increment j 
	B LOOP4

ENDLOOP3:
	ADD R9, R9, #1 // increment i
	B LOOP3
	
ENDLOOP2:
	ADD R7, R7, #1 // increment x
	B LOOP2

ENDLOOP1:	
	ADD R6, R6, #1 // Increment y 
	B LOOP1

END:
	B END