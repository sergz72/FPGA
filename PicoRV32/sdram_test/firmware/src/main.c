#include "board.h"
#include <shell.h>
#include <getstring.h>
#include <common_printf.h>
#include <sdram_commands.h>

static int state;
static char command_line[100];

static void shell_handler(void)
{
  int rc;

  if (!getstring_next())
  {
    switch (command_line[0])
    {
      case SHELL_UP_KEY:
        puts_("\r\33[2K$ ");
        getstring_buffer_init(shell_get_prev_from_history());
        break;
      case SHELL_DOWN_KEY:
        puts_("\r\33[2K$ ");
        getstring_buffer_init(shell_get_next_from_history());
        break;
      default:
        rc = shell_execute(command_line);
        if (rc == 0)
          puts_("OK\r\n$ ");
        else if (rc < 0)
          puts_("Invalid command line\r\n$ ");
        else
          common_printf("shell_execute returned %d\n$ ", rc);
        break;
    }
  }
}

__attribute__((naked)) int main(void)
{
  int counter = 0;

  shell_init(common_printf, NULL);
  register_sdram_commands(SDRAM_ADDRESS, SDRAM_SIZE);

  getstring_init(command_line, sizeof(command_line), getch_, puts_);

  state = LED1;

  while (1)
  {
    timer(2700000);
    wfi();
    if (counter == 9)
    {
      counter = 0;
      state ^= LED1;
      *PORT_ADDRESS = state;
    }
    else
      counter++;
    shell_handler();
  }
}
