package classfile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.fail;

public class MethodOrFieldTest {
    @org.junit.jupiter.api.Test
    void connect() throws ClassFileException {
        assertEquals(0, MethodOrField.getNumberOfParameters("()V"));
        assertEquals(6, MethodOrField.getNumberOfParameters("(Ljava/lang/string;Lclass3;ICJZ)V"));
        try {
            MethodOrField.getNumberOfParameters("(Ljava/lang/string;Lclass3;ICJZP)V");
            fail();
        } catch (ClassFileException e) {
        }
        try {
            MethodOrField.getNumberOfParameters("(V");
            fail();
        } catch (ClassFileException e) {
        }
        try {
            MethodOrField.getNumberOfParameters(")V");
            fail();
        } catch (ClassFileException e) {
        }
        try {
            MethodOrField.getNumberOfParameters("V");
            fail();
        } catch (ClassFileException e) {
        }
    }
}
