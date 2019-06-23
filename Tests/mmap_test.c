#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>

#define handle_error(msg) \
  do {                    \
    perror(msg);          \
    exit(EXIT_FAILURE);   \
  } while (0)

int main(int argc, char *argv[]) {
  const char *memblock;
  int fd;
  struct stat sb;

  fd = open("/home/umit/research/lttng/fsl-lttng/build/mmaptest.file", O_RDWR, 0);

  fstat(fd, &sb);
  printf("Size: %lu\n", (uint64_t)sb.st_size);

  memblock = mmap(NULL, sb.st_size, O_RDWR, MAP_SHARED, fd, 0);
  if (memblock == MAP_FAILED) handle_error("mmap");

  for (uint64_t i = 0; i < 10; i++) {
    printf("[%lu]=%X ", i, memblock[i]);
  }
  printf("\n");

  close(fd);
  return 0;
}
