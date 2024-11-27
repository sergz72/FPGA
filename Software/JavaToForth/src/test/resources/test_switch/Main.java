package test_switch;

import JavaCPU.Console;
import JavaCPU.System;

public class Main {
    public static void isr1() {
    }

    public static void isr2() {
    }

    private static int testLookupSwitch(int v) {
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

    private static int testTableSwitch(int v) {
        switch (v) {
            case 1:
                return 4;
            case 2:
                return 9;
            case 3:
                return 15;
            default:
                return 22;
        }
    }

    public static void main() {
        if (testLookupSwitch(1) != 4) {
            Console.println("l1");
            System.hlt();
        }
        if (testLookupSwitch(20) != 9) {
            Console.println("l20");
            System.hlt();
        }
        if (testLookupSwitch(39) != 15) {
            Console.println("l39");
            System.hlt();
        }
        if (testLookupSwitch(4) != 22) {
            Console.println("l4");
            System.hlt();
        }
        if (System.getStackPointer() != 0) {
            Console.println("@lsp");
            System.hlt();
        }

        if (testTableSwitch(0) != 22) {
            Console.println("t0");
            System.hlt();
        }
        if (testTableSwitch(1) != 4) {
            Console.println("t1");
            System.hlt();
        }
        if (testTableSwitch(2) != 9) {
            Console.println("t2");
            System.hlt();
        }
        if (testTableSwitch(3) != 15) {
            Console.println("t3");
            System.hlt();
        }
        if (testTableSwitch(4) != 22) {
            Console.println("t4");
            System.hlt();
        }
        if (System.getStackPointer() != 0) {
            Console.println("@tsp");
            System.hlt();
        }

        Console.println("OK");
        System.wfi();
    }
}
