#include <mmu.h>
#include <proc.h>

.global __entry
__entry:
	ldr sp, =_initStack /*(kernel/src/startup.c*/
	add sp, #4096

	bl enablePaging
	bl copyInterruptTable
	bl __useHighInterrupts  /* (system.S*/
	bl __enableInterrupts /*system.S*/
	bl __jump2HighMem /*system.S*/

	bl kernelEntry /*C entry at kernel/src/kernel.c*/

enablePaging:
	mov r2, lr

	mov r0, #1
	bl __setDomainAccessControl /*system.S*/

	ldr r0, =_startupPageDir /*startup.c*/
	sub r0, #KERNEL_BASE
	bl __setTranslationTableBase /*system.S*/

	bl __readControlRegister /*system.S*/
	orr r0, #1
	bl __setControlRegister /*system.S*/

	mov pc, r2

copyInterruptTable:
	mov r0, #0x0
	ldr r1, =interruptTableStart
	ldr r3, =interruptTableEnd
	
	copyLoopStart:
		ldr r2, [r1, #0x0]
		str r2, [r0, #0x0]
		add r0, r0, #0x4
		add r1, r1, #0x4
		cmp r1, r3
		bne copyLoopStart

	mov pc, lr

interruptTableStart:
	nop
	subs pc, lr, #4
	ldr pc, syscallEntryAddress
	subs pc, lr, #4
	subs pc, lr, #4
	subs pc, lr, #4
	ldr pc, irqEntryAddress
	syscallEntryAddress: .word syscallEntry
	irqEntryAddress: .word irqEntry
interruptTableEnd:

syscallEntry:
	ldr sp, =_initStack /*kernel/src/startup.c*/
	add sp, #4096

	SAVE_CONTEXT /*proc.h*/

	stmfd r13!, {r1-r12, r14}

	bl handleSyscall /*kernel/src/syscalls.c*/

	ldmfd r13!, {r1-r12, pc}^

irqEntry:
	sub r14, r14, #4
	ldr sp, =_irqStack
	add sp, #4096

	SAVE_CONTEXT

	stmfd r13!, {r0-r12, r14}

	bl handleIRQ /*kernel/src/irq.c*/

	ldmfd r13!, {r0-r12, pc}^
