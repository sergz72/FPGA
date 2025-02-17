import JavaCPU.Hal;
import JavaCPU.System;
import command_interpreter.CommandInterpreter;
import command_interpreter.ICommand;
import commands.I2CTest;
import i2c.I2CMaster;

class UartEchoWithoutTimer {
    private static final int DELAY = 500 * Hal.MS;
    private static final int UART_BUFFER_SIZE = 128;
    private static final I2CMaster i2c = new I2CMaster(Hal.I2C_ADDRESS);
    private static final ICommand[] commands = new ICommand[] {new I2CTest(i2c, new int[]{1,2}, 2)};

    private static volatile boolean commandReady;
    private static char[] command;
    private static int commandPointer, commandReadPointer;
    
    public static void isr1() {
    }

    public static void isr2() {
        char c = (char)(Hal.uartGet() & 0xFF);
        if (commandReady)
            return;
        if (c == '\r') {
            commandReady = true;
            return;
        }
        if (commandPointer < command.length) {
            command[commandPointer++] = c;
        }
    }

    private static void uartEcho() {
        while (commandReadPointer < commandPointer)
            Hal.outChar(command[commandReadPointer++]);
    }

    public static void main() {
        command = new char[UART_BUFFER_SIZE];
        commandReady = false;
        commandPointer = commandReadPointer = 0;
        boolean ledState = false;
        CommandInterpreter.setCommands(commands);
        Hal.timerStart(DELAY);
        while (true) {
            System.wfi();
            uartEcho();
            Hal.timerStart(DELAY);
            Hal.ledSet(ledState);
            ledState = !ledState;
            if (commandReady) {
                Hal.outChar('\r');
                Hal.outChar('\n');
                CommandInterpreter.run(command, commandPointer);
                commandPointer = commandReadPointer = 0;
                commandReady = false;
            }
        }
    }
}    
