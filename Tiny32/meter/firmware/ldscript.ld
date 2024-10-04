OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{ 
  ROM   (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
  RAM   (rwx) : ORIGIN = 0x40000000, LENGTH = 4K 
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
  .data :
  {
    *(.sdata)
    *(.data)
    *(.bss)
  } >RAM

    .stack ORIGIN(RAM) + LENGTH(RAM) - stack_size :
  {
    . = stack_size;  
    PROVIDE( _sp = . ); 
  } >RAM
}
