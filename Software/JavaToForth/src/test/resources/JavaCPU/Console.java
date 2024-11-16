package JavaCPU;

public final class Console {
    public static void println(String text) {
        for (char c: text.toCharArray())
            Hal.outChar(c);
        Hal.outChar('\r');
        Hal.outChar('\n');
    }
}
