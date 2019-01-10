#ifndef __ATARI_H__
#define __ATARI_H__

#include <inttypes.h>

extern void atari_gpio_init(void);
extern void atari_cpu_startup(void);
extern uint8_t atari_get_databus(void);
extern uint16_t atari_get_addressbus(void);
extern void atari_set_expansion_memory(uint8_t exp);
extern int atari_get_phi2(void);
extern int atari_has_write(void);
extern uint8_t atari_get_addressbus_low(void);
extern int atari_has_cctl(void);

#endif
