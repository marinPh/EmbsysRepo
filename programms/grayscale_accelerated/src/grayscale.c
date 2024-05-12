#include <stdio.h>
#include <ov7670.h>
#include <swap.h>
#include <vga.h>

#define WRITEBIT 1 << 9
#define BUSADDRESS 1 << 10
#define MEMADDRESS 1 << 11
#define BLOCKSIZE 3 << 10
#define BURSTSIZE 4 << 10
#define CTLREG 5 << 10

int main()
{
  const uint32_t writeBit = 1 << 9;
  const uint32_t busStartAddress = 1 << 10;
  const uint32_t memoryStartAddress = 2 << 10;
  const uint32_t blockSize = 3 << 10;
  const uint32_t burstSize = 4 << 10;
  const uint32_t statusControl = 5 << 10;
  const uint32_t usedCiRamAddress = 50;
  const uint32_t usedBlocksize = 512;
  const uint32_t usedBurstSize = 16;
  volatile uint16_t rgb565[640 * 480];
  volatile uint8_t grayscale[640 * 480];
  volatile uint32_t result, cycles, stall, idle;
  volatile unsigned int *vga = (unsigned int *)0X50000020;
  camParameters camParams;
  vga_clear();
  int16_t buffer1[512];
  int8_t buffer2[512];

  int16_t *address1 = (int16_t *)&buffer1[0];
  int16_t *address2 = (int16_t *)&buffer2[0];
  int16_t *currentAddress1 = address1;
  int16_t *currentAddress2 = address2;
  // init ram
  for (int i = 0; i < 512; i++)
  {
    asm volatile("l.nios_rrr r0,%[in1],r0,20" ::[in1] "r"(i | writeBit)); // we clear the memory
    buffer1[i] = 0;
    buffer2[i] = 0;
  }

  printf("Initialising camera (this takes up to 3 seconds)!\n");
  camParams = initOv7670(VGA);
  printf("Done!\n");
  printf("NrOfPixels : %d\n", camParams.nrOfPixelsPerLine);
  result = (camParams.nrOfPixelsPerLine <= 320) ? camParams.nrOfPixelsPerLine | 0x80000000 : camParams.nrOfPixelsPerLine;
  vga[0] = swap_u32(result);
  printf("NrOfLines  : %d\n", camParams.nrOfLinesPerImage);
  result = (camParams.nrOfLinesPerImage <= 240) ? camParams.nrOfLinesPerImage | 0x80000000 : camParams.nrOfLinesPerImage;
  vga[1] = swap_u32(result);
  printf("PCLK (kHz) : %d\n", camParams.pixelClockInkHz);
  printf("FPS        : %d\n", camParams.framesPerSecond);
  uint32_t *rgb = (uint32_t *)&rgb565[0];
  uint32_t grayPixels;
  vga[2] = swap_u32(2);
  vga[3] = swap_u32((uint32_t)&grayscale[0]);
  while (1)
  {
    uint32_t *gray = (uint32_t *)&grayscale[0];
    takeSingleImageBlocking((uint32_t)&rgb565[0]);

    // initialize the buffer
    // give ramdmacontroller the address of the buffer
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"((uint32_t)currentAddress1));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(memoryStartAddress | writeBit), [in2] "r"(0));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(blockSize | writeBit), [in2] "r"(usedBlocksize));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(burstSize | writeBit), [in2] "r"(usedBurstSize));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(statusControl | writeBit), [in2] "r"(1));

    for (int i = 1; i < 600; i++)
    {
      currentAddress1 = (currentAddress1 == address1) ? address2 : address1;
      currentAddress2 = (currentAddress2 == address1) ? address2 : address1;

      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"((uint32_t)currentAddress1));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(statusControl | writeBit), [in2] "r"(1));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"((uint32_t)currentAddress2));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(statusControl | writeBit), [in2] "r"(2));

    }
    asm volatile("l.nios_rrr %[out1],r0,%[in2],0xC" : [out1] "=r"(cycles) : [in2] "r"(1 << 8 | 7 << 4));
    asm volatile("l.nios_rrr %[out1],%[in1],%[in2],0xC" : [out1] "=r"(stall) : [in1] "r"(1), [in2] "r"(1 << 9));
    asm volatile("l.nios_rrr %[out1],%[in1],%[in2],0xC" : [out1] "=r"(idle) : [in1] "r"(2), [in2] "r"(1 << 10));
    printf("nrOfCycles: %d %d %d\n", cycles, stall, idle);
  }
}
