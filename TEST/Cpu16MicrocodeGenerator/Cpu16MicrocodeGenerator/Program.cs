const int microcodeMask = 0xFFFF;
const int microcodeLength = 512;

var r = new Random();

for (var i = 0; i < microcodeLength; i++)
{
    var v = r.Next(microcodeMask);
    Console.WriteLine("{0:X4}", v);
}
