class Blink {  
    public static void isr1() {
    }

    public static void isr2() {
    }

    public static void main() {
        boolean ledState = false;
        while (true) {
            Hal.ledSet(ledState);
            Hal.timerStart(500 * Hal.MS);
            Hal.wfi();
            ledState = !ledState;
        }
    }
}    
