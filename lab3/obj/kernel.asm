
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	743010ef          	jal	ra,ffffffffc0201fae <memset>
    dtb_init();
ffffffffc0200070:	416000ef          	jal	ra,ffffffffc0200486 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	404000ef          	jal	ra,ffffffffc0200478 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f4850513          	addi	a0,a0,-184 # ffffffffc0201fc0 <etext>
ffffffffc0200080:	098000ef          	jal	ra,ffffffffc0200118 <cputs>

    print_kerninfo();
ffffffffc0200084:	0e4000ef          	jal	ra,ffffffffc0200168 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7ba000ef          	jal	ra,ffffffffc0200842 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	79a010ef          	jal	ra,ffffffffc0201826 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7b2000ef          	jal	ra,ffffffffc0200842 <idt_init>

    sbi_trigger_illegal_instruction();
ffffffffc0200094:	685010ef          	jal	ra,ffffffffc0201f18 <sbi_trigger_illegal_instruction>

    sbi_trigger_breakpoint();
ffffffffc0200098:	67b010ef          	jal	ra,ffffffffc0201f12 <sbi_trigger_breakpoint>
    
    clock_init();   // init clock interrupt
ffffffffc020009c:	39a000ef          	jal	ra,ffffffffc0200436 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc02000a0:	796000ef          	jal	ra,ffffffffc0200836 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc02000a4:	a001                	j	ffffffffc02000a4 <kern_init+0x50>

ffffffffc02000a6 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000a6:	1141                	addi	sp,sp,-16
ffffffffc02000a8:	e022                	sd	s0,0(sp)
ffffffffc02000aa:	e406                	sd	ra,8(sp)
ffffffffc02000ac:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ae:	3cc000ef          	jal	ra,ffffffffc020047a <cons_putc>
    (*cnt) ++;
ffffffffc02000b2:	401c                	lw	a5,0(s0)
}
ffffffffc02000b4:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000b6:	2785                	addiw	a5,a5,1
ffffffffc02000b8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000ba:	6402                	ld	s0,0(sp)
ffffffffc02000bc:	0141                	addi	sp,sp,16
ffffffffc02000be:	8082                	ret

ffffffffc02000c0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c0:	1101                	addi	sp,sp,-32
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a6 <cputch>
ffffffffc02000ce:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d2:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d4:	19f010ef          	jal	ra,ffffffffc0201a72 <vprintfmt>
    return cnt;
}
ffffffffc02000d8:	60e2                	ld	ra,24(sp)
ffffffffc02000da:	4532                	lw	a0,12(sp)
ffffffffc02000dc:	6105                	addi	sp,sp,32
ffffffffc02000de:	8082                	ret

ffffffffc02000e0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000e0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e2:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000e6:	8e2a                	mv	t3,a0
ffffffffc02000e8:	f42e                	sd	a1,40(sp)
ffffffffc02000ea:	f832                	sd	a2,48(sp)
ffffffffc02000ec:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ee:	00000517          	auipc	a0,0x0
ffffffffc02000f2:	fb850513          	addi	a0,a0,-72 # ffffffffc02000a6 <cputch>
ffffffffc02000f6:	004c                	addi	a1,sp,4
ffffffffc02000f8:	869a                	mv	a3,t1
ffffffffc02000fa:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000fc:	ec06                	sd	ra,24(sp)
ffffffffc02000fe:	e0ba                	sd	a4,64(sp)
ffffffffc0200100:	e4be                	sd	a5,72(sp)
ffffffffc0200102:	e8c2                	sd	a6,80(sp)
ffffffffc0200104:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200106:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200108:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020010a:	169010ef          	jal	ra,ffffffffc0201a72 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010e:	60e2                	ld	ra,24(sp)
ffffffffc0200110:	4512                	lw	a0,4(sp)
ffffffffc0200112:	6125                	addi	sp,sp,96
ffffffffc0200114:	8082                	ret

ffffffffc0200116 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200116:	a695                	j	ffffffffc020047a <cons_putc>

ffffffffc0200118 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200118:	1101                	addi	sp,sp,-32
ffffffffc020011a:	e822                	sd	s0,16(sp)
ffffffffc020011c:	ec06                	sd	ra,24(sp)
ffffffffc020011e:	e426                	sd	s1,8(sp)
ffffffffc0200120:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200122:	00054503          	lbu	a0,0(a0)
ffffffffc0200126:	c51d                	beqz	a0,ffffffffc0200154 <cputs+0x3c>
ffffffffc0200128:	0405                	addi	s0,s0,1
ffffffffc020012a:	4485                	li	s1,1
ffffffffc020012c:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020012e:	34c000ef          	jal	ra,ffffffffc020047a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200132:	00044503          	lbu	a0,0(s0)
ffffffffc0200136:	008487bb          	addw	a5,s1,s0
ffffffffc020013a:	0405                	addi	s0,s0,1
ffffffffc020013c:	f96d                	bnez	a0,ffffffffc020012e <cputs+0x16>
    (*cnt) ++;
ffffffffc020013e:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200142:	4529                	li	a0,10
ffffffffc0200144:	336000ef          	jal	ra,ffffffffc020047a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200148:	60e2                	ld	ra,24(sp)
ffffffffc020014a:	8522                	mv	a0,s0
ffffffffc020014c:	6442                	ld	s0,16(sp)
ffffffffc020014e:	64a2                	ld	s1,8(sp)
ffffffffc0200150:	6105                	addi	sp,sp,32
ffffffffc0200152:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200154:	4405                	li	s0,1
ffffffffc0200156:	b7f5                	j	ffffffffc0200142 <cputs+0x2a>

ffffffffc0200158 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200158:	1141                	addi	sp,sp,-16
ffffffffc020015a:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020015c:	326000ef          	jal	ra,ffffffffc0200482 <cons_getc>
ffffffffc0200160:	dd75                	beqz	a0,ffffffffc020015c <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
ffffffffc0200164:	0141                	addi	sp,sp,16
ffffffffc0200166:	8082                	ret

ffffffffc0200168 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200168:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	e7650513          	addi	a0,a0,-394 # ffffffffc0201fe0 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200172:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200174:	f6dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200178:	00000597          	auipc	a1,0x0
ffffffffc020017c:	edc58593          	addi	a1,a1,-292 # ffffffffc0200054 <kern_init>
ffffffffc0200180:	00002517          	auipc	a0,0x2
ffffffffc0200184:	e8050513          	addi	a0,a0,-384 # ffffffffc0202000 <etext+0x40>
ffffffffc0200188:	f59ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020018c:	00002597          	auipc	a1,0x2
ffffffffc0200190:	e3458593          	addi	a1,a1,-460 # ffffffffc0201fc0 <etext>
ffffffffc0200194:	00002517          	auipc	a0,0x2
ffffffffc0200198:	e8c50513          	addi	a0,a0,-372 # ffffffffc0202020 <etext+0x60>
ffffffffc020019c:	f45ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a0:	00007597          	auipc	a1,0x7
ffffffffc02001a4:	e8858593          	addi	a1,a1,-376 # ffffffffc0207028 <free_area>
ffffffffc02001a8:	00002517          	auipc	a0,0x2
ffffffffc02001ac:	e9850513          	addi	a0,a0,-360 # ffffffffc0202040 <etext+0x80>
ffffffffc02001b0:	f31ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b4:	00007597          	auipc	a1,0x7
ffffffffc02001b8:	2ec58593          	addi	a1,a1,748 # ffffffffc02074a0 <end>
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	ea450513          	addi	a0,a0,-348 # ffffffffc0202060 <etext+0xa0>
ffffffffc02001c4:	f1dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c8:	00007597          	auipc	a1,0x7
ffffffffc02001cc:	6d758593          	addi	a1,a1,1751 # ffffffffc020789f <end+0x3ff>
ffffffffc02001d0:	00000797          	auipc	a5,0x0
ffffffffc02001d4:	e8478793          	addi	a5,a5,-380 # ffffffffc0200054 <kern_init>
ffffffffc02001d8:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001dc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001e0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e6:	95be                	add	a1,a1,a5
ffffffffc02001e8:	85a9                	srai	a1,a1,0xa
ffffffffc02001ea:	00002517          	auipc	a0,0x2
ffffffffc02001ee:	e9650513          	addi	a0,a0,-362 # ffffffffc0202080 <etext+0xc0>
}
ffffffffc02001f2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f4:	b5f5                	j	ffffffffc02000e0 <cprintf>

ffffffffc02001f6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f8:	00002617          	auipc	a2,0x2
ffffffffc02001fc:	eb860613          	addi	a2,a2,-328 # ffffffffc02020b0 <etext+0xf0>
ffffffffc0200200:	04d00593          	li	a1,77
ffffffffc0200204:	00002517          	auipc	a0,0x2
ffffffffc0200208:	ec450513          	addi	a0,a0,-316 # ffffffffc02020c8 <etext+0x108>
void print_stackframe(void) {
ffffffffc020020c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020e:	1cc000ef          	jal	ra,ffffffffc02003da <__panic>

ffffffffc0200212 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200212:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200214:	00002617          	auipc	a2,0x2
ffffffffc0200218:	ecc60613          	addi	a2,a2,-308 # ffffffffc02020e0 <etext+0x120>
ffffffffc020021c:	00002597          	auipc	a1,0x2
ffffffffc0200220:	ee458593          	addi	a1,a1,-284 # ffffffffc0202100 <etext+0x140>
ffffffffc0200224:	00002517          	auipc	a0,0x2
ffffffffc0200228:	ee450513          	addi	a0,a0,-284 # ffffffffc0202108 <etext+0x148>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022c:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020022e:	eb3ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200232:	00002617          	auipc	a2,0x2
ffffffffc0200236:	ee660613          	addi	a2,a2,-282 # ffffffffc0202118 <etext+0x158>
ffffffffc020023a:	00002597          	auipc	a1,0x2
ffffffffc020023e:	f0658593          	addi	a1,a1,-250 # ffffffffc0202140 <etext+0x180>
ffffffffc0200242:	00002517          	auipc	a0,0x2
ffffffffc0200246:	ec650513          	addi	a0,a0,-314 # ffffffffc0202108 <etext+0x148>
ffffffffc020024a:	e97ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc020024e:	00002617          	auipc	a2,0x2
ffffffffc0200252:	f0260613          	addi	a2,a2,-254 # ffffffffc0202150 <etext+0x190>
ffffffffc0200256:	00002597          	auipc	a1,0x2
ffffffffc020025a:	f1a58593          	addi	a1,a1,-230 # ffffffffc0202170 <etext+0x1b0>
ffffffffc020025e:	00002517          	auipc	a0,0x2
ffffffffc0200262:	eaa50513          	addi	a0,a0,-342 # ffffffffc0202108 <etext+0x148>
ffffffffc0200266:	e7bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    return 0;
}
ffffffffc020026a:	60a2                	ld	ra,8(sp)
ffffffffc020026c:	4501                	li	a0,0
ffffffffc020026e:	0141                	addi	sp,sp,16
ffffffffc0200270:	8082                	ret

ffffffffc0200272 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200272:	1141                	addi	sp,sp,-16
ffffffffc0200274:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200276:	ef3ff0ef          	jal	ra,ffffffffc0200168 <print_kerninfo>
    return 0;
}
ffffffffc020027a:	60a2                	ld	ra,8(sp)
ffffffffc020027c:	4501                	li	a0,0
ffffffffc020027e:	0141                	addi	sp,sp,16
ffffffffc0200280:	8082                	ret

ffffffffc0200282 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1141                	addi	sp,sp,-16
ffffffffc0200284:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200286:	f71ff0ef          	jal	ra,ffffffffc02001f6 <print_stackframe>
    return 0;
}
ffffffffc020028a:	60a2                	ld	ra,8(sp)
ffffffffc020028c:	4501                	li	a0,0
ffffffffc020028e:	0141                	addi	sp,sp,16
ffffffffc0200290:	8082                	ret

ffffffffc0200292 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200292:	7115                	addi	sp,sp,-224
ffffffffc0200294:	ed5e                	sd	s7,152(sp)
ffffffffc0200296:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200298:	00002517          	auipc	a0,0x2
ffffffffc020029c:	ee850513          	addi	a0,a0,-280 # ffffffffc0202180 <etext+0x1c0>
kmonitor(struct trapframe *tf) {
ffffffffc02002a0:	ed86                	sd	ra,216(sp)
ffffffffc02002a2:	e9a2                	sd	s0,208(sp)
ffffffffc02002a4:	e5a6                	sd	s1,200(sp)
ffffffffc02002a6:	e1ca                	sd	s2,192(sp)
ffffffffc02002a8:	fd4e                	sd	s3,184(sp)
ffffffffc02002aa:	f952                	sd	s4,176(sp)
ffffffffc02002ac:	f556                	sd	s5,168(sp)
ffffffffc02002ae:	f15a                	sd	s6,160(sp)
ffffffffc02002b0:	e962                	sd	s8,144(sp)
ffffffffc02002b2:	e566                	sd	s9,136(sp)
ffffffffc02002b4:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b6:	e2bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002ba:	00002517          	auipc	a0,0x2
ffffffffc02002be:	eee50513          	addi	a0,a0,-274 # ffffffffc02021a8 <etext+0x1e8>
ffffffffc02002c2:	e1fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    if (tf != NULL) {
ffffffffc02002c6:	000b8563          	beqz	s7,ffffffffc02002d0 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002ca:	855e                	mv	a0,s7
ffffffffc02002cc:	756000ef          	jal	ra,ffffffffc0200a22 <print_trapframe>
ffffffffc02002d0:	00002c17          	auipc	s8,0x2
ffffffffc02002d4:	f48c0c13          	addi	s8,s8,-184 # ffffffffc0202218 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d8:	00002917          	auipc	s2,0x2
ffffffffc02002dc:	ef890913          	addi	s2,s2,-264 # ffffffffc02021d0 <etext+0x210>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e0:	00002497          	auipc	s1,0x2
ffffffffc02002e4:	ef848493          	addi	s1,s1,-264 # ffffffffc02021d8 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc02002e8:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002ea:	00002b17          	auipc	s6,0x2
ffffffffc02002ee:	ef6b0b13          	addi	s6,s6,-266 # ffffffffc02021e0 <etext+0x220>
        argv[argc ++] = buf;
ffffffffc02002f2:	00002a17          	auipc	s4,0x2
ffffffffc02002f6:	e0ea0a13          	addi	s4,s4,-498 # ffffffffc0202100 <etext+0x140>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fc:	854a                	mv	a0,s2
ffffffffc02002fe:	2f7010ef          	jal	ra,ffffffffc0201df4 <readline>
ffffffffc0200302:	842a                	mv	s0,a0
ffffffffc0200304:	dd65                	beqz	a0,ffffffffc02002fc <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200306:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030c:	e1bd                	bnez	a1,ffffffffc0200372 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020030e:	fe0c87e3          	beqz	s9,ffffffffc02002fc <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200312:	6582                	ld	a1,0(sp)
ffffffffc0200314:	00002d17          	auipc	s10,0x2
ffffffffc0200318:	f04d0d13          	addi	s10,s10,-252 # ffffffffc0202218 <commands>
        argv[argc ++] = buf;
ffffffffc020031c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031e:	4401                	li	s0,0
ffffffffc0200320:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200322:	433010ef          	jal	ra,ffffffffc0201f54 <strcmp>
ffffffffc0200326:	c919                	beqz	a0,ffffffffc020033c <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200328:	2405                	addiw	s0,s0,1
ffffffffc020032a:	0b540063          	beq	s0,s5,ffffffffc02003ca <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	000d3503          	ld	a0,0(s10)
ffffffffc0200332:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200334:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200336:	41f010ef          	jal	ra,ffffffffc0201f54 <strcmp>
ffffffffc020033a:	f57d                	bnez	a0,ffffffffc0200328 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020033c:	00141793          	slli	a5,s0,0x1
ffffffffc0200340:	97a2                	add	a5,a5,s0
ffffffffc0200342:	078e                	slli	a5,a5,0x3
ffffffffc0200344:	97e2                	add	a5,a5,s8
ffffffffc0200346:	6b9c                	ld	a5,16(a5)
ffffffffc0200348:	865e                	mv	a2,s7
ffffffffc020034a:	002c                	addi	a1,sp,8
ffffffffc020034c:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200350:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200352:	fa0555e3          	bgez	a0,ffffffffc02002fc <kmonitor+0x6a>
}
ffffffffc0200356:	60ee                	ld	ra,216(sp)
ffffffffc0200358:	644e                	ld	s0,208(sp)
ffffffffc020035a:	64ae                	ld	s1,200(sp)
ffffffffc020035c:	690e                	ld	s2,192(sp)
ffffffffc020035e:	79ea                	ld	s3,184(sp)
ffffffffc0200360:	7a4a                	ld	s4,176(sp)
ffffffffc0200362:	7aaa                	ld	s5,168(sp)
ffffffffc0200364:	7b0a                	ld	s6,160(sp)
ffffffffc0200366:	6bea                	ld	s7,152(sp)
ffffffffc0200368:	6c4a                	ld	s8,144(sp)
ffffffffc020036a:	6caa                	ld	s9,136(sp)
ffffffffc020036c:	6d0a                	ld	s10,128(sp)
ffffffffc020036e:	612d                	addi	sp,sp,224
ffffffffc0200370:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200372:	8526                	mv	a0,s1
ffffffffc0200374:	425010ef          	jal	ra,ffffffffc0201f98 <strchr>
ffffffffc0200378:	c901                	beqz	a0,ffffffffc0200388 <kmonitor+0xf6>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020037e:	00040023          	sb	zero,0(s0)
ffffffffc0200382:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200384:	d5c9                	beqz	a1,ffffffffc020030e <kmonitor+0x7c>
ffffffffc0200386:	b7f5                	j	ffffffffc0200372 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200388:	00044783          	lbu	a5,0(s0)
ffffffffc020038c:	d3c9                	beqz	a5,ffffffffc020030e <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc020038e:	033c8963          	beq	s9,s3,ffffffffc02003c0 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200392:	003c9793          	slli	a5,s9,0x3
ffffffffc0200396:	0118                	addi	a4,sp,128
ffffffffc0200398:	97ba                	add	a5,a5,a4
ffffffffc020039a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a2:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a4:	e591                	bnez	a1,ffffffffc02003b0 <kmonitor+0x11e>
ffffffffc02003a6:	b7b5                	j	ffffffffc0200312 <kmonitor+0x80>
ffffffffc02003a8:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003ac:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ae:	d1a5                	beqz	a1,ffffffffc020030e <kmonitor+0x7c>
ffffffffc02003b0:	8526                	mv	a0,s1
ffffffffc02003b2:	3e7010ef          	jal	ra,ffffffffc0201f98 <strchr>
ffffffffc02003b6:	d96d                	beqz	a0,ffffffffc02003a8 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b8:	00044583          	lbu	a1,0(s0)
ffffffffc02003bc:	d9a9                	beqz	a1,ffffffffc020030e <kmonitor+0x7c>
ffffffffc02003be:	bf55                	j	ffffffffc0200372 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c0:	45c1                	li	a1,16
ffffffffc02003c2:	855a                	mv	a0,s6
ffffffffc02003c4:	d1dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02003c8:	b7e9                	j	ffffffffc0200392 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003ca:	6582                	ld	a1,0(sp)
ffffffffc02003cc:	00002517          	auipc	a0,0x2
ffffffffc02003d0:	e3450513          	addi	a0,a0,-460 # ffffffffc0202200 <etext+0x240>
ffffffffc02003d4:	d0dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
ffffffffc02003d8:	b715                	j	ffffffffc02002fc <kmonitor+0x6a>

ffffffffc02003da <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003da:	00007317          	auipc	t1,0x7
ffffffffc02003de:	06630313          	addi	t1,t1,102 # ffffffffc0207440 <is_panic>
ffffffffc02003e2:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003e6:	715d                	addi	sp,sp,-80
ffffffffc02003e8:	ec06                	sd	ra,24(sp)
ffffffffc02003ea:	e822                	sd	s0,16(sp)
ffffffffc02003ec:	f436                	sd	a3,40(sp)
ffffffffc02003ee:	f83a                	sd	a4,48(sp)
ffffffffc02003f0:	fc3e                	sd	a5,56(sp)
ffffffffc02003f2:	e0c2                	sd	a6,64(sp)
ffffffffc02003f4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003f6:	020e1a63          	bnez	t3,ffffffffc020042a <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003fa:	4785                	li	a5,1
ffffffffc02003fc:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200400:	8432                	mv	s0,a2
ffffffffc0200402:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200404:	862e                	mv	a2,a1
ffffffffc0200406:	85aa                	mv	a1,a0
ffffffffc0200408:	00002517          	auipc	a0,0x2
ffffffffc020040c:	e5850513          	addi	a0,a0,-424 # ffffffffc0202260 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200410:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200412:	ccfff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200416:	65a2                	ld	a1,8(sp)
ffffffffc0200418:	8522                	mv	a0,s0
ffffffffc020041a:	ca7ff0ef          	jal	ra,ffffffffc02000c0 <vcprintf>
    cprintf("\n");
ffffffffc020041e:	00002517          	auipc	a0,0x2
ffffffffc0200422:	c8a50513          	addi	a0,a0,-886 # ffffffffc02020a8 <etext+0xe8>
ffffffffc0200426:	cbbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020042a:	412000ef          	jal	ra,ffffffffc020083c <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020042e:	4501                	li	a0,0
ffffffffc0200430:	e63ff0ef          	jal	ra,ffffffffc0200292 <kmonitor>
    while (1) {
ffffffffc0200434:	bfed                	j	ffffffffc020042e <__panic+0x54>

ffffffffc0200436 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200436:	1141                	addi	sp,sp,-16
ffffffffc0200438:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020043a:	02000793          	li	a5,32
ffffffffc020043e:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200442:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200446:	67e1                	lui	a5,0x18
ffffffffc0200448:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020044c:	953e                	add	a0,a0,a5
ffffffffc020044e:	275010ef          	jal	ra,ffffffffc0201ec2 <sbi_set_timer>
}
ffffffffc0200452:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200454:	00007797          	auipc	a5,0x7
ffffffffc0200458:	fe07ba23          	sd	zero,-12(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020045c:	00002517          	auipc	a0,0x2
ffffffffc0200460:	e2450513          	addi	a0,a0,-476 # ffffffffc0202280 <commands+0x68>
}
ffffffffc0200464:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200466:	b9ad                	j	ffffffffc02000e0 <cprintf>

ffffffffc0200468 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200468:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020046c:	67e1                	lui	a5,0x18
ffffffffc020046e:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200472:	953e                	add	a0,a0,a5
ffffffffc0200474:	24f0106f          	j	ffffffffc0201ec2 <sbi_set_timer>

ffffffffc0200478 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200478:	8082                	ret

ffffffffc020047a <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020047a:	0ff57513          	zext.b	a0,a0
ffffffffc020047e:	22b0106f          	j	ffffffffc0201ea8 <sbi_console_putchar>

ffffffffc0200482 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200482:	25b0106f          	j	ffffffffc0201edc <sbi_console_getchar>

ffffffffc0200486 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200486:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200488:	00002517          	auipc	a0,0x2
ffffffffc020048c:	e1850513          	addi	a0,a0,-488 # ffffffffc02022a0 <commands+0x88>
void dtb_init(void) {
ffffffffc0200490:	fc86                	sd	ra,120(sp)
ffffffffc0200492:	f8a2                	sd	s0,112(sp)
ffffffffc0200494:	e8d2                	sd	s4,80(sp)
ffffffffc0200496:	f4a6                	sd	s1,104(sp)
ffffffffc0200498:	f0ca                	sd	s2,96(sp)
ffffffffc020049a:	ecce                	sd	s3,88(sp)
ffffffffc020049c:	e4d6                	sd	s5,72(sp)
ffffffffc020049e:	e0da                	sd	s6,64(sp)
ffffffffc02004a0:	fc5e                	sd	s7,56(sp)
ffffffffc02004a2:	f862                	sd	s8,48(sp)
ffffffffc02004a4:	f466                	sd	s9,40(sp)
ffffffffc02004a6:	f06a                	sd	s10,32(sp)
ffffffffc02004a8:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004aa:	c37ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004ae:	00007597          	auipc	a1,0x7
ffffffffc02004b2:	b525b583          	ld	a1,-1198(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004b6:	00002517          	auipc	a0,0x2
ffffffffc02004ba:	dfa50513          	addi	a0,a0,-518 # ffffffffc02022b0 <commands+0x98>
ffffffffc02004be:	c23ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004c2:	00007417          	auipc	s0,0x7
ffffffffc02004c6:	b4640413          	addi	s0,s0,-1210 # ffffffffc0207008 <boot_dtb>
ffffffffc02004ca:	600c                	ld	a1,0(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	df450513          	addi	a0,a0,-524 # ffffffffc02022c0 <commands+0xa8>
ffffffffc02004d4:	c0dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004d8:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004dc:	00002517          	auipc	a0,0x2
ffffffffc02004e0:	dfc50513          	addi	a0,a0,-516 # ffffffffc02022d8 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004e4:	120a0463          	beqz	s4,ffffffffc020060c <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004e8:	57f5                	li	a5,-3
ffffffffc02004ea:	07fa                	slli	a5,a5,0x1e
ffffffffc02004ec:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004f0:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f2:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f6:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004fc:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200508:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050c:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050e:	8ec9                	or	a3,a3,a0
ffffffffc0200510:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200514:	1b7d                	addi	s6,s6,-1
ffffffffc0200516:	0167f7b3          	and	a5,a5,s6
ffffffffc020051a:	8dd5                	or	a1,a1,a3
ffffffffc020051c:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020051e:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200522:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200524:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200528:	10f59163          	bne	a1,a5,ffffffffc020062a <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020052c:	471c                	lw	a5,8(a4)
ffffffffc020052e:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200530:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200536:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020053a:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054a:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054e:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200552:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200556:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055a:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020055c:	01146433          	or	s0,s0,a7
ffffffffc0200560:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200564:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200568:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020056e:	8c49                	or	s0,s0,a0
ffffffffc0200570:	0166f6b3          	and	a3,a3,s6
ffffffffc0200574:	00ca6a33          	or	s4,s4,a2
ffffffffc0200578:	0167f7b3          	and	a5,a5,s6
ffffffffc020057c:	8c55                	or	s0,s0,a3
ffffffffc020057e:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200582:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200584:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200586:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200588:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020058c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020058e:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200590:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200594:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200596:	00002917          	auipc	s2,0x2
ffffffffc020059a:	d9290913          	addi	s2,s2,-622 # ffffffffc0202328 <commands+0x110>
ffffffffc020059e:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005a0:	4d91                	li	s11,4
ffffffffc02005a2:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005a4:	00002497          	auipc	s1,0x2
ffffffffc02005a8:	d7c48493          	addi	s1,s1,-644 # ffffffffc0202320 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005ac:	000a2703          	lw	a4,0(s4)
ffffffffc02005b0:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b4:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005b8:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005bc:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c0:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c4:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005c8:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ca:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ce:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005d2:	8fd5                	or	a5,a5,a3
ffffffffc02005d4:	00eb7733          	and	a4,s6,a4
ffffffffc02005d8:	8fd9                	or	a5,a5,a4
ffffffffc02005da:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005dc:	09778c63          	beq	a5,s7,ffffffffc0200674 <dtb_init+0x1ee>
ffffffffc02005e0:	00fbea63          	bltu	s7,a5,ffffffffc02005f4 <dtb_init+0x16e>
ffffffffc02005e4:	07a78663          	beq	a5,s10,ffffffffc0200650 <dtb_init+0x1ca>
ffffffffc02005e8:	4709                	li	a4,2
ffffffffc02005ea:	00e79763          	bne	a5,a4,ffffffffc02005f8 <dtb_init+0x172>
ffffffffc02005ee:	4c81                	li	s9,0
ffffffffc02005f0:	8a56                	mv	s4,s5
ffffffffc02005f2:	bf6d                	j	ffffffffc02005ac <dtb_init+0x126>
ffffffffc02005f4:	ffb78ee3          	beq	a5,s11,ffffffffc02005f0 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005f8:	00002517          	auipc	a0,0x2
ffffffffc02005fc:	da850513          	addi	a0,a0,-600 # ffffffffc02023a0 <commands+0x188>
ffffffffc0200600:	ae1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200604:	00002517          	auipc	a0,0x2
ffffffffc0200608:	dd450513          	addi	a0,a0,-556 # ffffffffc02023d8 <commands+0x1c0>
}
ffffffffc020060c:	7446                	ld	s0,112(sp)
ffffffffc020060e:	70e6                	ld	ra,120(sp)
ffffffffc0200610:	74a6                	ld	s1,104(sp)
ffffffffc0200612:	7906                	ld	s2,96(sp)
ffffffffc0200614:	69e6                	ld	s3,88(sp)
ffffffffc0200616:	6a46                	ld	s4,80(sp)
ffffffffc0200618:	6aa6                	ld	s5,72(sp)
ffffffffc020061a:	6b06                	ld	s6,64(sp)
ffffffffc020061c:	7be2                	ld	s7,56(sp)
ffffffffc020061e:	7c42                	ld	s8,48(sp)
ffffffffc0200620:	7ca2                	ld	s9,40(sp)
ffffffffc0200622:	7d02                	ld	s10,32(sp)
ffffffffc0200624:	6de2                	ld	s11,24(sp)
ffffffffc0200626:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200628:	bc65                	j	ffffffffc02000e0 <cprintf>
}
ffffffffc020062a:	7446                	ld	s0,112(sp)
ffffffffc020062c:	70e6                	ld	ra,120(sp)
ffffffffc020062e:	74a6                	ld	s1,104(sp)
ffffffffc0200630:	7906                	ld	s2,96(sp)
ffffffffc0200632:	69e6                	ld	s3,88(sp)
ffffffffc0200634:	6a46                	ld	s4,80(sp)
ffffffffc0200636:	6aa6                	ld	s5,72(sp)
ffffffffc0200638:	6b06                	ld	s6,64(sp)
ffffffffc020063a:	7be2                	ld	s7,56(sp)
ffffffffc020063c:	7c42                	ld	s8,48(sp)
ffffffffc020063e:	7ca2                	ld	s9,40(sp)
ffffffffc0200640:	7d02                	ld	s10,32(sp)
ffffffffc0200642:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200644:	00002517          	auipc	a0,0x2
ffffffffc0200648:	cb450513          	addi	a0,a0,-844 # ffffffffc02022f8 <commands+0xe0>
}
ffffffffc020064c:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020064e:	bc49                	j	ffffffffc02000e0 <cprintf>
                int name_len = strlen(name);
ffffffffc0200650:	8556                	mv	a0,s5
ffffffffc0200652:	0cd010ef          	jal	ra,ffffffffc0201f1e <strlen>
ffffffffc0200656:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200658:	4619                	li	a2,6
ffffffffc020065a:	85a6                	mv	a1,s1
ffffffffc020065c:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020065e:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200660:	113010ef          	jal	ra,ffffffffc0201f72 <strncmp>
ffffffffc0200664:	e111                	bnez	a0,ffffffffc0200668 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200666:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200668:	0a91                	addi	s5,s5,4
ffffffffc020066a:	9ad2                	add	s5,s5,s4
ffffffffc020066c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200670:	8a56                	mv	s4,s5
ffffffffc0200672:	bf2d                	j	ffffffffc02005ac <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200674:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200678:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200680:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200684:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200688:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020068c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200690:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200694:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200698:	0087979b          	slliw	a5,a5,0x8
ffffffffc020069c:	00eaeab3          	or	s5,s5,a4
ffffffffc02006a0:	00fb77b3          	and	a5,s6,a5
ffffffffc02006a4:	00faeab3          	or	s5,s5,a5
ffffffffc02006a8:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006aa:	000c9c63          	bnez	s9,ffffffffc02006c2 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006ae:	1a82                	slli	s5,s5,0x20
ffffffffc02006b0:	00368793          	addi	a5,a3,3
ffffffffc02006b4:	020ada93          	srli	s5,s5,0x20
ffffffffc02006b8:	9abe                	add	s5,s5,a5
ffffffffc02006ba:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006be:	8a56                	mv	s4,s5
ffffffffc02006c0:	b5f5                	j	ffffffffc02005ac <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c2:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006c6:	85ca                	mv	a1,s2
ffffffffc02006c8:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006d6:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006da:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006de:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e4:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e8:	8d59                	or	a0,a0,a4
ffffffffc02006ea:	00fb77b3          	and	a5,s6,a5
ffffffffc02006ee:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006f0:	1502                	slli	a0,a0,0x20
ffffffffc02006f2:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f4:	9522                	add	a0,a0,s0
ffffffffc02006f6:	05f010ef          	jal	ra,ffffffffc0201f54 <strcmp>
ffffffffc02006fa:	66a2                	ld	a3,8(sp)
ffffffffc02006fc:	f94d                	bnez	a0,ffffffffc02006ae <dtb_init+0x228>
ffffffffc02006fe:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006ae <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200702:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200706:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020070a:	00002517          	auipc	a0,0x2
ffffffffc020070e:	c2650513          	addi	a0,a0,-986 # ffffffffc0202330 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200712:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020071a:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071e:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200722:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0187d693          	srli	a3,a5,0x18
ffffffffc0200732:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200736:	0087579b          	srliw	a5,a4,0x8
ffffffffc020073a:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073e:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200742:	010f6f33          	or	t5,t5,a6
ffffffffc0200746:	0187529b          	srliw	t0,a4,0x18
ffffffffc020074a:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200752:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200756:	0186f6b3          	and	a3,a3,s8
ffffffffc020075a:	01859e1b          	slliw	t3,a1,0x18
ffffffffc020075e:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200762:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200766:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	8361                	srli	a4,a4,0x18
ffffffffc020076c:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200770:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200774:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200778:	00cb7633          	and	a2,s6,a2
ffffffffc020077c:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200780:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200784:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200790:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200794:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200798:	011b78b3          	and	a7,s6,a7
ffffffffc020079c:	005eeeb3          	or	t4,t4,t0
ffffffffc02007a0:	00c6e733          	or	a4,a3,a2
ffffffffc02007a4:	006c6c33          	or	s8,s8,t1
ffffffffc02007a8:	010b76b3          	and	a3,s6,a6
ffffffffc02007ac:	00bb7b33          	and	s6,s6,a1
ffffffffc02007b0:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007b4:	016c6b33          	or	s6,s8,s6
ffffffffc02007b8:	01146433          	or	s0,s0,a7
ffffffffc02007bc:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007be:	1702                	slli	a4,a4,0x20
ffffffffc02007c0:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c2:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c4:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c6:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c8:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007cc:	0167eb33          	or	s6,a5,s6
ffffffffc02007d0:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007d2:	90fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007d6:	85a2                	mv	a1,s0
ffffffffc02007d8:	00002517          	auipc	a0,0x2
ffffffffc02007dc:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202350 <commands+0x138>
ffffffffc02007e0:	901ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007e4:	014b5613          	srli	a2,s6,0x14
ffffffffc02007e8:	85da                	mv	a1,s6
ffffffffc02007ea:	00002517          	auipc	a0,0x2
ffffffffc02007ee:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0202368 <commands+0x150>
ffffffffc02007f2:	8efff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007f6:	008b05b3          	add	a1,s6,s0
ffffffffc02007fa:	15fd                	addi	a1,a1,-1
ffffffffc02007fc:	00002517          	auipc	a0,0x2
ffffffffc0200800:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202388 <commands+0x170>
ffffffffc0200804:	8ddff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200808:	00002517          	auipc	a0,0x2
ffffffffc020080c:	bd050513          	addi	a0,a0,-1072 # ffffffffc02023d8 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200810:	00007797          	auipc	a5,0x7
ffffffffc0200814:	c487b023          	sd	s0,-960(a5) # ffffffffc0207450 <memory_base>
        memory_size = mem_size;
ffffffffc0200818:	00007797          	auipc	a5,0x7
ffffffffc020081c:	c567b023          	sd	s6,-960(a5) # ffffffffc0207458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200820:	b3f5                	j	ffffffffc020060c <dtb_init+0x186>

ffffffffc0200822 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200822:	00007517          	auipc	a0,0x7
ffffffffc0200826:	c2e53503          	ld	a0,-978(a0) # ffffffffc0207450 <memory_base>
ffffffffc020082a:	8082                	ret

ffffffffc020082c <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020082c:	00007517          	auipc	a0,0x7
ffffffffc0200830:	c2c53503          	ld	a0,-980(a0) # ffffffffc0207458 <memory_size>
ffffffffc0200834:	8082                	ret

ffffffffc0200836 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200836:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020083a:	8082                	ret

ffffffffc020083c <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020083c:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200840:	8082                	ret

ffffffffc0200842 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200842:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200846:	00000797          	auipc	a5,0x0
ffffffffc020084a:	39a78793          	addi	a5,a5,922 # ffffffffc0200be0 <__alltraps>
ffffffffc020084e:	10579073          	csrw	stvec,a5
}
ffffffffc0200852:	8082                	ret

ffffffffc0200854 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200854:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200856:	1141                	addi	sp,sp,-16
ffffffffc0200858:	e022                	sd	s0,0(sp)
ffffffffc020085a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020085c:	00002517          	auipc	a0,0x2
ffffffffc0200860:	b9450513          	addi	a0,a0,-1132 # ffffffffc02023f0 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200864:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200866:	87bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020086a:	640c                	ld	a1,8(s0)
ffffffffc020086c:	00002517          	auipc	a0,0x2
ffffffffc0200870:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0202408 <commands+0x1f0>
ffffffffc0200874:	86dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200878:	680c                	ld	a1,16(s0)
ffffffffc020087a:	00002517          	auipc	a0,0x2
ffffffffc020087e:	ba650513          	addi	a0,a0,-1114 # ffffffffc0202420 <commands+0x208>
ffffffffc0200882:	85fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200886:	6c0c                	ld	a1,24(s0)
ffffffffc0200888:	00002517          	auipc	a0,0x2
ffffffffc020088c:	bb050513          	addi	a0,a0,-1104 # ffffffffc0202438 <commands+0x220>
ffffffffc0200890:	851ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200894:	700c                	ld	a1,32(s0)
ffffffffc0200896:	00002517          	auipc	a0,0x2
ffffffffc020089a:	bba50513          	addi	a0,a0,-1094 # ffffffffc0202450 <commands+0x238>
ffffffffc020089e:	843ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008a2:	740c                	ld	a1,40(s0)
ffffffffc02008a4:	00002517          	auipc	a0,0x2
ffffffffc02008a8:	bc450513          	addi	a0,a0,-1084 # ffffffffc0202468 <commands+0x250>
ffffffffc02008ac:	835ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008b0:	780c                	ld	a1,48(s0)
ffffffffc02008b2:	00002517          	auipc	a0,0x2
ffffffffc02008b6:	bce50513          	addi	a0,a0,-1074 # ffffffffc0202480 <commands+0x268>
ffffffffc02008ba:	827ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008be:	7c0c                	ld	a1,56(s0)
ffffffffc02008c0:	00002517          	auipc	a0,0x2
ffffffffc02008c4:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202498 <commands+0x280>
ffffffffc02008c8:	819ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008cc:	602c                	ld	a1,64(s0)
ffffffffc02008ce:	00002517          	auipc	a0,0x2
ffffffffc02008d2:	be250513          	addi	a0,a0,-1054 # ffffffffc02024b0 <commands+0x298>
ffffffffc02008d6:	80bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008da:	642c                	ld	a1,72(s0)
ffffffffc02008dc:	00002517          	auipc	a0,0x2
ffffffffc02008e0:	bec50513          	addi	a0,a0,-1044 # ffffffffc02024c8 <commands+0x2b0>
ffffffffc02008e4:	ffcff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e8:	682c                	ld	a1,80(s0)
ffffffffc02008ea:	00002517          	auipc	a0,0x2
ffffffffc02008ee:	bf650513          	addi	a0,a0,-1034 # ffffffffc02024e0 <commands+0x2c8>
ffffffffc02008f2:	feeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008f6:	6c2c                	ld	a1,88(s0)
ffffffffc02008f8:	00002517          	auipc	a0,0x2
ffffffffc02008fc:	c0050513          	addi	a0,a0,-1024 # ffffffffc02024f8 <commands+0x2e0>
ffffffffc0200900:	fe0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200904:	702c                	ld	a1,96(s0)
ffffffffc0200906:	00002517          	auipc	a0,0x2
ffffffffc020090a:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202510 <commands+0x2f8>
ffffffffc020090e:	fd2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200912:	742c                	ld	a1,104(s0)
ffffffffc0200914:	00002517          	auipc	a0,0x2
ffffffffc0200918:	c1450513          	addi	a0,a0,-1004 # ffffffffc0202528 <commands+0x310>
ffffffffc020091c:	fc4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200920:	782c                	ld	a1,112(s0)
ffffffffc0200922:	00002517          	auipc	a0,0x2
ffffffffc0200926:	c1e50513          	addi	a0,a0,-994 # ffffffffc0202540 <commands+0x328>
ffffffffc020092a:	fb6ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020092e:	7c2c                	ld	a1,120(s0)
ffffffffc0200930:	00002517          	auipc	a0,0x2
ffffffffc0200934:	c2850513          	addi	a0,a0,-984 # ffffffffc0202558 <commands+0x340>
ffffffffc0200938:	fa8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020093c:	604c                	ld	a1,128(s0)
ffffffffc020093e:	00002517          	auipc	a0,0x2
ffffffffc0200942:	c3250513          	addi	a0,a0,-974 # ffffffffc0202570 <commands+0x358>
ffffffffc0200946:	f9aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020094a:	644c                	ld	a1,136(s0)
ffffffffc020094c:	00002517          	auipc	a0,0x2
ffffffffc0200950:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202588 <commands+0x370>
ffffffffc0200954:	f8cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200958:	684c                	ld	a1,144(s0)
ffffffffc020095a:	00002517          	auipc	a0,0x2
ffffffffc020095e:	c4650513          	addi	a0,a0,-954 # ffffffffc02025a0 <commands+0x388>
ffffffffc0200962:	f7eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200966:	6c4c                	ld	a1,152(s0)
ffffffffc0200968:	00002517          	auipc	a0,0x2
ffffffffc020096c:	c5050513          	addi	a0,a0,-944 # ffffffffc02025b8 <commands+0x3a0>
ffffffffc0200970:	f70ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200974:	704c                	ld	a1,160(s0)
ffffffffc0200976:	00002517          	auipc	a0,0x2
ffffffffc020097a:	c5a50513          	addi	a0,a0,-934 # ffffffffc02025d0 <commands+0x3b8>
ffffffffc020097e:	f62ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200982:	744c                	ld	a1,168(s0)
ffffffffc0200984:	00002517          	auipc	a0,0x2
ffffffffc0200988:	c6450513          	addi	a0,a0,-924 # ffffffffc02025e8 <commands+0x3d0>
ffffffffc020098c:	f54ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200990:	784c                	ld	a1,176(s0)
ffffffffc0200992:	00002517          	auipc	a0,0x2
ffffffffc0200996:	c6e50513          	addi	a0,a0,-914 # ffffffffc0202600 <commands+0x3e8>
ffffffffc020099a:	f46ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020099e:	7c4c                	ld	a1,184(s0)
ffffffffc02009a0:	00002517          	auipc	a0,0x2
ffffffffc02009a4:	c7850513          	addi	a0,a0,-904 # ffffffffc0202618 <commands+0x400>
ffffffffc02009a8:	f38ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ac:	606c                	ld	a1,192(s0)
ffffffffc02009ae:	00002517          	auipc	a0,0x2
ffffffffc02009b2:	c8250513          	addi	a0,a0,-894 # ffffffffc0202630 <commands+0x418>
ffffffffc02009b6:	f2aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009ba:	646c                	ld	a1,200(s0)
ffffffffc02009bc:	00002517          	auipc	a0,0x2
ffffffffc02009c0:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202648 <commands+0x430>
ffffffffc02009c4:	f1cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c8:	686c                	ld	a1,208(s0)
ffffffffc02009ca:	00002517          	auipc	a0,0x2
ffffffffc02009ce:	c9650513          	addi	a0,a0,-874 # ffffffffc0202660 <commands+0x448>
ffffffffc02009d2:	f0eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009d6:	6c6c                	ld	a1,216(s0)
ffffffffc02009d8:	00002517          	auipc	a0,0x2
ffffffffc02009dc:	ca050513          	addi	a0,a0,-864 # ffffffffc0202678 <commands+0x460>
ffffffffc02009e0:	f00ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009e4:	706c                	ld	a1,224(s0)
ffffffffc02009e6:	00002517          	auipc	a0,0x2
ffffffffc02009ea:	caa50513          	addi	a0,a0,-854 # ffffffffc0202690 <commands+0x478>
ffffffffc02009ee:	ef2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009f2:	746c                	ld	a1,232(s0)
ffffffffc02009f4:	00002517          	auipc	a0,0x2
ffffffffc02009f8:	cb450513          	addi	a0,a0,-844 # ffffffffc02026a8 <commands+0x490>
ffffffffc02009fc:	ee4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a00:	786c                	ld	a1,240(s0)
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	cbe50513          	addi	a0,a0,-834 # ffffffffc02026c0 <commands+0x4a8>
ffffffffc0200a0a:	ed6ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a10:	6402                	ld	s0,0(sp)
ffffffffc0200a12:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a14:	00002517          	auipc	a0,0x2
ffffffffc0200a18:	cc450513          	addi	a0,a0,-828 # ffffffffc02026d8 <commands+0x4c0>
}
ffffffffc0200a1c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a1e:	ec2ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200a22 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a22:	1141                	addi	sp,sp,-16
ffffffffc0200a24:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a26:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a28:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2a:	00002517          	auipc	a0,0x2
ffffffffc0200a2e:	cc650513          	addi	a0,a0,-826 # ffffffffc02026f0 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a32:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a34:	eacff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a38:	8522                	mv	a0,s0
ffffffffc0200a3a:	e1bff0ef          	jal	ra,ffffffffc0200854 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a3e:	10043583          	ld	a1,256(s0)
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	cc650513          	addi	a0,a0,-826 # ffffffffc0202708 <commands+0x4f0>
ffffffffc0200a4a:	e96ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a4e:	10843583          	ld	a1,264(s0)
ffffffffc0200a52:	00002517          	auipc	a0,0x2
ffffffffc0200a56:	cce50513          	addi	a0,a0,-818 # ffffffffc0202720 <commands+0x508>
ffffffffc0200a5a:	e86ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a5e:	11043583          	ld	a1,272(s0)
ffffffffc0200a62:	00002517          	auipc	a0,0x2
ffffffffc0200a66:	cd650513          	addi	a0,a0,-810 # ffffffffc0202738 <commands+0x520>
ffffffffc0200a6a:	e76ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a72:	6402                	ld	s0,0(sp)
ffffffffc0200a74:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a76:	00002517          	auipc	a0,0x2
ffffffffc0200a7a:	cda50513          	addi	a0,a0,-806 # ffffffffc0202750 <commands+0x538>
}
ffffffffc0200a7e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a80:	e60ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200a84 <interrupt_handler>:
int num=0;
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a84:	11853783          	ld	a5,280(a0)
ffffffffc0200a88:	472d                	li	a4,11
ffffffffc0200a8a:	0786                	slli	a5,a5,0x1
ffffffffc0200a8c:	8385                	srli	a5,a5,0x1
ffffffffc0200a8e:	08f76963          	bltu	a4,a5,ffffffffc0200b20 <interrupt_handler+0x9c>
ffffffffc0200a92:	00002717          	auipc	a4,0x2
ffffffffc0200a96:	d9e70713          	addi	a4,a4,-610 # ffffffffc0202830 <commands+0x618>
ffffffffc0200a9a:	078a                	slli	a5,a5,0x2
ffffffffc0200a9c:	97ba                	add	a5,a5,a4
ffffffffc0200a9e:	439c                	lw	a5,0(a5)
ffffffffc0200aa0:	97ba                	add	a5,a5,a4
ffffffffc0200aa2:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200aa4:	00002517          	auipc	a0,0x2
ffffffffc0200aa8:	d2450513          	addi	a0,a0,-732 # ffffffffc02027c8 <commands+0x5b0>
ffffffffc0200aac:	e34ff06f          	j	ffffffffc02000e0 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200ab0:	00002517          	auipc	a0,0x2
ffffffffc0200ab4:	cf850513          	addi	a0,a0,-776 # ffffffffc02027a8 <commands+0x590>
ffffffffc0200ab8:	e28ff06f          	j	ffffffffc02000e0 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200abc:	00002517          	auipc	a0,0x2
ffffffffc0200ac0:	cac50513          	addi	a0,a0,-852 # ffffffffc0202768 <commands+0x550>
ffffffffc0200ac4:	e1cff06f          	j	ffffffffc02000e0 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac8:	00002517          	auipc	a0,0x2
ffffffffc0200acc:	d2050513          	addi	a0,a0,-736 # ffffffffc02027e8 <commands+0x5d0>
ffffffffc0200ad0:	e10ff06f          	j	ffffffffc02000e0 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200ad4:	1141                	addi	sp,sp,-16
ffffffffc0200ad6:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200ad8:	991ff0ef          	jal	ra,ffffffffc0200468 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200adc:	00007697          	auipc	a3,0x7
ffffffffc0200ae0:	96c68693          	addi	a3,a3,-1684 # ffffffffc0207448 <ticks>
ffffffffc0200ae4:	629c                	ld	a5,0(a3)
ffffffffc0200ae6:	06400713          	li	a4,100
ffffffffc0200aea:	0785                	addi	a5,a5,1
ffffffffc0200aec:	02e7f733          	remu	a4,a5,a4
ffffffffc0200af0:	e29c                	sd	a5,0(a3)
ffffffffc0200af2:	cb05                	beqz	a4,ffffffffc0200b22 <interrupt_handler+0x9e>
                print_ticks();
                num++;
            }
            if(num==10){sbi_shutdown();}
ffffffffc0200af4:	00007717          	auipc	a4,0x7
ffffffffc0200af8:	96c72703          	lw	a4,-1684(a4) # ffffffffc0207460 <num>
ffffffffc0200afc:	47a9                	li	a5,10
ffffffffc0200afe:	04f70363          	beq	a4,a5,ffffffffc0200b44 <interrupt_handler+0xc0>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b02:	60a2                	ld	ra,8(sp)
ffffffffc0200b04:	0141                	addi	sp,sp,16
ffffffffc0200b06:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b08:	00002517          	auipc	a0,0x2
ffffffffc0200b0c:	d0850513          	addi	a0,a0,-760 # ffffffffc0202810 <commands+0x5f8>
ffffffffc0200b10:	dd0ff06f          	j	ffffffffc02000e0 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b14:	00002517          	auipc	a0,0x2
ffffffffc0200b18:	c7450513          	addi	a0,a0,-908 # ffffffffc0202788 <commands+0x570>
ffffffffc0200b1c:	dc4ff06f          	j	ffffffffc02000e0 <cprintf>
            print_trapframe(tf);
ffffffffc0200b20:	b709                	j	ffffffffc0200a22 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b22:	06400593          	li	a1,100
ffffffffc0200b26:	00002517          	auipc	a0,0x2
ffffffffc0200b2a:	cda50513          	addi	a0,a0,-806 # ffffffffc0202800 <commands+0x5e8>
ffffffffc0200b2e:	db2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
                num++;
ffffffffc0200b32:	00007697          	auipc	a3,0x7
ffffffffc0200b36:	92e68693          	addi	a3,a3,-1746 # ffffffffc0207460 <num>
ffffffffc0200b3a:	429c                	lw	a5,0(a3)
ffffffffc0200b3c:	0017871b          	addiw	a4,a5,1
ffffffffc0200b40:	c298                	sw	a4,0(a3)
ffffffffc0200b42:	bf6d                	j	ffffffffc0200afc <interrupt_handler+0x78>
}
ffffffffc0200b44:	60a2                	ld	ra,8(sp)
ffffffffc0200b46:	0141                	addi	sp,sp,16
            if(num==10){sbi_shutdown();}
ffffffffc0200b48:	3b00106f          	j	ffffffffc0201ef8 <sbi_shutdown>

ffffffffc0200b4c <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b4c:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b50:	1141                	addi	sp,sp,-16
ffffffffc0200b52:	e022                	sd	s0,0(sp)
ffffffffc0200b54:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b56:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b58:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b5a:	04e78663          	beq	a5,a4,ffffffffc0200ba6 <exception_handler+0x5a>
ffffffffc0200b5e:	02f76c63          	bltu	a4,a5,ffffffffc0200b96 <exception_handler+0x4a>
ffffffffc0200b62:	4709                	li	a4,2
ffffffffc0200b64:	02e79563          	bne	a5,a4,ffffffffc0200b8e <exception_handler+0x42>
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            // (1) 输出指令异常类型
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b68:	00002517          	auipc	a0,0x2
ffffffffc0200b6c:	cf850513          	addi	a0,a0,-776 # ffffffffc0202860 <commands+0x648>
ffffffffc0200b70:	d70ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
            
            // (2) 输出异常指令地址
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b74:	10843583          	ld	a1,264(s0)
ffffffffc0200b78:	00002517          	auipc	a0,0x2
ffffffffc0200b7c:	d1050513          	addi	a0,a0,-752 # ffffffffc0202888 <commands+0x670>
ffffffffc0200b80:	d60ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
            
            // (3) 更新 tf->epc寄存器，跳过异常指令（RISC-V指令长度为4字节）
            tf->epc += 4;
ffffffffc0200b84:	10843783          	ld	a5,264(s0)
ffffffffc0200b88:	0791                	addi	a5,a5,4
ffffffffc0200b8a:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
ffffffffc0200b90:	6402                	ld	s0,0(sp)
ffffffffc0200b92:	0141                	addi	sp,sp,16
ffffffffc0200b94:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b96:	17f1                	addi	a5,a5,-4
ffffffffc0200b98:	471d                	li	a4,7
ffffffffc0200b9a:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b8e <exception_handler+0x42>
}
ffffffffc0200b9e:	6402                	ld	s0,0(sp)
ffffffffc0200ba0:	60a2                	ld	ra,8(sp)
ffffffffc0200ba2:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200ba4:	bdbd                	j	ffffffffc0200a22 <print_trapframe>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200ba6:	00002517          	auipc	a0,0x2
ffffffffc0200baa:	d0a50513          	addi	a0,a0,-758 # ffffffffc02028b0 <commands+0x698>
ffffffffc0200bae:	d32ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200bb2:	10843583          	ld	a1,264(s0)
ffffffffc0200bb6:	00002517          	auipc	a0,0x2
ffffffffc0200bba:	d1a50513          	addi	a0,a0,-742 # ffffffffc02028d0 <commands+0x6b8>
ffffffffc0200bbe:	d22ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
            tf->epc += 4;
ffffffffc0200bc2:	10843783          	ld	a5,264(s0)
}
ffffffffc0200bc6:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
ffffffffc0200bc8:	0791                	addi	a5,a5,4
ffffffffc0200bca:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200bce:	6402                	ld	s0,0(sp)
ffffffffc0200bd0:	0141                	addi	sp,sp,16
ffffffffc0200bd2:	8082                	ret

ffffffffc0200bd4 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bd4:	11853783          	ld	a5,280(a0)
ffffffffc0200bd8:	0007c363          	bltz	a5,ffffffffc0200bde <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bdc:	bf85                	j	ffffffffc0200b4c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bde:	b55d                	j	ffffffffc0200a84 <interrupt_handler>

ffffffffc0200be0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200be0:	14011073          	csrw	sscratch,sp
ffffffffc0200be4:	712d                	addi	sp,sp,-288
ffffffffc0200be6:	e002                	sd	zero,0(sp)
ffffffffc0200be8:	e406                	sd	ra,8(sp)
ffffffffc0200bea:	ec0e                	sd	gp,24(sp)
ffffffffc0200bec:	f012                	sd	tp,32(sp)
ffffffffc0200bee:	f416                	sd	t0,40(sp)
ffffffffc0200bf0:	f81a                	sd	t1,48(sp)
ffffffffc0200bf2:	fc1e                	sd	t2,56(sp)
ffffffffc0200bf4:	e0a2                	sd	s0,64(sp)
ffffffffc0200bf6:	e4a6                	sd	s1,72(sp)
ffffffffc0200bf8:	e8aa                	sd	a0,80(sp)
ffffffffc0200bfa:	ecae                	sd	a1,88(sp)
ffffffffc0200bfc:	f0b2                	sd	a2,96(sp)
ffffffffc0200bfe:	f4b6                	sd	a3,104(sp)
ffffffffc0200c00:	f8ba                	sd	a4,112(sp)
ffffffffc0200c02:	fcbe                	sd	a5,120(sp)
ffffffffc0200c04:	e142                	sd	a6,128(sp)
ffffffffc0200c06:	e546                	sd	a7,136(sp)
ffffffffc0200c08:	e94a                	sd	s2,144(sp)
ffffffffc0200c0a:	ed4e                	sd	s3,152(sp)
ffffffffc0200c0c:	f152                	sd	s4,160(sp)
ffffffffc0200c0e:	f556                	sd	s5,168(sp)
ffffffffc0200c10:	f95a                	sd	s6,176(sp)
ffffffffc0200c12:	fd5e                	sd	s7,184(sp)
ffffffffc0200c14:	e1e2                	sd	s8,192(sp)
ffffffffc0200c16:	e5e6                	sd	s9,200(sp)
ffffffffc0200c18:	e9ea                	sd	s10,208(sp)
ffffffffc0200c1a:	edee                	sd	s11,216(sp)
ffffffffc0200c1c:	f1f2                	sd	t3,224(sp)
ffffffffc0200c1e:	f5f6                	sd	t4,232(sp)
ffffffffc0200c20:	f9fa                	sd	t5,240(sp)
ffffffffc0200c22:	fdfe                	sd	t6,248(sp)
ffffffffc0200c24:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c28:	100024f3          	csrr	s1,sstatus
ffffffffc0200c2c:	14102973          	csrr	s2,sepc
ffffffffc0200c30:	143029f3          	csrr	s3,stval
ffffffffc0200c34:	14202a73          	csrr	s4,scause
ffffffffc0200c38:	e822                	sd	s0,16(sp)
ffffffffc0200c3a:	e226                	sd	s1,256(sp)
ffffffffc0200c3c:	e64a                	sd	s2,264(sp)
ffffffffc0200c3e:	ea4e                	sd	s3,272(sp)
ffffffffc0200c40:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c42:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c44:	f91ff0ef          	jal	ra,ffffffffc0200bd4 <trap>

ffffffffc0200c48 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c48:	6492                	ld	s1,256(sp)
ffffffffc0200c4a:	6932                	ld	s2,264(sp)
ffffffffc0200c4c:	10049073          	csrw	sstatus,s1
ffffffffc0200c50:	14191073          	csrw	sepc,s2
ffffffffc0200c54:	60a2                	ld	ra,8(sp)
ffffffffc0200c56:	61e2                	ld	gp,24(sp)
ffffffffc0200c58:	7202                	ld	tp,32(sp)
ffffffffc0200c5a:	72a2                	ld	t0,40(sp)
ffffffffc0200c5c:	7342                	ld	t1,48(sp)
ffffffffc0200c5e:	73e2                	ld	t2,56(sp)
ffffffffc0200c60:	6406                	ld	s0,64(sp)
ffffffffc0200c62:	64a6                	ld	s1,72(sp)
ffffffffc0200c64:	6546                	ld	a0,80(sp)
ffffffffc0200c66:	65e6                	ld	a1,88(sp)
ffffffffc0200c68:	7606                	ld	a2,96(sp)
ffffffffc0200c6a:	76a6                	ld	a3,104(sp)
ffffffffc0200c6c:	7746                	ld	a4,112(sp)
ffffffffc0200c6e:	77e6                	ld	a5,120(sp)
ffffffffc0200c70:	680a                	ld	a6,128(sp)
ffffffffc0200c72:	68aa                	ld	a7,136(sp)
ffffffffc0200c74:	694a                	ld	s2,144(sp)
ffffffffc0200c76:	69ea                	ld	s3,152(sp)
ffffffffc0200c78:	7a0a                	ld	s4,160(sp)
ffffffffc0200c7a:	7aaa                	ld	s5,168(sp)
ffffffffc0200c7c:	7b4a                	ld	s6,176(sp)
ffffffffc0200c7e:	7bea                	ld	s7,184(sp)
ffffffffc0200c80:	6c0e                	ld	s8,192(sp)
ffffffffc0200c82:	6cae                	ld	s9,200(sp)
ffffffffc0200c84:	6d4e                	ld	s10,208(sp)
ffffffffc0200c86:	6dee                	ld	s11,216(sp)
ffffffffc0200c88:	7e0e                	ld	t3,224(sp)
ffffffffc0200c8a:	7eae                	ld	t4,232(sp)
ffffffffc0200c8c:	7f4e                	ld	t5,240(sp)
ffffffffc0200c8e:	7fee                	ld	t6,248(sp)
ffffffffc0200c90:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c92:	10200073          	sret

ffffffffc0200c96 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c96:	00006797          	auipc	a5,0x6
ffffffffc0200c9a:	39278793          	addi	a5,a5,914 # ffffffffc0207028 <free_area>
ffffffffc0200c9e:	e79c                	sd	a5,8(a5)
ffffffffc0200ca0:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200ca2:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ca6:	8082                	ret

ffffffffc0200ca8 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200ca8:	00006517          	auipc	a0,0x6
ffffffffc0200cac:	39056503          	lwu	a0,912(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200cb0:	8082                	ret

ffffffffc0200cb2 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200cb2:	715d                	addi	sp,sp,-80
ffffffffc0200cb4:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200cb6:	00006417          	auipc	s0,0x6
ffffffffc0200cba:	37240413          	addi	s0,s0,882 # ffffffffc0207028 <free_area>
ffffffffc0200cbe:	641c                	ld	a5,8(s0)
ffffffffc0200cc0:	e486                	sd	ra,72(sp)
ffffffffc0200cc2:	fc26                	sd	s1,56(sp)
ffffffffc0200cc4:	f84a                	sd	s2,48(sp)
ffffffffc0200cc6:	f44e                	sd	s3,40(sp)
ffffffffc0200cc8:	f052                	sd	s4,32(sp)
ffffffffc0200cca:	ec56                	sd	s5,24(sp)
ffffffffc0200ccc:	e85a                	sd	s6,16(sp)
ffffffffc0200cce:	e45e                	sd	s7,8(sp)
ffffffffc0200cd0:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cd2:	2c878763          	beq	a5,s0,ffffffffc0200fa0 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200cd6:	4481                	li	s1,0
ffffffffc0200cd8:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200cda:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200cde:	8b09                	andi	a4,a4,2
ffffffffc0200ce0:	2c070463          	beqz	a4,ffffffffc0200fa8 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200ce4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ce8:	679c                	ld	a5,8(a5)
ffffffffc0200cea:	2905                	addiw	s2,s2,1
ffffffffc0200cec:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cee:	fe8796e3          	bne	a5,s0,ffffffffc0200cda <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200cf2:	89a6                	mv	s3,s1
ffffffffc0200cf4:	2f9000ef          	jal	ra,ffffffffc02017ec <nr_free_pages>
ffffffffc0200cf8:	71351863          	bne	a0,s3,ffffffffc0201408 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cfc:	4505                	li	a0,1
ffffffffc0200cfe:	271000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200d02:	8a2a                	mv	s4,a0
ffffffffc0200d04:	44050263          	beqz	a0,ffffffffc0201148 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d08:	4505                	li	a0,1
ffffffffc0200d0a:	265000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200d0e:	89aa                	mv	s3,a0
ffffffffc0200d10:	70050c63          	beqz	a0,ffffffffc0201428 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d14:	4505                	li	a0,1
ffffffffc0200d16:	259000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200d1a:	8aaa                	mv	s5,a0
ffffffffc0200d1c:	4a050663          	beqz	a0,ffffffffc02011c8 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d20:	2b3a0463          	beq	s4,s3,ffffffffc0200fc8 <default_check+0x316>
ffffffffc0200d24:	2aaa0263          	beq	s4,a0,ffffffffc0200fc8 <default_check+0x316>
ffffffffc0200d28:	2aa98063          	beq	s3,a0,ffffffffc0200fc8 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d2c:	000a2783          	lw	a5,0(s4)
ffffffffc0200d30:	2a079c63          	bnez	a5,ffffffffc0200fe8 <default_check+0x336>
ffffffffc0200d34:	0009a783          	lw	a5,0(s3)
ffffffffc0200d38:	2a079863          	bnez	a5,ffffffffc0200fe8 <default_check+0x336>
ffffffffc0200d3c:	411c                	lw	a5,0(a0)
ffffffffc0200d3e:	2a079563          	bnez	a5,ffffffffc0200fe8 <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d42:	00006797          	auipc	a5,0x6
ffffffffc0200d46:	72e7b783          	ld	a5,1838(a5) # ffffffffc0207470 <pages>
ffffffffc0200d4a:	40fa0733          	sub	a4,s4,a5
ffffffffc0200d4e:	870d                	srai	a4,a4,0x3
ffffffffc0200d50:	00002597          	auipc	a1,0x2
ffffffffc0200d54:	3285b583          	ld	a1,808(a1) # ffffffffc0203078 <error_string+0x38>
ffffffffc0200d58:	02b70733          	mul	a4,a4,a1
ffffffffc0200d5c:	00002617          	auipc	a2,0x2
ffffffffc0200d60:	32463603          	ld	a2,804(a2) # ffffffffc0203080 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d64:	00006697          	auipc	a3,0x6
ffffffffc0200d68:	7046b683          	ld	a3,1796(a3) # ffffffffc0207468 <npage>
ffffffffc0200d6c:	06b2                	slli	a3,a3,0xc
ffffffffc0200d6e:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d70:	0732                	slli	a4,a4,0xc
ffffffffc0200d72:	28d77b63          	bgeu	a4,a3,ffffffffc0201008 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d76:	40f98733          	sub	a4,s3,a5
ffffffffc0200d7a:	870d                	srai	a4,a4,0x3
ffffffffc0200d7c:	02b70733          	mul	a4,a4,a1
ffffffffc0200d80:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d82:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d84:	4cd77263          	bgeu	a4,a3,ffffffffc0201248 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d88:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d8c:	878d                	srai	a5,a5,0x3
ffffffffc0200d8e:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d92:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d94:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d96:	30d7f963          	bgeu	a5,a3,ffffffffc02010a8 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200d9a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d9c:	00043c03          	ld	s8,0(s0)
ffffffffc0200da0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200da4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200da8:	e400                	sd	s0,8(s0)
ffffffffc0200daa:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200dac:	00006797          	auipc	a5,0x6
ffffffffc0200db0:	2807a623          	sw	zero,652(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200db4:	1bb000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200db8:	2c051863          	bnez	a0,ffffffffc0201088 <default_check+0x3d6>
    free_page(p0);
ffffffffc0200dbc:	4585                	li	a1,1
ffffffffc0200dbe:	8552                	mv	a0,s4
ffffffffc0200dc0:	1ed000ef          	jal	ra,ffffffffc02017ac <free_pages>
    free_page(p1);
ffffffffc0200dc4:	4585                	li	a1,1
ffffffffc0200dc6:	854e                	mv	a0,s3
ffffffffc0200dc8:	1e5000ef          	jal	ra,ffffffffc02017ac <free_pages>
    free_page(p2);
ffffffffc0200dcc:	4585                	li	a1,1
ffffffffc0200dce:	8556                	mv	a0,s5
ffffffffc0200dd0:	1dd000ef          	jal	ra,ffffffffc02017ac <free_pages>
    assert(nr_free == 3);
ffffffffc0200dd4:	4818                	lw	a4,16(s0)
ffffffffc0200dd6:	478d                	li	a5,3
ffffffffc0200dd8:	28f71863          	bne	a4,a5,ffffffffc0201068 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ddc:	4505                	li	a0,1
ffffffffc0200dde:	191000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200de2:	89aa                	mv	s3,a0
ffffffffc0200de4:	26050263          	beqz	a0,ffffffffc0201048 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200de8:	4505                	li	a0,1
ffffffffc0200dea:	185000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200dee:	8aaa                	mv	s5,a0
ffffffffc0200df0:	3a050c63          	beqz	a0,ffffffffc02011a8 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200df4:	4505                	li	a0,1
ffffffffc0200df6:	179000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200dfa:	8a2a                	mv	s4,a0
ffffffffc0200dfc:	38050663          	beqz	a0,ffffffffc0201188 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200e00:	4505                	li	a0,1
ffffffffc0200e02:	16d000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200e06:	36051163          	bnez	a0,ffffffffc0201168 <default_check+0x4b6>
    free_page(p0);
ffffffffc0200e0a:	4585                	li	a1,1
ffffffffc0200e0c:	854e                	mv	a0,s3
ffffffffc0200e0e:	19f000ef          	jal	ra,ffffffffc02017ac <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e12:	641c                	ld	a5,8(s0)
ffffffffc0200e14:	20878a63          	beq	a5,s0,ffffffffc0201028 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200e18:	4505                	li	a0,1
ffffffffc0200e1a:	155000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200e1e:	30a99563          	bne	s3,a0,ffffffffc0201128 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200e22:	4505                	li	a0,1
ffffffffc0200e24:	14b000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200e28:	2e051063          	bnez	a0,ffffffffc0201108 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200e2c:	481c                	lw	a5,16(s0)
ffffffffc0200e2e:	2a079d63          	bnez	a5,ffffffffc02010e8 <default_check+0x436>
    free_page(p);
ffffffffc0200e32:	854e                	mv	a0,s3
ffffffffc0200e34:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e36:	01843023          	sd	s8,0(s0)
ffffffffc0200e3a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200e3e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e42:	16b000ef          	jal	ra,ffffffffc02017ac <free_pages>
    free_page(p1);
ffffffffc0200e46:	4585                	li	a1,1
ffffffffc0200e48:	8556                	mv	a0,s5
ffffffffc0200e4a:	163000ef          	jal	ra,ffffffffc02017ac <free_pages>
    free_page(p2);
ffffffffc0200e4e:	4585                	li	a1,1
ffffffffc0200e50:	8552                	mv	a0,s4
ffffffffc0200e52:	15b000ef          	jal	ra,ffffffffc02017ac <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e56:	4515                	li	a0,5
ffffffffc0200e58:	117000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200e5c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e5e:	26050563          	beqz	a0,ffffffffc02010c8 <default_check+0x416>
ffffffffc0200e62:	651c                	ld	a5,8(a0)
ffffffffc0200e64:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e66:	8b85                	andi	a5,a5,1
ffffffffc0200e68:	54079063          	bnez	a5,ffffffffc02013a8 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e6c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e6e:	00043b03          	ld	s6,0(s0)
ffffffffc0200e72:	00843a83          	ld	s5,8(s0)
ffffffffc0200e76:	e000                	sd	s0,0(s0)
ffffffffc0200e78:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200e7a:	0f5000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200e7e:	50051563          	bnez	a0,ffffffffc0201388 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200e82:	05098a13          	addi	s4,s3,80
ffffffffc0200e86:	8552                	mv	a0,s4
ffffffffc0200e88:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e8a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200e8e:	00006797          	auipc	a5,0x6
ffffffffc0200e92:	1a07a523          	sw	zero,426(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e96:	117000ef          	jal	ra,ffffffffc02017ac <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e9a:	4511                	li	a0,4
ffffffffc0200e9c:	0d3000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200ea0:	4c051463          	bnez	a0,ffffffffc0201368 <default_check+0x6b6>
ffffffffc0200ea4:	0589b783          	ld	a5,88(s3)
ffffffffc0200ea8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200eaa:	8b85                	andi	a5,a5,1
ffffffffc0200eac:	48078e63          	beqz	a5,ffffffffc0201348 <default_check+0x696>
ffffffffc0200eb0:	0609a703          	lw	a4,96(s3)
ffffffffc0200eb4:	478d                	li	a5,3
ffffffffc0200eb6:	48f71963          	bne	a4,a5,ffffffffc0201348 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200eba:	450d                	li	a0,3
ffffffffc0200ebc:	0b3000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200ec0:	8c2a                	mv	s8,a0
ffffffffc0200ec2:	46050363          	beqz	a0,ffffffffc0201328 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200ec6:	4505                	li	a0,1
ffffffffc0200ec8:	0a7000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200ecc:	42051e63          	bnez	a0,ffffffffc0201308 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200ed0:	418a1c63          	bne	s4,s8,ffffffffc02012e8 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200ed4:	4585                	li	a1,1
ffffffffc0200ed6:	854e                	mv	a0,s3
ffffffffc0200ed8:	0d5000ef          	jal	ra,ffffffffc02017ac <free_pages>
    free_pages(p1, 3);
ffffffffc0200edc:	458d                	li	a1,3
ffffffffc0200ede:	8552                	mv	a0,s4
ffffffffc0200ee0:	0cd000ef          	jal	ra,ffffffffc02017ac <free_pages>
ffffffffc0200ee4:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200ee8:	02898c13          	addi	s8,s3,40
ffffffffc0200eec:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200eee:	8b85                	andi	a5,a5,1
ffffffffc0200ef0:	3c078c63          	beqz	a5,ffffffffc02012c8 <default_check+0x616>
ffffffffc0200ef4:	0109a703          	lw	a4,16(s3)
ffffffffc0200ef8:	4785                	li	a5,1
ffffffffc0200efa:	3cf71763          	bne	a4,a5,ffffffffc02012c8 <default_check+0x616>
ffffffffc0200efe:	008a3783          	ld	a5,8(s4)
ffffffffc0200f02:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f04:	8b85                	andi	a5,a5,1
ffffffffc0200f06:	3a078163          	beqz	a5,ffffffffc02012a8 <default_check+0x5f6>
ffffffffc0200f0a:	010a2703          	lw	a4,16(s4)
ffffffffc0200f0e:	478d                	li	a5,3
ffffffffc0200f10:	38f71c63          	bne	a4,a5,ffffffffc02012a8 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f14:	4505                	li	a0,1
ffffffffc0200f16:	059000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200f1a:	36a99763          	bne	s3,a0,ffffffffc0201288 <default_check+0x5d6>
    free_page(p0);
ffffffffc0200f1e:	4585                	li	a1,1
ffffffffc0200f20:	08d000ef          	jal	ra,ffffffffc02017ac <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f24:	4509                	li	a0,2
ffffffffc0200f26:	049000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200f2a:	32aa1f63          	bne	s4,a0,ffffffffc0201268 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200f2e:	4589                	li	a1,2
ffffffffc0200f30:	07d000ef          	jal	ra,ffffffffc02017ac <free_pages>
    free_page(p2);
ffffffffc0200f34:	4585                	li	a1,1
ffffffffc0200f36:	8562                	mv	a0,s8
ffffffffc0200f38:	075000ef          	jal	ra,ffffffffc02017ac <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f3c:	4515                	li	a0,5
ffffffffc0200f3e:	031000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200f42:	89aa                	mv	s3,a0
ffffffffc0200f44:	48050263          	beqz	a0,ffffffffc02013c8 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200f48:	4505                	li	a0,1
ffffffffc0200f4a:	025000ef          	jal	ra,ffffffffc020176e <alloc_pages>
ffffffffc0200f4e:	2c051d63          	bnez	a0,ffffffffc0201228 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200f52:	481c                	lw	a5,16(s0)
ffffffffc0200f54:	2a079a63          	bnez	a5,ffffffffc0201208 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f58:	4595                	li	a1,5
ffffffffc0200f5a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f5c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200f60:	01643023          	sd	s6,0(s0)
ffffffffc0200f64:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200f68:	045000ef          	jal	ra,ffffffffc02017ac <free_pages>
    return listelm->next;
ffffffffc0200f6c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f6e:	00878963          	beq	a5,s0,ffffffffc0200f80 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200f72:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f76:	679c                	ld	a5,8(a5)
ffffffffc0200f78:	397d                	addiw	s2,s2,-1
ffffffffc0200f7a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f7c:	fe879be3          	bne	a5,s0,ffffffffc0200f72 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200f80:	26091463          	bnez	s2,ffffffffc02011e8 <default_check+0x536>
    assert(total == 0);
ffffffffc0200f84:	46049263          	bnez	s1,ffffffffc02013e8 <default_check+0x736>
}
ffffffffc0200f88:	60a6                	ld	ra,72(sp)
ffffffffc0200f8a:	6406                	ld	s0,64(sp)
ffffffffc0200f8c:	74e2                	ld	s1,56(sp)
ffffffffc0200f8e:	7942                	ld	s2,48(sp)
ffffffffc0200f90:	79a2                	ld	s3,40(sp)
ffffffffc0200f92:	7a02                	ld	s4,32(sp)
ffffffffc0200f94:	6ae2                	ld	s5,24(sp)
ffffffffc0200f96:	6b42                	ld	s6,16(sp)
ffffffffc0200f98:	6ba2                	ld	s7,8(sp)
ffffffffc0200f9a:	6c02                	ld	s8,0(sp)
ffffffffc0200f9c:	6161                	addi	sp,sp,80
ffffffffc0200f9e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fa0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200fa2:	4481                	li	s1,0
ffffffffc0200fa4:	4901                	li	s2,0
ffffffffc0200fa6:	b3b9                	j	ffffffffc0200cf4 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200fa8:	00002697          	auipc	a3,0x2
ffffffffc0200fac:	94868693          	addi	a3,a3,-1720 # ffffffffc02028f0 <commands+0x6d8>
ffffffffc0200fb0:	00002617          	auipc	a2,0x2
ffffffffc0200fb4:	95060613          	addi	a2,a2,-1712 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0200fb8:	0f000593          	li	a1,240
ffffffffc0200fbc:	00002517          	auipc	a0,0x2
ffffffffc0200fc0:	95c50513          	addi	a0,a0,-1700 # ffffffffc0202918 <commands+0x700>
ffffffffc0200fc4:	c16ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200fc8:	00002697          	auipc	a3,0x2
ffffffffc0200fcc:	9e868693          	addi	a3,a3,-1560 # ffffffffc02029b0 <commands+0x798>
ffffffffc0200fd0:	00002617          	auipc	a2,0x2
ffffffffc0200fd4:	93060613          	addi	a2,a2,-1744 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0200fd8:	0bd00593          	li	a1,189
ffffffffc0200fdc:	00002517          	auipc	a0,0x2
ffffffffc0200fe0:	93c50513          	addi	a0,a0,-1732 # ffffffffc0202918 <commands+0x700>
ffffffffc0200fe4:	bf6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200fe8:	00002697          	auipc	a3,0x2
ffffffffc0200fec:	9f068693          	addi	a3,a3,-1552 # ffffffffc02029d8 <commands+0x7c0>
ffffffffc0200ff0:	00002617          	auipc	a2,0x2
ffffffffc0200ff4:	91060613          	addi	a2,a2,-1776 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0200ff8:	0be00593          	li	a1,190
ffffffffc0200ffc:	00002517          	auipc	a0,0x2
ffffffffc0201000:	91c50513          	addi	a0,a0,-1764 # ffffffffc0202918 <commands+0x700>
ffffffffc0201004:	bd6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201008:	00002697          	auipc	a3,0x2
ffffffffc020100c:	a1068693          	addi	a3,a3,-1520 # ffffffffc0202a18 <commands+0x800>
ffffffffc0201010:	00002617          	auipc	a2,0x2
ffffffffc0201014:	8f060613          	addi	a2,a2,-1808 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201018:	0c000593          	li	a1,192
ffffffffc020101c:	00002517          	auipc	a0,0x2
ffffffffc0201020:	8fc50513          	addi	a0,a0,-1796 # ffffffffc0202918 <commands+0x700>
ffffffffc0201024:	bb6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201028:	00002697          	auipc	a3,0x2
ffffffffc020102c:	a7868693          	addi	a3,a3,-1416 # ffffffffc0202aa0 <commands+0x888>
ffffffffc0201030:	00002617          	auipc	a2,0x2
ffffffffc0201034:	8d060613          	addi	a2,a2,-1840 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201038:	0d900593          	li	a1,217
ffffffffc020103c:	00002517          	auipc	a0,0x2
ffffffffc0201040:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0202918 <commands+0x700>
ffffffffc0201044:	b96ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201048:	00002697          	auipc	a3,0x2
ffffffffc020104c:	90868693          	addi	a3,a3,-1784 # ffffffffc0202950 <commands+0x738>
ffffffffc0201050:	00002617          	auipc	a2,0x2
ffffffffc0201054:	8b060613          	addi	a2,a2,-1872 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201058:	0d200593          	li	a1,210
ffffffffc020105c:	00002517          	auipc	a0,0x2
ffffffffc0201060:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0202918 <commands+0x700>
ffffffffc0201064:	b76ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(nr_free == 3);
ffffffffc0201068:	00002697          	auipc	a3,0x2
ffffffffc020106c:	a2868693          	addi	a3,a3,-1496 # ffffffffc0202a90 <commands+0x878>
ffffffffc0201070:	00002617          	auipc	a2,0x2
ffffffffc0201074:	89060613          	addi	a2,a2,-1904 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201078:	0d000593          	li	a1,208
ffffffffc020107c:	00002517          	auipc	a0,0x2
ffffffffc0201080:	89c50513          	addi	a0,a0,-1892 # ffffffffc0202918 <commands+0x700>
ffffffffc0201084:	b56ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201088:	00002697          	auipc	a3,0x2
ffffffffc020108c:	9f068693          	addi	a3,a3,-1552 # ffffffffc0202a78 <commands+0x860>
ffffffffc0201090:	00002617          	auipc	a2,0x2
ffffffffc0201094:	87060613          	addi	a2,a2,-1936 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201098:	0cb00593          	li	a1,203
ffffffffc020109c:	00002517          	auipc	a0,0x2
ffffffffc02010a0:	87c50513          	addi	a0,a0,-1924 # ffffffffc0202918 <commands+0x700>
ffffffffc02010a4:	b36ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010a8:	00002697          	auipc	a3,0x2
ffffffffc02010ac:	9b068693          	addi	a3,a3,-1616 # ffffffffc0202a58 <commands+0x840>
ffffffffc02010b0:	00002617          	auipc	a2,0x2
ffffffffc02010b4:	85060613          	addi	a2,a2,-1968 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02010b8:	0c200593          	li	a1,194
ffffffffc02010bc:	00002517          	auipc	a0,0x2
ffffffffc02010c0:	85c50513          	addi	a0,a0,-1956 # ffffffffc0202918 <commands+0x700>
ffffffffc02010c4:	b16ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(p0 != NULL);
ffffffffc02010c8:	00002697          	auipc	a3,0x2
ffffffffc02010cc:	a2068693          	addi	a3,a3,-1504 # ffffffffc0202ae8 <commands+0x8d0>
ffffffffc02010d0:	00002617          	auipc	a2,0x2
ffffffffc02010d4:	83060613          	addi	a2,a2,-2000 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02010d8:	0f800593          	li	a1,248
ffffffffc02010dc:	00002517          	auipc	a0,0x2
ffffffffc02010e0:	83c50513          	addi	a0,a0,-1988 # ffffffffc0202918 <commands+0x700>
ffffffffc02010e4:	af6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(nr_free == 0);
ffffffffc02010e8:	00002697          	auipc	a3,0x2
ffffffffc02010ec:	9f068693          	addi	a3,a3,-1552 # ffffffffc0202ad8 <commands+0x8c0>
ffffffffc02010f0:	00002617          	auipc	a2,0x2
ffffffffc02010f4:	81060613          	addi	a2,a2,-2032 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02010f8:	0df00593          	li	a1,223
ffffffffc02010fc:	00002517          	auipc	a0,0x2
ffffffffc0201100:	81c50513          	addi	a0,a0,-2020 # ffffffffc0202918 <commands+0x700>
ffffffffc0201104:	ad6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201108:	00002697          	auipc	a3,0x2
ffffffffc020110c:	97068693          	addi	a3,a3,-1680 # ffffffffc0202a78 <commands+0x860>
ffffffffc0201110:	00001617          	auipc	a2,0x1
ffffffffc0201114:	7f060613          	addi	a2,a2,2032 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201118:	0dd00593          	li	a1,221
ffffffffc020111c:	00001517          	auipc	a0,0x1
ffffffffc0201120:	7fc50513          	addi	a0,a0,2044 # ffffffffc0202918 <commands+0x700>
ffffffffc0201124:	ab6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201128:	00002697          	auipc	a3,0x2
ffffffffc020112c:	99068693          	addi	a3,a3,-1648 # ffffffffc0202ab8 <commands+0x8a0>
ffffffffc0201130:	00001617          	auipc	a2,0x1
ffffffffc0201134:	7d060613          	addi	a2,a2,2000 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201138:	0dc00593          	li	a1,220
ffffffffc020113c:	00001517          	auipc	a0,0x1
ffffffffc0201140:	7dc50513          	addi	a0,a0,2012 # ffffffffc0202918 <commands+0x700>
ffffffffc0201144:	a96ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201148:	00002697          	auipc	a3,0x2
ffffffffc020114c:	80868693          	addi	a3,a3,-2040 # ffffffffc0202950 <commands+0x738>
ffffffffc0201150:	00001617          	auipc	a2,0x1
ffffffffc0201154:	7b060613          	addi	a2,a2,1968 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201158:	0b900593          	li	a1,185
ffffffffc020115c:	00001517          	auipc	a0,0x1
ffffffffc0201160:	7bc50513          	addi	a0,a0,1980 # ffffffffc0202918 <commands+0x700>
ffffffffc0201164:	a76ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201168:	00002697          	auipc	a3,0x2
ffffffffc020116c:	91068693          	addi	a3,a3,-1776 # ffffffffc0202a78 <commands+0x860>
ffffffffc0201170:	00001617          	auipc	a2,0x1
ffffffffc0201174:	79060613          	addi	a2,a2,1936 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201178:	0d600593          	li	a1,214
ffffffffc020117c:	00001517          	auipc	a0,0x1
ffffffffc0201180:	79c50513          	addi	a0,a0,1948 # ffffffffc0202918 <commands+0x700>
ffffffffc0201184:	a56ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201188:	00002697          	auipc	a3,0x2
ffffffffc020118c:	80868693          	addi	a3,a3,-2040 # ffffffffc0202990 <commands+0x778>
ffffffffc0201190:	00001617          	auipc	a2,0x1
ffffffffc0201194:	77060613          	addi	a2,a2,1904 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201198:	0d400593          	li	a1,212
ffffffffc020119c:	00001517          	auipc	a0,0x1
ffffffffc02011a0:	77c50513          	addi	a0,a0,1916 # ffffffffc0202918 <commands+0x700>
ffffffffc02011a4:	a36ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011a8:	00001697          	auipc	a3,0x1
ffffffffc02011ac:	7c868693          	addi	a3,a3,1992 # ffffffffc0202970 <commands+0x758>
ffffffffc02011b0:	00001617          	auipc	a2,0x1
ffffffffc02011b4:	75060613          	addi	a2,a2,1872 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02011b8:	0d300593          	li	a1,211
ffffffffc02011bc:	00001517          	auipc	a0,0x1
ffffffffc02011c0:	75c50513          	addi	a0,a0,1884 # ffffffffc0202918 <commands+0x700>
ffffffffc02011c4:	a16ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011c8:	00001697          	auipc	a3,0x1
ffffffffc02011cc:	7c868693          	addi	a3,a3,1992 # ffffffffc0202990 <commands+0x778>
ffffffffc02011d0:	00001617          	auipc	a2,0x1
ffffffffc02011d4:	73060613          	addi	a2,a2,1840 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02011d8:	0bb00593          	li	a1,187
ffffffffc02011dc:	00001517          	auipc	a0,0x1
ffffffffc02011e0:	73c50513          	addi	a0,a0,1852 # ffffffffc0202918 <commands+0x700>
ffffffffc02011e4:	9f6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(count == 0);
ffffffffc02011e8:	00002697          	auipc	a3,0x2
ffffffffc02011ec:	a5068693          	addi	a3,a3,-1456 # ffffffffc0202c38 <commands+0xa20>
ffffffffc02011f0:	00001617          	auipc	a2,0x1
ffffffffc02011f4:	71060613          	addi	a2,a2,1808 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02011f8:	12500593          	li	a1,293
ffffffffc02011fc:	00001517          	auipc	a0,0x1
ffffffffc0201200:	71c50513          	addi	a0,a0,1820 # ffffffffc0202918 <commands+0x700>
ffffffffc0201204:	9d6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(nr_free == 0);
ffffffffc0201208:	00002697          	auipc	a3,0x2
ffffffffc020120c:	8d068693          	addi	a3,a3,-1840 # ffffffffc0202ad8 <commands+0x8c0>
ffffffffc0201210:	00001617          	auipc	a2,0x1
ffffffffc0201214:	6f060613          	addi	a2,a2,1776 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201218:	11a00593          	li	a1,282
ffffffffc020121c:	00001517          	auipc	a0,0x1
ffffffffc0201220:	6fc50513          	addi	a0,a0,1788 # ffffffffc0202918 <commands+0x700>
ffffffffc0201224:	9b6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201228:	00002697          	auipc	a3,0x2
ffffffffc020122c:	85068693          	addi	a3,a3,-1968 # ffffffffc0202a78 <commands+0x860>
ffffffffc0201230:	00001617          	auipc	a2,0x1
ffffffffc0201234:	6d060613          	addi	a2,a2,1744 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201238:	11800593          	li	a1,280
ffffffffc020123c:	00001517          	auipc	a0,0x1
ffffffffc0201240:	6dc50513          	addi	a0,a0,1756 # ffffffffc0202918 <commands+0x700>
ffffffffc0201244:	996ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201248:	00001697          	auipc	a3,0x1
ffffffffc020124c:	7f068693          	addi	a3,a3,2032 # ffffffffc0202a38 <commands+0x820>
ffffffffc0201250:	00001617          	auipc	a2,0x1
ffffffffc0201254:	6b060613          	addi	a2,a2,1712 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201258:	0c100593          	li	a1,193
ffffffffc020125c:	00001517          	auipc	a0,0x1
ffffffffc0201260:	6bc50513          	addi	a0,a0,1724 # ffffffffc0202918 <commands+0x700>
ffffffffc0201264:	976ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201268:	00002697          	auipc	a3,0x2
ffffffffc020126c:	99068693          	addi	a3,a3,-1648 # ffffffffc0202bf8 <commands+0x9e0>
ffffffffc0201270:	00001617          	auipc	a2,0x1
ffffffffc0201274:	69060613          	addi	a2,a2,1680 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201278:	11200593          	li	a1,274
ffffffffc020127c:	00001517          	auipc	a0,0x1
ffffffffc0201280:	69c50513          	addi	a0,a0,1692 # ffffffffc0202918 <commands+0x700>
ffffffffc0201284:	956ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201288:	00002697          	auipc	a3,0x2
ffffffffc020128c:	95068693          	addi	a3,a3,-1712 # ffffffffc0202bd8 <commands+0x9c0>
ffffffffc0201290:	00001617          	auipc	a2,0x1
ffffffffc0201294:	67060613          	addi	a2,a2,1648 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201298:	11000593          	li	a1,272
ffffffffc020129c:	00001517          	auipc	a0,0x1
ffffffffc02012a0:	67c50513          	addi	a0,a0,1660 # ffffffffc0202918 <commands+0x700>
ffffffffc02012a4:	936ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012a8:	00002697          	auipc	a3,0x2
ffffffffc02012ac:	90868693          	addi	a3,a3,-1784 # ffffffffc0202bb0 <commands+0x998>
ffffffffc02012b0:	00001617          	auipc	a2,0x1
ffffffffc02012b4:	65060613          	addi	a2,a2,1616 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02012b8:	10e00593          	li	a1,270
ffffffffc02012bc:	00001517          	auipc	a0,0x1
ffffffffc02012c0:	65c50513          	addi	a0,a0,1628 # ffffffffc0202918 <commands+0x700>
ffffffffc02012c4:	916ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012c8:	00002697          	auipc	a3,0x2
ffffffffc02012cc:	8c068693          	addi	a3,a3,-1856 # ffffffffc0202b88 <commands+0x970>
ffffffffc02012d0:	00001617          	auipc	a2,0x1
ffffffffc02012d4:	63060613          	addi	a2,a2,1584 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02012d8:	10d00593          	li	a1,269
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	63c50513          	addi	a0,a0,1596 # ffffffffc0202918 <commands+0x700>
ffffffffc02012e4:	8f6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(p0 + 2 == p1);
ffffffffc02012e8:	00002697          	auipc	a3,0x2
ffffffffc02012ec:	89068693          	addi	a3,a3,-1904 # ffffffffc0202b78 <commands+0x960>
ffffffffc02012f0:	00001617          	auipc	a2,0x1
ffffffffc02012f4:	61060613          	addi	a2,a2,1552 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02012f8:	10800593          	li	a1,264
ffffffffc02012fc:	00001517          	auipc	a0,0x1
ffffffffc0201300:	61c50513          	addi	a0,a0,1564 # ffffffffc0202918 <commands+0x700>
ffffffffc0201304:	8d6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201308:	00001697          	auipc	a3,0x1
ffffffffc020130c:	77068693          	addi	a3,a3,1904 # ffffffffc0202a78 <commands+0x860>
ffffffffc0201310:	00001617          	auipc	a2,0x1
ffffffffc0201314:	5f060613          	addi	a2,a2,1520 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201318:	10700593          	li	a1,263
ffffffffc020131c:	00001517          	auipc	a0,0x1
ffffffffc0201320:	5fc50513          	addi	a0,a0,1532 # ffffffffc0202918 <commands+0x700>
ffffffffc0201324:	8b6ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201328:	00002697          	auipc	a3,0x2
ffffffffc020132c:	83068693          	addi	a3,a3,-2000 # ffffffffc0202b58 <commands+0x940>
ffffffffc0201330:	00001617          	auipc	a2,0x1
ffffffffc0201334:	5d060613          	addi	a2,a2,1488 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201338:	10600593          	li	a1,262
ffffffffc020133c:	00001517          	auipc	a0,0x1
ffffffffc0201340:	5dc50513          	addi	a0,a0,1500 # ffffffffc0202918 <commands+0x700>
ffffffffc0201344:	896ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201348:	00001697          	auipc	a3,0x1
ffffffffc020134c:	7e068693          	addi	a3,a3,2016 # ffffffffc0202b28 <commands+0x910>
ffffffffc0201350:	00001617          	auipc	a2,0x1
ffffffffc0201354:	5b060613          	addi	a2,a2,1456 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201358:	10500593          	li	a1,261
ffffffffc020135c:	00001517          	auipc	a0,0x1
ffffffffc0201360:	5bc50513          	addi	a0,a0,1468 # ffffffffc0202918 <commands+0x700>
ffffffffc0201364:	876ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201368:	00001697          	auipc	a3,0x1
ffffffffc020136c:	7a868693          	addi	a3,a3,1960 # ffffffffc0202b10 <commands+0x8f8>
ffffffffc0201370:	00001617          	auipc	a2,0x1
ffffffffc0201374:	59060613          	addi	a2,a2,1424 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201378:	10400593          	li	a1,260
ffffffffc020137c:	00001517          	auipc	a0,0x1
ffffffffc0201380:	59c50513          	addi	a0,a0,1436 # ffffffffc0202918 <commands+0x700>
ffffffffc0201384:	856ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201388:	00001697          	auipc	a3,0x1
ffffffffc020138c:	6f068693          	addi	a3,a3,1776 # ffffffffc0202a78 <commands+0x860>
ffffffffc0201390:	00001617          	auipc	a2,0x1
ffffffffc0201394:	57060613          	addi	a2,a2,1392 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201398:	0fe00593          	li	a1,254
ffffffffc020139c:	00001517          	auipc	a0,0x1
ffffffffc02013a0:	57c50513          	addi	a0,a0,1404 # ffffffffc0202918 <commands+0x700>
ffffffffc02013a4:	836ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(!PageProperty(p0));
ffffffffc02013a8:	00001697          	auipc	a3,0x1
ffffffffc02013ac:	75068693          	addi	a3,a3,1872 # ffffffffc0202af8 <commands+0x8e0>
ffffffffc02013b0:	00001617          	auipc	a2,0x1
ffffffffc02013b4:	55060613          	addi	a2,a2,1360 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02013b8:	0f900593          	li	a1,249
ffffffffc02013bc:	00001517          	auipc	a0,0x1
ffffffffc02013c0:	55c50513          	addi	a0,a0,1372 # ffffffffc0202918 <commands+0x700>
ffffffffc02013c4:	816ff0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02013c8:	00002697          	auipc	a3,0x2
ffffffffc02013cc:	85068693          	addi	a3,a3,-1968 # ffffffffc0202c18 <commands+0xa00>
ffffffffc02013d0:	00001617          	auipc	a2,0x1
ffffffffc02013d4:	53060613          	addi	a2,a2,1328 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02013d8:	11700593          	li	a1,279
ffffffffc02013dc:	00001517          	auipc	a0,0x1
ffffffffc02013e0:	53c50513          	addi	a0,a0,1340 # ffffffffc0202918 <commands+0x700>
ffffffffc02013e4:	ff7fe0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(total == 0);
ffffffffc02013e8:	00002697          	auipc	a3,0x2
ffffffffc02013ec:	86068693          	addi	a3,a3,-1952 # ffffffffc0202c48 <commands+0xa30>
ffffffffc02013f0:	00001617          	auipc	a2,0x1
ffffffffc02013f4:	51060613          	addi	a2,a2,1296 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02013f8:	12600593          	li	a1,294
ffffffffc02013fc:	00001517          	auipc	a0,0x1
ffffffffc0201400:	51c50513          	addi	a0,a0,1308 # ffffffffc0202918 <commands+0x700>
ffffffffc0201404:	fd7fe0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(total == nr_free_pages());
ffffffffc0201408:	00001697          	auipc	a3,0x1
ffffffffc020140c:	52868693          	addi	a3,a3,1320 # ffffffffc0202930 <commands+0x718>
ffffffffc0201410:	00001617          	auipc	a2,0x1
ffffffffc0201414:	4f060613          	addi	a2,a2,1264 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201418:	0f300593          	li	a1,243
ffffffffc020141c:	00001517          	auipc	a0,0x1
ffffffffc0201420:	4fc50513          	addi	a0,a0,1276 # ffffffffc0202918 <commands+0x700>
ffffffffc0201424:	fb7fe0ef          	jal	ra,ffffffffc02003da <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201428:	00001697          	auipc	a3,0x1
ffffffffc020142c:	54868693          	addi	a3,a3,1352 # ffffffffc0202970 <commands+0x758>
ffffffffc0201430:	00001617          	auipc	a2,0x1
ffffffffc0201434:	4d060613          	addi	a2,a2,1232 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201438:	0ba00593          	li	a1,186
ffffffffc020143c:	00001517          	auipc	a0,0x1
ffffffffc0201440:	4dc50513          	addi	a0,a0,1244 # ffffffffc0202918 <commands+0x700>
ffffffffc0201444:	f97fe0ef          	jal	ra,ffffffffc02003da <__panic>

ffffffffc0201448 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201448:	1141                	addi	sp,sp,-16
ffffffffc020144a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020144c:	14058a63          	beqz	a1,ffffffffc02015a0 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201450:	00259693          	slli	a3,a1,0x2
ffffffffc0201454:	96ae                	add	a3,a3,a1
ffffffffc0201456:	068e                	slli	a3,a3,0x3
ffffffffc0201458:	96aa                	add	a3,a3,a0
ffffffffc020145a:	87aa                	mv	a5,a0
ffffffffc020145c:	02d50263          	beq	a0,a3,ffffffffc0201480 <default_free_pages+0x38>
ffffffffc0201460:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201462:	8b05                	andi	a4,a4,1
ffffffffc0201464:	10071e63          	bnez	a4,ffffffffc0201580 <default_free_pages+0x138>
ffffffffc0201468:	6798                	ld	a4,8(a5)
ffffffffc020146a:	8b09                	andi	a4,a4,2
ffffffffc020146c:	10071a63          	bnez	a4,ffffffffc0201580 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0201470:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201474:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201478:	02878793          	addi	a5,a5,40
ffffffffc020147c:	fed792e3          	bne	a5,a3,ffffffffc0201460 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201480:	2581                	sext.w	a1,a1
ffffffffc0201482:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201484:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201488:	4789                	li	a5,2
ffffffffc020148a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020148e:	00006697          	auipc	a3,0x6
ffffffffc0201492:	b9a68693          	addi	a3,a3,-1126 # ffffffffc0207028 <free_area>
ffffffffc0201496:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201498:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020149a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020149e:	9db9                	addw	a1,a1,a4
ffffffffc02014a0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014a2:	0ad78863          	beq	a5,a3,ffffffffc0201552 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014a6:	fe878713          	addi	a4,a5,-24
ffffffffc02014aa:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014ae:	4581                	li	a1,0
            if (base < page) {
ffffffffc02014b0:	00e56a63          	bltu	a0,a4,ffffffffc02014c4 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc02014b4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014b6:	06d70263          	beq	a4,a3,ffffffffc020151a <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02014ba:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014bc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014c0:	fee57ae3          	bgeu	a0,a4,ffffffffc02014b4 <default_free_pages+0x6c>
ffffffffc02014c4:	c199                	beqz	a1,ffffffffc02014ca <default_free_pages+0x82>
ffffffffc02014c6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014ca:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02014cc:	e390                	sd	a2,0(a5)
ffffffffc02014ce:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014d0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014d2:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02014d4:	02d70063          	beq	a4,a3,ffffffffc02014f4 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02014d8:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02014dc:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02014e0:	02081613          	slli	a2,a6,0x20
ffffffffc02014e4:	9201                	srli	a2,a2,0x20
ffffffffc02014e6:	00261793          	slli	a5,a2,0x2
ffffffffc02014ea:	97b2                	add	a5,a5,a2
ffffffffc02014ec:	078e                	slli	a5,a5,0x3
ffffffffc02014ee:	97ae                	add	a5,a5,a1
ffffffffc02014f0:	02f50f63          	beq	a0,a5,ffffffffc020152e <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02014f4:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014f6:	00d70f63          	beq	a4,a3,ffffffffc0201514 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02014fa:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014fc:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201500:	02059613          	slli	a2,a1,0x20
ffffffffc0201504:	9201                	srli	a2,a2,0x20
ffffffffc0201506:	00261793          	slli	a5,a2,0x2
ffffffffc020150a:	97b2                	add	a5,a5,a2
ffffffffc020150c:	078e                	slli	a5,a5,0x3
ffffffffc020150e:	97aa                	add	a5,a5,a0
ffffffffc0201510:	04f68863          	beq	a3,a5,ffffffffc0201560 <default_free_pages+0x118>
}
ffffffffc0201514:	60a2                	ld	ra,8(sp)
ffffffffc0201516:	0141                	addi	sp,sp,16
ffffffffc0201518:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020151a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020151c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020151e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201520:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201522:	02d70563          	beq	a4,a3,ffffffffc020154c <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201526:	8832                	mv	a6,a2
ffffffffc0201528:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020152a:	87ba                	mv	a5,a4
ffffffffc020152c:	bf41                	j	ffffffffc02014bc <default_free_pages+0x74>
            p->property += base->property;
ffffffffc020152e:	491c                	lw	a5,16(a0)
ffffffffc0201530:	0107883b          	addw	a6,a5,a6
ffffffffc0201534:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201538:	57f5                	li	a5,-3
ffffffffc020153a:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020153e:	6d10                	ld	a2,24(a0)
ffffffffc0201540:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201542:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201544:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201546:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201548:	e390                	sd	a2,0(a5)
ffffffffc020154a:	b775                	j	ffffffffc02014f6 <default_free_pages+0xae>
ffffffffc020154c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020154e:	873e                	mv	a4,a5
ffffffffc0201550:	b761                	j	ffffffffc02014d8 <default_free_pages+0x90>
}
ffffffffc0201552:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201554:	e390                	sd	a2,0(a5)
ffffffffc0201556:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201558:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020155a:	ed1c                	sd	a5,24(a0)
ffffffffc020155c:	0141                	addi	sp,sp,16
ffffffffc020155e:	8082                	ret
            base->property += p->property;
ffffffffc0201560:	ff872783          	lw	a5,-8(a4)
ffffffffc0201564:	ff070693          	addi	a3,a4,-16
ffffffffc0201568:	9dbd                	addw	a1,a1,a5
ffffffffc020156a:	c90c                	sw	a1,16(a0)
ffffffffc020156c:	57f5                	li	a5,-3
ffffffffc020156e:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201572:	6314                	ld	a3,0(a4)
ffffffffc0201574:	671c                	ld	a5,8(a4)
}
ffffffffc0201576:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201578:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020157a:	e394                	sd	a3,0(a5)
ffffffffc020157c:	0141                	addi	sp,sp,16
ffffffffc020157e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201580:	00001697          	auipc	a3,0x1
ffffffffc0201584:	6e068693          	addi	a3,a3,1760 # ffffffffc0202c60 <commands+0xa48>
ffffffffc0201588:	00001617          	auipc	a2,0x1
ffffffffc020158c:	37860613          	addi	a2,a2,888 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201590:	08300593          	li	a1,131
ffffffffc0201594:	00001517          	auipc	a0,0x1
ffffffffc0201598:	38450513          	addi	a0,a0,900 # ffffffffc0202918 <commands+0x700>
ffffffffc020159c:	e3ffe0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(n > 0);
ffffffffc02015a0:	00001697          	auipc	a3,0x1
ffffffffc02015a4:	6b868693          	addi	a3,a3,1720 # ffffffffc0202c58 <commands+0xa40>
ffffffffc02015a8:	00001617          	auipc	a2,0x1
ffffffffc02015ac:	35860613          	addi	a2,a2,856 # ffffffffc0202900 <commands+0x6e8>
ffffffffc02015b0:	08000593          	li	a1,128
ffffffffc02015b4:	00001517          	auipc	a0,0x1
ffffffffc02015b8:	36450513          	addi	a0,a0,868 # ffffffffc0202918 <commands+0x700>
ffffffffc02015bc:	e1ffe0ef          	jal	ra,ffffffffc02003da <__panic>

ffffffffc02015c0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02015c0:	c959                	beqz	a0,ffffffffc0201656 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02015c2:	00006597          	auipc	a1,0x6
ffffffffc02015c6:	a6658593          	addi	a1,a1,-1434 # ffffffffc0207028 <free_area>
ffffffffc02015ca:	0105a803          	lw	a6,16(a1)
ffffffffc02015ce:	862a                	mv	a2,a0
ffffffffc02015d0:	02081793          	slli	a5,a6,0x20
ffffffffc02015d4:	9381                	srli	a5,a5,0x20
ffffffffc02015d6:	00a7ee63          	bltu	a5,a0,ffffffffc02015f2 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02015da:	87ae                	mv	a5,a1
ffffffffc02015dc:	a801                	j	ffffffffc02015ec <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02015de:	ff87a703          	lw	a4,-8(a5)
ffffffffc02015e2:	02071693          	slli	a3,a4,0x20
ffffffffc02015e6:	9281                	srli	a3,a3,0x20
ffffffffc02015e8:	00c6f763          	bgeu	a3,a2,ffffffffc02015f6 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02015ec:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015ee:	feb798e3          	bne	a5,a1,ffffffffc02015de <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02015f2:	4501                	li	a0,0
}
ffffffffc02015f4:	8082                	ret
    return listelm->prev;
ffffffffc02015f6:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015fa:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02015fe:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201602:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc0201606:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020160a:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020160e:	02d67b63          	bgeu	a2,a3,ffffffffc0201644 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0201612:	00261693          	slli	a3,a2,0x2
ffffffffc0201616:	96b2                	add	a3,a3,a2
ffffffffc0201618:	068e                	slli	a3,a3,0x3
ffffffffc020161a:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc020161c:	41c7073b          	subw	a4,a4,t3
ffffffffc0201620:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201622:	00868613          	addi	a2,a3,8
ffffffffc0201626:	4709                	li	a4,2
ffffffffc0201628:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020162c:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201630:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc0201634:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201638:	e310                	sd	a2,0(a4)
ffffffffc020163a:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020163e:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0201640:	0116bc23          	sd	a7,24(a3)
ffffffffc0201644:	41c8083b          	subw	a6,a6,t3
ffffffffc0201648:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020164c:	5775                	li	a4,-3
ffffffffc020164e:	17c1                	addi	a5,a5,-16
ffffffffc0201650:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201654:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201656:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201658:	00001697          	auipc	a3,0x1
ffffffffc020165c:	60068693          	addi	a3,a3,1536 # ffffffffc0202c58 <commands+0xa40>
ffffffffc0201660:	00001617          	auipc	a2,0x1
ffffffffc0201664:	2a060613          	addi	a2,a2,672 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0201668:	06200593          	li	a1,98
ffffffffc020166c:	00001517          	auipc	a0,0x1
ffffffffc0201670:	2ac50513          	addi	a0,a0,684 # ffffffffc0202918 <commands+0x700>
default_alloc_pages(size_t n) {
ffffffffc0201674:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201676:	d65fe0ef          	jal	ra,ffffffffc02003da <__panic>

ffffffffc020167a <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020167a:	1141                	addi	sp,sp,-16
ffffffffc020167c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020167e:	c9e1                	beqz	a1,ffffffffc020174e <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201680:	00259693          	slli	a3,a1,0x2
ffffffffc0201684:	96ae                	add	a3,a3,a1
ffffffffc0201686:	068e                	slli	a3,a3,0x3
ffffffffc0201688:	96aa                	add	a3,a3,a0
ffffffffc020168a:	87aa                	mv	a5,a0
ffffffffc020168c:	00d50f63          	beq	a0,a3,ffffffffc02016aa <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201690:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201692:	8b05                	andi	a4,a4,1
ffffffffc0201694:	cf49                	beqz	a4,ffffffffc020172e <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201696:	0007a823          	sw	zero,16(a5)
ffffffffc020169a:	0007b423          	sd	zero,8(a5)
ffffffffc020169e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016a2:	02878793          	addi	a5,a5,40
ffffffffc02016a6:	fed795e3          	bne	a5,a3,ffffffffc0201690 <default_init_memmap+0x16>
    base->property = n;
ffffffffc02016aa:	2581                	sext.w	a1,a1
ffffffffc02016ac:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016ae:	4789                	li	a5,2
ffffffffc02016b0:	00850713          	addi	a4,a0,8
ffffffffc02016b4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02016b8:	00006697          	auipc	a3,0x6
ffffffffc02016bc:	97068693          	addi	a3,a3,-1680 # ffffffffc0207028 <free_area>
ffffffffc02016c0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016c2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016c4:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016c8:	9db9                	addw	a1,a1,a4
ffffffffc02016ca:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02016cc:	04d78a63          	beq	a5,a3,ffffffffc0201720 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02016d0:	fe878713          	addi	a4,a5,-24
ffffffffc02016d4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02016d8:	4581                	li	a1,0
            if (base < page) {
ffffffffc02016da:	00e56a63          	bltu	a0,a4,ffffffffc02016ee <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02016de:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016e0:	02d70263          	beq	a4,a3,ffffffffc0201704 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02016e4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016e6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016ea:	fee57ae3          	bgeu	a0,a4,ffffffffc02016de <default_init_memmap+0x64>
ffffffffc02016ee:	c199                	beqz	a1,ffffffffc02016f4 <default_init_memmap+0x7a>
ffffffffc02016f0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016f4:	6398                	ld	a4,0(a5)
}
ffffffffc02016f6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016f8:	e390                	sd	a2,0(a5)
ffffffffc02016fa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016fc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016fe:	ed18                	sd	a4,24(a0)
ffffffffc0201700:	0141                	addi	sp,sp,16
ffffffffc0201702:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201704:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201706:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201708:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020170a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020170c:	00d70663          	beq	a4,a3,ffffffffc0201718 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201710:	8832                	mv	a6,a2
ffffffffc0201712:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201714:	87ba                	mv	a5,a4
ffffffffc0201716:	bfc1                	j	ffffffffc02016e6 <default_init_memmap+0x6c>
}
ffffffffc0201718:	60a2                	ld	ra,8(sp)
ffffffffc020171a:	e290                	sd	a2,0(a3)
ffffffffc020171c:	0141                	addi	sp,sp,16
ffffffffc020171e:	8082                	ret
ffffffffc0201720:	60a2                	ld	ra,8(sp)
ffffffffc0201722:	e390                	sd	a2,0(a5)
ffffffffc0201724:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201726:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201728:	ed1c                	sd	a5,24(a0)
ffffffffc020172a:	0141                	addi	sp,sp,16
ffffffffc020172c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020172e:	00001697          	auipc	a3,0x1
ffffffffc0201732:	55a68693          	addi	a3,a3,1370 # ffffffffc0202c88 <commands+0xa70>
ffffffffc0201736:	00001617          	auipc	a2,0x1
ffffffffc020173a:	1ca60613          	addi	a2,a2,458 # ffffffffc0202900 <commands+0x6e8>
ffffffffc020173e:	04900593          	li	a1,73
ffffffffc0201742:	00001517          	auipc	a0,0x1
ffffffffc0201746:	1d650513          	addi	a0,a0,470 # ffffffffc0202918 <commands+0x700>
ffffffffc020174a:	c91fe0ef          	jal	ra,ffffffffc02003da <__panic>
    assert(n > 0);
ffffffffc020174e:	00001697          	auipc	a3,0x1
ffffffffc0201752:	50a68693          	addi	a3,a3,1290 # ffffffffc0202c58 <commands+0xa40>
ffffffffc0201756:	00001617          	auipc	a2,0x1
ffffffffc020175a:	1aa60613          	addi	a2,a2,426 # ffffffffc0202900 <commands+0x6e8>
ffffffffc020175e:	04600593          	li	a1,70
ffffffffc0201762:	00001517          	auipc	a0,0x1
ffffffffc0201766:	1b650513          	addi	a0,a0,438 # ffffffffc0202918 <commands+0x700>
ffffffffc020176a:	c71fe0ef          	jal	ra,ffffffffc02003da <__panic>

ffffffffc020176e <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020176e:	100027f3          	csrr	a5,sstatus
ffffffffc0201772:	8b89                	andi	a5,a5,2
ffffffffc0201774:	e799                	bnez	a5,ffffffffc0201782 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201776:	00006797          	auipc	a5,0x6
ffffffffc020177a:	d027b783          	ld	a5,-766(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020177e:	6f9c                	ld	a5,24(a5)
ffffffffc0201780:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201782:	1141                	addi	sp,sp,-16
ffffffffc0201784:	e406                	sd	ra,8(sp)
ffffffffc0201786:	e022                	sd	s0,0(sp)
ffffffffc0201788:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020178a:	8b2ff0ef          	jal	ra,ffffffffc020083c <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020178e:	00006797          	auipc	a5,0x6
ffffffffc0201792:	cea7b783          	ld	a5,-790(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201796:	6f9c                	ld	a5,24(a5)
ffffffffc0201798:	8522                	mv	a0,s0
ffffffffc020179a:	9782                	jalr	a5
ffffffffc020179c:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020179e:	898ff0ef          	jal	ra,ffffffffc0200836 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02017a2:	60a2                	ld	ra,8(sp)
ffffffffc02017a4:	8522                	mv	a0,s0
ffffffffc02017a6:	6402                	ld	s0,0(sp)
ffffffffc02017a8:	0141                	addi	sp,sp,16
ffffffffc02017aa:	8082                	ret

ffffffffc02017ac <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017ac:	100027f3          	csrr	a5,sstatus
ffffffffc02017b0:	8b89                	andi	a5,a5,2
ffffffffc02017b2:	e799                	bnez	a5,ffffffffc02017c0 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02017b4:	00006797          	auipc	a5,0x6
ffffffffc02017b8:	cc47b783          	ld	a5,-828(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017bc:	739c                	ld	a5,32(a5)
ffffffffc02017be:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02017c0:	1101                	addi	sp,sp,-32
ffffffffc02017c2:	ec06                	sd	ra,24(sp)
ffffffffc02017c4:	e822                	sd	s0,16(sp)
ffffffffc02017c6:	e426                	sd	s1,8(sp)
ffffffffc02017c8:	842a                	mv	s0,a0
ffffffffc02017ca:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02017cc:	870ff0ef          	jal	ra,ffffffffc020083c <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02017d0:	00006797          	auipc	a5,0x6
ffffffffc02017d4:	ca87b783          	ld	a5,-856(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017d8:	739c                	ld	a5,32(a5)
ffffffffc02017da:	85a6                	mv	a1,s1
ffffffffc02017dc:	8522                	mv	a0,s0
ffffffffc02017de:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02017e0:	6442                	ld	s0,16(sp)
ffffffffc02017e2:	60e2                	ld	ra,24(sp)
ffffffffc02017e4:	64a2                	ld	s1,8(sp)
ffffffffc02017e6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02017e8:	84eff06f          	j	ffffffffc0200836 <intr_enable>

ffffffffc02017ec <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017ec:	100027f3          	csrr	a5,sstatus
ffffffffc02017f0:	8b89                	andi	a5,a5,2
ffffffffc02017f2:	e799                	bnez	a5,ffffffffc0201800 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02017f4:	00006797          	auipc	a5,0x6
ffffffffc02017f8:	c847b783          	ld	a5,-892(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017fc:	779c                	ld	a5,40(a5)
ffffffffc02017fe:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201800:	1141                	addi	sp,sp,-16
ffffffffc0201802:	e406                	sd	ra,8(sp)
ffffffffc0201804:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201806:	836ff0ef          	jal	ra,ffffffffc020083c <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020180a:	00006797          	auipc	a5,0x6
ffffffffc020180e:	c6e7b783          	ld	a5,-914(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201812:	779c                	ld	a5,40(a5)
ffffffffc0201814:	9782                	jalr	a5
ffffffffc0201816:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201818:	81eff0ef          	jal	ra,ffffffffc0200836 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020181c:	60a2                	ld	ra,8(sp)
ffffffffc020181e:	8522                	mv	a0,s0
ffffffffc0201820:	6402                	ld	s0,0(sp)
ffffffffc0201822:	0141                	addi	sp,sp,16
ffffffffc0201824:	8082                	ret

ffffffffc0201826 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201826:	00001797          	auipc	a5,0x1
ffffffffc020182a:	48a78793          	addi	a5,a5,1162 # ffffffffc0202cb0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020182e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201830:	7179                	addi	sp,sp,-48
ffffffffc0201832:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201834:	00001517          	auipc	a0,0x1
ffffffffc0201838:	4b450513          	addi	a0,a0,1204 # ffffffffc0202ce8 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc020183c:	00006417          	auipc	s0,0x6
ffffffffc0201840:	c3c40413          	addi	s0,s0,-964 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201844:	f406                	sd	ra,40(sp)
ffffffffc0201846:	ec26                	sd	s1,24(sp)
ffffffffc0201848:	e44e                	sd	s3,8(sp)
ffffffffc020184a:	e84a                	sd	s2,16(sp)
ffffffffc020184c:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020184e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201850:	891fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    pmm_manager->init();
ffffffffc0201854:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201856:	00006497          	auipc	s1,0x6
ffffffffc020185a:	c3a48493          	addi	s1,s1,-966 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc020185e:	679c                	ld	a5,8(a5)
ffffffffc0201860:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201862:	57f5                	li	a5,-3
ffffffffc0201864:	07fa                	slli	a5,a5,0x1e
ffffffffc0201866:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201868:	fbbfe0ef          	jal	ra,ffffffffc0200822 <get_memory_base>
ffffffffc020186c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020186e:	fbffe0ef          	jal	ra,ffffffffc020082c <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201872:	16050163          	beqz	a0,ffffffffc02019d4 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201876:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201878:	00001517          	auipc	a0,0x1
ffffffffc020187c:	4b850513          	addi	a0,a0,1208 # ffffffffc0202d30 <default_pmm_manager+0x80>
ffffffffc0201880:	861fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201884:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201888:	864e                	mv	a2,s3
ffffffffc020188a:	fffa0693          	addi	a3,s4,-1
ffffffffc020188e:	85ca                	mv	a1,s2
ffffffffc0201890:	00001517          	auipc	a0,0x1
ffffffffc0201894:	4b850513          	addi	a0,a0,1208 # ffffffffc0202d48 <default_pmm_manager+0x98>
ffffffffc0201898:	849fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020189c:	c80007b7          	lui	a5,0xc8000
ffffffffc02018a0:	8652                	mv	a2,s4
ffffffffc02018a2:	0d47e863          	bltu	a5,s4,ffffffffc0201972 <pmm_init+0x14c>
ffffffffc02018a6:	00007797          	auipc	a5,0x7
ffffffffc02018aa:	bf978793          	addi	a5,a5,-1031 # ffffffffc020849f <end+0xfff>
ffffffffc02018ae:	757d                	lui	a0,0xfffff
ffffffffc02018b0:	8d7d                	and	a0,a0,a5
ffffffffc02018b2:	8231                	srli	a2,a2,0xc
ffffffffc02018b4:	00006597          	auipc	a1,0x6
ffffffffc02018b8:	bb458593          	addi	a1,a1,-1100 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018bc:	00006817          	auipc	a6,0x6
ffffffffc02018c0:	bb480813          	addi	a6,a6,-1100 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02018c4:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018c6:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018ca:	000807b7          	lui	a5,0x80
ffffffffc02018ce:	02f60663          	beq	a2,a5,ffffffffc02018fa <pmm_init+0xd4>
ffffffffc02018d2:	4701                	li	a4,0
ffffffffc02018d4:	4781                	li	a5,0
ffffffffc02018d6:	4305                	li	t1,1
ffffffffc02018d8:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc02018dc:	953a                	add	a0,a0,a4
ffffffffc02018de:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc02018e2:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018e6:	6190                	ld	a2,0(a1)
ffffffffc02018e8:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02018ea:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018ee:	011606b3          	add	a3,a2,a7
ffffffffc02018f2:	02870713          	addi	a4,a4,40
ffffffffc02018f6:	fed7e3e3          	bltu	a5,a3,ffffffffc02018dc <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018fa:	00261693          	slli	a3,a2,0x2
ffffffffc02018fe:	96b2                	add	a3,a3,a2
ffffffffc0201900:	fec007b7          	lui	a5,0xfec00
ffffffffc0201904:	97aa                	add	a5,a5,a0
ffffffffc0201906:	068e                	slli	a3,a3,0x3
ffffffffc0201908:	96be                	add	a3,a3,a5
ffffffffc020190a:	c02007b7          	lui	a5,0xc0200
ffffffffc020190e:	0af6e763          	bltu	a3,a5,ffffffffc02019bc <pmm_init+0x196>
ffffffffc0201912:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201914:	77fd                	lui	a5,0xfffff
ffffffffc0201916:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020191a:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020191c:	04b6ee63          	bltu	a3,a1,ffffffffc0201978 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201920:	601c                	ld	a5,0(s0)
ffffffffc0201922:	7b9c                	ld	a5,48(a5)
ffffffffc0201924:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201926:	00001517          	auipc	a0,0x1
ffffffffc020192a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0202dd0 <default_pmm_manager+0x120>
ffffffffc020192e:	fb2fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201932:	00004597          	auipc	a1,0x4
ffffffffc0201936:	6ce58593          	addi	a1,a1,1742 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc020193a:	00006797          	auipc	a5,0x6
ffffffffc020193e:	b4b7b723          	sd	a1,-1202(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201942:	c02007b7          	lui	a5,0xc0200
ffffffffc0201946:	0af5e363          	bltu	a1,a5,ffffffffc02019ec <pmm_init+0x1c6>
ffffffffc020194a:	6090                	ld	a2,0(s1)
}
ffffffffc020194c:	7402                	ld	s0,32(sp)
ffffffffc020194e:	70a2                	ld	ra,40(sp)
ffffffffc0201950:	64e2                	ld	s1,24(sp)
ffffffffc0201952:	6942                	ld	s2,16(sp)
ffffffffc0201954:	69a2                	ld	s3,8(sp)
ffffffffc0201956:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201958:	40c58633          	sub	a2,a1,a2
ffffffffc020195c:	00006797          	auipc	a5,0x6
ffffffffc0201960:	b2c7b223          	sd	a2,-1244(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201964:	00001517          	auipc	a0,0x1
ffffffffc0201968:	48c50513          	addi	a0,a0,1164 # ffffffffc0202df0 <default_pmm_manager+0x140>
}
ffffffffc020196c:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020196e:	f72fe06f          	j	ffffffffc02000e0 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201972:	c8000637          	lui	a2,0xc8000
ffffffffc0201976:	bf05                	j	ffffffffc02018a6 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201978:	6705                	lui	a4,0x1
ffffffffc020197a:	177d                	addi	a4,a4,-1
ffffffffc020197c:	96ba                	add	a3,a3,a4
ffffffffc020197e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201980:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201984:	02c7f063          	bgeu	a5,a2,ffffffffc02019a4 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0201988:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020198a:	fff80737          	lui	a4,0xfff80
ffffffffc020198e:	973e                	add	a4,a4,a5
ffffffffc0201990:	00271793          	slli	a5,a4,0x2
ffffffffc0201994:	97ba                	add	a5,a5,a4
ffffffffc0201996:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201998:	8d95                	sub	a1,a1,a3
ffffffffc020199a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020199c:	81b1                	srli	a1,a1,0xc
ffffffffc020199e:	953e                	add	a0,a0,a5
ffffffffc02019a0:	9702                	jalr	a4
}
ffffffffc02019a2:	bfbd                	j	ffffffffc0201920 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02019a4:	00001617          	auipc	a2,0x1
ffffffffc02019a8:	3fc60613          	addi	a2,a2,1020 # ffffffffc0202da0 <default_pmm_manager+0xf0>
ffffffffc02019ac:	06b00593          	li	a1,107
ffffffffc02019b0:	00001517          	auipc	a0,0x1
ffffffffc02019b4:	41050513          	addi	a0,a0,1040 # ffffffffc0202dc0 <default_pmm_manager+0x110>
ffffffffc02019b8:	a23fe0ef          	jal	ra,ffffffffc02003da <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02019bc:	00001617          	auipc	a2,0x1
ffffffffc02019c0:	3bc60613          	addi	a2,a2,956 # ffffffffc0202d78 <default_pmm_manager+0xc8>
ffffffffc02019c4:	07100593          	li	a1,113
ffffffffc02019c8:	00001517          	auipc	a0,0x1
ffffffffc02019cc:	35850513          	addi	a0,a0,856 # ffffffffc0202d20 <default_pmm_manager+0x70>
ffffffffc02019d0:	a0bfe0ef          	jal	ra,ffffffffc02003da <__panic>
        panic("DTB memory info not available");
ffffffffc02019d4:	00001617          	auipc	a2,0x1
ffffffffc02019d8:	32c60613          	addi	a2,a2,812 # ffffffffc0202d00 <default_pmm_manager+0x50>
ffffffffc02019dc:	05a00593          	li	a1,90
ffffffffc02019e0:	00001517          	auipc	a0,0x1
ffffffffc02019e4:	34050513          	addi	a0,a0,832 # ffffffffc0202d20 <default_pmm_manager+0x70>
ffffffffc02019e8:	9f3fe0ef          	jal	ra,ffffffffc02003da <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019ec:	86ae                	mv	a3,a1
ffffffffc02019ee:	00001617          	auipc	a2,0x1
ffffffffc02019f2:	38a60613          	addi	a2,a2,906 # ffffffffc0202d78 <default_pmm_manager+0xc8>
ffffffffc02019f6:	08c00593          	li	a1,140
ffffffffc02019fa:	00001517          	auipc	a0,0x1
ffffffffc02019fe:	32650513          	addi	a0,a0,806 # ffffffffc0202d20 <default_pmm_manager+0x70>
ffffffffc0201a02:	9d9fe0ef          	jal	ra,ffffffffc02003da <__panic>

ffffffffc0201a06 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a06:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a0a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a0c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a10:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a12:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a16:	f022                	sd	s0,32(sp)
ffffffffc0201a18:	ec26                	sd	s1,24(sp)
ffffffffc0201a1a:	e84a                	sd	s2,16(sp)
ffffffffc0201a1c:	f406                	sd	ra,40(sp)
ffffffffc0201a1e:	e44e                	sd	s3,8(sp)
ffffffffc0201a20:	84aa                	mv	s1,a0
ffffffffc0201a22:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a24:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a28:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a2a:	03067e63          	bgeu	a2,a6,ffffffffc0201a66 <printnum+0x60>
ffffffffc0201a2e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a30:	00805763          	blez	s0,ffffffffc0201a3e <printnum+0x38>
ffffffffc0201a34:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a36:	85ca                	mv	a1,s2
ffffffffc0201a38:	854e                	mv	a0,s3
ffffffffc0201a3a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a3c:	fc65                	bnez	s0,ffffffffc0201a34 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a3e:	1a02                	slli	s4,s4,0x20
ffffffffc0201a40:	00001797          	auipc	a5,0x1
ffffffffc0201a44:	3f078793          	addi	a5,a5,1008 # ffffffffc0202e30 <default_pmm_manager+0x180>
ffffffffc0201a48:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a4c:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a4e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a50:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a54:	70a2                	ld	ra,40(sp)
ffffffffc0201a56:	69a2                	ld	s3,8(sp)
ffffffffc0201a58:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a5a:	85ca                	mv	a1,s2
ffffffffc0201a5c:	87a6                	mv	a5,s1
}
ffffffffc0201a5e:	6942                	ld	s2,16(sp)
ffffffffc0201a60:	64e2                	ld	s1,24(sp)
ffffffffc0201a62:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a64:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a66:	03065633          	divu	a2,a2,a6
ffffffffc0201a6a:	8722                	mv	a4,s0
ffffffffc0201a6c:	f9bff0ef          	jal	ra,ffffffffc0201a06 <printnum>
ffffffffc0201a70:	b7f9                	j	ffffffffc0201a3e <printnum+0x38>

ffffffffc0201a72 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a72:	7119                	addi	sp,sp,-128
ffffffffc0201a74:	f4a6                	sd	s1,104(sp)
ffffffffc0201a76:	f0ca                	sd	s2,96(sp)
ffffffffc0201a78:	ecce                	sd	s3,88(sp)
ffffffffc0201a7a:	e8d2                	sd	s4,80(sp)
ffffffffc0201a7c:	e4d6                	sd	s5,72(sp)
ffffffffc0201a7e:	e0da                	sd	s6,64(sp)
ffffffffc0201a80:	fc5e                	sd	s7,56(sp)
ffffffffc0201a82:	f06a                	sd	s10,32(sp)
ffffffffc0201a84:	fc86                	sd	ra,120(sp)
ffffffffc0201a86:	f8a2                	sd	s0,112(sp)
ffffffffc0201a88:	f862                	sd	s8,48(sp)
ffffffffc0201a8a:	f466                	sd	s9,40(sp)
ffffffffc0201a8c:	ec6e                	sd	s11,24(sp)
ffffffffc0201a8e:	892a                	mv	s2,a0
ffffffffc0201a90:	84ae                	mv	s1,a1
ffffffffc0201a92:	8d32                	mv	s10,a2
ffffffffc0201a94:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a96:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a9a:	5b7d                	li	s6,-1
ffffffffc0201a9c:	00001a97          	auipc	s5,0x1
ffffffffc0201aa0:	3c8a8a93          	addi	s5,s5,968 # ffffffffc0202e64 <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201aa4:	00001b97          	auipc	s7,0x1
ffffffffc0201aa8:	59cb8b93          	addi	s7,s7,1436 # ffffffffc0203040 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201aac:	000d4503          	lbu	a0,0(s10)
ffffffffc0201ab0:	001d0413          	addi	s0,s10,1
ffffffffc0201ab4:	01350a63          	beq	a0,s3,ffffffffc0201ac8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201ab8:	c121                	beqz	a0,ffffffffc0201af8 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201aba:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201abc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201abe:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ac0:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201ac4:	ff351ae3          	bne	a0,s3,ffffffffc0201ab8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ac8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201acc:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201ad0:	4c81                	li	s9,0
ffffffffc0201ad2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201ad4:	5c7d                	li	s8,-1
ffffffffc0201ad6:	5dfd                	li	s11,-1
ffffffffc0201ad8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201adc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ade:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201ae2:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ae6:	00140d13          	addi	s10,s0,1
ffffffffc0201aea:	04b56263          	bltu	a0,a1,ffffffffc0201b2e <vprintfmt+0xbc>
ffffffffc0201aee:	058a                	slli	a1,a1,0x2
ffffffffc0201af0:	95d6                	add	a1,a1,s5
ffffffffc0201af2:	4194                	lw	a3,0(a1)
ffffffffc0201af4:	96d6                	add	a3,a3,s5
ffffffffc0201af6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201af8:	70e6                	ld	ra,120(sp)
ffffffffc0201afa:	7446                	ld	s0,112(sp)
ffffffffc0201afc:	74a6                	ld	s1,104(sp)
ffffffffc0201afe:	7906                	ld	s2,96(sp)
ffffffffc0201b00:	69e6                	ld	s3,88(sp)
ffffffffc0201b02:	6a46                	ld	s4,80(sp)
ffffffffc0201b04:	6aa6                	ld	s5,72(sp)
ffffffffc0201b06:	6b06                	ld	s6,64(sp)
ffffffffc0201b08:	7be2                	ld	s7,56(sp)
ffffffffc0201b0a:	7c42                	ld	s8,48(sp)
ffffffffc0201b0c:	7ca2                	ld	s9,40(sp)
ffffffffc0201b0e:	7d02                	ld	s10,32(sp)
ffffffffc0201b10:	6de2                	ld	s11,24(sp)
ffffffffc0201b12:	6109                	addi	sp,sp,128
ffffffffc0201b14:	8082                	ret
            padc = '0';
ffffffffc0201b16:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b18:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b1c:	846a                	mv	s0,s10
ffffffffc0201b1e:	00140d13          	addi	s10,s0,1
ffffffffc0201b22:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b26:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b2a:	fcb572e3          	bgeu	a0,a1,ffffffffc0201aee <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b2e:	85a6                	mv	a1,s1
ffffffffc0201b30:	02500513          	li	a0,37
ffffffffc0201b34:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b36:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b3a:	8d22                	mv	s10,s0
ffffffffc0201b3c:	f73788e3          	beq	a5,s3,ffffffffc0201aac <vprintfmt+0x3a>
ffffffffc0201b40:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b44:	1d7d                	addi	s10,s10,-1
ffffffffc0201b46:	ff379de3          	bne	a5,s3,ffffffffc0201b40 <vprintfmt+0xce>
ffffffffc0201b4a:	b78d                	j	ffffffffc0201aac <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b4c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b50:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b54:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b56:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b5a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b5e:	02d86463          	bltu	a6,a3,ffffffffc0201b86 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b62:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b66:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b6a:	0186873b          	addw	a4,a3,s8
ffffffffc0201b6e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b72:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b74:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b78:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b7a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b7e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b82:	fed870e3          	bgeu	a6,a3,ffffffffc0201b62 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b86:	f40ddce3          	bgez	s11,ffffffffc0201ade <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b8a:	8de2                	mv	s11,s8
ffffffffc0201b8c:	5c7d                	li	s8,-1
ffffffffc0201b8e:	bf81                	j	ffffffffc0201ade <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b90:	fffdc693          	not	a3,s11
ffffffffc0201b94:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b96:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b9a:	00144603          	lbu	a2,1(s0)
ffffffffc0201b9e:	2d81                	sext.w	s11,s11
ffffffffc0201ba0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201ba2:	bf35                	j	ffffffffc0201ade <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201ba4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ba8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201bac:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bae:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201bb0:	bfd9                	j	ffffffffc0201b86 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201bb2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bb4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bb8:	01174463          	blt	a4,a7,ffffffffc0201bc0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201bbc:	1a088e63          	beqz	a7,ffffffffc0201d78 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201bc0:	000a3603          	ld	a2,0(s4)
ffffffffc0201bc4:	46c1                	li	a3,16
ffffffffc0201bc6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201bc8:	2781                	sext.w	a5,a5
ffffffffc0201bca:	876e                	mv	a4,s11
ffffffffc0201bcc:	85a6                	mv	a1,s1
ffffffffc0201bce:	854a                	mv	a0,s2
ffffffffc0201bd0:	e37ff0ef          	jal	ra,ffffffffc0201a06 <printnum>
            break;
ffffffffc0201bd4:	bde1                	j	ffffffffc0201aac <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201bd6:	000a2503          	lw	a0,0(s4)
ffffffffc0201bda:	85a6                	mv	a1,s1
ffffffffc0201bdc:	0a21                	addi	s4,s4,8
ffffffffc0201bde:	9902                	jalr	s2
            break;
ffffffffc0201be0:	b5f1                	j	ffffffffc0201aac <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201be2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201be4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201be8:	01174463          	blt	a4,a7,ffffffffc0201bf0 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201bec:	18088163          	beqz	a7,ffffffffc0201d6e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201bf0:	000a3603          	ld	a2,0(s4)
ffffffffc0201bf4:	46a9                	li	a3,10
ffffffffc0201bf6:	8a2e                	mv	s4,a1
ffffffffc0201bf8:	bfc1                	j	ffffffffc0201bc8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bfa:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201bfe:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c00:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c02:	bdf1                	j	ffffffffc0201ade <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c04:	85a6                	mv	a1,s1
ffffffffc0201c06:	02500513          	li	a0,37
ffffffffc0201c0a:	9902                	jalr	s2
            break;
ffffffffc0201c0c:	b545                	j	ffffffffc0201aac <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c0e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c12:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c14:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c16:	b5e1                	j	ffffffffc0201ade <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c18:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c1a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c1e:	01174463          	blt	a4,a7,ffffffffc0201c26 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c22:	14088163          	beqz	a7,ffffffffc0201d64 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c26:	000a3603          	ld	a2,0(s4)
ffffffffc0201c2a:	46a1                	li	a3,8
ffffffffc0201c2c:	8a2e                	mv	s4,a1
ffffffffc0201c2e:	bf69                	j	ffffffffc0201bc8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c30:	03000513          	li	a0,48
ffffffffc0201c34:	85a6                	mv	a1,s1
ffffffffc0201c36:	e03e                	sd	a5,0(sp)
ffffffffc0201c38:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c3a:	85a6                	mv	a1,s1
ffffffffc0201c3c:	07800513          	li	a0,120
ffffffffc0201c40:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c42:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c44:	6782                	ld	a5,0(sp)
ffffffffc0201c46:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c48:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c4c:	bfb5                	j	ffffffffc0201bc8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c4e:	000a3403          	ld	s0,0(s4)
ffffffffc0201c52:	008a0713          	addi	a4,s4,8
ffffffffc0201c56:	e03a                	sd	a4,0(sp)
ffffffffc0201c58:	14040263          	beqz	s0,ffffffffc0201d9c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c5c:	0fb05763          	blez	s11,ffffffffc0201d4a <vprintfmt+0x2d8>
ffffffffc0201c60:	02d00693          	li	a3,45
ffffffffc0201c64:	0cd79163          	bne	a5,a3,ffffffffc0201d26 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c68:	00044783          	lbu	a5,0(s0)
ffffffffc0201c6c:	0007851b          	sext.w	a0,a5
ffffffffc0201c70:	cf85                	beqz	a5,ffffffffc0201ca8 <vprintfmt+0x236>
ffffffffc0201c72:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c76:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c7a:	000c4563          	bltz	s8,ffffffffc0201c84 <vprintfmt+0x212>
ffffffffc0201c7e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c80:	036c0263          	beq	s8,s6,ffffffffc0201ca4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c84:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c86:	0e0c8e63          	beqz	s9,ffffffffc0201d82 <vprintfmt+0x310>
ffffffffc0201c8a:	3781                	addiw	a5,a5,-32
ffffffffc0201c8c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d82 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c90:	03f00513          	li	a0,63
ffffffffc0201c94:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c96:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c9a:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c9c:	0a05                	addi	s4,s4,1
ffffffffc0201c9e:	0007851b          	sext.w	a0,a5
ffffffffc0201ca2:	ffe1                	bnez	a5,ffffffffc0201c7a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201ca4:	01b05963          	blez	s11,ffffffffc0201cb6 <vprintfmt+0x244>
ffffffffc0201ca8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201caa:	85a6                	mv	a1,s1
ffffffffc0201cac:	02000513          	li	a0,32
ffffffffc0201cb0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201cb2:	fe0d9be3          	bnez	s11,ffffffffc0201ca8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cb6:	6a02                	ld	s4,0(sp)
ffffffffc0201cb8:	bbd5                	j	ffffffffc0201aac <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201cba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cbc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201cc0:	01174463          	blt	a4,a7,ffffffffc0201cc8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201cc4:	08088d63          	beqz	a7,ffffffffc0201d5e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201cc8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201ccc:	0a044d63          	bltz	s0,ffffffffc0201d86 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201cd0:	8622                	mv	a2,s0
ffffffffc0201cd2:	8a66                	mv	s4,s9
ffffffffc0201cd4:	46a9                	li	a3,10
ffffffffc0201cd6:	bdcd                	j	ffffffffc0201bc8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201cd8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cdc:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201cde:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201ce0:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201ce4:	8fb5                	xor	a5,a5,a3
ffffffffc0201ce6:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cea:	02d74163          	blt	a4,a3,ffffffffc0201d0c <vprintfmt+0x29a>
ffffffffc0201cee:	00369793          	slli	a5,a3,0x3
ffffffffc0201cf2:	97de                	add	a5,a5,s7
ffffffffc0201cf4:	639c                	ld	a5,0(a5)
ffffffffc0201cf6:	cb99                	beqz	a5,ffffffffc0201d0c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201cf8:	86be                	mv	a3,a5
ffffffffc0201cfa:	00001617          	auipc	a2,0x1
ffffffffc0201cfe:	16660613          	addi	a2,a2,358 # ffffffffc0202e60 <default_pmm_manager+0x1b0>
ffffffffc0201d02:	85a6                	mv	a1,s1
ffffffffc0201d04:	854a                	mv	a0,s2
ffffffffc0201d06:	0ce000ef          	jal	ra,ffffffffc0201dd4 <printfmt>
ffffffffc0201d0a:	b34d                	j	ffffffffc0201aac <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d0c:	00001617          	auipc	a2,0x1
ffffffffc0201d10:	14460613          	addi	a2,a2,324 # ffffffffc0202e50 <default_pmm_manager+0x1a0>
ffffffffc0201d14:	85a6                	mv	a1,s1
ffffffffc0201d16:	854a                	mv	a0,s2
ffffffffc0201d18:	0bc000ef          	jal	ra,ffffffffc0201dd4 <printfmt>
ffffffffc0201d1c:	bb41                	j	ffffffffc0201aac <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d1e:	00001417          	auipc	s0,0x1
ffffffffc0201d22:	12a40413          	addi	s0,s0,298 # ffffffffc0202e48 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d26:	85e2                	mv	a1,s8
ffffffffc0201d28:	8522                	mv	a0,s0
ffffffffc0201d2a:	e43e                	sd	a5,8(sp)
ffffffffc0201d2c:	20c000ef          	jal	ra,ffffffffc0201f38 <strnlen>
ffffffffc0201d30:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d34:	01b05b63          	blez	s11,ffffffffc0201d4a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d38:	67a2                	ld	a5,8(sp)
ffffffffc0201d3a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d3e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d40:	85a6                	mv	a1,s1
ffffffffc0201d42:	8552                	mv	a0,s4
ffffffffc0201d44:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d46:	fe0d9ce3          	bnez	s11,ffffffffc0201d3e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d4a:	00044783          	lbu	a5,0(s0)
ffffffffc0201d4e:	00140a13          	addi	s4,s0,1
ffffffffc0201d52:	0007851b          	sext.w	a0,a5
ffffffffc0201d56:	d3a5                	beqz	a5,ffffffffc0201cb6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d58:	05e00413          	li	s0,94
ffffffffc0201d5c:	bf39                	j	ffffffffc0201c7a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d5e:	000a2403          	lw	s0,0(s4)
ffffffffc0201d62:	b7ad                	j	ffffffffc0201ccc <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d64:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d68:	46a1                	li	a3,8
ffffffffc0201d6a:	8a2e                	mv	s4,a1
ffffffffc0201d6c:	bdb1                	j	ffffffffc0201bc8 <vprintfmt+0x156>
ffffffffc0201d6e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d72:	46a9                	li	a3,10
ffffffffc0201d74:	8a2e                	mv	s4,a1
ffffffffc0201d76:	bd89                	j	ffffffffc0201bc8 <vprintfmt+0x156>
ffffffffc0201d78:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d7c:	46c1                	li	a3,16
ffffffffc0201d7e:	8a2e                	mv	s4,a1
ffffffffc0201d80:	b5a1                	j	ffffffffc0201bc8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d82:	9902                	jalr	s2
ffffffffc0201d84:	bf09                	j	ffffffffc0201c96 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d86:	85a6                	mv	a1,s1
ffffffffc0201d88:	02d00513          	li	a0,45
ffffffffc0201d8c:	e03e                	sd	a5,0(sp)
ffffffffc0201d8e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d90:	6782                	ld	a5,0(sp)
ffffffffc0201d92:	8a66                	mv	s4,s9
ffffffffc0201d94:	40800633          	neg	a2,s0
ffffffffc0201d98:	46a9                	li	a3,10
ffffffffc0201d9a:	b53d                	j	ffffffffc0201bc8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d9c:	03b05163          	blez	s11,ffffffffc0201dbe <vprintfmt+0x34c>
ffffffffc0201da0:	02d00693          	li	a3,45
ffffffffc0201da4:	f6d79de3          	bne	a5,a3,ffffffffc0201d1e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201da8:	00001417          	auipc	s0,0x1
ffffffffc0201dac:	0a040413          	addi	s0,s0,160 # ffffffffc0202e48 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201db0:	02800793          	li	a5,40
ffffffffc0201db4:	02800513          	li	a0,40
ffffffffc0201db8:	00140a13          	addi	s4,s0,1
ffffffffc0201dbc:	bd6d                	j	ffffffffc0201c76 <vprintfmt+0x204>
ffffffffc0201dbe:	00001a17          	auipc	s4,0x1
ffffffffc0201dc2:	08ba0a13          	addi	s4,s4,139 # ffffffffc0202e49 <default_pmm_manager+0x199>
ffffffffc0201dc6:	02800513          	li	a0,40
ffffffffc0201dca:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dce:	05e00413          	li	s0,94
ffffffffc0201dd2:	b565                	j	ffffffffc0201c7a <vprintfmt+0x208>

ffffffffc0201dd4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dd4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201dd6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dda:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201ddc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dde:	ec06                	sd	ra,24(sp)
ffffffffc0201de0:	f83a                	sd	a4,48(sp)
ffffffffc0201de2:	fc3e                	sd	a5,56(sp)
ffffffffc0201de4:	e0c2                	sd	a6,64(sp)
ffffffffc0201de6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201de8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201dea:	c89ff0ef          	jal	ra,ffffffffc0201a72 <vprintfmt>
}
ffffffffc0201dee:	60e2                	ld	ra,24(sp)
ffffffffc0201df0:	6161                	addi	sp,sp,80
ffffffffc0201df2:	8082                	ret

ffffffffc0201df4 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201df4:	715d                	addi	sp,sp,-80
ffffffffc0201df6:	e486                	sd	ra,72(sp)
ffffffffc0201df8:	e0a6                	sd	s1,64(sp)
ffffffffc0201dfa:	fc4a                	sd	s2,56(sp)
ffffffffc0201dfc:	f84e                	sd	s3,48(sp)
ffffffffc0201dfe:	f452                	sd	s4,40(sp)
ffffffffc0201e00:	f056                	sd	s5,32(sp)
ffffffffc0201e02:	ec5a                	sd	s6,24(sp)
ffffffffc0201e04:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e06:	c901                	beqz	a0,ffffffffc0201e16 <readline+0x22>
ffffffffc0201e08:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e0a:	00001517          	auipc	a0,0x1
ffffffffc0201e0e:	05650513          	addi	a0,a0,86 # ffffffffc0202e60 <default_pmm_manager+0x1b0>
ffffffffc0201e12:	acefe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
readline(const char *prompt) {
ffffffffc0201e16:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e18:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e1a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e1c:	4aa9                	li	s5,10
ffffffffc0201e1e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e20:	00005b97          	auipc	s7,0x5
ffffffffc0201e24:	220b8b93          	addi	s7,s7,544 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e28:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e2c:	b2cfe0ef          	jal	ra,ffffffffc0200158 <getchar>
        if (c < 0) {
ffffffffc0201e30:	00054a63          	bltz	a0,ffffffffc0201e44 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e34:	00a95a63          	bge	s2,a0,ffffffffc0201e48 <readline+0x54>
ffffffffc0201e38:	029a5263          	bge	s4,s1,ffffffffc0201e5c <readline+0x68>
        c = getchar();
ffffffffc0201e3c:	b1cfe0ef          	jal	ra,ffffffffc0200158 <getchar>
        if (c < 0) {
ffffffffc0201e40:	fe055ae3          	bgez	a0,ffffffffc0201e34 <readline+0x40>
            return NULL;
ffffffffc0201e44:	4501                	li	a0,0
ffffffffc0201e46:	a091                	j	ffffffffc0201e8a <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e48:	03351463          	bne	a0,s3,ffffffffc0201e70 <readline+0x7c>
ffffffffc0201e4c:	e8a9                	bnez	s1,ffffffffc0201e9e <readline+0xaa>
        c = getchar();
ffffffffc0201e4e:	b0afe0ef          	jal	ra,ffffffffc0200158 <getchar>
        if (c < 0) {
ffffffffc0201e52:	fe0549e3          	bltz	a0,ffffffffc0201e44 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e56:	fea959e3          	bge	s2,a0,ffffffffc0201e48 <readline+0x54>
ffffffffc0201e5a:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e5c:	e42a                	sd	a0,8(sp)
ffffffffc0201e5e:	ab8fe0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i ++] = c;
ffffffffc0201e62:	6522                	ld	a0,8(sp)
ffffffffc0201e64:	009b87b3          	add	a5,s7,s1
ffffffffc0201e68:	2485                	addiw	s1,s1,1
ffffffffc0201e6a:	00a78023          	sb	a0,0(a5)
ffffffffc0201e6e:	bf7d                	j	ffffffffc0201e2c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e70:	01550463          	beq	a0,s5,ffffffffc0201e78 <readline+0x84>
ffffffffc0201e74:	fb651ce3          	bne	a0,s6,ffffffffc0201e2c <readline+0x38>
            cputchar(c);
ffffffffc0201e78:	a9efe0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i] = '\0';
ffffffffc0201e7c:	00005517          	auipc	a0,0x5
ffffffffc0201e80:	1c450513          	addi	a0,a0,452 # ffffffffc0207040 <buf>
ffffffffc0201e84:	94aa                	add	s1,s1,a0
ffffffffc0201e86:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e8a:	60a6                	ld	ra,72(sp)
ffffffffc0201e8c:	6486                	ld	s1,64(sp)
ffffffffc0201e8e:	7962                	ld	s2,56(sp)
ffffffffc0201e90:	79c2                	ld	s3,48(sp)
ffffffffc0201e92:	7a22                	ld	s4,40(sp)
ffffffffc0201e94:	7a82                	ld	s5,32(sp)
ffffffffc0201e96:	6b62                	ld	s6,24(sp)
ffffffffc0201e98:	6bc2                	ld	s7,16(sp)
ffffffffc0201e9a:	6161                	addi	sp,sp,80
ffffffffc0201e9c:	8082                	ret
            cputchar(c);
ffffffffc0201e9e:	4521                	li	a0,8
ffffffffc0201ea0:	a76fe0ef          	jal	ra,ffffffffc0200116 <cputchar>
            i --;
ffffffffc0201ea4:	34fd                	addiw	s1,s1,-1
ffffffffc0201ea6:	b759                	j	ffffffffc0201e2c <readline+0x38>

ffffffffc0201ea8 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201ea8:	4781                	li	a5,0
ffffffffc0201eaa:	00005717          	auipc	a4,0x5
ffffffffc0201eae:	16e73703          	ld	a4,366(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201eb2:	88ba                	mv	a7,a4
ffffffffc0201eb4:	852a                	mv	a0,a0
ffffffffc0201eb6:	85be                	mv	a1,a5
ffffffffc0201eb8:	863e                	mv	a2,a5
ffffffffc0201eba:	00000073          	ecall
ffffffffc0201ebe:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201ec0:	8082                	ret

ffffffffc0201ec2 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201ec2:	4781                	li	a5,0
ffffffffc0201ec4:	00005717          	auipc	a4,0x5
ffffffffc0201ec8:	5d473703          	ld	a4,1492(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201ecc:	88ba                	mv	a7,a4
ffffffffc0201ece:	852a                	mv	a0,a0
ffffffffc0201ed0:	85be                	mv	a1,a5
ffffffffc0201ed2:	863e                	mv	a2,a5
ffffffffc0201ed4:	00000073          	ecall
ffffffffc0201ed8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201eda:	8082                	ret

ffffffffc0201edc <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201edc:	4501                	li	a0,0
ffffffffc0201ede:	00005797          	auipc	a5,0x5
ffffffffc0201ee2:	1327b783          	ld	a5,306(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201ee6:	88be                	mv	a7,a5
ffffffffc0201ee8:	852a                	mv	a0,a0
ffffffffc0201eea:	85aa                	mv	a1,a0
ffffffffc0201eec:	862a                	mv	a2,a0
ffffffffc0201eee:	00000073          	ecall
ffffffffc0201ef2:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201ef4:	2501                	sext.w	a0,a0
ffffffffc0201ef6:	8082                	ret

ffffffffc0201ef8 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201ef8:	4781                	li	a5,0
ffffffffc0201efa:	00005717          	auipc	a4,0x5
ffffffffc0201efe:	12673703          	ld	a4,294(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201f02:	88ba                	mv	a7,a4
ffffffffc0201f04:	853e                	mv	a0,a5
ffffffffc0201f06:	85be                	mv	a1,a5
ffffffffc0201f08:	863e                	mv	a2,a5
ffffffffc0201f0a:	00000073          	ecall
ffffffffc0201f0e:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
}
ffffffffc0201f10:	8082                	ret

ffffffffc0201f12 <sbi_trigger_breakpoint>:

// 触发断点异常的函数
void sbi_trigger_breakpoint(void) {
ffffffffc0201f12:	00100073          	ebreak
    // 执行ebreak指令将立即触发断点异常
    __asm__ volatile (".word 0x00100073");//ebreak
}
ffffffffc0201f16:	8082                	ret

ffffffffc0201f18 <sbi_trigger_illegal_instruction>:

// 触发非法指令异常的函数
void sbi_trigger_illegal_instruction(void) {
ffffffffc0201f18:	0000                	unimp
ffffffffc0201f1a:	0000                	unimp
    // 嵌入一个被定义为非法的指令编码
    __asm__ volatile (".word 0x00000000");
ffffffffc0201f1c:	8082                	ret

ffffffffc0201f1e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f1e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f22:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f24:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f26:	cb81                	beqz	a5,ffffffffc0201f36 <strlen+0x18>
        cnt ++;
ffffffffc0201f28:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f2a:	00a707b3          	add	a5,a4,a0
ffffffffc0201f2e:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f32:	fbfd                	bnez	a5,ffffffffc0201f28 <strlen+0xa>
ffffffffc0201f34:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f36:	8082                	ret

ffffffffc0201f38 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f38:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f3a:	e589                	bnez	a1,ffffffffc0201f44 <strnlen+0xc>
ffffffffc0201f3c:	a811                	j	ffffffffc0201f50 <strnlen+0x18>
        cnt ++;
ffffffffc0201f3e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f40:	00f58863          	beq	a1,a5,ffffffffc0201f50 <strnlen+0x18>
ffffffffc0201f44:	00f50733          	add	a4,a0,a5
ffffffffc0201f48:	00074703          	lbu	a4,0(a4)
ffffffffc0201f4c:	fb6d                	bnez	a4,ffffffffc0201f3e <strnlen+0x6>
ffffffffc0201f4e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f50:	852e                	mv	a0,a1
ffffffffc0201f52:	8082                	ret

ffffffffc0201f54 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f54:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f58:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f5c:	cb89                	beqz	a5,ffffffffc0201f6e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201f5e:	0505                	addi	a0,a0,1
ffffffffc0201f60:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f62:	fee789e3          	beq	a5,a4,ffffffffc0201f54 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f66:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f6a:	9d19                	subw	a0,a0,a4
ffffffffc0201f6c:	8082                	ret
ffffffffc0201f6e:	4501                	li	a0,0
ffffffffc0201f70:	bfed                	j	ffffffffc0201f6a <strcmp+0x16>

ffffffffc0201f72 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f72:	c20d                	beqz	a2,ffffffffc0201f94 <strncmp+0x22>
ffffffffc0201f74:	962e                	add	a2,a2,a1
ffffffffc0201f76:	a031                	j	ffffffffc0201f82 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201f78:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f7a:	00e79a63          	bne	a5,a4,ffffffffc0201f8e <strncmp+0x1c>
ffffffffc0201f7e:	00b60b63          	beq	a2,a1,ffffffffc0201f94 <strncmp+0x22>
ffffffffc0201f82:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f86:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f88:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201f8c:	f7f5                	bnez	a5,ffffffffc0201f78 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f8e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201f92:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f94:	4501                	li	a0,0
ffffffffc0201f96:	8082                	ret

ffffffffc0201f98 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f98:	00054783          	lbu	a5,0(a0)
ffffffffc0201f9c:	c799                	beqz	a5,ffffffffc0201faa <strchr+0x12>
        if (*s == c) {
ffffffffc0201f9e:	00f58763          	beq	a1,a5,ffffffffc0201fac <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201fa2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201fa6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201fa8:	fbfd                	bnez	a5,ffffffffc0201f9e <strchr+0x6>
    }
    return NULL;
ffffffffc0201faa:	4501                	li	a0,0
}
ffffffffc0201fac:	8082                	ret

ffffffffc0201fae <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201fae:	ca01                	beqz	a2,ffffffffc0201fbe <memset+0x10>
ffffffffc0201fb0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201fb2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fb4:	0785                	addi	a5,a5,1
ffffffffc0201fb6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fba:	fec79de3          	bne	a5,a2,ffffffffc0201fb4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201fbe:	8082                	ret
