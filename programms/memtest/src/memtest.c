#include <stdio.h>
#include <vga.h>
#include <ov7670.h>

int main ()
{
  vga_clear();
  asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7));
  volatile uint32_t result, cycles,stall,idle;
  printf("Testing custom SRAM memory!\n");
  for(int i = 0; i < 512; ++i)
  {
    volatile uint32_t data = 512 - i + 512 - i + 512 - i;
    printf("Writing %x at location %d\n", data, i);
    asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(i | 512),[in2]"r"(data));
  }

  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(cycles):[in1]"r"(0),[in2]"r"(1<<8));
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
  printf("nrOfCycles: %d %d %d\n", cycles, stall, idle);

  printf("============================================\n");
  //asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7));
  for(int i = 1; i < 512; ++i)
  {
    volatile uint32_t data = 0;
    //reset counter 0
    //printf("Delaying %d * 16384 = %d CCs! Ctr = ", i, i << 14);
    printf("Reading from %d: ", i);
    asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xC"::[in1]"r"(0),[in2]"r"(1<<8));
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(data):[in1]"r"(i),[in2]"r"(0));
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(cycles):[in1]"r"(0),[in2]"r"(1<<8));
    printf("%d, took %d\n", data, cycles);
  }
  /*for(int i = 0; i < 512; ++i)
  {
    volatile uint32_t data = 0;
    printf("Reading from %d: ", i);
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(data):[in1]"r"(i),[in2]"r"(0));
    printf("%x\n", data);
  }*/
  
    //asm volatile ("l.nios_rrr %[out1],r0,%[in2],0xC":[out1]"=r"(cycles):[in2]"r"(1<<8|7<<4));
    //asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
    //asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
    printf("nrOfCycles: %d %d %d\n", cycles, stall, idle);
}
