package test_string_equals;

import JavaCPU.Console;
import JavaCPU.System;

public class Main {
    private static final char[] ca = {'1', '2', '3', '4', '5', '6', '7'};

    public static void isr1() {
    }

    public static void isr2() {
    }

    private static void test(Object o, boolean expected, String message) {
        if ("123".equals(o) != expected)
        {
            Console.println(message);
            System.hlt();
        }
    }

    private static void test2(String s, int pos, int l, boolean expected, String message) {
        if (System.stringEquals(s, ca, pos, l) != expected)
        {
            Console.println(message);
            System.hlt();
        }
    }

    public static void main() {
        test(new A(), false, "new A()");
        test(null, false, "null");
        test("1234", false, "1234");
        test("", false, "empty string");
        test("123", true, "123");

        test2("12", 0, 2, true, "12_0");
        test2("34", 2, 2, true, "34_2");
        test2("34", 1, 2, false, "34_1");
        test2("567", 4, 3, true, "567");

        System.wfi();
    }
}
