package classfile;

class MethodName {
    String className;
    String methodName;

    MethodName(String className, String methodName) {
        this.className = className;
        this.methodName = methodName;
    }

    @Override
    public String toString() {
        return className + "." + methodName;
    }
}
