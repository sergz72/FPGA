#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, const char **argv)
{
    if (argc != 5)
    {
        puts("Usage: calc_values osc_freq cpu_freq reset_delay uart_baud");
        return 1;
    }
    
    int osc_freq = atoi(argv[1]);
    int cpu_freq = atoi(argv[2]);
    int reset_delay = atoi(argv[3]);
    int uart_baud = atoi(argv[4]);

    if (uart_baud <= 0 || osc_freq / 2 < uart_baud || reset_delay <= 0 | cpu_freq == 0 || osc_freq / 2 < cpu_freq)
    {
        puts("Wrong input values");
        return 2;
    }

    printf("// OSC freq = %d, CPU freq = %d, Reset delay = %d, UART baud = %d\n", osc_freq, cpu_freq, reset_delay, uart_baud);
    
    int uart_clock_div = (int)round((double)osc_freq / uart_baud);
    double duart_clock_counter_bits = log2(uart_clock_div);
    int uart_clock_counter_bits = (int)duart_clock_counter_bits;
    if (duart_clock_counter_bits != uart_clock_counter_bits)
        uart_clock_counter_bits++;
    double dcpu_timer_bits = log2(osc_freq * reset_delay / 1000);
    int cpu_timer_bits = (int)dcpu_timer_bits;
    if (dcpu_timer_bits != cpu_timer_bits)
        cpu_timer_bits++;
    double dcpu_clock_bit = log2(osc_freq / cpu_freq);
    int cpu_clock_bit = (int)dcpu_clock_bit;
    if (dcpu_clock_bit != cpu_clock_bit)
        cpu_clock_bit++;
    int mhz_timer_value = osc_freq / 1000000;
    double dmhz_timer_bits = log2(mhz_timer_value);
    int mhz_timer_bits = (int)dmhz_timer_bits;
    if (dmhz_timer_bits != mhz_timer_bits)
        mhz_timer_bits++;

    printf("`define UART_CLOCK_DIV %d\n", uart_clock_div);
    printf("`define UART_CLOCK_COUNTER_BITS %d\n", uart_clock_counter_bits);
    printf("`define CPU_TIMER_BITS %d\n", cpu_timer_bits);
    printf("`define CPU_CLOCK_BIT %d\n", cpu_clock_bit);
    printf("`define MHZ_TIMER_BITS %d\n", mhz_timer_bits);
    printf("`define MHZ_TIMER_VALUE %d\n", mhz_timer_value - 1);

    return 0;
}