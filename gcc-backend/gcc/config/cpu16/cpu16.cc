/* Subroutines for gcc2 for cpu16.
   Copyright (C) 1994-2024 Free Software Foundation, Inc.

This file is part of GCC.

GCC is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

GCC is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GCC; see the file COPYING3.  If not see
<http://www.gnu.org/licenses/>.  */

define IN_TARGET_CODE 1

#include "config.h"

struct gcc_target targetm = TARGET_INITIALIZER;

/* Generate epilogue.  This uses the frame pointer to pop the local
   variables and any alloca data off the stack.  If there is no alloca
   and frame pointer elimination hasn't been disabled, there is no
   frame pointer and the local variables are popped by adjusting the
   stack pointer instead.  */

void
cpu16_expand_epilogue (void)
{								
}

void
cpu16_expand_epilogue (void)
{
}

/* Return the class number of the smallest class containing
   reg number REGNO.  */
enum reg_class
cpu16_regno_reg_class (int regno)
{ 
  if (regno == ARG_POINTER_REGNUM)
    return SP_REG;
  return GENERAL_REGS;
}
