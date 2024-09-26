;;- Machine description for the cpu16 for GNU C compiler
;; Copyright (C) 1994-2024 Free Software Foundation, Inc.

;; This file is part of GCC.

;; GCC is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GCC is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GCC; see the file COPYING3.  If not see
;; <http://www.gnu.org/licenses/>.

(include "predicates.md")
(include "constraints.md")

(define_constants
  [
   (RETVAL_REGNUM     	  0)
   (ARG_POINTER_REGNUM  254)
   (FRAME_POINTER_REGNUM  255)
   (STACK_POINTER_REGNUM  256)
   ;; End of hard registers
   (FIRST_PSEUDO_REGISTER 257)
  ])

;; Prologue and epilogue support.

(define_expand "prologue"
  [(const_int 0)]
  ""
{
  cpu16_expand_prologue ();
  DONE;
})

(define_expand "epilogue"
  [(const_int 0)]
  ""
{
  cpu16_expand_epilogue ();
  DONE;
})

;; length default is 2 bytes each
(define_attr "length" "" (const_int 2))

;; instruction base cost (not counting operands)
(define_attr "base_cost" "" (const_int 2))

;; -------------------------------------------------------------------------
;; nop instruction
;; -------------------------------------------------------------------------

(define_insn "nop"
  [(const_int 0)]
  ""
  "nop")
