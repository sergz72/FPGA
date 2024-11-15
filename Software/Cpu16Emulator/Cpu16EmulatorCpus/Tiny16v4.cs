namespace Cpu16EmulatorCpus;

public class Tiny16v4(string[] code, int speed): Cpu(code, speed, 4)
{
    protected override uint? IsCall(uint instruction)
    {
        return null;
    }
}