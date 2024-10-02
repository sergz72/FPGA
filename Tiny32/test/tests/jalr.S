#include "../custom_ops.S"

.section .reset_vec
.globl _start

_start:
  call ok1
  j ok
  j .
  j .
ok:
  halt_insn()
  j .
ok2:
  ret
  halt_insn()
  j .
ok1:
  mv a0, ra
  call ok2
  mv ra, a0
  ret
  halt_insn()
  j .
