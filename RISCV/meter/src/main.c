#include "board.h"
#include "ui.h"
#include "dev_keyboard.h"
#include "devices.h"
#include <shell.h>
#include <stdio.h>

static char led_state = 7;
static unsigned char command[MAX_COMMAND], *command_p;
static unsigned int process_command_request = 0;

static void uart_send(unsigned char c)
{
  unsigned int uart_status = *UART_CONTROL_ADDRESS;
  if (!(uart_status & UART_TX_FIFO_FULL))
    *UART_DATA_ADDRESS = c;
}

static void led_handler(void)
{
  led_state ^= 4;
  *LED_ADDRESS = led_state;
}

static void uart_handler(void)
{
  unsigned int uart_status;
  unsigned char uart_data;

  while (1)
  {
    uart_status = *UART_CONTROL_ADDRESS;
    if (uart_status & UART_RX_FIFO_EMPTY)
      break;
    
    uart_data = *UART_DATA_ADDRESS;
    if (uart_data == '\r')
    {
      uart_send(uart_data);
      uart_send('\n');
      *command_p = 0;
      process_command_request = 1;
    }
    else if (command_p - command < MAX_COMMAND - 1)
    {
      uart_send(uart_data);
      *command_p++ = uart_data;
    }
  }
}

static void process_command(void)
{
  /*int rc = shell_execute(command);
  if (rc == 0)
    puts("OK\r\n$ ");
  else if (rc < 0)
    puts("Invalid command line\r\n$ ");
  else
    printf("shell_execute returned %d\n$ ", rc);*/
}

int main(void)
{
  unsigned int measurement_no = 0, data_ready;
  unsigned int keyboard_status;

  command_p = command;

  //shell_init(printf, NULL);

  //BuildDeviceList();

  //BuildShellCommands();

  UI_Init();

  while (1)
  {  
    _wfi();
    led_handler();
    uart_handler();
    //BuildDeviceData(measurement_no);
    //keyboard_status = keyboard_get_filtered_status();
    data_ready = measurement_no == 10;
    //Process_Timer_Event(data_ready, keyboard_status);
    if (data_ready)
    {
      measurement_no = 0;
      if (process_command_request)
      {
        process_command_request = 0;
        process_command();
      }
    }
    else
      measurement_no++;
  }
}
