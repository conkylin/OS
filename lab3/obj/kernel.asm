
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
ffffffffc020006c:	6af010ef          	jal	ra,ffffffffc0201f1a <memset>
    dtb_init();
ffffffffc0200070:	40e000ef          	jal	ra,ffffffffc020047e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3fc000ef          	jal	ra,ffffffffc0200470 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	eb850513          	addi	a0,a0,-328 # ffffffffc0201f30 <etext+0x4>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	0dc000ef          	jal	ra,ffffffffc0200160 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b2000ef          	jal	ra,ffffffffc020083a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	712010ef          	jal	ra,ffffffffc020179e <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7aa000ef          	jal	ra,ffffffffc020083a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	39a000ef          	jal	ra,ffffffffc020042e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	796000ef          	jal	ra,ffffffffc020082e <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	3cc000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	11f010ef          	jal	ra,ffffffffc02019ea <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	0e9010ef          	jal	ra,ffffffffc02019ea <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	a695                	j	ffffffffc0200472 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	34c000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	336000ef          	jal	ra,ffffffffc0200472 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	326000ef          	jal	ra,ffffffffc020047a <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200160:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200162:	00002517          	auipc	a0,0x2
ffffffffc0200166:	dee50513          	addi	a0,a0,-530 # ffffffffc0201f50 <etext+0x24>
void print_kerninfo(void) {
ffffffffc020016a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016c:	f6dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200170:	00000597          	auipc	a1,0x0
ffffffffc0200174:	ee458593          	addi	a1,a1,-284 # ffffffffc0200054 <kern_init>
ffffffffc0200178:	00002517          	auipc	a0,0x2
ffffffffc020017c:	df850513          	addi	a0,a0,-520 # ffffffffc0201f70 <etext+0x44>
ffffffffc0200180:	f59ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200184:	00002597          	auipc	a1,0x2
ffffffffc0200188:	da858593          	addi	a1,a1,-600 # ffffffffc0201f2c <etext>
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	e0450513          	addi	a0,a0,-508 # ffffffffc0201f90 <etext+0x64>
ffffffffc0200194:	f45ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200198:	00006597          	auipc	a1,0x6
ffffffffc020019c:	e9058593          	addi	a1,a1,-368 # ffffffffc0206028 <free_area>
ffffffffc02001a0:	00002517          	auipc	a0,0x2
ffffffffc02001a4:	e1050513          	addi	a0,a0,-496 # ffffffffc0201fb0 <etext+0x84>
ffffffffc02001a8:	f31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ac:	00006597          	auipc	a1,0x6
ffffffffc02001b0:	2f458593          	addi	a1,a1,756 # ffffffffc02064a0 <end>
ffffffffc02001b4:	00002517          	auipc	a0,0x2
ffffffffc02001b8:	e1c50513          	addi	a0,a0,-484 # ffffffffc0201fd0 <etext+0xa4>
ffffffffc02001bc:	f1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c0:	00006597          	auipc	a1,0x6
ffffffffc02001c4:	6df58593          	addi	a1,a1,1759 # ffffffffc020689f <end+0x3ff>
ffffffffc02001c8:	00000797          	auipc	a5,0x0
ffffffffc02001cc:	e8c78793          	addi	a5,a5,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d4:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001d8:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001de:	95be                	add	a1,a1,a5
ffffffffc02001e0:	85a9                	srai	a1,a1,0xa
ffffffffc02001e2:	00002517          	auipc	a0,0x2
ffffffffc02001e6:	e0e50513          	addi	a0,a0,-498 # ffffffffc0201ff0 <etext+0xc4>
}
ffffffffc02001ea:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ec:	b5f5                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001ee <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ee:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	e3060613          	addi	a2,a2,-464 # ffffffffc0202020 <etext+0xf4>
ffffffffc02001f8:	04d00593          	li	a1,77
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	e3c50513          	addi	a0,a0,-452 # ffffffffc0202038 <etext+0x10c>
void print_stackframe(void) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200206:	1cc000ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020020a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	e4460613          	addi	a2,a2,-444 # ffffffffc0202050 <etext+0x124>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	e5c58593          	addi	a1,a1,-420 # ffffffffc0202070 <etext+0x144>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	e5c50513          	addi	a0,a0,-420 # ffffffffc0202078 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200224:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200226:	eb3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	e5e60613          	addi	a2,a2,-418 # ffffffffc0202088 <etext+0x15c>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	e7e58593          	addi	a1,a1,-386 # ffffffffc02020b0 <etext+0x184>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	e3e50513          	addi	a0,a0,-450 # ffffffffc0202078 <etext+0x14c>
ffffffffc0200242:	e97ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	e7a60613          	addi	a2,a2,-390 # ffffffffc02020c0 <etext+0x194>
ffffffffc020024e:	00002597          	auipc	a1,0x2
ffffffffc0200252:	e9258593          	addi	a1,a1,-366 # ffffffffc02020e0 <etext+0x1b4>
ffffffffc0200256:	00002517          	auipc	a0,0x2
ffffffffc020025a:	e2250513          	addi	a0,a0,-478 # ffffffffc0202078 <etext+0x14c>
ffffffffc020025e:	e7bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026a:	1141                	addi	sp,sp,-16
ffffffffc020026c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020026e:	ef3ff0ef          	jal	ra,ffffffffc0200160 <print_kerninfo>
    return 0;
}
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020027e:	f71ff0ef          	jal	ra,ffffffffc02001ee <print_stackframe>
    return 0;
}
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028a:	7115                	addi	sp,sp,-224
ffffffffc020028c:	ed5e                	sd	s7,152(sp)
ffffffffc020028e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	e6050513          	addi	a0,a0,-416 # ffffffffc02020f0 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc0200298:	ed86                	sd	ra,216(sp)
ffffffffc020029a:	e9a2                	sd	s0,208(sp)
ffffffffc020029c:	e5a6                	sd	s1,200(sp)
ffffffffc020029e:	e1ca                	sd	s2,192(sp)
ffffffffc02002a0:	fd4e                	sd	s3,184(sp)
ffffffffc02002a2:	f952                	sd	s4,176(sp)
ffffffffc02002a4:	f556                	sd	s5,168(sp)
ffffffffc02002a6:	f15a                	sd	s6,160(sp)
ffffffffc02002a8:	e962                	sd	s8,144(sp)
ffffffffc02002aa:	e566                	sd	s9,136(sp)
ffffffffc02002ac:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ae:	e2bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	e6650513          	addi	a0,a0,-410 # ffffffffc0202118 <etext+0x1ec>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002be:	000b8563          	beqz	s7,ffffffffc02002c8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c2:	855e                	mv	a0,s7
ffffffffc02002c4:	756000ef          	jal	ra,ffffffffc0200a1a <print_trapframe>
ffffffffc02002c8:	00002c17          	auipc	s8,0x2
ffffffffc02002cc:	ec0c0c13          	addi	s8,s8,-320 # ffffffffc0202188 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d0:	00002917          	auipc	s2,0x2
ffffffffc02002d4:	e7090913          	addi	s2,s2,-400 # ffffffffc0202140 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00002497          	auipc	s1,0x2
ffffffffc02002dc:	e7048493          	addi	s1,s1,-400 # ffffffffc0202148 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002e0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e2:	00002b17          	auipc	s6,0x2
ffffffffc02002e6:	e6eb0b13          	addi	s6,s6,-402 # ffffffffc0202150 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002ea:	00002a17          	auipc	s4,0x2
ffffffffc02002ee:	d86a0a13          	addi	s4,s4,-634 # ffffffffc0202070 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f4:	854a                	mv	a0,s2
ffffffffc02002f6:	277010ef          	jal	ra,ffffffffc0201d6c <readline>
ffffffffc02002fa:	842a                	mv	s0,a0
ffffffffc02002fc:	dd65                	beqz	a0,ffffffffc02002f4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fe:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200302:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200304:	e1bd                	bnez	a1,ffffffffc020036a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200306:	fe0c87e3          	beqz	s9,ffffffffc02002f4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	6582                	ld	a1,0(sp)
ffffffffc020030c:	00002d17          	auipc	s10,0x2
ffffffffc0200310:	e7cd0d13          	addi	s10,s10,-388 # ffffffffc0202188 <commands>
        argv[argc ++] = buf;
ffffffffc0200314:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200316:	4401                	li	s0,0
ffffffffc0200318:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031a:	3a7010ef          	jal	ra,ffffffffc0201ec0 <strcmp>
ffffffffc020031e:	c919                	beqz	a0,ffffffffc0200334 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200320:	2405                	addiw	s0,s0,1
ffffffffc0200322:	0b540063          	beq	s0,s5,ffffffffc02003c2 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200326:	000d3503          	ld	a0,0(s10)
ffffffffc020032a:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	393010ef          	jal	ra,ffffffffc0201ec0 <strcmp>
ffffffffc0200332:	f57d                	bnez	a0,ffffffffc0200320 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200334:	00141793          	slli	a5,s0,0x1
ffffffffc0200338:	97a2                	add	a5,a5,s0
ffffffffc020033a:	078e                	slli	a5,a5,0x3
ffffffffc020033c:	97e2                	add	a5,a5,s8
ffffffffc020033e:	6b9c                	ld	a5,16(a5)
ffffffffc0200340:	865e                	mv	a2,s7
ffffffffc0200342:	002c                	addi	a1,sp,8
ffffffffc0200344:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200348:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020034a:	fa0555e3          	bgez	a0,ffffffffc02002f4 <kmonitor+0x6a>
}
ffffffffc020034e:	60ee                	ld	ra,216(sp)
ffffffffc0200350:	644e                	ld	s0,208(sp)
ffffffffc0200352:	64ae                	ld	s1,200(sp)
ffffffffc0200354:	690e                	ld	s2,192(sp)
ffffffffc0200356:	79ea                	ld	s3,184(sp)
ffffffffc0200358:	7a4a                	ld	s4,176(sp)
ffffffffc020035a:	7aaa                	ld	s5,168(sp)
ffffffffc020035c:	7b0a                	ld	s6,160(sp)
ffffffffc020035e:	6bea                	ld	s7,152(sp)
ffffffffc0200360:	6c4a                	ld	s8,144(sp)
ffffffffc0200362:	6caa                	ld	s9,136(sp)
ffffffffc0200364:	6d0a                	ld	s10,128(sp)
ffffffffc0200366:	612d                	addi	sp,sp,224
ffffffffc0200368:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020036a:	8526                	mv	a0,s1
ffffffffc020036c:	399010ef          	jal	ra,ffffffffc0201f04 <strchr>
ffffffffc0200370:	c901                	beqz	a0,ffffffffc0200380 <kmonitor+0xf6>
ffffffffc0200372:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200376:	00040023          	sb	zero,0(s0)
ffffffffc020037a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037c:	d5c9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc020037e:	b7f5                	j	ffffffffc020036a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200380:	00044783          	lbu	a5,0(s0)
ffffffffc0200384:	d3c9                	beqz	a5,ffffffffc0200306 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200386:	033c8963          	beq	s9,s3,ffffffffc02003b8 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020038a:	003c9793          	slli	a5,s9,0x3
ffffffffc020038e:	0118                	addi	a4,sp,128
ffffffffc0200390:	97ba                	add	a5,a5,a4
ffffffffc0200392:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	e591                	bnez	a1,ffffffffc02003a8 <kmonitor+0x11e>
ffffffffc020039e:	b7b5                	j	ffffffffc020030a <kmonitor+0x80>
ffffffffc02003a0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a6:	d1a5                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003a8:	8526                	mv	a0,s1
ffffffffc02003aa:	35b010ef          	jal	ra,ffffffffc0201f04 <strchr>
ffffffffc02003ae:	d96d                	beqz	a0,ffffffffc02003a0 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b0:	00044583          	lbu	a1,0(s0)
ffffffffc02003b4:	d9a9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003b6:	bf55                	j	ffffffffc020036a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b8:	45c1                	li	a1,16
ffffffffc02003ba:	855a                	mv	a0,s6
ffffffffc02003bc:	d1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02003c0:	b7e9                	j	ffffffffc020038a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c2:	6582                	ld	a1,0(sp)
ffffffffc02003c4:	00002517          	auipc	a0,0x2
ffffffffc02003c8:	dac50513          	addi	a0,a0,-596 # ffffffffc0202170 <etext+0x244>
ffffffffc02003cc:	d0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc02003d0:	b715                	j	ffffffffc02002f4 <kmonitor+0x6a>

ffffffffc02003d2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d2:	00006317          	auipc	t1,0x6
ffffffffc02003d6:	06e30313          	addi	t1,t1,110 # ffffffffc0206440 <is_panic>
ffffffffc02003da:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003de:	715d                	addi	sp,sp,-80
ffffffffc02003e0:	ec06                	sd	ra,24(sp)
ffffffffc02003e2:	e822                	sd	s0,16(sp)
ffffffffc02003e4:	f436                	sd	a3,40(sp)
ffffffffc02003e6:	f83a                	sd	a4,48(sp)
ffffffffc02003e8:	fc3e                	sd	a5,56(sp)
ffffffffc02003ea:	e0c2                	sd	a6,64(sp)
ffffffffc02003ec:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ee:	020e1a63          	bnez	t3,ffffffffc0200422 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f2:	4785                	li	a5,1
ffffffffc02003f4:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f8:	8432                	mv	s0,a2
ffffffffc02003fa:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	dd050513          	addi	a0,a0,-560 # ffffffffc02021d0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	ccfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	ca7ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	c0250513          	addi	a0,a0,-1022 # ffffffffc0202018 <etext+0xec>
ffffffffc020041e:	cbbff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200422:	412000ef          	jal	ra,ffffffffc0200834 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e63ff0ef          	jal	ra,ffffffffc020028a <kmonitor>
    while (1) {
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x54>

ffffffffc020042e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	1f5010ef          	jal	ra,ffffffffc0201e3a <sbi_set_timer>
}
ffffffffc020044a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	fe07be23          	sd	zero,-4(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	d9c50513          	addi	a0,a0,-612 # ffffffffc02021f0 <commands+0x68>
}
ffffffffc020045c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b9ad                	j	ffffffffc02000d8 <cprintf>

ffffffffc0200460 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	1cf0106f          	j	ffffffffc0201e3a <sbi_set_timer>

ffffffffc0200470 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200472:	0ff57513          	zext.b	a0,a0
ffffffffc0200476:	1ab0106f          	j	ffffffffc0201e20 <sbi_console_putchar>

ffffffffc020047a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020047a:	1db0106f          	j	ffffffffc0201e54 <sbi_console_getchar>

ffffffffc020047e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020047e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200480:	00002517          	auipc	a0,0x2
ffffffffc0200484:	d9050513          	addi	a0,a0,-624 # ffffffffc0202210 <commands+0x88>
void dtb_init(void) {
ffffffffc0200488:	fc86                	sd	ra,120(sp)
ffffffffc020048a:	f8a2                	sd	s0,112(sp)
ffffffffc020048c:	e8d2                	sd	s4,80(sp)
ffffffffc020048e:	f4a6                	sd	s1,104(sp)
ffffffffc0200490:	f0ca                	sd	s2,96(sp)
ffffffffc0200492:	ecce                	sd	s3,88(sp)
ffffffffc0200494:	e4d6                	sd	s5,72(sp)
ffffffffc0200496:	e0da                	sd	s6,64(sp)
ffffffffc0200498:	fc5e                	sd	s7,56(sp)
ffffffffc020049a:	f862                	sd	s8,48(sp)
ffffffffc020049c:	f466                	sd	s9,40(sp)
ffffffffc020049e:	f06a                	sd	s10,32(sp)
ffffffffc02004a0:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004a2:	c37ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004a6:	00006597          	auipc	a1,0x6
ffffffffc02004aa:	b5a5b583          	ld	a1,-1190(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004ae:	00002517          	auipc	a0,0x2
ffffffffc02004b2:	d7250513          	addi	a0,a0,-654 # ffffffffc0202220 <commands+0x98>
ffffffffc02004b6:	c23ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004ba:	00006417          	auipc	s0,0x6
ffffffffc02004be:	b4e40413          	addi	s0,s0,-1202 # ffffffffc0206008 <boot_dtb>
ffffffffc02004c2:	600c                	ld	a1,0(s0)
ffffffffc02004c4:	00002517          	auipc	a0,0x2
ffffffffc02004c8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0202230 <commands+0xa8>
ffffffffc02004cc:	c0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004d0:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	d7450513          	addi	a0,a0,-652 # ffffffffc0202248 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004dc:	120a0463          	beqz	s4,ffffffffc0200604 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004e0:	57f5                	li	a5,-3
ffffffffc02004e2:	07fa                	slli	a5,a5,0x1e
ffffffffc02004e4:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004e8:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004f4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200506:	8ec9                	or	a3,a3,a0
ffffffffc0200508:	0087979b          	slliw	a5,a5,0x8
ffffffffc020050c:	1b7d                	addi	s6,s6,-1
ffffffffc020050e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200512:	8dd5                	or	a1,a1,a3
ffffffffc0200514:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200516:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020051c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc0200520:	10f59163          	bne	a1,a5,ffffffffc0200622 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200524:	471c                	lw	a5,8(a4)
ffffffffc0200526:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200528:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200532:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053a:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054e:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200552:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	01146433          	or	s0,s0,a7
ffffffffc0200558:	0086969b          	slliw	a3,a3,0x8
ffffffffc020055c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200560:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200562:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200566:	8c49                	or	s0,s0,a0
ffffffffc0200568:	0166f6b3          	and	a3,a3,s6
ffffffffc020056c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200570:	0167f7b3          	and	a5,a5,s6
ffffffffc0200574:	8c55                	or	s0,s0,a3
ffffffffc0200576:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200580:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200584:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200586:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200588:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020058c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020058e:	00002917          	auipc	s2,0x2
ffffffffc0200592:	d0a90913          	addi	s2,s2,-758 # ffffffffc0202298 <commands+0x110>
ffffffffc0200596:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200598:	4d91                	li	s11,4
ffffffffc020059a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020059c:	00002497          	auipc	s1,0x2
ffffffffc02005a0:	cf448493          	addi	s1,s1,-780 # ffffffffc0202290 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005a4:	000a2703          	lw	a4,0(s4)
ffffffffc02005a8:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005b0:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b4:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b8:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005bc:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005c0:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005ca:	8fd5                	or	a5,a5,a3
ffffffffc02005cc:	00eb7733          	and	a4,s6,a4
ffffffffc02005d0:	8fd9                	or	a5,a5,a4
ffffffffc02005d2:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005d4:	09778c63          	beq	a5,s7,ffffffffc020066c <dtb_init+0x1ee>
ffffffffc02005d8:	00fbea63          	bltu	s7,a5,ffffffffc02005ec <dtb_init+0x16e>
ffffffffc02005dc:	07a78663          	beq	a5,s10,ffffffffc0200648 <dtb_init+0x1ca>
ffffffffc02005e0:	4709                	li	a4,2
ffffffffc02005e2:	00e79763          	bne	a5,a4,ffffffffc02005f0 <dtb_init+0x172>
ffffffffc02005e6:	4c81                	li	s9,0
ffffffffc02005e8:	8a56                	mv	s4,s5
ffffffffc02005ea:	bf6d                	j	ffffffffc02005a4 <dtb_init+0x126>
ffffffffc02005ec:	ffb78ee3          	beq	a5,s11,ffffffffc02005e8 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005f0:	00002517          	auipc	a0,0x2
ffffffffc02005f4:	d2050513          	addi	a0,a0,-736 # ffffffffc0202310 <commands+0x188>
ffffffffc02005f8:	ae1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005fc:	00002517          	auipc	a0,0x2
ffffffffc0200600:	d4c50513          	addi	a0,a0,-692 # ffffffffc0202348 <commands+0x1c0>
}
ffffffffc0200604:	7446                	ld	s0,112(sp)
ffffffffc0200606:	70e6                	ld	ra,120(sp)
ffffffffc0200608:	74a6                	ld	s1,104(sp)
ffffffffc020060a:	7906                	ld	s2,96(sp)
ffffffffc020060c:	69e6                	ld	s3,88(sp)
ffffffffc020060e:	6a46                	ld	s4,80(sp)
ffffffffc0200610:	6aa6                	ld	s5,72(sp)
ffffffffc0200612:	6b06                	ld	s6,64(sp)
ffffffffc0200614:	7be2                	ld	s7,56(sp)
ffffffffc0200616:	7c42                	ld	s8,48(sp)
ffffffffc0200618:	7ca2                	ld	s9,40(sp)
ffffffffc020061a:	7d02                	ld	s10,32(sp)
ffffffffc020061c:	6de2                	ld	s11,24(sp)
ffffffffc020061e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200620:	bc65                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200622:	7446                	ld	s0,112(sp)
ffffffffc0200624:	70e6                	ld	ra,120(sp)
ffffffffc0200626:	74a6                	ld	s1,104(sp)
ffffffffc0200628:	7906                	ld	s2,96(sp)
ffffffffc020062a:	69e6                	ld	s3,88(sp)
ffffffffc020062c:	6a46                	ld	s4,80(sp)
ffffffffc020062e:	6aa6                	ld	s5,72(sp)
ffffffffc0200630:	6b06                	ld	s6,64(sp)
ffffffffc0200632:	7be2                	ld	s7,56(sp)
ffffffffc0200634:	7c42                	ld	s8,48(sp)
ffffffffc0200636:	7ca2                	ld	s9,40(sp)
ffffffffc0200638:	7d02                	ld	s10,32(sp)
ffffffffc020063a:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202268 <commands+0xe0>
}
ffffffffc0200644:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200646:	bc49                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc0200648:	8556                	mv	a0,s5
ffffffffc020064a:	041010ef          	jal	ra,ffffffffc0201e8a <strlen>
ffffffffc020064e:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200650:	4619                	li	a2,6
ffffffffc0200652:	85a6                	mv	a1,s1
ffffffffc0200654:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200656:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200658:	087010ef          	jal	ra,ffffffffc0201ede <strncmp>
ffffffffc020065c:	e111                	bnez	a0,ffffffffc0200660 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020065e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200660:	0a91                	addi	s5,s5,4
ffffffffc0200662:	9ad2                	add	s5,s5,s4
ffffffffc0200664:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200668:	8a56                	mv	s4,s5
ffffffffc020066a:	bf2d                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020066c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200670:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200678:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200680:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200684:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200688:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200690:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200694:	00eaeab3          	or	s5,s5,a4
ffffffffc0200698:	00fb77b3          	and	a5,s6,a5
ffffffffc020069c:	00faeab3          	or	s5,s5,a5
ffffffffc02006a0:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006a2:	000c9c63          	bnez	s9,ffffffffc02006ba <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006a6:	1a82                	slli	s5,s5,0x20
ffffffffc02006a8:	00368793          	addi	a5,a3,3
ffffffffc02006ac:	020ada93          	srli	s5,s5,0x20
ffffffffc02006b0:	9abe                	add	s5,s5,a5
ffffffffc02006b2:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006b6:	8a56                	mv	s4,s5
ffffffffc02006b8:	b5f5                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ba:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006be:	85ca                	mv	a1,s2
ffffffffc02006c0:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006ce:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006d6:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d8:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8d59                	or	a0,a0,a4
ffffffffc02006e2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006e6:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006e8:	1502                	slli	a0,a0,0x20
ffffffffc02006ea:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ec:	9522                	add	a0,a0,s0
ffffffffc02006ee:	7d2010ef          	jal	ra,ffffffffc0201ec0 <strcmp>
ffffffffc02006f2:	66a2                	ld	a3,8(sp)
ffffffffc02006f4:	f94d                	bnez	a0,ffffffffc02006a6 <dtb_init+0x228>
ffffffffc02006f6:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006a6 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006fa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006fe:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200702:	00002517          	auipc	a0,0x2
ffffffffc0200706:	b9e50513          	addi	a0,a0,-1122 # ffffffffc02022a0 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc020070a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200712:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020071a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0187d693          	srli	a3,a5,0x18
ffffffffc020072a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020072e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200732:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0106561b          	srliw	a2,a2,0x10
ffffffffc020073a:	010f6f33          	or	t5,t5,a6
ffffffffc020073e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200742:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200746:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074a:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200752:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200756:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020075e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200762:	8361                	srli	a4,a4,0x18
ffffffffc0200764:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200768:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020076c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200770:	00cb7633          	and	a2,s6,a2
ffffffffc0200774:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200778:	0085959b          	slliw	a1,a1,0x8
ffffffffc020077c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200790:	011b78b3          	and	a7,s6,a7
ffffffffc0200794:	005eeeb3          	or	t4,t4,t0
ffffffffc0200798:	00c6e733          	or	a4,a3,a2
ffffffffc020079c:	006c6c33          	or	s8,s8,t1
ffffffffc02007a0:	010b76b3          	and	a3,s6,a6
ffffffffc02007a4:	00bb7b33          	and	s6,s6,a1
ffffffffc02007a8:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007ac:	016c6b33          	or	s6,s8,s6
ffffffffc02007b0:	01146433          	or	s0,s0,a7
ffffffffc02007b4:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007b6:	1702                	slli	a4,a4,0x20
ffffffffc02007b8:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ba:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007bc:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007be:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c0:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c4:	0167eb33          	or	s6,a5,s6
ffffffffc02007c8:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007ca:	90fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007ce:	85a2                	mv	a1,s0
ffffffffc02007d0:	00002517          	auipc	a0,0x2
ffffffffc02007d4:	af050513          	addi	a0,a0,-1296 # ffffffffc02022c0 <commands+0x138>
ffffffffc02007d8:	901ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007dc:	014b5613          	srli	a2,s6,0x14
ffffffffc02007e0:	85da                	mv	a1,s6
ffffffffc02007e2:	00002517          	auipc	a0,0x2
ffffffffc02007e6:	af650513          	addi	a0,a0,-1290 # ffffffffc02022d8 <commands+0x150>
ffffffffc02007ea:	8efff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007ee:	008b05b3          	add	a1,s6,s0
ffffffffc02007f2:	15fd                	addi	a1,a1,-1
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	b0450513          	addi	a0,a0,-1276 # ffffffffc02022f8 <commands+0x170>
ffffffffc02007fc:	8ddff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200800:	00002517          	auipc	a0,0x2
ffffffffc0200804:	b4850513          	addi	a0,a0,-1208 # ffffffffc0202348 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200808:	00006797          	auipc	a5,0x6
ffffffffc020080c:	c487b423          	sd	s0,-952(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc0200810:	00006797          	auipc	a5,0x6
ffffffffc0200814:	c567b423          	sd	s6,-952(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200818:	b3f5                	j	ffffffffc0200604 <dtb_init+0x186>

ffffffffc020081a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020081a:	00006517          	auipc	a0,0x6
ffffffffc020081e:	c3653503          	ld	a0,-970(a0) # ffffffffc0206450 <memory_base>
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200824:	00006517          	auipc	a0,0x6
ffffffffc0200828:	c3453503          	ld	a0,-972(a0) # ffffffffc0206458 <memory_size>
ffffffffc020082c:	8082                	ret

ffffffffc020082e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020082e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200832:	8082                	ret

ffffffffc0200834 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200834:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200838:	8082                	ret

ffffffffc020083a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020083a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020083e:	00000797          	auipc	a5,0x0
ffffffffc0200842:	31a78793          	addi	a5,a5,794 # ffffffffc0200b58 <__alltraps>
ffffffffc0200846:	10579073          	csrw	stvec,a5
}
ffffffffc020084a:	8082                	ret

ffffffffc020084c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020084c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020084e:	1141                	addi	sp,sp,-16
ffffffffc0200850:	e022                	sd	s0,0(sp)
ffffffffc0200852:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200854:	00002517          	auipc	a0,0x2
ffffffffc0200858:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0202360 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020085e:	87bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200862:	640c                	ld	a1,8(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	b1450513          	addi	a0,a0,-1260 # ffffffffc0202378 <commands+0x1f0>
ffffffffc020086c:	86dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200870:	680c                	ld	a1,16(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0202390 <commands+0x208>
ffffffffc020087a:	85fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020087e:	6c0c                	ld	a1,24(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	b2850513          	addi	a0,a0,-1240 # ffffffffc02023a8 <commands+0x220>
ffffffffc0200888:	851ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088c:	700c                	ld	a1,32(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	b3250513          	addi	a0,a0,-1230 # ffffffffc02023c0 <commands+0x238>
ffffffffc0200896:	843ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089a:	740c                	ld	a1,40(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc02023d8 <commands+0x250>
ffffffffc02008a4:	835ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008a8:	780c                	ld	a1,48(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	b4650513          	addi	a0,a0,-1210 # ffffffffc02023f0 <commands+0x268>
ffffffffc02008b2:	827ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b6:	7c0c                	ld	a1,56(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	b5050513          	addi	a0,a0,-1200 # ffffffffc0202408 <commands+0x280>
ffffffffc02008c0:	819ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c4:	602c                	ld	a1,64(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0202420 <commands+0x298>
ffffffffc02008ce:	80bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d2:	642c                	ld	a1,72(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202438 <commands+0x2b0>
ffffffffc02008dc:	ffcff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e0:	682c                	ld	a1,80(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0202450 <commands+0x2c8>
ffffffffc02008ea:	feeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008ee:	6c2c                	ld	a1,88(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202468 <commands+0x2e0>
ffffffffc02008f8:	fe0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fc:	702c                	ld	a1,96(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202480 <commands+0x2f8>
ffffffffc0200906:	fd2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090a:	742c                	ld	a1,104(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202498 <commands+0x310>
ffffffffc0200914:	fc4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200918:	782c                	ld	a1,112(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	b9650513          	addi	a0,a0,-1130 # ffffffffc02024b0 <commands+0x328>
ffffffffc0200922:	fb6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200926:	7c2c                	ld	a1,120(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	ba050513          	addi	a0,a0,-1120 # ffffffffc02024c8 <commands+0x340>
ffffffffc0200930:	fa8ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200934:	604c                	ld	a1,128(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	baa50513          	addi	a0,a0,-1110 # ffffffffc02024e0 <commands+0x358>
ffffffffc020093e:	f9aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200942:	644c                	ld	a1,136(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	bb450513          	addi	a0,a0,-1100 # ffffffffc02024f8 <commands+0x370>
ffffffffc020094c:	f8cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200950:	684c                	ld	a1,144(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202510 <commands+0x388>
ffffffffc020095a:	f7eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020095e:	6c4c                	ld	a1,152(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202528 <commands+0x3a0>
ffffffffc0200968:	f70ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096c:	704c                	ld	a1,160(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202540 <commands+0x3b8>
ffffffffc0200976:	f62ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097a:	744c                	ld	a1,168(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202558 <commands+0x3d0>
ffffffffc0200984:	f54ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200988:	784c                	ld	a1,176(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	be650513          	addi	a0,a0,-1050 # ffffffffc0202570 <commands+0x3e8>
ffffffffc0200992:	f46ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200996:	7c4c                	ld	a1,184(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202588 <commands+0x400>
ffffffffc02009a0:	f38ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a4:	606c                	ld	a1,192(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	bfa50513          	addi	a0,a0,-1030 # ffffffffc02025a0 <commands+0x418>
ffffffffc02009ae:	f2aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b2:	646c                	ld	a1,200(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	c0450513          	addi	a0,a0,-1020 # ffffffffc02025b8 <commands+0x430>
ffffffffc02009bc:	f1cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c0:	686c                	ld	a1,208(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	c0e50513          	addi	a0,a0,-1010 # ffffffffc02025d0 <commands+0x448>
ffffffffc02009ca:	f0eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009ce:	6c6c                	ld	a1,216(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	c1850513          	addi	a0,a0,-1000 # ffffffffc02025e8 <commands+0x460>
ffffffffc02009d8:	f00ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009dc:	706c                	ld	a1,224(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	c2250513          	addi	a0,a0,-990 # ffffffffc0202600 <commands+0x478>
ffffffffc02009e6:	ef2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ea:	746c                	ld	a1,232(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202618 <commands+0x490>
ffffffffc02009f4:	ee4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009f8:	786c                	ld	a1,240(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	c3650513          	addi	a0,a0,-970 # ffffffffc0202630 <commands+0x4a8>
ffffffffc0200a02:	ed6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a06:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a08:	6402                	ld	s0,0(sp)
ffffffffc0200a0a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0c:	00002517          	auipc	a0,0x2
ffffffffc0200a10:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202648 <commands+0x4c0>
}
ffffffffc0200a14:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a16:	ec2ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a1a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1a:	1141                	addi	sp,sp,-16
ffffffffc0200a1c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a1e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a20:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202660 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2c:	eacff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a30:	8522                	mv	a0,s0
ffffffffc0200a32:	e1bff0ef          	jal	ra,ffffffffc020084c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a36:	10043583          	ld	a1,256(s0)
ffffffffc0200a3a:	00002517          	auipc	a0,0x2
ffffffffc0200a3e:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202678 <commands+0x4f0>
ffffffffc0200a42:	e96ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a46:	10843583          	ld	a1,264(s0)
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	c4650513          	addi	a0,a0,-954 # ffffffffc0202690 <commands+0x508>
ffffffffc0200a52:	e86ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a56:	11043583          	ld	a1,272(s0)
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	c4e50513          	addi	a0,a0,-946 # ffffffffc02026a8 <commands+0x520>
ffffffffc0200a62:	e76ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a66:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6a:	6402                	ld	s0,0(sp)
ffffffffc0200a6c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6e:	00002517          	auipc	a0,0x2
ffffffffc0200a72:	c5250513          	addi	a0,a0,-942 # ffffffffc02026c0 <commands+0x538>
}
ffffffffc0200a76:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7c <interrupt_handler>:
int num=0;
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a7c:	11853783          	ld	a5,280(a0)
ffffffffc0200a80:	472d                	li	a4,11
ffffffffc0200a82:	0786                	slli	a5,a5,0x1
ffffffffc0200a84:	8385                	srli	a5,a5,0x1
ffffffffc0200a86:	08f76963          	bltu	a4,a5,ffffffffc0200b18 <interrupt_handler+0x9c>
ffffffffc0200a8a:	00002717          	auipc	a4,0x2
ffffffffc0200a8e:	d1670713          	addi	a4,a4,-746 # ffffffffc02027a0 <commands+0x618>
ffffffffc0200a92:	078a                	slli	a5,a5,0x2
ffffffffc0200a94:	97ba                	add	a5,a5,a4
ffffffffc0200a96:	439c                	lw	a5,0(a5)
ffffffffc0200a98:	97ba                	add	a5,a5,a4
ffffffffc0200a9a:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a9c:	00002517          	auipc	a0,0x2
ffffffffc0200aa0:	c9c50513          	addi	a0,a0,-868 # ffffffffc0202738 <commands+0x5b0>
ffffffffc0200aa4:	e34ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aa8:	00002517          	auipc	a0,0x2
ffffffffc0200aac:	c7050513          	addi	a0,a0,-912 # ffffffffc0202718 <commands+0x590>
ffffffffc0200ab0:	e28ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ab4:	00002517          	auipc	a0,0x2
ffffffffc0200ab8:	c2450513          	addi	a0,a0,-988 # ffffffffc02026d8 <commands+0x550>
ffffffffc0200abc:	e1cff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac0:	00002517          	auipc	a0,0x2
ffffffffc0200ac4:	c9850513          	addi	a0,a0,-872 # ffffffffc0202758 <commands+0x5d0>
ffffffffc0200ac8:	e10ff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200acc:	1141                	addi	sp,sp,-16
ffffffffc0200ace:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200ad0:	991ff0ef          	jal	ra,ffffffffc0200460 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200ad4:	00006697          	auipc	a3,0x6
ffffffffc0200ad8:	97468693          	addi	a3,a3,-1676 # ffffffffc0206448 <ticks>
ffffffffc0200adc:	629c                	ld	a5,0(a3)
ffffffffc0200ade:	06400713          	li	a4,100
ffffffffc0200ae2:	0785                	addi	a5,a5,1
ffffffffc0200ae4:	02e7f733          	remu	a4,a5,a4
ffffffffc0200ae8:	e29c                	sd	a5,0(a3)
ffffffffc0200aea:	cb05                	beqz	a4,ffffffffc0200b1a <interrupt_handler+0x9e>
                print_ticks();
                num++;
            }
            if(num==10){sbi_shutdown();}
ffffffffc0200aec:	00006717          	auipc	a4,0x6
ffffffffc0200af0:	97472703          	lw	a4,-1676(a4) # ffffffffc0206460 <num>
ffffffffc0200af4:	47a9                	li	a5,10
ffffffffc0200af6:	04f70363          	beq	a4,a5,ffffffffc0200b3c <interrupt_handler+0xc0>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200afa:	60a2                	ld	ra,8(sp)
ffffffffc0200afc:	0141                	addi	sp,sp,16
ffffffffc0200afe:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b00:	00002517          	auipc	a0,0x2
ffffffffc0200b04:	c8050513          	addi	a0,a0,-896 # ffffffffc0202780 <commands+0x5f8>
ffffffffc0200b08:	dd0ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b0c:	00002517          	auipc	a0,0x2
ffffffffc0200b10:	bec50513          	addi	a0,a0,-1044 # ffffffffc02026f8 <commands+0x570>
ffffffffc0200b14:	dc4ff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b18:	b709                	j	ffffffffc0200a1a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b1a:	06400593          	li	a1,100
ffffffffc0200b1e:	00002517          	auipc	a0,0x2
ffffffffc0200b22:	c5250513          	addi	a0,a0,-942 # ffffffffc0202770 <commands+0x5e8>
ffffffffc0200b26:	db2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                num++;
ffffffffc0200b2a:	00006697          	auipc	a3,0x6
ffffffffc0200b2e:	93668693          	addi	a3,a3,-1738 # ffffffffc0206460 <num>
ffffffffc0200b32:	429c                	lw	a5,0(a3)
ffffffffc0200b34:	0017871b          	addiw	a4,a5,1
ffffffffc0200b38:	c298                	sw	a4,0(a3)
ffffffffc0200b3a:	bf6d                	j	ffffffffc0200af4 <interrupt_handler+0x78>
}
ffffffffc0200b3c:	60a2                	ld	ra,8(sp)
ffffffffc0200b3e:	0141                	addi	sp,sp,16
            if(num==10){sbi_shutdown();}
ffffffffc0200b40:	3300106f          	j	ffffffffc0201e70 <sbi_shutdown>

ffffffffc0200b44 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b44:	11853783          	ld	a5,280(a0)
ffffffffc0200b48:	0007c763          	bltz	a5,ffffffffc0200b56 <trap+0x12>
    switch (tf->cause) {
ffffffffc0200b4c:	472d                	li	a4,11
ffffffffc0200b4e:	00f76363          	bltu	a4,a5,ffffffffc0200b54 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200b52:	8082                	ret
            print_trapframe(tf);
ffffffffc0200b54:	b5d9                	j	ffffffffc0200a1a <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200b56:	b71d                	j	ffffffffc0200a7c <interrupt_handler>

ffffffffc0200b58 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b58:	14011073          	csrw	sscratch,sp
ffffffffc0200b5c:	712d                	addi	sp,sp,-288
ffffffffc0200b5e:	e002                	sd	zero,0(sp)
ffffffffc0200b60:	e406                	sd	ra,8(sp)
ffffffffc0200b62:	ec0e                	sd	gp,24(sp)
ffffffffc0200b64:	f012                	sd	tp,32(sp)
ffffffffc0200b66:	f416                	sd	t0,40(sp)
ffffffffc0200b68:	f81a                	sd	t1,48(sp)
ffffffffc0200b6a:	fc1e                	sd	t2,56(sp)
ffffffffc0200b6c:	e0a2                	sd	s0,64(sp)
ffffffffc0200b6e:	e4a6                	sd	s1,72(sp)
ffffffffc0200b70:	e8aa                	sd	a0,80(sp)
ffffffffc0200b72:	ecae                	sd	a1,88(sp)
ffffffffc0200b74:	f0b2                	sd	a2,96(sp)
ffffffffc0200b76:	f4b6                	sd	a3,104(sp)
ffffffffc0200b78:	f8ba                	sd	a4,112(sp)
ffffffffc0200b7a:	fcbe                	sd	a5,120(sp)
ffffffffc0200b7c:	e142                	sd	a6,128(sp)
ffffffffc0200b7e:	e546                	sd	a7,136(sp)
ffffffffc0200b80:	e94a                	sd	s2,144(sp)
ffffffffc0200b82:	ed4e                	sd	s3,152(sp)
ffffffffc0200b84:	f152                	sd	s4,160(sp)
ffffffffc0200b86:	f556                	sd	s5,168(sp)
ffffffffc0200b88:	f95a                	sd	s6,176(sp)
ffffffffc0200b8a:	fd5e                	sd	s7,184(sp)
ffffffffc0200b8c:	e1e2                	sd	s8,192(sp)
ffffffffc0200b8e:	e5e6                	sd	s9,200(sp)
ffffffffc0200b90:	e9ea                	sd	s10,208(sp)
ffffffffc0200b92:	edee                	sd	s11,216(sp)
ffffffffc0200b94:	f1f2                	sd	t3,224(sp)
ffffffffc0200b96:	f5f6                	sd	t4,232(sp)
ffffffffc0200b98:	f9fa                	sd	t5,240(sp)
ffffffffc0200b9a:	fdfe                	sd	t6,248(sp)
ffffffffc0200b9c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ba0:	100024f3          	csrr	s1,sstatus
ffffffffc0200ba4:	14102973          	csrr	s2,sepc
ffffffffc0200ba8:	143029f3          	csrr	s3,stval
ffffffffc0200bac:	14202a73          	csrr	s4,scause
ffffffffc0200bb0:	e822                	sd	s0,16(sp)
ffffffffc0200bb2:	e226                	sd	s1,256(sp)
ffffffffc0200bb4:	e64a                	sd	s2,264(sp)
ffffffffc0200bb6:	ea4e                	sd	s3,272(sp)
ffffffffc0200bb8:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bba:	850a                	mv	a0,sp
    jal trap
ffffffffc0200bbc:	f89ff0ef          	jal	ra,ffffffffc0200b44 <trap>

ffffffffc0200bc0 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200bc0:	6492                	ld	s1,256(sp)
ffffffffc0200bc2:	6932                	ld	s2,264(sp)
ffffffffc0200bc4:	10049073          	csrw	sstatus,s1
ffffffffc0200bc8:	14191073          	csrw	sepc,s2
ffffffffc0200bcc:	60a2                	ld	ra,8(sp)
ffffffffc0200bce:	61e2                	ld	gp,24(sp)
ffffffffc0200bd0:	7202                	ld	tp,32(sp)
ffffffffc0200bd2:	72a2                	ld	t0,40(sp)
ffffffffc0200bd4:	7342                	ld	t1,48(sp)
ffffffffc0200bd6:	73e2                	ld	t2,56(sp)
ffffffffc0200bd8:	6406                	ld	s0,64(sp)
ffffffffc0200bda:	64a6                	ld	s1,72(sp)
ffffffffc0200bdc:	6546                	ld	a0,80(sp)
ffffffffc0200bde:	65e6                	ld	a1,88(sp)
ffffffffc0200be0:	7606                	ld	a2,96(sp)
ffffffffc0200be2:	76a6                	ld	a3,104(sp)
ffffffffc0200be4:	7746                	ld	a4,112(sp)
ffffffffc0200be6:	77e6                	ld	a5,120(sp)
ffffffffc0200be8:	680a                	ld	a6,128(sp)
ffffffffc0200bea:	68aa                	ld	a7,136(sp)
ffffffffc0200bec:	694a                	ld	s2,144(sp)
ffffffffc0200bee:	69ea                	ld	s3,152(sp)
ffffffffc0200bf0:	7a0a                	ld	s4,160(sp)
ffffffffc0200bf2:	7aaa                	ld	s5,168(sp)
ffffffffc0200bf4:	7b4a                	ld	s6,176(sp)
ffffffffc0200bf6:	7bea                	ld	s7,184(sp)
ffffffffc0200bf8:	6c0e                	ld	s8,192(sp)
ffffffffc0200bfa:	6cae                	ld	s9,200(sp)
ffffffffc0200bfc:	6d4e                	ld	s10,208(sp)
ffffffffc0200bfe:	6dee                	ld	s11,216(sp)
ffffffffc0200c00:	7e0e                	ld	t3,224(sp)
ffffffffc0200c02:	7eae                	ld	t4,232(sp)
ffffffffc0200c04:	7f4e                	ld	t5,240(sp)
ffffffffc0200c06:	7fee                	ld	t6,248(sp)
ffffffffc0200c08:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c0a:	10200073          	sret

ffffffffc0200c0e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c0e:	00005797          	auipc	a5,0x5
ffffffffc0200c12:	41a78793          	addi	a5,a5,1050 # ffffffffc0206028 <free_area>
ffffffffc0200c16:	e79c                	sd	a5,8(a5)
ffffffffc0200c18:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c1a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c1e:	8082                	ret

ffffffffc0200c20 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c20:	00005517          	auipc	a0,0x5
ffffffffc0200c24:	41856503          	lwu	a0,1048(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200c28:	8082                	ret

ffffffffc0200c2a <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200c2a:	715d                	addi	sp,sp,-80
ffffffffc0200c2c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c2e:	00005417          	auipc	s0,0x5
ffffffffc0200c32:	3fa40413          	addi	s0,s0,1018 # ffffffffc0206028 <free_area>
ffffffffc0200c36:	641c                	ld	a5,8(s0)
ffffffffc0200c38:	e486                	sd	ra,72(sp)
ffffffffc0200c3a:	fc26                	sd	s1,56(sp)
ffffffffc0200c3c:	f84a                	sd	s2,48(sp)
ffffffffc0200c3e:	f44e                	sd	s3,40(sp)
ffffffffc0200c40:	f052                	sd	s4,32(sp)
ffffffffc0200c42:	ec56                	sd	s5,24(sp)
ffffffffc0200c44:	e85a                	sd	s6,16(sp)
ffffffffc0200c46:	e45e                	sd	s7,8(sp)
ffffffffc0200c48:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c4a:	2c878763          	beq	a5,s0,ffffffffc0200f18 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200c4e:	4481                	li	s1,0
ffffffffc0200c50:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c52:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c56:	8b09                	andi	a4,a4,2
ffffffffc0200c58:	2c070463          	beqz	a4,ffffffffc0200f20 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200c5c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c60:	679c                	ld	a5,8(a5)
ffffffffc0200c62:	2905                	addiw	s2,s2,1
ffffffffc0200c64:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c66:	fe8796e3          	bne	a5,s0,ffffffffc0200c52 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200c6a:	89a6                	mv	s3,s1
ffffffffc0200c6c:	2f9000ef          	jal	ra,ffffffffc0201764 <nr_free_pages>
ffffffffc0200c70:	71351863          	bne	a0,s3,ffffffffc0201380 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c74:	4505                	li	a0,1
ffffffffc0200c76:	271000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200c7a:	8a2a                	mv	s4,a0
ffffffffc0200c7c:	44050263          	beqz	a0,ffffffffc02010c0 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c80:	4505                	li	a0,1
ffffffffc0200c82:	265000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200c86:	89aa                	mv	s3,a0
ffffffffc0200c88:	70050c63          	beqz	a0,ffffffffc02013a0 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c8c:	4505                	li	a0,1
ffffffffc0200c8e:	259000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200c92:	8aaa                	mv	s5,a0
ffffffffc0200c94:	4a050663          	beqz	a0,ffffffffc0201140 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c98:	2b3a0463          	beq	s4,s3,ffffffffc0200f40 <default_check+0x316>
ffffffffc0200c9c:	2aaa0263          	beq	s4,a0,ffffffffc0200f40 <default_check+0x316>
ffffffffc0200ca0:	2aa98063          	beq	s3,a0,ffffffffc0200f40 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ca4:	000a2783          	lw	a5,0(s4)
ffffffffc0200ca8:	2a079c63          	bnez	a5,ffffffffc0200f60 <default_check+0x336>
ffffffffc0200cac:	0009a783          	lw	a5,0(s3)
ffffffffc0200cb0:	2a079863          	bnez	a5,ffffffffc0200f60 <default_check+0x336>
ffffffffc0200cb4:	411c                	lw	a5,0(a0)
ffffffffc0200cb6:	2a079563          	bnez	a5,ffffffffc0200f60 <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cba:	00005797          	auipc	a5,0x5
ffffffffc0200cbe:	7b67b783          	ld	a5,1974(a5) # ffffffffc0206470 <pages>
ffffffffc0200cc2:	40fa0733          	sub	a4,s4,a5
ffffffffc0200cc6:	870d                	srai	a4,a4,0x3
ffffffffc0200cc8:	00002597          	auipc	a1,0x2
ffffffffc0200ccc:	2905b583          	ld	a1,656(a1) # ffffffffc0202f58 <error_string+0x38>
ffffffffc0200cd0:	02b70733          	mul	a4,a4,a1
ffffffffc0200cd4:	00002617          	auipc	a2,0x2
ffffffffc0200cd8:	28c63603          	ld	a2,652(a2) # ffffffffc0202f60 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200cdc:	00005697          	auipc	a3,0x5
ffffffffc0200ce0:	78c6b683          	ld	a3,1932(a3) # ffffffffc0206468 <npage>
ffffffffc0200ce4:	06b2                	slli	a3,a3,0xc
ffffffffc0200ce6:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ce8:	0732                	slli	a4,a4,0xc
ffffffffc0200cea:	28d77b63          	bgeu	a4,a3,ffffffffc0200f80 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cee:	40f98733          	sub	a4,s3,a5
ffffffffc0200cf2:	870d                	srai	a4,a4,0x3
ffffffffc0200cf4:	02b70733          	mul	a4,a4,a1
ffffffffc0200cf8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cfa:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200cfc:	4cd77263          	bgeu	a4,a3,ffffffffc02011c0 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d00:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d04:	878d                	srai	a5,a5,0x3
ffffffffc0200d06:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d0a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d0c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d0e:	30d7f963          	bgeu	a5,a3,ffffffffc0201020 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200d12:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d14:	00043c03          	ld	s8,0(s0)
ffffffffc0200d18:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d1c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200d20:	e400                	sd	s0,8(s0)
ffffffffc0200d22:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200d24:	00005797          	auipc	a5,0x5
ffffffffc0200d28:	3007aa23          	sw	zero,788(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d2c:	1bb000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200d30:	2c051863          	bnez	a0,ffffffffc0201000 <default_check+0x3d6>
    free_page(p0);
ffffffffc0200d34:	4585                	li	a1,1
ffffffffc0200d36:	8552                	mv	a0,s4
ffffffffc0200d38:	1ed000ef          	jal	ra,ffffffffc0201724 <free_pages>
    free_page(p1);
ffffffffc0200d3c:	4585                	li	a1,1
ffffffffc0200d3e:	854e                	mv	a0,s3
ffffffffc0200d40:	1e5000ef          	jal	ra,ffffffffc0201724 <free_pages>
    free_page(p2);
ffffffffc0200d44:	4585                	li	a1,1
ffffffffc0200d46:	8556                	mv	a0,s5
ffffffffc0200d48:	1dd000ef          	jal	ra,ffffffffc0201724 <free_pages>
    assert(nr_free == 3);
ffffffffc0200d4c:	4818                	lw	a4,16(s0)
ffffffffc0200d4e:	478d                	li	a5,3
ffffffffc0200d50:	28f71863          	bne	a4,a5,ffffffffc0200fe0 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d54:	4505                	li	a0,1
ffffffffc0200d56:	191000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200d5a:	89aa                	mv	s3,a0
ffffffffc0200d5c:	26050263          	beqz	a0,ffffffffc0200fc0 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d60:	4505                	li	a0,1
ffffffffc0200d62:	185000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200d66:	8aaa                	mv	s5,a0
ffffffffc0200d68:	3a050c63          	beqz	a0,ffffffffc0201120 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d6c:	4505                	li	a0,1
ffffffffc0200d6e:	179000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200d72:	8a2a                	mv	s4,a0
ffffffffc0200d74:	38050663          	beqz	a0,ffffffffc0201100 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200d78:	4505                	li	a0,1
ffffffffc0200d7a:	16d000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200d7e:	36051163          	bnez	a0,ffffffffc02010e0 <default_check+0x4b6>
    free_page(p0);
ffffffffc0200d82:	4585                	li	a1,1
ffffffffc0200d84:	854e                	mv	a0,s3
ffffffffc0200d86:	19f000ef          	jal	ra,ffffffffc0201724 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200d8a:	641c                	ld	a5,8(s0)
ffffffffc0200d8c:	20878a63          	beq	a5,s0,ffffffffc0200fa0 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200d90:	4505                	li	a0,1
ffffffffc0200d92:	155000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200d96:	30a99563          	bne	s3,a0,ffffffffc02010a0 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200d9a:	4505                	li	a0,1
ffffffffc0200d9c:	14b000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200da0:	2e051063          	bnez	a0,ffffffffc0201080 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200da4:	481c                	lw	a5,16(s0)
ffffffffc0200da6:	2a079d63          	bnez	a5,ffffffffc0201060 <default_check+0x436>
    free_page(p);
ffffffffc0200daa:	854e                	mv	a0,s3
ffffffffc0200dac:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200dae:	01843023          	sd	s8,0(s0)
ffffffffc0200db2:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200db6:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200dba:	16b000ef          	jal	ra,ffffffffc0201724 <free_pages>
    free_page(p1);
ffffffffc0200dbe:	4585                	li	a1,1
ffffffffc0200dc0:	8556                	mv	a0,s5
ffffffffc0200dc2:	163000ef          	jal	ra,ffffffffc0201724 <free_pages>
    free_page(p2);
ffffffffc0200dc6:	4585                	li	a1,1
ffffffffc0200dc8:	8552                	mv	a0,s4
ffffffffc0200dca:	15b000ef          	jal	ra,ffffffffc0201724 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200dce:	4515                	li	a0,5
ffffffffc0200dd0:	117000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200dd4:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200dd6:	26050563          	beqz	a0,ffffffffc0201040 <default_check+0x416>
ffffffffc0200dda:	651c                	ld	a5,8(a0)
ffffffffc0200ddc:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200dde:	8b85                	andi	a5,a5,1
ffffffffc0200de0:	54079063          	bnez	a5,ffffffffc0201320 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200de4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200de6:	00043b03          	ld	s6,0(s0)
ffffffffc0200dea:	00843a83          	ld	s5,8(s0)
ffffffffc0200dee:	e000                	sd	s0,0(s0)
ffffffffc0200df0:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200df2:	0f5000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200df6:	50051563          	bnez	a0,ffffffffc0201300 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200dfa:	05098a13          	addi	s4,s3,80
ffffffffc0200dfe:	8552                	mv	a0,s4
ffffffffc0200e00:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e02:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200e06:	00005797          	auipc	a5,0x5
ffffffffc0200e0a:	2207a923          	sw	zero,562(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e0e:	117000ef          	jal	ra,ffffffffc0201724 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e12:	4511                	li	a0,4
ffffffffc0200e14:	0d3000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200e18:	4c051463          	bnez	a0,ffffffffc02012e0 <default_check+0x6b6>
ffffffffc0200e1c:	0589b783          	ld	a5,88(s3)
ffffffffc0200e20:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200e22:	8b85                	andi	a5,a5,1
ffffffffc0200e24:	48078e63          	beqz	a5,ffffffffc02012c0 <default_check+0x696>
ffffffffc0200e28:	0609a703          	lw	a4,96(s3)
ffffffffc0200e2c:	478d                	li	a5,3
ffffffffc0200e2e:	48f71963          	bne	a4,a5,ffffffffc02012c0 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e32:	450d                	li	a0,3
ffffffffc0200e34:	0b3000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200e38:	8c2a                	mv	s8,a0
ffffffffc0200e3a:	46050363          	beqz	a0,ffffffffc02012a0 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200e3e:	4505                	li	a0,1
ffffffffc0200e40:	0a7000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200e44:	42051e63          	bnez	a0,ffffffffc0201280 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200e48:	418a1c63          	bne	s4,s8,ffffffffc0201260 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200e4c:	4585                	li	a1,1
ffffffffc0200e4e:	854e                	mv	a0,s3
ffffffffc0200e50:	0d5000ef          	jal	ra,ffffffffc0201724 <free_pages>
    free_pages(p1, 3);
ffffffffc0200e54:	458d                	li	a1,3
ffffffffc0200e56:	8552                	mv	a0,s4
ffffffffc0200e58:	0cd000ef          	jal	ra,ffffffffc0201724 <free_pages>
ffffffffc0200e5c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200e60:	02898c13          	addi	s8,s3,40
ffffffffc0200e64:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200e66:	8b85                	andi	a5,a5,1
ffffffffc0200e68:	3c078c63          	beqz	a5,ffffffffc0201240 <default_check+0x616>
ffffffffc0200e6c:	0109a703          	lw	a4,16(s3)
ffffffffc0200e70:	4785                	li	a5,1
ffffffffc0200e72:	3cf71763          	bne	a4,a5,ffffffffc0201240 <default_check+0x616>
ffffffffc0200e76:	008a3783          	ld	a5,8(s4)
ffffffffc0200e7a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200e7c:	8b85                	andi	a5,a5,1
ffffffffc0200e7e:	3a078163          	beqz	a5,ffffffffc0201220 <default_check+0x5f6>
ffffffffc0200e82:	010a2703          	lw	a4,16(s4)
ffffffffc0200e86:	478d                	li	a5,3
ffffffffc0200e88:	38f71c63          	bne	a4,a5,ffffffffc0201220 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200e8c:	4505                	li	a0,1
ffffffffc0200e8e:	059000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200e92:	36a99763          	bne	s3,a0,ffffffffc0201200 <default_check+0x5d6>
    free_page(p0);
ffffffffc0200e96:	4585                	li	a1,1
ffffffffc0200e98:	08d000ef          	jal	ra,ffffffffc0201724 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200e9c:	4509                	li	a0,2
ffffffffc0200e9e:	049000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200ea2:	32aa1f63          	bne	s4,a0,ffffffffc02011e0 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200ea6:	4589                	li	a1,2
ffffffffc0200ea8:	07d000ef          	jal	ra,ffffffffc0201724 <free_pages>
    free_page(p2);
ffffffffc0200eac:	4585                	li	a1,1
ffffffffc0200eae:	8562                	mv	a0,s8
ffffffffc0200eb0:	075000ef          	jal	ra,ffffffffc0201724 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200eb4:	4515                	li	a0,5
ffffffffc0200eb6:	031000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200eba:	89aa                	mv	s3,a0
ffffffffc0200ebc:	48050263          	beqz	a0,ffffffffc0201340 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200ec0:	4505                	li	a0,1
ffffffffc0200ec2:	025000ef          	jal	ra,ffffffffc02016e6 <alloc_pages>
ffffffffc0200ec6:	2c051d63          	bnez	a0,ffffffffc02011a0 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200eca:	481c                	lw	a5,16(s0)
ffffffffc0200ecc:	2a079a63          	bnez	a5,ffffffffc0201180 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200ed0:	4595                	li	a1,5
ffffffffc0200ed2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200ed4:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200ed8:	01643023          	sd	s6,0(s0)
ffffffffc0200edc:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200ee0:	045000ef          	jal	ra,ffffffffc0201724 <free_pages>
    return listelm->next;
ffffffffc0200ee4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ee6:	00878963          	beq	a5,s0,ffffffffc0200ef8 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200eea:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eee:	679c                	ld	a5,8(a5)
ffffffffc0200ef0:	397d                	addiw	s2,s2,-1
ffffffffc0200ef2:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ef4:	fe879be3          	bne	a5,s0,ffffffffc0200eea <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200ef8:	26091463          	bnez	s2,ffffffffc0201160 <default_check+0x536>
    assert(total == 0);
ffffffffc0200efc:	46049263          	bnez	s1,ffffffffc0201360 <default_check+0x736>
}
ffffffffc0200f00:	60a6                	ld	ra,72(sp)
ffffffffc0200f02:	6406                	ld	s0,64(sp)
ffffffffc0200f04:	74e2                	ld	s1,56(sp)
ffffffffc0200f06:	7942                	ld	s2,48(sp)
ffffffffc0200f08:	79a2                	ld	s3,40(sp)
ffffffffc0200f0a:	7a02                	ld	s4,32(sp)
ffffffffc0200f0c:	6ae2                	ld	s5,24(sp)
ffffffffc0200f0e:	6b42                	ld	s6,16(sp)
ffffffffc0200f10:	6ba2                	ld	s7,8(sp)
ffffffffc0200f12:	6c02                	ld	s8,0(sp)
ffffffffc0200f14:	6161                	addi	sp,sp,80
ffffffffc0200f16:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f18:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f1a:	4481                	li	s1,0
ffffffffc0200f1c:	4901                	li	s2,0
ffffffffc0200f1e:	b3b9                	j	ffffffffc0200c6c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200f20:	00002697          	auipc	a3,0x2
ffffffffc0200f24:	8b068693          	addi	a3,a3,-1872 # ffffffffc02027d0 <commands+0x648>
ffffffffc0200f28:	00002617          	auipc	a2,0x2
ffffffffc0200f2c:	8b860613          	addi	a2,a2,-1864 # ffffffffc02027e0 <commands+0x658>
ffffffffc0200f30:	0f000593          	li	a1,240
ffffffffc0200f34:	00002517          	auipc	a0,0x2
ffffffffc0200f38:	8c450513          	addi	a0,a0,-1852 # ffffffffc02027f8 <commands+0x670>
ffffffffc0200f3c:	c96ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f40:	00002697          	auipc	a3,0x2
ffffffffc0200f44:	95068693          	addi	a3,a3,-1712 # ffffffffc0202890 <commands+0x708>
ffffffffc0200f48:	00002617          	auipc	a2,0x2
ffffffffc0200f4c:	89860613          	addi	a2,a2,-1896 # ffffffffc02027e0 <commands+0x658>
ffffffffc0200f50:	0bd00593          	li	a1,189
ffffffffc0200f54:	00002517          	auipc	a0,0x2
ffffffffc0200f58:	8a450513          	addi	a0,a0,-1884 # ffffffffc02027f8 <commands+0x670>
ffffffffc0200f5c:	c76ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f60:	00002697          	auipc	a3,0x2
ffffffffc0200f64:	95868693          	addi	a3,a3,-1704 # ffffffffc02028b8 <commands+0x730>
ffffffffc0200f68:	00002617          	auipc	a2,0x2
ffffffffc0200f6c:	87860613          	addi	a2,a2,-1928 # ffffffffc02027e0 <commands+0x658>
ffffffffc0200f70:	0be00593          	li	a1,190
ffffffffc0200f74:	00002517          	auipc	a0,0x2
ffffffffc0200f78:	88450513          	addi	a0,a0,-1916 # ffffffffc02027f8 <commands+0x670>
ffffffffc0200f7c:	c56ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f80:	00002697          	auipc	a3,0x2
ffffffffc0200f84:	97868693          	addi	a3,a3,-1672 # ffffffffc02028f8 <commands+0x770>
ffffffffc0200f88:	00002617          	auipc	a2,0x2
ffffffffc0200f8c:	85860613          	addi	a2,a2,-1960 # ffffffffc02027e0 <commands+0x658>
ffffffffc0200f90:	0c000593          	li	a1,192
ffffffffc0200f94:	00002517          	auipc	a0,0x2
ffffffffc0200f98:	86450513          	addi	a0,a0,-1948 # ffffffffc02027f8 <commands+0x670>
ffffffffc0200f9c:	c36ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200fa0:	00002697          	auipc	a3,0x2
ffffffffc0200fa4:	9e068693          	addi	a3,a3,-1568 # ffffffffc0202980 <commands+0x7f8>
ffffffffc0200fa8:	00002617          	auipc	a2,0x2
ffffffffc0200fac:	83860613          	addi	a2,a2,-1992 # ffffffffc02027e0 <commands+0x658>
ffffffffc0200fb0:	0d900593          	li	a1,217
ffffffffc0200fb4:	00002517          	auipc	a0,0x2
ffffffffc0200fb8:	84450513          	addi	a0,a0,-1980 # ffffffffc02027f8 <commands+0x670>
ffffffffc0200fbc:	c16ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fc0:	00002697          	auipc	a3,0x2
ffffffffc0200fc4:	87068693          	addi	a3,a3,-1936 # ffffffffc0202830 <commands+0x6a8>
ffffffffc0200fc8:	00002617          	auipc	a2,0x2
ffffffffc0200fcc:	81860613          	addi	a2,a2,-2024 # ffffffffc02027e0 <commands+0x658>
ffffffffc0200fd0:	0d200593          	li	a1,210
ffffffffc0200fd4:	00002517          	auipc	a0,0x2
ffffffffc0200fd8:	82450513          	addi	a0,a0,-2012 # ffffffffc02027f8 <commands+0x670>
ffffffffc0200fdc:	bf6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 3);
ffffffffc0200fe0:	00002697          	auipc	a3,0x2
ffffffffc0200fe4:	99068693          	addi	a3,a3,-1648 # ffffffffc0202970 <commands+0x7e8>
ffffffffc0200fe8:	00001617          	auipc	a2,0x1
ffffffffc0200fec:	7f860613          	addi	a2,a2,2040 # ffffffffc02027e0 <commands+0x658>
ffffffffc0200ff0:	0d000593          	li	a1,208
ffffffffc0200ff4:	00002517          	auipc	a0,0x2
ffffffffc0200ff8:	80450513          	addi	a0,a0,-2044 # ffffffffc02027f8 <commands+0x670>
ffffffffc0200ffc:	bd6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201000:	00002697          	auipc	a3,0x2
ffffffffc0201004:	95868693          	addi	a3,a3,-1704 # ffffffffc0202958 <commands+0x7d0>
ffffffffc0201008:	00001617          	auipc	a2,0x1
ffffffffc020100c:	7d860613          	addi	a2,a2,2008 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201010:	0cb00593          	li	a1,203
ffffffffc0201014:	00001517          	auipc	a0,0x1
ffffffffc0201018:	7e450513          	addi	a0,a0,2020 # ffffffffc02027f8 <commands+0x670>
ffffffffc020101c:	bb6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201020:	00002697          	auipc	a3,0x2
ffffffffc0201024:	91868693          	addi	a3,a3,-1768 # ffffffffc0202938 <commands+0x7b0>
ffffffffc0201028:	00001617          	auipc	a2,0x1
ffffffffc020102c:	7b860613          	addi	a2,a2,1976 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201030:	0c200593          	li	a1,194
ffffffffc0201034:	00001517          	auipc	a0,0x1
ffffffffc0201038:	7c450513          	addi	a0,a0,1988 # ffffffffc02027f8 <commands+0x670>
ffffffffc020103c:	b96ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != NULL);
ffffffffc0201040:	00002697          	auipc	a3,0x2
ffffffffc0201044:	98868693          	addi	a3,a3,-1656 # ffffffffc02029c8 <commands+0x840>
ffffffffc0201048:	00001617          	auipc	a2,0x1
ffffffffc020104c:	79860613          	addi	a2,a2,1944 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201050:	0f800593          	li	a1,248
ffffffffc0201054:	00001517          	auipc	a0,0x1
ffffffffc0201058:	7a450513          	addi	a0,a0,1956 # ffffffffc02027f8 <commands+0x670>
ffffffffc020105c:	b76ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc0201060:	00002697          	auipc	a3,0x2
ffffffffc0201064:	95868693          	addi	a3,a3,-1704 # ffffffffc02029b8 <commands+0x830>
ffffffffc0201068:	00001617          	auipc	a2,0x1
ffffffffc020106c:	77860613          	addi	a2,a2,1912 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201070:	0df00593          	li	a1,223
ffffffffc0201074:	00001517          	auipc	a0,0x1
ffffffffc0201078:	78450513          	addi	a0,a0,1924 # ffffffffc02027f8 <commands+0x670>
ffffffffc020107c:	b56ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201080:	00002697          	auipc	a3,0x2
ffffffffc0201084:	8d868693          	addi	a3,a3,-1832 # ffffffffc0202958 <commands+0x7d0>
ffffffffc0201088:	00001617          	auipc	a2,0x1
ffffffffc020108c:	75860613          	addi	a2,a2,1880 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201090:	0dd00593          	li	a1,221
ffffffffc0201094:	00001517          	auipc	a0,0x1
ffffffffc0201098:	76450513          	addi	a0,a0,1892 # ffffffffc02027f8 <commands+0x670>
ffffffffc020109c:	b36ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02010a0:	00002697          	auipc	a3,0x2
ffffffffc02010a4:	8f868693          	addi	a3,a3,-1800 # ffffffffc0202998 <commands+0x810>
ffffffffc02010a8:	00001617          	auipc	a2,0x1
ffffffffc02010ac:	73860613          	addi	a2,a2,1848 # ffffffffc02027e0 <commands+0x658>
ffffffffc02010b0:	0dc00593          	li	a1,220
ffffffffc02010b4:	00001517          	auipc	a0,0x1
ffffffffc02010b8:	74450513          	addi	a0,a0,1860 # ffffffffc02027f8 <commands+0x670>
ffffffffc02010bc:	b16ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010c0:	00001697          	auipc	a3,0x1
ffffffffc02010c4:	77068693          	addi	a3,a3,1904 # ffffffffc0202830 <commands+0x6a8>
ffffffffc02010c8:	00001617          	auipc	a2,0x1
ffffffffc02010cc:	71860613          	addi	a2,a2,1816 # ffffffffc02027e0 <commands+0x658>
ffffffffc02010d0:	0b900593          	li	a1,185
ffffffffc02010d4:	00001517          	auipc	a0,0x1
ffffffffc02010d8:	72450513          	addi	a0,a0,1828 # ffffffffc02027f8 <commands+0x670>
ffffffffc02010dc:	af6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010e0:	00002697          	auipc	a3,0x2
ffffffffc02010e4:	87868693          	addi	a3,a3,-1928 # ffffffffc0202958 <commands+0x7d0>
ffffffffc02010e8:	00001617          	auipc	a2,0x1
ffffffffc02010ec:	6f860613          	addi	a2,a2,1784 # ffffffffc02027e0 <commands+0x658>
ffffffffc02010f0:	0d600593          	li	a1,214
ffffffffc02010f4:	00001517          	auipc	a0,0x1
ffffffffc02010f8:	70450513          	addi	a0,a0,1796 # ffffffffc02027f8 <commands+0x670>
ffffffffc02010fc:	ad6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201100:	00001697          	auipc	a3,0x1
ffffffffc0201104:	77068693          	addi	a3,a3,1904 # ffffffffc0202870 <commands+0x6e8>
ffffffffc0201108:	00001617          	auipc	a2,0x1
ffffffffc020110c:	6d860613          	addi	a2,a2,1752 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201110:	0d400593          	li	a1,212
ffffffffc0201114:	00001517          	auipc	a0,0x1
ffffffffc0201118:	6e450513          	addi	a0,a0,1764 # ffffffffc02027f8 <commands+0x670>
ffffffffc020111c:	ab6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201120:	00001697          	auipc	a3,0x1
ffffffffc0201124:	73068693          	addi	a3,a3,1840 # ffffffffc0202850 <commands+0x6c8>
ffffffffc0201128:	00001617          	auipc	a2,0x1
ffffffffc020112c:	6b860613          	addi	a2,a2,1720 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201130:	0d300593          	li	a1,211
ffffffffc0201134:	00001517          	auipc	a0,0x1
ffffffffc0201138:	6c450513          	addi	a0,a0,1732 # ffffffffc02027f8 <commands+0x670>
ffffffffc020113c:	a96ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201140:	00001697          	auipc	a3,0x1
ffffffffc0201144:	73068693          	addi	a3,a3,1840 # ffffffffc0202870 <commands+0x6e8>
ffffffffc0201148:	00001617          	auipc	a2,0x1
ffffffffc020114c:	69860613          	addi	a2,a2,1688 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201150:	0bb00593          	li	a1,187
ffffffffc0201154:	00001517          	auipc	a0,0x1
ffffffffc0201158:	6a450513          	addi	a0,a0,1700 # ffffffffc02027f8 <commands+0x670>
ffffffffc020115c:	a76ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(count == 0);
ffffffffc0201160:	00002697          	auipc	a3,0x2
ffffffffc0201164:	9b868693          	addi	a3,a3,-1608 # ffffffffc0202b18 <commands+0x990>
ffffffffc0201168:	00001617          	auipc	a2,0x1
ffffffffc020116c:	67860613          	addi	a2,a2,1656 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201170:	12500593          	li	a1,293
ffffffffc0201174:	00001517          	auipc	a0,0x1
ffffffffc0201178:	68450513          	addi	a0,a0,1668 # ffffffffc02027f8 <commands+0x670>
ffffffffc020117c:	a56ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc0201180:	00002697          	auipc	a3,0x2
ffffffffc0201184:	83868693          	addi	a3,a3,-1992 # ffffffffc02029b8 <commands+0x830>
ffffffffc0201188:	00001617          	auipc	a2,0x1
ffffffffc020118c:	65860613          	addi	a2,a2,1624 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201190:	11a00593          	li	a1,282
ffffffffc0201194:	00001517          	auipc	a0,0x1
ffffffffc0201198:	66450513          	addi	a0,a0,1636 # ffffffffc02027f8 <commands+0x670>
ffffffffc020119c:	a36ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011a0:	00001697          	auipc	a3,0x1
ffffffffc02011a4:	7b868693          	addi	a3,a3,1976 # ffffffffc0202958 <commands+0x7d0>
ffffffffc02011a8:	00001617          	auipc	a2,0x1
ffffffffc02011ac:	63860613          	addi	a2,a2,1592 # ffffffffc02027e0 <commands+0x658>
ffffffffc02011b0:	11800593          	li	a1,280
ffffffffc02011b4:	00001517          	auipc	a0,0x1
ffffffffc02011b8:	64450513          	addi	a0,a0,1604 # ffffffffc02027f8 <commands+0x670>
ffffffffc02011bc:	a16ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02011c0:	00001697          	auipc	a3,0x1
ffffffffc02011c4:	75868693          	addi	a3,a3,1880 # ffffffffc0202918 <commands+0x790>
ffffffffc02011c8:	00001617          	auipc	a2,0x1
ffffffffc02011cc:	61860613          	addi	a2,a2,1560 # ffffffffc02027e0 <commands+0x658>
ffffffffc02011d0:	0c100593          	li	a1,193
ffffffffc02011d4:	00001517          	auipc	a0,0x1
ffffffffc02011d8:	62450513          	addi	a0,a0,1572 # ffffffffc02027f8 <commands+0x670>
ffffffffc02011dc:	9f6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011e0:	00002697          	auipc	a3,0x2
ffffffffc02011e4:	8f868693          	addi	a3,a3,-1800 # ffffffffc0202ad8 <commands+0x950>
ffffffffc02011e8:	00001617          	auipc	a2,0x1
ffffffffc02011ec:	5f860613          	addi	a2,a2,1528 # ffffffffc02027e0 <commands+0x658>
ffffffffc02011f0:	11200593          	li	a1,274
ffffffffc02011f4:	00001517          	auipc	a0,0x1
ffffffffc02011f8:	60450513          	addi	a0,a0,1540 # ffffffffc02027f8 <commands+0x670>
ffffffffc02011fc:	9d6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201200:	00002697          	auipc	a3,0x2
ffffffffc0201204:	8b868693          	addi	a3,a3,-1864 # ffffffffc0202ab8 <commands+0x930>
ffffffffc0201208:	00001617          	auipc	a2,0x1
ffffffffc020120c:	5d860613          	addi	a2,a2,1496 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201210:	11000593          	li	a1,272
ffffffffc0201214:	00001517          	auipc	a0,0x1
ffffffffc0201218:	5e450513          	addi	a0,a0,1508 # ffffffffc02027f8 <commands+0x670>
ffffffffc020121c:	9b6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201220:	00002697          	auipc	a3,0x2
ffffffffc0201224:	87068693          	addi	a3,a3,-1936 # ffffffffc0202a90 <commands+0x908>
ffffffffc0201228:	00001617          	auipc	a2,0x1
ffffffffc020122c:	5b860613          	addi	a2,a2,1464 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201230:	10e00593          	li	a1,270
ffffffffc0201234:	00001517          	auipc	a0,0x1
ffffffffc0201238:	5c450513          	addi	a0,a0,1476 # ffffffffc02027f8 <commands+0x670>
ffffffffc020123c:	996ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201240:	00002697          	auipc	a3,0x2
ffffffffc0201244:	82868693          	addi	a3,a3,-2008 # ffffffffc0202a68 <commands+0x8e0>
ffffffffc0201248:	00001617          	auipc	a2,0x1
ffffffffc020124c:	59860613          	addi	a2,a2,1432 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201250:	10d00593          	li	a1,269
ffffffffc0201254:	00001517          	auipc	a0,0x1
ffffffffc0201258:	5a450513          	addi	a0,a0,1444 # ffffffffc02027f8 <commands+0x670>
ffffffffc020125c:	976ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201260:	00001697          	auipc	a3,0x1
ffffffffc0201264:	7f868693          	addi	a3,a3,2040 # ffffffffc0202a58 <commands+0x8d0>
ffffffffc0201268:	00001617          	auipc	a2,0x1
ffffffffc020126c:	57860613          	addi	a2,a2,1400 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201270:	10800593          	li	a1,264
ffffffffc0201274:	00001517          	auipc	a0,0x1
ffffffffc0201278:	58450513          	addi	a0,a0,1412 # ffffffffc02027f8 <commands+0x670>
ffffffffc020127c:	956ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201280:	00001697          	auipc	a3,0x1
ffffffffc0201284:	6d868693          	addi	a3,a3,1752 # ffffffffc0202958 <commands+0x7d0>
ffffffffc0201288:	00001617          	auipc	a2,0x1
ffffffffc020128c:	55860613          	addi	a2,a2,1368 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201290:	10700593          	li	a1,263
ffffffffc0201294:	00001517          	auipc	a0,0x1
ffffffffc0201298:	56450513          	addi	a0,a0,1380 # ffffffffc02027f8 <commands+0x670>
ffffffffc020129c:	936ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02012a0:	00001697          	auipc	a3,0x1
ffffffffc02012a4:	79868693          	addi	a3,a3,1944 # ffffffffc0202a38 <commands+0x8b0>
ffffffffc02012a8:	00001617          	auipc	a2,0x1
ffffffffc02012ac:	53860613          	addi	a2,a2,1336 # ffffffffc02027e0 <commands+0x658>
ffffffffc02012b0:	10600593          	li	a1,262
ffffffffc02012b4:	00001517          	auipc	a0,0x1
ffffffffc02012b8:	54450513          	addi	a0,a0,1348 # ffffffffc02027f8 <commands+0x670>
ffffffffc02012bc:	916ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02012c0:	00001697          	auipc	a3,0x1
ffffffffc02012c4:	74868693          	addi	a3,a3,1864 # ffffffffc0202a08 <commands+0x880>
ffffffffc02012c8:	00001617          	auipc	a2,0x1
ffffffffc02012cc:	51860613          	addi	a2,a2,1304 # ffffffffc02027e0 <commands+0x658>
ffffffffc02012d0:	10500593          	li	a1,261
ffffffffc02012d4:	00001517          	auipc	a0,0x1
ffffffffc02012d8:	52450513          	addi	a0,a0,1316 # ffffffffc02027f8 <commands+0x670>
ffffffffc02012dc:	8f6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02012e0:	00001697          	auipc	a3,0x1
ffffffffc02012e4:	71068693          	addi	a3,a3,1808 # ffffffffc02029f0 <commands+0x868>
ffffffffc02012e8:	00001617          	auipc	a2,0x1
ffffffffc02012ec:	4f860613          	addi	a2,a2,1272 # ffffffffc02027e0 <commands+0x658>
ffffffffc02012f0:	10400593          	li	a1,260
ffffffffc02012f4:	00001517          	auipc	a0,0x1
ffffffffc02012f8:	50450513          	addi	a0,a0,1284 # ffffffffc02027f8 <commands+0x670>
ffffffffc02012fc:	8d6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201300:	00001697          	auipc	a3,0x1
ffffffffc0201304:	65868693          	addi	a3,a3,1624 # ffffffffc0202958 <commands+0x7d0>
ffffffffc0201308:	00001617          	auipc	a2,0x1
ffffffffc020130c:	4d860613          	addi	a2,a2,1240 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201310:	0fe00593          	li	a1,254
ffffffffc0201314:	00001517          	auipc	a0,0x1
ffffffffc0201318:	4e450513          	addi	a0,a0,1252 # ffffffffc02027f8 <commands+0x670>
ffffffffc020131c:	8b6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201320:	00001697          	auipc	a3,0x1
ffffffffc0201324:	6b868693          	addi	a3,a3,1720 # ffffffffc02029d8 <commands+0x850>
ffffffffc0201328:	00001617          	auipc	a2,0x1
ffffffffc020132c:	4b860613          	addi	a2,a2,1208 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201330:	0f900593          	li	a1,249
ffffffffc0201334:	00001517          	auipc	a0,0x1
ffffffffc0201338:	4c450513          	addi	a0,a0,1220 # ffffffffc02027f8 <commands+0x670>
ffffffffc020133c:	896ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201340:	00001697          	auipc	a3,0x1
ffffffffc0201344:	7b868693          	addi	a3,a3,1976 # ffffffffc0202af8 <commands+0x970>
ffffffffc0201348:	00001617          	auipc	a2,0x1
ffffffffc020134c:	49860613          	addi	a2,a2,1176 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201350:	11700593          	li	a1,279
ffffffffc0201354:	00001517          	auipc	a0,0x1
ffffffffc0201358:	4a450513          	addi	a0,a0,1188 # ffffffffc02027f8 <commands+0x670>
ffffffffc020135c:	876ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == 0);
ffffffffc0201360:	00001697          	auipc	a3,0x1
ffffffffc0201364:	7c868693          	addi	a3,a3,1992 # ffffffffc0202b28 <commands+0x9a0>
ffffffffc0201368:	00001617          	auipc	a2,0x1
ffffffffc020136c:	47860613          	addi	a2,a2,1144 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201370:	12600593          	li	a1,294
ffffffffc0201374:	00001517          	auipc	a0,0x1
ffffffffc0201378:	48450513          	addi	a0,a0,1156 # ffffffffc02027f8 <commands+0x670>
ffffffffc020137c:	856ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201380:	00001697          	auipc	a3,0x1
ffffffffc0201384:	49068693          	addi	a3,a3,1168 # ffffffffc0202810 <commands+0x688>
ffffffffc0201388:	00001617          	auipc	a2,0x1
ffffffffc020138c:	45860613          	addi	a2,a2,1112 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201390:	0f300593          	li	a1,243
ffffffffc0201394:	00001517          	auipc	a0,0x1
ffffffffc0201398:	46450513          	addi	a0,a0,1124 # ffffffffc02027f8 <commands+0x670>
ffffffffc020139c:	836ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013a0:	00001697          	auipc	a3,0x1
ffffffffc02013a4:	4b068693          	addi	a3,a3,1200 # ffffffffc0202850 <commands+0x6c8>
ffffffffc02013a8:	00001617          	auipc	a2,0x1
ffffffffc02013ac:	43860613          	addi	a2,a2,1080 # ffffffffc02027e0 <commands+0x658>
ffffffffc02013b0:	0ba00593          	li	a1,186
ffffffffc02013b4:	00001517          	auipc	a0,0x1
ffffffffc02013b8:	44450513          	addi	a0,a0,1092 # ffffffffc02027f8 <commands+0x670>
ffffffffc02013bc:	816ff0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc02013c0 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02013c0:	1141                	addi	sp,sp,-16
ffffffffc02013c2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02013c4:	14058a63          	beqz	a1,ffffffffc0201518 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02013c8:	00259693          	slli	a3,a1,0x2
ffffffffc02013cc:	96ae                	add	a3,a3,a1
ffffffffc02013ce:	068e                	slli	a3,a3,0x3
ffffffffc02013d0:	96aa                	add	a3,a3,a0
ffffffffc02013d2:	87aa                	mv	a5,a0
ffffffffc02013d4:	02d50263          	beq	a0,a3,ffffffffc02013f8 <default_free_pages+0x38>
ffffffffc02013d8:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02013da:	8b05                	andi	a4,a4,1
ffffffffc02013dc:	10071e63          	bnez	a4,ffffffffc02014f8 <default_free_pages+0x138>
ffffffffc02013e0:	6798                	ld	a4,8(a5)
ffffffffc02013e2:	8b09                	andi	a4,a4,2
ffffffffc02013e4:	10071a63          	bnez	a4,ffffffffc02014f8 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc02013e8:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02013ec:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02013f0:	02878793          	addi	a5,a5,40
ffffffffc02013f4:	fed792e3          	bne	a5,a3,ffffffffc02013d8 <default_free_pages+0x18>
    base->property = n;
ffffffffc02013f8:	2581                	sext.w	a1,a1
ffffffffc02013fa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02013fc:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201400:	4789                	li	a5,2
ffffffffc0201402:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201406:	00005697          	auipc	a3,0x5
ffffffffc020140a:	c2268693          	addi	a3,a3,-990 # ffffffffc0206028 <free_area>
ffffffffc020140e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201410:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201412:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201416:	9db9                	addw	a1,a1,a4
ffffffffc0201418:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020141a:	0ad78863          	beq	a5,a3,ffffffffc02014ca <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc020141e:	fe878713          	addi	a4,a5,-24
ffffffffc0201422:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201426:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201428:	00e56a63          	bltu	a0,a4,ffffffffc020143c <default_free_pages+0x7c>
    return listelm->next;
ffffffffc020142c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020142e:	06d70263          	beq	a4,a3,ffffffffc0201492 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201432:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201434:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201438:	fee57ae3          	bgeu	a0,a4,ffffffffc020142c <default_free_pages+0x6c>
ffffffffc020143c:	c199                	beqz	a1,ffffffffc0201442 <default_free_pages+0x82>
ffffffffc020143e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201442:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201444:	e390                	sd	a2,0(a5)
ffffffffc0201446:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201448:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020144a:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020144c:	02d70063          	beq	a4,a3,ffffffffc020146c <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201450:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201454:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201458:	02081613          	slli	a2,a6,0x20
ffffffffc020145c:	9201                	srli	a2,a2,0x20
ffffffffc020145e:	00261793          	slli	a5,a2,0x2
ffffffffc0201462:	97b2                	add	a5,a5,a2
ffffffffc0201464:	078e                	slli	a5,a5,0x3
ffffffffc0201466:	97ae                	add	a5,a5,a1
ffffffffc0201468:	02f50f63          	beq	a0,a5,ffffffffc02014a6 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc020146c:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020146e:	00d70f63          	beq	a4,a3,ffffffffc020148c <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201472:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201474:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201478:	02059613          	slli	a2,a1,0x20
ffffffffc020147c:	9201                	srli	a2,a2,0x20
ffffffffc020147e:	00261793          	slli	a5,a2,0x2
ffffffffc0201482:	97b2                	add	a5,a5,a2
ffffffffc0201484:	078e                	slli	a5,a5,0x3
ffffffffc0201486:	97aa                	add	a5,a5,a0
ffffffffc0201488:	04f68863          	beq	a3,a5,ffffffffc02014d8 <default_free_pages+0x118>
}
ffffffffc020148c:	60a2                	ld	ra,8(sp)
ffffffffc020148e:	0141                	addi	sp,sp,16
ffffffffc0201490:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201492:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201494:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201496:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201498:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020149a:	02d70563          	beq	a4,a3,ffffffffc02014c4 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc020149e:	8832                	mv	a6,a2
ffffffffc02014a0:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02014a2:	87ba                	mv	a5,a4
ffffffffc02014a4:	bf41                	j	ffffffffc0201434 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc02014a6:	491c                	lw	a5,16(a0)
ffffffffc02014a8:	0107883b          	addw	a6,a5,a6
ffffffffc02014ac:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014b0:	57f5                	li	a5,-3
ffffffffc02014b2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014b6:	6d10                	ld	a2,24(a0)
ffffffffc02014b8:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02014ba:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02014bc:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02014be:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02014c0:	e390                	sd	a2,0(a5)
ffffffffc02014c2:	b775                	j	ffffffffc020146e <default_free_pages+0xae>
ffffffffc02014c4:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014c6:	873e                	mv	a4,a5
ffffffffc02014c8:	b761                	j	ffffffffc0201450 <default_free_pages+0x90>
}
ffffffffc02014ca:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02014cc:	e390                	sd	a2,0(a5)
ffffffffc02014ce:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014d0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014d2:	ed1c                	sd	a5,24(a0)
ffffffffc02014d4:	0141                	addi	sp,sp,16
ffffffffc02014d6:	8082                	ret
            base->property += p->property;
ffffffffc02014d8:	ff872783          	lw	a5,-8(a4)
ffffffffc02014dc:	ff070693          	addi	a3,a4,-16
ffffffffc02014e0:	9dbd                	addw	a1,a1,a5
ffffffffc02014e2:	c90c                	sw	a1,16(a0)
ffffffffc02014e4:	57f5                	li	a5,-3
ffffffffc02014e6:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014ea:	6314                	ld	a3,0(a4)
ffffffffc02014ec:	671c                	ld	a5,8(a4)
}
ffffffffc02014ee:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02014f0:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02014f2:	e394                	sd	a3,0(a5)
ffffffffc02014f4:	0141                	addi	sp,sp,16
ffffffffc02014f6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014f8:	00001697          	auipc	a3,0x1
ffffffffc02014fc:	64868693          	addi	a3,a3,1608 # ffffffffc0202b40 <commands+0x9b8>
ffffffffc0201500:	00001617          	auipc	a2,0x1
ffffffffc0201504:	2e060613          	addi	a2,a2,736 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201508:	08300593          	li	a1,131
ffffffffc020150c:	00001517          	auipc	a0,0x1
ffffffffc0201510:	2ec50513          	addi	a0,a0,748 # ffffffffc02027f8 <commands+0x670>
ffffffffc0201514:	ebffe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc0201518:	00001697          	auipc	a3,0x1
ffffffffc020151c:	62068693          	addi	a3,a3,1568 # ffffffffc0202b38 <commands+0x9b0>
ffffffffc0201520:	00001617          	auipc	a2,0x1
ffffffffc0201524:	2c060613          	addi	a2,a2,704 # ffffffffc02027e0 <commands+0x658>
ffffffffc0201528:	08000593          	li	a1,128
ffffffffc020152c:	00001517          	auipc	a0,0x1
ffffffffc0201530:	2cc50513          	addi	a0,a0,716 # ffffffffc02027f8 <commands+0x670>
ffffffffc0201534:	e9ffe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201538 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201538:	c959                	beqz	a0,ffffffffc02015ce <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc020153a:	00005597          	auipc	a1,0x5
ffffffffc020153e:	aee58593          	addi	a1,a1,-1298 # ffffffffc0206028 <free_area>
ffffffffc0201542:	0105a803          	lw	a6,16(a1)
ffffffffc0201546:	862a                	mv	a2,a0
ffffffffc0201548:	02081793          	slli	a5,a6,0x20
ffffffffc020154c:	9381                	srli	a5,a5,0x20
ffffffffc020154e:	00a7ee63          	bltu	a5,a0,ffffffffc020156a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201552:	87ae                	mv	a5,a1
ffffffffc0201554:	a801                	j	ffffffffc0201564 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201556:	ff87a703          	lw	a4,-8(a5)
ffffffffc020155a:	02071693          	slli	a3,a4,0x20
ffffffffc020155e:	9281                	srli	a3,a3,0x20
ffffffffc0201560:	00c6f763          	bgeu	a3,a2,ffffffffc020156e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201564:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201566:	feb798e3          	bne	a5,a1,ffffffffc0201556 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020156a:	4501                	li	a0,0
}
ffffffffc020156c:	8082                	ret
    return listelm->prev;
ffffffffc020156e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201572:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201576:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020157a:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc020157e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201582:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201586:	02d67b63          	bgeu	a2,a3,ffffffffc02015bc <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020158a:	00261693          	slli	a3,a2,0x2
ffffffffc020158e:	96b2                	add	a3,a3,a2
ffffffffc0201590:	068e                	slli	a3,a3,0x3
ffffffffc0201592:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201594:	41c7073b          	subw	a4,a4,t3
ffffffffc0201598:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020159a:	00868613          	addi	a2,a3,8
ffffffffc020159e:	4709                	li	a4,2
ffffffffc02015a0:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015a4:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02015a8:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc02015ac:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02015b0:	e310                	sd	a2,0(a4)
ffffffffc02015b2:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02015b6:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc02015b8:	0116bc23          	sd	a7,24(a3)
ffffffffc02015bc:	41c8083b          	subw	a6,a6,t3
ffffffffc02015c0:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015c4:	5775                	li	a4,-3
ffffffffc02015c6:	17c1                	addi	a5,a5,-16
ffffffffc02015c8:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02015cc:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02015ce:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02015d0:	00001697          	auipc	a3,0x1
ffffffffc02015d4:	56868693          	addi	a3,a3,1384 # ffffffffc0202b38 <commands+0x9b0>
ffffffffc02015d8:	00001617          	auipc	a2,0x1
ffffffffc02015dc:	20860613          	addi	a2,a2,520 # ffffffffc02027e0 <commands+0x658>
ffffffffc02015e0:	06200593          	li	a1,98
ffffffffc02015e4:	00001517          	auipc	a0,0x1
ffffffffc02015e8:	21450513          	addi	a0,a0,532 # ffffffffc02027f8 <commands+0x670>
default_alloc_pages(size_t n) {
ffffffffc02015ec:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015ee:	de5fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc02015f2 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02015f2:	1141                	addi	sp,sp,-16
ffffffffc02015f4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015f6:	c9e1                	beqz	a1,ffffffffc02016c6 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02015f8:	00259693          	slli	a3,a1,0x2
ffffffffc02015fc:	96ae                	add	a3,a3,a1
ffffffffc02015fe:	068e                	slli	a3,a3,0x3
ffffffffc0201600:	96aa                	add	a3,a3,a0
ffffffffc0201602:	87aa                	mv	a5,a0
ffffffffc0201604:	00d50f63          	beq	a0,a3,ffffffffc0201622 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201608:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020160a:	8b05                	andi	a4,a4,1
ffffffffc020160c:	cf49                	beqz	a4,ffffffffc02016a6 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020160e:	0007a823          	sw	zero,16(a5)
ffffffffc0201612:	0007b423          	sd	zero,8(a5)
ffffffffc0201616:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020161a:	02878793          	addi	a5,a5,40
ffffffffc020161e:	fed795e3          	bne	a5,a3,ffffffffc0201608 <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201622:	2581                	sext.w	a1,a1
ffffffffc0201624:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201626:	4789                	li	a5,2
ffffffffc0201628:	00850713          	addi	a4,a0,8
ffffffffc020162c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201630:	00005697          	auipc	a3,0x5
ffffffffc0201634:	9f868693          	addi	a3,a3,-1544 # ffffffffc0206028 <free_area>
ffffffffc0201638:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020163a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020163c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201640:	9db9                	addw	a1,a1,a4
ffffffffc0201642:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201644:	04d78a63          	beq	a5,a3,ffffffffc0201698 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201648:	fe878713          	addi	a4,a5,-24
ffffffffc020164c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201650:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201652:	00e56a63          	bltu	a0,a4,ffffffffc0201666 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc0201656:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201658:	02d70263          	beq	a4,a3,ffffffffc020167c <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc020165c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020165e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201662:	fee57ae3          	bgeu	a0,a4,ffffffffc0201656 <default_init_memmap+0x64>
ffffffffc0201666:	c199                	beqz	a1,ffffffffc020166c <default_init_memmap+0x7a>
ffffffffc0201668:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020166c:	6398                	ld	a4,0(a5)
}
ffffffffc020166e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201670:	e390                	sd	a2,0(a5)
ffffffffc0201672:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201674:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201676:	ed18                	sd	a4,24(a0)
ffffffffc0201678:	0141                	addi	sp,sp,16
ffffffffc020167a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020167c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020167e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201680:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201682:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201684:	00d70663          	beq	a4,a3,ffffffffc0201690 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201688:	8832                	mv	a6,a2
ffffffffc020168a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020168c:	87ba                	mv	a5,a4
ffffffffc020168e:	bfc1                	j	ffffffffc020165e <default_init_memmap+0x6c>
}
ffffffffc0201690:	60a2                	ld	ra,8(sp)
ffffffffc0201692:	e290                	sd	a2,0(a3)
ffffffffc0201694:	0141                	addi	sp,sp,16
ffffffffc0201696:	8082                	ret
ffffffffc0201698:	60a2                	ld	ra,8(sp)
ffffffffc020169a:	e390                	sd	a2,0(a5)
ffffffffc020169c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020169e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016a0:	ed1c                	sd	a5,24(a0)
ffffffffc02016a2:	0141                	addi	sp,sp,16
ffffffffc02016a4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016a6:	00001697          	auipc	a3,0x1
ffffffffc02016aa:	4c268693          	addi	a3,a3,1218 # ffffffffc0202b68 <commands+0x9e0>
ffffffffc02016ae:	00001617          	auipc	a2,0x1
ffffffffc02016b2:	13260613          	addi	a2,a2,306 # ffffffffc02027e0 <commands+0x658>
ffffffffc02016b6:	04900593          	li	a1,73
ffffffffc02016ba:	00001517          	auipc	a0,0x1
ffffffffc02016be:	13e50513          	addi	a0,a0,318 # ffffffffc02027f8 <commands+0x670>
ffffffffc02016c2:	d11fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc02016c6:	00001697          	auipc	a3,0x1
ffffffffc02016ca:	47268693          	addi	a3,a3,1138 # ffffffffc0202b38 <commands+0x9b0>
ffffffffc02016ce:	00001617          	auipc	a2,0x1
ffffffffc02016d2:	11260613          	addi	a2,a2,274 # ffffffffc02027e0 <commands+0x658>
ffffffffc02016d6:	04600593          	li	a1,70
ffffffffc02016da:	00001517          	auipc	a0,0x1
ffffffffc02016de:	11e50513          	addi	a0,a0,286 # ffffffffc02027f8 <commands+0x670>
ffffffffc02016e2:	cf1fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc02016e6 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016e6:	100027f3          	csrr	a5,sstatus
ffffffffc02016ea:	8b89                	andi	a5,a5,2
ffffffffc02016ec:	e799                	bnez	a5,ffffffffc02016fa <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016ee:	00005797          	auipc	a5,0x5
ffffffffc02016f2:	d8a7b783          	ld	a5,-630(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02016f6:	6f9c                	ld	a5,24(a5)
ffffffffc02016f8:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02016fa:	1141                	addi	sp,sp,-16
ffffffffc02016fc:	e406                	sd	ra,8(sp)
ffffffffc02016fe:	e022                	sd	s0,0(sp)
ffffffffc0201700:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201702:	932ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201706:	00005797          	auipc	a5,0x5
ffffffffc020170a:	d727b783          	ld	a5,-654(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020170e:	6f9c                	ld	a5,24(a5)
ffffffffc0201710:	8522                	mv	a0,s0
ffffffffc0201712:	9782                	jalr	a5
ffffffffc0201714:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201716:	918ff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020171a:	60a2                	ld	ra,8(sp)
ffffffffc020171c:	8522                	mv	a0,s0
ffffffffc020171e:	6402                	ld	s0,0(sp)
ffffffffc0201720:	0141                	addi	sp,sp,16
ffffffffc0201722:	8082                	ret

ffffffffc0201724 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201724:	100027f3          	csrr	a5,sstatus
ffffffffc0201728:	8b89                	andi	a5,a5,2
ffffffffc020172a:	e799                	bnez	a5,ffffffffc0201738 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020172c:	00005797          	auipc	a5,0x5
ffffffffc0201730:	d4c7b783          	ld	a5,-692(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201734:	739c                	ld	a5,32(a5)
ffffffffc0201736:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201738:	1101                	addi	sp,sp,-32
ffffffffc020173a:	ec06                	sd	ra,24(sp)
ffffffffc020173c:	e822                	sd	s0,16(sp)
ffffffffc020173e:	e426                	sd	s1,8(sp)
ffffffffc0201740:	842a                	mv	s0,a0
ffffffffc0201742:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201744:	8f0ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201748:	00005797          	auipc	a5,0x5
ffffffffc020174c:	d307b783          	ld	a5,-720(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201750:	739c                	ld	a5,32(a5)
ffffffffc0201752:	85a6                	mv	a1,s1
ffffffffc0201754:	8522                	mv	a0,s0
ffffffffc0201756:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201758:	6442                	ld	s0,16(sp)
ffffffffc020175a:	60e2                	ld	ra,24(sp)
ffffffffc020175c:	64a2                	ld	s1,8(sp)
ffffffffc020175e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201760:	8ceff06f          	j	ffffffffc020082e <intr_enable>

ffffffffc0201764 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201764:	100027f3          	csrr	a5,sstatus
ffffffffc0201768:	8b89                	andi	a5,a5,2
ffffffffc020176a:	e799                	bnez	a5,ffffffffc0201778 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020176c:	00005797          	auipc	a5,0x5
ffffffffc0201770:	d0c7b783          	ld	a5,-756(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201774:	779c                	ld	a5,40(a5)
ffffffffc0201776:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201778:	1141                	addi	sp,sp,-16
ffffffffc020177a:	e406                	sd	ra,8(sp)
ffffffffc020177c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020177e:	8b6ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201782:	00005797          	auipc	a5,0x5
ffffffffc0201786:	cf67b783          	ld	a5,-778(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020178a:	779c                	ld	a5,40(a5)
ffffffffc020178c:	9782                	jalr	a5
ffffffffc020178e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201790:	89eff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201794:	60a2                	ld	ra,8(sp)
ffffffffc0201796:	8522                	mv	a0,s0
ffffffffc0201798:	6402                	ld	s0,0(sp)
ffffffffc020179a:	0141                	addi	sp,sp,16
ffffffffc020179c:	8082                	ret

ffffffffc020179e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020179e:	00001797          	auipc	a5,0x1
ffffffffc02017a2:	3f278793          	addi	a5,a5,1010 # ffffffffc0202b90 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017a6:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017a8:	7179                	addi	sp,sp,-48
ffffffffc02017aa:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017ac:	00001517          	auipc	a0,0x1
ffffffffc02017b0:	41c50513          	addi	a0,a0,1052 # ffffffffc0202bc8 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc02017b4:	00005417          	auipc	s0,0x5
ffffffffc02017b8:	cc440413          	addi	s0,s0,-828 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc02017bc:	f406                	sd	ra,40(sp)
ffffffffc02017be:	ec26                	sd	s1,24(sp)
ffffffffc02017c0:	e44e                	sd	s3,8(sp)
ffffffffc02017c2:	e84a                	sd	s2,16(sp)
ffffffffc02017c4:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02017c6:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017c8:	911fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc02017cc:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017ce:	00005497          	auipc	s1,0x5
ffffffffc02017d2:	cc248493          	addi	s1,s1,-830 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017d6:	679c                	ld	a5,8(a5)
ffffffffc02017d8:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017da:	57f5                	li	a5,-3
ffffffffc02017dc:	07fa                	slli	a5,a5,0x1e
ffffffffc02017de:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02017e0:	83aff0ef          	jal	ra,ffffffffc020081a <get_memory_base>
ffffffffc02017e4:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017e6:	83eff0ef          	jal	ra,ffffffffc0200824 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017ea:	16050163          	beqz	a0,ffffffffc020194c <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017ee:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02017f0:	00001517          	auipc	a0,0x1
ffffffffc02017f4:	42050513          	addi	a0,a0,1056 # ffffffffc0202c10 <default_pmm_manager+0x80>
ffffffffc02017f8:	8e1fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017fc:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201800:	864e                	mv	a2,s3
ffffffffc0201802:	fffa0693          	addi	a3,s4,-1
ffffffffc0201806:	85ca                	mv	a1,s2
ffffffffc0201808:	00001517          	auipc	a0,0x1
ffffffffc020180c:	42050513          	addi	a0,a0,1056 # ffffffffc0202c28 <default_pmm_manager+0x98>
ffffffffc0201810:	8c9fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201814:	c80007b7          	lui	a5,0xc8000
ffffffffc0201818:	8652                	mv	a2,s4
ffffffffc020181a:	0d47e863          	bltu	a5,s4,ffffffffc02018ea <pmm_init+0x14c>
ffffffffc020181e:	00006797          	auipc	a5,0x6
ffffffffc0201822:	c8178793          	addi	a5,a5,-895 # ffffffffc020749f <end+0xfff>
ffffffffc0201826:	757d                	lui	a0,0xfffff
ffffffffc0201828:	8d7d                	and	a0,a0,a5
ffffffffc020182a:	8231                	srli	a2,a2,0xc
ffffffffc020182c:	00005597          	auipc	a1,0x5
ffffffffc0201830:	c3c58593          	addi	a1,a1,-964 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201834:	00005817          	auipc	a6,0x5
ffffffffc0201838:	c3c80813          	addi	a6,a6,-964 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020183c:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020183e:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201842:	000807b7          	lui	a5,0x80
ffffffffc0201846:	02f60663          	beq	a2,a5,ffffffffc0201872 <pmm_init+0xd4>
ffffffffc020184a:	4701                	li	a4,0
ffffffffc020184c:	4781                	li	a5,0
ffffffffc020184e:	4305                	li	t1,1
ffffffffc0201850:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201854:	953a                	add	a0,a0,a4
ffffffffc0201856:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc020185a:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020185e:	6190                	ld	a2,0(a1)
ffffffffc0201860:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201862:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201866:	011606b3          	add	a3,a2,a7
ffffffffc020186a:	02870713          	addi	a4,a4,40
ffffffffc020186e:	fed7e3e3          	bltu	a5,a3,ffffffffc0201854 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201872:	00261693          	slli	a3,a2,0x2
ffffffffc0201876:	96b2                	add	a3,a3,a2
ffffffffc0201878:	fec007b7          	lui	a5,0xfec00
ffffffffc020187c:	97aa                	add	a5,a5,a0
ffffffffc020187e:	068e                	slli	a3,a3,0x3
ffffffffc0201880:	96be                	add	a3,a3,a5
ffffffffc0201882:	c02007b7          	lui	a5,0xc0200
ffffffffc0201886:	0af6e763          	bltu	a3,a5,ffffffffc0201934 <pmm_init+0x196>
ffffffffc020188a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020188c:	77fd                	lui	a5,0xfffff
ffffffffc020188e:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201892:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201894:	04b6ee63          	bltu	a3,a1,ffffffffc02018f0 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201898:	601c                	ld	a5,0(s0)
ffffffffc020189a:	7b9c                	ld	a5,48(a5)
ffffffffc020189c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020189e:	00001517          	auipc	a0,0x1
ffffffffc02018a2:	41250513          	addi	a0,a0,1042 # ffffffffc0202cb0 <default_pmm_manager+0x120>
ffffffffc02018a6:	833fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018aa:	00003597          	auipc	a1,0x3
ffffffffc02018ae:	75658593          	addi	a1,a1,1878 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02018b2:	00005797          	auipc	a5,0x5
ffffffffc02018b6:	bcb7bb23          	sd	a1,-1066(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018ba:	c02007b7          	lui	a5,0xc0200
ffffffffc02018be:	0af5e363          	bltu	a1,a5,ffffffffc0201964 <pmm_init+0x1c6>
ffffffffc02018c2:	6090                	ld	a2,0(s1)
}
ffffffffc02018c4:	7402                	ld	s0,32(sp)
ffffffffc02018c6:	70a2                	ld	ra,40(sp)
ffffffffc02018c8:	64e2                	ld	s1,24(sp)
ffffffffc02018ca:	6942                	ld	s2,16(sp)
ffffffffc02018cc:	69a2                	ld	s3,8(sp)
ffffffffc02018ce:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018d0:	40c58633          	sub	a2,a1,a2
ffffffffc02018d4:	00005797          	auipc	a5,0x5
ffffffffc02018d8:	bac7b623          	sd	a2,-1108(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018dc:	00001517          	auipc	a0,0x1
ffffffffc02018e0:	3f450513          	addi	a0,a0,1012 # ffffffffc0202cd0 <default_pmm_manager+0x140>
}
ffffffffc02018e4:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018e6:	ff2fe06f          	j	ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018ea:	c8000637          	lui	a2,0xc8000
ffffffffc02018ee:	bf05                	j	ffffffffc020181e <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018f0:	6705                	lui	a4,0x1
ffffffffc02018f2:	177d                	addi	a4,a4,-1
ffffffffc02018f4:	96ba                	add	a3,a3,a4
ffffffffc02018f6:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02018f8:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018fc:	02c7f063          	bgeu	a5,a2,ffffffffc020191c <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0201900:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201902:	fff80737          	lui	a4,0xfff80
ffffffffc0201906:	973e                	add	a4,a4,a5
ffffffffc0201908:	00271793          	slli	a5,a4,0x2
ffffffffc020190c:	97ba                	add	a5,a5,a4
ffffffffc020190e:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201910:	8d95                	sub	a1,a1,a3
ffffffffc0201912:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201914:	81b1                	srli	a1,a1,0xc
ffffffffc0201916:	953e                	add	a0,a0,a5
ffffffffc0201918:	9702                	jalr	a4
}
ffffffffc020191a:	bfbd                	j	ffffffffc0201898 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc020191c:	00001617          	auipc	a2,0x1
ffffffffc0201920:	36460613          	addi	a2,a2,868 # ffffffffc0202c80 <default_pmm_manager+0xf0>
ffffffffc0201924:	06b00593          	li	a1,107
ffffffffc0201928:	00001517          	auipc	a0,0x1
ffffffffc020192c:	37850513          	addi	a0,a0,888 # ffffffffc0202ca0 <default_pmm_manager+0x110>
ffffffffc0201930:	aa3fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201934:	00001617          	auipc	a2,0x1
ffffffffc0201938:	32460613          	addi	a2,a2,804 # ffffffffc0202c58 <default_pmm_manager+0xc8>
ffffffffc020193c:	07100593          	li	a1,113
ffffffffc0201940:	00001517          	auipc	a0,0x1
ffffffffc0201944:	2c050513          	addi	a0,a0,704 # ffffffffc0202c00 <default_pmm_manager+0x70>
ffffffffc0201948:	a8bfe0ef          	jal	ra,ffffffffc02003d2 <__panic>
        panic("DTB memory info not available");
ffffffffc020194c:	00001617          	auipc	a2,0x1
ffffffffc0201950:	29460613          	addi	a2,a2,660 # ffffffffc0202be0 <default_pmm_manager+0x50>
ffffffffc0201954:	05a00593          	li	a1,90
ffffffffc0201958:	00001517          	auipc	a0,0x1
ffffffffc020195c:	2a850513          	addi	a0,a0,680 # ffffffffc0202c00 <default_pmm_manager+0x70>
ffffffffc0201960:	a73fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201964:	86ae                	mv	a3,a1
ffffffffc0201966:	00001617          	auipc	a2,0x1
ffffffffc020196a:	2f260613          	addi	a2,a2,754 # ffffffffc0202c58 <default_pmm_manager+0xc8>
ffffffffc020196e:	08c00593          	li	a1,140
ffffffffc0201972:	00001517          	auipc	a0,0x1
ffffffffc0201976:	28e50513          	addi	a0,a0,654 # ffffffffc0202c00 <default_pmm_manager+0x70>
ffffffffc020197a:	a59fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020197e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020197e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201982:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201984:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201988:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020198a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020198e:	f022                	sd	s0,32(sp)
ffffffffc0201990:	ec26                	sd	s1,24(sp)
ffffffffc0201992:	e84a                	sd	s2,16(sp)
ffffffffc0201994:	f406                	sd	ra,40(sp)
ffffffffc0201996:	e44e                	sd	s3,8(sp)
ffffffffc0201998:	84aa                	mv	s1,a0
ffffffffc020199a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020199c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019a0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02019a2:	03067e63          	bgeu	a2,a6,ffffffffc02019de <printnum+0x60>
ffffffffc02019a6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019a8:	00805763          	blez	s0,ffffffffc02019b6 <printnum+0x38>
ffffffffc02019ac:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019ae:	85ca                	mv	a1,s2
ffffffffc02019b0:	854e                	mv	a0,s3
ffffffffc02019b2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019b4:	fc65                	bnez	s0,ffffffffc02019ac <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019b6:	1a02                	slli	s4,s4,0x20
ffffffffc02019b8:	00001797          	auipc	a5,0x1
ffffffffc02019bc:	35878793          	addi	a5,a5,856 # ffffffffc0202d10 <default_pmm_manager+0x180>
ffffffffc02019c0:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019c4:	9a3e                	add	s4,s4,a5
}
ffffffffc02019c6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019c8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02019cc:	70a2                	ld	ra,40(sp)
ffffffffc02019ce:	69a2                	ld	s3,8(sp)
ffffffffc02019d0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019d2:	85ca                	mv	a1,s2
ffffffffc02019d4:	87a6                	mv	a5,s1
}
ffffffffc02019d6:	6942                	ld	s2,16(sp)
ffffffffc02019d8:	64e2                	ld	s1,24(sp)
ffffffffc02019da:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019dc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019de:	03065633          	divu	a2,a2,a6
ffffffffc02019e2:	8722                	mv	a4,s0
ffffffffc02019e4:	f9bff0ef          	jal	ra,ffffffffc020197e <printnum>
ffffffffc02019e8:	b7f9                	j	ffffffffc02019b6 <printnum+0x38>

ffffffffc02019ea <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019ea:	7119                	addi	sp,sp,-128
ffffffffc02019ec:	f4a6                	sd	s1,104(sp)
ffffffffc02019ee:	f0ca                	sd	s2,96(sp)
ffffffffc02019f0:	ecce                	sd	s3,88(sp)
ffffffffc02019f2:	e8d2                	sd	s4,80(sp)
ffffffffc02019f4:	e4d6                	sd	s5,72(sp)
ffffffffc02019f6:	e0da                	sd	s6,64(sp)
ffffffffc02019f8:	fc5e                	sd	s7,56(sp)
ffffffffc02019fa:	f06a                	sd	s10,32(sp)
ffffffffc02019fc:	fc86                	sd	ra,120(sp)
ffffffffc02019fe:	f8a2                	sd	s0,112(sp)
ffffffffc0201a00:	f862                	sd	s8,48(sp)
ffffffffc0201a02:	f466                	sd	s9,40(sp)
ffffffffc0201a04:	ec6e                	sd	s11,24(sp)
ffffffffc0201a06:	892a                	mv	s2,a0
ffffffffc0201a08:	84ae                	mv	s1,a1
ffffffffc0201a0a:	8d32                	mv	s10,a2
ffffffffc0201a0c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a0e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a12:	5b7d                	li	s6,-1
ffffffffc0201a14:	00001a97          	auipc	s5,0x1
ffffffffc0201a18:	330a8a93          	addi	s5,s5,816 # ffffffffc0202d44 <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a1c:	00001b97          	auipc	s7,0x1
ffffffffc0201a20:	504b8b93          	addi	s7,s7,1284 # ffffffffc0202f20 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a24:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a28:	001d0413          	addi	s0,s10,1
ffffffffc0201a2c:	01350a63          	beq	a0,s3,ffffffffc0201a40 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a30:	c121                	beqz	a0,ffffffffc0201a70 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a32:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a34:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a36:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a38:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a3c:	ff351ae3          	bne	a0,s3,ffffffffc0201a30 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a40:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a44:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a48:	4c81                	li	s9,0
ffffffffc0201a4a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a4c:	5c7d                	li	s8,-1
ffffffffc0201a4e:	5dfd                	li	s11,-1
ffffffffc0201a50:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a54:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a56:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a5a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a5e:	00140d13          	addi	s10,s0,1
ffffffffc0201a62:	04b56263          	bltu	a0,a1,ffffffffc0201aa6 <vprintfmt+0xbc>
ffffffffc0201a66:	058a                	slli	a1,a1,0x2
ffffffffc0201a68:	95d6                	add	a1,a1,s5
ffffffffc0201a6a:	4194                	lw	a3,0(a1)
ffffffffc0201a6c:	96d6                	add	a3,a3,s5
ffffffffc0201a6e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a70:	70e6                	ld	ra,120(sp)
ffffffffc0201a72:	7446                	ld	s0,112(sp)
ffffffffc0201a74:	74a6                	ld	s1,104(sp)
ffffffffc0201a76:	7906                	ld	s2,96(sp)
ffffffffc0201a78:	69e6                	ld	s3,88(sp)
ffffffffc0201a7a:	6a46                	ld	s4,80(sp)
ffffffffc0201a7c:	6aa6                	ld	s5,72(sp)
ffffffffc0201a7e:	6b06                	ld	s6,64(sp)
ffffffffc0201a80:	7be2                	ld	s7,56(sp)
ffffffffc0201a82:	7c42                	ld	s8,48(sp)
ffffffffc0201a84:	7ca2                	ld	s9,40(sp)
ffffffffc0201a86:	7d02                	ld	s10,32(sp)
ffffffffc0201a88:	6de2                	ld	s11,24(sp)
ffffffffc0201a8a:	6109                	addi	sp,sp,128
ffffffffc0201a8c:	8082                	ret
            padc = '0';
ffffffffc0201a8e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a90:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a94:	846a                	mv	s0,s10
ffffffffc0201a96:	00140d13          	addi	s10,s0,1
ffffffffc0201a9a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a9e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201aa2:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a66 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201aa6:	85a6                	mv	a1,s1
ffffffffc0201aa8:	02500513          	li	a0,37
ffffffffc0201aac:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201aae:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201ab2:	8d22                	mv	s10,s0
ffffffffc0201ab4:	f73788e3          	beq	a5,s3,ffffffffc0201a24 <vprintfmt+0x3a>
ffffffffc0201ab8:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201abc:	1d7d                	addi	s10,s10,-1
ffffffffc0201abe:	ff379de3          	bne	a5,s3,ffffffffc0201ab8 <vprintfmt+0xce>
ffffffffc0201ac2:	b78d                	j	ffffffffc0201a24 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201ac4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201ac8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201acc:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201ace:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201ad2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201ad6:	02d86463          	bltu	a6,a3,ffffffffc0201afe <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201ada:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201ade:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201ae2:	0186873b          	addw	a4,a3,s8
ffffffffc0201ae6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201aea:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201aec:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201af0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201af2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201af6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201afa:	fed870e3          	bgeu	a6,a3,ffffffffc0201ada <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201afe:	f40ddce3          	bgez	s11,ffffffffc0201a56 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b02:	8de2                	mv	s11,s8
ffffffffc0201b04:	5c7d                	li	s8,-1
ffffffffc0201b06:	bf81                	j	ffffffffc0201a56 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b08:	fffdc693          	not	a3,s11
ffffffffc0201b0c:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b0e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b12:	00144603          	lbu	a2,1(s0)
ffffffffc0201b16:	2d81                	sext.w	s11,s11
ffffffffc0201b18:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b1a:	bf35                	j	ffffffffc0201a56 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201b1c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b20:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b24:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b26:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b28:	bfd9                	j	ffffffffc0201afe <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b2a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b2c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b30:	01174463          	blt	a4,a7,ffffffffc0201b38 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b34:	1a088e63          	beqz	a7,ffffffffc0201cf0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b38:	000a3603          	ld	a2,0(s4)
ffffffffc0201b3c:	46c1                	li	a3,16
ffffffffc0201b3e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b40:	2781                	sext.w	a5,a5
ffffffffc0201b42:	876e                	mv	a4,s11
ffffffffc0201b44:	85a6                	mv	a1,s1
ffffffffc0201b46:	854a                	mv	a0,s2
ffffffffc0201b48:	e37ff0ef          	jal	ra,ffffffffc020197e <printnum>
            break;
ffffffffc0201b4c:	bde1                	j	ffffffffc0201a24 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b4e:	000a2503          	lw	a0,0(s4)
ffffffffc0201b52:	85a6                	mv	a1,s1
ffffffffc0201b54:	0a21                	addi	s4,s4,8
ffffffffc0201b56:	9902                	jalr	s2
            break;
ffffffffc0201b58:	b5f1                	j	ffffffffc0201a24 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b5a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b5c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b60:	01174463          	blt	a4,a7,ffffffffc0201b68 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b64:	18088163          	beqz	a7,ffffffffc0201ce6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b68:	000a3603          	ld	a2,0(s4)
ffffffffc0201b6c:	46a9                	li	a3,10
ffffffffc0201b6e:	8a2e                	mv	s4,a1
ffffffffc0201b70:	bfc1                	j	ffffffffc0201b40 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b72:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b76:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b78:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b7a:	bdf1                	j	ffffffffc0201a56 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b7c:	85a6                	mv	a1,s1
ffffffffc0201b7e:	02500513          	li	a0,37
ffffffffc0201b82:	9902                	jalr	s2
            break;
ffffffffc0201b84:	b545                	j	ffffffffc0201a24 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b86:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b8a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b8c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b8e:	b5e1                	j	ffffffffc0201a56 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b90:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b92:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b96:	01174463          	blt	a4,a7,ffffffffc0201b9e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201b9a:	14088163          	beqz	a7,ffffffffc0201cdc <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b9e:	000a3603          	ld	a2,0(s4)
ffffffffc0201ba2:	46a1                	li	a3,8
ffffffffc0201ba4:	8a2e                	mv	s4,a1
ffffffffc0201ba6:	bf69                	j	ffffffffc0201b40 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201ba8:	03000513          	li	a0,48
ffffffffc0201bac:	85a6                	mv	a1,s1
ffffffffc0201bae:	e03e                	sd	a5,0(sp)
ffffffffc0201bb0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201bb2:	85a6                	mv	a1,s1
ffffffffc0201bb4:	07800513          	li	a0,120
ffffffffc0201bb8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bba:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201bbc:	6782                	ld	a5,0(sp)
ffffffffc0201bbe:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bc0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201bc4:	bfb5                	j	ffffffffc0201b40 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201bc6:	000a3403          	ld	s0,0(s4)
ffffffffc0201bca:	008a0713          	addi	a4,s4,8
ffffffffc0201bce:	e03a                	sd	a4,0(sp)
ffffffffc0201bd0:	14040263          	beqz	s0,ffffffffc0201d14 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201bd4:	0fb05763          	blez	s11,ffffffffc0201cc2 <vprintfmt+0x2d8>
ffffffffc0201bd8:	02d00693          	li	a3,45
ffffffffc0201bdc:	0cd79163          	bne	a5,a3,ffffffffc0201c9e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201be0:	00044783          	lbu	a5,0(s0)
ffffffffc0201be4:	0007851b          	sext.w	a0,a5
ffffffffc0201be8:	cf85                	beqz	a5,ffffffffc0201c20 <vprintfmt+0x236>
ffffffffc0201bea:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bee:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bf2:	000c4563          	bltz	s8,ffffffffc0201bfc <vprintfmt+0x212>
ffffffffc0201bf6:	3c7d                	addiw	s8,s8,-1
ffffffffc0201bf8:	036c0263          	beq	s8,s6,ffffffffc0201c1c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201bfc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bfe:	0e0c8e63          	beqz	s9,ffffffffc0201cfa <vprintfmt+0x310>
ffffffffc0201c02:	3781                	addiw	a5,a5,-32
ffffffffc0201c04:	0ef47b63          	bgeu	s0,a5,ffffffffc0201cfa <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c08:	03f00513          	li	a0,63
ffffffffc0201c0c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c0e:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c12:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c14:	0a05                	addi	s4,s4,1
ffffffffc0201c16:	0007851b          	sext.w	a0,a5
ffffffffc0201c1a:	ffe1                	bnez	a5,ffffffffc0201bf2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201c1c:	01b05963          	blez	s11,ffffffffc0201c2e <vprintfmt+0x244>
ffffffffc0201c20:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c22:	85a6                	mv	a1,s1
ffffffffc0201c24:	02000513          	li	a0,32
ffffffffc0201c28:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c2a:	fe0d9be3          	bnez	s11,ffffffffc0201c20 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c2e:	6a02                	ld	s4,0(sp)
ffffffffc0201c30:	bbd5                	j	ffffffffc0201a24 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c32:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c34:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c38:	01174463          	blt	a4,a7,ffffffffc0201c40 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c3c:	08088d63          	beqz	a7,ffffffffc0201cd6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c40:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c44:	0a044d63          	bltz	s0,ffffffffc0201cfe <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c48:	8622                	mv	a2,s0
ffffffffc0201c4a:	8a66                	mv	s4,s9
ffffffffc0201c4c:	46a9                	li	a3,10
ffffffffc0201c4e:	bdcd                	j	ffffffffc0201b40 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c50:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c54:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c56:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c58:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c5c:	8fb5                	xor	a5,a5,a3
ffffffffc0201c5e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c62:	02d74163          	blt	a4,a3,ffffffffc0201c84 <vprintfmt+0x29a>
ffffffffc0201c66:	00369793          	slli	a5,a3,0x3
ffffffffc0201c6a:	97de                	add	a5,a5,s7
ffffffffc0201c6c:	639c                	ld	a5,0(a5)
ffffffffc0201c6e:	cb99                	beqz	a5,ffffffffc0201c84 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c70:	86be                	mv	a3,a5
ffffffffc0201c72:	00001617          	auipc	a2,0x1
ffffffffc0201c76:	0ce60613          	addi	a2,a2,206 # ffffffffc0202d40 <default_pmm_manager+0x1b0>
ffffffffc0201c7a:	85a6                	mv	a1,s1
ffffffffc0201c7c:	854a                	mv	a0,s2
ffffffffc0201c7e:	0ce000ef          	jal	ra,ffffffffc0201d4c <printfmt>
ffffffffc0201c82:	b34d                	j	ffffffffc0201a24 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c84:	00001617          	auipc	a2,0x1
ffffffffc0201c88:	0ac60613          	addi	a2,a2,172 # ffffffffc0202d30 <default_pmm_manager+0x1a0>
ffffffffc0201c8c:	85a6                	mv	a1,s1
ffffffffc0201c8e:	854a                	mv	a0,s2
ffffffffc0201c90:	0bc000ef          	jal	ra,ffffffffc0201d4c <printfmt>
ffffffffc0201c94:	bb41                	j	ffffffffc0201a24 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201c96:	00001417          	auipc	s0,0x1
ffffffffc0201c9a:	09240413          	addi	s0,s0,146 # ffffffffc0202d28 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c9e:	85e2                	mv	a1,s8
ffffffffc0201ca0:	8522                	mv	a0,s0
ffffffffc0201ca2:	e43e                	sd	a5,8(sp)
ffffffffc0201ca4:	200000ef          	jal	ra,ffffffffc0201ea4 <strnlen>
ffffffffc0201ca8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201cac:	01b05b63          	blez	s11,ffffffffc0201cc2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201cb0:	67a2                	ld	a5,8(sp)
ffffffffc0201cb2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cb6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201cb8:	85a6                	mv	a1,s1
ffffffffc0201cba:	8552                	mv	a0,s4
ffffffffc0201cbc:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cbe:	fe0d9ce3          	bnez	s11,ffffffffc0201cb6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cc2:	00044783          	lbu	a5,0(s0)
ffffffffc0201cc6:	00140a13          	addi	s4,s0,1
ffffffffc0201cca:	0007851b          	sext.w	a0,a5
ffffffffc0201cce:	d3a5                	beqz	a5,ffffffffc0201c2e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cd0:	05e00413          	li	s0,94
ffffffffc0201cd4:	bf39                	j	ffffffffc0201bf2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201cd6:	000a2403          	lw	s0,0(s4)
ffffffffc0201cda:	b7ad                	j	ffffffffc0201c44 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201cdc:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ce0:	46a1                	li	a3,8
ffffffffc0201ce2:	8a2e                	mv	s4,a1
ffffffffc0201ce4:	bdb1                	j	ffffffffc0201b40 <vprintfmt+0x156>
ffffffffc0201ce6:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cea:	46a9                	li	a3,10
ffffffffc0201cec:	8a2e                	mv	s4,a1
ffffffffc0201cee:	bd89                	j	ffffffffc0201b40 <vprintfmt+0x156>
ffffffffc0201cf0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cf4:	46c1                	li	a3,16
ffffffffc0201cf6:	8a2e                	mv	s4,a1
ffffffffc0201cf8:	b5a1                	j	ffffffffc0201b40 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201cfa:	9902                	jalr	s2
ffffffffc0201cfc:	bf09                	j	ffffffffc0201c0e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201cfe:	85a6                	mv	a1,s1
ffffffffc0201d00:	02d00513          	li	a0,45
ffffffffc0201d04:	e03e                	sd	a5,0(sp)
ffffffffc0201d06:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d08:	6782                	ld	a5,0(sp)
ffffffffc0201d0a:	8a66                	mv	s4,s9
ffffffffc0201d0c:	40800633          	neg	a2,s0
ffffffffc0201d10:	46a9                	li	a3,10
ffffffffc0201d12:	b53d                	j	ffffffffc0201b40 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d14:	03b05163          	blez	s11,ffffffffc0201d36 <vprintfmt+0x34c>
ffffffffc0201d18:	02d00693          	li	a3,45
ffffffffc0201d1c:	f6d79de3          	bne	a5,a3,ffffffffc0201c96 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d20:	00001417          	auipc	s0,0x1
ffffffffc0201d24:	00840413          	addi	s0,s0,8 # ffffffffc0202d28 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d28:	02800793          	li	a5,40
ffffffffc0201d2c:	02800513          	li	a0,40
ffffffffc0201d30:	00140a13          	addi	s4,s0,1
ffffffffc0201d34:	bd6d                	j	ffffffffc0201bee <vprintfmt+0x204>
ffffffffc0201d36:	00001a17          	auipc	s4,0x1
ffffffffc0201d3a:	ff3a0a13          	addi	s4,s4,-13 # ffffffffc0202d29 <default_pmm_manager+0x199>
ffffffffc0201d3e:	02800513          	li	a0,40
ffffffffc0201d42:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d46:	05e00413          	li	s0,94
ffffffffc0201d4a:	b565                	j	ffffffffc0201bf2 <vprintfmt+0x208>

ffffffffc0201d4c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d4c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d4e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d52:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d54:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d56:	ec06                	sd	ra,24(sp)
ffffffffc0201d58:	f83a                	sd	a4,48(sp)
ffffffffc0201d5a:	fc3e                	sd	a5,56(sp)
ffffffffc0201d5c:	e0c2                	sd	a6,64(sp)
ffffffffc0201d5e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d60:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d62:	c89ff0ef          	jal	ra,ffffffffc02019ea <vprintfmt>
}
ffffffffc0201d66:	60e2                	ld	ra,24(sp)
ffffffffc0201d68:	6161                	addi	sp,sp,80
ffffffffc0201d6a:	8082                	ret

ffffffffc0201d6c <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d6c:	715d                	addi	sp,sp,-80
ffffffffc0201d6e:	e486                	sd	ra,72(sp)
ffffffffc0201d70:	e0a6                	sd	s1,64(sp)
ffffffffc0201d72:	fc4a                	sd	s2,56(sp)
ffffffffc0201d74:	f84e                	sd	s3,48(sp)
ffffffffc0201d76:	f452                	sd	s4,40(sp)
ffffffffc0201d78:	f056                	sd	s5,32(sp)
ffffffffc0201d7a:	ec5a                	sd	s6,24(sp)
ffffffffc0201d7c:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d7e:	c901                	beqz	a0,ffffffffc0201d8e <readline+0x22>
ffffffffc0201d80:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d82:	00001517          	auipc	a0,0x1
ffffffffc0201d86:	fbe50513          	addi	a0,a0,-66 # ffffffffc0202d40 <default_pmm_manager+0x1b0>
ffffffffc0201d8a:	b4efe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201d8e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d90:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d92:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d94:	4aa9                	li	s5,10
ffffffffc0201d96:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201d98:	00004b97          	auipc	s7,0x4
ffffffffc0201d9c:	2a8b8b93          	addi	s7,s7,680 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201da0:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201da4:	bacfe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201da8:	00054a63          	bltz	a0,ffffffffc0201dbc <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dac:	00a95a63          	bge	s2,a0,ffffffffc0201dc0 <readline+0x54>
ffffffffc0201db0:	029a5263          	bge	s4,s1,ffffffffc0201dd4 <readline+0x68>
        c = getchar();
ffffffffc0201db4:	b9cfe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201db8:	fe055ae3          	bgez	a0,ffffffffc0201dac <readline+0x40>
            return NULL;
ffffffffc0201dbc:	4501                	li	a0,0
ffffffffc0201dbe:	a091                	j	ffffffffc0201e02 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201dc0:	03351463          	bne	a0,s3,ffffffffc0201de8 <readline+0x7c>
ffffffffc0201dc4:	e8a9                	bnez	s1,ffffffffc0201e16 <readline+0xaa>
        c = getchar();
ffffffffc0201dc6:	b8afe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201dca:	fe0549e3          	bltz	a0,ffffffffc0201dbc <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dce:	fea959e3          	bge	s2,a0,ffffffffc0201dc0 <readline+0x54>
ffffffffc0201dd2:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201dd4:	e42a                	sd	a0,8(sp)
ffffffffc0201dd6:	b38fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201dda:	6522                	ld	a0,8(sp)
ffffffffc0201ddc:	009b87b3          	add	a5,s7,s1
ffffffffc0201de0:	2485                	addiw	s1,s1,1
ffffffffc0201de2:	00a78023          	sb	a0,0(a5)
ffffffffc0201de6:	bf7d                	j	ffffffffc0201da4 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201de8:	01550463          	beq	a0,s5,ffffffffc0201df0 <readline+0x84>
ffffffffc0201dec:	fb651ce3          	bne	a0,s6,ffffffffc0201da4 <readline+0x38>
            cputchar(c);
ffffffffc0201df0:	b1efe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201df4:	00004517          	auipc	a0,0x4
ffffffffc0201df8:	24c50513          	addi	a0,a0,588 # ffffffffc0206040 <buf>
ffffffffc0201dfc:	94aa                	add	s1,s1,a0
ffffffffc0201dfe:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e02:	60a6                	ld	ra,72(sp)
ffffffffc0201e04:	6486                	ld	s1,64(sp)
ffffffffc0201e06:	7962                	ld	s2,56(sp)
ffffffffc0201e08:	79c2                	ld	s3,48(sp)
ffffffffc0201e0a:	7a22                	ld	s4,40(sp)
ffffffffc0201e0c:	7a82                	ld	s5,32(sp)
ffffffffc0201e0e:	6b62                	ld	s6,24(sp)
ffffffffc0201e10:	6bc2                	ld	s7,16(sp)
ffffffffc0201e12:	6161                	addi	sp,sp,80
ffffffffc0201e14:	8082                	ret
            cputchar(c);
ffffffffc0201e16:	4521                	li	a0,8
ffffffffc0201e18:	af6fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201e1c:	34fd                	addiw	s1,s1,-1
ffffffffc0201e1e:	b759                	j	ffffffffc0201da4 <readline+0x38>

ffffffffc0201e20 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e20:	4781                	li	a5,0
ffffffffc0201e22:	00004717          	auipc	a4,0x4
ffffffffc0201e26:	1f673703          	ld	a4,502(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e2a:	88ba                	mv	a7,a4
ffffffffc0201e2c:	852a                	mv	a0,a0
ffffffffc0201e2e:	85be                	mv	a1,a5
ffffffffc0201e30:	863e                	mv	a2,a5
ffffffffc0201e32:	00000073          	ecall
ffffffffc0201e36:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e38:	8082                	ret

ffffffffc0201e3a <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e3a:	4781                	li	a5,0
ffffffffc0201e3c:	00004717          	auipc	a4,0x4
ffffffffc0201e40:	65c73703          	ld	a4,1628(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201e44:	88ba                	mv	a7,a4
ffffffffc0201e46:	852a                	mv	a0,a0
ffffffffc0201e48:	85be                	mv	a1,a5
ffffffffc0201e4a:	863e                	mv	a2,a5
ffffffffc0201e4c:	00000073          	ecall
ffffffffc0201e50:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e52:	8082                	ret

ffffffffc0201e54 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e54:	4501                	li	a0,0
ffffffffc0201e56:	00004797          	auipc	a5,0x4
ffffffffc0201e5a:	1ba7b783          	ld	a5,442(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e5e:	88be                	mv	a7,a5
ffffffffc0201e60:	852a                	mv	a0,a0
ffffffffc0201e62:	85aa                	mv	a1,a0
ffffffffc0201e64:	862a                	mv	a2,a0
ffffffffc0201e66:	00000073          	ecall
ffffffffc0201e6a:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e6c:	2501                	sext.w	a0,a0
ffffffffc0201e6e:	8082                	ret

ffffffffc0201e70 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e70:	4781                	li	a5,0
ffffffffc0201e72:	00004717          	auipc	a4,0x4
ffffffffc0201e76:	1ae73703          	ld	a4,430(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e7a:	88ba                	mv	a7,a4
ffffffffc0201e7c:	853e                	mv	a0,a5
ffffffffc0201e7e:	85be                	mv	a1,a5
ffffffffc0201e80:	863e                	mv	a2,a5
ffffffffc0201e82:	00000073          	ecall
ffffffffc0201e86:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e88:	8082                	ret

ffffffffc0201e8a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e8a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e8e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e90:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e92:	cb81                	beqz	a5,ffffffffc0201ea2 <strlen+0x18>
        cnt ++;
ffffffffc0201e94:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e96:	00a707b3          	add	a5,a4,a0
ffffffffc0201e9a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e9e:	fbfd                	bnez	a5,ffffffffc0201e94 <strlen+0xa>
ffffffffc0201ea0:	8082                	ret
    }
    return cnt;
}
ffffffffc0201ea2:	8082                	ret

ffffffffc0201ea4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201ea4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201ea6:	e589                	bnez	a1,ffffffffc0201eb0 <strnlen+0xc>
ffffffffc0201ea8:	a811                	j	ffffffffc0201ebc <strnlen+0x18>
        cnt ++;
ffffffffc0201eaa:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eac:	00f58863          	beq	a1,a5,ffffffffc0201ebc <strnlen+0x18>
ffffffffc0201eb0:	00f50733          	add	a4,a0,a5
ffffffffc0201eb4:	00074703          	lbu	a4,0(a4)
ffffffffc0201eb8:	fb6d                	bnez	a4,ffffffffc0201eaa <strnlen+0x6>
ffffffffc0201eba:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201ebc:	852e                	mv	a0,a1
ffffffffc0201ebe:	8082                	ret

ffffffffc0201ec0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ec0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ec4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ec8:	cb89                	beqz	a5,ffffffffc0201eda <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201eca:	0505                	addi	a0,a0,1
ffffffffc0201ecc:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ece:	fee789e3          	beq	a5,a4,ffffffffc0201ec0 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ed2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ed6:	9d19                	subw	a0,a0,a4
ffffffffc0201ed8:	8082                	ret
ffffffffc0201eda:	4501                	li	a0,0
ffffffffc0201edc:	bfed                	j	ffffffffc0201ed6 <strcmp+0x16>

ffffffffc0201ede <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ede:	c20d                	beqz	a2,ffffffffc0201f00 <strncmp+0x22>
ffffffffc0201ee0:	962e                	add	a2,a2,a1
ffffffffc0201ee2:	a031                	j	ffffffffc0201eee <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201ee4:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ee6:	00e79a63          	bne	a5,a4,ffffffffc0201efa <strncmp+0x1c>
ffffffffc0201eea:	00b60b63          	beq	a2,a1,ffffffffc0201f00 <strncmp+0x22>
ffffffffc0201eee:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ef2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ef4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201ef8:	f7f5                	bnez	a5,ffffffffc0201ee4 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201efa:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201efe:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f00:	4501                	li	a0,0
ffffffffc0201f02:	8082                	ret

ffffffffc0201f04 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f04:	00054783          	lbu	a5,0(a0)
ffffffffc0201f08:	c799                	beqz	a5,ffffffffc0201f16 <strchr+0x12>
        if (*s == c) {
ffffffffc0201f0a:	00f58763          	beq	a1,a5,ffffffffc0201f18 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f0e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201f12:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f14:	fbfd                	bnez	a5,ffffffffc0201f0a <strchr+0x6>
    }
    return NULL;
ffffffffc0201f16:	4501                	li	a0,0
}
ffffffffc0201f18:	8082                	ret

ffffffffc0201f1a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f1a:	ca01                	beqz	a2,ffffffffc0201f2a <memset+0x10>
ffffffffc0201f1c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f1e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f20:	0785                	addi	a5,a5,1
ffffffffc0201f22:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f26:	fec79de3          	bne	a5,a2,ffffffffc0201f20 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f2a:	8082                	ret
