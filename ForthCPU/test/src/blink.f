hex FFFF constant PORT

(
  push 0
begin:
  dup
  push PORT
  set
  push 1
  +
  jmp begin
)

: main 0 begin dup PORT ! 1 + again ;

