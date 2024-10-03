OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{ 
  ROM   (rx)  : ORIGIN = 0x00000000, LENGTH = 2K
  RAM   (rwx) : ORIGIN = 0x10000000, LENGTH = 1K 
}

SECTIONS
{
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
}
