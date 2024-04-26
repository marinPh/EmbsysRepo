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
volatile unsigned int testdest [128];
unsigned int getDmaStatus()
{
  volatile unsigned int statusreg = 0;
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(statusreg):[in1]"r"(ACCESS_CONTROL),[in2]"r"(0));
  return statusreg;
}

void setDmaParams(uint32_t busAddr, uint32_t bufAddr, uint32_t blockSize, uint32_t burstSize)
{
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_BUS_ADDRESS | WRITE_ENABLE),[in2]"r"(busAddr));
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_BUFFER_ADDRESS | WRITE_ENABLE),[in2]"r"(bufAddr));
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_BURST_SIZE | WRITE_ENABLE),[in2]"r"(burstSize));
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_BLOCK_SIZE | WRITE_ENABLE),[in2]"r"(blockSize));
}

void startDmaRead()
{
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_CONTROL | WRITE_ENABLE),[in2]"r"(1));
}

void startDmaWrite()
{
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xE"::[in1]"r"(ACCESS_CONTROL | WRITE_ENABLE),[in2]"r"(2));
}

int main ()
{
  vga_clear();
  asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7));
  volatile uint32_t result, cycles,stall,idle;
  volatile uint32_t ptr_as_uint = (uint32_t)&testbuf[0];
  printf("[+] Populating %p (0x%x) with random data!\n", testbuf, ptr_as_uint);
  for(unsigned int i = 0; i < 128; ++i)
  {
    testbuf[i] = i | (i << 8) | (i << 16) | (i << 24);
    testdest[i] = 0;
  }

  printf("[+] Setting parameters\n");
  setDmaParams(ptr_as_uint, 0x28, 29, 6);

  printf("[+] Reading parameters: \n");
  volatile uint32_t check = 0;
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(check):[in1]"r"(ACCESS_BUS_ADDRESS),[in2]"r"(0));
  printf(" - Bus addr: 0x%x\n", check);
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(check):[in1]"r"(ACCESS_BUFFER_ADDRESS),[in2]"r"(0));
  printf(" - Buf addr: 0x%x\n", check);
  asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0xE":[out1]"=r"(check):[in1]"r"(ACCESS_BURST_SIZE),[in2]"r"(0));
  printf(" - Burst size: 0x%x\n", check);
  
  printf("[+] Status reg: %d\n", getDmaStatus());

  printf("[+] Begin DMA read from 0x%x\n", ptr_as_uint);
  startDmaRead();
  printf("[+] Status reg: %d\n", getDmaStatus());
  while(getDmaStatus() == 1)
  {
    printf("[+] Stalling CPU: waiting for DMA transfer to be over!\n");
  }
  printf("[+] Status reg: %d\n", getDmaStatus());

  //start another dma transfer
  setDmaParams(ptr_as_uint + 80, 20, 29, 6);
  printf("[+] Begin DMA read from 0x%x\n", ptr_as_uint + 80);
  startDmaRead();
  printf("[+] Status reg: %d\n", getDmaStatus());
  while(getDmaStatus() == 1)
  {
    printf("[+] Stalling CPU: waiting for DMA transfer to be over!\n");
  }
  printf("[+] Status reg: %d\n", getDmaStatus());

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

  for(int i = 0; i < 128; ++i)
  {
    printf("Reading from buf %d: 0x%x\n", i, testbuf[i]);

  }

  //now do DMA to bus
  setDmaParams(&testdest[0] + 4, 20, 32, 15);
  printf("[+] Saving ciMem data to ram!\n");
  startDmaWrite();
  printf("[+] Status reg: %d\n", getDmaStatus());
  while(getDmaStatus() == 1)
  {
    printf("[+] Stalling CPU: waiting for DMA transfer to be over!\n");
  }
  printf("[+] Status reg: %d\n", getDmaStatus());

  for(int i = 0; i < 128; ++i)
  {
    printf("Reading from dest %d: 0x%x\n", i, testdest[i]);

  }
}
