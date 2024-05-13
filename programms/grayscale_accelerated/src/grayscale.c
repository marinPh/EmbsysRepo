#include <stdio.h>
#include <ov7670.h>
#include <swap.h>
#include <vga.h>

const uint32_t writeBit = 1 << 9;
const uint32_t busStartAddress = 1 << 10;
const uint32_t memoryStartAddress = 2 << 10;
const uint32_t blockSize = 3 << 10;
const uint32_t burstSize = 4 << 10;
const uint32_t statusControl = 5 << 10;
const uint32_t Blocksize565 = 256;
const uint32_t BlocksizeGray = 128;
const uint32_t usedBurstSize = 64;

const uint32_t usedCiRamAddress[2] = {0, 256};

void convert(uint32_t ciBufAddress)
{
  for(int j = 0; j < 256; j+=2)
  {
    register uint32_t pixels12;
    register uint32_t pixels34;
    register uint32_t grayPixels;
    //read pixels from dma buffer
    asm volatile("l.nios_rrr %[out1],%[in1],r0,20" :[out1]"=r"(pixels12):[in1] "r"(ciBufAddress + j)); 
    asm volatile("l.nios_rrr %[out1],%[in1],r0,20" :[out1]"=r"(pixels34):[in1] "r"(ciBufAddress + j + 1)); 
    //convert to grayscalse
    asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0x9":[out1]"=r"(grayPixels):[in1]"r"(swap_u32(pixels12)),[in2]"r"(swap_u32(pixels34)));
    //write back to dma buffer
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"((ciBufAddress + (j >> 1)) | writeBit), [in2] "r"(swap_u32(grayPixels))); 
  }
}

int main()
{
  volatile uint16_t rgb565[640 * 480];
  volatile uint8_t grayscale[640 * 480];
  volatile uint32_t result, cycles, stall, idle;
  volatile unsigned int *vga = (unsigned int *)0X50000020;
  camParameters camParams;
  vga_clear();

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
  int currentStat = 1;
  
  while (1)
  {
    uint32_t * rgb = (uint32_t *) &rgb565[0];
    uint32_t *gray = (uint32_t *)&grayscale[0];
    takeSingleImageBlocking((uint32_t)&rgb565[0]);
    asm volatile ("l.nios_rrr r0,r0,%[in2],0xC"::[in2]"r"(7));

    //start the first transfer
    //we transfer from rgb to buffer via ramdmacontroller
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"(rgb)); 
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(blockSize | writeBit), [in2] "r"(Blocksize565));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(burstSize | writeBit), [in2] "r"(usedBurstSize));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(memoryStartAddress | writeBit), [in2] "r"(usedCiRamAddress[0]));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(statusControl | writeBit), [in2] "r"(1));

    //poll until dma transfer
    int32_t dma_status = 1;
    while(dma_status & 1)
    {
      asm volatile("l.nios_rrr %[out1],%[in1],r0,20" :[out1] "=r"(dma_status) :[in1] "r"(statusControl));
    }

    //printf("[+]First transfer completed!\n");

    for (int pixel = 0; pixel < 256; pixel +=2) {
        uint32_t pixels12 = 0;
        uint32_t pixels34 = 0;
        asm volatile("l.nios_rrr %[out1],%[in1],r0,20" :[out1]"=r"(pixels12):[in1] "r"(usedCiRamAddress[0] + pixel));
        asm volatile("l.nios_rrr %[out1],%[in1],r0,20" :[out1]"=r"(pixels34):[in1] "r"(usedCiRamAddress[0] + pixel + 1));  
        printf("Pixel%d: 0x%x (expected 0x%x)\n", pixel, pixels12, rgb[pixel]);
        printf("Pixel%d: 0x%x (expected 0x%x)\n", pixel + 1, pixels34, rgb[pixel + 1]);
    }
    //return 0;

    int ping = 0; //where are we converting to grayscale
    int pong = 1; //where we transfer the next line
    for (int i = 1; i <= 600; i++)
    {
      //512 RGB565 pixels is 256 DWORDS
      //printf("[+]Iteration %d\n", i);
      //start next transfer
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(blockSize | writeBit), [in2] "r"(Blocksize565));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"((uint32_t) &rgb565[i * 512])); 
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(memoryStartAddress | writeBit), [in2] "r"(usedCiRamAddress[pong]));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(statusControl | writeBit), [in2] "r"(1));

      //printf("batch %d\n", i);
      convert(usedCiRamAddress[ping]);

      //printf(" * Conversion completed!\n");

      //we transfer from dma to gray buffer via ramdmacontroller
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(blockSize | writeBit), [in2] "r"(BlocksizeGray));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"((uint32_t) &grayscale[(i - 1) * 512]));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(memoryStartAddress | writeBit), [in2] "r"(usedCiRamAddress[ping]));
      asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(statusControl | writeBit), [in2] "r"(2));

      dma_status = 1;
      while(dma_status & 1)
      {
        asm volatile("l.nios_rrr %[out1],%[in1],r0,20" :[out1] "=r"(dma_status) :[in1] "r"(statusControl));
      }

      //printf(" * Write-back completed!\n");
      ping = ping ^ 1;
      pong = pong ^ 1;
    }

    //last batch, we do not start another transfer
    convert(usedCiRamAddress[ping]);
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"((uint32_t) grayscale[600 * 256]));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(memoryStartAddress | writeBit), [in2] "r"(usedCiRamAddress[ping]));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],20" ::[in1] "r"(statusControl | writeBit), [in2] "r"(2));

    dma_status = 1;
    while(dma_status & 1)
    {
      asm volatile("l.nios_rrr %[out1],%[in1],r0,20" :[out1] "=r"(dma_status) :[in1] "r"(statusControl));
    }
       

    asm volatile("l.nios_rrr %[out1],r0,%[in2],0xC" : [out1] "=r"(cycles) : [in2] "r"(1 << 8 | 7 << 4));
    asm volatile("l.nios_rrr %[out1],%[in1],%[in2],0xC" : [out1] "=r"(stall) : [in1] "r"(1), [in2] "r"(1 << 9));
    asm volatile("l.nios_rrr %[out1],%[in1],%[in2],0xC" : [out1] "=r"(idle) : [in1] "r"(2), [in2] "r"(1 << 10));
    printf("nrOfCycles: %d %d %d\n", cycles, stall, idle);

    //now check
    /*  for (int pixel = 0; pixel < ((camParams.nrOfLinesPerImage*camParams.nrOfPixelsPerLine) >> 1); pixel +=2) {
        uint32_t pixel1 = rgb[pixel];
        uint32_t pixel2 = rgb[pixel+1];
        asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0x9":[out1]"=r"(grayPixels):[in1]"r"(pixel1),[in2]"r"(pixel2));
        printf("%p: 0x%x (expected 0x%x)\n", gray, gray[0], grayPixels);
        gray[0] = grayPixels;//newGrayPixel;
        gray++;
      }*/
  }
}
