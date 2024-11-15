public final class Console {
    public static void println(String text) {
        for (char c: text.toCharArray())
            outChar(c);
        outChar('\r');
        outChar('\n');
    }

    public static void outChar(char c) {
        while ((uartGet() & 0x100) != 0)
          ;
        uartOut(c);
    }
    
    private static native void uartOut(char c);
    private static native int uartGet();
}
