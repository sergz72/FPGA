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
  j ok
