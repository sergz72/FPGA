package commands;

import command_interpreter.ICommand;
import JavaCPU.Console;
import JavaCPU.Hal;
import i2c.I2CMaster;

public final class I2CTest implements ICommand {
    private final I2CMaster i2c;
    private final int[] knownDevices;
    private final int channels;

    public I2CTest(I2CMaster i2c, int[] knownDevices, int channels) {
        this.i2c = i2c;
        this.knownDevices = knownDevices;
        this.channels = channels;
    }
    
    public String getName() { return "i2c_test"; }
    public int minParameters() { return 0; }
    public int maxParameters() { return 0; }
    public void init() {}
    public boolean validateParameter(int parameterNo, char[] buffer, int pos, int l) { return false; }
    
    public boolean run() {
        for (var channel = 0; channel < channels; channel++) {
            var found = false;
            Console.printDecimal(channel);
            Hal.outChar(':');
            Hal.outChar(' ');
            for (var d : knownDevices) {
                if (i2c.check(channel, d)) {
                    Console.printHex(d);
                    Console.cr();
                    found = true;
                    break;
                }
            }
            if (!found) {
                Console.println("no devices");
            }
        }
        return true;
    };
}
