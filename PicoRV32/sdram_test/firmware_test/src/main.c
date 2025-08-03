#define PORT_ADDRESS ((volatile unsigned int*)0x30000000)
#define UART_DATA_ADDRESS ((volatile unsigned char*)0x40000000)
#define UART_CONTROL_ADDRESS ((volatile unsigned int*)0x50000000)
#define SDRAM_ADDRESS ((volatile unsigned int*)0x60000000)
#define SDRAM_SIZE (1<<21)
#define UART_TX_FIFO_FULL 1
#define UART_RX_FIFO_EMPTY 2
#define LED1 1
#define LED2 2

int wfi(void);
int getq(void);
unsigned int timer(unsigned int value);

static int state;

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

static void stop(void)
{
  state |= LED2;
  *PORT_ADDRESS = state;
  while (1)
    ;
}

static void sdram_test(void)
{
  volatile unsigned int *p = SDRAM_ADDRESS;
  for (int i = 0; i < SDRAM_SIZE; i+= 4)
  {
    // 32 bit access;
    volatile unsigned int *p32 = p;
    *p32++ = 0x11223344;
    *p32++ = 0xFFEEDDCC;
    *p32++ = 0x55555555;
    *p32 = 0xAAAAAAAA;
    p32 = p;
    if (*p32++ != 0x11223344)
      stop();
    if (*p32++ != 0xFFEEDDCC)
      stop();
    if (*p32++ != 0x55555555)
      stop();
    if (*p32 != 0xAAAAAAAA)
      stop();

/*
    // 16 bit access;
    volatile unsigned short *p16 = (volatile unsigned short*)p;
    *p16++ = 0x5555;
    *p16++ = 0x5555;
    *p16++ = 0xAAAA;
    *p16++ = 0xAAAA;
    *p16++ = 0x1122;
    *p16++ = 0x3344;
    *p16++ = 0xFFEE;
    *p16 = 0xDDCC;
    p16 = (unsigned short*)p;
    if (*p16++ != 0x5555)
      stop();
    if (*p16++ != 0x5555)
      stop();
    if (*p16++ != 0xAAAA)
      stop();
    if (*p16++ != 0xAAAA)
      stop();
    if (*p16++ != 0x1122)
      stop();
    if (*p16++ != 0x3344)
      stop();
    if (*p16++ != 0xFFEE)
      stop();
    if (*p16 != 0xDDCC)
      stop();

    // 8 bit access;
    volatile unsigned char *p8 = (volatile unsigned char*)p;
    *p8++ = 0x11;
    *p8++ = 0x22;
    *p8++ = 0x33;
    *p8++ = 0x44;
    *p8++ = 0xFF;
    *p8++ = 0xEE;
    *p8++ = 0xDD;
    *p8++ = 0xCC;
    *p8++ = 0x55;
    *p8++ = 0x55;
    *p8++ = 0x55;
    *p8++ = 0x55;
    *p8++ = 0xAA;
    *p8++ = 0xAA;
    *p8++ = 0xAA;
    *p8 = 0xAA;
    p8 = (unsigned char*)p;
    if (*p8++ != 0x11)
      stop();
    if (*p8++ != 0x22)
      stop();
    if (*p8++ != 0x33)
      stop();
    if (*p8++ != 0x44)
      stop();
    if (*p8++ != 0xFF)
      stop();
    if (*p8++ != 0xEE)
      stop();
    if (*p8++ != 0xDD)
      stop();
    if (*p8++ != 0xCC)
      stop();
    if (*p8++ != 0x55)
      stop();
    if (*p8++ != 0x55)
      stop();
    if (*p8++ != 0x55)
      stop();
    if (*p8++ != 0x55)
      stop();
    if (*p8++ != 0xAA)
      stop();
    if (*p8++ != 0xAA)
      stop();
    if (*p8++ != 0xAA)
      stop();
    if (*p8 != 0xAA)
      stop();*/

    p += 4;
  }
}

__attribute__((naked)) int main(void)
{
  int counter = 0;

  state = LED1;

  sdram_test();
  while (1)
  {
    timer(2700000);
    wfi();
    if (counter == 9)
    {
      uart_handler();
      counter = 0;
      state ^= LED1;
      *PORT_ADDRESS = state;
    }
    else
      counter++;
  }
}
