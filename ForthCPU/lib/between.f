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
