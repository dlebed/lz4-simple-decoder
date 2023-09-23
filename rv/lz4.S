
.text

lz4_block_data_decode:


lz4_const_init:
    /* prerequisite constants, to be moved into upper function */
    li   t0, 0x01010101
    li   a5,  0x00FFFFFF
    li   t1, 1
    li   t2, 2
    li   t3, 3
    li   t5, 5
    /* end of constants */

/*
 * void lz4_offset_copy(void *dst, uint32_t offset, uint32_t len)
 * a0 = destination
 * a1 = offset
 * a2 = length
 */
.balign 32
lz4_offset_copy:
    add  t6, a0, a2  /* t6 = dst_end = dst + len */
    sub  a2, a0, a1  /* a2 = src = dst - offset */

    bgeu a1, t5, lz4_offset_copy_far_loop
    /* offset <= 4 */
lz4_offset_copy_near:
    beq  a1, t1, lz4_offset_copy_near_1b
    beq  a1, t2, lz4_offset_copy_near_2b
    beq  a1, t3, lz4_offset_copy_near_3b
    /* fall through, a1 = 4 */
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
    and  a3, a3, a5
    slli a4, a3, 24
    or   a3, a3, a4
    j    lz4_offset_copy_loop

.balign 8
lz4_offset_copy_loop:
    sw   a3, 0(a0)
    sw   a3, 4(a0)
    addi a0, a0, 8
    bltu a0, t6, lz4_offset_copy_loop

    j lz4_offset_copy_done

.balign 8
lz4_offset_copy_far_loop:
    lw   a3, 0(a2)
    lw   a4, 4(a2)
    sw   a3, 0(a0)
    sw   a4, 4(a0)
    addi a2, a2, 8
    addi a0, a0, 8
    bltu a0, t6, lz4_offset_copy_far_loop

lz4_offset_copy_done: