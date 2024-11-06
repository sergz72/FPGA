'A' 10 - constant A10
'a' 10 - constant a10

: is_hex dup '0' '9' between if
  '0' -
  else
    dup
    'A' 'F' between if
      A10 -
    else
      dup
      'a' 'f' between if
        a10 -
      else
        drop -1
      then
    then
  then
;
