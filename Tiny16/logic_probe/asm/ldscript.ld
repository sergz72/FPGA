stack_size=128
data_size=512-stack_size
code_size=4096-data_size-stack_size

section code size=code_size,address=0,file="code"
section data contains="bss",size=data_size,address=code_size,file="data"
