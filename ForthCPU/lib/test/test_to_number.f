"1234" sconstant s1
"ABCD" sconstant s2
"abcd" sconstant s3
"q" sconstant s4
"1q" sconstant s5
"" sconstant s6

: isr1 ;
: isr2 ;

: main
  hex
  s1 h>number if0 hlt then
  1234 != if hlt then
  s2 h>number if0 hlt then
  abcd != if hlt then
  s3 h>number if0 hlt then
  abcd != if hlt then
  s4 h>number if hlt then
  s5 h>number if hlt then
  s6 h>number if hlt then
  decimal
  s1 >number if0 hlt then
  1234 != if hlt then
  wfi
;
