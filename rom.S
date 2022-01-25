#define REG_FEATURES 0x00
#define REG_CMD      0x04
#define REG_PARAM    0x08

#define CMD_NOOP            0
#define CMD_RESET           1
#define CMD_HALT            2
#define CMD_PANIC           3
#define CMD_FW_MACHINE_ID   4
#define CMD_FW_LOAD         5
#define CMD_FW_RAMSIZE      6
#define CMD_FW_QEMU_VERSION 7

#define RESULT_ERROR (-1)

#define FW_M68K 0

#define PIC_IRQ_BASE(num)     (8 + (num - 1) * 32)
#define PIC_IRQ(num, irq)     (PIC_IRQ_BASE(num) + irq - 1)

#define VIRT_GF_PIC_MMIO_BASE 0xff000000
#define VIRT_GF_PIC_IRQ_BASE  1

#define VIRT_GF_RTC_MMIO_BASE 0xff006000
#define VIRT_GF_RTC_IRQ_BASE  PIC_IRQ(6, 1)

#define VIRT_GF_TTY_MMIO_BASE 0xff008000
#define VIRT_GF_TTY_IRQ_BASE  PIC_IRQ(1, 32)

#define VIRT_CTRL_MMIO_BASE 0xff009000
#define VIRT_CTRL_IRQ_BASE  PIC_IRQ(1, 1)

#define VIRT_VIRTIO_MMIO_BASE 0xff010000
#define VIRT_VIRTIO_IRQ_BASE  PIC_IRQ(2, 1)

#define BI_LAST         0x0000
#define BI_MACHTYPE     0x0001
#define BI_CPUTYPE      0x0002
#define BI_FPUTYPE      0x0003
#define BI_MMUTYPE      0x0004
#define BI_MEMCHUNK     0x0005
#define BI_RAMDISK      0x0006
#define BI_COMMAND_LINE 0x0007
#define BI_VIRT_QEMU_VERSION    0x8000
#define BI_VIRT_GF_PIC_BASE 0x8001
#define BI_VIRT_GF_RTC_BASE 0x8002
#define BI_VIRT_GF_TTY_BASE 0x8003
#define BI_VIRT_VIRTIO_BASE 0x8004
#define BI_VIRT_CTRL_BASE   0x8005


#define MACH_VIRT       14

#define CPUB_68040      2
#define CPU_68040       (1 << CPUB_68040)

#define FPUB_68040      2
#define FPU_68040       (1 << FPUB_68040)

#define MMUB_68040      2   /* Internal MMU */
#define MMU_68040       (1 << MMUB_68040)

	.text
	.globl _start
_start:
	lea banner, %a0
	clr.l %d0
banner_loop:
	move.b (%a0)+, %d0
	move.l %d0, VIRT_GF_TTY_MMIO_BASE
	tst.b (%a0)
	bne.W banner_loop

	lea VIRT_CTRL_MMIO_BASE, %a0
	move.l #FW_M68K, REG_PARAM(%a0)
	move.l #CMD_FW_LOAD, REG_CMD(%a0)
	move.l REG_PARAM(%a0), %d0
	cmp.l #RESULT_ERROR, %d0
	beq error
	move.l %d0, %a1   /* address of the end the kernel */
	move.l (%a1), %a2 /* entry point */
	move.l 4(%a1), %a3 /* address of the ramfs */
	move.l 8(%a1), %d1
	lea bootinfo, %a4
	move.w #((bootinfo_end - bootinfo) / 2 - 1), %d2
bootinfo_loop:
	move.w (%a4)+, (%a1)+
	dbf.w %d2, bootinfo_loop
	/* put kernel size */
        move.w #BI_MEMCHUNK, (%a1)+
	move.w #12, (%a1)+
	move.l #0, (%a1)+
	move.l #CMD_FW_RAMSIZE, REG_CMD(%a0)
	move.l REG_PARAM(%a0), (%a1)+
        /* put QEMU version */
	move.w #BI_VIRT_QEMU_VERSION, (%a1)+
	move.w #8, (%a1)+
	move.l #CMD_FW_QEMU_VERSION, REG_CMD(%a0)
	move.l REG_PARAM(%a0), (%a1)+
	/* put ramfs info */
        move.w #BI_RAMDISK, (%a1)+
	move.w #12, (%a1)+
	move.l %a3, (%a1)+ /* base */
	move.l %d1, (%a1)+ /* size */
	/* End-of-bootinfo tag */
        move.w #BI_LAST, (%a1)+
	move.w #4, (%a1)+
	/* jump into kernel */
	jra (%a2)
error:
	move.l #CMD_PANIC, REG_CMD(%a0)
loop:
	bra loop

banner:
	.string "Booting Petit boot firmware\n"

bootinfo:
	.word BI_MACHTYPE, 8
        .long MACH_VIRT
	.word BI_FPUTYPE, 8
        .long FPU_68040
	.word BI_MMUTYPE, 8
        .long MMU_68040
	.word BI_CPUTYPE, 8
        .long CPU_68040
	.word BI_VIRT_GF_PIC_BASE, 12
	.long VIRT_GF_PIC_MMIO_BASE, VIRT_GF_PIC_IRQ_BASE
	.word BI_VIRT_GF_RTC_BASE, 12
	.long VIRT_GF_RTC_MMIO_BASE, VIRT_GF_RTC_IRQ_BASE
	.word BI_VIRT_GF_TTY_BASE, 12
	.long VIRT_GF_TTY_MMIO_BASE, VIRT_GF_TTY_IRQ_BASE
	.word BI_VIRT_CTRL_BASE, 12
	.long VIRT_CTRL_MMIO_BASE, VIRT_CTRL_IRQ_BASE
	.word BI_VIRT_VIRTIO_BASE, 12
	.long VIRT_VIRTIO_MMIO_BASE, VIRT_VIRTIO_IRQ_BASE
bootinfo_cmdline:
         /* tag size must be a multiple of 4 */
#define TAG_COMMANG_LINE_SIZE 24
        .word BI_COMMAND_LINE, TAG_COMMANG_LINE_SIZE
	.string "console=ttyGF0 quiet"
bootinfo_end = bootinfo_cmdline + TAG_COMMANG_LINE_SIZE
