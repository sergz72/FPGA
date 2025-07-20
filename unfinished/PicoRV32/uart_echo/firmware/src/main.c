#define PORT_ADDRESS ((volatile unsigned int*)0x30000000)
#define UART_DATA_ADDRESS ((volatile unsigned char*)0x40000000)
#define UART_CONTROL_ADDRESS ((volatile unsigned int*)0x50000000)
#define UART_TX_FIFO_FULL 1
#define UART_RX_FIFO_EMPTY 2

int wfi(void);
int getq(void);
unsigned int timer(unsigned int value);

static void uart_send(unsigned char c)
{
  while (1)
  {
    unsigned int uart_status = *UART_CONTROL_ADDRESS;
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
  unsigned char uart_data;

  while (1)
  {
    uart_status = *UART_CONTROL_ADDRESS;
    if (uart_status & UART_RX_FIFO_EMPTY)
      return;
    uart_data = *UART_DATA_ADDRESS;
    uart_send(uart_data);
  }
}

__attribute__((naked)) int main(void)
{
  int counter = 0;
  int state = 1;

  while (1)
  {
    timer(2700000);
    wfi();
    if (counter == 9)
    {
      uart_handler();
      counter = 0;
      state ^= 1;
      *PORT_ADDRESS = state;
    }
    else
      counter++;
  }
}
