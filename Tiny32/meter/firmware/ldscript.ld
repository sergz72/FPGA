OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{ 
  ROM   (rx) : ORIGIN = 0x00000000, LENGTH = 4K
  RAM   (rw) : ORIGIN = 0x40000000, LENGTH = 4K
}

SECTIONS
{
  stack_size = 256;

  . = ALIGN(4);

  .text :
  {
    KEEP(*(.reset_vec)) /* Startup code */
    *(.text)
    *(.rodata)
    *(.srodata)
  } >ROM

  . = ALIGN(4);
  
  _sidata = .;
  .data : AT(_sidata)
  {
    *(.sdata)
    *(.data)
  } >RAM

  .bss :
  {
    PROVIDE( _bss_start = . );
    *(.sbss*)
    *(.bss .bss.*)
    *(COMMON)
    PROVIDE( _bss_end = . );
  } >RAM

  .stack ORIGIN(RAM) + LENGTH(RAM) - stack_size :
  {
    PROVIDE( _heap_end = . );
    . = stack_size;  
    PROVIDE( _sp = . ); 
  } >RAM
}
