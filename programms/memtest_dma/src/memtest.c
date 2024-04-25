#include <stdio.h>
#include <vga.h>
#include <ov7670.h>

#define WRITE_ENABLE 512
#define ACCESS_BUFFER 0
#define ACCESS_BUS_ADDRESS 1 << 10
#define ACCESS_BUFFER_ADDRESS 2 << 10
#define ACCESS_BLOCK_SIZE 3 << 10
#define ACCESS_BURST_SIZE 4 << 10
#define ACCESS_CONTROL 5 << 10

volatile unsigned int testbuf [128];

int main ()
{
  vga_clear();
  asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7));
  volatile uint32_t result, cycles,stall,idle;
  volatile uint32_t ptr_as_uint = (uint32_t)&testbuf[0];
  printf("[+] Populating %p (0x%x) with random data!\n", testbuf, ptr_as_uint);
  for(unsigned int i = 0; i < 128; ++i)
    testbuf[i] = i | (i << 8) | (i << 16) | (i << 24);//0xDEAD0000 | i;

  printf("[+] Setting parameters\n");
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_BUS_ADDRESS | WRITE_ENABLE),[in2]"r"(ptr_as_uint));
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_BUFFER_ADDRESS | WRITE_ENABLE),[in2]"r"(40));
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_BURST_SIZE | WRITE_ENABLE),[in2]"r"(15));
  printf("[+] Reading parameters: \n");
  volatile uint32_t check = 0;
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(check):[in1]"r"(ACCESS_BUS_ADDRESS),[in2]"r"(0));
  printf(" - Bus addr: 0x%x\n", check);
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(check):[in1]"r"(ACCESS_BUFFER_ADDRESS),[in2]"r"(0));
  printf(" - Buf addr: 0x%x\n", check);
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(check):[in1]"r"(ACCESS_BURST_SIZE),[in2]"r"(0));
  printf(" - Burst size: 0x%x\n", check);
  

  volatile uint32_t statusreg = 0;
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(statusreg):[in1]"r"(ACCESS_CONTROL),[in2]"r"(0));
  printf("[+] Status reg: %d\n", statusreg);

    printf("[+] Begin DMA read from 0x%x\n", ptr_as_uint);
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_CONTROL | WRITE_ENABLE),[in2]"r"(0));
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(statusreg):[in1]"r"(ACCESS_CONTROL),[in2]"r"(0));
  printf("[+] Status reg: %d\n", statusreg);
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(statusreg):[in1]"r"(ACCESS_CONTROL),[in2]"r"(0));
  printf("[+] Status reg: %d\n", statusreg);
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(statusreg):[in1]"r"(ACCESS_CONTROL),[in2]"r"(0));
  printf("[+] Status reg: %d\n", statusreg);
  //for(int i = 0; i < 512; ++i)
  //{
  //  volatile uint32_t data = 512 - i + 512 - i + 512 - i;
  //  printf("Writing %x at location %d\n", data, i);
  //  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(i | 512),[in2]"r"(data));
  //}

  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(cycles):[in1]"r"(0),[in2]"r"(1<<8));
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
  printf("nrOfCycles: %d %d %d\n", cycles, stall, idle);

  printf("============================================\n");
  //asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7));
  for(int i = 1; i < 128; ++i)
  {
    volatile uint32_t data = 0;
    //reset counter 0
    //printf("Delaying %d * 16384 = %d CCs! Ctr = ", i, i << 14);
    printf("Reading from %d: ", i);
    asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xC"::[in1]"r"(0),[in2]"r"(1<<8));
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(data):[in1]"r"(i),[in2]"r"(0));
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(cycles):[in1]"r"(0),[in2]"r"(1<<8));
    printf("0x%x, took %d\n", data, cycles);
  }

    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(statusreg):[in1]"r"(ACCESS_CONTROL),[in2]"r"(0));
  printf("[+] Status reg: %d\n", statusreg);
  for(int i = 0; i < 128; ++i)
  {
    printf("Reading from buf %d: 0x%x\n", i, testbuf[i]);

  }
  
    //asm volatile ("l.nios_rrr %[out1],r0,%[in2],0xC":[out1]"=r"(cycles):[in2]"r"(1<<8|7<<4));
    //asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(stall):[in1]"r"(1),[in2]"r"(1<<9));
    //asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xC":[out1]"=r"(idle):[in1]"r"(2),[in2]"r"(1<<10));
    printf("nrOfCycles: %d %d %d\n", cycles, stall, idle);
}
