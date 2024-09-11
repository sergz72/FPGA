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

#define IN_TARGET_CODE 1

#include "config.h"
#include "system.h"
#include "coretypes.h"
#include "backend.h"
#include "target.h"
#include "rtl.h"
#include "tree.h"
#include "stringpool.h"
#include "attribs.h"
#include "df.h"
#include "memmodel.h"
#include "tm_p.h"
#include "insn-config.h"
#include "insn-attr.h"
#include "regs.h"
#include "emit-rtl.h"
#include "recog.h"
#include "conditions.h"
#include "output.h"
#include "stor-layout.h"
#include "varasm.h"
#include "calls.h"
#include "expr.h"
#include "builtins.h"
#include "explow.h"
#include "expmed.h"

/* This file should be included last.  */
#include "target-def.h"

/* Initialize the GCC target structure.  */
#undef TARGET_ASM_BYTE_OP
#define TARGET_ASM_BYTE_OP NULL
#undef TARGET_ASM_ALIGNED_HI_OP
#define TARGET_ASM_ALIGNED_HI_OP NULL
#undef TARGET_ASM_ALIGNED_SI_OP
#define TARGET_ASM_ALIGNED_SI_OP NULL
//#undef TARGET_ASM_INTEGER
//#define TARGET_ASM_INTEGER cpu16_assemble_integer

/* These two apply to Unix and GNU assembler; for DEC, they are
   overridden during option processing.  */
#undef TARGET_ASM_OPEN_PAREN
#define TARGET_ASM_OPEN_PAREN "["
#undef TARGET_ASM_CLOSE_PAREN
#define TARGET_ASM_CLOSE_PAREN "]"

#undef TARGET_RTX_COSTS
#define TARGET_RTX_COSTS cpu16_rtx_costs

#undef  TARGET_ADDRESS_COST
#define TARGET_ADDRESS_COST cpu16_addr_cost

#undef  TARGET_INSN_COST
#define TARGET_INSN_COST cpu16_insn_cost

#undef  TARGET_MD_ASM_ADJUST
#define TARGET_MD_ASM_ADJUST cpu16_md_asm_adjust

#undef TARGET_FUNCTION_ARG
#define TARGET_FUNCTION_ARG cpu16_function_arg
#undef TARGET_FUNCTION_ARG_ADVANCE
#define TARGET_FUNCTION_ARG_ADVANCE cpu16_function_arg_advance

#undef TARGET_RETURN_IN_MEMORY
#define TARGET_RETURN_IN_MEMORY cpu16_return_in_memory

#undef TARGET_FUNCTION_VALUE
#define TARGET_FUNCTION_VALUE cpu16_function_value
#undef TARGET_LIBCALL_VALUE
#define TARGET_LIBCALL_VALUE cpu16_libcall_value
#undef TARGET_FUNCTION_VALUE_REGNO_P
#define TARGET_FUNCTION_VALUE_REGNO_P cpu16_function_value_regno_p

#undef TARGET_TRAMPOLINE_INIT
#define TARGET_TRAMPOLINE_INIT cpu16_trampoline_init

#undef  TARGET_SECONDARY_RELOAD
#define TARGET_SECONDARY_RELOAD cpu16_secondary_reload

#undef  TARGET_REGISTER_MOVE_COST 
#define TARGET_REGISTER_MOVE_COST cpu16_register_move_cost

#undef  TARGET_PREFERRED_RELOAD_CLASS
#define TARGET_PREFERRED_RELOAD_CLASS cpu16_preferred_reload_class

#undef  TARGET_PREFERRED_OUTPUT_RELOAD_CLASS
#define TARGET_PREFERRED_OUTPUT_RELOAD_CLASS cpu16_preferred_output_reload_class

#undef  TARGET_LRA_P
#define TARGET_LRA_P cpu16_lra_p

#undef  TARGET_LEGITIMATE_ADDRESS_P
#define TARGET_LEGITIMATE_ADDRESS_P cpu16_legitimate_address_p

#undef  TARGET_CONDITIONAL_REGISTER_USAGE
#define TARGET_CONDITIONAL_REGISTER_USAGE cpu16_conditional_register_usage

#undef  TARGET_OPTION_OVERRIDE
#define TARGET_OPTION_OVERRIDE cpu16_option_override

#undef  TARGET_ASM_FILE_START_FILE_DIRECTIVE
#define TARGET_ASM_FILE_START_FILE_DIRECTIVE true

#undef  TARGET_ASM_OUTPUT_IDENT
#define TARGET_ASM_OUTPUT_IDENT cpu16_output_ident

#undef  TARGET_ASM_FUNCTION_SECTION
#define TARGET_ASM_FUNCTION_SECTION cpu16_function_section

#undef  TARGET_ASM_NAMED_SECTION
#define	TARGET_ASM_NAMED_SECTION cpu16_asm_named_section

#undef  TARGET_ASM_INIT_SECTIONS
#define TARGET_ASM_INIT_SECTIONS cpu16_asm_init_sections

#undef  TARGET_ASM_FILE_START
#define TARGET_ASM_FILE_START cpu16_file_start

#undef  TARGET_ASM_FILE_END
#define TARGET_ASM_FILE_END cpu16_file_end

#undef  TARGET_PRINT_OPERAND
#define TARGET_PRINT_OPERAND cpu16_asm_print_operand

#undef  TARGET_PRINT_OPERAND_PUNCT_VALID_P
#define TARGET_PRINT_OPERAND_PUNCT_VALID_P cpu16_asm_print_operand_punct_valid_p

#undef  TARGET_LEGITIMATE_CONSTANT_P
#define TARGET_LEGITIMATE_CONSTANT_P cpu16_legitimate_constant_p

#undef  TARGET_SCALAR_MODE_SUPPORTED_P
#define TARGET_SCALAR_MODE_SUPPORTED_P cpu16_scalar_mode_supported_p

#undef  TARGET_HARD_REGNO_NREGS
#define TARGET_HARD_REGNO_NREGS cpu16_hard_regno_nregs

#undef  TARGET_HARD_REGNO_MODE_OK
#define TARGET_HARD_REGNO_MODE_OK cpu16_hard_regno_mode_ok

#undef  TARGET_MODES_TIEABLE_P
#define TARGET_MODES_TIEABLE_P cpu16_modes_tieable_p

#undef  TARGET_SECONDARY_MEMORY_NEEDED
#define TARGET_SECONDARY_MEMORY_NEEDED cpu16_secondary_memory_needed

#undef  TARGET_CAN_CHANGE_MODE_CLASS
#define TARGET_CAN_CHANGE_MODE_CLASS cpu16_can_change_mode_class

#undef TARGET_INVALID_WITHIN_DOLOOP
#define TARGET_INVALID_WITHIN_DOLOOP hook_constcharptr_const_rtx_insn_null

#undef  TARGET_CXX_GUARD_TYPE
#define TARGET_CXX_GUARD_TYPE cpu16_guard_type

#undef  TARGET_CXX_CLASS_DATA_ALWAYS_COMDAT
#define TARGET_CXX_CLASS_DATA_ALWAYS_COMDAT hook_bool_void_false

#undef  TARGET_CXX_LIBRARY_RTTI_COMDAT
#define TARGET_CXX_LIBRARY_RTTI_COMDAT hook_bool_void_false

#undef TARGET_HAVE_SPECULATION_SAFE_VALUE
#define TARGET_HAVE_SPECULATION_SAFE_VALUE speculation_safe_value_not_needed

#undef  TARGET_STACK_PROTECT_RUNTIME_ENABLED_P
#define TARGET_STACK_PROTECT_RUNTIME_ENABLED_P hook_bool_void_false

/* Routines to encode/decode cpu16 floats */
static void encode_cpu16_f (const struct real_format *fmt,
			    long *, const REAL_VALUE_TYPE *);
static void decode_cpu16_f (const struct real_format *,
			    REAL_VALUE_TYPE *, const long *);
static void encode_cpu16_d (const struct real_format *fmt,
			    long *, const REAL_VALUE_TYPE *);
static void decode_cpu16_d (const struct real_format *,
			    REAL_VALUE_TYPE *, const long *);

/* These two are taken from the corresponding vax descriptors
   in real.cc, changing only the encode/decode routine pointers.  */
const struct real_format cpu16_f_format =
  {
    encode_cpu16_f,
    decode_cpu16_f,
    2,
    24,
    24,
    -127,
    127,
    15,
    15,
    0,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    "cpu16_f"
  };

const struct real_format cpu16_d_format =
  {
    encode_cpu16_d,
    decode_cpu16_d,
    2,
    56,
    56,
    -127,
    127,
    15,
    15,
    0,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    "cpu16_d"
  };

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
cpu16_expand_prologue (void)
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

/* A helper function to determine if REGNO should be saved in the
   current function's stack frame.  */

static inline bool
cpu16_saved_regno (unsigned regno)
{
  return !call_used_or_fixed_reg_p (regno) && df_regs_ever_live_p (regno);
}

static int
cpu16_reg_save_size (void)
{
  int offset = 0, regno;

  for (regno = 0; regno < STACK_POINTER_REGNUM; regno++)
    if (cpu16_saved_regno (regno))
      offset += 2;
  
  return offset;
}

/* Return the offset between two registers, one to be eliminated, and the other
   its replacement, at the start of a routine.  */

int
cpu16_initial_elimination_offset (int from, int to)
{
  /* Get the size of the register save area.  */

  if (from == FRAME_POINTER_REGNUM && to == STACK_POINTER_REGNUM)
    return get_frame_size ();
  else if (from == ARG_POINTER_REGNUM && to == FRAME_POINTER_REGNUM)
    return cpu16_reg_save_size () + 2;
  else if (from == ARG_POINTER_REGNUM && to == STACK_POINTER_REGNUM)
    return cpu16_reg_save_size () + 2 + get_frame_size ();
  else
    gcc_assert (0);
}

static void
encode_cpu16_f (const struct real_format *fmt ATTRIBUTE_UNUSED, long *buf,
		const REAL_VALUE_TYPE *r)
{
}

static void
decode_cpu16_f (const struct real_format *fmt ATTRIBUTE_UNUSED,
		REAL_VALUE_TYPE *r, const long *buf)
{
}

static void
encode_cpu16_d (const struct real_format *fmt ATTRIBUTE_UNUSED, long *buf,
		const REAL_VALUE_TYPE *r)
{
}

static void
decode_cpu16_d (const struct real_format *fmt ATTRIBUTE_UNUSED,
		REAL_VALUE_TYPE *r, const long *buf)
{
}

static bool
cpu16_lra_p (void)
{
  return TARGET_LRA;
}

/* Register to register moves are cheap if both are general
   registers.  */
static int 
cpu16_register_move_cost (machine_mode mode ATTRIBUTE_UNUSED,
			  reg_class_t c1, reg_class_t c2)
{
  return 2;
}

/* This tries to approximate what cpu16_insn_cost would do, but
   without visibility into the actual instruction being generated it's
   inevitably a rough approximation.  */
static bool
cpu16_rtx_costs (rtx x, machine_mode mode, int outer_code,
		 int opno ATTRIBUTE_UNUSED, int *total, bool speed)
{
  const int code = GET_CODE (x);
  const int asize = (mode == QImode) ? 2 : GET_MODE_SIZE (mode);
  rtx src, dest;
  const char *fmt;
  
  switch (code)
    {
    case CONST_INT:
      /* Treat -1, 0, 1 as things that are optimized as clr or dec
	 etc. though that doesn't apply to every case.  */
      if (INTVAL (x) >= -1 && INTVAL (x) <= 1)
	{
	  *total = 0;
	  return true;
	}
      /* FALL THROUGH.  */
    case REG:
    case MEM:
    case CONST:
    case LABEL_REF:
    case SYMBOL_REF:
    case CONST_DOUBLE:
      *total = cpu16_addr_cost (x, mode, ADDR_SPACE_GENERIC, speed);
      return true;
    }
  if (GET_RTX_LENGTH (code) == 0)
    {
      if (speed)
	*total = 0;
      else
	*total = 2;
      return true;
    }

  /* Pick up source and dest.  We don't necessarily use the standard
     recursion in rtx_costs to figure the cost, because that would
     count the destination operand twice for three-operand insns.
     Also, this way we can catch special cases like move of zero, or
     add one.  */
  fmt = GET_RTX_FORMAT (code);
  if (fmt[0] != 'e' || (GET_RTX_LENGTH (code) > 1 && fmt[1] != 'e'))
    {
      if (speed)
	*total = 0;
      else
	*total = 2;
      return true;
    }
  if (GET_RTX_LENGTH (code) > 1)
    src = XEXP (x, 1);
  dest = XEXP (x, 0);
      
  /* If optimizing for size, claim everything costs 2 per word, plus
     whatever the operands require.  */
  if (!speed)
    *total = asize;
  else
    {
      if (FLOAT_MODE_P (mode))
	{
	  switch (code)
	    {
	    case MULT:
	    case DIV:
	    case MOD:
	      *total = 20;
	      break;

	    case COMPARE:
	      *total = 4;
	      break;

	    case PLUS:
	    case MINUS:
	      *total = 6;
	      break;

	    default:
	      *total = 2;
	      break;
	    }
	}
      else
	{
	  /* Integer operations are scaled for SI and DI modes, though the
	     scaling is not exactly accurate.  */
	  switch (code)
	    {
	    case MULT:
	      *total = 5 * asize * asize;
	      break;

	    case DIV:
	      *total = 10 * asize * asize;
	      break;
	  
	    case MOD:
	      /* Fake value because it's accounted for under DIV, since we
		 use a divmod pattern.  */
	      total = 0;
	      break;

	    case ASHIFT:
	    case ASHIFTRT:
	    case LSHIFTRT:
	      /* This is a bit problematic because the cost depends on the
		 shift amount.  Make it <asize> for now, which is for the
		 case of a one bit shift.  */
	      *total = asize;
	      break;
	  
	    default:
	      *total = asize;
	      break;
	    }
	}
    }
  
  /* Now see if we're looking at a SET.  If yes, then look at the
     source to see if this is a move or an arithmetic operation, and
     continue accordingly to handle the operands.  */
  if (code == SET)
    {
      switch (GET_CODE (src))
	{
	case REG:
	case MEM:
	case CONST_INT:
	case CONST:
	case LABEL_REF:
	case SYMBOL_REF:
	case CONST_DOUBLE:
	  /* It's a move.  */
	  *total += cpu16_addr_cost (dest, mode, ADDR_SPACE_GENERIC, speed);
	  if (src != const0_rtx)
	    *total += cpu16_addr_cost (src, mode, ADDR_SPACE_GENERIC, speed);
	  return true;
	default:
	  /* Not a move.  Get the cost of the source operand and add
	     that in, but not the destination operand since we're
	     dealing with read/modify/write operands.  */
	  *total += rtx_cost (src, mode, (enum rtx_code) outer_code, 1, speed);
	  return true;
	}
    }
  else if (code == PLUS || code == MINUS)
    {
      if (GET_CODE (src) == CONST_INT &&
	  (INTVAL (src) == 1 || INTVAL (src) == -1))
	{
	  *total += rtx_cost (dest, mode, (enum rtx_code) outer_code, 0, speed);
	  return true;
	}
    }
  return false;
}

/* Return cost of accessing the supplied operand.  Registers are free.
   Anything else starts with a cost of two.  Add to that for memory
   references the memory accesses of the addressing mode (if any) plus
   the data reference; for other operands just the memory access (if
   any) for the mode.  */
static int
cpu16_addr_cost (rtx addr, machine_mode mode, addr_space_t as ATTRIBUTE_UNUSED,
		 bool speed)
{
  int cost = 0;
  
  if (GET_CODE (addr) != REG)
    {
      if (!simple_memory_operand (addr, mode))
	cost = 2;

      /* If optimizing for speed, account for the memory reference if
	 any.  */
      if (speed && !CONSTANT_P (addr))
	cost += (mode == QImode) ? 2 : GET_MODE_SIZE (mode);
    }
  return cost;
}

static int
cpu16_insn_cost (rtx_insn *insn, bool speed)
{
  int base_cost;
  rtx pat, set, dest, src, src2;
  machine_mode mode;
  enum rtx_code op;

  if (recog_memoized (insn) < 0)
    return 0;

  /* If optimizing for size, we want the insn size.  */
  if (!speed)
    return get_attr_length (insn);
  else
    {
      /* Optimizing for speed.  Get the base cost of the insn, then
	 adjust for the cost of accessing operands.  Zero means use
	 the length as the cost even when optimizing for speed.  */
      base_cost = get_attr_base_cost (insn);
      if (base_cost <= 0)
	base_cost = get_attr_length (insn);
    }
  /* Look for the operands.  Often we have a PARALLEL that's either
     the actual operation plus a clobber, or the implicit compare plus
     the actual operation.  Find the actual operation.  */
  pat = PATTERN (insn);
  
  if (GET_CODE (pat) == PARALLEL)
    {
      set = XVECEXP (pat, 0, 0);
      if (GET_CODE (set) != SET || GET_CODE (XEXP (set, 1)) == COMPARE)
	set = XVECEXP (pat, 0, 1);
      if (GET_CODE (set) != SET || GET_CODE (XEXP (set, 1)) == COMPARE)
	return 0;
    }
  else
    {
      set = pat;
      if (GET_CODE (set) != SET)
	return 0;
    }
  
  /* Pick up the SET source and destination RTL.  */
  dest = XEXP (set, 0);
  src = XEXP (set, 1);
  mode = GET_MODE (dest);

  /* See if we have a move, or some arithmetic operation.  If a move,
     account for source and destination operand costs.  Otherwise,
     account for the destination and for the second operand of the
     operation -- the first is also destination and we don't want to
     double-count it.  */
  base_cost += cpu16_addr_cost (dest, mode, ADDR_SPACE_GENERIC, speed);
  op = GET_CODE (src);
  switch (op)
    {
    case REG:
    case MEM:
    case CONST_INT:
    case CONST:
    case LABEL_REF:
    case SYMBOL_REF:
    case CONST_DOUBLE:
      /* It's a move.  */
      if (src != const0_rtx)
	base_cost += cpu16_addr_cost (src, mode, ADDR_SPACE_GENERIC, speed);
      return base_cost;
    default:
      break;
    }
  /* There are some other cases where souce and dest are distinct.  */
  if (FLOAT_MODE_P (mode) &&
      (op == FLOAT_TRUNCATE || op == FLOAT_EXTEND || op == FIX || op == FLOAT))
    {
      src2 = XEXP (src, 0);
      base_cost += cpu16_addr_cost (src2, mode, ADDR_SPACE_GENERIC, speed);
    }
  /* Otherwise, pick up the second operand of the arithmetic
     operation, if it has two operands.  */
  else if (op != SUBREG && op != UNSPEC && GET_RTX_LENGTH (op) > 1)
    {
      src2 = XEXP (src, 1);
      base_cost += cpu16_addr_cost (src2, mode, ADDR_SPACE_GENERIC, speed);
    }
  
  return base_cost;
}

const char *
output_jump (rtx *operands, int ccnz, int length)
{
  rtx tmpop[1];
  static char buf[100];
  const char *pos, *neg;
  enum rtx_code code = GET_CODE (operands[0]);

  if (ccnz)
    {
      /* These are the branches valid for CCNZmode, i.e., a comparison
	 with zero where the V bit is not set to zero.  These cases
	 occur when CC or FCC are set as a side effect of some data
	 manipulation, such as the ADD instruction.  */
      switch (code)
	{
	case EQ: pos = "jmpeq", neg = "jmpne"; break;
	case NE: pos = "jmpne", neg = "jmpeq"; break;
	case LT: pos = "jmpmi", neg = "jmppl"; break;
	case GE: pos = "jmppl", neg = "jmpmi"; break;
	default: gcc_unreachable ();
	}
    }
  else
    {
      switch (code)
	{
	case EQ: pos = "beq", neg = "bne"; break;
	case NE: pos = "bne", neg = "beq"; break;
	case GT: pos = "bgt", neg = "ble"; break;
	case GTU: pos = "bhi", neg = "blos"; break;
	case LT: pos = "blt", neg = "bge"; break;
	case LTU: pos = "blo", neg = "bhis"; break;
	case GE: pos = "bge", neg = "blt"; break;
	case GEU: pos = "bhis", neg = "blo"; break;
	case LE: pos = "ble", neg = "bgt"; break;
	case LEU: pos = "blos", neg = "bhi"; break;
	default: gcc_unreachable ();
	}
    }
  switch (length)
    {
    case 2:
      sprintf (buf, "%s\t%%l1", pos);
      return buf;
    case 6:
      tmpop[0] = gen_label_rtx ();
      sprintf (buf, "%s\t%%l0", neg);
      output_asm_insn (buf, tmpop);
      output_asm_insn ("jmp\t%l1", operands);
      output_asm_label (tmpop[0]);
      fputs (":\n", asm_out_file);
      return "";
    default:
      gcc_unreachable ();
    }
}

/* Select the CC mode to be used for the side effect compare with
   zero, given the compare operation code in op and the compare
   operands in x in and y.  */
machine_mode
cpu16_cc_mode (enum rtx_code op ATTRIBUTE_UNUSED, rtx x, rtx y ATTRIBUTE_UNUSED)
{
  if (FLOAT_MODE_P (GET_MODE (x)))
    {
      switch (GET_CODE (x))
	{
	case ABS:
	case NEG:
	case REG:
	case MEM:
	  return CCmode;
	default:
	  return CCNZmode;
	}
    }
  else
    {
      switch (GET_CODE (x))
	{
	case XOR:
	case AND:
	case IOR:
	case MULT:
	case NOT:
	case REG:
	case MEM:
	  return CCmode;
	default:
	  return CCNZmode;
	}
    }
}

int
simple_memory_operand(rtx op, machine_mode mode ATTRIBUTE_UNUSED)
{
  rtx addr;

  /* Eliminate non-memory operations */
  if (GET_CODE (op) != MEM)
    return FALSE;

  /* Decode the address now.  */

 indirection:
    
  addr = XEXP (op, 0);

  switch (GET_CODE (addr))
    {
    case REG:
      /* (R0) - no extra cost */
      return 1;
	
    case PRE_DEC:
    case POST_INC:
    case PRE_MODIFY:
    case POST_MODIFY:
      /* -(R0), (R0)+ - cheap! */
      return 1;
	
    case MEM:
      /* cheap - is encoded in addressing mode info! 

	 -- except for @(R0), which has to be @0(R0) !!! */

      if (GET_CODE (XEXP (addr, 0)) == REG)
	return 0;
	
      op=addr;
      goto indirection;
	
    case CONST_INT:
    case LABEL_REF:	       
    case CONST:
    case SYMBOL_REF:
      /* @#address - extra cost */
      return 0;

    case PLUS:
      /* X(R0) - extra cost */
      return 0;

    default:
      break;
    }
    
  return FALSE;
}

/* Similar to simple_memory_operand but doesn't match push/pop.  */
int
no_side_effect_operand(rtx op, machine_mode mode ATTRIBUTE_UNUSED)
{
  rtx addr;

  /* Eliminate non-memory operations */
  if (GET_CODE (op) != MEM)
    return FALSE;

  /* Decode the address now.  */

 indirection:
    
  addr = XEXP (op, 0);

  switch (GET_CODE (addr))
    {
    case REG:
      /* (R0) - no extra cost */
      return 1;
	
    case PRE_DEC:
    case POST_INC:
    case PRE_MODIFY:
    case POST_MODIFY:
      return 0;
	
    case MEM:
      /* cheap - is encoded in addressing mode info! 

	 -- except for @(R0), which has to be @0(R0) !!! */

      if (GET_CODE (XEXP (addr, 0)) == REG)
	return 0;
	
      op=addr;
      goto indirection;
	
    case CONST_INT:
    case LABEL_REF:	       
    case CONST:
    case SYMBOL_REF:
      /* @#address - extra cost */
      return 0;

    case PLUS:
      /* X(R0) - extra cost */
      return 0;

    default:
      break;
    }
    
  return FALSE;
}

/* Return TRUE if op is a push or pop using the register "regno".  */
bool
pushpop_regeq (rtx op, int regno)
{
  rtx addr;

  /* False if not memory reference.  */
  if (GET_CODE (op) != MEM)
    return FALSE;

  /* Get the address of the memory reference.  */
  addr = XEXP (op, 0);

  if (GET_CODE (addr) == MEM)
    addr = XEXP (addr, 0);

  switch (GET_CODE (addr))
    {
    case PRE_DEC:
    case POST_INC:
    case PRE_MODIFY:
    case POST_MODIFY:
      return REGNO (XEXP (addr, 0)) == (unsigned) regno;
    default:
      return FALSE;
    }
}

/* This function checks whether a real value can be encoded as
   a literal, i.e., addressing mode 27.  In that mode, real values
   are one word values, so the remaining 48 bits have to be zero.  */
int
legitimate_const_double_p (rtx address)
{
  long sval[2];

  /* If it's too big for HOST_WIDE_INT, it's definitely to big here.  */
  if (GET_MODE (address) == VOIDmode)
    return 0;
  REAL_VALUE_TO_TARGET_DOUBLE (*CONST_DOUBLE_REAL_VALUE (address), sval);

  if ((sval[0] & 0xffff) == 0 && sval[1] == 0)
    return 1;
  return 0;
}

/* Implement TARGET_CAN_CHANGE_MODE_CLASS.  */
static bool
cpu16_can_change_mode_class (machine_mode from,
			     machine_mode to,
			     reg_class_t rclass)
{
  return false;
}

/* Implement TARGET_CXX_GUARD_TYPE */
static tree
cpu16_guard_type (void)
{
  return short_integer_type_node;
}

/* TARGET_PREFERRED_RELOAD_CLASS

   Given an rtx X being reloaded into a reg required to be
   in class CLASS, return the class of reg to actually use.
   In general this is just CLASS; but on some machines
   in some cases it is preferable to use a more restrictive class.  

*/

static reg_class_t
cpu16_preferred_reload_class (rtx x, reg_class_t rclass)
{
	return GENERAL_REGS;
}

/* TARGET_SECONDARY_RELOAD.

   FPU registers AC4 and AC5 (class NO_LOAD_FPU_REGS) require an 
   intermediate register (AC0-AC3: LOAD_FPU_REGS).  Everything else
   can be loaded/stored directly.  */
static reg_class_t 
cpu16_secondary_reload (bool in_p ATTRIBUTE_UNUSED,
			rtx x,
			reg_class_t reload_class,
			machine_mode reload_mode ATTRIBUTE_UNUSED,
			secondary_reload_info *sri ATTRIBUTE_UNUSED)
{
  return NO_REGS;
}

/* Implement TARGET_SECONDARY_MEMORY_NEEDED.

   The answer is yes if we're going between general register and FPU
   registers.  The mode doesn't matter in making this check.  */
static bool
cpu16_secondary_memory_needed (machine_mode, reg_class_t c1, reg_class_t c2)
{
  return false;
}

/* TARGET_LEGITIMATE_ADDRESS_P recognizes an RTL expression
   that is a valid memory address for an instruction.
   The MODE argument is the machine mode for the MEM expression
   that wants to use this address.

*/

static bool
cpu16_legitimate_address_p (machine_mode mode, rtx operand, bool strict,
			    code_helper = ERROR_MARK)
{
    rtx xfoob;

    /* accept @#address */
    if (CONSTANT_ADDRESS_P (operand))
      return true;
    
    switch (GET_CODE (operand))
      {
      case REG:
	/* accept (R0) */
	return !strict || REGNO_OK_FOR_BASE_P (REGNO (operand));
    
      case PLUS:
	/* accept X(R0) */
	return GET_CODE (XEXP (operand, 0)) == REG
	  && (!strict || REGNO_OK_FOR_BASE_P (REGNO (XEXP (operand, 0))))
	  && CONSTANT_ADDRESS_P (XEXP (operand, 1));

      case PRE_DEC:
	/* accept -(R0) */
	return GET_CODE (XEXP (operand, 0)) == REG
	  && (!strict || REGNO_OK_FOR_BASE_P (REGNO (XEXP (operand, 0))));

      case POST_INC:
	/* accept (R0)+ */
	return GET_CODE (XEXP (operand, 0)) == REG
	  && (!strict || REGNO_OK_FOR_BASE_P (REGNO (XEXP (operand, 0))));

      case PRE_MODIFY:
	/* accept -(SP) -- which uses PRE_MODIFY for byte mode */
	return GET_CODE (XEXP (operand, 0)) == REG
	  && REGNO (XEXP (operand, 0)) == STACK_POINTER_REGNUM
	  && GET_CODE ((xfoob = XEXP (operand, 1))) == PLUS
	  && GET_CODE (XEXP (xfoob, 0)) == REG
	  && REGNO (XEXP (xfoob, 0)) == STACK_POINTER_REGNUM
	  && CONST_INT_P (XEXP (xfoob, 1))
	  && INTVAL (XEXP (xfoob,1)) == -2;

      case POST_MODIFY:
	/* accept (SP)+ -- which uses POST_MODIFY for byte mode */
	return GET_CODE (XEXP (operand, 0)) == REG
	  && REGNO (XEXP (operand, 0)) == STACK_POINTER_REGNUM
	  && GET_CODE ((xfoob = XEXP (operand, 1))) == PLUS
	  && GET_CODE (XEXP (xfoob, 0)) == REG
	  && REGNO (XEXP (xfoob, 0)) == STACK_POINTER_REGNUM
	  && CONST_INT_P (XEXP (xfoob, 1))
	  && INTVAL (XEXP (xfoob,1)) == 2;

      case MEM:
	/* handle another level of indirection ! */
	xfoob = XEXP (operand, 0);

	/* (MEM:xx (MEM:xx ())) is not valid for SI, DI and currently
	   also forbidden for float, because we have to handle this 
	   in output_move_double and/or output_move_quad() - we could
	   do it, but currently it's not worth it!!! 
	   now that DFmode cannot go into CPU register file, 
	   maybe I should allow float ... 
	   but then I have to handle memory-to-memory moves in movdf ??  */
	if (GET_MODE_BITSIZE(mode) > 16)
	  return false;

	/* accept @address */
	if (CONSTANT_ADDRESS_P (xfoob))
	  return true;

	switch (GET_CODE (xfoob))
	  {
	  case REG:
	    /* accept @(R0) - which is @0(R0) */
	    return !strict || REGNO_OK_FOR_BASE_P(REGNO (xfoob));

	  case PLUS:
	    /* accept @X(R0) */
	    return GET_CODE (XEXP (xfoob, 0)) == REG
	      && (!strict || REGNO_OK_FOR_BASE_P (REGNO (XEXP (xfoob, 0))))
	      && CONSTANT_ADDRESS_P (XEXP (xfoob, 1));

	  case PRE_DEC:
	    /* accept @-(R0) */
	    return GET_CODE (XEXP (xfoob, 0)) == REG
	      && (!strict || REGNO_OK_FOR_BASE_P (REGNO (XEXP (xfoob, 0))));

	  case POST_INC:
	    /* accept @(R0)+ */
	    return GET_CODE (XEXP (xfoob, 0)) == REG
	      && (!strict || REGNO_OK_FOR_BASE_P (REGNO (XEXP (xfoob, 0))));

	  default:
	    /* anything else is invalid */
	    return false;
	  }

      default:
	/* anything else is invalid */
	return false;
      }
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

/* Return the regnums of the CC registers.  */
bool
cpu16_fixed_cc_regs (unsigned int *p1, unsigned int *p2)
{
  *p1 = CC_REGNUM;
  *p2 = FCC_REGNUM;
  return true;
}

/* A copy of output_addr_const modified for cpu16 expression syntax.
   output_addr_const also gets called for %cDIGIT and %nDIGIT, which we don't
   use, and for debugging output, which we don't support with this port either.
   So this copy should get called whenever needed.
*/
void
output_addr_const_cpu16 (FILE *file, rtx x)
{
  char buf[256];
  int i;
  
 restart:
  switch (GET_CODE (x))
    {
    case PC:
      gcc_assert (flag_pic);
      putc ('.', file);
      break;

    case SYMBOL_REF:
      assemble_name (file, XSTR (x, 0));
      break;

    case LABEL_REF:
      ASM_GENERATE_INTERNAL_LABEL (buf, "L", CODE_LABEL_NUMBER (XEXP (x, 0)));
      assemble_name (file, buf);
      break;

    case CODE_LABEL:
      ASM_GENERATE_INTERNAL_LABEL (buf, "L", CODE_LABEL_NUMBER (x));
      assemble_name (file, buf);
      break;

    case CONST_INT:
      i = INTVAL (x);
      if (i < 0)
	{
	  i = -i;
	  fprintf (file, "-");
	}
      if (TARGET_DEC_ASM)
	fprintf (file, "%o", i & 0xffff);
      else
	fprintf (file, "%#o", i & 0xffff);
      break;

    case CONST:
      output_addr_const_cpu16 (file, XEXP (x, 0));
      break;

    case PLUS:
      /* Some assemblers need integer constants to appear last (e.g. masm).  */
      if (GET_CODE (XEXP (x, 0)) == CONST_INT)
	{
	  output_addr_const_cpu16 (file, XEXP (x, 1));
	  if (INTVAL (XEXP (x, 0)) >= 0)
	    fprintf (file, "+");
	  output_addr_const_cpu16 (file, XEXP (x, 0));
	}
      else
	{
	  output_addr_const_cpu16 (file, XEXP (x, 0));
	  if (INTVAL (XEXP (x, 1)) >= 0)
	    fprintf (file, "+");
	  output_addr_const_cpu16 (file, XEXP (x, 1));
	}
      break;

    case MINUS:
      /* Avoid outputting things like x-x or x+5-x,
	 since some assemblers can't handle that.  */
      x = simplify_subtraction (x);
      if (GET_CODE (x) != MINUS)
	goto restart;

      output_addr_const_cpu16 (file, XEXP (x, 0));
      if (GET_CODE (XEXP (x, 1)) != CONST_INT
	  || INTVAL (XEXP (x, 1)) >= 0)
	fprintf (file, "-");
      output_addr_const_cpu16 (file, XEXP (x, 1));
      break;

    case ZERO_EXTEND:
    case SIGN_EXTEND:
      output_addr_const_cpu16 (file, XEXP (x, 0));
      break;

    default:
      output_operand_lossage ("invalid expression as operand");
    }
}

/* A copy of output_addr_const modified for cpu16 expression syntax.
   output_addr_const also gets called for %cDIGIT and %nDIGIT, which we don't
   use, and for debugging output, which we don't support with this port either.
   So this copy should get called whenever needed.
*/
void
output_addr_const_cpu16 (FILE *file, rtx x)
{
  char buf[256];
  int i;
  
 restart:
  switch (GET_CODE (x))
    {
    case PC:
      gcc_assert (flag_pic);
      putc ('.', file);
      break;

    case SYMBOL_REF:
      assemble_name (file, XSTR (x, 0));
      break;

    case LABEL_REF:
      ASM_GENERATE_INTERNAL_LABEL (buf, "L", CODE_LABEL_NUMBER (XEXP (x, 0)));
      assemble_name (file, buf);
      break;

    case CODE_LABEL:
      ASM_GENERATE_INTERNAL_LABEL (buf, "L", CODE_LABEL_NUMBER (x));
      assemble_name (file, buf);
      break;

    case CONST_INT:
      i = INTVAL (x);
      if (i < 0)
	{
	  i = -i;
	  fprintf (file, "-");
	}
      if (TARGET_DEC_ASM)
	fprintf (file, "%o", i & 0xffff);
      else
	fprintf (file, "%#o", i & 0xffff);
      break;

    case CONST:
      output_addr_const_cpu16 (file, XEXP (x, 0));
      break;

    case PLUS:
      /* Some assemblers need integer constants to appear last (e.g. masm).  */
      if (GET_CODE (XEXP (x, 0)) == CONST_INT)
	{
	  output_addr_const_cpu16 (file, XEXP (x, 1));
	  if (INTVAL (XEXP (x, 0)) >= 0)
	    fprintf (file, "+");
	  output_addr_const_cpu16 (file, XEXP (x, 0));
	}
      else
	{
	  output_addr_const_cpu16 (file, XEXP (x, 0));
	  if (INTVAL (XEXP (x, 1)) >= 0)
	    fprintf (file, "+");
	  output_addr_const_cpu16 (file, XEXP (x, 1));
	}
      break;

    case MINUS:
      /* Avoid outputting things like x-x or x+5-x,
	 since some assemblers can't handle that.  */
      x = simplify_subtraction (x);
      if (GET_CODE (x) != MINUS)
	goto restart;

      output_addr_const_cpu16 (file, XEXP (x, 0));
      if (GET_CODE (XEXP (x, 1)) != CONST_INT
	  || INTVAL (XEXP (x, 1)) >= 0)
	fprintf (file, "-");
      output_addr_const_cpu16 (file, XEXP (x, 1));
      break;

    case ZERO_EXTEND:
    case SIGN_EXTEND:
      output_addr_const_cpu16 (file, XEXP (x, 0));
      break;

    default:
      output_operand_lossage ("invalid expression as operand");
    }
}

/* Worker function for TARGET_RETURN_IN_MEMORY.  */

static bool
cpu16_return_in_memory (const_tree type, const_tree fntype ATTRIBUTE_UNUSED)
{
  /* Integers 32 bits and under, and scalar floats (if FPU), are returned
     in registers.  The rest go into memory.  */
  return (TYPE_MODE (type) == DImode
	  || (FLOAT_MODE_P (TYPE_MODE (type)) && ! TARGET_AC0)
	  || VECTOR_TYPE_P (type)
	  || COMPLEX_MODE_P (TYPE_MODE (type)));
}

/* Worker function for TARGET_FUNCTION_VALUE.

   On the cpu16 the value is found in R0 (or ac0??? not without FPU!!!! )  */

static rtx
cpu16_function_value (const_tree valtype, 
 		      const_tree fntype_or_decl ATTRIBUTE_UNUSED,
 		      bool outgoing ATTRIBUTE_UNUSED)
{
  return gen_rtx_REG (TYPE_MODE (valtype),
		      BASE_RETURN_VALUE_REG(TYPE_MODE(valtype)));
}

/* Worker function for TARGET_LIBCALL_VALUE.  */

static rtx
cpu16_libcall_value (machine_mode mode,
                     const_rtx fun ATTRIBUTE_UNUSED)
{
  return  gen_rtx_REG (mode, BASE_RETURN_VALUE_REG(mode));
}

/* Worker function for TARGET_FUNCTION_VALUE_REGNO_P.

   On the pdp, the first "output" reg is the only register thus used.

   maybe ac0 ? - as option someday!  */

static bool
cpu16_function_value_regno_p (const unsigned int regno)
{
  return regno == RETVAL_REGNUM;
}

/* Used for O constraint, matches if shift count is "small".  */
bool
cpu16_small_shift (int n)
{
  return (unsigned) n < 65536;
}

/* Expand a shift insn.  Returns true if the expansion was done,
   false if it needs to be handled by the caller.  */
bool
cpu16_expand_shift (rtx *operands, rtx (*shift_sc) (rtx, rtx, rtx),
		    rtx (*shift_base) (rtx, rtx, rtx))
{
  rtx r, test;
  rtx_code_label *lb;
  
  if (CONST_INT_P (operands[2]) && cpu16_small_shift (INTVAL (operands[2])))
    emit_insn ((*shift_sc) (operands[0], operands[1], operands[2]));
  else if (TARGET_40_PLUS)
    return false;
  else
    {
      lb = gen_label_rtx ();
      r = gen_reg_rtx (HImode);
      emit_move_insn (operands[0], operands[1]);
      emit_move_insn (r, operands[2]);
      if (!CONST_INT_P (operands[2]))
	{
	  test = gen_rtx_LE (HImode, r, const0_rtx);
	  emit_jump_insn (gen_cbranchhi4 (test, r, const0_rtx, lb));
	}
      /* It would be nice to expand the loop here, but that's not
	 possible because shifts may be generated by the loop unroll
	 optimizer and it doesn't appreciate flow changes happening
	 while it's doing things.  */
      emit_insn ((*shift_base) (operands[0], operands[1], r));
      if (!CONST_INT_P (operands[2]))
	{
	  emit_label (lb);

	  /* Allow REG_NOTES to be set on last insn (labels don't have enough
	     fields, and can't be used for REG_NOTES anyway).  */
	  emit_use (stack_pointer_rtx);
	}
    }
  return true;
}

/* Emit the instructions needed to produce a shift by a small constant
   amount (unrolled), or a shift made from a loop for the base machine
   case.  */
const char *
cpu16_assemble_shift (rtx *operands, machine_mode m, int code)
{
  int i, n;
  rtx inops[2];
  rtx exops[2][2];
  rtx lb[1];
  cpu16_action action[2];
  const bool small = CONST_INT_P (operands[2]) && cpu16_small_shift (INTVAL (operands[2]));

  gcc_assert (small || !TARGET_40_PLUS);

  if (m == E_SImode)
    {
      inops[0] = operands[0];
      cpu16_expand_operands (inops, exops, 1, 2, action, either);
    }
  
  if (!small)
    {
      /* Loop case, generate the top of loop label.  */
      lb[0] = gen_label_rtx ();
      output_asm_label (lb[0]);
      fputs (":\n", asm_out_file);
      n = 1;
    }
  else
    n = INTVAL (operands[2]);
  if (code == LSHIFTRT)
    {
      output_asm_insn ("clc", NULL);
      switch (m)
	{
	case E_QImode:
	  output_asm_insn ("rorb\t%0", operands);
	  break;
	case E_HImode:
	  output_asm_insn ("ror\t%0", operands);
	  break;
	case E_SImode:
	  output_asm_insn ("ror\t%0", exops[0]);
	  output_asm_insn ("ror\t%0", exops[1]);
	  break;
	default:
	  gcc_unreachable ();
	}
      n--;
    }
  for (i = 0; i < n; i++)
    {
      switch (code)
	{
	case LSHIFTRT:
	case ASHIFTRT:
	  switch (m)
	    {
	    case E_QImode:
	      output_asm_insn ("asrb\t%0", operands);
	      break;
	    case E_HImode:
	      output_asm_insn ("asr\t%0", operands);
	      break;
	    case E_SImode:
	      output_asm_insn ("asr\t%0", exops[0]);
	      output_asm_insn ("ror\t%0", exops[1]);
	      break;
	    default:
	      gcc_unreachable ();
	    }
	  break;
	case ASHIFT:
	  switch (m)
	    {
	    case E_QImode:
	      output_asm_insn ("aslb\t%0", operands);
	      break;
	    case E_HImode:
	      output_asm_insn ("asl\t%0", operands);
	      break;
	    case E_SImode:
	      output_asm_insn ("asl\t%0", exops[1]);
	      output_asm_insn ("rol\t%0", exops[0]);
	      break;
	    default:
	      gcc_unreachable ();
	    }
	  break;
	}
    }
  if (!small)
    {
      /* Loop case, emit the count-down and branch if not done.  */
      output_asm_insn ("dec\t%2", operands);
      output_asm_insn ("bne\t%l0", lb);
    }
  return "";
}

/* Figure out the length of the instructions that will be produced for
   the given operands by cpu16_assemble_shift above.  */
int
cpu16_shift_length (rtx *operands, machine_mode m, int code, bool simple_operand_p)
{
  int shift_size;

  /* Shift by 1 is 2 bytes if simple operand, 4 bytes if 2-word addressing mode.  */
  shift_size = simple_operand_p ? 2 : 4;

  /* In SImode, two shifts are needed per data item.  */
  if (m == E_SImode)
    shift_size *= 2;

  /* If shifting by a small constant, the loop is unrolled by the
     shift count.  Otherwise, account for the size of the decrement
     and branch.  */
  if (CONST_INT_P (operands[2]) && cpu16_small_shift (INTVAL (operands[2])))
    shift_size *= INTVAL (operands[2]);
  else
    shift_size += 4;

  /* Logical right shift takes one more instruction (CLC).  */
  if (code == LSHIFTRT)
    shift_size += 2;

  return shift_size;
}

/* Return the length of 2 or 4 word integer compares.  */
int
cpu16_cmp_length (rtx *operands, int words)
{
  rtx inops[2];
  rtx exops[4][2];
  int i, len = 0;

  if (!reload_completed)
    return 2;

  inops[0] = operands[0];
  inops[1] = operands[1];

  cpu16_expand_operands (inops, exops, 2, words, NULL, big);

  for (i = 0; i < words; i++)
    {
      len += 4;    /* cmp instruction word and branch that follows.  */
      if (!REG_P (exops[i][0]) &&
	  !simple_memory_operand (exops[i][0], HImode))
	len += 2;  /* first operand extra word.  */
      if (!REG_P (exops[i][1]) &&
	  !simple_memory_operand (exops[i][1], HImode) &&
	  !(CONST_INT_P (exops[i][1]) && INTVAL (exops[i][1]) == 0))
	len += 2;  /* second operand extra word.  */
    }

  /* Deduct one word because there is no branch at the end.  */
  return len - 2;
}

/* Prepend to CLOBBERS hard registers that are automatically clobbered
   for an asm We do this for CC_REGNUM and FCC_REGNUM (on FPU target)
   to maintain source compatibility with the original cc0-based
   compiler.  */

static rtx_insn *
cpu16_md_asm_adjust (vec<rtx> & /*outputs*/, vec<rtx> & /*inputs*/,
		     vec<machine_mode> & /*input_modes*/,
		     vec<const char *> & /*constraints*/,
		     vec<rtx> &/*uses*/, vec<rtx> &clobbers,
		     HARD_REG_SET &clobbered_regs, location_t /*loc*/)
{
  clobbers.safe_push (gen_rtx_REG (CCmode, CC_REGNUM));
  SET_HARD_REG_BIT (clobbered_regs, CC_REGNUM);
  if (TARGET_FPU)
    {
      clobbers.safe_push (gen_rtx_REG (CCmode, FCC_REGNUM));
      SET_HARD_REG_BIT (clobbered_regs, FCC_REGNUM);
    }
  return NULL;
}

/* Worker function for TARGET_TRAMPOLINE_INIT.

   trampoline - how should i do it in separate i+d ? 
   have some allocate_trampoline magic??? 

   the following should work for shared I/D:

   MOV	#STATIC, $4	01270Y	0x0000 <- STATIC; Y = STATIC_CHAIN_REGNUM
   JMP	@#FUNCTION	000137  0x0000 <- FUNCTION
*/
static void
cpu16_trampoline_init (rtx m_tramp, tree fndecl, rtx chain_value)
{
  rtx fnaddr = XEXP (DECL_RTL (fndecl), 0);
  rtx mem;

  gcc_assert (!TARGET_SPLIT);

  mem = adjust_address (m_tramp, HImode, 0);
  emit_move_insn (mem, GEN_INT (012700+STATIC_CHAIN_REGNUM));
  mem = adjust_address (m_tramp, HImode, 2);
  emit_move_insn (mem, chain_value);
  mem = adjust_address (m_tramp, HImode, 4);
  emit_move_insn (mem, GEN_INT (000137));
  emit_move_insn (mem, fnaddr);
}

/* Worker function for TARGET_FUNCTION_ARG.  */

static rtx
cpu16_function_arg (cumulative_args_t, const function_arg_info &)
{
  return NULL_RTX;
}

/* Worker function for TARGET_FUNCTION_ARG_ADVANCE.

   Update the data in CUM to advance over argument ARG.  */

static void
cpu16_function_arg_advance (cumulative_args_t cum_v,
			    const function_arg_info &arg)
{
  CUMULATIVE_ARGS *cum = get_cumulative_args (cum_v);

  *cum += arg.promoted_size_in_bytes ();
}

/* Make sure everything's fine if we *don't* have an FPU.
   This assumes that putting a register in fixed_regs will keep the
   compiler's mitts completely off it.  We don't bother to zero it out
   of register classes.  Also fix incompatible register naming with
   the UNIX assembler.  */

static void
cpu16_conditional_register_usage (void)
{
  int i;
  HARD_REG_SET x;
  if (!TARGET_FPU)
    {
      x = reg_class_contents[FPU_REGS];
      for (i = 0; i < FIRST_PSEUDO_REGISTER; i++ )
       if (TEST_HARD_REG_BIT (x, i))
	fixed_regs[i] = call_used_regs[i] = 1;
    }

  if (TARGET_AC0)
      call_used_regs[AC0_REGNUM] = 1;
  if (TARGET_UNIX_ASM)
    {
      /* Change names of FPU registers for the UNIX assembler.  */
      reg_names[8] = "fr0";
      reg_names[9] = "fr1";
      reg_names[10] = "fr2";
      reg_names[11] = "fr3";
      reg_names[12] = "fr4";
      reg_names[13] = "fr5";
    }
}

static section *
cpu16_function_section (tree decl ATTRIBUTE_UNUSED,
			enum node_frequency freq ATTRIBUTE_UNUSED,
			bool startup ATTRIBUTE_UNUSED,
			bool exit ATTRIBUTE_UNUSED)
{
  return NULL;
}

/* Support #ident for DEC assembler, but don't process the
   auto-generated ident string that names the compiler (since its
   syntax is not correct for DEC .ident).  */
static void cpu16_output_ident (const char *ident)
{
  if (TARGET_DEC_ASM)
    {
      if (!startswith (ident, "GCC:"))
	fprintf (asm_out_file, "\t.ident\t\"%s\"\n", ident);
    }
  
}

/* This emits a (user) label, which gets a "_" prefix except for DEC
   assembler output.  */
void
cpu16_output_labelref (FILE *file, const char *name)
{
  if (!TARGET_DEC_ASM)
    fputs (USER_LABEL_PREFIX, file);
  fputs (name, file);
}

/* This equates name with value.  */
void
cpu16_output_def (FILE *file, const char *label1, const char *label2)
{
  if (TARGET_DEC_ASM)
    {
      assemble_name (file, label1);
      putc ('=', file);
      assemble_name (file, label2);
    }
  else
    {
      fputs ("\t.set\t", file);
      assemble_name (file, label1);
      putc (',', file);
      assemble_name (file, label2);
    } 
  putc ('\n', file);
}

void
cpu16_output_addr_vec_elt (FILE *file, int value)
{
  char buf[256];

  cpu16_gen_int_label (buf, "L", value);
  if (!TARGET_UNIX_ASM)
    fprintf (file, "\t.word");
  fprintf (file, "\t%s\n", buf + 1);
}

/* This overrides some target hooks that are initializer elements so
   they can't be variables in the #define.  */
static void
cpu16_option_override (void)
{
  if (TARGET_DEC_ASM)
    {
      targetm.asm_out.open_paren  = "<";
      targetm.asm_out.close_paren = ">";
    }
}

static void
cpu16_asm_named_section (const char *name, unsigned int flags,
			 tree decl ATTRIBUTE_UNUSED)
{
  const char *rwro = (flags & SECTION_WRITE) ? "rw" : "ro";
  const char *insdat = (flags & SECTION_CODE) ? "i" : "d";
  
  gcc_assert (TARGET_DEC_ASM);
  fprintf (asm_out_file, "\t.psect\t%s,con,%s,%s\n", name, insdat, rwro);
}

static void
cpu16_asm_init_sections (void)
{
  if (TARGET_DEC_ASM)
    {
      bss_section = data_section;
    }
  else if (TARGET_GNU_ASM)
    {
      bss_section = get_unnamed_section (SECTION_WRITE | SECTION_BSS,
					 output_section_asm_op,
					 ".bss");
    }
}
  
static void
cpu16_file_start (void)
{
  default_file_start ();
  
  if (TARGET_DEC_ASM)
    fprintf (asm_out_file, "\t.enabl\tlsb,reg\n\n");
}

static void
cpu16_file_end (void)
{
  if (TARGET_DEC_ASM)
    fprintf (asm_out_file, "\t.end\n");
}

/* Implement TARGET_LEGITIMATE_CONSTANT_P.  */

static bool
cpu16_legitimate_constant_p (machine_mode mode ATTRIBUTE_UNUSED, rtx x)
{
  return GET_CODE (x) != CONST_DOUBLE || legitimate_const_double_p (x);
}

/* Implement TARGET_SCALAR_MODE_SUPPORTED_P.  */

static bool
cpu16_scalar_mode_supported_p (scalar_mode mode)
{
  /* Support SFmode even with -mfloat64.  */
  if (mode == SFmode)
    return true;
  return default_scalar_mode_supported_p (mode);
}

/* Implement TARGET_HARD_REGNO_NREGS.  */

static unsigned int
cpu16_hard_regno_nregs (unsigned int regno, machine_mode mode)
{
  if (regno <= PC_REGNUM)
    return CEIL (GET_MODE_SIZE (mode), UNITS_PER_WORD);
  return 1;
}

/* Implement TARGET_HARD_REGNO_MODE_OK.  On the pdp, the cpu registers
   can hold any mode other than float (because otherwise we may end up
   being asked to move from CPU to FPU register, which isn't a valid
   operation on the cpu16).  For CPU registers, check alignment.

   FPU accepts SF and DF but actually holds a DF - simplifies life!  */

static bool
cpu16_hard_regno_mode_ok (unsigned int regno, machine_mode mode)
{
  if (regno <= PC_REGNUM)
    return (GET_MODE_BITSIZE (mode) <= 16
	    || (GET_MODE_BITSIZE (mode) >= 32
		&& !(regno & 1)
		&& !FLOAT_MODE_P (mode)));

  return FLOAT_MODE_P (mode);
}

/* Implement TARGET_MODES_TIEABLE_P.  */

static bool
cpu16_modes_tieable_p (machine_mode mode1, machine_mode mode2)
{
  return mode1 == HImode && mode2 == QImode;
}

struct gcc_target targetm = TARGET_INITIALIZER;
