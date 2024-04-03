#ifndef GPIO_BASE
#define GPIO_BASE 0xFFFF0000
#endif

.globl _start
_start:
	// Load GPIO_BASE
	lui a0, %hi(GPIO_BASE)
	addi a0, a0, %lo(GPIO_BASE)

	// Load string address
	lui a1, %hi(_hello_world_string)
	addi a1, a0, %lo(_hello_world_string)

_loop:
	// Load character from string
	lb t0, 0(a1)

	// If end of string, halt
	beq t0, zero, _halt

	// Write to GPIO
	sb t0, 0(a0)

	// Increment pointer
	addi a1, a1, 1
	j _loop

// Halt
_halt:
	j _halt

.data
_hello_world_string:
    .string "Hello World!"
