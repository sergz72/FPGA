package test_fields;

import JavaCPU.Console;
import JavaCPU.System;
import JavaCPU.Hal;

public class Main {
    public static void isr1() {
    }

    public static void isr2() {
    }

    public static void main() {
        var t = new Test(1, 10, new int[]{1,3,5,7,9,11,13,15,17,19,21,23,25,27,29});
        var result = t.run(50);
        if (result != 149) {
            Console.print("result = ");
            Console.printDecimal(result);
            Console.cr();
            System.hlt();
        }
        if (System.getStackPointer() != 0) {
            Console.print("sp = ");
            Console.printDecimal(System.getStackPointer());
            Console.cr();
            System.hlt();
        }
        Console.println("OK");
        System.wfi();
    }
}
