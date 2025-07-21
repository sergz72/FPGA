OUTPUT_ARCH( "riscv" )
ENTRY( _start )

/* Highest address of the user mode stack */
_sp = ORIGIN(RAM) + LENGTH(RAM); /* end of "RAM" Ram type memory */

_Min_Heap_Size = 0x800; /* required amount of heap */
_Min_Stack_Size = 0x400; /* required amount of stack */

MEMORY
{ 
  ROM   (rx) : ORIGIN = 0x08000000, LENGTH = 32K
  RAM   (rw) : ORIGIN = 0x10000000, LENGTH = 8K
}

SECTIONS
{
  . = ALIGN(4);

  .text :
  {
    KEEP(*(.reset_vec)) /* Startup code */
    *(.text)
    *(.text*)
    *(.rodata)
    *(.srodata)

    KEEP (*(.init))
    KEEP (*(.fini))

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

  /* User_heap_stack section, used to check that there is enough "RAM" Ram  type memory left */
  ._user_heap_stack :
  {
    . = ALIGN(8);
    PROVIDE ( end = . );
    PROVIDE ( _end = . );
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(8);
  } >RAM

  /* Remove information from the compiler libraries */
  /DISCARD/ :
  {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
  }
}
