.data

ARRAY: .word -1, 23, 0, 12, -7
SIZE: .word 5

.text
.global _start

_start:
	LDR R0, =SIZE
	LDR R0, [R0] // SIZE => R0
	LDR R1, =ARRAY // &ARRAY[0] => R1
	MOV R2, #0 // step => R2 

LOOP1: 
	MOV R3, #0 // i => R3 
	CMP R0, R2
	BLE END
	ADD R2, R2, #1
	
LOOP2: 
	SUB R4, R0, R2
	CMP R4, R3
	BLE LOOP1 
	ADD R7, R3, #1

	LDR R4, [R1, R3, LSL#2] // *(ptr + i)
	LDR R5, [R1, R7, LSL#2] // *(ptr + i + 1)
	
	// Swap if necessary 
	CMP R4, R5
	STRGT   R5,[R1,R3,LSL #2]   
    STRGT   R4,[R1,R7,LSL #2]  
	
	ADD R3, R3, #1
	B LOOP2
		
END:
	B END