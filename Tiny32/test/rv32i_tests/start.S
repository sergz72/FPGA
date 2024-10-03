#include "../custom_ops.S"

.section .reset_vec
.globl _start, mytest_ret

_start:
  j mytest
  halt_insn()
  j .
  j .
mytest_ret:
  halt_insn()
  j .
