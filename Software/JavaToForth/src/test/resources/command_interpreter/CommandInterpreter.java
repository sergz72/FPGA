package command_interpreter;

import JavaCPU.Console;
import JavaCPU.System;
import JavaCPU.Hal;

public final class CommandInterpreter {
    private static ICommand[] commands;
    private static final int[] commandParts = new int[10];
    private static int partsCount;

    public static void setCommands(ICommand[] commands) {
        CommandInterpreter.commands = commands;
    }

    public static void run(char[] buffer, int length) {
        if (length == 0)
            return;
        splitCommand(buffer, length);
        if (partsCount == 0)
            return;
        //printCommandParts(buffer);
        for (var command: commands) {
            if (!System.stringEquals(command.getName(), buffer, commandParts[0] & 0xFFFF, commandParts[0] >> 16))
                continue;
            var pCount = partsCount - 1;
            if (pCount < command.minParameters() || pCount > command.maxParameters()) {
                Console.println("wrong number of parameters");
                return;
            }
            command.init();
            for (var i = 1; i < partsCount; i++) {
                if (!command.validateParameter(i, buffer,  commandParts[i] & 0xFFFF, commandParts[i] >> 16)) {
                    Console.print("incorrect parameter ");
                    Console.printDecimal(i);
                    Console.cr();
                    return;
                }
            }
            if (command.run())
                Console.println("OK");
            return;
        }
        Console.println("unknown command");
    }

    /*private static void printCommandParts(char[] buffer) {
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
    }*/

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
