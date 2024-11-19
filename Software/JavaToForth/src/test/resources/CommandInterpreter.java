import JavaCPU.Console;
import JavaCPU.Hal;

public final class CommandInterpreter {
    private static Command[] commands;
    private static final int[] commandParts = new int[10];
    private static int partsCount;

    public static void setCommands(Command[] commands) {
        CommandInterpreter.commands = commands;
    }

    public static void run(char[] buffer, int length) {
        if (length == 0)
            return;
        splitCommand(buffer, length);
        printCommandParts(buffer);
        for (var command: commands) {
            if (command.run(buffer, commandParts, partsCount))
                return;
        }
        Console.println("unknown command");
    }

    private static void printCommandParts(char[] buffer) {
        for (var i = 0; i < partsCount; i++) {
            var p = commandParts[i];
            printCommandPart(buffer, p & 0xFFFF, p >> 16);
        }
    }

    private static void printCommandPart(char[] buffer, int index, int length) {
        for (var i = 0; i < length; i++)
            Hal.outChar(buffer[index++]);
        Hal.outChar('\r');
        Hal.outChar('\n');
    }

    private static void splitCommand(char[] buffer, int pos) {
        partsCount = 0;
        var start = false;
        int currentPart = 0, currentPartLength = 0;
        for (var i = 0; i < pos; i++) {
            var c = buffer[i];
            if (c > ' ') {
                if (!start) {
                    start = true;
                    currentPart = i;
                    currentPartLength = 1;
                }
                else
                    currentPartLength++;
            } else if (start) {
                start = false;
                commandParts[partsCount++] = currentPart | (currentPartLength << 16);
            }
        }
        if (start)
            commandParts[partsCount++] = currentPart | (currentPartLength << 16);
    }
}
