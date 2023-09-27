
.text

/*
 * void lz4_block_data_decode(void *dst, void *src, uint32_t block_size)
 * a0 = destination
 * a1 = source (start of compressed block data)
 * a2 = block data size
 */
lz4_block_data_decode:
lz4_const_init:
    /* prerequisite constants, to be moved into upper function */
    li   t0, 0x01010101
    li   t1, 1
    li   t2, 2
    li   t3, 3
    li   t4, 0x0F
    li   t5, 5
    li   t6, 0xFF
    /* end of constants */

    add  a6, a1, a2     /* a6 = src_end = src + block_size */

lz4_block_data_loop:
    lbu  a2, 0(a1)      /* a2 = token */
    addi a1, a1, 1
    srli a3, a2, 4      /* a3 = literal length */

    beqz a3, lz4_block_match
    beq  a3, t4, lz4_block_lit_len_read
lz4_block_lit_len_done:
    add  a3, a1, a3     /* a3 = src_end = src + lit_len */

    bgeu a3, a6, lz4_block_data_decode_out /* end of block */

lz4_block_lit_copy_loop:
    lw   a4, 0(a1)
    lw   a5, 4(a1)
    sw   a4, 0(a0)
    sw   a5, 4(a0)
    addi a1, a1, 8
    addi a0, a0, 8
    bltu a1, a3, lz4_block_lit_copy_loop

lz4_block_match:
    lhu  a5, 0(a1)
    addi a1, a1, 2

    andi a2, a2, 0x0F   /* match length */
    beq  a2, t4, lz4_block_match_len_read
lz4_block_match_len_done:
    addi a2, a2, 4      /* += minimal len (4) */

/*  lz4_offset_copy subroutine */

/*
 * uint32_t lz4_offset_copy(void *dst, uint32_t offset, uint32_t len)
 * a0 = destination
 * a2 = length
 * a5 = offset
 * return: a0 = destination + length
 */
lz4_offset_copy:
    add  a7, a0, a2  /* a7 = dst_end = dst + len */
    sub  a2, a0, a5  /* a2 = src = dst - offset */

    bgeu a5, t5, lz4_offset_copy_far_loop
    /* offset <= 4 */
lz4_offset_copy_near:
    beq  a5, t1, lz4_offset_copy_near_1b
    beq  a5, t2, lz4_offset_copy_near_2b
    beq  a5, t3, lz4_offset_copy_near_3b
    /* fall through, a5 = 4 */
lz4_offset_copy_near_4b:
    lw   a3, 0(a2)
    j    lz4_offset_copy_loop

.balign 8
lz4_offset_copy_near_1b:
    lbu  a3, 0(a2)
    mul  a3, a3, t0
    j    lz4_offset_copy_loop

.balign 8
lz4_offset_copy_near_2b:
    lhu    a3, 0(a2)
    slli   a4, a3, 16
    or     a3, a3, a4
    j      lz4_offset_copy_loop

.balign 8
lz4_offset_copy_near_3b:
    lw   a3, 0(a2)
    slli a3, a3, 8
    srli a3, a3, 8
    slli a4, a3, 24
    or   a3, a3, a4
    j    lz4_offset_copy_loop_3b

.balign 8
lz4_offset_copy_loop:
    sw   a3, 0(a0)
    sw   a3, 4(a0)
    addi a0, a0, 8
    bltu a0, a7, lz4_offset_copy_loop

    j lz4_offset_copy_done

.balign 8
lz4_offset_copy_loop_3b:
    rori a4, a3, 8
    sw   a3, 0(a0)
    sw   a4, 4(a0)
    rori a3, a4, 8
    addi a0, a0, 8
    bltu a0, a7, lz4_offset_copy_loop_3b

    j lz4_offset_copy_done

.balign 8
lz4_offset_copy_far_loop:
    lw   a3, 0(a2)
    lw   a4, 4(a2)
    sw   a3, 0(a0)
    sw   a4, 4(a0)
    addi a2, a2, 8
    addi a0, a0, 8
    bltu a0, a7, lz4_offset_copy_far_loop

lz4_offset_copy_done:
    mv   a0, a7

/* end of lz4_offset_copy */

    j lz4_block_data_loop

lz4_block_data_decode_out:
/*
 * a1 = src
 * a0 = dst
 * a3 = src_end
 */
lz4_block_data_last_lit_loop:
    lbu  a4, 0(a1)
    sb   a4, 0(a0)
    addi a0, a0, 1
    addi a1, a1, 1
    bltu a1, a3, lz4_block_data_last_lit_loop

    ret

.balign 8
lz4_block_lit_len_read:
    lbu  a4, 0(a1)
    addi a1, a1, 1
    add  a3, a3, a4
    bne  a4, t6, lz4_block_lit_len_done
    j lz4_block_lit_len_read

.balign 8
lz4_block_match_len_read:
    lbu  a4, 0(a1)
    addi a1, a1, 1
    add  a2, a2, a4
    bne  a4, t6, lz4_block_match_len_done
    j lz4_block_match_len_read
