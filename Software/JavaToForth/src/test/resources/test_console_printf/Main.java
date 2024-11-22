package test_console_printf;

import JavaCPU.Console;
import JavaCPU.System;
import JavaCPU.Hal;

public class Main {
    public static void isr1() {
    }

    public static void isr2() {
    }

    public static void main() {
        Console.printDecimal(0);
        Hal.outChar('\r'); Hal.outChar('\n');
        Console.printDecimal(123);
        Hal.outChar('\r'); Hal.outChar('\n');
        Console.printDecimal(-1);
        Hal.outChar('\r'); Hal.outChar('\n');
        Console.printHex(0);
        Hal.outChar('\r'); Hal.outChar('\n');
        Console.printHex(123);
        Hal.outChar('\r'); Hal.outChar('\n');
        Console.printHex(-1);
        Hal.outChar('\r'); Hal.outChar('\n');
        System.hlt();
    }
}
