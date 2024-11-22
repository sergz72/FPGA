package JavaCPU;

public final class Console {
    private static final char[] integerBuffer = new char[20];

    public static void print(String text) {
        for (char c: text.toCharArray())
            Hal.outChar(c);
    }

    public static void cr() {
        Hal.outChar('\r');
        Hal.outChar('\n');
    }

    public static void println(String text) {
        print(text);
        cr();
    }

    public static void printDecimal(int value) {
        if (value == 0) {
            Hal.outChar('0');
            return;
        }
        if (value < 0) {
            Hal.outChar('-');
            value = -value;
        }
        var l = 0;
        while (value != 0) {
            var v = value % 10;
            integerBuffer[l++] = (char)(v + '0');
            value /= 10;
        }
        while (l > 0)
            Hal.outChar(integerBuffer[--l]);
    }

    public static void printHex(int value) {
        if (value == 0) {
            Hal.outChar('0');
            return;
        }
        var l = 0;
        while (value != 0) {
            var v = value & 0x0F;
            integerBuffer[l++] = v > 9 ? (char)(v - 10 + 'A') : (char)(v + '0');
            value >>>= 4;
        }
        while (l > 0)
            Hal.outChar(integerBuffer[--l]);
    }
}
