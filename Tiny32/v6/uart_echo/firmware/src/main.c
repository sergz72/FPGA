#define LED_ADDRESS 0
#define UART_DATA_ADDRESS 0x10000000
#define UART_CONTROL_ADDRESS 0x20000000
#define UART_TX_FIFO_FULL 1
#define UART_RX_FIFO_EMPTY 2

void wfi(void);
void hlt(void);
void out(unsigned int value, unsigned int address);
unsigned int in(unsigned int address);

static void uart_send(unsigned int c)
{
  while (1)
  {
    unsigned int uart_status = in(UART_CONTROL_ADDRESS);
    if (!(uart_status & UART_TX_FIFO_FULL))
    {
      out(c, UART_DATA_ADDRESS);
      return;
    }
  }
}

static void uart_handler(void)
{
  unsigned int uart_status;
  unsigned int uart_data;

  while (1)
  {
    uart_status = in(UART_CONTROL_ADDRESS);
    if (uart_status & UART_RX_FIFO_EMPTY)
      return;
    uart_data = in(UART_DATA_ADDRESS);
    uart_send(uart_data);
  }
}

__attribute__((naked)) int main(void)
{
  unsigned int state = 1;
  while (1)
  {
    wfi();
    uart_handler();
    state ^= 1;
    out(state, LED_ADDRESS);
  }
}
