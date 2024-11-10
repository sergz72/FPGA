: isr1 ;
: isr2 ;

: word1 1 ;
: word2 2 ;
: word3 3 ;

: word_with_locals
  locals a,b
  a! b!
  a@ b@ -
;

: main word1 word2 word3
  3 != if hlt then
  2 != if hlt then
  1 != if hlt then
  2 3 word_with_locals
  1 != if hlt then
  sp@ if hlt then
  wfi
;
