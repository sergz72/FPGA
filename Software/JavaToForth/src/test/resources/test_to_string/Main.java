package test_to_string;

import JavaCPU.Console;
import JavaCPU.System;

public class Main {
    public static void isr1() {
    }

    public static void isr2() {
    }

    private static void test(Object o) {
        Console.println(o.toString());
    }

    public static void main() {
        test(new A());
        test(new B());
        test(new C());
        System.hlt();
    }
}
