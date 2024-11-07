"1234" sconstant s1
"12345" sconstant s2
"1234" sconstant s3
"" sconstant s4
"1" sconstant s5
"" sconstant s6

: isr1 ;
: isr2 ;

hex
: main
  s1 s2 compare if0 hlt then
  s1 s3 compare if hlt then
  s4 s5 compare if0 hlt then
  s4 s6 compare if hlt then
  wfi
;
