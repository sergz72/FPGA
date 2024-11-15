class UartEcho {
    private static final int DELAY = 500 * Hal.MS;
    private static final int UART_BUFFER_SIZE = 128;

    private static boolean commandReady;
    private static char[] command;
    private static int commandPointer, commandReadPointer;

    private static boolean timerInterrupt;
    
    public static void isr1() {
        timerInterrupt = true;
    }

    public static void isr2() {
        char c = (char)(Hal.uartGet() & 0xFF);
        if (commandReady)
            return;
        if (c == '\n') {
            commandReady = true;
            return;
        }
        if (commandPointer < command.length) {
            command[commandPointer++] = c;
        }
    }

    private static void uartEcho() {
        while (commandReadPointer < commandPointer)
            Hal.outChar(command[commandReadPointer++]);
    }

    public static void main() {
        command = new char[UART_BUFFER_SIZE];
        commandReady = false;
        timerInterrupt = false;
        commandPointer = commandReadPointer = 0;
        boolean ledState = false;
        Hal.timerStart(DELAY);
        while (true) {
            System.wfi();
            uartEcho();
            if (timerInterrupt) {
                timerInterrupt = false;
                Hal.timerStart(DELAY);
                Hal.ledSet(ledState);
                ledState = !ledState;
                if (commandReady) {
                    commandReady = false;
                }
            }
        }
    }
}    
