package test_string_equals;

import JavaCPU.Console;
import JavaCPU.System;

public class Main {
    public static void isr1() {
    }

    public static void isr2() {
    }

    private static void test(Object o) {
        Console.println("123".equals(o) ? "true" : "false");
    }

    public static void main() {
        test(new A());
        test(null);
        test("1234");
        test("");
        test("123");
        System.hlt();
    }
}
