/* Definitions of target machine for GNU compiler, for the cpu16
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

#define CONSTANT_POOL_BEFORE_FUNCTION	0

#define ASSEMBLER_DIALECT 0

/* TYPE SIZES */
#define SHORT_TYPE_SIZE		16
#define INT_TYPE_SIZE		16
#define LONG_TYPE_SIZE		32
#define LONG_LONG_TYPE_SIZE	64     

/* In earlier versions, FLOAT_TYPE_SIZE was selectable as 32 or 64,
   but that conflicts with Fortran language rules.  Since there is no
   obvious reason why we should have that feature -- other targets
   generally don't have float and double the same size -- I've removed
   it.  Note that it continues to be true (for now) that arithmetic is
   always done with 64-bit values, i.e., the FPU is always in "double"
   mode.  */
#define FLOAT_TYPE_SIZE		32
#define DOUBLE_TYPE_SIZE	64
#define LONG_DOUBLE_TYPE_SIZE	64

#define TARGET_HAS_NO_HW_DIVIDE 1

enum reg_class
  { NO_REGS,
    SP_REG,
    GENERAL_REGS,
    ALL_REGS,
    LIM_REG_CLASSES };

#define N_REG_CLASSES ((int) LIM_REG_CLASSES)

/* Width of a word, in units (bytes). 

   UNITS OR BYTES - seems like units */
#define UNITS_PER_WORD 2

//??????
#define CUMULATIVE_ARGS int

/* Max number of bytes we can move from memory to memory
   in one reasonably fast instruction.  
*/
#define MOVE_MAX 2

/* Specify the machine mode that this machine uses
   for the index in the tablejump instruction.  */
#define CASE_VECTOR_MODE HImode

/* Specify the machine mode that pointers have.
   After generation of rtl, the compiler makes no further distinction
   between pointers and any other objects of this machine mode.  */
#define Pmode HImode

/* A function address in a call instruction
   is a word address (for indexing purposes)
   so give the MEM rtx a word's mode.  */
#define FUNCTION_MODE HImode

/* Define this if move instructions will actually fail to work
   when given unaligned data.  */
#define STRICT_ALIGNMENT 1

/* Define this if most significant bit is lowest numbered
   in instructions that operate on numbered bit-fields.  */
#define BITS_BIG_ENDIAN 0

/* Define this if most significant byte of a word is the lowest numbered.  */
#define BYTES_BIG_ENDIAN 0

/* Define this if most significant word of a multiword number is first.  */
#define WORDS_BIG_ENDIAN 0

/* Define that floats are in VAX order, not high word first as for ints.  */
#define FLOAT_WORDS_BIG_ENDIAN 0

/* Maximum sized of reasonable data type -- DImode ...*/
#define MAX_FIXED_MODE_SIZE 64	

/* Allocation boundary (in *bits*) for storing pointers in memory.  */
#define POINTER_BOUNDARY 16

/* Allocation boundary (in *bits*) for storing arguments in argument list.  */
#define PARM_BOUNDARY 16

/* Boundary (in *bits*) on which stack pointer should be aligned.  */
#define STACK_BOUNDARY 16

/* Allocation boundary (in *bits*) for the code of a function.  */
#define FUNCTION_BOUNDARY 16

/* Alignment of field after `int : 0' in a structure.  */
#define EMPTY_FIELD_BOUNDARY 16

/* No data type wants to be aligned rounder than this.  */
#define BIGGEST_ALIGNMENT 16

//????
#define TRAMPOLINE_SIZE 8
//?????
#define TRAMPOLINE_ALIGNMENT 16

#define TARGET_CPU_CPP_BUILTINS()		\
  do						\
    {						\
      builtin_define_std ("cpu16");		\
    }						\
  while (0)

/* Maximum number of registers that can appear in a valid memory address.  */

#define MAX_REGS_PER_ADDRESS 1

/* 1 if N is a possible register number for function argument passing.
   - not used */

#define FUNCTION_ARG_REGNO_P(N) 0

/* Definitions for register eliminations.

   This is an array of structures.  Each structure initializes one pair
   of eliminable registers.  The "from" register number is given first,
   followed by "to".  Eliminations of the same "from" register are listed
   in order of preference.

   There are two registers that can be eliminated on the cpu16.  The
   arg pointer can be replaced by the frame pointer; the frame pointer
   can often be replaced by the stack pointer.  */

#define ELIMINABLE_REGS					\
{{ ARG_POINTER_REGNUM, STACK_POINTER_REGNUM},		\
 { ARG_POINTER_REGNUM, FRAME_POINTER_REGNUM},		\
 { FRAME_POINTER_REGNUM, STACK_POINTER_REGNUM}}

#define INITIAL_ELIMINATION_OFFSET(FROM, TO, OFFSET) \
  ((OFFSET) = cpu16_initial_elimination_offset ((FROM), (TO)))

#define REG_CLASS_NAMES  \
  { "NO_REGS",		 \
    "SP_REG",		 \
    "GENERAL_REGS",	 \
    "ALL_REGS" }

/* Define which registers fit in which classes.
   This is an initializer for a vector of HARD_REG_SET
   of length N_REG_CLASSES.  */

#define REG_CLASS_CONTENTS \
  { {0x00000},	/* NO_REGS */		\
    {0x000bf},	/* SP_REG */		\
    {0x040ff},	/* GENERAL_REGS */	\
    {0x1ffff}}	/* ALL_REGS */

/* The same information, inverted:
   Return the class number of the smallest class containing
   reg number REGNO.  This could be a conditional expression
   or could index an array.  */

#define REGNO_REG_CLASS(REGNO) cpu16_regno_reg_class (REGNO)

/* The class value for index registers, and the one for base regs.  */
#define INDEX_REG_CLASS GENERAL_REGS
#define BASE_REG_CLASS GENERAL_REGS

/* Return TRUE if the class is a CPU register.  */
#define CPU_REG_CLASS(CLASS) \
  (CLASS > NO_REGS && CLASS <= GENERAL_REGS)
  
/* Return the maximum number of consecutive registers
   needed to represent mode MODE in a register of class CLASS.  */
#define CLASS_MAX_NREGS(CLASS, MODE)	\
  (CPU_REG_CLASS (CLASS) ?	\
   ((GET_MODE_SIZE (MODE) + UNITS_PER_WORD - 1) / UNITS_PER_WORD):	\
   1									\
  )

/* Stack layout; function entry, exit and calling.  */

/* Define this if pushing a word on the stack
   makes the stack pointer a smaller address.  */
#define STACK_GROWS_DOWNWARD 1

/* Define this to nonzero if the nominal address of the stack frame
   is at the high-address end of the local variables;
   that is, each additional local variable allocated
   goes at a more negative offset in the frame.
*/
#define FRAME_GROWS_DOWNWARD 1

/* Addressing modes, and classification of registers for them.  */

#define HAVE_POST_INCREMENT 1

#define HAVE_PRE_DECREMENT 1

/* Macros to check register numbers against specific register classes.  */

/* These assume that REGNO is a hard or pseudo reg number.
   They give nonzero only if REGNO is a hard reg of the suitable class
   or a pseudo reg currently allocated to a suitable hard reg.
   Since they use reg_renumber, they are safe only once reg_renumber
   has been allocated, which happens in reginfo.cc during register
   allocation.  */

#define REGNO_OK_FOR_BASE_P(REGNO) 1

#define REGNO_OK_FOR_INDEX_P(REGNO) REGNO_OK_FOR_BASE_P (REGNO)

/* Offset of first parameter from the argument pointer register value.  */
#define FIRST_PARM_OFFSET(FNDECL) 0

/* Define how to find the value returned by a function.
   VALTYPE is the data type of the value (as a tree).
   If the precise function being called is known, FUNC is its FUNCTION_DECL;
   otherwise, FUNC is 0.  */
#define BASE_RETURN_VALUE_REG(MODE) RETVAL_REGNUM

/* Initialize a variable CUM of type CUMULATIVE_ARGS
   for a call to a function whose data type is FNTYPE.
   For a library call, FNTYPE is 0.

   ...., the offset normally starts at 0, but starts at 1 word
   when the function gets a structure-value-address as an
   invisible first argument.  */

#define INIT_CUMULATIVE_ARGS(CUM, FNTYPE, LIBNAME, INDIRECT, N_NAMED_ARGS) ((CUM) = 0)

/* Output assembler code to FILE to increment profiler label # LABELNO
   for profiling a function entry.  */

#define FUNCTION_PROFILER(FILE, LABELNO)

/* EXIT_IGNORE_STACK should be nonzero if, when returning from a function,
   the stack pointer does not matter.  The value is tested only in
   functions that have frame pointers.
   No definition is equivalent to always zero.  */

#define EXIT_IGNORE_STACK	1

/* Define this as 1 if `char' should by default be signed; else as 0.  */
#define DEFAULT_SIGNED_CHAR 0

/* Nonzero if access to memory by byte is no faster than by word.  */
#define SLOW_BYTE_ACCESS 1

/* Output before read-only data.  */

#define TEXT_SECTION_ASM_OP "\t.text"

/* Output before writable data.  */

#define DATA_SECTION_ASM_OP "\t.data"

/* Output before read-only data.  Same as read-write data for non-DEC
   assemblers because they don't know about .rodata.  */

//#define READONLY_DATA_SECTION_ASM_OP "\t.rodata"

#define PUSH_ROUNDING(BYTES) (BYTES)

/* This is how to  to advance the location counter */

#define ASM_OUTPUT_ALIGN(FILE,LOG)

/* Output to assembler file text saying following lines
   may contain character constants, extra white space, comments, etc.  */

#define ASM_APP_ON ""

/* Output to assembler file text saying following lines
   no longer contain unusual constructs.  */

#define ASM_APP_OFF ""

#define REGISTER_NAMES \
{"r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15", \
"r16", "r17", "r18", "r19", "r20", "r21", "r22", "r23", "r24", "r25", "r26", "r27", "r28", "r29", "r30", "r31", \
"r32", "r33", "r34", "r35", "r36", "r37", "r38", "r39", "r40", "r41", "r42", "r43", "r44", "r45", "r46", "r47", \
"r48", "r49", "r50", "r51", "r52", "r53", "r54", "r55", "r56", "r57", "r58", "r59", "r60", "r61", "r62", "r63", \
"r64", "r65", "r66", "r67", "r68", "r69", "r70", "r71", "r72", "r73", "r74", "r75", "r76", "r77", "r78", "r79", \
"r80", "r81", "r82", "r83", "r84", "r85", "r86", "r87", "r88", "r89", "r90", "r91", "r92", "r93", "r94", "r95", \
"r96", "r97", "r98", "r99", "r100", "r101", "r102", "r103", "r104", "r105", "r106", "r107", "r108", "r109", "r110", "r111", \
"r112", "r113", "r114", "r115", "r116", "r117", "r118", "r119", "r120", "r121", "r122", "r123", "r124", "r125", "r126", "r127", \
"r128", "r129", "r130", "r131", "r132", "r133", "r134", "r135", "r136", "r137", "r138", "r139", "r140", "r141", "r142", "r143", \
"r144", "r145", "r146", "r147", "r148", "r149", "r150", "r151", "r152", "r153", "r154", "r155", "r156", "r157", "r158", "r159", \
"r160", "r161", "r162", "r163", "r164", "r165", "r166", "r167", "r168", "r169", "r170", "r171", "r172", "r173", "r174", "r175", \
"r176", "r177", "r178", "r179", "r180", "r181", "r182", "r183", "r184", "r185", "r186", "r187", "r188", "r189", "r190", "r191", \
"r192", "r193", "r194", "r195", "r196", "r197", "r198", "r199", "r200", "r201", "r202", "r203", "r204", "r205", "r206", "r207", \
"r208", "r209", "r210", "r211", "r212", "r213", "r214", "r215", "r216", "r217", "r218", "r219", "r220", "r221", "r222", "r223", \
"r224", "r225", "r226", "r227", "r228", "r229", "r230", "r231", "r232", "r233", "r234", "r235", "r236", "r237", "r238", "r239", \
"r240", "r241", "r242", "r243", "r244", "r245", "r246", "r247", "r248", "r249", "r250", "r251", "r252", "r253", "r254", "r255", \
"sp" }


/* Number of actual hardware registers.
   The hardware registers are assigned numbers for the compiler
   from 0 to just below FIRST_PSEUDO_REGISTER.
   All registers that the compiler knows about must be given numbers,
   even those that are not normally considered general registers.
*/

#define FIXED_REGISTERS  \
{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 }



/* 1 for registers not available across function calls.
   These must include the FIXED_REGISTERS and also any
   registers that can be used without being saved.
   The latter must include the registers where values are returned
   and the register where structure-value addresses are passed.
   Aside from that, you can include as many other registers as you like.  */

/* don't know about fp */
#define CALL_USED_REGISTERS  \
{1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 }

/* Globalizing directive for a label.  */
#define GLOBAL_ASM_OP ""

#define FLOAT_WORDS_BIG_ENDIAN 0

extern const struct real_format cpu16_f_format;
extern const struct real_format cpu16_d_format;
