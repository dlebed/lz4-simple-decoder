/*
 * SPDX-FileCopyrightText: 2023 Dmitrii Lebed <lebed.dmitry@gmail.com>
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include "lz4.h"
#include <string.h>
#include <stdint.h>

enum {
    LZ4_TOKEN_LEN_MORE      = 0x0F,
    LZ4_MIN_MATCH_LEN       = 4,
    LZ4_UNCOMPRESSED_FLAG   = 1UL << 31,
};

static void lz4_copy(uint8_t *dst, const uint8_t *src, size_t len)
{
    uint8_t *dst_end = dst + len;

    while (dst < dst_end) {
        *dst++ = *src++;
    }
}

static void lz4_offset_copy(uint8_t *dst, size_t offset, size_t len)
{
    uint8_t *dst_end = dst + len;
    const uint8_t *src = dst - offset;

    if (offset <= sizeof(uint32_t)) {
        uint32_t val;

        memcpy(&val, src, sizeof(val));

        switch (offset) {
            case 1:
                val &= 0xFF;
                val |= val << 8;
                val |= val << 16;
                break;
            case 2:
                val &= 0xFFFF;
                val |= val << 16;
                break;
            case 3:
                val &= 0xFFFFFF;
                val |= val << 24;
                break;
            default:
                break;
        }

        do {
            memcpy(dst, &val, sizeof(val));
            dst += sizeof(val);
        } while (dst < dst_end);
    } else {
        do {
            memcpy(dst, src, 4);
            dst += 4;
            src += 4;
        } while (dst < dst_end);
    }
}

static size_t lz4_block_data_decode(uint8_t *dst, const uint8_t *src,
                                    size_t block_size)
{
    const uint8_t *src_end = src + block_size;
    uint8_t *dst_orig = dst;

    while (true) {
        const uint8_t token = *src++;
        uint16_t offset;

        size_t lit_len = token >> 4;

        if (lit_len == LZ4_TOKEN_LEN_MORE) {
            do {
                lit_len += *src;
            } while (*src++ == 0xFF);
        }

        lz4_copy(dst, src, lit_len);
        dst += lit_len;
        src += lit_len;

        if (src >= src_end) {
            break;
        }

        memcpy(&offset, src, sizeof(offset));
        src += sizeof(offset);

        size_t match_len = token & 0x0F;

        if (match_len == LZ4_TOKEN_LEN_MORE) {
            do {
                match_len += *src;
            } while (*src++ == 0xFF);
        }

        match_len += LZ4_MIN_MATCH_LEN;

        lz4_offset_copy(dst, offset, match_len);
        dst += match_len;
    }

    return dst - dst_orig;
}

size_t lz4_block_decode(void *dst, const void *src)
{
    const uint8_t *src_buf = src;
    uint32_t block_data_size;
    uint8_t *dst_buf = dst;
    size_t res_size;

    memcpy(&block_data_size, src_buf, sizeof(block_data_size));
    src_buf += sizeof(block_data_size);

    if (block_data_size & LZ4_UNCOMPRESSED_FLAG) {
        res_size = block_data_size ^ LZ4_UNCOMPRESSED_FLAG;
        lz4_copy(dst_buf, src_buf, res_size);
    } else {
        res_size = lz4_block_data_decode(dst_buf, src_buf, block_data_size);
    }

    return res_size;
}