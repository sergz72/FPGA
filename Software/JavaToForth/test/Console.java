public final class Console {
    public static void println(String text) {
        for (char c: text.toCharArray())
            outChar(c);
        outChar('\r');
        outChar('\n');
    }

    public static native void outChar(char c);
}
