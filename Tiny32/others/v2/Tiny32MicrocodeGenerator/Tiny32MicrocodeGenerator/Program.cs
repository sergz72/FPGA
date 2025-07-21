using Tiny32MicrocodeGenerator;

var mul = false;
var div = false;

foreach (var arg in args)
{
    if (arg == "MUL")
        mul = true;
    if (arg == "DIV")
        div = true;
}

DecoderCodeGenerator.GenerateCode(mul, div);
new MicrocodeGenerator().GenerateCode();