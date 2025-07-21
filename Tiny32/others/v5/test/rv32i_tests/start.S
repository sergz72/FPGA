#include "../../custom_ops.S"

.section .reset_vec
.globl _start, mytest_ret, mytest_fail

_start:
  j mytest
  j .
  j .
mytest_ret:
  waitirq_insn();
  j .
mytest_fail:
  halt_insn();
  j .
  j .

