#ifndef KERNEL_H
#define KERNEL_H

#define Z_OK   0
#define Z_FAIL 1

#define Z_IRQ_KTIMER       3
#define Z_IRQ_UART         4
#define Z_IRQ_HID          5

typedef uint32_t z_rv;

static inline uint32_t maskirq(uint32_t new_mask) {
    uint32_t old_mask;

    __asm__ volatile (
        ".insn r 0x0B, 0x6, 0x03, %0, %1, zero"
        : "=r"(old_mask)      // output: destination register
        : "r"(new_mask)       // input: source register
        : "memory"
    );

    return old_mask;
}

#endif
