package test_fields;

final class Test {
    private final int start;
    private final int end;
    private final int[] v;

    Test(int start, int end, int[]v) {
        this.start = start;
        this.end = end;
        this.v = v;
    }

    int run(int value) {
        for (var i = start; i < end; i++) {
            value += v[i];
        }
        return value;
    }
}
