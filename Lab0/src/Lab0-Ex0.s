.global _start
_start:
	// reads a value from a fixed address in memory, adds four to it, and writes it back to that
	// address. That is, we will write an assembly program that is equivalent to 
	// this C code: *address += 4, where address is some constant address.

	mov r0, #0x100
	ldr r1, [r0]
	add r1, r1, #4
	str r1, [r0]
	