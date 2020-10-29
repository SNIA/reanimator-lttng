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

int main(){
    char *memblock;
    int fd;
    struct stat sb;
    int i;

    fd = open("mmaptest.file", O_RDWR, 0);

    fstat(fd, &sb);
    printf("file desc: %d, size: %lu\n", fd, (uint64_t)sb.st_size);

    printf("Original content:\n");
    memblock = mmap(NULL, 4096 * 10, O_RDWR, MAP_SHARED, fd, 0);
    if (memblock == MAP_FAILED) handle_error("mmap");

    for (i = 0; i < 10; i++) {
        printf("[%lu]=%X ", i, memblock[i]);
    }
    printf("\n");

    //unmap the beginning
    int ret = munmap(memblock, 4096);
    printf("Unmapped from the beginning, success? %d\n", ret);

    //right overlap
    ret = munmap(memblock, 4096 * 2);
    printf("Right overlap, success? %d\n", ret);

    //left overlap
    ret = munmap(memblock + 4096 * 9, 4096);
    printf("Left overlap, success? %d\n", ret);

    //enclosed
    ret = munmap(memblock + 4096 * 3, 4096 * 5);
    printf("Enclosed overlap, success? %d\n", ret);

    //enclosing
    ret = munmap(memblock, 4096 * 4);
    printf("Enclosing overlap, success? %d\n", ret);

    close(fd);
    return 0;
}
