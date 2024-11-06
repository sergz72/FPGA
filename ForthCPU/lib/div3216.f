hex 8000 constant DIV3216_AND decimal

\ FUNCTION DEF: Div3216
\ DESCRIPTION:  unsigned 32/16 division, dividend_hi dividend_lo divisor > result_hi result_lo remainder
: div3216
  locals hi,lo,divisor,rem,c,c2

  divisor! lo! hi!

\ Step-1: First the registers are initialized with corresponding values (Q = Dividend, M = Divisor, A = 0, n = number of bits in dividend)
  0 rem!
  32 0 do

\ Step-2: Then the content of register A and Q is shifted left as if they are a single unit
  lo@ DIV3216_AND and if 1 else 0 then c!
  lo@ 1 lshift lo!
  hi@ DIV3216_AND and if 1 else 0 then c2!
  hi@ 1 lshift c@ or hi!
  rem@ 1 lshift c2@ or rem!

\ Step-3: Then content of register M is subtracted from A and result is stored in C
  rem@ divisor@ - dup
\ Step-4: Then the most significant bit of the C is checked if it is 0 the least significant bit of Q is set to 1 and A = C otherwise
\ if it is 1 the least significant bit of Q is set to 0
  DIV3216_AND and if0 lo@ 1 or lo! rem! else drop then

  loop

  hi@ lo@ rem@
;
