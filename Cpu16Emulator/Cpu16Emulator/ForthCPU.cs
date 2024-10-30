namespace Cpu16Emulator;

public class ForthCPU(string[] code, int speed): Cpu(code, speed, 0)
{
    protected override ushort? IsCall(uint instruction)
    {
        return null;
    }
}