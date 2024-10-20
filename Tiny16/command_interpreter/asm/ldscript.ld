.equ stack_size 32
.equ reserved_size=256
.equ code_size=1024
.equ data_size=1024 - stack_size - reserved

.segment code size=code_size address=0 file=code.hex
.segment data contains=data,bss size=data_size address=F000 file=data.hex
