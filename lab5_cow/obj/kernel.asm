
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

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
ffffffffc020004a:	000b0517          	auipc	a0,0xb0
ffffffffc020004e:	72650513          	addi	a0,a0,1830 # ffffffffc02b0770 <buf>
ffffffffc0200052:	000b5617          	auipc	a2,0xb5
ffffffffc0200056:	bc260613          	addi	a2,a2,-1086 # ffffffffc02b4c14 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	06d050ef          	jal	ra,ffffffffc02058ce <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	88a58593          	addi	a1,a1,-1910 # ffffffffc02058f8 <etext>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	8a250513          	addi	a0,a0,-1886 # ffffffffc0205918 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0a5020ef          	jal	ra,ffffffffc020292a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	3db030ef          	jal	ra,ffffffffc0203c6c <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	78b040ef          	jal	ra,ffffffffc0205020 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	116050ef          	jal	ra,ffffffffc02051b8 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00006517          	auipc	a0,0x6
ffffffffc02000c0:	86450513          	addi	a0,a0,-1948 # ffffffffc0205920 <etext+0x28>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000b0b97          	auipc	s7,0xb0
ffffffffc02000d6:	69eb8b93          	addi	s7,s7,1694 # ffffffffc02b0770 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000b0517          	auipc	a0,0xb0
ffffffffc0200132:	64250513          	addi	a0,a0,1602 # ffffffffc02b0770 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	322050ef          	jal	ra,ffffffffc02054aa <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	2ec050ef          	jal	ra,ffffffffc02054aa <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	70a50513          	addi	a0,a0,1802 # ffffffffc0205928 <etext+0x30>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	71450513          	addi	a0,a0,1812 # ffffffffc0205948 <etext+0x50>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	6b858593          	addi	a1,a1,1720 # ffffffffc02058f8 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	72050513          	addi	a0,a0,1824 # ffffffffc0205968 <etext+0x70>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000b0597          	auipc	a1,0xb0
ffffffffc0200258:	51c58593          	addi	a1,a1,1308 # ffffffffc02b0770 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	72c50513          	addi	a0,a0,1836 # ffffffffc0205988 <etext+0x90>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000b5597          	auipc	a1,0xb5
ffffffffc020026c:	9ac58593          	addi	a1,a1,-1620 # ffffffffc02b4c14 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	73850513          	addi	a0,a0,1848 # ffffffffc02059a8 <etext+0xb0>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000b5597          	auipc	a1,0xb5
ffffffffc0200280:	d9758593          	addi	a1,a1,-617 # ffffffffc02b5013 <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	72a50513          	addi	a0,a0,1834 # ffffffffc02059c8 <etext+0xd0>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	74c60613          	addi	a2,a2,1868 # ffffffffc02059f8 <etext+0x100>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	75850513          	addi	a0,a0,1880 # ffffffffc0205a10 <etext+0x118>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	76060613          	addi	a2,a2,1888 # ffffffffc0205a28 <etext+0x130>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	77858593          	addi	a1,a1,1912 # ffffffffc0205a48 <etext+0x150>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	77850513          	addi	a0,a0,1912 # ffffffffc0205a50 <etext+0x158>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	77a60613          	addi	a2,a2,1914 # ffffffffc0205a60 <etext+0x168>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	79a58593          	addi	a1,a1,1946 # ffffffffc0205a88 <etext+0x190>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	75a50513          	addi	a0,a0,1882 # ffffffffc0205a50 <etext+0x158>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	79660613          	addi	a2,a2,1942 # ffffffffc0205a98 <etext+0x1a0>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	7ae58593          	addi	a1,a1,1966 # ffffffffc0205ab8 <etext+0x1c0>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	73e50513          	addi	a0,a0,1854 # ffffffffc0205a50 <etext+0x158>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	77c50513          	addi	a0,a0,1916 # ffffffffc0205ac8 <etext+0x1d0>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	78250513          	addi	a0,a0,1922 # ffffffffc0205af0 <etext+0x1f8>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	7dcc0c13          	addi	s8,s8,2012 # ffffffffc0205b60 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	78c90913          	addi	s2,s2,1932 # ffffffffc0205b18 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	78c48493          	addi	s1,s1,1932 # ffffffffc0205b20 <etext+0x228>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	78ab0b13          	addi	s6,s6,1930 # ffffffffc0205b28 <etext+0x230>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	6a2a0a13          	addi	s4,s4,1698 # ffffffffc0205a48 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	798d0d13          	addi	s10,s10,1944 # ffffffffc0205b60 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	49e050ef          	jal	ra,ffffffffc0205874 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	48a050ef          	jal	ra,ffffffffc0205874 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	490050ef          	jal	ra,ffffffffc02058b8 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	452050ef          	jal	ra,ffffffffc02058b8 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	6c850513          	addi	a0,a0,1736 # ffffffffc0205b48 <etext+0x250>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000b4317          	auipc	t1,0xb4
ffffffffc0200492:	70a30313          	addi	t1,t1,1802 # ffffffffc02b4b98 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	6ec50513          	addi	a0,a0,1772 # ffffffffc0205ba8 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00007517          	auipc	a0,0x7
ffffffffc02004d6:	8be50513          	addi	a0,a0,-1858 # ffffffffc0206d90 <default_pmm_manager+0x520>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	6c250513          	addi	a0,a0,1730 # ffffffffc0205bc8 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00007517          	auipc	a0,0x7
ffffffffc020052a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0206d90 <default_pmm_manager+0x520>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd570>
ffffffffc0200540:	000b4717          	auipc	a4,0xb4
ffffffffc0200544:	66f73423          	sd	a5,1640(a4) # ffffffffc02b4ba8 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	68850513          	addi	a0,a0,1672 # ffffffffc0205be8 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000b4797          	auipc	a5,0xb4
ffffffffc020056c:	6207bc23          	sd	zero,1592(a5) # ffffffffc02b4ba0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000b4797          	auipc	a5,0xb4
ffffffffc020057a:	6327b783          	ld	a5,1586(a5) # ffffffffc02b4ba8 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	60850513          	addi	a0,a0,1544 # ffffffffc0205c08 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	5ea50513          	addi	a0,a0,1514 # ffffffffc0205c18 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	5e450513          	addi	a0,a0,1508 # ffffffffc0205c28 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	5ec50513          	addi	a0,a0,1516 # ffffffffc0205c40 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe2b2d9>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	58290913          	addi	s2,s2,1410 # ffffffffc0205c90 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	56c48493          	addi	s1,s1,1388 # ffffffffc0205c88 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	59850513          	addi	a0,a0,1432 # ffffffffc0205d08 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	5c450513          	addi	a0,a0,1476 # ffffffffc0205d40 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	4a450513          	addi	a0,a0,1188 # ffffffffc0205c60 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	062050ef          	jal	ra,ffffffffc020582c <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	0ba050ef          	jal	ra,ffffffffc0205892 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	006050ef          	jal	ra,ffffffffc0205874 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	41650513          	addi	a0,a0,1046 # ffffffffc0205c98 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	36850513          	addi	a0,a0,872 # ffffffffc0205cb8 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	36e50513          	addi	a0,a0,878 # ffffffffc0205cd0 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	37c50513          	addi	a0,a0,892 # ffffffffc0205cf0 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	3c050513          	addi	a0,a0,960 # ffffffffc0205d40 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000b4797          	auipc	a5,0xb4
ffffffffc020098c:	2287b423          	sd	s0,552(a5) # ffffffffc02b4bb0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000b4797          	auipc	a5,0xb4
ffffffffc0200994:	2367b423          	sd	s6,552(a5) # ffffffffc02b4bb8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000b4517          	auipc	a0,0xb4
ffffffffc020099e:	21653503          	ld	a0,534(a0) # ffffffffc02b4bb0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000b4517          	auipc	a0,0xb4
ffffffffc02009a8:	21453503          	ld	a0,532(a0) # ffffffffc02b4bb8 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	69878793          	addi	a5,a5,1688 # ffffffffc0201058 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	37a50513          	addi	a0,a0,890 # ffffffffc0205d58 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	38250513          	addi	a0,a0,898 # ffffffffc0205d70 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	38c50513          	addi	a0,a0,908 # ffffffffc0205d88 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	39650513          	addi	a0,a0,918 # ffffffffc0205da0 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	3a050513          	addi	a0,a0,928 # ffffffffc0205db8 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	3aa50513          	addi	a0,a0,938 # ffffffffc0205dd0 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	3b450513          	addi	a0,a0,948 # ffffffffc0205de8 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	3be50513          	addi	a0,a0,958 # ffffffffc0205e00 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	3c850513          	addi	a0,a0,968 # ffffffffc0205e18 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	3d250513          	addi	a0,a0,978 # ffffffffc0205e30 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	3dc50513          	addi	a0,a0,988 # ffffffffc0205e48 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	3e650513          	addi	a0,a0,998 # ffffffffc0205e60 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	3f050513          	addi	a0,a0,1008 # ffffffffc0205e78 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205e90 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	40450513          	addi	a0,a0,1028 # ffffffffc0205ea8 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	40e50513          	addi	a0,a0,1038 # ffffffffc0205ec0 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	41850513          	addi	a0,a0,1048 # ffffffffc0205ed8 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	42250513          	addi	a0,a0,1058 # ffffffffc0205ef0 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	42c50513          	addi	a0,a0,1068 # ffffffffc0205f08 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	43650513          	addi	a0,a0,1078 # ffffffffc0205f20 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	44050513          	addi	a0,a0,1088 # ffffffffc0205f38 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	44a50513          	addi	a0,a0,1098 # ffffffffc0205f50 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	45450513          	addi	a0,a0,1108 # ffffffffc0205f68 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	45e50513          	addi	a0,a0,1118 # ffffffffc0205f80 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	46850513          	addi	a0,a0,1128 # ffffffffc0205f98 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	47250513          	addi	a0,a0,1138 # ffffffffc0205fb0 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	47c50513          	addi	a0,a0,1148 # ffffffffc0205fc8 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	48650513          	addi	a0,a0,1158 # ffffffffc0205fe0 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	49050513          	addi	a0,a0,1168 # ffffffffc0205ff8 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	49a50513          	addi	a0,a0,1178 # ffffffffc0206010 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	4a450513          	addi	a0,a0,1188 # ffffffffc0206028 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0206040 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206058 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206070 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	4b450513          	addi	a0,a0,1204 # ffffffffc0206088 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	4bc50513          	addi	a0,a0,1212 # ffffffffc02060a0 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	4b850513          	addi	a0,a0,1208 # ffffffffc02060b0 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <handle_page_fault>:
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c06:	10053783          	ld	a5,256(a0)
{
ffffffffc0200c0a:	715d                	addi	sp,sp,-80
ffffffffc0200c0c:	e0a2                	sd	s0,64(sp)
ffffffffc0200c0e:	e486                	sd	ra,72(sp)
ffffffffc0200c10:	fc26                	sd	s1,56(sp)
ffffffffc0200c12:	f84a                	sd	s2,48(sp)
ffffffffc0200c14:	f44e                	sd	s3,40(sp)
ffffffffc0200c16:	f052                	sd	s4,32(sp)
ffffffffc0200c18:	ec56                	sd	s5,24(sp)
ffffffffc0200c1a:	e85a                	sd	s6,16(sp)
ffffffffc0200c1c:	e45e                	sd	s7,8(sp)
ffffffffc0200c1e:	e062                	sd	s8,0(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c20:	1007f793          	andi	a5,a5,256
{
ffffffffc0200c24:	842a                	mv	s0,a0
    if (trap_in_kernel(tf))
ffffffffc0200c26:	18079d63          	bnez	a5,ffffffffc0200dc0 <handle_page_fault+0x1ba>
    struct proc_struct *proc = current;
ffffffffc0200c2a:	000b4997          	auipc	s3,0xb4
ffffffffc0200c2e:	fce9b983          	ld	s3,-50(s3) # ffffffffc02b4bf8 <current>
    if (proc == NULL || proc->mm == NULL)
ffffffffc0200c32:	84ae                	mv	s1,a1
ffffffffc0200c34:	12098b63          	beqz	s3,ffffffffc0200d6a <handle_page_fault+0x164>
ffffffffc0200c38:	0289b783          	ld	a5,40(s3)
ffffffffc0200c3c:	12078763          	beqz	a5,ffffffffc0200d6a <handle_page_fault+0x164>
    pte_t *ptep = get_pte(proc->mm->pgdir, addr, 0);
ffffffffc0200c40:	6f88                	ld	a0,24(a5)
    uintptr_t addr = ROUNDDOWN(badaddr, PGSIZE);
ffffffffc0200c42:	7a7d                	lui	s4,0xfffff
ffffffffc0200c44:	0145fa33          	and	s4,a1,s4
    pte_t *ptep = get_pte(proc->mm->pgdir, addr, 0);
ffffffffc0200c48:	4601                	li	a2,0
ffffffffc0200c4a:	85d2                	mv	a1,s4
ffffffffc0200c4c:	4f8010ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc0200c50:	892a                	mv	s2,a0
    if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0200c52:	cd61                	beqz	a0,ffffffffc0200d2a <handle_page_fault+0x124>
ffffffffc0200c54:	6110                	ld	a2,0(a0)
ffffffffc0200c56:	00167793          	andi	a5,a2,1
ffffffffc0200c5a:	cbe1                	beqz	a5,ffffffffc0200d2a <handle_page_fault+0x124>
    if (is_store_fault && ((*ptep & PTE_COW) != 0))
ffffffffc0200c5c:	11843703          	ld	a4,280(s0)
ffffffffc0200c60:	47bd                	li	a5,15
ffffffffc0200c62:	0ef71c63          	bne	a4,a5,ffffffffc0200d5a <handle_page_fault+0x154>
ffffffffc0200c66:	10067793          	andi	a5,a2,256
ffffffffc0200c6a:	0e078863          	beqz	a5,ffffffffc0200d5a <handle_page_fault+0x154>
}

static inline struct Page *
pa2page(uintptr_t pa)
{
    if (PPN(pa) >= npage)
ffffffffc0200c6e:	000b4b97          	auipc	s7,0xb4
ffffffffc0200c72:	f6ab8b93          	addi	s7,s7,-150 # ffffffffc02b4bd8 <npage>
ffffffffc0200c76:	000bb783          	ld	a5,0(s7)
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
ffffffffc0200c7a:	00261713          	slli	a4,a2,0x2
ffffffffc0200c7e:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0200c80:	16f77563          	bgeu	a4,a5,ffffffffc0200dea <handle_page_fault+0x1e4>
    return &pages[PPN(pa) - nbase];
ffffffffc0200c84:	000b4c17          	auipc	s8,0xb4
ffffffffc0200c88:	f5cc0c13          	addi	s8,s8,-164 # ffffffffc02b4be0 <pages>
ffffffffc0200c8c:	000c3483          	ld	s1,0(s8)
ffffffffc0200c90:	00007b17          	auipc	s6,0x7
ffffffffc0200c94:	e88b3b03          	ld	s6,-376(s6) # ffffffffc0207b18 <nbase>
ffffffffc0200c98:	41670733          	sub	a4,a4,s6
ffffffffc0200c9c:	071a                	slli	a4,a4,0x6
ffffffffc0200c9e:	94ba                	add	s1,s1,a4
        if (page_ref(oldpage) == 1)
ffffffffc0200ca0:	4098                	lw	a4,0(s1)
ffffffffc0200ca2:	4785                	li	a5,1
ffffffffc0200ca4:	0cf70b63          	beq	a4,a5,ffffffffc0200d7a <handle_page_fault+0x174>
        struct Page *newpage = alloc_page();
ffffffffc0200ca8:	4505                	li	a0,1
ffffffffc0200caa:	3e2010ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0200cae:	8aaa                	mv	s5,a0
        if (newpage == NULL)
ffffffffc0200cb0:	10050163          	beqz	a0,ffffffffc0200db2 <handle_page_fault+0x1ac>
    return page - pages + nbase;
ffffffffc0200cb4:	000c3783          	ld	a5,0(s8)
    return KADDR(page2pa(page));
ffffffffc0200cb8:	577d                	li	a4,-1
ffffffffc0200cba:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc0200cbe:	40f506b3          	sub	a3,a0,a5
ffffffffc0200cc2:	8699                	srai	a3,a3,0x6
ffffffffc0200cc4:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc0200cc6:	8331                	srli	a4,a4,0xc
ffffffffc0200cc8:	00e6f5b3          	and	a1,a3,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ccc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0200cce:	12c5fb63          	bgeu	a1,a2,ffffffffc0200e04 <handle_page_fault+0x1fe>
    return page - pages + nbase;
ffffffffc0200cd2:	40f487b3          	sub	a5,s1,a5
ffffffffc0200cd6:	8799                	srai	a5,a5,0x6
ffffffffc0200cd8:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc0200cda:	000b4597          	auipc	a1,0xb4
ffffffffc0200cde:	f165b583          	ld	a1,-234(a1) # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc0200ce2:	8f7d                	and	a4,a4,a5
ffffffffc0200ce4:	00b68533          	add	a0,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ce8:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0200cea:	10c77c63          	bgeu	a4,a2,ffffffffc0200e02 <handle_page_fault+0x1fc>
        memcpy(page2kva(newpage), page2kva(oldpage), PGSIZE);
ffffffffc0200cee:	6605                	lui	a2,0x1
ffffffffc0200cf0:	95be                	add	a1,a1,a5
ffffffffc0200cf2:	3ef040ef          	jal	ra,ffffffffc02058e0 <memcpy>
        page_remove(proc->mm->pgdir, addr);
ffffffffc0200cf6:	0289b783          	ld	a5,40(s3)
ffffffffc0200cfa:	85d2                	mv	a1,s4
        uint32_t perm = (*ptep & (PTE_R | PTE_X | PTE_U));
ffffffffc0200cfc:	00093483          	ld	s1,0(s2)
        page_remove(proc->mm->pgdir, addr);
ffffffffc0200d00:	6f88                	ld	a0,24(a5)
        uint32_t perm = (*ptep & (PTE_R | PTE_X | PTE_U));
ffffffffc0200d02:	88e9                	andi	s1,s1,26
        page_remove(proc->mm->pgdir, addr);
ffffffffc0200d04:	295010ef          	jal	ra,ffffffffc0202798 <page_remove>
        if (page_insert(proc->mm->pgdir, newpage, addr, perm) != 0)
ffffffffc0200d08:	0289b783          	ld	a5,40(s3)
ffffffffc0200d0c:	0044e693          	ori	a3,s1,4
ffffffffc0200d10:	8652                	mv	a2,s4
ffffffffc0200d12:	6f88                	ld	a0,24(a5)
ffffffffc0200d14:	85d6                	mv	a1,s5
ffffffffc0200d16:	31f010ef          	jal	ra,ffffffffc0202834 <page_insert>
ffffffffc0200d1a:	c559                	beqz	a0,ffffffffc0200da8 <handle_page_fault+0x1a2>
            cprintf("COW: failed to insert new page mapping\n");
ffffffffc0200d1c:	00005517          	auipc	a0,0x5
ffffffffc0200d20:	4f450513          	addi	a0,a0,1268 # ffffffffc0206210 <commands+0x6b0>
ffffffffc0200d24:	c70ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            goto fault_exit;
ffffffffc0200d28:	a801                	j	ffffffffc0200d38 <handle_page_fault+0x132>
        cprintf("Invalid memory access at va=%p, no mapping found\n", badaddr);
ffffffffc0200d2a:	85a6                	mv	a1,s1
ffffffffc0200d2c:	00005517          	auipc	a0,0x5
ffffffffc0200d30:	42c50513          	addi	a0,a0,1068 # ffffffffc0206158 <commands+0x5f8>
ffffffffc0200d34:	c60ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_trapframe(tf);
ffffffffc0200d38:	8522                	mv	a0,s0
ffffffffc0200d3a:	e6bff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
}
ffffffffc0200d3e:	6406                	ld	s0,64(sp)
ffffffffc0200d40:	60a6                	ld	ra,72(sp)
ffffffffc0200d42:	74e2                	ld	s1,56(sp)
ffffffffc0200d44:	7942                	ld	s2,48(sp)
ffffffffc0200d46:	79a2                	ld	s3,40(sp)
ffffffffc0200d48:	7a02                	ld	s4,32(sp)
ffffffffc0200d4a:	6ae2                	ld	s5,24(sp)
ffffffffc0200d4c:	6b42                	ld	s6,16(sp)
ffffffffc0200d4e:	6ba2                	ld	s7,8(sp)
ffffffffc0200d50:	6c02                	ld	s8,0(sp)
    do_exit(-E_FAULT);
ffffffffc0200d52:	5569                	li	a0,-6
}
ffffffffc0200d54:	6161                	addi	sp,sp,80
    do_exit(-E_FAULT);
ffffffffc0200d56:	0ad0306f          	j	ffffffffc0204602 <do_exit>
    cprintf("Unhandled page fault at va=%p (pte=%p)\n", badaddr, (void *)(*ptep));
ffffffffc0200d5a:	85a6                	mv	a1,s1
ffffffffc0200d5c:	00005517          	auipc	a0,0x5
ffffffffc0200d60:	4dc50513          	addi	a0,a0,1244 # ffffffffc0206238 <commands+0x6d8>
ffffffffc0200d64:	c30ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200d68:	bfc1                	j	ffffffffc0200d38 <handle_page_fault+0x132>
        cprintf("Page fault with no process or mm at va=%p\n", badaddr);
ffffffffc0200d6a:	85a6                	mv	a1,s1
ffffffffc0200d6c:	00005517          	auipc	a0,0x5
ffffffffc0200d70:	3bc50513          	addi	a0,a0,956 # ffffffffc0206128 <commands+0x5c8>
ffffffffc0200d74:	c20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        goto fault_exit;
ffffffffc0200d78:	b7c1                	j	ffffffffc0200d38 <handle_page_fault+0x132>
            tlb_invalidate(proc->mm->pgdir, addr);
ffffffffc0200d7a:	0289b703          	ld	a4,40(s3)
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
ffffffffc0200d7e:	efb67793          	andi	a5,a2,-261
ffffffffc0200d82:	0047e793          	ori	a5,a5,4
            tlb_invalidate(proc->mm->pgdir, addr);
ffffffffc0200d86:	6f08                	ld	a0,24(a4)
ffffffffc0200d88:	85d2                	mv	a1,s4
            *ptep = (*ptep | PTE_W) & ~PTE_COW;
ffffffffc0200d8a:	00f93023          	sd	a5,0(s2)
}
ffffffffc0200d8e:	6406                	ld	s0,64(sp)
ffffffffc0200d90:	60a6                	ld	ra,72(sp)
ffffffffc0200d92:	74e2                	ld	s1,56(sp)
ffffffffc0200d94:	7942                	ld	s2,48(sp)
ffffffffc0200d96:	79a2                	ld	s3,40(sp)
ffffffffc0200d98:	7a02                	ld	s4,32(sp)
ffffffffc0200d9a:	6ae2                	ld	s5,24(sp)
ffffffffc0200d9c:	6b42                	ld	s6,16(sp)
ffffffffc0200d9e:	6ba2                	ld	s7,8(sp)
ffffffffc0200da0:	6c02                	ld	s8,0(sp)
ffffffffc0200da2:	6161                	addi	sp,sp,80
        tlb_invalidate(proc->mm->pgdir, addr);
ffffffffc0200da4:	28b0206f          	j	ffffffffc020382e <tlb_invalidate>
ffffffffc0200da8:	0289b783          	ld	a5,40(s3)
ffffffffc0200dac:	85d2                	mv	a1,s4
ffffffffc0200dae:	6f88                	ld	a0,24(a5)
ffffffffc0200db0:	bff9                	j	ffffffffc0200d8e <handle_page_fault+0x188>
            cprintf("COW: failed to allocate new page\n");
ffffffffc0200db2:	00005517          	auipc	a0,0x5
ffffffffc0200db6:	40e50513          	addi	a0,a0,1038 # ffffffffc02061c0 <commands+0x660>
ffffffffc0200dba:	bdaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            goto fault_exit;
ffffffffc0200dbe:	bfad                	j	ffffffffc0200d38 <handle_page_fault+0x132>
        cprintf("Unhandled page fault in kernel at va=%p\n", badaddr);
ffffffffc0200dc0:	00005517          	auipc	a0,0x5
ffffffffc0200dc4:	30850513          	addi	a0,a0,776 # ffffffffc02060c8 <commands+0x568>
ffffffffc0200dc8:	bccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200dcc:	8522                	mv	a0,s0
ffffffffc0200dce:	dd7ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
        panic("kernel page fault\n");
ffffffffc0200dd2:	00005617          	auipc	a2,0x5
ffffffffc0200dd6:	32660613          	addi	a2,a2,806 # ffffffffc02060f8 <commands+0x598>
ffffffffc0200dda:	02500593          	li	a1,37
ffffffffc0200dde:	00005517          	auipc	a0,0x5
ffffffffc0200de2:	33250513          	addi	a0,a0,818 # ffffffffc0206110 <commands+0x5b0>
ffffffffc0200de6:	ea8ff0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200dea:	00005617          	auipc	a2,0x5
ffffffffc0200dee:	3a660613          	addi	a2,a2,934 # ffffffffc0206190 <commands+0x630>
ffffffffc0200df2:	06900593          	li	a1,105
ffffffffc0200df6:	00005517          	auipc	a0,0x5
ffffffffc0200dfa:	3ba50513          	addi	a0,a0,954 # ffffffffc02061b0 <commands+0x650>
ffffffffc0200dfe:	e90ff0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0200e02:	86be                	mv	a3,a5
ffffffffc0200e04:	00005617          	auipc	a2,0x5
ffffffffc0200e08:	3e460613          	addi	a2,a2,996 # ffffffffc02061e8 <commands+0x688>
ffffffffc0200e0c:	07100593          	li	a1,113
ffffffffc0200e10:	00005517          	auipc	a0,0x5
ffffffffc0200e14:	3a050513          	addi	a0,a0,928 # ffffffffc02061b0 <commands+0x650>
ffffffffc0200e18:	e76ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e1c <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200e1c:	11853783          	ld	a5,280(a0)
ffffffffc0200e20:	472d                	li	a4,11
ffffffffc0200e22:	0786                	slli	a5,a5,0x1
ffffffffc0200e24:	8385                	srli	a5,a5,0x1
ffffffffc0200e26:	06f76c63          	bltu	a4,a5,ffffffffc0200e9e <interrupt_handler+0x82>
ffffffffc0200e2a:	00005717          	auipc	a4,0x5
ffffffffc0200e2e:	4e670713          	addi	a4,a4,1254 # ffffffffc0206310 <commands+0x7b0>
ffffffffc0200e32:	078a                	slli	a5,a5,0x2
ffffffffc0200e34:	97ba                	add	a5,a5,a4
ffffffffc0200e36:	439c                	lw	a5,0(a5)
ffffffffc0200e38:	97ba                	add	a5,a5,a4
ffffffffc0200e3a:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200e3c:	00005517          	auipc	a0,0x5
ffffffffc0200e40:	48450513          	addi	a0,a0,1156 # ffffffffc02062c0 <commands+0x760>
ffffffffc0200e44:	b50ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200e48:	00005517          	auipc	a0,0x5
ffffffffc0200e4c:	45850513          	addi	a0,a0,1112 # ffffffffc02062a0 <commands+0x740>
ffffffffc0200e50:	b44ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200e54:	00005517          	auipc	a0,0x5
ffffffffc0200e58:	40c50513          	addi	a0,a0,1036 # ffffffffc0206260 <commands+0x700>
ffffffffc0200e5c:	b38ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200e60:	00005517          	auipc	a0,0x5
ffffffffc0200e64:	42050513          	addi	a0,a0,1056 # ffffffffc0206280 <commands+0x720>
ffffffffc0200e68:	b2cff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200e6c:	1141                	addi	sp,sp,-16
ffffffffc0200e6e:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
ffffffffc0200e70:	f02ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200e74:	000b4697          	auipc	a3,0xb4
ffffffffc0200e78:	d2c68693          	addi	a3,a3,-724 # ffffffffc02b4ba0 <ticks>
ffffffffc0200e7c:	629c                	ld	a5,0(a3)
ffffffffc0200e7e:	06400713          	li	a4,100
ffffffffc0200e82:	0785                	addi	a5,a5,1
ffffffffc0200e84:	02e7f733          	remu	a4,a5,a4
ffffffffc0200e88:	e29c                	sd	a5,0(a3)
ffffffffc0200e8a:	cb19                	beqz	a4,ffffffffc0200ea0 <interrupt_handler+0x84>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200e8c:	60a2                	ld	ra,8(sp)
ffffffffc0200e8e:	0141                	addi	sp,sp,16
ffffffffc0200e90:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200e92:	00005517          	auipc	a0,0x5
ffffffffc0200e96:	45e50513          	addi	a0,a0,1118 # ffffffffc02062f0 <commands+0x790>
ffffffffc0200e9a:	afaff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200e9e:	b319                	j	ffffffffc0200ba4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ea0:	06400593          	li	a1,100
ffffffffc0200ea4:	00005517          	auipc	a0,0x5
ffffffffc0200ea8:	43c50513          	addi	a0,a0,1084 # ffffffffc02062e0 <commands+0x780>
ffffffffc0200eac:	ae8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            if (current != NULL) {
ffffffffc0200eb0:	000b4797          	auipc	a5,0xb4
ffffffffc0200eb4:	d487b783          	ld	a5,-696(a5) # ffffffffc02b4bf8 <current>
ffffffffc0200eb8:	dbf1                	beqz	a5,ffffffffc0200e8c <interrupt_handler+0x70>
                current->need_resched = 1;
ffffffffc0200eba:	4705                	li	a4,1
ffffffffc0200ebc:	ef98                	sd	a4,24(a5)
ffffffffc0200ebe:	b7f9                	j	ffffffffc0200e8c <interrupt_handler+0x70>

ffffffffc0200ec0 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200ec0:	11853783          	ld	a5,280(a0)
{
ffffffffc0200ec4:	1141                	addi	sp,sp,-16
ffffffffc0200ec6:	e022                	sd	s0,0(sp)
ffffffffc0200ec8:	e406                	sd	ra,8(sp)
ffffffffc0200eca:	473d                	li	a4,15
ffffffffc0200ecc:	842a                	mv	s0,a0
ffffffffc0200ece:	0af76b63          	bltu	a4,a5,ffffffffc0200f84 <exception_handler+0xc4>
ffffffffc0200ed2:	00005717          	auipc	a4,0x5
ffffffffc0200ed6:	59e70713          	addi	a4,a4,1438 # ffffffffc0206470 <commands+0x910>
ffffffffc0200eda:	078a                	slli	a5,a5,0x2
ffffffffc0200edc:	97ba                	add	a5,a5,a4
ffffffffc0200ede:	439c                	lw	a5,0(a5)
ffffffffc0200ee0:	97ba                	add	a5,a5,a4
ffffffffc0200ee2:	8782                	jr	a5
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200ee4:	6402                	ld	s0,0(sp)
ffffffffc0200ee6:	60a2                	ld	ra,8(sp)
        handle_page_fault(tf, tf->tval);
ffffffffc0200ee8:	11053583          	ld	a1,272(a0)
}
ffffffffc0200eec:	0141                	addi	sp,sp,16
        handle_page_fault(tf, tf->tval);
ffffffffc0200eee:	bb21                	j	ffffffffc0200c06 <handle_page_fault>
        cprintf("Environment call from S-mode\n");
ffffffffc0200ef0:	00005517          	auipc	a0,0x5
ffffffffc0200ef4:	52050513          	addi	a0,a0,1312 # ffffffffc0206410 <commands+0x8b0>
ffffffffc0200ef8:	a9cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200efc:	10843783          	ld	a5,264(s0)
}
ffffffffc0200f00:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200f02:	0791                	addi	a5,a5,4
ffffffffc0200f04:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200f08:	6402                	ld	s0,0(sp)
ffffffffc0200f0a:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200f0c:	49c0406f          	j	ffffffffc02053a8 <syscall>
        cprintf("Instruction address misaligned\n");
ffffffffc0200f10:	00005517          	auipc	a0,0x5
ffffffffc0200f14:	43050513          	addi	a0,a0,1072 # ffffffffc0206340 <commands+0x7e0>
}
ffffffffc0200f18:	6402                	ld	s0,0(sp)
ffffffffc0200f1a:	60a2                	ld	ra,8(sp)
ffffffffc0200f1c:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200f1e:	a76ff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200f22:	00005517          	auipc	a0,0x5
ffffffffc0200f26:	43e50513          	addi	a0,a0,1086 # ffffffffc0206360 <commands+0x800>
ffffffffc0200f2a:	b7fd                	j	ffffffffc0200f18 <exception_handler+0x58>
        cprintf("Illegal instruction\n");
ffffffffc0200f2c:	00005517          	auipc	a0,0x5
ffffffffc0200f30:	45450513          	addi	a0,a0,1108 # ffffffffc0206380 <commands+0x820>
ffffffffc0200f34:	b7d5                	j	ffffffffc0200f18 <exception_handler+0x58>
        cprintf("Environment call from M-mode\n");
ffffffffc0200f36:	00005517          	auipc	a0,0x5
ffffffffc0200f3a:	51a50513          	addi	a0,a0,1306 # ffffffffc0206450 <commands+0x8f0>
ffffffffc0200f3e:	bfe9                	j	ffffffffc0200f18 <exception_handler+0x58>
        cprintf("Environment call from H-mode\n");
ffffffffc0200f40:	00005517          	auipc	a0,0x5
ffffffffc0200f44:	4f050513          	addi	a0,a0,1264 # ffffffffc0206430 <commands+0x8d0>
ffffffffc0200f48:	bfc1                	j	ffffffffc0200f18 <exception_handler+0x58>
        cprintf("Store/AMO access fault\n");
ffffffffc0200f4a:	00005517          	auipc	a0,0x5
ffffffffc0200f4e:	4ae50513          	addi	a0,a0,1198 # ffffffffc02063f8 <commands+0x898>
ffffffffc0200f52:	b7d9                	j	ffffffffc0200f18 <exception_handler+0x58>
        cprintf("Breakpoint\n");
ffffffffc0200f54:	00005517          	auipc	a0,0x5
ffffffffc0200f58:	44450513          	addi	a0,a0,1092 # ffffffffc0206398 <commands+0x838>
ffffffffc0200f5c:	a38ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200f60:	6458                	ld	a4,136(s0)
ffffffffc0200f62:	47a9                	li	a5,10
ffffffffc0200f64:	04f70163          	beq	a4,a5,ffffffffc0200fa6 <exception_handler+0xe6>
}
ffffffffc0200f68:	60a2                	ld	ra,8(sp)
ffffffffc0200f6a:	6402                	ld	s0,0(sp)
ffffffffc0200f6c:	0141                	addi	sp,sp,16
ffffffffc0200f6e:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200f70:	00005517          	auipc	a0,0x5
ffffffffc0200f74:	43850513          	addi	a0,a0,1080 # ffffffffc02063a8 <commands+0x848>
ffffffffc0200f78:	b745                	j	ffffffffc0200f18 <exception_handler+0x58>
        cprintf("Load access fault\n");
ffffffffc0200f7a:	00005517          	auipc	a0,0x5
ffffffffc0200f7e:	44e50513          	addi	a0,a0,1102 # ffffffffc02063c8 <commands+0x868>
ffffffffc0200f82:	bf59                	j	ffffffffc0200f18 <exception_handler+0x58>
        print_trapframe(tf);
ffffffffc0200f84:	8522                	mv	a0,s0
}
ffffffffc0200f86:	6402                	ld	s0,0(sp)
ffffffffc0200f88:	60a2                	ld	ra,8(sp)
ffffffffc0200f8a:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200f8c:	b921                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200f8e:	00005617          	auipc	a2,0x5
ffffffffc0200f92:	45260613          	addi	a2,a2,1106 # ffffffffc02063e0 <commands+0x880>
ffffffffc0200f96:	11000593          	li	a1,272
ffffffffc0200f9a:	00005517          	auipc	a0,0x5
ffffffffc0200f9e:	17650513          	addi	a0,a0,374 # ffffffffc0206110 <commands+0x5b0>
ffffffffc0200fa2:	cecff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200fa6:	10843783          	ld	a5,264(s0)
ffffffffc0200faa:	0791                	addi	a5,a5,4
ffffffffc0200fac:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200fb0:	3f8040ef          	jal	ra,ffffffffc02053a8 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200fb4:	000b4797          	auipc	a5,0xb4
ffffffffc0200fb8:	c447b783          	ld	a5,-956(a5) # ffffffffc02b4bf8 <current>
ffffffffc0200fbc:	6b9c                	ld	a5,16(a5)
ffffffffc0200fbe:	8522                	mv	a0,s0
}
ffffffffc0200fc0:	6402                	ld	s0,0(sp)
ffffffffc0200fc2:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200fc4:	6589                	lui	a1,0x2
ffffffffc0200fc6:	95be                	add	a1,a1,a5
}
ffffffffc0200fc8:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200fca:	aab1                	j	ffffffffc0201126 <kernel_execve_ret>

ffffffffc0200fcc <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200fcc:	1101                	addi	sp,sp,-32
ffffffffc0200fce:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200fd0:	000b4417          	auipc	s0,0xb4
ffffffffc0200fd4:	c2840413          	addi	s0,s0,-984 # ffffffffc02b4bf8 <current>
ffffffffc0200fd8:	6018                	ld	a4,0(s0)
{
ffffffffc0200fda:	ec06                	sd	ra,24(sp)
ffffffffc0200fdc:	e426                	sd	s1,8(sp)
ffffffffc0200fde:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200fe0:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200fe4:	cf1d                	beqz	a4,ffffffffc0201022 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200fe6:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200fea:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200fee:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200ff0:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200ff4:	0206c463          	bltz	a3,ffffffffc020101c <trap+0x50>
        exception_handler(tf);
ffffffffc0200ff8:	ec9ff0ef          	jal	ra,ffffffffc0200ec0 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200ffc:	601c                	ld	a5,0(s0)
ffffffffc0200ffe:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0201002:	e499                	bnez	s1,ffffffffc0201010 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0201004:	0b07a703          	lw	a4,176(a5)
ffffffffc0201008:	8b05                	andi	a4,a4,1
ffffffffc020100a:	e329                	bnez	a4,ffffffffc020104c <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc020100c:	6f9c                	ld	a5,24(a5)
ffffffffc020100e:	eb85                	bnez	a5,ffffffffc020103e <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0201010:	60e2                	ld	ra,24(sp)
ffffffffc0201012:	6442                	ld	s0,16(sp)
ffffffffc0201014:	64a2                	ld	s1,8(sp)
ffffffffc0201016:	6902                	ld	s2,0(sp)
ffffffffc0201018:	6105                	addi	sp,sp,32
ffffffffc020101a:	8082                	ret
        interrupt_handler(tf);
ffffffffc020101c:	e01ff0ef          	jal	ra,ffffffffc0200e1c <interrupt_handler>
ffffffffc0201020:	bff1                	j	ffffffffc0200ffc <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0201022:	0006c863          	bltz	a3,ffffffffc0201032 <trap+0x66>
}
ffffffffc0201026:	6442                	ld	s0,16(sp)
ffffffffc0201028:	60e2                	ld	ra,24(sp)
ffffffffc020102a:	64a2                	ld	s1,8(sp)
ffffffffc020102c:	6902                	ld	s2,0(sp)
ffffffffc020102e:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0201030:	bd41                	j	ffffffffc0200ec0 <exception_handler>
}
ffffffffc0201032:	6442                	ld	s0,16(sp)
ffffffffc0201034:	60e2                	ld	ra,24(sp)
ffffffffc0201036:	64a2                	ld	s1,8(sp)
ffffffffc0201038:	6902                	ld	s2,0(sp)
ffffffffc020103a:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc020103c:	b3c5                	j	ffffffffc0200e1c <interrupt_handler>
}
ffffffffc020103e:	6442                	ld	s0,16(sp)
ffffffffc0201040:	60e2                	ld	ra,24(sp)
ffffffffc0201042:	64a2                	ld	s1,8(sp)
ffffffffc0201044:	6902                	ld	s2,0(sp)
ffffffffc0201046:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0201048:	2740406f          	j	ffffffffc02052bc <schedule>
                do_exit(-E_KILLED);
ffffffffc020104c:	555d                	li	a0,-9
ffffffffc020104e:	5b4030ef          	jal	ra,ffffffffc0204602 <do_exit>
            if (current->need_resched)
ffffffffc0201052:	601c                	ld	a5,0(s0)
ffffffffc0201054:	bf65                	j	ffffffffc020100c <trap+0x40>
	...

ffffffffc0201058 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0201058:	14011173          	csrrw	sp,sscratch,sp
ffffffffc020105c:	00011463          	bnez	sp,ffffffffc0201064 <__alltraps+0xc>
ffffffffc0201060:	14002173          	csrr	sp,sscratch
ffffffffc0201064:	712d                	addi	sp,sp,-288
ffffffffc0201066:	e002                	sd	zero,0(sp)
ffffffffc0201068:	e406                	sd	ra,8(sp)
ffffffffc020106a:	ec0e                	sd	gp,24(sp)
ffffffffc020106c:	f012                	sd	tp,32(sp)
ffffffffc020106e:	f416                	sd	t0,40(sp)
ffffffffc0201070:	f81a                	sd	t1,48(sp)
ffffffffc0201072:	fc1e                	sd	t2,56(sp)
ffffffffc0201074:	e0a2                	sd	s0,64(sp)
ffffffffc0201076:	e4a6                	sd	s1,72(sp)
ffffffffc0201078:	e8aa                	sd	a0,80(sp)
ffffffffc020107a:	ecae                	sd	a1,88(sp)
ffffffffc020107c:	f0b2                	sd	a2,96(sp)
ffffffffc020107e:	f4b6                	sd	a3,104(sp)
ffffffffc0201080:	f8ba                	sd	a4,112(sp)
ffffffffc0201082:	fcbe                	sd	a5,120(sp)
ffffffffc0201084:	e142                	sd	a6,128(sp)
ffffffffc0201086:	e546                	sd	a7,136(sp)
ffffffffc0201088:	e94a                	sd	s2,144(sp)
ffffffffc020108a:	ed4e                	sd	s3,152(sp)
ffffffffc020108c:	f152                	sd	s4,160(sp)
ffffffffc020108e:	f556                	sd	s5,168(sp)
ffffffffc0201090:	f95a                	sd	s6,176(sp)
ffffffffc0201092:	fd5e                	sd	s7,184(sp)
ffffffffc0201094:	e1e2                	sd	s8,192(sp)
ffffffffc0201096:	e5e6                	sd	s9,200(sp)
ffffffffc0201098:	e9ea                	sd	s10,208(sp)
ffffffffc020109a:	edee                	sd	s11,216(sp)
ffffffffc020109c:	f1f2                	sd	t3,224(sp)
ffffffffc020109e:	f5f6                	sd	t4,232(sp)
ffffffffc02010a0:	f9fa                	sd	t5,240(sp)
ffffffffc02010a2:	fdfe                	sd	t6,248(sp)
ffffffffc02010a4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02010a8:	100024f3          	csrr	s1,sstatus
ffffffffc02010ac:	14102973          	csrr	s2,sepc
ffffffffc02010b0:	143029f3          	csrr	s3,stval
ffffffffc02010b4:	14202a73          	csrr	s4,scause
ffffffffc02010b8:	e822                	sd	s0,16(sp)
ffffffffc02010ba:	e226                	sd	s1,256(sp)
ffffffffc02010bc:	e64a                	sd	s2,264(sp)
ffffffffc02010be:	ea4e                	sd	s3,272(sp)
ffffffffc02010c0:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02010c2:	850a                	mv	a0,sp
    jal trap
ffffffffc02010c4:	f09ff0ef          	jal	ra,ffffffffc0200fcc <trap>

ffffffffc02010c8 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02010c8:	6492                	ld	s1,256(sp)
ffffffffc02010ca:	6932                	ld	s2,264(sp)
ffffffffc02010cc:	1004f413          	andi	s0,s1,256
ffffffffc02010d0:	e401                	bnez	s0,ffffffffc02010d8 <__trapret+0x10>
ffffffffc02010d2:	1200                	addi	s0,sp,288
ffffffffc02010d4:	14041073          	csrw	sscratch,s0
ffffffffc02010d8:	10049073          	csrw	sstatus,s1
ffffffffc02010dc:	14191073          	csrw	sepc,s2
ffffffffc02010e0:	60a2                	ld	ra,8(sp)
ffffffffc02010e2:	61e2                	ld	gp,24(sp)
ffffffffc02010e4:	7202                	ld	tp,32(sp)
ffffffffc02010e6:	72a2                	ld	t0,40(sp)
ffffffffc02010e8:	7342                	ld	t1,48(sp)
ffffffffc02010ea:	73e2                	ld	t2,56(sp)
ffffffffc02010ec:	6406                	ld	s0,64(sp)
ffffffffc02010ee:	64a6                	ld	s1,72(sp)
ffffffffc02010f0:	6546                	ld	a0,80(sp)
ffffffffc02010f2:	65e6                	ld	a1,88(sp)
ffffffffc02010f4:	7606                	ld	a2,96(sp)
ffffffffc02010f6:	76a6                	ld	a3,104(sp)
ffffffffc02010f8:	7746                	ld	a4,112(sp)
ffffffffc02010fa:	77e6                	ld	a5,120(sp)
ffffffffc02010fc:	680a                	ld	a6,128(sp)
ffffffffc02010fe:	68aa                	ld	a7,136(sp)
ffffffffc0201100:	694a                	ld	s2,144(sp)
ffffffffc0201102:	69ea                	ld	s3,152(sp)
ffffffffc0201104:	7a0a                	ld	s4,160(sp)
ffffffffc0201106:	7aaa                	ld	s5,168(sp)
ffffffffc0201108:	7b4a                	ld	s6,176(sp)
ffffffffc020110a:	7bea                	ld	s7,184(sp)
ffffffffc020110c:	6c0e                	ld	s8,192(sp)
ffffffffc020110e:	6cae                	ld	s9,200(sp)
ffffffffc0201110:	6d4e                	ld	s10,208(sp)
ffffffffc0201112:	6dee                	ld	s11,216(sp)
ffffffffc0201114:	7e0e                	ld	t3,224(sp)
ffffffffc0201116:	7eae                	ld	t4,232(sp)
ffffffffc0201118:	7f4e                	ld	t5,240(sp)
ffffffffc020111a:	7fee                	ld	t6,248(sp)
ffffffffc020111c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc020111e:	10200073          	sret

ffffffffc0201122 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0201122:	812a                	mv	sp,a0
    j __trapret
ffffffffc0201124:	b755                	j	ffffffffc02010c8 <__trapret>

ffffffffc0201126 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0201126:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc020112a:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc020112e:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0201132:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0201136:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc020113a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc020113e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0201142:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0201146:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc020114a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc020114c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc020114e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0201150:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0201152:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0201154:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0201156:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0201158:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc020115a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc020115c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc020115e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0201160:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0201162:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201164:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0201166:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0201168:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc020116a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc020116c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc020116e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0201170:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0201172:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201174:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0201176:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201178:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc020117a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc020117c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc020117e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201180:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0201182:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201184:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0201186:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201188:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc020118a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc020118c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc020118e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201190:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0201192:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201194:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0201196:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201198:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc020119a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc020119c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc020119e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc02011a0:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc02011a2:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc02011a4:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc02011a6:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc02011a8:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc02011aa:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc02011ac:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc02011ae:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc02011b0:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc02011b2:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc02011b4:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc02011b6:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc02011b8:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc02011ba:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc02011bc:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc02011be:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc02011c0:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc02011c2:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc02011c4:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc02011c6:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc02011c8:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc02011ca:	812e                	mv	sp,a1
ffffffffc02011cc:	bdf5                	j	ffffffffc02010c8 <__trapret>

ffffffffc02011ce <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02011ce:	000b0797          	auipc	a5,0xb0
ffffffffc02011d2:	9a278793          	addi	a5,a5,-1630 # ffffffffc02b0b70 <free_area>
ffffffffc02011d6:	e79c                	sd	a5,8(a5)
ffffffffc02011d8:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc02011da:	0007a823          	sw	zero,16(a5)
}
ffffffffc02011de:	8082                	ret

ffffffffc02011e0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc02011e0:	000b0517          	auipc	a0,0xb0
ffffffffc02011e4:	9a056503          	lwu	a0,-1632(a0) # ffffffffc02b0b80 <free_area+0x10>
ffffffffc02011e8:	8082                	ret

ffffffffc02011ea <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc02011ea:	715d                	addi	sp,sp,-80
ffffffffc02011ec:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02011ee:	000b0417          	auipc	s0,0xb0
ffffffffc02011f2:	98240413          	addi	s0,s0,-1662 # ffffffffc02b0b70 <free_area>
ffffffffc02011f6:	641c                	ld	a5,8(s0)
ffffffffc02011f8:	e486                	sd	ra,72(sp)
ffffffffc02011fa:	fc26                	sd	s1,56(sp)
ffffffffc02011fc:	f84a                	sd	s2,48(sp)
ffffffffc02011fe:	f44e                	sd	s3,40(sp)
ffffffffc0201200:	f052                	sd	s4,32(sp)
ffffffffc0201202:	ec56                	sd	s5,24(sp)
ffffffffc0201204:	e85a                	sd	s6,16(sp)
ffffffffc0201206:	e45e                	sd	s7,8(sp)
ffffffffc0201208:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020120a:	2a878d63          	beq	a5,s0,ffffffffc02014c4 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020120e:	4481                	li	s1,0
ffffffffc0201210:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201212:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201216:	8b09                	andi	a4,a4,2
ffffffffc0201218:	2a070a63          	beqz	a4,ffffffffc02014cc <default_check+0x2e2>
        count++, total += p->property;
ffffffffc020121c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201220:	679c                	ld	a5,8(a5)
ffffffffc0201222:	2905                	addiw	s2,s2,1
ffffffffc0201224:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201226:	fe8796e3          	bne	a5,s0,ffffffffc0201212 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020122a:	89a6                	mv	s3,s1
ffffffffc020122c:	6df000ef          	jal	ra,ffffffffc020210a <nr_free_pages>
ffffffffc0201230:	6f351e63          	bne	a0,s3,ffffffffc020192c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201234:	4505                	li	a0,1
ffffffffc0201236:	657000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc020123a:	8aaa                	mv	s5,a0
ffffffffc020123c:	42050863          	beqz	a0,ffffffffc020166c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201240:	4505                	li	a0,1
ffffffffc0201242:	64b000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201246:	89aa                	mv	s3,a0
ffffffffc0201248:	70050263          	beqz	a0,ffffffffc020194c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020124c:	4505                	li	a0,1
ffffffffc020124e:	63f000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201252:	8a2a                	mv	s4,a0
ffffffffc0201254:	48050c63          	beqz	a0,ffffffffc02016ec <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201258:	293a8a63          	beq	s5,s3,ffffffffc02014ec <default_check+0x302>
ffffffffc020125c:	28aa8863          	beq	s5,a0,ffffffffc02014ec <default_check+0x302>
ffffffffc0201260:	28a98663          	beq	s3,a0,ffffffffc02014ec <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201264:	000aa783          	lw	a5,0(s5)
ffffffffc0201268:	2a079263          	bnez	a5,ffffffffc020150c <default_check+0x322>
ffffffffc020126c:	0009a783          	lw	a5,0(s3)
ffffffffc0201270:	28079e63          	bnez	a5,ffffffffc020150c <default_check+0x322>
ffffffffc0201274:	411c                	lw	a5,0(a0)
ffffffffc0201276:	28079b63          	bnez	a5,ffffffffc020150c <default_check+0x322>
    return page - pages + nbase;
ffffffffc020127a:	000b4797          	auipc	a5,0xb4
ffffffffc020127e:	9667b783          	ld	a5,-1690(a5) # ffffffffc02b4be0 <pages>
ffffffffc0201282:	40fa8733          	sub	a4,s5,a5
ffffffffc0201286:	00007617          	auipc	a2,0x7
ffffffffc020128a:	89263603          	ld	a2,-1902(a2) # ffffffffc0207b18 <nbase>
ffffffffc020128e:	8719                	srai	a4,a4,0x6
ffffffffc0201290:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201292:	000b4697          	auipc	a3,0xb4
ffffffffc0201296:	9466b683          	ld	a3,-1722(a3) # ffffffffc02b4bd8 <npage>
ffffffffc020129a:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020129c:	0732                	slli	a4,a4,0xc
ffffffffc020129e:	28d77763          	bgeu	a4,a3,ffffffffc020152c <default_check+0x342>
    return page - pages + nbase;
ffffffffc02012a2:	40f98733          	sub	a4,s3,a5
ffffffffc02012a6:	8719                	srai	a4,a4,0x6
ffffffffc02012a8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02012aa:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02012ac:	4cd77063          	bgeu	a4,a3,ffffffffc020176c <default_check+0x582>
    return page - pages + nbase;
ffffffffc02012b0:	40f507b3          	sub	a5,a0,a5
ffffffffc02012b4:	8799                	srai	a5,a5,0x6
ffffffffc02012b6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02012b8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012ba:	30d7f963          	bgeu	a5,a3,ffffffffc02015cc <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02012be:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02012c0:	00043c03          	ld	s8,0(s0)
ffffffffc02012c4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02012c8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02012cc:	e400                	sd	s0,8(s0)
ffffffffc02012ce:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02012d0:	000b0797          	auipc	a5,0xb0
ffffffffc02012d4:	8a07a823          	sw	zero,-1872(a5) # ffffffffc02b0b80 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02012d8:	5b5000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc02012dc:	2c051863          	bnez	a0,ffffffffc02015ac <default_check+0x3c2>
    free_page(p0);
ffffffffc02012e0:	4585                	li	a1,1
ffffffffc02012e2:	8556                	mv	a0,s5
ffffffffc02012e4:	5e7000ef          	jal	ra,ffffffffc02020ca <free_pages>
    free_page(p1);
ffffffffc02012e8:	4585                	li	a1,1
ffffffffc02012ea:	854e                	mv	a0,s3
ffffffffc02012ec:	5df000ef          	jal	ra,ffffffffc02020ca <free_pages>
    free_page(p2);
ffffffffc02012f0:	4585                	li	a1,1
ffffffffc02012f2:	8552                	mv	a0,s4
ffffffffc02012f4:	5d7000ef          	jal	ra,ffffffffc02020ca <free_pages>
    assert(nr_free == 3);
ffffffffc02012f8:	4818                	lw	a4,16(s0)
ffffffffc02012fa:	478d                	li	a5,3
ffffffffc02012fc:	28f71863          	bne	a4,a5,ffffffffc020158c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201300:	4505                	li	a0,1
ffffffffc0201302:	58b000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201306:	89aa                	mv	s3,a0
ffffffffc0201308:	26050263          	beqz	a0,ffffffffc020156c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020130c:	4505                	li	a0,1
ffffffffc020130e:	57f000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201312:	8aaa                	mv	s5,a0
ffffffffc0201314:	3a050c63          	beqz	a0,ffffffffc02016cc <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201318:	4505                	li	a0,1
ffffffffc020131a:	573000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc020131e:	8a2a                	mv	s4,a0
ffffffffc0201320:	38050663          	beqz	a0,ffffffffc02016ac <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201324:	4505                	li	a0,1
ffffffffc0201326:	567000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc020132a:	36051163          	bnez	a0,ffffffffc020168c <default_check+0x4a2>
    free_page(p0);
ffffffffc020132e:	4585                	li	a1,1
ffffffffc0201330:	854e                	mv	a0,s3
ffffffffc0201332:	599000ef          	jal	ra,ffffffffc02020ca <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201336:	641c                	ld	a5,8(s0)
ffffffffc0201338:	20878a63          	beq	a5,s0,ffffffffc020154c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020133c:	4505                	li	a0,1
ffffffffc020133e:	54f000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201342:	30a99563          	bne	s3,a0,ffffffffc020164c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201346:	4505                	li	a0,1
ffffffffc0201348:	545000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc020134c:	2e051063          	bnez	a0,ffffffffc020162c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201350:	481c                	lw	a5,16(s0)
ffffffffc0201352:	2a079d63          	bnez	a5,ffffffffc020160c <default_check+0x422>
    free_page(p);
ffffffffc0201356:	854e                	mv	a0,s3
ffffffffc0201358:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020135a:	01843023          	sd	s8,0(s0)
ffffffffc020135e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201362:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201366:	565000ef          	jal	ra,ffffffffc02020ca <free_pages>
    free_page(p1);
ffffffffc020136a:	4585                	li	a1,1
ffffffffc020136c:	8556                	mv	a0,s5
ffffffffc020136e:	55d000ef          	jal	ra,ffffffffc02020ca <free_pages>
    free_page(p2);
ffffffffc0201372:	4585                	li	a1,1
ffffffffc0201374:	8552                	mv	a0,s4
ffffffffc0201376:	555000ef          	jal	ra,ffffffffc02020ca <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020137a:	4515                	li	a0,5
ffffffffc020137c:	511000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201380:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201382:	26050563          	beqz	a0,ffffffffc02015ec <default_check+0x402>
ffffffffc0201386:	651c                	ld	a5,8(a0)
ffffffffc0201388:	8385                	srli	a5,a5,0x1
ffffffffc020138a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020138c:	54079063          	bnez	a5,ffffffffc02018cc <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201390:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201392:	00043b03          	ld	s6,0(s0)
ffffffffc0201396:	00843a83          	ld	s5,8(s0)
ffffffffc020139a:	e000                	sd	s0,0(s0)
ffffffffc020139c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020139e:	4ef000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc02013a2:	50051563          	bnez	a0,ffffffffc02018ac <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02013a6:	08098a13          	addi	s4,s3,128
ffffffffc02013aa:	8552                	mv	a0,s4
ffffffffc02013ac:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02013ae:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02013b2:	000af797          	auipc	a5,0xaf
ffffffffc02013b6:	7c07a723          	sw	zero,1998(a5) # ffffffffc02b0b80 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02013ba:	511000ef          	jal	ra,ffffffffc02020ca <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02013be:	4511                	li	a0,4
ffffffffc02013c0:	4cd000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc02013c4:	4c051463          	bnez	a0,ffffffffc020188c <default_check+0x6a2>
ffffffffc02013c8:	0889b783          	ld	a5,136(s3)
ffffffffc02013cc:	8385                	srli	a5,a5,0x1
ffffffffc02013ce:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02013d0:	48078e63          	beqz	a5,ffffffffc020186c <default_check+0x682>
ffffffffc02013d4:	0909a703          	lw	a4,144(s3)
ffffffffc02013d8:	478d                	li	a5,3
ffffffffc02013da:	48f71963          	bne	a4,a5,ffffffffc020186c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013de:	450d                	li	a0,3
ffffffffc02013e0:	4ad000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc02013e4:	8c2a                	mv	s8,a0
ffffffffc02013e6:	46050363          	beqz	a0,ffffffffc020184c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02013ea:	4505                	li	a0,1
ffffffffc02013ec:	4a1000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc02013f0:	42051e63          	bnez	a0,ffffffffc020182c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02013f4:	418a1c63          	bne	s4,s8,ffffffffc020180c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02013f8:	4585                	li	a1,1
ffffffffc02013fa:	854e                	mv	a0,s3
ffffffffc02013fc:	4cf000ef          	jal	ra,ffffffffc02020ca <free_pages>
    free_pages(p1, 3);
ffffffffc0201400:	458d                	li	a1,3
ffffffffc0201402:	8552                	mv	a0,s4
ffffffffc0201404:	4c7000ef          	jal	ra,ffffffffc02020ca <free_pages>
ffffffffc0201408:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020140c:	04098c13          	addi	s8,s3,64
ffffffffc0201410:	8385                	srli	a5,a5,0x1
ffffffffc0201412:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201414:	3c078c63          	beqz	a5,ffffffffc02017ec <default_check+0x602>
ffffffffc0201418:	0109a703          	lw	a4,16(s3)
ffffffffc020141c:	4785                	li	a5,1
ffffffffc020141e:	3cf71763          	bne	a4,a5,ffffffffc02017ec <default_check+0x602>
ffffffffc0201422:	008a3783          	ld	a5,8(s4) # fffffffffffff008 <end+0x3fd4a3f4>
ffffffffc0201426:	8385                	srli	a5,a5,0x1
ffffffffc0201428:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020142a:	3a078163          	beqz	a5,ffffffffc02017cc <default_check+0x5e2>
ffffffffc020142e:	010a2703          	lw	a4,16(s4)
ffffffffc0201432:	478d                	li	a5,3
ffffffffc0201434:	38f71c63          	bne	a4,a5,ffffffffc02017cc <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201438:	4505                	li	a0,1
ffffffffc020143a:	453000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc020143e:	36a99763          	bne	s3,a0,ffffffffc02017ac <default_check+0x5c2>
    free_page(p0);
ffffffffc0201442:	4585                	li	a1,1
ffffffffc0201444:	487000ef          	jal	ra,ffffffffc02020ca <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201448:	4509                	li	a0,2
ffffffffc020144a:	443000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc020144e:	32aa1f63          	bne	s4,a0,ffffffffc020178c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201452:	4589                	li	a1,2
ffffffffc0201454:	477000ef          	jal	ra,ffffffffc02020ca <free_pages>
    free_page(p2);
ffffffffc0201458:	4585                	li	a1,1
ffffffffc020145a:	8562                	mv	a0,s8
ffffffffc020145c:	46f000ef          	jal	ra,ffffffffc02020ca <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201460:	4515                	li	a0,5
ffffffffc0201462:	42b000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201466:	89aa                	mv	s3,a0
ffffffffc0201468:	48050263          	beqz	a0,ffffffffc02018ec <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020146c:	4505                	li	a0,1
ffffffffc020146e:	41f000ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0201472:	2c051d63          	bnez	a0,ffffffffc020174c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201476:	481c                	lw	a5,16(s0)
ffffffffc0201478:	2a079a63          	bnez	a5,ffffffffc020172c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020147c:	4595                	li	a1,5
ffffffffc020147e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201480:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201484:	01643023          	sd	s6,0(s0)
ffffffffc0201488:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020148c:	43f000ef          	jal	ra,ffffffffc02020ca <free_pages>
    return listelm->next;
ffffffffc0201490:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201492:	00878963          	beq	a5,s0,ffffffffc02014a4 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201496:	ff87a703          	lw	a4,-8(a5)
ffffffffc020149a:	679c                	ld	a5,8(a5)
ffffffffc020149c:	397d                	addiw	s2,s2,-1
ffffffffc020149e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02014a0:	fe879be3          	bne	a5,s0,ffffffffc0201496 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02014a4:	26091463          	bnez	s2,ffffffffc020170c <default_check+0x522>
    assert(total == 0);
ffffffffc02014a8:	46049263          	bnez	s1,ffffffffc020190c <default_check+0x722>
}
ffffffffc02014ac:	60a6                	ld	ra,72(sp)
ffffffffc02014ae:	6406                	ld	s0,64(sp)
ffffffffc02014b0:	74e2                	ld	s1,56(sp)
ffffffffc02014b2:	7942                	ld	s2,48(sp)
ffffffffc02014b4:	79a2                	ld	s3,40(sp)
ffffffffc02014b6:	7a02                	ld	s4,32(sp)
ffffffffc02014b8:	6ae2                	ld	s5,24(sp)
ffffffffc02014ba:	6b42                	ld	s6,16(sp)
ffffffffc02014bc:	6ba2                	ld	s7,8(sp)
ffffffffc02014be:	6c02                	ld	s8,0(sp)
ffffffffc02014c0:	6161                	addi	sp,sp,80
ffffffffc02014c2:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02014c4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02014c6:	4481                	li	s1,0
ffffffffc02014c8:	4901                	li	s2,0
ffffffffc02014ca:	b38d                	j	ffffffffc020122c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	fe468693          	addi	a3,a3,-28 # ffffffffc02064b0 <commands+0x950>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	fec60613          	addi	a2,a2,-20 # ffffffffc02064c0 <commands+0x960>
ffffffffc02014dc:	11000593          	li	a1,272
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	ff850513          	addi	a0,a0,-8 # ffffffffc02064d8 <commands+0x978>
ffffffffc02014e8:	fa7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	08468693          	addi	a3,a3,132 # ffffffffc0206570 <commands+0xa10>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	fcc60613          	addi	a2,a2,-52 # ffffffffc02064c0 <commands+0x960>
ffffffffc02014fc:	0db00593          	li	a1,219
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	fd850513          	addi	a0,a0,-40 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201508:	f87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	08c68693          	addi	a3,a3,140 # ffffffffc0206598 <commands+0xa38>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	fac60613          	addi	a2,a2,-84 # ffffffffc02064c0 <commands+0x960>
ffffffffc020151c:	0dc00593          	li	a1,220
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	fb850513          	addi	a0,a0,-72 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201528:	f67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	0ac68693          	addi	a3,a3,172 # ffffffffc02065d8 <commands+0xa78>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	f8c60613          	addi	a2,a2,-116 # ffffffffc02064c0 <commands+0x960>
ffffffffc020153c:	0de00593          	li	a1,222
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	f9850513          	addi	a0,a0,-104 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201548:	f47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	11468693          	addi	a3,a3,276 # ffffffffc0206660 <commands+0xb00>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	f6c60613          	addi	a2,a2,-148 # ffffffffc02064c0 <commands+0x960>
ffffffffc020155c:	0f700593          	li	a1,247
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	f7850513          	addi	a0,a0,-136 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201568:	f27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	fa468693          	addi	a3,a3,-92 # ffffffffc0206510 <commands+0x9b0>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	f4c60613          	addi	a2,a2,-180 # ffffffffc02064c0 <commands+0x960>
ffffffffc020157c:	0f000593          	li	a1,240
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	f5850513          	addi	a0,a0,-168 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201588:	f07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	0c468693          	addi	a3,a3,196 # ffffffffc0206650 <commands+0xaf0>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	f2c60613          	addi	a2,a2,-212 # ffffffffc02064c0 <commands+0x960>
ffffffffc020159c:	0ee00593          	li	a1,238
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	f3850513          	addi	a0,a0,-200 # ffffffffc02064d8 <commands+0x978>
ffffffffc02015a8:	ee7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	08c68693          	addi	a3,a3,140 # ffffffffc0206638 <commands+0xad8>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	f0c60613          	addi	a2,a2,-244 # ffffffffc02064c0 <commands+0x960>
ffffffffc02015bc:	0e900593          	li	a1,233
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	f1850513          	addi	a0,a0,-232 # ffffffffc02064d8 <commands+0x978>
ffffffffc02015c8:	ec7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	04c68693          	addi	a3,a3,76 # ffffffffc0206618 <commands+0xab8>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	eec60613          	addi	a2,a2,-276 # ffffffffc02064c0 <commands+0x960>
ffffffffc02015dc:	0e000593          	li	a1,224
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	ef850513          	addi	a0,a0,-264 # ffffffffc02064d8 <commands+0x978>
ffffffffc02015e8:	ea7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	0bc68693          	addi	a3,a3,188 # ffffffffc02066a8 <commands+0xb48>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	ecc60613          	addi	a2,a2,-308 # ffffffffc02064c0 <commands+0x960>
ffffffffc02015fc:	11800593          	li	a1,280
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	ed850513          	addi	a0,a0,-296 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201608:	e87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	08c68693          	addi	a3,a3,140 # ffffffffc0206698 <commands+0xb38>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	eac60613          	addi	a2,a2,-340 # ffffffffc02064c0 <commands+0x960>
ffffffffc020161c:	0fd00593          	li	a1,253
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	eb850513          	addi	a0,a0,-328 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201628:	e67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	00c68693          	addi	a3,a3,12 # ffffffffc0206638 <commands+0xad8>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	e8c60613          	addi	a2,a2,-372 # ffffffffc02064c0 <commands+0x960>
ffffffffc020163c:	0fb00593          	li	a1,251
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	e9850513          	addi	a0,a0,-360 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201648:	e47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	02c68693          	addi	a3,a3,44 # ffffffffc0206678 <commands+0xb18>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	e6c60613          	addi	a2,a2,-404 # ffffffffc02064c0 <commands+0x960>
ffffffffc020165c:	0fa00593          	li	a1,250
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	e7850513          	addi	a0,a0,-392 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201668:	e27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	ea468693          	addi	a3,a3,-348 # ffffffffc0206510 <commands+0x9b0>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	e4c60613          	addi	a2,a2,-436 # ffffffffc02064c0 <commands+0x960>
ffffffffc020167c:	0d700593          	li	a1,215
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	e5850513          	addi	a0,a0,-424 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201688:	e07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	fac68693          	addi	a3,a3,-84 # ffffffffc0206638 <commands+0xad8>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	e2c60613          	addi	a2,a2,-468 # ffffffffc02064c0 <commands+0x960>
ffffffffc020169c:	0f400593          	li	a1,244
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	e3850513          	addi	a0,a0,-456 # ffffffffc02064d8 <commands+0x978>
ffffffffc02016a8:	de7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	ea468693          	addi	a3,a3,-348 # ffffffffc0206550 <commands+0x9f0>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	e0c60613          	addi	a2,a2,-500 # ffffffffc02064c0 <commands+0x960>
ffffffffc02016bc:	0f200593          	li	a1,242
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	e1850513          	addi	a0,a0,-488 # ffffffffc02064d8 <commands+0x978>
ffffffffc02016c8:	dc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	e6468693          	addi	a3,a3,-412 # ffffffffc0206530 <commands+0x9d0>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	dec60613          	addi	a2,a2,-532 # ffffffffc02064c0 <commands+0x960>
ffffffffc02016dc:	0f100593          	li	a1,241
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	df850513          	addi	a0,a0,-520 # ffffffffc02064d8 <commands+0x978>
ffffffffc02016e8:	da7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	e6468693          	addi	a3,a3,-412 # ffffffffc0206550 <commands+0x9f0>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	dcc60613          	addi	a2,a2,-564 # ffffffffc02064c0 <commands+0x960>
ffffffffc02016fc:	0d900593          	li	a1,217
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	dd850513          	addi	a0,a0,-552 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201708:	d87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	0ec68693          	addi	a3,a3,236 # ffffffffc02067f8 <commands+0xc98>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	dac60613          	addi	a2,a2,-596 # ffffffffc02064c0 <commands+0x960>
ffffffffc020171c:	14600593          	li	a1,326
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	db850513          	addi	a0,a0,-584 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201728:	d67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	f6c68693          	addi	a3,a3,-148 # ffffffffc0206698 <commands+0xb38>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	d8c60613          	addi	a2,a2,-628 # ffffffffc02064c0 <commands+0x960>
ffffffffc020173c:	13a00593          	li	a1,314
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	d9850513          	addi	a0,a0,-616 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201748:	d47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020174c:	00005697          	auipc	a3,0x5
ffffffffc0201750:	eec68693          	addi	a3,a3,-276 # ffffffffc0206638 <commands+0xad8>
ffffffffc0201754:	00005617          	auipc	a2,0x5
ffffffffc0201758:	d6c60613          	addi	a2,a2,-660 # ffffffffc02064c0 <commands+0x960>
ffffffffc020175c:	13800593          	li	a1,312
ffffffffc0201760:	00005517          	auipc	a0,0x5
ffffffffc0201764:	d7850513          	addi	a0,a0,-648 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201768:	d27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020176c:	00005697          	auipc	a3,0x5
ffffffffc0201770:	e8c68693          	addi	a3,a3,-372 # ffffffffc02065f8 <commands+0xa98>
ffffffffc0201774:	00005617          	auipc	a2,0x5
ffffffffc0201778:	d4c60613          	addi	a2,a2,-692 # ffffffffc02064c0 <commands+0x960>
ffffffffc020177c:	0df00593          	li	a1,223
ffffffffc0201780:	00005517          	auipc	a0,0x5
ffffffffc0201784:	d5850513          	addi	a0,a0,-680 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201788:	d07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020178c:	00005697          	auipc	a3,0x5
ffffffffc0201790:	02c68693          	addi	a3,a3,44 # ffffffffc02067b8 <commands+0xc58>
ffffffffc0201794:	00005617          	auipc	a2,0x5
ffffffffc0201798:	d2c60613          	addi	a2,a2,-724 # ffffffffc02064c0 <commands+0x960>
ffffffffc020179c:	13200593          	li	a1,306
ffffffffc02017a0:	00005517          	auipc	a0,0x5
ffffffffc02017a4:	d3850513          	addi	a0,a0,-712 # ffffffffc02064d8 <commands+0x978>
ffffffffc02017a8:	ce7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02017ac:	00005697          	auipc	a3,0x5
ffffffffc02017b0:	fec68693          	addi	a3,a3,-20 # ffffffffc0206798 <commands+0xc38>
ffffffffc02017b4:	00005617          	auipc	a2,0x5
ffffffffc02017b8:	d0c60613          	addi	a2,a2,-756 # ffffffffc02064c0 <commands+0x960>
ffffffffc02017bc:	13000593          	li	a1,304
ffffffffc02017c0:	00005517          	auipc	a0,0x5
ffffffffc02017c4:	d1850513          	addi	a0,a0,-744 # ffffffffc02064d8 <commands+0x978>
ffffffffc02017c8:	cc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02017cc:	00005697          	auipc	a3,0x5
ffffffffc02017d0:	fa468693          	addi	a3,a3,-92 # ffffffffc0206770 <commands+0xc10>
ffffffffc02017d4:	00005617          	auipc	a2,0x5
ffffffffc02017d8:	cec60613          	addi	a2,a2,-788 # ffffffffc02064c0 <commands+0x960>
ffffffffc02017dc:	12e00593          	li	a1,302
ffffffffc02017e0:	00005517          	auipc	a0,0x5
ffffffffc02017e4:	cf850513          	addi	a0,a0,-776 # ffffffffc02064d8 <commands+0x978>
ffffffffc02017e8:	ca7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02017ec:	00005697          	auipc	a3,0x5
ffffffffc02017f0:	f5c68693          	addi	a3,a3,-164 # ffffffffc0206748 <commands+0xbe8>
ffffffffc02017f4:	00005617          	auipc	a2,0x5
ffffffffc02017f8:	ccc60613          	addi	a2,a2,-820 # ffffffffc02064c0 <commands+0x960>
ffffffffc02017fc:	12d00593          	li	a1,301
ffffffffc0201800:	00005517          	auipc	a0,0x5
ffffffffc0201804:	cd850513          	addi	a0,a0,-808 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201808:	c87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc020180c:	00005697          	auipc	a3,0x5
ffffffffc0201810:	f2c68693          	addi	a3,a3,-212 # ffffffffc0206738 <commands+0xbd8>
ffffffffc0201814:	00005617          	auipc	a2,0x5
ffffffffc0201818:	cac60613          	addi	a2,a2,-852 # ffffffffc02064c0 <commands+0x960>
ffffffffc020181c:	12800593          	li	a1,296
ffffffffc0201820:	00005517          	auipc	a0,0x5
ffffffffc0201824:	cb850513          	addi	a0,a0,-840 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201828:	c67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020182c:	00005697          	auipc	a3,0x5
ffffffffc0201830:	e0c68693          	addi	a3,a3,-500 # ffffffffc0206638 <commands+0xad8>
ffffffffc0201834:	00005617          	auipc	a2,0x5
ffffffffc0201838:	c8c60613          	addi	a2,a2,-884 # ffffffffc02064c0 <commands+0x960>
ffffffffc020183c:	12700593          	li	a1,295
ffffffffc0201840:	00005517          	auipc	a0,0x5
ffffffffc0201844:	c9850513          	addi	a0,a0,-872 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201848:	c47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020184c:	00005697          	auipc	a3,0x5
ffffffffc0201850:	ecc68693          	addi	a3,a3,-308 # ffffffffc0206718 <commands+0xbb8>
ffffffffc0201854:	00005617          	auipc	a2,0x5
ffffffffc0201858:	c6c60613          	addi	a2,a2,-916 # ffffffffc02064c0 <commands+0x960>
ffffffffc020185c:	12600593          	li	a1,294
ffffffffc0201860:	00005517          	auipc	a0,0x5
ffffffffc0201864:	c7850513          	addi	a0,a0,-904 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201868:	c27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020186c:	00005697          	auipc	a3,0x5
ffffffffc0201870:	e7c68693          	addi	a3,a3,-388 # ffffffffc02066e8 <commands+0xb88>
ffffffffc0201874:	00005617          	auipc	a2,0x5
ffffffffc0201878:	c4c60613          	addi	a2,a2,-948 # ffffffffc02064c0 <commands+0x960>
ffffffffc020187c:	12500593          	li	a1,293
ffffffffc0201880:	00005517          	auipc	a0,0x5
ffffffffc0201884:	c5850513          	addi	a0,a0,-936 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201888:	c07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020188c:	00005697          	auipc	a3,0x5
ffffffffc0201890:	e4468693          	addi	a3,a3,-444 # ffffffffc02066d0 <commands+0xb70>
ffffffffc0201894:	00005617          	auipc	a2,0x5
ffffffffc0201898:	c2c60613          	addi	a2,a2,-980 # ffffffffc02064c0 <commands+0x960>
ffffffffc020189c:	12400593          	li	a1,292
ffffffffc02018a0:	00005517          	auipc	a0,0x5
ffffffffc02018a4:	c3850513          	addi	a0,a0,-968 # ffffffffc02064d8 <commands+0x978>
ffffffffc02018a8:	be7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02018ac:	00005697          	auipc	a3,0x5
ffffffffc02018b0:	d8c68693          	addi	a3,a3,-628 # ffffffffc0206638 <commands+0xad8>
ffffffffc02018b4:	00005617          	auipc	a2,0x5
ffffffffc02018b8:	c0c60613          	addi	a2,a2,-1012 # ffffffffc02064c0 <commands+0x960>
ffffffffc02018bc:	11e00593          	li	a1,286
ffffffffc02018c0:	00005517          	auipc	a0,0x5
ffffffffc02018c4:	c1850513          	addi	a0,a0,-1000 # ffffffffc02064d8 <commands+0x978>
ffffffffc02018c8:	bc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc02018cc:	00005697          	auipc	a3,0x5
ffffffffc02018d0:	dec68693          	addi	a3,a3,-532 # ffffffffc02066b8 <commands+0xb58>
ffffffffc02018d4:	00005617          	auipc	a2,0x5
ffffffffc02018d8:	bec60613          	addi	a2,a2,-1044 # ffffffffc02064c0 <commands+0x960>
ffffffffc02018dc:	11900593          	li	a1,281
ffffffffc02018e0:	00005517          	auipc	a0,0x5
ffffffffc02018e4:	bf850513          	addi	a0,a0,-1032 # ffffffffc02064d8 <commands+0x978>
ffffffffc02018e8:	ba7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02018ec:	00005697          	auipc	a3,0x5
ffffffffc02018f0:	eec68693          	addi	a3,a3,-276 # ffffffffc02067d8 <commands+0xc78>
ffffffffc02018f4:	00005617          	auipc	a2,0x5
ffffffffc02018f8:	bcc60613          	addi	a2,a2,-1076 # ffffffffc02064c0 <commands+0x960>
ffffffffc02018fc:	13700593          	li	a1,311
ffffffffc0201900:	00005517          	auipc	a0,0x5
ffffffffc0201904:	bd850513          	addi	a0,a0,-1064 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201908:	b87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc020190c:	00005697          	auipc	a3,0x5
ffffffffc0201910:	efc68693          	addi	a3,a3,-260 # ffffffffc0206808 <commands+0xca8>
ffffffffc0201914:	00005617          	auipc	a2,0x5
ffffffffc0201918:	bac60613          	addi	a2,a2,-1108 # ffffffffc02064c0 <commands+0x960>
ffffffffc020191c:	14700593          	li	a1,327
ffffffffc0201920:	00005517          	auipc	a0,0x5
ffffffffc0201924:	bb850513          	addi	a0,a0,-1096 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201928:	b67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc020192c:	00005697          	auipc	a3,0x5
ffffffffc0201930:	bc468693          	addi	a3,a3,-1084 # ffffffffc02064f0 <commands+0x990>
ffffffffc0201934:	00005617          	auipc	a2,0x5
ffffffffc0201938:	b8c60613          	addi	a2,a2,-1140 # ffffffffc02064c0 <commands+0x960>
ffffffffc020193c:	11300593          	li	a1,275
ffffffffc0201940:	00005517          	auipc	a0,0x5
ffffffffc0201944:	b9850513          	addi	a0,a0,-1128 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201948:	b47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020194c:	00005697          	auipc	a3,0x5
ffffffffc0201950:	be468693          	addi	a3,a3,-1052 # ffffffffc0206530 <commands+0x9d0>
ffffffffc0201954:	00005617          	auipc	a2,0x5
ffffffffc0201958:	b6c60613          	addi	a2,a2,-1172 # ffffffffc02064c0 <commands+0x960>
ffffffffc020195c:	0d800593          	li	a1,216
ffffffffc0201960:	00005517          	auipc	a0,0x5
ffffffffc0201964:	b7850513          	addi	a0,a0,-1160 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201968:	b27fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020196c <default_free_pages>:
{
ffffffffc020196c:	1141                	addi	sp,sp,-16
ffffffffc020196e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201970:	14058463          	beqz	a1,ffffffffc0201ab8 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201974:	00659693          	slli	a3,a1,0x6
ffffffffc0201978:	96aa                	add	a3,a3,a0
ffffffffc020197a:	87aa                	mv	a5,a0
ffffffffc020197c:	02d50263          	beq	a0,a3,ffffffffc02019a0 <default_free_pages+0x34>
ffffffffc0201980:	6798                	ld	a4,8(a5)
ffffffffc0201982:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201984:	10071a63          	bnez	a4,ffffffffc0201a98 <default_free_pages+0x12c>
ffffffffc0201988:	6798                	ld	a4,8(a5)
ffffffffc020198a:	8b09                	andi	a4,a4,2
ffffffffc020198c:	10071663          	bnez	a4,ffffffffc0201a98 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201990:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201994:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201998:	04078793          	addi	a5,a5,64
ffffffffc020199c:	fed792e3          	bne	a5,a3,ffffffffc0201980 <default_free_pages+0x14>
    base->property = n;
ffffffffc02019a0:	2581                	sext.w	a1,a1
ffffffffc02019a2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02019a4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019a8:	4789                	li	a5,2
ffffffffc02019aa:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02019ae:	000af697          	auipc	a3,0xaf
ffffffffc02019b2:	1c268693          	addi	a3,a3,450 # ffffffffc02b0b70 <free_area>
ffffffffc02019b6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019b8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019ba:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019be:	9db9                	addw	a1,a1,a4
ffffffffc02019c0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019c2:	0ad78463          	beq	a5,a3,ffffffffc0201a6a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02019c6:	fe878713          	addi	a4,a5,-24
ffffffffc02019ca:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019ce:	4581                	li	a1,0
            if (base < page)
ffffffffc02019d0:	00e56a63          	bltu	a0,a4,ffffffffc02019e4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02019d4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019d6:	04d70c63          	beq	a4,a3,ffffffffc0201a2e <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02019da:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019dc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019e0:	fee57ae3          	bgeu	a0,a4,ffffffffc02019d4 <default_free_pages+0x68>
ffffffffc02019e4:	c199                	beqz	a1,ffffffffc02019ea <default_free_pages+0x7e>
ffffffffc02019e6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019ea:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02019ec:	e390                	sd	a2,0(a5)
ffffffffc02019ee:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02019f0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019f2:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02019f4:	00d70d63          	beq	a4,a3,ffffffffc0201a0e <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02019f8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02019fc:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201a00:	02059813          	slli	a6,a1,0x20
ffffffffc0201a04:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201a08:	97b2                	add	a5,a5,a2
ffffffffc0201a0a:	02f50c63          	beq	a0,a5,ffffffffc0201a42 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201a0e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201a10:	00d78c63          	beq	a5,a3,ffffffffc0201a28 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201a14:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201a16:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201a1a:	02061593          	slli	a1,a2,0x20
ffffffffc0201a1e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201a22:	972a                	add	a4,a4,a0
ffffffffc0201a24:	04e68a63          	beq	a3,a4,ffffffffc0201a78 <default_free_pages+0x10c>
}
ffffffffc0201a28:	60a2                	ld	ra,8(sp)
ffffffffc0201a2a:	0141                	addi	sp,sp,16
ffffffffc0201a2c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a2e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a30:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a32:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a34:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a36:	02d70763          	beq	a4,a3,ffffffffc0201a64 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201a3a:	8832                	mv	a6,a2
ffffffffc0201a3c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a3e:	87ba                	mv	a5,a4
ffffffffc0201a40:	bf71                	j	ffffffffc02019dc <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201a42:	491c                	lw	a5,16(a0)
ffffffffc0201a44:	9dbd                	addw	a1,a1,a5
ffffffffc0201a46:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201a4a:	57f5                	li	a5,-3
ffffffffc0201a4c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201a50:	01853803          	ld	a6,24(a0)
ffffffffc0201a54:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201a56:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201a58:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201a5c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201a5e:	0105b023          	sd	a6,0(a1)
ffffffffc0201a62:	b77d                	j	ffffffffc0201a10 <default_free_pages+0xa4>
ffffffffc0201a64:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a66:	873e                	mv	a4,a5
ffffffffc0201a68:	bf41                	j	ffffffffc02019f8 <default_free_pages+0x8c>
}
ffffffffc0201a6a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a6c:	e390                	sd	a2,0(a5)
ffffffffc0201a6e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a70:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a72:	ed1c                	sd	a5,24(a0)
ffffffffc0201a74:	0141                	addi	sp,sp,16
ffffffffc0201a76:	8082                	ret
            base->property += p->property;
ffffffffc0201a78:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201a7c:	ff078693          	addi	a3,a5,-16
ffffffffc0201a80:	9e39                	addw	a2,a2,a4
ffffffffc0201a82:	c910                	sw	a2,16(a0)
ffffffffc0201a84:	5775                	li	a4,-3
ffffffffc0201a86:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201a8a:	6398                	ld	a4,0(a5)
ffffffffc0201a8c:	679c                	ld	a5,8(a5)
}
ffffffffc0201a8e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201a90:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201a92:	e398                	sd	a4,0(a5)
ffffffffc0201a94:	0141                	addi	sp,sp,16
ffffffffc0201a96:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201a98:	00005697          	auipc	a3,0x5
ffffffffc0201a9c:	d8868693          	addi	a3,a3,-632 # ffffffffc0206820 <commands+0xcc0>
ffffffffc0201aa0:	00005617          	auipc	a2,0x5
ffffffffc0201aa4:	a2060613          	addi	a2,a2,-1504 # ffffffffc02064c0 <commands+0x960>
ffffffffc0201aa8:	09400593          	li	a1,148
ffffffffc0201aac:	00005517          	auipc	a0,0x5
ffffffffc0201ab0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201ab4:	9dbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201ab8:	00005697          	auipc	a3,0x5
ffffffffc0201abc:	d6068693          	addi	a3,a3,-672 # ffffffffc0206818 <commands+0xcb8>
ffffffffc0201ac0:	00005617          	auipc	a2,0x5
ffffffffc0201ac4:	a0060613          	addi	a2,a2,-1536 # ffffffffc02064c0 <commands+0x960>
ffffffffc0201ac8:	09000593          	li	a1,144
ffffffffc0201acc:	00005517          	auipc	a0,0x5
ffffffffc0201ad0:	a0c50513          	addi	a0,a0,-1524 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201ad4:	9bbfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ad8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201ad8:	c941                	beqz	a0,ffffffffc0201b68 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201ada:	000af597          	auipc	a1,0xaf
ffffffffc0201ade:	09658593          	addi	a1,a1,150 # ffffffffc02b0b70 <free_area>
ffffffffc0201ae2:	0105a803          	lw	a6,16(a1)
ffffffffc0201ae6:	872a                	mv	a4,a0
ffffffffc0201ae8:	02081793          	slli	a5,a6,0x20
ffffffffc0201aec:	9381                	srli	a5,a5,0x20
ffffffffc0201aee:	00a7ee63          	bltu	a5,a0,ffffffffc0201b0a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201af2:	87ae                	mv	a5,a1
ffffffffc0201af4:	a801                	j	ffffffffc0201b04 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201af6:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201afa:	02069613          	slli	a2,a3,0x20
ffffffffc0201afe:	9201                	srli	a2,a2,0x20
ffffffffc0201b00:	00e67763          	bgeu	a2,a4,ffffffffc0201b0e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201b04:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201b06:	feb798e3          	bne	a5,a1,ffffffffc0201af6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201b0a:	4501                	li	a0,0
}
ffffffffc0201b0c:	8082                	ret
    return listelm->prev;
ffffffffc0201b0e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201b12:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201b16:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201b1a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201b1e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201b22:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201b26:	02c77863          	bgeu	a4,a2,ffffffffc0201b56 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201b2a:	071a                	slli	a4,a4,0x6
ffffffffc0201b2c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201b2e:	41c686bb          	subw	a3,a3,t3
ffffffffc0201b32:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201b34:	00870613          	addi	a2,a4,8
ffffffffc0201b38:	4689                	li	a3,2
ffffffffc0201b3a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201b3e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201b42:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201b46:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201b4a:	e290                	sd	a2,0(a3)
ffffffffc0201b4c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201b50:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201b52:	01173c23          	sd	a7,24(a4)
ffffffffc0201b56:	41c8083b          	subw	a6,a6,t3
ffffffffc0201b5a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201b5e:	5775                	li	a4,-3
ffffffffc0201b60:	17c1                	addi	a5,a5,-16
ffffffffc0201b62:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201b66:	8082                	ret
{
ffffffffc0201b68:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201b6a:	00005697          	auipc	a3,0x5
ffffffffc0201b6e:	cae68693          	addi	a3,a3,-850 # ffffffffc0206818 <commands+0xcb8>
ffffffffc0201b72:	00005617          	auipc	a2,0x5
ffffffffc0201b76:	94e60613          	addi	a2,a2,-1714 # ffffffffc02064c0 <commands+0x960>
ffffffffc0201b7a:	06c00593          	li	a1,108
ffffffffc0201b7e:	00005517          	auipc	a0,0x5
ffffffffc0201b82:	95a50513          	addi	a0,a0,-1702 # ffffffffc02064d8 <commands+0x978>
{
ffffffffc0201b86:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201b88:	907fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b8c <default_init_memmap>:
{
ffffffffc0201b8c:	1141                	addi	sp,sp,-16
ffffffffc0201b8e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201b90:	c5f1                	beqz	a1,ffffffffc0201c5c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201b92:	00659693          	slli	a3,a1,0x6
ffffffffc0201b96:	96aa                	add	a3,a3,a0
ffffffffc0201b98:	87aa                	mv	a5,a0
ffffffffc0201b9a:	00d50f63          	beq	a0,a3,ffffffffc0201bb8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201b9e:	6798                	ld	a4,8(a5)
ffffffffc0201ba0:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201ba2:	cf49                	beqz	a4,ffffffffc0201c3c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201ba4:	0007a823          	sw	zero,16(a5)
ffffffffc0201ba8:	0007b423          	sd	zero,8(a5)
ffffffffc0201bac:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201bb0:	04078793          	addi	a5,a5,64
ffffffffc0201bb4:	fed795e3          	bne	a5,a3,ffffffffc0201b9e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201bb8:	2581                	sext.w	a1,a1
ffffffffc0201bba:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201bbc:	4789                	li	a5,2
ffffffffc0201bbe:	00850713          	addi	a4,a0,8
ffffffffc0201bc2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201bc6:	000af697          	auipc	a3,0xaf
ffffffffc0201bca:	faa68693          	addi	a3,a3,-86 # ffffffffc02b0b70 <free_area>
ffffffffc0201bce:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201bd0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201bd2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201bd6:	9db9                	addw	a1,a1,a4
ffffffffc0201bd8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201bda:	04d78a63          	beq	a5,a3,ffffffffc0201c2e <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201bde:	fe878713          	addi	a4,a5,-24
ffffffffc0201be2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201be6:	4581                	li	a1,0
            if (base < page)
ffffffffc0201be8:	00e56a63          	bltu	a0,a4,ffffffffc0201bfc <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201bec:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201bee:	02d70263          	beq	a4,a3,ffffffffc0201c12 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201bf2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201bf4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201bf8:	fee57ae3          	bgeu	a0,a4,ffffffffc0201bec <default_init_memmap+0x60>
ffffffffc0201bfc:	c199                	beqz	a1,ffffffffc0201c02 <default_init_memmap+0x76>
ffffffffc0201bfe:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201c02:	6398                	ld	a4,0(a5)
}
ffffffffc0201c04:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201c06:	e390                	sd	a2,0(a5)
ffffffffc0201c08:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201c0a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201c0c:	ed18                	sd	a4,24(a0)
ffffffffc0201c0e:	0141                	addi	sp,sp,16
ffffffffc0201c10:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201c12:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201c14:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201c16:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201c18:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201c1a:	00d70663          	beq	a4,a3,ffffffffc0201c26 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201c1e:	8832                	mv	a6,a2
ffffffffc0201c20:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201c22:	87ba                	mv	a5,a4
ffffffffc0201c24:	bfc1                	j	ffffffffc0201bf4 <default_init_memmap+0x68>
}
ffffffffc0201c26:	60a2                	ld	ra,8(sp)
ffffffffc0201c28:	e290                	sd	a2,0(a3)
ffffffffc0201c2a:	0141                	addi	sp,sp,16
ffffffffc0201c2c:	8082                	ret
ffffffffc0201c2e:	60a2                	ld	ra,8(sp)
ffffffffc0201c30:	e390                	sd	a2,0(a5)
ffffffffc0201c32:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201c34:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201c36:	ed1c                	sd	a5,24(a0)
ffffffffc0201c38:	0141                	addi	sp,sp,16
ffffffffc0201c3a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201c3c:	00005697          	auipc	a3,0x5
ffffffffc0201c40:	c0c68693          	addi	a3,a3,-1012 # ffffffffc0206848 <commands+0xce8>
ffffffffc0201c44:	00005617          	auipc	a2,0x5
ffffffffc0201c48:	87c60613          	addi	a2,a2,-1924 # ffffffffc02064c0 <commands+0x960>
ffffffffc0201c4c:	04b00593          	li	a1,75
ffffffffc0201c50:	00005517          	auipc	a0,0x5
ffffffffc0201c54:	88850513          	addi	a0,a0,-1912 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201c58:	837fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201c5c:	00005697          	auipc	a3,0x5
ffffffffc0201c60:	bbc68693          	addi	a3,a3,-1092 # ffffffffc0206818 <commands+0xcb8>
ffffffffc0201c64:	00005617          	auipc	a2,0x5
ffffffffc0201c68:	85c60613          	addi	a2,a2,-1956 # ffffffffc02064c0 <commands+0x960>
ffffffffc0201c6c:	04700593          	li	a1,71
ffffffffc0201c70:	00005517          	auipc	a0,0x5
ffffffffc0201c74:	86850513          	addi	a0,a0,-1944 # ffffffffc02064d8 <commands+0x978>
ffffffffc0201c78:	817fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c7c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201c7c:	c94d                	beqz	a0,ffffffffc0201d2e <slob_free+0xb2>
{
ffffffffc0201c7e:	1141                	addi	sp,sp,-16
ffffffffc0201c80:	e022                	sd	s0,0(sp)
ffffffffc0201c82:	e406                	sd	ra,8(sp)
ffffffffc0201c84:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201c86:	e9c1                	bnez	a1,ffffffffc0201d16 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c88:	100027f3          	csrr	a5,sstatus
ffffffffc0201c8c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201c8e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c90:	ebd9                	bnez	a5,ffffffffc0201d26 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201c92:	000af617          	auipc	a2,0xaf
ffffffffc0201c96:	ace60613          	addi	a2,a2,-1330 # ffffffffc02b0760 <slobfree>
ffffffffc0201c9a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201c9c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201c9e:	679c                	ld	a5,8(a5)
ffffffffc0201ca0:	02877a63          	bgeu	a4,s0,ffffffffc0201cd4 <slob_free+0x58>
ffffffffc0201ca4:	00f46463          	bltu	s0,a5,ffffffffc0201cac <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ca8:	fef76ae3          	bltu	a4,a5,ffffffffc0201c9c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201cac:	400c                	lw	a1,0(s0)
ffffffffc0201cae:	00459693          	slli	a3,a1,0x4
ffffffffc0201cb2:	96a2                	add	a3,a3,s0
ffffffffc0201cb4:	02d78a63          	beq	a5,a3,ffffffffc0201ce8 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201cb8:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201cba:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201cbc:	00469793          	slli	a5,a3,0x4
ffffffffc0201cc0:	97ba                	add	a5,a5,a4
ffffffffc0201cc2:	02f40e63          	beq	s0,a5,ffffffffc0201cfe <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201cc6:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201cc8:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201cca:	e129                	bnez	a0,ffffffffc0201d0c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201ccc:	60a2                	ld	ra,8(sp)
ffffffffc0201cce:	6402                	ld	s0,0(sp)
ffffffffc0201cd0:	0141                	addi	sp,sp,16
ffffffffc0201cd2:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201cd4:	fcf764e3          	bltu	a4,a5,ffffffffc0201c9c <slob_free+0x20>
ffffffffc0201cd8:	fcf472e3          	bgeu	s0,a5,ffffffffc0201c9c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201cdc:	400c                	lw	a1,0(s0)
ffffffffc0201cde:	00459693          	slli	a3,a1,0x4
ffffffffc0201ce2:	96a2                	add	a3,a3,s0
ffffffffc0201ce4:	fcd79ae3          	bne	a5,a3,ffffffffc0201cb8 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201ce8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201cea:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201cec:	9db5                	addw	a1,a1,a3
ffffffffc0201cee:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201cf0:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201cf2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201cf4:	00469793          	slli	a5,a3,0x4
ffffffffc0201cf8:	97ba                	add	a5,a5,a4
ffffffffc0201cfa:	fcf416e3          	bne	s0,a5,ffffffffc0201cc6 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201cfe:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201d00:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201d02:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201d04:	9ebd                	addw	a3,a3,a5
ffffffffc0201d06:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201d08:	e70c                	sd	a1,8(a4)
ffffffffc0201d0a:	d169                	beqz	a0,ffffffffc0201ccc <slob_free+0x50>
}
ffffffffc0201d0c:	6402                	ld	s0,0(sp)
ffffffffc0201d0e:	60a2                	ld	ra,8(sp)
ffffffffc0201d10:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201d12:	c9dfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201d16:	25bd                	addiw	a1,a1,15
ffffffffc0201d18:	8191                	srli	a1,a1,0x4
ffffffffc0201d1a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d1c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d20:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201d22:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d24:	d7bd                	beqz	a5,ffffffffc0201c92 <slob_free+0x16>
        intr_disable();
ffffffffc0201d26:	c8ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201d2a:	4505                	li	a0,1
ffffffffc0201d2c:	b79d                	j	ffffffffc0201c92 <slob_free+0x16>
ffffffffc0201d2e:	8082                	ret

ffffffffc0201d30 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201d30:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201d32:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201d34:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201d38:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201d3a:	352000ef          	jal	ra,ffffffffc020208c <alloc_pages>
	if (!page)
ffffffffc0201d3e:	c91d                	beqz	a0,ffffffffc0201d74 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201d40:	000b3697          	auipc	a3,0xb3
ffffffffc0201d44:	ea06b683          	ld	a3,-352(a3) # ffffffffc02b4be0 <pages>
ffffffffc0201d48:	8d15                	sub	a0,a0,a3
ffffffffc0201d4a:	8519                	srai	a0,a0,0x6
ffffffffc0201d4c:	00006697          	auipc	a3,0x6
ffffffffc0201d50:	dcc6b683          	ld	a3,-564(a3) # ffffffffc0207b18 <nbase>
ffffffffc0201d54:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201d56:	00c51793          	slli	a5,a0,0xc
ffffffffc0201d5a:	83b1                	srli	a5,a5,0xc
ffffffffc0201d5c:	000b3717          	auipc	a4,0xb3
ffffffffc0201d60:	e7c73703          	ld	a4,-388(a4) # ffffffffc02b4bd8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d64:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201d66:	00e7fa63          	bgeu	a5,a4,ffffffffc0201d7a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201d6a:	000b3697          	auipc	a3,0xb3
ffffffffc0201d6e:	e866b683          	ld	a3,-378(a3) # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc0201d72:	9536                	add	a0,a0,a3
}
ffffffffc0201d74:	60a2                	ld	ra,8(sp)
ffffffffc0201d76:	0141                	addi	sp,sp,16
ffffffffc0201d78:	8082                	ret
ffffffffc0201d7a:	86aa                	mv	a3,a0
ffffffffc0201d7c:	00004617          	auipc	a2,0x4
ffffffffc0201d80:	46c60613          	addi	a2,a2,1132 # ffffffffc02061e8 <commands+0x688>
ffffffffc0201d84:	07100593          	li	a1,113
ffffffffc0201d88:	00004517          	auipc	a0,0x4
ffffffffc0201d8c:	42850513          	addi	a0,a0,1064 # ffffffffc02061b0 <commands+0x650>
ffffffffc0201d90:	efefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d94 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201d94:	1101                	addi	sp,sp,-32
ffffffffc0201d96:	ec06                	sd	ra,24(sp)
ffffffffc0201d98:	e822                	sd	s0,16(sp)
ffffffffc0201d9a:	e426                	sd	s1,8(sp)
ffffffffc0201d9c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d9e:	01050713          	addi	a4,a0,16
ffffffffc0201da2:	6785                	lui	a5,0x1
ffffffffc0201da4:	0cf77363          	bgeu	a4,a5,ffffffffc0201e6a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201da8:	00f50493          	addi	s1,a0,15
ffffffffc0201dac:	8091                	srli	s1,s1,0x4
ffffffffc0201dae:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201db0:	10002673          	csrr	a2,sstatus
ffffffffc0201db4:	8a09                	andi	a2,a2,2
ffffffffc0201db6:	e25d                	bnez	a2,ffffffffc0201e5c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201db8:	000af917          	auipc	s2,0xaf
ffffffffc0201dbc:	9a890913          	addi	s2,s2,-1624 # ffffffffc02b0760 <slobfree>
ffffffffc0201dc0:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201dc4:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201dc6:	4398                	lw	a4,0(a5)
ffffffffc0201dc8:	08975e63          	bge	a4,s1,ffffffffc0201e64 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201dcc:	00f68b63          	beq	a3,a5,ffffffffc0201de2 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201dd0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201dd2:	4018                	lw	a4,0(s0)
ffffffffc0201dd4:	02975a63          	bge	a4,s1,ffffffffc0201e08 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201dd8:	00093683          	ld	a3,0(s2)
ffffffffc0201ddc:	87a2                	mv	a5,s0
ffffffffc0201dde:	fef699e3          	bne	a3,a5,ffffffffc0201dd0 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201de2:	ee31                	bnez	a2,ffffffffc0201e3e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201de4:	4501                	li	a0,0
ffffffffc0201de6:	f4bff0ef          	jal	ra,ffffffffc0201d30 <__slob_get_free_pages.constprop.0>
ffffffffc0201dea:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201dec:	cd05                	beqz	a0,ffffffffc0201e24 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201dee:	6585                	lui	a1,0x1
ffffffffc0201df0:	e8dff0ef          	jal	ra,ffffffffc0201c7c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201df4:	10002673          	csrr	a2,sstatus
ffffffffc0201df8:	8a09                	andi	a2,a2,2
ffffffffc0201dfa:	ee05                	bnez	a2,ffffffffc0201e32 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201dfc:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201e00:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201e02:	4018                	lw	a4,0(s0)
ffffffffc0201e04:	fc974ae3          	blt	a4,s1,ffffffffc0201dd8 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201e08:	04e48763          	beq	s1,a4,ffffffffc0201e56 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201e0c:	00449693          	slli	a3,s1,0x4
ffffffffc0201e10:	96a2                	add	a3,a3,s0
ffffffffc0201e12:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201e14:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201e16:	9f05                	subw	a4,a4,s1
ffffffffc0201e18:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201e1a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201e1c:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201e1e:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201e22:	e20d                	bnez	a2,ffffffffc0201e44 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201e24:	60e2                	ld	ra,24(sp)
ffffffffc0201e26:	8522                	mv	a0,s0
ffffffffc0201e28:	6442                	ld	s0,16(sp)
ffffffffc0201e2a:	64a2                	ld	s1,8(sp)
ffffffffc0201e2c:	6902                	ld	s2,0(sp)
ffffffffc0201e2e:	6105                	addi	sp,sp,32
ffffffffc0201e30:	8082                	ret
        intr_disable();
ffffffffc0201e32:	b83fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201e36:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201e3a:	4605                	li	a2,1
ffffffffc0201e3c:	b7d1                	j	ffffffffc0201e00 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201e3e:	b71fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e42:	b74d                	j	ffffffffc0201de4 <slob_alloc.constprop.0+0x50>
ffffffffc0201e44:	b6bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201e48:	60e2                	ld	ra,24(sp)
ffffffffc0201e4a:	8522                	mv	a0,s0
ffffffffc0201e4c:	6442                	ld	s0,16(sp)
ffffffffc0201e4e:	64a2                	ld	s1,8(sp)
ffffffffc0201e50:	6902                	ld	s2,0(sp)
ffffffffc0201e52:	6105                	addi	sp,sp,32
ffffffffc0201e54:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201e56:	6418                	ld	a4,8(s0)
ffffffffc0201e58:	e798                	sd	a4,8(a5)
ffffffffc0201e5a:	b7d1                	j	ffffffffc0201e1e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201e5c:	b59fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201e60:	4605                	li	a2,1
ffffffffc0201e62:	bf99                	j	ffffffffc0201db8 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201e64:	843e                	mv	s0,a5
ffffffffc0201e66:	87b6                	mv	a5,a3
ffffffffc0201e68:	b745                	j	ffffffffc0201e08 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201e6a:	00005697          	auipc	a3,0x5
ffffffffc0201e6e:	a3e68693          	addi	a3,a3,-1474 # ffffffffc02068a8 <default_pmm_manager+0x38>
ffffffffc0201e72:	00004617          	auipc	a2,0x4
ffffffffc0201e76:	64e60613          	addi	a2,a2,1614 # ffffffffc02064c0 <commands+0x960>
ffffffffc0201e7a:	06300593          	li	a1,99
ffffffffc0201e7e:	00005517          	auipc	a0,0x5
ffffffffc0201e82:	a4a50513          	addi	a0,a0,-1462 # ffffffffc02068c8 <default_pmm_manager+0x58>
ffffffffc0201e86:	e08fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e8a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201e8a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201e8c:	00005517          	auipc	a0,0x5
ffffffffc0201e90:	a5450513          	addi	a0,a0,-1452 # ffffffffc02068e0 <default_pmm_manager+0x70>
{
ffffffffc0201e94:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201e96:	afefe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201e9a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201e9c:	00005517          	auipc	a0,0x5
ffffffffc0201ea0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc02068f8 <default_pmm_manager+0x88>
}
ffffffffc0201ea4:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ea6:	aeefe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201eaa <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201eaa:	4501                	li	a0,0
ffffffffc0201eac:	8082                	ret

ffffffffc0201eae <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201eae:	1101                	addi	sp,sp,-32
ffffffffc0201eb0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201eb2:	6905                	lui	s2,0x1
{
ffffffffc0201eb4:	e822                	sd	s0,16(sp)
ffffffffc0201eb6:	ec06                	sd	ra,24(sp)
ffffffffc0201eb8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201eba:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc9>
{
ffffffffc0201ebe:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ec0:	04a7f963          	bgeu	a5,a0,ffffffffc0201f12 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ec4:	4561                	li	a0,24
ffffffffc0201ec6:	ecfff0ef          	jal	ra,ffffffffc0201d94 <slob_alloc.constprop.0>
ffffffffc0201eca:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ecc:	c929                	beqz	a0,ffffffffc0201f1e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201ece:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ed2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ed4:	00f95763          	bge	s2,a5,ffffffffc0201ee2 <kmalloc+0x34>
ffffffffc0201ed8:	6705                	lui	a4,0x1
ffffffffc0201eda:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201edc:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ede:	fef74ee3          	blt	a4,a5,ffffffffc0201eda <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201ee2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ee4:	e4dff0ef          	jal	ra,ffffffffc0201d30 <__slob_get_free_pages.constprop.0>
ffffffffc0201ee8:	e488                	sd	a0,8(s1)
ffffffffc0201eea:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201eec:	c525                	beqz	a0,ffffffffc0201f54 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eee:	100027f3          	csrr	a5,sstatus
ffffffffc0201ef2:	8b89                	andi	a5,a5,2
ffffffffc0201ef4:	ef8d                	bnez	a5,ffffffffc0201f2e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201ef6:	000b3797          	auipc	a5,0xb3
ffffffffc0201efa:	cca78793          	addi	a5,a5,-822 # ffffffffc02b4bc0 <bigblocks>
ffffffffc0201efe:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201f00:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201f02:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201f04:	60e2                	ld	ra,24(sp)
ffffffffc0201f06:	8522                	mv	a0,s0
ffffffffc0201f08:	6442                	ld	s0,16(sp)
ffffffffc0201f0a:	64a2                	ld	s1,8(sp)
ffffffffc0201f0c:	6902                	ld	s2,0(sp)
ffffffffc0201f0e:	6105                	addi	sp,sp,32
ffffffffc0201f10:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201f12:	0541                	addi	a0,a0,16
ffffffffc0201f14:	e81ff0ef          	jal	ra,ffffffffc0201d94 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201f18:	01050413          	addi	s0,a0,16
ffffffffc0201f1c:	f565                	bnez	a0,ffffffffc0201f04 <kmalloc+0x56>
ffffffffc0201f1e:	4401                	li	s0,0
}
ffffffffc0201f20:	60e2                	ld	ra,24(sp)
ffffffffc0201f22:	8522                	mv	a0,s0
ffffffffc0201f24:	6442                	ld	s0,16(sp)
ffffffffc0201f26:	64a2                	ld	s1,8(sp)
ffffffffc0201f28:	6902                	ld	s2,0(sp)
ffffffffc0201f2a:	6105                	addi	sp,sp,32
ffffffffc0201f2c:	8082                	ret
        intr_disable();
ffffffffc0201f2e:	a87fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201f32:	000b3797          	auipc	a5,0xb3
ffffffffc0201f36:	c8e78793          	addi	a5,a5,-882 # ffffffffc02b4bc0 <bigblocks>
ffffffffc0201f3a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201f3c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201f3e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201f40:	a6ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201f44:	6480                	ld	s0,8(s1)
}
ffffffffc0201f46:	60e2                	ld	ra,24(sp)
ffffffffc0201f48:	64a2                	ld	s1,8(sp)
ffffffffc0201f4a:	8522                	mv	a0,s0
ffffffffc0201f4c:	6442                	ld	s0,16(sp)
ffffffffc0201f4e:	6902                	ld	s2,0(sp)
ffffffffc0201f50:	6105                	addi	sp,sp,32
ffffffffc0201f52:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201f54:	45e1                	li	a1,24
ffffffffc0201f56:	8526                	mv	a0,s1
ffffffffc0201f58:	d25ff0ef          	jal	ra,ffffffffc0201c7c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201f5c:	b765                	j	ffffffffc0201f04 <kmalloc+0x56>

ffffffffc0201f5e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201f5e:	c169                	beqz	a0,ffffffffc0202020 <kfree+0xc2>
{
ffffffffc0201f60:	1101                	addi	sp,sp,-32
ffffffffc0201f62:	e822                	sd	s0,16(sp)
ffffffffc0201f64:	ec06                	sd	ra,24(sp)
ffffffffc0201f66:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201f68:	03451793          	slli	a5,a0,0x34
ffffffffc0201f6c:	842a                	mv	s0,a0
ffffffffc0201f6e:	e3d9                	bnez	a5,ffffffffc0201ff4 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f70:	100027f3          	csrr	a5,sstatus
ffffffffc0201f74:	8b89                	andi	a5,a5,2
ffffffffc0201f76:	e7d9                	bnez	a5,ffffffffc0202004 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f78:	000b3797          	auipc	a5,0xb3
ffffffffc0201f7c:	c487b783          	ld	a5,-952(a5) # ffffffffc02b4bc0 <bigblocks>
    return 0;
ffffffffc0201f80:	4601                	li	a2,0
ffffffffc0201f82:	cbad                	beqz	a5,ffffffffc0201ff4 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201f84:	000b3697          	auipc	a3,0xb3
ffffffffc0201f88:	c3c68693          	addi	a3,a3,-964 # ffffffffc02b4bc0 <bigblocks>
ffffffffc0201f8c:	a021                	j	ffffffffc0201f94 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f8e:	01048693          	addi	a3,s1,16
ffffffffc0201f92:	c3a5                	beqz	a5,ffffffffc0201ff2 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201f94:	6798                	ld	a4,8(a5)
ffffffffc0201f96:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201f98:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201f9a:	fe871ae3          	bne	a4,s0,ffffffffc0201f8e <kfree+0x30>
				*last = bb->next;
ffffffffc0201f9e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201fa0:	ee2d                	bnez	a2,ffffffffc020201a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201fa2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201fa6:	4098                	lw	a4,0(s1)
ffffffffc0201fa8:	08f46963          	bltu	s0,a5,ffffffffc020203a <kfree+0xdc>
ffffffffc0201fac:	000b3697          	auipc	a3,0xb3
ffffffffc0201fb0:	c446b683          	ld	a3,-956(a3) # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc0201fb4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201fb6:	8031                	srli	s0,s0,0xc
ffffffffc0201fb8:	000b3797          	auipc	a5,0xb3
ffffffffc0201fbc:	c207b783          	ld	a5,-992(a5) # ffffffffc02b4bd8 <npage>
ffffffffc0201fc0:	06f47163          	bgeu	s0,a5,ffffffffc0202022 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fc4:	00006517          	auipc	a0,0x6
ffffffffc0201fc8:	b5453503          	ld	a0,-1196(a0) # ffffffffc0207b18 <nbase>
ffffffffc0201fcc:	8c09                	sub	s0,s0,a0
ffffffffc0201fce:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201fd0:	000b3517          	auipc	a0,0xb3
ffffffffc0201fd4:	c1053503          	ld	a0,-1008(a0) # ffffffffc02b4be0 <pages>
ffffffffc0201fd8:	4585                	li	a1,1
ffffffffc0201fda:	9522                	add	a0,a0,s0
ffffffffc0201fdc:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201fe0:	0ea000ef          	jal	ra,ffffffffc02020ca <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201fe4:	6442                	ld	s0,16(sp)
ffffffffc0201fe6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201fe8:	8526                	mv	a0,s1
}
ffffffffc0201fea:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201fec:	45e1                	li	a1,24
}
ffffffffc0201fee:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ff0:	b171                	j	ffffffffc0201c7c <slob_free>
ffffffffc0201ff2:	e20d                	bnez	a2,ffffffffc0202014 <kfree+0xb6>
ffffffffc0201ff4:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201ff8:	6442                	ld	s0,16(sp)
ffffffffc0201ffa:	60e2                	ld	ra,24(sp)
ffffffffc0201ffc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ffe:	4581                	li	a1,0
}
ffffffffc0202000:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202002:	b9ad                	j	ffffffffc0201c7c <slob_free>
        intr_disable();
ffffffffc0202004:	9b1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202008:	000b3797          	auipc	a5,0xb3
ffffffffc020200c:	bb87b783          	ld	a5,-1096(a5) # ffffffffc02b4bc0 <bigblocks>
        return 1;
ffffffffc0202010:	4605                	li	a2,1
ffffffffc0202012:	fbad                	bnez	a5,ffffffffc0201f84 <kfree+0x26>
        intr_enable();
ffffffffc0202014:	99bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202018:	bff1                	j	ffffffffc0201ff4 <kfree+0x96>
ffffffffc020201a:	995fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020201e:	b751                	j	ffffffffc0201fa2 <kfree+0x44>
ffffffffc0202020:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0202022:	00004617          	auipc	a2,0x4
ffffffffc0202026:	16e60613          	addi	a2,a2,366 # ffffffffc0206190 <commands+0x630>
ffffffffc020202a:	06900593          	li	a1,105
ffffffffc020202e:	00004517          	auipc	a0,0x4
ffffffffc0202032:	18250513          	addi	a0,a0,386 # ffffffffc02061b0 <commands+0x650>
ffffffffc0202036:	c58fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc020203a:	86a2                	mv	a3,s0
ffffffffc020203c:	00005617          	auipc	a2,0x5
ffffffffc0202040:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc0202044:	07700593          	li	a1,119
ffffffffc0202048:	00004517          	auipc	a0,0x4
ffffffffc020204c:	16850513          	addi	a0,a0,360 # ffffffffc02061b0 <commands+0x650>
ffffffffc0202050:	c3efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202054 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0202054:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0202056:	00004617          	auipc	a2,0x4
ffffffffc020205a:	13a60613          	addi	a2,a2,314 # ffffffffc0206190 <commands+0x630>
ffffffffc020205e:	06900593          	li	a1,105
ffffffffc0202062:	00004517          	auipc	a0,0x4
ffffffffc0202066:	14e50513          	addi	a0,a0,334 # ffffffffc02061b0 <commands+0x650>
pa2page(uintptr_t pa)
ffffffffc020206a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020206c:	c22fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202070 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0202070:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0202072:	00005617          	auipc	a2,0x5
ffffffffc0202076:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0206940 <default_pmm_manager+0xd0>
ffffffffc020207a:	07f00593          	li	a1,127
ffffffffc020207e:	00004517          	auipc	a0,0x4
ffffffffc0202082:	13250513          	addi	a0,a0,306 # ffffffffc02061b0 <commands+0x650>
pte2page(pte_t pte)
ffffffffc0202086:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0202088:	c06fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020208c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020208c:	100027f3          	csrr	a5,sstatus
ffffffffc0202090:	8b89                	andi	a5,a5,2
ffffffffc0202092:	e799                	bnez	a5,ffffffffc02020a0 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0202094:	000b3797          	auipc	a5,0xb3
ffffffffc0202098:	b547b783          	ld	a5,-1196(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc020209c:	6f9c                	ld	a5,24(a5)
ffffffffc020209e:	8782                	jr	a5
{
ffffffffc02020a0:	1141                	addi	sp,sp,-16
ffffffffc02020a2:	e406                	sd	ra,8(sp)
ffffffffc02020a4:	e022                	sd	s0,0(sp)
ffffffffc02020a6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02020a8:	90dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020ac:	000b3797          	auipc	a5,0xb3
ffffffffc02020b0:	b3c7b783          	ld	a5,-1220(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc02020b4:	6f9c                	ld	a5,24(a5)
ffffffffc02020b6:	8522                	mv	a0,s0
ffffffffc02020b8:	9782                	jalr	a5
ffffffffc02020ba:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020bc:	8f3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02020c0:	60a2                	ld	ra,8(sp)
ffffffffc02020c2:	8522                	mv	a0,s0
ffffffffc02020c4:	6402                	ld	s0,0(sp)
ffffffffc02020c6:	0141                	addi	sp,sp,16
ffffffffc02020c8:	8082                	ret

ffffffffc02020ca <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02020ca:	100027f3          	csrr	a5,sstatus
ffffffffc02020ce:	8b89                	andi	a5,a5,2
ffffffffc02020d0:	e799                	bnez	a5,ffffffffc02020de <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02020d2:	000b3797          	auipc	a5,0xb3
ffffffffc02020d6:	b167b783          	ld	a5,-1258(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc02020da:	739c                	ld	a5,32(a5)
ffffffffc02020dc:	8782                	jr	a5
{
ffffffffc02020de:	1101                	addi	sp,sp,-32
ffffffffc02020e0:	ec06                	sd	ra,24(sp)
ffffffffc02020e2:	e822                	sd	s0,16(sp)
ffffffffc02020e4:	e426                	sd	s1,8(sp)
ffffffffc02020e6:	842a                	mv	s0,a0
ffffffffc02020e8:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02020ea:	8cbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02020ee:	000b3797          	auipc	a5,0xb3
ffffffffc02020f2:	afa7b783          	ld	a5,-1286(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc02020f6:	739c                	ld	a5,32(a5)
ffffffffc02020f8:	85a6                	mv	a1,s1
ffffffffc02020fa:	8522                	mv	a0,s0
ffffffffc02020fc:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02020fe:	6442                	ld	s0,16(sp)
ffffffffc0202100:	60e2                	ld	ra,24(sp)
ffffffffc0202102:	64a2                	ld	s1,8(sp)
ffffffffc0202104:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0202106:	8a9fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc020210a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020210a:	100027f3          	csrr	a5,sstatus
ffffffffc020210e:	8b89                	andi	a5,a5,2
ffffffffc0202110:	e799                	bnez	a5,ffffffffc020211e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0202112:	000b3797          	auipc	a5,0xb3
ffffffffc0202116:	ad67b783          	ld	a5,-1322(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc020211a:	779c                	ld	a5,40(a5)
ffffffffc020211c:	8782                	jr	a5
{
ffffffffc020211e:	1141                	addi	sp,sp,-16
ffffffffc0202120:	e406                	sd	ra,8(sp)
ffffffffc0202122:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0202124:	891fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202128:	000b3797          	auipc	a5,0xb3
ffffffffc020212c:	ac07b783          	ld	a5,-1344(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc0202130:	779c                	ld	a5,40(a5)
ffffffffc0202132:	9782                	jalr	a5
ffffffffc0202134:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202136:	879fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020213a:	60a2                	ld	ra,8(sp)
ffffffffc020213c:	8522                	mv	a0,s0
ffffffffc020213e:	6402                	ld	s0,0(sp)
ffffffffc0202140:	0141                	addi	sp,sp,16
ffffffffc0202142:	8082                	ret

ffffffffc0202144 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202144:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0202148:	1ff7f793          	andi	a5,a5,511
{
ffffffffc020214c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020214e:	078e                	slli	a5,a5,0x3
{
ffffffffc0202150:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202152:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0202156:	6094                	ld	a3,0(s1)
{
ffffffffc0202158:	f04a                	sd	s2,32(sp)
ffffffffc020215a:	ec4e                	sd	s3,24(sp)
ffffffffc020215c:	e852                	sd	s4,16(sp)
ffffffffc020215e:	fc06                	sd	ra,56(sp)
ffffffffc0202160:	f822                	sd	s0,48(sp)
ffffffffc0202162:	e456                	sd	s5,8(sp)
ffffffffc0202164:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0202166:	0016f793          	andi	a5,a3,1
{
ffffffffc020216a:	892e                	mv	s2,a1
ffffffffc020216c:	8a32                	mv	s4,a2
ffffffffc020216e:	000b3997          	auipc	s3,0xb3
ffffffffc0202172:	a6a98993          	addi	s3,s3,-1430 # ffffffffc02b4bd8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202176:	efbd                	bnez	a5,ffffffffc02021f4 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202178:	14060c63          	beqz	a2,ffffffffc02022d0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020217c:	100027f3          	csrr	a5,sstatus
ffffffffc0202180:	8b89                	andi	a5,a5,2
ffffffffc0202182:	14079963          	bnez	a5,ffffffffc02022d4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202186:	000b3797          	auipc	a5,0xb3
ffffffffc020218a:	a627b783          	ld	a5,-1438(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc020218e:	6f9c                	ld	a5,24(a5)
ffffffffc0202190:	4505                	li	a0,1
ffffffffc0202192:	9782                	jalr	a5
ffffffffc0202194:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202196:	12040d63          	beqz	s0,ffffffffc02022d0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020219a:	000b3b17          	auipc	s6,0xb3
ffffffffc020219e:	a46b0b13          	addi	s6,s6,-1466 # ffffffffc02b4be0 <pages>
ffffffffc02021a2:	000b3503          	ld	a0,0(s6)
ffffffffc02021a6:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021aa:	000b3997          	auipc	s3,0xb3
ffffffffc02021ae:	a2e98993          	addi	s3,s3,-1490 # ffffffffc02b4bd8 <npage>
ffffffffc02021b2:	40a40533          	sub	a0,s0,a0
ffffffffc02021b6:	8519                	srai	a0,a0,0x6
ffffffffc02021b8:	9556                	add	a0,a0,s5
ffffffffc02021ba:	0009b703          	ld	a4,0(s3)
ffffffffc02021be:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02021c2:	4685                	li	a3,1
ffffffffc02021c4:	c014                	sw	a3,0(s0)
ffffffffc02021c6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02021c8:	0532                	slli	a0,a0,0xc
ffffffffc02021ca:	16e7f763          	bgeu	a5,a4,ffffffffc0202338 <get_pte+0x1f4>
ffffffffc02021ce:	000b3797          	auipc	a5,0xb3
ffffffffc02021d2:	a227b783          	ld	a5,-1502(a5) # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc02021d6:	6605                	lui	a2,0x1
ffffffffc02021d8:	4581                	li	a1,0
ffffffffc02021da:	953e                	add	a0,a0,a5
ffffffffc02021dc:	6f2030ef          	jal	ra,ffffffffc02058ce <memset>
    return page - pages + nbase;
ffffffffc02021e0:	000b3683          	ld	a3,0(s6)
ffffffffc02021e4:	40d406b3          	sub	a3,s0,a3
ffffffffc02021e8:	8699                	srai	a3,a3,0x6
ffffffffc02021ea:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02021ec:	06aa                	slli	a3,a3,0xa
ffffffffc02021ee:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02021f2:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021f4:	77fd                	lui	a5,0xfffff
ffffffffc02021f6:	068a                	slli	a3,a3,0x2
ffffffffc02021f8:	0009b703          	ld	a4,0(s3)
ffffffffc02021fc:	8efd                	and	a3,a3,a5
ffffffffc02021fe:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202202:	10e7ff63          	bgeu	a5,a4,ffffffffc0202320 <get_pte+0x1dc>
ffffffffc0202206:	000b3a97          	auipc	s5,0xb3
ffffffffc020220a:	9eaa8a93          	addi	s5,s5,-1558 # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc020220e:	000ab403          	ld	s0,0(s5)
ffffffffc0202212:	01595793          	srli	a5,s2,0x15
ffffffffc0202216:	1ff7f793          	andi	a5,a5,511
ffffffffc020221a:	96a2                	add	a3,a3,s0
ffffffffc020221c:	00379413          	slli	s0,a5,0x3
ffffffffc0202220:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202222:	6014                	ld	a3,0(s0)
ffffffffc0202224:	0016f793          	andi	a5,a3,1
ffffffffc0202228:	ebad                	bnez	a5,ffffffffc020229a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020222a:	0a0a0363          	beqz	s4,ffffffffc02022d0 <get_pte+0x18c>
ffffffffc020222e:	100027f3          	csrr	a5,sstatus
ffffffffc0202232:	8b89                	andi	a5,a5,2
ffffffffc0202234:	efcd                	bnez	a5,ffffffffc02022ee <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202236:	000b3797          	auipc	a5,0xb3
ffffffffc020223a:	9b27b783          	ld	a5,-1614(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc020223e:	6f9c                	ld	a5,24(a5)
ffffffffc0202240:	4505                	li	a0,1
ffffffffc0202242:	9782                	jalr	a5
ffffffffc0202244:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202246:	c4c9                	beqz	s1,ffffffffc02022d0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202248:	000b3b17          	auipc	s6,0xb3
ffffffffc020224c:	998b0b13          	addi	s6,s6,-1640 # ffffffffc02b4be0 <pages>
ffffffffc0202250:	000b3503          	ld	a0,0(s6)
ffffffffc0202254:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202258:	0009b703          	ld	a4,0(s3)
ffffffffc020225c:	40a48533          	sub	a0,s1,a0
ffffffffc0202260:	8519                	srai	a0,a0,0x6
ffffffffc0202262:	9552                	add	a0,a0,s4
ffffffffc0202264:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202268:	4685                	li	a3,1
ffffffffc020226a:	c094                	sw	a3,0(s1)
ffffffffc020226c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020226e:	0532                	slli	a0,a0,0xc
ffffffffc0202270:	0ee7f163          	bgeu	a5,a4,ffffffffc0202352 <get_pte+0x20e>
ffffffffc0202274:	000ab783          	ld	a5,0(s5)
ffffffffc0202278:	6605                	lui	a2,0x1
ffffffffc020227a:	4581                	li	a1,0
ffffffffc020227c:	953e                	add	a0,a0,a5
ffffffffc020227e:	650030ef          	jal	ra,ffffffffc02058ce <memset>
    return page - pages + nbase;
ffffffffc0202282:	000b3683          	ld	a3,0(s6)
ffffffffc0202286:	40d486b3          	sub	a3,s1,a3
ffffffffc020228a:	8699                	srai	a3,a3,0x6
ffffffffc020228c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020228e:	06aa                	slli	a3,a3,0xa
ffffffffc0202290:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202294:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202296:	0009b703          	ld	a4,0(s3)
ffffffffc020229a:	068a                	slli	a3,a3,0x2
ffffffffc020229c:	757d                	lui	a0,0xfffff
ffffffffc020229e:	8ee9                	and	a3,a3,a0
ffffffffc02022a0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02022a4:	06e7f263          	bgeu	a5,a4,ffffffffc0202308 <get_pte+0x1c4>
ffffffffc02022a8:	000ab503          	ld	a0,0(s5)
ffffffffc02022ac:	00c95913          	srli	s2,s2,0xc
ffffffffc02022b0:	1ff97913          	andi	s2,s2,511
ffffffffc02022b4:	96aa                	add	a3,a3,a0
ffffffffc02022b6:	00391513          	slli	a0,s2,0x3
ffffffffc02022ba:	9536                	add	a0,a0,a3
}
ffffffffc02022bc:	70e2                	ld	ra,56(sp)
ffffffffc02022be:	7442                	ld	s0,48(sp)
ffffffffc02022c0:	74a2                	ld	s1,40(sp)
ffffffffc02022c2:	7902                	ld	s2,32(sp)
ffffffffc02022c4:	69e2                	ld	s3,24(sp)
ffffffffc02022c6:	6a42                	ld	s4,16(sp)
ffffffffc02022c8:	6aa2                	ld	s5,8(sp)
ffffffffc02022ca:	6b02                	ld	s6,0(sp)
ffffffffc02022cc:	6121                	addi	sp,sp,64
ffffffffc02022ce:	8082                	ret
            return NULL;
ffffffffc02022d0:	4501                	li	a0,0
ffffffffc02022d2:	b7ed                	j	ffffffffc02022bc <get_pte+0x178>
        intr_disable();
ffffffffc02022d4:	ee0fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022d8:	000b3797          	auipc	a5,0xb3
ffffffffc02022dc:	9107b783          	ld	a5,-1776(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc02022e0:	6f9c                	ld	a5,24(a5)
ffffffffc02022e2:	4505                	li	a0,1
ffffffffc02022e4:	9782                	jalr	a5
ffffffffc02022e6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02022e8:	ec6fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022ec:	b56d                	j	ffffffffc0202196 <get_pte+0x52>
        intr_disable();
ffffffffc02022ee:	ec6fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02022f2:	000b3797          	auipc	a5,0xb3
ffffffffc02022f6:	8f67b783          	ld	a5,-1802(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc02022fa:	6f9c                	ld	a5,24(a5)
ffffffffc02022fc:	4505                	li	a0,1
ffffffffc02022fe:	9782                	jalr	a5
ffffffffc0202300:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202302:	eacfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202306:	b781                	j	ffffffffc0202246 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202308:	00004617          	auipc	a2,0x4
ffffffffc020230c:	ee060613          	addi	a2,a2,-288 # ffffffffc02061e8 <commands+0x688>
ffffffffc0202310:	0fa00593          	li	a1,250
ffffffffc0202314:	00004517          	auipc	a0,0x4
ffffffffc0202318:	65450513          	addi	a0,a0,1620 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020231c:	972fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202320:	00004617          	auipc	a2,0x4
ffffffffc0202324:	ec860613          	addi	a2,a2,-312 # ffffffffc02061e8 <commands+0x688>
ffffffffc0202328:	0ed00593          	li	a1,237
ffffffffc020232c:	00004517          	auipc	a0,0x4
ffffffffc0202330:	63c50513          	addi	a0,a0,1596 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0202334:	95afe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202338:	86aa                	mv	a3,a0
ffffffffc020233a:	00004617          	auipc	a2,0x4
ffffffffc020233e:	eae60613          	addi	a2,a2,-338 # ffffffffc02061e8 <commands+0x688>
ffffffffc0202342:	0e900593          	li	a1,233
ffffffffc0202346:	00004517          	auipc	a0,0x4
ffffffffc020234a:	62250513          	addi	a0,a0,1570 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020234e:	940fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202352:	86aa                	mv	a3,a0
ffffffffc0202354:	00004617          	auipc	a2,0x4
ffffffffc0202358:	e9460613          	addi	a2,a2,-364 # ffffffffc02061e8 <commands+0x688>
ffffffffc020235c:	0f700593          	li	a1,247
ffffffffc0202360:	00004517          	auipc	a0,0x4
ffffffffc0202364:	60850513          	addi	a0,a0,1544 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0202368:	926fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020236c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020236c:	1141                	addi	sp,sp,-16
ffffffffc020236e:	e022                	sd	s0,0(sp)
ffffffffc0202370:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202372:	4601                	li	a2,0
{
ffffffffc0202374:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202376:	dcfff0ef          	jal	ra,ffffffffc0202144 <get_pte>
    if (ptep_store != NULL)
ffffffffc020237a:	c011                	beqz	s0,ffffffffc020237e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020237c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020237e:	c511                	beqz	a0,ffffffffc020238a <get_page+0x1e>
ffffffffc0202380:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202382:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202384:	0017f713          	andi	a4,a5,1
ffffffffc0202388:	e709                	bnez	a4,ffffffffc0202392 <get_page+0x26>
}
ffffffffc020238a:	60a2                	ld	ra,8(sp)
ffffffffc020238c:	6402                	ld	s0,0(sp)
ffffffffc020238e:	0141                	addi	sp,sp,16
ffffffffc0202390:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202392:	078a                	slli	a5,a5,0x2
ffffffffc0202394:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202396:	000b3717          	auipc	a4,0xb3
ffffffffc020239a:	84273703          	ld	a4,-1982(a4) # ffffffffc02b4bd8 <npage>
ffffffffc020239e:	00e7ff63          	bgeu	a5,a4,ffffffffc02023bc <get_page+0x50>
ffffffffc02023a2:	60a2                	ld	ra,8(sp)
ffffffffc02023a4:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02023a6:	fff80537          	lui	a0,0xfff80
ffffffffc02023aa:	97aa                	add	a5,a5,a0
ffffffffc02023ac:	079a                	slli	a5,a5,0x6
ffffffffc02023ae:	000b3517          	auipc	a0,0xb3
ffffffffc02023b2:	83253503          	ld	a0,-1998(a0) # ffffffffc02b4be0 <pages>
ffffffffc02023b6:	953e                	add	a0,a0,a5
ffffffffc02023b8:	0141                	addi	sp,sp,16
ffffffffc02023ba:	8082                	ret
ffffffffc02023bc:	c99ff0ef          	jal	ra,ffffffffc0202054 <pa2page.part.0>

ffffffffc02023c0 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02023c0:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023c2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02023c6:	f486                	sd	ra,104(sp)
ffffffffc02023c8:	f0a2                	sd	s0,96(sp)
ffffffffc02023ca:	eca6                	sd	s1,88(sp)
ffffffffc02023cc:	e8ca                	sd	s2,80(sp)
ffffffffc02023ce:	e4ce                	sd	s3,72(sp)
ffffffffc02023d0:	e0d2                	sd	s4,64(sp)
ffffffffc02023d2:	fc56                	sd	s5,56(sp)
ffffffffc02023d4:	f85a                	sd	s6,48(sp)
ffffffffc02023d6:	f45e                	sd	s7,40(sp)
ffffffffc02023d8:	f062                	sd	s8,32(sp)
ffffffffc02023da:	ec66                	sd	s9,24(sp)
ffffffffc02023dc:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023de:	17d2                	slli	a5,a5,0x34
ffffffffc02023e0:	e3ed                	bnez	a5,ffffffffc02024c2 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02023e2:	002007b7          	lui	a5,0x200
ffffffffc02023e6:	842e                	mv	s0,a1
ffffffffc02023e8:	0ef5ed63          	bltu	a1,a5,ffffffffc02024e2 <unmap_range+0x122>
ffffffffc02023ec:	8932                	mv	s2,a2
ffffffffc02023ee:	0ec5fa63          	bgeu	a1,a2,ffffffffc02024e2 <unmap_range+0x122>
ffffffffc02023f2:	4785                	li	a5,1
ffffffffc02023f4:	07fe                	slli	a5,a5,0x1f
ffffffffc02023f6:	0ec7e663          	bltu	a5,a2,ffffffffc02024e2 <unmap_range+0x122>
ffffffffc02023fa:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02023fc:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02023fe:	000b2c97          	auipc	s9,0xb2
ffffffffc0202402:	7dac8c93          	addi	s9,s9,2010 # ffffffffc02b4bd8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202406:	000b2c17          	auipc	s8,0xb2
ffffffffc020240a:	7dac0c13          	addi	s8,s8,2010 # ffffffffc02b4be0 <pages>
ffffffffc020240e:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202412:	000b2d17          	auipc	s10,0xb2
ffffffffc0202416:	7d6d0d13          	addi	s10,s10,2006 # ffffffffc02b4be8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020241a:	00200b37          	lui	s6,0x200
ffffffffc020241e:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202422:	4601                	li	a2,0
ffffffffc0202424:	85a2                	mv	a1,s0
ffffffffc0202426:	854e                	mv	a0,s3
ffffffffc0202428:	d1dff0ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc020242c:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020242e:	cd29                	beqz	a0,ffffffffc0202488 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202430:	611c                	ld	a5,0(a0)
ffffffffc0202432:	e395                	bnez	a5,ffffffffc0202456 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202434:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202436:	ff2466e3          	bltu	s0,s2,ffffffffc0202422 <unmap_range+0x62>
}
ffffffffc020243a:	70a6                	ld	ra,104(sp)
ffffffffc020243c:	7406                	ld	s0,96(sp)
ffffffffc020243e:	64e6                	ld	s1,88(sp)
ffffffffc0202440:	6946                	ld	s2,80(sp)
ffffffffc0202442:	69a6                	ld	s3,72(sp)
ffffffffc0202444:	6a06                	ld	s4,64(sp)
ffffffffc0202446:	7ae2                	ld	s5,56(sp)
ffffffffc0202448:	7b42                	ld	s6,48(sp)
ffffffffc020244a:	7ba2                	ld	s7,40(sp)
ffffffffc020244c:	7c02                	ld	s8,32(sp)
ffffffffc020244e:	6ce2                	ld	s9,24(sp)
ffffffffc0202450:	6d42                	ld	s10,16(sp)
ffffffffc0202452:	6165                	addi	sp,sp,112
ffffffffc0202454:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202456:	0017f713          	andi	a4,a5,1
ffffffffc020245a:	df69                	beqz	a4,ffffffffc0202434 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020245c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202460:	078a                	slli	a5,a5,0x2
ffffffffc0202462:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202464:	08e7ff63          	bgeu	a5,a4,ffffffffc0202502 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202468:	000c3503          	ld	a0,0(s8)
ffffffffc020246c:	97de                	add	a5,a5,s7
ffffffffc020246e:	079a                	slli	a5,a5,0x6
ffffffffc0202470:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202472:	411c                	lw	a5,0(a0)
ffffffffc0202474:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202478:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020247a:	cf11                	beqz	a4,ffffffffc0202496 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020247c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202480:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202484:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202486:	bf45                	j	ffffffffc0202436 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202488:	945a                	add	s0,s0,s6
ffffffffc020248a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020248e:	d455                	beqz	s0,ffffffffc020243a <unmap_range+0x7a>
ffffffffc0202490:	f92469e3          	bltu	s0,s2,ffffffffc0202422 <unmap_range+0x62>
ffffffffc0202494:	b75d                	j	ffffffffc020243a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202496:	100027f3          	csrr	a5,sstatus
ffffffffc020249a:	8b89                	andi	a5,a5,2
ffffffffc020249c:	e799                	bnez	a5,ffffffffc02024aa <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020249e:	000d3783          	ld	a5,0(s10)
ffffffffc02024a2:	4585                	li	a1,1
ffffffffc02024a4:	739c                	ld	a5,32(a5)
ffffffffc02024a6:	9782                	jalr	a5
    if (flag)
ffffffffc02024a8:	bfd1                	j	ffffffffc020247c <unmap_range+0xbc>
ffffffffc02024aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02024ac:	d08fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02024b0:	000d3783          	ld	a5,0(s10)
ffffffffc02024b4:	6522                	ld	a0,8(sp)
ffffffffc02024b6:	4585                	li	a1,1
ffffffffc02024b8:	739c                	ld	a5,32(a5)
ffffffffc02024ba:	9782                	jalr	a5
        intr_enable();
ffffffffc02024bc:	cf2fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02024c0:	bf75                	j	ffffffffc020247c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024c2:	00004697          	auipc	a3,0x4
ffffffffc02024c6:	4b668693          	addi	a3,a3,1206 # ffffffffc0206978 <default_pmm_manager+0x108>
ffffffffc02024ca:	00004617          	auipc	a2,0x4
ffffffffc02024ce:	ff660613          	addi	a2,a2,-10 # ffffffffc02064c0 <commands+0x960>
ffffffffc02024d2:	12000593          	li	a1,288
ffffffffc02024d6:	00004517          	auipc	a0,0x4
ffffffffc02024da:	49250513          	addi	a0,a0,1170 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02024de:	fb1fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02024e2:	00004697          	auipc	a3,0x4
ffffffffc02024e6:	4c668693          	addi	a3,a3,1222 # ffffffffc02069a8 <default_pmm_manager+0x138>
ffffffffc02024ea:	00004617          	auipc	a2,0x4
ffffffffc02024ee:	fd660613          	addi	a2,a2,-42 # ffffffffc02064c0 <commands+0x960>
ffffffffc02024f2:	12100593          	li	a1,289
ffffffffc02024f6:	00004517          	auipc	a0,0x4
ffffffffc02024fa:	47250513          	addi	a0,a0,1138 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02024fe:	f91fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202502:	b53ff0ef          	jal	ra,ffffffffc0202054 <pa2page.part.0>

ffffffffc0202506 <exit_range>:
{
ffffffffc0202506:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202508:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020250c:	fc86                	sd	ra,120(sp)
ffffffffc020250e:	f8a2                	sd	s0,112(sp)
ffffffffc0202510:	f4a6                	sd	s1,104(sp)
ffffffffc0202512:	f0ca                	sd	s2,96(sp)
ffffffffc0202514:	ecce                	sd	s3,88(sp)
ffffffffc0202516:	e8d2                	sd	s4,80(sp)
ffffffffc0202518:	e4d6                	sd	s5,72(sp)
ffffffffc020251a:	e0da                	sd	s6,64(sp)
ffffffffc020251c:	fc5e                	sd	s7,56(sp)
ffffffffc020251e:	f862                	sd	s8,48(sp)
ffffffffc0202520:	f466                	sd	s9,40(sp)
ffffffffc0202522:	f06a                	sd	s10,32(sp)
ffffffffc0202524:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202526:	17d2                	slli	a5,a5,0x34
ffffffffc0202528:	20079a63          	bnez	a5,ffffffffc020273c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020252c:	002007b7          	lui	a5,0x200
ffffffffc0202530:	24f5e463          	bltu	a1,a5,ffffffffc0202778 <exit_range+0x272>
ffffffffc0202534:	8ab2                	mv	s5,a2
ffffffffc0202536:	24c5f163          	bgeu	a1,a2,ffffffffc0202778 <exit_range+0x272>
ffffffffc020253a:	4785                	li	a5,1
ffffffffc020253c:	07fe                	slli	a5,a5,0x1f
ffffffffc020253e:	22c7ed63          	bltu	a5,a2,ffffffffc0202778 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202542:	c00009b7          	lui	s3,0xc0000
ffffffffc0202546:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020254a:	ffe00937          	lui	s2,0xffe00
ffffffffc020254e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202552:	5cfd                	li	s9,-1
ffffffffc0202554:	8c2a                	mv	s8,a0
ffffffffc0202556:	0125f933          	and	s2,a1,s2
ffffffffc020255a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020255c:	000b2d17          	auipc	s10,0xb2
ffffffffc0202560:	67cd0d13          	addi	s10,s10,1660 # ffffffffc02b4bd8 <npage>
    return KADDR(page2pa(page));
ffffffffc0202564:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202568:	000b2717          	auipc	a4,0xb2
ffffffffc020256c:	67870713          	addi	a4,a4,1656 # ffffffffc02b4be0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202570:	000b2d97          	auipc	s11,0xb2
ffffffffc0202574:	678d8d93          	addi	s11,s11,1656 # ffffffffc02b4be8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202578:	c0000437          	lui	s0,0xc0000
ffffffffc020257c:	944e                	add	s0,s0,s3
ffffffffc020257e:	8079                	srli	s0,s0,0x1e
ffffffffc0202580:	1ff47413          	andi	s0,s0,511
ffffffffc0202584:	040e                	slli	s0,s0,0x3
ffffffffc0202586:	9462                	add	s0,s0,s8
ffffffffc0202588:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed0>
        if (pde1 & PTE_V)
ffffffffc020258c:	001a7793          	andi	a5,s4,1
ffffffffc0202590:	eb99                	bnez	a5,ffffffffc02025a6 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202592:	12098463          	beqz	s3,ffffffffc02026ba <exit_range+0x1b4>
ffffffffc0202596:	400007b7          	lui	a5,0x40000
ffffffffc020259a:	97ce                	add	a5,a5,s3
ffffffffc020259c:	894e                	mv	s2,s3
ffffffffc020259e:	1159fe63          	bgeu	s3,s5,ffffffffc02026ba <exit_range+0x1b4>
ffffffffc02025a2:	89be                	mv	s3,a5
ffffffffc02025a4:	bfd1                	j	ffffffffc0202578 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02025a6:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025aa:	0a0a                	slli	s4,s4,0x2
ffffffffc02025ac:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02025b0:	1cfa7263          	bgeu	s4,a5,ffffffffc0202774 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02025b4:	fff80637          	lui	a2,0xfff80
ffffffffc02025b8:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02025ba:	000806b7          	lui	a3,0x80
ffffffffc02025be:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02025c0:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02025c4:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02025c6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025c8:	18f5fa63          	bgeu	a1,a5,ffffffffc020275c <exit_range+0x256>
ffffffffc02025cc:	000b2817          	auipc	a6,0xb2
ffffffffc02025d0:	62480813          	addi	a6,a6,1572 # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc02025d4:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02025d8:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02025da:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02025de:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02025e0:	00080337          	lui	t1,0x80
ffffffffc02025e4:	6885                	lui	a7,0x1
ffffffffc02025e6:	a819                	j	ffffffffc02025fc <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02025e8:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02025ea:	002007b7          	lui	a5,0x200
ffffffffc02025ee:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02025f0:	08090c63          	beqz	s2,ffffffffc0202688 <exit_range+0x182>
ffffffffc02025f4:	09397a63          	bgeu	s2,s3,ffffffffc0202688 <exit_range+0x182>
ffffffffc02025f8:	0f597063          	bgeu	s2,s5,ffffffffc02026d8 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02025fc:	01595493          	srli	s1,s2,0x15
ffffffffc0202600:	1ff4f493          	andi	s1,s1,511
ffffffffc0202604:	048e                	slli	s1,s1,0x3
ffffffffc0202606:	94da                	add	s1,s1,s6
ffffffffc0202608:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020260a:	0017f693          	andi	a3,a5,1
ffffffffc020260e:	dee9                	beqz	a3,ffffffffc02025e8 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202610:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202614:	078a                	slli	a5,a5,0x2
ffffffffc0202616:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202618:	14b7fe63          	bgeu	a5,a1,ffffffffc0202774 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020261c:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020261e:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202622:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202626:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020262a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020262c:	12bef863          	bgeu	t4,a1,ffffffffc020275c <exit_range+0x256>
ffffffffc0202630:	00083783          	ld	a5,0(a6)
ffffffffc0202634:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202636:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020263a:	629c                	ld	a5,0(a3)
ffffffffc020263c:	8b85                	andi	a5,a5,1
ffffffffc020263e:	f7d5                	bnez	a5,ffffffffc02025ea <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202640:	06a1                	addi	a3,a3,8
ffffffffc0202642:	fed59ce3          	bne	a1,a3,ffffffffc020263a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202646:	631c                	ld	a5,0(a4)
ffffffffc0202648:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020264a:	100027f3          	csrr	a5,sstatus
ffffffffc020264e:	8b89                	andi	a5,a5,2
ffffffffc0202650:	e7d9                	bnez	a5,ffffffffc02026de <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202652:	000db783          	ld	a5,0(s11)
ffffffffc0202656:	4585                	li	a1,1
ffffffffc0202658:	e032                	sd	a2,0(sp)
ffffffffc020265a:	739c                	ld	a5,32(a5)
ffffffffc020265c:	9782                	jalr	a5
    if (flag)
ffffffffc020265e:	6602                	ld	a2,0(sp)
ffffffffc0202660:	000b2817          	auipc	a6,0xb2
ffffffffc0202664:	59080813          	addi	a6,a6,1424 # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc0202668:	fff80e37          	lui	t3,0xfff80
ffffffffc020266c:	00080337          	lui	t1,0x80
ffffffffc0202670:	6885                	lui	a7,0x1
ffffffffc0202672:	000b2717          	auipc	a4,0xb2
ffffffffc0202676:	56e70713          	addi	a4,a4,1390 # ffffffffc02b4be0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020267a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020267e:	002007b7          	lui	a5,0x200
ffffffffc0202682:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202684:	f60918e3          	bnez	s2,ffffffffc02025f4 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202688:	f00b85e3          	beqz	s7,ffffffffc0202592 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020268c:	000d3783          	ld	a5,0(s10)
ffffffffc0202690:	0efa7263          	bgeu	s4,a5,ffffffffc0202774 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202694:	6308                	ld	a0,0(a4)
ffffffffc0202696:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202698:	100027f3          	csrr	a5,sstatus
ffffffffc020269c:	8b89                	andi	a5,a5,2
ffffffffc020269e:	efad                	bnez	a5,ffffffffc0202718 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02026a0:	000db783          	ld	a5,0(s11)
ffffffffc02026a4:	4585                	li	a1,1
ffffffffc02026a6:	739c                	ld	a5,32(a5)
ffffffffc02026a8:	9782                	jalr	a5
ffffffffc02026aa:	000b2717          	auipc	a4,0xb2
ffffffffc02026ae:	53670713          	addi	a4,a4,1334 # ffffffffc02b4be0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02026b2:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02026b6:	ee0990e3          	bnez	s3,ffffffffc0202596 <exit_range+0x90>
}
ffffffffc02026ba:	70e6                	ld	ra,120(sp)
ffffffffc02026bc:	7446                	ld	s0,112(sp)
ffffffffc02026be:	74a6                	ld	s1,104(sp)
ffffffffc02026c0:	7906                	ld	s2,96(sp)
ffffffffc02026c2:	69e6                	ld	s3,88(sp)
ffffffffc02026c4:	6a46                	ld	s4,80(sp)
ffffffffc02026c6:	6aa6                	ld	s5,72(sp)
ffffffffc02026c8:	6b06                	ld	s6,64(sp)
ffffffffc02026ca:	7be2                	ld	s7,56(sp)
ffffffffc02026cc:	7c42                	ld	s8,48(sp)
ffffffffc02026ce:	7ca2                	ld	s9,40(sp)
ffffffffc02026d0:	7d02                	ld	s10,32(sp)
ffffffffc02026d2:	6de2                	ld	s11,24(sp)
ffffffffc02026d4:	6109                	addi	sp,sp,128
ffffffffc02026d6:	8082                	ret
            if (free_pd0)
ffffffffc02026d8:	ea0b8fe3          	beqz	s7,ffffffffc0202596 <exit_range+0x90>
ffffffffc02026dc:	bf45                	j	ffffffffc020268c <exit_range+0x186>
ffffffffc02026de:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02026e0:	e42a                	sd	a0,8(sp)
ffffffffc02026e2:	ad2fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026e6:	000db783          	ld	a5,0(s11)
ffffffffc02026ea:	6522                	ld	a0,8(sp)
ffffffffc02026ec:	4585                	li	a1,1
ffffffffc02026ee:	739c                	ld	a5,32(a5)
ffffffffc02026f0:	9782                	jalr	a5
        intr_enable();
ffffffffc02026f2:	abcfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026f6:	6602                	ld	a2,0(sp)
ffffffffc02026f8:	000b2717          	auipc	a4,0xb2
ffffffffc02026fc:	4e870713          	addi	a4,a4,1256 # ffffffffc02b4be0 <pages>
ffffffffc0202700:	6885                	lui	a7,0x1
ffffffffc0202702:	00080337          	lui	t1,0x80
ffffffffc0202706:	fff80e37          	lui	t3,0xfff80
ffffffffc020270a:	000b2817          	auipc	a6,0xb2
ffffffffc020270e:	4e680813          	addi	a6,a6,1254 # ffffffffc02b4bf0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202712:	0004b023          	sd	zero,0(s1)
ffffffffc0202716:	b7a5                	j	ffffffffc020267e <exit_range+0x178>
ffffffffc0202718:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020271a:	a9afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020271e:	000db783          	ld	a5,0(s11)
ffffffffc0202722:	6502                	ld	a0,0(sp)
ffffffffc0202724:	4585                	li	a1,1
ffffffffc0202726:	739c                	ld	a5,32(a5)
ffffffffc0202728:	9782                	jalr	a5
        intr_enable();
ffffffffc020272a:	a84fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020272e:	000b2717          	auipc	a4,0xb2
ffffffffc0202732:	4b270713          	addi	a4,a4,1202 # ffffffffc02b4be0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202736:	00043023          	sd	zero,0(s0)
ffffffffc020273a:	bfb5                	j	ffffffffc02026b6 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020273c:	00004697          	auipc	a3,0x4
ffffffffc0202740:	23c68693          	addi	a3,a3,572 # ffffffffc0206978 <default_pmm_manager+0x108>
ffffffffc0202744:	00004617          	auipc	a2,0x4
ffffffffc0202748:	d7c60613          	addi	a2,a2,-644 # ffffffffc02064c0 <commands+0x960>
ffffffffc020274c:	13500593          	li	a1,309
ffffffffc0202750:	00004517          	auipc	a0,0x4
ffffffffc0202754:	21850513          	addi	a0,a0,536 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0202758:	d37fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020275c:	00004617          	auipc	a2,0x4
ffffffffc0202760:	a8c60613          	addi	a2,a2,-1396 # ffffffffc02061e8 <commands+0x688>
ffffffffc0202764:	07100593          	li	a1,113
ffffffffc0202768:	00004517          	auipc	a0,0x4
ffffffffc020276c:	a4850513          	addi	a0,a0,-1464 # ffffffffc02061b0 <commands+0x650>
ffffffffc0202770:	d1ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202774:	8e1ff0ef          	jal	ra,ffffffffc0202054 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202778:	00004697          	auipc	a3,0x4
ffffffffc020277c:	23068693          	addi	a3,a3,560 # ffffffffc02069a8 <default_pmm_manager+0x138>
ffffffffc0202780:	00004617          	auipc	a2,0x4
ffffffffc0202784:	d4060613          	addi	a2,a2,-704 # ffffffffc02064c0 <commands+0x960>
ffffffffc0202788:	13600593          	li	a1,310
ffffffffc020278c:	00004517          	auipc	a0,0x4
ffffffffc0202790:	1dc50513          	addi	a0,a0,476 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0202794:	cfbfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202798 <page_remove>:
{
ffffffffc0202798:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020279a:	4601                	li	a2,0
{
ffffffffc020279c:	ec26                	sd	s1,24(sp)
ffffffffc020279e:	f406                	sd	ra,40(sp)
ffffffffc02027a0:	f022                	sd	s0,32(sp)
ffffffffc02027a2:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02027a4:	9a1ff0ef          	jal	ra,ffffffffc0202144 <get_pte>
    if (ptep != NULL)
ffffffffc02027a8:	c511                	beqz	a0,ffffffffc02027b4 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02027aa:	611c                	ld	a5,0(a0)
ffffffffc02027ac:	842a                	mv	s0,a0
ffffffffc02027ae:	0017f713          	andi	a4,a5,1
ffffffffc02027b2:	e711                	bnez	a4,ffffffffc02027be <page_remove+0x26>
}
ffffffffc02027b4:	70a2                	ld	ra,40(sp)
ffffffffc02027b6:	7402                	ld	s0,32(sp)
ffffffffc02027b8:	64e2                	ld	s1,24(sp)
ffffffffc02027ba:	6145                	addi	sp,sp,48
ffffffffc02027bc:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02027be:	078a                	slli	a5,a5,0x2
ffffffffc02027c0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027c2:	000b2717          	auipc	a4,0xb2
ffffffffc02027c6:	41673703          	ld	a4,1046(a4) # ffffffffc02b4bd8 <npage>
ffffffffc02027ca:	06e7f363          	bgeu	a5,a4,ffffffffc0202830 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02027ce:	fff80537          	lui	a0,0xfff80
ffffffffc02027d2:	97aa                	add	a5,a5,a0
ffffffffc02027d4:	079a                	slli	a5,a5,0x6
ffffffffc02027d6:	000b2517          	auipc	a0,0xb2
ffffffffc02027da:	40a53503          	ld	a0,1034(a0) # ffffffffc02b4be0 <pages>
ffffffffc02027de:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02027e0:	411c                	lw	a5,0(a0)
ffffffffc02027e2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02027e6:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02027e8:	cb11                	beqz	a4,ffffffffc02027fc <page_remove+0x64>
        *ptep = 0;
ffffffffc02027ea:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027ee:	12048073          	sfence.vma	s1
}
ffffffffc02027f2:	70a2                	ld	ra,40(sp)
ffffffffc02027f4:	7402                	ld	s0,32(sp)
ffffffffc02027f6:	64e2                	ld	s1,24(sp)
ffffffffc02027f8:	6145                	addi	sp,sp,48
ffffffffc02027fa:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027fc:	100027f3          	csrr	a5,sstatus
ffffffffc0202800:	8b89                	andi	a5,a5,2
ffffffffc0202802:	eb89                	bnez	a5,ffffffffc0202814 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202804:	000b2797          	auipc	a5,0xb2
ffffffffc0202808:	3e47b783          	ld	a5,996(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc020280c:	739c                	ld	a5,32(a5)
ffffffffc020280e:	4585                	li	a1,1
ffffffffc0202810:	9782                	jalr	a5
    if (flag)
ffffffffc0202812:	bfe1                	j	ffffffffc02027ea <page_remove+0x52>
        intr_disable();
ffffffffc0202814:	e42a                	sd	a0,8(sp)
ffffffffc0202816:	99efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020281a:	000b2797          	auipc	a5,0xb2
ffffffffc020281e:	3ce7b783          	ld	a5,974(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc0202822:	739c                	ld	a5,32(a5)
ffffffffc0202824:	6522                	ld	a0,8(sp)
ffffffffc0202826:	4585                	li	a1,1
ffffffffc0202828:	9782                	jalr	a5
        intr_enable();
ffffffffc020282a:	984fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020282e:	bf75                	j	ffffffffc02027ea <page_remove+0x52>
ffffffffc0202830:	825ff0ef          	jal	ra,ffffffffc0202054 <pa2page.part.0>

ffffffffc0202834 <page_insert>:
{
ffffffffc0202834:	7139                	addi	sp,sp,-64
ffffffffc0202836:	e852                	sd	s4,16(sp)
ffffffffc0202838:	8a32                	mv	s4,a2
ffffffffc020283a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020283c:	4605                	li	a2,1
{
ffffffffc020283e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202840:	85d2                	mv	a1,s4
{
ffffffffc0202842:	f426                	sd	s1,40(sp)
ffffffffc0202844:	fc06                	sd	ra,56(sp)
ffffffffc0202846:	f04a                	sd	s2,32(sp)
ffffffffc0202848:	ec4e                	sd	s3,24(sp)
ffffffffc020284a:	e456                	sd	s5,8(sp)
ffffffffc020284c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020284e:	8f7ff0ef          	jal	ra,ffffffffc0202144 <get_pte>
    if (ptep == NULL)
ffffffffc0202852:	c961                	beqz	a0,ffffffffc0202922 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202854:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202856:	611c                	ld	a5,0(a0)
ffffffffc0202858:	89aa                	mv	s3,a0
ffffffffc020285a:	0016871b          	addiw	a4,a3,1
ffffffffc020285e:	c018                	sw	a4,0(s0)
ffffffffc0202860:	0017f713          	andi	a4,a5,1
ffffffffc0202864:	ef05                	bnez	a4,ffffffffc020289c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202866:	000b2717          	auipc	a4,0xb2
ffffffffc020286a:	37a73703          	ld	a4,890(a4) # ffffffffc02b4be0 <pages>
ffffffffc020286e:	8c19                	sub	s0,s0,a4
ffffffffc0202870:	000807b7          	lui	a5,0x80
ffffffffc0202874:	8419                	srai	s0,s0,0x6
ffffffffc0202876:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202878:	042a                	slli	s0,s0,0xa
ffffffffc020287a:	8cc1                	or	s1,s1,s0
ffffffffc020287c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202880:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202884:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202888:	4501                	li	a0,0
}
ffffffffc020288a:	70e2                	ld	ra,56(sp)
ffffffffc020288c:	7442                	ld	s0,48(sp)
ffffffffc020288e:	74a2                	ld	s1,40(sp)
ffffffffc0202890:	7902                	ld	s2,32(sp)
ffffffffc0202892:	69e2                	ld	s3,24(sp)
ffffffffc0202894:	6a42                	ld	s4,16(sp)
ffffffffc0202896:	6aa2                	ld	s5,8(sp)
ffffffffc0202898:	6121                	addi	sp,sp,64
ffffffffc020289a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020289c:	078a                	slli	a5,a5,0x2
ffffffffc020289e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028a0:	000b2717          	auipc	a4,0xb2
ffffffffc02028a4:	33873703          	ld	a4,824(a4) # ffffffffc02b4bd8 <npage>
ffffffffc02028a8:	06e7ff63          	bgeu	a5,a4,ffffffffc0202926 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ac:	000b2a97          	auipc	s5,0xb2
ffffffffc02028b0:	334a8a93          	addi	s5,s5,820 # ffffffffc02b4be0 <pages>
ffffffffc02028b4:	000ab703          	ld	a4,0(s5)
ffffffffc02028b8:	fff80937          	lui	s2,0xfff80
ffffffffc02028bc:	993e                	add	s2,s2,a5
ffffffffc02028be:	091a                	slli	s2,s2,0x6
ffffffffc02028c0:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02028c2:	01240c63          	beq	s0,s2,ffffffffc02028da <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02028c6:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccb3ec>
ffffffffc02028ca:	fff7869b          	addiw	a3,a5,-1
ffffffffc02028ce:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02028d2:	c691                	beqz	a3,ffffffffc02028de <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02028d4:	120a0073          	sfence.vma	s4
}
ffffffffc02028d8:	bf59                	j	ffffffffc020286e <page_insert+0x3a>
ffffffffc02028da:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02028dc:	bf49                	j	ffffffffc020286e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028de:	100027f3          	csrr	a5,sstatus
ffffffffc02028e2:	8b89                	andi	a5,a5,2
ffffffffc02028e4:	ef91                	bnez	a5,ffffffffc0202900 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02028e6:	000b2797          	auipc	a5,0xb2
ffffffffc02028ea:	3027b783          	ld	a5,770(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc02028ee:	739c                	ld	a5,32(a5)
ffffffffc02028f0:	4585                	li	a1,1
ffffffffc02028f2:	854a                	mv	a0,s2
ffffffffc02028f4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02028f6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02028fa:	120a0073          	sfence.vma	s4
ffffffffc02028fe:	bf85                	j	ffffffffc020286e <page_insert+0x3a>
        intr_disable();
ffffffffc0202900:	8b4fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202904:	000b2797          	auipc	a5,0xb2
ffffffffc0202908:	2e47b783          	ld	a5,740(a5) # ffffffffc02b4be8 <pmm_manager>
ffffffffc020290c:	739c                	ld	a5,32(a5)
ffffffffc020290e:	4585                	li	a1,1
ffffffffc0202910:	854a                	mv	a0,s2
ffffffffc0202912:	9782                	jalr	a5
        intr_enable();
ffffffffc0202914:	89afe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202918:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020291c:	120a0073          	sfence.vma	s4
ffffffffc0202920:	b7b9                	j	ffffffffc020286e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202922:	5571                	li	a0,-4
ffffffffc0202924:	b79d                	j	ffffffffc020288a <page_insert+0x56>
ffffffffc0202926:	f2eff0ef          	jal	ra,ffffffffc0202054 <pa2page.part.0>

ffffffffc020292a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020292a:	00004797          	auipc	a5,0x4
ffffffffc020292e:	f4678793          	addi	a5,a5,-186 # ffffffffc0206870 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202932:	638c                	ld	a1,0(a5)
{
ffffffffc0202934:	7159                	addi	sp,sp,-112
ffffffffc0202936:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202938:	00004517          	auipc	a0,0x4
ffffffffc020293c:	08850513          	addi	a0,a0,136 # ffffffffc02069c0 <default_pmm_manager+0x150>
    pmm_manager = &default_pmm_manager;
ffffffffc0202940:	000b2b17          	auipc	s6,0xb2
ffffffffc0202944:	2a8b0b13          	addi	s6,s6,680 # ffffffffc02b4be8 <pmm_manager>
{
ffffffffc0202948:	f486                	sd	ra,104(sp)
ffffffffc020294a:	e8ca                	sd	s2,80(sp)
ffffffffc020294c:	e4ce                	sd	s3,72(sp)
ffffffffc020294e:	f0a2                	sd	s0,96(sp)
ffffffffc0202950:	eca6                	sd	s1,88(sp)
ffffffffc0202952:	e0d2                	sd	s4,64(sp)
ffffffffc0202954:	fc56                	sd	s5,56(sp)
ffffffffc0202956:	f45e                	sd	s7,40(sp)
ffffffffc0202958:	f062                	sd	s8,32(sp)
ffffffffc020295a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020295c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202960:	835fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202964:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202968:	000b2997          	auipc	s3,0xb2
ffffffffc020296c:	28898993          	addi	s3,s3,648 # ffffffffc02b4bf0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202970:	679c                	ld	a5,8(a5)
ffffffffc0202972:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202974:	57f5                	li	a5,-3
ffffffffc0202976:	07fa                	slli	a5,a5,0x1e
ffffffffc0202978:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020297c:	81efe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202980:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202982:	822fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202986:	200505e3          	beqz	a0,ffffffffc0203390 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020298a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020298c:	00004517          	auipc	a0,0x4
ffffffffc0202990:	06c50513          	addi	a0,a0,108 # ffffffffc02069f8 <default_pmm_manager+0x188>
ffffffffc0202994:	801fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202998:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020299c:	fff40693          	addi	a3,s0,-1
ffffffffc02029a0:	864a                	mv	a2,s2
ffffffffc02029a2:	85a6                	mv	a1,s1
ffffffffc02029a4:	00004517          	auipc	a0,0x4
ffffffffc02029a8:	06c50513          	addi	a0,a0,108 # ffffffffc0206a10 <default_pmm_manager+0x1a0>
ffffffffc02029ac:	fe8fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02029b0:	c8000737          	lui	a4,0xc8000
ffffffffc02029b4:	87a2                	mv	a5,s0
ffffffffc02029b6:	54876163          	bltu	a4,s0,ffffffffc0202ef8 <pmm_init+0x5ce>
ffffffffc02029ba:	757d                	lui	a0,0xfffff
ffffffffc02029bc:	000b3617          	auipc	a2,0xb3
ffffffffc02029c0:	25760613          	addi	a2,a2,599 # ffffffffc02b5c13 <end+0xfff>
ffffffffc02029c4:	8e69                	and	a2,a2,a0
ffffffffc02029c6:	000b2497          	auipc	s1,0xb2
ffffffffc02029ca:	21248493          	addi	s1,s1,530 # ffffffffc02b4bd8 <npage>
ffffffffc02029ce:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02029d2:	000b2b97          	auipc	s7,0xb2
ffffffffc02029d6:	20eb8b93          	addi	s7,s7,526 # ffffffffc02b4be0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02029da:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02029dc:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02029e0:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02029e4:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02029e6:	02f50863          	beq	a0,a5,ffffffffc0202a16 <pmm_init+0xec>
ffffffffc02029ea:	4781                	li	a5,0
ffffffffc02029ec:	4585                	li	a1,1
ffffffffc02029ee:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02029f2:	00679513          	slli	a0,a5,0x6
ffffffffc02029f6:	9532                	add	a0,a0,a2
ffffffffc02029f8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd4a3f4>
ffffffffc02029fc:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202a00:	6088                	ld	a0,0(s1)
ffffffffc0202a02:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202a04:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202a08:	00d50733          	add	a4,a0,a3
ffffffffc0202a0c:	fee7e3e3          	bltu	a5,a4,ffffffffc02029f2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202a10:	071a                	slli	a4,a4,0x6
ffffffffc0202a12:	00e606b3          	add	a3,a2,a4
ffffffffc0202a16:	c02007b7          	lui	a5,0xc0200
ffffffffc0202a1a:	2ef6ece3          	bltu	a3,a5,ffffffffc0203512 <pmm_init+0xbe8>
ffffffffc0202a1e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202a22:	77fd                	lui	a5,0xfffff
ffffffffc0202a24:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202a26:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202a28:	5086eb63          	bltu	a3,s0,ffffffffc0202f3e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202a2c:	00004517          	auipc	a0,0x4
ffffffffc0202a30:	00c50513          	addi	a0,a0,12 # ffffffffc0206a38 <default_pmm_manager+0x1c8>
ffffffffc0202a34:	f60fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202a38:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202a3c:	000b2917          	auipc	s2,0xb2
ffffffffc0202a40:	19490913          	addi	s2,s2,404 # ffffffffc02b4bd0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202a44:	7b9c                	ld	a5,48(a5)
ffffffffc0202a46:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202a48:	00004517          	auipc	a0,0x4
ffffffffc0202a4c:	00850513          	addi	a0,a0,8 # ffffffffc0206a50 <default_pmm_manager+0x1e0>
ffffffffc0202a50:	f44fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202a54:	00007697          	auipc	a3,0x7
ffffffffc0202a58:	5ac68693          	addi	a3,a3,1452 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202a5c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202a60:	c02007b7          	lui	a5,0xc0200
ffffffffc0202a64:	28f6ebe3          	bltu	a3,a5,ffffffffc02034fa <pmm_init+0xbd0>
ffffffffc0202a68:	0009b783          	ld	a5,0(s3)
ffffffffc0202a6c:	8e9d                	sub	a3,a3,a5
ffffffffc0202a6e:	000b2797          	auipc	a5,0xb2
ffffffffc0202a72:	14d7bd23          	sd	a3,346(a5) # ffffffffc02b4bc8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202a76:	100027f3          	csrr	a5,sstatus
ffffffffc0202a7a:	8b89                	andi	a5,a5,2
ffffffffc0202a7c:	4a079763          	bnez	a5,ffffffffc0202f2a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a80:	000b3783          	ld	a5,0(s6)
ffffffffc0202a84:	779c                	ld	a5,40(a5)
ffffffffc0202a86:	9782                	jalr	a5
ffffffffc0202a88:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202a8a:	6098                	ld	a4,0(s1)
ffffffffc0202a8c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202a90:	83b1                	srli	a5,a5,0xc
ffffffffc0202a92:	66e7e363          	bltu	a5,a4,ffffffffc02030f8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202a96:	00093503          	ld	a0,0(s2)
ffffffffc0202a9a:	62050f63          	beqz	a0,ffffffffc02030d8 <pmm_init+0x7ae>
ffffffffc0202a9e:	03451793          	slli	a5,a0,0x34
ffffffffc0202aa2:	62079b63          	bnez	a5,ffffffffc02030d8 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202aa6:	4601                	li	a2,0
ffffffffc0202aa8:	4581                	li	a1,0
ffffffffc0202aaa:	8c3ff0ef          	jal	ra,ffffffffc020236c <get_page>
ffffffffc0202aae:	60051563          	bnez	a0,ffffffffc02030b8 <pmm_init+0x78e>
ffffffffc0202ab2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ab6:	8b89                	andi	a5,a5,2
ffffffffc0202ab8:	44079e63          	bnez	a5,ffffffffc0202f14 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202abc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ac0:	4505                	li	a0,1
ffffffffc0202ac2:	6f9c                	ld	a5,24(a5)
ffffffffc0202ac4:	9782                	jalr	a5
ffffffffc0202ac6:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202ac8:	00093503          	ld	a0,0(s2)
ffffffffc0202acc:	4681                	li	a3,0
ffffffffc0202ace:	4601                	li	a2,0
ffffffffc0202ad0:	85d2                	mv	a1,s4
ffffffffc0202ad2:	d63ff0ef          	jal	ra,ffffffffc0202834 <page_insert>
ffffffffc0202ad6:	26051ae3          	bnez	a0,ffffffffc020354a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202ada:	00093503          	ld	a0,0(s2)
ffffffffc0202ade:	4601                	li	a2,0
ffffffffc0202ae0:	4581                	li	a1,0
ffffffffc0202ae2:	e62ff0ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc0202ae6:	240502e3          	beqz	a0,ffffffffc020352a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202aea:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202aec:	0017f713          	andi	a4,a5,1
ffffffffc0202af0:	5a070263          	beqz	a4,ffffffffc0203094 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202af4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202af6:	078a                	slli	a5,a5,0x2
ffffffffc0202af8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202afa:	58e7fb63          	bgeu	a5,a4,ffffffffc0203090 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202afe:	000bb683          	ld	a3,0(s7)
ffffffffc0202b02:	fff80637          	lui	a2,0xfff80
ffffffffc0202b06:	97b2                	add	a5,a5,a2
ffffffffc0202b08:	079a                	slli	a5,a5,0x6
ffffffffc0202b0a:	97b6                	add	a5,a5,a3
ffffffffc0202b0c:	14fa17e3          	bne	s4,a5,ffffffffc020345a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202b10:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0202b14:	4785                	li	a5,1
ffffffffc0202b16:	12f692e3          	bne	a3,a5,ffffffffc020343a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202b1a:	00093503          	ld	a0,0(s2)
ffffffffc0202b1e:	77fd                	lui	a5,0xfffff
ffffffffc0202b20:	6114                	ld	a3,0(a0)
ffffffffc0202b22:	068a                	slli	a3,a3,0x2
ffffffffc0202b24:	8efd                	and	a3,a3,a5
ffffffffc0202b26:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202b2a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203422 <pmm_init+0xaf8>
ffffffffc0202b2e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b32:	96e2                	add	a3,a3,s8
ffffffffc0202b34:	0006ba83          	ld	s5,0(a3)
ffffffffc0202b38:	0a8a                	slli	s5,s5,0x2
ffffffffc0202b3a:	00fafab3          	and	s5,s5,a5
ffffffffc0202b3e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202b42:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203408 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b46:	4601                	li	a2,0
ffffffffc0202b48:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b4a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b4c:	df8ff0ef          	jal	ra,ffffffffc0202144 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b50:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b52:	55551363          	bne	a0,s5,ffffffffc0203098 <pmm_init+0x76e>
ffffffffc0202b56:	100027f3          	csrr	a5,sstatus
ffffffffc0202b5a:	8b89                	andi	a5,a5,2
ffffffffc0202b5c:	3a079163          	bnez	a5,ffffffffc0202efe <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b60:	000b3783          	ld	a5,0(s6)
ffffffffc0202b64:	4505                	li	a0,1
ffffffffc0202b66:	6f9c                	ld	a5,24(a5)
ffffffffc0202b68:	9782                	jalr	a5
ffffffffc0202b6a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202b6c:	00093503          	ld	a0,0(s2)
ffffffffc0202b70:	46d1                	li	a3,20
ffffffffc0202b72:	6605                	lui	a2,0x1
ffffffffc0202b74:	85e2                	mv	a1,s8
ffffffffc0202b76:	cbfff0ef          	jal	ra,ffffffffc0202834 <page_insert>
ffffffffc0202b7a:	060517e3          	bnez	a0,ffffffffc02033e8 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202b7e:	00093503          	ld	a0,0(s2)
ffffffffc0202b82:	4601                	li	a2,0
ffffffffc0202b84:	6585                	lui	a1,0x1
ffffffffc0202b86:	dbeff0ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc0202b8a:	02050fe3          	beqz	a0,ffffffffc02033c8 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202b8e:	611c                	ld	a5,0(a0)
ffffffffc0202b90:	0107f713          	andi	a4,a5,16
ffffffffc0202b94:	7c070e63          	beqz	a4,ffffffffc0203370 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202b98:	8b91                	andi	a5,a5,4
ffffffffc0202b9a:	7a078b63          	beqz	a5,ffffffffc0203350 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b9e:	00093503          	ld	a0,0(s2)
ffffffffc0202ba2:	611c                	ld	a5,0(a0)
ffffffffc0202ba4:	8bc1                	andi	a5,a5,16
ffffffffc0202ba6:	78078563          	beqz	a5,ffffffffc0203330 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202baa:	000c2703          	lw	a4,0(s8)
ffffffffc0202bae:	4785                	li	a5,1
ffffffffc0202bb0:	76f71063          	bne	a4,a5,ffffffffc0203310 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202bb4:	4681                	li	a3,0
ffffffffc0202bb6:	6605                	lui	a2,0x1
ffffffffc0202bb8:	85d2                	mv	a1,s4
ffffffffc0202bba:	c7bff0ef          	jal	ra,ffffffffc0202834 <page_insert>
ffffffffc0202bbe:	72051963          	bnez	a0,ffffffffc02032f0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202bc2:	000a2703          	lw	a4,0(s4)
ffffffffc0202bc6:	4789                	li	a5,2
ffffffffc0202bc8:	70f71463          	bne	a4,a5,ffffffffc02032d0 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202bcc:	000c2783          	lw	a5,0(s8)
ffffffffc0202bd0:	6e079063          	bnez	a5,ffffffffc02032b0 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	4601                	li	a2,0
ffffffffc0202bda:	6585                	lui	a1,0x1
ffffffffc0202bdc:	d68ff0ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc0202be0:	6a050863          	beqz	a0,ffffffffc0203290 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202be4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202be6:	00177793          	andi	a5,a4,1
ffffffffc0202bea:	4a078563          	beqz	a5,ffffffffc0203094 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202bee:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202bf0:	00271793          	slli	a5,a4,0x2
ffffffffc0202bf4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bf6:	48d7fd63          	bgeu	a5,a3,ffffffffc0203090 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bfa:	000bb683          	ld	a3,0(s7)
ffffffffc0202bfe:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202c02:	97d6                	add	a5,a5,s5
ffffffffc0202c04:	079a                	slli	a5,a5,0x6
ffffffffc0202c06:	97b6                	add	a5,a5,a3
ffffffffc0202c08:	66fa1463          	bne	s4,a5,ffffffffc0203270 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202c0c:	8b41                	andi	a4,a4,16
ffffffffc0202c0e:	64071163          	bnez	a4,ffffffffc0203250 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202c12:	00093503          	ld	a0,0(s2)
ffffffffc0202c16:	4581                	li	a1,0
ffffffffc0202c18:	b81ff0ef          	jal	ra,ffffffffc0202798 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202c1c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202c20:	4785                	li	a5,1
ffffffffc0202c22:	60fc9763          	bne	s9,a5,ffffffffc0203230 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202c26:	000c2783          	lw	a5,0(s8)
ffffffffc0202c2a:	5e079363          	bnez	a5,ffffffffc0203210 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202c2e:	00093503          	ld	a0,0(s2)
ffffffffc0202c32:	6585                	lui	a1,0x1
ffffffffc0202c34:	b65ff0ef          	jal	ra,ffffffffc0202798 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202c38:	000a2783          	lw	a5,0(s4)
ffffffffc0202c3c:	52079a63          	bnez	a5,ffffffffc0203170 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202c40:	000c2783          	lw	a5,0(s8)
ffffffffc0202c44:	50079663          	bnez	a5,ffffffffc0203150 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202c48:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c4c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c4e:	000a3683          	ld	a3,0(s4)
ffffffffc0202c52:	068a                	slli	a3,a3,0x2
ffffffffc0202c54:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c56:	42b6fd63          	bgeu	a3,a1,ffffffffc0203090 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c5a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c5e:	96d6                	add	a3,a3,s5
ffffffffc0202c60:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202c62:	00d507b3          	add	a5,a0,a3
ffffffffc0202c66:	439c                	lw	a5,0(a5)
ffffffffc0202c68:	4d979463          	bne	a5,s9,ffffffffc0203130 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202c6c:	8699                	srai	a3,a3,0x6
ffffffffc0202c6e:	00080637          	lui	a2,0x80
ffffffffc0202c72:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202c74:	00c69713          	slli	a4,a3,0xc
ffffffffc0202c78:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c7a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c7c:	48b77e63          	bgeu	a4,a1,ffffffffc0203118 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202c80:	0009b703          	ld	a4,0(s3)
ffffffffc0202c84:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c86:	629c                	ld	a5,0(a3)
ffffffffc0202c88:	078a                	slli	a5,a5,0x2
ffffffffc0202c8a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c8c:	40b7f263          	bgeu	a5,a1,ffffffffc0203090 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c90:	8f91                	sub	a5,a5,a2
ffffffffc0202c92:	079a                	slli	a5,a5,0x6
ffffffffc0202c94:	953e                	add	a0,a0,a5
ffffffffc0202c96:	100027f3          	csrr	a5,sstatus
ffffffffc0202c9a:	8b89                	andi	a5,a5,2
ffffffffc0202c9c:	30079963          	bnez	a5,ffffffffc0202fae <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202ca0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ca4:	4585                	li	a1,1
ffffffffc0202ca6:	739c                	ld	a5,32(a5)
ffffffffc0202ca8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202caa:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202cae:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb0:	078a                	slli	a5,a5,0x2
ffffffffc0202cb2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cb4:	3ce7fe63          	bgeu	a5,a4,ffffffffc0203090 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cb8:	000bb503          	ld	a0,0(s7)
ffffffffc0202cbc:	fff80737          	lui	a4,0xfff80
ffffffffc0202cc0:	97ba                	add	a5,a5,a4
ffffffffc0202cc2:	079a                	slli	a5,a5,0x6
ffffffffc0202cc4:	953e                	add	a0,a0,a5
ffffffffc0202cc6:	100027f3          	csrr	a5,sstatus
ffffffffc0202cca:	8b89                	andi	a5,a5,2
ffffffffc0202ccc:	2c079563          	bnez	a5,ffffffffc0202f96 <pmm_init+0x66c>
ffffffffc0202cd0:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd4:	4585                	li	a1,1
ffffffffc0202cd6:	739c                	ld	a5,32(a5)
ffffffffc0202cd8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cda:	00093783          	ld	a5,0(s2)
ffffffffc0202cde:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd4a3ec>
    asm volatile("sfence.vma");
ffffffffc0202ce2:	12000073          	sfence.vma
ffffffffc0202ce6:	100027f3          	csrr	a5,sstatus
ffffffffc0202cea:	8b89                	andi	a5,a5,2
ffffffffc0202cec:	28079b63          	bnez	a5,ffffffffc0202f82 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cf0:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf4:	779c                	ld	a5,40(a5)
ffffffffc0202cf6:	9782                	jalr	a5
ffffffffc0202cf8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202cfa:	4b441b63          	bne	s0,s4,ffffffffc02031b0 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202cfe:	00004517          	auipc	a0,0x4
ffffffffc0202d02:	07a50513          	addi	a0,a0,122 # ffffffffc0206d78 <default_pmm_manager+0x508>
ffffffffc0202d06:	c8efd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202d0a:	100027f3          	csrr	a5,sstatus
ffffffffc0202d0e:	8b89                	andi	a5,a5,2
ffffffffc0202d10:	24079f63          	bnez	a5,ffffffffc0202f6e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d14:	000b3783          	ld	a5,0(s6)
ffffffffc0202d18:	779c                	ld	a5,40(a5)
ffffffffc0202d1a:	9782                	jalr	a5
ffffffffc0202d1c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d1e:	6098                	ld	a4,0(s1)
ffffffffc0202d20:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d24:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d26:	00c71793          	slli	a5,a4,0xc
ffffffffc0202d2a:	6a05                	lui	s4,0x1
ffffffffc0202d2c:	02f47c63          	bgeu	s0,a5,ffffffffc0202d64 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d30:	00c45793          	srli	a5,s0,0xc
ffffffffc0202d34:	00093503          	ld	a0,0(s2)
ffffffffc0202d38:	2ee7ff63          	bgeu	a5,a4,ffffffffc0203036 <pmm_init+0x70c>
ffffffffc0202d3c:	0009b583          	ld	a1,0(s3)
ffffffffc0202d40:	4601                	li	a2,0
ffffffffc0202d42:	95a2                	add	a1,a1,s0
ffffffffc0202d44:	c00ff0ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc0202d48:	32050463          	beqz	a0,ffffffffc0203070 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d4c:	611c                	ld	a5,0(a0)
ffffffffc0202d4e:	078a                	slli	a5,a5,0x2
ffffffffc0202d50:	0157f7b3          	and	a5,a5,s5
ffffffffc0202d54:	2e879e63          	bne	a5,s0,ffffffffc0203050 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d58:	6098                	ld	a4,0(s1)
ffffffffc0202d5a:	9452                	add	s0,s0,s4
ffffffffc0202d5c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202d60:	fcf468e3          	bltu	s0,a5,ffffffffc0202d30 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202d64:	00093783          	ld	a5,0(s2)
ffffffffc0202d68:	639c                	ld	a5,0(a5)
ffffffffc0202d6a:	42079363          	bnez	a5,ffffffffc0203190 <pmm_init+0x866>
ffffffffc0202d6e:	100027f3          	csrr	a5,sstatus
ffffffffc0202d72:	8b89                	andi	a5,a5,2
ffffffffc0202d74:	24079963          	bnez	a5,ffffffffc0202fc6 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d78:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7c:	4505                	li	a0,1
ffffffffc0202d7e:	6f9c                	ld	a5,24(a5)
ffffffffc0202d80:	9782                	jalr	a5
ffffffffc0202d82:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202d84:	00093503          	ld	a0,0(s2)
ffffffffc0202d88:	4699                	li	a3,6
ffffffffc0202d8a:	10000613          	li	a2,256
ffffffffc0202d8e:	85d2                	mv	a1,s4
ffffffffc0202d90:	aa5ff0ef          	jal	ra,ffffffffc0202834 <page_insert>
ffffffffc0202d94:	44051e63          	bnez	a0,ffffffffc02031f0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202d98:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0202d9c:	4785                	li	a5,1
ffffffffc0202d9e:	42f71963          	bne	a4,a5,ffffffffc02031d0 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202da2:	00093503          	ld	a0,0(s2)
ffffffffc0202da6:	6405                	lui	s0,0x1
ffffffffc0202da8:	4699                	li	a3,6
ffffffffc0202daa:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab8>
ffffffffc0202dae:	85d2                	mv	a1,s4
ffffffffc0202db0:	a85ff0ef          	jal	ra,ffffffffc0202834 <page_insert>
ffffffffc0202db4:	72051363          	bnez	a0,ffffffffc02034da <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202db8:	000a2703          	lw	a4,0(s4)
ffffffffc0202dbc:	4789                	li	a5,2
ffffffffc0202dbe:	6ef71e63          	bne	a4,a5,ffffffffc02034ba <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202dc2:	00004597          	auipc	a1,0x4
ffffffffc0202dc6:	0fe58593          	addi	a1,a1,254 # ffffffffc0206ec0 <default_pmm_manager+0x650>
ffffffffc0202dca:	10000513          	li	a0,256
ffffffffc0202dce:	295020ef          	jal	ra,ffffffffc0205862 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202dd2:	10040593          	addi	a1,s0,256
ffffffffc0202dd6:	10000513          	li	a0,256
ffffffffc0202dda:	29b020ef          	jal	ra,ffffffffc0205874 <strcmp>
ffffffffc0202dde:	6a051e63          	bnez	a0,ffffffffc020349a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202de2:	000bb683          	ld	a3,0(s7)
ffffffffc0202de6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202dea:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202dec:	40da06b3          	sub	a3,s4,a3
ffffffffc0202df0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202df2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202df4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202df6:	8031                	srli	s0,s0,0xc
ffffffffc0202df8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202dfc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202dfe:	30f77d63          	bgeu	a4,a5,ffffffffc0203118 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202e02:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202e06:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202e0a:	96be                	add	a3,a3,a5
ffffffffc0202e0c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202e10:	21d020ef          	jal	ra,ffffffffc020582c <strlen>
ffffffffc0202e14:	66051363          	bnez	a0,ffffffffc020347a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202e18:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202e1c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e1e:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd4a3ec>
ffffffffc0202e22:	068a                	slli	a3,a3,0x2
ffffffffc0202e24:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e26:	26f6f563          	bgeu	a3,a5,ffffffffc0203090 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202e2a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e2c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e2e:	2ef47563          	bgeu	s0,a5,ffffffffc0203118 <pmm_init+0x7ee>
ffffffffc0202e32:	0009b403          	ld	s0,0(s3)
ffffffffc0202e36:	9436                	add	s0,s0,a3
ffffffffc0202e38:	100027f3          	csrr	a5,sstatus
ffffffffc0202e3c:	8b89                	andi	a5,a5,2
ffffffffc0202e3e:	1e079163          	bnez	a5,ffffffffc0203020 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202e42:	000b3783          	ld	a5,0(s6)
ffffffffc0202e46:	4585                	li	a1,1
ffffffffc0202e48:	8552                	mv	a0,s4
ffffffffc0202e4a:	739c                	ld	a5,32(a5)
ffffffffc0202e4c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e4e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202e50:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e52:	078a                	slli	a5,a5,0x2
ffffffffc0202e54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e56:	22e7fd63          	bgeu	a5,a4,ffffffffc0203090 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e5a:	000bb503          	ld	a0,0(s7)
ffffffffc0202e5e:	fff80737          	lui	a4,0xfff80
ffffffffc0202e62:	97ba                	add	a5,a5,a4
ffffffffc0202e64:	079a                	slli	a5,a5,0x6
ffffffffc0202e66:	953e                	add	a0,a0,a5
ffffffffc0202e68:	100027f3          	csrr	a5,sstatus
ffffffffc0202e6c:	8b89                	andi	a5,a5,2
ffffffffc0202e6e:	18079d63          	bnez	a5,ffffffffc0203008 <pmm_init+0x6de>
ffffffffc0202e72:	000b3783          	ld	a5,0(s6)
ffffffffc0202e76:	4585                	li	a1,1
ffffffffc0202e78:	739c                	ld	a5,32(a5)
ffffffffc0202e7a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e7c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202e80:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e82:	078a                	slli	a5,a5,0x2
ffffffffc0202e84:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e86:	20e7f563          	bgeu	a5,a4,ffffffffc0203090 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e8a:	000bb503          	ld	a0,0(s7)
ffffffffc0202e8e:	fff80737          	lui	a4,0xfff80
ffffffffc0202e92:	97ba                	add	a5,a5,a4
ffffffffc0202e94:	079a                	slli	a5,a5,0x6
ffffffffc0202e96:	953e                	add	a0,a0,a5
ffffffffc0202e98:	100027f3          	csrr	a5,sstatus
ffffffffc0202e9c:	8b89                	andi	a5,a5,2
ffffffffc0202e9e:	14079963          	bnez	a5,ffffffffc0202ff0 <pmm_init+0x6c6>
ffffffffc0202ea2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ea6:	4585                	li	a1,1
ffffffffc0202ea8:	739c                	ld	a5,32(a5)
ffffffffc0202eaa:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202eac:	00093783          	ld	a5,0(s2)
ffffffffc0202eb0:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202eb4:	12000073          	sfence.vma
ffffffffc0202eb8:	100027f3          	csrr	a5,sstatus
ffffffffc0202ebc:	8b89                	andi	a5,a5,2
ffffffffc0202ebe:	10079f63          	bnez	a5,ffffffffc0202fdc <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ec2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec6:	779c                	ld	a5,40(a5)
ffffffffc0202ec8:	9782                	jalr	a5
ffffffffc0202eca:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202ecc:	4c8c1e63          	bne	s8,s0,ffffffffc02033a8 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202ed0:	00004517          	auipc	a0,0x4
ffffffffc0202ed4:	06850513          	addi	a0,a0,104 # ffffffffc0206f38 <default_pmm_manager+0x6c8>
ffffffffc0202ed8:	abcfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202edc:	7406                	ld	s0,96(sp)
ffffffffc0202ede:	70a6                	ld	ra,104(sp)
ffffffffc0202ee0:	64e6                	ld	s1,88(sp)
ffffffffc0202ee2:	6946                	ld	s2,80(sp)
ffffffffc0202ee4:	69a6                	ld	s3,72(sp)
ffffffffc0202ee6:	6a06                	ld	s4,64(sp)
ffffffffc0202ee8:	7ae2                	ld	s5,56(sp)
ffffffffc0202eea:	7b42                	ld	s6,48(sp)
ffffffffc0202eec:	7ba2                	ld	s7,40(sp)
ffffffffc0202eee:	7c02                	ld	s8,32(sp)
ffffffffc0202ef0:	6ce2                	ld	s9,24(sp)
ffffffffc0202ef2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202ef4:	f97fe06f          	j	ffffffffc0201e8a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202ef8:	c80007b7          	lui	a5,0xc8000
ffffffffc0202efc:	bc7d                	j	ffffffffc02029ba <pmm_init+0x90>
        intr_disable();
ffffffffc0202efe:	ab7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202f02:	000b3783          	ld	a5,0(s6)
ffffffffc0202f06:	4505                	li	a0,1
ffffffffc0202f08:	6f9c                	ld	a5,24(a5)
ffffffffc0202f0a:	9782                	jalr	a5
ffffffffc0202f0c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202f0e:	aa1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f12:	b9a9                	j	ffffffffc0202b6c <pmm_init+0x242>
        intr_disable();
ffffffffc0202f14:	aa1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202f18:	000b3783          	ld	a5,0(s6)
ffffffffc0202f1c:	4505                	li	a0,1
ffffffffc0202f1e:	6f9c                	ld	a5,24(a5)
ffffffffc0202f20:	9782                	jalr	a5
ffffffffc0202f22:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202f24:	a8bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f28:	b645                	j	ffffffffc0202ac8 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202f2a:	a8bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202f32:	779c                	ld	a5,40(a5)
ffffffffc0202f34:	9782                	jalr	a5
ffffffffc0202f36:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202f38:	a77fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f3c:	b6b9                	j	ffffffffc0202a8a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202f3e:	6705                	lui	a4,0x1
ffffffffc0202f40:	177d                	addi	a4,a4,-1
ffffffffc0202f42:	96ba                	add	a3,a3,a4
ffffffffc0202f44:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202f46:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202f4a:	14a77363          	bgeu	a4,a0,ffffffffc0203090 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202f4e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202f52:	fff80537          	lui	a0,0xfff80
ffffffffc0202f56:	972a                	add	a4,a4,a0
ffffffffc0202f58:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202f5a:	8c1d                	sub	s0,s0,a5
ffffffffc0202f5c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202f60:	00c45593          	srli	a1,s0,0xc
ffffffffc0202f64:	9532                	add	a0,a0,a2
ffffffffc0202f66:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202f68:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202f6c:	b4c1                	j	ffffffffc0202a2c <pmm_init+0x102>
        intr_disable();
ffffffffc0202f6e:	a47fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f72:	000b3783          	ld	a5,0(s6)
ffffffffc0202f76:	779c                	ld	a5,40(a5)
ffffffffc0202f78:	9782                	jalr	a5
ffffffffc0202f7a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202f7c:	a33fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f80:	bb79                	j	ffffffffc0202d1e <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202f82:	a33fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202f86:	000b3783          	ld	a5,0(s6)
ffffffffc0202f8a:	779c                	ld	a5,40(a5)
ffffffffc0202f8c:	9782                	jalr	a5
ffffffffc0202f8e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202f90:	a1ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f94:	b39d                	j	ffffffffc0202cfa <pmm_init+0x3d0>
ffffffffc0202f96:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f98:	a1dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202f9c:	000b3783          	ld	a5,0(s6)
ffffffffc0202fa0:	6522                	ld	a0,8(sp)
ffffffffc0202fa2:	4585                	li	a1,1
ffffffffc0202fa4:	739c                	ld	a5,32(a5)
ffffffffc0202fa6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202fa8:	a07fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fac:	b33d                	j	ffffffffc0202cda <pmm_init+0x3b0>
ffffffffc0202fae:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202fb0:	a05fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202fb4:	000b3783          	ld	a5,0(s6)
ffffffffc0202fb8:	6522                	ld	a0,8(sp)
ffffffffc0202fba:	4585                	li	a1,1
ffffffffc0202fbc:	739c                	ld	a5,32(a5)
ffffffffc0202fbe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202fc0:	9effd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fc4:	b1dd                	j	ffffffffc0202caa <pmm_init+0x380>
        intr_disable();
ffffffffc0202fc6:	9effd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202fca:	000b3783          	ld	a5,0(s6)
ffffffffc0202fce:	4505                	li	a0,1
ffffffffc0202fd0:	6f9c                	ld	a5,24(a5)
ffffffffc0202fd2:	9782                	jalr	a5
ffffffffc0202fd4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202fd6:	9d9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fda:	b36d                	j	ffffffffc0202d84 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202fdc:	9d9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202fe0:	000b3783          	ld	a5,0(s6)
ffffffffc0202fe4:	779c                	ld	a5,40(a5)
ffffffffc0202fe6:	9782                	jalr	a5
ffffffffc0202fe8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202fea:	9c5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fee:	bdf9                	j	ffffffffc0202ecc <pmm_init+0x5a2>
ffffffffc0202ff0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ff2:	9c3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ff6:	000b3783          	ld	a5,0(s6)
ffffffffc0202ffa:	6522                	ld	a0,8(sp)
ffffffffc0202ffc:	4585                	li	a1,1
ffffffffc0202ffe:	739c                	ld	a5,32(a5)
ffffffffc0203000:	9782                	jalr	a5
        intr_enable();
ffffffffc0203002:	9adfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203006:	b55d                	j	ffffffffc0202eac <pmm_init+0x582>
ffffffffc0203008:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020300a:	9abfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020300e:	000b3783          	ld	a5,0(s6)
ffffffffc0203012:	6522                	ld	a0,8(sp)
ffffffffc0203014:	4585                	li	a1,1
ffffffffc0203016:	739c                	ld	a5,32(a5)
ffffffffc0203018:	9782                	jalr	a5
        intr_enable();
ffffffffc020301a:	995fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020301e:	bdb9                	j	ffffffffc0202e7c <pmm_init+0x552>
        intr_disable();
ffffffffc0203020:	995fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203024:	000b3783          	ld	a5,0(s6)
ffffffffc0203028:	4585                	li	a1,1
ffffffffc020302a:	8552                	mv	a0,s4
ffffffffc020302c:	739c                	ld	a5,32(a5)
ffffffffc020302e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203030:	97ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203034:	bd29                	j	ffffffffc0202e4e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203036:	86a2                	mv	a3,s0
ffffffffc0203038:	00003617          	auipc	a2,0x3
ffffffffc020303c:	1b060613          	addi	a2,a2,432 # ffffffffc02061e8 <commands+0x688>
ffffffffc0203040:	26100593          	li	a1,609
ffffffffc0203044:	00004517          	auipc	a0,0x4
ffffffffc0203048:	92450513          	addi	a0,a0,-1756 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020304c:	c42fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203050:	00004697          	auipc	a3,0x4
ffffffffc0203054:	d8868693          	addi	a3,a3,-632 # ffffffffc0206dd8 <default_pmm_manager+0x568>
ffffffffc0203058:	00003617          	auipc	a2,0x3
ffffffffc020305c:	46860613          	addi	a2,a2,1128 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203060:	26200593          	li	a1,610
ffffffffc0203064:	00004517          	auipc	a0,0x4
ffffffffc0203068:	90450513          	addi	a0,a0,-1788 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020306c:	c22fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203070:	00004697          	auipc	a3,0x4
ffffffffc0203074:	d2868693          	addi	a3,a3,-728 # ffffffffc0206d98 <default_pmm_manager+0x528>
ffffffffc0203078:	00003617          	auipc	a2,0x3
ffffffffc020307c:	44860613          	addi	a2,a2,1096 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203080:	26100593          	li	a1,609
ffffffffc0203084:	00004517          	auipc	a0,0x4
ffffffffc0203088:	8e450513          	addi	a0,a0,-1820 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020308c:	c02fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203090:	fc5fe0ef          	jal	ra,ffffffffc0202054 <pa2page.part.0>
ffffffffc0203094:	fddfe0ef          	jal	ra,ffffffffc0202070 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0203098:	00004697          	auipc	a3,0x4
ffffffffc020309c:	af868693          	addi	a3,a3,-1288 # ffffffffc0206b90 <default_pmm_manager+0x320>
ffffffffc02030a0:	00003617          	auipc	a2,0x3
ffffffffc02030a4:	42060613          	addi	a2,a2,1056 # ffffffffc02064c0 <commands+0x960>
ffffffffc02030a8:	23100593          	li	a1,561
ffffffffc02030ac:	00004517          	auipc	a0,0x4
ffffffffc02030b0:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02030b4:	bdafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02030b8:	00004697          	auipc	a3,0x4
ffffffffc02030bc:	a1868693          	addi	a3,a3,-1512 # ffffffffc0206ad0 <default_pmm_manager+0x260>
ffffffffc02030c0:	00003617          	auipc	a2,0x3
ffffffffc02030c4:	40060613          	addi	a2,a2,1024 # ffffffffc02064c0 <commands+0x960>
ffffffffc02030c8:	22400593          	li	a1,548
ffffffffc02030cc:	00004517          	auipc	a0,0x4
ffffffffc02030d0:	89c50513          	addi	a0,a0,-1892 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02030d4:	bbafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02030d8:	00004697          	auipc	a3,0x4
ffffffffc02030dc:	9b868693          	addi	a3,a3,-1608 # ffffffffc0206a90 <default_pmm_manager+0x220>
ffffffffc02030e0:	00003617          	auipc	a2,0x3
ffffffffc02030e4:	3e060613          	addi	a2,a2,992 # ffffffffc02064c0 <commands+0x960>
ffffffffc02030e8:	22300593          	li	a1,547
ffffffffc02030ec:	00004517          	auipc	a0,0x4
ffffffffc02030f0:	87c50513          	addi	a0,a0,-1924 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02030f4:	b9afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02030f8:	00004697          	auipc	a3,0x4
ffffffffc02030fc:	97868693          	addi	a3,a3,-1672 # ffffffffc0206a70 <default_pmm_manager+0x200>
ffffffffc0203100:	00003617          	auipc	a2,0x3
ffffffffc0203104:	3c060613          	addi	a2,a2,960 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203108:	22200593          	li	a1,546
ffffffffc020310c:	00004517          	auipc	a0,0x4
ffffffffc0203110:	85c50513          	addi	a0,a0,-1956 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203114:	b7afd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203118:	00003617          	auipc	a2,0x3
ffffffffc020311c:	0d060613          	addi	a2,a2,208 # ffffffffc02061e8 <commands+0x688>
ffffffffc0203120:	07100593          	li	a1,113
ffffffffc0203124:	00003517          	auipc	a0,0x3
ffffffffc0203128:	08c50513          	addi	a0,a0,140 # ffffffffc02061b0 <commands+0x650>
ffffffffc020312c:	b62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0203130:	00004697          	auipc	a3,0x4
ffffffffc0203134:	bf068693          	addi	a3,a3,-1040 # ffffffffc0206d20 <default_pmm_manager+0x4b0>
ffffffffc0203138:	00003617          	auipc	a2,0x3
ffffffffc020313c:	38860613          	addi	a2,a2,904 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203140:	24a00593          	li	a1,586
ffffffffc0203144:	00004517          	auipc	a0,0x4
ffffffffc0203148:	82450513          	addi	a0,a0,-2012 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020314c:	b42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203150:	00004697          	auipc	a3,0x4
ffffffffc0203154:	b8868693          	addi	a3,a3,-1144 # ffffffffc0206cd8 <default_pmm_manager+0x468>
ffffffffc0203158:	00003617          	auipc	a2,0x3
ffffffffc020315c:	36860613          	addi	a2,a2,872 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203160:	24800593          	li	a1,584
ffffffffc0203164:	00004517          	auipc	a0,0x4
ffffffffc0203168:	80450513          	addi	a0,a0,-2044 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020316c:	b22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203170:	00004697          	auipc	a3,0x4
ffffffffc0203174:	b9868693          	addi	a3,a3,-1128 # ffffffffc0206d08 <default_pmm_manager+0x498>
ffffffffc0203178:	00003617          	auipc	a2,0x3
ffffffffc020317c:	34860613          	addi	a2,a2,840 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203180:	24700593          	li	a1,583
ffffffffc0203184:	00003517          	auipc	a0,0x3
ffffffffc0203188:	7e450513          	addi	a0,a0,2020 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020318c:	b02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203190:	00004697          	auipc	a3,0x4
ffffffffc0203194:	c6068693          	addi	a3,a3,-928 # ffffffffc0206df0 <default_pmm_manager+0x580>
ffffffffc0203198:	00003617          	auipc	a2,0x3
ffffffffc020319c:	32860613          	addi	a2,a2,808 # ffffffffc02064c0 <commands+0x960>
ffffffffc02031a0:	26500593          	li	a1,613
ffffffffc02031a4:	00003517          	auipc	a0,0x3
ffffffffc02031a8:	7c450513          	addi	a0,a0,1988 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02031ac:	ae2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02031b0:	00004697          	auipc	a3,0x4
ffffffffc02031b4:	ba068693          	addi	a3,a3,-1120 # ffffffffc0206d50 <default_pmm_manager+0x4e0>
ffffffffc02031b8:	00003617          	auipc	a2,0x3
ffffffffc02031bc:	30860613          	addi	a2,a2,776 # ffffffffc02064c0 <commands+0x960>
ffffffffc02031c0:	25200593          	li	a1,594
ffffffffc02031c4:	00003517          	auipc	a0,0x3
ffffffffc02031c8:	7a450513          	addi	a0,a0,1956 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02031cc:	ac2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc02031d0:	00004697          	auipc	a3,0x4
ffffffffc02031d4:	c7868693          	addi	a3,a3,-904 # ffffffffc0206e48 <default_pmm_manager+0x5d8>
ffffffffc02031d8:	00003617          	auipc	a2,0x3
ffffffffc02031dc:	2e860613          	addi	a2,a2,744 # ffffffffc02064c0 <commands+0x960>
ffffffffc02031e0:	26a00593          	li	a1,618
ffffffffc02031e4:	00003517          	auipc	a0,0x3
ffffffffc02031e8:	78450513          	addi	a0,a0,1924 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02031ec:	aa2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02031f0:	00004697          	auipc	a3,0x4
ffffffffc02031f4:	c1868693          	addi	a3,a3,-1000 # ffffffffc0206e08 <default_pmm_manager+0x598>
ffffffffc02031f8:	00003617          	auipc	a2,0x3
ffffffffc02031fc:	2c860613          	addi	a2,a2,712 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203200:	26900593          	li	a1,617
ffffffffc0203204:	00003517          	auipc	a0,0x3
ffffffffc0203208:	76450513          	addi	a0,a0,1892 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020320c:	a82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203210:	00004697          	auipc	a3,0x4
ffffffffc0203214:	ac868693          	addi	a3,a3,-1336 # ffffffffc0206cd8 <default_pmm_manager+0x468>
ffffffffc0203218:	00003617          	auipc	a2,0x3
ffffffffc020321c:	2a860613          	addi	a2,a2,680 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203220:	24400593          	li	a1,580
ffffffffc0203224:	00003517          	auipc	a0,0x3
ffffffffc0203228:	74450513          	addi	a0,a0,1860 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020322c:	a62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203230:	00004697          	auipc	a3,0x4
ffffffffc0203234:	94868693          	addi	a3,a3,-1720 # ffffffffc0206b78 <default_pmm_manager+0x308>
ffffffffc0203238:	00003617          	auipc	a2,0x3
ffffffffc020323c:	28860613          	addi	a2,a2,648 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203240:	24300593          	li	a1,579
ffffffffc0203244:	00003517          	auipc	a0,0x3
ffffffffc0203248:	72450513          	addi	a0,a0,1828 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020324c:	a42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203250:	00004697          	auipc	a3,0x4
ffffffffc0203254:	aa068693          	addi	a3,a3,-1376 # ffffffffc0206cf0 <default_pmm_manager+0x480>
ffffffffc0203258:	00003617          	auipc	a2,0x3
ffffffffc020325c:	26860613          	addi	a2,a2,616 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203260:	24000593          	li	a1,576
ffffffffc0203264:	00003517          	auipc	a0,0x3
ffffffffc0203268:	70450513          	addi	a0,a0,1796 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020326c:	a22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203270:	00004697          	auipc	a3,0x4
ffffffffc0203274:	8f068693          	addi	a3,a3,-1808 # ffffffffc0206b60 <default_pmm_manager+0x2f0>
ffffffffc0203278:	00003617          	auipc	a2,0x3
ffffffffc020327c:	24860613          	addi	a2,a2,584 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203280:	23f00593          	li	a1,575
ffffffffc0203284:	00003517          	auipc	a0,0x3
ffffffffc0203288:	6e450513          	addi	a0,a0,1764 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020328c:	a02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203290:	00004697          	auipc	a3,0x4
ffffffffc0203294:	97068693          	addi	a3,a3,-1680 # ffffffffc0206c00 <default_pmm_manager+0x390>
ffffffffc0203298:	00003617          	auipc	a2,0x3
ffffffffc020329c:	22860613          	addi	a2,a2,552 # ffffffffc02064c0 <commands+0x960>
ffffffffc02032a0:	23e00593          	li	a1,574
ffffffffc02032a4:	00003517          	auipc	a0,0x3
ffffffffc02032a8:	6c450513          	addi	a0,a0,1732 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02032ac:	9e2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02032b0:	00004697          	auipc	a3,0x4
ffffffffc02032b4:	a2868693          	addi	a3,a3,-1496 # ffffffffc0206cd8 <default_pmm_manager+0x468>
ffffffffc02032b8:	00003617          	auipc	a2,0x3
ffffffffc02032bc:	20860613          	addi	a2,a2,520 # ffffffffc02064c0 <commands+0x960>
ffffffffc02032c0:	23d00593          	li	a1,573
ffffffffc02032c4:	00003517          	auipc	a0,0x3
ffffffffc02032c8:	6a450513          	addi	a0,a0,1700 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02032cc:	9c2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02032d0:	00004697          	auipc	a3,0x4
ffffffffc02032d4:	9f068693          	addi	a3,a3,-1552 # ffffffffc0206cc0 <default_pmm_manager+0x450>
ffffffffc02032d8:	00003617          	auipc	a2,0x3
ffffffffc02032dc:	1e860613          	addi	a2,a2,488 # ffffffffc02064c0 <commands+0x960>
ffffffffc02032e0:	23c00593          	li	a1,572
ffffffffc02032e4:	00003517          	auipc	a0,0x3
ffffffffc02032e8:	68450513          	addi	a0,a0,1668 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02032ec:	9a2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02032f0:	00004697          	auipc	a3,0x4
ffffffffc02032f4:	9a068693          	addi	a3,a3,-1632 # ffffffffc0206c90 <default_pmm_manager+0x420>
ffffffffc02032f8:	00003617          	auipc	a2,0x3
ffffffffc02032fc:	1c860613          	addi	a2,a2,456 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203300:	23b00593          	li	a1,571
ffffffffc0203304:	00003517          	auipc	a0,0x3
ffffffffc0203308:	66450513          	addi	a0,a0,1636 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020330c:	982fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203310:	00004697          	auipc	a3,0x4
ffffffffc0203314:	96868693          	addi	a3,a3,-1688 # ffffffffc0206c78 <default_pmm_manager+0x408>
ffffffffc0203318:	00003617          	auipc	a2,0x3
ffffffffc020331c:	1a860613          	addi	a2,a2,424 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203320:	23900593          	li	a1,569
ffffffffc0203324:	00003517          	auipc	a0,0x3
ffffffffc0203328:	64450513          	addi	a0,a0,1604 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020332c:	962fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203330:	00004697          	auipc	a3,0x4
ffffffffc0203334:	92868693          	addi	a3,a3,-1752 # ffffffffc0206c58 <default_pmm_manager+0x3e8>
ffffffffc0203338:	00003617          	auipc	a2,0x3
ffffffffc020333c:	18860613          	addi	a2,a2,392 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203340:	23800593          	li	a1,568
ffffffffc0203344:	00003517          	auipc	a0,0x3
ffffffffc0203348:	62450513          	addi	a0,a0,1572 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020334c:	942fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203350:	00004697          	auipc	a3,0x4
ffffffffc0203354:	8f868693          	addi	a3,a3,-1800 # ffffffffc0206c48 <default_pmm_manager+0x3d8>
ffffffffc0203358:	00003617          	auipc	a2,0x3
ffffffffc020335c:	16860613          	addi	a2,a2,360 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203360:	23700593          	li	a1,567
ffffffffc0203364:	00003517          	auipc	a0,0x3
ffffffffc0203368:	60450513          	addi	a0,a0,1540 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020336c:	922fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203370:	00004697          	auipc	a3,0x4
ffffffffc0203374:	8c868693          	addi	a3,a3,-1848 # ffffffffc0206c38 <default_pmm_manager+0x3c8>
ffffffffc0203378:	00003617          	auipc	a2,0x3
ffffffffc020337c:	14860613          	addi	a2,a2,328 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203380:	23600593          	li	a1,566
ffffffffc0203384:	00003517          	auipc	a0,0x3
ffffffffc0203388:	5e450513          	addi	a0,a0,1508 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020338c:	902fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203390:	00003617          	auipc	a2,0x3
ffffffffc0203394:	64860613          	addi	a2,a2,1608 # ffffffffc02069d8 <default_pmm_manager+0x168>
ffffffffc0203398:	06500593          	li	a1,101
ffffffffc020339c:	00003517          	auipc	a0,0x3
ffffffffc02033a0:	5cc50513          	addi	a0,a0,1484 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02033a4:	8eafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02033a8:	00004697          	auipc	a3,0x4
ffffffffc02033ac:	9a868693          	addi	a3,a3,-1624 # ffffffffc0206d50 <default_pmm_manager+0x4e0>
ffffffffc02033b0:	00003617          	auipc	a2,0x3
ffffffffc02033b4:	11060613          	addi	a2,a2,272 # ffffffffc02064c0 <commands+0x960>
ffffffffc02033b8:	27c00593          	li	a1,636
ffffffffc02033bc:	00003517          	auipc	a0,0x3
ffffffffc02033c0:	5ac50513          	addi	a0,a0,1452 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02033c4:	8cafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02033c8:	00004697          	auipc	a3,0x4
ffffffffc02033cc:	83868693          	addi	a3,a3,-1992 # ffffffffc0206c00 <default_pmm_manager+0x390>
ffffffffc02033d0:	00003617          	auipc	a2,0x3
ffffffffc02033d4:	0f060613          	addi	a2,a2,240 # ffffffffc02064c0 <commands+0x960>
ffffffffc02033d8:	23500593          	li	a1,565
ffffffffc02033dc:	00003517          	auipc	a0,0x3
ffffffffc02033e0:	58c50513          	addi	a0,a0,1420 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02033e4:	8aafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02033e8:	00003697          	auipc	a3,0x3
ffffffffc02033ec:	7d868693          	addi	a3,a3,2008 # ffffffffc0206bc0 <default_pmm_manager+0x350>
ffffffffc02033f0:	00003617          	auipc	a2,0x3
ffffffffc02033f4:	0d060613          	addi	a2,a2,208 # ffffffffc02064c0 <commands+0x960>
ffffffffc02033f8:	23400593          	li	a1,564
ffffffffc02033fc:	00003517          	auipc	a0,0x3
ffffffffc0203400:	56c50513          	addi	a0,a0,1388 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203404:	88afd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203408:	86d6                	mv	a3,s5
ffffffffc020340a:	00003617          	auipc	a2,0x3
ffffffffc020340e:	dde60613          	addi	a2,a2,-546 # ffffffffc02061e8 <commands+0x688>
ffffffffc0203412:	23000593          	li	a1,560
ffffffffc0203416:	00003517          	auipc	a0,0x3
ffffffffc020341a:	55250513          	addi	a0,a0,1362 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020341e:	870fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203422:	00003617          	auipc	a2,0x3
ffffffffc0203426:	dc660613          	addi	a2,a2,-570 # ffffffffc02061e8 <commands+0x688>
ffffffffc020342a:	22f00593          	li	a1,559
ffffffffc020342e:	00003517          	auipc	a0,0x3
ffffffffc0203432:	53a50513          	addi	a0,a0,1338 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203436:	858fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020343a:	00003697          	auipc	a3,0x3
ffffffffc020343e:	73e68693          	addi	a3,a3,1854 # ffffffffc0206b78 <default_pmm_manager+0x308>
ffffffffc0203442:	00003617          	auipc	a2,0x3
ffffffffc0203446:	07e60613          	addi	a2,a2,126 # ffffffffc02064c0 <commands+0x960>
ffffffffc020344a:	22d00593          	li	a1,557
ffffffffc020344e:	00003517          	auipc	a0,0x3
ffffffffc0203452:	51a50513          	addi	a0,a0,1306 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203456:	838fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020345a:	00003697          	auipc	a3,0x3
ffffffffc020345e:	70668693          	addi	a3,a3,1798 # ffffffffc0206b60 <default_pmm_manager+0x2f0>
ffffffffc0203462:	00003617          	auipc	a2,0x3
ffffffffc0203466:	05e60613          	addi	a2,a2,94 # ffffffffc02064c0 <commands+0x960>
ffffffffc020346a:	22c00593          	li	a1,556
ffffffffc020346e:	00003517          	auipc	a0,0x3
ffffffffc0203472:	4fa50513          	addi	a0,a0,1274 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203476:	818fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020347a:	00004697          	auipc	a3,0x4
ffffffffc020347e:	a9668693          	addi	a3,a3,-1386 # ffffffffc0206f10 <default_pmm_manager+0x6a0>
ffffffffc0203482:	00003617          	auipc	a2,0x3
ffffffffc0203486:	03e60613          	addi	a2,a2,62 # ffffffffc02064c0 <commands+0x960>
ffffffffc020348a:	27300593          	li	a1,627
ffffffffc020348e:	00003517          	auipc	a0,0x3
ffffffffc0203492:	4da50513          	addi	a0,a0,1242 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203496:	ff9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020349a:	00004697          	auipc	a3,0x4
ffffffffc020349e:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0206ed8 <default_pmm_manager+0x668>
ffffffffc02034a2:	00003617          	auipc	a2,0x3
ffffffffc02034a6:	01e60613          	addi	a2,a2,30 # ffffffffc02064c0 <commands+0x960>
ffffffffc02034aa:	27000593          	li	a1,624
ffffffffc02034ae:	00003517          	auipc	a0,0x3
ffffffffc02034b2:	4ba50513          	addi	a0,a0,1210 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02034b6:	fd9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02034ba:	00004697          	auipc	a3,0x4
ffffffffc02034be:	9ee68693          	addi	a3,a3,-1554 # ffffffffc0206ea8 <default_pmm_manager+0x638>
ffffffffc02034c2:	00003617          	auipc	a2,0x3
ffffffffc02034c6:	ffe60613          	addi	a2,a2,-2 # ffffffffc02064c0 <commands+0x960>
ffffffffc02034ca:	26c00593          	li	a1,620
ffffffffc02034ce:	00003517          	auipc	a0,0x3
ffffffffc02034d2:	49a50513          	addi	a0,a0,1178 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02034d6:	fb9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02034da:	00004697          	auipc	a3,0x4
ffffffffc02034de:	98668693          	addi	a3,a3,-1658 # ffffffffc0206e60 <default_pmm_manager+0x5f0>
ffffffffc02034e2:	00003617          	auipc	a2,0x3
ffffffffc02034e6:	fde60613          	addi	a2,a2,-34 # ffffffffc02064c0 <commands+0x960>
ffffffffc02034ea:	26b00593          	li	a1,619
ffffffffc02034ee:	00003517          	auipc	a0,0x3
ffffffffc02034f2:	47a50513          	addi	a0,a0,1146 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02034f6:	f99fc0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02034fa:	00003617          	auipc	a2,0x3
ffffffffc02034fe:	41e60613          	addi	a2,a2,1054 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc0203502:	0c900593          	li	a1,201
ffffffffc0203506:	00003517          	auipc	a0,0x3
ffffffffc020350a:	46250513          	addi	a0,a0,1122 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020350e:	f81fc0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203512:	00003617          	auipc	a2,0x3
ffffffffc0203516:	40660613          	addi	a2,a2,1030 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc020351a:	08100593          	li	a1,129
ffffffffc020351e:	00003517          	auipc	a0,0x3
ffffffffc0203522:	44a50513          	addi	a0,a0,1098 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203526:	f69fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020352a:	00003697          	auipc	a3,0x3
ffffffffc020352e:	60668693          	addi	a3,a3,1542 # ffffffffc0206b30 <default_pmm_manager+0x2c0>
ffffffffc0203532:	00003617          	auipc	a2,0x3
ffffffffc0203536:	f8e60613          	addi	a2,a2,-114 # ffffffffc02064c0 <commands+0x960>
ffffffffc020353a:	22b00593          	li	a1,555
ffffffffc020353e:	00003517          	auipc	a0,0x3
ffffffffc0203542:	42a50513          	addi	a0,a0,1066 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203546:	f49fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020354a:	00003697          	auipc	a3,0x3
ffffffffc020354e:	5b668693          	addi	a3,a3,1462 # ffffffffc0206b00 <default_pmm_manager+0x290>
ffffffffc0203552:	00003617          	auipc	a2,0x3
ffffffffc0203556:	f6e60613          	addi	a2,a2,-146 # ffffffffc02064c0 <commands+0x960>
ffffffffc020355a:	22800593          	li	a1,552
ffffffffc020355e:	00003517          	auipc	a0,0x3
ffffffffc0203562:	40a50513          	addi	a0,a0,1034 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203566:	f29fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020356a <copy_range>:
{
ffffffffc020356a:	7119                	addi	sp,sp,-128
ffffffffc020356c:	f8a2                	sd	s0,112(sp)
ffffffffc020356e:	8436                	mv	s0,a3
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203570:	8ed1                	or	a3,a3,a2
{
ffffffffc0203572:	fc86                	sd	ra,120(sp)
ffffffffc0203574:	f4a6                	sd	s1,104(sp)
ffffffffc0203576:	f0ca                	sd	s2,96(sp)
ffffffffc0203578:	ecce                	sd	s3,88(sp)
ffffffffc020357a:	e8d2                	sd	s4,80(sp)
ffffffffc020357c:	e4d6                	sd	s5,72(sp)
ffffffffc020357e:	e0da                	sd	s6,64(sp)
ffffffffc0203580:	fc5e                	sd	s7,56(sp)
ffffffffc0203582:	f862                	sd	s8,48(sp)
ffffffffc0203584:	f466                	sd	s9,40(sp)
ffffffffc0203586:	f06a                	sd	s10,32(sp)
ffffffffc0203588:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020358a:	16d2                	slli	a3,a3,0x34
ffffffffc020358c:	28069163          	bnez	a3,ffffffffc020380e <copy_range+0x2a4>
ffffffffc0203590:	8b3a                	mv	s6,a4
    assert(USER_ACCESS(start, end));
ffffffffc0203592:	00200737          	lui	a4,0x200
ffffffffc0203596:	8db2                	mv	s11,a2
ffffffffc0203598:	24e66b63          	bltu	a2,a4,ffffffffc02037ee <copy_range+0x284>
ffffffffc020359c:	24867963          	bgeu	a2,s0,ffffffffc02037ee <copy_range+0x284>
ffffffffc02035a0:	4705                	li	a4,1
ffffffffc02035a2:	077e                	slli	a4,a4,0x1f
ffffffffc02035a4:	24876563          	bltu	a4,s0,ffffffffc02037ee <copy_range+0x284>
ffffffffc02035a8:	5bfd                	li	s7,-1
ffffffffc02035aa:	89aa                	mv	s3,a0
ffffffffc02035ac:	84ae                	mv	s1,a1
        start += PGSIZE;
ffffffffc02035ae:	6905                	lui	s2,0x1
    if (PPN(pa) >= npage)
ffffffffc02035b0:	000b1a97          	auipc	s5,0xb1
ffffffffc02035b4:	628a8a93          	addi	s5,s5,1576 # ffffffffc02b4bd8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02035b8:	000b1a17          	auipc	s4,0xb1
ffffffffc02035bc:	628a0a13          	addi	s4,s4,1576 # ffffffffc02b4be0 <pages>
    return KADDR(page2pa(page));
ffffffffc02035c0:	00cbdb93          	srli	s7,s7,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02035c4:	000b1d17          	auipc	s10,0xb1
ffffffffc02035c8:	624d0d13          	addi	s10,s10,1572 # ffffffffc02b4be8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02035cc:	4601                	li	a2,0
ffffffffc02035ce:	85ee                	mv	a1,s11
ffffffffc02035d0:	8526                	mv	a0,s1
ffffffffc02035d2:	b73fe0ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc02035d6:	8caa                	mv	s9,a0
        if (ptep == NULL)
ffffffffc02035d8:	c549                	beqz	a0,ffffffffc0203662 <copy_range+0xf8>
        if (*ptep & PTE_V)
ffffffffc02035da:	6118                	ld	a4,0(a0)
ffffffffc02035dc:	8b05                	andi	a4,a4,1
ffffffffc02035de:	e705                	bnez	a4,ffffffffc0203606 <copy_range+0x9c>
        start += PGSIZE;
ffffffffc02035e0:	9dca                	add	s11,s11,s2
    } while (start != 0 && start < end);
ffffffffc02035e2:	fe8de5e3          	bltu	s11,s0,ffffffffc02035cc <copy_range+0x62>
    return 0;
ffffffffc02035e6:	4501                	li	a0,0
}
ffffffffc02035e8:	70e6                	ld	ra,120(sp)
ffffffffc02035ea:	7446                	ld	s0,112(sp)
ffffffffc02035ec:	74a6                	ld	s1,104(sp)
ffffffffc02035ee:	7906                	ld	s2,96(sp)
ffffffffc02035f0:	69e6                	ld	s3,88(sp)
ffffffffc02035f2:	6a46                	ld	s4,80(sp)
ffffffffc02035f4:	6aa6                	ld	s5,72(sp)
ffffffffc02035f6:	6b06                	ld	s6,64(sp)
ffffffffc02035f8:	7be2                	ld	s7,56(sp)
ffffffffc02035fa:	7c42                	ld	s8,48(sp)
ffffffffc02035fc:	7ca2                	ld	s9,40(sp)
ffffffffc02035fe:	7d02                	ld	s10,32(sp)
ffffffffc0203600:	6de2                	ld	s11,24(sp)
ffffffffc0203602:	6109                	addi	sp,sp,128
ffffffffc0203604:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203606:	4605                	li	a2,1
ffffffffc0203608:	85ee                	mv	a1,s11
ffffffffc020360a:	854e                	mv	a0,s3
ffffffffc020360c:	b39fe0ef          	jal	ra,ffffffffc0202144 <get_pte>
ffffffffc0203610:	14050863          	beqz	a0,ffffffffc0203760 <copy_range+0x1f6>
                struct Page *page = pte2page(*ptep);
ffffffffc0203614:	000cb703          	ld	a4,0(s9)
    if (!(pte & PTE_V))
ffffffffc0203618:	00177693          	andi	a3,a4,1
            if (share)
ffffffffc020361c:	060b0063          	beqz	s6,ffffffffc020367c <copy_range+0x112>
ffffffffc0203620:	1a068b63          	beqz	a3,ffffffffc02037d6 <copy_range+0x26c>
    if (PPN(pa) >= npage)
ffffffffc0203624:	000ab603          	ld	a2,0(s5)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203628:	00271693          	slli	a3,a4,0x2
ffffffffc020362c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020362e:	18c6f863          	bgeu	a3,a2,ffffffffc02037be <copy_range+0x254>
    return &pages[PPN(pa) - nbase];
ffffffffc0203632:	000a3583          	ld	a1,0(s4)
ffffffffc0203636:	fff807b7          	lui	a5,0xfff80
ffffffffc020363a:	96be                	add	a3,a3,a5
ffffffffc020363c:	069a                	slli	a3,a3,0x6
                if (perm & PTE_W)
ffffffffc020363e:	00477613          	andi	a2,a4,4
ffffffffc0203642:	95b6                	add	a1,a1,a3
                uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203644:	0007069b          	sext.w	a3,a4
                if (perm & PTE_W)
ffffffffc0203648:	e675                	bnez	a2,ffffffffc0203734 <copy_range+0x1ca>
                uint32_t perm = (*ptep & PTE_USER);
ffffffffc020364a:	8afd                	andi	a3,a3,31
                int ret = page_insert(to, page, start, perm);
ffffffffc020364c:	866e                	mv	a2,s11
ffffffffc020364e:	854e                	mv	a0,s3
ffffffffc0203650:	9e4ff0ef          	jal	ra,ffffffffc0202834 <page_insert>
                if (ret != 0)
ffffffffc0203654:	f951                	bnez	a0,ffffffffc02035e8 <copy_range+0x7e>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203656:	120d8073          	sfence.vma	s11
ffffffffc020365a:	120d8073          	sfence.vma	s11
        start += PGSIZE;
ffffffffc020365e:	9dca                	add	s11,s11,s2
    } while (start != 0 && start < end);
ffffffffc0203660:	b749                	j	ffffffffc02035e2 <copy_range+0x78>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203662:	00200637          	lui	a2,0x200
ffffffffc0203666:	00cd87b3          	add	a5,s11,a2
ffffffffc020366a:	ffe00637          	lui	a2,0xffe00
ffffffffc020366e:	00c7fdb3          	and	s11,a5,a2
    } while (start != 0 && start < end);
ffffffffc0203672:	f60d8ae3          	beqz	s11,ffffffffc02035e6 <copy_range+0x7c>
ffffffffc0203676:	f48debe3          	bltu	s11,s0,ffffffffc02035cc <copy_range+0x62>
ffffffffc020367a:	b7b5                	j	ffffffffc02035e6 <copy_range+0x7c>
                uint32_t perm = (*ptep & PTE_USER);
ffffffffc020367c:	01f77c93          	andi	s9,a4,31
    if (!(pte & PTE_V))
ffffffffc0203680:	14068b63          	beqz	a3,ffffffffc02037d6 <copy_range+0x26c>
    if (PPN(pa) >= npage)
ffffffffc0203684:	000ab683          	ld	a3,0(s5)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203688:	070a                	slli	a4,a4,0x2
ffffffffc020368a:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020368c:	12d77963          	bgeu	a4,a3,ffffffffc02037be <copy_range+0x254>
    return &pages[PPN(pa) - nbase];
ffffffffc0203690:	000a3683          	ld	a3,0(s4)
ffffffffc0203694:	fff807b7          	lui	a5,0xfff80
ffffffffc0203698:	973e                	add	a4,a4,a5
ffffffffc020369a:	071a                	slli	a4,a4,0x6
ffffffffc020369c:	9736                	add	a4,a4,a3
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020369e:	100026f3          	csrr	a3,sstatus
ffffffffc02036a2:	8a89                	andi	a3,a3,2
ffffffffc02036a4:	e43a                	sd	a4,8(sp)
ffffffffc02036a6:	e2cd                	bnez	a3,ffffffffc0203748 <copy_range+0x1de>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036a8:	000d3683          	ld	a3,0(s10)
ffffffffc02036ac:	4505                	li	a0,1
ffffffffc02036ae:	6e94                	ld	a3,24(a3)
ffffffffc02036b0:	9682                	jalr	a3
ffffffffc02036b2:	6722                	ld	a4,8(sp)
ffffffffc02036b4:	8c2a                	mv	s8,a0
                assert(page != NULL);
ffffffffc02036b6:	0e070463          	beqz	a4,ffffffffc020379e <copy_range+0x234>
                assert(npage != NULL);
ffffffffc02036ba:	0c0c0263          	beqz	s8,ffffffffc020377e <copy_range+0x214>
    return page - pages + nbase;
ffffffffc02036be:	000a3603          	ld	a2,0(s4)
ffffffffc02036c2:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc02036c6:	000ab883          	ld	a7,0(s5)
    return page - pages + nbase;
ffffffffc02036ca:	8f11                	sub	a4,a4,a2
ffffffffc02036cc:	40675693          	srai	a3,a4,0x6
ffffffffc02036d0:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02036d2:	0176f733          	and	a4,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc02036d6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02036d8:	09177763          	bgeu	a4,a7,ffffffffc0203766 <copy_range+0x1fc>
    return page - pages + nbase;
ffffffffc02036dc:	40cc0733          	sub	a4,s8,a2
    return KADDR(page2pa(page));
ffffffffc02036e0:	000b1797          	auipc	a5,0xb1
ffffffffc02036e4:	51078793          	addi	a5,a5,1296 # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc02036e8:	6388                	ld	a0,0(a5)
    return page - pages + nbase;
ffffffffc02036ea:	8719                	srai	a4,a4,0x6
ffffffffc02036ec:	972e                	add	a4,a4,a1
    return KADDR(page2pa(page));
ffffffffc02036ee:	01777633          	and	a2,a4,s7
ffffffffc02036f2:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02036f6:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc02036f8:	07167663          	bgeu	a2,a7,ffffffffc0203764 <copy_range+0x1fa>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02036fc:	6605                	lui	a2,0x1
ffffffffc02036fe:	953a                	add	a0,a0,a4
ffffffffc0203700:	1e0020ef          	jal	ra,ffffffffc02058e0 <memcpy>
                int ret = page_insert(to, npage, start, perm);
ffffffffc0203704:	86e6                	mv	a3,s9
ffffffffc0203706:	866e                	mv	a2,s11
ffffffffc0203708:	85e2                	mv	a1,s8
ffffffffc020370a:	854e                	mv	a0,s3
ffffffffc020370c:	928ff0ef          	jal	ra,ffffffffc0202834 <page_insert>
                assert(ret == 0);
ffffffffc0203710:	ec0508e3          	beqz	a0,ffffffffc02035e0 <copy_range+0x76>
ffffffffc0203714:	00004697          	auipc	a3,0x4
ffffffffc0203718:	86468693          	addi	a3,a3,-1948 # ffffffffc0206f78 <default_pmm_manager+0x708>
ffffffffc020371c:	00003617          	auipc	a2,0x3
ffffffffc0203720:	da460613          	addi	a2,a2,-604 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203724:	1bf00593          	li	a1,447
ffffffffc0203728:	00003517          	auipc	a0,0x3
ffffffffc020372c:	24050513          	addi	a0,a0,576 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc0203730:	d5ffc0ef          	jal	ra,ffffffffc020048e <__panic>
                    *ptep = (*ptep & (~PTE_W)) | PTE_COW;
ffffffffc0203734:	efb77713          	andi	a4,a4,-261
                    perm &= ~PTE_W;
ffffffffc0203738:	8aed                	andi	a3,a3,27
                    *ptep = (*ptep & (~PTE_W)) | PTE_COW;
ffffffffc020373a:	10076713          	ori	a4,a4,256
                    perm |= PTE_COW;
ffffffffc020373e:	1006e693          	ori	a3,a3,256
                    *ptep = (*ptep & (~PTE_W)) | PTE_COW;
ffffffffc0203742:	00ecb023          	sd	a4,0(s9)
ffffffffc0203746:	b719                	j	ffffffffc020364c <copy_range+0xe2>
        intr_disable();
ffffffffc0203748:	a6cfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020374c:	000d3683          	ld	a3,0(s10)
ffffffffc0203750:	4505                	li	a0,1
ffffffffc0203752:	6e94                	ld	a3,24(a3)
ffffffffc0203754:	9682                	jalr	a3
ffffffffc0203756:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0203758:	a56fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020375c:	6722                	ld	a4,8(sp)
ffffffffc020375e:	bfa1                	j	ffffffffc02036b6 <copy_range+0x14c>
                return -E_NO_MEM;
ffffffffc0203760:	5571                	li	a0,-4
ffffffffc0203762:	b559                	j	ffffffffc02035e8 <copy_range+0x7e>
ffffffffc0203764:	86ba                	mv	a3,a4
ffffffffc0203766:	00003617          	auipc	a2,0x3
ffffffffc020376a:	a8260613          	addi	a2,a2,-1406 # ffffffffc02061e8 <commands+0x688>
ffffffffc020376e:	07100593          	li	a1,113
ffffffffc0203772:	00003517          	auipc	a0,0x3
ffffffffc0203776:	a3e50513          	addi	a0,a0,-1474 # ffffffffc02061b0 <commands+0x650>
ffffffffc020377a:	d15fc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(npage != NULL);
ffffffffc020377e:	00003697          	auipc	a3,0x3
ffffffffc0203782:	7ea68693          	addi	a3,a3,2026 # ffffffffc0206f68 <default_pmm_manager+0x6f8>
ffffffffc0203786:	00003617          	auipc	a2,0x3
ffffffffc020378a:	d3a60613          	addi	a2,a2,-710 # ffffffffc02064c0 <commands+0x960>
ffffffffc020378e:	1ba00593          	li	a1,442
ffffffffc0203792:	00003517          	auipc	a0,0x3
ffffffffc0203796:	1d650513          	addi	a0,a0,470 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020379a:	cf5fc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(page != NULL);
ffffffffc020379e:	00003697          	auipc	a3,0x3
ffffffffc02037a2:	7ba68693          	addi	a3,a3,1978 # ffffffffc0206f58 <default_pmm_manager+0x6e8>
ffffffffc02037a6:	00003617          	auipc	a2,0x3
ffffffffc02037aa:	d1a60613          	addi	a2,a2,-742 # ffffffffc02064c0 <commands+0x960>
ffffffffc02037ae:	1b900593          	li	a1,441
ffffffffc02037b2:	00003517          	auipc	a0,0x3
ffffffffc02037b6:	1b650513          	addi	a0,a0,438 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02037ba:	cd5fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02037be:	00003617          	auipc	a2,0x3
ffffffffc02037c2:	9d260613          	addi	a2,a2,-1582 # ffffffffc0206190 <commands+0x630>
ffffffffc02037c6:	06900593          	li	a1,105
ffffffffc02037ca:	00003517          	auipc	a0,0x3
ffffffffc02037ce:	9e650513          	addi	a0,a0,-1562 # ffffffffc02061b0 <commands+0x650>
ffffffffc02037d2:	cbdfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02037d6:	00003617          	auipc	a2,0x3
ffffffffc02037da:	16a60613          	addi	a2,a2,362 # ffffffffc0206940 <default_pmm_manager+0xd0>
ffffffffc02037de:	07f00593          	li	a1,127
ffffffffc02037e2:	00003517          	auipc	a0,0x3
ffffffffc02037e6:	9ce50513          	addi	a0,a0,-1586 # ffffffffc02061b0 <commands+0x650>
ffffffffc02037ea:	ca5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02037ee:	00003697          	auipc	a3,0x3
ffffffffc02037f2:	1ba68693          	addi	a3,a3,442 # ffffffffc02069a8 <default_pmm_manager+0x138>
ffffffffc02037f6:	00003617          	auipc	a2,0x3
ffffffffc02037fa:	cca60613          	addi	a2,a2,-822 # ffffffffc02064c0 <commands+0x960>
ffffffffc02037fe:	17b00593          	li	a1,379
ffffffffc0203802:	00003517          	auipc	a0,0x3
ffffffffc0203806:	16650513          	addi	a0,a0,358 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020380a:	c85fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020380e:	00003697          	auipc	a3,0x3
ffffffffc0203812:	16a68693          	addi	a3,a3,362 # ffffffffc0206978 <default_pmm_manager+0x108>
ffffffffc0203816:	00003617          	auipc	a2,0x3
ffffffffc020381a:	caa60613          	addi	a2,a2,-854 # ffffffffc02064c0 <commands+0x960>
ffffffffc020381e:	17a00593          	li	a1,378
ffffffffc0203822:	00003517          	auipc	a0,0x3
ffffffffc0203826:	14650513          	addi	a0,a0,326 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc020382a:	c65fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020382e <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020382e:	12058073          	sfence.vma	a1
}
ffffffffc0203832:	8082                	ret

ffffffffc0203834 <pgdir_alloc_page>:
{
ffffffffc0203834:	7179                	addi	sp,sp,-48
ffffffffc0203836:	ec26                	sd	s1,24(sp)
ffffffffc0203838:	e84a                	sd	s2,16(sp)
ffffffffc020383a:	e052                	sd	s4,0(sp)
ffffffffc020383c:	f406                	sd	ra,40(sp)
ffffffffc020383e:	f022                	sd	s0,32(sp)
ffffffffc0203840:	e44e                	sd	s3,8(sp)
ffffffffc0203842:	8a2a                	mv	s4,a0
ffffffffc0203844:	84ae                	mv	s1,a1
ffffffffc0203846:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203848:	100027f3          	csrr	a5,sstatus
ffffffffc020384c:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc020384e:	000b1997          	auipc	s3,0xb1
ffffffffc0203852:	39a98993          	addi	s3,s3,922 # ffffffffc02b4be8 <pmm_manager>
ffffffffc0203856:	ef8d                	bnez	a5,ffffffffc0203890 <pgdir_alloc_page+0x5c>
ffffffffc0203858:	0009b783          	ld	a5,0(s3)
ffffffffc020385c:	4505                	li	a0,1
ffffffffc020385e:	6f9c                	ld	a5,24(a5)
ffffffffc0203860:	9782                	jalr	a5
ffffffffc0203862:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203864:	cc09                	beqz	s0,ffffffffc020387e <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203866:	86ca                	mv	a3,s2
ffffffffc0203868:	8626                	mv	a2,s1
ffffffffc020386a:	85a2                	mv	a1,s0
ffffffffc020386c:	8552                	mv	a0,s4
ffffffffc020386e:	fc7fe0ef          	jal	ra,ffffffffc0202834 <page_insert>
ffffffffc0203872:	e915                	bnez	a0,ffffffffc02038a6 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203874:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203876:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203878:	4785                	li	a5,1
ffffffffc020387a:	04f71e63          	bne	a4,a5,ffffffffc02038d6 <pgdir_alloc_page+0xa2>
}
ffffffffc020387e:	70a2                	ld	ra,40(sp)
ffffffffc0203880:	8522                	mv	a0,s0
ffffffffc0203882:	7402                	ld	s0,32(sp)
ffffffffc0203884:	64e2                	ld	s1,24(sp)
ffffffffc0203886:	6942                	ld	s2,16(sp)
ffffffffc0203888:	69a2                	ld	s3,8(sp)
ffffffffc020388a:	6a02                	ld	s4,0(sp)
ffffffffc020388c:	6145                	addi	sp,sp,48
ffffffffc020388e:	8082                	ret
        intr_disable();
ffffffffc0203890:	924fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203894:	0009b783          	ld	a5,0(s3)
ffffffffc0203898:	4505                	li	a0,1
ffffffffc020389a:	6f9c                	ld	a5,24(a5)
ffffffffc020389c:	9782                	jalr	a5
ffffffffc020389e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02038a0:	90efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02038a4:	b7c1                	j	ffffffffc0203864 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02038a6:	100027f3          	csrr	a5,sstatus
ffffffffc02038aa:	8b89                	andi	a5,a5,2
ffffffffc02038ac:	eb89                	bnez	a5,ffffffffc02038be <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc02038ae:	0009b783          	ld	a5,0(s3)
ffffffffc02038b2:	8522                	mv	a0,s0
ffffffffc02038b4:	4585                	li	a1,1
ffffffffc02038b6:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02038b8:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02038ba:	9782                	jalr	a5
    if (flag)
ffffffffc02038bc:	b7c9                	j	ffffffffc020387e <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc02038be:	8f6fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02038c2:	0009b783          	ld	a5,0(s3)
ffffffffc02038c6:	8522                	mv	a0,s0
ffffffffc02038c8:	4585                	li	a1,1
ffffffffc02038ca:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02038cc:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02038ce:	9782                	jalr	a5
        intr_enable();
ffffffffc02038d0:	8defd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02038d4:	b76d                	j	ffffffffc020387e <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc02038d6:	00003697          	auipc	a3,0x3
ffffffffc02038da:	6b268693          	addi	a3,a3,1714 # ffffffffc0206f88 <default_pmm_manager+0x718>
ffffffffc02038de:	00003617          	auipc	a2,0x3
ffffffffc02038e2:	be260613          	addi	a2,a2,-1054 # ffffffffc02064c0 <commands+0x960>
ffffffffc02038e6:	20900593          	li	a1,521
ffffffffc02038ea:	00003517          	auipc	a0,0x3
ffffffffc02038ee:	07e50513          	addi	a0,a0,126 # ffffffffc0206968 <default_pmm_manager+0xf8>
ffffffffc02038f2:	b9dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038f6 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02038f6:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02038f8:	00003697          	auipc	a3,0x3
ffffffffc02038fc:	6a868693          	addi	a3,a3,1704 # ffffffffc0206fa0 <default_pmm_manager+0x730>
ffffffffc0203900:	00003617          	auipc	a2,0x3
ffffffffc0203904:	bc060613          	addi	a2,a2,-1088 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203908:	07400593          	li	a1,116
ffffffffc020390c:	00003517          	auipc	a0,0x3
ffffffffc0203910:	6b450513          	addi	a0,a0,1716 # ffffffffc0206fc0 <default_pmm_manager+0x750>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203914:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203916:	b79fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020391a <mm_create>:
{
ffffffffc020391a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020391c:	04000513          	li	a0,64
{
ffffffffc0203920:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203922:	d8cfe0ef          	jal	ra,ffffffffc0201eae <kmalloc>
    if (mm != NULL)
ffffffffc0203926:	cd19                	beqz	a0,ffffffffc0203944 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203928:	e508                	sd	a0,8(a0)
ffffffffc020392a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020392c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203930:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203934:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203938:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020393c:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203940:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203944:	60a2                	ld	ra,8(sp)
ffffffffc0203946:	0141                	addi	sp,sp,16
ffffffffc0203948:	8082                	ret

ffffffffc020394a <find_vma>:
{
ffffffffc020394a:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc020394c:	c505                	beqz	a0,ffffffffc0203974 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc020394e:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203950:	c501                	beqz	a0,ffffffffc0203958 <find_vma+0xe>
ffffffffc0203952:	651c                	ld	a5,8(a0)
ffffffffc0203954:	02f5f263          	bgeu	a1,a5,ffffffffc0203978 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203958:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc020395a:	00f68d63          	beq	a3,a5,ffffffffc0203974 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020395e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203962:	00e5e663          	bltu	a1,a4,ffffffffc020396e <find_vma+0x24>
ffffffffc0203966:	ff07b703          	ld	a4,-16(a5)
ffffffffc020396a:	00e5ec63          	bltu	a1,a4,ffffffffc0203982 <find_vma+0x38>
ffffffffc020396e:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203970:	fef697e3          	bne	a3,a5,ffffffffc020395e <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203974:	4501                	li	a0,0
}
ffffffffc0203976:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203978:	691c                	ld	a5,16(a0)
ffffffffc020397a:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203958 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020397e:	ea88                	sd	a0,16(a3)
ffffffffc0203980:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203982:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203986:	ea88                	sd	a0,16(a3)
ffffffffc0203988:	8082                	ret

ffffffffc020398a <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020398a:	6590                	ld	a2,8(a1)
ffffffffc020398c:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ee0>
{
ffffffffc0203990:	1141                	addi	sp,sp,-16
ffffffffc0203992:	e406                	sd	ra,8(sp)
ffffffffc0203994:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203996:	01066763          	bltu	a2,a6,ffffffffc02039a4 <insert_vma_struct+0x1a>
ffffffffc020399a:	a085                	j	ffffffffc02039fa <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020399c:	fe87b703          	ld	a4,-24(a5)
ffffffffc02039a0:	04e66863          	bltu	a2,a4,ffffffffc02039f0 <insert_vma_struct+0x66>
ffffffffc02039a4:	86be                	mv	a3,a5
ffffffffc02039a6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02039a8:	fef51ae3          	bne	a0,a5,ffffffffc020399c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02039ac:	02a68463          	beq	a3,a0,ffffffffc02039d4 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02039b0:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02039b4:	fe86b883          	ld	a7,-24(a3)
ffffffffc02039b8:	08e8f163          	bgeu	a7,a4,ffffffffc0203a3a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02039bc:	04e66f63          	bltu	a2,a4,ffffffffc0203a1a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc02039c0:	00f50a63          	beq	a0,a5,ffffffffc02039d4 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02039c4:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02039c8:	05076963          	bltu	a4,a6,ffffffffc0203a1a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc02039cc:	ff07b603          	ld	a2,-16(a5)
ffffffffc02039d0:	02c77363          	bgeu	a4,a2,ffffffffc02039f6 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02039d4:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02039d6:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02039d8:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02039dc:	e390                	sd	a2,0(a5)
ffffffffc02039de:	e690                	sd	a2,8(a3)
}
ffffffffc02039e0:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02039e2:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02039e4:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02039e6:	0017079b          	addiw	a5,a4,1
ffffffffc02039ea:	d11c                	sw	a5,32(a0)
}
ffffffffc02039ec:	0141                	addi	sp,sp,16
ffffffffc02039ee:	8082                	ret
    if (le_prev != list)
ffffffffc02039f0:	fca690e3          	bne	a3,a0,ffffffffc02039b0 <insert_vma_struct+0x26>
ffffffffc02039f4:	bfd1                	j	ffffffffc02039c8 <insert_vma_struct+0x3e>
ffffffffc02039f6:	f01ff0ef          	jal	ra,ffffffffc02038f6 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02039fa:	00003697          	auipc	a3,0x3
ffffffffc02039fe:	5d668693          	addi	a3,a3,1494 # ffffffffc0206fd0 <default_pmm_manager+0x760>
ffffffffc0203a02:	00003617          	auipc	a2,0x3
ffffffffc0203a06:	abe60613          	addi	a2,a2,-1346 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203a0a:	07a00593          	li	a1,122
ffffffffc0203a0e:	00003517          	auipc	a0,0x3
ffffffffc0203a12:	5b250513          	addi	a0,a0,1458 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203a16:	a79fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203a1a:	00003697          	auipc	a3,0x3
ffffffffc0203a1e:	5f668693          	addi	a3,a3,1526 # ffffffffc0207010 <default_pmm_manager+0x7a0>
ffffffffc0203a22:	00003617          	auipc	a2,0x3
ffffffffc0203a26:	a9e60613          	addi	a2,a2,-1378 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203a2a:	07300593          	li	a1,115
ffffffffc0203a2e:	00003517          	auipc	a0,0x3
ffffffffc0203a32:	59250513          	addi	a0,a0,1426 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203a36:	a59fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203a3a:	00003697          	auipc	a3,0x3
ffffffffc0203a3e:	5b668693          	addi	a3,a3,1462 # ffffffffc0206ff0 <default_pmm_manager+0x780>
ffffffffc0203a42:	00003617          	auipc	a2,0x3
ffffffffc0203a46:	a7e60613          	addi	a2,a2,-1410 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203a4a:	07200593          	li	a1,114
ffffffffc0203a4e:	00003517          	auipc	a0,0x3
ffffffffc0203a52:	57250513          	addi	a0,a0,1394 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203a56:	a39fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a5a <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203a5a:	591c                	lw	a5,48(a0)
{
ffffffffc0203a5c:	1141                	addi	sp,sp,-16
ffffffffc0203a5e:	e406                	sd	ra,8(sp)
ffffffffc0203a60:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203a62:	e78d                	bnez	a5,ffffffffc0203a8c <mm_destroy+0x32>
ffffffffc0203a64:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203a66:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203a68:	00a40c63          	beq	s0,a0,ffffffffc0203a80 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203a6c:	6118                	ld	a4,0(a0)
ffffffffc0203a6e:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203a70:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203a72:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203a74:	e398                	sd	a4,0(a5)
ffffffffc0203a76:	ce8fe0ef          	jal	ra,ffffffffc0201f5e <kfree>
    return listelm->next;
ffffffffc0203a7a:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203a7c:	fea418e3          	bne	s0,a0,ffffffffc0203a6c <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203a80:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203a82:	6402                	ld	s0,0(sp)
ffffffffc0203a84:	60a2                	ld	ra,8(sp)
ffffffffc0203a86:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203a88:	cd6fe06f          	j	ffffffffc0201f5e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203a8c:	00003697          	auipc	a3,0x3
ffffffffc0203a90:	5a468693          	addi	a3,a3,1444 # ffffffffc0207030 <default_pmm_manager+0x7c0>
ffffffffc0203a94:	00003617          	auipc	a2,0x3
ffffffffc0203a98:	a2c60613          	addi	a2,a2,-1492 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203a9c:	09e00593          	li	a1,158
ffffffffc0203aa0:	00003517          	auipc	a0,0x3
ffffffffc0203aa4:	52050513          	addi	a0,a0,1312 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203aa8:	9e7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203aac <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203aac:	7139                	addi	sp,sp,-64
ffffffffc0203aae:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203ab0:	6405                	lui	s0,0x1
ffffffffc0203ab2:	147d                	addi	s0,s0,-1
ffffffffc0203ab4:	77fd                	lui	a5,0xfffff
ffffffffc0203ab6:	9622                	add	a2,a2,s0
ffffffffc0203ab8:	962e                	add	a2,a2,a1
{
ffffffffc0203aba:	f426                	sd	s1,40(sp)
ffffffffc0203abc:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203abe:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203ac2:	f04a                	sd	s2,32(sp)
ffffffffc0203ac4:	ec4e                	sd	s3,24(sp)
ffffffffc0203ac6:	e852                	sd	s4,16(sp)
ffffffffc0203ac8:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203aca:	002005b7          	lui	a1,0x200
ffffffffc0203ace:	00f67433          	and	s0,a2,a5
ffffffffc0203ad2:	06b4e363          	bltu	s1,a1,ffffffffc0203b38 <mm_map+0x8c>
ffffffffc0203ad6:	0684f163          	bgeu	s1,s0,ffffffffc0203b38 <mm_map+0x8c>
ffffffffc0203ada:	4785                	li	a5,1
ffffffffc0203adc:	07fe                	slli	a5,a5,0x1f
ffffffffc0203ade:	0487ed63          	bltu	a5,s0,ffffffffc0203b38 <mm_map+0x8c>
ffffffffc0203ae2:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203ae4:	cd21                	beqz	a0,ffffffffc0203b3c <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203ae6:	85a6                	mv	a1,s1
ffffffffc0203ae8:	8ab6                	mv	s5,a3
ffffffffc0203aea:	8a3a                	mv	s4,a4
ffffffffc0203aec:	e5fff0ef          	jal	ra,ffffffffc020394a <find_vma>
ffffffffc0203af0:	c501                	beqz	a0,ffffffffc0203af8 <mm_map+0x4c>
ffffffffc0203af2:	651c                	ld	a5,8(a0)
ffffffffc0203af4:	0487e263          	bltu	a5,s0,ffffffffc0203b38 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203af8:	03000513          	li	a0,48
ffffffffc0203afc:	bb2fe0ef          	jal	ra,ffffffffc0201eae <kmalloc>
ffffffffc0203b00:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203b02:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203b04:	02090163          	beqz	s2,ffffffffc0203b26 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203b08:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203b0a:	00993423          	sd	s1,8(s2) # 1008 <_binary_obj___user_faultread_out_size-0x8bb0>
        vma->vm_end = vm_end;
ffffffffc0203b0e:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203b12:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203b16:	85ca                	mv	a1,s2
ffffffffc0203b18:	e73ff0ef          	jal	ra,ffffffffc020398a <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203b1c:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203b1e:	000a0463          	beqz	s4,ffffffffc0203b26 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203b22:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0203b26:	70e2                	ld	ra,56(sp)
ffffffffc0203b28:	7442                	ld	s0,48(sp)
ffffffffc0203b2a:	74a2                	ld	s1,40(sp)
ffffffffc0203b2c:	7902                	ld	s2,32(sp)
ffffffffc0203b2e:	69e2                	ld	s3,24(sp)
ffffffffc0203b30:	6a42                	ld	s4,16(sp)
ffffffffc0203b32:	6aa2                	ld	s5,8(sp)
ffffffffc0203b34:	6121                	addi	sp,sp,64
ffffffffc0203b36:	8082                	ret
        return -E_INVAL;
ffffffffc0203b38:	5575                	li	a0,-3
ffffffffc0203b3a:	b7f5                	j	ffffffffc0203b26 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203b3c:	00003697          	auipc	a3,0x3
ffffffffc0203b40:	50c68693          	addi	a3,a3,1292 # ffffffffc0207048 <default_pmm_manager+0x7d8>
ffffffffc0203b44:	00003617          	auipc	a2,0x3
ffffffffc0203b48:	97c60613          	addi	a2,a2,-1668 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203b4c:	0b300593          	li	a1,179
ffffffffc0203b50:	00003517          	auipc	a0,0x3
ffffffffc0203b54:	47050513          	addi	a0,a0,1136 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203b58:	937fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b5c <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203b5c:	7139                	addi	sp,sp,-64
ffffffffc0203b5e:	fc06                	sd	ra,56(sp)
ffffffffc0203b60:	f822                	sd	s0,48(sp)
ffffffffc0203b62:	f426                	sd	s1,40(sp)
ffffffffc0203b64:	f04a                	sd	s2,32(sp)
ffffffffc0203b66:	ec4e                	sd	s3,24(sp)
ffffffffc0203b68:	e852                	sd	s4,16(sp)
ffffffffc0203b6a:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203b6c:	c52d                	beqz	a0,ffffffffc0203bd6 <dup_mmap+0x7a>
ffffffffc0203b6e:	892a                	mv	s2,a0
ffffffffc0203b70:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203b72:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203b74:	e595                	bnez	a1,ffffffffc0203ba0 <dup_mmap+0x44>
ffffffffc0203b76:	a085                	j	ffffffffc0203bd6 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203b78:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203b7a:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ed8>
        vma->vm_end = vm_end;
ffffffffc0203b7e:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203b82:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203b86:	e05ff0ef          	jal	ra,ffffffffc020398a <insert_vma_struct>
         * copy‑on‑write by passing share=1 to copy_range.  This causes
         * the physical pages to be shared between parent and child and
         * write permission removed from both until a write fault occurs.
         */
        bool share = 1;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203b8a:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0203b8e:	fe843603          	ld	a2,-24(s0)
ffffffffc0203b92:	6c8c                	ld	a1,24(s1)
ffffffffc0203b94:	01893503          	ld	a0,24(s2)
ffffffffc0203b98:	4705                	li	a4,1
ffffffffc0203b9a:	9d1ff0ef          	jal	ra,ffffffffc020356a <copy_range>
ffffffffc0203b9e:	e105                	bnez	a0,ffffffffc0203bbe <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203ba0:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203ba2:	02848863          	beq	s1,s0,ffffffffc0203bd2 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ba6:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203baa:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203bae:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203bb2:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203bb6:	af8fe0ef          	jal	ra,ffffffffc0201eae <kmalloc>
ffffffffc0203bba:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203bbc:	fd55                	bnez	a0,ffffffffc0203b78 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203bbe:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203bc0:	70e2                	ld	ra,56(sp)
ffffffffc0203bc2:	7442                	ld	s0,48(sp)
ffffffffc0203bc4:	74a2                	ld	s1,40(sp)
ffffffffc0203bc6:	7902                	ld	s2,32(sp)
ffffffffc0203bc8:	69e2                	ld	s3,24(sp)
ffffffffc0203bca:	6a42                	ld	s4,16(sp)
ffffffffc0203bcc:	6aa2                	ld	s5,8(sp)
ffffffffc0203bce:	6121                	addi	sp,sp,64
ffffffffc0203bd0:	8082                	ret
    return 0;
ffffffffc0203bd2:	4501                	li	a0,0
ffffffffc0203bd4:	b7f5                	j	ffffffffc0203bc0 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203bd6:	00003697          	auipc	a3,0x3
ffffffffc0203bda:	48268693          	addi	a3,a3,1154 # ffffffffc0207058 <default_pmm_manager+0x7e8>
ffffffffc0203bde:	00003617          	auipc	a2,0x3
ffffffffc0203be2:	8e260613          	addi	a2,a2,-1822 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203be6:	0cf00593          	li	a1,207
ffffffffc0203bea:	00003517          	auipc	a0,0x3
ffffffffc0203bee:	3d650513          	addi	a0,a0,982 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203bf2:	89dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203bf6 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203bf6:	1101                	addi	sp,sp,-32
ffffffffc0203bf8:	ec06                	sd	ra,24(sp)
ffffffffc0203bfa:	e822                	sd	s0,16(sp)
ffffffffc0203bfc:	e426                	sd	s1,8(sp)
ffffffffc0203bfe:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203c00:	c531                	beqz	a0,ffffffffc0203c4c <exit_mmap+0x56>
ffffffffc0203c02:	591c                	lw	a5,48(a0)
ffffffffc0203c04:	84aa                	mv	s1,a0
ffffffffc0203c06:	e3b9                	bnez	a5,ffffffffc0203c4c <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203c08:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203c0a:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203c0e:	02850663          	beq	a0,s0,ffffffffc0203c3a <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203c12:	ff043603          	ld	a2,-16(s0)
ffffffffc0203c16:	fe843583          	ld	a1,-24(s0)
ffffffffc0203c1a:	854a                	mv	a0,s2
ffffffffc0203c1c:	fa4fe0ef          	jal	ra,ffffffffc02023c0 <unmap_range>
ffffffffc0203c20:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203c22:	fe8498e3          	bne	s1,s0,ffffffffc0203c12 <exit_mmap+0x1c>
ffffffffc0203c26:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203c28:	00848c63          	beq	s1,s0,ffffffffc0203c40 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203c2c:	ff043603          	ld	a2,-16(s0)
ffffffffc0203c30:	fe843583          	ld	a1,-24(s0)
ffffffffc0203c34:	854a                	mv	a0,s2
ffffffffc0203c36:	8d1fe0ef          	jal	ra,ffffffffc0202506 <exit_range>
ffffffffc0203c3a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203c3c:	fe8498e3          	bne	s1,s0,ffffffffc0203c2c <exit_mmap+0x36>
    }
}
ffffffffc0203c40:	60e2                	ld	ra,24(sp)
ffffffffc0203c42:	6442                	ld	s0,16(sp)
ffffffffc0203c44:	64a2                	ld	s1,8(sp)
ffffffffc0203c46:	6902                	ld	s2,0(sp)
ffffffffc0203c48:	6105                	addi	sp,sp,32
ffffffffc0203c4a:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203c4c:	00003697          	auipc	a3,0x3
ffffffffc0203c50:	42c68693          	addi	a3,a3,1068 # ffffffffc0207078 <default_pmm_manager+0x808>
ffffffffc0203c54:	00003617          	auipc	a2,0x3
ffffffffc0203c58:	86c60613          	addi	a2,a2,-1940 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203c5c:	0ee00593          	li	a1,238
ffffffffc0203c60:	00003517          	auipc	a0,0x3
ffffffffc0203c64:	36050513          	addi	a0,a0,864 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203c68:	827fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203c6c <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203c6c:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203c6e:	04000513          	li	a0,64
{
ffffffffc0203c72:	fc06                	sd	ra,56(sp)
ffffffffc0203c74:	f822                	sd	s0,48(sp)
ffffffffc0203c76:	f426                	sd	s1,40(sp)
ffffffffc0203c78:	f04a                	sd	s2,32(sp)
ffffffffc0203c7a:	ec4e                	sd	s3,24(sp)
ffffffffc0203c7c:	e852                	sd	s4,16(sp)
ffffffffc0203c7e:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203c80:	a2efe0ef          	jal	ra,ffffffffc0201eae <kmalloc>
    if (mm != NULL)
ffffffffc0203c84:	2e050663          	beqz	a0,ffffffffc0203f70 <vmm_init+0x304>
ffffffffc0203c88:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203c8a:	e508                	sd	a0,8(a0)
ffffffffc0203c8c:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203c8e:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203c92:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203c96:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203c9a:	02053423          	sd	zero,40(a0)
ffffffffc0203c9e:	02052823          	sw	zero,48(a0)
ffffffffc0203ca2:	02053c23          	sd	zero,56(a0)
ffffffffc0203ca6:	03200413          	li	s0,50
ffffffffc0203caa:	a811                	j	ffffffffc0203cbe <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203cac:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203cae:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203cb0:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203cb4:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203cb6:	8526                	mv	a0,s1
ffffffffc0203cb8:	cd3ff0ef          	jal	ra,ffffffffc020398a <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203cbc:	c80d                	beqz	s0,ffffffffc0203cee <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203cbe:	03000513          	li	a0,48
ffffffffc0203cc2:	9ecfe0ef          	jal	ra,ffffffffc0201eae <kmalloc>
ffffffffc0203cc6:	85aa                	mv	a1,a0
ffffffffc0203cc8:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203ccc:	f165                	bnez	a0,ffffffffc0203cac <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203cce:	00003697          	auipc	a3,0x3
ffffffffc0203cd2:	54268693          	addi	a3,a3,1346 # ffffffffc0207210 <default_pmm_manager+0x9a0>
ffffffffc0203cd6:	00002617          	auipc	a2,0x2
ffffffffc0203cda:	7ea60613          	addi	a2,a2,2026 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203cde:	13200593          	li	a1,306
ffffffffc0203ce2:	00003517          	auipc	a0,0x3
ffffffffc0203ce6:	2de50513          	addi	a0,a0,734 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203cea:	fa4fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203cee:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203cf2:	1f900913          	li	s2,505
ffffffffc0203cf6:	a819                	j	ffffffffc0203d0c <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203cf8:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203cfa:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203cfc:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d00:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203d02:	8526                	mv	a0,s1
ffffffffc0203d04:	c87ff0ef          	jal	ra,ffffffffc020398a <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203d08:	03240a63          	beq	s0,s2,ffffffffc0203d3c <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d0c:	03000513          	li	a0,48
ffffffffc0203d10:	99efe0ef          	jal	ra,ffffffffc0201eae <kmalloc>
ffffffffc0203d14:	85aa                	mv	a1,a0
ffffffffc0203d16:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203d1a:	fd79                	bnez	a0,ffffffffc0203cf8 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203d1c:	00003697          	auipc	a3,0x3
ffffffffc0203d20:	4f468693          	addi	a3,a3,1268 # ffffffffc0207210 <default_pmm_manager+0x9a0>
ffffffffc0203d24:	00002617          	auipc	a2,0x2
ffffffffc0203d28:	79c60613          	addi	a2,a2,1948 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203d2c:	13900593          	li	a1,313
ffffffffc0203d30:	00003517          	auipc	a0,0x3
ffffffffc0203d34:	29050513          	addi	a0,a0,656 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203d38:	f56fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203d3c:	649c                	ld	a5,8(s1)
ffffffffc0203d3e:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203d40:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203d44:	16f48663          	beq	s1,a5,ffffffffc0203eb0 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203d48:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd4a3d4>
ffffffffc0203d4c:	ffe70693          	addi	a3,a4,-2 # 1ffffe <_binary_obj___user_exit_out_size+0x1f4ece>
ffffffffc0203d50:	10d61063          	bne	a2,a3,ffffffffc0203e50 <vmm_init+0x1e4>
ffffffffc0203d54:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203d58:	0ed71c63          	bne	a4,a3,ffffffffc0203e50 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203d5c:	0715                	addi	a4,a4,5
ffffffffc0203d5e:	679c                	ld	a5,8(a5)
ffffffffc0203d60:	feb712e3          	bne	a4,a1,ffffffffc0203d44 <vmm_init+0xd8>
ffffffffc0203d64:	4a1d                	li	s4,7
ffffffffc0203d66:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d68:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203d6c:	85a2                	mv	a1,s0
ffffffffc0203d6e:	8526                	mv	a0,s1
ffffffffc0203d70:	bdbff0ef          	jal	ra,ffffffffc020394a <find_vma>
ffffffffc0203d74:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203d76:	16050d63          	beqz	a0,ffffffffc0203ef0 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203d7a:	00140593          	addi	a1,s0,1
ffffffffc0203d7e:	8526                	mv	a0,s1
ffffffffc0203d80:	bcbff0ef          	jal	ra,ffffffffc020394a <find_vma>
ffffffffc0203d84:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203d86:	14050563          	beqz	a0,ffffffffc0203ed0 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203d8a:	85d2                	mv	a1,s4
ffffffffc0203d8c:	8526                	mv	a0,s1
ffffffffc0203d8e:	bbdff0ef          	jal	ra,ffffffffc020394a <find_vma>
        assert(vma3 == NULL);
ffffffffc0203d92:	16051f63          	bnez	a0,ffffffffc0203f10 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203d96:	00340593          	addi	a1,s0,3
ffffffffc0203d9a:	8526                	mv	a0,s1
ffffffffc0203d9c:	bafff0ef          	jal	ra,ffffffffc020394a <find_vma>
        assert(vma4 == NULL);
ffffffffc0203da0:	1a051863          	bnez	a0,ffffffffc0203f50 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203da4:	00440593          	addi	a1,s0,4
ffffffffc0203da8:	8526                	mv	a0,s1
ffffffffc0203daa:	ba1ff0ef          	jal	ra,ffffffffc020394a <find_vma>
        assert(vma5 == NULL);
ffffffffc0203dae:	18051163          	bnez	a0,ffffffffc0203f30 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203db2:	00893783          	ld	a5,8(s2)
ffffffffc0203db6:	0a879d63          	bne	a5,s0,ffffffffc0203e70 <vmm_init+0x204>
ffffffffc0203dba:	01093783          	ld	a5,16(s2)
ffffffffc0203dbe:	0b479963          	bne	a5,s4,ffffffffc0203e70 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203dc2:	0089b783          	ld	a5,8(s3)
ffffffffc0203dc6:	0c879563          	bne	a5,s0,ffffffffc0203e90 <vmm_init+0x224>
ffffffffc0203dca:	0109b783          	ld	a5,16(s3)
ffffffffc0203dce:	0d479163          	bne	a5,s4,ffffffffc0203e90 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203dd2:	0415                	addi	s0,s0,5
ffffffffc0203dd4:	0a15                	addi	s4,s4,5
ffffffffc0203dd6:	f9541be3          	bne	s0,s5,ffffffffc0203d6c <vmm_init+0x100>
ffffffffc0203dda:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203ddc:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203dde:	85a2                	mv	a1,s0
ffffffffc0203de0:	8526                	mv	a0,s1
ffffffffc0203de2:	b69ff0ef          	jal	ra,ffffffffc020394a <find_vma>
ffffffffc0203de6:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203dea:	c90d                	beqz	a0,ffffffffc0203e1c <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203dec:	6914                	ld	a3,16(a0)
ffffffffc0203dee:	6510                	ld	a2,8(a0)
ffffffffc0203df0:	00003517          	auipc	a0,0x3
ffffffffc0203df4:	3a850513          	addi	a0,a0,936 # ffffffffc0207198 <default_pmm_manager+0x928>
ffffffffc0203df8:	b9cfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203dfc:	00003697          	auipc	a3,0x3
ffffffffc0203e00:	3c468693          	addi	a3,a3,964 # ffffffffc02071c0 <default_pmm_manager+0x950>
ffffffffc0203e04:	00002617          	auipc	a2,0x2
ffffffffc0203e08:	6bc60613          	addi	a2,a2,1724 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203e0c:	15f00593          	li	a1,351
ffffffffc0203e10:	00003517          	auipc	a0,0x3
ffffffffc0203e14:	1b050513          	addi	a0,a0,432 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203e18:	e76fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203e1c:	147d                	addi	s0,s0,-1
ffffffffc0203e1e:	fd2410e3          	bne	s0,s2,ffffffffc0203dde <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203e22:	8526                	mv	a0,s1
ffffffffc0203e24:	c37ff0ef          	jal	ra,ffffffffc0203a5a <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203e28:	00003517          	auipc	a0,0x3
ffffffffc0203e2c:	3b050513          	addi	a0,a0,944 # ffffffffc02071d8 <default_pmm_manager+0x968>
ffffffffc0203e30:	b64fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203e34:	7442                	ld	s0,48(sp)
ffffffffc0203e36:	70e2                	ld	ra,56(sp)
ffffffffc0203e38:	74a2                	ld	s1,40(sp)
ffffffffc0203e3a:	7902                	ld	s2,32(sp)
ffffffffc0203e3c:	69e2                	ld	s3,24(sp)
ffffffffc0203e3e:	6a42                	ld	s4,16(sp)
ffffffffc0203e40:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203e42:	00003517          	auipc	a0,0x3
ffffffffc0203e46:	3b650513          	addi	a0,a0,950 # ffffffffc02071f8 <default_pmm_manager+0x988>
}
ffffffffc0203e4a:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203e4c:	b48fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203e50:	00003697          	auipc	a3,0x3
ffffffffc0203e54:	26068693          	addi	a3,a3,608 # ffffffffc02070b0 <default_pmm_manager+0x840>
ffffffffc0203e58:	00002617          	auipc	a2,0x2
ffffffffc0203e5c:	66860613          	addi	a2,a2,1640 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203e60:	14300593          	li	a1,323
ffffffffc0203e64:	00003517          	auipc	a0,0x3
ffffffffc0203e68:	15c50513          	addi	a0,a0,348 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203e6c:	e22fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203e70:	00003697          	auipc	a3,0x3
ffffffffc0203e74:	2c868693          	addi	a3,a3,712 # ffffffffc0207138 <default_pmm_manager+0x8c8>
ffffffffc0203e78:	00002617          	auipc	a2,0x2
ffffffffc0203e7c:	64860613          	addi	a2,a2,1608 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203e80:	15400593          	li	a1,340
ffffffffc0203e84:	00003517          	auipc	a0,0x3
ffffffffc0203e88:	13c50513          	addi	a0,a0,316 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203e8c:	e02fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203e90:	00003697          	auipc	a3,0x3
ffffffffc0203e94:	2d868693          	addi	a3,a3,728 # ffffffffc0207168 <default_pmm_manager+0x8f8>
ffffffffc0203e98:	00002617          	auipc	a2,0x2
ffffffffc0203e9c:	62860613          	addi	a2,a2,1576 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203ea0:	15500593          	li	a1,341
ffffffffc0203ea4:	00003517          	auipc	a0,0x3
ffffffffc0203ea8:	11c50513          	addi	a0,a0,284 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203eac:	de2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203eb0:	00003697          	auipc	a3,0x3
ffffffffc0203eb4:	1e868693          	addi	a3,a3,488 # ffffffffc0207098 <default_pmm_manager+0x828>
ffffffffc0203eb8:	00002617          	auipc	a2,0x2
ffffffffc0203ebc:	60860613          	addi	a2,a2,1544 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203ec0:	14100593          	li	a1,321
ffffffffc0203ec4:	00003517          	auipc	a0,0x3
ffffffffc0203ec8:	0fc50513          	addi	a0,a0,252 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203ecc:	dc2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203ed0:	00003697          	auipc	a3,0x3
ffffffffc0203ed4:	22868693          	addi	a3,a3,552 # ffffffffc02070f8 <default_pmm_manager+0x888>
ffffffffc0203ed8:	00002617          	auipc	a2,0x2
ffffffffc0203edc:	5e860613          	addi	a2,a2,1512 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203ee0:	14c00593          	li	a1,332
ffffffffc0203ee4:	00003517          	auipc	a0,0x3
ffffffffc0203ee8:	0dc50513          	addi	a0,a0,220 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203eec:	da2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203ef0:	00003697          	auipc	a3,0x3
ffffffffc0203ef4:	1f868693          	addi	a3,a3,504 # ffffffffc02070e8 <default_pmm_manager+0x878>
ffffffffc0203ef8:	00002617          	auipc	a2,0x2
ffffffffc0203efc:	5c860613          	addi	a2,a2,1480 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203f00:	14a00593          	li	a1,330
ffffffffc0203f04:	00003517          	auipc	a0,0x3
ffffffffc0203f08:	0bc50513          	addi	a0,a0,188 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203f0c:	d82fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203f10:	00003697          	auipc	a3,0x3
ffffffffc0203f14:	1f868693          	addi	a3,a3,504 # ffffffffc0207108 <default_pmm_manager+0x898>
ffffffffc0203f18:	00002617          	auipc	a2,0x2
ffffffffc0203f1c:	5a860613          	addi	a2,a2,1448 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203f20:	14e00593          	li	a1,334
ffffffffc0203f24:	00003517          	auipc	a0,0x3
ffffffffc0203f28:	09c50513          	addi	a0,a0,156 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203f2c:	d62fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203f30:	00003697          	auipc	a3,0x3
ffffffffc0203f34:	1f868693          	addi	a3,a3,504 # ffffffffc0207128 <default_pmm_manager+0x8b8>
ffffffffc0203f38:	00002617          	auipc	a2,0x2
ffffffffc0203f3c:	58860613          	addi	a2,a2,1416 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203f40:	15200593          	li	a1,338
ffffffffc0203f44:	00003517          	auipc	a0,0x3
ffffffffc0203f48:	07c50513          	addi	a0,a0,124 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203f4c:	d42fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203f50:	00003697          	auipc	a3,0x3
ffffffffc0203f54:	1c868693          	addi	a3,a3,456 # ffffffffc0207118 <default_pmm_manager+0x8a8>
ffffffffc0203f58:	00002617          	auipc	a2,0x2
ffffffffc0203f5c:	56860613          	addi	a2,a2,1384 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203f60:	15000593          	li	a1,336
ffffffffc0203f64:	00003517          	auipc	a0,0x3
ffffffffc0203f68:	05c50513          	addi	a0,a0,92 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203f6c:	d22fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203f70:	00003697          	auipc	a3,0x3
ffffffffc0203f74:	0d868693          	addi	a3,a3,216 # ffffffffc0207048 <default_pmm_manager+0x7d8>
ffffffffc0203f78:	00002617          	auipc	a2,0x2
ffffffffc0203f7c:	54860613          	addi	a2,a2,1352 # ffffffffc02064c0 <commands+0x960>
ffffffffc0203f80:	12a00593          	li	a1,298
ffffffffc0203f84:	00003517          	auipc	a0,0x3
ffffffffc0203f88:	03c50513          	addi	a0,a0,60 # ffffffffc0206fc0 <default_pmm_manager+0x750>
ffffffffc0203f8c:	d02fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f90 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203f90:	7179                	addi	sp,sp,-48
ffffffffc0203f92:	f022                	sd	s0,32(sp)
ffffffffc0203f94:	f406                	sd	ra,40(sp)
ffffffffc0203f96:	ec26                	sd	s1,24(sp)
ffffffffc0203f98:	e84a                	sd	s2,16(sp)
ffffffffc0203f9a:	e44e                	sd	s3,8(sp)
ffffffffc0203f9c:	e052                	sd	s4,0(sp)
ffffffffc0203f9e:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203fa0:	c135                	beqz	a0,ffffffffc0204004 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203fa2:	002007b7          	lui	a5,0x200
ffffffffc0203fa6:	04f5e663          	bltu	a1,a5,ffffffffc0203ff2 <user_mem_check+0x62>
ffffffffc0203faa:	00c584b3          	add	s1,a1,a2
ffffffffc0203fae:	0495f263          	bgeu	a1,s1,ffffffffc0203ff2 <user_mem_check+0x62>
ffffffffc0203fb2:	4785                	li	a5,1
ffffffffc0203fb4:	07fe                	slli	a5,a5,0x1f
ffffffffc0203fb6:	0297ee63          	bltu	a5,s1,ffffffffc0203ff2 <user_mem_check+0x62>
ffffffffc0203fba:	892a                	mv	s2,a0
ffffffffc0203fbc:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203fbe:	6a05                	lui	s4,0x1
ffffffffc0203fc0:	a821                	j	ffffffffc0203fd8 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203fc2:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203fc6:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203fc8:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203fca:	c685                	beqz	a3,ffffffffc0203ff2 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203fcc:	c399                	beqz	a5,ffffffffc0203fd2 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203fce:	02e46263          	bltu	s0,a4,ffffffffc0203ff2 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203fd2:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203fd4:	04947663          	bgeu	s0,s1,ffffffffc0204020 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203fd8:	85a2                	mv	a1,s0
ffffffffc0203fda:	854a                	mv	a0,s2
ffffffffc0203fdc:	96fff0ef          	jal	ra,ffffffffc020394a <find_vma>
ffffffffc0203fe0:	c909                	beqz	a0,ffffffffc0203ff2 <user_mem_check+0x62>
ffffffffc0203fe2:	6518                	ld	a4,8(a0)
ffffffffc0203fe4:	00e46763          	bltu	s0,a4,ffffffffc0203ff2 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203fe8:	4d1c                	lw	a5,24(a0)
ffffffffc0203fea:	fc099ce3          	bnez	s3,ffffffffc0203fc2 <user_mem_check+0x32>
ffffffffc0203fee:	8b85                	andi	a5,a5,1
ffffffffc0203ff0:	f3ed                	bnez	a5,ffffffffc0203fd2 <user_mem_check+0x42>
            return 0;
ffffffffc0203ff2:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203ff4:	70a2                	ld	ra,40(sp)
ffffffffc0203ff6:	7402                	ld	s0,32(sp)
ffffffffc0203ff8:	64e2                	ld	s1,24(sp)
ffffffffc0203ffa:	6942                	ld	s2,16(sp)
ffffffffc0203ffc:	69a2                	ld	s3,8(sp)
ffffffffc0203ffe:	6a02                	ld	s4,0(sp)
ffffffffc0204000:	6145                	addi	sp,sp,48
ffffffffc0204002:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204004:	c02007b7          	lui	a5,0xc0200
ffffffffc0204008:	4501                	li	a0,0
ffffffffc020400a:	fef5e5e3          	bltu	a1,a5,ffffffffc0203ff4 <user_mem_check+0x64>
ffffffffc020400e:	962e                	add	a2,a2,a1
ffffffffc0204010:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203ff4 <user_mem_check+0x64>
ffffffffc0204014:	c8000537          	lui	a0,0xc8000
ffffffffc0204018:	0505                	addi	a0,a0,1
ffffffffc020401a:	00a63533          	sltu	a0,a2,a0
ffffffffc020401e:	bfd9                	j	ffffffffc0203ff4 <user_mem_check+0x64>
        return 1;
ffffffffc0204020:	4505                	li	a0,1
ffffffffc0204022:	bfc9                	j	ffffffffc0203ff4 <user_mem_check+0x64>

ffffffffc0204024 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204024:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204026:	9402                	jalr	s0

	jal do_exit
ffffffffc0204028:	5da000ef          	jal	ra,ffffffffc0204602 <do_exit>

ffffffffc020402c <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020402c:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020402e:	10800513          	li	a0,264
{
ffffffffc0204032:	e022                	sd	s0,0(sp)
ffffffffc0204034:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204036:	e79fd0ef          	jal	ra,ffffffffc0201eae <kmalloc>
ffffffffc020403a:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020403c:	cd21                	beqz	a0,ffffffffc0204094 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;                 // 进程状态 - 未初始化
ffffffffc020403e:	57fd                	li	a5,-1
ffffffffc0204040:	1782                	slli	a5,a5,0x20
ffffffffc0204042:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                            // 运行次数 - 还未运行过
        proc->kstack = 0;                          // 内核栈 - 还未分配
        proc->need_resched = 0;                    // 初始不需要重新调度
        proc->parent = NULL;                       // 还没有父进程
        proc->mm = NULL;                           // 内存管理结构 - 还未设置
        memset(&(proc->context), 0, sizeof(struct context));  // 清空上下文
ffffffffc0204044:	07000613          	li	a2,112
ffffffffc0204048:	4581                	li	a1,0
        proc->runs = 0;                            // 运行次数 - 还未运行过
ffffffffc020404a:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d4b3f4>
        proc->kstack = 0;                          // 内核栈 - 还未分配
ffffffffc020404e:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                    // 初始不需要重新调度
ffffffffc0204052:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                       // 还没有父进程
ffffffffc0204056:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                           // 内存管理结构 - 还未设置
ffffffffc020405a:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));  // 清空上下文
ffffffffc020405e:	03050513          	addi	a0,a0,48
ffffffffc0204062:	06d010ef          	jal	ra,ffffffffc02058ce <memset>
        proc->tf = NULL;                           // 中断帧 - 还未设置
        proc->pgdir = boot_pgdir_pa;              // 初始使用启动页目录
ffffffffc0204066:	000b1797          	auipc	a5,0xb1
ffffffffc020406a:	b627b783          	ld	a5,-1182(a5) # ffffffffc02b4bc8 <boot_pgdir_pa>
        proc->tf = NULL;                           // 中断帧 - 还未设置
ffffffffc020406e:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;              // 初始使用启动页目录
ffffffffc0204072:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                           // 没有设置标志
ffffffffc0204074:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 清空进程名
ffffffffc0204078:	4641                	li	a2,16
ffffffffc020407a:	4581                	li	a1,0
ffffffffc020407c:	0b440513          	addi	a0,s0,180
ffffffffc0204080:	04f010ef          	jal	ra,ffffffffc02058ce <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;        // 0 通常表示不在等待状态
ffffffffc0204084:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;           // child pointer: 还没有孩子
ffffffffc0204088:	0e043823          	sd	zero,240(s0)
        proc->yptr = NULL;           // younger sibling: 还没有更“年轻”的兄弟
ffffffffc020408c:	0e043c23          	sd	zero,248(s0)
        proc->optr = NULL;           // older sibling: 还没有更“年长”的兄弟
ffffffffc0204090:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0204094:	60a2                	ld	ra,8(sp)
ffffffffc0204096:	8522                	mv	a0,s0
ffffffffc0204098:	6402                	ld	s0,0(sp)
ffffffffc020409a:	0141                	addi	sp,sp,16
ffffffffc020409c:	8082                	ret

ffffffffc020409e <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020409e:	000b1797          	auipc	a5,0xb1
ffffffffc02040a2:	b5a7b783          	ld	a5,-1190(a5) # ffffffffc02b4bf8 <current>
ffffffffc02040a6:	73c8                	ld	a0,160(a5)
ffffffffc02040a8:	87afd06f          	j	ffffffffc0201122 <forkrets>

ffffffffc02040ac <user_main>:
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(cowtest);
ffffffffc02040ac:	000b1797          	auipc	a5,0xb1
ffffffffc02040b0:	b4c7b783          	ld	a5,-1204(a5) # ffffffffc02b4bf8 <current>
ffffffffc02040b4:	43cc                	lw	a1,4(a5)
{
ffffffffc02040b6:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE(cowtest);
ffffffffc02040b8:	00003617          	auipc	a2,0x3
ffffffffc02040bc:	16860613          	addi	a2,a2,360 # ffffffffc0207220 <default_pmm_manager+0x9b0>
ffffffffc02040c0:	00003517          	auipc	a0,0x3
ffffffffc02040c4:	16850513          	addi	a0,a0,360 # ffffffffc0207228 <default_pmm_manager+0x9b8>
{
ffffffffc02040c8:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE(cowtest);
ffffffffc02040ca:	8cafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02040ce:	3fe06797          	auipc	a5,0x3fe06
ffffffffc02040d2:	31278793          	addi	a5,a5,786 # a3e0 <_binary_obj___user_cowtest_out_size>
ffffffffc02040d6:	e43e                	sd	a5,8(sp)
ffffffffc02040d8:	00003517          	auipc	a0,0x3
ffffffffc02040dc:	14850513          	addi	a0,a0,328 # ffffffffc0207220 <default_pmm_manager+0x9b0>
ffffffffc02040e0:	0001c797          	auipc	a5,0x1c
ffffffffc02040e4:	eb878793          	addi	a5,a5,-328 # ffffffffc021ff98 <_binary_obj___user_cowtest_out_start>
ffffffffc02040e8:	f03e                	sd	a5,32(sp)
ffffffffc02040ea:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc02040ec:	e802                	sd	zero,16(sp)
ffffffffc02040ee:	73e010ef          	jal	ra,ffffffffc020582c <strlen>
ffffffffc02040f2:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc02040f4:	4511                	li	a0,4
ffffffffc02040f6:	55a2                	lw	a1,40(sp)
ffffffffc02040f8:	4662                	lw	a2,24(sp)
ffffffffc02040fa:	5682                	lw	a3,32(sp)
ffffffffc02040fc:	4722                	lw	a4,8(sp)
ffffffffc02040fe:	48a9                	li	a7,10
ffffffffc0204100:	9002                	ebreak
ffffffffc0204102:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204104:	65c2                	ld	a1,16(sp)
ffffffffc0204106:	00003517          	auipc	a0,0x3
ffffffffc020410a:	14a50513          	addi	a0,a0,330 # ffffffffc0207250 <default_pmm_manager+0x9e0>
ffffffffc020410e:	886fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
    panic("user_main execve failed.\n");
ffffffffc0204112:	00003617          	auipc	a2,0x3
ffffffffc0204116:	14e60613          	addi	a2,a2,334 # ffffffffc0207260 <default_pmm_manager+0x9f0>
ffffffffc020411a:	3b800593          	li	a1,952
ffffffffc020411e:	00003517          	auipc	a0,0x3
ffffffffc0204122:	16250513          	addi	a0,a0,354 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204126:	b68fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020412a <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc020412a:	6d14                	ld	a3,24(a0)
{
ffffffffc020412c:	1141                	addi	sp,sp,-16
ffffffffc020412e:	e406                	sd	ra,8(sp)
ffffffffc0204130:	c02007b7          	lui	a5,0xc0200
ffffffffc0204134:	02f6ee63          	bltu	a3,a5,ffffffffc0204170 <put_pgdir+0x46>
ffffffffc0204138:	000b1517          	auipc	a0,0xb1
ffffffffc020413c:	ab853503          	ld	a0,-1352(a0) # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc0204140:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0204142:	82b1                	srli	a3,a3,0xc
ffffffffc0204144:	000b1797          	auipc	a5,0xb1
ffffffffc0204148:	a947b783          	ld	a5,-1388(a5) # ffffffffc02b4bd8 <npage>
ffffffffc020414c:	02f6fe63          	bgeu	a3,a5,ffffffffc0204188 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204150:	00004517          	auipc	a0,0x4
ffffffffc0204154:	9c853503          	ld	a0,-1592(a0) # ffffffffc0207b18 <nbase>
}
ffffffffc0204158:	60a2                	ld	ra,8(sp)
ffffffffc020415a:	8e89                	sub	a3,a3,a0
ffffffffc020415c:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc020415e:	000b1517          	auipc	a0,0xb1
ffffffffc0204162:	a8253503          	ld	a0,-1406(a0) # ffffffffc02b4be0 <pages>
ffffffffc0204166:	4585                	li	a1,1
ffffffffc0204168:	9536                	add	a0,a0,a3
}
ffffffffc020416a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc020416c:	f5ffd06f          	j	ffffffffc02020ca <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204170:	00002617          	auipc	a2,0x2
ffffffffc0204174:	7a860613          	addi	a2,a2,1960 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc0204178:	07700593          	li	a1,119
ffffffffc020417c:	00002517          	auipc	a0,0x2
ffffffffc0204180:	03450513          	addi	a0,a0,52 # ffffffffc02061b0 <commands+0x650>
ffffffffc0204184:	b0afc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204188:	00002617          	auipc	a2,0x2
ffffffffc020418c:	00860613          	addi	a2,a2,8 # ffffffffc0206190 <commands+0x630>
ffffffffc0204190:	06900593          	li	a1,105
ffffffffc0204194:	00002517          	auipc	a0,0x2
ffffffffc0204198:	01c50513          	addi	a0,a0,28 # ffffffffc02061b0 <commands+0x650>
ffffffffc020419c:	af2fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02041a0 <proc_run>:
{
ffffffffc02041a0:	7179                	addi	sp,sp,-48
ffffffffc02041a2:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02041a4:	000b1917          	auipc	s2,0xb1
ffffffffc02041a8:	a5490913          	addi	s2,s2,-1452 # ffffffffc02b4bf8 <current>
{
ffffffffc02041ac:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02041ae:	00093483          	ld	s1,0(s2)
{
ffffffffc02041b2:	f406                	sd	ra,40(sp)
ffffffffc02041b4:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc02041b6:	02a48863          	beq	s1,a0,ffffffffc02041e6 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041ba:	100027f3          	csrr	a5,sstatus
ffffffffc02041be:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02041c0:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041c2:	ef9d                	bnez	a5,ffffffffc0204200 <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc02041c4:	755c                	ld	a5,168(a0)
ffffffffc02041c6:	577d                	li	a4,-1
ffffffffc02041c8:	177e                	slli	a4,a4,0x3f
ffffffffc02041ca:	83b1                	srli	a5,a5,0xc
        current = proc;
ffffffffc02041cc:	00a93023          	sd	a0,0(s2)
ffffffffc02041d0:	8fd9                	or	a5,a5,a4
ffffffffc02041d2:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(proc->context));
ffffffffc02041d6:	03050593          	addi	a1,a0,48
ffffffffc02041da:	03048513          	addi	a0,s1,48
ffffffffc02041de:	7f5000ef          	jal	ra,ffffffffc02051d2 <switch_to>
    if (flag)
ffffffffc02041e2:	00099863          	bnez	s3,ffffffffc02041f2 <proc_run+0x52>
}
ffffffffc02041e6:	70a2                	ld	ra,40(sp)
ffffffffc02041e8:	7482                	ld	s1,32(sp)
ffffffffc02041ea:	6962                	ld	s2,24(sp)
ffffffffc02041ec:	69c2                	ld	s3,16(sp)
ffffffffc02041ee:	6145                	addi	sp,sp,48
ffffffffc02041f0:	8082                	ret
ffffffffc02041f2:	70a2                	ld	ra,40(sp)
ffffffffc02041f4:	7482                	ld	s1,32(sp)
ffffffffc02041f6:	6962                	ld	s2,24(sp)
ffffffffc02041f8:	69c2                	ld	s3,16(sp)
ffffffffc02041fa:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02041fc:	fb2fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204200:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204202:	fb2fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204206:	6522                	ld	a0,8(sp)
ffffffffc0204208:	4985                	li	s3,1
ffffffffc020420a:	bf6d                	j	ffffffffc02041c4 <proc_run+0x24>

ffffffffc020420c <do_fork>:
{
ffffffffc020420c:	7119                	addi	sp,sp,-128
ffffffffc020420e:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204210:	000b1917          	auipc	s2,0xb1
ffffffffc0204214:	a0090913          	addi	s2,s2,-1536 # ffffffffc02b4c10 <nr_process>
ffffffffc0204218:	00092703          	lw	a4,0(s2)
{
ffffffffc020421c:	fc86                	sd	ra,120(sp)
ffffffffc020421e:	f8a2                	sd	s0,112(sp)
ffffffffc0204220:	f4a6                	sd	s1,104(sp)
ffffffffc0204222:	ecce                	sd	s3,88(sp)
ffffffffc0204224:	e8d2                	sd	s4,80(sp)
ffffffffc0204226:	e4d6                	sd	s5,72(sp)
ffffffffc0204228:	e0da                	sd	s6,64(sp)
ffffffffc020422a:	fc5e                	sd	s7,56(sp)
ffffffffc020422c:	f862                	sd	s8,48(sp)
ffffffffc020422e:	f466                	sd	s9,40(sp)
ffffffffc0204230:	f06a                	sd	s10,32(sp)
ffffffffc0204232:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204234:	6785                	lui	a5,0x1
ffffffffc0204236:	2ef75c63          	bge	a4,a5,ffffffffc020452e <do_fork+0x322>
ffffffffc020423a:	8a2a                	mv	s4,a0
ffffffffc020423c:	89ae                	mv	s3,a1
ffffffffc020423e:	8432                	mv	s0,a2
        proc = alloc_proc();
ffffffffc0204240:	dedff0ef          	jal	ra,ffffffffc020402c <alloc_proc>
ffffffffc0204244:	84aa                	mv	s1,a0
        if (proc == NULL) {
ffffffffc0204246:	2c050863          	beqz	a0,ffffffffc0204516 <do_fork+0x30a>
        proc->parent = current;
ffffffffc020424a:	000b1c17          	auipc	s8,0xb1
ffffffffc020424e:	9aec0c13          	addi	s8,s8,-1618 # ffffffffc02b4bf8 <current>
ffffffffc0204252:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204256:	4509                	li	a0,2
        proc->parent = current;
ffffffffc0204258:	f09c                	sd	a5,32(s1)
        current->wait_state = 0;
ffffffffc020425a:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8acc>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020425e:	e2ffd0ef          	jal	ra,ffffffffc020208c <alloc_pages>
    if (page != NULL)
ffffffffc0204262:	2a050763          	beqz	a0,ffffffffc0204510 <do_fork+0x304>
    return page - pages + nbase;
ffffffffc0204266:	000b1a97          	auipc	s5,0xb1
ffffffffc020426a:	97aa8a93          	addi	s5,s5,-1670 # ffffffffc02b4be0 <pages>
ffffffffc020426e:	000ab683          	ld	a3,0(s5)
ffffffffc0204272:	00004b17          	auipc	s6,0x4
ffffffffc0204276:	8a6b0b13          	addi	s6,s6,-1882 # ffffffffc0207b18 <nbase>
ffffffffc020427a:	000b3783          	ld	a5,0(s6)
ffffffffc020427e:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204282:	000b1b97          	auipc	s7,0xb1
ffffffffc0204286:	956b8b93          	addi	s7,s7,-1706 # ffffffffc02b4bd8 <npage>
    return page - pages + nbase;
ffffffffc020428a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020428c:	5dfd                	li	s11,-1
ffffffffc020428e:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204292:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204294:	00cddd93          	srli	s11,s11,0xc
ffffffffc0204298:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020429c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020429e:	2ce67563          	bgeu	a2,a4,ffffffffc0204568 <do_fork+0x35c>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02042a2:	000c3603          	ld	a2,0(s8)
ffffffffc02042a6:	000b1c17          	auipc	s8,0xb1
ffffffffc02042aa:	94ac0c13          	addi	s8,s8,-1718 # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc02042ae:	000c3703          	ld	a4,0(s8)
ffffffffc02042b2:	02863d03          	ld	s10,40(a2)
ffffffffc02042b6:	e43e                	sd	a5,8(sp)
ffffffffc02042b8:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02042ba:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02042bc:	020d0863          	beqz	s10,ffffffffc02042ec <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc02042c0:	100a7a13          	andi	s4,s4,256
ffffffffc02042c4:	180a0863          	beqz	s4,ffffffffc0204454 <do_fork+0x248>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02042c8:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02042cc:	018d3783          	ld	a5,24(s10)
ffffffffc02042d0:	c02006b7          	lui	a3,0xc0200
ffffffffc02042d4:	2705                	addiw	a4,a4,1
ffffffffc02042d6:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc02042da:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02042de:	2ad7e163          	bltu	a5,a3,ffffffffc0204580 <do_fork+0x374>
ffffffffc02042e2:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02042e6:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02042e8:	8f99                	sub	a5,a5,a4
ffffffffc02042ea:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02042ec:	6789                	lui	a5,0x2
ffffffffc02042ee:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>
ffffffffc02042f2:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02042f4:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02042f6:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc02042f8:	87b6                	mv	a5,a3
ffffffffc02042fa:	12040893          	addi	a7,s0,288
ffffffffc02042fe:	00063803          	ld	a6,0(a2)
ffffffffc0204302:	6608                	ld	a0,8(a2)
ffffffffc0204304:	6a0c                	ld	a1,16(a2)
ffffffffc0204306:	6e18                	ld	a4,24(a2)
ffffffffc0204308:	0107b023          	sd	a6,0(a5)
ffffffffc020430c:	e788                	sd	a0,8(a5)
ffffffffc020430e:	eb8c                	sd	a1,16(a5)
ffffffffc0204310:	ef98                	sd	a4,24(a5)
ffffffffc0204312:	02060613          	addi	a2,a2,32
ffffffffc0204316:	02078793          	addi	a5,a5,32
ffffffffc020431a:	ff1612e3          	bne	a2,a7,ffffffffc02042fe <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc020431e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204322:	12098763          	beqz	s3,ffffffffc0204450 <do_fork+0x244>
    if (++last_pid >= MAX_PID)
ffffffffc0204326:	000ac817          	auipc	a6,0xac
ffffffffc020432a:	44280813          	addi	a6,a6,1090 # ffffffffc02b0768 <last_pid.1>
ffffffffc020432e:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204332:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204336:	00000717          	auipc	a4,0x0
ffffffffc020433a:	d6870713          	addi	a4,a4,-664 # ffffffffc020409e <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc020433e:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204342:	f898                	sd	a4,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204344:	fc94                	sd	a3,56(s1)
    if (++last_pid >= MAX_PID)
ffffffffc0204346:	00a82023          	sw	a0,0(a6)
ffffffffc020434a:	6789                	lui	a5,0x2
ffffffffc020434c:	08f55b63          	bge	a0,a5,ffffffffc02043e2 <do_fork+0x1d6>
    if (last_pid >= next_safe)
ffffffffc0204350:	000ac317          	auipc	t1,0xac
ffffffffc0204354:	41c30313          	addi	t1,t1,1052 # ffffffffc02b076c <next_safe.0>
ffffffffc0204358:	00032783          	lw	a5,0(t1)
ffffffffc020435c:	000b1417          	auipc	s0,0xb1
ffffffffc0204360:	82c40413          	addi	s0,s0,-2004 # ffffffffc02b4b88 <proc_list>
ffffffffc0204364:	08f55763          	bge	a0,a5,ffffffffc02043f2 <do_fork+0x1e6>
        proc->pid = get_pid();
ffffffffc0204368:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020436a:	45a9                	li	a1,10
ffffffffc020436c:	2501                	sext.w	a0,a0
ffffffffc020436e:	0ba010ef          	jal	ra,ffffffffc0205428 <hash32>
ffffffffc0204372:	02051793          	slli	a5,a0,0x20
ffffffffc0204376:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020437a:	000ad797          	auipc	a5,0xad
ffffffffc020437e:	80e78793          	addi	a5,a5,-2034 # ffffffffc02b0b88 <hash_list>
ffffffffc0204382:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204384:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204386:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204388:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020438c:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020438e:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204390:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204392:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204394:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204398:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020439a:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020439c:	e21c                	sd	a5,0(a2)
ffffffffc020439e:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02043a0:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02043a2:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02043a4:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02043a8:	10e4b023          	sd	a4,256(s1)
ffffffffc02043ac:	c311                	beqz	a4,ffffffffc02043b0 <do_fork+0x1a4>
        proc->optr->yptr = proc;
ffffffffc02043ae:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02043b0:	00092783          	lw	a5,0(s2)
        wakeup_proc(proc);
ffffffffc02043b4:	8526                	mv	a0,s1
    proc->parent->cptr = proc;
ffffffffc02043b6:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02043b8:	2785                	addiw	a5,a5,1
ffffffffc02043ba:	00f92023          	sw	a5,0(s2)
        wakeup_proc(proc);
ffffffffc02043be:	67f000ef          	jal	ra,ffffffffc020523c <wakeup_proc>
        ret = proc->pid;
ffffffffc02043c2:	40c8                	lw	a0,4(s1)
}
ffffffffc02043c4:	70e6                	ld	ra,120(sp)
ffffffffc02043c6:	7446                	ld	s0,112(sp)
ffffffffc02043c8:	74a6                	ld	s1,104(sp)
ffffffffc02043ca:	7906                	ld	s2,96(sp)
ffffffffc02043cc:	69e6                	ld	s3,88(sp)
ffffffffc02043ce:	6a46                	ld	s4,80(sp)
ffffffffc02043d0:	6aa6                	ld	s5,72(sp)
ffffffffc02043d2:	6b06                	ld	s6,64(sp)
ffffffffc02043d4:	7be2                	ld	s7,56(sp)
ffffffffc02043d6:	7c42                	ld	s8,48(sp)
ffffffffc02043d8:	7ca2                	ld	s9,40(sp)
ffffffffc02043da:	7d02                	ld	s10,32(sp)
ffffffffc02043dc:	6de2                	ld	s11,24(sp)
ffffffffc02043de:	6109                	addi	sp,sp,128
ffffffffc02043e0:	8082                	ret
        last_pid = 1;
ffffffffc02043e2:	4785                	li	a5,1
ffffffffc02043e4:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02043e8:	4505                	li	a0,1
ffffffffc02043ea:	000ac317          	auipc	t1,0xac
ffffffffc02043ee:	38230313          	addi	t1,t1,898 # ffffffffc02b076c <next_safe.0>
    return listelm->next;
ffffffffc02043f2:	000b0417          	auipc	s0,0xb0
ffffffffc02043f6:	79640413          	addi	s0,s0,1942 # ffffffffc02b4b88 <proc_list>
ffffffffc02043fa:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02043fe:	6789                	lui	a5,0x2
ffffffffc0204400:	00f32023          	sw	a5,0(t1)
ffffffffc0204404:	86aa                	mv	a3,a0
ffffffffc0204406:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204408:	6e89                	lui	t4,0x2
ffffffffc020440a:	108e0d63          	beq	t3,s0,ffffffffc0204524 <do_fork+0x318>
ffffffffc020440e:	88ae                	mv	a7,a1
ffffffffc0204410:	87f2                	mv	a5,t3
ffffffffc0204412:	6609                	lui	a2,0x2
ffffffffc0204414:	a811                	j	ffffffffc0204428 <do_fork+0x21c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204416:	00e6d663          	bge	a3,a4,ffffffffc0204422 <do_fork+0x216>
ffffffffc020441a:	00c75463          	bge	a4,a2,ffffffffc0204422 <do_fork+0x216>
ffffffffc020441e:	863a                	mv	a2,a4
ffffffffc0204420:	4885                	li	a7,1
ffffffffc0204422:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204424:	00878d63          	beq	a5,s0,ffffffffc020443e <do_fork+0x232>
            if (proc->pid == last_pid)
ffffffffc0204428:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc020442c:	fed715e3          	bne	a4,a3,ffffffffc0204416 <do_fork+0x20a>
                if (++last_pid >= next_safe)
ffffffffc0204430:	2685                	addiw	a3,a3,1
ffffffffc0204432:	0ec6d463          	bge	a3,a2,ffffffffc020451a <do_fork+0x30e>
ffffffffc0204436:	679c                	ld	a5,8(a5)
ffffffffc0204438:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020443a:	fe8797e3          	bne	a5,s0,ffffffffc0204428 <do_fork+0x21c>
ffffffffc020443e:	c581                	beqz	a1,ffffffffc0204446 <do_fork+0x23a>
ffffffffc0204440:	00d82023          	sw	a3,0(a6)
ffffffffc0204444:	8536                	mv	a0,a3
ffffffffc0204446:	f20881e3          	beqz	a7,ffffffffc0204368 <do_fork+0x15c>
ffffffffc020444a:	00c32023          	sw	a2,0(t1)
ffffffffc020444e:	bf29                	j	ffffffffc0204368 <do_fork+0x15c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204450:	89b6                	mv	s3,a3
ffffffffc0204452:	bdd1                	j	ffffffffc0204326 <do_fork+0x11a>
    if ((mm = mm_create()) == NULL)
ffffffffc0204454:	cc6ff0ef          	jal	ra,ffffffffc020391a <mm_create>
ffffffffc0204458:	8caa                	mv	s9,a0
ffffffffc020445a:	c159                	beqz	a0,ffffffffc02044e0 <do_fork+0x2d4>
    if ((page = alloc_page()) == NULL)
ffffffffc020445c:	4505                	li	a0,1
ffffffffc020445e:	c2ffd0ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0204462:	cd25                	beqz	a0,ffffffffc02044da <do_fork+0x2ce>
    return page - pages + nbase;
ffffffffc0204464:	000ab683          	ld	a3,0(s5)
ffffffffc0204468:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc020446a:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc020446e:	40d506b3          	sub	a3,a0,a3
ffffffffc0204472:	8699                	srai	a3,a3,0x6
ffffffffc0204474:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204476:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020447a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020447c:	0eedf663          	bgeu	s11,a4,ffffffffc0204568 <do_fork+0x35c>
ffffffffc0204480:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204484:	6605                	lui	a2,0x1
ffffffffc0204486:	000b0597          	auipc	a1,0xb0
ffffffffc020448a:	74a5b583          	ld	a1,1866(a1) # ffffffffc02b4bd0 <boot_pgdir_va>
ffffffffc020448e:	9a36                	add	s4,s4,a3
ffffffffc0204490:	8552                	mv	a0,s4
ffffffffc0204492:	44e010ef          	jal	ra,ffffffffc02058e0 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204496:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc020449a:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020449e:	4785                	li	a5,1
ffffffffc02044a0:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02044a4:	8b85                	andi	a5,a5,1
ffffffffc02044a6:	4a05                	li	s4,1
ffffffffc02044a8:	c799                	beqz	a5,ffffffffc02044b6 <do_fork+0x2aa>
    {
        schedule();
ffffffffc02044aa:	613000ef          	jal	ra,ffffffffc02052bc <schedule>
ffffffffc02044ae:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc02044b2:	8b85                	andi	a5,a5,1
ffffffffc02044b4:	fbfd                	bnez	a5,ffffffffc02044aa <do_fork+0x29e>
        ret = dup_mmap(mm, oldmm);
ffffffffc02044b6:	85ea                	mv	a1,s10
ffffffffc02044b8:	8566                	mv	a0,s9
ffffffffc02044ba:	ea2ff0ef          	jal	ra,ffffffffc0203b5c <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02044be:	57f9                	li	a5,-2
ffffffffc02044c0:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc02044c4:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02044c6:	cbad                	beqz	a5,ffffffffc0204538 <do_fork+0x32c>
good_mm:
ffffffffc02044c8:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc02044ca:	de050fe3          	beqz	a0,ffffffffc02042c8 <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc02044ce:	8566                	mv	a0,s9
ffffffffc02044d0:	f26ff0ef          	jal	ra,ffffffffc0203bf6 <exit_mmap>
    put_pgdir(mm);
ffffffffc02044d4:	8566                	mv	a0,s9
ffffffffc02044d6:	c55ff0ef          	jal	ra,ffffffffc020412a <put_pgdir>
    mm_destroy(mm);
ffffffffc02044da:	8566                	mv	a0,s9
ffffffffc02044dc:	d7eff0ef          	jal	ra,ffffffffc0203a5a <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02044e0:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc02044e2:	c02007b7          	lui	a5,0xc0200
ffffffffc02044e6:	0af6ea63          	bltu	a3,a5,ffffffffc020459a <do_fork+0x38e>
ffffffffc02044ea:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02044ee:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02044f2:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02044f6:	83b1                	srli	a5,a5,0xc
ffffffffc02044f8:	04e7fc63          	bgeu	a5,a4,ffffffffc0204550 <do_fork+0x344>
    return &pages[PPN(pa) - nbase];
ffffffffc02044fc:	000b3703          	ld	a4,0(s6)
ffffffffc0204500:	000ab503          	ld	a0,0(s5)
ffffffffc0204504:	4589                	li	a1,2
ffffffffc0204506:	8f99                	sub	a5,a5,a4
ffffffffc0204508:	079a                	slli	a5,a5,0x6
ffffffffc020450a:	953e                	add	a0,a0,a5
ffffffffc020450c:	bbffd0ef          	jal	ra,ffffffffc02020ca <free_pages>
    kfree(proc);
ffffffffc0204510:	8526                	mv	a0,s1
ffffffffc0204512:	a4dfd0ef          	jal	ra,ffffffffc0201f5e <kfree>
    ret = -E_NO_MEM;
ffffffffc0204516:	5571                	li	a0,-4
    return ret;
ffffffffc0204518:	b575                	j	ffffffffc02043c4 <do_fork+0x1b8>
                    if (last_pid >= MAX_PID)
ffffffffc020451a:	01d6c363          	blt	a3,t4,ffffffffc0204520 <do_fork+0x314>
                        last_pid = 1;
ffffffffc020451e:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204520:	4585                	li	a1,1
ffffffffc0204522:	b5e5                	j	ffffffffc020440a <do_fork+0x1fe>
ffffffffc0204524:	c599                	beqz	a1,ffffffffc0204532 <do_fork+0x326>
ffffffffc0204526:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020452a:	8536                	mv	a0,a3
ffffffffc020452c:	bd35                	j	ffffffffc0204368 <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;
ffffffffc020452e:	556d                	li	a0,-5
ffffffffc0204530:	bd51                	j	ffffffffc02043c4 <do_fork+0x1b8>
    return last_pid;
ffffffffc0204532:	00082503          	lw	a0,0(a6)
ffffffffc0204536:	bd0d                	j	ffffffffc0204368 <do_fork+0x15c>
    {
        panic("Unlock failed.\n");
ffffffffc0204538:	00003617          	auipc	a2,0x3
ffffffffc020453c:	d6060613          	addi	a2,a2,-672 # ffffffffc0207298 <default_pmm_manager+0xa28>
ffffffffc0204540:	03f00593          	li	a1,63
ffffffffc0204544:	00003517          	auipc	a0,0x3
ffffffffc0204548:	d6450513          	addi	a0,a0,-668 # ffffffffc02072a8 <default_pmm_manager+0xa38>
ffffffffc020454c:	f43fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204550:	00002617          	auipc	a2,0x2
ffffffffc0204554:	c4060613          	addi	a2,a2,-960 # ffffffffc0206190 <commands+0x630>
ffffffffc0204558:	06900593          	li	a1,105
ffffffffc020455c:	00002517          	auipc	a0,0x2
ffffffffc0204560:	c5450513          	addi	a0,a0,-940 # ffffffffc02061b0 <commands+0x650>
ffffffffc0204564:	f2bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204568:	00002617          	auipc	a2,0x2
ffffffffc020456c:	c8060613          	addi	a2,a2,-896 # ffffffffc02061e8 <commands+0x688>
ffffffffc0204570:	07100593          	li	a1,113
ffffffffc0204574:	00002517          	auipc	a0,0x2
ffffffffc0204578:	c3c50513          	addi	a0,a0,-964 # ffffffffc02061b0 <commands+0x650>
ffffffffc020457c:	f13fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204580:	86be                	mv	a3,a5
ffffffffc0204582:	00002617          	auipc	a2,0x2
ffffffffc0204586:	39660613          	addi	a2,a2,918 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc020458a:	19200593          	li	a1,402
ffffffffc020458e:	00003517          	auipc	a0,0x3
ffffffffc0204592:	cf250513          	addi	a0,a0,-782 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204596:	ef9fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc020459a:	00002617          	auipc	a2,0x2
ffffffffc020459e:	37e60613          	addi	a2,a2,894 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc02045a2:	07700593          	li	a1,119
ffffffffc02045a6:	00002517          	auipc	a0,0x2
ffffffffc02045aa:	c0a50513          	addi	a0,a0,-1014 # ffffffffc02061b0 <commands+0x650>
ffffffffc02045ae:	ee1fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02045b2 <kernel_thread>:
{
ffffffffc02045b2:	7129                	addi	sp,sp,-320
ffffffffc02045b4:	fa22                	sd	s0,304(sp)
ffffffffc02045b6:	f626                	sd	s1,296(sp)
ffffffffc02045b8:	f24a                	sd	s2,288(sp)
ffffffffc02045ba:	84ae                	mv	s1,a1
ffffffffc02045bc:	892a                	mv	s2,a0
ffffffffc02045be:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02045c0:	4581                	li	a1,0
ffffffffc02045c2:	12000613          	li	a2,288
ffffffffc02045c6:	850a                	mv	a0,sp
{
ffffffffc02045c8:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02045ca:	304010ef          	jal	ra,ffffffffc02058ce <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02045ce:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02045d0:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02045d2:	100027f3          	csrr	a5,sstatus
ffffffffc02045d6:	edd7f793          	andi	a5,a5,-291
ffffffffc02045da:	1207e793          	ori	a5,a5,288
ffffffffc02045de:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045e0:	860a                	mv	a2,sp
ffffffffc02045e2:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02045e6:	00000797          	auipc	a5,0x0
ffffffffc02045ea:	a3e78793          	addi	a5,a5,-1474 # ffffffffc0204024 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045ee:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02045f0:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045f2:	c1bff0ef          	jal	ra,ffffffffc020420c <do_fork>
}
ffffffffc02045f6:	70f2                	ld	ra,312(sp)
ffffffffc02045f8:	7452                	ld	s0,304(sp)
ffffffffc02045fa:	74b2                	ld	s1,296(sp)
ffffffffc02045fc:	7912                	ld	s2,288(sp)
ffffffffc02045fe:	6131                	addi	sp,sp,320
ffffffffc0204600:	8082                	ret

ffffffffc0204602 <do_exit>:
{
ffffffffc0204602:	7179                	addi	sp,sp,-48
ffffffffc0204604:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204606:	000b0417          	auipc	s0,0xb0
ffffffffc020460a:	5f240413          	addi	s0,s0,1522 # ffffffffc02b4bf8 <current>
ffffffffc020460e:	601c                	ld	a5,0(s0)
{
ffffffffc0204610:	f406                	sd	ra,40(sp)
ffffffffc0204612:	ec26                	sd	s1,24(sp)
ffffffffc0204614:	e84a                	sd	s2,16(sp)
ffffffffc0204616:	e44e                	sd	s3,8(sp)
ffffffffc0204618:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020461a:	000b0717          	auipc	a4,0xb0
ffffffffc020461e:	5e673703          	ld	a4,1510(a4) # ffffffffc02b4c00 <idleproc>
ffffffffc0204622:	0ce78c63          	beq	a5,a4,ffffffffc02046fa <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204626:	000b0497          	auipc	s1,0xb0
ffffffffc020462a:	5e248493          	addi	s1,s1,1506 # ffffffffc02b4c08 <initproc>
ffffffffc020462e:	6098                	ld	a4,0(s1)
ffffffffc0204630:	0ee78b63          	beq	a5,a4,ffffffffc0204726 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204634:	0287b983          	ld	s3,40(a5)
ffffffffc0204638:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020463a:	02098663          	beqz	s3,ffffffffc0204666 <do_exit+0x64>
ffffffffc020463e:	000b0797          	auipc	a5,0xb0
ffffffffc0204642:	58a7b783          	ld	a5,1418(a5) # ffffffffc02b4bc8 <boot_pgdir_pa>
ffffffffc0204646:	577d                	li	a4,-1
ffffffffc0204648:	177e                	slli	a4,a4,0x3f
ffffffffc020464a:	83b1                	srli	a5,a5,0xc
ffffffffc020464c:	8fd9                	or	a5,a5,a4
ffffffffc020464e:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204652:	0309a783          	lw	a5,48(s3)
ffffffffc0204656:	fff7871b          	addiw	a4,a5,-1
ffffffffc020465a:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020465e:	cb55                	beqz	a4,ffffffffc0204712 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204660:	601c                	ld	a5,0(s0)
ffffffffc0204662:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204666:	601c                	ld	a5,0(s0)
ffffffffc0204668:	470d                	li	a4,3
ffffffffc020466a:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020466c:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204670:	100027f3          	csrr	a5,sstatus
ffffffffc0204674:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204676:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204678:	e3f9                	bnez	a5,ffffffffc020473e <do_exit+0x13c>
        proc = current->parent;
ffffffffc020467a:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020467c:	800007b7          	lui	a5,0x80000
ffffffffc0204680:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204682:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204684:	0ec52703          	lw	a4,236(a0)
ffffffffc0204688:	0af70f63          	beq	a4,a5,ffffffffc0204746 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc020468c:	6018                	ld	a4,0(s0)
ffffffffc020468e:	7b7c                	ld	a5,240(a4)
ffffffffc0204690:	c3a1                	beqz	a5,ffffffffc02046d0 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204692:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204696:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204698:	0985                	addi	s3,s3,1
ffffffffc020469a:	a021                	j	ffffffffc02046a2 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc020469c:	6018                	ld	a4,0(s0)
ffffffffc020469e:	7b7c                	ld	a5,240(a4)
ffffffffc02046a0:	cb85                	beqz	a5,ffffffffc02046d0 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02046a2:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02046a6:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02046a8:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02046aa:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02046ac:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02046b0:	10e7b023          	sd	a4,256(a5)
ffffffffc02046b4:	c311                	beqz	a4,ffffffffc02046b8 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02046b6:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046b8:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02046ba:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02046bc:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046be:	fd271fe3          	bne	a4,s2,ffffffffc020469c <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02046c2:	0ec52783          	lw	a5,236(a0)
ffffffffc02046c6:	fd379be3          	bne	a5,s3,ffffffffc020469c <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02046ca:	373000ef          	jal	ra,ffffffffc020523c <wakeup_proc>
ffffffffc02046ce:	b7f9                	j	ffffffffc020469c <do_exit+0x9a>
    if (flag)
ffffffffc02046d0:	020a1263          	bnez	s4,ffffffffc02046f4 <do_exit+0xf2>
    schedule();
ffffffffc02046d4:	3e9000ef          	jal	ra,ffffffffc02052bc <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02046d8:	601c                	ld	a5,0(s0)
ffffffffc02046da:	00003617          	auipc	a2,0x3
ffffffffc02046de:	c0660613          	addi	a2,a2,-1018 # ffffffffc02072e0 <default_pmm_manager+0xa70>
ffffffffc02046e2:	23f00593          	li	a1,575
ffffffffc02046e6:	43d4                	lw	a3,4(a5)
ffffffffc02046e8:	00003517          	auipc	a0,0x3
ffffffffc02046ec:	b9850513          	addi	a0,a0,-1128 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc02046f0:	d9ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02046f4:	abafc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02046f8:	bff1                	j	ffffffffc02046d4 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02046fa:	00003617          	auipc	a2,0x3
ffffffffc02046fe:	bc660613          	addi	a2,a2,-1082 # ffffffffc02072c0 <default_pmm_manager+0xa50>
ffffffffc0204702:	20b00593          	li	a1,523
ffffffffc0204706:	00003517          	auipc	a0,0x3
ffffffffc020470a:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc020470e:	d81fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204712:	854e                	mv	a0,s3
ffffffffc0204714:	ce2ff0ef          	jal	ra,ffffffffc0203bf6 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204718:	854e                	mv	a0,s3
ffffffffc020471a:	a11ff0ef          	jal	ra,ffffffffc020412a <put_pgdir>
            mm_destroy(mm);
ffffffffc020471e:	854e                	mv	a0,s3
ffffffffc0204720:	b3aff0ef          	jal	ra,ffffffffc0203a5a <mm_destroy>
ffffffffc0204724:	bf35                	j	ffffffffc0204660 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204726:	00003617          	auipc	a2,0x3
ffffffffc020472a:	baa60613          	addi	a2,a2,-1110 # ffffffffc02072d0 <default_pmm_manager+0xa60>
ffffffffc020472e:	20f00593          	li	a1,527
ffffffffc0204732:	00003517          	auipc	a0,0x3
ffffffffc0204736:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc020473a:	d55fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc020473e:	a76fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204742:	4a05                	li	s4,1
ffffffffc0204744:	bf1d                	j	ffffffffc020467a <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204746:	2f7000ef          	jal	ra,ffffffffc020523c <wakeup_proc>
ffffffffc020474a:	b789                	j	ffffffffc020468c <do_exit+0x8a>

ffffffffc020474c <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc020474c:	715d                	addi	sp,sp,-80
ffffffffc020474e:	f84a                	sd	s2,48(sp)
ffffffffc0204750:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204752:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204756:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204758:	fc26                	sd	s1,56(sp)
ffffffffc020475a:	f052                	sd	s4,32(sp)
ffffffffc020475c:	ec56                	sd	s5,24(sp)
ffffffffc020475e:	e85a                	sd	s6,16(sp)
ffffffffc0204760:	e45e                	sd	s7,8(sp)
ffffffffc0204762:	e486                	sd	ra,72(sp)
ffffffffc0204764:	e0a2                	sd	s0,64(sp)
ffffffffc0204766:	84aa                	mv	s1,a0
ffffffffc0204768:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc020476a:	000b0b97          	auipc	s7,0xb0
ffffffffc020476e:	48eb8b93          	addi	s7,s7,1166 # ffffffffc02b4bf8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204772:	00050b1b          	sext.w	s6,a0
ffffffffc0204776:	fff50a9b          	addiw	s5,a0,-1
ffffffffc020477a:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020477c:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020477e:	ccbd                	beqz	s1,ffffffffc02047fc <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204780:	0359e863          	bltu	s3,s5,ffffffffc02047b0 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204784:	45a9                	li	a1,10
ffffffffc0204786:	855a                	mv	a0,s6
ffffffffc0204788:	4a1000ef          	jal	ra,ffffffffc0205428 <hash32>
ffffffffc020478c:	02051793          	slli	a5,a0,0x20
ffffffffc0204790:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204794:	000ac797          	auipc	a5,0xac
ffffffffc0204798:	3f478793          	addi	a5,a5,1012 # ffffffffc02b0b88 <hash_list>
ffffffffc020479c:	953e                	add	a0,a0,a5
ffffffffc020479e:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc02047a0:	a029                	j	ffffffffc02047aa <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc02047a2:	f2c42783          	lw	a5,-212(s0)
ffffffffc02047a6:	02978163          	beq	a5,s1,ffffffffc02047c8 <do_wait.part.0+0x7c>
ffffffffc02047aa:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc02047ac:	fe851be3          	bne	a0,s0,ffffffffc02047a2 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc02047b0:	5579                	li	a0,-2
}
ffffffffc02047b2:	60a6                	ld	ra,72(sp)
ffffffffc02047b4:	6406                	ld	s0,64(sp)
ffffffffc02047b6:	74e2                	ld	s1,56(sp)
ffffffffc02047b8:	7942                	ld	s2,48(sp)
ffffffffc02047ba:	79a2                	ld	s3,40(sp)
ffffffffc02047bc:	7a02                	ld	s4,32(sp)
ffffffffc02047be:	6ae2                	ld	s5,24(sp)
ffffffffc02047c0:	6b42                	ld	s6,16(sp)
ffffffffc02047c2:	6ba2                	ld	s7,8(sp)
ffffffffc02047c4:	6161                	addi	sp,sp,80
ffffffffc02047c6:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02047c8:	000bb683          	ld	a3,0(s7)
ffffffffc02047cc:	f4843783          	ld	a5,-184(s0)
ffffffffc02047d0:	fed790e3          	bne	a5,a3,ffffffffc02047b0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047d4:	f2842703          	lw	a4,-216(s0)
ffffffffc02047d8:	478d                	li	a5,3
ffffffffc02047da:	0ef70b63          	beq	a4,a5,ffffffffc02048d0 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02047de:	4785                	li	a5,1
ffffffffc02047e0:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02047e2:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02047e6:	2d7000ef          	jal	ra,ffffffffc02052bc <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02047ea:	000bb783          	ld	a5,0(s7)
ffffffffc02047ee:	0b07a783          	lw	a5,176(a5)
ffffffffc02047f2:	8b85                	andi	a5,a5,1
ffffffffc02047f4:	d7c9                	beqz	a5,ffffffffc020477e <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02047f6:	555d                	li	a0,-9
ffffffffc02047f8:	e0bff0ef          	jal	ra,ffffffffc0204602 <do_exit>
        proc = current->cptr;
ffffffffc02047fc:	000bb683          	ld	a3,0(s7)
ffffffffc0204800:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204802:	d45d                	beqz	s0,ffffffffc02047b0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204804:	470d                	li	a4,3
ffffffffc0204806:	a021                	j	ffffffffc020480e <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204808:	10043403          	ld	s0,256(s0)
ffffffffc020480c:	d869                	beqz	s0,ffffffffc02047de <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020480e:	401c                	lw	a5,0(s0)
ffffffffc0204810:	fee79ce3          	bne	a5,a4,ffffffffc0204808 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204814:	000b0797          	auipc	a5,0xb0
ffffffffc0204818:	3ec7b783          	ld	a5,1004(a5) # ffffffffc02b4c00 <idleproc>
ffffffffc020481c:	0c878963          	beq	a5,s0,ffffffffc02048ee <do_wait.part.0+0x1a2>
ffffffffc0204820:	000b0797          	auipc	a5,0xb0
ffffffffc0204824:	3e87b783          	ld	a5,1000(a5) # ffffffffc02b4c08 <initproc>
ffffffffc0204828:	0cf40363          	beq	s0,a5,ffffffffc02048ee <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc020482c:	000a0663          	beqz	s4,ffffffffc0204838 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204830:	0e842783          	lw	a5,232(s0)
ffffffffc0204834:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204838:	100027f3          	csrr	a5,sstatus
ffffffffc020483c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020483e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204840:	e7c1                	bnez	a5,ffffffffc02048c8 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204842:	6c70                	ld	a2,216(s0)
ffffffffc0204844:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204846:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc020484a:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc020484c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020484e:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204850:	6470                	ld	a2,200(s0)
ffffffffc0204852:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204854:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204856:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204858:	c319                	beqz	a4,ffffffffc020485e <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc020485a:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc020485c:	7c7c                	ld	a5,248(s0)
ffffffffc020485e:	c3b5                	beqz	a5,ffffffffc02048c2 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204860:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204864:	000b0717          	auipc	a4,0xb0
ffffffffc0204868:	3ac70713          	addi	a4,a4,940 # ffffffffc02b4c10 <nr_process>
ffffffffc020486c:	431c                	lw	a5,0(a4)
ffffffffc020486e:	37fd                	addiw	a5,a5,-1
ffffffffc0204870:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204872:	e5a9                	bnez	a1,ffffffffc02048bc <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204874:	6814                	ld	a3,16(s0)
ffffffffc0204876:	c02007b7          	lui	a5,0xc0200
ffffffffc020487a:	04f6ee63          	bltu	a3,a5,ffffffffc02048d6 <do_wait.part.0+0x18a>
ffffffffc020487e:	000b0797          	auipc	a5,0xb0
ffffffffc0204882:	3727b783          	ld	a5,882(a5) # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc0204886:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204888:	82b1                	srli	a3,a3,0xc
ffffffffc020488a:	000b0797          	auipc	a5,0xb0
ffffffffc020488e:	34e7b783          	ld	a5,846(a5) # ffffffffc02b4bd8 <npage>
ffffffffc0204892:	06f6fa63          	bgeu	a3,a5,ffffffffc0204906 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204896:	00003517          	auipc	a0,0x3
ffffffffc020489a:	28253503          	ld	a0,642(a0) # ffffffffc0207b18 <nbase>
ffffffffc020489e:	8e89                	sub	a3,a3,a0
ffffffffc02048a0:	069a                	slli	a3,a3,0x6
ffffffffc02048a2:	000b0517          	auipc	a0,0xb0
ffffffffc02048a6:	33e53503          	ld	a0,830(a0) # ffffffffc02b4be0 <pages>
ffffffffc02048aa:	9536                	add	a0,a0,a3
ffffffffc02048ac:	4589                	li	a1,2
ffffffffc02048ae:	81dfd0ef          	jal	ra,ffffffffc02020ca <free_pages>
    kfree(proc);// 释放子进程的进程控制块(PCB)本身
ffffffffc02048b2:	8522                	mv	a0,s0
ffffffffc02048b4:	eaafd0ef          	jal	ra,ffffffffc0201f5e <kfree>
    return 0;
ffffffffc02048b8:	4501                	li	a0,0
ffffffffc02048ba:	bde5                	j	ffffffffc02047b2 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02048bc:	8f2fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02048c0:	bf55                	j	ffffffffc0204874 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02048c2:	701c                	ld	a5,32(s0)
ffffffffc02048c4:	fbf8                	sd	a4,240(a5)
ffffffffc02048c6:	bf79                	j	ffffffffc0204864 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02048c8:	8ecfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02048cc:	4585                	li	a1,1
ffffffffc02048ce:	bf95                	j	ffffffffc0204842 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02048d0:	f2840413          	addi	s0,s0,-216
ffffffffc02048d4:	b781                	j	ffffffffc0204814 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02048d6:	00002617          	auipc	a2,0x2
ffffffffc02048da:	04260613          	addi	a2,a2,66 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc02048de:	07700593          	li	a1,119
ffffffffc02048e2:	00002517          	auipc	a0,0x2
ffffffffc02048e6:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02061b0 <commands+0x650>
ffffffffc02048ea:	ba5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02048ee:	00003617          	auipc	a2,0x3
ffffffffc02048f2:	a1260613          	addi	a2,a2,-1518 # ffffffffc0207300 <default_pmm_manager+0xa90>
ffffffffc02048f6:	36000593          	li	a1,864
ffffffffc02048fa:	00003517          	auipc	a0,0x3
ffffffffc02048fe:	98650513          	addi	a0,a0,-1658 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204902:	b8dfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204906:	00002617          	auipc	a2,0x2
ffffffffc020490a:	88a60613          	addi	a2,a2,-1910 # ffffffffc0206190 <commands+0x630>
ffffffffc020490e:	06900593          	li	a1,105
ffffffffc0204912:	00002517          	auipc	a0,0x2
ffffffffc0204916:	89e50513          	addi	a0,a0,-1890 # ffffffffc02061b0 <commands+0x650>
ffffffffc020491a:	b75fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020491e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020491e:	1141                	addi	sp,sp,-16
ffffffffc0204920:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204922:	fe8fd0ef          	jal	ra,ffffffffc020210a <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204926:	d84fd0ef          	jal	ra,ffffffffc0201eaa <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020492a:	4601                	li	a2,0
ffffffffc020492c:	4581                	li	a1,0
ffffffffc020492e:	fffff517          	auipc	a0,0xfffff
ffffffffc0204932:	77e50513          	addi	a0,a0,1918 # ffffffffc02040ac <user_main>
ffffffffc0204936:	c7dff0ef          	jal	ra,ffffffffc02045b2 <kernel_thread>
    if (pid <= 0)
ffffffffc020493a:	00a04563          	bgtz	a0,ffffffffc0204944 <init_main+0x26>
ffffffffc020493e:	a071                	j	ffffffffc02049ca <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204940:	17d000ef          	jal	ra,ffffffffc02052bc <schedule>
    if (code_store != NULL)
ffffffffc0204944:	4581                	li	a1,0
ffffffffc0204946:	4501                	li	a0,0
ffffffffc0204948:	e05ff0ef          	jal	ra,ffffffffc020474c <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc020494c:	d975                	beqz	a0,ffffffffc0204940 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020494e:	00003517          	auipc	a0,0x3
ffffffffc0204952:	9f250513          	addi	a0,a0,-1550 # ffffffffc0207340 <default_pmm_manager+0xad0>
ffffffffc0204956:	83ffb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020495a:	000b0797          	auipc	a5,0xb0
ffffffffc020495e:	2ae7b783          	ld	a5,686(a5) # ffffffffc02b4c08 <initproc>
ffffffffc0204962:	7bf8                	ld	a4,240(a5)
ffffffffc0204964:	e339                	bnez	a4,ffffffffc02049aa <init_main+0x8c>
ffffffffc0204966:	7ff8                	ld	a4,248(a5)
ffffffffc0204968:	e329                	bnez	a4,ffffffffc02049aa <init_main+0x8c>
ffffffffc020496a:	1007b703          	ld	a4,256(a5)
ffffffffc020496e:	ef15                	bnez	a4,ffffffffc02049aa <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204970:	000b0697          	auipc	a3,0xb0
ffffffffc0204974:	2a06a683          	lw	a3,672(a3) # ffffffffc02b4c10 <nr_process>
ffffffffc0204978:	4709                	li	a4,2
ffffffffc020497a:	0ae69463          	bne	a3,a4,ffffffffc0204a22 <init_main+0x104>
    return listelm->next;
ffffffffc020497e:	000b0697          	auipc	a3,0xb0
ffffffffc0204982:	20a68693          	addi	a3,a3,522 # ffffffffc02b4b88 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204986:	6698                	ld	a4,8(a3)
ffffffffc0204988:	0c878793          	addi	a5,a5,200
ffffffffc020498c:	06f71b63          	bne	a4,a5,ffffffffc0204a02 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204990:	629c                	ld	a5,0(a3)
ffffffffc0204992:	04f71863          	bne	a4,a5,ffffffffc02049e2 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204996:	00003517          	auipc	a0,0x3
ffffffffc020499a:	a9250513          	addi	a0,a0,-1390 # ffffffffc0207428 <default_pmm_manager+0xbb8>
ffffffffc020499e:	ff6fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02049a2:	60a2                	ld	ra,8(sp)
ffffffffc02049a4:	4501                	li	a0,0
ffffffffc02049a6:	0141                	addi	sp,sp,16
ffffffffc02049a8:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02049aa:	00003697          	auipc	a3,0x3
ffffffffc02049ae:	9be68693          	addi	a3,a3,-1602 # ffffffffc0207368 <default_pmm_manager+0xaf8>
ffffffffc02049b2:	00002617          	auipc	a2,0x2
ffffffffc02049b6:	b0e60613          	addi	a2,a2,-1266 # ffffffffc02064c0 <commands+0x960>
ffffffffc02049ba:	3ce00593          	li	a1,974
ffffffffc02049be:	00003517          	auipc	a0,0x3
ffffffffc02049c2:	8c250513          	addi	a0,a0,-1854 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc02049c6:	ac9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc02049ca:	00003617          	auipc	a2,0x3
ffffffffc02049ce:	95660613          	addi	a2,a2,-1706 # ffffffffc0207320 <default_pmm_manager+0xab0>
ffffffffc02049d2:	3c500593          	li	a1,965
ffffffffc02049d6:	00003517          	auipc	a0,0x3
ffffffffc02049da:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc02049de:	ab1fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02049e2:	00003697          	auipc	a3,0x3
ffffffffc02049e6:	a1668693          	addi	a3,a3,-1514 # ffffffffc02073f8 <default_pmm_manager+0xb88>
ffffffffc02049ea:	00002617          	auipc	a2,0x2
ffffffffc02049ee:	ad660613          	addi	a2,a2,-1322 # ffffffffc02064c0 <commands+0x960>
ffffffffc02049f2:	3d100593          	li	a1,977
ffffffffc02049f6:	00003517          	auipc	a0,0x3
ffffffffc02049fa:	88a50513          	addi	a0,a0,-1910 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc02049fe:	a91fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204a02:	00003697          	auipc	a3,0x3
ffffffffc0204a06:	9c668693          	addi	a3,a3,-1594 # ffffffffc02073c8 <default_pmm_manager+0xb58>
ffffffffc0204a0a:	00002617          	auipc	a2,0x2
ffffffffc0204a0e:	ab660613          	addi	a2,a2,-1354 # ffffffffc02064c0 <commands+0x960>
ffffffffc0204a12:	3d000593          	li	a1,976
ffffffffc0204a16:	00003517          	auipc	a0,0x3
ffffffffc0204a1a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204a1e:	a71fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204a22:	00003697          	auipc	a3,0x3
ffffffffc0204a26:	99668693          	addi	a3,a3,-1642 # ffffffffc02073b8 <default_pmm_manager+0xb48>
ffffffffc0204a2a:	00002617          	auipc	a2,0x2
ffffffffc0204a2e:	a9660613          	addi	a2,a2,-1386 # ffffffffc02064c0 <commands+0x960>
ffffffffc0204a32:	3cf00593          	li	a1,975
ffffffffc0204a36:	00003517          	auipc	a0,0x3
ffffffffc0204a3a:	84a50513          	addi	a0,a0,-1974 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204a3e:	a51fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204a42 <do_execve>:
{
ffffffffc0204a42:	7171                	addi	sp,sp,-176
ffffffffc0204a44:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204a46:	000b0d97          	auipc	s11,0xb0
ffffffffc0204a4a:	1b2d8d93          	addi	s11,s11,434 # ffffffffc02b4bf8 <current>
ffffffffc0204a4e:	000db783          	ld	a5,0(s11)
{
ffffffffc0204a52:	e54e                	sd	s3,136(sp)
ffffffffc0204a54:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204a56:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204a5a:	e94a                	sd	s2,144(sp)
ffffffffc0204a5c:	f4de                	sd	s7,104(sp)
ffffffffc0204a5e:	892a                	mv	s2,a0
ffffffffc0204a60:	8bb2                	mv	s7,a2
ffffffffc0204a62:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204a64:	862e                	mv	a2,a1
ffffffffc0204a66:	4681                	li	a3,0
ffffffffc0204a68:	85aa                	mv	a1,a0
ffffffffc0204a6a:	854e                	mv	a0,s3
{
ffffffffc0204a6c:	f506                	sd	ra,168(sp)
ffffffffc0204a6e:	f122                	sd	s0,160(sp)
ffffffffc0204a70:	e152                	sd	s4,128(sp)
ffffffffc0204a72:	fcd6                	sd	s5,120(sp)
ffffffffc0204a74:	f8da                	sd	s6,112(sp)
ffffffffc0204a76:	f0e2                	sd	s8,96(sp)
ffffffffc0204a78:	ece6                	sd	s9,88(sp)
ffffffffc0204a7a:	e8ea                	sd	s10,80(sp)
ffffffffc0204a7c:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204a7e:	d12ff0ef          	jal	ra,ffffffffc0203f90 <user_mem_check>
ffffffffc0204a82:	40050a63          	beqz	a0,ffffffffc0204e96 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204a86:	4641                	li	a2,16
ffffffffc0204a88:	4581                	li	a1,0
ffffffffc0204a8a:	1808                	addi	a0,sp,48
ffffffffc0204a8c:	643000ef          	jal	ra,ffffffffc02058ce <memset>
    memcpy(local_name, name, len);
ffffffffc0204a90:	47bd                	li	a5,15
ffffffffc0204a92:	8626                	mv	a2,s1
ffffffffc0204a94:	1e97e263          	bltu	a5,s1,ffffffffc0204c78 <do_execve+0x236>
ffffffffc0204a98:	85ca                	mv	a1,s2
ffffffffc0204a9a:	1808                	addi	a0,sp,48
ffffffffc0204a9c:	645000ef          	jal	ra,ffffffffc02058e0 <memcpy>
    if (mm != NULL)
ffffffffc0204aa0:	1e098363          	beqz	s3,ffffffffc0204c86 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204aa4:	00002517          	auipc	a0,0x2
ffffffffc0204aa8:	5a450513          	addi	a0,a0,1444 # ffffffffc0207048 <default_pmm_manager+0x7d8>
ffffffffc0204aac:	f20fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204ab0:	000b0797          	auipc	a5,0xb0
ffffffffc0204ab4:	1187b783          	ld	a5,280(a5) # ffffffffc02b4bc8 <boot_pgdir_pa>
ffffffffc0204ab8:	577d                	li	a4,-1
ffffffffc0204aba:	177e                	slli	a4,a4,0x3f
ffffffffc0204abc:	83b1                	srli	a5,a5,0xc
ffffffffc0204abe:	8fd9                	or	a5,a5,a4
ffffffffc0204ac0:	18079073          	csrw	satp,a5
ffffffffc0204ac4:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b88>
ffffffffc0204ac8:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204acc:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204ad0:	2c070463          	beqz	a4,ffffffffc0204d98 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204ad4:	000db783          	ld	a5,0(s11)
ffffffffc0204ad8:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204adc:	e3ffe0ef          	jal	ra,ffffffffc020391a <mm_create>
ffffffffc0204ae0:	84aa                	mv	s1,a0
ffffffffc0204ae2:	1c050d63          	beqz	a0,ffffffffc0204cbc <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204ae6:	4505                	li	a0,1
ffffffffc0204ae8:	da4fd0ef          	jal	ra,ffffffffc020208c <alloc_pages>
ffffffffc0204aec:	3a050963          	beqz	a0,ffffffffc0204e9e <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204af0:	000b0c97          	auipc	s9,0xb0
ffffffffc0204af4:	0f0c8c93          	addi	s9,s9,240 # ffffffffc02b4be0 <pages>
ffffffffc0204af8:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204afc:	000b0c17          	auipc	s8,0xb0
ffffffffc0204b00:	0dcc0c13          	addi	s8,s8,220 # ffffffffc02b4bd8 <npage>
    return page - pages + nbase;
ffffffffc0204b04:	00003717          	auipc	a4,0x3
ffffffffc0204b08:	01473703          	ld	a4,20(a4) # ffffffffc0207b18 <nbase>
ffffffffc0204b0c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204b10:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204b12:	5afd                	li	s5,-1
ffffffffc0204b14:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204b18:	96ba                	add	a3,a3,a4
ffffffffc0204b1a:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b1c:	00cad713          	srli	a4,s5,0xc
ffffffffc0204b20:	ec3a                	sd	a4,24(sp)
ffffffffc0204b22:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b24:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b26:	38f77063          	bgeu	a4,a5,ffffffffc0204ea6 <do_execve+0x464>
ffffffffc0204b2a:	000b0b17          	auipc	s6,0xb0
ffffffffc0204b2e:	0c6b0b13          	addi	s6,s6,198 # ffffffffc02b4bf0 <va_pa_offset>
ffffffffc0204b32:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204b36:	6605                	lui	a2,0x1
ffffffffc0204b38:	000b0597          	auipc	a1,0xb0
ffffffffc0204b3c:	0985b583          	ld	a1,152(a1) # ffffffffc02b4bd0 <boot_pgdir_va>
ffffffffc0204b40:	9936                	add	s2,s2,a3
ffffffffc0204b42:	854a                	mv	a0,s2
ffffffffc0204b44:	59d000ef          	jal	ra,ffffffffc02058e0 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204b48:	7782                	ld	a5,32(sp)
ffffffffc0204b4a:	4398                	lw	a4,0(a5)
ffffffffc0204b4c:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204b50:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204b54:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b944f>
ffffffffc0204b58:	14f71863          	bne	a4,a5,ffffffffc0204ca8 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b5c:	7682                	ld	a3,32(sp)
ffffffffc0204b5e:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204b62:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b66:	00371793          	slli	a5,a4,0x3
ffffffffc0204b6a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204b6c:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b6e:	078e                	slli	a5,a5,0x3
ffffffffc0204b70:	97ce                	add	a5,a5,s3
ffffffffc0204b72:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204b74:	00f9fc63          	bgeu	s3,a5,ffffffffc0204b8c <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204b78:	0009a783          	lw	a5,0(s3)
ffffffffc0204b7c:	4705                	li	a4,1
ffffffffc0204b7e:	14e78163          	beq	a5,a4,ffffffffc0204cc0 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204b82:	77a2                	ld	a5,40(sp)
ffffffffc0204b84:	03898993          	addi	s3,s3,56
ffffffffc0204b88:	fef9e8e3          	bltu	s3,a5,ffffffffc0204b78 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204b8c:	4701                	li	a4,0
ffffffffc0204b8e:	46ad                	li	a3,11
ffffffffc0204b90:	00100637          	lui	a2,0x100
ffffffffc0204b94:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204b98:	8526                	mv	a0,s1
ffffffffc0204b9a:	f13fe0ef          	jal	ra,ffffffffc0203aac <mm_map>
ffffffffc0204b9e:	8a2a                	mv	s4,a0
ffffffffc0204ba0:	1e051263          	bnez	a0,ffffffffc0204d84 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ba4:	6c88                	ld	a0,24(s1)
ffffffffc0204ba6:	467d                	li	a2,31
ffffffffc0204ba8:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204bac:	c89fe0ef          	jal	ra,ffffffffc0203834 <pgdir_alloc_page>
ffffffffc0204bb0:	38050363          	beqz	a0,ffffffffc0204f36 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bb4:	6c88                	ld	a0,24(s1)
ffffffffc0204bb6:	467d                	li	a2,31
ffffffffc0204bb8:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204bbc:	c79fe0ef          	jal	ra,ffffffffc0203834 <pgdir_alloc_page>
ffffffffc0204bc0:	34050b63          	beqz	a0,ffffffffc0204f16 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bc4:	6c88                	ld	a0,24(s1)
ffffffffc0204bc6:	467d                	li	a2,31
ffffffffc0204bc8:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204bcc:	c69fe0ef          	jal	ra,ffffffffc0203834 <pgdir_alloc_page>
ffffffffc0204bd0:	32050363          	beqz	a0,ffffffffc0204ef6 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bd4:	6c88                	ld	a0,24(s1)
ffffffffc0204bd6:	467d                	li	a2,31
ffffffffc0204bd8:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204bdc:	c59fe0ef          	jal	ra,ffffffffc0203834 <pgdir_alloc_page>
ffffffffc0204be0:	2e050b63          	beqz	a0,ffffffffc0204ed6 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204be4:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204be6:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204bea:	6c94                	ld	a3,24(s1)
ffffffffc0204bec:	2785                	addiw	a5,a5,1
ffffffffc0204bee:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204bf0:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204bf2:	c02007b7          	lui	a5,0xc0200
ffffffffc0204bf6:	2cf6e463          	bltu	a3,a5,ffffffffc0204ebe <do_execve+0x47c>
ffffffffc0204bfa:	000b3783          	ld	a5,0(s6)
ffffffffc0204bfe:	577d                	li	a4,-1
ffffffffc0204c00:	177e                	slli	a4,a4,0x3f
ffffffffc0204c02:	8e9d                	sub	a3,a3,a5
ffffffffc0204c04:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204c08:	f654                	sd	a3,168(a2)
ffffffffc0204c0a:	8fd9                	or	a5,a5,a4
ffffffffc0204c0c:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204c10:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204c12:	4581                	li	a1,0
ffffffffc0204c14:	12000613          	li	a2,288
ffffffffc0204c18:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204c1a:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204c1e:	4b1000ef          	jal	ra,ffffffffc02058ce <memset>
    tf->epc = elf->e_entry;
ffffffffc0204c22:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204c24:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204c28:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204c2c:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204c2e:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204c30:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f84>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204c34:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204c36:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204c3a:	4641                	li	a2,16
ffffffffc0204c3c:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204c3e:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204c40:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204c44:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204c48:	854a                	mv	a0,s2
ffffffffc0204c4a:	485000ef          	jal	ra,ffffffffc02058ce <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204c4e:	463d                	li	a2,15
ffffffffc0204c50:	180c                	addi	a1,sp,48
ffffffffc0204c52:	854a                	mv	a0,s2
ffffffffc0204c54:	48d000ef          	jal	ra,ffffffffc02058e0 <memcpy>
}
ffffffffc0204c58:	70aa                	ld	ra,168(sp)
ffffffffc0204c5a:	740a                	ld	s0,160(sp)
ffffffffc0204c5c:	64ea                	ld	s1,152(sp)
ffffffffc0204c5e:	694a                	ld	s2,144(sp)
ffffffffc0204c60:	69aa                	ld	s3,136(sp)
ffffffffc0204c62:	7ae6                	ld	s5,120(sp)
ffffffffc0204c64:	7b46                	ld	s6,112(sp)
ffffffffc0204c66:	7ba6                	ld	s7,104(sp)
ffffffffc0204c68:	7c06                	ld	s8,96(sp)
ffffffffc0204c6a:	6ce6                	ld	s9,88(sp)
ffffffffc0204c6c:	6d46                	ld	s10,80(sp)
ffffffffc0204c6e:	6da6                	ld	s11,72(sp)
ffffffffc0204c70:	8552                	mv	a0,s4
ffffffffc0204c72:	6a0a                	ld	s4,128(sp)
ffffffffc0204c74:	614d                	addi	sp,sp,176
ffffffffc0204c76:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204c78:	463d                	li	a2,15
ffffffffc0204c7a:	85ca                	mv	a1,s2
ffffffffc0204c7c:	1808                	addi	a0,sp,48
ffffffffc0204c7e:	463000ef          	jal	ra,ffffffffc02058e0 <memcpy>
    if (mm != NULL)
ffffffffc0204c82:	e20991e3          	bnez	s3,ffffffffc0204aa4 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204c86:	000db783          	ld	a5,0(s11)
ffffffffc0204c8a:	779c                	ld	a5,40(a5)
ffffffffc0204c8c:	e40788e3          	beqz	a5,ffffffffc0204adc <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204c90:	00002617          	auipc	a2,0x2
ffffffffc0204c94:	7b860613          	addi	a2,a2,1976 # ffffffffc0207448 <default_pmm_manager+0xbd8>
ffffffffc0204c98:	24b00593          	li	a1,587
ffffffffc0204c9c:	00002517          	auipc	a0,0x2
ffffffffc0204ca0:	5e450513          	addi	a0,a0,1508 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204ca4:	feafb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204ca8:	8526                	mv	a0,s1
ffffffffc0204caa:	c80ff0ef          	jal	ra,ffffffffc020412a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204cae:	8526                	mv	a0,s1
ffffffffc0204cb0:	dabfe0ef          	jal	ra,ffffffffc0203a5a <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204cb4:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204cb6:	8552                	mv	a0,s4
ffffffffc0204cb8:	94bff0ef          	jal	ra,ffffffffc0204602 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204cbc:	5a71                	li	s4,-4
ffffffffc0204cbe:	bfe5                	j	ffffffffc0204cb6 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204cc0:	0289b603          	ld	a2,40(s3)
ffffffffc0204cc4:	0209b783          	ld	a5,32(s3)
ffffffffc0204cc8:	1cf66d63          	bltu	a2,a5,ffffffffc0204ea2 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204ccc:	0049a783          	lw	a5,4(s3)
ffffffffc0204cd0:	0017f693          	andi	a3,a5,1
ffffffffc0204cd4:	c291                	beqz	a3,ffffffffc0204cd8 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204cd6:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204cd8:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204cdc:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204cde:	e779                	bnez	a4,ffffffffc0204dac <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204ce0:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ce2:	c781                	beqz	a5,ffffffffc0204cea <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204ce4:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204ce8:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204cea:	0026f793          	andi	a5,a3,2
ffffffffc0204cee:	e3f1                	bnez	a5,ffffffffc0204db2 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204cf0:	0046f793          	andi	a5,a3,4
ffffffffc0204cf4:	c399                	beqz	a5,ffffffffc0204cfa <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204cf6:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204cfa:	0109b583          	ld	a1,16(s3)
ffffffffc0204cfe:	4701                	li	a4,0
ffffffffc0204d00:	8526                	mv	a0,s1
ffffffffc0204d02:	dabfe0ef          	jal	ra,ffffffffc0203aac <mm_map>
ffffffffc0204d06:	8a2a                	mv	s4,a0
ffffffffc0204d08:	ed35                	bnez	a0,ffffffffc0204d84 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204d0a:	0109bb83          	ld	s7,16(s3)
ffffffffc0204d0e:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204d10:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204d14:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204d18:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204d1c:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204d1e:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204d20:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204d22:	054be963          	bltu	s7,s4,ffffffffc0204d74 <do_execve+0x332>
ffffffffc0204d26:	aa95                	j	ffffffffc0204e9a <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d28:	6785                	lui	a5,0x1
ffffffffc0204d2a:	415b8533          	sub	a0,s7,s5
ffffffffc0204d2e:	9abe                	add	s5,s5,a5
ffffffffc0204d30:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204d34:	015a7463          	bgeu	s4,s5,ffffffffc0204d3c <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204d38:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204d3c:	000cb683          	ld	a3,0(s9)
ffffffffc0204d40:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d42:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204d46:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d4a:	8699                	srai	a3,a3,0x6
ffffffffc0204d4c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d4e:	67e2                	ld	a5,24(sp)
ffffffffc0204d50:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d54:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d56:	14b87863          	bgeu	a6,a1,ffffffffc0204ea6 <do_execve+0x464>
ffffffffc0204d5a:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d5e:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204d60:	9bb2                	add	s7,s7,a2
ffffffffc0204d62:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d64:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204d66:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d68:	379000ef          	jal	ra,ffffffffc02058e0 <memcpy>
            start += size, from += size;
ffffffffc0204d6c:	6622                	ld	a2,8(sp)
ffffffffc0204d6e:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204d70:	054bf363          	bgeu	s7,s4,ffffffffc0204db6 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d74:	6c88                	ld	a0,24(s1)
ffffffffc0204d76:	866a                	mv	a2,s10
ffffffffc0204d78:	85d6                	mv	a1,s5
ffffffffc0204d7a:	abbfe0ef          	jal	ra,ffffffffc0203834 <pgdir_alloc_page>
ffffffffc0204d7e:	842a                	mv	s0,a0
ffffffffc0204d80:	f545                	bnez	a0,ffffffffc0204d28 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204d82:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204d84:	8526                	mv	a0,s1
ffffffffc0204d86:	e71fe0ef          	jal	ra,ffffffffc0203bf6 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204d8a:	8526                	mv	a0,s1
ffffffffc0204d8c:	b9eff0ef          	jal	ra,ffffffffc020412a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204d90:	8526                	mv	a0,s1
ffffffffc0204d92:	cc9fe0ef          	jal	ra,ffffffffc0203a5a <mm_destroy>
    return ret;
ffffffffc0204d96:	b705                	j	ffffffffc0204cb6 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204d98:	854e                	mv	a0,s3
ffffffffc0204d9a:	e5dfe0ef          	jal	ra,ffffffffc0203bf6 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d9e:	854e                	mv	a0,s3
ffffffffc0204da0:	b8aff0ef          	jal	ra,ffffffffc020412a <put_pgdir>
            mm_destroy(mm);
ffffffffc0204da4:	854e                	mv	a0,s3
ffffffffc0204da6:	cb5fe0ef          	jal	ra,ffffffffc0203a5a <mm_destroy>
ffffffffc0204daa:	b32d                	j	ffffffffc0204ad4 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204dac:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204db0:	fb95                	bnez	a5,ffffffffc0204ce4 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204db2:	4d5d                	li	s10,23
ffffffffc0204db4:	bf35                	j	ffffffffc0204cf0 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204db6:	0109b683          	ld	a3,16(s3)
ffffffffc0204dba:	0289b903          	ld	s2,40(s3)
ffffffffc0204dbe:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204dc0:	075bfd63          	bgeu	s7,s5,ffffffffc0204e3a <do_execve+0x3f8>
            if (start == end)
ffffffffc0204dc4:	db790fe3          	beq	s2,s7,ffffffffc0204b82 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204dc8:	6785                	lui	a5,0x1
ffffffffc0204dca:	00fb8533          	add	a0,s7,a5
ffffffffc0204dce:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204dd2:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204dd6:	0b597d63          	bgeu	s2,s5,ffffffffc0204e90 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204dda:	000cb683          	ld	a3,0(s9)
ffffffffc0204dde:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204de0:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204de4:	40d406b3          	sub	a3,s0,a3
ffffffffc0204de8:	8699                	srai	a3,a3,0x6
ffffffffc0204dea:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204dec:	67e2                	ld	a5,24(sp)
ffffffffc0204dee:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204df2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204df4:	0ac5f963          	bgeu	a1,a2,ffffffffc0204ea6 <do_execve+0x464>
ffffffffc0204df8:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204dfc:	8652                	mv	a2,s4
ffffffffc0204dfe:	4581                	li	a1,0
ffffffffc0204e00:	96c2                	add	a3,a3,a6
ffffffffc0204e02:	9536                	add	a0,a0,a3
ffffffffc0204e04:	2cb000ef          	jal	ra,ffffffffc02058ce <memset>
            start += size;
ffffffffc0204e08:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204e0c:	03597463          	bgeu	s2,s5,ffffffffc0204e34 <do_execve+0x3f2>
ffffffffc0204e10:	d6e909e3          	beq	s2,a4,ffffffffc0204b82 <do_execve+0x140>
ffffffffc0204e14:	00002697          	auipc	a3,0x2
ffffffffc0204e18:	65c68693          	addi	a3,a3,1628 # ffffffffc0207470 <default_pmm_manager+0xc00>
ffffffffc0204e1c:	00001617          	auipc	a2,0x1
ffffffffc0204e20:	6a460613          	addi	a2,a2,1700 # ffffffffc02064c0 <commands+0x960>
ffffffffc0204e24:	2b400593          	li	a1,692
ffffffffc0204e28:	00002517          	auipc	a0,0x2
ffffffffc0204e2c:	45850513          	addi	a0,a0,1112 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204e30:	e5efb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204e34:	ff5710e3          	bne	a4,s5,ffffffffc0204e14 <do_execve+0x3d2>
ffffffffc0204e38:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204e3a:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204b82 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204e3e:	6c88                	ld	a0,24(s1)
ffffffffc0204e40:	866a                	mv	a2,s10
ffffffffc0204e42:	85d6                	mv	a1,s5
ffffffffc0204e44:	9f1fe0ef          	jal	ra,ffffffffc0203834 <pgdir_alloc_page>
ffffffffc0204e48:	842a                	mv	s0,a0
ffffffffc0204e4a:	dd05                	beqz	a0,ffffffffc0204d82 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204e4c:	6785                	lui	a5,0x1
ffffffffc0204e4e:	415b8533          	sub	a0,s7,s5
ffffffffc0204e52:	9abe                	add	s5,s5,a5
ffffffffc0204e54:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204e58:	01597463          	bgeu	s2,s5,ffffffffc0204e60 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204e5c:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204e60:	000cb683          	ld	a3,0(s9)
ffffffffc0204e64:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204e66:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204e6a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204e6e:	8699                	srai	a3,a3,0x6
ffffffffc0204e70:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204e72:	67e2                	ld	a5,24(sp)
ffffffffc0204e74:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e78:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e7a:	02b87663          	bgeu	a6,a1,ffffffffc0204ea6 <do_execve+0x464>
ffffffffc0204e7e:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e82:	4581                	li	a1,0
            start += size;
ffffffffc0204e84:	9bb2                	add	s7,s7,a2
ffffffffc0204e86:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e88:	9536                	add	a0,a0,a3
ffffffffc0204e8a:	245000ef          	jal	ra,ffffffffc02058ce <memset>
ffffffffc0204e8e:	b775                	j	ffffffffc0204e3a <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e90:	417a8a33          	sub	s4,s5,s7
ffffffffc0204e94:	b799                	j	ffffffffc0204dda <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204e96:	5a75                	li	s4,-3
ffffffffc0204e98:	b3c1                	j	ffffffffc0204c58 <do_execve+0x216>
        while (start < end)
ffffffffc0204e9a:	86de                	mv	a3,s7
ffffffffc0204e9c:	bf39                	j	ffffffffc0204dba <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204e9e:	5a71                	li	s4,-4
ffffffffc0204ea0:	bdc5                	j	ffffffffc0204d90 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204ea2:	5a61                	li	s4,-8
ffffffffc0204ea4:	b5c5                	j	ffffffffc0204d84 <do_execve+0x342>
ffffffffc0204ea6:	00001617          	auipc	a2,0x1
ffffffffc0204eaa:	34260613          	addi	a2,a2,834 # ffffffffc02061e8 <commands+0x688>
ffffffffc0204eae:	07100593          	li	a1,113
ffffffffc0204eb2:	00001517          	auipc	a0,0x1
ffffffffc0204eb6:	2fe50513          	addi	a0,a0,766 # ffffffffc02061b0 <commands+0x650>
ffffffffc0204eba:	dd4fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204ebe:	00002617          	auipc	a2,0x2
ffffffffc0204ec2:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0206918 <default_pmm_manager+0xa8>
ffffffffc0204ec6:	2d300593          	li	a1,723
ffffffffc0204eca:	00002517          	auipc	a0,0x2
ffffffffc0204ece:	3b650513          	addi	a0,a0,950 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204ed2:	dbcfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ed6:	00002697          	auipc	a3,0x2
ffffffffc0204eda:	6b268693          	addi	a3,a3,1714 # ffffffffc0207588 <default_pmm_manager+0xd18>
ffffffffc0204ede:	00001617          	auipc	a2,0x1
ffffffffc0204ee2:	5e260613          	addi	a2,a2,1506 # ffffffffc02064c0 <commands+0x960>
ffffffffc0204ee6:	2ce00593          	li	a1,718
ffffffffc0204eea:	00002517          	auipc	a0,0x2
ffffffffc0204eee:	39650513          	addi	a0,a0,918 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204ef2:	d9cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ef6:	00002697          	auipc	a3,0x2
ffffffffc0204efa:	64a68693          	addi	a3,a3,1610 # ffffffffc0207540 <default_pmm_manager+0xcd0>
ffffffffc0204efe:	00001617          	auipc	a2,0x1
ffffffffc0204f02:	5c260613          	addi	a2,a2,1474 # ffffffffc02064c0 <commands+0x960>
ffffffffc0204f06:	2cd00593          	li	a1,717
ffffffffc0204f0a:	00002517          	auipc	a0,0x2
ffffffffc0204f0e:	37650513          	addi	a0,a0,886 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204f12:	d7cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204f16:	00002697          	auipc	a3,0x2
ffffffffc0204f1a:	5e268693          	addi	a3,a3,1506 # ffffffffc02074f8 <default_pmm_manager+0xc88>
ffffffffc0204f1e:	00001617          	auipc	a2,0x1
ffffffffc0204f22:	5a260613          	addi	a2,a2,1442 # ffffffffc02064c0 <commands+0x960>
ffffffffc0204f26:	2cc00593          	li	a1,716
ffffffffc0204f2a:	00002517          	auipc	a0,0x2
ffffffffc0204f2e:	35650513          	addi	a0,a0,854 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204f32:	d5cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204f36:	00002697          	auipc	a3,0x2
ffffffffc0204f3a:	57a68693          	addi	a3,a3,1402 # ffffffffc02074b0 <default_pmm_manager+0xc40>
ffffffffc0204f3e:	00001617          	auipc	a2,0x1
ffffffffc0204f42:	58260613          	addi	a2,a2,1410 # ffffffffc02064c0 <commands+0x960>
ffffffffc0204f46:	2cb00593          	li	a1,715
ffffffffc0204f4a:	00002517          	auipc	a0,0x2
ffffffffc0204f4e:	33650513          	addi	a0,a0,822 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0204f52:	d3cfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204f56 <do_yield>:
    current->need_resched = 1;
ffffffffc0204f56:	000b0797          	auipc	a5,0xb0
ffffffffc0204f5a:	ca27b783          	ld	a5,-862(a5) # ffffffffc02b4bf8 <current>
ffffffffc0204f5e:	4705                	li	a4,1
ffffffffc0204f60:	ef98                	sd	a4,24(a5)
}
ffffffffc0204f62:	4501                	li	a0,0
ffffffffc0204f64:	8082                	ret

ffffffffc0204f66 <do_wait>:
{
ffffffffc0204f66:	1101                	addi	sp,sp,-32
ffffffffc0204f68:	e822                	sd	s0,16(sp)
ffffffffc0204f6a:	e426                	sd	s1,8(sp)
ffffffffc0204f6c:	ec06                	sd	ra,24(sp)
ffffffffc0204f6e:	842e                	mv	s0,a1
ffffffffc0204f70:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204f72:	c999                	beqz	a1,ffffffffc0204f88 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204f74:	000b0797          	auipc	a5,0xb0
ffffffffc0204f78:	c847b783          	ld	a5,-892(a5) # ffffffffc02b4bf8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f7c:	7788                	ld	a0,40(a5)
ffffffffc0204f7e:	4685                	li	a3,1
ffffffffc0204f80:	4611                	li	a2,4
ffffffffc0204f82:	80eff0ef          	jal	ra,ffffffffc0203f90 <user_mem_check>
ffffffffc0204f86:	c909                	beqz	a0,ffffffffc0204f98 <do_wait+0x32>
ffffffffc0204f88:	85a2                	mv	a1,s0
}
ffffffffc0204f8a:	6442                	ld	s0,16(sp)
ffffffffc0204f8c:	60e2                	ld	ra,24(sp)
ffffffffc0204f8e:	8526                	mv	a0,s1
ffffffffc0204f90:	64a2                	ld	s1,8(sp)
ffffffffc0204f92:	6105                	addi	sp,sp,32
ffffffffc0204f94:	fb8ff06f          	j	ffffffffc020474c <do_wait.part.0>
ffffffffc0204f98:	60e2                	ld	ra,24(sp)
ffffffffc0204f9a:	6442                	ld	s0,16(sp)
ffffffffc0204f9c:	64a2                	ld	s1,8(sp)
ffffffffc0204f9e:	5575                	li	a0,-3
ffffffffc0204fa0:	6105                	addi	sp,sp,32
ffffffffc0204fa2:	8082                	ret

ffffffffc0204fa4 <do_kill>:
{
ffffffffc0204fa4:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204fa6:	6789                	lui	a5,0x2
{
ffffffffc0204fa8:	e406                	sd	ra,8(sp)
ffffffffc0204faa:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204fac:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204fb0:	17f9                	addi	a5,a5,-2
ffffffffc0204fb2:	02e7e963          	bltu	a5,a4,ffffffffc0204fe4 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204fb6:	842a                	mv	s0,a0
ffffffffc0204fb8:	45a9                	li	a1,10
ffffffffc0204fba:	2501                	sext.w	a0,a0
ffffffffc0204fbc:	46c000ef          	jal	ra,ffffffffc0205428 <hash32>
ffffffffc0204fc0:	02051793          	slli	a5,a0,0x20
ffffffffc0204fc4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204fc8:	000ac797          	auipc	a5,0xac
ffffffffc0204fcc:	bc078793          	addi	a5,a5,-1088 # ffffffffc02b0b88 <hash_list>
ffffffffc0204fd0:	953e                	add	a0,a0,a5
ffffffffc0204fd2:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204fd4:	a029                	j	ffffffffc0204fde <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204fd6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204fda:	00870b63          	beq	a4,s0,ffffffffc0204ff0 <do_kill+0x4c>
ffffffffc0204fde:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204fe0:	fef51be3          	bne	a0,a5,ffffffffc0204fd6 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204fe4:	5475                	li	s0,-3
}
ffffffffc0204fe6:	60a2                	ld	ra,8(sp)
ffffffffc0204fe8:	8522                	mv	a0,s0
ffffffffc0204fea:	6402                	ld	s0,0(sp)
ffffffffc0204fec:	0141                	addi	sp,sp,16
ffffffffc0204fee:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204ff0:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204ff4:	00177693          	andi	a3,a4,1
ffffffffc0204ff8:	e295                	bnez	a3,ffffffffc020501c <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204ffa:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204ffc:	00176713          	ori	a4,a4,1
ffffffffc0205000:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205004:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205006:	fe06d0e3          	bgez	a3,ffffffffc0204fe6 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc020500a:	f2878513          	addi	a0,a5,-216
ffffffffc020500e:	22e000ef          	jal	ra,ffffffffc020523c <wakeup_proc>
}
ffffffffc0205012:	60a2                	ld	ra,8(sp)
ffffffffc0205014:	8522                	mv	a0,s0
ffffffffc0205016:	6402                	ld	s0,0(sp)
ffffffffc0205018:	0141                	addi	sp,sp,16
ffffffffc020501a:	8082                	ret
        return -E_KILLED;
ffffffffc020501c:	545d                	li	s0,-9
ffffffffc020501e:	b7e1                	j	ffffffffc0204fe6 <do_kill+0x42>

ffffffffc0205020 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0205020:	1101                	addi	sp,sp,-32
ffffffffc0205022:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205024:	000b0797          	auipc	a5,0xb0
ffffffffc0205028:	b6478793          	addi	a5,a5,-1180 # ffffffffc02b4b88 <proc_list>
ffffffffc020502c:	ec06                	sd	ra,24(sp)
ffffffffc020502e:	e822                	sd	s0,16(sp)
ffffffffc0205030:	e04a                	sd	s2,0(sp)
ffffffffc0205032:	000ac497          	auipc	s1,0xac
ffffffffc0205036:	b5648493          	addi	s1,s1,-1194 # ffffffffc02b0b88 <hash_list>
ffffffffc020503a:	e79c                	sd	a5,8(a5)
ffffffffc020503c:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc020503e:	000b0717          	auipc	a4,0xb0
ffffffffc0205042:	b4a70713          	addi	a4,a4,-1206 # ffffffffc02b4b88 <proc_list>
ffffffffc0205046:	87a6                	mv	a5,s1
ffffffffc0205048:	e79c                	sd	a5,8(a5)
ffffffffc020504a:	e39c                	sd	a5,0(a5)
ffffffffc020504c:	07c1                	addi	a5,a5,16
ffffffffc020504e:	fef71de3          	bne	a4,a5,ffffffffc0205048 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205052:	fdbfe0ef          	jal	ra,ffffffffc020402c <alloc_proc>
ffffffffc0205056:	000b0917          	auipc	s2,0xb0
ffffffffc020505a:	baa90913          	addi	s2,s2,-1110 # ffffffffc02b4c00 <idleproc>
ffffffffc020505e:	00a93023          	sd	a0,0(s2)
ffffffffc0205062:	0e050f63          	beqz	a0,ffffffffc0205160 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205066:	4789                	li	a5,2
ffffffffc0205068:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020506a:	00003797          	auipc	a5,0x3
ffffffffc020506e:	f9678793          	addi	a5,a5,-106 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205072:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205076:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205078:	4785                	li	a5,1
ffffffffc020507a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020507c:	4641                	li	a2,16
ffffffffc020507e:	4581                	li	a1,0
ffffffffc0205080:	8522                	mv	a0,s0
ffffffffc0205082:	04d000ef          	jal	ra,ffffffffc02058ce <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205086:	463d                	li	a2,15
ffffffffc0205088:	00002597          	auipc	a1,0x2
ffffffffc020508c:	56058593          	addi	a1,a1,1376 # ffffffffc02075e8 <default_pmm_manager+0xd78>
ffffffffc0205090:	8522                	mv	a0,s0
ffffffffc0205092:	04f000ef          	jal	ra,ffffffffc02058e0 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205096:	000b0717          	auipc	a4,0xb0
ffffffffc020509a:	b7a70713          	addi	a4,a4,-1158 # ffffffffc02b4c10 <nr_process>
ffffffffc020509e:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02050a0:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc02050a4:	4601                	li	a2,0
    nr_process++;
ffffffffc02050a6:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc02050a8:	4581                	li	a1,0
ffffffffc02050aa:	00000517          	auipc	a0,0x0
ffffffffc02050ae:	87450513          	addi	a0,a0,-1932 # ffffffffc020491e <init_main>
    nr_process++;
ffffffffc02050b2:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02050b4:	000b0797          	auipc	a5,0xb0
ffffffffc02050b8:	b4d7b223          	sd	a3,-1212(a5) # ffffffffc02b4bf8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc02050bc:	cf6ff0ef          	jal	ra,ffffffffc02045b2 <kernel_thread>
ffffffffc02050c0:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02050c2:	08a05363          	blez	a0,ffffffffc0205148 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc02050c6:	6789                	lui	a5,0x2
ffffffffc02050c8:	fff5071b          	addiw	a4,a0,-1
ffffffffc02050cc:	17f9                	addi	a5,a5,-2
ffffffffc02050ce:	2501                	sext.w	a0,a0
ffffffffc02050d0:	02e7e363          	bltu	a5,a4,ffffffffc02050f6 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02050d4:	45a9                	li	a1,10
ffffffffc02050d6:	352000ef          	jal	ra,ffffffffc0205428 <hash32>
ffffffffc02050da:	02051793          	slli	a5,a0,0x20
ffffffffc02050de:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02050e2:	96a6                	add	a3,a3,s1
ffffffffc02050e4:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02050e6:	a029                	j	ffffffffc02050f0 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc02050e8:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc02050ec:	04870b63          	beq	a4,s0,ffffffffc0205142 <proc_init+0x122>
    return listelm->next;
ffffffffc02050f0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02050f2:	fef69be3          	bne	a3,a5,ffffffffc02050e8 <proc_init+0xc8>
    return NULL;
ffffffffc02050f6:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050f8:	0b478493          	addi	s1,a5,180
ffffffffc02050fc:	4641                	li	a2,16
ffffffffc02050fe:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205100:	000b0417          	auipc	s0,0xb0
ffffffffc0205104:	b0840413          	addi	s0,s0,-1272 # ffffffffc02b4c08 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205108:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020510a:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020510c:	7c2000ef          	jal	ra,ffffffffc02058ce <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205110:	463d                	li	a2,15
ffffffffc0205112:	00002597          	auipc	a1,0x2
ffffffffc0205116:	4fe58593          	addi	a1,a1,1278 # ffffffffc0207610 <default_pmm_manager+0xda0>
ffffffffc020511a:	8526                	mv	a0,s1
ffffffffc020511c:	7c4000ef          	jal	ra,ffffffffc02058e0 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205120:	00093783          	ld	a5,0(s2)
ffffffffc0205124:	cbb5                	beqz	a5,ffffffffc0205198 <proc_init+0x178>
ffffffffc0205126:	43dc                	lw	a5,4(a5)
ffffffffc0205128:	eba5                	bnez	a5,ffffffffc0205198 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020512a:	601c                	ld	a5,0(s0)
ffffffffc020512c:	c7b1                	beqz	a5,ffffffffc0205178 <proc_init+0x158>
ffffffffc020512e:	43d8                	lw	a4,4(a5)
ffffffffc0205130:	4785                	li	a5,1
ffffffffc0205132:	04f71363          	bne	a4,a5,ffffffffc0205178 <proc_init+0x158>
}
ffffffffc0205136:	60e2                	ld	ra,24(sp)
ffffffffc0205138:	6442                	ld	s0,16(sp)
ffffffffc020513a:	64a2                	ld	s1,8(sp)
ffffffffc020513c:	6902                	ld	s2,0(sp)
ffffffffc020513e:	6105                	addi	sp,sp,32
ffffffffc0205140:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205142:	f2878793          	addi	a5,a5,-216
ffffffffc0205146:	bf4d                	j	ffffffffc02050f8 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205148:	00002617          	auipc	a2,0x2
ffffffffc020514c:	4a860613          	addi	a2,a2,1192 # ffffffffc02075f0 <default_pmm_manager+0xd80>
ffffffffc0205150:	3f400593          	li	a1,1012
ffffffffc0205154:	00002517          	auipc	a0,0x2
ffffffffc0205158:	12c50513          	addi	a0,a0,300 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc020515c:	b32fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205160:	00002617          	auipc	a2,0x2
ffffffffc0205164:	47060613          	addi	a2,a2,1136 # ffffffffc02075d0 <default_pmm_manager+0xd60>
ffffffffc0205168:	3e500593          	li	a1,997
ffffffffc020516c:	00002517          	auipc	a0,0x2
ffffffffc0205170:	11450513          	addi	a0,a0,276 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0205174:	b1afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205178:	00002697          	auipc	a3,0x2
ffffffffc020517c:	4c868693          	addi	a3,a3,1224 # ffffffffc0207640 <default_pmm_manager+0xdd0>
ffffffffc0205180:	00001617          	auipc	a2,0x1
ffffffffc0205184:	34060613          	addi	a2,a2,832 # ffffffffc02064c0 <commands+0x960>
ffffffffc0205188:	3fb00593          	li	a1,1019
ffffffffc020518c:	00002517          	auipc	a0,0x2
ffffffffc0205190:	0f450513          	addi	a0,a0,244 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc0205194:	afafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205198:	00002697          	auipc	a3,0x2
ffffffffc020519c:	48068693          	addi	a3,a3,1152 # ffffffffc0207618 <default_pmm_manager+0xda8>
ffffffffc02051a0:	00001617          	auipc	a2,0x1
ffffffffc02051a4:	32060613          	addi	a2,a2,800 # ffffffffc02064c0 <commands+0x960>
ffffffffc02051a8:	3fa00593          	li	a1,1018
ffffffffc02051ac:	00002517          	auipc	a0,0x2
ffffffffc02051b0:	0d450513          	addi	a0,a0,212 # ffffffffc0207280 <default_pmm_manager+0xa10>
ffffffffc02051b4:	adafb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02051b8 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02051b8:	1141                	addi	sp,sp,-16
ffffffffc02051ba:	e022                	sd	s0,0(sp)
ffffffffc02051bc:	e406                	sd	ra,8(sp)
ffffffffc02051be:	000b0417          	auipc	s0,0xb0
ffffffffc02051c2:	a3a40413          	addi	s0,s0,-1478 # ffffffffc02b4bf8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02051c6:	6018                	ld	a4,0(s0)
ffffffffc02051c8:	6f1c                	ld	a5,24(a4)
ffffffffc02051ca:	dffd                	beqz	a5,ffffffffc02051c8 <cpu_idle+0x10>
        {
            schedule();
ffffffffc02051cc:	0f0000ef          	jal	ra,ffffffffc02052bc <schedule>
ffffffffc02051d0:	bfdd                	j	ffffffffc02051c6 <cpu_idle+0xe>

ffffffffc02051d2 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02051d2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02051d6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02051da:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02051dc:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02051de:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02051e2:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02051e6:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02051ea:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02051ee:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02051f2:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02051f6:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02051fa:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02051fe:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205202:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205206:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020520a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020520e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205210:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205212:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205216:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020521a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020521e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205222:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205226:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020522a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020522e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205232:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205236:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020523a:	8082                	ret

ffffffffc020523c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020523c:	4118                	lw	a4,0(a0)
{
ffffffffc020523e:	1101                	addi	sp,sp,-32
ffffffffc0205240:	ec06                	sd	ra,24(sp)
ffffffffc0205242:	e822                	sd	s0,16(sp)
ffffffffc0205244:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205246:	478d                	li	a5,3
ffffffffc0205248:	04f70b63          	beq	a4,a5,ffffffffc020529e <wakeup_proc+0x62>
ffffffffc020524c:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020524e:	100027f3          	csrr	a5,sstatus
ffffffffc0205252:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205254:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205256:	ef9d                	bnez	a5,ffffffffc0205294 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205258:	4789                	li	a5,2
ffffffffc020525a:	02f70163          	beq	a4,a5,ffffffffc020527c <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020525e:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205260:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205264:	e491                	bnez	s1,ffffffffc0205270 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205266:	60e2                	ld	ra,24(sp)
ffffffffc0205268:	6442                	ld	s0,16(sp)
ffffffffc020526a:	64a2                	ld	s1,8(sp)
ffffffffc020526c:	6105                	addi	sp,sp,32
ffffffffc020526e:	8082                	ret
ffffffffc0205270:	6442                	ld	s0,16(sp)
ffffffffc0205272:	60e2                	ld	ra,24(sp)
ffffffffc0205274:	64a2                	ld	s1,8(sp)
ffffffffc0205276:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205278:	f36fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020527c:	00002617          	auipc	a2,0x2
ffffffffc0205280:	42460613          	addi	a2,a2,1060 # ffffffffc02076a0 <default_pmm_manager+0xe30>
ffffffffc0205284:	45d1                	li	a1,20
ffffffffc0205286:	00002517          	auipc	a0,0x2
ffffffffc020528a:	40250513          	addi	a0,a0,1026 # ffffffffc0207688 <default_pmm_manager+0xe18>
ffffffffc020528e:	a68fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205292:	bfc9                	j	ffffffffc0205264 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205294:	f20fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205298:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020529a:	4485                	li	s1,1
ffffffffc020529c:	bf75                	j	ffffffffc0205258 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020529e:	00002697          	auipc	a3,0x2
ffffffffc02052a2:	3ca68693          	addi	a3,a3,970 # ffffffffc0207668 <default_pmm_manager+0xdf8>
ffffffffc02052a6:	00001617          	auipc	a2,0x1
ffffffffc02052aa:	21a60613          	addi	a2,a2,538 # ffffffffc02064c0 <commands+0x960>
ffffffffc02052ae:	45a5                	li	a1,9
ffffffffc02052b0:	00002517          	auipc	a0,0x2
ffffffffc02052b4:	3d850513          	addi	a0,a0,984 # ffffffffc0207688 <default_pmm_manager+0xe18>
ffffffffc02052b8:	9d6fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02052bc <schedule>:

void schedule(void)
{
ffffffffc02052bc:	1141                	addi	sp,sp,-16
ffffffffc02052be:	e406                	sd	ra,8(sp)
ffffffffc02052c0:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02052c2:	100027f3          	csrr	a5,sstatus
ffffffffc02052c6:	8b89                	andi	a5,a5,2
ffffffffc02052c8:	4401                	li	s0,0
ffffffffc02052ca:	efbd                	bnez	a5,ffffffffc0205348 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02052cc:	000b0897          	auipc	a7,0xb0
ffffffffc02052d0:	92c8b883          	ld	a7,-1748(a7) # ffffffffc02b4bf8 <current>
ffffffffc02052d4:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02052d8:	000b0517          	auipc	a0,0xb0
ffffffffc02052dc:	92853503          	ld	a0,-1752(a0) # ffffffffc02b4c00 <idleproc>
ffffffffc02052e0:	04a88e63          	beq	a7,a0,ffffffffc020533c <schedule+0x80>
ffffffffc02052e4:	0c888693          	addi	a3,a7,200
ffffffffc02052e8:	000b0617          	auipc	a2,0xb0
ffffffffc02052ec:	8a060613          	addi	a2,a2,-1888 # ffffffffc02b4b88 <proc_list>
        le = last;
ffffffffc02052f0:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02052f2:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02052f4:	4809                	li	a6,2
ffffffffc02052f6:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02052f8:	00c78863          	beq	a5,a2,ffffffffc0205308 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02052fc:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205300:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205304:	03070163          	beq	a4,a6,ffffffffc0205326 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205308:	fef697e3          	bne	a3,a5,ffffffffc02052f6 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020530c:	ed89                	bnez	a1,ffffffffc0205326 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020530e:	451c                	lw	a5,8(a0)
ffffffffc0205310:	2785                	addiw	a5,a5,1
ffffffffc0205312:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205314:	00a88463          	beq	a7,a0,ffffffffc020531c <schedule+0x60>
        {
            proc_run(next);
ffffffffc0205318:	e89fe0ef          	jal	ra,ffffffffc02041a0 <proc_run>
    if (flag)
ffffffffc020531c:	e819                	bnez	s0,ffffffffc0205332 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020531e:	60a2                	ld	ra,8(sp)
ffffffffc0205320:	6402                	ld	s0,0(sp)
ffffffffc0205322:	0141                	addi	sp,sp,16
ffffffffc0205324:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205326:	4198                	lw	a4,0(a1)
ffffffffc0205328:	4789                	li	a5,2
ffffffffc020532a:	fef712e3          	bne	a4,a5,ffffffffc020530e <schedule+0x52>
ffffffffc020532e:	852e                	mv	a0,a1
ffffffffc0205330:	bff9                	j	ffffffffc020530e <schedule+0x52>
}
ffffffffc0205332:	6402                	ld	s0,0(sp)
ffffffffc0205334:	60a2                	ld	ra,8(sp)
ffffffffc0205336:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205338:	e76fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020533c:	000b0617          	auipc	a2,0xb0
ffffffffc0205340:	84c60613          	addi	a2,a2,-1972 # ffffffffc02b4b88 <proc_list>
ffffffffc0205344:	86b2                	mv	a3,a2
ffffffffc0205346:	b76d                	j	ffffffffc02052f0 <schedule+0x34>
        intr_disable();
ffffffffc0205348:	e6cfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020534c:	4405                	li	s0,1
ffffffffc020534e:	bfbd                	j	ffffffffc02052cc <schedule+0x10>

ffffffffc0205350 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205350:	000b0797          	auipc	a5,0xb0
ffffffffc0205354:	8a87b783          	ld	a5,-1880(a5) # ffffffffc02b4bf8 <current>
}
ffffffffc0205358:	43c8                	lw	a0,4(a5)
ffffffffc020535a:	8082                	ret

ffffffffc020535c <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020535c:	4501                	li	a0,0
ffffffffc020535e:	8082                	ret

ffffffffc0205360 <sys_putc>:
    cputchar(c);
ffffffffc0205360:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205362:	1141                	addi	sp,sp,-16
ffffffffc0205364:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205366:	e65fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020536a:	60a2                	ld	ra,8(sp)
ffffffffc020536c:	4501                	li	a0,0
ffffffffc020536e:	0141                	addi	sp,sp,16
ffffffffc0205370:	8082                	ret

ffffffffc0205372 <sys_kill>:
    return do_kill(pid);
ffffffffc0205372:	4108                	lw	a0,0(a0)
ffffffffc0205374:	c31ff06f          	j	ffffffffc0204fa4 <do_kill>

ffffffffc0205378 <sys_yield>:
    return do_yield();
ffffffffc0205378:	bdfff06f          	j	ffffffffc0204f56 <do_yield>

ffffffffc020537c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020537c:	6d14                	ld	a3,24(a0)
ffffffffc020537e:	6910                	ld	a2,16(a0)
ffffffffc0205380:	650c                	ld	a1,8(a0)
ffffffffc0205382:	6108                	ld	a0,0(a0)
ffffffffc0205384:	ebeff06f          	j	ffffffffc0204a42 <do_execve>

ffffffffc0205388 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205388:	650c                	ld	a1,8(a0)
ffffffffc020538a:	4108                	lw	a0,0(a0)
ffffffffc020538c:	bdbff06f          	j	ffffffffc0204f66 <do_wait>

ffffffffc0205390 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205390:	000b0797          	auipc	a5,0xb0
ffffffffc0205394:	8687b783          	ld	a5,-1944(a5) # ffffffffc02b4bf8 <current>
ffffffffc0205398:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020539a:	4501                	li	a0,0
ffffffffc020539c:	6a0c                	ld	a1,16(a2)
ffffffffc020539e:	e6ffe06f          	j	ffffffffc020420c <do_fork>

ffffffffc02053a2 <sys_exit>:
    return do_exit(error_code);
ffffffffc02053a2:	4108                	lw	a0,0(a0)
ffffffffc02053a4:	a5eff06f          	j	ffffffffc0204602 <do_exit>

ffffffffc02053a8 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02053a8:	715d                	addi	sp,sp,-80
ffffffffc02053aa:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02053ac:	000b0497          	auipc	s1,0xb0
ffffffffc02053b0:	84c48493          	addi	s1,s1,-1972 # ffffffffc02b4bf8 <current>
ffffffffc02053b4:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02053b6:	e0a2                	sd	s0,64(sp)
ffffffffc02053b8:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02053ba:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02053bc:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02053be:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02053c0:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02053c4:	0327ee63          	bltu	a5,s2,ffffffffc0205400 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02053c8:	00391713          	slli	a4,s2,0x3
ffffffffc02053cc:	00002797          	auipc	a5,0x2
ffffffffc02053d0:	33c78793          	addi	a5,a5,828 # ffffffffc0207708 <syscalls>
ffffffffc02053d4:	97ba                	add	a5,a5,a4
ffffffffc02053d6:	639c                	ld	a5,0(a5)
ffffffffc02053d8:	c785                	beqz	a5,ffffffffc0205400 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02053da:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02053dc:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02053de:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02053e0:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02053e2:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02053e4:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02053e6:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02053e8:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02053ea:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02053ec:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053ee:	0028                	addi	a0,sp,8
ffffffffc02053f0:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053f2:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053f4:	e828                	sd	a0,80(s0)
}
ffffffffc02053f6:	6406                	ld	s0,64(sp)
ffffffffc02053f8:	74e2                	ld	s1,56(sp)
ffffffffc02053fa:	7942                	ld	s2,48(sp)
ffffffffc02053fc:	6161                	addi	sp,sp,80
ffffffffc02053fe:	8082                	ret
    print_trapframe(tf);
ffffffffc0205400:	8522                	mv	a0,s0
ffffffffc0205402:	fa2fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205406:	609c                	ld	a5,0(s1)
ffffffffc0205408:	86ca                	mv	a3,s2
ffffffffc020540a:	00002617          	auipc	a2,0x2
ffffffffc020540e:	2b660613          	addi	a2,a2,694 # ffffffffc02076c0 <default_pmm_manager+0xe50>
ffffffffc0205412:	43d8                	lw	a4,4(a5)
ffffffffc0205414:	06200593          	li	a1,98
ffffffffc0205418:	0b478793          	addi	a5,a5,180
ffffffffc020541c:	00002517          	auipc	a0,0x2
ffffffffc0205420:	2d450513          	addi	a0,a0,724 # ffffffffc02076f0 <default_pmm_manager+0xe80>
ffffffffc0205424:	86afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205428 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205428:	9e3707b7          	lui	a5,0x9e370
ffffffffc020542c:	2785                	addiw	a5,a5,1
ffffffffc020542e:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205432:	02000793          	li	a5,32
ffffffffc0205436:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205438:	00f5553b          	srlw	a0,a0,a5
ffffffffc020543c:	8082                	ret

ffffffffc020543e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020543e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205442:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205444:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205448:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020544a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020544e:	f022                	sd	s0,32(sp)
ffffffffc0205450:	ec26                	sd	s1,24(sp)
ffffffffc0205452:	e84a                	sd	s2,16(sp)
ffffffffc0205454:	f406                	sd	ra,40(sp)
ffffffffc0205456:	e44e                	sd	s3,8(sp)
ffffffffc0205458:	84aa                	mv	s1,a0
ffffffffc020545a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020545c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205460:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205462:	03067e63          	bgeu	a2,a6,ffffffffc020549e <printnum+0x60>
ffffffffc0205466:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205468:	00805763          	blez	s0,ffffffffc0205476 <printnum+0x38>
ffffffffc020546c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020546e:	85ca                	mv	a1,s2
ffffffffc0205470:	854e                	mv	a0,s3
ffffffffc0205472:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205474:	fc65                	bnez	s0,ffffffffc020546c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205476:	1a02                	slli	s4,s4,0x20
ffffffffc0205478:	00002797          	auipc	a5,0x2
ffffffffc020547c:	39078793          	addi	a5,a5,912 # ffffffffc0207808 <syscalls+0x100>
ffffffffc0205480:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205484:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205486:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205488:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020548c:	70a2                	ld	ra,40(sp)
ffffffffc020548e:	69a2                	ld	s3,8(sp)
ffffffffc0205490:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205492:	85ca                	mv	a1,s2
ffffffffc0205494:	87a6                	mv	a5,s1
}
ffffffffc0205496:	6942                	ld	s2,16(sp)
ffffffffc0205498:	64e2                	ld	s1,24(sp)
ffffffffc020549a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020549c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020549e:	03065633          	divu	a2,a2,a6
ffffffffc02054a2:	8722                	mv	a4,s0
ffffffffc02054a4:	f9bff0ef          	jal	ra,ffffffffc020543e <printnum>
ffffffffc02054a8:	b7f9                	j	ffffffffc0205476 <printnum+0x38>

ffffffffc02054aa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02054aa:	7119                	addi	sp,sp,-128
ffffffffc02054ac:	f4a6                	sd	s1,104(sp)
ffffffffc02054ae:	f0ca                	sd	s2,96(sp)
ffffffffc02054b0:	ecce                	sd	s3,88(sp)
ffffffffc02054b2:	e8d2                	sd	s4,80(sp)
ffffffffc02054b4:	e4d6                	sd	s5,72(sp)
ffffffffc02054b6:	e0da                	sd	s6,64(sp)
ffffffffc02054b8:	fc5e                	sd	s7,56(sp)
ffffffffc02054ba:	f06a                	sd	s10,32(sp)
ffffffffc02054bc:	fc86                	sd	ra,120(sp)
ffffffffc02054be:	f8a2                	sd	s0,112(sp)
ffffffffc02054c0:	f862                	sd	s8,48(sp)
ffffffffc02054c2:	f466                	sd	s9,40(sp)
ffffffffc02054c4:	ec6e                	sd	s11,24(sp)
ffffffffc02054c6:	892a                	mv	s2,a0
ffffffffc02054c8:	84ae                	mv	s1,a1
ffffffffc02054ca:	8d32                	mv	s10,a2
ffffffffc02054cc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054ce:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02054d2:	5b7d                	li	s6,-1
ffffffffc02054d4:	00002a97          	auipc	s5,0x2
ffffffffc02054d8:	360a8a93          	addi	s5,s5,864 # ffffffffc0207834 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02054dc:	00002b97          	auipc	s7,0x2
ffffffffc02054e0:	574b8b93          	addi	s7,s7,1396 # ffffffffc0207a50 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054e4:	000d4503          	lbu	a0,0(s10)
ffffffffc02054e8:	001d0413          	addi	s0,s10,1
ffffffffc02054ec:	01350a63          	beq	a0,s3,ffffffffc0205500 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02054f0:	c121                	beqz	a0,ffffffffc0205530 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02054f2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054f4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02054f6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054f8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02054fc:	ff351ae3          	bne	a0,s3,ffffffffc02054f0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205500:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205504:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205508:	4c81                	li	s9,0
ffffffffc020550a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020550c:	5c7d                	li	s8,-1
ffffffffc020550e:	5dfd                	li	s11,-1
ffffffffc0205510:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205514:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205516:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020551a:	0ff5f593          	zext.b	a1,a1
ffffffffc020551e:	00140d13          	addi	s10,s0,1
ffffffffc0205522:	04b56263          	bltu	a0,a1,ffffffffc0205566 <vprintfmt+0xbc>
ffffffffc0205526:	058a                	slli	a1,a1,0x2
ffffffffc0205528:	95d6                	add	a1,a1,s5
ffffffffc020552a:	4194                	lw	a3,0(a1)
ffffffffc020552c:	96d6                	add	a3,a3,s5
ffffffffc020552e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205530:	70e6                	ld	ra,120(sp)
ffffffffc0205532:	7446                	ld	s0,112(sp)
ffffffffc0205534:	74a6                	ld	s1,104(sp)
ffffffffc0205536:	7906                	ld	s2,96(sp)
ffffffffc0205538:	69e6                	ld	s3,88(sp)
ffffffffc020553a:	6a46                	ld	s4,80(sp)
ffffffffc020553c:	6aa6                	ld	s5,72(sp)
ffffffffc020553e:	6b06                	ld	s6,64(sp)
ffffffffc0205540:	7be2                	ld	s7,56(sp)
ffffffffc0205542:	7c42                	ld	s8,48(sp)
ffffffffc0205544:	7ca2                	ld	s9,40(sp)
ffffffffc0205546:	7d02                	ld	s10,32(sp)
ffffffffc0205548:	6de2                	ld	s11,24(sp)
ffffffffc020554a:	6109                	addi	sp,sp,128
ffffffffc020554c:	8082                	ret
            padc = '0';
ffffffffc020554e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205550:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205554:	846a                	mv	s0,s10
ffffffffc0205556:	00140d13          	addi	s10,s0,1
ffffffffc020555a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020555e:	0ff5f593          	zext.b	a1,a1
ffffffffc0205562:	fcb572e3          	bgeu	a0,a1,ffffffffc0205526 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205566:	85a6                	mv	a1,s1
ffffffffc0205568:	02500513          	li	a0,37
ffffffffc020556c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020556e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205572:	8d22                	mv	s10,s0
ffffffffc0205574:	f73788e3          	beq	a5,s3,ffffffffc02054e4 <vprintfmt+0x3a>
ffffffffc0205578:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020557c:	1d7d                	addi	s10,s10,-1
ffffffffc020557e:	ff379de3          	bne	a5,s3,ffffffffc0205578 <vprintfmt+0xce>
ffffffffc0205582:	b78d                	j	ffffffffc02054e4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205584:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205588:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020558c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020558e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205592:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205596:	02d86463          	bltu	a6,a3,ffffffffc02055be <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020559a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020559e:	002c169b          	slliw	a3,s8,0x2
ffffffffc02055a2:	0186873b          	addw	a4,a3,s8
ffffffffc02055a6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02055aa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02055ac:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02055b0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02055b2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02055b6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02055ba:	fed870e3          	bgeu	a6,a3,ffffffffc020559a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02055be:	f40ddce3          	bgez	s11,ffffffffc0205516 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02055c2:	8de2                	mv	s11,s8
ffffffffc02055c4:	5c7d                	li	s8,-1
ffffffffc02055c6:	bf81                	j	ffffffffc0205516 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02055c8:	fffdc693          	not	a3,s11
ffffffffc02055cc:	96fd                	srai	a3,a3,0x3f
ffffffffc02055ce:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055d2:	00144603          	lbu	a2,1(s0)
ffffffffc02055d6:	2d81                	sext.w	s11,s11
ffffffffc02055d8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055da:	bf35                	j	ffffffffc0205516 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02055dc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02055e4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02055e8:	bfd9                	j	ffffffffc02055be <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02055ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055f0:	01174463          	blt	a4,a7,ffffffffc02055f8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02055f4:	1a088e63          	beqz	a7,ffffffffc02057b0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02055f8:	000a3603          	ld	a2,0(s4)
ffffffffc02055fc:	46c1                	li	a3,16
ffffffffc02055fe:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205600:	2781                	sext.w	a5,a5
ffffffffc0205602:	876e                	mv	a4,s11
ffffffffc0205604:	85a6                	mv	a1,s1
ffffffffc0205606:	854a                	mv	a0,s2
ffffffffc0205608:	e37ff0ef          	jal	ra,ffffffffc020543e <printnum>
            break;
ffffffffc020560c:	bde1                	j	ffffffffc02054e4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020560e:	000a2503          	lw	a0,0(s4)
ffffffffc0205612:	85a6                	mv	a1,s1
ffffffffc0205614:	0a21                	addi	s4,s4,8
ffffffffc0205616:	9902                	jalr	s2
            break;
ffffffffc0205618:	b5f1                	j	ffffffffc02054e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020561a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020561c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205620:	01174463          	blt	a4,a7,ffffffffc0205628 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205624:	18088163          	beqz	a7,ffffffffc02057a6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205628:	000a3603          	ld	a2,0(s4)
ffffffffc020562c:	46a9                	li	a3,10
ffffffffc020562e:	8a2e                	mv	s4,a1
ffffffffc0205630:	bfc1                	j	ffffffffc0205600 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205632:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205636:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205638:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020563a:	bdf1                	j	ffffffffc0205516 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020563c:	85a6                	mv	a1,s1
ffffffffc020563e:	02500513          	li	a0,37
ffffffffc0205642:	9902                	jalr	s2
            break;
ffffffffc0205644:	b545                	j	ffffffffc02054e4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205646:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020564a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020564c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020564e:	b5e1                	j	ffffffffc0205516 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205650:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205652:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205656:	01174463          	blt	a4,a7,ffffffffc020565e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020565a:	14088163          	beqz	a7,ffffffffc020579c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020565e:	000a3603          	ld	a2,0(s4)
ffffffffc0205662:	46a1                	li	a3,8
ffffffffc0205664:	8a2e                	mv	s4,a1
ffffffffc0205666:	bf69                	j	ffffffffc0205600 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205668:	03000513          	li	a0,48
ffffffffc020566c:	85a6                	mv	a1,s1
ffffffffc020566e:	e03e                	sd	a5,0(sp)
ffffffffc0205670:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205672:	85a6                	mv	a1,s1
ffffffffc0205674:	07800513          	li	a0,120
ffffffffc0205678:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020567a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020567c:	6782                	ld	a5,0(sp)
ffffffffc020567e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205680:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205684:	bfb5                	j	ffffffffc0205600 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205686:	000a3403          	ld	s0,0(s4)
ffffffffc020568a:	008a0713          	addi	a4,s4,8
ffffffffc020568e:	e03a                	sd	a4,0(sp)
ffffffffc0205690:	14040263          	beqz	s0,ffffffffc02057d4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205694:	0fb05763          	blez	s11,ffffffffc0205782 <vprintfmt+0x2d8>
ffffffffc0205698:	02d00693          	li	a3,45
ffffffffc020569c:	0cd79163          	bne	a5,a3,ffffffffc020575e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056a0:	00044783          	lbu	a5,0(s0)
ffffffffc02056a4:	0007851b          	sext.w	a0,a5
ffffffffc02056a8:	cf85                	beqz	a5,ffffffffc02056e0 <vprintfmt+0x236>
ffffffffc02056aa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056ae:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056b2:	000c4563          	bltz	s8,ffffffffc02056bc <vprintfmt+0x212>
ffffffffc02056b6:	3c7d                	addiw	s8,s8,-1
ffffffffc02056b8:	036c0263          	beq	s8,s6,ffffffffc02056dc <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02056bc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056be:	0e0c8e63          	beqz	s9,ffffffffc02057ba <vprintfmt+0x310>
ffffffffc02056c2:	3781                	addiw	a5,a5,-32
ffffffffc02056c4:	0ef47b63          	bgeu	s0,a5,ffffffffc02057ba <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02056c8:	03f00513          	li	a0,63
ffffffffc02056cc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056ce:	000a4783          	lbu	a5,0(s4)
ffffffffc02056d2:	3dfd                	addiw	s11,s11,-1
ffffffffc02056d4:	0a05                	addi	s4,s4,1
ffffffffc02056d6:	0007851b          	sext.w	a0,a5
ffffffffc02056da:	ffe1                	bnez	a5,ffffffffc02056b2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02056dc:	01b05963          	blez	s11,ffffffffc02056ee <vprintfmt+0x244>
ffffffffc02056e0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02056e2:	85a6                	mv	a1,s1
ffffffffc02056e4:	02000513          	li	a0,32
ffffffffc02056e8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02056ea:	fe0d9be3          	bnez	s11,ffffffffc02056e0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02056ee:	6a02                	ld	s4,0(sp)
ffffffffc02056f0:	bbd5                	j	ffffffffc02054e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02056f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056f4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02056f8:	01174463          	blt	a4,a7,ffffffffc0205700 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02056fc:	08088d63          	beqz	a7,ffffffffc0205796 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205700:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205704:	0a044d63          	bltz	s0,ffffffffc02057be <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205708:	8622                	mv	a2,s0
ffffffffc020570a:	8a66                	mv	s4,s9
ffffffffc020570c:	46a9                	li	a3,10
ffffffffc020570e:	bdcd                	j	ffffffffc0205600 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205710:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205714:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205716:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205718:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020571c:	8fb5                	xor	a5,a5,a3
ffffffffc020571e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205722:	02d74163          	blt	a4,a3,ffffffffc0205744 <vprintfmt+0x29a>
ffffffffc0205726:	00369793          	slli	a5,a3,0x3
ffffffffc020572a:	97de                	add	a5,a5,s7
ffffffffc020572c:	639c                	ld	a5,0(a5)
ffffffffc020572e:	cb99                	beqz	a5,ffffffffc0205744 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205730:	86be                	mv	a3,a5
ffffffffc0205732:	00000617          	auipc	a2,0x0
ffffffffc0205736:	1ee60613          	addi	a2,a2,494 # ffffffffc0205920 <etext+0x28>
ffffffffc020573a:	85a6                	mv	a1,s1
ffffffffc020573c:	854a                	mv	a0,s2
ffffffffc020573e:	0ce000ef          	jal	ra,ffffffffc020580c <printfmt>
ffffffffc0205742:	b34d                	j	ffffffffc02054e4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205744:	00002617          	auipc	a2,0x2
ffffffffc0205748:	0e460613          	addi	a2,a2,228 # ffffffffc0207828 <syscalls+0x120>
ffffffffc020574c:	85a6                	mv	a1,s1
ffffffffc020574e:	854a                	mv	a0,s2
ffffffffc0205750:	0bc000ef          	jal	ra,ffffffffc020580c <printfmt>
ffffffffc0205754:	bb41                	j	ffffffffc02054e4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205756:	00002417          	auipc	s0,0x2
ffffffffc020575a:	0ca40413          	addi	s0,s0,202 # ffffffffc0207820 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020575e:	85e2                	mv	a1,s8
ffffffffc0205760:	8522                	mv	a0,s0
ffffffffc0205762:	e43e                	sd	a5,8(sp)
ffffffffc0205764:	0e2000ef          	jal	ra,ffffffffc0205846 <strnlen>
ffffffffc0205768:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020576c:	01b05b63          	blez	s11,ffffffffc0205782 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205770:	67a2                	ld	a5,8(sp)
ffffffffc0205772:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205776:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205778:	85a6                	mv	a1,s1
ffffffffc020577a:	8552                	mv	a0,s4
ffffffffc020577c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020577e:	fe0d9ce3          	bnez	s11,ffffffffc0205776 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205782:	00044783          	lbu	a5,0(s0)
ffffffffc0205786:	00140a13          	addi	s4,s0,1
ffffffffc020578a:	0007851b          	sext.w	a0,a5
ffffffffc020578e:	d3a5                	beqz	a5,ffffffffc02056ee <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205790:	05e00413          	li	s0,94
ffffffffc0205794:	bf39                	j	ffffffffc02056b2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205796:	000a2403          	lw	s0,0(s4)
ffffffffc020579a:	b7ad                	j	ffffffffc0205704 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020579c:	000a6603          	lwu	a2,0(s4)
ffffffffc02057a0:	46a1                	li	a3,8
ffffffffc02057a2:	8a2e                	mv	s4,a1
ffffffffc02057a4:	bdb1                	j	ffffffffc0205600 <vprintfmt+0x156>
ffffffffc02057a6:	000a6603          	lwu	a2,0(s4)
ffffffffc02057aa:	46a9                	li	a3,10
ffffffffc02057ac:	8a2e                	mv	s4,a1
ffffffffc02057ae:	bd89                	j	ffffffffc0205600 <vprintfmt+0x156>
ffffffffc02057b0:	000a6603          	lwu	a2,0(s4)
ffffffffc02057b4:	46c1                	li	a3,16
ffffffffc02057b6:	8a2e                	mv	s4,a1
ffffffffc02057b8:	b5a1                	j	ffffffffc0205600 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02057ba:	9902                	jalr	s2
ffffffffc02057bc:	bf09                	j	ffffffffc02056ce <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02057be:	85a6                	mv	a1,s1
ffffffffc02057c0:	02d00513          	li	a0,45
ffffffffc02057c4:	e03e                	sd	a5,0(sp)
ffffffffc02057c6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02057c8:	6782                	ld	a5,0(sp)
ffffffffc02057ca:	8a66                	mv	s4,s9
ffffffffc02057cc:	40800633          	neg	a2,s0
ffffffffc02057d0:	46a9                	li	a3,10
ffffffffc02057d2:	b53d                	j	ffffffffc0205600 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02057d4:	03b05163          	blez	s11,ffffffffc02057f6 <vprintfmt+0x34c>
ffffffffc02057d8:	02d00693          	li	a3,45
ffffffffc02057dc:	f6d79de3          	bne	a5,a3,ffffffffc0205756 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02057e0:	00002417          	auipc	s0,0x2
ffffffffc02057e4:	04040413          	addi	s0,s0,64 # ffffffffc0207820 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057e8:	02800793          	li	a5,40
ffffffffc02057ec:	02800513          	li	a0,40
ffffffffc02057f0:	00140a13          	addi	s4,s0,1
ffffffffc02057f4:	bd6d                	j	ffffffffc02056ae <vprintfmt+0x204>
ffffffffc02057f6:	00002a17          	auipc	s4,0x2
ffffffffc02057fa:	02ba0a13          	addi	s4,s4,43 # ffffffffc0207821 <syscalls+0x119>
ffffffffc02057fe:	02800513          	li	a0,40
ffffffffc0205802:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205806:	05e00413          	li	s0,94
ffffffffc020580a:	b565                	j	ffffffffc02056b2 <vprintfmt+0x208>

ffffffffc020580c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020580c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020580e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205812:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205814:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205816:	ec06                	sd	ra,24(sp)
ffffffffc0205818:	f83a                	sd	a4,48(sp)
ffffffffc020581a:	fc3e                	sd	a5,56(sp)
ffffffffc020581c:	e0c2                	sd	a6,64(sp)
ffffffffc020581e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205820:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205822:	c89ff0ef          	jal	ra,ffffffffc02054aa <vprintfmt>
}
ffffffffc0205826:	60e2                	ld	ra,24(sp)
ffffffffc0205828:	6161                	addi	sp,sp,80
ffffffffc020582a:	8082                	ret

ffffffffc020582c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020582c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205830:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205832:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205834:	cb81                	beqz	a5,ffffffffc0205844 <strlen+0x18>
        cnt ++;
ffffffffc0205836:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205838:	00a707b3          	add	a5,a4,a0
ffffffffc020583c:	0007c783          	lbu	a5,0(a5)
ffffffffc0205840:	fbfd                	bnez	a5,ffffffffc0205836 <strlen+0xa>
ffffffffc0205842:	8082                	ret
    }
    return cnt;
}
ffffffffc0205844:	8082                	ret

ffffffffc0205846 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205846:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205848:	e589                	bnez	a1,ffffffffc0205852 <strnlen+0xc>
ffffffffc020584a:	a811                	j	ffffffffc020585e <strnlen+0x18>
        cnt ++;
ffffffffc020584c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020584e:	00f58863          	beq	a1,a5,ffffffffc020585e <strnlen+0x18>
ffffffffc0205852:	00f50733          	add	a4,a0,a5
ffffffffc0205856:	00074703          	lbu	a4,0(a4)
ffffffffc020585a:	fb6d                	bnez	a4,ffffffffc020584c <strnlen+0x6>
ffffffffc020585c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020585e:	852e                	mv	a0,a1
ffffffffc0205860:	8082                	ret

ffffffffc0205862 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205862:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205864:	0005c703          	lbu	a4,0(a1)
ffffffffc0205868:	0785                	addi	a5,a5,1
ffffffffc020586a:	0585                	addi	a1,a1,1
ffffffffc020586c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205870:	fb75                	bnez	a4,ffffffffc0205864 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205872:	8082                	ret

ffffffffc0205874 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205874:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205878:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020587c:	cb89                	beqz	a5,ffffffffc020588e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020587e:	0505                	addi	a0,a0,1
ffffffffc0205880:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205882:	fee789e3          	beq	a5,a4,ffffffffc0205874 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205886:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020588a:	9d19                	subw	a0,a0,a4
ffffffffc020588c:	8082                	ret
ffffffffc020588e:	4501                	li	a0,0
ffffffffc0205890:	bfed                	j	ffffffffc020588a <strcmp+0x16>

ffffffffc0205892 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205892:	c20d                	beqz	a2,ffffffffc02058b4 <strncmp+0x22>
ffffffffc0205894:	962e                	add	a2,a2,a1
ffffffffc0205896:	a031                	j	ffffffffc02058a2 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205898:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020589a:	00e79a63          	bne	a5,a4,ffffffffc02058ae <strncmp+0x1c>
ffffffffc020589e:	00b60b63          	beq	a2,a1,ffffffffc02058b4 <strncmp+0x22>
ffffffffc02058a2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02058a6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02058a8:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02058ac:	f7f5                	bnez	a5,ffffffffc0205898 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02058ae:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02058b2:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02058b4:	4501                	li	a0,0
ffffffffc02058b6:	8082                	ret

ffffffffc02058b8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02058b8:	00054783          	lbu	a5,0(a0)
ffffffffc02058bc:	c799                	beqz	a5,ffffffffc02058ca <strchr+0x12>
        if (*s == c) {
ffffffffc02058be:	00f58763          	beq	a1,a5,ffffffffc02058cc <strchr+0x14>
    while (*s != '\0') {
ffffffffc02058c2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02058c6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02058c8:	fbfd                	bnez	a5,ffffffffc02058be <strchr+0x6>
    }
    return NULL;
ffffffffc02058ca:	4501                	li	a0,0
}
ffffffffc02058cc:	8082                	ret

ffffffffc02058ce <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02058ce:	ca01                	beqz	a2,ffffffffc02058de <memset+0x10>
ffffffffc02058d0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02058d2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02058d4:	0785                	addi	a5,a5,1
ffffffffc02058d6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02058da:	fec79de3          	bne	a5,a2,ffffffffc02058d4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02058de:	8082                	ret

ffffffffc02058e0 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02058e0:	ca19                	beqz	a2,ffffffffc02058f6 <memcpy+0x16>
ffffffffc02058e2:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02058e4:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02058e6:	0005c703          	lbu	a4,0(a1)
ffffffffc02058ea:	0585                	addi	a1,a1,1
ffffffffc02058ec:	0785                	addi	a5,a5,1
ffffffffc02058ee:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02058f2:	fec59ae3          	bne	a1,a2,ffffffffc02058e6 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02058f6:	8082                	ret
