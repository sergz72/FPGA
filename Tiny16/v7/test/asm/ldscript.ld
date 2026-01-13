data_size=1024
code_size=4096-data_size

section code size=code_size,address=0,file="code"
section data contains="bss",size=data_size,address=code_size,file="data"
