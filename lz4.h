/*
 * SPDX-FileCopyrightText: 2023 Dmitrii Lebed <lebed.dmitry@gmail.com>
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef LZ4_H
#define LZ4_H

#include <stddef.h>
#include <stdint.h>

size_t lz4_block_decode(void *dst, const void *src);

#endif //LZ4_H
