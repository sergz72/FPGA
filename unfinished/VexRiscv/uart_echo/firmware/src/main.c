#define PORT_ADDRESS ((volatile unsigned int*)0x30000000)
#define UART_DATA_ADDRESS ((volatile unsigned int*)0x50000000)
#define UART_TX_FIFO_FULL 1
#define UART_RX_FIFO_EMPTY 2

void delay(unsigned int us);

static void uart_send(unsigned int c)
{
  while (1)
  {
    unsigned int uart_status = *PORT_ADDRESS;
    if (!(uart_status & UART_TX_FIFO_FULL))
    {
      *UART_DATA_ADDRESS = c;
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
    uart_status = *PORT_ADDRESS;
    if (uart_status & UART_RX_FIFO_EMPTY)
      return;
    uart_data = *UART_DATA_ADDRESS;
    uart_send(uart_data);
  }
}

__attribute__((naked)) int main(void)
{
  unsigned int state = 1;
  while (1)
  {
    delay(1000);
    uart_handler();
    state ^= 1;
    *PORT_ADDRESS = state;
  }
}
