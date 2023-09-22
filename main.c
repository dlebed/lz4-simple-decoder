/*
 * SPDX-FileCopyrightText: 2023 Dmitrii Lebed <lebed.dmitry@gmail.com>
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <stdio.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>
#include "lz4.h"

uint8_t output[1024 * 64];

const uint8_t *open_file(const char *filename, size_t *size)
{
    const uint8_t *res;
    struct stat s;
    int status;
    int fd;

    /* Open the file for reading. */
    fd = open(filename, O_RDONLY);
    if (fd < 0) {
        printf("open failed\n");
        return NULL;
    }

    /* Get the size of the file. */
    status = fstat(fd, &s);
    if (status < 0) {
        printf("stat failed\n");
        return NULL;
    }

    *size = s.st_size;

    /* Memory-map the file. */
    res = mmap(0, *size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (res == MAP_FAILED) {
        printf("mmap failed\n");
        return NULL;
    }

    return res;
}

int main() {
    const uint8_t *comp_data;
    const uint8_t *orig_data;
    size_t comp_size;
    size_t orig_size;


    comp_data = open_file("in.lz4", &comp_size);
    if (!comp_data)
        return -1;

    orig_data = open_file("in", &orig_size);
    if (!orig_data)
        return -1;

    printf("File opened, comp size %zu, orig size %zu\n", comp_size, orig_size);

    const uint8_t *block_data = comp_data;
    size_t block_size;

    block_data += 4; /* magic */
    block_data += 3; /* frame descriptor */

    block_size = comp_size - (block_data - comp_data);
    block_size -= 4; /* C.checksum */
    block_size -= 4; /* end mark */

    size_t res_size;

    res_size = lz4_block_decode(output, block_data);

    printf("Resulting size: %zu\n", res_size);

    if (res_size != orig_size) {
        printf("Decompressed size mismatch\n");
        return -1;
    }

    int res;
    res = memcmp(orig_data, output, res_size);

    if (res == 0) {
        printf("OK: contents match\n");
    } else {
        printf("FAIL: contents mismatch\n");
    }

    return 0;
}
