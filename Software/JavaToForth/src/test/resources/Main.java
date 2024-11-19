import JavaCPU.Console;

class Main {
    int i;
    long j;
    public Main(int i, long j) {
        this.i = i;
        this.j = j;
    }

    public void run(int ii, long ii2) {
         Console.println("Hello Java");
         for (int i = ii; i < this.i; i++) {
             if (i > 0)
                 Console.println("i>0");
             if (i > 100)
                 Console.println("i>100");
         }
         for (long i = ii2; i < this.j; i++) {
             if (i > 0)
                 Console.println("l>0");
             if (i > 100)
                 Console.println("l>100");
         }
    }

    public static void main(String args[], int ii, long ii2) {
         new Main(200, 200).run(ii, ii2);
    }
}    
