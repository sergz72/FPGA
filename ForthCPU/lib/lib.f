'A' 10 - constant is_hex_A10
'a' 10 - constant is_hex_a10

: cr '\r' emit '\n' emit ;
: space 32 emit ;
: err 'E' emit cr ;
: ok 'K' emit cr ;

\ shows hex digit
: hex_out
  hex F and decimal
  dup 9 > if A10 else '0' then
  + emit
;

\ shows hex number
: h.
  dup 12 rshift hex_out
  dup 8 rshift hex_out
  dup 4 rshift hex_out
  hex_out
;

\ shows string
: s.
  dup \ s s
  @ dup \ s l l
  if \ s l
    0 do \ s
      1 +
      dup @ emit 
    loop
  else
    drop drop
  then
;

\ v v1 v2 -> 1/0
: between
  rot \ v1 v2 v
  dup \ v1 v2 v v
  rot \ v1 v v v2
  > if \ v1 v
    drop drop 0
  else
    <=
  then
;

\ s1 s2 -> 0/1
: compare
  locals s1,s2
  s2! s1!
  s1@ @ s2@ @ != if 1 else \ compare string lengths
    s1@ @ if \ if string length > 0
      s1@ @ 0 do
        s1@ 1 + s1!
        s2@ 1 + s2!
        s1@ @ s2@ @ != if 1 exit then \ compare characters
      loop
    then
    0
  then
;

\ FUNCTION DEF: Div3216
\ DESCRIPTION:  unsigned 32/16 division, dividend_hi dividend_lo divisor > result_hi result_lo remainder
: div3216
  locals hi,lo,divisor,rem,c,c2

  divisor! lo! hi!

\ Step-1: First the registers are initialized with corresponding values (Q = Dividend, M = Divisor, A = 0, n = number of bits in dividend)
  0 rem!
  32 0 do

\ Step-2: Then the content of register A and Q is shifted left as if they are a single unit
  lo@ 15 bit? c!
  lo@ 1 lshift lo!
  hi@ 15 bit? c2!
  hi@ 1 lshift c@ or hi!
  rem@ 1 lshift c2@ or rem!

\ Step-3: Then content of register M is subtracted from A and result is stored in C
  rem@ divisor@ - dup
\ Step-4: Then the most significant bit of the C is checked if it is 0 the least significant bit of Q is set to 1 and A = C otherwise
\ if it is 1 the least significant bit of Q is set to 0
  15 bit? if0 lo@ 1 or lo! rem! else drop then

  loop

  hi@ lo@ rem@
;

\ char -> num (-1 if is not hex)
: is_hex dup '0' '9' between if
  '0' -
  else
    dup
    'A' 'F' between if
      is_hex_A10 -
    else
      dup
      'a' 'f' between if
        is_hex_a10 -
      else
        drop -1
      then
    then
  then
;

\ converts hex number string to number
\ string -> num 1 OR 0
: h>number
  locals r

  0 r!
  dup @ dup \ s l l
  if \ s l
    0 do \ s
      1 + dup @ \ s c
      is_hex dup \ s n n
      -1 = if drop drop 0 exit then
      r@ 4 lshift + r!
    loop
    drop r@ 1
  then
;

\ converts decimal number string to number
\ string -> num 1 OR 0
: >number
  locals r

  0 r!
  dup @ dup \ s l l
  if \ s l
    0 do \ s
      1 + dup @ \ s c
      is_hex dup \ s n n
      -1 = if drop drop 0 exit then
      r@ 10 * + r!
    loop
    drop r@ 1
  then
;
