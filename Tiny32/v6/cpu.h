#ifndef _CPU_H
#define _CPU_H

void wfi(void);
void hlt(void);
void out(unsigned int value, unsigned int address);
unsigned int in(unsigned int address);

#endif
