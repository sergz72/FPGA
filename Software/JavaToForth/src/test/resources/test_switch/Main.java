package test_switch;

import JavaCPU.Console;
import JavaCPU.System;

public class Main {
    public static void isr1() {
    }

    public static void isr2() {
    }

    private static int test(int v) {
        switch (v) {
            case 1:
                return 4;
            case 20:
                return 9;
            case 39:
                return 15;
            default:
                return 22;
        }
    }

    public static void main() {
        if (test(1) != 4) {
            Console.println("1");
            System.hlt();
        }
        if (test(20) != 9) {
            Console.println("20");
            System.hlt();
        }
        if (test(39) != 15) {
            Console.println("39");
            System.hlt();
        }
        if (test(4) != 22) {
            Console.println("4");
            System.hlt();
        }
        if (System.getStackPointer() != 0) {
            Console.println("@sp");
            System.hlt();
        }
        Console.println("OK");
        System.wfi();
    }
}
