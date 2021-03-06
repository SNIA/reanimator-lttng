/*
 * Copyright (c) 2019 Erez Zadok
 * Copyright (c) 2019-2020 Ibrahim Umit Akgun
 * Copyright (c) 2020 Lukas Velikov */

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>

#define handle_error(msg) \
  do {                    \
    perror(msg);          \
    exit(EXIT_FAILURE);   \
  } while (0)

int main(int argc, char *argv[]) {
  char *memblock;
  int fd;
  struct stat sb;
  uint64_t i = 0;
  fd = open("/root/research/lttng/fsl-lttng/build/mmaptest.file", O_RDWR, 0);

  fstat(fd, &sb);
  printf("file desc: %d, size: %lu\n", fd, (uint64_t)sb.st_size);

  memblock = mmap(NULL, 4096 * 20, O_RDWR, MAP_SHARED, fd, 0);
  if (memblock == MAP_FAILED) handle_error("mmap");

  for (i = 0; i < 10; i++) {
    printf("[%lu]=%X ", i, memblock[8192 + i]);
  }
  printf("\n");

  for (i = 0; i < 10; i++) {
    printf("[%lu]=%X ", i, memblock[16384 + i]);
  }
  printf("\n");

  strcpy(memblock, "TEST 123");
  // msync(memblock, 4096 * 20, MS_SYNC);
  strcpy(memblock + 4096, "TEST 123");
  // msync(memblock, 4096 * 20, MS_SYNC);
  fsync(fd);
  
  close(fd);
  return 0;
}
