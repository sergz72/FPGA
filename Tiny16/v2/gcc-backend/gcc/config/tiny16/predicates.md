;; Predicate definitions for Tiny16
;; Copyright (C) 2009-2024 Free Software Foundation, Inc.

;; This file is part of GCC.

;; GCC is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.

;; GCC is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GCC; see the file COPYING3.  If not see
;; <http://www.gnu.org/licenses/>.

;; -------------------------------------------------------------------------
;; Predicates
;; -------------------------------------------------------------------------

;; Nonzero if OP can be source of a simple move operation.

(define_predicate "tiny16_general_movsrc_operand"
  (match_code "mem,const_int,reg,subreg,symbol_ref,label_ref,const")
{
  /* Any (MEM LABEL_REF) is OK.  That is a pc-relative load.  */
  if (MEM_P (op) && GET_CODE (XEXP (op, 0)) == LABEL_REF)
    return 1;

  if (MEM_P (op)
      && GET_CODE (XEXP (op, 0)) == PLUS
      && GET_CODE (XEXP (XEXP (op, 0), 0)) == REG
      && GET_CODE (XEXP (XEXP (op, 0), 1)) == CONST_INT
      && IN_RANGE (INTVAL (XEXP (XEXP (op, 0), 1)), -32768, 32767))
    return 1;

  return general_operand (op, mode);
})

;; Nonzero if OP can be an operand to an add/inc/dec instruction.

(define_predicate "tiny16_add_operand"
  (ior (match_code "reg")
       (and (match_code "const_int")
	    (match_test "IN_RANGE (INTVAL (op), -255, 255)"))))

;; Nonzero if OP can be an operand to an sub/dec instruction.

(define_predicate "tiny16_sub_operand"
  (ior (match_code "reg")
       (and (match_code "const_int")
	    (match_test "IN_RANGE (INTVAL (op), 0, 255)"))))