stack_size=32
reserved_size=256
code_size=1024
data_size=1024 - stack_size - reserved_size

section code size=code_size,address=0,file="code"
section data contains="data,bss",size=data_size,address=$F000,file="data"
