while (<>) {
  @line = split('\t',$_);
  $pin = $line[0];
  $pin =~ s/ //g;
  $name = $line[1];
  $name =~ s/ //g;
  $name =~ s/\r//g;
  $name =~ s/\n//g;
  $name = lc($name);
  print "LOCATE COMP \"sdram_$name\" SITE \"$pin\";\n";
  print "IOBUF PORT \"sdram_$name\" IO_TYPE=LVCMOS33 DRIVE=4;\n";
}