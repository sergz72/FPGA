namespace Cpu16Emulator;

public class Tiny16v4(string[] code, int speed): Cpu(code, speed, 4)
{
    protected override ushort? IsCall(uint instruction)
    {
        return null;
    }
}