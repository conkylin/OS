
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000c2517          	auipc	a0,0xc2
ffffffffc020004e:	74e50513          	addi	a0,a0,1870 # ffffffffc02c2798 <buf>
ffffffffc0200052:	000c7617          	auipc	a2,0xc7
ffffffffc0200056:	c2660613          	addi	a2,a2,-986 # ffffffffc02c6c78 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7b2050ef          	jal	ra,ffffffffc0205814 <memset>
    cons_init(); // init the console
ffffffffc0200066:	520000ef          	jal	ra,ffffffffc0200586 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00005597          	auipc	a1,0x5
ffffffffc020006e:	7d658593          	addi	a1,a1,2006 # ffffffffc0205840 <etext+0x2>
ffffffffc0200072:	00005517          	auipc	a0,0x5
ffffffffc0200076:	7ee50513          	addi	a0,a0,2030 # ffffffffc0205860 <etext+0x22>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	576000ef          	jal	ra,ffffffffc02005f8 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	598020ef          	jal	ra,ffffffffc020261e <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	12b000ef          	jal	ra,ffffffffc02009b4 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	129000ef          	jal	ra,ffffffffc02009b6 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	065030ef          	jal	ra,ffffffffc02038f6 <vmm_init>
    sched_init();
ffffffffc0200096:	014050ef          	jal	ra,ffffffffc02050aa <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	4ab040ef          	jal	ra,ffffffffc0204d44 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	107000ef          	jal	ra,ffffffffc02009a8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	637040ef          	jal	ra,ffffffffc0204edc <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	715d                	addi	sp,sp,-80
ffffffffc02000ac:	e486                	sd	ra,72(sp)
ffffffffc02000ae:	e0a6                	sd	s1,64(sp)
ffffffffc02000b0:	fc4a                	sd	s2,56(sp)
ffffffffc02000b2:	f84e                	sd	s3,48(sp)
ffffffffc02000b4:	f452                	sd	s4,40(sp)
ffffffffc02000b6:	f056                	sd	s5,32(sp)
ffffffffc02000b8:	ec5a                	sd	s6,24(sp)
ffffffffc02000ba:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000bc:	c901                	beqz	a0,ffffffffc02000cc <readline+0x22>
ffffffffc02000be:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000c0:	00005517          	auipc	a0,0x5
ffffffffc02000c4:	7a850513          	addi	a0,a0,1960 # ffffffffc0205868 <etext+0x2a>
ffffffffc02000c8:	0d0000ef          	jal	ra,ffffffffc0200198 <cprintf>
readline(const char *prompt) {
ffffffffc02000cc:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ce:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000d2:	4aa9                	li	s5,10
ffffffffc02000d4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d6:	000c2b97          	auipc	s7,0xc2
ffffffffc02000da:	6c2b8b93          	addi	s7,s7,1730 # ffffffffc02c2798 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000de:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000e2:	12e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000e6:	00054a63          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ea:	00a95a63          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc02000ee:	029a5263          	bge	s4,s1,ffffffffc0200112 <readline+0x68>
        c = getchar();
ffffffffc02000f2:	11e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000f6:	fe055ae3          	bgez	a0,ffffffffc02000ea <readline+0x40>
            return NULL;
ffffffffc02000fa:	4501                	li	a0,0
ffffffffc02000fc:	a091                	j	ffffffffc0200140 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fe:	03351463          	bne	a0,s3,ffffffffc0200126 <readline+0x7c>
ffffffffc0200102:	e8a9                	bnez	s1,ffffffffc0200154 <readline+0xaa>
        c = getchar();
ffffffffc0200104:	10c000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc0200108:	fe0549e3          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010c:	fea959e3          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc0200110:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200112:	e42a                	sd	a0,8(sp)
ffffffffc0200114:	0ba000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i ++] = c;
ffffffffc0200118:	6522                	ld	a0,8(sp)
ffffffffc020011a:	009b87b3          	add	a5,s7,s1
ffffffffc020011e:	2485                	addiw	s1,s1,1
ffffffffc0200120:	00a78023          	sb	a0,0(a5)
ffffffffc0200124:	bf7d                	j	ffffffffc02000e2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200126:	01550463          	beq	a0,s5,ffffffffc020012e <readline+0x84>
ffffffffc020012a:	fb651ce3          	bne	a0,s6,ffffffffc02000e2 <readline+0x38>
            cputchar(c);
ffffffffc020012e:	0a0000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i] = '\0';
ffffffffc0200132:	000c2517          	auipc	a0,0xc2
ffffffffc0200136:	66650513          	addi	a0,a0,1638 # ffffffffc02c2798 <buf>
ffffffffc020013a:	94aa                	add	s1,s1,a0
ffffffffc020013c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200140:	60a6                	ld	ra,72(sp)
ffffffffc0200142:	6486                	ld	s1,64(sp)
ffffffffc0200144:	7962                	ld	s2,56(sp)
ffffffffc0200146:	79c2                	ld	s3,48(sp)
ffffffffc0200148:	7a22                	ld	s4,40(sp)
ffffffffc020014a:	7a82                	ld	s5,32(sp)
ffffffffc020014c:	6b62                	ld	s6,24(sp)
ffffffffc020014e:	6bc2                	ld	s7,16(sp)
ffffffffc0200150:	6161                	addi	sp,sp,80
ffffffffc0200152:	8082                	ret
            cputchar(c);
ffffffffc0200154:	4521                	li	a0,8
ffffffffc0200156:	078000ef          	jal	ra,ffffffffc02001ce <cputchar>
            i --;
ffffffffc020015a:	34fd                	addiw	s1,s1,-1
ffffffffc020015c:	b759                	j	ffffffffc02000e2 <readline+0x38>

ffffffffc020015e <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e022                	sd	s0,0(sp)
ffffffffc0200162:	e406                	sd	ra,8(sp)
ffffffffc0200164:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200166:	422000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	401c                	lw	a5,0(s0)
}
ffffffffc020016c:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016e:	2785                	addiw	a5,a5,1
ffffffffc0200170:	c01c                	sw	a5,0(s0)
}
ffffffffc0200172:	6402                	ld	s0,0(sp)
ffffffffc0200174:	0141                	addi	sp,sp,16
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe050513          	addi	a0,a0,-32 # ffffffffc020015e <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	264050ef          	jal	ra,ffffffffc02053f0 <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
{
ffffffffc020019e:	8e2a                	mv	t3,a0
ffffffffc02001a0:	f42e                	sd	a1,40(sp)
ffffffffc02001a2:	f832                	sd	a2,48(sp)
ffffffffc02001a4:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a6:	00000517          	auipc	a0,0x0
ffffffffc02001aa:	fb850513          	addi	a0,a0,-72 # ffffffffc020015e <cputch>
ffffffffc02001ae:	004c                	addi	a1,sp,4
ffffffffc02001b0:	869a                	mv	a3,t1
ffffffffc02001b2:	8672                	mv	a2,t3
{
ffffffffc02001b4:	ec06                	sd	ra,24(sp)
ffffffffc02001b6:	e0ba                	sd	a4,64(sp)
ffffffffc02001b8:	e4be                	sd	a5,72(sp)
ffffffffc02001ba:	e8c2                	sd	a6,80(sp)
ffffffffc02001bc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001c0:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c2:	22e050ef          	jal	ra,ffffffffc02053f0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	4512                	lw	a0,4(sp)
ffffffffc02001ca:	6125                	addi	sp,sp,96
ffffffffc02001cc:	8082                	ret

ffffffffc02001ce <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ce:	ae6d                	j	ffffffffc0200588 <cons_putc>

ffffffffc02001d0 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001d0:	1101                	addi	sp,sp,-32
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	ec06                	sd	ra,24(sp)
ffffffffc02001d6:	e426                	sd	s1,8(sp)
ffffffffc02001d8:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001da:	00054503          	lbu	a0,0(a0)
ffffffffc02001de:	c51d                	beqz	a0,ffffffffc020020c <cputs+0x3c>
ffffffffc02001e0:	0405                	addi	s0,s0,1
ffffffffc02001e2:	4485                	li	s1,1
ffffffffc02001e4:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e6:	3a2000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001ea:	00044503          	lbu	a0,0(s0)
ffffffffc02001ee:	008487bb          	addw	a5,s1,s0
ffffffffc02001f2:	0405                	addi	s0,s0,1
ffffffffc02001f4:	f96d                	bnez	a0,ffffffffc02001e6 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f6:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001fa:	4529                	li	a0,10
ffffffffc02001fc:	38c000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200200:	60e2                	ld	ra,24(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	6442                	ld	s0,16(sp)
ffffffffc0200206:	64a2                	ld	s1,8(sp)
ffffffffc0200208:	6105                	addi	sp,sp,32
ffffffffc020020a:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc020020c:	4405                	li	s0,1
ffffffffc020020e:	b7f5                	j	ffffffffc02001fa <cputs+0x2a>

ffffffffc0200210 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200210:	1141                	addi	sp,sp,-16
ffffffffc0200212:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200214:	3a8000ef          	jal	ra,ffffffffc02005bc <cons_getc>
ffffffffc0200218:	dd75                	beqz	a0,ffffffffc0200214 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	0141                	addi	sp,sp,16
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200220:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	64e50513          	addi	a0,a0,1614 # ffffffffc0205870 <etext+0x32>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00005517          	auipc	a0,0x5
ffffffffc020023c:	65850513          	addi	a0,a0,1624 # ffffffffc0205890 <etext+0x52>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00005597          	auipc	a1,0x5
ffffffffc0200248:	5fa58593          	addi	a1,a1,1530 # ffffffffc020583e <etext>
ffffffffc020024c:	00005517          	auipc	a0,0x5
ffffffffc0200250:	66450513          	addi	a0,a0,1636 # ffffffffc02058b0 <etext+0x72>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000c2597          	auipc	a1,0xc2
ffffffffc020025c:	54058593          	addi	a1,a1,1344 # ffffffffc02c2798 <buf>
ffffffffc0200260:	00005517          	auipc	a0,0x5
ffffffffc0200264:	67050513          	addi	a0,a0,1648 # ffffffffc02058d0 <etext+0x92>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000c7597          	auipc	a1,0xc7
ffffffffc0200270:	a0c58593          	addi	a1,a1,-1524 # ffffffffc02c6c78 <end>
ffffffffc0200274:	00005517          	auipc	a0,0x5
ffffffffc0200278:	67c50513          	addi	a0,a0,1660 # ffffffffc02058f0 <etext+0xb2>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000c7597          	auipc	a1,0xc7
ffffffffc0200284:	df758593          	addi	a1,a1,-521 # ffffffffc02c7077 <end+0x3ff>
ffffffffc0200288:	00000797          	auipc	a5,0x0
ffffffffc020028c:	dc278793          	addi	a5,a5,-574 # ffffffffc020004a <kern_init>
ffffffffc0200290:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029a:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029e:	95be                	add	a1,a1,a5
ffffffffc02002a0:	85a9                	srai	a1,a1,0xa
ffffffffc02002a2:	00005517          	auipc	a0,0x5
ffffffffc02002a6:	66e50513          	addi	a0,a0,1646 # ffffffffc0205910 <etext+0xd2>
}
ffffffffc02002aa:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ac:	b5f5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002ae <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002ae:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b0:	00005617          	auipc	a2,0x5
ffffffffc02002b4:	69060613          	addi	a2,a2,1680 # ffffffffc0205940 <etext+0x102>
ffffffffc02002b8:	04d00593          	li	a1,77
ffffffffc02002bc:	00005517          	auipc	a0,0x5
ffffffffc02002c0:	69c50513          	addi	a0,a0,1692 # ffffffffc0205958 <etext+0x11a>
void print_stackframe(void) {
ffffffffc02002c4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c6:	1cc000ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02002ca <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ca:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002cc:	00005617          	auipc	a2,0x5
ffffffffc02002d0:	6a460613          	addi	a2,a2,1700 # ffffffffc0205970 <etext+0x132>
ffffffffc02002d4:	00005597          	auipc	a1,0x5
ffffffffc02002d8:	6bc58593          	addi	a1,a1,1724 # ffffffffc0205990 <etext+0x152>
ffffffffc02002dc:	00005517          	auipc	a0,0x5
ffffffffc02002e0:	6bc50513          	addi	a0,a0,1724 # ffffffffc0205998 <etext+0x15a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00005617          	auipc	a2,0x5
ffffffffc02002ee:	6be60613          	addi	a2,a2,1726 # ffffffffc02059a8 <etext+0x16a>
ffffffffc02002f2:	00005597          	auipc	a1,0x5
ffffffffc02002f6:	6de58593          	addi	a1,a1,1758 # ffffffffc02059d0 <etext+0x192>
ffffffffc02002fa:	00005517          	auipc	a0,0x5
ffffffffc02002fe:	69e50513          	addi	a0,a0,1694 # ffffffffc0205998 <etext+0x15a>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00005617          	auipc	a2,0x5
ffffffffc020030a:	6da60613          	addi	a2,a2,1754 # ffffffffc02059e0 <etext+0x1a2>
ffffffffc020030e:	00005597          	auipc	a1,0x5
ffffffffc0200312:	6f258593          	addi	a1,a1,1778 # ffffffffc0205a00 <etext+0x1c2>
ffffffffc0200316:	00005517          	auipc	a0,0x5
ffffffffc020031a:	68250513          	addi	a0,a0,1666 # ffffffffc0205998 <etext+0x15a>
ffffffffc020031e:	e7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    return 0;
}
ffffffffc0200322:	60a2                	ld	ra,8(sp)
ffffffffc0200324:	4501                	li	a0,0
ffffffffc0200326:	0141                	addi	sp,sp,16
ffffffffc0200328:	8082                	ret

ffffffffc020032a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032a:	1141                	addi	sp,sp,-16
ffffffffc020032c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032e:	ef3ff0ef          	jal	ra,ffffffffc0200220 <print_kerninfo>
    return 0;
}
ffffffffc0200332:	60a2                	ld	ra,8(sp)
ffffffffc0200334:	4501                	li	a0,0
ffffffffc0200336:	0141                	addi	sp,sp,16
ffffffffc0200338:	8082                	ret

ffffffffc020033a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033a:	1141                	addi	sp,sp,-16
ffffffffc020033c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033e:	f71ff0ef          	jal	ra,ffffffffc02002ae <print_stackframe>
    return 0;
}
ffffffffc0200342:	60a2                	ld	ra,8(sp)
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	0141                	addi	sp,sp,16
ffffffffc0200348:	8082                	ret

ffffffffc020034a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034a:	7115                	addi	sp,sp,-224
ffffffffc020034c:	ed5e                	sd	s7,152(sp)
ffffffffc020034e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200350:	00005517          	auipc	a0,0x5
ffffffffc0200354:	6c050513          	addi	a0,a0,1728 # ffffffffc0205a10 <etext+0x1d2>
kmonitor(struct trapframe *tf) {
ffffffffc0200358:	ed86                	sd	ra,216(sp)
ffffffffc020035a:	e9a2                	sd	s0,208(sp)
ffffffffc020035c:	e5a6                	sd	s1,200(sp)
ffffffffc020035e:	e1ca                	sd	s2,192(sp)
ffffffffc0200360:	fd4e                	sd	s3,184(sp)
ffffffffc0200362:	f952                	sd	s4,176(sp)
ffffffffc0200364:	f556                	sd	s5,168(sp)
ffffffffc0200366:	f15a                	sd	s6,160(sp)
ffffffffc0200368:	e962                	sd	s8,144(sp)
ffffffffc020036a:	e566                	sd	s9,136(sp)
ffffffffc020036c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036e:	e2bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200372:	00005517          	auipc	a0,0x5
ffffffffc0200376:	6c650513          	addi	a0,a0,1734 # ffffffffc0205a38 <etext+0x1fa>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	01b000ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
ffffffffc0200388:	00005c17          	auipc	s8,0x5
ffffffffc020038c:	720c0c13          	addi	s8,s8,1824 # ffffffffc0205aa8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00005917          	auipc	s2,0x5
ffffffffc0200394:	6d090913          	addi	s2,s2,1744 # ffffffffc0205a60 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00005497          	auipc	s1,0x5
ffffffffc020039c:	6d048493          	addi	s1,s1,1744 # ffffffffc0205a68 <etext+0x22a>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00005b17          	auipc	s6,0x5
ffffffffc02003a6:	6ceb0b13          	addi	s6,s6,1742 # ffffffffc0205a70 <etext+0x232>
        argv[argc ++] = buf;
ffffffffc02003aa:	00005a17          	auipc	s4,0x5
ffffffffc02003ae:	5e6a0a13          	addi	s4,s4,1510 # ffffffffc0205990 <etext+0x152>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b4:	854a                	mv	a0,s2
ffffffffc02003b6:	cf5ff0ef          	jal	ra,ffffffffc02000aa <readline>
ffffffffc02003ba:	842a                	mv	s0,a0
ffffffffc02003bc:	dd65                	beqz	a0,ffffffffc02003b4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003c2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c4:	e1bd                	bnez	a1,ffffffffc020042a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003c6:	fe0c87e3          	beqz	s9,ffffffffc02003b4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ca:	6582                	ld	a1,0(sp)
ffffffffc02003cc:	00005d17          	auipc	s10,0x5
ffffffffc02003d0:	6dcd0d13          	addi	s10,s10,1756 # ffffffffc0205aa8 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	3e0050ef          	jal	ra,ffffffffc02057ba <strcmp>
ffffffffc02003de:	c919                	beqz	a0,ffffffffc02003f4 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	2405                	addiw	s0,s0,1
ffffffffc02003e2:	0b540063          	beq	s0,s5,ffffffffc0200482 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e6:	000d3503          	ld	a0,0(s10)
ffffffffc02003ea:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ec:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ee:	3cc050ef          	jal	ra,ffffffffc02057ba <strcmp>
ffffffffc02003f2:	f57d                	bnez	a0,ffffffffc02003e0 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f4:	00141793          	slli	a5,s0,0x1
ffffffffc02003f8:	97a2                	add	a5,a5,s0
ffffffffc02003fa:	078e                	slli	a5,a5,0x3
ffffffffc02003fc:	97e2                	add	a5,a5,s8
ffffffffc02003fe:	6b9c                	ld	a5,16(a5)
ffffffffc0200400:	865e                	mv	a2,s7
ffffffffc0200402:	002c                	addi	a1,sp,8
ffffffffc0200404:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200408:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020040a:	fa0555e3          	bgez	a0,ffffffffc02003b4 <kmonitor+0x6a>
}
ffffffffc020040e:	60ee                	ld	ra,216(sp)
ffffffffc0200410:	644e                	ld	s0,208(sp)
ffffffffc0200412:	64ae                	ld	s1,200(sp)
ffffffffc0200414:	690e                	ld	s2,192(sp)
ffffffffc0200416:	79ea                	ld	s3,184(sp)
ffffffffc0200418:	7a4a                	ld	s4,176(sp)
ffffffffc020041a:	7aaa                	ld	s5,168(sp)
ffffffffc020041c:	7b0a                	ld	s6,160(sp)
ffffffffc020041e:	6bea                	ld	s7,152(sp)
ffffffffc0200420:	6c4a                	ld	s8,144(sp)
ffffffffc0200422:	6caa                	ld	s9,136(sp)
ffffffffc0200424:	6d0a                	ld	s10,128(sp)
ffffffffc0200426:	612d                	addi	sp,sp,224
ffffffffc0200428:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042a:	8526                	mv	a0,s1
ffffffffc020042c:	3d2050ef          	jal	ra,ffffffffc02057fe <strchr>
ffffffffc0200430:	c901                	beqz	a0,ffffffffc0200440 <kmonitor+0xf6>
ffffffffc0200432:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200436:	00040023          	sb	zero,0(s0)
ffffffffc020043a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043c:	d5c9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc020043e:	b7f5                	j	ffffffffc020042a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200440:	00044783          	lbu	a5,0(s0)
ffffffffc0200444:	d3c9                	beqz	a5,ffffffffc02003c6 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	033c8963          	beq	s9,s3,ffffffffc0200478 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020044a:	003c9793          	slli	a5,s9,0x3
ffffffffc020044e:	0118                	addi	a4,sp,128
ffffffffc0200450:	97ba                	add	a5,a5,a4
ffffffffc0200452:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020045a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020045c:	e591                	bnez	a1,ffffffffc0200468 <kmonitor+0x11e>
ffffffffc020045e:	b7b5                	j	ffffffffc02003ca <kmonitor+0x80>
ffffffffc0200460:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200464:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	d1a5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200468:	8526                	mv	a0,s1
ffffffffc020046a:	394050ef          	jal	ra,ffffffffc02057fe <strchr>
ffffffffc020046e:	d96d                	beqz	a0,ffffffffc0200460 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200470:	00044583          	lbu	a1,0(s0)
ffffffffc0200474:	d9a9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200476:	bf55                	j	ffffffffc020042a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200478:	45c1                	li	a1,16
ffffffffc020047a:	855a                	mv	a0,s6
ffffffffc020047c:	d1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200480:	b7e9                	j	ffffffffc020044a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00005517          	auipc	a0,0x5
ffffffffc0200488:	60c50513          	addi	a0,a0,1548 # ffffffffc0205a90 <etext+0x252>
ffffffffc020048c:	d0dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
ffffffffc0200490:	b715                	j	ffffffffc02003b4 <kmonitor+0x6a>

ffffffffc0200492 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200492:	000c6317          	auipc	t1,0xc6
ffffffffc0200496:	75e30313          	addi	t1,t1,1886 # ffffffffc02c6bf0 <is_panic>
ffffffffc020049a:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020049e:	715d                	addi	sp,sp,-80
ffffffffc02004a0:	ec06                	sd	ra,24(sp)
ffffffffc02004a2:	e822                	sd	s0,16(sp)
ffffffffc02004a4:	f436                	sd	a3,40(sp)
ffffffffc02004a6:	f83a                	sd	a4,48(sp)
ffffffffc02004a8:	fc3e                	sd	a5,56(sp)
ffffffffc02004aa:	e0c2                	sd	a6,64(sp)
ffffffffc02004ac:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004ae:	020e1a63          	bnez	t3,ffffffffc02004e2 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004b2:	4785                	li	a5,1
ffffffffc02004b4:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	8432                	mv	s0,a2
ffffffffc02004ba:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004bc:	862e                	mv	a2,a1
ffffffffc02004be:	85aa                	mv	a1,a0
ffffffffc02004c0:	00005517          	auipc	a0,0x5
ffffffffc02004c4:	63050513          	addi	a0,a0,1584 # ffffffffc0205af0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c8:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ca:	ccfff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ce:	65a2                	ld	a1,8(sp)
ffffffffc02004d0:	8522                	mv	a0,s0
ffffffffc02004d2:	ca7ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004d6:	00006517          	auipc	a0,0x6
ffffffffc02004da:	71250513          	addi	a0,a0,1810 # ffffffffc0206be8 <default_pmm_manager+0x578>
ffffffffc02004de:	cbbff0ef          	jal	ra,ffffffffc0200198 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004e2:	4501                	li	a0,0
ffffffffc02004e4:	4581                	li	a1,0
ffffffffc02004e6:	4601                	li	a2,0
ffffffffc02004e8:	48a1                	li	a7,8
ffffffffc02004ea:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ee:	4c0000ef          	jal	ra,ffffffffc02009ae <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	e57ff0ef          	jal	ra,ffffffffc020034a <kmonitor>
    while (1) {
ffffffffc02004f8:	bfed                	j	ffffffffc02004f2 <__panic+0x60>

ffffffffc02004fa <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	715d                	addi	sp,sp,-80
ffffffffc02004fc:	832e                	mv	t1,a1
ffffffffc02004fe:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200500:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200502:	8432                	mv	s0,a2
ffffffffc0200504:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200508:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020050a:	00005517          	auipc	a0,0x5
ffffffffc020050e:	60650513          	addi	a0,a0,1542 # ffffffffc0205b10 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200512:	ec06                	sd	ra,24(sp)
ffffffffc0200514:	f436                	sd	a3,40(sp)
ffffffffc0200516:	f83a                	sd	a4,48(sp)
ffffffffc0200518:	e0c2                	sd	a6,64(sp)
ffffffffc020051a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020051c:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051e:	c7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200522:	65a2                	ld	a1,8(sp)
ffffffffc0200524:	8522                	mv	a0,s0
ffffffffc0200526:	c53ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020052a:	00006517          	auipc	a0,0x6
ffffffffc020052e:	6be50513          	addi	a0,a0,1726 # ffffffffc0206be8 <default_pmm_manager+0x578>
ffffffffc0200532:	c67ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc0200536:	60e2                	ld	ra,24(sp)
ffffffffc0200538:	6442                	ld	s0,16(sp)
ffffffffc020053a:	6161                	addi	sp,sp,80
ffffffffc020053c:	8082                	ret

ffffffffc020053e <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc020053e:	02000793          	li	a5,32
ffffffffc0200542:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200546:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054a:	67e1                	lui	a5,0x18
ffffffffc020054c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf88>
ffffffffc0200550:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200552:	4581                	li	a1,0
ffffffffc0200554:	4601                	li	a2,0
ffffffffc0200556:	4881                	li	a7,0
ffffffffc0200558:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	00005517          	auipc	a0,0x5
ffffffffc0200560:	5d450513          	addi	a0,a0,1492 # ffffffffc0205b30 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000c6797          	auipc	a5,0xc6
ffffffffc0200568:	6807ba23          	sd	zero,1684(a5) # ffffffffc02c6bf8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056c:	b135                	j	ffffffffc0200198 <cprintf>

ffffffffc020056e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200572:	67e1                	lui	a5,0x18
ffffffffc0200574:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf88>
ffffffffc0200578:	953e                	add	a0,a0,a5
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	4881                	li	a7,0
ffffffffc0200580:	00000073          	ecall
ffffffffc0200584:	8082                	ret

ffffffffc0200586 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200588:	100027f3          	csrr	a5,sstatus
ffffffffc020058c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020058e:	0ff57513          	zext.b	a0,a0
ffffffffc0200592:	e799                	bnez	a5,ffffffffc02005a0 <cons_putc+0x18>
ffffffffc0200594:	4581                	li	a1,0
ffffffffc0200596:	4601                	li	a2,0
ffffffffc0200598:	4885                	li	a7,1
ffffffffc020059a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020059e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a0:	1101                	addi	sp,sp,-32
ffffffffc02005a2:	ec06                	sd	ra,24(sp)
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a6:	408000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005aa:	6522                	ld	a0,8(sp)
ffffffffc02005ac:	4581                	li	a1,0
ffffffffc02005ae:	4601                	li	a2,0
ffffffffc02005b0:	4885                	li	a7,1
ffffffffc02005b2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b6:	60e2                	ld	ra,24(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005ba:	a6fd                	j	ffffffffc02009a8 <intr_enable>

ffffffffc02005bc <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005bc:	100027f3          	csrr	a5,sstatus
ffffffffc02005c0:	8b89                	andi	a5,a5,2
ffffffffc02005c2:	eb89                	bnez	a5,ffffffffc02005d4 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c4:	4501                	li	a0,0
ffffffffc02005c6:	4581                	li	a1,0
ffffffffc02005c8:	4601                	li	a2,0
ffffffffc02005ca:	4889                	li	a7,2
ffffffffc02005cc:	00000073          	ecall
ffffffffc02005d0:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d2:	8082                	ret
int cons_getc(void) {
ffffffffc02005d4:	1101                	addi	sp,sp,-32
ffffffffc02005d6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005d8:	3d6000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005dc:	4501                	li	a0,0
ffffffffc02005de:	4581                	li	a1,0
ffffffffc02005e0:	4601                	li	a2,0
ffffffffc02005e2:	4889                	li	a7,2
ffffffffc02005e4:	00000073          	ecall
ffffffffc02005e8:	2501                	sext.w	a0,a0
ffffffffc02005ea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ec:	3bc000ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc02005f0:	60e2                	ld	ra,24(sp)
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	6105                	addi	sp,sp,32
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005f8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02005fa:	00005517          	auipc	a0,0x5
ffffffffc02005fe:	55650513          	addi	a0,a0,1366 # ffffffffc0205b50 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200602:	fc86                	sd	ra,120(sp)
ffffffffc0200604:	f8a2                	sd	s0,112(sp)
ffffffffc0200606:	e8d2                	sd	s4,80(sp)
ffffffffc0200608:	f4a6                	sd	s1,104(sp)
ffffffffc020060a:	f0ca                	sd	s2,96(sp)
ffffffffc020060c:	ecce                	sd	s3,88(sp)
ffffffffc020060e:	e4d6                	sd	s5,72(sp)
ffffffffc0200610:	e0da                	sd	s6,64(sp)
ffffffffc0200612:	fc5e                	sd	s7,56(sp)
ffffffffc0200614:	f862                	sd	s8,48(sp)
ffffffffc0200616:	f466                	sd	s9,40(sp)
ffffffffc0200618:	f06a                	sd	s10,32(sp)
ffffffffc020061a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020061c:	b7dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200620:	0000c597          	auipc	a1,0xc
ffffffffc0200624:	9e05b583          	ld	a1,-1568(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200628:	00005517          	auipc	a0,0x5
ffffffffc020062c:	53850513          	addi	a0,a0,1336 # ffffffffc0205b60 <commands+0xb8>
ffffffffc0200630:	b69ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200634:	0000c417          	auipc	s0,0xc
ffffffffc0200638:	9d440413          	addi	s0,s0,-1580 # ffffffffc020c008 <boot_dtb>
ffffffffc020063c:	600c                	ld	a1,0(s0)
ffffffffc020063e:	00005517          	auipc	a0,0x5
ffffffffc0200642:	53250513          	addi	a0,a0,1330 # ffffffffc0205b70 <commands+0xc8>
ffffffffc0200646:	b53ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020064a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020064e:	00005517          	auipc	a0,0x5
ffffffffc0200652:	53a50513          	addi	a0,a0,1338 # ffffffffc0205b88 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc0200656:	120a0463          	beqz	s4,ffffffffc020077e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020065a:	57f5                	li	a5,-3
ffffffffc020065c:	07fa                	slli	a5,a5,0x1e
ffffffffc020065e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200662:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200664:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200668:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020066e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200672:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	8ec9                	or	a3,a3,a0
ffffffffc0200682:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200686:	1b7d                	addi	s6,s6,-1
ffffffffc0200688:	0167f7b3          	and	a5,a5,s6
ffffffffc020068c:	8dd5                	or	a1,a1,a3
ffffffffc020068e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200690:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe19275>
ffffffffc020069a:	10f59163          	bne	a1,a5,ffffffffc020079c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020069e:	471c                	lw	a5,8(a4)
ffffffffc02006a0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006a8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006ac:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006bc:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006cc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	01146433          	or	s0,s0,a7
ffffffffc02006d2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006d6:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006da:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8c49                	or	s0,s0,a0
ffffffffc02006e2:	0166f6b3          	and	a3,a3,s6
ffffffffc02006e6:	00ca6a33          	or	s4,s4,a2
ffffffffc02006ea:	0167f7b3          	and	a5,a5,s6
ffffffffc02006ee:	8c55                	or	s0,s0,a3
ffffffffc02006f0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006f6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fa:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200706:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200708:	00005917          	auipc	s2,0x5
ffffffffc020070c:	4d090913          	addi	s2,s2,1232 # ffffffffc0205bd8 <commands+0x130>
ffffffffc0200710:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200712:	4d91                	li	s11,4
ffffffffc0200714:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200716:	00005497          	auipc	s1,0x5
ffffffffc020071a:	4ba48493          	addi	s1,s1,1210 # ffffffffc0205bd0 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020071e:	000a2703          	lw	a4,0(s4)
ffffffffc0200722:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0087569b          	srliw	a3,a4,0x8
ffffffffc020072a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0107571b          	srliw	a4,a4,0x10
ffffffffc020073a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200744:	8fd5                	or	a5,a5,a3
ffffffffc0200746:	00eb7733          	and	a4,s6,a4
ffffffffc020074a:	8fd9                	or	a5,a5,a4
ffffffffc020074c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020074e:	09778c63          	beq	a5,s7,ffffffffc02007e6 <dtb_init+0x1ee>
ffffffffc0200752:	00fbea63          	bltu	s7,a5,ffffffffc0200766 <dtb_init+0x16e>
ffffffffc0200756:	07a78663          	beq	a5,s10,ffffffffc02007c2 <dtb_init+0x1ca>
ffffffffc020075a:	4709                	li	a4,2
ffffffffc020075c:	00e79763          	bne	a5,a4,ffffffffc020076a <dtb_init+0x172>
ffffffffc0200760:	4c81                	li	s9,0
ffffffffc0200762:	8a56                	mv	s4,s5
ffffffffc0200764:	bf6d                	j	ffffffffc020071e <dtb_init+0x126>
ffffffffc0200766:	ffb78ee3          	beq	a5,s11,ffffffffc0200762 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020076a:	00005517          	auipc	a0,0x5
ffffffffc020076e:	4e650513          	addi	a0,a0,1254 # ffffffffc0205c50 <commands+0x1a8>
ffffffffc0200772:	a27ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200776:	00005517          	auipc	a0,0x5
ffffffffc020077a:	51250513          	addi	a0,a0,1298 # ffffffffc0205c88 <commands+0x1e0>
}
ffffffffc020077e:	7446                	ld	s0,112(sp)
ffffffffc0200780:	70e6                	ld	ra,120(sp)
ffffffffc0200782:	74a6                	ld	s1,104(sp)
ffffffffc0200784:	7906                	ld	s2,96(sp)
ffffffffc0200786:	69e6                	ld	s3,88(sp)
ffffffffc0200788:	6a46                	ld	s4,80(sp)
ffffffffc020078a:	6aa6                	ld	s5,72(sp)
ffffffffc020078c:	6b06                	ld	s6,64(sp)
ffffffffc020078e:	7be2                	ld	s7,56(sp)
ffffffffc0200790:	7c42                	ld	s8,48(sp)
ffffffffc0200792:	7ca2                	ld	s9,40(sp)
ffffffffc0200794:	7d02                	ld	s10,32(sp)
ffffffffc0200796:	6de2                	ld	s11,24(sp)
ffffffffc0200798:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020079a:	bafd                	j	ffffffffc0200198 <cprintf>
}
ffffffffc020079c:	7446                	ld	s0,112(sp)
ffffffffc020079e:	70e6                	ld	ra,120(sp)
ffffffffc02007a0:	74a6                	ld	s1,104(sp)
ffffffffc02007a2:	7906                	ld	s2,96(sp)
ffffffffc02007a4:	69e6                	ld	s3,88(sp)
ffffffffc02007a6:	6a46                	ld	s4,80(sp)
ffffffffc02007a8:	6aa6                	ld	s5,72(sp)
ffffffffc02007aa:	6b06                	ld	s6,64(sp)
ffffffffc02007ac:	7be2                	ld	s7,56(sp)
ffffffffc02007ae:	7c42                	ld	s8,48(sp)
ffffffffc02007b0:	7ca2                	ld	s9,40(sp)
ffffffffc02007b2:	7d02                	ld	s10,32(sp)
ffffffffc02007b4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007b6:	00005517          	auipc	a0,0x5
ffffffffc02007ba:	3f250513          	addi	a0,a0,1010 # ffffffffc0205ba8 <commands+0x100>
}
ffffffffc02007be:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c0:	bae1                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c2:	8556                	mv	a0,s5
ffffffffc02007c4:	7af040ef          	jal	ra,ffffffffc0205772 <strlen>
ffffffffc02007c8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ca:	4619                	li	a2,6
ffffffffc02007cc:	85a6                	mv	a1,s1
ffffffffc02007ce:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d0:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d2:	006050ef          	jal	ra,ffffffffc02057d8 <strncmp>
ffffffffc02007d6:	e111                	bnez	a0,ffffffffc02007da <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007d8:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007da:	0a91                	addi	s5,s5,4
ffffffffc02007dc:	9ad2                	add	s5,s5,s4
ffffffffc02007de:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e2:	8a56                	mv	s4,s5
ffffffffc02007e4:	bf2d                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007e6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ea:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ee:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fe:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200802:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020080e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200812:	00fb77b3          	and	a5,s6,a5
ffffffffc0200816:	00faeab3          	or	s5,s5,a5
ffffffffc020081a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020081c:	000c9c63          	bnez	s9,ffffffffc0200834 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200820:	1a82                	slli	s5,s5,0x20
ffffffffc0200822:	00368793          	addi	a5,a3,3
ffffffffc0200826:	020ada93          	srli	s5,s5,0x20
ffffffffc020082a:	9abe                	add	s5,s5,a5
ffffffffc020082c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200830:	8a56                	mv	s4,s5
ffffffffc0200832:	b5f5                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200834:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200838:	85ca                	mv	a1,s2
ffffffffc020083a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020083c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200840:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200844:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200848:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200850:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0087979b          	slliw	a5,a5,0x8
ffffffffc020085a:	8d59                	or	a0,a0,a4
ffffffffc020085c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200860:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200862:	1502                	slli	a0,a0,0x20
ffffffffc0200864:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200866:	9522                	add	a0,a0,s0
ffffffffc0200868:	753040ef          	jal	ra,ffffffffc02057ba <strcmp>
ffffffffc020086c:	66a2                	ld	a3,8(sp)
ffffffffc020086e:	f94d                	bnez	a0,ffffffffc0200820 <dtb_init+0x228>
ffffffffc0200870:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200820 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200874:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200878:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020087c:	00005517          	auipc	a0,0x5
ffffffffc0200880:	36450513          	addi	a0,a0,868 # ffffffffc0205be0 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc0200884:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200888:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020088c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200890:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200894:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200898:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020089c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a0:	0187d693          	srli	a3,a5,0x18
ffffffffc02008a4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008a8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008ac:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008b4:	010f6f33          	or	t5,t5,a6
ffffffffc02008b8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008bc:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008c4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c8:	0186f6b3          	and	a3,a3,s8
ffffffffc02008cc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d0:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008d4:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008d8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008dc:	8361                	srli	a4,a4,0x18
ffffffffc02008de:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008e6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008ea:	00cb7633          	and	a2,s6,a2
ffffffffc02008ee:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008f6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008fa:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008fe:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200902:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200906:	0088989b          	slliw	a7,a7,0x8
ffffffffc020090a:	011b78b3          	and	a7,s6,a7
ffffffffc020090e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200912:	00c6e733          	or	a4,a3,a2
ffffffffc0200916:	006c6c33          	or	s8,s8,t1
ffffffffc020091a:	010b76b3          	and	a3,s6,a6
ffffffffc020091e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200922:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200926:	016c6b33          	or	s6,s8,s6
ffffffffc020092a:	01146433          	or	s0,s0,a7
ffffffffc020092e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200930:	1702                	slli	a4,a4,0x20
ffffffffc0200932:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200934:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200938:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	0167eb33          	or	s6,a5,s6
ffffffffc0200942:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200944:	855ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200948:	85a2                	mv	a1,s0
ffffffffc020094a:	00005517          	auipc	a0,0x5
ffffffffc020094e:	2b650513          	addi	a0,a0,694 # ffffffffc0205c00 <commands+0x158>
ffffffffc0200952:	847ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200956:	014b5613          	srli	a2,s6,0x14
ffffffffc020095a:	85da                	mv	a1,s6
ffffffffc020095c:	00005517          	auipc	a0,0x5
ffffffffc0200960:	2bc50513          	addi	a0,a0,700 # ffffffffc0205c18 <commands+0x170>
ffffffffc0200964:	835ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200968:	008b05b3          	add	a1,s6,s0
ffffffffc020096c:	15fd                	addi	a1,a1,-1
ffffffffc020096e:	00005517          	auipc	a0,0x5
ffffffffc0200972:	2ca50513          	addi	a0,a0,714 # ffffffffc0205c38 <commands+0x190>
ffffffffc0200976:	823ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020097a:	00005517          	auipc	a0,0x5
ffffffffc020097e:	30e50513          	addi	a0,a0,782 # ffffffffc0205c88 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200982:	000c6797          	auipc	a5,0xc6
ffffffffc0200986:	2687bf23          	sd	s0,638(a5) # ffffffffc02c6c00 <memory_base>
        memory_size = mem_size;
ffffffffc020098a:	000c6797          	auipc	a5,0xc6
ffffffffc020098e:	2767bf23          	sd	s6,638(a5) # ffffffffc02c6c08 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200992:	b3f5                	j	ffffffffc020077e <dtb_init+0x186>

ffffffffc0200994 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200994:	000c6517          	auipc	a0,0xc6
ffffffffc0200998:	26c53503          	ld	a0,620(a0) # ffffffffc02c6c00 <memory_base>
ffffffffc020099c:	8082                	ret

ffffffffc020099e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020099e:	000c6517          	auipc	a0,0xc6
ffffffffc02009a2:	26a53503          	ld	a0,618(a0) # ffffffffc02c6c08 <memory_size>
ffffffffc02009a6:	8082                	ret

ffffffffc02009a8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009a8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009b4:	8082                	ret

ffffffffc02009b6 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009b6:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009ba:	00000797          	auipc	a5,0x0
ffffffffc02009be:	43a78793          	addi	a5,a5,1082 # ffffffffc0200df4 <__alltraps>
ffffffffc02009c2:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009c6:	000407b7          	lui	a5,0x40
ffffffffc02009ca:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009ce:	8082                	ret

ffffffffc02009d0 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d0:	610c                	ld	a1,0(a0)
{
ffffffffc02009d2:	1141                	addi	sp,sp,-16
ffffffffc02009d4:	e022                	sd	s0,0(sp)
ffffffffc02009d6:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	2c850513          	addi	a0,a0,712 # ffffffffc0205ca0 <commands+0x1f8>
{
ffffffffc02009e0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e2:	fb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009e6:	640c                	ld	a1,8(s0)
ffffffffc02009e8:	00005517          	auipc	a0,0x5
ffffffffc02009ec:	2d050513          	addi	a0,a0,720 # ffffffffc0205cb8 <commands+0x210>
ffffffffc02009f0:	fa8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f4:	680c                	ld	a1,16(s0)
ffffffffc02009f6:	00005517          	auipc	a0,0x5
ffffffffc02009fa:	2da50513          	addi	a0,a0,730 # ffffffffc0205cd0 <commands+0x228>
ffffffffc02009fe:	f9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a02:	6c0c                	ld	a1,24(s0)
ffffffffc0200a04:	00005517          	auipc	a0,0x5
ffffffffc0200a08:	2e450513          	addi	a0,a0,740 # ffffffffc0205ce8 <commands+0x240>
ffffffffc0200a0c:	f8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a10:	700c                	ld	a1,32(s0)
ffffffffc0200a12:	00005517          	auipc	a0,0x5
ffffffffc0200a16:	2ee50513          	addi	a0,a0,750 # ffffffffc0205d00 <commands+0x258>
ffffffffc0200a1a:	f7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a1e:	740c                	ld	a1,40(s0)
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	2f850513          	addi	a0,a0,760 # ffffffffc0205d18 <commands+0x270>
ffffffffc0200a28:	f70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a2c:	780c                	ld	a1,48(s0)
ffffffffc0200a2e:	00005517          	auipc	a0,0x5
ffffffffc0200a32:	30250513          	addi	a0,a0,770 # ffffffffc0205d30 <commands+0x288>
ffffffffc0200a36:	f62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3a:	7c0c                	ld	a1,56(s0)
ffffffffc0200a3c:	00005517          	auipc	a0,0x5
ffffffffc0200a40:	30c50513          	addi	a0,a0,780 # ffffffffc0205d48 <commands+0x2a0>
ffffffffc0200a44:	f54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a48:	602c                	ld	a1,64(s0)
ffffffffc0200a4a:	00005517          	auipc	a0,0x5
ffffffffc0200a4e:	31650513          	addi	a0,a0,790 # ffffffffc0205d60 <commands+0x2b8>
ffffffffc0200a52:	f46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a56:	642c                	ld	a1,72(s0)
ffffffffc0200a58:	00005517          	auipc	a0,0x5
ffffffffc0200a5c:	32050513          	addi	a0,a0,800 # ffffffffc0205d78 <commands+0x2d0>
ffffffffc0200a60:	f38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a64:	682c                	ld	a1,80(s0)
ffffffffc0200a66:	00005517          	auipc	a0,0x5
ffffffffc0200a6a:	32a50513          	addi	a0,a0,810 # ffffffffc0205d90 <commands+0x2e8>
ffffffffc0200a6e:	f2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a72:	6c2c                	ld	a1,88(s0)
ffffffffc0200a74:	00005517          	auipc	a0,0x5
ffffffffc0200a78:	33450513          	addi	a0,a0,820 # ffffffffc0205da8 <commands+0x300>
ffffffffc0200a7c:	f1cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a80:	702c                	ld	a1,96(s0)
ffffffffc0200a82:	00005517          	auipc	a0,0x5
ffffffffc0200a86:	33e50513          	addi	a0,a0,830 # ffffffffc0205dc0 <commands+0x318>
ffffffffc0200a8a:	f0eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a8e:	742c                	ld	a1,104(s0)
ffffffffc0200a90:	00005517          	auipc	a0,0x5
ffffffffc0200a94:	34850513          	addi	a0,a0,840 # ffffffffc0205dd8 <commands+0x330>
ffffffffc0200a98:	f00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a9c:	782c                	ld	a1,112(s0)
ffffffffc0200a9e:	00005517          	auipc	a0,0x5
ffffffffc0200aa2:	35250513          	addi	a0,a0,850 # ffffffffc0205df0 <commands+0x348>
ffffffffc0200aa6:	ef2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aaa:	7c2c                	ld	a1,120(s0)
ffffffffc0200aac:	00005517          	auipc	a0,0x5
ffffffffc0200ab0:	35c50513          	addi	a0,a0,860 # ffffffffc0205e08 <commands+0x360>
ffffffffc0200ab4:	ee4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200ab8:	604c                	ld	a1,128(s0)
ffffffffc0200aba:	00005517          	auipc	a0,0x5
ffffffffc0200abe:	36650513          	addi	a0,a0,870 # ffffffffc0205e20 <commands+0x378>
ffffffffc0200ac2:	ed6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200ac6:	644c                	ld	a1,136(s0)
ffffffffc0200ac8:	00005517          	auipc	a0,0x5
ffffffffc0200acc:	37050513          	addi	a0,a0,880 # ffffffffc0205e38 <commands+0x390>
ffffffffc0200ad0:	ec8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad4:	684c                	ld	a1,144(s0)
ffffffffc0200ad6:	00005517          	auipc	a0,0x5
ffffffffc0200ada:	37a50513          	addi	a0,a0,890 # ffffffffc0205e50 <commands+0x3a8>
ffffffffc0200ade:	ebaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae2:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae4:	00005517          	auipc	a0,0x5
ffffffffc0200ae8:	38450513          	addi	a0,a0,900 # ffffffffc0205e68 <commands+0x3c0>
ffffffffc0200aec:	eacff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af0:	704c                	ld	a1,160(s0)
ffffffffc0200af2:	00005517          	auipc	a0,0x5
ffffffffc0200af6:	38e50513          	addi	a0,a0,910 # ffffffffc0205e80 <commands+0x3d8>
ffffffffc0200afa:	e9eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200afe:	744c                	ld	a1,168(s0)
ffffffffc0200b00:	00005517          	auipc	a0,0x5
ffffffffc0200b04:	39850513          	addi	a0,a0,920 # ffffffffc0205e98 <commands+0x3f0>
ffffffffc0200b08:	e90ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b0c:	784c                	ld	a1,176(s0)
ffffffffc0200b0e:	00005517          	auipc	a0,0x5
ffffffffc0200b12:	3a250513          	addi	a0,a0,930 # ffffffffc0205eb0 <commands+0x408>
ffffffffc0200b16:	e82ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1a:	7c4c                	ld	a1,184(s0)
ffffffffc0200b1c:	00005517          	auipc	a0,0x5
ffffffffc0200b20:	3ac50513          	addi	a0,a0,940 # ffffffffc0205ec8 <commands+0x420>
ffffffffc0200b24:	e74ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b28:	606c                	ld	a1,192(s0)
ffffffffc0200b2a:	00005517          	auipc	a0,0x5
ffffffffc0200b2e:	3b650513          	addi	a0,a0,950 # ffffffffc0205ee0 <commands+0x438>
ffffffffc0200b32:	e66ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b36:	646c                	ld	a1,200(s0)
ffffffffc0200b38:	00005517          	auipc	a0,0x5
ffffffffc0200b3c:	3c050513          	addi	a0,a0,960 # ffffffffc0205ef8 <commands+0x450>
ffffffffc0200b40:	e58ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b44:	686c                	ld	a1,208(s0)
ffffffffc0200b46:	00005517          	auipc	a0,0x5
ffffffffc0200b4a:	3ca50513          	addi	a0,a0,970 # ffffffffc0205f10 <commands+0x468>
ffffffffc0200b4e:	e4aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b52:	6c6c                	ld	a1,216(s0)
ffffffffc0200b54:	00005517          	auipc	a0,0x5
ffffffffc0200b58:	3d450513          	addi	a0,a0,980 # ffffffffc0205f28 <commands+0x480>
ffffffffc0200b5c:	e3cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b60:	706c                	ld	a1,224(s0)
ffffffffc0200b62:	00005517          	auipc	a0,0x5
ffffffffc0200b66:	3de50513          	addi	a0,a0,990 # ffffffffc0205f40 <commands+0x498>
ffffffffc0200b6a:	e2eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b6e:	746c                	ld	a1,232(s0)
ffffffffc0200b70:	00005517          	auipc	a0,0x5
ffffffffc0200b74:	3e850513          	addi	a0,a0,1000 # ffffffffc0205f58 <commands+0x4b0>
ffffffffc0200b78:	e20ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b7c:	786c                	ld	a1,240(s0)
ffffffffc0200b7e:	00005517          	auipc	a0,0x5
ffffffffc0200b82:	3f250513          	addi	a0,a0,1010 # ffffffffc0205f70 <commands+0x4c8>
ffffffffc0200b86:	e12ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8a:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	00005517          	auipc	a0,0x5
ffffffffc0200b94:	3f850513          	addi	a0,a0,1016 # ffffffffc0205f88 <commands+0x4e0>
}
ffffffffc0200b98:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b9a:	dfeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b9e <print_trapframe>:
{
ffffffffc0200b9e:	1141                	addi	sp,sp,-16
ffffffffc0200ba0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba2:	85aa                	mv	a1,a0
{
ffffffffc0200ba4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba6:	00005517          	auipc	a0,0x5
ffffffffc0200baa:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205fa0 <commands+0x4f8>
{
ffffffffc0200bae:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb0:	de8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bb4:	8522                	mv	a0,s0
ffffffffc0200bb6:	e1bff0ef          	jal	ra,ffffffffc02009d0 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bba:	10043583          	ld	a1,256(s0)
ffffffffc0200bbe:	00005517          	auipc	a0,0x5
ffffffffc0200bc2:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205fb8 <commands+0x510>
ffffffffc0200bc6:	dd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bca:	10843583          	ld	a1,264(s0)
ffffffffc0200bce:	00005517          	auipc	a0,0x5
ffffffffc0200bd2:	40250513          	addi	a0,a0,1026 # ffffffffc0205fd0 <commands+0x528>
ffffffffc0200bd6:	dc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bda:	11043583          	ld	a1,272(s0)
ffffffffc0200bde:	00005517          	auipc	a0,0x5
ffffffffc0200be2:	40a50513          	addi	a0,a0,1034 # ffffffffc0205fe8 <commands+0x540>
ffffffffc0200be6:	db2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bea:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf2:	00005517          	auipc	a0,0x5
ffffffffc0200bf6:	40650513          	addi	a0,a0,1030 # ffffffffc0205ff8 <commands+0x550>
}
ffffffffc0200bfa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bfc:	d9cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200c00 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c00:	11853783          	ld	a5,280(a0)
ffffffffc0200c04:	472d                	li	a4,11
ffffffffc0200c06:	0786                	slli	a5,a5,0x1
ffffffffc0200c08:	8385                	srli	a5,a5,0x1
ffffffffc0200c0a:	06f76c63          	bltu	a4,a5,ffffffffc0200c82 <interrupt_handler+0x82>
ffffffffc0200c0e:	00005717          	auipc	a4,0x5
ffffffffc0200c12:	4a270713          	addi	a4,a4,1186 # ffffffffc02060b0 <commands+0x608>
ffffffffc0200c16:	078a                	slli	a5,a5,0x2
ffffffffc0200c18:	97ba                	add	a5,a5,a4
ffffffffc0200c1a:	439c                	lw	a5,0(a5)
ffffffffc0200c1c:	97ba                	add	a5,a5,a4
ffffffffc0200c1e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c20:	00005517          	auipc	a0,0x5
ffffffffc0200c24:	45050513          	addi	a0,a0,1104 # ffffffffc0206070 <commands+0x5c8>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c2c:	00005517          	auipc	a0,0x5
ffffffffc0200c30:	42450513          	addi	a0,a0,1060 # ffffffffc0206050 <commands+0x5a8>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c38:	00005517          	auipc	a0,0x5
ffffffffc0200c3c:	3d850513          	addi	a0,a0,984 # ffffffffc0206010 <commands+0x568>
ffffffffc0200c40:	d58ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c44:	00005517          	auipc	a0,0x5
ffffffffc0200c48:	3ec50513          	addi	a0,a0,1004 # ffffffffc0206030 <commands+0x588>
ffffffffc0200c4c:	d4cff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200c50:	1141                	addi	sp,sp,-16
ffffffffc0200c52:	e406                	sd	ra,8(sp)
        // clear_csr(sip, SIP_STIP);

        /* LAB3 :填写你在lab3中实现的代码 */
        // lab6: YOUR CODE  (update LAB3 steps)
        //  在时钟中断时调用调度器的 sched_class_proc_tick 函数
        clock_set_next_event();
ffffffffc0200c54:	91bff0ef          	jal	ra,ffffffffc020056e <clock_set_next_event>
        ticks++;
ffffffffc0200c58:	000c6717          	auipc	a4,0xc6
ffffffffc0200c5c:	fa070713          	addi	a4,a4,-96 # ffffffffc02c6bf8 <ticks>
ffffffffc0200c60:	631c                	ld	a5,0(a4)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c62:	60a2                	ld	ra,8(sp)
        sched_class_proc_tick(current);
ffffffffc0200c64:	000c6517          	auipc	a0,0xc6
ffffffffc0200c68:	fe453503          	ld	a0,-28(a0) # ffffffffc02c6c48 <current>
        ticks++;
ffffffffc0200c6c:	0785                	addi	a5,a5,1
ffffffffc0200c6e:	e31c                	sd	a5,0(a4)
}
ffffffffc0200c70:	0141                	addi	sp,sp,16
        sched_class_proc_tick(current);
ffffffffc0200c72:	4100406f          	j	ffffffffc0205082 <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c76:	00005517          	auipc	a0,0x5
ffffffffc0200c7a:	41a50513          	addi	a0,a0,1050 # ffffffffc0206090 <commands+0x5e8>
ffffffffc0200c7e:	d1aff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c82:	bf31                	j	ffffffffc0200b9e <print_trapframe>

ffffffffc0200c84 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c84:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c88:	1141                	addi	sp,sp,-16
ffffffffc0200c8a:	e022                	sd	s0,0(sp)
ffffffffc0200c8c:	e406                	sd	ra,8(sp)
ffffffffc0200c8e:	473d                	li	a4,15
ffffffffc0200c90:	842a                	mv	s0,a0
ffffffffc0200c92:	0af76b63          	bltu	a4,a5,ffffffffc0200d48 <exception_handler+0xc4>
ffffffffc0200c96:	00005717          	auipc	a4,0x5
ffffffffc0200c9a:	5da70713          	addi	a4,a4,1498 # ffffffffc0206270 <commands+0x7c8>
ffffffffc0200c9e:	078a                	slli	a5,a5,0x2
ffffffffc0200ca0:	97ba                	add	a5,a5,a4
ffffffffc0200ca2:	439c                	lw	a5,0(a5)
ffffffffc0200ca4:	97ba                	add	a5,a5,a4
ffffffffc0200ca6:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200ca8:	00005517          	auipc	a0,0x5
ffffffffc0200cac:	52050513          	addi	a0,a0,1312 # ffffffffc02061c8 <commands+0x720>
ffffffffc0200cb0:	ce8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200cb4:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cb8:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cba:	0791                	addi	a5,a5,4
ffffffffc0200cbc:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cc0:	6402                	ld	s0,0(sp)
ffffffffc0200cc2:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cc4:	6280406f          	j	ffffffffc02052ec <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cc8:	00005517          	auipc	a0,0x5
ffffffffc0200ccc:	52050513          	addi	a0,a0,1312 # ffffffffc02061e8 <commands+0x740>
}
ffffffffc0200cd0:	6402                	ld	s0,0(sp)
ffffffffc0200cd2:	60a2                	ld	ra,8(sp)
ffffffffc0200cd4:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200cd6:	cc2ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cda:	00005517          	auipc	a0,0x5
ffffffffc0200cde:	52e50513          	addi	a0,a0,1326 # ffffffffc0206208 <commands+0x760>
ffffffffc0200ce2:	b7fd                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200ce4:	00005517          	auipc	a0,0x5
ffffffffc0200ce8:	54450513          	addi	a0,a0,1348 # ffffffffc0206228 <commands+0x780>
ffffffffc0200cec:	b7d5                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200cee:	00005517          	auipc	a0,0x5
ffffffffc0200cf2:	55250513          	addi	a0,a0,1362 # ffffffffc0206240 <commands+0x798>
ffffffffc0200cf6:	bfe9                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200cf8:	00005517          	auipc	a0,0x5
ffffffffc0200cfc:	56050513          	addi	a0,a0,1376 # ffffffffc0206258 <commands+0x7b0>
ffffffffc0200d00:	bfc1                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d02:	00005517          	auipc	a0,0x5
ffffffffc0200d06:	3de50513          	addi	a0,a0,990 # ffffffffc02060e0 <commands+0x638>
ffffffffc0200d0a:	b7d9                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d0c:	00005517          	auipc	a0,0x5
ffffffffc0200d10:	3f450513          	addi	a0,a0,1012 # ffffffffc0206100 <commands+0x658>
ffffffffc0200d14:	bf75                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d16:	00005517          	auipc	a0,0x5
ffffffffc0200d1a:	40a50513          	addi	a0,a0,1034 # ffffffffc0206120 <commands+0x678>
ffffffffc0200d1e:	bf4d                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d20:	00005517          	auipc	a0,0x5
ffffffffc0200d24:	41850513          	addi	a0,a0,1048 # ffffffffc0206138 <commands+0x690>
ffffffffc0200d28:	b765                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200d2a:	00005517          	auipc	a0,0x5
ffffffffc0200d2e:	41e50513          	addi	a0,a0,1054 # ffffffffc0206148 <commands+0x6a0>
ffffffffc0200d32:	bf79                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d34:	00005517          	auipc	a0,0x5
ffffffffc0200d38:	43450513          	addi	a0,a0,1076 # ffffffffc0206168 <commands+0x6c0>
ffffffffc0200d3c:	bf51                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d3e:	00005517          	auipc	a0,0x5
ffffffffc0200d42:	47250513          	addi	a0,a0,1138 # ffffffffc02061b0 <commands+0x708>
ffffffffc0200d46:	b769                	j	ffffffffc0200cd0 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d48:	8522                	mv	a0,s0
}
ffffffffc0200d4a:	6402                	ld	s0,0(sp)
ffffffffc0200d4c:	60a2                	ld	ra,8(sp)
ffffffffc0200d4e:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d50:	b5b9                	j	ffffffffc0200b9e <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d52:	00005617          	auipc	a2,0x5
ffffffffc0200d56:	42e60613          	addi	a2,a2,1070 # ffffffffc0206180 <commands+0x6d8>
ffffffffc0200d5a:	0b500593          	li	a1,181
ffffffffc0200d5e:	00005517          	auipc	a0,0x5
ffffffffc0200d62:	43a50513          	addi	a0,a0,1082 # ffffffffc0206198 <commands+0x6f0>
ffffffffc0200d66:	f2cff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200d6a <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200d6a:	1101                	addi	sp,sp,-32
ffffffffc0200d6c:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d6e:	000c6417          	auipc	s0,0xc6
ffffffffc0200d72:	eda40413          	addi	s0,s0,-294 # ffffffffc02c6c48 <current>
ffffffffc0200d76:	6018                	ld	a4,0(s0)
{
ffffffffc0200d78:	ec06                	sd	ra,24(sp)
ffffffffc0200d7a:	e426                	sd	s1,8(sp)
ffffffffc0200d7c:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d7e:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200d82:	cf1d                	beqz	a4,ffffffffc0200dc0 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d84:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d88:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200d8c:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d8e:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d92:	0206c463          	bltz	a3,ffffffffc0200dba <trap+0x50>
        exception_handler(tf);
ffffffffc0200d96:	eefff0ef          	jal	ra,ffffffffc0200c84 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d9a:	601c                	ld	a5,0(s0)
ffffffffc0200d9c:	0b27b023          	sd	s2,160(a5) # 400a0 <_binary_obj___user_matrix_out_size+0x33988>
        if (!in_kernel)
ffffffffc0200da0:	e499                	bnez	s1,ffffffffc0200dae <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200da2:	0b07a703          	lw	a4,176(a5)
ffffffffc0200da6:	8b05                	andi	a4,a4,1
ffffffffc0200da8:	e329                	bnez	a4,ffffffffc0200dea <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200daa:	6f9c                	ld	a5,24(a5)
ffffffffc0200dac:	eb85                	bnez	a5,ffffffffc0200ddc <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200dae:	60e2                	ld	ra,24(sp)
ffffffffc0200db0:	6442                	ld	s0,16(sp)
ffffffffc0200db2:	64a2                	ld	s1,8(sp)
ffffffffc0200db4:	6902                	ld	s2,0(sp)
ffffffffc0200db6:	6105                	addi	sp,sp,32
ffffffffc0200db8:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200dba:	e47ff0ef          	jal	ra,ffffffffc0200c00 <interrupt_handler>
ffffffffc0200dbe:	bff1                	j	ffffffffc0200d9a <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dc0:	0006c863          	bltz	a3,ffffffffc0200dd0 <trap+0x66>
}
ffffffffc0200dc4:	6442                	ld	s0,16(sp)
ffffffffc0200dc6:	60e2                	ld	ra,24(sp)
ffffffffc0200dc8:	64a2                	ld	s1,8(sp)
ffffffffc0200dca:	6902                	ld	s2,0(sp)
ffffffffc0200dcc:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200dce:	bd5d                	j	ffffffffc0200c84 <exception_handler>
}
ffffffffc0200dd0:	6442                	ld	s0,16(sp)
ffffffffc0200dd2:	60e2                	ld	ra,24(sp)
ffffffffc0200dd4:	64a2                	ld	s1,8(sp)
ffffffffc0200dd6:	6902                	ld	s2,0(sp)
ffffffffc0200dd8:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200dda:	b51d                	j	ffffffffc0200c00 <interrupt_handler>
}
ffffffffc0200ddc:	6442                	ld	s0,16(sp)
ffffffffc0200dde:	60e2                	ld	ra,24(sp)
ffffffffc0200de0:	64a2                	ld	s1,8(sp)
ffffffffc0200de2:	6902                	ld	s2,0(sp)
ffffffffc0200de4:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200de6:	3c80406f          	j	ffffffffc02051ae <schedule>
                do_exit(-E_KILLED);
ffffffffc0200dea:	555d                	li	a0,-9
ffffffffc0200dec:	4a4030ef          	jal	ra,ffffffffc0204290 <do_exit>
            if (current->need_resched)
ffffffffc0200df0:	601c                	ld	a5,0(s0)
ffffffffc0200df2:	bf65                	j	ffffffffc0200daa <trap+0x40>

ffffffffc0200df4 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200df4:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200df8:	00011463          	bnez	sp,ffffffffc0200e00 <__alltraps+0xc>
ffffffffc0200dfc:	14002173          	csrr	sp,sscratch
ffffffffc0200e00:	712d                	addi	sp,sp,-288
ffffffffc0200e02:	e002                	sd	zero,0(sp)
ffffffffc0200e04:	e406                	sd	ra,8(sp)
ffffffffc0200e06:	ec0e                	sd	gp,24(sp)
ffffffffc0200e08:	f012                	sd	tp,32(sp)
ffffffffc0200e0a:	f416                	sd	t0,40(sp)
ffffffffc0200e0c:	f81a                	sd	t1,48(sp)
ffffffffc0200e0e:	fc1e                	sd	t2,56(sp)
ffffffffc0200e10:	e0a2                	sd	s0,64(sp)
ffffffffc0200e12:	e4a6                	sd	s1,72(sp)
ffffffffc0200e14:	e8aa                	sd	a0,80(sp)
ffffffffc0200e16:	ecae                	sd	a1,88(sp)
ffffffffc0200e18:	f0b2                	sd	a2,96(sp)
ffffffffc0200e1a:	f4b6                	sd	a3,104(sp)
ffffffffc0200e1c:	f8ba                	sd	a4,112(sp)
ffffffffc0200e1e:	fcbe                	sd	a5,120(sp)
ffffffffc0200e20:	e142                	sd	a6,128(sp)
ffffffffc0200e22:	e546                	sd	a7,136(sp)
ffffffffc0200e24:	e94a                	sd	s2,144(sp)
ffffffffc0200e26:	ed4e                	sd	s3,152(sp)
ffffffffc0200e28:	f152                	sd	s4,160(sp)
ffffffffc0200e2a:	f556                	sd	s5,168(sp)
ffffffffc0200e2c:	f95a                	sd	s6,176(sp)
ffffffffc0200e2e:	fd5e                	sd	s7,184(sp)
ffffffffc0200e30:	e1e2                	sd	s8,192(sp)
ffffffffc0200e32:	e5e6                	sd	s9,200(sp)
ffffffffc0200e34:	e9ea                	sd	s10,208(sp)
ffffffffc0200e36:	edee                	sd	s11,216(sp)
ffffffffc0200e38:	f1f2                	sd	t3,224(sp)
ffffffffc0200e3a:	f5f6                	sd	t4,232(sp)
ffffffffc0200e3c:	f9fa                	sd	t5,240(sp)
ffffffffc0200e3e:	fdfe                	sd	t6,248(sp)
ffffffffc0200e40:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e44:	100024f3          	csrr	s1,sstatus
ffffffffc0200e48:	14102973          	csrr	s2,sepc
ffffffffc0200e4c:	143029f3          	csrr	s3,stval
ffffffffc0200e50:	14202a73          	csrr	s4,scause
ffffffffc0200e54:	e822                	sd	s0,16(sp)
ffffffffc0200e56:	e226                	sd	s1,256(sp)
ffffffffc0200e58:	e64a                	sd	s2,264(sp)
ffffffffc0200e5a:	ea4e                	sd	s3,272(sp)
ffffffffc0200e5c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e5e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e60:	f0bff0ef          	jal	ra,ffffffffc0200d6a <trap>

ffffffffc0200e64 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e64:	6492                	ld	s1,256(sp)
ffffffffc0200e66:	6932                	ld	s2,264(sp)
ffffffffc0200e68:	1004f413          	andi	s0,s1,256
ffffffffc0200e6c:	e401                	bnez	s0,ffffffffc0200e74 <__trapret+0x10>
ffffffffc0200e6e:	1200                	addi	s0,sp,288
ffffffffc0200e70:	14041073          	csrw	sscratch,s0
ffffffffc0200e74:	10049073          	csrw	sstatus,s1
ffffffffc0200e78:	14191073          	csrw	sepc,s2
ffffffffc0200e7c:	60a2                	ld	ra,8(sp)
ffffffffc0200e7e:	61e2                	ld	gp,24(sp)
ffffffffc0200e80:	7202                	ld	tp,32(sp)
ffffffffc0200e82:	72a2                	ld	t0,40(sp)
ffffffffc0200e84:	7342                	ld	t1,48(sp)
ffffffffc0200e86:	73e2                	ld	t2,56(sp)
ffffffffc0200e88:	6406                	ld	s0,64(sp)
ffffffffc0200e8a:	64a6                	ld	s1,72(sp)
ffffffffc0200e8c:	6546                	ld	a0,80(sp)
ffffffffc0200e8e:	65e6                	ld	a1,88(sp)
ffffffffc0200e90:	7606                	ld	a2,96(sp)
ffffffffc0200e92:	76a6                	ld	a3,104(sp)
ffffffffc0200e94:	7746                	ld	a4,112(sp)
ffffffffc0200e96:	77e6                	ld	a5,120(sp)
ffffffffc0200e98:	680a                	ld	a6,128(sp)
ffffffffc0200e9a:	68aa                	ld	a7,136(sp)
ffffffffc0200e9c:	694a                	ld	s2,144(sp)
ffffffffc0200e9e:	69ea                	ld	s3,152(sp)
ffffffffc0200ea0:	7a0a                	ld	s4,160(sp)
ffffffffc0200ea2:	7aaa                	ld	s5,168(sp)
ffffffffc0200ea4:	7b4a                	ld	s6,176(sp)
ffffffffc0200ea6:	7bea                	ld	s7,184(sp)
ffffffffc0200ea8:	6c0e                	ld	s8,192(sp)
ffffffffc0200eaa:	6cae                	ld	s9,200(sp)
ffffffffc0200eac:	6d4e                	ld	s10,208(sp)
ffffffffc0200eae:	6dee                	ld	s11,216(sp)
ffffffffc0200eb0:	7e0e                	ld	t3,224(sp)
ffffffffc0200eb2:	7eae                	ld	t4,232(sp)
ffffffffc0200eb4:	7f4e                	ld	t5,240(sp)
ffffffffc0200eb6:	7fee                	ld	t6,248(sp)
ffffffffc0200eb8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eba:	10200073          	sret

ffffffffc0200ebe <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200ebe:	812a                	mv	sp,a0
ffffffffc0200ec0:	b755                	j	ffffffffc0200e64 <__trapret>

ffffffffc0200ec2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ec2:	000c2797          	auipc	a5,0xc2
ffffffffc0200ec6:	cd678793          	addi	a5,a5,-810 # ffffffffc02c2b98 <free_area>
ffffffffc0200eca:	e79c                	sd	a5,8(a5)
ffffffffc0200ecc:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200ece:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ed2:	8082                	ret

ffffffffc0200ed4 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200ed4:	000c2517          	auipc	a0,0xc2
ffffffffc0200ed8:	cd456503          	lwu	a0,-812(a0) # ffffffffc02c2ba8 <free_area+0x10>
ffffffffc0200edc:	8082                	ret

ffffffffc0200ede <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200ede:	715d                	addi	sp,sp,-80
ffffffffc0200ee0:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ee2:	000c2417          	auipc	s0,0xc2
ffffffffc0200ee6:	cb640413          	addi	s0,s0,-842 # ffffffffc02c2b98 <free_area>
ffffffffc0200eea:	641c                	ld	a5,8(s0)
ffffffffc0200eec:	e486                	sd	ra,72(sp)
ffffffffc0200eee:	fc26                	sd	s1,56(sp)
ffffffffc0200ef0:	f84a                	sd	s2,48(sp)
ffffffffc0200ef2:	f44e                	sd	s3,40(sp)
ffffffffc0200ef4:	f052                	sd	s4,32(sp)
ffffffffc0200ef6:	ec56                	sd	s5,24(sp)
ffffffffc0200ef8:	e85a                	sd	s6,16(sp)
ffffffffc0200efa:	e45e                	sd	s7,8(sp)
ffffffffc0200efc:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200efe:	2a878d63          	beq	a5,s0,ffffffffc02011b8 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200f02:	4481                	li	s1,0
ffffffffc0200f04:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f06:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f0a:	8b09                	andi	a4,a4,2
ffffffffc0200f0c:	2a070a63          	beqz	a4,ffffffffc02011c0 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200f10:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f14:	679c                	ld	a5,8(a5)
ffffffffc0200f16:	2905                	addiw	s2,s2,1
ffffffffc0200f18:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f1a:	fe8796e3          	bne	a5,s0,ffffffffc0200f06 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200f1e:	89a6                	mv	s3,s1
ffffffffc0200f20:	6df000ef          	jal	ra,ffffffffc0201dfe <nr_free_pages>
ffffffffc0200f24:	6f351e63          	bne	a0,s3,ffffffffc0201620 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f28:	4505                	li	a0,1
ffffffffc0200f2a:	657000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0200f2e:	8aaa                	mv	s5,a0
ffffffffc0200f30:	42050863          	beqz	a0,ffffffffc0201360 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f34:	4505                	li	a0,1
ffffffffc0200f36:	64b000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0200f3a:	89aa                	mv	s3,a0
ffffffffc0200f3c:	70050263          	beqz	a0,ffffffffc0201640 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f40:	4505                	li	a0,1
ffffffffc0200f42:	63f000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0200f46:	8a2a                	mv	s4,a0
ffffffffc0200f48:	48050c63          	beqz	a0,ffffffffc02013e0 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f4c:	293a8a63          	beq	s5,s3,ffffffffc02011e0 <default_check+0x302>
ffffffffc0200f50:	28aa8863          	beq	s5,a0,ffffffffc02011e0 <default_check+0x302>
ffffffffc0200f54:	28a98663          	beq	s3,a0,ffffffffc02011e0 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f58:	000aa783          	lw	a5,0(s5)
ffffffffc0200f5c:	2a079263          	bnez	a5,ffffffffc0201200 <default_check+0x322>
ffffffffc0200f60:	0009a783          	lw	a5,0(s3)
ffffffffc0200f64:	28079e63          	bnez	a5,ffffffffc0201200 <default_check+0x322>
ffffffffc0200f68:	411c                	lw	a5,0(a0)
ffffffffc0200f6a:	28079b63          	bnez	a5,ffffffffc0201200 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f6e:	000c6797          	auipc	a5,0xc6
ffffffffc0200f72:	cc27b783          	ld	a5,-830(a5) # ffffffffc02c6c30 <pages>
ffffffffc0200f76:	40fa8733          	sub	a4,s5,a5
ffffffffc0200f7a:	00007617          	auipc	a2,0x7
ffffffffc0200f7e:	1c663603          	ld	a2,454(a2) # ffffffffc0208140 <nbase>
ffffffffc0200f82:	8719                	srai	a4,a4,0x6
ffffffffc0200f84:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f86:	000c6697          	auipc	a3,0xc6
ffffffffc0200f8a:	ca26b683          	ld	a3,-862(a3) # ffffffffc02c6c28 <npage>
ffffffffc0200f8e:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f90:	0732                	slli	a4,a4,0xc
ffffffffc0200f92:	28d77763          	bgeu	a4,a3,ffffffffc0201220 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200f96:	40f98733          	sub	a4,s3,a5
ffffffffc0200f9a:	8719                	srai	a4,a4,0x6
ffffffffc0200f9c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f9e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200fa0:	4cd77063          	bgeu	a4,a3,ffffffffc0201460 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200fa4:	40f507b3          	sub	a5,a0,a5
ffffffffc0200fa8:	8799                	srai	a5,a5,0x6
ffffffffc0200faa:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fac:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fae:	30d7f963          	bgeu	a5,a3,ffffffffc02012c0 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200fb2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fb4:	00043c03          	ld	s8,0(s0)
ffffffffc0200fb8:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200fbc:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200fc0:	e400                	sd	s0,8(s0)
ffffffffc0200fc2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200fc4:	000c2797          	auipc	a5,0xc2
ffffffffc0200fc8:	be07a223          	sw	zero,-1052(a5) # ffffffffc02c2ba8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200fcc:	5b5000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0200fd0:	2c051863          	bnez	a0,ffffffffc02012a0 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200fd4:	4585                	li	a1,1
ffffffffc0200fd6:	8556                	mv	a0,s5
ffffffffc0200fd8:	5e7000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    free_page(p1);
ffffffffc0200fdc:	4585                	li	a1,1
ffffffffc0200fde:	854e                	mv	a0,s3
ffffffffc0200fe0:	5df000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    free_page(p2);
ffffffffc0200fe4:	4585                	li	a1,1
ffffffffc0200fe6:	8552                	mv	a0,s4
ffffffffc0200fe8:	5d7000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    assert(nr_free == 3);
ffffffffc0200fec:	4818                	lw	a4,16(s0)
ffffffffc0200fee:	478d                	li	a5,3
ffffffffc0200ff0:	28f71863          	bne	a4,a5,ffffffffc0201280 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	58b000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0200ffa:	89aa                	mv	s3,a0
ffffffffc0200ffc:	26050263          	beqz	a0,ffffffffc0201260 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201000:	4505                	li	a0,1
ffffffffc0201002:	57f000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201006:	8aaa                	mv	s5,a0
ffffffffc0201008:	3a050c63          	beqz	a0,ffffffffc02013c0 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020100c:	4505                	li	a0,1
ffffffffc020100e:	573000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201012:	8a2a                	mv	s4,a0
ffffffffc0201014:	38050663          	beqz	a0,ffffffffc02013a0 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201018:	4505                	li	a0,1
ffffffffc020101a:	567000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc020101e:	36051163          	bnez	a0,ffffffffc0201380 <default_check+0x4a2>
    free_page(p0);
ffffffffc0201022:	4585                	li	a1,1
ffffffffc0201024:	854e                	mv	a0,s3
ffffffffc0201026:	599000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020102a:	641c                	ld	a5,8(s0)
ffffffffc020102c:	20878a63          	beq	a5,s0,ffffffffc0201240 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201030:	4505                	li	a0,1
ffffffffc0201032:	54f000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201036:	30a99563          	bne	s3,a0,ffffffffc0201340 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc020103a:	4505                	li	a0,1
ffffffffc020103c:	545000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201040:	2e051063          	bnez	a0,ffffffffc0201320 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201044:	481c                	lw	a5,16(s0)
ffffffffc0201046:	2a079d63          	bnez	a5,ffffffffc0201300 <default_check+0x422>
    free_page(p);
ffffffffc020104a:	854e                	mv	a0,s3
ffffffffc020104c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020104e:	01843023          	sd	s8,0(s0)
ffffffffc0201052:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201056:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020105a:	565000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    free_page(p1);
ffffffffc020105e:	4585                	li	a1,1
ffffffffc0201060:	8556                	mv	a0,s5
ffffffffc0201062:	55d000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    free_page(p2);
ffffffffc0201066:	4585                	li	a1,1
ffffffffc0201068:	8552                	mv	a0,s4
ffffffffc020106a:	555000ef          	jal	ra,ffffffffc0201dbe <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020106e:	4515                	li	a0,5
ffffffffc0201070:	511000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201074:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201076:	26050563          	beqz	a0,ffffffffc02012e0 <default_check+0x402>
ffffffffc020107a:	651c                	ld	a5,8(a0)
ffffffffc020107c:	8385                	srli	a5,a5,0x1
ffffffffc020107e:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201080:	54079063          	bnez	a5,ffffffffc02015c0 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201084:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201086:	00043b03          	ld	s6,0(s0)
ffffffffc020108a:	00843a83          	ld	s5,8(s0)
ffffffffc020108e:	e000                	sd	s0,0(s0)
ffffffffc0201090:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201092:	4ef000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201096:	50051563          	bnez	a0,ffffffffc02015a0 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020109a:	08098a13          	addi	s4,s3,128
ffffffffc020109e:	8552                	mv	a0,s4
ffffffffc02010a0:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02010a2:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02010a6:	000c2797          	auipc	a5,0xc2
ffffffffc02010aa:	b007a123          	sw	zero,-1278(a5) # ffffffffc02c2ba8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010ae:	511000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010b2:	4511                	li	a0,4
ffffffffc02010b4:	4cd000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc02010b8:	4c051463          	bnez	a0,ffffffffc0201580 <default_check+0x6a2>
ffffffffc02010bc:	0889b783          	ld	a5,136(s3)
ffffffffc02010c0:	8385                	srli	a5,a5,0x1
ffffffffc02010c2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010c4:	48078e63          	beqz	a5,ffffffffc0201560 <default_check+0x682>
ffffffffc02010c8:	0909a703          	lw	a4,144(s3)
ffffffffc02010cc:	478d                	li	a5,3
ffffffffc02010ce:	48f71963          	bne	a4,a5,ffffffffc0201560 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010d2:	450d                	li	a0,3
ffffffffc02010d4:	4ad000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc02010d8:	8c2a                	mv	s8,a0
ffffffffc02010da:	46050363          	beqz	a0,ffffffffc0201540 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02010de:	4505                	li	a0,1
ffffffffc02010e0:	4a1000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc02010e4:	42051e63          	bnez	a0,ffffffffc0201520 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02010e8:	418a1c63          	bne	s4,s8,ffffffffc0201500 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010ec:	4585                	li	a1,1
ffffffffc02010ee:	854e                	mv	a0,s3
ffffffffc02010f0:	4cf000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    free_pages(p1, 3);
ffffffffc02010f4:	458d                	li	a1,3
ffffffffc02010f6:	8552                	mv	a0,s4
ffffffffc02010f8:	4c7000ef          	jal	ra,ffffffffc0201dbe <free_pages>
ffffffffc02010fc:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201100:	04098c13          	addi	s8,s3,64
ffffffffc0201104:	8385                	srli	a5,a5,0x1
ffffffffc0201106:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201108:	3c078c63          	beqz	a5,ffffffffc02014e0 <default_check+0x602>
ffffffffc020110c:	0109a703          	lw	a4,16(s3)
ffffffffc0201110:	4785                	li	a5,1
ffffffffc0201112:	3cf71763          	bne	a4,a5,ffffffffc02014e0 <default_check+0x602>
ffffffffc0201116:	008a3783          	ld	a5,8(s4)
ffffffffc020111a:	8385                	srli	a5,a5,0x1
ffffffffc020111c:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020111e:	3a078163          	beqz	a5,ffffffffc02014c0 <default_check+0x5e2>
ffffffffc0201122:	010a2703          	lw	a4,16(s4)
ffffffffc0201126:	478d                	li	a5,3
ffffffffc0201128:	38f71c63          	bne	a4,a5,ffffffffc02014c0 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020112c:	4505                	li	a0,1
ffffffffc020112e:	453000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201132:	36a99763          	bne	s3,a0,ffffffffc02014a0 <default_check+0x5c2>
    free_page(p0);
ffffffffc0201136:	4585                	li	a1,1
ffffffffc0201138:	487000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020113c:	4509                	li	a0,2
ffffffffc020113e:	443000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201142:	32aa1f63          	bne	s4,a0,ffffffffc0201480 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201146:	4589                	li	a1,2
ffffffffc0201148:	477000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    free_page(p2);
ffffffffc020114c:	4585                	li	a1,1
ffffffffc020114e:	8562                	mv	a0,s8
ffffffffc0201150:	46f000ef          	jal	ra,ffffffffc0201dbe <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201154:	4515                	li	a0,5
ffffffffc0201156:	42b000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc020115a:	89aa                	mv	s3,a0
ffffffffc020115c:	48050263          	beqz	a0,ffffffffc02015e0 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201160:	4505                	li	a0,1
ffffffffc0201162:	41f000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc0201166:	2c051d63          	bnez	a0,ffffffffc0201440 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020116a:	481c                	lw	a5,16(s0)
ffffffffc020116c:	2a079a63          	bnez	a5,ffffffffc0201420 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201170:	4595                	li	a1,5
ffffffffc0201172:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201174:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201178:	01643023          	sd	s6,0(s0)
ffffffffc020117c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201180:	43f000ef          	jal	ra,ffffffffc0201dbe <free_pages>
    return listelm->next;
ffffffffc0201184:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201186:	00878963          	beq	a5,s0,ffffffffc0201198 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020118a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020118e:	679c                	ld	a5,8(a5)
ffffffffc0201190:	397d                	addiw	s2,s2,-1
ffffffffc0201192:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201194:	fe879be3          	bne	a5,s0,ffffffffc020118a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201198:	26091463          	bnez	s2,ffffffffc0201400 <default_check+0x522>
    assert(total == 0);
ffffffffc020119c:	46049263          	bnez	s1,ffffffffc0201600 <default_check+0x722>
}
ffffffffc02011a0:	60a6                	ld	ra,72(sp)
ffffffffc02011a2:	6406                	ld	s0,64(sp)
ffffffffc02011a4:	74e2                	ld	s1,56(sp)
ffffffffc02011a6:	7942                	ld	s2,48(sp)
ffffffffc02011a8:	79a2                	ld	s3,40(sp)
ffffffffc02011aa:	7a02                	ld	s4,32(sp)
ffffffffc02011ac:	6ae2                	ld	s5,24(sp)
ffffffffc02011ae:	6b42                	ld	s6,16(sp)
ffffffffc02011b0:	6ba2                	ld	s7,8(sp)
ffffffffc02011b2:	6c02                	ld	s8,0(sp)
ffffffffc02011b4:	6161                	addi	sp,sp,80
ffffffffc02011b6:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02011b8:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011ba:	4481                	li	s1,0
ffffffffc02011bc:	4901                	li	s2,0
ffffffffc02011be:	b38d                	j	ffffffffc0200f20 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02011c0:	00005697          	auipc	a3,0x5
ffffffffc02011c4:	0f068693          	addi	a3,a3,240 # ffffffffc02062b0 <commands+0x808>
ffffffffc02011c8:	00005617          	auipc	a2,0x5
ffffffffc02011cc:	0f860613          	addi	a2,a2,248 # ffffffffc02062c0 <commands+0x818>
ffffffffc02011d0:	11000593          	li	a1,272
ffffffffc02011d4:	00005517          	auipc	a0,0x5
ffffffffc02011d8:	10450513          	addi	a0,a0,260 # ffffffffc02062d8 <commands+0x830>
ffffffffc02011dc:	ab6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011e0:	00005697          	auipc	a3,0x5
ffffffffc02011e4:	19068693          	addi	a3,a3,400 # ffffffffc0206370 <commands+0x8c8>
ffffffffc02011e8:	00005617          	auipc	a2,0x5
ffffffffc02011ec:	0d860613          	addi	a2,a2,216 # ffffffffc02062c0 <commands+0x818>
ffffffffc02011f0:	0db00593          	li	a1,219
ffffffffc02011f4:	00005517          	auipc	a0,0x5
ffffffffc02011f8:	0e450513          	addi	a0,a0,228 # ffffffffc02062d8 <commands+0x830>
ffffffffc02011fc:	a96ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201200:	00005697          	auipc	a3,0x5
ffffffffc0201204:	19868693          	addi	a3,a3,408 # ffffffffc0206398 <commands+0x8f0>
ffffffffc0201208:	00005617          	auipc	a2,0x5
ffffffffc020120c:	0b860613          	addi	a2,a2,184 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201210:	0dc00593          	li	a1,220
ffffffffc0201214:	00005517          	auipc	a0,0x5
ffffffffc0201218:	0c450513          	addi	a0,a0,196 # ffffffffc02062d8 <commands+0x830>
ffffffffc020121c:	a76ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201220:	00005697          	auipc	a3,0x5
ffffffffc0201224:	1b868693          	addi	a3,a3,440 # ffffffffc02063d8 <commands+0x930>
ffffffffc0201228:	00005617          	auipc	a2,0x5
ffffffffc020122c:	09860613          	addi	a2,a2,152 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201230:	0de00593          	li	a1,222
ffffffffc0201234:	00005517          	auipc	a0,0x5
ffffffffc0201238:	0a450513          	addi	a0,a0,164 # ffffffffc02062d8 <commands+0x830>
ffffffffc020123c:	a56ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201240:	00005697          	auipc	a3,0x5
ffffffffc0201244:	22068693          	addi	a3,a3,544 # ffffffffc0206460 <commands+0x9b8>
ffffffffc0201248:	00005617          	auipc	a2,0x5
ffffffffc020124c:	07860613          	addi	a2,a2,120 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201250:	0f700593          	li	a1,247
ffffffffc0201254:	00005517          	auipc	a0,0x5
ffffffffc0201258:	08450513          	addi	a0,a0,132 # ffffffffc02062d8 <commands+0x830>
ffffffffc020125c:	a36ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201260:	00005697          	auipc	a3,0x5
ffffffffc0201264:	0b068693          	addi	a3,a3,176 # ffffffffc0206310 <commands+0x868>
ffffffffc0201268:	00005617          	auipc	a2,0x5
ffffffffc020126c:	05860613          	addi	a2,a2,88 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201270:	0f000593          	li	a1,240
ffffffffc0201274:	00005517          	auipc	a0,0x5
ffffffffc0201278:	06450513          	addi	a0,a0,100 # ffffffffc02062d8 <commands+0x830>
ffffffffc020127c:	a16ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc0201280:	00005697          	auipc	a3,0x5
ffffffffc0201284:	1d068693          	addi	a3,a3,464 # ffffffffc0206450 <commands+0x9a8>
ffffffffc0201288:	00005617          	auipc	a2,0x5
ffffffffc020128c:	03860613          	addi	a2,a2,56 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201290:	0ee00593          	li	a1,238
ffffffffc0201294:	00005517          	auipc	a0,0x5
ffffffffc0201298:	04450513          	addi	a0,a0,68 # ffffffffc02062d8 <commands+0x830>
ffffffffc020129c:	9f6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012a0:	00005697          	auipc	a3,0x5
ffffffffc02012a4:	19868693          	addi	a3,a3,408 # ffffffffc0206438 <commands+0x990>
ffffffffc02012a8:	00005617          	auipc	a2,0x5
ffffffffc02012ac:	01860613          	addi	a2,a2,24 # ffffffffc02062c0 <commands+0x818>
ffffffffc02012b0:	0e900593          	li	a1,233
ffffffffc02012b4:	00005517          	auipc	a0,0x5
ffffffffc02012b8:	02450513          	addi	a0,a0,36 # ffffffffc02062d8 <commands+0x830>
ffffffffc02012bc:	9d6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012c0:	00005697          	auipc	a3,0x5
ffffffffc02012c4:	15868693          	addi	a3,a3,344 # ffffffffc0206418 <commands+0x970>
ffffffffc02012c8:	00005617          	auipc	a2,0x5
ffffffffc02012cc:	ff860613          	addi	a2,a2,-8 # ffffffffc02062c0 <commands+0x818>
ffffffffc02012d0:	0e000593          	li	a1,224
ffffffffc02012d4:	00005517          	auipc	a0,0x5
ffffffffc02012d8:	00450513          	addi	a0,a0,4 # ffffffffc02062d8 <commands+0x830>
ffffffffc02012dc:	9b6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc02012e0:	00005697          	auipc	a3,0x5
ffffffffc02012e4:	1c868693          	addi	a3,a3,456 # ffffffffc02064a8 <commands+0xa00>
ffffffffc02012e8:	00005617          	auipc	a2,0x5
ffffffffc02012ec:	fd860613          	addi	a2,a2,-40 # ffffffffc02062c0 <commands+0x818>
ffffffffc02012f0:	11800593          	li	a1,280
ffffffffc02012f4:	00005517          	auipc	a0,0x5
ffffffffc02012f8:	fe450513          	addi	a0,a0,-28 # ffffffffc02062d8 <commands+0x830>
ffffffffc02012fc:	996ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201300:	00005697          	auipc	a3,0x5
ffffffffc0201304:	19868693          	addi	a3,a3,408 # ffffffffc0206498 <commands+0x9f0>
ffffffffc0201308:	00005617          	auipc	a2,0x5
ffffffffc020130c:	fb860613          	addi	a2,a2,-72 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201310:	0fd00593          	li	a1,253
ffffffffc0201314:	00005517          	auipc	a0,0x5
ffffffffc0201318:	fc450513          	addi	a0,a0,-60 # ffffffffc02062d8 <commands+0x830>
ffffffffc020131c:	976ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201320:	00005697          	auipc	a3,0x5
ffffffffc0201324:	11868693          	addi	a3,a3,280 # ffffffffc0206438 <commands+0x990>
ffffffffc0201328:	00005617          	auipc	a2,0x5
ffffffffc020132c:	f9860613          	addi	a2,a2,-104 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201330:	0fb00593          	li	a1,251
ffffffffc0201334:	00005517          	auipc	a0,0x5
ffffffffc0201338:	fa450513          	addi	a0,a0,-92 # ffffffffc02062d8 <commands+0x830>
ffffffffc020133c:	956ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201340:	00005697          	auipc	a3,0x5
ffffffffc0201344:	13868693          	addi	a3,a3,312 # ffffffffc0206478 <commands+0x9d0>
ffffffffc0201348:	00005617          	auipc	a2,0x5
ffffffffc020134c:	f7860613          	addi	a2,a2,-136 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201350:	0fa00593          	li	a1,250
ffffffffc0201354:	00005517          	auipc	a0,0x5
ffffffffc0201358:	f8450513          	addi	a0,a0,-124 # ffffffffc02062d8 <commands+0x830>
ffffffffc020135c:	936ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201360:	00005697          	auipc	a3,0x5
ffffffffc0201364:	fb068693          	addi	a3,a3,-80 # ffffffffc0206310 <commands+0x868>
ffffffffc0201368:	00005617          	auipc	a2,0x5
ffffffffc020136c:	f5860613          	addi	a2,a2,-168 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201370:	0d700593          	li	a1,215
ffffffffc0201374:	00005517          	auipc	a0,0x5
ffffffffc0201378:	f6450513          	addi	a0,a0,-156 # ffffffffc02062d8 <commands+0x830>
ffffffffc020137c:	916ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201380:	00005697          	auipc	a3,0x5
ffffffffc0201384:	0b868693          	addi	a3,a3,184 # ffffffffc0206438 <commands+0x990>
ffffffffc0201388:	00005617          	auipc	a2,0x5
ffffffffc020138c:	f3860613          	addi	a2,a2,-200 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201390:	0f400593          	li	a1,244
ffffffffc0201394:	00005517          	auipc	a0,0x5
ffffffffc0201398:	f4450513          	addi	a0,a0,-188 # ffffffffc02062d8 <commands+0x830>
ffffffffc020139c:	8f6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013a0:	00005697          	auipc	a3,0x5
ffffffffc02013a4:	fb068693          	addi	a3,a3,-80 # ffffffffc0206350 <commands+0x8a8>
ffffffffc02013a8:	00005617          	auipc	a2,0x5
ffffffffc02013ac:	f1860613          	addi	a2,a2,-232 # ffffffffc02062c0 <commands+0x818>
ffffffffc02013b0:	0f200593          	li	a1,242
ffffffffc02013b4:	00005517          	auipc	a0,0x5
ffffffffc02013b8:	f2450513          	addi	a0,a0,-220 # ffffffffc02062d8 <commands+0x830>
ffffffffc02013bc:	8d6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013c0:	00005697          	auipc	a3,0x5
ffffffffc02013c4:	f7068693          	addi	a3,a3,-144 # ffffffffc0206330 <commands+0x888>
ffffffffc02013c8:	00005617          	auipc	a2,0x5
ffffffffc02013cc:	ef860613          	addi	a2,a2,-264 # ffffffffc02062c0 <commands+0x818>
ffffffffc02013d0:	0f100593          	li	a1,241
ffffffffc02013d4:	00005517          	auipc	a0,0x5
ffffffffc02013d8:	f0450513          	addi	a0,a0,-252 # ffffffffc02062d8 <commands+0x830>
ffffffffc02013dc:	8b6ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013e0:	00005697          	auipc	a3,0x5
ffffffffc02013e4:	f7068693          	addi	a3,a3,-144 # ffffffffc0206350 <commands+0x8a8>
ffffffffc02013e8:	00005617          	auipc	a2,0x5
ffffffffc02013ec:	ed860613          	addi	a2,a2,-296 # ffffffffc02062c0 <commands+0x818>
ffffffffc02013f0:	0d900593          	li	a1,217
ffffffffc02013f4:	00005517          	auipc	a0,0x5
ffffffffc02013f8:	ee450513          	addi	a0,a0,-284 # ffffffffc02062d8 <commands+0x830>
ffffffffc02013fc:	896ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc0201400:	00005697          	auipc	a3,0x5
ffffffffc0201404:	1f868693          	addi	a3,a3,504 # ffffffffc02065f8 <commands+0xb50>
ffffffffc0201408:	00005617          	auipc	a2,0x5
ffffffffc020140c:	eb860613          	addi	a2,a2,-328 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201410:	14600593          	li	a1,326
ffffffffc0201414:	00005517          	auipc	a0,0x5
ffffffffc0201418:	ec450513          	addi	a0,a0,-316 # ffffffffc02062d8 <commands+0x830>
ffffffffc020141c:	876ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201420:	00005697          	auipc	a3,0x5
ffffffffc0201424:	07868693          	addi	a3,a3,120 # ffffffffc0206498 <commands+0x9f0>
ffffffffc0201428:	00005617          	auipc	a2,0x5
ffffffffc020142c:	e9860613          	addi	a2,a2,-360 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201430:	13a00593          	li	a1,314
ffffffffc0201434:	00005517          	auipc	a0,0x5
ffffffffc0201438:	ea450513          	addi	a0,a0,-348 # ffffffffc02062d8 <commands+0x830>
ffffffffc020143c:	856ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201440:	00005697          	auipc	a3,0x5
ffffffffc0201444:	ff868693          	addi	a3,a3,-8 # ffffffffc0206438 <commands+0x990>
ffffffffc0201448:	00005617          	auipc	a2,0x5
ffffffffc020144c:	e7860613          	addi	a2,a2,-392 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201450:	13800593          	li	a1,312
ffffffffc0201454:	00005517          	auipc	a0,0x5
ffffffffc0201458:	e8450513          	addi	a0,a0,-380 # ffffffffc02062d8 <commands+0x830>
ffffffffc020145c:	836ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201460:	00005697          	auipc	a3,0x5
ffffffffc0201464:	f9868693          	addi	a3,a3,-104 # ffffffffc02063f8 <commands+0x950>
ffffffffc0201468:	00005617          	auipc	a2,0x5
ffffffffc020146c:	e5860613          	addi	a2,a2,-424 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201470:	0df00593          	li	a1,223
ffffffffc0201474:	00005517          	auipc	a0,0x5
ffffffffc0201478:	e6450513          	addi	a0,a0,-412 # ffffffffc02062d8 <commands+0x830>
ffffffffc020147c:	816ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201480:	00005697          	auipc	a3,0x5
ffffffffc0201484:	13868693          	addi	a3,a3,312 # ffffffffc02065b8 <commands+0xb10>
ffffffffc0201488:	00005617          	auipc	a2,0x5
ffffffffc020148c:	e3860613          	addi	a2,a2,-456 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201490:	13200593          	li	a1,306
ffffffffc0201494:	00005517          	auipc	a0,0x5
ffffffffc0201498:	e4450513          	addi	a0,a0,-444 # ffffffffc02062d8 <commands+0x830>
ffffffffc020149c:	ff7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02014a0:	00005697          	auipc	a3,0x5
ffffffffc02014a4:	0f868693          	addi	a3,a3,248 # ffffffffc0206598 <commands+0xaf0>
ffffffffc02014a8:	00005617          	auipc	a2,0x5
ffffffffc02014ac:	e1860613          	addi	a2,a2,-488 # ffffffffc02062c0 <commands+0x818>
ffffffffc02014b0:	13000593          	li	a1,304
ffffffffc02014b4:	00005517          	auipc	a0,0x5
ffffffffc02014b8:	e2450513          	addi	a0,a0,-476 # ffffffffc02062d8 <commands+0x830>
ffffffffc02014bc:	fd7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014c0:	00005697          	auipc	a3,0x5
ffffffffc02014c4:	0b068693          	addi	a3,a3,176 # ffffffffc0206570 <commands+0xac8>
ffffffffc02014c8:	00005617          	auipc	a2,0x5
ffffffffc02014cc:	df860613          	addi	a2,a2,-520 # ffffffffc02062c0 <commands+0x818>
ffffffffc02014d0:	12e00593          	li	a1,302
ffffffffc02014d4:	00005517          	auipc	a0,0x5
ffffffffc02014d8:	e0450513          	addi	a0,a0,-508 # ffffffffc02062d8 <commands+0x830>
ffffffffc02014dc:	fb7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014e0:	00005697          	auipc	a3,0x5
ffffffffc02014e4:	06868693          	addi	a3,a3,104 # ffffffffc0206548 <commands+0xaa0>
ffffffffc02014e8:	00005617          	auipc	a2,0x5
ffffffffc02014ec:	dd860613          	addi	a2,a2,-552 # ffffffffc02062c0 <commands+0x818>
ffffffffc02014f0:	12d00593          	li	a1,301
ffffffffc02014f4:	00005517          	auipc	a0,0x5
ffffffffc02014f8:	de450513          	addi	a0,a0,-540 # ffffffffc02062d8 <commands+0x830>
ffffffffc02014fc:	f97fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201500:	00005697          	auipc	a3,0x5
ffffffffc0201504:	03868693          	addi	a3,a3,56 # ffffffffc0206538 <commands+0xa90>
ffffffffc0201508:	00005617          	auipc	a2,0x5
ffffffffc020150c:	db860613          	addi	a2,a2,-584 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201510:	12800593          	li	a1,296
ffffffffc0201514:	00005517          	auipc	a0,0x5
ffffffffc0201518:	dc450513          	addi	a0,a0,-572 # ffffffffc02062d8 <commands+0x830>
ffffffffc020151c:	f77fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201520:	00005697          	auipc	a3,0x5
ffffffffc0201524:	f1868693          	addi	a3,a3,-232 # ffffffffc0206438 <commands+0x990>
ffffffffc0201528:	00005617          	auipc	a2,0x5
ffffffffc020152c:	d9860613          	addi	a2,a2,-616 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201530:	12700593          	li	a1,295
ffffffffc0201534:	00005517          	auipc	a0,0x5
ffffffffc0201538:	da450513          	addi	a0,a0,-604 # ffffffffc02062d8 <commands+0x830>
ffffffffc020153c:	f57fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201540:	00005697          	auipc	a3,0x5
ffffffffc0201544:	fd868693          	addi	a3,a3,-40 # ffffffffc0206518 <commands+0xa70>
ffffffffc0201548:	00005617          	auipc	a2,0x5
ffffffffc020154c:	d7860613          	addi	a2,a2,-648 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201550:	12600593          	li	a1,294
ffffffffc0201554:	00005517          	auipc	a0,0x5
ffffffffc0201558:	d8450513          	addi	a0,a0,-636 # ffffffffc02062d8 <commands+0x830>
ffffffffc020155c:	f37fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201560:	00005697          	auipc	a3,0x5
ffffffffc0201564:	f8868693          	addi	a3,a3,-120 # ffffffffc02064e8 <commands+0xa40>
ffffffffc0201568:	00005617          	auipc	a2,0x5
ffffffffc020156c:	d5860613          	addi	a2,a2,-680 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201570:	12500593          	li	a1,293
ffffffffc0201574:	00005517          	auipc	a0,0x5
ffffffffc0201578:	d6450513          	addi	a0,a0,-668 # ffffffffc02062d8 <commands+0x830>
ffffffffc020157c:	f17fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201580:	00005697          	auipc	a3,0x5
ffffffffc0201584:	f5068693          	addi	a3,a3,-176 # ffffffffc02064d0 <commands+0xa28>
ffffffffc0201588:	00005617          	auipc	a2,0x5
ffffffffc020158c:	d3860613          	addi	a2,a2,-712 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201590:	12400593          	li	a1,292
ffffffffc0201594:	00005517          	auipc	a0,0x5
ffffffffc0201598:	d4450513          	addi	a0,a0,-700 # ffffffffc02062d8 <commands+0x830>
ffffffffc020159c:	ef7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015a0:	00005697          	auipc	a3,0x5
ffffffffc02015a4:	e9868693          	addi	a3,a3,-360 # ffffffffc0206438 <commands+0x990>
ffffffffc02015a8:	00005617          	auipc	a2,0x5
ffffffffc02015ac:	d1860613          	addi	a2,a2,-744 # ffffffffc02062c0 <commands+0x818>
ffffffffc02015b0:	11e00593          	li	a1,286
ffffffffc02015b4:	00005517          	auipc	a0,0x5
ffffffffc02015b8:	d2450513          	addi	a0,a0,-732 # ffffffffc02062d8 <commands+0x830>
ffffffffc02015bc:	ed7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015c0:	00005697          	auipc	a3,0x5
ffffffffc02015c4:	ef868693          	addi	a3,a3,-264 # ffffffffc02064b8 <commands+0xa10>
ffffffffc02015c8:	00005617          	auipc	a2,0x5
ffffffffc02015cc:	cf860613          	addi	a2,a2,-776 # ffffffffc02062c0 <commands+0x818>
ffffffffc02015d0:	11900593          	li	a1,281
ffffffffc02015d4:	00005517          	auipc	a0,0x5
ffffffffc02015d8:	d0450513          	addi	a0,a0,-764 # ffffffffc02062d8 <commands+0x830>
ffffffffc02015dc:	eb7fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015e0:	00005697          	auipc	a3,0x5
ffffffffc02015e4:	ff868693          	addi	a3,a3,-8 # ffffffffc02065d8 <commands+0xb30>
ffffffffc02015e8:	00005617          	auipc	a2,0x5
ffffffffc02015ec:	cd860613          	addi	a2,a2,-808 # ffffffffc02062c0 <commands+0x818>
ffffffffc02015f0:	13700593          	li	a1,311
ffffffffc02015f4:	00005517          	auipc	a0,0x5
ffffffffc02015f8:	ce450513          	addi	a0,a0,-796 # ffffffffc02062d8 <commands+0x830>
ffffffffc02015fc:	e97fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc0201600:	00005697          	auipc	a3,0x5
ffffffffc0201604:	00868693          	addi	a3,a3,8 # ffffffffc0206608 <commands+0xb60>
ffffffffc0201608:	00005617          	auipc	a2,0x5
ffffffffc020160c:	cb860613          	addi	a2,a2,-840 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201610:	14700593          	li	a1,327
ffffffffc0201614:	00005517          	auipc	a0,0x5
ffffffffc0201618:	cc450513          	addi	a0,a0,-828 # ffffffffc02062d8 <commands+0x830>
ffffffffc020161c:	e77fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201620:	00005697          	auipc	a3,0x5
ffffffffc0201624:	cd068693          	addi	a3,a3,-816 # ffffffffc02062f0 <commands+0x848>
ffffffffc0201628:	00005617          	auipc	a2,0x5
ffffffffc020162c:	c9860613          	addi	a2,a2,-872 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201630:	11300593          	li	a1,275
ffffffffc0201634:	00005517          	auipc	a0,0x5
ffffffffc0201638:	ca450513          	addi	a0,a0,-860 # ffffffffc02062d8 <commands+0x830>
ffffffffc020163c:	e57fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201640:	00005697          	auipc	a3,0x5
ffffffffc0201644:	cf068693          	addi	a3,a3,-784 # ffffffffc0206330 <commands+0x888>
ffffffffc0201648:	00005617          	auipc	a2,0x5
ffffffffc020164c:	c7860613          	addi	a2,a2,-904 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201650:	0d800593          	li	a1,216
ffffffffc0201654:	00005517          	auipc	a0,0x5
ffffffffc0201658:	c8450513          	addi	a0,a0,-892 # ffffffffc02062d8 <commands+0x830>
ffffffffc020165c:	e37fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201660 <default_free_pages>:
{
ffffffffc0201660:	1141                	addi	sp,sp,-16
ffffffffc0201662:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201664:	14058463          	beqz	a1,ffffffffc02017ac <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201668:	00659693          	slli	a3,a1,0x6
ffffffffc020166c:	96aa                	add	a3,a3,a0
ffffffffc020166e:	87aa                	mv	a5,a0
ffffffffc0201670:	02d50263          	beq	a0,a3,ffffffffc0201694 <default_free_pages+0x34>
ffffffffc0201674:	6798                	ld	a4,8(a5)
ffffffffc0201676:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201678:	10071a63          	bnez	a4,ffffffffc020178c <default_free_pages+0x12c>
ffffffffc020167c:	6798                	ld	a4,8(a5)
ffffffffc020167e:	8b09                	andi	a4,a4,2
ffffffffc0201680:	10071663          	bnez	a4,ffffffffc020178c <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201684:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201688:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020168c:	04078793          	addi	a5,a5,64
ffffffffc0201690:	fed792e3          	bne	a5,a3,ffffffffc0201674 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201694:	2581                	sext.w	a1,a1
ffffffffc0201696:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201698:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020169c:	4789                	li	a5,2
ffffffffc020169e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02016a2:	000c1697          	auipc	a3,0xc1
ffffffffc02016a6:	4f668693          	addi	a3,a3,1270 # ffffffffc02c2b98 <free_area>
ffffffffc02016aa:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016ac:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016ae:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016b2:	9db9                	addw	a1,a1,a4
ffffffffc02016b4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02016b6:	0ad78463          	beq	a5,a3,ffffffffc020175e <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02016ba:	fe878713          	addi	a4,a5,-24
ffffffffc02016be:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02016c2:	4581                	li	a1,0
            if (base < page)
ffffffffc02016c4:	00e56a63          	bltu	a0,a4,ffffffffc02016d8 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02016c8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02016ca:	04d70c63          	beq	a4,a3,ffffffffc0201722 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02016ce:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02016d0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02016d4:	fee57ae3          	bgeu	a0,a4,ffffffffc02016c8 <default_free_pages+0x68>
ffffffffc02016d8:	c199                	beqz	a1,ffffffffc02016de <default_free_pages+0x7e>
ffffffffc02016da:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016de:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016e0:	e390                	sd	a2,0(a5)
ffffffffc02016e2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016e4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016e6:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02016e8:	00d70d63          	beq	a4,a3,ffffffffc0201702 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02016ec:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016f0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02016f4:	02059813          	slli	a6,a1,0x20
ffffffffc02016f8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02016fc:	97b2                	add	a5,a5,a2
ffffffffc02016fe:	02f50c63          	beq	a0,a5,ffffffffc0201736 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201702:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201704:	00d78c63          	beq	a5,a3,ffffffffc020171c <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201708:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020170a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020170e:	02061593          	slli	a1,a2,0x20
ffffffffc0201712:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201716:	972a                	add	a4,a4,a0
ffffffffc0201718:	04e68a63          	beq	a3,a4,ffffffffc020176c <default_free_pages+0x10c>
}
ffffffffc020171c:	60a2                	ld	ra,8(sp)
ffffffffc020171e:	0141                	addi	sp,sp,16
ffffffffc0201720:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201722:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201724:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201726:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201728:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020172a:	02d70763          	beq	a4,a3,ffffffffc0201758 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020172e:	8832                	mv	a6,a2
ffffffffc0201730:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201732:	87ba                	mv	a5,a4
ffffffffc0201734:	bf71                	j	ffffffffc02016d0 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201736:	491c                	lw	a5,16(a0)
ffffffffc0201738:	9dbd                	addw	a1,a1,a5
ffffffffc020173a:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020173e:	57f5                	li	a5,-3
ffffffffc0201740:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201744:	01853803          	ld	a6,24(a0)
ffffffffc0201748:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020174a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020174c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201750:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201752:	0105b023          	sd	a6,0(a1)
ffffffffc0201756:	b77d                	j	ffffffffc0201704 <default_free_pages+0xa4>
ffffffffc0201758:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc020175a:	873e                	mv	a4,a5
ffffffffc020175c:	bf41                	j	ffffffffc02016ec <default_free_pages+0x8c>
}
ffffffffc020175e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201760:	e390                	sd	a2,0(a5)
ffffffffc0201762:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201764:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201766:	ed1c                	sd	a5,24(a0)
ffffffffc0201768:	0141                	addi	sp,sp,16
ffffffffc020176a:	8082                	ret
            base->property += p->property;
ffffffffc020176c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201770:	ff078693          	addi	a3,a5,-16
ffffffffc0201774:	9e39                	addw	a2,a2,a4
ffffffffc0201776:	c910                	sw	a2,16(a0)
ffffffffc0201778:	5775                	li	a4,-3
ffffffffc020177a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020177e:	6398                	ld	a4,0(a5)
ffffffffc0201780:	679c                	ld	a5,8(a5)
}
ffffffffc0201782:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201784:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201786:	e398                	sd	a4,0(a5)
ffffffffc0201788:	0141                	addi	sp,sp,16
ffffffffc020178a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020178c:	00005697          	auipc	a3,0x5
ffffffffc0201790:	e9468693          	addi	a3,a3,-364 # ffffffffc0206620 <commands+0xb78>
ffffffffc0201794:	00005617          	auipc	a2,0x5
ffffffffc0201798:	b2c60613          	addi	a2,a2,-1236 # ffffffffc02062c0 <commands+0x818>
ffffffffc020179c:	09400593          	li	a1,148
ffffffffc02017a0:	00005517          	auipc	a0,0x5
ffffffffc02017a4:	b3850513          	addi	a0,a0,-1224 # ffffffffc02062d8 <commands+0x830>
ffffffffc02017a8:	cebfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc02017ac:	00005697          	auipc	a3,0x5
ffffffffc02017b0:	e6c68693          	addi	a3,a3,-404 # ffffffffc0206618 <commands+0xb70>
ffffffffc02017b4:	00005617          	auipc	a2,0x5
ffffffffc02017b8:	b0c60613          	addi	a2,a2,-1268 # ffffffffc02062c0 <commands+0x818>
ffffffffc02017bc:	09000593          	li	a1,144
ffffffffc02017c0:	00005517          	auipc	a0,0x5
ffffffffc02017c4:	b1850513          	addi	a0,a0,-1256 # ffffffffc02062d8 <commands+0x830>
ffffffffc02017c8:	ccbfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02017cc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017cc:	c941                	beqz	a0,ffffffffc020185c <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02017ce:	000c1597          	auipc	a1,0xc1
ffffffffc02017d2:	3ca58593          	addi	a1,a1,970 # ffffffffc02c2b98 <free_area>
ffffffffc02017d6:	0105a803          	lw	a6,16(a1)
ffffffffc02017da:	872a                	mv	a4,a0
ffffffffc02017dc:	02081793          	slli	a5,a6,0x20
ffffffffc02017e0:	9381                	srli	a5,a5,0x20
ffffffffc02017e2:	00a7ee63          	bltu	a5,a0,ffffffffc02017fe <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017e6:	87ae                	mv	a5,a1
ffffffffc02017e8:	a801                	j	ffffffffc02017f8 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02017ea:	ff87a683          	lw	a3,-8(a5)
ffffffffc02017ee:	02069613          	slli	a2,a3,0x20
ffffffffc02017f2:	9201                	srli	a2,a2,0x20
ffffffffc02017f4:	00e67763          	bgeu	a2,a4,ffffffffc0201802 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02017f8:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02017fa:	feb798e3          	bne	a5,a1,ffffffffc02017ea <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02017fe:	4501                	li	a0,0
}
ffffffffc0201800:	8082                	ret
    return listelm->prev;
ffffffffc0201802:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201806:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020180a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020180e:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201812:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201816:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc020181a:	02c77863          	bgeu	a4,a2,ffffffffc020184a <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020181e:	071a                	slli	a4,a4,0x6
ffffffffc0201820:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201822:	41c686bb          	subw	a3,a3,t3
ffffffffc0201826:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201828:	00870613          	addi	a2,a4,8
ffffffffc020182c:	4689                	li	a3,2
ffffffffc020182e:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201832:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201836:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020183a:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020183e:	e290                	sd	a2,0(a3)
ffffffffc0201840:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201844:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201846:	01173c23          	sd	a7,24(a4)
ffffffffc020184a:	41c8083b          	subw	a6,a6,t3
ffffffffc020184e:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201852:	5775                	li	a4,-3
ffffffffc0201854:	17c1                	addi	a5,a5,-16
ffffffffc0201856:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020185a:	8082                	ret
{
ffffffffc020185c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020185e:	00005697          	auipc	a3,0x5
ffffffffc0201862:	dba68693          	addi	a3,a3,-582 # ffffffffc0206618 <commands+0xb70>
ffffffffc0201866:	00005617          	auipc	a2,0x5
ffffffffc020186a:	a5a60613          	addi	a2,a2,-1446 # ffffffffc02062c0 <commands+0x818>
ffffffffc020186e:	06c00593          	li	a1,108
ffffffffc0201872:	00005517          	auipc	a0,0x5
ffffffffc0201876:	a6650513          	addi	a0,a0,-1434 # ffffffffc02062d8 <commands+0x830>
{
ffffffffc020187a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020187c:	c17fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201880 <default_init_memmap>:
{
ffffffffc0201880:	1141                	addi	sp,sp,-16
ffffffffc0201882:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201884:	c5f1                	beqz	a1,ffffffffc0201950 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201886:	00659693          	slli	a3,a1,0x6
ffffffffc020188a:	96aa                	add	a3,a3,a0
ffffffffc020188c:	87aa                	mv	a5,a0
ffffffffc020188e:	00d50f63          	beq	a0,a3,ffffffffc02018ac <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201892:	6798                	ld	a4,8(a5)
ffffffffc0201894:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201896:	cf49                	beqz	a4,ffffffffc0201930 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201898:	0007a823          	sw	zero,16(a5)
ffffffffc020189c:	0007b423          	sd	zero,8(a5)
ffffffffc02018a0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018a4:	04078793          	addi	a5,a5,64
ffffffffc02018a8:	fed795e3          	bne	a5,a3,ffffffffc0201892 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018ac:	2581                	sext.w	a1,a1
ffffffffc02018ae:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018b0:	4789                	li	a5,2
ffffffffc02018b2:	00850713          	addi	a4,a0,8
ffffffffc02018b6:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018ba:	000c1697          	auipc	a3,0xc1
ffffffffc02018be:	2de68693          	addi	a3,a3,734 # ffffffffc02c2b98 <free_area>
ffffffffc02018c2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018c4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018c6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018ca:	9db9                	addw	a1,a1,a4
ffffffffc02018cc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02018ce:	04d78a63          	beq	a5,a3,ffffffffc0201922 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02018d2:	fe878713          	addi	a4,a5,-24
ffffffffc02018d6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02018da:	4581                	li	a1,0
            if (base < page)
ffffffffc02018dc:	00e56a63          	bltu	a0,a4,ffffffffc02018f0 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02018e0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02018e2:	02d70263          	beq	a4,a3,ffffffffc0201906 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02018e6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02018e8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02018ec:	fee57ae3          	bgeu	a0,a4,ffffffffc02018e0 <default_init_memmap+0x60>
ffffffffc02018f0:	c199                	beqz	a1,ffffffffc02018f6 <default_init_memmap+0x76>
ffffffffc02018f2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018f6:	6398                	ld	a4,0(a5)
}
ffffffffc02018f8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018fa:	e390                	sd	a2,0(a5)
ffffffffc02018fc:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018fe:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201900:	ed18                	sd	a4,24(a0)
ffffffffc0201902:	0141                	addi	sp,sp,16
ffffffffc0201904:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201906:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201908:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020190a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020190c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020190e:	00d70663          	beq	a4,a3,ffffffffc020191a <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201912:	8832                	mv	a6,a2
ffffffffc0201914:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201916:	87ba                	mv	a5,a4
ffffffffc0201918:	bfc1                	j	ffffffffc02018e8 <default_init_memmap+0x68>
}
ffffffffc020191a:	60a2                	ld	ra,8(sp)
ffffffffc020191c:	e290                	sd	a2,0(a3)
ffffffffc020191e:	0141                	addi	sp,sp,16
ffffffffc0201920:	8082                	ret
ffffffffc0201922:	60a2                	ld	ra,8(sp)
ffffffffc0201924:	e390                	sd	a2,0(a5)
ffffffffc0201926:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201928:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020192a:	ed1c                	sd	a5,24(a0)
ffffffffc020192c:	0141                	addi	sp,sp,16
ffffffffc020192e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201930:	00005697          	auipc	a3,0x5
ffffffffc0201934:	d1868693          	addi	a3,a3,-744 # ffffffffc0206648 <commands+0xba0>
ffffffffc0201938:	00005617          	auipc	a2,0x5
ffffffffc020193c:	98860613          	addi	a2,a2,-1656 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201940:	04b00593          	li	a1,75
ffffffffc0201944:	00005517          	auipc	a0,0x5
ffffffffc0201948:	99450513          	addi	a0,a0,-1644 # ffffffffc02062d8 <commands+0x830>
ffffffffc020194c:	b47fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201950:	00005697          	auipc	a3,0x5
ffffffffc0201954:	cc868693          	addi	a3,a3,-824 # ffffffffc0206618 <commands+0xb70>
ffffffffc0201958:	00005617          	auipc	a2,0x5
ffffffffc020195c:	96860613          	addi	a2,a2,-1688 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201960:	04700593          	li	a1,71
ffffffffc0201964:	00005517          	auipc	a0,0x5
ffffffffc0201968:	97450513          	addi	a0,a0,-1676 # ffffffffc02062d8 <commands+0x830>
ffffffffc020196c:	b27fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201970 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201970:	c94d                	beqz	a0,ffffffffc0201a22 <slob_free+0xb2>
{
ffffffffc0201972:	1141                	addi	sp,sp,-16
ffffffffc0201974:	e022                	sd	s0,0(sp)
ffffffffc0201976:	e406                	sd	ra,8(sp)
ffffffffc0201978:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020197a:	e9c1                	bnez	a1,ffffffffc0201a0a <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020197c:	100027f3          	csrr	a5,sstatus
ffffffffc0201980:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201982:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201984:	ebd9                	bnez	a5,ffffffffc0201a1a <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201986:	000c1617          	auipc	a2,0xc1
ffffffffc020198a:	e0260613          	addi	a2,a2,-510 # ffffffffc02c2788 <slobfree>
ffffffffc020198e:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201990:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201992:	679c                	ld	a5,8(a5)
ffffffffc0201994:	02877a63          	bgeu	a4,s0,ffffffffc02019c8 <slob_free+0x58>
ffffffffc0201998:	00f46463          	bltu	s0,a5,ffffffffc02019a0 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020199c:	fef76ae3          	bltu	a4,a5,ffffffffc0201990 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02019a0:	400c                	lw	a1,0(s0)
ffffffffc02019a2:	00459693          	slli	a3,a1,0x4
ffffffffc02019a6:	96a2                	add	a3,a3,s0
ffffffffc02019a8:	02d78a63          	beq	a5,a3,ffffffffc02019dc <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019ac:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02019ae:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019b0:	00469793          	slli	a5,a3,0x4
ffffffffc02019b4:	97ba                	add	a5,a5,a4
ffffffffc02019b6:	02f40e63          	beq	s0,a5,ffffffffc02019f2 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02019ba:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02019bc:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc02019be:	e129                	bnez	a0,ffffffffc0201a00 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02019c0:	60a2                	ld	ra,8(sp)
ffffffffc02019c2:	6402                	ld	s0,0(sp)
ffffffffc02019c4:	0141                	addi	sp,sp,16
ffffffffc02019c6:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c8:	fcf764e3          	bltu	a4,a5,ffffffffc0201990 <slob_free+0x20>
ffffffffc02019cc:	fcf472e3          	bgeu	s0,a5,ffffffffc0201990 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02019d0:	400c                	lw	a1,0(s0)
ffffffffc02019d2:	00459693          	slli	a3,a1,0x4
ffffffffc02019d6:	96a2                	add	a3,a3,s0
ffffffffc02019d8:	fcd79ae3          	bne	a5,a3,ffffffffc02019ac <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02019dc:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02019de:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02019e0:	9db5                	addw	a1,a1,a3
ffffffffc02019e2:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02019e4:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02019e6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019e8:	00469793          	slli	a5,a3,0x4
ffffffffc02019ec:	97ba                	add	a5,a5,a4
ffffffffc02019ee:	fcf416e3          	bne	s0,a5,ffffffffc02019ba <slob_free+0x4a>
		cur->units += b->units;
ffffffffc02019f2:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc02019f4:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc02019f6:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc02019f8:	9ebd                	addw	a3,a3,a5
ffffffffc02019fa:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc02019fc:	e70c                	sd	a1,8(a4)
ffffffffc02019fe:	d169                	beqz	a0,ffffffffc02019c0 <slob_free+0x50>
}
ffffffffc0201a00:	6402                	ld	s0,0(sp)
ffffffffc0201a02:	60a2                	ld	ra,8(sp)
ffffffffc0201a04:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201a06:	fa3fe06f          	j	ffffffffc02009a8 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201a0a:	25bd                	addiw	a1,a1,15
ffffffffc0201a0c:	8191                	srli	a1,a1,0x4
ffffffffc0201a0e:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a10:	100027f3          	csrr	a5,sstatus
ffffffffc0201a14:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a16:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a18:	d7bd                	beqz	a5,ffffffffc0201986 <slob_free+0x16>
        intr_disable();
ffffffffc0201a1a:	f95fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201a1e:	4505                	li	a0,1
ffffffffc0201a20:	b79d                	j	ffffffffc0201986 <slob_free+0x16>
ffffffffc0201a22:	8082                	ret

ffffffffc0201a24 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a24:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a26:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a28:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a2c:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a2e:	352000ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
	if (!page)
ffffffffc0201a32:	c91d                	beqz	a0,ffffffffc0201a68 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a34:	000c5697          	auipc	a3,0xc5
ffffffffc0201a38:	1fc6b683          	ld	a3,508(a3) # ffffffffc02c6c30 <pages>
ffffffffc0201a3c:	8d15                	sub	a0,a0,a3
ffffffffc0201a3e:	8519                	srai	a0,a0,0x6
ffffffffc0201a40:	00006697          	auipc	a3,0x6
ffffffffc0201a44:	7006b683          	ld	a3,1792(a3) # ffffffffc0208140 <nbase>
ffffffffc0201a48:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201a4a:	00c51793          	slli	a5,a0,0xc
ffffffffc0201a4e:	83b1                	srli	a5,a5,0xc
ffffffffc0201a50:	000c5717          	auipc	a4,0xc5
ffffffffc0201a54:	1d873703          	ld	a4,472(a4) # ffffffffc02c6c28 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201a58:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201a5a:	00e7fa63          	bgeu	a5,a4,ffffffffc0201a6e <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201a5e:	000c5697          	auipc	a3,0xc5
ffffffffc0201a62:	1e26b683          	ld	a3,482(a3) # ffffffffc02c6c40 <va_pa_offset>
ffffffffc0201a66:	9536                	add	a0,a0,a3
}
ffffffffc0201a68:	60a2                	ld	ra,8(sp)
ffffffffc0201a6a:	0141                	addi	sp,sp,16
ffffffffc0201a6c:	8082                	ret
ffffffffc0201a6e:	86aa                	mv	a3,a0
ffffffffc0201a70:	00005617          	auipc	a2,0x5
ffffffffc0201a74:	c3860613          	addi	a2,a2,-968 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0201a78:	07100593          	li	a1,113
ffffffffc0201a7c:	00005517          	auipc	a0,0x5
ffffffffc0201a80:	c5450513          	addi	a0,a0,-940 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0201a84:	a0ffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201a88 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201a88:	1101                	addi	sp,sp,-32
ffffffffc0201a8a:	ec06                	sd	ra,24(sp)
ffffffffc0201a8c:	e822                	sd	s0,16(sp)
ffffffffc0201a8e:	e426                	sd	s1,8(sp)
ffffffffc0201a90:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a92:	01050713          	addi	a4,a0,16
ffffffffc0201a96:	6785                	lui	a5,0x1
ffffffffc0201a98:	0cf77363          	bgeu	a4,a5,ffffffffc0201b5e <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201a9c:	00f50493          	addi	s1,a0,15
ffffffffc0201aa0:	8091                	srli	s1,s1,0x4
ffffffffc0201aa2:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aa4:	10002673          	csrr	a2,sstatus
ffffffffc0201aa8:	8a09                	andi	a2,a2,2
ffffffffc0201aaa:	e25d                	bnez	a2,ffffffffc0201b50 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201aac:	000c1917          	auipc	s2,0xc1
ffffffffc0201ab0:	cdc90913          	addi	s2,s2,-804 # ffffffffc02c2788 <slobfree>
ffffffffc0201ab4:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ab8:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201aba:	4398                	lw	a4,0(a5)
ffffffffc0201abc:	08975e63          	bge	a4,s1,ffffffffc0201b58 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201ac0:	00f68b63          	beq	a3,a5,ffffffffc0201ad6 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ac4:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201ac6:	4018                	lw	a4,0(s0)
ffffffffc0201ac8:	02975a63          	bge	a4,s1,ffffffffc0201afc <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201acc:	00093683          	ld	a3,0(s2)
ffffffffc0201ad0:	87a2                	mv	a5,s0
ffffffffc0201ad2:	fef699e3          	bne	a3,a5,ffffffffc0201ac4 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201ad6:	ee31                	bnez	a2,ffffffffc0201b32 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201ad8:	4501                	li	a0,0
ffffffffc0201ada:	f4bff0ef          	jal	ra,ffffffffc0201a24 <__slob_get_free_pages.constprop.0>
ffffffffc0201ade:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201ae0:	cd05                	beqz	a0,ffffffffc0201b18 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201ae2:	6585                	lui	a1,0x1
ffffffffc0201ae4:	e8dff0ef          	jal	ra,ffffffffc0201970 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ae8:	10002673          	csrr	a2,sstatus
ffffffffc0201aec:	8a09                	andi	a2,a2,2
ffffffffc0201aee:	ee05                	bnez	a2,ffffffffc0201b26 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201af0:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201af4:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201af6:	4018                	lw	a4,0(s0)
ffffffffc0201af8:	fc974ae3          	blt	a4,s1,ffffffffc0201acc <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201afc:	04e48763          	beq	s1,a4,ffffffffc0201b4a <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201b00:	00449693          	slli	a3,s1,0x4
ffffffffc0201b04:	96a2                	add	a3,a3,s0
ffffffffc0201b06:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201b08:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201b0a:	9f05                	subw	a4,a4,s1
ffffffffc0201b0c:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201b0e:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201b10:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201b12:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201b16:	e20d                	bnez	a2,ffffffffc0201b38 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201b18:	60e2                	ld	ra,24(sp)
ffffffffc0201b1a:	8522                	mv	a0,s0
ffffffffc0201b1c:	6442                	ld	s0,16(sp)
ffffffffc0201b1e:	64a2                	ld	s1,8(sp)
ffffffffc0201b20:	6902                	ld	s2,0(sp)
ffffffffc0201b22:	6105                	addi	sp,sp,32
ffffffffc0201b24:	8082                	ret
        intr_disable();
ffffffffc0201b26:	e89fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
			cur = slobfree;
ffffffffc0201b2a:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201b2e:	4605                	li	a2,1
ffffffffc0201b30:	b7d1                	j	ffffffffc0201af4 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201b32:	e77fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201b36:	b74d                	j	ffffffffc0201ad8 <slob_alloc.constprop.0+0x50>
ffffffffc0201b38:	e71fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc0201b3c:	60e2                	ld	ra,24(sp)
ffffffffc0201b3e:	8522                	mv	a0,s0
ffffffffc0201b40:	6442                	ld	s0,16(sp)
ffffffffc0201b42:	64a2                	ld	s1,8(sp)
ffffffffc0201b44:	6902                	ld	s2,0(sp)
ffffffffc0201b46:	6105                	addi	sp,sp,32
ffffffffc0201b48:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201b4a:	6418                	ld	a4,8(s0)
ffffffffc0201b4c:	e798                	sd	a4,8(a5)
ffffffffc0201b4e:	b7d1                	j	ffffffffc0201b12 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201b50:	e5ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201b54:	4605                	li	a2,1
ffffffffc0201b56:	bf99                	j	ffffffffc0201aac <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201b58:	843e                	mv	s0,a5
ffffffffc0201b5a:	87b6                	mv	a5,a3
ffffffffc0201b5c:	b745                	j	ffffffffc0201afc <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b5e:	00005697          	auipc	a3,0x5
ffffffffc0201b62:	b8268693          	addi	a3,a3,-1150 # ffffffffc02066e0 <default_pmm_manager+0x70>
ffffffffc0201b66:	00004617          	auipc	a2,0x4
ffffffffc0201b6a:	75a60613          	addi	a2,a2,1882 # ffffffffc02062c0 <commands+0x818>
ffffffffc0201b6e:	06300593          	li	a1,99
ffffffffc0201b72:	00005517          	auipc	a0,0x5
ffffffffc0201b76:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0206700 <default_pmm_manager+0x90>
ffffffffc0201b7a:	919fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201b7e <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201b7e:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201b80:	00005517          	auipc	a0,0x5
ffffffffc0201b84:	b9850513          	addi	a0,a0,-1128 # ffffffffc0206718 <default_pmm_manager+0xa8>
{
ffffffffc0201b88:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201b8a:	e0efe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201b8e:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b90:	00005517          	auipc	a0,0x5
ffffffffc0201b94:	ba050513          	addi	a0,a0,-1120 # ffffffffc0206730 <default_pmm_manager+0xc0>
}
ffffffffc0201b98:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b9a:	dfefe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201b9e <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201b9e:	4501                	li	a0,0
ffffffffc0201ba0:	8082                	ret

ffffffffc0201ba2 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ba2:	1101                	addi	sp,sp,-32
ffffffffc0201ba4:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ba6:	6905                	lui	s2,0x1
{
ffffffffc0201ba8:	e822                	sd	s0,16(sp)
ffffffffc0201baa:	ec06                	sd	ra,24(sp)
ffffffffc0201bac:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bae:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f51>
{
ffffffffc0201bb2:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bb4:	04a7f963          	bgeu	a5,a0,ffffffffc0201c06 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201bb8:	4561                	li	a0,24
ffffffffc0201bba:	ecfff0ef          	jal	ra,ffffffffc0201a88 <slob_alloc.constprop.0>
ffffffffc0201bbe:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201bc0:	c929                	beqz	a0,ffffffffc0201c12 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201bc2:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201bc6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201bc8:	00f95763          	bge	s2,a5,ffffffffc0201bd6 <kmalloc+0x34>
ffffffffc0201bcc:	6705                	lui	a4,0x1
ffffffffc0201bce:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201bd0:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201bd2:	fef74ee3          	blt	a4,a5,ffffffffc0201bce <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201bd6:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201bd8:	e4dff0ef          	jal	ra,ffffffffc0201a24 <__slob_get_free_pages.constprop.0>
ffffffffc0201bdc:	e488                	sd	a0,8(s1)
ffffffffc0201bde:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201be0:	c525                	beqz	a0,ffffffffc0201c48 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201be2:	100027f3          	csrr	a5,sstatus
ffffffffc0201be6:	8b89                	andi	a5,a5,2
ffffffffc0201be8:	ef8d                	bnez	a5,ffffffffc0201c22 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201bea:	000c5797          	auipc	a5,0xc5
ffffffffc0201bee:	02678793          	addi	a5,a5,38 # ffffffffc02c6c10 <bigblocks>
ffffffffc0201bf2:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201bf4:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201bf6:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201bf8:	60e2                	ld	ra,24(sp)
ffffffffc0201bfa:	8522                	mv	a0,s0
ffffffffc0201bfc:	6442                	ld	s0,16(sp)
ffffffffc0201bfe:	64a2                	ld	s1,8(sp)
ffffffffc0201c00:	6902                	ld	s2,0(sp)
ffffffffc0201c02:	6105                	addi	sp,sp,32
ffffffffc0201c04:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c06:	0541                	addi	a0,a0,16
ffffffffc0201c08:	e81ff0ef          	jal	ra,ffffffffc0201a88 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c0c:	01050413          	addi	s0,a0,16
ffffffffc0201c10:	f565                	bnez	a0,ffffffffc0201bf8 <kmalloc+0x56>
ffffffffc0201c12:	4401                	li	s0,0
}
ffffffffc0201c14:	60e2                	ld	ra,24(sp)
ffffffffc0201c16:	8522                	mv	a0,s0
ffffffffc0201c18:	6442                	ld	s0,16(sp)
ffffffffc0201c1a:	64a2                	ld	s1,8(sp)
ffffffffc0201c1c:	6902                	ld	s2,0(sp)
ffffffffc0201c1e:	6105                	addi	sp,sp,32
ffffffffc0201c20:	8082                	ret
        intr_disable();
ffffffffc0201c22:	d8dfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c26:	000c5797          	auipc	a5,0xc5
ffffffffc0201c2a:	fea78793          	addi	a5,a5,-22 # ffffffffc02c6c10 <bigblocks>
ffffffffc0201c2e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c30:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c32:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201c34:	d75fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
		return bb->pages;
ffffffffc0201c38:	6480                	ld	s0,8(s1)
}
ffffffffc0201c3a:	60e2                	ld	ra,24(sp)
ffffffffc0201c3c:	64a2                	ld	s1,8(sp)
ffffffffc0201c3e:	8522                	mv	a0,s0
ffffffffc0201c40:	6442                	ld	s0,16(sp)
ffffffffc0201c42:	6902                	ld	s2,0(sp)
ffffffffc0201c44:	6105                	addi	sp,sp,32
ffffffffc0201c46:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c48:	45e1                	li	a1,24
ffffffffc0201c4a:	8526                	mv	a0,s1
ffffffffc0201c4c:	d25ff0ef          	jal	ra,ffffffffc0201970 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201c50:	b765                	j	ffffffffc0201bf8 <kmalloc+0x56>

ffffffffc0201c52 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c52:	c169                	beqz	a0,ffffffffc0201d14 <kfree+0xc2>
{
ffffffffc0201c54:	1101                	addi	sp,sp,-32
ffffffffc0201c56:	e822                	sd	s0,16(sp)
ffffffffc0201c58:	ec06                	sd	ra,24(sp)
ffffffffc0201c5a:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201c5c:	03451793          	slli	a5,a0,0x34
ffffffffc0201c60:	842a                	mv	s0,a0
ffffffffc0201c62:	e3d9                	bnez	a5,ffffffffc0201ce8 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c64:	100027f3          	csrr	a5,sstatus
ffffffffc0201c68:	8b89                	andi	a5,a5,2
ffffffffc0201c6a:	e7d9                	bnez	a5,ffffffffc0201cf8 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c6c:	000c5797          	auipc	a5,0xc5
ffffffffc0201c70:	fa47b783          	ld	a5,-92(a5) # ffffffffc02c6c10 <bigblocks>
    return 0;
ffffffffc0201c74:	4601                	li	a2,0
ffffffffc0201c76:	cbad                	beqz	a5,ffffffffc0201ce8 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201c78:	000c5697          	auipc	a3,0xc5
ffffffffc0201c7c:	f9868693          	addi	a3,a3,-104 # ffffffffc02c6c10 <bigblocks>
ffffffffc0201c80:	a021                	j	ffffffffc0201c88 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c82:	01048693          	addi	a3,s1,16
ffffffffc0201c86:	c3a5                	beqz	a5,ffffffffc0201ce6 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201c88:	6798                	ld	a4,8(a5)
ffffffffc0201c8a:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201c8c:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201c8e:	fe871ae3          	bne	a4,s0,ffffffffc0201c82 <kfree+0x30>
				*last = bb->next;
ffffffffc0201c92:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201c94:	ee2d                	bnez	a2,ffffffffc0201d0e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201c96:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201c9a:	4098                	lw	a4,0(s1)
ffffffffc0201c9c:	08f46963          	bltu	s0,a5,ffffffffc0201d2e <kfree+0xdc>
ffffffffc0201ca0:	000c5697          	auipc	a3,0xc5
ffffffffc0201ca4:	fa06b683          	ld	a3,-96(a3) # ffffffffc02c6c40 <va_pa_offset>
ffffffffc0201ca8:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201caa:	8031                	srli	s0,s0,0xc
ffffffffc0201cac:	000c5797          	auipc	a5,0xc5
ffffffffc0201cb0:	f7c7b783          	ld	a5,-132(a5) # ffffffffc02c6c28 <npage>
ffffffffc0201cb4:	06f47163          	bgeu	s0,a5,ffffffffc0201d16 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201cb8:	00006517          	auipc	a0,0x6
ffffffffc0201cbc:	48853503          	ld	a0,1160(a0) # ffffffffc0208140 <nbase>
ffffffffc0201cc0:	8c09                	sub	s0,s0,a0
ffffffffc0201cc2:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201cc4:	000c5517          	auipc	a0,0xc5
ffffffffc0201cc8:	f6c53503          	ld	a0,-148(a0) # ffffffffc02c6c30 <pages>
ffffffffc0201ccc:	4585                	li	a1,1
ffffffffc0201cce:	9522                	add	a0,a0,s0
ffffffffc0201cd0:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201cd4:	0ea000ef          	jal	ra,ffffffffc0201dbe <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201cd8:	6442                	ld	s0,16(sp)
ffffffffc0201cda:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201cdc:	8526                	mv	a0,s1
}
ffffffffc0201cde:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ce0:	45e1                	li	a1,24
}
ffffffffc0201ce2:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ce4:	b171                	j	ffffffffc0201970 <slob_free>
ffffffffc0201ce6:	e20d                	bnez	a2,ffffffffc0201d08 <kfree+0xb6>
ffffffffc0201ce8:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201cec:	6442                	ld	s0,16(sp)
ffffffffc0201cee:	60e2                	ld	ra,24(sp)
ffffffffc0201cf0:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cf2:	4581                	li	a1,0
}
ffffffffc0201cf4:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cf6:	b9ad                	j	ffffffffc0201970 <slob_free>
        intr_disable();
ffffffffc0201cf8:	cb7fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cfc:	000c5797          	auipc	a5,0xc5
ffffffffc0201d00:	f147b783          	ld	a5,-236(a5) # ffffffffc02c6c10 <bigblocks>
        return 1;
ffffffffc0201d04:	4605                	li	a2,1
ffffffffc0201d06:	fbad                	bnez	a5,ffffffffc0201c78 <kfree+0x26>
        intr_enable();
ffffffffc0201d08:	ca1fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d0c:	bff1                	j	ffffffffc0201ce8 <kfree+0x96>
ffffffffc0201d0e:	c9bfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d12:	b751                	j	ffffffffc0201c96 <kfree+0x44>
ffffffffc0201d14:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d16:	00005617          	auipc	a2,0x5
ffffffffc0201d1a:	a6260613          	addi	a2,a2,-1438 # ffffffffc0206778 <default_pmm_manager+0x108>
ffffffffc0201d1e:	06900593          	li	a1,105
ffffffffc0201d22:	00005517          	auipc	a0,0x5
ffffffffc0201d26:	9ae50513          	addi	a0,a0,-1618 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0201d2a:	f68fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d2e:	86a2                	mv	a3,s0
ffffffffc0201d30:	00005617          	auipc	a2,0x5
ffffffffc0201d34:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc0201d38:	07700593          	li	a1,119
ffffffffc0201d3c:	00005517          	auipc	a0,0x5
ffffffffc0201d40:	99450513          	addi	a0,a0,-1644 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0201d44:	f4efe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d48 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d48:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201d4a:	00005617          	auipc	a2,0x5
ffffffffc0201d4e:	a2e60613          	addi	a2,a2,-1490 # ffffffffc0206778 <default_pmm_manager+0x108>
ffffffffc0201d52:	06900593          	li	a1,105
ffffffffc0201d56:	00005517          	auipc	a0,0x5
ffffffffc0201d5a:	97a50513          	addi	a0,a0,-1670 # ffffffffc02066d0 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201d5e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201d60:	f32fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d64 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201d64:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201d66:	00005617          	auipc	a2,0x5
ffffffffc0201d6a:	a3260613          	addi	a2,a2,-1486 # ffffffffc0206798 <default_pmm_manager+0x128>
ffffffffc0201d6e:	07f00593          	li	a1,127
ffffffffc0201d72:	00005517          	auipc	a0,0x5
ffffffffc0201d76:	95e50513          	addi	a0,a0,-1698 # ffffffffc02066d0 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201d7a:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201d7c:	f16fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d80 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d80:	100027f3          	csrr	a5,sstatus
ffffffffc0201d84:	8b89                	andi	a5,a5,2
ffffffffc0201d86:	e799                	bnez	a5,ffffffffc0201d94 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d88:	000c5797          	auipc	a5,0xc5
ffffffffc0201d8c:	eb07b783          	ld	a5,-336(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201d90:	6f9c                	ld	a5,24(a5)
ffffffffc0201d92:	8782                	jr	a5
{
ffffffffc0201d94:	1141                	addi	sp,sp,-16
ffffffffc0201d96:	e406                	sd	ra,8(sp)
ffffffffc0201d98:	e022                	sd	s0,0(sp)
ffffffffc0201d9a:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201d9c:	c13fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201da0:	000c5797          	auipc	a5,0xc5
ffffffffc0201da4:	e987b783          	ld	a5,-360(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201da8:	6f9c                	ld	a5,24(a5)
ffffffffc0201daa:	8522                	mv	a0,s0
ffffffffc0201dac:	9782                	jalr	a5
ffffffffc0201dae:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201db0:	bf9fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201db4:	60a2                	ld	ra,8(sp)
ffffffffc0201db6:	8522                	mv	a0,s0
ffffffffc0201db8:	6402                	ld	s0,0(sp)
ffffffffc0201dba:	0141                	addi	sp,sp,16
ffffffffc0201dbc:	8082                	ret

ffffffffc0201dbe <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dbe:	100027f3          	csrr	a5,sstatus
ffffffffc0201dc2:	8b89                	andi	a5,a5,2
ffffffffc0201dc4:	e799                	bnez	a5,ffffffffc0201dd2 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201dc6:	000c5797          	auipc	a5,0xc5
ffffffffc0201dca:	e727b783          	ld	a5,-398(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201dce:	739c                	ld	a5,32(a5)
ffffffffc0201dd0:	8782                	jr	a5
{
ffffffffc0201dd2:	1101                	addi	sp,sp,-32
ffffffffc0201dd4:	ec06                	sd	ra,24(sp)
ffffffffc0201dd6:	e822                	sd	s0,16(sp)
ffffffffc0201dd8:	e426                	sd	s1,8(sp)
ffffffffc0201dda:	842a                	mv	s0,a0
ffffffffc0201ddc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201dde:	bd1fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201de2:	000c5797          	auipc	a5,0xc5
ffffffffc0201de6:	e567b783          	ld	a5,-426(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201dea:	739c                	ld	a5,32(a5)
ffffffffc0201dec:	85a6                	mv	a1,s1
ffffffffc0201dee:	8522                	mv	a0,s0
ffffffffc0201df0:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201df2:	6442                	ld	s0,16(sp)
ffffffffc0201df4:	60e2                	ld	ra,24(sp)
ffffffffc0201df6:	64a2                	ld	s1,8(sp)
ffffffffc0201df8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201dfa:	baffe06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0201dfe <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dfe:	100027f3          	csrr	a5,sstatus
ffffffffc0201e02:	8b89                	andi	a5,a5,2
ffffffffc0201e04:	e799                	bnez	a5,ffffffffc0201e12 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e06:	000c5797          	auipc	a5,0xc5
ffffffffc0201e0a:	e327b783          	ld	a5,-462(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201e0e:	779c                	ld	a5,40(a5)
ffffffffc0201e10:	8782                	jr	a5
{
ffffffffc0201e12:	1141                	addi	sp,sp,-16
ffffffffc0201e14:	e406                	sd	ra,8(sp)
ffffffffc0201e16:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201e18:	b97fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e1c:	000c5797          	auipc	a5,0xc5
ffffffffc0201e20:	e1c7b783          	ld	a5,-484(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201e24:	779c                	ld	a5,40(a5)
ffffffffc0201e26:	9782                	jalr	a5
ffffffffc0201e28:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e2a:	b7ffe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e2e:	60a2                	ld	ra,8(sp)
ffffffffc0201e30:	8522                	mv	a0,s0
ffffffffc0201e32:	6402                	ld	s0,0(sp)
ffffffffc0201e34:	0141                	addi	sp,sp,16
ffffffffc0201e36:	8082                	ret

ffffffffc0201e38 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e38:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e3c:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201e40:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e42:	078e                	slli	a5,a5,0x3
{
ffffffffc0201e44:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e46:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e4a:	6094                	ld	a3,0(s1)
{
ffffffffc0201e4c:	f04a                	sd	s2,32(sp)
ffffffffc0201e4e:	ec4e                	sd	s3,24(sp)
ffffffffc0201e50:	e852                	sd	s4,16(sp)
ffffffffc0201e52:	fc06                	sd	ra,56(sp)
ffffffffc0201e54:	f822                	sd	s0,48(sp)
ffffffffc0201e56:	e456                	sd	s5,8(sp)
ffffffffc0201e58:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e5a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e5e:	892e                	mv	s2,a1
ffffffffc0201e60:	8a32                	mv	s4,a2
ffffffffc0201e62:	000c5997          	auipc	s3,0xc5
ffffffffc0201e66:	dc698993          	addi	s3,s3,-570 # ffffffffc02c6c28 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e6a:	efbd                	bnez	a5,ffffffffc0201ee8 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e6c:	14060c63          	beqz	a2,ffffffffc0201fc4 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e70:	100027f3          	csrr	a5,sstatus
ffffffffc0201e74:	8b89                	andi	a5,a5,2
ffffffffc0201e76:	14079963          	bnez	a5,ffffffffc0201fc8 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e7a:	000c5797          	auipc	a5,0xc5
ffffffffc0201e7e:	dbe7b783          	ld	a5,-578(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201e82:	6f9c                	ld	a5,24(a5)
ffffffffc0201e84:	4505                	li	a0,1
ffffffffc0201e86:	9782                	jalr	a5
ffffffffc0201e88:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e8a:	12040d63          	beqz	s0,ffffffffc0201fc4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e8e:	000c5b17          	auipc	s6,0xc5
ffffffffc0201e92:	da2b0b13          	addi	s6,s6,-606 # ffffffffc02c6c30 <pages>
ffffffffc0201e96:	000b3503          	ld	a0,0(s6)
ffffffffc0201e9a:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e9e:	000c5997          	auipc	s3,0xc5
ffffffffc0201ea2:	d8a98993          	addi	s3,s3,-630 # ffffffffc02c6c28 <npage>
ffffffffc0201ea6:	40a40533          	sub	a0,s0,a0
ffffffffc0201eaa:	8519                	srai	a0,a0,0x6
ffffffffc0201eac:	9556                	add	a0,a0,s5
ffffffffc0201eae:	0009b703          	ld	a4,0(s3)
ffffffffc0201eb2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201eb6:	4685                	li	a3,1
ffffffffc0201eb8:	c014                	sw	a3,0(s0)
ffffffffc0201eba:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ebc:	0532                	slli	a0,a0,0xc
ffffffffc0201ebe:	16e7f763          	bgeu	a5,a4,ffffffffc020202c <get_pte+0x1f4>
ffffffffc0201ec2:	000c5797          	auipc	a5,0xc5
ffffffffc0201ec6:	d7e7b783          	ld	a5,-642(a5) # ffffffffc02c6c40 <va_pa_offset>
ffffffffc0201eca:	6605                	lui	a2,0x1
ffffffffc0201ecc:	4581                	li	a1,0
ffffffffc0201ece:	953e                	add	a0,a0,a5
ffffffffc0201ed0:	145030ef          	jal	ra,ffffffffc0205814 <memset>
    return page - pages + nbase;
ffffffffc0201ed4:	000b3683          	ld	a3,0(s6)
ffffffffc0201ed8:	40d406b3          	sub	a3,s0,a3
ffffffffc0201edc:	8699                	srai	a3,a3,0x6
ffffffffc0201ede:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ee0:	06aa                	slli	a3,a3,0xa
ffffffffc0201ee2:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ee6:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ee8:	77fd                	lui	a5,0xfffff
ffffffffc0201eea:	068a                	slli	a3,a3,0x2
ffffffffc0201eec:	0009b703          	ld	a4,0(s3)
ffffffffc0201ef0:	8efd                	and	a3,a3,a5
ffffffffc0201ef2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201ef6:	10e7ff63          	bgeu	a5,a4,ffffffffc0202014 <get_pte+0x1dc>
ffffffffc0201efa:	000c5a97          	auipc	s5,0xc5
ffffffffc0201efe:	d46a8a93          	addi	s5,s5,-698 # ffffffffc02c6c40 <va_pa_offset>
ffffffffc0201f02:	000ab403          	ld	s0,0(s5)
ffffffffc0201f06:	01595793          	srli	a5,s2,0x15
ffffffffc0201f0a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f0e:	96a2                	add	a3,a3,s0
ffffffffc0201f10:	00379413          	slli	s0,a5,0x3
ffffffffc0201f14:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f16:	6014                	ld	a3,0(s0)
ffffffffc0201f18:	0016f793          	andi	a5,a3,1
ffffffffc0201f1c:	ebad                	bnez	a5,ffffffffc0201f8e <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f1e:	0a0a0363          	beqz	s4,ffffffffc0201fc4 <get_pte+0x18c>
ffffffffc0201f22:	100027f3          	csrr	a5,sstatus
ffffffffc0201f26:	8b89                	andi	a5,a5,2
ffffffffc0201f28:	efcd                	bnez	a5,ffffffffc0201fe2 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f2a:	000c5797          	auipc	a5,0xc5
ffffffffc0201f2e:	d0e7b783          	ld	a5,-754(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201f32:	6f9c                	ld	a5,24(a5)
ffffffffc0201f34:	4505                	li	a0,1
ffffffffc0201f36:	9782                	jalr	a5
ffffffffc0201f38:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f3a:	c4c9                	beqz	s1,ffffffffc0201fc4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f3c:	000c5b17          	auipc	s6,0xc5
ffffffffc0201f40:	cf4b0b13          	addi	s6,s6,-780 # ffffffffc02c6c30 <pages>
ffffffffc0201f44:	000b3503          	ld	a0,0(s6)
ffffffffc0201f48:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f4c:	0009b703          	ld	a4,0(s3)
ffffffffc0201f50:	40a48533          	sub	a0,s1,a0
ffffffffc0201f54:	8519                	srai	a0,a0,0x6
ffffffffc0201f56:	9552                	add	a0,a0,s4
ffffffffc0201f58:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f5c:	4685                	li	a3,1
ffffffffc0201f5e:	c094                	sw	a3,0(s1)
ffffffffc0201f60:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f62:	0532                	slli	a0,a0,0xc
ffffffffc0201f64:	0ee7f163          	bgeu	a5,a4,ffffffffc0202046 <get_pte+0x20e>
ffffffffc0201f68:	000ab783          	ld	a5,0(s5)
ffffffffc0201f6c:	6605                	lui	a2,0x1
ffffffffc0201f6e:	4581                	li	a1,0
ffffffffc0201f70:	953e                	add	a0,a0,a5
ffffffffc0201f72:	0a3030ef          	jal	ra,ffffffffc0205814 <memset>
    return page - pages + nbase;
ffffffffc0201f76:	000b3683          	ld	a3,0(s6)
ffffffffc0201f7a:	40d486b3          	sub	a3,s1,a3
ffffffffc0201f7e:	8699                	srai	a3,a3,0x6
ffffffffc0201f80:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f82:	06aa                	slli	a3,a3,0xa
ffffffffc0201f84:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f88:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f8a:	0009b703          	ld	a4,0(s3)
ffffffffc0201f8e:	068a                	slli	a3,a3,0x2
ffffffffc0201f90:	757d                	lui	a0,0xfffff
ffffffffc0201f92:	8ee9                	and	a3,a3,a0
ffffffffc0201f94:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f98:	06e7f263          	bgeu	a5,a4,ffffffffc0201ffc <get_pte+0x1c4>
ffffffffc0201f9c:	000ab503          	ld	a0,0(s5)
ffffffffc0201fa0:	00c95913          	srli	s2,s2,0xc
ffffffffc0201fa4:	1ff97913          	andi	s2,s2,511
ffffffffc0201fa8:	96aa                	add	a3,a3,a0
ffffffffc0201faa:	00391513          	slli	a0,s2,0x3
ffffffffc0201fae:	9536                	add	a0,a0,a3
}
ffffffffc0201fb0:	70e2                	ld	ra,56(sp)
ffffffffc0201fb2:	7442                	ld	s0,48(sp)
ffffffffc0201fb4:	74a2                	ld	s1,40(sp)
ffffffffc0201fb6:	7902                	ld	s2,32(sp)
ffffffffc0201fb8:	69e2                	ld	s3,24(sp)
ffffffffc0201fba:	6a42                	ld	s4,16(sp)
ffffffffc0201fbc:	6aa2                	ld	s5,8(sp)
ffffffffc0201fbe:	6b02                	ld	s6,0(sp)
ffffffffc0201fc0:	6121                	addi	sp,sp,64
ffffffffc0201fc2:	8082                	ret
            return NULL;
ffffffffc0201fc4:	4501                	li	a0,0
ffffffffc0201fc6:	b7ed                	j	ffffffffc0201fb0 <get_pte+0x178>
        intr_disable();
ffffffffc0201fc8:	9e7fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fcc:	000c5797          	auipc	a5,0xc5
ffffffffc0201fd0:	c6c7b783          	ld	a5,-916(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201fd4:	6f9c                	ld	a5,24(a5)
ffffffffc0201fd6:	4505                	li	a0,1
ffffffffc0201fd8:	9782                	jalr	a5
ffffffffc0201fda:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fdc:	9cdfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201fe0:	b56d                	j	ffffffffc0201e8a <get_pte+0x52>
        intr_disable();
ffffffffc0201fe2:	9cdfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0201fe6:	000c5797          	auipc	a5,0xc5
ffffffffc0201fea:	c527b783          	ld	a5,-942(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0201fee:	6f9c                	ld	a5,24(a5)
ffffffffc0201ff0:	4505                	li	a0,1
ffffffffc0201ff2:	9782                	jalr	a5
ffffffffc0201ff4:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201ff6:	9b3fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201ffa:	b781                	j	ffffffffc0201f3a <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ffc:	00004617          	auipc	a2,0x4
ffffffffc0202000:	6ac60613          	addi	a2,a2,1708 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0202004:	0fa00593          	li	a1,250
ffffffffc0202008:	00004517          	auipc	a0,0x4
ffffffffc020200c:	7b850513          	addi	a0,a0,1976 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202010:	c82fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202014:	00004617          	auipc	a2,0x4
ffffffffc0202018:	69460613          	addi	a2,a2,1684 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc020201c:	0ed00593          	li	a1,237
ffffffffc0202020:	00004517          	auipc	a0,0x4
ffffffffc0202024:	7a050513          	addi	a0,a0,1952 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202028:	c6afe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020202c:	86aa                	mv	a3,a0
ffffffffc020202e:	00004617          	auipc	a2,0x4
ffffffffc0202032:	67a60613          	addi	a2,a2,1658 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0202036:	0e900593          	li	a1,233
ffffffffc020203a:	00004517          	auipc	a0,0x4
ffffffffc020203e:	78650513          	addi	a0,a0,1926 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202042:	c50fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202046:	86aa                	mv	a3,a0
ffffffffc0202048:	00004617          	auipc	a2,0x4
ffffffffc020204c:	66060613          	addi	a2,a2,1632 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0202050:	0f700593          	li	a1,247
ffffffffc0202054:	00004517          	auipc	a0,0x4
ffffffffc0202058:	76c50513          	addi	a0,a0,1900 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020205c:	c36fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202060 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202060:	1141                	addi	sp,sp,-16
ffffffffc0202062:	e022                	sd	s0,0(sp)
ffffffffc0202064:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202066:	4601                	li	a2,0
{
ffffffffc0202068:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020206a:	dcfff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
    if (ptep_store != NULL)
ffffffffc020206e:	c011                	beqz	s0,ffffffffc0202072 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202070:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202072:	c511                	beqz	a0,ffffffffc020207e <get_page+0x1e>
ffffffffc0202074:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202076:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202078:	0017f713          	andi	a4,a5,1
ffffffffc020207c:	e709                	bnez	a4,ffffffffc0202086 <get_page+0x26>
}
ffffffffc020207e:	60a2                	ld	ra,8(sp)
ffffffffc0202080:	6402                	ld	s0,0(sp)
ffffffffc0202082:	0141                	addi	sp,sp,16
ffffffffc0202084:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202086:	078a                	slli	a5,a5,0x2
ffffffffc0202088:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020208a:	000c5717          	auipc	a4,0xc5
ffffffffc020208e:	b9e73703          	ld	a4,-1122(a4) # ffffffffc02c6c28 <npage>
ffffffffc0202092:	00e7ff63          	bgeu	a5,a4,ffffffffc02020b0 <get_page+0x50>
ffffffffc0202096:	60a2                	ld	ra,8(sp)
ffffffffc0202098:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020209a:	fff80537          	lui	a0,0xfff80
ffffffffc020209e:	97aa                	add	a5,a5,a0
ffffffffc02020a0:	079a                	slli	a5,a5,0x6
ffffffffc02020a2:	000c5517          	auipc	a0,0xc5
ffffffffc02020a6:	b8e53503          	ld	a0,-1138(a0) # ffffffffc02c6c30 <pages>
ffffffffc02020aa:	953e                	add	a0,a0,a5
ffffffffc02020ac:	0141                	addi	sp,sp,16
ffffffffc02020ae:	8082                	ret
ffffffffc02020b0:	c99ff0ef          	jal	ra,ffffffffc0201d48 <pa2page.part.0>

ffffffffc02020b4 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02020b4:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020b6:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02020ba:	f486                	sd	ra,104(sp)
ffffffffc02020bc:	f0a2                	sd	s0,96(sp)
ffffffffc02020be:	eca6                	sd	s1,88(sp)
ffffffffc02020c0:	e8ca                	sd	s2,80(sp)
ffffffffc02020c2:	e4ce                	sd	s3,72(sp)
ffffffffc02020c4:	e0d2                	sd	s4,64(sp)
ffffffffc02020c6:	fc56                	sd	s5,56(sp)
ffffffffc02020c8:	f85a                	sd	s6,48(sp)
ffffffffc02020ca:	f45e                	sd	s7,40(sp)
ffffffffc02020cc:	f062                	sd	s8,32(sp)
ffffffffc02020ce:	ec66                	sd	s9,24(sp)
ffffffffc02020d0:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020d2:	17d2                	slli	a5,a5,0x34
ffffffffc02020d4:	e3ed                	bnez	a5,ffffffffc02021b6 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02020d6:	002007b7          	lui	a5,0x200
ffffffffc02020da:	842e                	mv	s0,a1
ffffffffc02020dc:	0ef5ed63          	bltu	a1,a5,ffffffffc02021d6 <unmap_range+0x122>
ffffffffc02020e0:	8932                	mv	s2,a2
ffffffffc02020e2:	0ec5fa63          	bgeu	a1,a2,ffffffffc02021d6 <unmap_range+0x122>
ffffffffc02020e6:	4785                	li	a5,1
ffffffffc02020e8:	07fe                	slli	a5,a5,0x1f
ffffffffc02020ea:	0ec7e663          	bltu	a5,a2,ffffffffc02021d6 <unmap_range+0x122>
ffffffffc02020ee:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02020f0:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02020f2:	000c5c97          	auipc	s9,0xc5
ffffffffc02020f6:	b36c8c93          	addi	s9,s9,-1226 # ffffffffc02c6c28 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02020fa:	000c5c17          	auipc	s8,0xc5
ffffffffc02020fe:	b36c0c13          	addi	s8,s8,-1226 # ffffffffc02c6c30 <pages>
ffffffffc0202102:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202106:	000c5d17          	auipc	s10,0xc5
ffffffffc020210a:	b32d0d13          	addi	s10,s10,-1230 # ffffffffc02c6c38 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020210e:	00200b37          	lui	s6,0x200
ffffffffc0202112:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202116:	4601                	li	a2,0
ffffffffc0202118:	85a2                	mv	a1,s0
ffffffffc020211a:	854e                	mv	a0,s3
ffffffffc020211c:	d1dff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
ffffffffc0202120:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0202122:	cd29                	beqz	a0,ffffffffc020217c <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202124:	611c                	ld	a5,0(a0)
ffffffffc0202126:	e395                	bnez	a5,ffffffffc020214a <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202128:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020212a:	ff2466e3          	bltu	s0,s2,ffffffffc0202116 <unmap_range+0x62>
}
ffffffffc020212e:	70a6                	ld	ra,104(sp)
ffffffffc0202130:	7406                	ld	s0,96(sp)
ffffffffc0202132:	64e6                	ld	s1,88(sp)
ffffffffc0202134:	6946                	ld	s2,80(sp)
ffffffffc0202136:	69a6                	ld	s3,72(sp)
ffffffffc0202138:	6a06                	ld	s4,64(sp)
ffffffffc020213a:	7ae2                	ld	s5,56(sp)
ffffffffc020213c:	7b42                	ld	s6,48(sp)
ffffffffc020213e:	7ba2                	ld	s7,40(sp)
ffffffffc0202140:	7c02                	ld	s8,32(sp)
ffffffffc0202142:	6ce2                	ld	s9,24(sp)
ffffffffc0202144:	6d42                	ld	s10,16(sp)
ffffffffc0202146:	6165                	addi	sp,sp,112
ffffffffc0202148:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc020214a:	0017f713          	andi	a4,a5,1
ffffffffc020214e:	df69                	beqz	a4,ffffffffc0202128 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202150:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202154:	078a                	slli	a5,a5,0x2
ffffffffc0202156:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202158:	08e7ff63          	bgeu	a5,a4,ffffffffc02021f6 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc020215c:	000c3503          	ld	a0,0(s8)
ffffffffc0202160:	97de                	add	a5,a5,s7
ffffffffc0202162:	079a                	slli	a5,a5,0x6
ffffffffc0202164:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202166:	411c                	lw	a5,0(a0)
ffffffffc0202168:	fff7871b          	addiw	a4,a5,-1
ffffffffc020216c:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020216e:	cf11                	beqz	a4,ffffffffc020218a <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202170:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202174:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202178:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020217a:	bf45                	j	ffffffffc020212a <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020217c:	945a                	add	s0,s0,s6
ffffffffc020217e:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202182:	d455                	beqz	s0,ffffffffc020212e <unmap_range+0x7a>
ffffffffc0202184:	f92469e3          	bltu	s0,s2,ffffffffc0202116 <unmap_range+0x62>
ffffffffc0202188:	b75d                	j	ffffffffc020212e <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020218a:	100027f3          	csrr	a5,sstatus
ffffffffc020218e:	8b89                	andi	a5,a5,2
ffffffffc0202190:	e799                	bnez	a5,ffffffffc020219e <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0202192:	000d3783          	ld	a5,0(s10)
ffffffffc0202196:	4585                	li	a1,1
ffffffffc0202198:	739c                	ld	a5,32(a5)
ffffffffc020219a:	9782                	jalr	a5
    if (flag)
ffffffffc020219c:	bfd1                	j	ffffffffc0202170 <unmap_range+0xbc>
ffffffffc020219e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021a0:	80ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02021a4:	000d3783          	ld	a5,0(s10)
ffffffffc02021a8:	6522                	ld	a0,8(sp)
ffffffffc02021aa:	4585                	li	a1,1
ffffffffc02021ac:	739c                	ld	a5,32(a5)
ffffffffc02021ae:	9782                	jalr	a5
        intr_enable();
ffffffffc02021b0:	ff8fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02021b4:	bf75                	j	ffffffffc0202170 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021b6:	00004697          	auipc	a3,0x4
ffffffffc02021ba:	61a68693          	addi	a3,a3,1562 # ffffffffc02067d0 <default_pmm_manager+0x160>
ffffffffc02021be:	00004617          	auipc	a2,0x4
ffffffffc02021c2:	10260613          	addi	a2,a2,258 # ffffffffc02062c0 <commands+0x818>
ffffffffc02021c6:	12200593          	li	a1,290
ffffffffc02021ca:	00004517          	auipc	a0,0x4
ffffffffc02021ce:	5f650513          	addi	a0,a0,1526 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02021d2:	ac0fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02021d6:	00004697          	auipc	a3,0x4
ffffffffc02021da:	62a68693          	addi	a3,a3,1578 # ffffffffc0206800 <default_pmm_manager+0x190>
ffffffffc02021de:	00004617          	auipc	a2,0x4
ffffffffc02021e2:	0e260613          	addi	a2,a2,226 # ffffffffc02062c0 <commands+0x818>
ffffffffc02021e6:	12300593          	li	a1,291
ffffffffc02021ea:	00004517          	auipc	a0,0x4
ffffffffc02021ee:	5d650513          	addi	a0,a0,1494 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02021f2:	aa0fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02021f6:	b53ff0ef          	jal	ra,ffffffffc0201d48 <pa2page.part.0>

ffffffffc02021fa <exit_range>:
{
ffffffffc02021fa:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021fc:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202200:	fc86                	sd	ra,120(sp)
ffffffffc0202202:	f8a2                	sd	s0,112(sp)
ffffffffc0202204:	f4a6                	sd	s1,104(sp)
ffffffffc0202206:	f0ca                	sd	s2,96(sp)
ffffffffc0202208:	ecce                	sd	s3,88(sp)
ffffffffc020220a:	e8d2                	sd	s4,80(sp)
ffffffffc020220c:	e4d6                	sd	s5,72(sp)
ffffffffc020220e:	e0da                	sd	s6,64(sp)
ffffffffc0202210:	fc5e                	sd	s7,56(sp)
ffffffffc0202212:	f862                	sd	s8,48(sp)
ffffffffc0202214:	f466                	sd	s9,40(sp)
ffffffffc0202216:	f06a                	sd	s10,32(sp)
ffffffffc0202218:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020221a:	17d2                	slli	a5,a5,0x34
ffffffffc020221c:	20079a63          	bnez	a5,ffffffffc0202430 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202220:	002007b7          	lui	a5,0x200
ffffffffc0202224:	24f5e463          	bltu	a1,a5,ffffffffc020246c <exit_range+0x272>
ffffffffc0202228:	8ab2                	mv	s5,a2
ffffffffc020222a:	24c5f163          	bgeu	a1,a2,ffffffffc020246c <exit_range+0x272>
ffffffffc020222e:	4785                	li	a5,1
ffffffffc0202230:	07fe                	slli	a5,a5,0x1f
ffffffffc0202232:	22c7ed63          	bltu	a5,a2,ffffffffc020246c <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202236:	c00009b7          	lui	s3,0xc0000
ffffffffc020223a:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020223e:	ffe00937          	lui	s2,0xffe00
ffffffffc0202242:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202246:	5cfd                	li	s9,-1
ffffffffc0202248:	8c2a                	mv	s8,a0
ffffffffc020224a:	0125f933          	and	s2,a1,s2
ffffffffc020224e:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202250:	000c5d17          	auipc	s10,0xc5
ffffffffc0202254:	9d8d0d13          	addi	s10,s10,-1576 # ffffffffc02c6c28 <npage>
    return KADDR(page2pa(page));
ffffffffc0202258:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc020225c:	000c5717          	auipc	a4,0xc5
ffffffffc0202260:	9d470713          	addi	a4,a4,-1580 # ffffffffc02c6c30 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202264:	000c5d97          	auipc	s11,0xc5
ffffffffc0202268:	9d4d8d93          	addi	s11,s11,-1580 # ffffffffc02c6c38 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020226c:	c0000437          	lui	s0,0xc0000
ffffffffc0202270:	944e                	add	s0,s0,s3
ffffffffc0202272:	8079                	srli	s0,s0,0x1e
ffffffffc0202274:	1ff47413          	andi	s0,s0,511
ffffffffc0202278:	040e                	slli	s0,s0,0x3
ffffffffc020227a:	9462                	add	s0,s0,s8
ffffffffc020227c:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38e8>
        if (pde1 & PTE_V)
ffffffffc0202280:	001a7793          	andi	a5,s4,1
ffffffffc0202284:	eb99                	bnez	a5,ffffffffc020229a <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202286:	12098463          	beqz	s3,ffffffffc02023ae <exit_range+0x1b4>
ffffffffc020228a:	400007b7          	lui	a5,0x40000
ffffffffc020228e:	97ce                	add	a5,a5,s3
ffffffffc0202290:	894e                	mv	s2,s3
ffffffffc0202292:	1159fe63          	bgeu	s3,s5,ffffffffc02023ae <exit_range+0x1b4>
ffffffffc0202296:	89be                	mv	s3,a5
ffffffffc0202298:	bfd1                	j	ffffffffc020226c <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc020229a:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020229e:	0a0a                	slli	s4,s4,0x2
ffffffffc02022a0:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02022a4:	1cfa7263          	bgeu	s4,a5,ffffffffc0202468 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022a8:	fff80637          	lui	a2,0xfff80
ffffffffc02022ac:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02022ae:	000806b7          	lui	a3,0x80
ffffffffc02022b2:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02022b4:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02022b8:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02022ba:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02022bc:	18f5fa63          	bgeu	a1,a5,ffffffffc0202450 <exit_range+0x256>
ffffffffc02022c0:	000c5817          	auipc	a6,0xc5
ffffffffc02022c4:	98080813          	addi	a6,a6,-1664 # ffffffffc02c6c40 <va_pa_offset>
ffffffffc02022c8:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02022cc:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02022ce:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02022d2:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02022d4:	00080337          	lui	t1,0x80
ffffffffc02022d8:	6885                	lui	a7,0x1
ffffffffc02022da:	a819                	j	ffffffffc02022f0 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02022dc:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02022de:	002007b7          	lui	a5,0x200
ffffffffc02022e2:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02022e4:	08090c63          	beqz	s2,ffffffffc020237c <exit_range+0x182>
ffffffffc02022e8:	09397a63          	bgeu	s2,s3,ffffffffc020237c <exit_range+0x182>
ffffffffc02022ec:	0f597063          	bgeu	s2,s5,ffffffffc02023cc <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02022f0:	01595493          	srli	s1,s2,0x15
ffffffffc02022f4:	1ff4f493          	andi	s1,s1,511
ffffffffc02022f8:	048e                	slli	s1,s1,0x3
ffffffffc02022fa:	94da                	add	s1,s1,s6
ffffffffc02022fc:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02022fe:	0017f693          	andi	a3,a5,1
ffffffffc0202302:	dee9                	beqz	a3,ffffffffc02022dc <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202304:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202308:	078a                	slli	a5,a5,0x2
ffffffffc020230a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020230c:	14b7fe63          	bgeu	a5,a1,ffffffffc0202468 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202310:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0202312:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202316:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020231a:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020231e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202320:	12bef863          	bgeu	t4,a1,ffffffffc0202450 <exit_range+0x256>
ffffffffc0202324:	00083783          	ld	a5,0(a6)
ffffffffc0202328:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020232a:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020232e:	629c                	ld	a5,0(a3)
ffffffffc0202330:	8b85                	andi	a5,a5,1
ffffffffc0202332:	f7d5                	bnez	a5,ffffffffc02022de <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202334:	06a1                	addi	a3,a3,8
ffffffffc0202336:	fed59ce3          	bne	a1,a3,ffffffffc020232e <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc020233a:	631c                	ld	a5,0(a4)
ffffffffc020233c:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020233e:	100027f3          	csrr	a5,sstatus
ffffffffc0202342:	8b89                	andi	a5,a5,2
ffffffffc0202344:	e7d9                	bnez	a5,ffffffffc02023d2 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202346:	000db783          	ld	a5,0(s11)
ffffffffc020234a:	4585                	li	a1,1
ffffffffc020234c:	e032                	sd	a2,0(sp)
ffffffffc020234e:	739c                	ld	a5,32(a5)
ffffffffc0202350:	9782                	jalr	a5
    if (flag)
ffffffffc0202352:	6602                	ld	a2,0(sp)
ffffffffc0202354:	000c5817          	auipc	a6,0xc5
ffffffffc0202358:	8ec80813          	addi	a6,a6,-1812 # ffffffffc02c6c40 <va_pa_offset>
ffffffffc020235c:	fff80e37          	lui	t3,0xfff80
ffffffffc0202360:	00080337          	lui	t1,0x80
ffffffffc0202364:	6885                	lui	a7,0x1
ffffffffc0202366:	000c5717          	auipc	a4,0xc5
ffffffffc020236a:	8ca70713          	addi	a4,a4,-1846 # ffffffffc02c6c30 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020236e:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0202372:	002007b7          	lui	a5,0x200
ffffffffc0202376:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202378:	f60918e3          	bnez	s2,ffffffffc02022e8 <exit_range+0xee>
            if (free_pd0)
ffffffffc020237c:	f00b85e3          	beqz	s7,ffffffffc0202286 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202380:	000d3783          	ld	a5,0(s10)
ffffffffc0202384:	0efa7263          	bgeu	s4,a5,ffffffffc0202468 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202388:	6308                	ld	a0,0(a4)
ffffffffc020238a:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020238c:	100027f3          	csrr	a5,sstatus
ffffffffc0202390:	8b89                	andi	a5,a5,2
ffffffffc0202392:	efad                	bnez	a5,ffffffffc020240c <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202394:	000db783          	ld	a5,0(s11)
ffffffffc0202398:	4585                	li	a1,1
ffffffffc020239a:	739c                	ld	a5,32(a5)
ffffffffc020239c:	9782                	jalr	a5
ffffffffc020239e:	000c5717          	auipc	a4,0xc5
ffffffffc02023a2:	89270713          	addi	a4,a4,-1902 # ffffffffc02c6c30 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02023a6:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02023aa:	ee0990e3          	bnez	s3,ffffffffc020228a <exit_range+0x90>
}
ffffffffc02023ae:	70e6                	ld	ra,120(sp)
ffffffffc02023b0:	7446                	ld	s0,112(sp)
ffffffffc02023b2:	74a6                	ld	s1,104(sp)
ffffffffc02023b4:	7906                	ld	s2,96(sp)
ffffffffc02023b6:	69e6                	ld	s3,88(sp)
ffffffffc02023b8:	6a46                	ld	s4,80(sp)
ffffffffc02023ba:	6aa6                	ld	s5,72(sp)
ffffffffc02023bc:	6b06                	ld	s6,64(sp)
ffffffffc02023be:	7be2                	ld	s7,56(sp)
ffffffffc02023c0:	7c42                	ld	s8,48(sp)
ffffffffc02023c2:	7ca2                	ld	s9,40(sp)
ffffffffc02023c4:	7d02                	ld	s10,32(sp)
ffffffffc02023c6:	6de2                	ld	s11,24(sp)
ffffffffc02023c8:	6109                	addi	sp,sp,128
ffffffffc02023ca:	8082                	ret
            if (free_pd0)
ffffffffc02023cc:	ea0b8fe3          	beqz	s7,ffffffffc020228a <exit_range+0x90>
ffffffffc02023d0:	bf45                	j	ffffffffc0202380 <exit_range+0x186>
ffffffffc02023d2:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02023d4:	e42a                	sd	a0,8(sp)
ffffffffc02023d6:	dd8fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02023da:	000db783          	ld	a5,0(s11)
ffffffffc02023de:	6522                	ld	a0,8(sp)
ffffffffc02023e0:	4585                	li	a1,1
ffffffffc02023e2:	739c                	ld	a5,32(a5)
ffffffffc02023e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02023e6:	dc2fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02023ea:	6602                	ld	a2,0(sp)
ffffffffc02023ec:	000c5717          	auipc	a4,0xc5
ffffffffc02023f0:	84470713          	addi	a4,a4,-1980 # ffffffffc02c6c30 <pages>
ffffffffc02023f4:	6885                	lui	a7,0x1
ffffffffc02023f6:	00080337          	lui	t1,0x80
ffffffffc02023fa:	fff80e37          	lui	t3,0xfff80
ffffffffc02023fe:	000c5817          	auipc	a6,0xc5
ffffffffc0202402:	84280813          	addi	a6,a6,-1982 # ffffffffc02c6c40 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202406:	0004b023          	sd	zero,0(s1)
ffffffffc020240a:	b7a5                	j	ffffffffc0202372 <exit_range+0x178>
ffffffffc020240c:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020240e:	da0fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202412:	000db783          	ld	a5,0(s11)
ffffffffc0202416:	6502                	ld	a0,0(sp)
ffffffffc0202418:	4585                	li	a1,1
ffffffffc020241a:	739c                	ld	a5,32(a5)
ffffffffc020241c:	9782                	jalr	a5
        intr_enable();
ffffffffc020241e:	d8afe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202422:	000c5717          	auipc	a4,0xc5
ffffffffc0202426:	80e70713          	addi	a4,a4,-2034 # ffffffffc02c6c30 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020242a:	00043023          	sd	zero,0(s0)
ffffffffc020242e:	bfb5                	j	ffffffffc02023aa <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202430:	00004697          	auipc	a3,0x4
ffffffffc0202434:	3a068693          	addi	a3,a3,928 # ffffffffc02067d0 <default_pmm_manager+0x160>
ffffffffc0202438:	00004617          	auipc	a2,0x4
ffffffffc020243c:	e8860613          	addi	a2,a2,-376 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202440:	13700593          	li	a1,311
ffffffffc0202444:	00004517          	auipc	a0,0x4
ffffffffc0202448:	37c50513          	addi	a0,a0,892 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020244c:	846fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202450:	00004617          	auipc	a2,0x4
ffffffffc0202454:	25860613          	addi	a2,a2,600 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0202458:	07100593          	li	a1,113
ffffffffc020245c:	00004517          	auipc	a0,0x4
ffffffffc0202460:	27450513          	addi	a0,a0,628 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0202464:	82efe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202468:	8e1ff0ef          	jal	ra,ffffffffc0201d48 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc020246c:	00004697          	auipc	a3,0x4
ffffffffc0202470:	39468693          	addi	a3,a3,916 # ffffffffc0206800 <default_pmm_manager+0x190>
ffffffffc0202474:	00004617          	auipc	a2,0x4
ffffffffc0202478:	e4c60613          	addi	a2,a2,-436 # ffffffffc02062c0 <commands+0x818>
ffffffffc020247c:	13800593          	li	a1,312
ffffffffc0202480:	00004517          	auipc	a0,0x4
ffffffffc0202484:	34050513          	addi	a0,a0,832 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202488:	80afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020248c <page_remove>:
{
ffffffffc020248c:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020248e:	4601                	li	a2,0
{
ffffffffc0202490:	ec26                	sd	s1,24(sp)
ffffffffc0202492:	f406                	sd	ra,40(sp)
ffffffffc0202494:	f022                	sd	s0,32(sp)
ffffffffc0202496:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202498:	9a1ff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
    if (ptep != NULL)
ffffffffc020249c:	c511                	beqz	a0,ffffffffc02024a8 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020249e:	611c                	ld	a5,0(a0)
ffffffffc02024a0:	842a                	mv	s0,a0
ffffffffc02024a2:	0017f713          	andi	a4,a5,1
ffffffffc02024a6:	e711                	bnez	a4,ffffffffc02024b2 <page_remove+0x26>
}
ffffffffc02024a8:	70a2                	ld	ra,40(sp)
ffffffffc02024aa:	7402                	ld	s0,32(sp)
ffffffffc02024ac:	64e2                	ld	s1,24(sp)
ffffffffc02024ae:	6145                	addi	sp,sp,48
ffffffffc02024b0:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024b2:	078a                	slli	a5,a5,0x2
ffffffffc02024b4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024b6:	000c4717          	auipc	a4,0xc4
ffffffffc02024ba:	77273703          	ld	a4,1906(a4) # ffffffffc02c6c28 <npage>
ffffffffc02024be:	06e7f363          	bgeu	a5,a4,ffffffffc0202524 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02024c2:	fff80537          	lui	a0,0xfff80
ffffffffc02024c6:	97aa                	add	a5,a5,a0
ffffffffc02024c8:	079a                	slli	a5,a5,0x6
ffffffffc02024ca:	000c4517          	auipc	a0,0xc4
ffffffffc02024ce:	76653503          	ld	a0,1894(a0) # ffffffffc02c6c30 <pages>
ffffffffc02024d2:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02024d4:	411c                	lw	a5,0(a0)
ffffffffc02024d6:	fff7871b          	addiw	a4,a5,-1
ffffffffc02024da:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02024dc:	cb11                	beqz	a4,ffffffffc02024f0 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02024de:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02024e2:	12048073          	sfence.vma	s1
}
ffffffffc02024e6:	70a2                	ld	ra,40(sp)
ffffffffc02024e8:	7402                	ld	s0,32(sp)
ffffffffc02024ea:	64e2                	ld	s1,24(sp)
ffffffffc02024ec:	6145                	addi	sp,sp,48
ffffffffc02024ee:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024f0:	100027f3          	csrr	a5,sstatus
ffffffffc02024f4:	8b89                	andi	a5,a5,2
ffffffffc02024f6:	eb89                	bnez	a5,ffffffffc0202508 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02024f8:	000c4797          	auipc	a5,0xc4
ffffffffc02024fc:	7407b783          	ld	a5,1856(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0202500:	739c                	ld	a5,32(a5)
ffffffffc0202502:	4585                	li	a1,1
ffffffffc0202504:	9782                	jalr	a5
    if (flag)
ffffffffc0202506:	bfe1                	j	ffffffffc02024de <page_remove+0x52>
        intr_disable();
ffffffffc0202508:	e42a                	sd	a0,8(sp)
ffffffffc020250a:	ca4fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020250e:	000c4797          	auipc	a5,0xc4
ffffffffc0202512:	72a7b783          	ld	a5,1834(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0202516:	739c                	ld	a5,32(a5)
ffffffffc0202518:	6522                	ld	a0,8(sp)
ffffffffc020251a:	4585                	li	a1,1
ffffffffc020251c:	9782                	jalr	a5
        intr_enable();
ffffffffc020251e:	c8afe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202522:	bf75                	j	ffffffffc02024de <page_remove+0x52>
ffffffffc0202524:	825ff0ef          	jal	ra,ffffffffc0201d48 <pa2page.part.0>

ffffffffc0202528 <page_insert>:
{
ffffffffc0202528:	7139                	addi	sp,sp,-64
ffffffffc020252a:	e852                	sd	s4,16(sp)
ffffffffc020252c:	8a32                	mv	s4,a2
ffffffffc020252e:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202530:	4605                	li	a2,1
{
ffffffffc0202532:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202534:	85d2                	mv	a1,s4
{
ffffffffc0202536:	f426                	sd	s1,40(sp)
ffffffffc0202538:	fc06                	sd	ra,56(sp)
ffffffffc020253a:	f04a                	sd	s2,32(sp)
ffffffffc020253c:	ec4e                	sd	s3,24(sp)
ffffffffc020253e:	e456                	sd	s5,8(sp)
ffffffffc0202540:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202542:	8f7ff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
    if (ptep == NULL)
ffffffffc0202546:	c961                	beqz	a0,ffffffffc0202616 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202548:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020254a:	611c                	ld	a5,0(a0)
ffffffffc020254c:	89aa                	mv	s3,a0
ffffffffc020254e:	0016871b          	addiw	a4,a3,1
ffffffffc0202552:	c018                	sw	a4,0(s0)
ffffffffc0202554:	0017f713          	andi	a4,a5,1
ffffffffc0202558:	ef05                	bnez	a4,ffffffffc0202590 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020255a:	000c4717          	auipc	a4,0xc4
ffffffffc020255e:	6d673703          	ld	a4,1750(a4) # ffffffffc02c6c30 <pages>
ffffffffc0202562:	8c19                	sub	s0,s0,a4
ffffffffc0202564:	000807b7          	lui	a5,0x80
ffffffffc0202568:	8419                	srai	s0,s0,0x6
ffffffffc020256a:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020256c:	042a                	slli	s0,s0,0xa
ffffffffc020256e:	8cc1                	or	s1,s1,s0
ffffffffc0202570:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202574:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38e8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202578:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc020257c:	4501                	li	a0,0
}
ffffffffc020257e:	70e2                	ld	ra,56(sp)
ffffffffc0202580:	7442                	ld	s0,48(sp)
ffffffffc0202582:	74a2                	ld	s1,40(sp)
ffffffffc0202584:	7902                	ld	s2,32(sp)
ffffffffc0202586:	69e2                	ld	s3,24(sp)
ffffffffc0202588:	6a42                	ld	s4,16(sp)
ffffffffc020258a:	6aa2                	ld	s5,8(sp)
ffffffffc020258c:	6121                	addi	sp,sp,64
ffffffffc020258e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202590:	078a                	slli	a5,a5,0x2
ffffffffc0202592:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202594:	000c4717          	auipc	a4,0xc4
ffffffffc0202598:	69473703          	ld	a4,1684(a4) # ffffffffc02c6c28 <npage>
ffffffffc020259c:	06e7ff63          	bgeu	a5,a4,ffffffffc020261a <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02025a0:	000c4a97          	auipc	s5,0xc4
ffffffffc02025a4:	690a8a93          	addi	s5,s5,1680 # ffffffffc02c6c30 <pages>
ffffffffc02025a8:	000ab703          	ld	a4,0(s5)
ffffffffc02025ac:	fff80937          	lui	s2,0xfff80
ffffffffc02025b0:	993e                	add	s2,s2,a5
ffffffffc02025b2:	091a                	slli	s2,s2,0x6
ffffffffc02025b4:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02025b6:	01240c63          	beq	s0,s2,ffffffffc02025ce <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02025ba:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcb9388>
ffffffffc02025be:	fff7869b          	addiw	a3,a5,-1
ffffffffc02025c2:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02025c6:	c691                	beqz	a3,ffffffffc02025d2 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025c8:	120a0073          	sfence.vma	s4
}
ffffffffc02025cc:	bf59                	j	ffffffffc0202562 <page_insert+0x3a>
ffffffffc02025ce:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02025d0:	bf49                	j	ffffffffc0202562 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025d2:	100027f3          	csrr	a5,sstatus
ffffffffc02025d6:	8b89                	andi	a5,a5,2
ffffffffc02025d8:	ef91                	bnez	a5,ffffffffc02025f4 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02025da:	000c4797          	auipc	a5,0xc4
ffffffffc02025de:	65e7b783          	ld	a5,1630(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc02025e2:	739c                	ld	a5,32(a5)
ffffffffc02025e4:	4585                	li	a1,1
ffffffffc02025e6:	854a                	mv	a0,s2
ffffffffc02025e8:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02025ea:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025ee:	120a0073          	sfence.vma	s4
ffffffffc02025f2:	bf85                	j	ffffffffc0202562 <page_insert+0x3a>
        intr_disable();
ffffffffc02025f4:	bbafe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025f8:	000c4797          	auipc	a5,0xc4
ffffffffc02025fc:	6407b783          	ld	a5,1600(a5) # ffffffffc02c6c38 <pmm_manager>
ffffffffc0202600:	739c                	ld	a5,32(a5)
ffffffffc0202602:	4585                	li	a1,1
ffffffffc0202604:	854a                	mv	a0,s2
ffffffffc0202606:	9782                	jalr	a5
        intr_enable();
ffffffffc0202608:	ba0fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020260c:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202610:	120a0073          	sfence.vma	s4
ffffffffc0202614:	b7b9                	j	ffffffffc0202562 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202616:	5571                	li	a0,-4
ffffffffc0202618:	b79d                	j	ffffffffc020257e <page_insert+0x56>
ffffffffc020261a:	f2eff0ef          	jal	ra,ffffffffc0201d48 <pa2page.part.0>

ffffffffc020261e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020261e:	00004797          	auipc	a5,0x4
ffffffffc0202622:	05278793          	addi	a5,a5,82 # ffffffffc0206670 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202626:	638c                	ld	a1,0(a5)
{
ffffffffc0202628:	7159                	addi	sp,sp,-112
ffffffffc020262a:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020262c:	00004517          	auipc	a0,0x4
ffffffffc0202630:	1ec50513          	addi	a0,a0,492 # ffffffffc0206818 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202634:	000c4b17          	auipc	s6,0xc4
ffffffffc0202638:	604b0b13          	addi	s6,s6,1540 # ffffffffc02c6c38 <pmm_manager>
{
ffffffffc020263c:	f486                	sd	ra,104(sp)
ffffffffc020263e:	e8ca                	sd	s2,80(sp)
ffffffffc0202640:	e4ce                	sd	s3,72(sp)
ffffffffc0202642:	f0a2                	sd	s0,96(sp)
ffffffffc0202644:	eca6                	sd	s1,88(sp)
ffffffffc0202646:	e0d2                	sd	s4,64(sp)
ffffffffc0202648:	fc56                	sd	s5,56(sp)
ffffffffc020264a:	f45e                	sd	s7,40(sp)
ffffffffc020264c:	f062                	sd	s8,32(sp)
ffffffffc020264e:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202650:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202654:	b45fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc0202658:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020265c:	000c4997          	auipc	s3,0xc4
ffffffffc0202660:	5e498993          	addi	s3,s3,1508 # ffffffffc02c6c40 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202664:	679c                	ld	a5,8(a5)
ffffffffc0202666:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202668:	57f5                	li	a5,-3
ffffffffc020266a:	07fa                	slli	a5,a5,0x1e
ffffffffc020266c:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202670:	b24fe0ef          	jal	ra,ffffffffc0200994 <get_memory_base>
ffffffffc0202674:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202676:	b28fe0ef          	jal	ra,ffffffffc020099e <get_memory_size>
    if (mem_size == 0)
ffffffffc020267a:	200505e3          	beqz	a0,ffffffffc0203084 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020267e:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202680:	00004517          	auipc	a0,0x4
ffffffffc0202684:	1d050513          	addi	a0,a0,464 # ffffffffc0206850 <default_pmm_manager+0x1e0>
ffffffffc0202688:	b11fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020268c:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202690:	fff40693          	addi	a3,s0,-1
ffffffffc0202694:	864a                	mv	a2,s2
ffffffffc0202696:	85a6                	mv	a1,s1
ffffffffc0202698:	00004517          	auipc	a0,0x4
ffffffffc020269c:	1d050513          	addi	a0,a0,464 # ffffffffc0206868 <default_pmm_manager+0x1f8>
ffffffffc02026a0:	af9fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02026a4:	c8000737          	lui	a4,0xc8000
ffffffffc02026a8:	87a2                	mv	a5,s0
ffffffffc02026aa:	54876163          	bltu	a4,s0,ffffffffc0202bec <pmm_init+0x5ce>
ffffffffc02026ae:	757d                	lui	a0,0xfffff
ffffffffc02026b0:	000c5617          	auipc	a2,0xc5
ffffffffc02026b4:	5c760613          	addi	a2,a2,1479 # ffffffffc02c7c77 <end+0xfff>
ffffffffc02026b8:	8e69                	and	a2,a2,a0
ffffffffc02026ba:	000c4497          	auipc	s1,0xc4
ffffffffc02026be:	56e48493          	addi	s1,s1,1390 # ffffffffc02c6c28 <npage>
ffffffffc02026c2:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026c6:	000c4b97          	auipc	s7,0xc4
ffffffffc02026ca:	56ab8b93          	addi	s7,s7,1386 # ffffffffc02c6c30 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02026ce:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026d0:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026d4:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026d8:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026da:	02f50863          	beq	a0,a5,ffffffffc020270a <pmm_init+0xec>
ffffffffc02026de:	4781                	li	a5,0
ffffffffc02026e0:	4585                	li	a1,1
ffffffffc02026e2:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02026e6:	00679513          	slli	a0,a5,0x6
ffffffffc02026ea:	9532                	add	a0,a0,a2
ffffffffc02026ec:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd38390>
ffffffffc02026f0:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026f4:	6088                	ld	a0,0(s1)
ffffffffc02026f6:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02026f8:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026fc:	00d50733          	add	a4,a0,a3
ffffffffc0202700:	fee7e3e3          	bltu	a5,a4,ffffffffc02026e6 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202704:	071a                	slli	a4,a4,0x6
ffffffffc0202706:	00e606b3          	add	a3,a2,a4
ffffffffc020270a:	c02007b7          	lui	a5,0xc0200
ffffffffc020270e:	2ef6ece3          	bltu	a3,a5,ffffffffc0203206 <pmm_init+0xbe8>
ffffffffc0202712:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202716:	77fd                	lui	a5,0xfffff
ffffffffc0202718:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020271a:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc020271c:	5086eb63          	bltu	a3,s0,ffffffffc0202c32 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202720:	00004517          	auipc	a0,0x4
ffffffffc0202724:	17050513          	addi	a0,a0,368 # ffffffffc0206890 <default_pmm_manager+0x220>
ffffffffc0202728:	a71fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc020272c:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202730:	000c4917          	auipc	s2,0xc4
ffffffffc0202734:	4f090913          	addi	s2,s2,1264 # ffffffffc02c6c20 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202738:	7b9c                	ld	a5,48(a5)
ffffffffc020273a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020273c:	00004517          	auipc	a0,0x4
ffffffffc0202740:	16c50513          	addi	a0,a0,364 # ffffffffc02068a8 <default_pmm_manager+0x238>
ffffffffc0202744:	a55fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202748:	00009697          	auipc	a3,0x9
ffffffffc020274c:	8b868693          	addi	a3,a3,-1864 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202750:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202754:	c02007b7          	lui	a5,0xc0200
ffffffffc0202758:	28f6ebe3          	bltu	a3,a5,ffffffffc02031ee <pmm_init+0xbd0>
ffffffffc020275c:	0009b783          	ld	a5,0(s3)
ffffffffc0202760:	8e9d                	sub	a3,a3,a5
ffffffffc0202762:	000c4797          	auipc	a5,0xc4
ffffffffc0202766:	4ad7bb23          	sd	a3,1206(a5) # ffffffffc02c6c18 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020276a:	100027f3          	csrr	a5,sstatus
ffffffffc020276e:	8b89                	andi	a5,a5,2
ffffffffc0202770:	4a079763          	bnez	a5,ffffffffc0202c1e <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202774:	000b3783          	ld	a5,0(s6)
ffffffffc0202778:	779c                	ld	a5,40(a5)
ffffffffc020277a:	9782                	jalr	a5
ffffffffc020277c:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020277e:	6098                	ld	a4,0(s1)
ffffffffc0202780:	c80007b7          	lui	a5,0xc8000
ffffffffc0202784:	83b1                	srli	a5,a5,0xc
ffffffffc0202786:	66e7e363          	bltu	a5,a4,ffffffffc0202dec <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020278a:	00093503          	ld	a0,0(s2)
ffffffffc020278e:	62050f63          	beqz	a0,ffffffffc0202dcc <pmm_init+0x7ae>
ffffffffc0202792:	03451793          	slli	a5,a0,0x34
ffffffffc0202796:	62079b63          	bnez	a5,ffffffffc0202dcc <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020279a:	4601                	li	a2,0
ffffffffc020279c:	4581                	li	a1,0
ffffffffc020279e:	8c3ff0ef          	jal	ra,ffffffffc0202060 <get_page>
ffffffffc02027a2:	60051563          	bnez	a0,ffffffffc0202dac <pmm_init+0x78e>
ffffffffc02027a6:	100027f3          	csrr	a5,sstatus
ffffffffc02027aa:	8b89                	andi	a5,a5,2
ffffffffc02027ac:	44079e63          	bnez	a5,ffffffffc0202c08 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027b0:	000b3783          	ld	a5,0(s6)
ffffffffc02027b4:	4505                	li	a0,1
ffffffffc02027b6:	6f9c                	ld	a5,24(a5)
ffffffffc02027b8:	9782                	jalr	a5
ffffffffc02027ba:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02027bc:	00093503          	ld	a0,0(s2)
ffffffffc02027c0:	4681                	li	a3,0
ffffffffc02027c2:	4601                	li	a2,0
ffffffffc02027c4:	85d2                	mv	a1,s4
ffffffffc02027c6:	d63ff0ef          	jal	ra,ffffffffc0202528 <page_insert>
ffffffffc02027ca:	26051ae3          	bnez	a0,ffffffffc020323e <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02027ce:	00093503          	ld	a0,0(s2)
ffffffffc02027d2:	4601                	li	a2,0
ffffffffc02027d4:	4581                	li	a1,0
ffffffffc02027d6:	e62ff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
ffffffffc02027da:	240502e3          	beqz	a0,ffffffffc020321e <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02027de:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02027e0:	0017f713          	andi	a4,a5,1
ffffffffc02027e4:	5a070263          	beqz	a4,ffffffffc0202d88 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02027e8:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02027ea:	078a                	slli	a5,a5,0x2
ffffffffc02027ec:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027ee:	58e7fb63          	bgeu	a5,a4,ffffffffc0202d84 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02027f2:	000bb683          	ld	a3,0(s7)
ffffffffc02027f6:	fff80637          	lui	a2,0xfff80
ffffffffc02027fa:	97b2                	add	a5,a5,a2
ffffffffc02027fc:	079a                	slli	a5,a5,0x6
ffffffffc02027fe:	97b6                	add	a5,a5,a3
ffffffffc0202800:	14fa17e3          	bne	s4,a5,ffffffffc020314e <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202804:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc0202808:	4785                	li	a5,1
ffffffffc020280a:	12f692e3          	bne	a3,a5,ffffffffc020312e <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020280e:	00093503          	ld	a0,0(s2)
ffffffffc0202812:	77fd                	lui	a5,0xfffff
ffffffffc0202814:	6114                	ld	a3,0(a0)
ffffffffc0202816:	068a                	slli	a3,a3,0x2
ffffffffc0202818:	8efd                	and	a3,a3,a5
ffffffffc020281a:	00c6d613          	srli	a2,a3,0xc
ffffffffc020281e:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203116 <pmm_init+0xaf8>
ffffffffc0202822:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202826:	96e2                	add	a3,a3,s8
ffffffffc0202828:	0006ba83          	ld	s5,0(a3)
ffffffffc020282c:	0a8a                	slli	s5,s5,0x2
ffffffffc020282e:	00fafab3          	and	s5,s5,a5
ffffffffc0202832:	00cad793          	srli	a5,s5,0xc
ffffffffc0202836:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02030fc <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020283a:	4601                	li	a2,0
ffffffffc020283c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020283e:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202840:	df8ff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202844:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202846:	55551363          	bne	a0,s5,ffffffffc0202d8c <pmm_init+0x76e>
ffffffffc020284a:	100027f3          	csrr	a5,sstatus
ffffffffc020284e:	8b89                	andi	a5,a5,2
ffffffffc0202850:	3a079163          	bnez	a5,ffffffffc0202bf2 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202854:	000b3783          	ld	a5,0(s6)
ffffffffc0202858:	4505                	li	a0,1
ffffffffc020285a:	6f9c                	ld	a5,24(a5)
ffffffffc020285c:	9782                	jalr	a5
ffffffffc020285e:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202860:	00093503          	ld	a0,0(s2)
ffffffffc0202864:	46d1                	li	a3,20
ffffffffc0202866:	6605                	lui	a2,0x1
ffffffffc0202868:	85e2                	mv	a1,s8
ffffffffc020286a:	cbfff0ef          	jal	ra,ffffffffc0202528 <page_insert>
ffffffffc020286e:	060517e3          	bnez	a0,ffffffffc02030dc <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202872:	00093503          	ld	a0,0(s2)
ffffffffc0202876:	4601                	li	a2,0
ffffffffc0202878:	6585                	lui	a1,0x1
ffffffffc020287a:	dbeff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
ffffffffc020287e:	02050fe3          	beqz	a0,ffffffffc02030bc <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202882:	611c                	ld	a5,0(a0)
ffffffffc0202884:	0107f713          	andi	a4,a5,16
ffffffffc0202888:	7c070e63          	beqz	a4,ffffffffc0203064 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc020288c:	8b91                	andi	a5,a5,4
ffffffffc020288e:	7a078b63          	beqz	a5,ffffffffc0203044 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202892:	00093503          	ld	a0,0(s2)
ffffffffc0202896:	611c                	ld	a5,0(a0)
ffffffffc0202898:	8bc1                	andi	a5,a5,16
ffffffffc020289a:	78078563          	beqz	a5,ffffffffc0203024 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc020289e:	000c2703          	lw	a4,0(s8)
ffffffffc02028a2:	4785                	li	a5,1
ffffffffc02028a4:	76f71063          	bne	a4,a5,ffffffffc0203004 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02028a8:	4681                	li	a3,0
ffffffffc02028aa:	6605                	lui	a2,0x1
ffffffffc02028ac:	85d2                	mv	a1,s4
ffffffffc02028ae:	c7bff0ef          	jal	ra,ffffffffc0202528 <page_insert>
ffffffffc02028b2:	72051963          	bnez	a0,ffffffffc0202fe4 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02028b6:	000a2703          	lw	a4,0(s4)
ffffffffc02028ba:	4789                	li	a5,2
ffffffffc02028bc:	70f71463          	bne	a4,a5,ffffffffc0202fc4 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02028c0:	000c2783          	lw	a5,0(s8)
ffffffffc02028c4:	6e079063          	bnez	a5,ffffffffc0202fa4 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02028c8:	00093503          	ld	a0,0(s2)
ffffffffc02028cc:	4601                	li	a2,0
ffffffffc02028ce:	6585                	lui	a1,0x1
ffffffffc02028d0:	d68ff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
ffffffffc02028d4:	6a050863          	beqz	a0,ffffffffc0202f84 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02028d8:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028da:	00177793          	andi	a5,a4,1
ffffffffc02028de:	4a078563          	beqz	a5,ffffffffc0202d88 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028e2:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028e4:	00271793          	slli	a5,a4,0x2
ffffffffc02028e8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028ea:	48d7fd63          	bgeu	a5,a3,ffffffffc0202d84 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ee:	000bb683          	ld	a3,0(s7)
ffffffffc02028f2:	fff80ab7          	lui	s5,0xfff80
ffffffffc02028f6:	97d6                	add	a5,a5,s5
ffffffffc02028f8:	079a                	slli	a5,a5,0x6
ffffffffc02028fa:	97b6                	add	a5,a5,a3
ffffffffc02028fc:	66fa1463          	bne	s4,a5,ffffffffc0202f64 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202900:	8b41                	andi	a4,a4,16
ffffffffc0202902:	64071163          	bnez	a4,ffffffffc0202f44 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202906:	00093503          	ld	a0,0(s2)
ffffffffc020290a:	4581                	li	a1,0
ffffffffc020290c:	b81ff0ef          	jal	ra,ffffffffc020248c <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202910:	000a2c83          	lw	s9,0(s4)
ffffffffc0202914:	4785                	li	a5,1
ffffffffc0202916:	60fc9763          	bne	s9,a5,ffffffffc0202f24 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc020291a:	000c2783          	lw	a5,0(s8)
ffffffffc020291e:	5e079363          	bnez	a5,ffffffffc0202f04 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202922:	00093503          	ld	a0,0(s2)
ffffffffc0202926:	6585                	lui	a1,0x1
ffffffffc0202928:	b65ff0ef          	jal	ra,ffffffffc020248c <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020292c:	000a2783          	lw	a5,0(s4)
ffffffffc0202930:	52079a63          	bnez	a5,ffffffffc0202e64 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202934:	000c2783          	lw	a5,0(s8)
ffffffffc0202938:	50079663          	bnez	a5,ffffffffc0202e44 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020293c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202940:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202942:	000a3683          	ld	a3,0(s4)
ffffffffc0202946:	068a                	slli	a3,a3,0x2
ffffffffc0202948:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020294a:	42b6fd63          	bgeu	a3,a1,ffffffffc0202d84 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020294e:	000bb503          	ld	a0,0(s7)
ffffffffc0202952:	96d6                	add	a3,a3,s5
ffffffffc0202954:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202956:	00d507b3          	add	a5,a0,a3
ffffffffc020295a:	439c                	lw	a5,0(a5)
ffffffffc020295c:	4d979463          	bne	a5,s9,ffffffffc0202e24 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202960:	8699                	srai	a3,a3,0x6
ffffffffc0202962:	00080637          	lui	a2,0x80
ffffffffc0202966:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202968:	00c69713          	slli	a4,a3,0xc
ffffffffc020296c:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020296e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202970:	48b77e63          	bgeu	a4,a1,ffffffffc0202e0c <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202974:	0009b703          	ld	a4,0(s3)
ffffffffc0202978:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc020297a:	629c                	ld	a5,0(a3)
ffffffffc020297c:	078a                	slli	a5,a5,0x2
ffffffffc020297e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202980:	40b7f263          	bgeu	a5,a1,ffffffffc0202d84 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202984:	8f91                	sub	a5,a5,a2
ffffffffc0202986:	079a                	slli	a5,a5,0x6
ffffffffc0202988:	953e                	add	a0,a0,a5
ffffffffc020298a:	100027f3          	csrr	a5,sstatus
ffffffffc020298e:	8b89                	andi	a5,a5,2
ffffffffc0202990:	30079963          	bnez	a5,ffffffffc0202ca2 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202994:	000b3783          	ld	a5,0(s6)
ffffffffc0202998:	4585                	li	a1,1
ffffffffc020299a:	739c                	ld	a5,32(a5)
ffffffffc020299c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020299e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02029a2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02029a4:	078a                	slli	a5,a5,0x2
ffffffffc02029a6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029a8:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202d84 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029ac:	000bb503          	ld	a0,0(s7)
ffffffffc02029b0:	fff80737          	lui	a4,0xfff80
ffffffffc02029b4:	97ba                	add	a5,a5,a4
ffffffffc02029b6:	079a                	slli	a5,a5,0x6
ffffffffc02029b8:	953e                	add	a0,a0,a5
ffffffffc02029ba:	100027f3          	csrr	a5,sstatus
ffffffffc02029be:	8b89                	andi	a5,a5,2
ffffffffc02029c0:	2c079563          	bnez	a5,ffffffffc0202c8a <pmm_init+0x66c>
ffffffffc02029c4:	000b3783          	ld	a5,0(s6)
ffffffffc02029c8:	4585                	li	a1,1
ffffffffc02029ca:	739c                	ld	a5,32(a5)
ffffffffc02029cc:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02029ce:	00093783          	ld	a5,0(s2)
ffffffffc02029d2:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd38388>
    asm volatile("sfence.vma");
ffffffffc02029d6:	12000073          	sfence.vma
ffffffffc02029da:	100027f3          	csrr	a5,sstatus
ffffffffc02029de:	8b89                	andi	a5,a5,2
ffffffffc02029e0:	28079b63          	bnez	a5,ffffffffc0202c76 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc02029e4:	000b3783          	ld	a5,0(s6)
ffffffffc02029e8:	779c                	ld	a5,40(a5)
ffffffffc02029ea:	9782                	jalr	a5
ffffffffc02029ec:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02029ee:	4b441b63          	bne	s0,s4,ffffffffc0202ea4 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02029f2:	00004517          	auipc	a0,0x4
ffffffffc02029f6:	1de50513          	addi	a0,a0,478 # ffffffffc0206bd0 <default_pmm_manager+0x560>
ffffffffc02029fa:	f9efd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02029fe:	100027f3          	csrr	a5,sstatus
ffffffffc0202a02:	8b89                	andi	a5,a5,2
ffffffffc0202a04:	24079f63          	bnez	a5,ffffffffc0202c62 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a08:	000b3783          	ld	a5,0(s6)
ffffffffc0202a0c:	779c                	ld	a5,40(a5)
ffffffffc0202a0e:	9782                	jalr	a5
ffffffffc0202a10:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a12:	6098                	ld	a4,0(s1)
ffffffffc0202a14:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a18:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a1a:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a1e:	6a05                	lui	s4,0x1
ffffffffc0202a20:	02f47c63          	bgeu	s0,a5,ffffffffc0202a58 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202a24:	00c45793          	srli	a5,s0,0xc
ffffffffc0202a28:	00093503          	ld	a0,0(s2)
ffffffffc0202a2c:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202d2a <pmm_init+0x70c>
ffffffffc0202a30:	0009b583          	ld	a1,0(s3)
ffffffffc0202a34:	4601                	li	a2,0
ffffffffc0202a36:	95a2                	add	a1,a1,s0
ffffffffc0202a38:	c00ff0ef          	jal	ra,ffffffffc0201e38 <get_pte>
ffffffffc0202a3c:	32050463          	beqz	a0,ffffffffc0202d64 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a40:	611c                	ld	a5,0(a0)
ffffffffc0202a42:	078a                	slli	a5,a5,0x2
ffffffffc0202a44:	0157f7b3          	and	a5,a5,s5
ffffffffc0202a48:	2e879e63          	bne	a5,s0,ffffffffc0202d44 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a4c:	6098                	ld	a4,0(s1)
ffffffffc0202a4e:	9452                	add	s0,s0,s4
ffffffffc0202a50:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a54:	fcf468e3          	bltu	s0,a5,ffffffffc0202a24 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202a58:	00093783          	ld	a5,0(s2)
ffffffffc0202a5c:	639c                	ld	a5,0(a5)
ffffffffc0202a5e:	42079363          	bnez	a5,ffffffffc0202e84 <pmm_init+0x866>
ffffffffc0202a62:	100027f3          	csrr	a5,sstatus
ffffffffc0202a66:	8b89                	andi	a5,a5,2
ffffffffc0202a68:	24079963          	bnez	a5,ffffffffc0202cba <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a6c:	000b3783          	ld	a5,0(s6)
ffffffffc0202a70:	4505                	li	a0,1
ffffffffc0202a72:	6f9c                	ld	a5,24(a5)
ffffffffc0202a74:	9782                	jalr	a5
ffffffffc0202a76:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a78:	00093503          	ld	a0,0(s2)
ffffffffc0202a7c:	4699                	li	a3,6
ffffffffc0202a7e:	10000613          	li	a2,256
ffffffffc0202a82:	85d2                	mv	a1,s4
ffffffffc0202a84:	aa5ff0ef          	jal	ra,ffffffffc0202528 <page_insert>
ffffffffc0202a88:	44051e63          	bnez	a0,ffffffffc0202ee4 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202a8c:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
ffffffffc0202a90:	4785                	li	a5,1
ffffffffc0202a92:	42f71963          	bne	a4,a5,ffffffffc0202ec4 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202a96:	00093503          	ld	a0,0(s2)
ffffffffc0202a9a:	6405                	lui	s0,0x1
ffffffffc0202a9c:	4699                	li	a3,6
ffffffffc0202a9e:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e40>
ffffffffc0202aa2:	85d2                	mv	a1,s4
ffffffffc0202aa4:	a85ff0ef          	jal	ra,ffffffffc0202528 <page_insert>
ffffffffc0202aa8:	72051363          	bnez	a0,ffffffffc02031ce <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202aac:	000a2703          	lw	a4,0(s4)
ffffffffc0202ab0:	4789                	li	a5,2
ffffffffc0202ab2:	6ef71e63          	bne	a4,a5,ffffffffc02031ae <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202ab6:	00004597          	auipc	a1,0x4
ffffffffc0202aba:	26258593          	addi	a1,a1,610 # ffffffffc0206d18 <default_pmm_manager+0x6a8>
ffffffffc0202abe:	10000513          	li	a0,256
ffffffffc0202ac2:	4e7020ef          	jal	ra,ffffffffc02057a8 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ac6:	10040593          	addi	a1,s0,256
ffffffffc0202aca:	10000513          	li	a0,256
ffffffffc0202ace:	4ed020ef          	jal	ra,ffffffffc02057ba <strcmp>
ffffffffc0202ad2:	6a051e63          	bnez	a0,ffffffffc020318e <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202ad6:	000bb683          	ld	a3,0(s7)
ffffffffc0202ada:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202ade:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202ae0:	40da06b3          	sub	a3,s4,a3
ffffffffc0202ae4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202ae6:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202ae8:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202aea:	8031                	srli	s0,s0,0xc
ffffffffc0202aec:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202af0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202af2:	30f77d63          	bgeu	a4,a5,ffffffffc0202e0c <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202af6:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202afa:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202afe:	96be                	add	a3,a3,a5
ffffffffc0202b00:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b04:	46f020ef          	jal	ra,ffffffffc0205772 <strlen>
ffffffffc0202b08:	66051363          	bnez	a0,ffffffffc020316e <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202b0c:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b10:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b12:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd38388>
ffffffffc0202b16:	068a                	slli	a3,a3,0x2
ffffffffc0202b18:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b1a:	26f6f563          	bgeu	a3,a5,ffffffffc0202d84 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202b1e:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b20:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b22:	2ef47563          	bgeu	s0,a5,ffffffffc0202e0c <pmm_init+0x7ee>
ffffffffc0202b26:	0009b403          	ld	s0,0(s3)
ffffffffc0202b2a:	9436                	add	s0,s0,a3
ffffffffc0202b2c:	100027f3          	csrr	a5,sstatus
ffffffffc0202b30:	8b89                	andi	a5,a5,2
ffffffffc0202b32:	1e079163          	bnez	a5,ffffffffc0202d14 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202b36:	000b3783          	ld	a5,0(s6)
ffffffffc0202b3a:	4585                	li	a1,1
ffffffffc0202b3c:	8552                	mv	a0,s4
ffffffffc0202b3e:	739c                	ld	a5,32(a5)
ffffffffc0202b40:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b42:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202b44:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b46:	078a                	slli	a5,a5,0x2
ffffffffc0202b48:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b4a:	22e7fd63          	bgeu	a5,a4,ffffffffc0202d84 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b4e:	000bb503          	ld	a0,0(s7)
ffffffffc0202b52:	fff80737          	lui	a4,0xfff80
ffffffffc0202b56:	97ba                	add	a5,a5,a4
ffffffffc0202b58:	079a                	slli	a5,a5,0x6
ffffffffc0202b5a:	953e                	add	a0,a0,a5
ffffffffc0202b5c:	100027f3          	csrr	a5,sstatus
ffffffffc0202b60:	8b89                	andi	a5,a5,2
ffffffffc0202b62:	18079d63          	bnez	a5,ffffffffc0202cfc <pmm_init+0x6de>
ffffffffc0202b66:	000b3783          	ld	a5,0(s6)
ffffffffc0202b6a:	4585                	li	a1,1
ffffffffc0202b6c:	739c                	ld	a5,32(a5)
ffffffffc0202b6e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b70:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202b74:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b76:	078a                	slli	a5,a5,0x2
ffffffffc0202b78:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b7a:	20e7f563          	bgeu	a5,a4,ffffffffc0202d84 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b7e:	000bb503          	ld	a0,0(s7)
ffffffffc0202b82:	fff80737          	lui	a4,0xfff80
ffffffffc0202b86:	97ba                	add	a5,a5,a4
ffffffffc0202b88:	079a                	slli	a5,a5,0x6
ffffffffc0202b8a:	953e                	add	a0,a0,a5
ffffffffc0202b8c:	100027f3          	csrr	a5,sstatus
ffffffffc0202b90:	8b89                	andi	a5,a5,2
ffffffffc0202b92:	14079963          	bnez	a5,ffffffffc0202ce4 <pmm_init+0x6c6>
ffffffffc0202b96:	000b3783          	ld	a5,0(s6)
ffffffffc0202b9a:	4585                	li	a1,1
ffffffffc0202b9c:	739c                	ld	a5,32(a5)
ffffffffc0202b9e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ba0:	00093783          	ld	a5,0(s2)
ffffffffc0202ba4:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202ba8:	12000073          	sfence.vma
ffffffffc0202bac:	100027f3          	csrr	a5,sstatus
ffffffffc0202bb0:	8b89                	andi	a5,a5,2
ffffffffc0202bb2:	10079f63          	bnez	a5,ffffffffc0202cd0 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bb6:	000b3783          	ld	a5,0(s6)
ffffffffc0202bba:	779c                	ld	a5,40(a5)
ffffffffc0202bbc:	9782                	jalr	a5
ffffffffc0202bbe:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202bc0:	4c8c1e63          	bne	s8,s0,ffffffffc020309c <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202bc4:	00004517          	auipc	a0,0x4
ffffffffc0202bc8:	1cc50513          	addi	a0,a0,460 # ffffffffc0206d90 <default_pmm_manager+0x720>
ffffffffc0202bcc:	dccfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202bd0:	7406                	ld	s0,96(sp)
ffffffffc0202bd2:	70a6                	ld	ra,104(sp)
ffffffffc0202bd4:	64e6                	ld	s1,88(sp)
ffffffffc0202bd6:	6946                	ld	s2,80(sp)
ffffffffc0202bd8:	69a6                	ld	s3,72(sp)
ffffffffc0202bda:	6a06                	ld	s4,64(sp)
ffffffffc0202bdc:	7ae2                	ld	s5,56(sp)
ffffffffc0202bde:	7b42                	ld	s6,48(sp)
ffffffffc0202be0:	7ba2                	ld	s7,40(sp)
ffffffffc0202be2:	7c02                	ld	s8,32(sp)
ffffffffc0202be4:	6ce2                	ld	s9,24(sp)
ffffffffc0202be6:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202be8:	f97fe06f          	j	ffffffffc0201b7e <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202bec:	c80007b7          	lui	a5,0xc8000
ffffffffc0202bf0:	bc7d                	j	ffffffffc02026ae <pmm_init+0x90>
        intr_disable();
ffffffffc0202bf2:	dbdfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202bfa:	4505                	li	a0,1
ffffffffc0202bfc:	6f9c                	ld	a5,24(a5)
ffffffffc0202bfe:	9782                	jalr	a5
ffffffffc0202c00:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c02:	da7fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c06:	b9a9                	j	ffffffffc0202860 <pmm_init+0x242>
        intr_disable();
ffffffffc0202c08:	da7fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c0c:	000b3783          	ld	a5,0(s6)
ffffffffc0202c10:	4505                	li	a0,1
ffffffffc0202c12:	6f9c                	ld	a5,24(a5)
ffffffffc0202c14:	9782                	jalr	a5
ffffffffc0202c16:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c18:	d91fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c1c:	b645                	j	ffffffffc02027bc <pmm_init+0x19e>
        intr_disable();
ffffffffc0202c1e:	d91fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c22:	000b3783          	ld	a5,0(s6)
ffffffffc0202c26:	779c                	ld	a5,40(a5)
ffffffffc0202c28:	9782                	jalr	a5
ffffffffc0202c2a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202c2c:	d7dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c30:	b6b9                	j	ffffffffc020277e <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202c32:	6705                	lui	a4,0x1
ffffffffc0202c34:	177d                	addi	a4,a4,-1
ffffffffc0202c36:	96ba                	add	a3,a3,a4
ffffffffc0202c38:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202c3a:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202c3e:	14a77363          	bgeu	a4,a0,ffffffffc0202d84 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202c42:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202c46:	fff80537          	lui	a0,0xfff80
ffffffffc0202c4a:	972a                	add	a4,a4,a0
ffffffffc0202c4c:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202c4e:	8c1d                	sub	s0,s0,a5
ffffffffc0202c50:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202c54:	00c45593          	srli	a1,s0,0xc
ffffffffc0202c58:	9532                	add	a0,a0,a2
ffffffffc0202c5a:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202c5c:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202c60:	b4c1                	j	ffffffffc0202720 <pmm_init+0x102>
        intr_disable();
ffffffffc0202c62:	d4dfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c66:	000b3783          	ld	a5,0(s6)
ffffffffc0202c6a:	779c                	ld	a5,40(a5)
ffffffffc0202c6c:	9782                	jalr	a5
ffffffffc0202c6e:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c70:	d39fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c74:	bb79                	j	ffffffffc0202a12 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202c76:	d39fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c7a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c7e:	779c                	ld	a5,40(a5)
ffffffffc0202c80:	9782                	jalr	a5
ffffffffc0202c82:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c84:	d25fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c88:	b39d                	j	ffffffffc02029ee <pmm_init+0x3d0>
ffffffffc0202c8a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202c8c:	d23fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202c90:	000b3783          	ld	a5,0(s6)
ffffffffc0202c94:	6522                	ld	a0,8(sp)
ffffffffc0202c96:	4585                	li	a1,1
ffffffffc0202c98:	739c                	ld	a5,32(a5)
ffffffffc0202c9a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202c9c:	d0dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202ca0:	b33d                	j	ffffffffc02029ce <pmm_init+0x3b0>
ffffffffc0202ca2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ca4:	d0bfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202ca8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cac:	6522                	ld	a0,8(sp)
ffffffffc0202cae:	4585                	li	a1,1
ffffffffc0202cb0:	739c                	ld	a5,32(a5)
ffffffffc0202cb2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cb4:	cf5fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cb8:	b1dd                	j	ffffffffc020299e <pmm_init+0x380>
        intr_disable();
ffffffffc0202cba:	cf5fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cbe:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc2:	4505                	li	a0,1
ffffffffc0202cc4:	6f9c                	ld	a5,24(a5)
ffffffffc0202cc6:	9782                	jalr	a5
ffffffffc0202cc8:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cca:	cdffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cce:	b36d                	j	ffffffffc0202a78 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202cd0:	cdffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cd4:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd8:	779c                	ld	a5,40(a5)
ffffffffc0202cda:	9782                	jalr	a5
ffffffffc0202cdc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202cde:	ccbfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202ce2:	bdf9                	j	ffffffffc0202bc0 <pmm_init+0x5a2>
ffffffffc0202ce4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ce6:	cc9fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202cea:	000b3783          	ld	a5,0(s6)
ffffffffc0202cee:	6522                	ld	a0,8(sp)
ffffffffc0202cf0:	4585                	li	a1,1
ffffffffc0202cf2:	739c                	ld	a5,32(a5)
ffffffffc0202cf4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cf6:	cb3fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cfa:	b55d                	j	ffffffffc0202ba0 <pmm_init+0x582>
ffffffffc0202cfc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cfe:	cb1fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d02:	000b3783          	ld	a5,0(s6)
ffffffffc0202d06:	6522                	ld	a0,8(sp)
ffffffffc0202d08:	4585                	li	a1,1
ffffffffc0202d0a:	739c                	ld	a5,32(a5)
ffffffffc0202d0c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d0e:	c9bfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d12:	bdb9                	j	ffffffffc0202b70 <pmm_init+0x552>
        intr_disable();
ffffffffc0202d14:	c9bfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d18:	000b3783          	ld	a5,0(s6)
ffffffffc0202d1c:	4585                	li	a1,1
ffffffffc0202d1e:	8552                	mv	a0,s4
ffffffffc0202d20:	739c                	ld	a5,32(a5)
ffffffffc0202d22:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d24:	c85fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d28:	bd29                	j	ffffffffc0202b42 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d2a:	86a2                	mv	a3,s0
ffffffffc0202d2c:	00004617          	auipc	a2,0x4
ffffffffc0202d30:	97c60613          	addi	a2,a2,-1668 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0202d34:	24100593          	li	a1,577
ffffffffc0202d38:	00004517          	auipc	a0,0x4
ffffffffc0202d3c:	a8850513          	addi	a0,a0,-1400 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202d40:	f52fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d44:	00004697          	auipc	a3,0x4
ffffffffc0202d48:	eec68693          	addi	a3,a3,-276 # ffffffffc0206c30 <default_pmm_manager+0x5c0>
ffffffffc0202d4c:	00003617          	auipc	a2,0x3
ffffffffc0202d50:	57460613          	addi	a2,a2,1396 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202d54:	24200593          	li	a1,578
ffffffffc0202d58:	00004517          	auipc	a0,0x4
ffffffffc0202d5c:	a6850513          	addi	a0,a0,-1432 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202d60:	f32fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d64:	00004697          	auipc	a3,0x4
ffffffffc0202d68:	e8c68693          	addi	a3,a3,-372 # ffffffffc0206bf0 <default_pmm_manager+0x580>
ffffffffc0202d6c:	00003617          	auipc	a2,0x3
ffffffffc0202d70:	55460613          	addi	a2,a2,1364 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202d74:	24100593          	li	a1,577
ffffffffc0202d78:	00004517          	auipc	a0,0x4
ffffffffc0202d7c:	a4850513          	addi	a0,a0,-1464 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202d80:	f12fd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202d84:	fc5fe0ef          	jal	ra,ffffffffc0201d48 <pa2page.part.0>
ffffffffc0202d88:	fddfe0ef          	jal	ra,ffffffffc0201d64 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d8c:	00004697          	auipc	a3,0x4
ffffffffc0202d90:	c5c68693          	addi	a3,a3,-932 # ffffffffc02069e8 <default_pmm_manager+0x378>
ffffffffc0202d94:	00003617          	auipc	a2,0x3
ffffffffc0202d98:	52c60613          	addi	a2,a2,1324 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202d9c:	21100593          	li	a1,529
ffffffffc0202da0:	00004517          	auipc	a0,0x4
ffffffffc0202da4:	a2050513          	addi	a0,a0,-1504 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202da8:	eeafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202dac:	00004697          	auipc	a3,0x4
ffffffffc0202db0:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0206928 <default_pmm_manager+0x2b8>
ffffffffc0202db4:	00003617          	auipc	a2,0x3
ffffffffc0202db8:	50c60613          	addi	a2,a2,1292 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202dbc:	20400593          	li	a1,516
ffffffffc0202dc0:	00004517          	auipc	a0,0x4
ffffffffc0202dc4:	a0050513          	addi	a0,a0,-1536 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202dc8:	ecafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202dcc:	00004697          	auipc	a3,0x4
ffffffffc0202dd0:	b1c68693          	addi	a3,a3,-1252 # ffffffffc02068e8 <default_pmm_manager+0x278>
ffffffffc0202dd4:	00003617          	auipc	a2,0x3
ffffffffc0202dd8:	4ec60613          	addi	a2,a2,1260 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202ddc:	20300593          	li	a1,515
ffffffffc0202de0:	00004517          	auipc	a0,0x4
ffffffffc0202de4:	9e050513          	addi	a0,a0,-1568 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202de8:	eaafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202dec:	00004697          	auipc	a3,0x4
ffffffffc0202df0:	adc68693          	addi	a3,a3,-1316 # ffffffffc02068c8 <default_pmm_manager+0x258>
ffffffffc0202df4:	00003617          	auipc	a2,0x3
ffffffffc0202df8:	4cc60613          	addi	a2,a2,1228 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202dfc:	20200593          	li	a1,514
ffffffffc0202e00:	00004517          	auipc	a0,0x4
ffffffffc0202e04:	9c050513          	addi	a0,a0,-1600 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202e08:	e8afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202e0c:	00004617          	auipc	a2,0x4
ffffffffc0202e10:	89c60613          	addi	a2,a2,-1892 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0202e14:	07100593          	li	a1,113
ffffffffc0202e18:	00004517          	auipc	a0,0x4
ffffffffc0202e1c:	8b850513          	addi	a0,a0,-1864 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0202e20:	e72fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e24:	00004697          	auipc	a3,0x4
ffffffffc0202e28:	d5468693          	addi	a3,a3,-684 # ffffffffc0206b78 <default_pmm_manager+0x508>
ffffffffc0202e2c:	00003617          	auipc	a2,0x3
ffffffffc0202e30:	49460613          	addi	a2,a2,1172 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202e34:	22a00593          	li	a1,554
ffffffffc0202e38:	00004517          	auipc	a0,0x4
ffffffffc0202e3c:	98850513          	addi	a0,a0,-1656 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202e40:	e52fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e44:	00004697          	auipc	a3,0x4
ffffffffc0202e48:	cec68693          	addi	a3,a3,-788 # ffffffffc0206b30 <default_pmm_manager+0x4c0>
ffffffffc0202e4c:	00003617          	auipc	a2,0x3
ffffffffc0202e50:	47460613          	addi	a2,a2,1140 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202e54:	22800593          	li	a1,552
ffffffffc0202e58:	00004517          	auipc	a0,0x4
ffffffffc0202e5c:	96850513          	addi	a0,a0,-1688 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202e60:	e32fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e64:	00004697          	auipc	a3,0x4
ffffffffc0202e68:	cfc68693          	addi	a3,a3,-772 # ffffffffc0206b60 <default_pmm_manager+0x4f0>
ffffffffc0202e6c:	00003617          	auipc	a2,0x3
ffffffffc0202e70:	45460613          	addi	a2,a2,1108 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202e74:	22700593          	li	a1,551
ffffffffc0202e78:	00004517          	auipc	a0,0x4
ffffffffc0202e7c:	94850513          	addi	a0,a0,-1720 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202e80:	e12fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202e84:	00004697          	auipc	a3,0x4
ffffffffc0202e88:	dc468693          	addi	a3,a3,-572 # ffffffffc0206c48 <default_pmm_manager+0x5d8>
ffffffffc0202e8c:	00003617          	auipc	a2,0x3
ffffffffc0202e90:	43460613          	addi	a2,a2,1076 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202e94:	24500593          	li	a1,581
ffffffffc0202e98:	00004517          	auipc	a0,0x4
ffffffffc0202e9c:	92850513          	addi	a0,a0,-1752 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202ea0:	df2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ea4:	00004697          	auipc	a3,0x4
ffffffffc0202ea8:	d0468693          	addi	a3,a3,-764 # ffffffffc0206ba8 <default_pmm_manager+0x538>
ffffffffc0202eac:	00003617          	auipc	a2,0x3
ffffffffc0202eb0:	41460613          	addi	a2,a2,1044 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202eb4:	23200593          	li	a1,562
ffffffffc0202eb8:	00004517          	auipc	a0,0x4
ffffffffc0202ebc:	90850513          	addi	a0,a0,-1784 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202ec0:	dd2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202ec4:	00004697          	auipc	a3,0x4
ffffffffc0202ec8:	ddc68693          	addi	a3,a3,-548 # ffffffffc0206ca0 <default_pmm_manager+0x630>
ffffffffc0202ecc:	00003617          	auipc	a2,0x3
ffffffffc0202ed0:	3f460613          	addi	a2,a2,1012 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202ed4:	24a00593          	li	a1,586
ffffffffc0202ed8:	00004517          	auipc	a0,0x4
ffffffffc0202edc:	8e850513          	addi	a0,a0,-1816 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202ee0:	db2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202ee4:	00004697          	auipc	a3,0x4
ffffffffc0202ee8:	d7c68693          	addi	a3,a3,-644 # ffffffffc0206c60 <default_pmm_manager+0x5f0>
ffffffffc0202eec:	00003617          	auipc	a2,0x3
ffffffffc0202ef0:	3d460613          	addi	a2,a2,980 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202ef4:	24900593          	li	a1,585
ffffffffc0202ef8:	00004517          	auipc	a0,0x4
ffffffffc0202efc:	8c850513          	addi	a0,a0,-1848 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202f00:	d92fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f04:	00004697          	auipc	a3,0x4
ffffffffc0202f08:	c2c68693          	addi	a3,a3,-980 # ffffffffc0206b30 <default_pmm_manager+0x4c0>
ffffffffc0202f0c:	00003617          	auipc	a2,0x3
ffffffffc0202f10:	3b460613          	addi	a2,a2,948 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202f14:	22400593          	li	a1,548
ffffffffc0202f18:	00004517          	auipc	a0,0x4
ffffffffc0202f1c:	8a850513          	addi	a0,a0,-1880 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202f20:	d72fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f24:	00004697          	auipc	a3,0x4
ffffffffc0202f28:	aac68693          	addi	a3,a3,-1364 # ffffffffc02069d0 <default_pmm_manager+0x360>
ffffffffc0202f2c:	00003617          	auipc	a2,0x3
ffffffffc0202f30:	39460613          	addi	a2,a2,916 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202f34:	22300593          	li	a1,547
ffffffffc0202f38:	00004517          	auipc	a0,0x4
ffffffffc0202f3c:	88850513          	addi	a0,a0,-1912 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202f40:	d52fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202f44:	00004697          	auipc	a3,0x4
ffffffffc0202f48:	c0468693          	addi	a3,a3,-1020 # ffffffffc0206b48 <default_pmm_manager+0x4d8>
ffffffffc0202f4c:	00003617          	auipc	a2,0x3
ffffffffc0202f50:	37460613          	addi	a2,a2,884 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202f54:	22000593          	li	a1,544
ffffffffc0202f58:	00004517          	auipc	a0,0x4
ffffffffc0202f5c:	86850513          	addi	a0,a0,-1944 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202f60:	d32fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f64:	00004697          	auipc	a3,0x4
ffffffffc0202f68:	a5468693          	addi	a3,a3,-1452 # ffffffffc02069b8 <default_pmm_manager+0x348>
ffffffffc0202f6c:	00003617          	auipc	a2,0x3
ffffffffc0202f70:	35460613          	addi	a2,a2,852 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202f74:	21f00593          	li	a1,543
ffffffffc0202f78:	00004517          	auipc	a0,0x4
ffffffffc0202f7c:	84850513          	addi	a0,a0,-1976 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202f80:	d12fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202f84:	00004697          	auipc	a3,0x4
ffffffffc0202f88:	ad468693          	addi	a3,a3,-1324 # ffffffffc0206a58 <default_pmm_manager+0x3e8>
ffffffffc0202f8c:	00003617          	auipc	a2,0x3
ffffffffc0202f90:	33460613          	addi	a2,a2,820 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202f94:	21e00593          	li	a1,542
ffffffffc0202f98:	00004517          	auipc	a0,0x4
ffffffffc0202f9c:	82850513          	addi	a0,a0,-2008 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202fa0:	cf2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fa4:	00004697          	auipc	a3,0x4
ffffffffc0202fa8:	b8c68693          	addi	a3,a3,-1140 # ffffffffc0206b30 <default_pmm_manager+0x4c0>
ffffffffc0202fac:	00003617          	auipc	a2,0x3
ffffffffc0202fb0:	31460613          	addi	a2,a2,788 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202fb4:	21d00593          	li	a1,541
ffffffffc0202fb8:	00004517          	auipc	a0,0x4
ffffffffc0202fbc:	80850513          	addi	a0,a0,-2040 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202fc0:	cd2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202fc4:	00004697          	auipc	a3,0x4
ffffffffc0202fc8:	b5468693          	addi	a3,a3,-1196 # ffffffffc0206b18 <default_pmm_manager+0x4a8>
ffffffffc0202fcc:	00003617          	auipc	a2,0x3
ffffffffc0202fd0:	2f460613          	addi	a2,a2,756 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202fd4:	21c00593          	li	a1,540
ffffffffc0202fd8:	00003517          	auipc	a0,0x3
ffffffffc0202fdc:	7e850513          	addi	a0,a0,2024 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0202fe0:	cb2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202fe4:	00004697          	auipc	a3,0x4
ffffffffc0202fe8:	b0468693          	addi	a3,a3,-1276 # ffffffffc0206ae8 <default_pmm_manager+0x478>
ffffffffc0202fec:	00003617          	auipc	a2,0x3
ffffffffc0202ff0:	2d460613          	addi	a2,a2,724 # ffffffffc02062c0 <commands+0x818>
ffffffffc0202ff4:	21b00593          	li	a1,539
ffffffffc0202ff8:	00003517          	auipc	a0,0x3
ffffffffc0202ffc:	7c850513          	addi	a0,a0,1992 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203000:	c92fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203004:	00004697          	auipc	a3,0x4
ffffffffc0203008:	acc68693          	addi	a3,a3,-1332 # ffffffffc0206ad0 <default_pmm_manager+0x460>
ffffffffc020300c:	00003617          	auipc	a2,0x3
ffffffffc0203010:	2b460613          	addi	a2,a2,692 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203014:	21900593          	li	a1,537
ffffffffc0203018:	00003517          	auipc	a0,0x3
ffffffffc020301c:	7a850513          	addi	a0,a0,1960 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203020:	c72fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203024:	00004697          	auipc	a3,0x4
ffffffffc0203028:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0206ab0 <default_pmm_manager+0x440>
ffffffffc020302c:	00003617          	auipc	a2,0x3
ffffffffc0203030:	29460613          	addi	a2,a2,660 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203034:	21800593          	li	a1,536
ffffffffc0203038:	00003517          	auipc	a0,0x3
ffffffffc020303c:	78850513          	addi	a0,a0,1928 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203040:	c52fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203044:	00004697          	auipc	a3,0x4
ffffffffc0203048:	a5c68693          	addi	a3,a3,-1444 # ffffffffc0206aa0 <default_pmm_manager+0x430>
ffffffffc020304c:	00003617          	auipc	a2,0x3
ffffffffc0203050:	27460613          	addi	a2,a2,628 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203054:	21700593          	li	a1,535
ffffffffc0203058:	00003517          	auipc	a0,0x3
ffffffffc020305c:	76850513          	addi	a0,a0,1896 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203060:	c32fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203064:	00004697          	auipc	a3,0x4
ffffffffc0203068:	a2c68693          	addi	a3,a3,-1492 # ffffffffc0206a90 <default_pmm_manager+0x420>
ffffffffc020306c:	00003617          	auipc	a2,0x3
ffffffffc0203070:	25460613          	addi	a2,a2,596 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203074:	21600593          	li	a1,534
ffffffffc0203078:	00003517          	auipc	a0,0x3
ffffffffc020307c:	74850513          	addi	a0,a0,1864 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203080:	c12fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc0203084:	00003617          	auipc	a2,0x3
ffffffffc0203088:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206830 <default_pmm_manager+0x1c0>
ffffffffc020308c:	06500593          	li	a1,101
ffffffffc0203090:	00003517          	auipc	a0,0x3
ffffffffc0203094:	73050513          	addi	a0,a0,1840 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203098:	bfafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020309c:	00004697          	auipc	a3,0x4
ffffffffc02030a0:	b0c68693          	addi	a3,a3,-1268 # ffffffffc0206ba8 <default_pmm_manager+0x538>
ffffffffc02030a4:	00003617          	auipc	a2,0x3
ffffffffc02030a8:	21c60613          	addi	a2,a2,540 # ffffffffc02062c0 <commands+0x818>
ffffffffc02030ac:	25c00593          	li	a1,604
ffffffffc02030b0:	00003517          	auipc	a0,0x3
ffffffffc02030b4:	71050513          	addi	a0,a0,1808 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02030b8:	bdafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030bc:	00004697          	auipc	a3,0x4
ffffffffc02030c0:	99c68693          	addi	a3,a3,-1636 # ffffffffc0206a58 <default_pmm_manager+0x3e8>
ffffffffc02030c4:	00003617          	auipc	a2,0x3
ffffffffc02030c8:	1fc60613          	addi	a2,a2,508 # ffffffffc02062c0 <commands+0x818>
ffffffffc02030cc:	21500593          	li	a1,533
ffffffffc02030d0:	00003517          	auipc	a0,0x3
ffffffffc02030d4:	6f050513          	addi	a0,a0,1776 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02030d8:	bbafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02030dc:	00004697          	auipc	a3,0x4
ffffffffc02030e0:	93c68693          	addi	a3,a3,-1732 # ffffffffc0206a18 <default_pmm_manager+0x3a8>
ffffffffc02030e4:	00003617          	auipc	a2,0x3
ffffffffc02030e8:	1dc60613          	addi	a2,a2,476 # ffffffffc02062c0 <commands+0x818>
ffffffffc02030ec:	21400593          	li	a1,532
ffffffffc02030f0:	00003517          	auipc	a0,0x3
ffffffffc02030f4:	6d050513          	addi	a0,a0,1744 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02030f8:	b9afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02030fc:	86d6                	mv	a3,s5
ffffffffc02030fe:	00003617          	auipc	a2,0x3
ffffffffc0203102:	5aa60613          	addi	a2,a2,1450 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0203106:	21000593          	li	a1,528
ffffffffc020310a:	00003517          	auipc	a0,0x3
ffffffffc020310e:	6b650513          	addi	a0,a0,1718 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203112:	b80fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203116:	00003617          	auipc	a2,0x3
ffffffffc020311a:	59260613          	addi	a2,a2,1426 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc020311e:	20f00593          	li	a1,527
ffffffffc0203122:	00003517          	auipc	a0,0x3
ffffffffc0203126:	69e50513          	addi	a0,a0,1694 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020312a:	b68fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020312e:	00004697          	auipc	a3,0x4
ffffffffc0203132:	8a268693          	addi	a3,a3,-1886 # ffffffffc02069d0 <default_pmm_manager+0x360>
ffffffffc0203136:	00003617          	auipc	a2,0x3
ffffffffc020313a:	18a60613          	addi	a2,a2,394 # ffffffffc02062c0 <commands+0x818>
ffffffffc020313e:	20d00593          	li	a1,525
ffffffffc0203142:	00003517          	auipc	a0,0x3
ffffffffc0203146:	67e50513          	addi	a0,a0,1662 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020314a:	b48fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020314e:	00004697          	auipc	a3,0x4
ffffffffc0203152:	86a68693          	addi	a3,a3,-1942 # ffffffffc02069b8 <default_pmm_manager+0x348>
ffffffffc0203156:	00003617          	auipc	a2,0x3
ffffffffc020315a:	16a60613          	addi	a2,a2,362 # ffffffffc02062c0 <commands+0x818>
ffffffffc020315e:	20c00593          	li	a1,524
ffffffffc0203162:	00003517          	auipc	a0,0x3
ffffffffc0203166:	65e50513          	addi	a0,a0,1630 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020316a:	b28fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020316e:	00004697          	auipc	a3,0x4
ffffffffc0203172:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0206d68 <default_pmm_manager+0x6f8>
ffffffffc0203176:	00003617          	auipc	a2,0x3
ffffffffc020317a:	14a60613          	addi	a2,a2,330 # ffffffffc02062c0 <commands+0x818>
ffffffffc020317e:	25300593          	li	a1,595
ffffffffc0203182:	00003517          	auipc	a0,0x3
ffffffffc0203186:	63e50513          	addi	a0,a0,1598 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020318a:	b08fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020318e:	00004697          	auipc	a3,0x4
ffffffffc0203192:	ba268693          	addi	a3,a3,-1118 # ffffffffc0206d30 <default_pmm_manager+0x6c0>
ffffffffc0203196:	00003617          	auipc	a2,0x3
ffffffffc020319a:	12a60613          	addi	a2,a2,298 # ffffffffc02062c0 <commands+0x818>
ffffffffc020319e:	25000593          	li	a1,592
ffffffffc02031a2:	00003517          	auipc	a0,0x3
ffffffffc02031a6:	61e50513          	addi	a0,a0,1566 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02031aa:	ae8fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02031ae:	00004697          	auipc	a3,0x4
ffffffffc02031b2:	b5268693          	addi	a3,a3,-1198 # ffffffffc0206d00 <default_pmm_manager+0x690>
ffffffffc02031b6:	00003617          	auipc	a2,0x3
ffffffffc02031ba:	10a60613          	addi	a2,a2,266 # ffffffffc02062c0 <commands+0x818>
ffffffffc02031be:	24c00593          	li	a1,588
ffffffffc02031c2:	00003517          	auipc	a0,0x3
ffffffffc02031c6:	5fe50513          	addi	a0,a0,1534 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02031ca:	ac8fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02031ce:	00004697          	auipc	a3,0x4
ffffffffc02031d2:	aea68693          	addi	a3,a3,-1302 # ffffffffc0206cb8 <default_pmm_manager+0x648>
ffffffffc02031d6:	00003617          	auipc	a2,0x3
ffffffffc02031da:	0ea60613          	addi	a2,a2,234 # ffffffffc02062c0 <commands+0x818>
ffffffffc02031de:	24b00593          	li	a1,587
ffffffffc02031e2:	00003517          	auipc	a0,0x3
ffffffffc02031e6:	5de50513          	addi	a0,a0,1502 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02031ea:	aa8fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02031ee:	00003617          	auipc	a2,0x3
ffffffffc02031f2:	56260613          	addi	a2,a2,1378 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc02031f6:	0c900593          	li	a1,201
ffffffffc02031fa:	00003517          	auipc	a0,0x3
ffffffffc02031fe:	5c650513          	addi	a0,a0,1478 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc0203202:	a90fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203206:	00003617          	auipc	a2,0x3
ffffffffc020320a:	54a60613          	addi	a2,a2,1354 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc020320e:	08100593          	li	a1,129
ffffffffc0203212:	00003517          	auipc	a0,0x3
ffffffffc0203216:	5ae50513          	addi	a0,a0,1454 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020321a:	a78fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020321e:	00003697          	auipc	a3,0x3
ffffffffc0203222:	76a68693          	addi	a3,a3,1898 # ffffffffc0206988 <default_pmm_manager+0x318>
ffffffffc0203226:	00003617          	auipc	a2,0x3
ffffffffc020322a:	09a60613          	addi	a2,a2,154 # ffffffffc02062c0 <commands+0x818>
ffffffffc020322e:	20b00593          	li	a1,523
ffffffffc0203232:	00003517          	auipc	a0,0x3
ffffffffc0203236:	58e50513          	addi	a0,a0,1422 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020323a:	a58fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020323e:	00003697          	auipc	a3,0x3
ffffffffc0203242:	71a68693          	addi	a3,a3,1818 # ffffffffc0206958 <default_pmm_manager+0x2e8>
ffffffffc0203246:	00003617          	auipc	a2,0x3
ffffffffc020324a:	07a60613          	addi	a2,a2,122 # ffffffffc02062c0 <commands+0x818>
ffffffffc020324e:	20800593          	li	a1,520
ffffffffc0203252:	00003517          	auipc	a0,0x3
ffffffffc0203256:	56e50513          	addi	a0,a0,1390 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020325a:	a38fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020325e <copy_range>:
{
ffffffffc020325e:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203260:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203264:	f486                	sd	ra,104(sp)
ffffffffc0203266:	f0a2                	sd	s0,96(sp)
ffffffffc0203268:	eca6                	sd	s1,88(sp)
ffffffffc020326a:	e8ca                	sd	s2,80(sp)
ffffffffc020326c:	e4ce                	sd	s3,72(sp)
ffffffffc020326e:	e0d2                	sd	s4,64(sp)
ffffffffc0203270:	fc56                	sd	s5,56(sp)
ffffffffc0203272:	f85a                	sd	s6,48(sp)
ffffffffc0203274:	f45e                	sd	s7,40(sp)
ffffffffc0203276:	f062                	sd	s8,32(sp)
ffffffffc0203278:	ec66                	sd	s9,24(sp)
ffffffffc020327a:	e86a                	sd	s10,16(sp)
ffffffffc020327c:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020327e:	17d2                	slli	a5,a5,0x34
ffffffffc0203280:	20079f63          	bnez	a5,ffffffffc020349e <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc0203284:	002007b7          	lui	a5,0x200
ffffffffc0203288:	8432                	mv	s0,a2
ffffffffc020328a:	1af66263          	bltu	a2,a5,ffffffffc020342e <copy_range+0x1d0>
ffffffffc020328e:	8936                	mv	s2,a3
ffffffffc0203290:	18d67f63          	bgeu	a2,a3,ffffffffc020342e <copy_range+0x1d0>
ffffffffc0203294:	4785                	li	a5,1
ffffffffc0203296:	07fe                	slli	a5,a5,0x1f
ffffffffc0203298:	18d7eb63          	bltu	a5,a3,ffffffffc020342e <copy_range+0x1d0>
ffffffffc020329c:	5b7d                	li	s6,-1
ffffffffc020329e:	8aaa                	mv	s5,a0
ffffffffc02032a0:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02032a2:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02032a4:	000c4c17          	auipc	s8,0xc4
ffffffffc02032a8:	984c0c13          	addi	s8,s8,-1660 # ffffffffc02c6c28 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02032ac:	000c4b97          	auipc	s7,0xc4
ffffffffc02032b0:	984b8b93          	addi	s7,s7,-1660 # ffffffffc02c6c30 <pages>
    return KADDR(page2pa(page));
ffffffffc02032b4:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02032b8:	000c4c97          	auipc	s9,0xc4
ffffffffc02032bc:	980c8c93          	addi	s9,s9,-1664 # ffffffffc02c6c38 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02032c0:	4601                	li	a2,0
ffffffffc02032c2:	85a2                	mv	a1,s0
ffffffffc02032c4:	854e                	mv	a0,s3
ffffffffc02032c6:	b73fe0ef          	jal	ra,ffffffffc0201e38 <get_pte>
ffffffffc02032ca:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02032cc:	0e050c63          	beqz	a0,ffffffffc02033c4 <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc02032d0:	611c                	ld	a5,0(a0)
ffffffffc02032d2:	8b85                	andi	a5,a5,1
ffffffffc02032d4:	e785                	bnez	a5,ffffffffc02032fc <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02032d6:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02032d8:	ff2464e3          	bltu	s0,s2,ffffffffc02032c0 <copy_range+0x62>
    return 0;
ffffffffc02032dc:	4501                	li	a0,0
}
ffffffffc02032de:	70a6                	ld	ra,104(sp)
ffffffffc02032e0:	7406                	ld	s0,96(sp)
ffffffffc02032e2:	64e6                	ld	s1,88(sp)
ffffffffc02032e4:	6946                	ld	s2,80(sp)
ffffffffc02032e6:	69a6                	ld	s3,72(sp)
ffffffffc02032e8:	6a06                	ld	s4,64(sp)
ffffffffc02032ea:	7ae2                	ld	s5,56(sp)
ffffffffc02032ec:	7b42                	ld	s6,48(sp)
ffffffffc02032ee:	7ba2                	ld	s7,40(sp)
ffffffffc02032f0:	7c02                	ld	s8,32(sp)
ffffffffc02032f2:	6ce2                	ld	s9,24(sp)
ffffffffc02032f4:	6d42                	ld	s10,16(sp)
ffffffffc02032f6:	6da2                	ld	s11,8(sp)
ffffffffc02032f8:	6165                	addi	sp,sp,112
ffffffffc02032fa:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02032fc:	4605                	li	a2,1
ffffffffc02032fe:	85a2                	mv	a1,s0
ffffffffc0203300:	8556                	mv	a0,s5
ffffffffc0203302:	b37fe0ef          	jal	ra,ffffffffc0201e38 <get_pte>
ffffffffc0203306:	c56d                	beqz	a0,ffffffffc02033f0 <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203308:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc020330a:	0017f713          	andi	a4,a5,1
ffffffffc020330e:	01f7f493          	andi	s1,a5,31
ffffffffc0203312:	16070a63          	beqz	a4,ffffffffc0203486 <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc0203316:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020331a:	078a                	slli	a5,a5,0x2
ffffffffc020331c:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203320:	14d77763          	bgeu	a4,a3,ffffffffc020346e <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc0203324:	000bb783          	ld	a5,0(s7)
ffffffffc0203328:	fff806b7          	lui	a3,0xfff80
ffffffffc020332c:	9736                	add	a4,a4,a3
ffffffffc020332e:	071a                	slli	a4,a4,0x6
ffffffffc0203330:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203334:	10002773          	csrr	a4,sstatus
ffffffffc0203338:	8b09                	andi	a4,a4,2
ffffffffc020333a:	e345                	bnez	a4,ffffffffc02033da <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc020333c:	000cb703          	ld	a4,0(s9)
ffffffffc0203340:	4505                	li	a0,1
ffffffffc0203342:	6f18                	ld	a4,24(a4)
ffffffffc0203344:	9702                	jalr	a4
ffffffffc0203346:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203348:	0c0d8363          	beqz	s11,ffffffffc020340e <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc020334c:	100d0163          	beqz	s10,ffffffffc020344e <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc0203350:	000bb703          	ld	a4,0(s7)
ffffffffc0203354:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203358:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc020335c:	40ed86b3          	sub	a3,s11,a4
ffffffffc0203360:	8699                	srai	a3,a3,0x6
ffffffffc0203362:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0203364:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203368:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020336a:	08c7f663          	bgeu	a5,a2,ffffffffc02033f6 <copy_range+0x198>
    return page - pages + nbase;
ffffffffc020336e:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc0203372:	000c4717          	auipc	a4,0xc4
ffffffffc0203376:	8ce70713          	addi	a4,a4,-1842 # ffffffffc02c6c40 <va_pa_offset>
ffffffffc020337a:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc020337c:	8799                	srai	a5,a5,0x6
ffffffffc020337e:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0203380:	0167f733          	and	a4,a5,s6
ffffffffc0203384:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203388:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020338a:	06c77563          	bgeu	a4,a2,ffffffffc02033f4 <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020338e:	6605                	lui	a2,0x1
ffffffffc0203390:	953e                	add	a0,a0,a5
ffffffffc0203392:	494020ef          	jal	ra,ffffffffc0205826 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc0203396:	86a6                	mv	a3,s1
ffffffffc0203398:	8622                	mv	a2,s0
ffffffffc020339a:	85ea                	mv	a1,s10
ffffffffc020339c:	8556                	mv	a0,s5
ffffffffc020339e:	98aff0ef          	jal	ra,ffffffffc0202528 <page_insert>
            assert(ret == 0);
ffffffffc02033a2:	d915                	beqz	a0,ffffffffc02032d6 <copy_range+0x78>
ffffffffc02033a4:	00004697          	auipc	a3,0x4
ffffffffc02033a8:	a2c68693          	addi	a3,a3,-1492 # ffffffffc0206dd0 <default_pmm_manager+0x760>
ffffffffc02033ac:	00003617          	auipc	a2,0x3
ffffffffc02033b0:	f1460613          	addi	a2,a2,-236 # ffffffffc02062c0 <commands+0x818>
ffffffffc02033b4:	1a000593          	li	a1,416
ffffffffc02033b8:	00003517          	auipc	a0,0x3
ffffffffc02033bc:	40850513          	addi	a0,a0,1032 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02033c0:	8d2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02033c4:	00200637          	lui	a2,0x200
ffffffffc02033c8:	9432                	add	s0,s0,a2
ffffffffc02033ca:	ffe00637          	lui	a2,0xffe00
ffffffffc02033ce:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02033d0:	f00406e3          	beqz	s0,ffffffffc02032dc <copy_range+0x7e>
ffffffffc02033d4:	ef2466e3          	bltu	s0,s2,ffffffffc02032c0 <copy_range+0x62>
ffffffffc02033d8:	b711                	j	ffffffffc02032dc <copy_range+0x7e>
        intr_disable();
ffffffffc02033da:	dd4fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02033de:	000cb703          	ld	a4,0(s9)
ffffffffc02033e2:	4505                	li	a0,1
ffffffffc02033e4:	6f18                	ld	a4,24(a4)
ffffffffc02033e6:	9702                	jalr	a4
ffffffffc02033e8:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02033ea:	dbefd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02033ee:	bfa9                	j	ffffffffc0203348 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc02033f0:	5571                	li	a0,-4
ffffffffc02033f2:	b5f5                	j	ffffffffc02032de <copy_range+0x80>
ffffffffc02033f4:	86be                	mv	a3,a5
ffffffffc02033f6:	00003617          	auipc	a2,0x3
ffffffffc02033fa:	2b260613          	addi	a2,a2,690 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc02033fe:	07100593          	li	a1,113
ffffffffc0203402:	00003517          	auipc	a0,0x3
ffffffffc0203406:	2ce50513          	addi	a0,a0,718 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc020340a:	888fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(page != NULL);
ffffffffc020340e:	00004697          	auipc	a3,0x4
ffffffffc0203412:	9a268693          	addi	a3,a3,-1630 # ffffffffc0206db0 <default_pmm_manager+0x740>
ffffffffc0203416:	00003617          	auipc	a2,0x3
ffffffffc020341a:	eaa60613          	addi	a2,a2,-342 # ffffffffc02062c0 <commands+0x818>
ffffffffc020341e:	19600593          	li	a1,406
ffffffffc0203422:	00003517          	auipc	a0,0x3
ffffffffc0203426:	39e50513          	addi	a0,a0,926 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020342a:	868fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020342e:	00003697          	auipc	a3,0x3
ffffffffc0203432:	3d268693          	addi	a3,a3,978 # ffffffffc0206800 <default_pmm_manager+0x190>
ffffffffc0203436:	00003617          	auipc	a2,0x3
ffffffffc020343a:	e8a60613          	addi	a2,a2,-374 # ffffffffc02062c0 <commands+0x818>
ffffffffc020343e:	17e00593          	li	a1,382
ffffffffc0203442:	00003517          	auipc	a0,0x3
ffffffffc0203446:	37e50513          	addi	a0,a0,894 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020344a:	848fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(npage != NULL);
ffffffffc020344e:	00004697          	auipc	a3,0x4
ffffffffc0203452:	97268693          	addi	a3,a3,-1678 # ffffffffc0206dc0 <default_pmm_manager+0x750>
ffffffffc0203456:	00003617          	auipc	a2,0x3
ffffffffc020345a:	e6a60613          	addi	a2,a2,-406 # ffffffffc02062c0 <commands+0x818>
ffffffffc020345e:	19700593          	li	a1,407
ffffffffc0203462:	00003517          	auipc	a0,0x3
ffffffffc0203466:	35e50513          	addi	a0,a0,862 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020346a:	828fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020346e:	00003617          	auipc	a2,0x3
ffffffffc0203472:	30a60613          	addi	a2,a2,778 # ffffffffc0206778 <default_pmm_manager+0x108>
ffffffffc0203476:	06900593          	li	a1,105
ffffffffc020347a:	00003517          	auipc	a0,0x3
ffffffffc020347e:	25650513          	addi	a0,a0,598 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0203482:	810fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203486:	00003617          	auipc	a2,0x3
ffffffffc020348a:	31260613          	addi	a2,a2,786 # ffffffffc0206798 <default_pmm_manager+0x128>
ffffffffc020348e:	07f00593          	li	a1,127
ffffffffc0203492:	00003517          	auipc	a0,0x3
ffffffffc0203496:	23e50513          	addi	a0,a0,574 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc020349a:	ff9fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020349e:	00003697          	auipc	a3,0x3
ffffffffc02034a2:	33268693          	addi	a3,a3,818 # ffffffffc02067d0 <default_pmm_manager+0x160>
ffffffffc02034a6:	00003617          	auipc	a2,0x3
ffffffffc02034aa:	e1a60613          	addi	a2,a2,-486 # ffffffffc02062c0 <commands+0x818>
ffffffffc02034ae:	17d00593          	li	a1,381
ffffffffc02034b2:	00003517          	auipc	a0,0x3
ffffffffc02034b6:	30e50513          	addi	a0,a0,782 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc02034ba:	fd9fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02034be <pgdir_alloc_page>:
{
ffffffffc02034be:	7179                	addi	sp,sp,-48
ffffffffc02034c0:	ec26                	sd	s1,24(sp)
ffffffffc02034c2:	e84a                	sd	s2,16(sp)
ffffffffc02034c4:	e052                	sd	s4,0(sp)
ffffffffc02034c6:	f406                	sd	ra,40(sp)
ffffffffc02034c8:	f022                	sd	s0,32(sp)
ffffffffc02034ca:	e44e                	sd	s3,8(sp)
ffffffffc02034cc:	8a2a                	mv	s4,a0
ffffffffc02034ce:	84ae                	mv	s1,a1
ffffffffc02034d0:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034d2:	100027f3          	csrr	a5,sstatus
ffffffffc02034d6:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02034d8:	000c3997          	auipc	s3,0xc3
ffffffffc02034dc:	76098993          	addi	s3,s3,1888 # ffffffffc02c6c38 <pmm_manager>
ffffffffc02034e0:	ef8d                	bnez	a5,ffffffffc020351a <pgdir_alloc_page+0x5c>
ffffffffc02034e2:	0009b783          	ld	a5,0(s3)
ffffffffc02034e6:	4505                	li	a0,1
ffffffffc02034e8:	6f9c                	ld	a5,24(a5)
ffffffffc02034ea:	9782                	jalr	a5
ffffffffc02034ec:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02034ee:	cc09                	beqz	s0,ffffffffc0203508 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02034f0:	86ca                	mv	a3,s2
ffffffffc02034f2:	8626                	mv	a2,s1
ffffffffc02034f4:	85a2                	mv	a1,s0
ffffffffc02034f6:	8552                	mv	a0,s4
ffffffffc02034f8:	830ff0ef          	jal	ra,ffffffffc0202528 <page_insert>
ffffffffc02034fc:	e915                	bnez	a0,ffffffffc0203530 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02034fe:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203500:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203502:	4785                	li	a5,1
ffffffffc0203504:	04f71e63          	bne	a4,a5,ffffffffc0203560 <pgdir_alloc_page+0xa2>
}
ffffffffc0203508:	70a2                	ld	ra,40(sp)
ffffffffc020350a:	8522                	mv	a0,s0
ffffffffc020350c:	7402                	ld	s0,32(sp)
ffffffffc020350e:	64e2                	ld	s1,24(sp)
ffffffffc0203510:	6942                	ld	s2,16(sp)
ffffffffc0203512:	69a2                	ld	s3,8(sp)
ffffffffc0203514:	6a02                	ld	s4,0(sp)
ffffffffc0203516:	6145                	addi	sp,sp,48
ffffffffc0203518:	8082                	ret
        intr_disable();
ffffffffc020351a:	c94fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020351e:	0009b783          	ld	a5,0(s3)
ffffffffc0203522:	4505                	li	a0,1
ffffffffc0203524:	6f9c                	ld	a5,24(a5)
ffffffffc0203526:	9782                	jalr	a5
ffffffffc0203528:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020352a:	c7efd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020352e:	b7c1                	j	ffffffffc02034ee <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203530:	100027f3          	csrr	a5,sstatus
ffffffffc0203534:	8b89                	andi	a5,a5,2
ffffffffc0203536:	eb89                	bnez	a5,ffffffffc0203548 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203538:	0009b783          	ld	a5,0(s3)
ffffffffc020353c:	8522                	mv	a0,s0
ffffffffc020353e:	4585                	li	a1,1
ffffffffc0203540:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203542:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203544:	9782                	jalr	a5
    if (flag)
ffffffffc0203546:	b7c9                	j	ffffffffc0203508 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203548:	c66fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020354c:	0009b783          	ld	a5,0(s3)
ffffffffc0203550:	8522                	mv	a0,s0
ffffffffc0203552:	4585                	li	a1,1
ffffffffc0203554:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203556:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203558:	9782                	jalr	a5
        intr_enable();
ffffffffc020355a:	c4efd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020355e:	b76d                	j	ffffffffc0203508 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203560:	00004697          	auipc	a3,0x4
ffffffffc0203564:	88068693          	addi	a3,a3,-1920 # ffffffffc0206de0 <default_pmm_manager+0x770>
ffffffffc0203568:	00003617          	auipc	a2,0x3
ffffffffc020356c:	d5860613          	addi	a2,a2,-680 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203570:	1e900593          	li	a1,489
ffffffffc0203574:	00003517          	auipc	a0,0x3
ffffffffc0203578:	24c50513          	addi	a0,a0,588 # ffffffffc02067c0 <default_pmm_manager+0x150>
ffffffffc020357c:	f17fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203580 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203580:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203582:	00004697          	auipc	a3,0x4
ffffffffc0203586:	87668693          	addi	a3,a3,-1930 # ffffffffc0206df8 <default_pmm_manager+0x788>
ffffffffc020358a:	00003617          	auipc	a2,0x3
ffffffffc020358e:	d3660613          	addi	a2,a2,-714 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203592:	07400593          	li	a1,116
ffffffffc0203596:	00004517          	auipc	a0,0x4
ffffffffc020359a:	88250513          	addi	a0,a0,-1918 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020359e:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02035a0:	ef3fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02035a4 <mm_create>:
{
ffffffffc02035a4:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035a6:	04000513          	li	a0,64
{
ffffffffc02035aa:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035ac:	df6fe0ef          	jal	ra,ffffffffc0201ba2 <kmalloc>
    if (mm != NULL)
ffffffffc02035b0:	cd19                	beqz	a0,ffffffffc02035ce <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02035b2:	e508                	sd	a0,8(a0)
ffffffffc02035b4:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02035b6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02035ba:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02035be:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02035c2:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02035c6:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02035ca:	02053c23          	sd	zero,56(a0)
}
ffffffffc02035ce:	60a2                	ld	ra,8(sp)
ffffffffc02035d0:	0141                	addi	sp,sp,16
ffffffffc02035d2:	8082                	ret

ffffffffc02035d4 <find_vma>:
{
ffffffffc02035d4:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02035d6:	c505                	beqz	a0,ffffffffc02035fe <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02035d8:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02035da:	c501                	beqz	a0,ffffffffc02035e2 <find_vma+0xe>
ffffffffc02035dc:	651c                	ld	a5,8(a0)
ffffffffc02035de:	02f5f263          	bgeu	a1,a5,ffffffffc0203602 <find_vma+0x2e>
    return listelm->next;
ffffffffc02035e2:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02035e4:	00f68d63          	beq	a3,a5,ffffffffc02035fe <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02035e8:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f38d0>
ffffffffc02035ec:	00e5e663          	bltu	a1,a4,ffffffffc02035f8 <find_vma+0x24>
ffffffffc02035f0:	ff07b703          	ld	a4,-16(a5)
ffffffffc02035f4:	00e5ec63          	bltu	a1,a4,ffffffffc020360c <find_vma+0x38>
ffffffffc02035f8:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02035fa:	fef697e3          	bne	a3,a5,ffffffffc02035e8 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02035fe:	4501                	li	a0,0
}
ffffffffc0203600:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203602:	691c                	ld	a5,16(a0)
ffffffffc0203604:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02035e2 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203608:	ea88                	sd	a0,16(a3)
ffffffffc020360a:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc020360c:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203610:	ea88                	sd	a0,16(a3)
ffffffffc0203612:	8082                	ret

ffffffffc0203614 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203614:	6590                	ld	a2,8(a1)
ffffffffc0203616:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_matrix_out_size+0x738f8>
{
ffffffffc020361a:	1141                	addi	sp,sp,-16
ffffffffc020361c:	e406                	sd	ra,8(sp)
ffffffffc020361e:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203620:	01066763          	bltu	a2,a6,ffffffffc020362e <insert_vma_struct+0x1a>
ffffffffc0203624:	a085                	j	ffffffffc0203684 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203626:	fe87b703          	ld	a4,-24(a5)
ffffffffc020362a:	04e66863          	bltu	a2,a4,ffffffffc020367a <insert_vma_struct+0x66>
ffffffffc020362e:	86be                	mv	a3,a5
ffffffffc0203630:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203632:	fef51ae3          	bne	a0,a5,ffffffffc0203626 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203636:	02a68463          	beq	a3,a0,ffffffffc020365e <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020363a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020363e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203642:	08e8f163          	bgeu	a7,a4,ffffffffc02036c4 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203646:	04e66f63          	bltu	a2,a4,ffffffffc02036a4 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc020364a:	00f50a63          	beq	a0,a5,ffffffffc020365e <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020364e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203652:	05076963          	bltu	a4,a6,ffffffffc02036a4 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203656:	ff07b603          	ld	a2,-16(a5)
ffffffffc020365a:	02c77363          	bgeu	a4,a2,ffffffffc0203680 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020365e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203660:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203662:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203666:	e390                	sd	a2,0(a5)
ffffffffc0203668:	e690                	sd	a2,8(a3)
}
ffffffffc020366a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020366c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020366e:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203670:	0017079b          	addiw	a5,a4,1
ffffffffc0203674:	d11c                	sw	a5,32(a0)
}
ffffffffc0203676:	0141                	addi	sp,sp,16
ffffffffc0203678:	8082                	ret
    if (le_prev != list)
ffffffffc020367a:	fca690e3          	bne	a3,a0,ffffffffc020363a <insert_vma_struct+0x26>
ffffffffc020367e:	bfd1                	j	ffffffffc0203652 <insert_vma_struct+0x3e>
ffffffffc0203680:	f01ff0ef          	jal	ra,ffffffffc0203580 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203684:	00003697          	auipc	a3,0x3
ffffffffc0203688:	7a468693          	addi	a3,a3,1956 # ffffffffc0206e28 <default_pmm_manager+0x7b8>
ffffffffc020368c:	00003617          	auipc	a2,0x3
ffffffffc0203690:	c3460613          	addi	a2,a2,-972 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203694:	07a00593          	li	a1,122
ffffffffc0203698:	00003517          	auipc	a0,0x3
ffffffffc020369c:	78050513          	addi	a0,a0,1920 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc02036a0:	df3fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036a4:	00003697          	auipc	a3,0x3
ffffffffc02036a8:	7c468693          	addi	a3,a3,1988 # ffffffffc0206e68 <default_pmm_manager+0x7f8>
ffffffffc02036ac:	00003617          	auipc	a2,0x3
ffffffffc02036b0:	c1460613          	addi	a2,a2,-1004 # ffffffffc02062c0 <commands+0x818>
ffffffffc02036b4:	07300593          	li	a1,115
ffffffffc02036b8:	00003517          	auipc	a0,0x3
ffffffffc02036bc:	76050513          	addi	a0,a0,1888 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc02036c0:	dd3fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036c4:	00003697          	auipc	a3,0x3
ffffffffc02036c8:	78468693          	addi	a3,a3,1924 # ffffffffc0206e48 <default_pmm_manager+0x7d8>
ffffffffc02036cc:	00003617          	auipc	a2,0x3
ffffffffc02036d0:	bf460613          	addi	a2,a2,-1036 # ffffffffc02062c0 <commands+0x818>
ffffffffc02036d4:	07200593          	li	a1,114
ffffffffc02036d8:	00003517          	auipc	a0,0x3
ffffffffc02036dc:	74050513          	addi	a0,a0,1856 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc02036e0:	db3fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02036e4 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02036e4:	591c                	lw	a5,48(a0)
{
ffffffffc02036e6:	1141                	addi	sp,sp,-16
ffffffffc02036e8:	e406                	sd	ra,8(sp)
ffffffffc02036ea:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02036ec:	e78d                	bnez	a5,ffffffffc0203716 <mm_destroy+0x32>
ffffffffc02036ee:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02036f0:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02036f2:	00a40c63          	beq	s0,a0,ffffffffc020370a <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02036f6:	6118                	ld	a4,0(a0)
ffffffffc02036f8:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02036fa:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02036fc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02036fe:	e398                	sd	a4,0(a5)
ffffffffc0203700:	d52fe0ef          	jal	ra,ffffffffc0201c52 <kfree>
    return listelm->next;
ffffffffc0203704:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203706:	fea418e3          	bne	s0,a0,ffffffffc02036f6 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020370a:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020370c:	6402                	ld	s0,0(sp)
ffffffffc020370e:	60a2                	ld	ra,8(sp)
ffffffffc0203710:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203712:	d40fe06f          	j	ffffffffc0201c52 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203716:	00003697          	auipc	a3,0x3
ffffffffc020371a:	77268693          	addi	a3,a3,1906 # ffffffffc0206e88 <default_pmm_manager+0x818>
ffffffffc020371e:	00003617          	auipc	a2,0x3
ffffffffc0203722:	ba260613          	addi	a2,a2,-1118 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203726:	09e00593          	li	a1,158
ffffffffc020372a:	00003517          	auipc	a0,0x3
ffffffffc020372e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203732:	d61fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203736 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203736:	7139                	addi	sp,sp,-64
ffffffffc0203738:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020373a:	6405                	lui	s0,0x1
ffffffffc020373c:	147d                	addi	s0,s0,-1
ffffffffc020373e:	77fd                	lui	a5,0xfffff
ffffffffc0203740:	9622                	add	a2,a2,s0
ffffffffc0203742:	962e                	add	a2,a2,a1
{
ffffffffc0203744:	f426                	sd	s1,40(sp)
ffffffffc0203746:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203748:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc020374c:	f04a                	sd	s2,32(sp)
ffffffffc020374e:	ec4e                	sd	s3,24(sp)
ffffffffc0203750:	e852                	sd	s4,16(sp)
ffffffffc0203752:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203754:	002005b7          	lui	a1,0x200
ffffffffc0203758:	00f67433          	and	s0,a2,a5
ffffffffc020375c:	06b4e363          	bltu	s1,a1,ffffffffc02037c2 <mm_map+0x8c>
ffffffffc0203760:	0684f163          	bgeu	s1,s0,ffffffffc02037c2 <mm_map+0x8c>
ffffffffc0203764:	4785                	li	a5,1
ffffffffc0203766:	07fe                	slli	a5,a5,0x1f
ffffffffc0203768:	0487ed63          	bltu	a5,s0,ffffffffc02037c2 <mm_map+0x8c>
ffffffffc020376c:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020376e:	cd21                	beqz	a0,ffffffffc02037c6 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203770:	85a6                	mv	a1,s1
ffffffffc0203772:	8ab6                	mv	s5,a3
ffffffffc0203774:	8a3a                	mv	s4,a4
ffffffffc0203776:	e5fff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
ffffffffc020377a:	c501                	beqz	a0,ffffffffc0203782 <mm_map+0x4c>
ffffffffc020377c:	651c                	ld	a5,8(a0)
ffffffffc020377e:	0487e263          	bltu	a5,s0,ffffffffc02037c2 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203782:	03000513          	li	a0,48
ffffffffc0203786:	c1cfe0ef          	jal	ra,ffffffffc0201ba2 <kmalloc>
ffffffffc020378a:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020378c:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020378e:	02090163          	beqz	s2,ffffffffc02037b0 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203792:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203794:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203798:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc020379c:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02037a0:	85ca                	mv	a1,s2
ffffffffc02037a2:	e73ff0ef          	jal	ra,ffffffffc0203614 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02037a6:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02037a8:	000a0463          	beqz	s4,ffffffffc02037b0 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02037ac:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>

out:
    return ret;
}
ffffffffc02037b0:	70e2                	ld	ra,56(sp)
ffffffffc02037b2:	7442                	ld	s0,48(sp)
ffffffffc02037b4:	74a2                	ld	s1,40(sp)
ffffffffc02037b6:	7902                	ld	s2,32(sp)
ffffffffc02037b8:	69e2                	ld	s3,24(sp)
ffffffffc02037ba:	6a42                	ld	s4,16(sp)
ffffffffc02037bc:	6aa2                	ld	s5,8(sp)
ffffffffc02037be:	6121                	addi	sp,sp,64
ffffffffc02037c0:	8082                	ret
        return -E_INVAL;
ffffffffc02037c2:	5575                	li	a0,-3
ffffffffc02037c4:	b7f5                	j	ffffffffc02037b0 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02037c6:	00003697          	auipc	a3,0x3
ffffffffc02037ca:	6da68693          	addi	a3,a3,1754 # ffffffffc0206ea0 <default_pmm_manager+0x830>
ffffffffc02037ce:	00003617          	auipc	a2,0x3
ffffffffc02037d2:	af260613          	addi	a2,a2,-1294 # ffffffffc02062c0 <commands+0x818>
ffffffffc02037d6:	0b300593          	li	a1,179
ffffffffc02037da:	00003517          	auipc	a0,0x3
ffffffffc02037de:	63e50513          	addi	a0,a0,1598 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc02037e2:	cb1fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02037e6 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02037e6:	7139                	addi	sp,sp,-64
ffffffffc02037e8:	fc06                	sd	ra,56(sp)
ffffffffc02037ea:	f822                	sd	s0,48(sp)
ffffffffc02037ec:	f426                	sd	s1,40(sp)
ffffffffc02037ee:	f04a                	sd	s2,32(sp)
ffffffffc02037f0:	ec4e                	sd	s3,24(sp)
ffffffffc02037f2:	e852                	sd	s4,16(sp)
ffffffffc02037f4:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02037f6:	c52d                	beqz	a0,ffffffffc0203860 <dup_mmap+0x7a>
ffffffffc02037f8:	892a                	mv	s2,a0
ffffffffc02037fa:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02037fc:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02037fe:	e595                	bnez	a1,ffffffffc020382a <dup_mmap+0x44>
ffffffffc0203800:	a085                	j	ffffffffc0203860 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203802:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203804:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f38f0>
        vma->vm_end = vm_end;
ffffffffc0203808:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020380c:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203810:	e05ff0ef          	jal	ra,ffffffffc0203614 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203814:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f50>
ffffffffc0203818:	fe843603          	ld	a2,-24(s0)
ffffffffc020381c:	6c8c                	ld	a1,24(s1)
ffffffffc020381e:	01893503          	ld	a0,24(s2)
ffffffffc0203822:	4701                	li	a4,0
ffffffffc0203824:	a3bff0ef          	jal	ra,ffffffffc020325e <copy_range>
ffffffffc0203828:	e105                	bnez	a0,ffffffffc0203848 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020382a:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc020382c:	02848863          	beq	s1,s0,ffffffffc020385c <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203830:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203834:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203838:	ff043a03          	ld	s4,-16(s0)
ffffffffc020383c:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203840:	b62fe0ef          	jal	ra,ffffffffc0201ba2 <kmalloc>
ffffffffc0203844:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203846:	fd55                	bnez	a0,ffffffffc0203802 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203848:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020384a:	70e2                	ld	ra,56(sp)
ffffffffc020384c:	7442                	ld	s0,48(sp)
ffffffffc020384e:	74a2                	ld	s1,40(sp)
ffffffffc0203850:	7902                	ld	s2,32(sp)
ffffffffc0203852:	69e2                	ld	s3,24(sp)
ffffffffc0203854:	6a42                	ld	s4,16(sp)
ffffffffc0203856:	6aa2                	ld	s5,8(sp)
ffffffffc0203858:	6121                	addi	sp,sp,64
ffffffffc020385a:	8082                	ret
    return 0;
ffffffffc020385c:	4501                	li	a0,0
ffffffffc020385e:	b7f5                	j	ffffffffc020384a <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203860:	00003697          	auipc	a3,0x3
ffffffffc0203864:	65068693          	addi	a3,a3,1616 # ffffffffc0206eb0 <default_pmm_manager+0x840>
ffffffffc0203868:	00003617          	auipc	a2,0x3
ffffffffc020386c:	a5860613          	addi	a2,a2,-1448 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203870:	0cf00593          	li	a1,207
ffffffffc0203874:	00003517          	auipc	a0,0x3
ffffffffc0203878:	5a450513          	addi	a0,a0,1444 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc020387c:	c17fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203880 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203880:	1101                	addi	sp,sp,-32
ffffffffc0203882:	ec06                	sd	ra,24(sp)
ffffffffc0203884:	e822                	sd	s0,16(sp)
ffffffffc0203886:	e426                	sd	s1,8(sp)
ffffffffc0203888:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020388a:	c531                	beqz	a0,ffffffffc02038d6 <exit_mmap+0x56>
ffffffffc020388c:	591c                	lw	a5,48(a0)
ffffffffc020388e:	84aa                	mv	s1,a0
ffffffffc0203890:	e3b9                	bnez	a5,ffffffffc02038d6 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203892:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203894:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203898:	02850663          	beq	a0,s0,ffffffffc02038c4 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020389c:	ff043603          	ld	a2,-16(s0)
ffffffffc02038a0:	fe843583          	ld	a1,-24(s0)
ffffffffc02038a4:	854a                	mv	a0,s2
ffffffffc02038a6:	80ffe0ef          	jal	ra,ffffffffc02020b4 <unmap_range>
ffffffffc02038aa:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038ac:	fe8498e3          	bne	s1,s0,ffffffffc020389c <exit_mmap+0x1c>
ffffffffc02038b0:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02038b2:	00848c63          	beq	s1,s0,ffffffffc02038ca <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038b6:	ff043603          	ld	a2,-16(s0)
ffffffffc02038ba:	fe843583          	ld	a1,-24(s0)
ffffffffc02038be:	854a                	mv	a0,s2
ffffffffc02038c0:	93bfe0ef          	jal	ra,ffffffffc02021fa <exit_range>
ffffffffc02038c4:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038c6:	fe8498e3          	bne	s1,s0,ffffffffc02038b6 <exit_mmap+0x36>
    }
}
ffffffffc02038ca:	60e2                	ld	ra,24(sp)
ffffffffc02038cc:	6442                	ld	s0,16(sp)
ffffffffc02038ce:	64a2                	ld	s1,8(sp)
ffffffffc02038d0:	6902                	ld	s2,0(sp)
ffffffffc02038d2:	6105                	addi	sp,sp,32
ffffffffc02038d4:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038d6:	00003697          	auipc	a3,0x3
ffffffffc02038da:	5fa68693          	addi	a3,a3,1530 # ffffffffc0206ed0 <default_pmm_manager+0x860>
ffffffffc02038de:	00003617          	auipc	a2,0x3
ffffffffc02038e2:	9e260613          	addi	a2,a2,-1566 # ffffffffc02062c0 <commands+0x818>
ffffffffc02038e6:	0e800593          	li	a1,232
ffffffffc02038ea:	00003517          	auipc	a0,0x3
ffffffffc02038ee:	52e50513          	addi	a0,a0,1326 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc02038f2:	ba1fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02038f6 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02038f6:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038f8:	04000513          	li	a0,64
{
ffffffffc02038fc:	fc06                	sd	ra,56(sp)
ffffffffc02038fe:	f822                	sd	s0,48(sp)
ffffffffc0203900:	f426                	sd	s1,40(sp)
ffffffffc0203902:	f04a                	sd	s2,32(sp)
ffffffffc0203904:	ec4e                	sd	s3,24(sp)
ffffffffc0203906:	e852                	sd	s4,16(sp)
ffffffffc0203908:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020390a:	a98fe0ef          	jal	ra,ffffffffc0201ba2 <kmalloc>
    if (mm != NULL)
ffffffffc020390e:	2e050663          	beqz	a0,ffffffffc0203bfa <vmm_init+0x304>
ffffffffc0203912:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203914:	e508                	sd	a0,8(a0)
ffffffffc0203916:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203918:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020391c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203920:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203924:	02053423          	sd	zero,40(a0)
ffffffffc0203928:	02052823          	sw	zero,48(a0)
ffffffffc020392c:	02053c23          	sd	zero,56(a0)
ffffffffc0203930:	03200413          	li	s0,50
ffffffffc0203934:	a811                	j	ffffffffc0203948 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203936:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203938:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020393a:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc020393e:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203940:	8526                	mv	a0,s1
ffffffffc0203942:	cd3ff0ef          	jal	ra,ffffffffc0203614 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203946:	c80d                	beqz	s0,ffffffffc0203978 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203948:	03000513          	li	a0,48
ffffffffc020394c:	a56fe0ef          	jal	ra,ffffffffc0201ba2 <kmalloc>
ffffffffc0203950:	85aa                	mv	a1,a0
ffffffffc0203952:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203956:	f165                	bnez	a0,ffffffffc0203936 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203958:	00003697          	auipc	a3,0x3
ffffffffc020395c:	71068693          	addi	a3,a3,1808 # ffffffffc0207068 <default_pmm_manager+0x9f8>
ffffffffc0203960:	00003617          	auipc	a2,0x3
ffffffffc0203964:	96060613          	addi	a2,a2,-1696 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203968:	12c00593          	li	a1,300
ffffffffc020396c:	00003517          	auipc	a0,0x3
ffffffffc0203970:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203974:	b1ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0203978:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc020397c:	1f900913          	li	s2,505
ffffffffc0203980:	a819                	j	ffffffffc0203996 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203982:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203984:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203986:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc020398a:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020398c:	8526                	mv	a0,s1
ffffffffc020398e:	c87ff0ef          	jal	ra,ffffffffc0203614 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203992:	03240a63          	beq	s0,s2,ffffffffc02039c6 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203996:	03000513          	li	a0,48
ffffffffc020399a:	a08fe0ef          	jal	ra,ffffffffc0201ba2 <kmalloc>
ffffffffc020399e:	85aa                	mv	a1,a0
ffffffffc02039a0:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02039a4:	fd79                	bnez	a0,ffffffffc0203982 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc02039a6:	00003697          	auipc	a3,0x3
ffffffffc02039aa:	6c268693          	addi	a3,a3,1730 # ffffffffc0207068 <default_pmm_manager+0x9f8>
ffffffffc02039ae:	00003617          	auipc	a2,0x3
ffffffffc02039b2:	91260613          	addi	a2,a2,-1774 # ffffffffc02062c0 <commands+0x818>
ffffffffc02039b6:	13300593          	li	a1,307
ffffffffc02039ba:	00003517          	auipc	a0,0x3
ffffffffc02039be:	45e50513          	addi	a0,a0,1118 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc02039c2:	ad1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc02039c6:	649c                	ld	a5,8(s1)
ffffffffc02039c8:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02039ca:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02039ce:	16f48663          	beq	s1,a5,ffffffffc0203b3a <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02039d2:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd38370>
ffffffffc02039d6:	ffe70693          	addi	a3,a4,-2
ffffffffc02039da:	10d61063          	bne	a2,a3,ffffffffc0203ada <vmm_init+0x1e4>
ffffffffc02039de:	ff07b683          	ld	a3,-16(a5)
ffffffffc02039e2:	0ed71c63          	bne	a4,a3,ffffffffc0203ada <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc02039e6:	0715                	addi	a4,a4,5
ffffffffc02039e8:	679c                	ld	a5,8(a5)
ffffffffc02039ea:	feb712e3          	bne	a4,a1,ffffffffc02039ce <vmm_init+0xd8>
ffffffffc02039ee:	4a1d                	li	s4,7
ffffffffc02039f0:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02039f2:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02039f6:	85a2                	mv	a1,s0
ffffffffc02039f8:	8526                	mv	a0,s1
ffffffffc02039fa:	bdbff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
ffffffffc02039fe:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203a00:	16050d63          	beqz	a0,ffffffffc0203b7a <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a04:	00140593          	addi	a1,s0,1
ffffffffc0203a08:	8526                	mv	a0,s1
ffffffffc0203a0a:	bcbff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
ffffffffc0203a0e:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a10:	14050563          	beqz	a0,ffffffffc0203b5a <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a14:	85d2                	mv	a1,s4
ffffffffc0203a16:	8526                	mv	a0,s1
ffffffffc0203a18:	bbdff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a1c:	16051f63          	bnez	a0,ffffffffc0203b9a <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a20:	00340593          	addi	a1,s0,3
ffffffffc0203a24:	8526                	mv	a0,s1
ffffffffc0203a26:	bafff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a2a:	1a051863          	bnez	a0,ffffffffc0203bda <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a2e:	00440593          	addi	a1,s0,4
ffffffffc0203a32:	8526                	mv	a0,s1
ffffffffc0203a34:	ba1ff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203a38:	18051163          	bnez	a0,ffffffffc0203bba <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a3c:	00893783          	ld	a5,8(s2)
ffffffffc0203a40:	0a879d63          	bne	a5,s0,ffffffffc0203afa <vmm_init+0x204>
ffffffffc0203a44:	01093783          	ld	a5,16(s2)
ffffffffc0203a48:	0b479963          	bne	a5,s4,ffffffffc0203afa <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a4c:	0089b783          	ld	a5,8(s3)
ffffffffc0203a50:	0c879563          	bne	a5,s0,ffffffffc0203b1a <vmm_init+0x224>
ffffffffc0203a54:	0109b783          	ld	a5,16(s3)
ffffffffc0203a58:	0d479163          	bne	a5,s4,ffffffffc0203b1a <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a5c:	0415                	addi	s0,s0,5
ffffffffc0203a5e:	0a15                	addi	s4,s4,5
ffffffffc0203a60:	f9541be3          	bne	s0,s5,ffffffffc02039f6 <vmm_init+0x100>
ffffffffc0203a64:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a66:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a68:	85a2                	mv	a1,s0
ffffffffc0203a6a:	8526                	mv	a0,s1
ffffffffc0203a6c:	b69ff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
ffffffffc0203a70:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203a74:	c90d                	beqz	a0,ffffffffc0203aa6 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203a76:	6914                	ld	a3,16(a0)
ffffffffc0203a78:	6510                	ld	a2,8(a0)
ffffffffc0203a7a:	00003517          	auipc	a0,0x3
ffffffffc0203a7e:	57650513          	addi	a0,a0,1398 # ffffffffc0206ff0 <default_pmm_manager+0x980>
ffffffffc0203a82:	f16fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203a86:	00003697          	auipc	a3,0x3
ffffffffc0203a8a:	59268693          	addi	a3,a3,1426 # ffffffffc0207018 <default_pmm_manager+0x9a8>
ffffffffc0203a8e:	00003617          	auipc	a2,0x3
ffffffffc0203a92:	83260613          	addi	a2,a2,-1998 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203a96:	15900593          	li	a1,345
ffffffffc0203a9a:	00003517          	auipc	a0,0x3
ffffffffc0203a9e:	37e50513          	addi	a0,a0,894 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203aa2:	9f1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203aa6:	147d                	addi	s0,s0,-1
ffffffffc0203aa8:	fd2410e3          	bne	s0,s2,ffffffffc0203a68 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203aac:	8526                	mv	a0,s1
ffffffffc0203aae:	c37ff0ef          	jal	ra,ffffffffc02036e4 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ab2:	00003517          	auipc	a0,0x3
ffffffffc0203ab6:	57e50513          	addi	a0,a0,1406 # ffffffffc0207030 <default_pmm_manager+0x9c0>
ffffffffc0203aba:	edefc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0203abe:	7442                	ld	s0,48(sp)
ffffffffc0203ac0:	70e2                	ld	ra,56(sp)
ffffffffc0203ac2:	74a2                	ld	s1,40(sp)
ffffffffc0203ac4:	7902                	ld	s2,32(sp)
ffffffffc0203ac6:	69e2                	ld	s3,24(sp)
ffffffffc0203ac8:	6a42                	ld	s4,16(sp)
ffffffffc0203aca:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203acc:	00003517          	auipc	a0,0x3
ffffffffc0203ad0:	58450513          	addi	a0,a0,1412 # ffffffffc0207050 <default_pmm_manager+0x9e0>
}
ffffffffc0203ad4:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ad6:	ec2fc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ada:	00003697          	auipc	a3,0x3
ffffffffc0203ade:	42e68693          	addi	a3,a3,1070 # ffffffffc0206f08 <default_pmm_manager+0x898>
ffffffffc0203ae2:	00002617          	auipc	a2,0x2
ffffffffc0203ae6:	7de60613          	addi	a2,a2,2014 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203aea:	13d00593          	li	a1,317
ffffffffc0203aee:	00003517          	auipc	a0,0x3
ffffffffc0203af2:	32a50513          	addi	a0,a0,810 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203af6:	99dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203afa:	00003697          	auipc	a3,0x3
ffffffffc0203afe:	49668693          	addi	a3,a3,1174 # ffffffffc0206f90 <default_pmm_manager+0x920>
ffffffffc0203b02:	00002617          	auipc	a2,0x2
ffffffffc0203b06:	7be60613          	addi	a2,a2,1982 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203b0a:	14e00593          	li	a1,334
ffffffffc0203b0e:	00003517          	auipc	a0,0x3
ffffffffc0203b12:	30a50513          	addi	a0,a0,778 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203b16:	97dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b1a:	00003697          	auipc	a3,0x3
ffffffffc0203b1e:	4a668693          	addi	a3,a3,1190 # ffffffffc0206fc0 <default_pmm_manager+0x950>
ffffffffc0203b22:	00002617          	auipc	a2,0x2
ffffffffc0203b26:	79e60613          	addi	a2,a2,1950 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203b2a:	14f00593          	li	a1,335
ffffffffc0203b2e:	00003517          	auipc	a0,0x3
ffffffffc0203b32:	2ea50513          	addi	a0,a0,746 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203b36:	95dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b3a:	00003697          	auipc	a3,0x3
ffffffffc0203b3e:	3b668693          	addi	a3,a3,950 # ffffffffc0206ef0 <default_pmm_manager+0x880>
ffffffffc0203b42:	00002617          	auipc	a2,0x2
ffffffffc0203b46:	77e60613          	addi	a2,a2,1918 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203b4a:	13b00593          	li	a1,315
ffffffffc0203b4e:	00003517          	auipc	a0,0x3
ffffffffc0203b52:	2ca50513          	addi	a0,a0,714 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203b56:	93dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203b5a:	00003697          	auipc	a3,0x3
ffffffffc0203b5e:	3f668693          	addi	a3,a3,1014 # ffffffffc0206f50 <default_pmm_manager+0x8e0>
ffffffffc0203b62:	00002617          	auipc	a2,0x2
ffffffffc0203b66:	75e60613          	addi	a2,a2,1886 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203b6a:	14600593          	li	a1,326
ffffffffc0203b6e:	00003517          	auipc	a0,0x3
ffffffffc0203b72:	2aa50513          	addi	a0,a0,682 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203b76:	91dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203b7a:	00003697          	auipc	a3,0x3
ffffffffc0203b7e:	3c668693          	addi	a3,a3,966 # ffffffffc0206f40 <default_pmm_manager+0x8d0>
ffffffffc0203b82:	00002617          	auipc	a2,0x2
ffffffffc0203b86:	73e60613          	addi	a2,a2,1854 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203b8a:	14400593          	li	a1,324
ffffffffc0203b8e:	00003517          	auipc	a0,0x3
ffffffffc0203b92:	28a50513          	addi	a0,a0,650 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203b96:	8fdfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203b9a:	00003697          	auipc	a3,0x3
ffffffffc0203b9e:	3c668693          	addi	a3,a3,966 # ffffffffc0206f60 <default_pmm_manager+0x8f0>
ffffffffc0203ba2:	00002617          	auipc	a2,0x2
ffffffffc0203ba6:	71e60613          	addi	a2,a2,1822 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203baa:	14800593          	li	a1,328
ffffffffc0203bae:	00003517          	auipc	a0,0x3
ffffffffc0203bb2:	26a50513          	addi	a0,a0,618 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203bb6:	8ddfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203bba:	00003697          	auipc	a3,0x3
ffffffffc0203bbe:	3c668693          	addi	a3,a3,966 # ffffffffc0206f80 <default_pmm_manager+0x910>
ffffffffc0203bc2:	00002617          	auipc	a2,0x2
ffffffffc0203bc6:	6fe60613          	addi	a2,a2,1790 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203bca:	14c00593          	li	a1,332
ffffffffc0203bce:	00003517          	auipc	a0,0x3
ffffffffc0203bd2:	24a50513          	addi	a0,a0,586 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203bd6:	8bdfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203bda:	00003697          	auipc	a3,0x3
ffffffffc0203bde:	39668693          	addi	a3,a3,918 # ffffffffc0206f70 <default_pmm_manager+0x900>
ffffffffc0203be2:	00002617          	auipc	a2,0x2
ffffffffc0203be6:	6de60613          	addi	a2,a2,1758 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203bea:	14a00593          	li	a1,330
ffffffffc0203bee:	00003517          	auipc	a0,0x3
ffffffffc0203bf2:	22a50513          	addi	a0,a0,554 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203bf6:	89dfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203bfa:	00003697          	auipc	a3,0x3
ffffffffc0203bfe:	2a668693          	addi	a3,a3,678 # ffffffffc0206ea0 <default_pmm_manager+0x830>
ffffffffc0203c02:	00002617          	auipc	a2,0x2
ffffffffc0203c06:	6be60613          	addi	a2,a2,1726 # ffffffffc02062c0 <commands+0x818>
ffffffffc0203c0a:	12400593          	li	a1,292
ffffffffc0203c0e:	00003517          	auipc	a0,0x3
ffffffffc0203c12:	20a50513          	addi	a0,a0,522 # ffffffffc0206e18 <default_pmm_manager+0x7a8>
ffffffffc0203c16:	87dfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203c1a <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203c1a:	7179                	addi	sp,sp,-48
ffffffffc0203c1c:	f022                	sd	s0,32(sp)
ffffffffc0203c1e:	f406                	sd	ra,40(sp)
ffffffffc0203c20:	ec26                	sd	s1,24(sp)
ffffffffc0203c22:	e84a                	sd	s2,16(sp)
ffffffffc0203c24:	e44e                	sd	s3,8(sp)
ffffffffc0203c26:	e052                	sd	s4,0(sp)
ffffffffc0203c28:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203c2a:	c135                	beqz	a0,ffffffffc0203c8e <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203c2c:	002007b7          	lui	a5,0x200
ffffffffc0203c30:	04f5e663          	bltu	a1,a5,ffffffffc0203c7c <user_mem_check+0x62>
ffffffffc0203c34:	00c584b3          	add	s1,a1,a2
ffffffffc0203c38:	0495f263          	bgeu	a1,s1,ffffffffc0203c7c <user_mem_check+0x62>
ffffffffc0203c3c:	4785                	li	a5,1
ffffffffc0203c3e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203c40:	0297ee63          	bltu	a5,s1,ffffffffc0203c7c <user_mem_check+0x62>
ffffffffc0203c44:	892a                	mv	s2,a0
ffffffffc0203c46:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c48:	6a05                	lui	s4,0x1
ffffffffc0203c4a:	a821                	j	ffffffffc0203c62 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c4c:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c50:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c52:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c54:	c685                	beqz	a3,ffffffffc0203c7c <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c56:	c399                	beqz	a5,ffffffffc0203c5c <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c58:	02e46263          	bltu	s0,a4,ffffffffc0203c7c <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203c5c:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203c5e:	04947663          	bgeu	s0,s1,ffffffffc0203caa <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203c62:	85a2                	mv	a1,s0
ffffffffc0203c64:	854a                	mv	a0,s2
ffffffffc0203c66:	96fff0ef          	jal	ra,ffffffffc02035d4 <find_vma>
ffffffffc0203c6a:	c909                	beqz	a0,ffffffffc0203c7c <user_mem_check+0x62>
ffffffffc0203c6c:	6518                	ld	a4,8(a0)
ffffffffc0203c6e:	00e46763          	bltu	s0,a4,ffffffffc0203c7c <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c72:	4d1c                	lw	a5,24(a0)
ffffffffc0203c74:	fc099ce3          	bnez	s3,ffffffffc0203c4c <user_mem_check+0x32>
ffffffffc0203c78:	8b85                	andi	a5,a5,1
ffffffffc0203c7a:	f3ed                	bnez	a5,ffffffffc0203c5c <user_mem_check+0x42>
            return 0;
ffffffffc0203c7c:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203c7e:	70a2                	ld	ra,40(sp)
ffffffffc0203c80:	7402                	ld	s0,32(sp)
ffffffffc0203c82:	64e2                	ld	s1,24(sp)
ffffffffc0203c84:	6942                	ld	s2,16(sp)
ffffffffc0203c86:	69a2                	ld	s3,8(sp)
ffffffffc0203c88:	6a02                	ld	s4,0(sp)
ffffffffc0203c8a:	6145                	addi	sp,sp,48
ffffffffc0203c8c:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203c8e:	c02007b7          	lui	a5,0xc0200
ffffffffc0203c92:	4501                	li	a0,0
ffffffffc0203c94:	fef5e5e3          	bltu	a1,a5,ffffffffc0203c7e <user_mem_check+0x64>
ffffffffc0203c98:	962e                	add	a2,a2,a1
ffffffffc0203c9a:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203c7e <user_mem_check+0x64>
ffffffffc0203c9e:	c8000537          	lui	a0,0xc8000
ffffffffc0203ca2:	0505                	addi	a0,a0,1
ffffffffc0203ca4:	00a63533          	sltu	a0,a2,a0
ffffffffc0203ca8:	bfd9                	j	ffffffffc0203c7e <user_mem_check+0x64>
        return 1;
ffffffffc0203caa:	4505                	li	a0,1
ffffffffc0203cac:	bfc9                	j	ffffffffc0203c7e <user_mem_check+0x64>

ffffffffc0203cae <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203cae:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203cb0:	9402                	jalr	s0

	jal do_exit
ffffffffc0203cb2:	5de000ef          	jal	ra,ffffffffc0204290 <do_exit>

ffffffffc0203cb6 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203cb6:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cb8:	14800513          	li	a0,328
{
ffffffffc0203cbc:	e022                	sd	s0,0(sp)
ffffffffc0203cbe:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203cc0:	ee3fd0ef          	jal	ra,ffffffffc0201ba2 <kmalloc>
ffffffffc0203cc4:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203cc6:	cd35                	beqz	a0,ffffffffc0203d42 <alloc_proc+0x8c>
    {
        // LAB4:填写你在lab4中实现的代码
        proc->state = PROC_UNINIT;                 // 进程状态 - 未初始化
ffffffffc0203cc8:	57fd                	li	a5,-1
ffffffffc0203cca:	1782                	slli	a5,a5,0x20
ffffffffc0203ccc:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                            // 运行次数 - 还未运行过
        proc->kstack = 0;                          // 内核栈 - 还未分配
        proc->need_resched = 0;                    // 初始不需要重新调度
        proc->parent = NULL;                       // 还没有父进程
        proc->mm = NULL;                           // 内存管理结构 - 还未设置
        memset(&(proc->context), 0, sizeof(struct context));  // 清空上下文
ffffffffc0203cce:	07000613          	li	a2,112
ffffffffc0203cd2:	4581                	li	a1,0
        proc->runs = 0;                            // 运行次数 - 还未运行过
ffffffffc0203cd4:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d39390>
        proc->kstack = 0;                          // 内核栈 - 还未分配
ffffffffc0203cd8:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                    // 初始不需要重新调度
ffffffffc0203cdc:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                       // 还没有父进程
ffffffffc0203ce0:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                           // 内存管理结构 - 还未设置
ffffffffc0203ce4:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));  // 清空上下文
ffffffffc0203ce8:	03050513          	addi	a0,a0,48
ffffffffc0203cec:	329010ef          	jal	ra,ffffffffc0205814 <memset>
        proc->tf = NULL;                           // 中断帧 - 还未设置
        proc->pgdir = boot_pgdir_pa;              // 初始使用启动页目录
ffffffffc0203cf0:	000c3797          	auipc	a5,0xc3
ffffffffc0203cf4:	f287b783          	ld	a5,-216(a5) # ffffffffc02c6c18 <boot_pgdir_pa>
ffffffffc0203cf8:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;                           // 中断帧 - 还未设置
ffffffffc0203cfa:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                           // 没有设置标志
ffffffffc0203cfe:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 清空进程名
ffffffffc0203d02:	4641                	li	a2,16
ffffffffc0203d04:	4581                	li	a1,0
ffffffffc0203d06:	0b440513          	addi	a0,s0,180
ffffffffc0203d0a:	30b010ef          	jal	ra,ffffffffc0205814 <memset>
        proc->yptr = NULL;           // younger sibling: 还没有更"年轻"的兄弟
        proc->optr = NULL;           // older sibling: 还没有更"年长"的兄弟

        // LAB6:YOUR CODE (update LAB5 steps)
        proc->rq = NULL;             // 运行队列
        list_init(&(proc->run_link)); // 初始化运行队列链表项
ffffffffc0203d0e:	11040793          	addi	a5,s0,272
        proc->wait_state = 0;        // 0 通常表示不在等待状态
ffffffffc0203d12:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;           // child pointer: 还没有孩子
ffffffffc0203d16:	0e043823          	sd	zero,240(s0)
        proc->yptr = NULL;           // younger sibling: 还没有更"年轻"的兄弟
ffffffffc0203d1a:	0e043c23          	sd	zero,248(s0)
        proc->optr = NULL;           // older sibling: 还没有更"年长"的兄弟
ffffffffc0203d1e:	10043023          	sd	zero,256(s0)
        proc->rq = NULL;             // 运行队列
ffffffffc0203d22:	10043423          	sd	zero,264(s0)
    elm->prev = elm->next = elm;
ffffffffc0203d26:	10f43c23          	sd	a5,280(s0)
ffffffffc0203d2a:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;        // 时间片
ffffffffc0203d2e:	12042023          	sw	zero,288(s0)
        proc->lab6_run_pool.left = proc->lab6_run_pool.right = proc->lab6_run_pool.parent = NULL;
ffffffffc0203d32:	12043423          	sd	zero,296(s0)
ffffffffc0203d36:	12043823          	sd	zero,304(s0)
ffffffffc0203d3a:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;       // stride值
ffffffffc0203d3e:	14043023          	sd	zero,320(s0)
        proc->lab6_priority = 0;     // 优先级
    }
    return proc;
}
ffffffffc0203d42:	60a2                	ld	ra,8(sp)
ffffffffc0203d44:	8522                	mv	a0,s0
ffffffffc0203d46:	6402                	ld	s0,0(sp)
ffffffffc0203d48:	0141                	addi	sp,sp,16
ffffffffc0203d4a:	8082                	ret

ffffffffc0203d4c <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203d4c:	000c3797          	auipc	a5,0xc3
ffffffffc0203d50:	efc7b783          	ld	a5,-260(a5) # ffffffffc02c6c48 <current>
ffffffffc0203d54:	73c8                	ld	a0,160(a5)
ffffffffc0203d56:	968fd06f          	j	ffffffffc0200ebe <forkrets>

ffffffffc0203d5a <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203d5a:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203d5c:	1141                	addi	sp,sp,-16
ffffffffc0203d5e:	e406                	sd	ra,8(sp)
ffffffffc0203d60:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d64:	02f6ee63          	bltu	a3,a5,ffffffffc0203da0 <put_pgdir+0x46>
ffffffffc0203d68:	000c3517          	auipc	a0,0xc3
ffffffffc0203d6c:	ed853503          	ld	a0,-296(a0) # ffffffffc02c6c40 <va_pa_offset>
ffffffffc0203d70:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203d72:	82b1                	srli	a3,a3,0xc
ffffffffc0203d74:	000c3797          	auipc	a5,0xc3
ffffffffc0203d78:	eb47b783          	ld	a5,-332(a5) # ffffffffc02c6c28 <npage>
ffffffffc0203d7c:	02f6fe63          	bgeu	a3,a5,ffffffffc0203db8 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203d80:	00004517          	auipc	a0,0x4
ffffffffc0203d84:	3c053503          	ld	a0,960(a0) # ffffffffc0208140 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203d88:	60a2                	ld	ra,8(sp)
ffffffffc0203d8a:	8e89                	sub	a3,a3,a0
ffffffffc0203d8c:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203d8e:	000c3517          	auipc	a0,0xc3
ffffffffc0203d92:	ea253503          	ld	a0,-350(a0) # ffffffffc02c6c30 <pages>
ffffffffc0203d96:	4585                	li	a1,1
ffffffffc0203d98:	9536                	add	a0,a0,a3
}
ffffffffc0203d9a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203d9c:	822fe06f          	j	ffffffffc0201dbe <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203da0:	00003617          	auipc	a2,0x3
ffffffffc0203da4:	9b060613          	addi	a2,a2,-1616 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc0203da8:	07700593          	li	a1,119
ffffffffc0203dac:	00003517          	auipc	a0,0x3
ffffffffc0203db0:	92450513          	addi	a0,a0,-1756 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0203db4:	edefc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203db8:	00003617          	auipc	a2,0x3
ffffffffc0203dbc:	9c060613          	addi	a2,a2,-1600 # ffffffffc0206778 <default_pmm_manager+0x108>
ffffffffc0203dc0:	06900593          	li	a1,105
ffffffffc0203dc4:	00003517          	auipc	a0,0x3
ffffffffc0203dc8:	90c50513          	addi	a0,a0,-1780 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0203dcc:	ec6fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203dd0 <proc_run>:
{
ffffffffc0203dd0:	7179                	addi	sp,sp,-48
ffffffffc0203dd2:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203dd4:	000c3917          	auipc	s2,0xc3
ffffffffc0203dd8:	e7490913          	addi	s2,s2,-396 # ffffffffc02c6c48 <current>
{
ffffffffc0203ddc:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203dde:	00093483          	ld	s1,0(s2)
{
ffffffffc0203de2:	f406                	sd	ra,40(sp)
ffffffffc0203de4:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203de6:	02a48863          	beq	s1,a0,ffffffffc0203e16 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203dea:	100027f3          	csrr	a5,sstatus
ffffffffc0203dee:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203df0:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203df2:	ef9d                	bnez	a5,ffffffffc0203e30 <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203df4:	755c                	ld	a5,168(a0)
ffffffffc0203df6:	577d                	li	a4,-1
ffffffffc0203df8:	177e                	slli	a4,a4,0x3f
ffffffffc0203dfa:	83b1                	srli	a5,a5,0xc
        current = proc;
ffffffffc0203dfc:	00a93023          	sd	a0,0(s2)
ffffffffc0203e00:	8fd9                	or	a5,a5,a4
ffffffffc0203e02:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(proc->context));
ffffffffc0203e06:	03050593          	addi	a1,a0,48
ffffffffc0203e0a:	03048513          	addi	a0,s1,48
ffffffffc0203e0e:	122010ef          	jal	ra,ffffffffc0204f30 <switch_to>
    if (flag)
ffffffffc0203e12:	00099863          	bnez	s3,ffffffffc0203e22 <proc_run+0x52>
}
ffffffffc0203e16:	70a2                	ld	ra,40(sp)
ffffffffc0203e18:	7482                	ld	s1,32(sp)
ffffffffc0203e1a:	6962                	ld	s2,24(sp)
ffffffffc0203e1c:	69c2                	ld	s3,16(sp)
ffffffffc0203e1e:	6145                	addi	sp,sp,48
ffffffffc0203e20:	8082                	ret
ffffffffc0203e22:	70a2                	ld	ra,40(sp)
ffffffffc0203e24:	7482                	ld	s1,32(sp)
ffffffffc0203e26:	6962                	ld	s2,24(sp)
ffffffffc0203e28:	69c2                	ld	s3,16(sp)
ffffffffc0203e2a:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203e2c:	b7dfc06f          	j	ffffffffc02009a8 <intr_enable>
ffffffffc0203e30:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203e32:	b7dfc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0203e36:	6522                	ld	a0,8(sp)
ffffffffc0203e38:	4985                	li	s3,1
ffffffffc0203e3a:	bf6d                	j	ffffffffc0203df4 <proc_run+0x24>

ffffffffc0203e3c <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0203e3c:	7119                	addi	sp,sp,-128
ffffffffc0203e3e:	f0ca                	sd	s2,96(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e40:	000c3917          	auipc	s2,0xc3
ffffffffc0203e44:	e2090913          	addi	s2,s2,-480 # ffffffffc02c6c60 <nr_process>
ffffffffc0203e48:	00092703          	lw	a4,0(s2)
{
ffffffffc0203e4c:	fc86                	sd	ra,120(sp)
ffffffffc0203e4e:	f8a2                	sd	s0,112(sp)
ffffffffc0203e50:	f4a6                	sd	s1,104(sp)
ffffffffc0203e52:	ecce                	sd	s3,88(sp)
ffffffffc0203e54:	e8d2                	sd	s4,80(sp)
ffffffffc0203e56:	e4d6                	sd	s5,72(sp)
ffffffffc0203e58:	e0da                	sd	s6,64(sp)
ffffffffc0203e5a:	fc5e                	sd	s7,56(sp)
ffffffffc0203e5c:	f862                	sd	s8,48(sp)
ffffffffc0203e5e:	f466                	sd	s9,40(sp)
ffffffffc0203e60:	f06a                	sd	s10,32(sp)
ffffffffc0203e62:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203e64:	6785                	lui	a5,0x1
ffffffffc0203e66:	32f75b63          	bge	a4,a5,ffffffffc020419c <do_fork+0x360>
ffffffffc0203e6a:	8a2a                	mv	s4,a0
ffffffffc0203e6c:	89ae                	mv	s3,a1
ffffffffc0203e6e:	8432                	mv	s0,a2
    ret = -E_NO_MEM;
    // LAB4:填写你在lab4中实现的代码
    // LAB5:填写你在lab5中实现的代码 (update LAB4 steps)
    
    //    1. 调用alloc_proc分配一个proc_struct
    proc = alloc_proc();
ffffffffc0203e70:	e47ff0ef          	jal	ra,ffffffffc0203cb6 <alloc_proc>
ffffffffc0203e74:	84aa                	mv	s1,a0
    if (proc == NULL) {
ffffffffc0203e76:	30050463          	beqz	a0,ffffffffc020417e <do_fork+0x342>
        goto fork_out;
    }
    proc->parent = current;
ffffffffc0203e7a:	000c3c17          	auipc	s8,0xc3
ffffffffc0203e7e:	dcec0c13          	addi	s8,s8,-562 # ffffffffc02c6c48 <current>
ffffffffc0203e82:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0203e86:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8e54>
    proc->parent = current;
ffffffffc0203e8a:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0203e8c:	30071d63          	bnez	a4,ffffffffc02041a6 <do_fork+0x36a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203e90:	4509                	li	a0,2
ffffffffc0203e92:	eeffd0ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
    if (page != NULL)
ffffffffc0203e96:	2e050163          	beqz	a0,ffffffffc0204178 <do_fork+0x33c>
    return page - pages + nbase;
ffffffffc0203e9a:	000c3a97          	auipc	s5,0xc3
ffffffffc0203e9e:	d96a8a93          	addi	s5,s5,-618 # ffffffffc02c6c30 <pages>
ffffffffc0203ea2:	000ab683          	ld	a3,0(s5)
ffffffffc0203ea6:	00004b17          	auipc	s6,0x4
ffffffffc0203eaa:	29ab0b13          	addi	s6,s6,666 # ffffffffc0208140 <nbase>
ffffffffc0203eae:	000b3783          	ld	a5,0(s6)
ffffffffc0203eb2:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203eb6:	000c3b97          	auipc	s7,0xc3
ffffffffc0203eba:	d72b8b93          	addi	s7,s7,-654 # ffffffffc02c6c28 <npage>
    return page - pages + nbase;
ffffffffc0203ebe:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203ec0:	5dfd                	li	s11,-1
ffffffffc0203ec2:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0203ec6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203ec8:	00cddd93          	srli	s11,s11,0xc
ffffffffc0203ecc:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0203ed0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203ed2:	2ee67a63          	bgeu	a2,a4,ffffffffc02041c6 <do_fork+0x38a>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203ed6:	000c3603          	ld	a2,0(s8)
ffffffffc0203eda:	000c3c17          	auipc	s8,0xc3
ffffffffc0203ede:	d66c0c13          	addi	s8,s8,-666 # ffffffffc02c6c40 <va_pa_offset>
ffffffffc0203ee2:	000c3703          	ld	a4,0(s8)
ffffffffc0203ee6:	02863d03          	ld	s10,40(a2)
ffffffffc0203eea:	e43e                	sd	a5,8(sp)
ffffffffc0203eec:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203eee:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0203ef0:	020d0863          	beqz	s10,ffffffffc0203f20 <do_fork+0xe4>
    if (clone_flags & CLONE_VM)
ffffffffc0203ef4:	100a7a13          	andi	s4,s4,256
ffffffffc0203ef8:	1c0a0163          	beqz	s4,ffffffffc02040ba <do_fork+0x27e>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203efc:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f00:	018d3783          	ld	a5,24(s10)
ffffffffc0203f04:	c02006b7          	lui	a3,0xc0200
ffffffffc0203f08:	2705                	addiw	a4,a4,1
ffffffffc0203f0a:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0203f0e:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f12:	2ed7e263          	bltu	a5,a3,ffffffffc02041f6 <do_fork+0x3ba>
ffffffffc0203f16:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f1a:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f1c:	8f99                	sub	a5,a5,a4
ffffffffc0203f1e:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f20:	6789                	lui	a5,0x2
ffffffffc0203f22:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8060>
ffffffffc0203f26:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0203f28:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f2a:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0203f2c:	87b6                	mv	a5,a3
ffffffffc0203f2e:	12040893          	addi	a7,s0,288
ffffffffc0203f32:	00063803          	ld	a6,0(a2)
ffffffffc0203f36:	6608                	ld	a0,8(a2)
ffffffffc0203f38:	6a0c                	ld	a1,16(a2)
ffffffffc0203f3a:	6e18                	ld	a4,24(a2)
ffffffffc0203f3c:	0107b023          	sd	a6,0(a5)
ffffffffc0203f40:	e788                	sd	a0,8(a5)
ffffffffc0203f42:	eb8c                	sd	a1,16(a5)
ffffffffc0203f44:	ef98                	sd	a4,24(a5)
ffffffffc0203f46:	02060613          	addi	a2,a2,32
ffffffffc0203f4a:	02078793          	addi	a5,a5,32
ffffffffc0203f4e:	ff1612e3          	bne	a2,a7,ffffffffc0203f32 <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc0203f52:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203f56:	12098f63          	beqz	s3,ffffffffc0204094 <do_fork+0x258>
ffffffffc0203f5a:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203f5e:	00000797          	auipc	a5,0x0
ffffffffc0203f62:	dee78793          	addi	a5,a5,-530 # ffffffffc0203d4c <forkret>
ffffffffc0203f66:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203f68:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f6a:	100027f3          	csrr	a5,sstatus
ffffffffc0203f6e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f70:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f72:	14079063          	bnez	a5,ffffffffc02040b2 <do_fork+0x276>
    if (++last_pid >= MAX_PID)
ffffffffc0203f76:	000bf817          	auipc	a6,0xbf
ffffffffc0203f7a:	81a80813          	addi	a6,a6,-2022 # ffffffffc02c2790 <last_pid.1>
ffffffffc0203f7e:	00082783          	lw	a5,0(a6)
ffffffffc0203f82:	6709                	lui	a4,0x2
ffffffffc0203f84:	0017851b          	addiw	a0,a5,1
ffffffffc0203f88:	00a82023          	sw	a0,0(a6)
ffffffffc0203f8c:	08e55d63          	bge	a0,a4,ffffffffc0204026 <do_fork+0x1ea>
    if (last_pid >= next_safe)
ffffffffc0203f90:	000bf317          	auipc	t1,0xbf
ffffffffc0203f94:	80430313          	addi	t1,t1,-2044 # ffffffffc02c2794 <next_safe.0>
ffffffffc0203f98:	00032783          	lw	a5,0(t1)
ffffffffc0203f9c:	000c3417          	auipc	s0,0xc3
ffffffffc0203fa0:	c1440413          	addi	s0,s0,-1004 # ffffffffc02c6bb0 <proc_list>
ffffffffc0203fa4:	08f55963          	bge	a0,a5,ffffffffc0204036 <do_fork+0x1fa>
    
    //    5. 将proc_struct插入hash_list和proc_list，设置进程关系链接
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
ffffffffc0203fa8:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203faa:	45a9                	li	a1,10
ffffffffc0203fac:	2501                	sext.w	a0,a0
ffffffffc0203fae:	3c0010ef          	jal	ra,ffffffffc020536e <hash32>
ffffffffc0203fb2:	02051793          	slli	a5,a0,0x20
ffffffffc0203fb6:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203fba:	000bf797          	auipc	a5,0xbf
ffffffffc0203fbe:	bf678793          	addi	a5,a5,-1034 # ffffffffc02c2bb0 <hash_list>
ffffffffc0203fc2:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0203fc4:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203fc6:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203fc8:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0203fcc:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203fce:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0203fd0:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203fd2:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0203fd4:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0203fd8:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0203fda:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0203fdc:	e21c                	sd	a5,0(a2)
ffffffffc0203fde:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0203fe0:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0203fe2:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0203fe4:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203fe8:	10e4b023          	sd	a4,256(s1)
ffffffffc0203fec:	c311                	beqz	a4,ffffffffc0203ff0 <do_fork+0x1b4>
        proc->optr->yptr = proc;
ffffffffc0203fee:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0203ff0:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0203ff4:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0203ff6:	2785                	addiw	a5,a5,1
ffffffffc0203ff8:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc0203ffc:	18099363          	bnez	s3,ffffffffc0204182 <do_fork+0x346>
        set_links(proc);
    }
    local_intr_restore(intr_flag);
    
    //    6. 调用wakeup_proc使新子进程变为RUNNABLE
    wakeup_proc(proc);
ffffffffc0204000:	8526                	mv	a0,s1
ffffffffc0204002:	0fa010ef          	jal	ra,ffffffffc02050fc <wakeup_proc>
    
    //    7. 使用子进程的pid设置返回值
    ret = proc->pid;
ffffffffc0204006:	40c8                	lw	a0,4(s1)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc0204008:	70e6                	ld	ra,120(sp)
ffffffffc020400a:	7446                	ld	s0,112(sp)
ffffffffc020400c:	74a6                	ld	s1,104(sp)
ffffffffc020400e:	7906                	ld	s2,96(sp)
ffffffffc0204010:	69e6                	ld	s3,88(sp)
ffffffffc0204012:	6a46                	ld	s4,80(sp)
ffffffffc0204014:	6aa6                	ld	s5,72(sp)
ffffffffc0204016:	6b06                	ld	s6,64(sp)
ffffffffc0204018:	7be2                	ld	s7,56(sp)
ffffffffc020401a:	7c42                	ld	s8,48(sp)
ffffffffc020401c:	7ca2                	ld	s9,40(sp)
ffffffffc020401e:	7d02                	ld	s10,32(sp)
ffffffffc0204020:	6de2                	ld	s11,24(sp)
ffffffffc0204022:	6109                	addi	sp,sp,128
ffffffffc0204024:	8082                	ret
        last_pid = 1;
ffffffffc0204026:	4785                	li	a5,1
ffffffffc0204028:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020402c:	4505                	li	a0,1
ffffffffc020402e:	000be317          	auipc	t1,0xbe
ffffffffc0204032:	76630313          	addi	t1,t1,1894 # ffffffffc02c2794 <next_safe.0>
    return listelm->next;
ffffffffc0204036:	000c3417          	auipc	s0,0xc3
ffffffffc020403a:	b7a40413          	addi	s0,s0,-1158 # ffffffffc02c6bb0 <proc_list>
ffffffffc020403e:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204042:	6789                	lui	a5,0x2
ffffffffc0204044:	00f32023          	sw	a5,0(t1)
ffffffffc0204048:	86aa                	mv	a3,a0
ffffffffc020404a:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020404c:	6e89                	lui	t4,0x2
ffffffffc020404e:	148e0263          	beq	t3,s0,ffffffffc0204192 <do_fork+0x356>
ffffffffc0204052:	88ae                	mv	a7,a1
ffffffffc0204054:	87f2                	mv	a5,t3
ffffffffc0204056:	6609                	lui	a2,0x2
ffffffffc0204058:	a811                	j	ffffffffc020406c <do_fork+0x230>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020405a:	00e6d663          	bge	a3,a4,ffffffffc0204066 <do_fork+0x22a>
ffffffffc020405e:	00c75463          	bge	a4,a2,ffffffffc0204066 <do_fork+0x22a>
ffffffffc0204062:	863a                	mv	a2,a4
ffffffffc0204064:	4885                	li	a7,1
ffffffffc0204066:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204068:	00878d63          	beq	a5,s0,ffffffffc0204082 <do_fork+0x246>
            if (proc->pid == last_pid)
ffffffffc020406c:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x8004>
ffffffffc0204070:	fed715e3          	bne	a4,a3,ffffffffc020405a <do_fork+0x21e>
                if (++last_pid >= next_safe)
ffffffffc0204074:	2685                	addiw	a3,a3,1
ffffffffc0204076:	10c6d963          	bge	a3,a2,ffffffffc0204188 <do_fork+0x34c>
ffffffffc020407a:	679c                	ld	a5,8(a5)
ffffffffc020407c:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020407e:	fe8797e3          	bne	a5,s0,ffffffffc020406c <do_fork+0x230>
ffffffffc0204082:	c581                	beqz	a1,ffffffffc020408a <do_fork+0x24e>
ffffffffc0204084:	00d82023          	sw	a3,0(a6)
ffffffffc0204088:	8536                	mv	a0,a3
ffffffffc020408a:	f0088fe3          	beqz	a7,ffffffffc0203fa8 <do_fork+0x16c>
ffffffffc020408e:	00c32023          	sw	a2,0(t1)
ffffffffc0204092:	bf19                	j	ffffffffc0203fa8 <do_fork+0x16c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204094:	89b6                	mv	s3,a3
ffffffffc0204096:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020409a:	00000797          	auipc	a5,0x0
ffffffffc020409e:	cb278793          	addi	a5,a5,-846 # ffffffffc0203d4c <forkret>
ffffffffc02040a2:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02040a4:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040a6:	100027f3          	csrr	a5,sstatus
ffffffffc02040aa:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040ac:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040ae:	ec0784e3          	beqz	a5,ffffffffc0203f76 <do_fork+0x13a>
        intr_disable();
ffffffffc02040b2:	8fdfc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02040b6:	4985                	li	s3,1
ffffffffc02040b8:	bd7d                	j	ffffffffc0203f76 <do_fork+0x13a>
    if ((mm = mm_create()) == NULL)
ffffffffc02040ba:	ceaff0ef          	jal	ra,ffffffffc02035a4 <mm_create>
ffffffffc02040be:	8caa                	mv	s9,a0
ffffffffc02040c0:	c541                	beqz	a0,ffffffffc0204148 <do_fork+0x30c>
    if ((page = alloc_page()) == NULL)
ffffffffc02040c2:	4505                	li	a0,1
ffffffffc02040c4:	cbdfd0ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc02040c8:	cd2d                	beqz	a0,ffffffffc0204142 <do_fork+0x306>
    return page - pages + nbase;
ffffffffc02040ca:	000ab683          	ld	a3,0(s5)
ffffffffc02040ce:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02040d0:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02040d4:	40d506b3          	sub	a3,a0,a3
ffffffffc02040d8:	8699                	srai	a3,a3,0x6
ffffffffc02040da:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02040dc:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02040e0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040e2:	0eedf263          	bgeu	s11,a4,ffffffffc02041c6 <do_fork+0x38a>
ffffffffc02040e6:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02040ea:	6605                	lui	a2,0x1
ffffffffc02040ec:	000c3597          	auipc	a1,0xc3
ffffffffc02040f0:	b345b583          	ld	a1,-1228(a1) # ffffffffc02c6c20 <boot_pgdir_va>
ffffffffc02040f4:	9a36                	add	s4,s4,a3
ffffffffc02040f6:	8552                	mv	a0,s4
ffffffffc02040f8:	72e010ef          	jal	ra,ffffffffc0205826 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02040fc:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204100:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204104:	4785                	li	a5,1
ffffffffc0204106:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020410a:	8b85                	andi	a5,a5,1
ffffffffc020410c:	4a05                	li	s4,1
ffffffffc020410e:	c799                	beqz	a5,ffffffffc020411c <do_fork+0x2e0>
    {
        schedule();
ffffffffc0204110:	09e010ef          	jal	ra,ffffffffc02051ae <schedule>
ffffffffc0204114:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc0204118:	8b85                	andi	a5,a5,1
ffffffffc020411a:	fbfd                	bnez	a5,ffffffffc0204110 <do_fork+0x2d4>
        ret = dup_mmap(mm, oldmm);
ffffffffc020411c:	85ea                	mv	a1,s10
ffffffffc020411e:	8566                	mv	a0,s9
ffffffffc0204120:	ec6ff0ef          	jal	ra,ffffffffc02037e6 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204124:	57f9                	li	a5,-2
ffffffffc0204126:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020412a:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020412c:	0e078e63          	beqz	a5,ffffffffc0204228 <do_fork+0x3ec>
good_mm:
ffffffffc0204130:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204132:	dc0505e3          	beqz	a0,ffffffffc0203efc <do_fork+0xc0>
    exit_mmap(mm);
ffffffffc0204136:	8566                	mv	a0,s9
ffffffffc0204138:	f48ff0ef          	jal	ra,ffffffffc0203880 <exit_mmap>
    put_pgdir(mm);
ffffffffc020413c:	8566                	mv	a0,s9
ffffffffc020413e:	c1dff0ef          	jal	ra,ffffffffc0203d5a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204142:	8566                	mv	a0,s9
ffffffffc0204144:	da0ff0ef          	jal	ra,ffffffffc02036e4 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204148:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020414a:	c02007b7          	lui	a5,0xc0200
ffffffffc020414e:	0cf6e163          	bltu	a3,a5,ffffffffc0204210 <do_fork+0x3d4>
ffffffffc0204152:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204156:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020415a:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020415e:	83b1                	srli	a5,a5,0xc
ffffffffc0204160:	06e7ff63          	bgeu	a5,a4,ffffffffc02041de <do_fork+0x3a2>
    return &pages[PPN(pa) - nbase];
ffffffffc0204164:	000b3703          	ld	a4,0(s6)
ffffffffc0204168:	000ab503          	ld	a0,0(s5)
ffffffffc020416c:	4589                	li	a1,2
ffffffffc020416e:	8f99                	sub	a5,a5,a4
ffffffffc0204170:	079a                	slli	a5,a5,0x6
ffffffffc0204172:	953e                	add	a0,a0,a5
ffffffffc0204174:	c4bfd0ef          	jal	ra,ffffffffc0201dbe <free_pages>
    kfree(proc);
ffffffffc0204178:	8526                	mv	a0,s1
ffffffffc020417a:	ad9fd0ef          	jal	ra,ffffffffc0201c52 <kfree>
    ret = -E_NO_MEM;
ffffffffc020417e:	5571                	li	a0,-4
    return ret;
ffffffffc0204180:	b561                	j	ffffffffc0204008 <do_fork+0x1cc>
        intr_enable();
ffffffffc0204182:	827fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204186:	bdad                	j	ffffffffc0204000 <do_fork+0x1c4>
                    if (last_pid >= MAX_PID)
ffffffffc0204188:	01d6c363          	blt	a3,t4,ffffffffc020418e <do_fork+0x352>
                        last_pid = 1;
ffffffffc020418c:	4685                	li	a3,1
                    goto repeat;
ffffffffc020418e:	4585                	li	a1,1
ffffffffc0204190:	bd7d                	j	ffffffffc020404e <do_fork+0x212>
ffffffffc0204192:	c599                	beqz	a1,ffffffffc02041a0 <do_fork+0x364>
ffffffffc0204194:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204198:	8536                	mv	a0,a3
ffffffffc020419a:	b539                	j	ffffffffc0203fa8 <do_fork+0x16c>
    int ret = -E_NO_FREE_PROC;
ffffffffc020419c:	556d                	li	a0,-5
ffffffffc020419e:	b5ad                	j	ffffffffc0204008 <do_fork+0x1cc>
    return last_pid;
ffffffffc02041a0:	00082503          	lw	a0,0(a6)
ffffffffc02041a4:	b511                	j	ffffffffc0203fa8 <do_fork+0x16c>
    assert(current->wait_state == 0);
ffffffffc02041a6:	00003697          	auipc	a3,0x3
ffffffffc02041aa:	ed268693          	addi	a3,a3,-302 # ffffffffc0207078 <default_pmm_manager+0xa08>
ffffffffc02041ae:	00002617          	auipc	a2,0x2
ffffffffc02041b2:	11260613          	addi	a2,a2,274 # ffffffffc02062c0 <commands+0x818>
ffffffffc02041b6:	1b100593          	li	a1,433
ffffffffc02041ba:	00003517          	auipc	a0,0x3
ffffffffc02041be:	ede50513          	addi	a0,a0,-290 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc02041c2:	ad0fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc02041c6:	00002617          	auipc	a2,0x2
ffffffffc02041ca:	4e260613          	addi	a2,a2,1250 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc02041ce:	07100593          	li	a1,113
ffffffffc02041d2:	00002517          	auipc	a0,0x2
ffffffffc02041d6:	4fe50513          	addi	a0,a0,1278 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc02041da:	ab8fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02041de:	00002617          	auipc	a2,0x2
ffffffffc02041e2:	59a60613          	addi	a2,a2,1434 # ffffffffc0206778 <default_pmm_manager+0x108>
ffffffffc02041e6:	06900593          	li	a1,105
ffffffffc02041ea:	00002517          	auipc	a0,0x2
ffffffffc02041ee:	4e650513          	addi	a0,a0,1254 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc02041f2:	aa0fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02041f6:	86be                	mv	a3,a5
ffffffffc02041f8:	00002617          	auipc	a2,0x2
ffffffffc02041fc:	55860613          	addi	a2,a2,1368 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc0204200:	17f00593          	li	a1,383
ffffffffc0204204:	00003517          	auipc	a0,0x3
ffffffffc0204208:	e9450513          	addi	a0,a0,-364 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc020420c:	a86fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204210:	00002617          	auipc	a2,0x2
ffffffffc0204214:	54060613          	addi	a2,a2,1344 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc0204218:	07700593          	li	a1,119
ffffffffc020421c:	00002517          	auipc	a0,0x2
ffffffffc0204220:	4b450513          	addi	a0,a0,1204 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0204224:	a6efc0ef          	jal	ra,ffffffffc0200492 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204228:	00003617          	auipc	a2,0x3
ffffffffc020422c:	e8860613          	addi	a2,a2,-376 # ffffffffc02070b0 <default_pmm_manager+0xa40>
ffffffffc0204230:	04000593          	li	a1,64
ffffffffc0204234:	00003517          	auipc	a0,0x3
ffffffffc0204238:	e8c50513          	addi	a0,a0,-372 # ffffffffc02070c0 <default_pmm_manager+0xa50>
ffffffffc020423c:	a56fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204240 <kernel_thread>:
{
ffffffffc0204240:	7129                	addi	sp,sp,-320
ffffffffc0204242:	fa22                	sd	s0,304(sp)
ffffffffc0204244:	f626                	sd	s1,296(sp)
ffffffffc0204246:	f24a                	sd	s2,288(sp)
ffffffffc0204248:	84ae                	mv	s1,a1
ffffffffc020424a:	892a                	mv	s2,a0
ffffffffc020424c:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020424e:	4581                	li	a1,0
ffffffffc0204250:	12000613          	li	a2,288
ffffffffc0204254:	850a                	mv	a0,sp
{
ffffffffc0204256:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204258:	5bc010ef          	jal	ra,ffffffffc0205814 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020425c:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020425e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204260:	100027f3          	csrr	a5,sstatus
ffffffffc0204264:	edd7f793          	andi	a5,a5,-291
ffffffffc0204268:	1207e793          	ori	a5,a5,288
ffffffffc020426c:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020426e:	860a                	mv	a2,sp
ffffffffc0204270:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204274:	00000797          	auipc	a5,0x0
ffffffffc0204278:	a3a78793          	addi	a5,a5,-1478 # ffffffffc0203cae <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020427c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020427e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204280:	bbdff0ef          	jal	ra,ffffffffc0203e3c <do_fork>
}
ffffffffc0204284:	70f2                	ld	ra,312(sp)
ffffffffc0204286:	7452                	ld	s0,304(sp)
ffffffffc0204288:	74b2                	ld	s1,296(sp)
ffffffffc020428a:	7912                	ld	s2,288(sp)
ffffffffc020428c:	6131                	addi	sp,sp,320
ffffffffc020428e:	8082                	ret

ffffffffc0204290 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc0204290:	7179                	addi	sp,sp,-48
ffffffffc0204292:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204294:	000c3417          	auipc	s0,0xc3
ffffffffc0204298:	9b440413          	addi	s0,s0,-1612 # ffffffffc02c6c48 <current>
ffffffffc020429c:	601c                	ld	a5,0(s0)
{
ffffffffc020429e:	f406                	sd	ra,40(sp)
ffffffffc02042a0:	ec26                	sd	s1,24(sp)
ffffffffc02042a2:	e84a                	sd	s2,16(sp)
ffffffffc02042a4:	e44e                	sd	s3,8(sp)
ffffffffc02042a6:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02042a8:	000c3717          	auipc	a4,0xc3
ffffffffc02042ac:	9a873703          	ld	a4,-1624(a4) # ffffffffc02c6c50 <idleproc>
ffffffffc02042b0:	0ce78c63          	beq	a5,a4,ffffffffc0204388 <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02042b4:	000c3497          	auipc	s1,0xc3
ffffffffc02042b8:	9a448493          	addi	s1,s1,-1628 # ffffffffc02c6c58 <initproc>
ffffffffc02042bc:	6098                	ld	a4,0(s1)
ffffffffc02042be:	0ee78b63          	beq	a5,a4,ffffffffc02043b4 <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc02042c2:	0287b983          	ld	s3,40(a5)
ffffffffc02042c6:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02042c8:	02098663          	beqz	s3,ffffffffc02042f4 <do_exit+0x64>
ffffffffc02042cc:	000c3797          	auipc	a5,0xc3
ffffffffc02042d0:	94c7b783          	ld	a5,-1716(a5) # ffffffffc02c6c18 <boot_pgdir_pa>
ffffffffc02042d4:	577d                	li	a4,-1
ffffffffc02042d6:	177e                	slli	a4,a4,0x3f
ffffffffc02042d8:	83b1                	srli	a5,a5,0xc
ffffffffc02042da:	8fd9                	or	a5,a5,a4
ffffffffc02042dc:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02042e0:	0309a783          	lw	a5,48(s3)
ffffffffc02042e4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02042e8:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc02042ec:	cb55                	beqz	a4,ffffffffc02043a0 <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc02042ee:	601c                	ld	a5,0(s0)
ffffffffc02042f0:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc02042f4:	601c                	ld	a5,0(s0)
ffffffffc02042f6:	470d                	li	a4,3
ffffffffc02042f8:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02042fa:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02042fe:	100027f3          	csrr	a5,sstatus
ffffffffc0204302:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204304:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204306:	e3f9                	bnez	a5,ffffffffc02043cc <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc0204308:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020430a:	800007b7          	lui	a5,0x80000
ffffffffc020430e:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204310:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204312:	0ec52703          	lw	a4,236(a0)
ffffffffc0204316:	0af70f63          	beq	a4,a5,ffffffffc02043d4 <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc020431a:	6018                	ld	a4,0(s0)
ffffffffc020431c:	7b7c                	ld	a5,240(a4)
ffffffffc020431e:	c3a1                	beqz	a5,ffffffffc020435e <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204320:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204324:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204326:	0985                	addi	s3,s3,1
ffffffffc0204328:	a021                	j	ffffffffc0204330 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc020432a:	6018                	ld	a4,0(s0)
ffffffffc020432c:	7b7c                	ld	a5,240(a4)
ffffffffc020432e:	cb85                	beqz	a5,ffffffffc020435e <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204330:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff39e8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204334:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204336:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204338:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020433a:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020433e:	10e7b023          	sd	a4,256(a5)
ffffffffc0204342:	c311                	beqz	a4,ffffffffc0204346 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204344:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204346:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204348:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020434a:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020434c:	fd271fe3          	bne	a4,s2,ffffffffc020432a <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204350:	0ec52783          	lw	a5,236(a0)
ffffffffc0204354:	fd379be3          	bne	a5,s3,ffffffffc020432a <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc0204358:	5a5000ef          	jal	ra,ffffffffc02050fc <wakeup_proc>
ffffffffc020435c:	b7f9                	j	ffffffffc020432a <do_exit+0x9a>
    if (flag)
ffffffffc020435e:	020a1263          	bnez	s4,ffffffffc0204382 <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc0204362:	64d000ef          	jal	ra,ffffffffc02051ae <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204366:	601c                	ld	a5,0(s0)
ffffffffc0204368:	00003617          	auipc	a2,0x3
ffffffffc020436c:	d9060613          	addi	a2,a2,-624 # ffffffffc02070f8 <default_pmm_manager+0xa88>
ffffffffc0204370:	21600593          	li	a1,534
ffffffffc0204374:	43d4                	lw	a3,4(a5)
ffffffffc0204376:	00003517          	auipc	a0,0x3
ffffffffc020437a:	d2250513          	addi	a0,a0,-734 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc020437e:	914fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc0204382:	e26fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204386:	bff1                	j	ffffffffc0204362 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204388:	00003617          	auipc	a2,0x3
ffffffffc020438c:	d5060613          	addi	a2,a2,-688 # ffffffffc02070d8 <default_pmm_manager+0xa68>
ffffffffc0204390:	1e200593          	li	a1,482
ffffffffc0204394:	00003517          	auipc	a0,0x3
ffffffffc0204398:	d0450513          	addi	a0,a0,-764 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc020439c:	8f6fc0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc02043a0:	854e                	mv	a0,s3
ffffffffc02043a2:	cdeff0ef          	jal	ra,ffffffffc0203880 <exit_mmap>
            put_pgdir(mm);
ffffffffc02043a6:	854e                	mv	a0,s3
ffffffffc02043a8:	9b3ff0ef          	jal	ra,ffffffffc0203d5a <put_pgdir>
            mm_destroy(mm);
ffffffffc02043ac:	854e                	mv	a0,s3
ffffffffc02043ae:	b36ff0ef          	jal	ra,ffffffffc02036e4 <mm_destroy>
ffffffffc02043b2:	bf35                	j	ffffffffc02042ee <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02043b4:	00003617          	auipc	a2,0x3
ffffffffc02043b8:	d3460613          	addi	a2,a2,-716 # ffffffffc02070e8 <default_pmm_manager+0xa78>
ffffffffc02043bc:	1e600593          	li	a1,486
ffffffffc02043c0:	00003517          	auipc	a0,0x3
ffffffffc02043c4:	cd850513          	addi	a0,a0,-808 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc02043c8:	8cafc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc02043cc:	de2fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02043d0:	4a05                	li	s4,1
ffffffffc02043d2:	bf1d                	j	ffffffffc0204308 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02043d4:	529000ef          	jal	ra,ffffffffc02050fc <wakeup_proc>
ffffffffc02043d8:	b789                	j	ffffffffc020431a <do_exit+0x8a>

ffffffffc02043da <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc02043da:	715d                	addi	sp,sp,-80
ffffffffc02043dc:	f84a                	sd	s2,48(sp)
ffffffffc02043de:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc02043e0:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02043e4:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02043e6:	fc26                	sd	s1,56(sp)
ffffffffc02043e8:	f052                	sd	s4,32(sp)
ffffffffc02043ea:	ec56                	sd	s5,24(sp)
ffffffffc02043ec:	e85a                	sd	s6,16(sp)
ffffffffc02043ee:	e45e                	sd	s7,8(sp)
ffffffffc02043f0:	e486                	sd	ra,72(sp)
ffffffffc02043f2:	e0a2                	sd	s0,64(sp)
ffffffffc02043f4:	84aa                	mv	s1,a0
ffffffffc02043f6:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02043f8:	000c3b97          	auipc	s7,0xc3
ffffffffc02043fc:	850b8b93          	addi	s7,s7,-1968 # ffffffffc02c6c48 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204400:	00050b1b          	sext.w	s6,a0
ffffffffc0204404:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204408:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020440a:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020440c:	ccbd                	beqz	s1,ffffffffc020448a <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020440e:	0359e863          	bltu	s3,s5,ffffffffc020443e <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204412:	45a9                	li	a1,10
ffffffffc0204414:	855a                	mv	a0,s6
ffffffffc0204416:	759000ef          	jal	ra,ffffffffc020536e <hash32>
ffffffffc020441a:	02051793          	slli	a5,a0,0x20
ffffffffc020441e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204422:	000be797          	auipc	a5,0xbe
ffffffffc0204426:	78e78793          	addi	a5,a5,1934 # ffffffffc02c2bb0 <hash_list>
ffffffffc020442a:	953e                	add	a0,a0,a5
ffffffffc020442c:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020442e:	a029                	j	ffffffffc0204438 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204430:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204434:	02978163          	beq	a5,s1,ffffffffc0204456 <do_wait.part.0+0x7c>
ffffffffc0204438:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020443a:	fe851be3          	bne	a0,s0,ffffffffc0204430 <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc020443e:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc0204440:	60a6                	ld	ra,72(sp)
ffffffffc0204442:	6406                	ld	s0,64(sp)
ffffffffc0204444:	74e2                	ld	s1,56(sp)
ffffffffc0204446:	7942                	ld	s2,48(sp)
ffffffffc0204448:	79a2                	ld	s3,40(sp)
ffffffffc020444a:	7a02                	ld	s4,32(sp)
ffffffffc020444c:	6ae2                	ld	s5,24(sp)
ffffffffc020444e:	6b42                	ld	s6,16(sp)
ffffffffc0204450:	6ba2                	ld	s7,8(sp)
ffffffffc0204452:	6161                	addi	sp,sp,80
ffffffffc0204454:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204456:	000bb683          	ld	a3,0(s7)
ffffffffc020445a:	f4843783          	ld	a5,-184(s0)
ffffffffc020445e:	fed790e3          	bne	a5,a3,ffffffffc020443e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204462:	f2842703          	lw	a4,-216(s0)
ffffffffc0204466:	478d                	li	a5,3
ffffffffc0204468:	0ef70b63          	beq	a4,a5,ffffffffc020455e <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc020446c:	4785                	li	a5,1
ffffffffc020446e:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204470:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204474:	53b000ef          	jal	ra,ffffffffc02051ae <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204478:	000bb783          	ld	a5,0(s7)
ffffffffc020447c:	0b07a783          	lw	a5,176(a5)
ffffffffc0204480:	8b85                	andi	a5,a5,1
ffffffffc0204482:	d7c9                	beqz	a5,ffffffffc020440c <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204484:	555d                	li	a0,-9
ffffffffc0204486:	e0bff0ef          	jal	ra,ffffffffc0204290 <do_exit>
        proc = current->cptr;
ffffffffc020448a:	000bb683          	ld	a3,0(s7)
ffffffffc020448e:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204490:	d45d                	beqz	s0,ffffffffc020443e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204492:	470d                	li	a4,3
ffffffffc0204494:	a021                	j	ffffffffc020449c <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204496:	10043403          	ld	s0,256(s0)
ffffffffc020449a:	d869                	beqz	s0,ffffffffc020446c <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020449c:	401c                	lw	a5,0(s0)
ffffffffc020449e:	fee79ce3          	bne	a5,a4,ffffffffc0204496 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02044a2:	000c2797          	auipc	a5,0xc2
ffffffffc02044a6:	7ae7b783          	ld	a5,1966(a5) # ffffffffc02c6c50 <idleproc>
ffffffffc02044aa:	0c878963          	beq	a5,s0,ffffffffc020457c <do_wait.part.0+0x1a2>
ffffffffc02044ae:	000c2797          	auipc	a5,0xc2
ffffffffc02044b2:	7aa7b783          	ld	a5,1962(a5) # ffffffffc02c6c58 <initproc>
ffffffffc02044b6:	0cf40363          	beq	s0,a5,ffffffffc020457c <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02044ba:	000a0663          	beqz	s4,ffffffffc02044c6 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02044be:	0e842783          	lw	a5,232(s0)
ffffffffc02044c2:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044c6:	100027f3          	csrr	a5,sstatus
ffffffffc02044ca:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02044cc:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044ce:	e7c1                	bnez	a5,ffffffffc0204556 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02044d0:	6c70                	ld	a2,216(s0)
ffffffffc02044d2:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02044d4:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02044d8:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02044da:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02044dc:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02044de:	6470                	ld	a2,200(s0)
ffffffffc02044e0:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02044e2:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02044e4:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02044e6:	c319                	beqz	a4,ffffffffc02044ec <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02044e8:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02044ea:	7c7c                	ld	a5,248(s0)
ffffffffc02044ec:	c3b5                	beqz	a5,ffffffffc0204550 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02044ee:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02044f2:	000c2717          	auipc	a4,0xc2
ffffffffc02044f6:	76e70713          	addi	a4,a4,1902 # ffffffffc02c6c60 <nr_process>
ffffffffc02044fa:	431c                	lw	a5,0(a4)
ffffffffc02044fc:	37fd                	addiw	a5,a5,-1
ffffffffc02044fe:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204500:	e5a9                	bnez	a1,ffffffffc020454a <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204502:	6814                	ld	a3,16(s0)
ffffffffc0204504:	c02007b7          	lui	a5,0xc0200
ffffffffc0204508:	04f6ee63          	bltu	a3,a5,ffffffffc0204564 <do_wait.part.0+0x18a>
ffffffffc020450c:	000c2797          	auipc	a5,0xc2
ffffffffc0204510:	7347b783          	ld	a5,1844(a5) # ffffffffc02c6c40 <va_pa_offset>
ffffffffc0204514:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204516:	82b1                	srli	a3,a3,0xc
ffffffffc0204518:	000c2797          	auipc	a5,0xc2
ffffffffc020451c:	7107b783          	ld	a5,1808(a5) # ffffffffc02c6c28 <npage>
ffffffffc0204520:	06f6fa63          	bgeu	a3,a5,ffffffffc0204594 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204524:	00004517          	auipc	a0,0x4
ffffffffc0204528:	c1c53503          	ld	a0,-996(a0) # ffffffffc0208140 <nbase>
ffffffffc020452c:	8e89                	sub	a3,a3,a0
ffffffffc020452e:	069a                	slli	a3,a3,0x6
ffffffffc0204530:	000c2517          	auipc	a0,0xc2
ffffffffc0204534:	70053503          	ld	a0,1792(a0) # ffffffffc02c6c30 <pages>
ffffffffc0204538:	9536                	add	a0,a0,a3
ffffffffc020453a:	4589                	li	a1,2
ffffffffc020453c:	883fd0ef          	jal	ra,ffffffffc0201dbe <free_pages>
    kfree(proc);
ffffffffc0204540:	8522                	mv	a0,s0
ffffffffc0204542:	f10fd0ef          	jal	ra,ffffffffc0201c52 <kfree>
    return 0;
ffffffffc0204546:	4501                	li	a0,0
ffffffffc0204548:	bde5                	j	ffffffffc0204440 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020454a:	c5efc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020454e:	bf55                	j	ffffffffc0204502 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204550:	701c                	ld	a5,32(s0)
ffffffffc0204552:	fbf8                	sd	a4,240(a5)
ffffffffc0204554:	bf79                	j	ffffffffc02044f2 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204556:	c58fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc020455a:	4585                	li	a1,1
ffffffffc020455c:	bf95                	j	ffffffffc02044d0 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020455e:	f2840413          	addi	s0,s0,-216
ffffffffc0204562:	b781                	j	ffffffffc02044a2 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204564:	00002617          	auipc	a2,0x2
ffffffffc0204568:	1ec60613          	addi	a2,a2,492 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc020456c:	07700593          	li	a1,119
ffffffffc0204570:	00002517          	auipc	a0,0x2
ffffffffc0204574:	16050513          	addi	a0,a0,352 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0204578:	f1bfb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc020457c:	00003617          	auipc	a2,0x3
ffffffffc0204580:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0207118 <default_pmm_manager+0xaa8>
ffffffffc0204584:	33000593          	li	a1,816
ffffffffc0204588:	00003517          	auipc	a0,0x3
ffffffffc020458c:	b1050513          	addi	a0,a0,-1264 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204590:	f03fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204594:	00002617          	auipc	a2,0x2
ffffffffc0204598:	1e460613          	addi	a2,a2,484 # ffffffffc0206778 <default_pmm_manager+0x108>
ffffffffc020459c:	06900593          	li	a1,105
ffffffffc02045a0:	00002517          	auipc	a0,0x2
ffffffffc02045a4:	13050513          	addi	a0,a0,304 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc02045a8:	eebfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02045ac <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02045ac:	1141                	addi	sp,sp,-16
ffffffffc02045ae:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045b0:	84ffd0ef          	jal	ra,ffffffffc0201dfe <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02045b4:	deafd0ef          	jal	ra,ffffffffc0201b9e <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02045b8:	4601                	li	a2,0
ffffffffc02045ba:	4581                	li	a1,0
ffffffffc02045bc:	00000517          	auipc	a0,0x0
ffffffffc02045c0:	62850513          	addi	a0,a0,1576 # ffffffffc0204be4 <user_main>
ffffffffc02045c4:	c7dff0ef          	jal	ra,ffffffffc0204240 <kernel_thread>
    if (pid <= 0)
ffffffffc02045c8:	00a04563          	bgtz	a0,ffffffffc02045d2 <init_main+0x26>
ffffffffc02045cc:	a071                	j	ffffffffc0204658 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02045ce:	3e1000ef          	jal	ra,ffffffffc02051ae <schedule>
    if (code_store != NULL)
ffffffffc02045d2:	4581                	li	a1,0
ffffffffc02045d4:	4501                	li	a0,0
ffffffffc02045d6:	e05ff0ef          	jal	ra,ffffffffc02043da <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02045da:	d975                	beqz	a0,ffffffffc02045ce <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02045dc:	00003517          	auipc	a0,0x3
ffffffffc02045e0:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0207158 <default_pmm_manager+0xae8>
ffffffffc02045e4:	bb5fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02045e8:	000c2797          	auipc	a5,0xc2
ffffffffc02045ec:	6707b783          	ld	a5,1648(a5) # ffffffffc02c6c58 <initproc>
ffffffffc02045f0:	7bf8                	ld	a4,240(a5)
ffffffffc02045f2:	e339                	bnez	a4,ffffffffc0204638 <init_main+0x8c>
ffffffffc02045f4:	7ff8                	ld	a4,248(a5)
ffffffffc02045f6:	e329                	bnez	a4,ffffffffc0204638 <init_main+0x8c>
ffffffffc02045f8:	1007b703          	ld	a4,256(a5)
ffffffffc02045fc:	ef15                	bnez	a4,ffffffffc0204638 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02045fe:	000c2697          	auipc	a3,0xc2
ffffffffc0204602:	6626a683          	lw	a3,1634(a3) # ffffffffc02c6c60 <nr_process>
ffffffffc0204606:	4709                	li	a4,2
ffffffffc0204608:	0ae69463          	bne	a3,a4,ffffffffc02046b0 <init_main+0x104>
    return listelm->next;
ffffffffc020460c:	000c2697          	auipc	a3,0xc2
ffffffffc0204610:	5a468693          	addi	a3,a3,1444 # ffffffffc02c6bb0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204614:	6698                	ld	a4,8(a3)
ffffffffc0204616:	0c878793          	addi	a5,a5,200
ffffffffc020461a:	06f71b63          	bne	a4,a5,ffffffffc0204690 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020461e:	629c                	ld	a5,0(a3)
ffffffffc0204620:	04f71863          	bne	a4,a5,ffffffffc0204670 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204624:	00003517          	auipc	a0,0x3
ffffffffc0204628:	c1c50513          	addi	a0,a0,-996 # ffffffffc0207240 <default_pmm_manager+0xbd0>
ffffffffc020462c:	b6dfb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc0204630:	60a2                	ld	ra,8(sp)
ffffffffc0204632:	4501                	li	a0,0
ffffffffc0204634:	0141                	addi	sp,sp,16
ffffffffc0204636:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204638:	00003697          	auipc	a3,0x3
ffffffffc020463c:	b4868693          	addi	a3,a3,-1208 # ffffffffc0207180 <default_pmm_manager+0xb10>
ffffffffc0204640:	00002617          	auipc	a2,0x2
ffffffffc0204644:	c8060613          	addi	a2,a2,-896 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204648:	39c00593          	li	a1,924
ffffffffc020464c:	00003517          	auipc	a0,0x3
ffffffffc0204650:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204654:	e3ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204658:	00003617          	auipc	a2,0x3
ffffffffc020465c:	ae060613          	addi	a2,a2,-1312 # ffffffffc0207138 <default_pmm_manager+0xac8>
ffffffffc0204660:	39300593          	li	a1,915
ffffffffc0204664:	00003517          	auipc	a0,0x3
ffffffffc0204668:	a3450513          	addi	a0,a0,-1484 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc020466c:	e27fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204670:	00003697          	auipc	a3,0x3
ffffffffc0204674:	ba068693          	addi	a3,a3,-1120 # ffffffffc0207210 <default_pmm_manager+0xba0>
ffffffffc0204678:	00002617          	auipc	a2,0x2
ffffffffc020467c:	c4860613          	addi	a2,a2,-952 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204680:	39f00593          	li	a1,927
ffffffffc0204684:	00003517          	auipc	a0,0x3
ffffffffc0204688:	a1450513          	addi	a0,a0,-1516 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc020468c:	e07fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204690:	00003697          	auipc	a3,0x3
ffffffffc0204694:	b5068693          	addi	a3,a3,-1200 # ffffffffc02071e0 <default_pmm_manager+0xb70>
ffffffffc0204698:	00002617          	auipc	a2,0x2
ffffffffc020469c:	c2860613          	addi	a2,a2,-984 # ffffffffc02062c0 <commands+0x818>
ffffffffc02046a0:	39e00593          	li	a1,926
ffffffffc02046a4:	00003517          	auipc	a0,0x3
ffffffffc02046a8:	9f450513          	addi	a0,a0,-1548 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc02046ac:	de7fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc02046b0:	00003697          	auipc	a3,0x3
ffffffffc02046b4:	b2068693          	addi	a3,a3,-1248 # ffffffffc02071d0 <default_pmm_manager+0xb60>
ffffffffc02046b8:	00002617          	auipc	a2,0x2
ffffffffc02046bc:	c0860613          	addi	a2,a2,-1016 # ffffffffc02062c0 <commands+0x818>
ffffffffc02046c0:	39d00593          	li	a1,925
ffffffffc02046c4:	00003517          	auipc	a0,0x3
ffffffffc02046c8:	9d450513          	addi	a0,a0,-1580 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc02046cc:	dc7fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02046d0 <do_execve>:
{
ffffffffc02046d0:	7171                	addi	sp,sp,-176
ffffffffc02046d2:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046d4:	000c2d97          	auipc	s11,0xc2
ffffffffc02046d8:	574d8d93          	addi	s11,s11,1396 # ffffffffc02c6c48 <current>
ffffffffc02046dc:	000db783          	ld	a5,0(s11)
{
ffffffffc02046e0:	e54e                	sd	s3,136(sp)
ffffffffc02046e2:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02046e4:	0287b983          	ld	s3,40(a5)
{
ffffffffc02046e8:	e94a                	sd	s2,144(sp)
ffffffffc02046ea:	f4de                	sd	s7,104(sp)
ffffffffc02046ec:	892a                	mv	s2,a0
ffffffffc02046ee:	8bb2                	mv	s7,a2
ffffffffc02046f0:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02046f2:	862e                	mv	a2,a1
ffffffffc02046f4:	4681                	li	a3,0
ffffffffc02046f6:	85aa                	mv	a1,a0
ffffffffc02046f8:	854e                	mv	a0,s3
{
ffffffffc02046fa:	f506                	sd	ra,168(sp)
ffffffffc02046fc:	f122                	sd	s0,160(sp)
ffffffffc02046fe:	e152                	sd	s4,128(sp)
ffffffffc0204700:	fcd6                	sd	s5,120(sp)
ffffffffc0204702:	f8da                	sd	s6,112(sp)
ffffffffc0204704:	f0e2                	sd	s8,96(sp)
ffffffffc0204706:	ece6                	sd	s9,88(sp)
ffffffffc0204708:	e8ea                	sd	s10,80(sp)
ffffffffc020470a:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020470c:	d0eff0ef          	jal	ra,ffffffffc0203c1a <user_mem_check>
ffffffffc0204710:	40050a63          	beqz	a0,ffffffffc0204b24 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204714:	4641                	li	a2,16
ffffffffc0204716:	4581                	li	a1,0
ffffffffc0204718:	1808                	addi	a0,sp,48
ffffffffc020471a:	0fa010ef          	jal	ra,ffffffffc0205814 <memset>
    memcpy(local_name, name, len);
ffffffffc020471e:	47bd                	li	a5,15
ffffffffc0204720:	8626                	mv	a2,s1
ffffffffc0204722:	1e97e263          	bltu	a5,s1,ffffffffc0204906 <do_execve+0x236>
ffffffffc0204726:	85ca                	mv	a1,s2
ffffffffc0204728:	1808                	addi	a0,sp,48
ffffffffc020472a:	0fc010ef          	jal	ra,ffffffffc0205826 <memcpy>
    if (mm != NULL)
ffffffffc020472e:	1e098363          	beqz	s3,ffffffffc0204914 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204732:	00002517          	auipc	a0,0x2
ffffffffc0204736:	76e50513          	addi	a0,a0,1902 # ffffffffc0206ea0 <default_pmm_manager+0x830>
ffffffffc020473a:	a97fb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc020473e:	000c2797          	auipc	a5,0xc2
ffffffffc0204742:	4da7b783          	ld	a5,1242(a5) # ffffffffc02c6c18 <boot_pgdir_pa>
ffffffffc0204746:	577d                	li	a4,-1
ffffffffc0204748:	177e                	slli	a4,a4,0x3f
ffffffffc020474a:	83b1                	srli	a5,a5,0xc
ffffffffc020474c:	8fd9                	or	a5,a5,a4
ffffffffc020474e:	18079073          	csrw	satp,a5
ffffffffc0204752:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7f10>
ffffffffc0204756:	fff7871b          	addiw	a4,a5,-1
ffffffffc020475a:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020475e:	2c070463          	beqz	a4,ffffffffc0204a26 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204762:	000db783          	ld	a5,0(s11)
ffffffffc0204766:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc020476a:	e3bfe0ef          	jal	ra,ffffffffc02035a4 <mm_create>
ffffffffc020476e:	84aa                	mv	s1,a0
ffffffffc0204770:	1c050d63          	beqz	a0,ffffffffc020494a <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204774:	4505                	li	a0,1
ffffffffc0204776:	e0afd0ef          	jal	ra,ffffffffc0201d80 <alloc_pages>
ffffffffc020477a:	3a050963          	beqz	a0,ffffffffc0204b2c <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc020477e:	000c2c97          	auipc	s9,0xc2
ffffffffc0204782:	4b2c8c93          	addi	s9,s9,1202 # ffffffffc02c6c30 <pages>
ffffffffc0204786:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc020478a:	000c2c17          	auipc	s8,0xc2
ffffffffc020478e:	49ec0c13          	addi	s8,s8,1182 # ffffffffc02c6c28 <npage>
    return page - pages + nbase;
ffffffffc0204792:	00004717          	auipc	a4,0x4
ffffffffc0204796:	9ae73703          	ld	a4,-1618(a4) # ffffffffc0208140 <nbase>
ffffffffc020479a:	40d506b3          	sub	a3,a0,a3
ffffffffc020479e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02047a0:	5afd                	li	s5,-1
ffffffffc02047a2:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02047a6:	96ba                	add	a3,a3,a4
ffffffffc02047a8:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02047aa:	00cad713          	srli	a4,s5,0xc
ffffffffc02047ae:	ec3a                	sd	a4,24(sp)
ffffffffc02047b0:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02047b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02047b4:	38f77063          	bgeu	a4,a5,ffffffffc0204b34 <do_execve+0x464>
ffffffffc02047b8:	000c2b17          	auipc	s6,0xc2
ffffffffc02047bc:	488b0b13          	addi	s6,s6,1160 # ffffffffc02c6c40 <va_pa_offset>
ffffffffc02047c0:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02047c4:	6605                	lui	a2,0x1
ffffffffc02047c6:	000c2597          	auipc	a1,0xc2
ffffffffc02047ca:	45a5b583          	ld	a1,1114(a1) # ffffffffc02c6c20 <boot_pgdir_va>
ffffffffc02047ce:	9936                	add	s2,s2,a3
ffffffffc02047d0:	854a                	mv	a0,s2
ffffffffc02047d2:	054010ef          	jal	ra,ffffffffc0205826 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047d6:	7782                	ld	a5,32(sp)
ffffffffc02047d8:	4398                	lw	a4,0(a5)
ffffffffc02047da:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02047de:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02047e2:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e67>
ffffffffc02047e6:	14f71863          	bne	a4,a5,ffffffffc0204936 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02047ea:	7682                	ld	a3,32(sp)
ffffffffc02047ec:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02047f0:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02047f4:	00371793          	slli	a5,a4,0x3
ffffffffc02047f8:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02047fa:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02047fc:	078e                	slli	a5,a5,0x3
ffffffffc02047fe:	97ce                	add	a5,a5,s3
ffffffffc0204800:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204802:	00f9fc63          	bgeu	s3,a5,ffffffffc020481a <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204806:	0009a783          	lw	a5,0(s3)
ffffffffc020480a:	4705                	li	a4,1
ffffffffc020480c:	14e78163          	beq	a5,a4,ffffffffc020494e <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204810:	77a2                	ld	a5,40(sp)
ffffffffc0204812:	03898993          	addi	s3,s3,56
ffffffffc0204816:	fef9e8e3          	bltu	s3,a5,ffffffffc0204806 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc020481a:	4701                	li	a4,0
ffffffffc020481c:	46ad                	li	a3,11
ffffffffc020481e:	00100637          	lui	a2,0x100
ffffffffc0204822:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204826:	8526                	mv	a0,s1
ffffffffc0204828:	f0ffe0ef          	jal	ra,ffffffffc0203736 <mm_map>
ffffffffc020482c:	8a2a                	mv	s4,a0
ffffffffc020482e:	1e051263          	bnez	a0,ffffffffc0204a12 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204832:	6c88                	ld	a0,24(s1)
ffffffffc0204834:	467d                	li	a2,31
ffffffffc0204836:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc020483a:	c85fe0ef          	jal	ra,ffffffffc02034be <pgdir_alloc_page>
ffffffffc020483e:	38050363          	beqz	a0,ffffffffc0204bc4 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204842:	6c88                	ld	a0,24(s1)
ffffffffc0204844:	467d                	li	a2,31
ffffffffc0204846:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc020484a:	c75fe0ef          	jal	ra,ffffffffc02034be <pgdir_alloc_page>
ffffffffc020484e:	34050b63          	beqz	a0,ffffffffc0204ba4 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204852:	6c88                	ld	a0,24(s1)
ffffffffc0204854:	467d                	li	a2,31
ffffffffc0204856:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc020485a:	c65fe0ef          	jal	ra,ffffffffc02034be <pgdir_alloc_page>
ffffffffc020485e:	32050363          	beqz	a0,ffffffffc0204b84 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204862:	6c88                	ld	a0,24(s1)
ffffffffc0204864:	467d                	li	a2,31
ffffffffc0204866:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc020486a:	c55fe0ef          	jal	ra,ffffffffc02034be <pgdir_alloc_page>
ffffffffc020486e:	2e050b63          	beqz	a0,ffffffffc0204b64 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204872:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204874:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204878:	6c94                	ld	a3,24(s1)
ffffffffc020487a:	2785                	addiw	a5,a5,1
ffffffffc020487c:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc020487e:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204880:	c02007b7          	lui	a5,0xc0200
ffffffffc0204884:	2cf6e463          	bltu	a3,a5,ffffffffc0204b4c <do_execve+0x47c>
ffffffffc0204888:	000b3783          	ld	a5,0(s6)
ffffffffc020488c:	577d                	li	a4,-1
ffffffffc020488e:	177e                	slli	a4,a4,0x3f
ffffffffc0204890:	8e9d                	sub	a3,a3,a5
ffffffffc0204892:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204896:	f654                	sd	a3,168(a2)
ffffffffc0204898:	8fd9                	or	a5,a5,a4
ffffffffc020489a:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc020489e:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048a0:	4581                	li	a1,0
ffffffffc02048a2:	12000613          	li	a2,288
ffffffffc02048a6:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc02048a8:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048ac:	769000ef          	jal	ra,ffffffffc0205814 <memset>
    tf->epc = elf->e_entry;
ffffffffc02048b0:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048b2:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02048b6:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc02048ba:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc02048bc:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048be:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_matrix_out_size+0xffffffff7fff399c>
    tf->gpr.sp = USTACKTOP;
ffffffffc02048c2:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02048c4:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048c8:	4641                	li	a2,16
ffffffffc02048ca:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc02048cc:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc02048ce:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02048d2:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02048d6:	854a                	mv	a0,s2
ffffffffc02048d8:	73d000ef          	jal	ra,ffffffffc0205814 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02048dc:	463d                	li	a2,15
ffffffffc02048de:	180c                	addi	a1,sp,48
ffffffffc02048e0:	854a                	mv	a0,s2
ffffffffc02048e2:	745000ef          	jal	ra,ffffffffc0205826 <memcpy>
}
ffffffffc02048e6:	70aa                	ld	ra,168(sp)
ffffffffc02048e8:	740a                	ld	s0,160(sp)
ffffffffc02048ea:	64ea                	ld	s1,152(sp)
ffffffffc02048ec:	694a                	ld	s2,144(sp)
ffffffffc02048ee:	69aa                	ld	s3,136(sp)
ffffffffc02048f0:	7ae6                	ld	s5,120(sp)
ffffffffc02048f2:	7b46                	ld	s6,112(sp)
ffffffffc02048f4:	7ba6                	ld	s7,104(sp)
ffffffffc02048f6:	7c06                	ld	s8,96(sp)
ffffffffc02048f8:	6ce6                	ld	s9,88(sp)
ffffffffc02048fa:	6d46                	ld	s10,80(sp)
ffffffffc02048fc:	6da6                	ld	s11,72(sp)
ffffffffc02048fe:	8552                	mv	a0,s4
ffffffffc0204900:	6a0a                	ld	s4,128(sp)
ffffffffc0204902:	614d                	addi	sp,sp,176
ffffffffc0204904:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204906:	463d                	li	a2,15
ffffffffc0204908:	85ca                	mv	a1,s2
ffffffffc020490a:	1808                	addi	a0,sp,48
ffffffffc020490c:	71b000ef          	jal	ra,ffffffffc0205826 <memcpy>
    if (mm != NULL)
ffffffffc0204910:	e20991e3          	bnez	s3,ffffffffc0204732 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204914:	000db783          	ld	a5,0(s11)
ffffffffc0204918:	779c                	ld	a5,40(a5)
ffffffffc020491a:	e40788e3          	beqz	a5,ffffffffc020476a <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc020491e:	00003617          	auipc	a2,0x3
ffffffffc0204922:	94260613          	addi	a2,a2,-1726 # ffffffffc0207260 <default_pmm_manager+0xbf0>
ffffffffc0204926:	22200593          	li	a1,546
ffffffffc020492a:	00002517          	auipc	a0,0x2
ffffffffc020492e:	76e50513          	addi	a0,a0,1902 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204932:	b61fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc0204936:	8526                	mv	a0,s1
ffffffffc0204938:	c22ff0ef          	jal	ra,ffffffffc0203d5a <put_pgdir>
    mm_destroy(mm);
ffffffffc020493c:	8526                	mv	a0,s1
ffffffffc020493e:	da7fe0ef          	jal	ra,ffffffffc02036e4 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204942:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204944:	8552                	mv	a0,s4
ffffffffc0204946:	94bff0ef          	jal	ra,ffffffffc0204290 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc020494a:	5a71                	li	s4,-4
ffffffffc020494c:	bfe5                	j	ffffffffc0204944 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc020494e:	0289b603          	ld	a2,40(s3)
ffffffffc0204952:	0209b783          	ld	a5,32(s3)
ffffffffc0204956:	1cf66d63          	bltu	a2,a5,ffffffffc0204b30 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc020495a:	0049a783          	lw	a5,4(s3)
ffffffffc020495e:	0017f693          	andi	a3,a5,1
ffffffffc0204962:	c291                	beqz	a3,ffffffffc0204966 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204964:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204966:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc020496a:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc020496c:	e779                	bnez	a4,ffffffffc0204a3a <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc020496e:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204970:	c781                	beqz	a5,ffffffffc0204978 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204972:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204976:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204978:	0026f793          	andi	a5,a3,2
ffffffffc020497c:	e3f1                	bnez	a5,ffffffffc0204a40 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc020497e:	0046f793          	andi	a5,a3,4
ffffffffc0204982:	c399                	beqz	a5,ffffffffc0204988 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204984:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204988:	0109b583          	ld	a1,16(s3)
ffffffffc020498c:	4701                	li	a4,0
ffffffffc020498e:	8526                	mv	a0,s1
ffffffffc0204990:	da7fe0ef          	jal	ra,ffffffffc0203736 <mm_map>
ffffffffc0204994:	8a2a                	mv	s4,a0
ffffffffc0204996:	ed35                	bnez	a0,ffffffffc0204a12 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204998:	0109bb83          	ld	s7,16(s3)
ffffffffc020499c:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc020499e:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049a2:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049a6:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049aa:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc02049ac:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049ae:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc02049b0:	054be963          	bltu	s7,s4,ffffffffc0204a02 <do_execve+0x332>
ffffffffc02049b4:	aa95                	j	ffffffffc0204b28 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02049b6:	6785                	lui	a5,0x1
ffffffffc02049b8:	415b8533          	sub	a0,s7,s5
ffffffffc02049bc:	9abe                	add	s5,s5,a5
ffffffffc02049be:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc02049c2:	015a7463          	bgeu	s4,s5,ffffffffc02049ca <do_execve+0x2fa>
                size -= la - end;
ffffffffc02049c6:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc02049ca:	000cb683          	ld	a3,0(s9)
ffffffffc02049ce:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02049d0:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02049d4:	40d406b3          	sub	a3,s0,a3
ffffffffc02049d8:	8699                	srai	a3,a3,0x6
ffffffffc02049da:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02049dc:	67e2                	ld	a5,24(sp)
ffffffffc02049de:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02049e2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049e4:	14b87863          	bgeu	a6,a1,ffffffffc0204b34 <do_execve+0x464>
ffffffffc02049e8:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02049ec:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc02049ee:	9bb2                	add	s7,s7,a2
ffffffffc02049f0:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc02049f2:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc02049f4:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc02049f6:	631000ef          	jal	ra,ffffffffc0205826 <memcpy>
            start += size, from += size;
ffffffffc02049fa:	6622                	ld	a2,8(sp)
ffffffffc02049fc:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc02049fe:	054bf363          	bgeu	s7,s4,ffffffffc0204a44 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a02:	6c88                	ld	a0,24(s1)
ffffffffc0204a04:	866a                	mv	a2,s10
ffffffffc0204a06:	85d6                	mv	a1,s5
ffffffffc0204a08:	ab7fe0ef          	jal	ra,ffffffffc02034be <pgdir_alloc_page>
ffffffffc0204a0c:	842a                	mv	s0,a0
ffffffffc0204a0e:	f545                	bnez	a0,ffffffffc02049b6 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204a10:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204a12:	8526                	mv	a0,s1
ffffffffc0204a14:	e6dfe0ef          	jal	ra,ffffffffc0203880 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204a18:	8526                	mv	a0,s1
ffffffffc0204a1a:	b40ff0ef          	jal	ra,ffffffffc0203d5a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204a1e:	8526                	mv	a0,s1
ffffffffc0204a20:	cc5fe0ef          	jal	ra,ffffffffc02036e4 <mm_destroy>
    return ret;
ffffffffc0204a24:	b705                	j	ffffffffc0204944 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204a26:	854e                	mv	a0,s3
ffffffffc0204a28:	e59fe0ef          	jal	ra,ffffffffc0203880 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204a2c:	854e                	mv	a0,s3
ffffffffc0204a2e:	b2cff0ef          	jal	ra,ffffffffc0203d5a <put_pgdir>
            mm_destroy(mm);
ffffffffc0204a32:	854e                	mv	a0,s3
ffffffffc0204a34:	cb1fe0ef          	jal	ra,ffffffffc02036e4 <mm_destroy>
ffffffffc0204a38:	b32d                	j	ffffffffc0204762 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204a3a:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a3e:	fb95                	bnez	a5,ffffffffc0204972 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204a40:	4d5d                	li	s10,23
ffffffffc0204a42:	bf35                	j	ffffffffc020497e <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204a44:	0109b683          	ld	a3,16(s3)
ffffffffc0204a48:	0289b903          	ld	s2,40(s3)
ffffffffc0204a4c:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204a4e:	075bfd63          	bgeu	s7,s5,ffffffffc0204ac8 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204a52:	db790fe3          	beq	s2,s7,ffffffffc0204810 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204a56:	6785                	lui	a5,0x1
ffffffffc0204a58:	00fb8533          	add	a0,s7,a5
ffffffffc0204a5c:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204a60:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204a64:	0b597d63          	bgeu	s2,s5,ffffffffc0204b1e <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204a68:	000cb683          	ld	a3,0(s9)
ffffffffc0204a6c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a6e:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204a72:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a76:	8699                	srai	a3,a3,0x6
ffffffffc0204a78:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a7a:	67e2                	ld	a5,24(sp)
ffffffffc0204a7c:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a80:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a82:	0ac5f963          	bgeu	a1,a2,ffffffffc0204b34 <do_execve+0x464>
ffffffffc0204a86:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204a8a:	8652                	mv	a2,s4
ffffffffc0204a8c:	4581                	li	a1,0
ffffffffc0204a8e:	96c2                	add	a3,a3,a6
ffffffffc0204a90:	9536                	add	a0,a0,a3
ffffffffc0204a92:	583000ef          	jal	ra,ffffffffc0205814 <memset>
            start += size;
ffffffffc0204a96:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204a9a:	03597463          	bgeu	s2,s5,ffffffffc0204ac2 <do_execve+0x3f2>
ffffffffc0204a9e:	d6e909e3          	beq	s2,a4,ffffffffc0204810 <do_execve+0x140>
ffffffffc0204aa2:	00002697          	auipc	a3,0x2
ffffffffc0204aa6:	7e668693          	addi	a3,a3,2022 # ffffffffc0207288 <default_pmm_manager+0xc18>
ffffffffc0204aaa:	00002617          	auipc	a2,0x2
ffffffffc0204aae:	81660613          	addi	a2,a2,-2026 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204ab2:	28b00593          	li	a1,651
ffffffffc0204ab6:	00002517          	auipc	a0,0x2
ffffffffc0204aba:	5e250513          	addi	a0,a0,1506 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204abe:	9d5fb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0204ac2:	ff5710e3          	bne	a4,s5,ffffffffc0204aa2 <do_execve+0x3d2>
ffffffffc0204ac6:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204ac8:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204810 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204acc:	6c88                	ld	a0,24(s1)
ffffffffc0204ace:	866a                	mv	a2,s10
ffffffffc0204ad0:	85d6                	mv	a1,s5
ffffffffc0204ad2:	9edfe0ef          	jal	ra,ffffffffc02034be <pgdir_alloc_page>
ffffffffc0204ad6:	842a                	mv	s0,a0
ffffffffc0204ad8:	dd05                	beqz	a0,ffffffffc0204a10 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204ada:	6785                	lui	a5,0x1
ffffffffc0204adc:	415b8533          	sub	a0,s7,s5
ffffffffc0204ae0:	9abe                	add	s5,s5,a5
ffffffffc0204ae2:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204ae6:	01597463          	bgeu	s2,s5,ffffffffc0204aee <do_execve+0x41e>
                size -= la - end;
ffffffffc0204aea:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204aee:	000cb683          	ld	a3,0(s9)
ffffffffc0204af2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204af4:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204af8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204afc:	8699                	srai	a3,a3,0x6
ffffffffc0204afe:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b00:	67e2                	ld	a5,24(sp)
ffffffffc0204b02:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b06:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b08:	02b87663          	bgeu	a6,a1,ffffffffc0204b34 <do_execve+0x464>
ffffffffc0204b0c:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b10:	4581                	li	a1,0
            start += size;
ffffffffc0204b12:	9bb2                	add	s7,s7,a2
ffffffffc0204b14:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b16:	9536                	add	a0,a0,a3
ffffffffc0204b18:	4fd000ef          	jal	ra,ffffffffc0205814 <memset>
ffffffffc0204b1c:	b775                	j	ffffffffc0204ac8 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b1e:	417a8a33          	sub	s4,s5,s7
ffffffffc0204b22:	b799                	j	ffffffffc0204a68 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204b24:	5a75                	li	s4,-3
ffffffffc0204b26:	b3c1                	j	ffffffffc02048e6 <do_execve+0x216>
        while (start < end)
ffffffffc0204b28:	86de                	mv	a3,s7
ffffffffc0204b2a:	bf39                	j	ffffffffc0204a48 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204b2c:	5a71                	li	s4,-4
ffffffffc0204b2e:	bdc5                	j	ffffffffc0204a1e <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204b30:	5a61                	li	s4,-8
ffffffffc0204b32:	b5c5                	j	ffffffffc0204a12 <do_execve+0x342>
ffffffffc0204b34:	00002617          	auipc	a2,0x2
ffffffffc0204b38:	b7460613          	addi	a2,a2,-1164 # ffffffffc02066a8 <default_pmm_manager+0x38>
ffffffffc0204b3c:	07100593          	li	a1,113
ffffffffc0204b40:	00002517          	auipc	a0,0x2
ffffffffc0204b44:	b9050513          	addi	a0,a0,-1136 # ffffffffc02066d0 <default_pmm_manager+0x60>
ffffffffc0204b48:	94bfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b4c:	00002617          	auipc	a2,0x2
ffffffffc0204b50:	c0460613          	addi	a2,a2,-1020 # ffffffffc0206750 <default_pmm_manager+0xe0>
ffffffffc0204b54:	2aa00593          	li	a1,682
ffffffffc0204b58:	00002517          	auipc	a0,0x2
ffffffffc0204b5c:	54050513          	addi	a0,a0,1344 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204b60:	933fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b64:	00003697          	auipc	a3,0x3
ffffffffc0204b68:	83c68693          	addi	a3,a3,-1988 # ffffffffc02073a0 <default_pmm_manager+0xd30>
ffffffffc0204b6c:	00001617          	auipc	a2,0x1
ffffffffc0204b70:	75460613          	addi	a2,a2,1876 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204b74:	2a500593          	li	a1,677
ffffffffc0204b78:	00002517          	auipc	a0,0x2
ffffffffc0204b7c:	52050513          	addi	a0,a0,1312 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204b80:	913fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b84:	00002697          	auipc	a3,0x2
ffffffffc0204b88:	7d468693          	addi	a3,a3,2004 # ffffffffc0207358 <default_pmm_manager+0xce8>
ffffffffc0204b8c:	00001617          	auipc	a2,0x1
ffffffffc0204b90:	73460613          	addi	a2,a2,1844 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204b94:	2a400593          	li	a1,676
ffffffffc0204b98:	00002517          	auipc	a0,0x2
ffffffffc0204b9c:	50050513          	addi	a0,a0,1280 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204ba0:	8f3fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ba4:	00002697          	auipc	a3,0x2
ffffffffc0204ba8:	76c68693          	addi	a3,a3,1900 # ffffffffc0207310 <default_pmm_manager+0xca0>
ffffffffc0204bac:	00001617          	auipc	a2,0x1
ffffffffc0204bb0:	71460613          	addi	a2,a2,1812 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204bb4:	2a300593          	li	a1,675
ffffffffc0204bb8:	00002517          	auipc	a0,0x2
ffffffffc0204bbc:	4e050513          	addi	a0,a0,1248 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204bc0:	8d3fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204bc4:	00002697          	auipc	a3,0x2
ffffffffc0204bc8:	70468693          	addi	a3,a3,1796 # ffffffffc02072c8 <default_pmm_manager+0xc58>
ffffffffc0204bcc:	00001617          	auipc	a2,0x1
ffffffffc0204bd0:	6f460613          	addi	a2,a2,1780 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204bd4:	2a200593          	li	a1,674
ffffffffc0204bd8:	00002517          	auipc	a0,0x2
ffffffffc0204bdc:	4c050513          	addi	a0,a0,1216 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204be0:	8b3fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204be4 <user_main>:
{
ffffffffc0204be4:	1101                	addi	sp,sp,-32
ffffffffc0204be6:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204be8:	000c2917          	auipc	s2,0xc2
ffffffffc0204bec:	06090913          	addi	s2,s2,96 # ffffffffc02c6c48 <current>
ffffffffc0204bf0:	00093783          	ld	a5,0(s2)
ffffffffc0204bf4:	00002617          	auipc	a2,0x2
ffffffffc0204bf8:	7f460613          	addi	a2,a2,2036 # ffffffffc02073e8 <default_pmm_manager+0xd78>
ffffffffc0204bfc:	00002517          	auipc	a0,0x2
ffffffffc0204c00:	7fc50513          	addi	a0,a0,2044 # ffffffffc02073f8 <default_pmm_manager+0xd88>
ffffffffc0204c04:	43cc                	lw	a1,4(a5)
{
ffffffffc0204c06:	ec06                	sd	ra,24(sp)
ffffffffc0204c08:	e822                	sd	s0,16(sp)
ffffffffc0204c0a:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c0c:	d8cfb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204c10:	00002517          	auipc	a0,0x2
ffffffffc0204c14:	7d850513          	addi	a0,a0,2008 # ffffffffc02073e8 <default_pmm_manager+0xd78>
ffffffffc0204c18:	35b000ef          	jal	ra,ffffffffc0205772 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204c1c:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204c20:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c22:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c26:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c28:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c2a:	6789                	lui	a5,0x2
ffffffffc0204c2c:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8060>
ffffffffc0204c30:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c32:	8522                	mv	a0,s0
ffffffffc0204c34:	3f3000ef          	jal	ra,ffffffffc0205826 <memcpy>
    current->tf = new_tf;
ffffffffc0204c38:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204c3c:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204c40:	b0c68693          	addi	a3,a3,-1268 # b748 <_binary_obj___user_priority_out_size>
ffffffffc0204c44:	0007d617          	auipc	a2,0x7d
ffffffffc0204c48:	11c60613          	addi	a2,a2,284 # ffffffffc0281d60 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204c4c:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204c4e:	85a6                	mv	a1,s1
ffffffffc0204c50:	00002517          	auipc	a0,0x2
ffffffffc0204c54:	79850513          	addi	a0,a0,1944 # ffffffffc02073e8 <default_pmm_manager+0xd78>
ffffffffc0204c58:	a79ff0ef          	jal	ra,ffffffffc02046d0 <do_execve>
    asm volatile(
ffffffffc0204c5c:	8122                	mv	sp,s0
ffffffffc0204c5e:	a06fc06f          	j	ffffffffc0200e64 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204c62:	00002617          	auipc	a2,0x2
ffffffffc0204c66:	7be60613          	addi	a2,a2,1982 # ffffffffc0207420 <default_pmm_manager+0xdb0>
ffffffffc0204c6a:	38600593          	li	a1,902
ffffffffc0204c6e:	00002517          	auipc	a0,0x2
ffffffffc0204c72:	42a50513          	addi	a0,a0,1066 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204c76:	81dfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204c7a <do_yield>:
    current->need_resched = 1;
ffffffffc0204c7a:	000c2797          	auipc	a5,0xc2
ffffffffc0204c7e:	fce7b783          	ld	a5,-50(a5) # ffffffffc02c6c48 <current>
ffffffffc0204c82:	4705                	li	a4,1
ffffffffc0204c84:	ef98                	sd	a4,24(a5)
}
ffffffffc0204c86:	4501                	li	a0,0
ffffffffc0204c88:	8082                	ret

ffffffffc0204c8a <do_wait>:
{
ffffffffc0204c8a:	1101                	addi	sp,sp,-32
ffffffffc0204c8c:	e822                	sd	s0,16(sp)
ffffffffc0204c8e:	e426                	sd	s1,8(sp)
ffffffffc0204c90:	ec06                	sd	ra,24(sp)
ffffffffc0204c92:	842e                	mv	s0,a1
ffffffffc0204c94:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204c96:	c999                	beqz	a1,ffffffffc0204cac <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204c98:	000c2797          	auipc	a5,0xc2
ffffffffc0204c9c:	fb07b783          	ld	a5,-80(a5) # ffffffffc02c6c48 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204ca0:	7788                	ld	a0,40(a5)
ffffffffc0204ca2:	4685                	li	a3,1
ffffffffc0204ca4:	4611                	li	a2,4
ffffffffc0204ca6:	f75fe0ef          	jal	ra,ffffffffc0203c1a <user_mem_check>
ffffffffc0204caa:	c909                	beqz	a0,ffffffffc0204cbc <do_wait+0x32>
ffffffffc0204cac:	85a2                	mv	a1,s0
}
ffffffffc0204cae:	6442                	ld	s0,16(sp)
ffffffffc0204cb0:	60e2                	ld	ra,24(sp)
ffffffffc0204cb2:	8526                	mv	a0,s1
ffffffffc0204cb4:	64a2                	ld	s1,8(sp)
ffffffffc0204cb6:	6105                	addi	sp,sp,32
ffffffffc0204cb8:	f22ff06f          	j	ffffffffc02043da <do_wait.part.0>
ffffffffc0204cbc:	60e2                	ld	ra,24(sp)
ffffffffc0204cbe:	6442                	ld	s0,16(sp)
ffffffffc0204cc0:	64a2                	ld	s1,8(sp)
ffffffffc0204cc2:	5575                	li	a0,-3
ffffffffc0204cc4:	6105                	addi	sp,sp,32
ffffffffc0204cc6:	8082                	ret

ffffffffc0204cc8 <do_kill>:
{
ffffffffc0204cc8:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204cca:	6789                	lui	a5,0x2
{
ffffffffc0204ccc:	e406                	sd	ra,8(sp)
ffffffffc0204cce:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204cd0:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204cd4:	17f9                	addi	a5,a5,-2
ffffffffc0204cd6:	02e7e963          	bltu	a5,a4,ffffffffc0204d08 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204cda:	842a                	mv	s0,a0
ffffffffc0204cdc:	45a9                	li	a1,10
ffffffffc0204cde:	2501                	sext.w	a0,a0
ffffffffc0204ce0:	68e000ef          	jal	ra,ffffffffc020536e <hash32>
ffffffffc0204ce4:	02051793          	slli	a5,a0,0x20
ffffffffc0204ce8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204cec:	000be797          	auipc	a5,0xbe
ffffffffc0204cf0:	ec478793          	addi	a5,a5,-316 # ffffffffc02c2bb0 <hash_list>
ffffffffc0204cf4:	953e                	add	a0,a0,a5
ffffffffc0204cf6:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204cf8:	a029                	j	ffffffffc0204d02 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204cfa:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204cfe:	00870b63          	beq	a4,s0,ffffffffc0204d14 <do_kill+0x4c>
ffffffffc0204d02:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204d04:	fef51be3          	bne	a0,a5,ffffffffc0204cfa <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204d08:	5475                	li	s0,-3
}
ffffffffc0204d0a:	60a2                	ld	ra,8(sp)
ffffffffc0204d0c:	8522                	mv	a0,s0
ffffffffc0204d0e:	6402                	ld	s0,0(sp)
ffffffffc0204d10:	0141                	addi	sp,sp,16
ffffffffc0204d12:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204d14:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204d18:	00177693          	andi	a3,a4,1
ffffffffc0204d1c:	e295                	bnez	a3,ffffffffc0204d40 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d1e:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204d20:	00176713          	ori	a4,a4,1
ffffffffc0204d24:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204d28:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d2a:	fe06d0e3          	bgez	a3,ffffffffc0204d0a <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204d2e:	f2878513          	addi	a0,a5,-216
ffffffffc0204d32:	3ca000ef          	jal	ra,ffffffffc02050fc <wakeup_proc>
}
ffffffffc0204d36:	60a2                	ld	ra,8(sp)
ffffffffc0204d38:	8522                	mv	a0,s0
ffffffffc0204d3a:	6402                	ld	s0,0(sp)
ffffffffc0204d3c:	0141                	addi	sp,sp,16
ffffffffc0204d3e:	8082                	ret
        return -E_KILLED;
ffffffffc0204d40:	545d                	li	s0,-9
ffffffffc0204d42:	b7e1                	j	ffffffffc0204d0a <do_kill+0x42>

ffffffffc0204d44 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204d44:	1101                	addi	sp,sp,-32
ffffffffc0204d46:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204d48:	000c2797          	auipc	a5,0xc2
ffffffffc0204d4c:	e6878793          	addi	a5,a5,-408 # ffffffffc02c6bb0 <proc_list>
ffffffffc0204d50:	ec06                	sd	ra,24(sp)
ffffffffc0204d52:	e822                	sd	s0,16(sp)
ffffffffc0204d54:	e04a                	sd	s2,0(sp)
ffffffffc0204d56:	000be497          	auipc	s1,0xbe
ffffffffc0204d5a:	e5a48493          	addi	s1,s1,-422 # ffffffffc02c2bb0 <hash_list>
ffffffffc0204d5e:	e79c                	sd	a5,8(a5)
ffffffffc0204d60:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204d62:	000c2717          	auipc	a4,0xc2
ffffffffc0204d66:	e4e70713          	addi	a4,a4,-434 # ffffffffc02c6bb0 <proc_list>
ffffffffc0204d6a:	87a6                	mv	a5,s1
ffffffffc0204d6c:	e79c                	sd	a5,8(a5)
ffffffffc0204d6e:	e39c                	sd	a5,0(a5)
ffffffffc0204d70:	07c1                	addi	a5,a5,16
ffffffffc0204d72:	fef71de3          	bne	a4,a5,ffffffffc0204d6c <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204d76:	f41fe0ef          	jal	ra,ffffffffc0203cb6 <alloc_proc>
ffffffffc0204d7a:	000c2917          	auipc	s2,0xc2
ffffffffc0204d7e:	ed690913          	addi	s2,s2,-298 # ffffffffc02c6c50 <idleproc>
ffffffffc0204d82:	00a93023          	sd	a0,0(s2)
ffffffffc0204d86:	0e050f63          	beqz	a0,ffffffffc0204e84 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204d8a:	4789                	li	a5,2
ffffffffc0204d8c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204d8e:	00004797          	auipc	a5,0x4
ffffffffc0204d92:	27278793          	addi	a5,a5,626 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d96:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204d9a:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204d9c:	4785                	li	a5,1
ffffffffc0204d9e:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204da0:	4641                	li	a2,16
ffffffffc0204da2:	4581                	li	a1,0
ffffffffc0204da4:	8522                	mv	a0,s0
ffffffffc0204da6:	26f000ef          	jal	ra,ffffffffc0205814 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204daa:	463d                	li	a2,15
ffffffffc0204dac:	00002597          	auipc	a1,0x2
ffffffffc0204db0:	6ac58593          	addi	a1,a1,1708 # ffffffffc0207458 <default_pmm_manager+0xde8>
ffffffffc0204db4:	8522                	mv	a0,s0
ffffffffc0204db6:	271000ef          	jal	ra,ffffffffc0205826 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204dba:	000c2717          	auipc	a4,0xc2
ffffffffc0204dbe:	ea670713          	addi	a4,a4,-346 # ffffffffc02c6c60 <nr_process>
ffffffffc0204dc2:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204dc4:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204dc8:	4601                	li	a2,0
    nr_process++;
ffffffffc0204dca:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204dcc:	4581                	li	a1,0
ffffffffc0204dce:	fffff517          	auipc	a0,0xfffff
ffffffffc0204dd2:	7de50513          	addi	a0,a0,2014 # ffffffffc02045ac <init_main>
    nr_process++;
ffffffffc0204dd6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204dd8:	000c2797          	auipc	a5,0xc2
ffffffffc0204ddc:	e6d7b823          	sd	a3,-400(a5) # ffffffffc02c6c48 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204de0:	c60ff0ef          	jal	ra,ffffffffc0204240 <kernel_thread>
ffffffffc0204de4:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204de6:	08a05363          	blez	a0,ffffffffc0204e6c <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204dea:	6789                	lui	a5,0x2
ffffffffc0204dec:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204df0:	17f9                	addi	a5,a5,-2
ffffffffc0204df2:	2501                	sext.w	a0,a0
ffffffffc0204df4:	02e7e363          	bltu	a5,a4,ffffffffc0204e1a <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204df8:	45a9                	li	a1,10
ffffffffc0204dfa:	574000ef          	jal	ra,ffffffffc020536e <hash32>
ffffffffc0204dfe:	02051793          	slli	a5,a0,0x20
ffffffffc0204e02:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e06:	96a6                	add	a3,a3,s1
ffffffffc0204e08:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e0a:	a029                	j	ffffffffc0204e14 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204e0c:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8014>
ffffffffc0204e10:	04870b63          	beq	a4,s0,ffffffffc0204e66 <proc_init+0x122>
    return listelm->next;
ffffffffc0204e14:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e16:	fef69be3          	bne	a3,a5,ffffffffc0204e0c <proc_init+0xc8>
    return NULL;
ffffffffc0204e1a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e1c:	0b478493          	addi	s1,a5,180
ffffffffc0204e20:	4641                	li	a2,16
ffffffffc0204e22:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204e24:	000c2417          	auipc	s0,0xc2
ffffffffc0204e28:	e3440413          	addi	s0,s0,-460 # ffffffffc02c6c58 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e2c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204e2e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e30:	1e5000ef          	jal	ra,ffffffffc0205814 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e34:	463d                	li	a2,15
ffffffffc0204e36:	00002597          	auipc	a1,0x2
ffffffffc0204e3a:	64a58593          	addi	a1,a1,1610 # ffffffffc0207480 <default_pmm_manager+0xe10>
ffffffffc0204e3e:	8526                	mv	a0,s1
ffffffffc0204e40:	1e7000ef          	jal	ra,ffffffffc0205826 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204e44:	00093783          	ld	a5,0(s2)
ffffffffc0204e48:	cbb5                	beqz	a5,ffffffffc0204ebc <proc_init+0x178>
ffffffffc0204e4a:	43dc                	lw	a5,4(a5)
ffffffffc0204e4c:	eba5                	bnez	a5,ffffffffc0204ebc <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204e4e:	601c                	ld	a5,0(s0)
ffffffffc0204e50:	c7b1                	beqz	a5,ffffffffc0204e9c <proc_init+0x158>
ffffffffc0204e52:	43d8                	lw	a4,4(a5)
ffffffffc0204e54:	4785                	li	a5,1
ffffffffc0204e56:	04f71363          	bne	a4,a5,ffffffffc0204e9c <proc_init+0x158>
}
ffffffffc0204e5a:	60e2                	ld	ra,24(sp)
ffffffffc0204e5c:	6442                	ld	s0,16(sp)
ffffffffc0204e5e:	64a2                	ld	s1,8(sp)
ffffffffc0204e60:	6902                	ld	s2,0(sp)
ffffffffc0204e62:	6105                	addi	sp,sp,32
ffffffffc0204e64:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204e66:	f2878793          	addi	a5,a5,-216
ffffffffc0204e6a:	bf4d                	j	ffffffffc0204e1c <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204e6c:	00002617          	auipc	a2,0x2
ffffffffc0204e70:	5f460613          	addi	a2,a2,1524 # ffffffffc0207460 <default_pmm_manager+0xdf0>
ffffffffc0204e74:	3c200593          	li	a1,962
ffffffffc0204e78:	00002517          	auipc	a0,0x2
ffffffffc0204e7c:	22050513          	addi	a0,a0,544 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204e80:	e12fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204e84:	00002617          	auipc	a2,0x2
ffffffffc0204e88:	5bc60613          	addi	a2,a2,1468 # ffffffffc0207440 <default_pmm_manager+0xdd0>
ffffffffc0204e8c:	3b300593          	li	a1,947
ffffffffc0204e90:	00002517          	auipc	a0,0x2
ffffffffc0204e94:	20850513          	addi	a0,a0,520 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204e98:	dfafb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204e9c:	00002697          	auipc	a3,0x2
ffffffffc0204ea0:	61468693          	addi	a3,a3,1556 # ffffffffc02074b0 <default_pmm_manager+0xe40>
ffffffffc0204ea4:	00001617          	auipc	a2,0x1
ffffffffc0204ea8:	41c60613          	addi	a2,a2,1052 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204eac:	3c900593          	li	a1,969
ffffffffc0204eb0:	00002517          	auipc	a0,0x2
ffffffffc0204eb4:	1e850513          	addi	a0,a0,488 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204eb8:	ddafb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204ebc:	00002697          	auipc	a3,0x2
ffffffffc0204ec0:	5cc68693          	addi	a3,a3,1484 # ffffffffc0207488 <default_pmm_manager+0xe18>
ffffffffc0204ec4:	00001617          	auipc	a2,0x1
ffffffffc0204ec8:	3fc60613          	addi	a2,a2,1020 # ffffffffc02062c0 <commands+0x818>
ffffffffc0204ecc:	3c800593          	li	a1,968
ffffffffc0204ed0:	00002517          	auipc	a0,0x2
ffffffffc0204ed4:	1c850513          	addi	a0,a0,456 # ffffffffc0207098 <default_pmm_manager+0xa28>
ffffffffc0204ed8:	dbafb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204edc <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204edc:	1141                	addi	sp,sp,-16
ffffffffc0204ede:	e022                	sd	s0,0(sp)
ffffffffc0204ee0:	e406                	sd	ra,8(sp)
ffffffffc0204ee2:	000c2417          	auipc	s0,0xc2
ffffffffc0204ee6:	d6640413          	addi	s0,s0,-666 # ffffffffc02c6c48 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204eea:	6018                	ld	a4,0(s0)
ffffffffc0204eec:	6f1c                	ld	a5,24(a4)
ffffffffc0204eee:	dffd                	beqz	a5,ffffffffc0204eec <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204ef0:	2be000ef          	jal	ra,ffffffffc02051ae <schedule>
ffffffffc0204ef4:	bfdd                	j	ffffffffc0204eea <cpu_idle+0xe>

ffffffffc0204ef6 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204ef6:	1141                	addi	sp,sp,-16
ffffffffc0204ef8:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204efa:	85aa                	mv	a1,a0
{
ffffffffc0204efc:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204efe:	00002517          	auipc	a0,0x2
ffffffffc0204f02:	5da50513          	addi	a0,a0,1498 # ffffffffc02074d8 <default_pmm_manager+0xe68>
{
ffffffffc0204f06:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f08:	a90fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc0204f0c:	000c2797          	auipc	a5,0xc2
ffffffffc0204f10:	d3c7b783          	ld	a5,-708(a5) # ffffffffc02c6c48 <current>
    if (priority == 0)
ffffffffc0204f14:	e801                	bnez	s0,ffffffffc0204f24 <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc0204f16:	60a2                	ld	ra,8(sp)
ffffffffc0204f18:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc0204f1a:	4705                	li	a4,1
ffffffffc0204f1c:	14e7a223          	sw	a4,324(a5)
}
ffffffffc0204f20:	0141                	addi	sp,sp,16
ffffffffc0204f22:	8082                	ret
ffffffffc0204f24:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc0204f26:	1487a223          	sw	s0,324(a5)
}
ffffffffc0204f2a:	6402                	ld	s0,0(sp)
ffffffffc0204f2c:	0141                	addi	sp,sp,16
ffffffffc0204f2e:	8082                	ret

ffffffffc0204f30 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204f30:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204f34:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204f38:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204f3a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204f3c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204f40:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204f44:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204f48:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204f4c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204f50:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204f54:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204f58:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204f5c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204f60:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204f64:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204f68:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204f6c:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204f6e:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204f70:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204f74:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204f78:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204f7c:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204f80:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204f84:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204f88:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204f8c:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204f90:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204f94:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204f98:	8082                	ret

ffffffffc0204f9a <RR_init>:
    elm->prev = elm->next = elm;
ffffffffc0204f9a:	e508                	sd	a0,8(a0)
ffffffffc0204f9c:	e108                	sd	a0,0(a0)
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_init(&(rq->run_list));
    rq->proc_num = 0;
ffffffffc0204f9e:	00052823          	sw	zero,16(a0)
}
ffffffffc0204fa2:	8082                	ret

ffffffffc0204fa4 <RR_pick_next>:
    return listelm->next;
ffffffffc0204fa4:	651c                	ld	a5,8(a0)
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
ffffffffc0204fa6:	00f50563          	beq	a0,a5,ffffffffc0204fb0 <RR_pick_next+0xc>
        return le2proc(le, run_link);
ffffffffc0204faa:	ef078513          	addi	a0,a5,-272
ffffffffc0204fae:	8082                	ret
    }
    return NULL;
ffffffffc0204fb0:	4501                	li	a0,0
}
ffffffffc0204fb2:	8082                	ret

ffffffffc0204fb4 <RR_proc_tick>:
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    if (proc->time_slice > 0) {
ffffffffc0204fb4:	1205a783          	lw	a5,288(a1)
ffffffffc0204fb8:	00f05563          	blez	a5,ffffffffc0204fc2 <RR_proc_tick+0xe>
        proc->time_slice--;
ffffffffc0204fbc:	37fd                	addiw	a5,a5,-1
ffffffffc0204fbe:	12f5a023          	sw	a5,288(a1)
    }
    if (proc->time_slice == 0) {
ffffffffc0204fc2:	e399                	bnez	a5,ffffffffc0204fc8 <RR_proc_tick+0x14>
        proc->need_resched = 1;
ffffffffc0204fc4:	4785                	li	a5,1
ffffffffc0204fc6:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0204fc8:	8082                	ret

ffffffffc0204fca <RR_dequeue>:
    return list->next == list;
ffffffffc0204fca:	1185b703          	ld	a4,280(a1)
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc0204fce:	11058793          	addi	a5,a1,272
ffffffffc0204fd2:	02e78363          	beq	a5,a4,ffffffffc0204ff8 <RR_dequeue+0x2e>
ffffffffc0204fd6:	1085b683          	ld	a3,264(a1)
ffffffffc0204fda:	00a69f63          	bne	a3,a0,ffffffffc0204ff8 <RR_dequeue+0x2e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204fde:	1105b503          	ld	a0,272(a1)
    rq->proc_num--;
ffffffffc0204fe2:	4a90                	lw	a2,16(a3)
    prev->next = next;
ffffffffc0204fe4:	e518                	sd	a4,8(a0)
    next->prev = prev;
ffffffffc0204fe6:	e308                	sd	a0,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0204fe8:	10f5bc23          	sd	a5,280(a1)
ffffffffc0204fec:	10f5b823          	sd	a5,272(a1)
ffffffffc0204ff0:	fff6079b          	addiw	a5,a2,-1
ffffffffc0204ff4:	ca9c                	sw	a5,16(a3)
ffffffffc0204ff6:	8082                	ret
{
ffffffffc0204ff8:	1141                	addi	sp,sp,-16
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc0204ffa:	00002697          	auipc	a3,0x2
ffffffffc0204ffe:	4f668693          	addi	a3,a3,1270 # ffffffffc02074f0 <default_pmm_manager+0xe80>
ffffffffc0205002:	00001617          	auipc	a2,0x1
ffffffffc0205006:	2be60613          	addi	a2,a2,702 # ffffffffc02062c0 <commands+0x818>
ffffffffc020500a:	03c00593          	li	a1,60
ffffffffc020500e:	00002517          	auipc	a0,0x2
ffffffffc0205012:	51a50513          	addi	a0,a0,1306 # ffffffffc0207528 <default_pmm_manager+0xeb8>
{
ffffffffc0205016:	e406                	sd	ra,8(sp)
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc0205018:	c7afb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020501c <RR_enqueue>:
    assert(list_empty(&(proc->run_link)));
ffffffffc020501c:	1185b703          	ld	a4,280(a1)
ffffffffc0205020:	11058793          	addi	a5,a1,272
ffffffffc0205024:	02e79d63          	bne	a5,a4,ffffffffc020505e <RR_enqueue+0x42>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205028:	6118                	ld	a4,0(a0)
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc020502a:	1205a683          	lw	a3,288(a1)
    prev->next = next->prev = elm;
ffffffffc020502e:	e11c                	sd	a5,0(a0)
ffffffffc0205030:	e71c                	sd	a5,8(a4)
    elm->next = next;
ffffffffc0205032:	10a5bc23          	sd	a0,280(a1)
    elm->prev = prev;
ffffffffc0205036:	10e5b823          	sd	a4,272(a1)
ffffffffc020503a:	495c                	lw	a5,20(a0)
ffffffffc020503c:	ea89                	bnez	a3,ffffffffc020504e <RR_enqueue+0x32>
        proc->time_slice = rq->max_time_slice;
ffffffffc020503e:	12f5a023          	sw	a5,288(a1)
    rq->proc_num++;
ffffffffc0205042:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc0205044:	10a5b423          	sd	a0,264(a1)
    rq->proc_num++;
ffffffffc0205048:	2785                	addiw	a5,a5,1
ffffffffc020504a:	c91c                	sw	a5,16(a0)
ffffffffc020504c:	8082                	ret
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc020504e:	fed7c8e3          	blt	a5,a3,ffffffffc020503e <RR_enqueue+0x22>
    rq->proc_num++;
ffffffffc0205052:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc0205054:	10a5b423          	sd	a0,264(a1)
    rq->proc_num++;
ffffffffc0205058:	2785                	addiw	a5,a5,1
ffffffffc020505a:	c91c                	sw	a5,16(a0)
ffffffffc020505c:	8082                	ret
{
ffffffffc020505e:	1141                	addi	sp,sp,-16
    assert(list_empty(&(proc->run_link)));
ffffffffc0205060:	00002697          	auipc	a3,0x2
ffffffffc0205064:	4e868693          	addi	a3,a3,1256 # ffffffffc0207548 <default_pmm_manager+0xed8>
ffffffffc0205068:	00001617          	auipc	a2,0x1
ffffffffc020506c:	25860613          	addi	a2,a2,600 # ffffffffc02062c0 <commands+0x818>
ffffffffc0205070:	02800593          	li	a1,40
ffffffffc0205074:	00002517          	auipc	a0,0x2
ffffffffc0205078:	4b450513          	addi	a0,a0,1204 # ffffffffc0207528 <default_pmm_manager+0xeb8>
{
ffffffffc020507c:	e406                	sd	ra,8(sp)
    assert(list_empty(&(proc->run_link)));
ffffffffc020507e:	c14fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205082 <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc0205082:	000c2797          	auipc	a5,0xc2
ffffffffc0205086:	bce7b783          	ld	a5,-1074(a5) # ffffffffc02c6c50 <idleproc>
{
ffffffffc020508a:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc020508c:	00a78c63          	beq	a5,a0,ffffffffc02050a4 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc0205090:	000c2797          	auipc	a5,0xc2
ffffffffc0205094:	be07b783          	ld	a5,-1056(a5) # ffffffffc02c6c70 <sched_class>
ffffffffc0205098:	779c                	ld	a5,40(a5)
ffffffffc020509a:	000c2517          	auipc	a0,0xc2
ffffffffc020509e:	bce53503          	ld	a0,-1074(a0) # ffffffffc02c6c68 <rq>
ffffffffc02050a2:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc02050a4:	4705                	li	a4,1
ffffffffc02050a6:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc02050a8:	8082                	ret

ffffffffc02050aa <sched_init>:

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc02050aa:	1141                	addi	sp,sp,-16
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc02050ac:	000bd717          	auipc	a4,0xbd
ffffffffc02050b0:	6ac70713          	addi	a4,a4,1708 # ffffffffc02c2758 <default_sched_class>
{
ffffffffc02050b4:	e022                	sd	s0,0(sp)
ffffffffc02050b6:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02050b8:	000c2797          	auipc	a5,0xc2
ffffffffc02050bc:	b2878793          	addi	a5,a5,-1240 # ffffffffc02c6be0 <timer_list>

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc02050c0:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc02050c2:	000c2517          	auipc	a0,0xc2
ffffffffc02050c6:	afe50513          	addi	a0,a0,-1282 # ffffffffc02c6bc0 <__rq>
ffffffffc02050ca:	e79c                	sd	a5,8(a5)
ffffffffc02050cc:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc02050ce:	4795                	li	a5,5
ffffffffc02050d0:	c95c                	sw	a5,20(a0)
    sched_class = &default_sched_class;
ffffffffc02050d2:	000c2417          	auipc	s0,0xc2
ffffffffc02050d6:	b9e40413          	addi	s0,s0,-1122 # ffffffffc02c6c70 <sched_class>
    rq = &__rq;
ffffffffc02050da:	000c2797          	auipc	a5,0xc2
ffffffffc02050de:	b8a7b723          	sd	a0,-1138(a5) # ffffffffc02c6c68 <rq>
    sched_class = &default_sched_class;
ffffffffc02050e2:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc02050e4:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02050e6:	601c                	ld	a5,0(s0)
}
ffffffffc02050e8:	6402                	ld	s0,0(sp)
ffffffffc02050ea:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02050ec:	638c                	ld	a1,0(a5)
ffffffffc02050ee:	00002517          	auipc	a0,0x2
ffffffffc02050f2:	48a50513          	addi	a0,a0,1162 # ffffffffc0207578 <default_pmm_manager+0xf08>
}
ffffffffc02050f6:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02050f8:	8a0fb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc02050fc <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02050fc:	4118                	lw	a4,0(a0)
{
ffffffffc02050fe:	1101                	addi	sp,sp,-32
ffffffffc0205100:	ec06                	sd	ra,24(sp)
ffffffffc0205102:	e822                	sd	s0,16(sp)
ffffffffc0205104:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205106:	478d                	li	a5,3
ffffffffc0205108:	08f70363          	beq	a4,a5,ffffffffc020518e <wakeup_proc+0x92>
ffffffffc020510c:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020510e:	100027f3          	csrr	a5,sstatus
ffffffffc0205112:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205114:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205116:	e7bd                	bnez	a5,ffffffffc0205184 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205118:	4789                	li	a5,2
ffffffffc020511a:	04f70863          	beq	a4,a5,ffffffffc020516a <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020511e:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205120:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc0205124:	000c2797          	auipc	a5,0xc2
ffffffffc0205128:	b247b783          	ld	a5,-1244(a5) # ffffffffc02c6c48 <current>
ffffffffc020512c:	02878363          	beq	a5,s0,ffffffffc0205152 <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc0205130:	000c2797          	auipc	a5,0xc2
ffffffffc0205134:	b207b783          	ld	a5,-1248(a5) # ffffffffc02c6c50 <idleproc>
ffffffffc0205138:	00f40d63          	beq	s0,a5,ffffffffc0205152 <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc020513c:	000c2797          	auipc	a5,0xc2
ffffffffc0205140:	b347b783          	ld	a5,-1228(a5) # ffffffffc02c6c70 <sched_class>
ffffffffc0205144:	6b9c                	ld	a5,16(a5)
ffffffffc0205146:	85a2                	mv	a1,s0
ffffffffc0205148:	000c2517          	auipc	a0,0xc2
ffffffffc020514c:	b2053503          	ld	a0,-1248(a0) # ffffffffc02c6c68 <rq>
ffffffffc0205150:	9782                	jalr	a5
    if (flag)
ffffffffc0205152:	e491                	bnez	s1,ffffffffc020515e <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205154:	60e2                	ld	ra,24(sp)
ffffffffc0205156:	6442                	ld	s0,16(sp)
ffffffffc0205158:	64a2                	ld	s1,8(sp)
ffffffffc020515a:	6105                	addi	sp,sp,32
ffffffffc020515c:	8082                	ret
ffffffffc020515e:	6442                	ld	s0,16(sp)
ffffffffc0205160:	60e2                	ld	ra,24(sp)
ffffffffc0205162:	64a2                	ld	s1,8(sp)
ffffffffc0205164:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205166:	843fb06f          	j	ffffffffc02009a8 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020516a:	00002617          	auipc	a2,0x2
ffffffffc020516e:	45e60613          	addi	a2,a2,1118 # ffffffffc02075c8 <default_pmm_manager+0xf58>
ffffffffc0205172:	05100593          	li	a1,81
ffffffffc0205176:	00002517          	auipc	a0,0x2
ffffffffc020517a:	43a50513          	addi	a0,a0,1082 # ffffffffc02075b0 <default_pmm_manager+0xf40>
ffffffffc020517e:	b7cfb0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc0205182:	bfc1                	j	ffffffffc0205152 <wakeup_proc+0x56>
        intr_disable();
ffffffffc0205184:	82bfb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205188:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020518a:	4485                	li	s1,1
ffffffffc020518c:	b771                	j	ffffffffc0205118 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020518e:	00002697          	auipc	a3,0x2
ffffffffc0205192:	40268693          	addi	a3,a3,1026 # ffffffffc0207590 <default_pmm_manager+0xf20>
ffffffffc0205196:	00001617          	auipc	a2,0x1
ffffffffc020519a:	12a60613          	addi	a2,a2,298 # ffffffffc02062c0 <commands+0x818>
ffffffffc020519e:	04200593          	li	a1,66
ffffffffc02051a2:	00002517          	auipc	a0,0x2
ffffffffc02051a6:	40e50513          	addi	a0,a0,1038 # ffffffffc02075b0 <default_pmm_manager+0xf40>
ffffffffc02051aa:	ae8fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02051ae <schedule>:

void schedule(void)
{
ffffffffc02051ae:	7179                	addi	sp,sp,-48
ffffffffc02051b0:	f406                	sd	ra,40(sp)
ffffffffc02051b2:	f022                	sd	s0,32(sp)
ffffffffc02051b4:	ec26                	sd	s1,24(sp)
ffffffffc02051b6:	e84a                	sd	s2,16(sp)
ffffffffc02051b8:	e44e                	sd	s3,8(sp)
ffffffffc02051ba:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051bc:	100027f3          	csrr	a5,sstatus
ffffffffc02051c0:	8b89                	andi	a5,a5,2
ffffffffc02051c2:	4a01                	li	s4,0
ffffffffc02051c4:	e3cd                	bnez	a5,ffffffffc0205266 <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02051c6:	000c2497          	auipc	s1,0xc2
ffffffffc02051ca:	a8248493          	addi	s1,s1,-1406 # ffffffffc02c6c48 <current>
ffffffffc02051ce:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc02051d0:	000c2997          	auipc	s3,0xc2
ffffffffc02051d4:	aa098993          	addi	s3,s3,-1376 # ffffffffc02c6c70 <sched_class>
ffffffffc02051d8:	000c2917          	auipc	s2,0xc2
ffffffffc02051dc:	a9090913          	addi	s2,s2,-1392 # ffffffffc02c6c68 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc02051e0:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc02051e2:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc02051e6:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc02051e8:	0009b783          	ld	a5,0(s3)
ffffffffc02051ec:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc02051f0:	04e68e63          	beq	a3,a4,ffffffffc020524c <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc02051f4:	739c                	ld	a5,32(a5)
ffffffffc02051f6:	9782                	jalr	a5
ffffffffc02051f8:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc02051fa:	c521                	beqz	a0,ffffffffc0205242 <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc02051fc:	0009b783          	ld	a5,0(s3)
ffffffffc0205200:	00093503          	ld	a0,0(s2)
ffffffffc0205204:	85a2                	mv	a1,s0
ffffffffc0205206:	6f9c                	ld	a5,24(a5)
ffffffffc0205208:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020520a:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc020520c:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc020520e:	2785                	addiw	a5,a5,1
ffffffffc0205210:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc0205212:	00870563          	beq	a4,s0,ffffffffc020521c <schedule+0x6e>
        {
            proc_run(next);
ffffffffc0205216:	8522                	mv	a0,s0
ffffffffc0205218:	bb9fe0ef          	jal	ra,ffffffffc0203dd0 <proc_run>
    if (flag)
ffffffffc020521c:	000a1a63          	bnez	s4,ffffffffc0205230 <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205220:	70a2                	ld	ra,40(sp)
ffffffffc0205222:	7402                	ld	s0,32(sp)
ffffffffc0205224:	64e2                	ld	s1,24(sp)
ffffffffc0205226:	6942                	ld	s2,16(sp)
ffffffffc0205228:	69a2                	ld	s3,8(sp)
ffffffffc020522a:	6a02                	ld	s4,0(sp)
ffffffffc020522c:	6145                	addi	sp,sp,48
ffffffffc020522e:	8082                	ret
ffffffffc0205230:	7402                	ld	s0,32(sp)
ffffffffc0205232:	70a2                	ld	ra,40(sp)
ffffffffc0205234:	64e2                	ld	s1,24(sp)
ffffffffc0205236:	6942                	ld	s2,16(sp)
ffffffffc0205238:	69a2                	ld	s3,8(sp)
ffffffffc020523a:	6a02                	ld	s4,0(sp)
ffffffffc020523c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020523e:	f6afb06f          	j	ffffffffc02009a8 <intr_enable>
            next = idleproc;
ffffffffc0205242:	000c2417          	auipc	s0,0xc2
ffffffffc0205246:	a0e43403          	ld	s0,-1522(s0) # ffffffffc02c6c50 <idleproc>
ffffffffc020524a:	b7c1                	j	ffffffffc020520a <schedule+0x5c>
    if (proc != idleproc)
ffffffffc020524c:	000c2717          	auipc	a4,0xc2
ffffffffc0205250:	a0473703          	ld	a4,-1532(a4) # ffffffffc02c6c50 <idleproc>
ffffffffc0205254:	fae580e3          	beq	a1,a4,ffffffffc02051f4 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc0205258:	6b9c                	ld	a5,16(a5)
ffffffffc020525a:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc020525c:	0009b783          	ld	a5,0(s3)
ffffffffc0205260:	00093503          	ld	a0,0(s2)
ffffffffc0205264:	bf41                	j	ffffffffc02051f4 <schedule+0x46>
        intr_disable();
ffffffffc0205266:	f48fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc020526a:	4a05                	li	s4,1
ffffffffc020526c:	bfa9                	j	ffffffffc02051c6 <schedule+0x18>

ffffffffc020526e <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020526e:	000c2797          	auipc	a5,0xc2
ffffffffc0205272:	9da7b783          	ld	a5,-1574(a5) # ffffffffc02c6c48 <current>
}
ffffffffc0205276:	43c8                	lw	a0,4(a5)
ffffffffc0205278:	8082                	ret

ffffffffc020527a <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020527a:	4501                	li	a0,0
ffffffffc020527c:	8082                	ret

ffffffffc020527e <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc020527e:	000c2797          	auipc	a5,0xc2
ffffffffc0205282:	97a7b783          	ld	a5,-1670(a5) # ffffffffc02c6bf8 <ticks>
ffffffffc0205286:	0027951b          	slliw	a0,a5,0x2
ffffffffc020528a:	9d3d                	addw	a0,a0,a5
}
ffffffffc020528c:	0015151b          	slliw	a0,a0,0x1
ffffffffc0205290:	8082                	ret

ffffffffc0205292 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc0205292:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc0205294:	1141                	addi	sp,sp,-16
ffffffffc0205296:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc0205298:	c5fff0ef          	jal	ra,ffffffffc0204ef6 <lab6_set_priority>
    return 0;
}
ffffffffc020529c:	60a2                	ld	ra,8(sp)
ffffffffc020529e:	4501                	li	a0,0
ffffffffc02052a0:	0141                	addi	sp,sp,16
ffffffffc02052a2:	8082                	ret

ffffffffc02052a4 <sys_putc>:
    cputchar(c);
ffffffffc02052a4:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052a6:	1141                	addi	sp,sp,-16
ffffffffc02052a8:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052aa:	f25fa0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc02052ae:	60a2                	ld	ra,8(sp)
ffffffffc02052b0:	4501                	li	a0,0
ffffffffc02052b2:	0141                	addi	sp,sp,16
ffffffffc02052b4:	8082                	ret

ffffffffc02052b6 <sys_kill>:
    return do_kill(pid);
ffffffffc02052b6:	4108                	lw	a0,0(a0)
ffffffffc02052b8:	a11ff06f          	j	ffffffffc0204cc8 <do_kill>

ffffffffc02052bc <sys_yield>:
    return do_yield();
ffffffffc02052bc:	9bfff06f          	j	ffffffffc0204c7a <do_yield>

ffffffffc02052c0 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052c0:	6d14                	ld	a3,24(a0)
ffffffffc02052c2:	6910                	ld	a2,16(a0)
ffffffffc02052c4:	650c                	ld	a1,8(a0)
ffffffffc02052c6:	6108                	ld	a0,0(a0)
ffffffffc02052c8:	c08ff06f          	j	ffffffffc02046d0 <do_execve>

ffffffffc02052cc <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052cc:	650c                	ld	a1,8(a0)
ffffffffc02052ce:	4108                	lw	a0,0(a0)
ffffffffc02052d0:	9bbff06f          	j	ffffffffc0204c8a <do_wait>

ffffffffc02052d4 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052d4:	000c2797          	auipc	a5,0xc2
ffffffffc02052d8:	9747b783          	ld	a5,-1676(a5) # ffffffffc02c6c48 <current>
ffffffffc02052dc:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052de:	4501                	li	a0,0
ffffffffc02052e0:	6a0c                	ld	a1,16(a2)
ffffffffc02052e2:	b5bfe06f          	j	ffffffffc0203e3c <do_fork>

ffffffffc02052e6 <sys_exit>:
    return do_exit(error_code);
ffffffffc02052e6:	4108                	lw	a0,0(a0)
ffffffffc02052e8:	fa9fe06f          	j	ffffffffc0204290 <do_exit>

ffffffffc02052ec <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02052ec:	715d                	addi	sp,sp,-80
ffffffffc02052ee:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02052f0:	000c2497          	auipc	s1,0xc2
ffffffffc02052f4:	95848493          	addi	s1,s1,-1704 # ffffffffc02c6c48 <current>
ffffffffc02052f8:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02052fa:	e0a2                	sd	s0,64(sp)
ffffffffc02052fc:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02052fe:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205300:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205302:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc0205306:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020530a:	0327ee63          	bltu	a5,s2,ffffffffc0205346 <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc020530e:	00391713          	slli	a4,s2,0x3
ffffffffc0205312:	00002797          	auipc	a5,0x2
ffffffffc0205316:	31e78793          	addi	a5,a5,798 # ffffffffc0207630 <syscalls>
ffffffffc020531a:	97ba                	add	a5,a5,a4
ffffffffc020531c:	639c                	ld	a5,0(a5)
ffffffffc020531e:	c785                	beqz	a5,ffffffffc0205346 <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc0205320:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205322:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205324:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205326:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205328:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020532a:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc020532c:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020532e:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205330:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205332:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205334:	0028                	addi	a0,sp,8
ffffffffc0205336:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205338:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020533a:	e828                	sd	a0,80(s0)
}
ffffffffc020533c:	6406                	ld	s0,64(sp)
ffffffffc020533e:	74e2                	ld	s1,56(sp)
ffffffffc0205340:	7942                	ld	s2,48(sp)
ffffffffc0205342:	6161                	addi	sp,sp,80
ffffffffc0205344:	8082                	ret
    print_trapframe(tf);
ffffffffc0205346:	8522                	mv	a0,s0
ffffffffc0205348:	857fb0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020534c:	609c                	ld	a5,0(s1)
ffffffffc020534e:	86ca                	mv	a3,s2
ffffffffc0205350:	00002617          	auipc	a2,0x2
ffffffffc0205354:	29860613          	addi	a2,a2,664 # ffffffffc02075e8 <default_pmm_manager+0xf78>
ffffffffc0205358:	43d8                	lw	a4,4(a5)
ffffffffc020535a:	06c00593          	li	a1,108
ffffffffc020535e:	0b478793          	addi	a5,a5,180
ffffffffc0205362:	00002517          	auipc	a0,0x2
ffffffffc0205366:	2b650513          	addi	a0,a0,694 # ffffffffc0207618 <default_pmm_manager+0xfa8>
ffffffffc020536a:	928fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020536e <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020536e:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205372:	2785                	addiw	a5,a5,1
ffffffffc0205374:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205378:	02000793          	li	a5,32
ffffffffc020537c:	9f8d                	subw	a5,a5,a1
}
ffffffffc020537e:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205382:	8082                	ret

ffffffffc0205384 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205384:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205388:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020538a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020538e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205390:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205394:	f022                	sd	s0,32(sp)
ffffffffc0205396:	ec26                	sd	s1,24(sp)
ffffffffc0205398:	e84a                	sd	s2,16(sp)
ffffffffc020539a:	f406                	sd	ra,40(sp)
ffffffffc020539c:	e44e                	sd	s3,8(sp)
ffffffffc020539e:	84aa                	mv	s1,a0
ffffffffc02053a0:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053a2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02053a6:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02053a8:	03067e63          	bgeu	a2,a6,ffffffffc02053e4 <printnum+0x60>
ffffffffc02053ac:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053ae:	00805763          	blez	s0,ffffffffc02053bc <printnum+0x38>
ffffffffc02053b2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053b4:	85ca                	mv	a1,s2
ffffffffc02053b6:	854e                	mv	a0,s3
ffffffffc02053b8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053ba:	fc65                	bnez	s0,ffffffffc02053b2 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053bc:	1a02                	slli	s4,s4,0x20
ffffffffc02053be:	00003797          	auipc	a5,0x3
ffffffffc02053c2:	a7278793          	addi	a5,a5,-1422 # ffffffffc0207e30 <syscalls+0x800>
ffffffffc02053c6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02053ca:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053cc:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053ce:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02053d2:	70a2                	ld	ra,40(sp)
ffffffffc02053d4:	69a2                	ld	s3,8(sp)
ffffffffc02053d6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053d8:	85ca                	mv	a1,s2
ffffffffc02053da:	87a6                	mv	a5,s1
}
ffffffffc02053dc:	6942                	ld	s2,16(sp)
ffffffffc02053de:	64e2                	ld	s1,24(sp)
ffffffffc02053e0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053e2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053e4:	03065633          	divu	a2,a2,a6
ffffffffc02053e8:	8722                	mv	a4,s0
ffffffffc02053ea:	f9bff0ef          	jal	ra,ffffffffc0205384 <printnum>
ffffffffc02053ee:	b7f9                	j	ffffffffc02053bc <printnum+0x38>

ffffffffc02053f0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02053f0:	7119                	addi	sp,sp,-128
ffffffffc02053f2:	f4a6                	sd	s1,104(sp)
ffffffffc02053f4:	f0ca                	sd	s2,96(sp)
ffffffffc02053f6:	ecce                	sd	s3,88(sp)
ffffffffc02053f8:	e8d2                	sd	s4,80(sp)
ffffffffc02053fa:	e4d6                	sd	s5,72(sp)
ffffffffc02053fc:	e0da                	sd	s6,64(sp)
ffffffffc02053fe:	fc5e                	sd	s7,56(sp)
ffffffffc0205400:	f06a                	sd	s10,32(sp)
ffffffffc0205402:	fc86                	sd	ra,120(sp)
ffffffffc0205404:	f8a2                	sd	s0,112(sp)
ffffffffc0205406:	f862                	sd	s8,48(sp)
ffffffffc0205408:	f466                	sd	s9,40(sp)
ffffffffc020540a:	ec6e                	sd	s11,24(sp)
ffffffffc020540c:	892a                	mv	s2,a0
ffffffffc020540e:	84ae                	mv	s1,a1
ffffffffc0205410:	8d32                	mv	s10,a2
ffffffffc0205412:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205414:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205418:	5b7d                	li	s6,-1
ffffffffc020541a:	00003a97          	auipc	s5,0x3
ffffffffc020541e:	a42a8a93          	addi	s5,s5,-1470 # ffffffffc0207e5c <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205422:	00003b97          	auipc	s7,0x3
ffffffffc0205426:	c56b8b93          	addi	s7,s7,-938 # ffffffffc0208078 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020542a:	000d4503          	lbu	a0,0(s10)
ffffffffc020542e:	001d0413          	addi	s0,s10,1
ffffffffc0205432:	01350a63          	beq	a0,s3,ffffffffc0205446 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205436:	c121                	beqz	a0,ffffffffc0205476 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205438:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020543a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020543c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020543e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205442:	ff351ae3          	bne	a0,s3,ffffffffc0205436 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205446:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020544a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020544e:	4c81                	li	s9,0
ffffffffc0205450:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205452:	5c7d                	li	s8,-1
ffffffffc0205454:	5dfd                	li	s11,-1
ffffffffc0205456:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020545a:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020545c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205460:	0ff5f593          	zext.b	a1,a1
ffffffffc0205464:	00140d13          	addi	s10,s0,1
ffffffffc0205468:	04b56263          	bltu	a0,a1,ffffffffc02054ac <vprintfmt+0xbc>
ffffffffc020546c:	058a                	slli	a1,a1,0x2
ffffffffc020546e:	95d6                	add	a1,a1,s5
ffffffffc0205470:	4194                	lw	a3,0(a1)
ffffffffc0205472:	96d6                	add	a3,a3,s5
ffffffffc0205474:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205476:	70e6                	ld	ra,120(sp)
ffffffffc0205478:	7446                	ld	s0,112(sp)
ffffffffc020547a:	74a6                	ld	s1,104(sp)
ffffffffc020547c:	7906                	ld	s2,96(sp)
ffffffffc020547e:	69e6                	ld	s3,88(sp)
ffffffffc0205480:	6a46                	ld	s4,80(sp)
ffffffffc0205482:	6aa6                	ld	s5,72(sp)
ffffffffc0205484:	6b06                	ld	s6,64(sp)
ffffffffc0205486:	7be2                	ld	s7,56(sp)
ffffffffc0205488:	7c42                	ld	s8,48(sp)
ffffffffc020548a:	7ca2                	ld	s9,40(sp)
ffffffffc020548c:	7d02                	ld	s10,32(sp)
ffffffffc020548e:	6de2                	ld	s11,24(sp)
ffffffffc0205490:	6109                	addi	sp,sp,128
ffffffffc0205492:	8082                	ret
            padc = '0';
ffffffffc0205494:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205496:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020549a:	846a                	mv	s0,s10
ffffffffc020549c:	00140d13          	addi	s10,s0,1
ffffffffc02054a0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054a4:	0ff5f593          	zext.b	a1,a1
ffffffffc02054a8:	fcb572e3          	bgeu	a0,a1,ffffffffc020546c <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02054ac:	85a6                	mv	a1,s1
ffffffffc02054ae:	02500513          	li	a0,37
ffffffffc02054b2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02054b4:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054b8:	8d22                	mv	s10,s0
ffffffffc02054ba:	f73788e3          	beq	a5,s3,ffffffffc020542a <vprintfmt+0x3a>
ffffffffc02054be:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02054c2:	1d7d                	addi	s10,s10,-1
ffffffffc02054c4:	ff379de3          	bne	a5,s3,ffffffffc02054be <vprintfmt+0xce>
ffffffffc02054c8:	b78d                	j	ffffffffc020542a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02054ca:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02054ce:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054d2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02054d4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02054d8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054dc:	02d86463          	bltu	a6,a3,ffffffffc0205504 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02054e0:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02054e4:	002c169b          	slliw	a3,s8,0x2
ffffffffc02054e8:	0186873b          	addw	a4,a3,s8
ffffffffc02054ec:	0017171b          	slliw	a4,a4,0x1
ffffffffc02054f0:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02054f2:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02054f6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02054f8:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02054fc:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205500:	fed870e3          	bgeu	a6,a3,ffffffffc02054e0 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205504:	f40ddce3          	bgez	s11,ffffffffc020545c <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205508:	8de2                	mv	s11,s8
ffffffffc020550a:	5c7d                	li	s8,-1
ffffffffc020550c:	bf81                	j	ffffffffc020545c <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020550e:	fffdc693          	not	a3,s11
ffffffffc0205512:	96fd                	srai	a3,a3,0x3f
ffffffffc0205514:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205518:	00144603          	lbu	a2,1(s0)
ffffffffc020551c:	2d81                	sext.w	s11,s11
ffffffffc020551e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205520:	bf35                	j	ffffffffc020545c <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205522:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205526:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020552a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020552c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020552e:	bfd9                	j	ffffffffc0205504 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205530:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205532:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205536:	01174463          	blt	a4,a7,ffffffffc020553e <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020553a:	1a088e63          	beqz	a7,ffffffffc02056f6 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020553e:	000a3603          	ld	a2,0(s4)
ffffffffc0205542:	46c1                	li	a3,16
ffffffffc0205544:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205546:	2781                	sext.w	a5,a5
ffffffffc0205548:	876e                	mv	a4,s11
ffffffffc020554a:	85a6                	mv	a1,s1
ffffffffc020554c:	854a                	mv	a0,s2
ffffffffc020554e:	e37ff0ef          	jal	ra,ffffffffc0205384 <printnum>
            break;
ffffffffc0205552:	bde1                	j	ffffffffc020542a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205554:	000a2503          	lw	a0,0(s4)
ffffffffc0205558:	85a6                	mv	a1,s1
ffffffffc020555a:	0a21                	addi	s4,s4,8
ffffffffc020555c:	9902                	jalr	s2
            break;
ffffffffc020555e:	b5f1                	j	ffffffffc020542a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205560:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205562:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205566:	01174463          	blt	a4,a7,ffffffffc020556e <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020556a:	18088163          	beqz	a7,ffffffffc02056ec <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020556e:	000a3603          	ld	a2,0(s4)
ffffffffc0205572:	46a9                	li	a3,10
ffffffffc0205574:	8a2e                	mv	s4,a1
ffffffffc0205576:	bfc1                	j	ffffffffc0205546 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205578:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020557c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020557e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205580:	bdf1                	j	ffffffffc020545c <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205582:	85a6                	mv	a1,s1
ffffffffc0205584:	02500513          	li	a0,37
ffffffffc0205588:	9902                	jalr	s2
            break;
ffffffffc020558a:	b545                	j	ffffffffc020542a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020558c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205590:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205592:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205594:	b5e1                	j	ffffffffc020545c <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205596:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205598:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020559c:	01174463          	blt	a4,a7,ffffffffc02055a4 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02055a0:	14088163          	beqz	a7,ffffffffc02056e2 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02055a4:	000a3603          	ld	a2,0(s4)
ffffffffc02055a8:	46a1                	li	a3,8
ffffffffc02055aa:	8a2e                	mv	s4,a1
ffffffffc02055ac:	bf69                	j	ffffffffc0205546 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02055ae:	03000513          	li	a0,48
ffffffffc02055b2:	85a6                	mv	a1,s1
ffffffffc02055b4:	e03e                	sd	a5,0(sp)
ffffffffc02055b6:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02055b8:	85a6                	mv	a1,s1
ffffffffc02055ba:	07800513          	li	a0,120
ffffffffc02055be:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055c0:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055c2:	6782                	ld	a5,0(sp)
ffffffffc02055c4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055c6:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02055ca:	bfb5                	j	ffffffffc0205546 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055cc:	000a3403          	ld	s0,0(s4)
ffffffffc02055d0:	008a0713          	addi	a4,s4,8
ffffffffc02055d4:	e03a                	sd	a4,0(sp)
ffffffffc02055d6:	14040263          	beqz	s0,ffffffffc020571a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02055da:	0fb05763          	blez	s11,ffffffffc02056c8 <vprintfmt+0x2d8>
ffffffffc02055de:	02d00693          	li	a3,45
ffffffffc02055e2:	0cd79163          	bne	a5,a3,ffffffffc02056a4 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055e6:	00044783          	lbu	a5,0(s0)
ffffffffc02055ea:	0007851b          	sext.w	a0,a5
ffffffffc02055ee:	cf85                	beqz	a5,ffffffffc0205626 <vprintfmt+0x236>
ffffffffc02055f0:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055f4:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055f8:	000c4563          	bltz	s8,ffffffffc0205602 <vprintfmt+0x212>
ffffffffc02055fc:	3c7d                	addiw	s8,s8,-1
ffffffffc02055fe:	036c0263          	beq	s8,s6,ffffffffc0205622 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205602:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205604:	0e0c8e63          	beqz	s9,ffffffffc0205700 <vprintfmt+0x310>
ffffffffc0205608:	3781                	addiw	a5,a5,-32
ffffffffc020560a:	0ef47b63          	bgeu	s0,a5,ffffffffc0205700 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020560e:	03f00513          	li	a0,63
ffffffffc0205612:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205614:	000a4783          	lbu	a5,0(s4)
ffffffffc0205618:	3dfd                	addiw	s11,s11,-1
ffffffffc020561a:	0a05                	addi	s4,s4,1
ffffffffc020561c:	0007851b          	sext.w	a0,a5
ffffffffc0205620:	ffe1                	bnez	a5,ffffffffc02055f8 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205622:	01b05963          	blez	s11,ffffffffc0205634 <vprintfmt+0x244>
ffffffffc0205626:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205628:	85a6                	mv	a1,s1
ffffffffc020562a:	02000513          	li	a0,32
ffffffffc020562e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205630:	fe0d9be3          	bnez	s11,ffffffffc0205626 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205634:	6a02                	ld	s4,0(sp)
ffffffffc0205636:	bbd5                	j	ffffffffc020542a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205638:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020563a:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020563e:	01174463          	blt	a4,a7,ffffffffc0205646 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205642:	08088d63          	beqz	a7,ffffffffc02056dc <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205646:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020564a:	0a044d63          	bltz	s0,ffffffffc0205704 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020564e:	8622                	mv	a2,s0
ffffffffc0205650:	8a66                	mv	s4,s9
ffffffffc0205652:	46a9                	li	a3,10
ffffffffc0205654:	bdcd                	j	ffffffffc0205546 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205656:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020565a:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020565c:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020565e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205662:	8fb5                	xor	a5,a5,a3
ffffffffc0205664:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205668:	02d74163          	blt	a4,a3,ffffffffc020568a <vprintfmt+0x29a>
ffffffffc020566c:	00369793          	slli	a5,a3,0x3
ffffffffc0205670:	97de                	add	a5,a5,s7
ffffffffc0205672:	639c                	ld	a5,0(a5)
ffffffffc0205674:	cb99                	beqz	a5,ffffffffc020568a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205676:	86be                	mv	a3,a5
ffffffffc0205678:	00000617          	auipc	a2,0x0
ffffffffc020567c:	1f060613          	addi	a2,a2,496 # ffffffffc0205868 <etext+0x2a>
ffffffffc0205680:	85a6                	mv	a1,s1
ffffffffc0205682:	854a                	mv	a0,s2
ffffffffc0205684:	0ce000ef          	jal	ra,ffffffffc0205752 <printfmt>
ffffffffc0205688:	b34d                	j	ffffffffc020542a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020568a:	00002617          	auipc	a2,0x2
ffffffffc020568e:	7c660613          	addi	a2,a2,1990 # ffffffffc0207e50 <syscalls+0x820>
ffffffffc0205692:	85a6                	mv	a1,s1
ffffffffc0205694:	854a                	mv	a0,s2
ffffffffc0205696:	0bc000ef          	jal	ra,ffffffffc0205752 <printfmt>
ffffffffc020569a:	bb41                	j	ffffffffc020542a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020569c:	00002417          	auipc	s0,0x2
ffffffffc02056a0:	7ac40413          	addi	s0,s0,1964 # ffffffffc0207e48 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056a4:	85e2                	mv	a1,s8
ffffffffc02056a6:	8522                	mv	a0,s0
ffffffffc02056a8:	e43e                	sd	a5,8(sp)
ffffffffc02056aa:	0e2000ef          	jal	ra,ffffffffc020578c <strnlen>
ffffffffc02056ae:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02056b2:	01b05b63          	blez	s11,ffffffffc02056c8 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02056b6:	67a2                	ld	a5,8(sp)
ffffffffc02056b8:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056bc:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02056be:	85a6                	mv	a1,s1
ffffffffc02056c0:	8552                	mv	a0,s4
ffffffffc02056c2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056c4:	fe0d9ce3          	bnez	s11,ffffffffc02056bc <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056c8:	00044783          	lbu	a5,0(s0)
ffffffffc02056cc:	00140a13          	addi	s4,s0,1
ffffffffc02056d0:	0007851b          	sext.w	a0,a5
ffffffffc02056d4:	d3a5                	beqz	a5,ffffffffc0205634 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056d6:	05e00413          	li	s0,94
ffffffffc02056da:	bf39                	j	ffffffffc02055f8 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02056dc:	000a2403          	lw	s0,0(s4)
ffffffffc02056e0:	b7ad                	j	ffffffffc020564a <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02056e2:	000a6603          	lwu	a2,0(s4)
ffffffffc02056e6:	46a1                	li	a3,8
ffffffffc02056e8:	8a2e                	mv	s4,a1
ffffffffc02056ea:	bdb1                	j	ffffffffc0205546 <vprintfmt+0x156>
ffffffffc02056ec:	000a6603          	lwu	a2,0(s4)
ffffffffc02056f0:	46a9                	li	a3,10
ffffffffc02056f2:	8a2e                	mv	s4,a1
ffffffffc02056f4:	bd89                	j	ffffffffc0205546 <vprintfmt+0x156>
ffffffffc02056f6:	000a6603          	lwu	a2,0(s4)
ffffffffc02056fa:	46c1                	li	a3,16
ffffffffc02056fc:	8a2e                	mv	s4,a1
ffffffffc02056fe:	b5a1                	j	ffffffffc0205546 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205700:	9902                	jalr	s2
ffffffffc0205702:	bf09                	j	ffffffffc0205614 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205704:	85a6                	mv	a1,s1
ffffffffc0205706:	02d00513          	li	a0,45
ffffffffc020570a:	e03e                	sd	a5,0(sp)
ffffffffc020570c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020570e:	6782                	ld	a5,0(sp)
ffffffffc0205710:	8a66                	mv	s4,s9
ffffffffc0205712:	40800633          	neg	a2,s0
ffffffffc0205716:	46a9                	li	a3,10
ffffffffc0205718:	b53d                	j	ffffffffc0205546 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020571a:	03b05163          	blez	s11,ffffffffc020573c <vprintfmt+0x34c>
ffffffffc020571e:	02d00693          	li	a3,45
ffffffffc0205722:	f6d79de3          	bne	a5,a3,ffffffffc020569c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205726:	00002417          	auipc	s0,0x2
ffffffffc020572a:	72240413          	addi	s0,s0,1826 # ffffffffc0207e48 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020572e:	02800793          	li	a5,40
ffffffffc0205732:	02800513          	li	a0,40
ffffffffc0205736:	00140a13          	addi	s4,s0,1
ffffffffc020573a:	bd6d                	j	ffffffffc02055f4 <vprintfmt+0x204>
ffffffffc020573c:	00002a17          	auipc	s4,0x2
ffffffffc0205740:	70da0a13          	addi	s4,s4,1805 # ffffffffc0207e49 <syscalls+0x819>
ffffffffc0205744:	02800513          	li	a0,40
ffffffffc0205748:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020574c:	05e00413          	li	s0,94
ffffffffc0205750:	b565                	j	ffffffffc02055f8 <vprintfmt+0x208>

ffffffffc0205752 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205752:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205754:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205758:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020575a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020575c:	ec06                	sd	ra,24(sp)
ffffffffc020575e:	f83a                	sd	a4,48(sp)
ffffffffc0205760:	fc3e                	sd	a5,56(sp)
ffffffffc0205762:	e0c2                	sd	a6,64(sp)
ffffffffc0205764:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205766:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205768:	c89ff0ef          	jal	ra,ffffffffc02053f0 <vprintfmt>
}
ffffffffc020576c:	60e2                	ld	ra,24(sp)
ffffffffc020576e:	6161                	addi	sp,sp,80
ffffffffc0205770:	8082                	ret

ffffffffc0205772 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205772:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205776:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205778:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020577a:	cb81                	beqz	a5,ffffffffc020578a <strlen+0x18>
        cnt ++;
ffffffffc020577c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020577e:	00a707b3          	add	a5,a4,a0
ffffffffc0205782:	0007c783          	lbu	a5,0(a5)
ffffffffc0205786:	fbfd                	bnez	a5,ffffffffc020577c <strlen+0xa>
ffffffffc0205788:	8082                	ret
    }
    return cnt;
}
ffffffffc020578a:	8082                	ret

ffffffffc020578c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020578c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020578e:	e589                	bnez	a1,ffffffffc0205798 <strnlen+0xc>
ffffffffc0205790:	a811                	j	ffffffffc02057a4 <strnlen+0x18>
        cnt ++;
ffffffffc0205792:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205794:	00f58863          	beq	a1,a5,ffffffffc02057a4 <strnlen+0x18>
ffffffffc0205798:	00f50733          	add	a4,a0,a5
ffffffffc020579c:	00074703          	lbu	a4,0(a4)
ffffffffc02057a0:	fb6d                	bnez	a4,ffffffffc0205792 <strnlen+0x6>
ffffffffc02057a2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057a4:	852e                	mv	a0,a1
ffffffffc02057a6:	8082                	ret

ffffffffc02057a8 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057a8:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057aa:	0005c703          	lbu	a4,0(a1)
ffffffffc02057ae:	0785                	addi	a5,a5,1
ffffffffc02057b0:	0585                	addi	a1,a1,1
ffffffffc02057b2:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057b6:	fb75                	bnez	a4,ffffffffc02057aa <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057b8:	8082                	ret

ffffffffc02057ba <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057ba:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057be:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057c2:	cb89                	beqz	a5,ffffffffc02057d4 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02057c4:	0505                	addi	a0,a0,1
ffffffffc02057c6:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057c8:	fee789e3          	beq	a5,a4,ffffffffc02057ba <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057cc:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057d0:	9d19                	subw	a0,a0,a4
ffffffffc02057d2:	8082                	ret
ffffffffc02057d4:	4501                	li	a0,0
ffffffffc02057d6:	bfed                	j	ffffffffc02057d0 <strcmp+0x16>

ffffffffc02057d8 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057d8:	c20d                	beqz	a2,ffffffffc02057fa <strncmp+0x22>
ffffffffc02057da:	962e                	add	a2,a2,a1
ffffffffc02057dc:	a031                	j	ffffffffc02057e8 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02057de:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057e0:	00e79a63          	bne	a5,a4,ffffffffc02057f4 <strncmp+0x1c>
ffffffffc02057e4:	00b60b63          	beq	a2,a1,ffffffffc02057fa <strncmp+0x22>
ffffffffc02057e8:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057ec:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057ee:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02057f2:	f7f5                	bnez	a5,ffffffffc02057de <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057f4:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02057f8:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057fa:	4501                	li	a0,0
ffffffffc02057fc:	8082                	ret

ffffffffc02057fe <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02057fe:	00054783          	lbu	a5,0(a0)
ffffffffc0205802:	c799                	beqz	a5,ffffffffc0205810 <strchr+0x12>
        if (*s == c) {
ffffffffc0205804:	00f58763          	beq	a1,a5,ffffffffc0205812 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205808:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020580c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020580e:	fbfd                	bnez	a5,ffffffffc0205804 <strchr+0x6>
    }
    return NULL;
ffffffffc0205810:	4501                	li	a0,0
}
ffffffffc0205812:	8082                	ret

ffffffffc0205814 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205814:	ca01                	beqz	a2,ffffffffc0205824 <memset+0x10>
ffffffffc0205816:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205818:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020581a:	0785                	addi	a5,a5,1
ffffffffc020581c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205820:	fec79de3          	bne	a5,a2,ffffffffc020581a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205824:	8082                	ret

ffffffffc0205826 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205826:	ca19                	beqz	a2,ffffffffc020583c <memcpy+0x16>
ffffffffc0205828:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020582a:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020582c:	0005c703          	lbu	a4,0(a1)
ffffffffc0205830:	0585                	addi	a1,a1,1
ffffffffc0205832:	0785                	addi	a5,a5,1
ffffffffc0205834:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205838:	fec59ae3          	bne	a1,a2,ffffffffc020582c <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020583c:	8082                	ret
