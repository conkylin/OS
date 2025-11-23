
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
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
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	67f010ef          	jal	ra,ffffffffc0201eea <memset>
    dtb_init();
ffffffffc0200070:	41a000ef          	jal	ra,ffffffffc020048a <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	408000ef          	jal	ra,ffffffffc020047c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e8850513          	addi	a0,a0,-376 # ffffffffc0201f00 <etext+0x4>
ffffffffc0200080:	09c000ef          	jal	ra,ffffffffc020011c <cputs>

    print_kerninfo();
ffffffffc0200084:	0e8000ef          	jal	ra,ffffffffc020016c <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7be000ef          	jal	ra,ffffffffc0200846 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	6e2010ef          	jal	ra,ffffffffc020176e <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7b6000ef          	jal	ra,ffffffffc0200846 <idt_init>
ffffffffc0200094:	0000                	unimp
ffffffffc0200096:	0000                	unimp
    
    __asm__ volatile (".word 0x00000000");
ffffffffc0200098:	00100073          	ebreak
    //intr_enable();
    //sbi_trigger_illegal_instruction();
    __asm__ volatile (".word 0x00100073");
ffffffffc020009c:	0000                	unimp
ffffffffc020009e:	0000                	unimp
    //intr_enable();
    //sbi_trigger_breakpoint();
    __asm__ volatile (".word 0x00000000");
    //intr_enable();
    
    clock_init();   // init clock interrupt
ffffffffc02000a0:	39a000ef          	jal	ra,ffffffffc020043a <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc02000a4:	796000ef          	jal	ra,ffffffffc020083a <intr_enable>

    /* do nothing */
    while (1)
ffffffffc02000a8:	a001                	j	ffffffffc02000a8 <kern_init+0x54>

ffffffffc02000aa <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000aa:	1141                	addi	sp,sp,-16
ffffffffc02000ac:	e022                	sd	s0,0(sp)
ffffffffc02000ae:	e406                	sd	ra,8(sp)
ffffffffc02000b0:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000b2:	3cc000ef          	jal	ra,ffffffffc020047e <cons_putc>
    (*cnt) ++;
ffffffffc02000b6:	401c                	lw	a5,0(s0)
}
ffffffffc02000b8:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ba:	2785                	addiw	a5,a5,1
ffffffffc02000bc:	c01c                	sw	a5,0(s0)
}
ffffffffc02000be:	6402                	ld	s0,0(sp)
ffffffffc02000c0:	0141                	addi	sp,sp,16
ffffffffc02000c2:	8082                	ret

ffffffffc02000c4 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c4:	1101                	addi	sp,sp,-32
ffffffffc02000c6:	862a                	mv	a2,a0
ffffffffc02000c8:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	00000517          	auipc	a0,0x0
ffffffffc02000ce:	fe050513          	addi	a0,a0,-32 # ffffffffc02000aa <cputch>
ffffffffc02000d2:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000d4:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d6:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d8:	0e3010ef          	jal	ra,ffffffffc02019ba <vprintfmt>
    return cnt;
}
ffffffffc02000dc:	60e2                	ld	ra,24(sp)
ffffffffc02000de:	4532                	lw	a0,12(sp)
ffffffffc02000e0:	6105                	addi	sp,sp,32
ffffffffc02000e2:	8082                	ret

ffffffffc02000e4 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000e4:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e6:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000ea:	8e2a                	mv	t3,a0
ffffffffc02000ec:	f42e                	sd	a1,40(sp)
ffffffffc02000ee:	f832                	sd	a2,48(sp)
ffffffffc02000f0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f2:	00000517          	auipc	a0,0x0
ffffffffc02000f6:	fb850513          	addi	a0,a0,-72 # ffffffffc02000aa <cputch>
ffffffffc02000fa:	004c                	addi	a1,sp,4
ffffffffc02000fc:	869a                	mv	a3,t1
ffffffffc02000fe:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200100:	ec06                	sd	ra,24(sp)
ffffffffc0200102:	e0ba                	sd	a4,64(sp)
ffffffffc0200104:	e4be                	sd	a5,72(sp)
ffffffffc0200106:	e8c2                	sd	a6,80(sp)
ffffffffc0200108:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020010a:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020010c:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020010e:	0ad010ef          	jal	ra,ffffffffc02019ba <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200112:	60e2                	ld	ra,24(sp)
ffffffffc0200114:	4512                	lw	a0,4(sp)
ffffffffc0200116:	6125                	addi	sp,sp,96
ffffffffc0200118:	8082                	ret

ffffffffc020011a <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020011a:	a695                	j	ffffffffc020047e <cons_putc>

ffffffffc020011c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020011c:	1101                	addi	sp,sp,-32
ffffffffc020011e:	e822                	sd	s0,16(sp)
ffffffffc0200120:	ec06                	sd	ra,24(sp)
ffffffffc0200122:	e426                	sd	s1,8(sp)
ffffffffc0200124:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	00054503          	lbu	a0,0(a0)
ffffffffc020012a:	c51d                	beqz	a0,ffffffffc0200158 <cputs+0x3c>
ffffffffc020012c:	0405                	addi	s0,s0,1
ffffffffc020012e:	4485                	li	s1,1
ffffffffc0200130:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200132:	34c000ef          	jal	ra,ffffffffc020047e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200136:	00044503          	lbu	a0,0(s0)
ffffffffc020013a:	008487bb          	addw	a5,s1,s0
ffffffffc020013e:	0405                	addi	s0,s0,1
ffffffffc0200140:	f96d                	bnez	a0,ffffffffc0200132 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200142:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200146:	4529                	li	a0,10
ffffffffc0200148:	336000ef          	jal	ra,ffffffffc020047e <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020014c:	60e2                	ld	ra,24(sp)
ffffffffc020014e:	8522                	mv	a0,s0
ffffffffc0200150:	6442                	ld	s0,16(sp)
ffffffffc0200152:	64a2                	ld	s1,8(sp)
ffffffffc0200154:	6105                	addi	sp,sp,32
ffffffffc0200156:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200158:	4405                	li	s0,1
ffffffffc020015a:	b7f5                	j	ffffffffc0200146 <cputs+0x2a>

ffffffffc020015c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020015c:	1141                	addi	sp,sp,-16
ffffffffc020015e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200160:	326000ef          	jal	ra,ffffffffc0200486 <cons_getc>
ffffffffc0200164:	dd75                	beqz	a0,ffffffffc0200160 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200166:	60a2                	ld	ra,8(sp)
ffffffffc0200168:	0141                	addi	sp,sp,16
ffffffffc020016a:	8082                	ret

ffffffffc020016c <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020016c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020016e:	00002517          	auipc	a0,0x2
ffffffffc0200172:	db250513          	addi	a0,a0,-590 # ffffffffc0201f20 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200176:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200178:	f6dff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020017c:	00000597          	auipc	a1,0x0
ffffffffc0200180:	ed858593          	addi	a1,a1,-296 # ffffffffc0200054 <kern_init>
ffffffffc0200184:	00002517          	auipc	a0,0x2
ffffffffc0200188:	dbc50513          	addi	a0,a0,-580 # ffffffffc0201f40 <etext+0x44>
ffffffffc020018c:	f59ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200190:	00002597          	auipc	a1,0x2
ffffffffc0200194:	d6c58593          	addi	a1,a1,-660 # ffffffffc0201efc <etext>
ffffffffc0200198:	00002517          	auipc	a0,0x2
ffffffffc020019c:	dc850513          	addi	a0,a0,-568 # ffffffffc0201f60 <etext+0x64>
ffffffffc02001a0:	f45ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a4:	00006597          	auipc	a1,0x6
ffffffffc02001a8:	e8458593          	addi	a1,a1,-380 # ffffffffc0206028 <free_area>
ffffffffc02001ac:	00002517          	auipc	a0,0x2
ffffffffc02001b0:	dd450513          	addi	a0,a0,-556 # ffffffffc0201f80 <etext+0x84>
ffffffffc02001b4:	f31ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b8:	00006597          	auipc	a1,0x6
ffffffffc02001bc:	2e858593          	addi	a1,a1,744 # ffffffffc02064a0 <end>
ffffffffc02001c0:	00002517          	auipc	a0,0x2
ffffffffc02001c4:	de050513          	addi	a0,a0,-544 # ffffffffc0201fa0 <etext+0xa4>
ffffffffc02001c8:	f1dff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001cc:	00006597          	auipc	a1,0x6
ffffffffc02001d0:	6d358593          	addi	a1,a1,1747 # ffffffffc020689f <end+0x3ff>
ffffffffc02001d4:	00000797          	auipc	a5,0x0
ffffffffc02001d8:	e8078793          	addi	a5,a5,-384 # ffffffffc0200054 <kern_init>
ffffffffc02001dc:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e0:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001e4:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e6:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001ea:	95be                	add	a1,a1,a5
ffffffffc02001ec:	85a9                	srai	a1,a1,0xa
ffffffffc02001ee:	00002517          	auipc	a0,0x2
ffffffffc02001f2:	dd250513          	addi	a0,a0,-558 # ffffffffc0201fc0 <etext+0xc4>
}
ffffffffc02001f6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f8:	b5f5                	j	ffffffffc02000e4 <cprintf>

ffffffffc02001fa <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001fa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001fc:	00002617          	auipc	a2,0x2
ffffffffc0200200:	df460613          	addi	a2,a2,-524 # ffffffffc0201ff0 <etext+0xf4>
ffffffffc0200204:	04d00593          	li	a1,77
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	e0050513          	addi	a0,a0,-512 # ffffffffc0202008 <etext+0x10c>
void print_stackframe(void) {
ffffffffc0200210:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200212:	1cc000ef          	jal	ra,ffffffffc02003de <__panic>

ffffffffc0200216 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200216:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200218:	00002617          	auipc	a2,0x2
ffffffffc020021c:	e0860613          	addi	a2,a2,-504 # ffffffffc0202020 <etext+0x124>
ffffffffc0200220:	00002597          	auipc	a1,0x2
ffffffffc0200224:	e2058593          	addi	a1,a1,-480 # ffffffffc0202040 <etext+0x144>
ffffffffc0200228:	00002517          	auipc	a0,0x2
ffffffffc020022c:	e2050513          	addi	a0,a0,-480 # ffffffffc0202048 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200230:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200232:	eb3ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
ffffffffc0200236:	00002617          	auipc	a2,0x2
ffffffffc020023a:	e2260613          	addi	a2,a2,-478 # ffffffffc0202058 <etext+0x15c>
ffffffffc020023e:	00002597          	auipc	a1,0x2
ffffffffc0200242:	e4258593          	addi	a1,a1,-446 # ffffffffc0202080 <etext+0x184>
ffffffffc0200246:	00002517          	auipc	a0,0x2
ffffffffc020024a:	e0250513          	addi	a0,a0,-510 # ffffffffc0202048 <etext+0x14c>
ffffffffc020024e:	e97ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
ffffffffc0200252:	00002617          	auipc	a2,0x2
ffffffffc0200256:	e3e60613          	addi	a2,a2,-450 # ffffffffc0202090 <etext+0x194>
ffffffffc020025a:	00002597          	auipc	a1,0x2
ffffffffc020025e:	e5658593          	addi	a1,a1,-426 # ffffffffc02020b0 <etext+0x1b4>
ffffffffc0200262:	00002517          	auipc	a0,0x2
ffffffffc0200266:	de650513          	addi	a0,a0,-538 # ffffffffc0202048 <etext+0x14c>
ffffffffc020026a:	e7bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    }
    return 0;
}
ffffffffc020026e:	60a2                	ld	ra,8(sp)
ffffffffc0200270:	4501                	li	a0,0
ffffffffc0200272:	0141                	addi	sp,sp,16
ffffffffc0200274:	8082                	ret

ffffffffc0200276 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200276:	1141                	addi	sp,sp,-16
ffffffffc0200278:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020027a:	ef3ff0ef          	jal	ra,ffffffffc020016c <print_kerninfo>
    return 0;
}
ffffffffc020027e:	60a2                	ld	ra,8(sp)
ffffffffc0200280:	4501                	li	a0,0
ffffffffc0200282:	0141                	addi	sp,sp,16
ffffffffc0200284:	8082                	ret

ffffffffc0200286 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
ffffffffc0200288:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020028a:	f71ff0ef          	jal	ra,ffffffffc02001fa <print_stackframe>
    return 0;
}
ffffffffc020028e:	60a2                	ld	ra,8(sp)
ffffffffc0200290:	4501                	li	a0,0
ffffffffc0200292:	0141                	addi	sp,sp,16
ffffffffc0200294:	8082                	ret

ffffffffc0200296 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200296:	7115                	addi	sp,sp,-224
ffffffffc0200298:	ed5e                	sd	s7,152(sp)
ffffffffc020029a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020029c:	00002517          	auipc	a0,0x2
ffffffffc02002a0:	e2450513          	addi	a0,a0,-476 # ffffffffc02020c0 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc02002a4:	ed86                	sd	ra,216(sp)
ffffffffc02002a6:	e9a2                	sd	s0,208(sp)
ffffffffc02002a8:	e5a6                	sd	s1,200(sp)
ffffffffc02002aa:	e1ca                	sd	s2,192(sp)
ffffffffc02002ac:	fd4e                	sd	s3,184(sp)
ffffffffc02002ae:	f952                	sd	s4,176(sp)
ffffffffc02002b0:	f556                	sd	s5,168(sp)
ffffffffc02002b2:	f15a                	sd	s6,160(sp)
ffffffffc02002b4:	e962                	sd	s8,144(sp)
ffffffffc02002b6:	e566                	sd	s9,136(sp)
ffffffffc02002b8:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ba:	e2bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002be:	00002517          	auipc	a0,0x2
ffffffffc02002c2:	e2a50513          	addi	a0,a0,-470 # ffffffffc02020e8 <etext+0x1ec>
ffffffffc02002c6:	e1fff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    if (tf != NULL) {
ffffffffc02002ca:	000b8563          	beqz	s7,ffffffffc02002d4 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002ce:	855e                	mv	a0,s7
ffffffffc02002d0:	756000ef          	jal	ra,ffffffffc0200a26 <print_trapframe>
ffffffffc02002d4:	00002c17          	auipc	s8,0x2
ffffffffc02002d8:	e84c0c13          	addi	s8,s8,-380 # ffffffffc0202158 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002dc:	00002917          	auipc	s2,0x2
ffffffffc02002e0:	e3490913          	addi	s2,s2,-460 # ffffffffc0202110 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	00002497          	auipc	s1,0x2
ffffffffc02002e8:	e3448493          	addi	s1,s1,-460 # ffffffffc0202118 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ec:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002ee:	00002b17          	auipc	s6,0x2
ffffffffc02002f2:	e32b0b13          	addi	s6,s6,-462 # ffffffffc0202120 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002f6:	00002a17          	auipc	s4,0x2
ffffffffc02002fa:	d4aa0a13          	addi	s4,s4,-694 # ffffffffc0202040 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fe:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200300:	854a                	mv	a0,s2
ffffffffc0200302:	23b010ef          	jal	ra,ffffffffc0201d3c <readline>
ffffffffc0200306:	842a                	mv	s0,a0
ffffffffc0200308:	dd65                	beqz	a0,ffffffffc0200300 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030e:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200310:	e1bd                	bnez	a1,ffffffffc0200376 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200312:	fe0c87e3          	beqz	s9,ffffffffc0200300 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200316:	6582                	ld	a1,0(sp)
ffffffffc0200318:	00002d17          	auipc	s10,0x2
ffffffffc020031c:	e40d0d13          	addi	s10,s10,-448 # ffffffffc0202158 <commands>
        argv[argc ++] = buf;
ffffffffc0200320:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200322:	4401                	li	s0,0
ffffffffc0200324:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200326:	36b010ef          	jal	ra,ffffffffc0201e90 <strcmp>
ffffffffc020032a:	c919                	beqz	a0,ffffffffc0200340 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	2405                	addiw	s0,s0,1
ffffffffc020032e:	0b540063          	beq	s0,s5,ffffffffc02003ce <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200332:	000d3503          	ld	a0,0(s10)
ffffffffc0200336:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200338:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020033a:	357010ef          	jal	ra,ffffffffc0201e90 <strcmp>
ffffffffc020033e:	f57d                	bnez	a0,ffffffffc020032c <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200340:	00141793          	slli	a5,s0,0x1
ffffffffc0200344:	97a2                	add	a5,a5,s0
ffffffffc0200346:	078e                	slli	a5,a5,0x3
ffffffffc0200348:	97e2                	add	a5,a5,s8
ffffffffc020034a:	6b9c                	ld	a5,16(a5)
ffffffffc020034c:	865e                	mv	a2,s7
ffffffffc020034e:	002c                	addi	a1,sp,8
ffffffffc0200350:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200354:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200356:	fa0555e3          	bgez	a0,ffffffffc0200300 <kmonitor+0x6a>
}
ffffffffc020035a:	60ee                	ld	ra,216(sp)
ffffffffc020035c:	644e                	ld	s0,208(sp)
ffffffffc020035e:	64ae                	ld	s1,200(sp)
ffffffffc0200360:	690e                	ld	s2,192(sp)
ffffffffc0200362:	79ea                	ld	s3,184(sp)
ffffffffc0200364:	7a4a                	ld	s4,176(sp)
ffffffffc0200366:	7aaa                	ld	s5,168(sp)
ffffffffc0200368:	7b0a                	ld	s6,160(sp)
ffffffffc020036a:	6bea                	ld	s7,152(sp)
ffffffffc020036c:	6c4a                	ld	s8,144(sp)
ffffffffc020036e:	6caa                	ld	s9,136(sp)
ffffffffc0200370:	6d0a                	ld	s10,128(sp)
ffffffffc0200372:	612d                	addi	sp,sp,224
ffffffffc0200374:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200376:	8526                	mv	a0,s1
ffffffffc0200378:	35d010ef          	jal	ra,ffffffffc0201ed4 <strchr>
ffffffffc020037c:	c901                	beqz	a0,ffffffffc020038c <kmonitor+0xf6>
ffffffffc020037e:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200382:	00040023          	sb	zero,0(s0)
ffffffffc0200386:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200388:	d5c9                	beqz	a1,ffffffffc0200312 <kmonitor+0x7c>
ffffffffc020038a:	b7f5                	j	ffffffffc0200376 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020038c:	00044783          	lbu	a5,0(s0)
ffffffffc0200390:	d3c9                	beqz	a5,ffffffffc0200312 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200392:	033c8963          	beq	s9,s3,ffffffffc02003c4 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200396:	003c9793          	slli	a5,s9,0x3
ffffffffc020039a:	0118                	addi	a4,sp,128
ffffffffc020039c:	97ba                	add	a5,a5,a4
ffffffffc020039e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a2:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a6:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a8:	e591                	bnez	a1,ffffffffc02003b4 <kmonitor+0x11e>
ffffffffc02003aa:	b7b5                	j	ffffffffc0200316 <kmonitor+0x80>
ffffffffc02003ac:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003b2:	d1a5                	beqz	a1,ffffffffc0200312 <kmonitor+0x7c>
ffffffffc02003b4:	8526                	mv	a0,s1
ffffffffc02003b6:	31f010ef          	jal	ra,ffffffffc0201ed4 <strchr>
ffffffffc02003ba:	d96d                	beqz	a0,ffffffffc02003ac <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003bc:	00044583          	lbu	a1,0(s0)
ffffffffc02003c0:	d9a9                	beqz	a1,ffffffffc0200312 <kmonitor+0x7c>
ffffffffc02003c2:	bf55                	j	ffffffffc0200376 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c4:	45c1                	li	a1,16
ffffffffc02003c6:	855a                	mv	a0,s6
ffffffffc02003c8:	d1dff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
ffffffffc02003cc:	b7e9                	j	ffffffffc0200396 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003ce:	6582                	ld	a1,0(sp)
ffffffffc02003d0:	00002517          	auipc	a0,0x2
ffffffffc02003d4:	d7050513          	addi	a0,a0,-656 # ffffffffc0202140 <etext+0x244>
ffffffffc02003d8:	d0dff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    return 0;
ffffffffc02003dc:	b715                	j	ffffffffc0200300 <kmonitor+0x6a>

ffffffffc02003de <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003de:	00006317          	auipc	t1,0x6
ffffffffc02003e2:	06230313          	addi	t1,t1,98 # ffffffffc0206440 <is_panic>
ffffffffc02003e6:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003ea:	715d                	addi	sp,sp,-80
ffffffffc02003ec:	ec06                	sd	ra,24(sp)
ffffffffc02003ee:	e822                	sd	s0,16(sp)
ffffffffc02003f0:	f436                	sd	a3,40(sp)
ffffffffc02003f2:	f83a                	sd	a4,48(sp)
ffffffffc02003f4:	fc3e                	sd	a5,56(sp)
ffffffffc02003f6:	e0c2                	sd	a6,64(sp)
ffffffffc02003f8:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003fa:	020e1a63          	bnez	t3,ffffffffc020042e <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003fe:	4785                	li	a5,1
ffffffffc0200400:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200404:	8432                	mv	s0,a2
ffffffffc0200406:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200408:	862e                	mv	a2,a1
ffffffffc020040a:	85aa                	mv	a1,a0
ffffffffc020040c:	00002517          	auipc	a0,0x2
ffffffffc0200410:	d9450513          	addi	a0,a0,-620 # ffffffffc02021a0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200414:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200416:	ccfff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020041a:	65a2                	ld	a1,8(sp)
ffffffffc020041c:	8522                	mv	a0,s0
ffffffffc020041e:	ca7ff0ef          	jal	ra,ffffffffc02000c4 <vcprintf>
    cprintf("\n");
ffffffffc0200422:	00002517          	auipc	a0,0x2
ffffffffc0200426:	bc650513          	addi	a0,a0,-1082 # ffffffffc0201fe8 <etext+0xec>
ffffffffc020042a:	cbbff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020042e:	412000ef          	jal	ra,ffffffffc0200840 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200432:	4501                	li	a0,0
ffffffffc0200434:	e63ff0ef          	jal	ra,ffffffffc0200296 <kmonitor>
    while (1) {
ffffffffc0200438:	bfed                	j	ffffffffc0200432 <__panic+0x54>

ffffffffc020043a <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020043a:	1141                	addi	sp,sp,-16
ffffffffc020043c:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020043e:	02000793          	li	a5,32
ffffffffc0200442:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200446:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020044a:	67e1                	lui	a5,0x18
ffffffffc020044c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200450:	953e                	add	a0,a0,a5
ffffffffc0200452:	1b9010ef          	jal	ra,ffffffffc0201e0a <sbi_set_timer>
}
ffffffffc0200456:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200458:	00006797          	auipc	a5,0x6
ffffffffc020045c:	fe07b823          	sd	zero,-16(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200460:	00002517          	auipc	a0,0x2
ffffffffc0200464:	d6050513          	addi	a0,a0,-672 # ffffffffc02021c0 <commands+0x68>
}
ffffffffc0200468:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020046a:	b9ad                	j	ffffffffc02000e4 <cprintf>

ffffffffc020046c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020046c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200470:	67e1                	lui	a5,0x18
ffffffffc0200472:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200476:	953e                	add	a0,a0,a5
ffffffffc0200478:	1930106f          	j	ffffffffc0201e0a <sbi_set_timer>

ffffffffc020047c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020047c:	8082                	ret

ffffffffc020047e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020047e:	0ff57513          	zext.b	a0,a0
ffffffffc0200482:	16f0106f          	j	ffffffffc0201df0 <sbi_console_putchar>

ffffffffc0200486 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200486:	19f0106f          	j	ffffffffc0201e24 <sbi_console_getchar>

ffffffffc020048a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020048a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020048c:	00002517          	auipc	a0,0x2
ffffffffc0200490:	d5450513          	addi	a0,a0,-684 # ffffffffc02021e0 <commands+0x88>
void dtb_init(void) {
ffffffffc0200494:	fc86                	sd	ra,120(sp)
ffffffffc0200496:	f8a2                	sd	s0,112(sp)
ffffffffc0200498:	e8d2                	sd	s4,80(sp)
ffffffffc020049a:	f4a6                	sd	s1,104(sp)
ffffffffc020049c:	f0ca                	sd	s2,96(sp)
ffffffffc020049e:	ecce                	sd	s3,88(sp)
ffffffffc02004a0:	e4d6                	sd	s5,72(sp)
ffffffffc02004a2:	e0da                	sd	s6,64(sp)
ffffffffc02004a4:	fc5e                	sd	s7,56(sp)
ffffffffc02004a6:	f862                	sd	s8,48(sp)
ffffffffc02004a8:	f466                	sd	s9,40(sp)
ffffffffc02004aa:	f06a                	sd	s10,32(sp)
ffffffffc02004ac:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004ae:	c37ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004b2:	00006597          	auipc	a1,0x6
ffffffffc02004b6:	b4e5b583          	ld	a1,-1202(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004ba:	00002517          	auipc	a0,0x2
ffffffffc02004be:	d3650513          	addi	a0,a0,-714 # ffffffffc02021f0 <commands+0x98>
ffffffffc02004c2:	c23ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004c6:	00006417          	auipc	s0,0x6
ffffffffc02004ca:	b4240413          	addi	s0,s0,-1214 # ffffffffc0206008 <boot_dtb>
ffffffffc02004ce:	600c                	ld	a1,0(s0)
ffffffffc02004d0:	00002517          	auipc	a0,0x2
ffffffffc02004d4:	d3050513          	addi	a0,a0,-720 # ffffffffc0202200 <commands+0xa8>
ffffffffc02004d8:	c0dff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004dc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004e0:	00002517          	auipc	a0,0x2
ffffffffc02004e4:	d3850513          	addi	a0,a0,-712 # ffffffffc0202218 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004e8:	120a0463          	beqz	s4,ffffffffc0200610 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004ec:	57f5                	li	a5,-3
ffffffffc02004ee:	07fa                	slli	a5,a5,0x1e
ffffffffc02004f0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004f4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fa:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200500:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200508:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050c:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200510:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	8ec9                	or	a3,a3,a0
ffffffffc0200514:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200518:	1b7d                	addi	s6,s6,-1
ffffffffc020051a:	0167f7b3          	and	a5,a5,s6
ffffffffc020051e:	8dd5                	or	a1,a1,a3
ffffffffc0200520:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200522:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200528:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc020052c:	10f59163          	bne	a1,a5,ffffffffc020062e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200530:	471c                	lw	a5,8(a4)
ffffffffc0200532:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200534:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020053a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020053e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200542:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200546:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200552:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200556:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020055a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200560:	01146433          	or	s0,s0,a7
ffffffffc0200564:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200568:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020056c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200572:	8c49                	or	s0,s0,a0
ffffffffc0200574:	0166f6b3          	and	a3,a3,s6
ffffffffc0200578:	00ca6a33          	or	s4,s4,a2
ffffffffc020057c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200580:	8c55                	or	s0,s0,a3
ffffffffc0200582:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200586:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200588:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020058a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020058c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200590:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200592:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200594:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200598:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020059a:	00002917          	auipc	s2,0x2
ffffffffc020059e:	cce90913          	addi	s2,s2,-818 # ffffffffc0202268 <commands+0x110>
ffffffffc02005a2:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005a4:	4d91                	li	s11,4
ffffffffc02005a6:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005a8:	00002497          	auipc	s1,0x2
ffffffffc02005ac:	cb848493          	addi	s1,s1,-840 # ffffffffc0202260 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005b0:	000a2703          	lw	a4,0(s4)
ffffffffc02005b4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005bc:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005cc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ce:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005d6:	8fd5                	or	a5,a5,a3
ffffffffc02005d8:	00eb7733          	and	a4,s6,a4
ffffffffc02005dc:	8fd9                	or	a5,a5,a4
ffffffffc02005de:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005e0:	09778c63          	beq	a5,s7,ffffffffc0200678 <dtb_init+0x1ee>
ffffffffc02005e4:	00fbea63          	bltu	s7,a5,ffffffffc02005f8 <dtb_init+0x16e>
ffffffffc02005e8:	07a78663          	beq	a5,s10,ffffffffc0200654 <dtb_init+0x1ca>
ffffffffc02005ec:	4709                	li	a4,2
ffffffffc02005ee:	00e79763          	bne	a5,a4,ffffffffc02005fc <dtb_init+0x172>
ffffffffc02005f2:	4c81                	li	s9,0
ffffffffc02005f4:	8a56                	mv	s4,s5
ffffffffc02005f6:	bf6d                	j	ffffffffc02005b0 <dtb_init+0x126>
ffffffffc02005f8:	ffb78ee3          	beq	a5,s11,ffffffffc02005f4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005fc:	00002517          	auipc	a0,0x2
ffffffffc0200600:	ce450513          	addi	a0,a0,-796 # ffffffffc02022e0 <commands+0x188>
ffffffffc0200604:	ae1ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	d1050513          	addi	a0,a0,-752 # ffffffffc0202318 <commands+0x1c0>
}
ffffffffc0200610:	7446                	ld	s0,112(sp)
ffffffffc0200612:	70e6                	ld	ra,120(sp)
ffffffffc0200614:	74a6                	ld	s1,104(sp)
ffffffffc0200616:	7906                	ld	s2,96(sp)
ffffffffc0200618:	69e6                	ld	s3,88(sp)
ffffffffc020061a:	6a46                	ld	s4,80(sp)
ffffffffc020061c:	6aa6                	ld	s5,72(sp)
ffffffffc020061e:	6b06                	ld	s6,64(sp)
ffffffffc0200620:	7be2                	ld	s7,56(sp)
ffffffffc0200622:	7c42                	ld	s8,48(sp)
ffffffffc0200624:	7ca2                	ld	s9,40(sp)
ffffffffc0200626:	7d02                	ld	s10,32(sp)
ffffffffc0200628:	6de2                	ld	s11,24(sp)
ffffffffc020062a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020062c:	bc65                	j	ffffffffc02000e4 <cprintf>
}
ffffffffc020062e:	7446                	ld	s0,112(sp)
ffffffffc0200630:	70e6                	ld	ra,120(sp)
ffffffffc0200632:	74a6                	ld	s1,104(sp)
ffffffffc0200634:	7906                	ld	s2,96(sp)
ffffffffc0200636:	69e6                	ld	s3,88(sp)
ffffffffc0200638:	6a46                	ld	s4,80(sp)
ffffffffc020063a:	6aa6                	ld	s5,72(sp)
ffffffffc020063c:	6b06                	ld	s6,64(sp)
ffffffffc020063e:	7be2                	ld	s7,56(sp)
ffffffffc0200640:	7c42                	ld	s8,48(sp)
ffffffffc0200642:	7ca2                	ld	s9,40(sp)
ffffffffc0200644:	7d02                	ld	s10,32(sp)
ffffffffc0200646:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200648:	00002517          	auipc	a0,0x2
ffffffffc020064c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202238 <commands+0xe0>
}
ffffffffc0200650:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200652:	bc49                	j	ffffffffc02000e4 <cprintf>
                int name_len = strlen(name);
ffffffffc0200654:	8556                	mv	a0,s5
ffffffffc0200656:	005010ef          	jal	ra,ffffffffc0201e5a <strlen>
ffffffffc020065a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020065c:	4619                	li	a2,6
ffffffffc020065e:	85a6                	mv	a1,s1
ffffffffc0200660:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200662:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200664:	04b010ef          	jal	ra,ffffffffc0201eae <strncmp>
ffffffffc0200668:	e111                	bnez	a0,ffffffffc020066c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020066a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020066c:	0a91                	addi	s5,s5,4
ffffffffc020066e:	9ad2                	add	s5,s5,s4
ffffffffc0200670:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200674:	8a56                	mv	s4,s5
ffffffffc0200676:	bf2d                	j	ffffffffc02005b0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200678:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020067c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200680:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200684:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200688:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200690:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200694:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200698:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069c:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006a0:	00eaeab3          	or	s5,s5,a4
ffffffffc02006a4:	00fb77b3          	and	a5,s6,a5
ffffffffc02006a8:	00faeab3          	or	s5,s5,a5
ffffffffc02006ac:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ae:	000c9c63          	bnez	s9,ffffffffc02006c6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006b2:	1a82                	slli	s5,s5,0x20
ffffffffc02006b4:	00368793          	addi	a5,a3,3
ffffffffc02006b8:	020ada93          	srli	s5,s5,0x20
ffffffffc02006bc:	9abe                	add	s5,s5,a5
ffffffffc02006be:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006c2:	8a56                	mv	s4,s5
ffffffffc02006c4:	b5f5                	j	ffffffffc02005b0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ca:	85ca                	mv	a1,s2
ffffffffc02006cc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ce:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006da:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006de:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006e2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ec:	8d59                	or	a0,a0,a4
ffffffffc02006ee:	00fb77b3          	and	a5,s6,a5
ffffffffc02006f2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006f4:	1502                	slli	a0,a0,0x20
ffffffffc02006f6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	9522                	add	a0,a0,s0
ffffffffc02006fa:	796010ef          	jal	ra,ffffffffc0201e90 <strcmp>
ffffffffc02006fe:	66a2                	ld	a3,8(sp)
ffffffffc0200700:	f94d                	bnez	a0,ffffffffc02006b2 <dtb_init+0x228>
ffffffffc0200702:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006b2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200706:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020070a:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020070e:	00002517          	auipc	a0,0x2
ffffffffc0200712:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202270 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200716:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020071e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200726:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0187d693          	srli	a3,a5,0x18
ffffffffc0200736:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020073a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020073e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200742:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200746:	010f6f33          	or	t5,t5,a6
ffffffffc020074a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020074e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200752:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200756:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075a:	0186f6b3          	and	a3,a3,s8
ffffffffc020075e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200762:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	0107581b          	srliw	a6,a4,0x10
ffffffffc020076a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076e:	8361                	srli	a4,a4,0x18
ffffffffc0200770:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200774:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200778:	01e6e6b3          	or	a3,a3,t5
ffffffffc020077c:	00cb7633          	and	a2,s6,a2
ffffffffc0200780:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200784:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200788:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200790:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200794:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200798:	0088989b          	slliw	a7,a7,0x8
ffffffffc020079c:	011b78b3          	and	a7,s6,a7
ffffffffc02007a0:	005eeeb3          	or	t4,t4,t0
ffffffffc02007a4:	00c6e733          	or	a4,a3,a2
ffffffffc02007a8:	006c6c33          	or	s8,s8,t1
ffffffffc02007ac:	010b76b3          	and	a3,s6,a6
ffffffffc02007b0:	00bb7b33          	and	s6,s6,a1
ffffffffc02007b4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007b8:	016c6b33          	or	s6,s8,s6
ffffffffc02007bc:	01146433          	or	s0,s0,a7
ffffffffc02007c0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007c2:	1702                	slli	a4,a4,0x20
ffffffffc02007c4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ca:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007cc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007d0:	0167eb33          	or	s6,a5,s6
ffffffffc02007d4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007d6:	90fff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007da:	85a2                	mv	a1,s0
ffffffffc02007dc:	00002517          	auipc	a0,0x2
ffffffffc02007e0:	ab450513          	addi	a0,a0,-1356 # ffffffffc0202290 <commands+0x138>
ffffffffc02007e4:	901ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007e8:	014b5613          	srli	a2,s6,0x14
ffffffffc02007ec:	85da                	mv	a1,s6
ffffffffc02007ee:	00002517          	auipc	a0,0x2
ffffffffc02007f2:	aba50513          	addi	a0,a0,-1350 # ffffffffc02022a8 <commands+0x150>
ffffffffc02007f6:	8efff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007fa:	008b05b3          	add	a1,s6,s0
ffffffffc02007fe:	15fd                	addi	a1,a1,-1
ffffffffc0200800:	00002517          	auipc	a0,0x2
ffffffffc0200804:	ac850513          	addi	a0,a0,-1336 # ffffffffc02022c8 <commands+0x170>
ffffffffc0200808:	8ddff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020080c:	00002517          	auipc	a0,0x2
ffffffffc0200810:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0202318 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200814:	00006797          	auipc	a5,0x6
ffffffffc0200818:	c287be23          	sd	s0,-964(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc020081c:	00006797          	auipc	a5,0x6
ffffffffc0200820:	c367be23          	sd	s6,-964(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200824:	b3f5                	j	ffffffffc0200610 <dtb_init+0x186>

ffffffffc0200826 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200826:	00006517          	auipc	a0,0x6
ffffffffc020082a:	c2a53503          	ld	a0,-982(a0) # ffffffffc0206450 <memory_base>
ffffffffc020082e:	8082                	ret

ffffffffc0200830 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200830:	00006517          	auipc	a0,0x6
ffffffffc0200834:	c2853503          	ld	a0,-984(a0) # ffffffffc0206458 <memory_size>
ffffffffc0200838:	8082                	ret

ffffffffc020083a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020083a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020083e:	8082                	ret

ffffffffc0200840 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200840:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200844:	8082                	ret

ffffffffc0200846 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200846:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020084a:	00000797          	auipc	a5,0x0
ffffffffc020084e:	39a78793          	addi	a5,a5,922 # ffffffffc0200be4 <__alltraps>
ffffffffc0200852:	10579073          	csrw	stvec,a5
}
ffffffffc0200856:	8082                	ret

ffffffffc0200858 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200858:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020085a:	1141                	addi	sp,sp,-16
ffffffffc020085c:	e022                	sd	s0,0(sp)
ffffffffc020085e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200860:	00002517          	auipc	a0,0x2
ffffffffc0200864:	ad050513          	addi	a0,a0,-1328 # ffffffffc0202330 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200868:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020086a:	87bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020086e:	640c                	ld	a1,8(s0)
ffffffffc0200870:	00002517          	auipc	a0,0x2
ffffffffc0200874:	ad850513          	addi	a0,a0,-1320 # ffffffffc0202348 <commands+0x1f0>
ffffffffc0200878:	86dff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020087c:	680c                	ld	a1,16(s0)
ffffffffc020087e:	00002517          	auipc	a0,0x2
ffffffffc0200882:	ae250513          	addi	a0,a0,-1310 # ffffffffc0202360 <commands+0x208>
ffffffffc0200886:	85fff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020088a:	6c0c                	ld	a1,24(s0)
ffffffffc020088c:	00002517          	auipc	a0,0x2
ffffffffc0200890:	aec50513          	addi	a0,a0,-1300 # ffffffffc0202378 <commands+0x220>
ffffffffc0200894:	851ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200898:	700c                	ld	a1,32(s0)
ffffffffc020089a:	00002517          	auipc	a0,0x2
ffffffffc020089e:	af650513          	addi	a0,a0,-1290 # ffffffffc0202390 <commands+0x238>
ffffffffc02008a2:	843ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008a6:	740c                	ld	a1,40(s0)
ffffffffc02008a8:	00002517          	auipc	a0,0x2
ffffffffc02008ac:	b0050513          	addi	a0,a0,-1280 # ffffffffc02023a8 <commands+0x250>
ffffffffc02008b0:	835ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008b4:	780c                	ld	a1,48(s0)
ffffffffc02008b6:	00002517          	auipc	a0,0x2
ffffffffc02008ba:	b0a50513          	addi	a0,a0,-1270 # ffffffffc02023c0 <commands+0x268>
ffffffffc02008be:	827ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008c2:	7c0c                	ld	a1,56(s0)
ffffffffc02008c4:	00002517          	auipc	a0,0x2
ffffffffc02008c8:	b1450513          	addi	a0,a0,-1260 # ffffffffc02023d8 <commands+0x280>
ffffffffc02008cc:	819ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008d0:	602c                	ld	a1,64(s0)
ffffffffc02008d2:	00002517          	auipc	a0,0x2
ffffffffc02008d6:	b1e50513          	addi	a0,a0,-1250 # ffffffffc02023f0 <commands+0x298>
ffffffffc02008da:	80bff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008de:	642c                	ld	a1,72(s0)
ffffffffc02008e0:	00002517          	auipc	a0,0x2
ffffffffc02008e4:	b2850513          	addi	a0,a0,-1240 # ffffffffc0202408 <commands+0x2b0>
ffffffffc02008e8:	ffcff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008ec:	682c                	ld	a1,80(s0)
ffffffffc02008ee:	00002517          	auipc	a0,0x2
ffffffffc02008f2:	b3250513          	addi	a0,a0,-1230 # ffffffffc0202420 <commands+0x2c8>
ffffffffc02008f6:	feeff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008fa:	6c2c                	ld	a1,88(s0)
ffffffffc02008fc:	00002517          	auipc	a0,0x2
ffffffffc0200900:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0202438 <commands+0x2e0>
ffffffffc0200904:	fe0ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200908:	702c                	ld	a1,96(s0)
ffffffffc020090a:	00002517          	auipc	a0,0x2
ffffffffc020090e:	b4650513          	addi	a0,a0,-1210 # ffffffffc0202450 <commands+0x2f8>
ffffffffc0200912:	fd2ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200916:	742c                	ld	a1,104(s0)
ffffffffc0200918:	00002517          	auipc	a0,0x2
ffffffffc020091c:	b5050513          	addi	a0,a0,-1200 # ffffffffc0202468 <commands+0x310>
ffffffffc0200920:	fc4ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200924:	782c                	ld	a1,112(s0)
ffffffffc0200926:	00002517          	auipc	a0,0x2
ffffffffc020092a:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0202480 <commands+0x328>
ffffffffc020092e:	fb6ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200932:	7c2c                	ld	a1,120(s0)
ffffffffc0200934:	00002517          	auipc	a0,0x2
ffffffffc0200938:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202498 <commands+0x340>
ffffffffc020093c:	fa8ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200940:	604c                	ld	a1,128(s0)
ffffffffc0200942:	00002517          	auipc	a0,0x2
ffffffffc0200946:	b6e50513          	addi	a0,a0,-1170 # ffffffffc02024b0 <commands+0x358>
ffffffffc020094a:	f9aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020094e:	644c                	ld	a1,136(s0)
ffffffffc0200950:	00002517          	auipc	a0,0x2
ffffffffc0200954:	b7850513          	addi	a0,a0,-1160 # ffffffffc02024c8 <commands+0x370>
ffffffffc0200958:	f8cff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020095c:	684c                	ld	a1,144(s0)
ffffffffc020095e:	00002517          	auipc	a0,0x2
ffffffffc0200962:	b8250513          	addi	a0,a0,-1150 # ffffffffc02024e0 <commands+0x388>
ffffffffc0200966:	f7eff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020096a:	6c4c                	ld	a1,152(s0)
ffffffffc020096c:	00002517          	auipc	a0,0x2
ffffffffc0200970:	b8c50513          	addi	a0,a0,-1140 # ffffffffc02024f8 <commands+0x3a0>
ffffffffc0200974:	f70ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200978:	704c                	ld	a1,160(s0)
ffffffffc020097a:	00002517          	auipc	a0,0x2
ffffffffc020097e:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202510 <commands+0x3b8>
ffffffffc0200982:	f62ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200986:	744c                	ld	a1,168(s0)
ffffffffc0200988:	00002517          	auipc	a0,0x2
ffffffffc020098c:	ba050513          	addi	a0,a0,-1120 # ffffffffc0202528 <commands+0x3d0>
ffffffffc0200990:	f54ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200994:	784c                	ld	a1,176(s0)
ffffffffc0200996:	00002517          	auipc	a0,0x2
ffffffffc020099a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202540 <commands+0x3e8>
ffffffffc020099e:	f46ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009a2:	7c4c                	ld	a1,184(s0)
ffffffffc02009a4:	00002517          	auipc	a0,0x2
ffffffffc02009a8:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202558 <commands+0x400>
ffffffffc02009ac:	f38ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009b0:	606c                	ld	a1,192(s0)
ffffffffc02009b2:	00002517          	auipc	a0,0x2
ffffffffc02009b6:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202570 <commands+0x418>
ffffffffc02009ba:	f2aff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009be:	646c                	ld	a1,200(s0)
ffffffffc02009c0:	00002517          	auipc	a0,0x2
ffffffffc02009c4:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202588 <commands+0x430>
ffffffffc02009c8:	f1cff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009cc:	686c                	ld	a1,208(s0)
ffffffffc02009ce:	00002517          	auipc	a0,0x2
ffffffffc02009d2:	bd250513          	addi	a0,a0,-1070 # ffffffffc02025a0 <commands+0x448>
ffffffffc02009d6:	f0eff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009da:	6c6c                	ld	a1,216(s0)
ffffffffc02009dc:	00002517          	auipc	a0,0x2
ffffffffc02009e0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc02025b8 <commands+0x460>
ffffffffc02009e4:	f00ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009e8:	706c                	ld	a1,224(s0)
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	be650513          	addi	a0,a0,-1050 # ffffffffc02025d0 <commands+0x478>
ffffffffc02009f2:	ef2ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009f6:	746c                	ld	a1,232(s0)
ffffffffc02009f8:	00002517          	auipc	a0,0x2
ffffffffc02009fc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02025e8 <commands+0x490>
ffffffffc0200a00:	ee4ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a04:	786c                	ld	a1,240(s0)
ffffffffc0200a06:	00002517          	auipc	a0,0x2
ffffffffc0200a0a:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202600 <commands+0x4a8>
ffffffffc0200a0e:	ed6ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a12:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a14:	6402                	ld	s0,0(sp)
ffffffffc0200a16:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0202618 <commands+0x4c0>
}
ffffffffc0200a20:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a22:	ec2ff06f          	j	ffffffffc02000e4 <cprintf>

ffffffffc0200a26 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a26:	1141                	addi	sp,sp,-16
ffffffffc0200a28:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2a:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2c:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2e:	00002517          	auipc	a0,0x2
ffffffffc0200a32:	c0250513          	addi	a0,a0,-1022 # ffffffffc0202630 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a36:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a38:	eacff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a3c:	8522                	mv	a0,s0
ffffffffc0200a3e:	e1bff0ef          	jal	ra,ffffffffc0200858 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a42:	10043583          	ld	a1,256(s0)
ffffffffc0200a46:	00002517          	auipc	a0,0x2
ffffffffc0200a4a:	c0250513          	addi	a0,a0,-1022 # ffffffffc0202648 <commands+0x4f0>
ffffffffc0200a4e:	e96ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a52:	10843583          	ld	a1,264(s0)
ffffffffc0200a56:	00002517          	auipc	a0,0x2
ffffffffc0200a5a:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202660 <commands+0x508>
ffffffffc0200a5e:	e86ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a62:	11043583          	ld	a1,272(s0)
ffffffffc0200a66:	00002517          	auipc	a0,0x2
ffffffffc0200a6a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0202678 <commands+0x520>
ffffffffc0200a6e:	e76ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a72:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a76:	6402                	ld	s0,0(sp)
ffffffffc0200a78:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a7a:	00002517          	auipc	a0,0x2
ffffffffc0200a7e:	c1650513          	addi	a0,a0,-1002 # ffffffffc0202690 <commands+0x538>
}
ffffffffc0200a82:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a84:	e60ff06f          	j	ffffffffc02000e4 <cprintf>

ffffffffc0200a88 <interrupt_handler>:
int num=0;
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a88:	11853783          	ld	a5,280(a0)
ffffffffc0200a8c:	472d                	li	a4,11
ffffffffc0200a8e:	0786                	slli	a5,a5,0x1
ffffffffc0200a90:	8385                	srli	a5,a5,0x1
ffffffffc0200a92:	08f76963          	bltu	a4,a5,ffffffffc0200b24 <interrupt_handler+0x9c>
ffffffffc0200a96:	00002717          	auipc	a4,0x2
ffffffffc0200a9a:	cda70713          	addi	a4,a4,-806 # ffffffffc0202770 <commands+0x618>
ffffffffc0200a9e:	078a                	slli	a5,a5,0x2
ffffffffc0200aa0:	97ba                	add	a5,a5,a4
ffffffffc0200aa2:	439c                	lw	a5,0(a5)
ffffffffc0200aa4:	97ba                	add	a5,a5,a4
ffffffffc0200aa6:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200aa8:	00002517          	auipc	a0,0x2
ffffffffc0200aac:	c6050513          	addi	a0,a0,-928 # ffffffffc0202708 <commands+0x5b0>
ffffffffc0200ab0:	e34ff06f          	j	ffffffffc02000e4 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200ab4:	00002517          	auipc	a0,0x2
ffffffffc0200ab8:	c3450513          	addi	a0,a0,-972 # ffffffffc02026e8 <commands+0x590>
ffffffffc0200abc:	e28ff06f          	j	ffffffffc02000e4 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ac0:	00002517          	auipc	a0,0x2
ffffffffc0200ac4:	be850513          	addi	a0,a0,-1048 # ffffffffc02026a8 <commands+0x550>
ffffffffc0200ac8:	e1cff06f          	j	ffffffffc02000e4 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200acc:	00002517          	auipc	a0,0x2
ffffffffc0200ad0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0202728 <commands+0x5d0>
ffffffffc0200ad4:	e10ff06f          	j	ffffffffc02000e4 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200ad8:	1141                	addi	sp,sp,-16
ffffffffc0200ada:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200adc:	991ff0ef          	jal	ra,ffffffffc020046c <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200ae0:	00006697          	auipc	a3,0x6
ffffffffc0200ae4:	96868693          	addi	a3,a3,-1688 # ffffffffc0206448 <ticks>
ffffffffc0200ae8:	629c                	ld	a5,0(a3)
ffffffffc0200aea:	06400713          	li	a4,100
ffffffffc0200aee:	0785                	addi	a5,a5,1
ffffffffc0200af0:	02e7f733          	remu	a4,a5,a4
ffffffffc0200af4:	e29c                	sd	a5,0(a3)
ffffffffc0200af6:	cb05                	beqz	a4,ffffffffc0200b26 <interrupt_handler+0x9e>
                print_ticks();
                num++;
            }
            if(num==10){sbi_shutdown();}
ffffffffc0200af8:	00006717          	auipc	a4,0x6
ffffffffc0200afc:	96872703          	lw	a4,-1688(a4) # ffffffffc0206460 <num>
ffffffffc0200b00:	47a9                	li	a5,10
ffffffffc0200b02:	04f70363          	beq	a4,a5,ffffffffc0200b48 <interrupt_handler+0xc0>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b06:	60a2                	ld	ra,8(sp)
ffffffffc0200b08:	0141                	addi	sp,sp,16
ffffffffc0200b0a:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b0c:	00002517          	auipc	a0,0x2
ffffffffc0200b10:	c4450513          	addi	a0,a0,-956 # ffffffffc0202750 <commands+0x5f8>
ffffffffc0200b14:	dd0ff06f          	j	ffffffffc02000e4 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b18:	00002517          	auipc	a0,0x2
ffffffffc0200b1c:	bb050513          	addi	a0,a0,-1104 # ffffffffc02026c8 <commands+0x570>
ffffffffc0200b20:	dc4ff06f          	j	ffffffffc02000e4 <cprintf>
            print_trapframe(tf);
ffffffffc0200b24:	b709                	j	ffffffffc0200a26 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b26:	06400593          	li	a1,100
ffffffffc0200b2a:	00002517          	auipc	a0,0x2
ffffffffc0200b2e:	c1650513          	addi	a0,a0,-1002 # ffffffffc0202740 <commands+0x5e8>
ffffffffc0200b32:	db2ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
                num++;
ffffffffc0200b36:	00006697          	auipc	a3,0x6
ffffffffc0200b3a:	92a68693          	addi	a3,a3,-1750 # ffffffffc0206460 <num>
ffffffffc0200b3e:	429c                	lw	a5,0(a3)
ffffffffc0200b40:	0017871b          	addiw	a4,a5,1
ffffffffc0200b44:	c298                	sw	a4,0(a3)
ffffffffc0200b46:	bf6d                	j	ffffffffc0200b00 <interrupt_handler+0x78>
}
ffffffffc0200b48:	60a2                	ld	ra,8(sp)
ffffffffc0200b4a:	0141                	addi	sp,sp,16
            if(num==10){sbi_shutdown();}
ffffffffc0200b4c:	2f40106f          	j	ffffffffc0201e40 <sbi_shutdown>

ffffffffc0200b50 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b50:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b54:	1141                	addi	sp,sp,-16
ffffffffc0200b56:	e022                	sd	s0,0(sp)
ffffffffc0200b58:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b5a:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b5c:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b5e:	04e78663          	beq	a5,a4,ffffffffc0200baa <exception_handler+0x5a>
ffffffffc0200b62:	02f76c63          	bltu	a4,a5,ffffffffc0200b9a <exception_handler+0x4a>
ffffffffc0200b66:	4709                	li	a4,2
ffffffffc0200b68:	02e79563          	bne	a5,a4,ffffffffc0200b92 <exception_handler+0x42>
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            // (1) 输出指令异常类型
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b6c:	00002517          	auipc	a0,0x2
ffffffffc0200b70:	c3450513          	addi	a0,a0,-972 # ffffffffc02027a0 <commands+0x648>
ffffffffc0200b74:	d70ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
            
            // (2) 输出异常指令地址
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b78:	10843583          	ld	a1,264(s0)
ffffffffc0200b7c:	00002517          	auipc	a0,0x2
ffffffffc0200b80:	c4c50513          	addi	a0,a0,-948 # ffffffffc02027c8 <commands+0x670>
ffffffffc0200b84:	d60ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
            
            // (3) 更新 tf->epc寄存器，跳过异常指令（RISC-V指令长度为4字节）
            tf->epc += 4;
ffffffffc0200b88:	10843783          	ld	a5,264(s0)
ffffffffc0200b8c:	0791                	addi	a5,a5,4
ffffffffc0200b8e:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b92:	60a2                	ld	ra,8(sp)
ffffffffc0200b94:	6402                	ld	s0,0(sp)
ffffffffc0200b96:	0141                	addi	sp,sp,16
ffffffffc0200b98:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b9a:	17f1                	addi	a5,a5,-4
ffffffffc0200b9c:	471d                	li	a4,7
ffffffffc0200b9e:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b92 <exception_handler+0x42>
}
ffffffffc0200ba2:	6402                	ld	s0,0(sp)
ffffffffc0200ba4:	60a2                	ld	ra,8(sp)
ffffffffc0200ba6:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200ba8:	bdbd                	j	ffffffffc0200a26 <print_trapframe>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200baa:	00002517          	auipc	a0,0x2
ffffffffc0200bae:	c4650513          	addi	a0,a0,-954 # ffffffffc02027f0 <commands+0x698>
ffffffffc0200bb2:	d32ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200bb6:	10843583          	ld	a1,264(s0)
ffffffffc0200bba:	00002517          	auipc	a0,0x2
ffffffffc0200bbe:	c5650513          	addi	a0,a0,-938 # ffffffffc0202810 <commands+0x6b8>
ffffffffc0200bc2:	d22ff0ef          	jal	ra,ffffffffc02000e4 <cprintf>
            tf->epc += 4;
ffffffffc0200bc6:	10843783          	ld	a5,264(s0)
}
ffffffffc0200bca:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
ffffffffc0200bcc:	0791                	addi	a5,a5,4
ffffffffc0200bce:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200bd2:	6402                	ld	s0,0(sp)
ffffffffc0200bd4:	0141                	addi	sp,sp,16
ffffffffc0200bd6:	8082                	ret

ffffffffc0200bd8 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bd8:	11853783          	ld	a5,280(a0)
ffffffffc0200bdc:	0007c363          	bltz	a5,ffffffffc0200be2 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200be0:	bf85                	j	ffffffffc0200b50 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200be2:	b55d                	j	ffffffffc0200a88 <interrupt_handler>

ffffffffc0200be4 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200be4:	14011073          	csrw	sscratch,sp
ffffffffc0200be8:	712d                	addi	sp,sp,-288
ffffffffc0200bea:	e002                	sd	zero,0(sp)
ffffffffc0200bec:	e406                	sd	ra,8(sp)
ffffffffc0200bee:	ec0e                	sd	gp,24(sp)
ffffffffc0200bf0:	f012                	sd	tp,32(sp)
ffffffffc0200bf2:	f416                	sd	t0,40(sp)
ffffffffc0200bf4:	f81a                	sd	t1,48(sp)
ffffffffc0200bf6:	fc1e                	sd	t2,56(sp)
ffffffffc0200bf8:	e0a2                	sd	s0,64(sp)
ffffffffc0200bfa:	e4a6                	sd	s1,72(sp)
ffffffffc0200bfc:	e8aa                	sd	a0,80(sp)
ffffffffc0200bfe:	ecae                	sd	a1,88(sp)
ffffffffc0200c00:	f0b2                	sd	a2,96(sp)
ffffffffc0200c02:	f4b6                	sd	a3,104(sp)
ffffffffc0200c04:	f8ba                	sd	a4,112(sp)
ffffffffc0200c06:	fcbe                	sd	a5,120(sp)
ffffffffc0200c08:	e142                	sd	a6,128(sp)
ffffffffc0200c0a:	e546                	sd	a7,136(sp)
ffffffffc0200c0c:	e94a                	sd	s2,144(sp)
ffffffffc0200c0e:	ed4e                	sd	s3,152(sp)
ffffffffc0200c10:	f152                	sd	s4,160(sp)
ffffffffc0200c12:	f556                	sd	s5,168(sp)
ffffffffc0200c14:	f95a                	sd	s6,176(sp)
ffffffffc0200c16:	fd5e                	sd	s7,184(sp)
ffffffffc0200c18:	e1e2                	sd	s8,192(sp)
ffffffffc0200c1a:	e5e6                	sd	s9,200(sp)
ffffffffc0200c1c:	e9ea                	sd	s10,208(sp)
ffffffffc0200c1e:	edee                	sd	s11,216(sp)
ffffffffc0200c20:	f1f2                	sd	t3,224(sp)
ffffffffc0200c22:	f5f6                	sd	t4,232(sp)
ffffffffc0200c24:	f9fa                	sd	t5,240(sp)
ffffffffc0200c26:	fdfe                	sd	t6,248(sp)
ffffffffc0200c28:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c2c:	100024f3          	csrr	s1,sstatus
ffffffffc0200c30:	14102973          	csrr	s2,sepc
ffffffffc0200c34:	143029f3          	csrr	s3,stval
ffffffffc0200c38:	14202a73          	csrr	s4,scause
ffffffffc0200c3c:	e822                	sd	s0,16(sp)
ffffffffc0200c3e:	e226                	sd	s1,256(sp)
ffffffffc0200c40:	e64a                	sd	s2,264(sp)
ffffffffc0200c42:	ea4e                	sd	s3,272(sp)
ffffffffc0200c44:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c46:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c48:	f91ff0ef          	jal	ra,ffffffffc0200bd8 <trap>

ffffffffc0200c4c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c4c:	6492                	ld	s1,256(sp)
ffffffffc0200c4e:	6932                	ld	s2,264(sp)
ffffffffc0200c50:	10049073          	csrw	sstatus,s1
ffffffffc0200c54:	14191073          	csrw	sepc,s2
ffffffffc0200c58:	60a2                	ld	ra,8(sp)
ffffffffc0200c5a:	61e2                	ld	gp,24(sp)
ffffffffc0200c5c:	7202                	ld	tp,32(sp)
ffffffffc0200c5e:	72a2                	ld	t0,40(sp)
ffffffffc0200c60:	7342                	ld	t1,48(sp)
ffffffffc0200c62:	73e2                	ld	t2,56(sp)
ffffffffc0200c64:	6406                	ld	s0,64(sp)
ffffffffc0200c66:	64a6                	ld	s1,72(sp)
ffffffffc0200c68:	6546                	ld	a0,80(sp)
ffffffffc0200c6a:	65e6                	ld	a1,88(sp)
ffffffffc0200c6c:	7606                	ld	a2,96(sp)
ffffffffc0200c6e:	76a6                	ld	a3,104(sp)
ffffffffc0200c70:	7746                	ld	a4,112(sp)
ffffffffc0200c72:	77e6                	ld	a5,120(sp)
ffffffffc0200c74:	680a                	ld	a6,128(sp)
ffffffffc0200c76:	68aa                	ld	a7,136(sp)
ffffffffc0200c78:	694a                	ld	s2,144(sp)
ffffffffc0200c7a:	69ea                	ld	s3,152(sp)
ffffffffc0200c7c:	7a0a                	ld	s4,160(sp)
ffffffffc0200c7e:	7aaa                	ld	s5,168(sp)
ffffffffc0200c80:	7b4a                	ld	s6,176(sp)
ffffffffc0200c82:	7bea                	ld	s7,184(sp)
ffffffffc0200c84:	6c0e                	ld	s8,192(sp)
ffffffffc0200c86:	6cae                	ld	s9,200(sp)
ffffffffc0200c88:	6d4e                	ld	s10,208(sp)
ffffffffc0200c8a:	6dee                	ld	s11,216(sp)
ffffffffc0200c8c:	7e0e                	ld	t3,224(sp)
ffffffffc0200c8e:	7eae                	ld	t4,232(sp)
ffffffffc0200c90:	7f4e                	ld	t5,240(sp)
ffffffffc0200c92:	7fee                	ld	t6,248(sp)
ffffffffc0200c94:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c96:	10200073          	sret

ffffffffc0200c9a <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c9a:	00005797          	auipc	a5,0x5
ffffffffc0200c9e:	38e78793          	addi	a5,a5,910 # ffffffffc0206028 <free_area>
ffffffffc0200ca2:	e79c                	sd	a5,8(a5)
ffffffffc0200ca4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200ca6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200caa:	8082                	ret

ffffffffc0200cac <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200cac:	00005517          	auipc	a0,0x5
ffffffffc0200cb0:	38c56503          	lwu	a0,908(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200cb4:	8082                	ret

ffffffffc0200cb6 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200cb6:	c94d                	beqz	a0,ffffffffc0200d68 <best_fit_alloc_pages+0xb2>
    if (n > nr_free) {
ffffffffc0200cb8:	00005617          	auipc	a2,0x5
ffffffffc0200cbc:	37060613          	addi	a2,a2,880 # ffffffffc0206028 <free_area>
ffffffffc0200cc0:	01062803          	lw	a6,16(a2)
ffffffffc0200cc4:	86aa                	mv	a3,a0
ffffffffc0200cc6:	02081793          	slli	a5,a6,0x20
ffffffffc0200cca:	9381                	srli	a5,a5,0x20
ffffffffc0200ccc:	08a7ea63          	bltu	a5,a0,ffffffffc0200d60 <best_fit_alloc_pages+0xaa>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200cd0:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200cd2:	0018059b          	addiw	a1,a6,1
ffffffffc0200cd6:	1582                	slli	a1,a1,0x20
ffffffffc0200cd8:	9181                	srli	a1,a1,0x20
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cda:	08c78363          	beq	a5,a2,ffffffffc0200d60 <best_fit_alloc_pages+0xaa>
    struct Page *page = NULL;
ffffffffc0200cde:	4881                	li	a7,0
ffffffffc0200ce0:	a811                	j	ffffffffc0200cf4 <best_fit_alloc_pages+0x3e>
        }else if(p->property > n && p->property < min_size)
ffffffffc0200ce2:	00e6f663          	bgeu	a3,a4,ffffffffc0200cee <best_fit_alloc_pages+0x38>
ffffffffc0200ce6:	00b77463          	bgeu	a4,a1,ffffffffc0200cee <best_fit_alloc_pages+0x38>
ffffffffc0200cea:	85ba                	mv	a1,a4
        struct Page *p = le2page(le, page_link);
ffffffffc0200cec:	88aa                	mv	a7,a0
ffffffffc0200cee:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cf0:	06c78463          	beq	a5,a2,ffffffffc0200d58 <best_fit_alloc_pages+0xa2>
        if (p->property == n) {
ffffffffc0200cf4:	ff87e703          	lwu	a4,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0200cf8:	fe878513          	addi	a0,a5,-24
        if (p->property == n) {
ffffffffc0200cfc:	fed713e3          	bne	a4,a3,ffffffffc0200ce2 <best_fit_alloc_pages+0x2c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d00:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200d02:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200d04:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200d06:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d0a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200d0c:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200d0e:	02059793          	slli	a5,a1,0x20
ffffffffc0200d12:	9381                	srli	a5,a5,0x20
ffffffffc0200d14:	02f6f863          	bgeu	a3,a5,ffffffffc0200d44 <best_fit_alloc_pages+0x8e>
            struct Page *p = page + n;
ffffffffc0200d18:	00269793          	slli	a5,a3,0x2
ffffffffc0200d1c:	97b6                	add	a5,a5,a3
ffffffffc0200d1e:	078e                	slli	a5,a5,0x3
ffffffffc0200d20:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200d22:	411585bb          	subw	a1,a1,a7
ffffffffc0200d26:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d28:	4689                	li	a3,2
ffffffffc0200d2a:	00878593          	addi	a1,a5,8
ffffffffc0200d2e:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d32:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200d34:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200d38:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200d3c:	e28c                	sd	a1,0(a3)
ffffffffc0200d3e:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200d40:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200d42:	ef98                	sd	a4,24(a5)
ffffffffc0200d44:	4118083b          	subw	a6,a6,a7
ffffffffc0200d48:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200d4c:	57f5                	li	a5,-3
ffffffffc0200d4e:	00850713          	addi	a4,a0,8
ffffffffc0200d52:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200d56:	8082                	ret
        return NULL;
ffffffffc0200d58:	4501                	li	a0,0
    if (page != NULL) {
ffffffffc0200d5a:	00089563          	bnez	a7,ffffffffc0200d64 <best_fit_alloc_pages+0xae>
}
ffffffffc0200d5e:	8082                	ret
        return NULL;
ffffffffc0200d60:	4501                	li	a0,0
}
ffffffffc0200d62:	8082                	ret
ffffffffc0200d64:	8546                	mv	a0,a7
ffffffffc0200d66:	bf69                	j	ffffffffc0200d00 <best_fit_alloc_pages+0x4a>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d68:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200d6a:	00002697          	auipc	a3,0x2
ffffffffc0200d6e:	ac668693          	addi	a3,a3,-1338 # ffffffffc0202830 <commands+0x6d8>
ffffffffc0200d72:	00002617          	auipc	a2,0x2
ffffffffc0200d76:	ac660613          	addi	a2,a2,-1338 # ffffffffc0202838 <commands+0x6e0>
ffffffffc0200d7a:	06900593          	li	a1,105
ffffffffc0200d7e:	00002517          	auipc	a0,0x2
ffffffffc0200d82:	ad250513          	addi	a0,a0,-1326 # ffffffffc0202850 <commands+0x6f8>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d86:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d88:	e56ff0ef          	jal	ra,ffffffffc02003de <__panic>

ffffffffc0200d8c <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200d8c:	715d                	addi	sp,sp,-80
ffffffffc0200d8e:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200d90:	00005417          	auipc	s0,0x5
ffffffffc0200d94:	29840413          	addi	s0,s0,664 # ffffffffc0206028 <free_area>
ffffffffc0200d98:	641c                	ld	a5,8(s0)
ffffffffc0200d9a:	e486                	sd	ra,72(sp)
ffffffffc0200d9c:	fc26                	sd	s1,56(sp)
ffffffffc0200d9e:	f84a                	sd	s2,48(sp)
ffffffffc0200da0:	f44e                	sd	s3,40(sp)
ffffffffc0200da2:	f052                	sd	s4,32(sp)
ffffffffc0200da4:	ec56                	sd	s5,24(sp)
ffffffffc0200da6:	e85a                	sd	s6,16(sp)
ffffffffc0200da8:	e45e                	sd	s7,8(sp)
ffffffffc0200daa:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dac:	26878b63          	beq	a5,s0,ffffffffc0201022 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200db0:	4481                	li	s1,0
ffffffffc0200db2:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200db4:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200db8:	8b09                	andi	a4,a4,2
ffffffffc0200dba:	26070863          	beqz	a4,ffffffffc020102a <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200dbe:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200dc2:	679c                	ld	a5,8(a5)
ffffffffc0200dc4:	2905                	addiw	s2,s2,1
ffffffffc0200dc6:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dc8:	fe8796e3          	bne	a5,s0,ffffffffc0200db4 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200dcc:	89a6                	mv	s3,s1
ffffffffc0200dce:	167000ef          	jal	ra,ffffffffc0201734 <nr_free_pages>
ffffffffc0200dd2:	33351c63          	bne	a0,s3,ffffffffc020110a <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dd6:	4505                	li	a0,1
ffffffffc0200dd8:	0df000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200ddc:	8a2a                	mv	s4,a0
ffffffffc0200dde:	36050663          	beqz	a0,ffffffffc020114a <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200de2:	4505                	li	a0,1
ffffffffc0200de4:	0d3000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200de8:	89aa                	mv	s3,a0
ffffffffc0200dea:	34050063          	beqz	a0,ffffffffc020112a <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dee:	4505                	li	a0,1
ffffffffc0200df0:	0c7000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200df4:	8aaa                	mv	s5,a0
ffffffffc0200df6:	2c050a63          	beqz	a0,ffffffffc02010ca <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200dfa:	253a0863          	beq	s4,s3,ffffffffc020104a <best_fit_check+0x2be>
ffffffffc0200dfe:	24aa0663          	beq	s4,a0,ffffffffc020104a <best_fit_check+0x2be>
ffffffffc0200e02:	24a98463          	beq	s3,a0,ffffffffc020104a <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e06:	000a2783          	lw	a5,0(s4)
ffffffffc0200e0a:	26079063          	bnez	a5,ffffffffc020106a <best_fit_check+0x2de>
ffffffffc0200e0e:	0009a783          	lw	a5,0(s3)
ffffffffc0200e12:	24079c63          	bnez	a5,ffffffffc020106a <best_fit_check+0x2de>
ffffffffc0200e16:	411c                	lw	a5,0(a0)
ffffffffc0200e18:	24079963          	bnez	a5,ffffffffc020106a <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e1c:	00005797          	auipc	a5,0x5
ffffffffc0200e20:	6547b783          	ld	a5,1620(a5) # ffffffffc0206470 <pages>
ffffffffc0200e24:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e28:	870d                	srai	a4,a4,0x3
ffffffffc0200e2a:	00002597          	auipc	a1,0x2
ffffffffc0200e2e:	1165b583          	ld	a1,278(a1) # ffffffffc0202f40 <error_string+0x38>
ffffffffc0200e32:	02b70733          	mul	a4,a4,a1
ffffffffc0200e36:	00002617          	auipc	a2,0x2
ffffffffc0200e3a:	11263603          	ld	a2,274(a2) # ffffffffc0202f48 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e3e:	00005697          	auipc	a3,0x5
ffffffffc0200e42:	62a6b683          	ld	a3,1578(a3) # ffffffffc0206468 <npage>
ffffffffc0200e46:	06b2                	slli	a3,a3,0xc
ffffffffc0200e48:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e4a:	0732                	slli	a4,a4,0xc
ffffffffc0200e4c:	22d77f63          	bgeu	a4,a3,ffffffffc020108a <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e50:	40f98733          	sub	a4,s3,a5
ffffffffc0200e54:	870d                	srai	a4,a4,0x3
ffffffffc0200e56:	02b70733          	mul	a4,a4,a1
ffffffffc0200e5a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e5c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e5e:	3ed77663          	bgeu	a4,a3,ffffffffc020124a <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e62:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e66:	878d                	srai	a5,a5,0x3
ffffffffc0200e68:	02b787b3          	mul	a5,a5,a1
ffffffffc0200e6c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e6e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e70:	3ad7fd63          	bgeu	a5,a3,ffffffffc020122a <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200e74:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e76:	00043c03          	ld	s8,0(s0)
ffffffffc0200e7a:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e7e:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e82:	e400                	sd	s0,8(s0)
ffffffffc0200e84:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e86:	00005797          	auipc	a5,0x5
ffffffffc0200e8a:	1a07a923          	sw	zero,434(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e8e:	029000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200e92:	36051c63          	bnez	a0,ffffffffc020120a <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200e96:	4585                	li	a1,1
ffffffffc0200e98:	8552                	mv	a0,s4
ffffffffc0200e9a:	05b000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    free_page(p1);
ffffffffc0200e9e:	4585                	li	a1,1
ffffffffc0200ea0:	854e                	mv	a0,s3
ffffffffc0200ea2:	053000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    free_page(p2);
ffffffffc0200ea6:	4585                	li	a1,1
ffffffffc0200ea8:	8556                	mv	a0,s5
ffffffffc0200eaa:	04b000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    assert(nr_free == 3);
ffffffffc0200eae:	4818                	lw	a4,16(s0)
ffffffffc0200eb0:	478d                	li	a5,3
ffffffffc0200eb2:	32f71c63          	bne	a4,a5,ffffffffc02011ea <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200eb6:	4505                	li	a0,1
ffffffffc0200eb8:	7fe000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200ebc:	89aa                	mv	s3,a0
ffffffffc0200ebe:	30050663          	beqz	a0,ffffffffc02011ca <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ec2:	4505                	li	a0,1
ffffffffc0200ec4:	7f2000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200ec8:	8aaa                	mv	s5,a0
ffffffffc0200eca:	2e050063          	beqz	a0,ffffffffc02011aa <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ece:	4505                	li	a0,1
ffffffffc0200ed0:	7e6000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200ed4:	8a2a                	mv	s4,a0
ffffffffc0200ed6:	2a050a63          	beqz	a0,ffffffffc020118a <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200eda:	4505                	li	a0,1
ffffffffc0200edc:	7da000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200ee0:	28051563          	bnez	a0,ffffffffc020116a <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200ee4:	4585                	li	a1,1
ffffffffc0200ee6:	854e                	mv	a0,s3
ffffffffc0200ee8:	00d000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200eec:	641c                	ld	a5,8(s0)
ffffffffc0200eee:	1a878e63          	beq	a5,s0,ffffffffc02010aa <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200ef2:	4505                	li	a0,1
ffffffffc0200ef4:	7c2000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200ef8:	52a99963          	bne	s3,a0,ffffffffc020142a <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200efc:	4505                	li	a0,1
ffffffffc0200efe:	7b8000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200f02:	50051463          	bnez	a0,ffffffffc020140a <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200f06:	481c                	lw	a5,16(s0)
ffffffffc0200f08:	4e079163          	bnez	a5,ffffffffc02013ea <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200f0c:	854e                	mv	a0,s3
ffffffffc0200f0e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f10:	01843023          	sd	s8,0(s0)
ffffffffc0200f14:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f18:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f1c:	7d8000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    free_page(p1);
ffffffffc0200f20:	4585                	li	a1,1
ffffffffc0200f22:	8556                	mv	a0,s5
ffffffffc0200f24:	7d0000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    free_page(p2);
ffffffffc0200f28:	4585                	li	a1,1
ffffffffc0200f2a:	8552                	mv	a0,s4
ffffffffc0200f2c:	7c8000ef          	jal	ra,ffffffffc02016f4 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f30:	4515                	li	a0,5
ffffffffc0200f32:	784000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200f36:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f38:	48050963          	beqz	a0,ffffffffc02013ca <best_fit_check+0x63e>
ffffffffc0200f3c:	651c                	ld	a5,8(a0)
ffffffffc0200f3e:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f40:	8b85                	andi	a5,a5,1
ffffffffc0200f42:	46079463          	bnez	a5,ffffffffc02013aa <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f46:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f48:	00043a83          	ld	s5,0(s0)
ffffffffc0200f4c:	00843a03          	ld	s4,8(s0)
ffffffffc0200f50:	e000                	sd	s0,0(s0)
ffffffffc0200f52:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f54:	762000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200f58:	42051963          	bnez	a0,ffffffffc020138a <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200f5c:	4589                	li	a1,2
ffffffffc0200f5e:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200f62:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200f66:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200f6a:	00005797          	auipc	a5,0x5
ffffffffc0200f6e:	0c07a723          	sw	zero,206(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200f72:	782000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200f76:	8562                	mv	a0,s8
ffffffffc0200f78:	4585                	li	a1,1
ffffffffc0200f7a:	77a000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f7e:	4511                	li	a0,4
ffffffffc0200f80:	736000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200f84:	3e051363          	bnez	a0,ffffffffc020136a <best_fit_check+0x5de>
ffffffffc0200f88:	0309b783          	ld	a5,48(s3)
ffffffffc0200f8c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f8e:	8b85                	andi	a5,a5,1
ffffffffc0200f90:	3a078d63          	beqz	a5,ffffffffc020134a <best_fit_check+0x5be>
ffffffffc0200f94:	0389a703          	lw	a4,56(s3)
ffffffffc0200f98:	4789                	li	a5,2
ffffffffc0200f9a:	3af71863          	bne	a4,a5,ffffffffc020134a <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f9e:	4505                	li	a0,1
ffffffffc0200fa0:	716000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200fa4:	8baa                	mv	s7,a0
ffffffffc0200fa6:	38050263          	beqz	a0,ffffffffc020132a <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200faa:	4509                	li	a0,2
ffffffffc0200fac:	70a000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200fb0:	34050d63          	beqz	a0,ffffffffc020130a <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200fb4:	337c1b63          	bne	s8,s7,ffffffffc02012ea <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200fb8:	854e                	mv	a0,s3
ffffffffc0200fba:	4595                	li	a1,5
ffffffffc0200fbc:	738000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200fc0:	4515                	li	a0,5
ffffffffc0200fc2:	6f4000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200fc6:	89aa                	mv	s3,a0
ffffffffc0200fc8:	30050163          	beqz	a0,ffffffffc02012ca <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200fcc:	4505                	li	a0,1
ffffffffc0200fce:	6e8000ef          	jal	ra,ffffffffc02016b6 <alloc_pages>
ffffffffc0200fd2:	2c051c63          	bnez	a0,ffffffffc02012aa <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200fd6:	481c                	lw	a5,16(s0)
ffffffffc0200fd8:	2a079963          	bnez	a5,ffffffffc020128a <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fdc:	4595                	li	a1,5
ffffffffc0200fde:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200fe0:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200fe4:	01543023          	sd	s5,0(s0)
ffffffffc0200fe8:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200fec:	708000ef          	jal	ra,ffffffffc02016f4 <free_pages>
    return listelm->next;
ffffffffc0200ff0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ff2:	00878963          	beq	a5,s0,ffffffffc0201004 <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200ff6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ffa:	679c                	ld	a5,8(a5)
ffffffffc0200ffc:	397d                	addiw	s2,s2,-1
ffffffffc0200ffe:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201000:	fe879be3          	bne	a5,s0,ffffffffc0200ff6 <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0201004:	26091363          	bnez	s2,ffffffffc020126a <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0201008:	e0ed                	bnez	s1,ffffffffc02010ea <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc020100a:	60a6                	ld	ra,72(sp)
ffffffffc020100c:	6406                	ld	s0,64(sp)
ffffffffc020100e:	74e2                	ld	s1,56(sp)
ffffffffc0201010:	7942                	ld	s2,48(sp)
ffffffffc0201012:	79a2                	ld	s3,40(sp)
ffffffffc0201014:	7a02                	ld	s4,32(sp)
ffffffffc0201016:	6ae2                	ld	s5,24(sp)
ffffffffc0201018:	6b42                	ld	s6,16(sp)
ffffffffc020101a:	6ba2                	ld	s7,8(sp)
ffffffffc020101c:	6c02                	ld	s8,0(sp)
ffffffffc020101e:	6161                	addi	sp,sp,80
ffffffffc0201020:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201022:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201024:	4481                	li	s1,0
ffffffffc0201026:	4901                	li	s2,0
ffffffffc0201028:	b35d                	j	ffffffffc0200dce <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc020102a:	00002697          	auipc	a3,0x2
ffffffffc020102e:	83e68693          	addi	a3,a3,-1986 # ffffffffc0202868 <commands+0x710>
ffffffffc0201032:	00002617          	auipc	a2,0x2
ffffffffc0201036:	80660613          	addi	a2,a2,-2042 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020103a:	10f00593          	li	a1,271
ffffffffc020103e:	00002517          	auipc	a0,0x2
ffffffffc0201042:	81250513          	addi	a0,a0,-2030 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201046:	b98ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020104a:	00002697          	auipc	a3,0x2
ffffffffc020104e:	8ae68693          	addi	a3,a3,-1874 # ffffffffc02028f8 <commands+0x7a0>
ffffffffc0201052:	00001617          	auipc	a2,0x1
ffffffffc0201056:	7e660613          	addi	a2,a2,2022 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020105a:	0db00593          	li	a1,219
ffffffffc020105e:	00001517          	auipc	a0,0x1
ffffffffc0201062:	7f250513          	addi	a0,a0,2034 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201066:	b78ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020106a:	00002697          	auipc	a3,0x2
ffffffffc020106e:	8b668693          	addi	a3,a3,-1866 # ffffffffc0202920 <commands+0x7c8>
ffffffffc0201072:	00001617          	auipc	a2,0x1
ffffffffc0201076:	7c660613          	addi	a2,a2,1990 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020107a:	0dc00593          	li	a1,220
ffffffffc020107e:	00001517          	auipc	a0,0x1
ffffffffc0201082:	7d250513          	addi	a0,a0,2002 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201086:	b58ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020108a:	00002697          	auipc	a3,0x2
ffffffffc020108e:	8d668693          	addi	a3,a3,-1834 # ffffffffc0202960 <commands+0x808>
ffffffffc0201092:	00001617          	auipc	a2,0x1
ffffffffc0201096:	7a660613          	addi	a2,a2,1958 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020109a:	0de00593          	li	a1,222
ffffffffc020109e:	00001517          	auipc	a0,0x1
ffffffffc02010a2:	7b250513          	addi	a0,a0,1970 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02010a6:	b38ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010aa:	00002697          	auipc	a3,0x2
ffffffffc02010ae:	93e68693          	addi	a3,a3,-1730 # ffffffffc02029e8 <commands+0x890>
ffffffffc02010b2:	00001617          	auipc	a2,0x1
ffffffffc02010b6:	78660613          	addi	a2,a2,1926 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02010ba:	0f700593          	li	a1,247
ffffffffc02010be:	00001517          	auipc	a0,0x1
ffffffffc02010c2:	79250513          	addi	a0,a0,1938 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02010c6:	b18ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010ca:	00002697          	auipc	a3,0x2
ffffffffc02010ce:	80e68693          	addi	a3,a3,-2034 # ffffffffc02028d8 <commands+0x780>
ffffffffc02010d2:	00001617          	auipc	a2,0x1
ffffffffc02010d6:	76660613          	addi	a2,a2,1894 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02010da:	0d900593          	li	a1,217
ffffffffc02010de:	00001517          	auipc	a0,0x1
ffffffffc02010e2:	77250513          	addi	a0,a0,1906 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02010e6:	af8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(total == 0);
ffffffffc02010ea:	00002697          	auipc	a3,0x2
ffffffffc02010ee:	a2e68693          	addi	a3,a3,-1490 # ffffffffc0202b18 <commands+0x9c0>
ffffffffc02010f2:	00001617          	auipc	a2,0x1
ffffffffc02010f6:	74660613          	addi	a2,a2,1862 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02010fa:	15100593          	li	a1,337
ffffffffc02010fe:	00001517          	auipc	a0,0x1
ffffffffc0201102:	75250513          	addi	a0,a0,1874 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201106:	ad8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(total == nr_free_pages());
ffffffffc020110a:	00001697          	auipc	a3,0x1
ffffffffc020110e:	76e68693          	addi	a3,a3,1902 # ffffffffc0202878 <commands+0x720>
ffffffffc0201112:	00001617          	auipc	a2,0x1
ffffffffc0201116:	72660613          	addi	a2,a2,1830 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020111a:	11200593          	li	a1,274
ffffffffc020111e:	00001517          	auipc	a0,0x1
ffffffffc0201122:	73250513          	addi	a0,a0,1842 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201126:	ab8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020112a:	00001697          	auipc	a3,0x1
ffffffffc020112e:	78e68693          	addi	a3,a3,1934 # ffffffffc02028b8 <commands+0x760>
ffffffffc0201132:	00001617          	auipc	a2,0x1
ffffffffc0201136:	70660613          	addi	a2,a2,1798 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020113a:	0d800593          	li	a1,216
ffffffffc020113e:	00001517          	auipc	a0,0x1
ffffffffc0201142:	71250513          	addi	a0,a0,1810 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201146:	a98ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020114a:	00001697          	auipc	a3,0x1
ffffffffc020114e:	74e68693          	addi	a3,a3,1870 # ffffffffc0202898 <commands+0x740>
ffffffffc0201152:	00001617          	auipc	a2,0x1
ffffffffc0201156:	6e660613          	addi	a2,a2,1766 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020115a:	0d700593          	li	a1,215
ffffffffc020115e:	00001517          	auipc	a0,0x1
ffffffffc0201162:	6f250513          	addi	a0,a0,1778 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201166:	a78ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(alloc_page() == NULL);
ffffffffc020116a:	00002697          	auipc	a3,0x2
ffffffffc020116e:	85668693          	addi	a3,a3,-1962 # ffffffffc02029c0 <commands+0x868>
ffffffffc0201172:	00001617          	auipc	a2,0x1
ffffffffc0201176:	6c660613          	addi	a2,a2,1734 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020117a:	0f400593          	li	a1,244
ffffffffc020117e:	00001517          	auipc	a0,0x1
ffffffffc0201182:	6d250513          	addi	a0,a0,1746 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201186:	a58ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020118a:	00001697          	auipc	a3,0x1
ffffffffc020118e:	74e68693          	addi	a3,a3,1870 # ffffffffc02028d8 <commands+0x780>
ffffffffc0201192:	00001617          	auipc	a2,0x1
ffffffffc0201196:	6a660613          	addi	a2,a2,1702 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020119a:	0f200593          	li	a1,242
ffffffffc020119e:	00001517          	auipc	a0,0x1
ffffffffc02011a2:	6b250513          	addi	a0,a0,1714 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02011a6:	a38ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011aa:	00001697          	auipc	a3,0x1
ffffffffc02011ae:	70e68693          	addi	a3,a3,1806 # ffffffffc02028b8 <commands+0x760>
ffffffffc02011b2:	00001617          	auipc	a2,0x1
ffffffffc02011b6:	68660613          	addi	a2,a2,1670 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02011ba:	0f100593          	li	a1,241
ffffffffc02011be:	00001517          	auipc	a0,0x1
ffffffffc02011c2:	69250513          	addi	a0,a0,1682 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02011c6:	a18ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011ca:	00001697          	auipc	a3,0x1
ffffffffc02011ce:	6ce68693          	addi	a3,a3,1742 # ffffffffc0202898 <commands+0x740>
ffffffffc02011d2:	00001617          	auipc	a2,0x1
ffffffffc02011d6:	66660613          	addi	a2,a2,1638 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02011da:	0f000593          	li	a1,240
ffffffffc02011de:	00001517          	auipc	a0,0x1
ffffffffc02011e2:	67250513          	addi	a0,a0,1650 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02011e6:	9f8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(nr_free == 3);
ffffffffc02011ea:	00001697          	auipc	a3,0x1
ffffffffc02011ee:	7ee68693          	addi	a3,a3,2030 # ffffffffc02029d8 <commands+0x880>
ffffffffc02011f2:	00001617          	auipc	a2,0x1
ffffffffc02011f6:	64660613          	addi	a2,a2,1606 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02011fa:	0ee00593          	li	a1,238
ffffffffc02011fe:	00001517          	auipc	a0,0x1
ffffffffc0201202:	65250513          	addi	a0,a0,1618 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201206:	9d8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(alloc_page() == NULL);
ffffffffc020120a:	00001697          	auipc	a3,0x1
ffffffffc020120e:	7b668693          	addi	a3,a3,1974 # ffffffffc02029c0 <commands+0x868>
ffffffffc0201212:	00001617          	auipc	a2,0x1
ffffffffc0201216:	62660613          	addi	a2,a2,1574 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020121a:	0e900593          	li	a1,233
ffffffffc020121e:	00001517          	auipc	a0,0x1
ffffffffc0201222:	63250513          	addi	a0,a0,1586 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201226:	9b8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020122a:	00001697          	auipc	a3,0x1
ffffffffc020122e:	77668693          	addi	a3,a3,1910 # ffffffffc02029a0 <commands+0x848>
ffffffffc0201232:	00001617          	auipc	a2,0x1
ffffffffc0201236:	60660613          	addi	a2,a2,1542 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020123a:	0e000593          	li	a1,224
ffffffffc020123e:	00001517          	auipc	a0,0x1
ffffffffc0201242:	61250513          	addi	a0,a0,1554 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201246:	998ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020124a:	00001697          	auipc	a3,0x1
ffffffffc020124e:	73668693          	addi	a3,a3,1846 # ffffffffc0202980 <commands+0x828>
ffffffffc0201252:	00001617          	auipc	a2,0x1
ffffffffc0201256:	5e660613          	addi	a2,a2,1510 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020125a:	0df00593          	li	a1,223
ffffffffc020125e:	00001517          	auipc	a0,0x1
ffffffffc0201262:	5f250513          	addi	a0,a0,1522 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201266:	978ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(count == 0);
ffffffffc020126a:	00002697          	auipc	a3,0x2
ffffffffc020126e:	89e68693          	addi	a3,a3,-1890 # ffffffffc0202b08 <commands+0x9b0>
ffffffffc0201272:	00001617          	auipc	a2,0x1
ffffffffc0201276:	5c660613          	addi	a2,a2,1478 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020127a:	15000593          	li	a1,336
ffffffffc020127e:	00001517          	auipc	a0,0x1
ffffffffc0201282:	5d250513          	addi	a0,a0,1490 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201286:	958ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(nr_free == 0);
ffffffffc020128a:	00001697          	auipc	a3,0x1
ffffffffc020128e:	79668693          	addi	a3,a3,1942 # ffffffffc0202a20 <commands+0x8c8>
ffffffffc0201292:	00001617          	auipc	a2,0x1
ffffffffc0201296:	5a660613          	addi	a2,a2,1446 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020129a:	14500593          	li	a1,325
ffffffffc020129e:	00001517          	auipc	a0,0x1
ffffffffc02012a2:	5b250513          	addi	a0,a0,1458 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02012a6:	938ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012aa:	00001697          	auipc	a3,0x1
ffffffffc02012ae:	71668693          	addi	a3,a3,1814 # ffffffffc02029c0 <commands+0x868>
ffffffffc02012b2:	00001617          	auipc	a2,0x1
ffffffffc02012b6:	58660613          	addi	a2,a2,1414 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02012ba:	13f00593          	li	a1,319
ffffffffc02012be:	00001517          	auipc	a0,0x1
ffffffffc02012c2:	59250513          	addi	a0,a0,1426 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02012c6:	918ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012ca:	00002697          	auipc	a3,0x2
ffffffffc02012ce:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202ae8 <commands+0x990>
ffffffffc02012d2:	00001617          	auipc	a2,0x1
ffffffffc02012d6:	56660613          	addi	a2,a2,1382 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02012da:	13e00593          	li	a1,318
ffffffffc02012de:	00001517          	auipc	a0,0x1
ffffffffc02012e2:	57250513          	addi	a0,a0,1394 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02012e6:	8f8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(p0 + 4 == p1);
ffffffffc02012ea:	00001697          	auipc	a3,0x1
ffffffffc02012ee:	7ee68693          	addi	a3,a3,2030 # ffffffffc0202ad8 <commands+0x980>
ffffffffc02012f2:	00001617          	auipc	a2,0x1
ffffffffc02012f6:	54660613          	addi	a2,a2,1350 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02012fa:	13600593          	li	a1,310
ffffffffc02012fe:	00001517          	auipc	a0,0x1
ffffffffc0201302:	55250513          	addi	a0,a0,1362 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201306:	8d8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc020130a:	00001697          	auipc	a3,0x1
ffffffffc020130e:	7b668693          	addi	a3,a3,1974 # ffffffffc0202ac0 <commands+0x968>
ffffffffc0201312:	00001617          	auipc	a2,0x1
ffffffffc0201316:	52660613          	addi	a2,a2,1318 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020131a:	13500593          	li	a1,309
ffffffffc020131e:	00001517          	auipc	a0,0x1
ffffffffc0201322:	53250513          	addi	a0,a0,1330 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201326:	8b8ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc020132a:	00001697          	auipc	a3,0x1
ffffffffc020132e:	77668693          	addi	a3,a3,1910 # ffffffffc0202aa0 <commands+0x948>
ffffffffc0201332:	00001617          	auipc	a2,0x1
ffffffffc0201336:	50660613          	addi	a2,a2,1286 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020133a:	13400593          	li	a1,308
ffffffffc020133e:	00001517          	auipc	a0,0x1
ffffffffc0201342:	51250513          	addi	a0,a0,1298 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201346:	898ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc020134a:	00001697          	auipc	a3,0x1
ffffffffc020134e:	72668693          	addi	a3,a3,1830 # ffffffffc0202a70 <commands+0x918>
ffffffffc0201352:	00001617          	auipc	a2,0x1
ffffffffc0201356:	4e660613          	addi	a2,a2,1254 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020135a:	13200593          	li	a1,306
ffffffffc020135e:	00001517          	auipc	a0,0x1
ffffffffc0201362:	4f250513          	addi	a0,a0,1266 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201366:	878ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020136a:	00001697          	auipc	a3,0x1
ffffffffc020136e:	6ee68693          	addi	a3,a3,1774 # ffffffffc0202a58 <commands+0x900>
ffffffffc0201372:	00001617          	auipc	a2,0x1
ffffffffc0201376:	4c660613          	addi	a2,a2,1222 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020137a:	13100593          	li	a1,305
ffffffffc020137e:	00001517          	auipc	a0,0x1
ffffffffc0201382:	4d250513          	addi	a0,a0,1234 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201386:	858ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(alloc_page() == NULL);
ffffffffc020138a:	00001697          	auipc	a3,0x1
ffffffffc020138e:	63668693          	addi	a3,a3,1590 # ffffffffc02029c0 <commands+0x868>
ffffffffc0201392:	00001617          	auipc	a2,0x1
ffffffffc0201396:	4a660613          	addi	a2,a2,1190 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020139a:	12500593          	li	a1,293
ffffffffc020139e:	00001517          	auipc	a0,0x1
ffffffffc02013a2:	4b250513          	addi	a0,a0,1202 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02013a6:	838ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(!PageProperty(p0));
ffffffffc02013aa:	00001697          	auipc	a3,0x1
ffffffffc02013ae:	69668693          	addi	a3,a3,1686 # ffffffffc0202a40 <commands+0x8e8>
ffffffffc02013b2:	00001617          	auipc	a2,0x1
ffffffffc02013b6:	48660613          	addi	a2,a2,1158 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02013ba:	11c00593          	li	a1,284
ffffffffc02013be:	00001517          	auipc	a0,0x1
ffffffffc02013c2:	49250513          	addi	a0,a0,1170 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02013c6:	818ff0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(p0 != NULL);
ffffffffc02013ca:	00001697          	auipc	a3,0x1
ffffffffc02013ce:	66668693          	addi	a3,a3,1638 # ffffffffc0202a30 <commands+0x8d8>
ffffffffc02013d2:	00001617          	auipc	a2,0x1
ffffffffc02013d6:	46660613          	addi	a2,a2,1126 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02013da:	11b00593          	li	a1,283
ffffffffc02013de:	00001517          	auipc	a0,0x1
ffffffffc02013e2:	47250513          	addi	a0,a0,1138 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02013e6:	ff9fe0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(nr_free == 0);
ffffffffc02013ea:	00001697          	auipc	a3,0x1
ffffffffc02013ee:	63668693          	addi	a3,a3,1590 # ffffffffc0202a20 <commands+0x8c8>
ffffffffc02013f2:	00001617          	auipc	a2,0x1
ffffffffc02013f6:	44660613          	addi	a2,a2,1094 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02013fa:	0fd00593          	li	a1,253
ffffffffc02013fe:	00001517          	auipc	a0,0x1
ffffffffc0201402:	45250513          	addi	a0,a0,1106 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201406:	fd9fe0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(alloc_page() == NULL);
ffffffffc020140a:	00001697          	auipc	a3,0x1
ffffffffc020140e:	5b668693          	addi	a3,a3,1462 # ffffffffc02029c0 <commands+0x868>
ffffffffc0201412:	00001617          	auipc	a2,0x1
ffffffffc0201416:	42660613          	addi	a2,a2,1062 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020141a:	0fb00593          	li	a1,251
ffffffffc020141e:	00001517          	auipc	a0,0x1
ffffffffc0201422:	43250513          	addi	a0,a0,1074 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201426:	fb9fe0ef          	jal	ra,ffffffffc02003de <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020142a:	00001697          	auipc	a3,0x1
ffffffffc020142e:	5d668693          	addi	a3,a3,1494 # ffffffffc0202a00 <commands+0x8a8>
ffffffffc0201432:	00001617          	auipc	a2,0x1
ffffffffc0201436:	40660613          	addi	a2,a2,1030 # ffffffffc0202838 <commands+0x6e0>
ffffffffc020143a:	0fa00593          	li	a1,250
ffffffffc020143e:	00001517          	auipc	a0,0x1
ffffffffc0201442:	41250513          	addi	a0,a0,1042 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201446:	f99fe0ef          	jal	ra,ffffffffc02003de <__panic>

ffffffffc020144a <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc020144a:	1141                	addi	sp,sp,-16
ffffffffc020144c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020144e:	14058a63          	beqz	a1,ffffffffc02015a2 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201452:	00259693          	slli	a3,a1,0x2
ffffffffc0201456:	96ae                	add	a3,a3,a1
ffffffffc0201458:	068e                	slli	a3,a3,0x3
ffffffffc020145a:	96aa                	add	a3,a3,a0
ffffffffc020145c:	87aa                	mv	a5,a0
ffffffffc020145e:	02d50263          	beq	a0,a3,ffffffffc0201482 <best_fit_free_pages+0x38>
ffffffffc0201462:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201464:	8b05                	andi	a4,a4,1
ffffffffc0201466:	10071e63          	bnez	a4,ffffffffc0201582 <best_fit_free_pages+0x138>
ffffffffc020146a:	6798                	ld	a4,8(a5)
ffffffffc020146c:	8b09                	andi	a4,a4,2
ffffffffc020146e:	10071a63          	bnez	a4,ffffffffc0201582 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0201472:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201476:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020147a:	02878793          	addi	a5,a5,40
ffffffffc020147e:	fed792e3          	bne	a5,a3,ffffffffc0201462 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0201482:	2581                	sext.w	a1,a1
ffffffffc0201484:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201486:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020148a:	4789                	li	a5,2
ffffffffc020148c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201490:	00005697          	auipc	a3,0x5
ffffffffc0201494:	b9868693          	addi	a3,a3,-1128 # ffffffffc0206028 <free_area>
ffffffffc0201498:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020149a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020149c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014a0:	9db9                	addw	a1,a1,a4
ffffffffc02014a2:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014a4:	0ad78863          	beq	a5,a3,ffffffffc0201554 <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014a8:	fe878713          	addi	a4,a5,-24
ffffffffc02014ac:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014b0:	4581                	li	a1,0
            if (base < page) {
ffffffffc02014b2:	00e56a63          	bltu	a0,a4,ffffffffc02014c6 <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc02014b6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014b8:	06d70263          	beq	a4,a3,ffffffffc020151c <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02014bc:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014be:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014c2:	fee57ae3          	bgeu	a0,a4,ffffffffc02014b6 <best_fit_free_pages+0x6c>
ffffffffc02014c6:	c199                	beqz	a1,ffffffffc02014cc <best_fit_free_pages+0x82>
ffffffffc02014c8:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014cc:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02014ce:	e390                	sd	a2,0(a5)
ffffffffc02014d0:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014d2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014d4:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02014d6:	02d70063          	beq	a4,a3,ffffffffc02014f6 <best_fit_free_pages+0xac>
        if(p+p->property==base)
ffffffffc02014da:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02014de:	fe870593          	addi	a1,a4,-24
        if(p+p->property==base)
ffffffffc02014e2:	02081613          	slli	a2,a6,0x20
ffffffffc02014e6:	9201                	srli	a2,a2,0x20
ffffffffc02014e8:	00261793          	slli	a5,a2,0x2
ffffffffc02014ec:	97b2                	add	a5,a5,a2
ffffffffc02014ee:	078e                	slli	a5,a5,0x3
ffffffffc02014f0:	97ae                	add	a5,a5,a1
ffffffffc02014f2:	02f50f63          	beq	a0,a5,ffffffffc0201530 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc02014f6:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014f8:	00d70f63          	beq	a4,a3,ffffffffc0201516 <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02014fc:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014fe:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201502:	02059613          	slli	a2,a1,0x20
ffffffffc0201506:	9201                	srli	a2,a2,0x20
ffffffffc0201508:	00261793          	slli	a5,a2,0x2
ffffffffc020150c:	97b2                	add	a5,a5,a2
ffffffffc020150e:	078e                	slli	a5,a5,0x3
ffffffffc0201510:	97aa                	add	a5,a5,a0
ffffffffc0201512:	04f68863          	beq	a3,a5,ffffffffc0201562 <best_fit_free_pages+0x118>
}
ffffffffc0201516:	60a2                	ld	ra,8(sp)
ffffffffc0201518:	0141                	addi	sp,sp,16
ffffffffc020151a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020151c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020151e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201520:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201522:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201524:	02d70563          	beq	a4,a3,ffffffffc020154e <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201528:	8832                	mv	a6,a2
ffffffffc020152a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020152c:	87ba                	mv	a5,a4
ffffffffc020152e:	bf41                	j	ffffffffc02014be <best_fit_free_pages+0x74>
            p->property+=base->property;
ffffffffc0201530:	491c                	lw	a5,16(a0)
ffffffffc0201532:	0107883b          	addw	a6,a5,a6
ffffffffc0201536:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020153a:	57f5                	li	a5,-3
ffffffffc020153c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201540:	6d10                	ld	a2,24(a0)
ffffffffc0201542:	711c                	ld	a5,32(a0)
            base=p;
ffffffffc0201544:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc0201546:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201548:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc020154a:	e390                	sd	a2,0(a5)
ffffffffc020154c:	b775                	j	ffffffffc02014f8 <best_fit_free_pages+0xae>
ffffffffc020154e:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201550:	873e                	mv	a4,a5
ffffffffc0201552:	b761                	j	ffffffffc02014da <best_fit_free_pages+0x90>
}
ffffffffc0201554:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201556:	e390                	sd	a2,0(a5)
ffffffffc0201558:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020155a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020155c:	ed1c                	sd	a5,24(a0)
ffffffffc020155e:	0141                	addi	sp,sp,16
ffffffffc0201560:	8082                	ret
            base->property += p->property;
ffffffffc0201562:	ff872783          	lw	a5,-8(a4)
ffffffffc0201566:	ff070693          	addi	a3,a4,-16
ffffffffc020156a:	9dbd                	addw	a1,a1,a5
ffffffffc020156c:	c90c                	sw	a1,16(a0)
ffffffffc020156e:	57f5                	li	a5,-3
ffffffffc0201570:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201574:	6314                	ld	a3,0(a4)
ffffffffc0201576:	671c                	ld	a5,8(a4)
}
ffffffffc0201578:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020157a:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020157c:	e394                	sd	a3,0(a5)
ffffffffc020157e:	0141                	addi	sp,sp,16
ffffffffc0201580:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201582:	00001697          	auipc	a3,0x1
ffffffffc0201586:	5a668693          	addi	a3,a3,1446 # ffffffffc0202b28 <commands+0x9d0>
ffffffffc020158a:	00001617          	auipc	a2,0x1
ffffffffc020158e:	2ae60613          	addi	a2,a2,686 # ffffffffc0202838 <commands+0x6e0>
ffffffffc0201592:	09600593          	li	a1,150
ffffffffc0201596:	00001517          	auipc	a0,0x1
ffffffffc020159a:	2ba50513          	addi	a0,a0,698 # ffffffffc0202850 <commands+0x6f8>
ffffffffc020159e:	e41fe0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(n > 0);
ffffffffc02015a2:	00001697          	auipc	a3,0x1
ffffffffc02015a6:	28e68693          	addi	a3,a3,654 # ffffffffc0202830 <commands+0x6d8>
ffffffffc02015aa:	00001617          	auipc	a2,0x1
ffffffffc02015ae:	28e60613          	addi	a2,a2,654 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02015b2:	09300593          	li	a1,147
ffffffffc02015b6:	00001517          	auipc	a0,0x1
ffffffffc02015ba:	29a50513          	addi	a0,a0,666 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02015be:	e21fe0ef          	jal	ra,ffffffffc02003de <__panic>

ffffffffc02015c2 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02015c2:	1141                	addi	sp,sp,-16
ffffffffc02015c4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015c6:	c9e1                	beqz	a1,ffffffffc0201696 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02015c8:	00259693          	slli	a3,a1,0x2
ffffffffc02015cc:	96ae                	add	a3,a3,a1
ffffffffc02015ce:	068e                	slli	a3,a3,0x3
ffffffffc02015d0:	96aa                	add	a3,a3,a0
ffffffffc02015d2:	87aa                	mv	a5,a0
ffffffffc02015d4:	00d50f63          	beq	a0,a3,ffffffffc02015f2 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02015d8:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02015da:	8b05                	andi	a4,a4,1
ffffffffc02015dc:	cf49                	beqz	a4,ffffffffc0201676 <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02015de:	0007a823          	sw	zero,16(a5)
ffffffffc02015e2:	0007b423          	sd	zero,8(a5)
ffffffffc02015e6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015ea:	02878793          	addi	a5,a5,40
ffffffffc02015ee:	fed795e3          	bne	a5,a3,ffffffffc02015d8 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02015f2:	2581                	sext.w	a1,a1
ffffffffc02015f4:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015f6:	4789                	li	a5,2
ffffffffc02015f8:	00850713          	addi	a4,a0,8
ffffffffc02015fc:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201600:	00005697          	auipc	a3,0x5
ffffffffc0201604:	a2868693          	addi	a3,a3,-1496 # ffffffffc0206028 <free_area>
ffffffffc0201608:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020160a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020160c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201610:	9db9                	addw	a1,a1,a4
ffffffffc0201612:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201614:	04d78a63          	beq	a5,a3,ffffffffc0201668 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201618:	fe878713          	addi	a4,a5,-24
ffffffffc020161c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201620:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201622:	00e56a63          	bltu	a0,a4,ffffffffc0201636 <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc0201626:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201628:	02d70263          	beq	a4,a3,ffffffffc020164c <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc020162c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020162e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201632:	fee57ae3          	bgeu	a0,a4,ffffffffc0201626 <best_fit_init_memmap+0x64>
ffffffffc0201636:	c199                	beqz	a1,ffffffffc020163c <best_fit_init_memmap+0x7a>
ffffffffc0201638:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020163c:	6398                	ld	a4,0(a5)
}
ffffffffc020163e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201640:	e390                	sd	a2,0(a5)
ffffffffc0201642:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201644:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201646:	ed18                	sd	a4,24(a0)
ffffffffc0201648:	0141                	addi	sp,sp,16
ffffffffc020164a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020164c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020164e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201650:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201652:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201654:	00d70663          	beq	a4,a3,ffffffffc0201660 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201658:	8832                	mv	a6,a2
ffffffffc020165a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020165c:	87ba                	mv	a5,a4
ffffffffc020165e:	bfc1                	j	ffffffffc020162e <best_fit_init_memmap+0x6c>
}
ffffffffc0201660:	60a2                	ld	ra,8(sp)
ffffffffc0201662:	e290                	sd	a2,0(a3)
ffffffffc0201664:	0141                	addi	sp,sp,16
ffffffffc0201666:	8082                	ret
ffffffffc0201668:	60a2                	ld	ra,8(sp)
ffffffffc020166a:	e390                	sd	a2,0(a5)
ffffffffc020166c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020166e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201670:	ed1c                	sd	a5,24(a0)
ffffffffc0201672:	0141                	addi	sp,sp,16
ffffffffc0201674:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201676:	00001697          	auipc	a3,0x1
ffffffffc020167a:	4da68693          	addi	a3,a3,1242 # ffffffffc0202b50 <commands+0x9f8>
ffffffffc020167e:	00001617          	auipc	a2,0x1
ffffffffc0201682:	1ba60613          	addi	a2,a2,442 # ffffffffc0202838 <commands+0x6e0>
ffffffffc0201686:	04a00593          	li	a1,74
ffffffffc020168a:	00001517          	auipc	a0,0x1
ffffffffc020168e:	1c650513          	addi	a0,a0,454 # ffffffffc0202850 <commands+0x6f8>
ffffffffc0201692:	d4dfe0ef          	jal	ra,ffffffffc02003de <__panic>
    assert(n > 0);
ffffffffc0201696:	00001697          	auipc	a3,0x1
ffffffffc020169a:	19a68693          	addi	a3,a3,410 # ffffffffc0202830 <commands+0x6d8>
ffffffffc020169e:	00001617          	auipc	a2,0x1
ffffffffc02016a2:	19a60613          	addi	a2,a2,410 # ffffffffc0202838 <commands+0x6e0>
ffffffffc02016a6:	04700593          	li	a1,71
ffffffffc02016aa:	00001517          	auipc	a0,0x1
ffffffffc02016ae:	1a650513          	addi	a0,a0,422 # ffffffffc0202850 <commands+0x6f8>
ffffffffc02016b2:	d2dfe0ef          	jal	ra,ffffffffc02003de <__panic>

ffffffffc02016b6 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016b6:	100027f3          	csrr	a5,sstatus
ffffffffc02016ba:	8b89                	andi	a5,a5,2
ffffffffc02016bc:	e799                	bnez	a5,ffffffffc02016ca <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016be:	00005797          	auipc	a5,0x5
ffffffffc02016c2:	dba7b783          	ld	a5,-582(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016c6:	6f9c                	ld	a5,24(a5)
ffffffffc02016c8:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02016ca:	1141                	addi	sp,sp,-16
ffffffffc02016cc:	e406                	sd	ra,8(sp)
ffffffffc02016ce:	e022                	sd	s0,0(sp)
ffffffffc02016d0:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02016d2:	96eff0ef          	jal	ra,ffffffffc0200840 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02016d6:	00005797          	auipc	a5,0x5
ffffffffc02016da:	da27b783          	ld	a5,-606(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016de:	6f9c                	ld	a5,24(a5)
ffffffffc02016e0:	8522                	mv	a0,s0
ffffffffc02016e2:	9782                	jalr	a5
ffffffffc02016e4:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02016e6:	954ff0ef          	jal	ra,ffffffffc020083a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02016ea:	60a2                	ld	ra,8(sp)
ffffffffc02016ec:	8522                	mv	a0,s0
ffffffffc02016ee:	6402                	ld	s0,0(sp)
ffffffffc02016f0:	0141                	addi	sp,sp,16
ffffffffc02016f2:	8082                	ret

ffffffffc02016f4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016f4:	100027f3          	csrr	a5,sstatus
ffffffffc02016f8:	8b89                	andi	a5,a5,2
ffffffffc02016fa:	e799                	bnez	a5,ffffffffc0201708 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02016fc:	00005797          	auipc	a5,0x5
ffffffffc0201700:	d7c7b783          	ld	a5,-644(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201704:	739c                	ld	a5,32(a5)
ffffffffc0201706:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201708:	1101                	addi	sp,sp,-32
ffffffffc020170a:	ec06                	sd	ra,24(sp)
ffffffffc020170c:	e822                	sd	s0,16(sp)
ffffffffc020170e:	e426                	sd	s1,8(sp)
ffffffffc0201710:	842a                	mv	s0,a0
ffffffffc0201712:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201714:	92cff0ef          	jal	ra,ffffffffc0200840 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201718:	00005797          	auipc	a5,0x5
ffffffffc020171c:	d607b783          	ld	a5,-672(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201720:	739c                	ld	a5,32(a5)
ffffffffc0201722:	85a6                	mv	a1,s1
ffffffffc0201724:	8522                	mv	a0,s0
ffffffffc0201726:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201728:	6442                	ld	s0,16(sp)
ffffffffc020172a:	60e2                	ld	ra,24(sp)
ffffffffc020172c:	64a2                	ld	s1,8(sp)
ffffffffc020172e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201730:	90aff06f          	j	ffffffffc020083a <intr_enable>

ffffffffc0201734 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201734:	100027f3          	csrr	a5,sstatus
ffffffffc0201738:	8b89                	andi	a5,a5,2
ffffffffc020173a:	e799                	bnez	a5,ffffffffc0201748 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020173c:	00005797          	auipc	a5,0x5
ffffffffc0201740:	d3c7b783          	ld	a5,-708(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201744:	779c                	ld	a5,40(a5)
ffffffffc0201746:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201748:	1141                	addi	sp,sp,-16
ffffffffc020174a:	e406                	sd	ra,8(sp)
ffffffffc020174c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020174e:	8f2ff0ef          	jal	ra,ffffffffc0200840 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201752:	00005797          	auipc	a5,0x5
ffffffffc0201756:	d267b783          	ld	a5,-730(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020175a:	779c                	ld	a5,40(a5)
ffffffffc020175c:	9782                	jalr	a5
ffffffffc020175e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201760:	8daff0ef          	jal	ra,ffffffffc020083a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201764:	60a2                	ld	ra,8(sp)
ffffffffc0201766:	8522                	mv	a0,s0
ffffffffc0201768:	6402                	ld	s0,0(sp)
ffffffffc020176a:	0141                	addi	sp,sp,16
ffffffffc020176c:	8082                	ret

ffffffffc020176e <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020176e:	00001797          	auipc	a5,0x1
ffffffffc0201772:	40a78793          	addi	a5,a5,1034 # ffffffffc0202b78 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201776:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201778:	7179                	addi	sp,sp,-48
ffffffffc020177a:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020177c:	00001517          	auipc	a0,0x1
ffffffffc0201780:	43450513          	addi	a0,a0,1076 # ffffffffc0202bb0 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201784:	00005417          	auipc	s0,0x5
ffffffffc0201788:	cf440413          	addi	s0,s0,-780 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc020178c:	f406                	sd	ra,40(sp)
ffffffffc020178e:	ec26                	sd	s1,24(sp)
ffffffffc0201790:	e44e                	sd	s3,8(sp)
ffffffffc0201792:	e84a                	sd	s2,16(sp)
ffffffffc0201794:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201796:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201798:	94dfe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    pmm_manager->init();
ffffffffc020179c:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020179e:	00005497          	auipc	s1,0x5
ffffffffc02017a2:	cf248493          	addi	s1,s1,-782 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017a6:	679c                	ld	a5,8(a5)
ffffffffc02017a8:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017aa:	57f5                	li	a5,-3
ffffffffc02017ac:	07fa                	slli	a5,a5,0x1e
ffffffffc02017ae:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02017b0:	876ff0ef          	jal	ra,ffffffffc0200826 <get_memory_base>
ffffffffc02017b4:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017b6:	87aff0ef          	jal	ra,ffffffffc0200830 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017ba:	16050163          	beqz	a0,ffffffffc020191c <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017be:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02017c0:	00001517          	auipc	a0,0x1
ffffffffc02017c4:	43850513          	addi	a0,a0,1080 # ffffffffc0202bf8 <best_fit_pmm_manager+0x80>
ffffffffc02017c8:	91dfe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017cc:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02017d0:	864e                	mv	a2,s3
ffffffffc02017d2:	fffa0693          	addi	a3,s4,-1
ffffffffc02017d6:	85ca                	mv	a1,s2
ffffffffc02017d8:	00001517          	auipc	a0,0x1
ffffffffc02017dc:	43850513          	addi	a0,a0,1080 # ffffffffc0202c10 <best_fit_pmm_manager+0x98>
ffffffffc02017e0:	905fe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02017e4:	c80007b7          	lui	a5,0xc8000
ffffffffc02017e8:	8652                	mv	a2,s4
ffffffffc02017ea:	0d47e863          	bltu	a5,s4,ffffffffc02018ba <pmm_init+0x14c>
ffffffffc02017ee:	00006797          	auipc	a5,0x6
ffffffffc02017f2:	cb178793          	addi	a5,a5,-847 # ffffffffc020749f <end+0xfff>
ffffffffc02017f6:	757d                	lui	a0,0xfffff
ffffffffc02017f8:	8d7d                	and	a0,a0,a5
ffffffffc02017fa:	8231                	srli	a2,a2,0xc
ffffffffc02017fc:	00005597          	auipc	a1,0x5
ffffffffc0201800:	c6c58593          	addi	a1,a1,-916 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201804:	00005817          	auipc	a6,0x5
ffffffffc0201808:	c6c80813          	addi	a6,a6,-916 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020180c:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020180e:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201812:	000807b7          	lui	a5,0x80
ffffffffc0201816:	02f60663          	beq	a2,a5,ffffffffc0201842 <pmm_init+0xd4>
ffffffffc020181a:	4701                	li	a4,0
ffffffffc020181c:	4781                	li	a5,0
ffffffffc020181e:	4305                	li	t1,1
ffffffffc0201820:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201824:	953a                	add	a0,a0,a4
ffffffffc0201826:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc020182a:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020182e:	6190                	ld	a2,0(a1)
ffffffffc0201830:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201832:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201836:	011606b3          	add	a3,a2,a7
ffffffffc020183a:	02870713          	addi	a4,a4,40
ffffffffc020183e:	fed7e3e3          	bltu	a5,a3,ffffffffc0201824 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201842:	00261693          	slli	a3,a2,0x2
ffffffffc0201846:	96b2                	add	a3,a3,a2
ffffffffc0201848:	fec007b7          	lui	a5,0xfec00
ffffffffc020184c:	97aa                	add	a5,a5,a0
ffffffffc020184e:	068e                	slli	a3,a3,0x3
ffffffffc0201850:	96be                	add	a3,a3,a5
ffffffffc0201852:	c02007b7          	lui	a5,0xc0200
ffffffffc0201856:	0af6e763          	bltu	a3,a5,ffffffffc0201904 <pmm_init+0x196>
ffffffffc020185a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020185c:	77fd                	lui	a5,0xfffff
ffffffffc020185e:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201862:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201864:	04b6ee63          	bltu	a3,a1,ffffffffc02018c0 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201868:	601c                	ld	a5,0(s0)
ffffffffc020186a:	7b9c                	ld	a5,48(a5)
ffffffffc020186c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020186e:	00001517          	auipc	a0,0x1
ffffffffc0201872:	42a50513          	addi	a0,a0,1066 # ffffffffc0202c98 <best_fit_pmm_manager+0x120>
ffffffffc0201876:	86ffe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020187a:	00003597          	auipc	a1,0x3
ffffffffc020187e:	78658593          	addi	a1,a1,1926 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201882:	00005797          	auipc	a5,0x5
ffffffffc0201886:	c0b7b323          	sd	a1,-1018(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020188a:	c02007b7          	lui	a5,0xc0200
ffffffffc020188e:	0af5e363          	bltu	a1,a5,ffffffffc0201934 <pmm_init+0x1c6>
ffffffffc0201892:	6090                	ld	a2,0(s1)
}
ffffffffc0201894:	7402                	ld	s0,32(sp)
ffffffffc0201896:	70a2                	ld	ra,40(sp)
ffffffffc0201898:	64e2                	ld	s1,24(sp)
ffffffffc020189a:	6942                	ld	s2,16(sp)
ffffffffc020189c:	69a2                	ld	s3,8(sp)
ffffffffc020189e:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018a0:	40c58633          	sub	a2,a1,a2
ffffffffc02018a4:	00005797          	auipc	a5,0x5
ffffffffc02018a8:	bcc7be23          	sd	a2,-1060(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018ac:	00001517          	auipc	a0,0x1
ffffffffc02018b0:	40c50513          	addi	a0,a0,1036 # ffffffffc0202cb8 <best_fit_pmm_manager+0x140>
}
ffffffffc02018b4:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018b6:	82ffe06f          	j	ffffffffc02000e4 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018ba:	c8000637          	lui	a2,0xc8000
ffffffffc02018be:	bf05                	j	ffffffffc02017ee <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018c0:	6705                	lui	a4,0x1
ffffffffc02018c2:	177d                	addi	a4,a4,-1
ffffffffc02018c4:	96ba                	add	a3,a3,a4
ffffffffc02018c6:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02018c8:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018cc:	02c7f063          	bgeu	a5,a2,ffffffffc02018ec <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc02018d0:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02018d2:	fff80737          	lui	a4,0xfff80
ffffffffc02018d6:	973e                	add	a4,a4,a5
ffffffffc02018d8:	00271793          	slli	a5,a4,0x2
ffffffffc02018dc:	97ba                	add	a5,a5,a4
ffffffffc02018de:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02018e0:	8d95                	sub	a1,a1,a3
ffffffffc02018e2:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02018e4:	81b1                	srli	a1,a1,0xc
ffffffffc02018e6:	953e                	add	a0,a0,a5
ffffffffc02018e8:	9702                	jalr	a4
}
ffffffffc02018ea:	bfbd                	j	ffffffffc0201868 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02018ec:	00001617          	auipc	a2,0x1
ffffffffc02018f0:	37c60613          	addi	a2,a2,892 # ffffffffc0202c68 <best_fit_pmm_manager+0xf0>
ffffffffc02018f4:	06b00593          	li	a1,107
ffffffffc02018f8:	00001517          	auipc	a0,0x1
ffffffffc02018fc:	39050513          	addi	a0,a0,912 # ffffffffc0202c88 <best_fit_pmm_manager+0x110>
ffffffffc0201900:	adffe0ef          	jal	ra,ffffffffc02003de <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201904:	00001617          	auipc	a2,0x1
ffffffffc0201908:	33c60613          	addi	a2,a2,828 # ffffffffc0202c40 <best_fit_pmm_manager+0xc8>
ffffffffc020190c:	07100593          	li	a1,113
ffffffffc0201910:	00001517          	auipc	a0,0x1
ffffffffc0201914:	2d850513          	addi	a0,a0,728 # ffffffffc0202be8 <best_fit_pmm_manager+0x70>
ffffffffc0201918:	ac7fe0ef          	jal	ra,ffffffffc02003de <__panic>
        panic("DTB memory info not available");
ffffffffc020191c:	00001617          	auipc	a2,0x1
ffffffffc0201920:	2ac60613          	addi	a2,a2,684 # ffffffffc0202bc8 <best_fit_pmm_manager+0x50>
ffffffffc0201924:	05a00593          	li	a1,90
ffffffffc0201928:	00001517          	auipc	a0,0x1
ffffffffc020192c:	2c050513          	addi	a0,a0,704 # ffffffffc0202be8 <best_fit_pmm_manager+0x70>
ffffffffc0201930:	aaffe0ef          	jal	ra,ffffffffc02003de <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201934:	86ae                	mv	a3,a1
ffffffffc0201936:	00001617          	auipc	a2,0x1
ffffffffc020193a:	30a60613          	addi	a2,a2,778 # ffffffffc0202c40 <best_fit_pmm_manager+0xc8>
ffffffffc020193e:	08c00593          	li	a1,140
ffffffffc0201942:	00001517          	auipc	a0,0x1
ffffffffc0201946:	2a650513          	addi	a0,a0,678 # ffffffffc0202be8 <best_fit_pmm_manager+0x70>
ffffffffc020194a:	a95fe0ef          	jal	ra,ffffffffc02003de <__panic>

ffffffffc020194e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020194e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201952:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201954:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201958:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020195a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020195e:	f022                	sd	s0,32(sp)
ffffffffc0201960:	ec26                	sd	s1,24(sp)
ffffffffc0201962:	e84a                	sd	s2,16(sp)
ffffffffc0201964:	f406                	sd	ra,40(sp)
ffffffffc0201966:	e44e                	sd	s3,8(sp)
ffffffffc0201968:	84aa                	mv	s1,a0
ffffffffc020196a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020196c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201970:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201972:	03067e63          	bgeu	a2,a6,ffffffffc02019ae <printnum+0x60>
ffffffffc0201976:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201978:	00805763          	blez	s0,ffffffffc0201986 <printnum+0x38>
ffffffffc020197c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020197e:	85ca                	mv	a1,s2
ffffffffc0201980:	854e                	mv	a0,s3
ffffffffc0201982:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201984:	fc65                	bnez	s0,ffffffffc020197c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201986:	1a02                	slli	s4,s4,0x20
ffffffffc0201988:	00001797          	auipc	a5,0x1
ffffffffc020198c:	37078793          	addi	a5,a5,880 # ffffffffc0202cf8 <best_fit_pmm_manager+0x180>
ffffffffc0201990:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201994:	9a3e                	add	s4,s4,a5
}
ffffffffc0201996:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201998:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020199c:	70a2                	ld	ra,40(sp)
ffffffffc020199e:	69a2                	ld	s3,8(sp)
ffffffffc02019a0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019a2:	85ca                	mv	a1,s2
ffffffffc02019a4:	87a6                	mv	a5,s1
}
ffffffffc02019a6:	6942                	ld	s2,16(sp)
ffffffffc02019a8:	64e2                	ld	s1,24(sp)
ffffffffc02019aa:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019ac:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019ae:	03065633          	divu	a2,a2,a6
ffffffffc02019b2:	8722                	mv	a4,s0
ffffffffc02019b4:	f9bff0ef          	jal	ra,ffffffffc020194e <printnum>
ffffffffc02019b8:	b7f9                	j	ffffffffc0201986 <printnum+0x38>

ffffffffc02019ba <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019ba:	7119                	addi	sp,sp,-128
ffffffffc02019bc:	f4a6                	sd	s1,104(sp)
ffffffffc02019be:	f0ca                	sd	s2,96(sp)
ffffffffc02019c0:	ecce                	sd	s3,88(sp)
ffffffffc02019c2:	e8d2                	sd	s4,80(sp)
ffffffffc02019c4:	e4d6                	sd	s5,72(sp)
ffffffffc02019c6:	e0da                	sd	s6,64(sp)
ffffffffc02019c8:	fc5e                	sd	s7,56(sp)
ffffffffc02019ca:	f06a                	sd	s10,32(sp)
ffffffffc02019cc:	fc86                	sd	ra,120(sp)
ffffffffc02019ce:	f8a2                	sd	s0,112(sp)
ffffffffc02019d0:	f862                	sd	s8,48(sp)
ffffffffc02019d2:	f466                	sd	s9,40(sp)
ffffffffc02019d4:	ec6e                	sd	s11,24(sp)
ffffffffc02019d6:	892a                	mv	s2,a0
ffffffffc02019d8:	84ae                	mv	s1,a1
ffffffffc02019da:	8d32                	mv	s10,a2
ffffffffc02019dc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019de:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02019e2:	5b7d                	li	s6,-1
ffffffffc02019e4:	00001a97          	auipc	s5,0x1
ffffffffc02019e8:	348a8a93          	addi	s5,s5,840 # ffffffffc0202d2c <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019ec:	00001b97          	auipc	s7,0x1
ffffffffc02019f0:	51cb8b93          	addi	s7,s7,1308 # ffffffffc0202f08 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019f4:	000d4503          	lbu	a0,0(s10)
ffffffffc02019f8:	001d0413          	addi	s0,s10,1
ffffffffc02019fc:	01350a63          	beq	a0,s3,ffffffffc0201a10 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a00:	c121                	beqz	a0,ffffffffc0201a40 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a02:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a04:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a06:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a08:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a0c:	ff351ae3          	bne	a0,s3,ffffffffc0201a00 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a10:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a14:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a18:	4c81                	li	s9,0
ffffffffc0201a1a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a1c:	5c7d                	li	s8,-1
ffffffffc0201a1e:	5dfd                	li	s11,-1
ffffffffc0201a20:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a24:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a26:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a2a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a2e:	00140d13          	addi	s10,s0,1
ffffffffc0201a32:	04b56263          	bltu	a0,a1,ffffffffc0201a76 <vprintfmt+0xbc>
ffffffffc0201a36:	058a                	slli	a1,a1,0x2
ffffffffc0201a38:	95d6                	add	a1,a1,s5
ffffffffc0201a3a:	4194                	lw	a3,0(a1)
ffffffffc0201a3c:	96d6                	add	a3,a3,s5
ffffffffc0201a3e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a40:	70e6                	ld	ra,120(sp)
ffffffffc0201a42:	7446                	ld	s0,112(sp)
ffffffffc0201a44:	74a6                	ld	s1,104(sp)
ffffffffc0201a46:	7906                	ld	s2,96(sp)
ffffffffc0201a48:	69e6                	ld	s3,88(sp)
ffffffffc0201a4a:	6a46                	ld	s4,80(sp)
ffffffffc0201a4c:	6aa6                	ld	s5,72(sp)
ffffffffc0201a4e:	6b06                	ld	s6,64(sp)
ffffffffc0201a50:	7be2                	ld	s7,56(sp)
ffffffffc0201a52:	7c42                	ld	s8,48(sp)
ffffffffc0201a54:	7ca2                	ld	s9,40(sp)
ffffffffc0201a56:	7d02                	ld	s10,32(sp)
ffffffffc0201a58:	6de2                	ld	s11,24(sp)
ffffffffc0201a5a:	6109                	addi	sp,sp,128
ffffffffc0201a5c:	8082                	ret
            padc = '0';
ffffffffc0201a5e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a60:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a64:	846a                	mv	s0,s10
ffffffffc0201a66:	00140d13          	addi	s10,s0,1
ffffffffc0201a6a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a6e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a72:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a36 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201a76:	85a6                	mv	a1,s1
ffffffffc0201a78:	02500513          	li	a0,37
ffffffffc0201a7c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a7e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a82:	8d22                	mv	s10,s0
ffffffffc0201a84:	f73788e3          	beq	a5,s3,ffffffffc02019f4 <vprintfmt+0x3a>
ffffffffc0201a88:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201a8c:	1d7d                	addi	s10,s10,-1
ffffffffc0201a8e:	ff379de3          	bne	a5,s3,ffffffffc0201a88 <vprintfmt+0xce>
ffffffffc0201a92:	b78d                	j	ffffffffc02019f4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201a94:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201a98:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a9c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201a9e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201aa2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201aa6:	02d86463          	bltu	a6,a3,ffffffffc0201ace <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201aaa:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201aae:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201ab2:	0186873b          	addw	a4,a3,s8
ffffffffc0201ab6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201aba:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201abc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201ac0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201ac2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201ac6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201aca:	fed870e3          	bgeu	a6,a3,ffffffffc0201aaa <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201ace:	f40ddce3          	bgez	s11,ffffffffc0201a26 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201ad2:	8de2                	mv	s11,s8
ffffffffc0201ad4:	5c7d                	li	s8,-1
ffffffffc0201ad6:	bf81                	j	ffffffffc0201a26 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201ad8:	fffdc693          	not	a3,s11
ffffffffc0201adc:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ade:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae2:	00144603          	lbu	a2,1(s0)
ffffffffc0201ae6:	2d81                	sext.w	s11,s11
ffffffffc0201ae8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201aea:	bf35                	j	ffffffffc0201a26 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201aec:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201af0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201af4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201af6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201af8:	bfd9                	j	ffffffffc0201ace <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201afa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201afc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b00:	01174463          	blt	a4,a7,ffffffffc0201b08 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b04:	1a088e63          	beqz	a7,ffffffffc0201cc0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b08:	000a3603          	ld	a2,0(s4)
ffffffffc0201b0c:	46c1                	li	a3,16
ffffffffc0201b0e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b10:	2781                	sext.w	a5,a5
ffffffffc0201b12:	876e                	mv	a4,s11
ffffffffc0201b14:	85a6                	mv	a1,s1
ffffffffc0201b16:	854a                	mv	a0,s2
ffffffffc0201b18:	e37ff0ef          	jal	ra,ffffffffc020194e <printnum>
            break;
ffffffffc0201b1c:	bde1                	j	ffffffffc02019f4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b1e:	000a2503          	lw	a0,0(s4)
ffffffffc0201b22:	85a6                	mv	a1,s1
ffffffffc0201b24:	0a21                	addi	s4,s4,8
ffffffffc0201b26:	9902                	jalr	s2
            break;
ffffffffc0201b28:	b5f1                	j	ffffffffc02019f4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b2a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b2c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b30:	01174463          	blt	a4,a7,ffffffffc0201b38 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b34:	18088163          	beqz	a7,ffffffffc0201cb6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b38:	000a3603          	ld	a2,0(s4)
ffffffffc0201b3c:	46a9                	li	a3,10
ffffffffc0201b3e:	8a2e                	mv	s4,a1
ffffffffc0201b40:	bfc1                	j	ffffffffc0201b10 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b42:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b46:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b48:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b4a:	bdf1                	j	ffffffffc0201a26 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b4c:	85a6                	mv	a1,s1
ffffffffc0201b4e:	02500513          	li	a0,37
ffffffffc0201b52:	9902                	jalr	s2
            break;
ffffffffc0201b54:	b545                	j	ffffffffc02019f4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b56:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b5a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b5c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b5e:	b5e1                	j	ffffffffc0201a26 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b60:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b62:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b66:	01174463          	blt	a4,a7,ffffffffc0201b6e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201b6a:	14088163          	beqz	a7,ffffffffc0201cac <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b6e:	000a3603          	ld	a2,0(s4)
ffffffffc0201b72:	46a1                	li	a3,8
ffffffffc0201b74:	8a2e                	mv	s4,a1
ffffffffc0201b76:	bf69                	j	ffffffffc0201b10 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201b78:	03000513          	li	a0,48
ffffffffc0201b7c:	85a6                	mv	a1,s1
ffffffffc0201b7e:	e03e                	sd	a5,0(sp)
ffffffffc0201b80:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201b82:	85a6                	mv	a1,s1
ffffffffc0201b84:	07800513          	li	a0,120
ffffffffc0201b88:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b8a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b8c:	6782                	ld	a5,0(sp)
ffffffffc0201b8e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b90:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201b94:	bfb5                	j	ffffffffc0201b10 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b96:	000a3403          	ld	s0,0(s4)
ffffffffc0201b9a:	008a0713          	addi	a4,s4,8
ffffffffc0201b9e:	e03a                	sd	a4,0(sp)
ffffffffc0201ba0:	14040263          	beqz	s0,ffffffffc0201ce4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201ba4:	0fb05763          	blez	s11,ffffffffc0201c92 <vprintfmt+0x2d8>
ffffffffc0201ba8:	02d00693          	li	a3,45
ffffffffc0201bac:	0cd79163          	bne	a5,a3,ffffffffc0201c6e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bb0:	00044783          	lbu	a5,0(s0)
ffffffffc0201bb4:	0007851b          	sext.w	a0,a5
ffffffffc0201bb8:	cf85                	beqz	a5,ffffffffc0201bf0 <vprintfmt+0x236>
ffffffffc0201bba:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bbe:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bc2:	000c4563          	bltz	s8,ffffffffc0201bcc <vprintfmt+0x212>
ffffffffc0201bc6:	3c7d                	addiw	s8,s8,-1
ffffffffc0201bc8:	036c0263          	beq	s8,s6,ffffffffc0201bec <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201bcc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bce:	0e0c8e63          	beqz	s9,ffffffffc0201cca <vprintfmt+0x310>
ffffffffc0201bd2:	3781                	addiw	a5,a5,-32
ffffffffc0201bd4:	0ef47b63          	bgeu	s0,a5,ffffffffc0201cca <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201bd8:	03f00513          	li	a0,63
ffffffffc0201bdc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bde:	000a4783          	lbu	a5,0(s4)
ffffffffc0201be2:	3dfd                	addiw	s11,s11,-1
ffffffffc0201be4:	0a05                	addi	s4,s4,1
ffffffffc0201be6:	0007851b          	sext.w	a0,a5
ffffffffc0201bea:	ffe1                	bnez	a5,ffffffffc0201bc2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201bec:	01b05963          	blez	s11,ffffffffc0201bfe <vprintfmt+0x244>
ffffffffc0201bf0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201bf2:	85a6                	mv	a1,s1
ffffffffc0201bf4:	02000513          	li	a0,32
ffffffffc0201bf8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201bfa:	fe0d9be3          	bnez	s11,ffffffffc0201bf0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bfe:	6a02                	ld	s4,0(sp)
ffffffffc0201c00:	bbd5                	j	ffffffffc02019f4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c02:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c04:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c08:	01174463          	blt	a4,a7,ffffffffc0201c10 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c0c:	08088d63          	beqz	a7,ffffffffc0201ca6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c10:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c14:	0a044d63          	bltz	s0,ffffffffc0201cce <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c18:	8622                	mv	a2,s0
ffffffffc0201c1a:	8a66                	mv	s4,s9
ffffffffc0201c1c:	46a9                	li	a3,10
ffffffffc0201c1e:	bdcd                	j	ffffffffc0201b10 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c20:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c24:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c26:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c28:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c2c:	8fb5                	xor	a5,a5,a3
ffffffffc0201c2e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c32:	02d74163          	blt	a4,a3,ffffffffc0201c54 <vprintfmt+0x29a>
ffffffffc0201c36:	00369793          	slli	a5,a3,0x3
ffffffffc0201c3a:	97de                	add	a5,a5,s7
ffffffffc0201c3c:	639c                	ld	a5,0(a5)
ffffffffc0201c3e:	cb99                	beqz	a5,ffffffffc0201c54 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c40:	86be                	mv	a3,a5
ffffffffc0201c42:	00001617          	auipc	a2,0x1
ffffffffc0201c46:	0e660613          	addi	a2,a2,230 # ffffffffc0202d28 <best_fit_pmm_manager+0x1b0>
ffffffffc0201c4a:	85a6                	mv	a1,s1
ffffffffc0201c4c:	854a                	mv	a0,s2
ffffffffc0201c4e:	0ce000ef          	jal	ra,ffffffffc0201d1c <printfmt>
ffffffffc0201c52:	b34d                	j	ffffffffc02019f4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c54:	00001617          	auipc	a2,0x1
ffffffffc0201c58:	0c460613          	addi	a2,a2,196 # ffffffffc0202d18 <best_fit_pmm_manager+0x1a0>
ffffffffc0201c5c:	85a6                	mv	a1,s1
ffffffffc0201c5e:	854a                	mv	a0,s2
ffffffffc0201c60:	0bc000ef          	jal	ra,ffffffffc0201d1c <printfmt>
ffffffffc0201c64:	bb41                	j	ffffffffc02019f4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201c66:	00001417          	auipc	s0,0x1
ffffffffc0201c6a:	0aa40413          	addi	s0,s0,170 # ffffffffc0202d10 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c6e:	85e2                	mv	a1,s8
ffffffffc0201c70:	8522                	mv	a0,s0
ffffffffc0201c72:	e43e                	sd	a5,8(sp)
ffffffffc0201c74:	200000ef          	jal	ra,ffffffffc0201e74 <strnlen>
ffffffffc0201c78:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201c7c:	01b05b63          	blez	s11,ffffffffc0201c92 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201c80:	67a2                	ld	a5,8(sp)
ffffffffc0201c82:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c86:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201c88:	85a6                	mv	a1,s1
ffffffffc0201c8a:	8552                	mv	a0,s4
ffffffffc0201c8c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c8e:	fe0d9ce3          	bnez	s11,ffffffffc0201c86 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c92:	00044783          	lbu	a5,0(s0)
ffffffffc0201c96:	00140a13          	addi	s4,s0,1
ffffffffc0201c9a:	0007851b          	sext.w	a0,a5
ffffffffc0201c9e:	d3a5                	beqz	a5,ffffffffc0201bfe <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ca0:	05e00413          	li	s0,94
ffffffffc0201ca4:	bf39                	j	ffffffffc0201bc2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201ca6:	000a2403          	lw	s0,0(s4)
ffffffffc0201caa:	b7ad                	j	ffffffffc0201c14 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201cac:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cb0:	46a1                	li	a3,8
ffffffffc0201cb2:	8a2e                	mv	s4,a1
ffffffffc0201cb4:	bdb1                	j	ffffffffc0201b10 <vprintfmt+0x156>
ffffffffc0201cb6:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cba:	46a9                	li	a3,10
ffffffffc0201cbc:	8a2e                	mv	s4,a1
ffffffffc0201cbe:	bd89                	j	ffffffffc0201b10 <vprintfmt+0x156>
ffffffffc0201cc0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cc4:	46c1                	li	a3,16
ffffffffc0201cc6:	8a2e                	mv	s4,a1
ffffffffc0201cc8:	b5a1                	j	ffffffffc0201b10 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201cca:	9902                	jalr	s2
ffffffffc0201ccc:	bf09                	j	ffffffffc0201bde <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201cce:	85a6                	mv	a1,s1
ffffffffc0201cd0:	02d00513          	li	a0,45
ffffffffc0201cd4:	e03e                	sd	a5,0(sp)
ffffffffc0201cd6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201cd8:	6782                	ld	a5,0(sp)
ffffffffc0201cda:	8a66                	mv	s4,s9
ffffffffc0201cdc:	40800633          	neg	a2,s0
ffffffffc0201ce0:	46a9                	li	a3,10
ffffffffc0201ce2:	b53d                	j	ffffffffc0201b10 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201ce4:	03b05163          	blez	s11,ffffffffc0201d06 <vprintfmt+0x34c>
ffffffffc0201ce8:	02d00693          	li	a3,45
ffffffffc0201cec:	f6d79de3          	bne	a5,a3,ffffffffc0201c66 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201cf0:	00001417          	auipc	s0,0x1
ffffffffc0201cf4:	02040413          	addi	s0,s0,32 # ffffffffc0202d10 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cf8:	02800793          	li	a5,40
ffffffffc0201cfc:	02800513          	li	a0,40
ffffffffc0201d00:	00140a13          	addi	s4,s0,1
ffffffffc0201d04:	bd6d                	j	ffffffffc0201bbe <vprintfmt+0x204>
ffffffffc0201d06:	00001a17          	auipc	s4,0x1
ffffffffc0201d0a:	00ba0a13          	addi	s4,s4,11 # ffffffffc0202d11 <best_fit_pmm_manager+0x199>
ffffffffc0201d0e:	02800513          	li	a0,40
ffffffffc0201d12:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d16:	05e00413          	li	s0,94
ffffffffc0201d1a:	b565                	j	ffffffffc0201bc2 <vprintfmt+0x208>

ffffffffc0201d1c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d1c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d1e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d22:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d24:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d26:	ec06                	sd	ra,24(sp)
ffffffffc0201d28:	f83a                	sd	a4,48(sp)
ffffffffc0201d2a:	fc3e                	sd	a5,56(sp)
ffffffffc0201d2c:	e0c2                	sd	a6,64(sp)
ffffffffc0201d2e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d30:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d32:	c89ff0ef          	jal	ra,ffffffffc02019ba <vprintfmt>
}
ffffffffc0201d36:	60e2                	ld	ra,24(sp)
ffffffffc0201d38:	6161                	addi	sp,sp,80
ffffffffc0201d3a:	8082                	ret

ffffffffc0201d3c <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d3c:	715d                	addi	sp,sp,-80
ffffffffc0201d3e:	e486                	sd	ra,72(sp)
ffffffffc0201d40:	e0a6                	sd	s1,64(sp)
ffffffffc0201d42:	fc4a                	sd	s2,56(sp)
ffffffffc0201d44:	f84e                	sd	s3,48(sp)
ffffffffc0201d46:	f452                	sd	s4,40(sp)
ffffffffc0201d48:	f056                	sd	s5,32(sp)
ffffffffc0201d4a:	ec5a                	sd	s6,24(sp)
ffffffffc0201d4c:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d4e:	c901                	beqz	a0,ffffffffc0201d5e <readline+0x22>
ffffffffc0201d50:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d52:	00001517          	auipc	a0,0x1
ffffffffc0201d56:	fd650513          	addi	a0,a0,-42 # ffffffffc0202d28 <best_fit_pmm_manager+0x1b0>
ffffffffc0201d5a:	b8afe0ef          	jal	ra,ffffffffc02000e4 <cprintf>
readline(const char *prompt) {
ffffffffc0201d5e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d60:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d62:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d64:	4aa9                	li	s5,10
ffffffffc0201d66:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201d68:	00004b97          	auipc	s7,0x4
ffffffffc0201d6c:	2d8b8b93          	addi	s7,s7,728 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d70:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201d74:	be8fe0ef          	jal	ra,ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201d78:	00054a63          	bltz	a0,ffffffffc0201d8c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d7c:	00a95a63          	bge	s2,a0,ffffffffc0201d90 <readline+0x54>
ffffffffc0201d80:	029a5263          	bge	s4,s1,ffffffffc0201da4 <readline+0x68>
        c = getchar();
ffffffffc0201d84:	bd8fe0ef          	jal	ra,ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201d88:	fe055ae3          	bgez	a0,ffffffffc0201d7c <readline+0x40>
            return NULL;
ffffffffc0201d8c:	4501                	li	a0,0
ffffffffc0201d8e:	a091                	j	ffffffffc0201dd2 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201d90:	03351463          	bne	a0,s3,ffffffffc0201db8 <readline+0x7c>
ffffffffc0201d94:	e8a9                	bnez	s1,ffffffffc0201de6 <readline+0xaa>
        c = getchar();
ffffffffc0201d96:	bc6fe0ef          	jal	ra,ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201d9a:	fe0549e3          	bltz	a0,ffffffffc0201d8c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d9e:	fea959e3          	bge	s2,a0,ffffffffc0201d90 <readline+0x54>
ffffffffc0201da2:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201da4:	e42a                	sd	a0,8(sp)
ffffffffc0201da6:	b74fe0ef          	jal	ra,ffffffffc020011a <cputchar>
            buf[i ++] = c;
ffffffffc0201daa:	6522                	ld	a0,8(sp)
ffffffffc0201dac:	009b87b3          	add	a5,s7,s1
ffffffffc0201db0:	2485                	addiw	s1,s1,1
ffffffffc0201db2:	00a78023          	sb	a0,0(a5)
ffffffffc0201db6:	bf7d                	j	ffffffffc0201d74 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201db8:	01550463          	beq	a0,s5,ffffffffc0201dc0 <readline+0x84>
ffffffffc0201dbc:	fb651ce3          	bne	a0,s6,ffffffffc0201d74 <readline+0x38>
            cputchar(c);
ffffffffc0201dc0:	b5afe0ef          	jal	ra,ffffffffc020011a <cputchar>
            buf[i] = '\0';
ffffffffc0201dc4:	00004517          	auipc	a0,0x4
ffffffffc0201dc8:	27c50513          	addi	a0,a0,636 # ffffffffc0206040 <buf>
ffffffffc0201dcc:	94aa                	add	s1,s1,a0
ffffffffc0201dce:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201dd2:	60a6                	ld	ra,72(sp)
ffffffffc0201dd4:	6486                	ld	s1,64(sp)
ffffffffc0201dd6:	7962                	ld	s2,56(sp)
ffffffffc0201dd8:	79c2                	ld	s3,48(sp)
ffffffffc0201dda:	7a22                	ld	s4,40(sp)
ffffffffc0201ddc:	7a82                	ld	s5,32(sp)
ffffffffc0201dde:	6b62                	ld	s6,24(sp)
ffffffffc0201de0:	6bc2                	ld	s7,16(sp)
ffffffffc0201de2:	6161                	addi	sp,sp,80
ffffffffc0201de4:	8082                	ret
            cputchar(c);
ffffffffc0201de6:	4521                	li	a0,8
ffffffffc0201de8:	b32fe0ef          	jal	ra,ffffffffc020011a <cputchar>
            i --;
ffffffffc0201dec:	34fd                	addiw	s1,s1,-1
ffffffffc0201dee:	b759                	j	ffffffffc0201d74 <readline+0x38>

ffffffffc0201df0 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201df0:	4781                	li	a5,0
ffffffffc0201df2:	00004717          	auipc	a4,0x4
ffffffffc0201df6:	22673703          	ld	a4,550(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dfa:	88ba                	mv	a7,a4
ffffffffc0201dfc:	852a                	mv	a0,a0
ffffffffc0201dfe:	85be                	mv	a1,a5
ffffffffc0201e00:	863e                	mv	a2,a5
ffffffffc0201e02:	00000073          	ecall
ffffffffc0201e06:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e08:	8082                	ret

ffffffffc0201e0a <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e0a:	4781                	li	a5,0
ffffffffc0201e0c:	00004717          	auipc	a4,0x4
ffffffffc0201e10:	68c73703          	ld	a4,1676(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201e14:	88ba                	mv	a7,a4
ffffffffc0201e16:	852a                	mv	a0,a0
ffffffffc0201e18:	85be                	mv	a1,a5
ffffffffc0201e1a:	863e                	mv	a2,a5
ffffffffc0201e1c:	00000073          	ecall
ffffffffc0201e20:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e22:	8082                	ret

ffffffffc0201e24 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e24:	4501                	li	a0,0
ffffffffc0201e26:	00004797          	auipc	a5,0x4
ffffffffc0201e2a:	1ea7b783          	ld	a5,490(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e2e:	88be                	mv	a7,a5
ffffffffc0201e30:	852a                	mv	a0,a0
ffffffffc0201e32:	85aa                	mv	a1,a0
ffffffffc0201e34:	862a                	mv	a2,a0
ffffffffc0201e36:	00000073          	ecall
ffffffffc0201e3a:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e3c:	2501                	sext.w	a0,a0
ffffffffc0201e3e:	8082                	ret

ffffffffc0201e40 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e40:	4781                	li	a5,0
ffffffffc0201e42:	00004717          	auipc	a4,0x4
ffffffffc0201e46:	1de73703          	ld	a4,478(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e4a:	88ba                	mv	a7,a4
ffffffffc0201e4c:	853e                	mv	a0,a5
ffffffffc0201e4e:	85be                	mv	a1,a5
ffffffffc0201e50:	863e                	mv	a2,a5
ffffffffc0201e52:	00000073          	ecall
ffffffffc0201e56:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
}
ffffffffc0201e58:	8082                	ret

ffffffffc0201e5a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e5a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e5e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e60:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e62:	cb81                	beqz	a5,ffffffffc0201e72 <strlen+0x18>
        cnt ++;
ffffffffc0201e64:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e66:	00a707b3          	add	a5,a4,a0
ffffffffc0201e6a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e6e:	fbfd                	bnez	a5,ffffffffc0201e64 <strlen+0xa>
ffffffffc0201e70:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e72:	8082                	ret

ffffffffc0201e74 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e74:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e76:	e589                	bnez	a1,ffffffffc0201e80 <strnlen+0xc>
ffffffffc0201e78:	a811                	j	ffffffffc0201e8c <strnlen+0x18>
        cnt ++;
ffffffffc0201e7a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e7c:	00f58863          	beq	a1,a5,ffffffffc0201e8c <strnlen+0x18>
ffffffffc0201e80:	00f50733          	add	a4,a0,a5
ffffffffc0201e84:	00074703          	lbu	a4,0(a4)
ffffffffc0201e88:	fb6d                	bnez	a4,ffffffffc0201e7a <strnlen+0x6>
ffffffffc0201e8a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e8c:	852e                	mv	a0,a1
ffffffffc0201e8e:	8082                	ret

ffffffffc0201e90 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e90:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e94:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e98:	cb89                	beqz	a5,ffffffffc0201eaa <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201e9a:	0505                	addi	a0,a0,1
ffffffffc0201e9c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e9e:	fee789e3          	beq	a5,a4,ffffffffc0201e90 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ea2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ea6:	9d19                	subw	a0,a0,a4
ffffffffc0201ea8:	8082                	ret
ffffffffc0201eaa:	4501                	li	a0,0
ffffffffc0201eac:	bfed                	j	ffffffffc0201ea6 <strcmp+0x16>

ffffffffc0201eae <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201eae:	c20d                	beqz	a2,ffffffffc0201ed0 <strncmp+0x22>
ffffffffc0201eb0:	962e                	add	a2,a2,a1
ffffffffc0201eb2:	a031                	j	ffffffffc0201ebe <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201eb4:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201eb6:	00e79a63          	bne	a5,a4,ffffffffc0201eca <strncmp+0x1c>
ffffffffc0201eba:	00b60b63          	beq	a2,a1,ffffffffc0201ed0 <strncmp+0x22>
ffffffffc0201ebe:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ec2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ec4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201ec8:	f7f5                	bnez	a5,ffffffffc0201eb4 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eca:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201ece:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ed0:	4501                	li	a0,0
ffffffffc0201ed2:	8082                	ret

ffffffffc0201ed4 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201ed4:	00054783          	lbu	a5,0(a0)
ffffffffc0201ed8:	c799                	beqz	a5,ffffffffc0201ee6 <strchr+0x12>
        if (*s == c) {
ffffffffc0201eda:	00f58763          	beq	a1,a5,ffffffffc0201ee8 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201ede:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201ee2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201ee4:	fbfd                	bnez	a5,ffffffffc0201eda <strchr+0x6>
    }
    return NULL;
ffffffffc0201ee6:	4501                	li	a0,0
}
ffffffffc0201ee8:	8082                	ret

ffffffffc0201eea <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201eea:	ca01                	beqz	a2,ffffffffc0201efa <memset+0x10>
ffffffffc0201eec:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201eee:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ef0:	0785                	addi	a5,a5,1
ffffffffc0201ef2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201ef6:	fec79de3          	bne	a5,a2,ffffffffc0201ef0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201efa:	8082                	ret
