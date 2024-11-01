: read4 dup command_read_p @ @ dup is_hex if
  else
    0
  then
;

: ram_test 
  command_p @ command_read_p @ - 8 = if
    address read4 if
      length read4 if
        ok
      else
        err
      then
    else
      err
    then
  else
    err
  then
;
