#include "../custom_ops.S"

.section .reset_vec
.globl _start

_start:
  j ok1
  halt_insn()
  j .
  j .
ok:
  halt_insn()
  j .
ok1:
  li a0, 1
  mv a1, a0
  beq a0, a1, ok2
  halt_insn()
  j .
ok2:
  bge a0, a1, ok3
  halt_insn()
  j .
ok3:
  bgeu a0, a1, ok4
  halt_insn()
  j .
ok4:
  addi a0, a0, 1
  bne a0, a1, ok5
  halt_insn()
  j .
ok5:
  bltu a1, a0, ok6
fail:
  halt_insn()
  j .
ok6:
  bgeu a1, a0, fail
  li a1, -1
  bgeu a1, a0, ok7
  halt_insn()
  j .
ok7:  
  j ok
