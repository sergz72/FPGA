package i2c;

import JavaCPU.System;

public final class I2CMaster {
    private static final int I2C_DELAY = 10;
    private static final int SCL = 2;
    private static final int SDA = 1;

    private int address;

    public I2CMaster(int address) {
        this.address = address;
    }

    private static void delay() {
        for (var i = 0; i < I2C_DELAY; i++)
            ;
    }

    private static void start(int address) {
        System.set(SCL, address);
        delay();
        System.set(0, address);
    }

    private static void stop(int address) {
        System.set(0, address);
        delay();
        System.set(SCL, address);
        delay();
        System.set(SCL|SDA, address);
    }

    private static void bitSend(int address, int data) {
        var state = System.bitTest(data, 7);
        System.set(state, address);
        System.set(state|SCL, address);
        delay();
        System.set(state, address);
    }

    private static boolean byteSend(int address, int data) {
        for (var i = 0; i < 8; i++) {
            bitSend(address, data);
            data <<= 1;
        }
        System.set(SDA, address);
        System.set(SCL|SDA, address);
        delay();
        var ack = System.get(address) & SDA;
        System.set(SCL, address);
        return ack == 0;
    }

    public boolean check(int channel, int deviceAddress) {
        var a = address + channel;
        start(a);
        var ack = byteSend(a, deviceAddress << 1);
        stop(a);
        return ack;
    }
}
