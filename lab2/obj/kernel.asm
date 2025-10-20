
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
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	ac450513          	addi	a0,a0,-1340 # ffffffffc0201b10 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	ace50513          	addi	a0,a0,-1330 # ffffffffc0201b30 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	a9c58593          	addi	a1,a1,-1380 # ffffffffc0201b0a <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	ada50513          	addi	a0,a0,-1318 # ffffffffc0201b50 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_list>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	ae650513          	addi	a0,a0,-1306 # ffffffffc0201b70 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	46258593          	addi	a1,a1,1122 # ffffffffc02064f8 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	af250513          	addi	a0,a0,-1294 # ffffffffc0201b90 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	84d58593          	addi	a1,a1,-1971 # ffffffffc02068f7 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	ae450513          	addi	a0,a0,-1308 # ffffffffc0201bb0 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <free_list>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	41860613          	addi	a2,a2,1048 # ffffffffc02064f8 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	209010ef          	jal	ra,ffffffffc0201af8 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	ae450513          	addi	a0,a0,-1308 # ffffffffc0201be0 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4c4000ef          	jal	ra,ffffffffc02005d0 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	55c010ef          	jal	ra,ffffffffc020169c <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	526010ef          	jal	ra,ffffffffc020169c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	2e630313          	addi	t1,t1,742 # ffffffffc02064a8 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0201c00 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	9d050513          	addi	a0,a0,-1584 # ffffffffc0201bd8 <etext+0xce>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	0490106f          	j	ffffffffc0201a64 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0201c20 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	9e050513          	addi	a0,a0,-1568 # ffffffffc0201c30 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	9da50513          	addi	a0,a0,-1574 # ffffffffc0201c40 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	9e250513          	addi	a0,a0,-1566 # ffffffffc0201c58 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed99f5>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	97890913          	addi	s2,s2,-1672 # ffffffffc0201ca8 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	96248493          	addi	s1,s1,-1694 # ffffffffc0201ca0 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	98e50513          	addi	a0,a0,-1650 # ffffffffc0201d20 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0201d58 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	89a50513          	addi	a0,a0,-1894 # ffffffffc0201c78 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	692010ef          	jal	ra,ffffffffc0201a7e <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	6d8010ef          	jal	ra,ffffffffc0201ad2 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	624010ef          	jal	ra,ffffffffc0201ab4 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	80c50513          	addi	a0,a0,-2036 # ffffffffc0201cb0 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	75e50513          	addi	a0,a0,1886 # ffffffffc0201cd0 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	76450513          	addi	a0,a0,1892 # ffffffffc0201ce8 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	77250513          	addi	a0,a0,1906 # ffffffffc0201d08 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	7b650513          	addi	a0,a0,1974 # ffffffffc0201d58 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	f087b323          	sd	s0,-250(a5) # ffffffffc02064b0 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	f167b323          	sd	s6,-250(a5) # ffffffffc02064b8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	ef453503          	ld	a0,-268(a0) # ffffffffc02064b0 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	ef253503          	ld	a0,-270(a0) # ffffffffc02064b8 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <pmm_init>:

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    //pmm_manager = &best_fit_pmm_manager;
    //pmm_manager = &buddy_pmm_manager;
    pmm_manager = &slub_pmm_manager;
ffffffffc02005d0:	00002797          	auipc	a5,0x2
ffffffffc02005d4:	d7878793          	addi	a5,a5,-648 # ffffffffc0202348 <slub_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005d8:	638c                	ld	a1,0(a5)
    if (freemem < mem_end) {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}
/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02005da:	7179                	addi	sp,sp,-48
ffffffffc02005dc:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	79250513          	addi	a0,a0,1938 # ffffffffc0201d70 <etext+0x266>
    pmm_manager = &slub_pmm_manager;
ffffffffc02005e6:	00006417          	auipc	s0,0x6
ffffffffc02005ea:	eea40413          	addi	s0,s0,-278 # ffffffffc02064d0 <pmm_manager>
void pmm_init(void) {
ffffffffc02005ee:	f406                	sd	ra,40(sp)
ffffffffc02005f0:	ec26                	sd	s1,24(sp)
ffffffffc02005f2:	e44e                	sd	s3,8(sp)
ffffffffc02005f4:	e84a                	sd	s2,16(sp)
ffffffffc02005f6:	e052                	sd	s4,0(sp)
    pmm_manager = &slub_pmm_manager;
ffffffffc02005f8:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005fa:	b53ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc02005fe:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200600:	00006497          	auipc	s1,0x6
ffffffffc0200604:	ee848493          	addi	s1,s1,-280 # ffffffffc02064e8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200608:	679c                	ld	a5,8(a5)
ffffffffc020060a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020060c:	57f5                	li	a5,-3
ffffffffc020060e:	07fa                	slli	a5,a5,0x1e
ffffffffc0200610:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200612:	fabff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200616:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200618:	fafff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020061c:	14050c63          	beqz	a0,ffffffffc0200774 <pmm_init+0x1a4>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200620:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200622:	00001517          	auipc	a0,0x1
ffffffffc0200626:	79650513          	addi	a0,a0,1942 # ffffffffc0201db8 <etext+0x2ae>
ffffffffc020062a:	b23ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020062e:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200632:	864e                	mv	a2,s3
ffffffffc0200634:	fffa0693          	addi	a3,s4,-1
ffffffffc0200638:	85ca                	mv	a1,s2
ffffffffc020063a:	00001517          	auipc	a0,0x1
ffffffffc020063e:	79650513          	addi	a0,a0,1942 # ffffffffc0201dd0 <etext+0x2c6>
ffffffffc0200642:	b0bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200646:	c80007b7          	lui	a5,0xc8000
ffffffffc020064a:	8652                	mv	a2,s4
ffffffffc020064c:	0d47e363          	bltu	a5,s4,ffffffffc0200712 <pmm_init+0x142>
ffffffffc0200650:	00007797          	auipc	a5,0x7
ffffffffc0200654:	ea778793          	addi	a5,a5,-345 # ffffffffc02074f7 <end+0xfff>
ffffffffc0200658:	757d                	lui	a0,0xfffff
ffffffffc020065a:	8d7d                	and	a0,a0,a5
ffffffffc020065c:	8231                	srli	a2,a2,0xc
ffffffffc020065e:	00006797          	auipc	a5,0x6
ffffffffc0200662:	e6c7b123          	sd	a2,-414(a5) # ffffffffc02064c0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200666:	00006797          	auipc	a5,0x6
ffffffffc020066a:	e6a7b123          	sd	a0,-414(a5) # ffffffffc02064c8 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020066e:	000807b7          	lui	a5,0x80
ffffffffc0200672:	002005b7          	lui	a1,0x200
ffffffffc0200676:	02f60563          	beq	a2,a5,ffffffffc02006a0 <pmm_init+0xd0>
ffffffffc020067a:	00261593          	slli	a1,a2,0x2
ffffffffc020067e:	00c586b3          	add	a3,a1,a2
ffffffffc0200682:	fec007b7          	lui	a5,0xfec00
ffffffffc0200686:	97aa                	add	a5,a5,a0
ffffffffc0200688:	068e                	slli	a3,a3,0x3
ffffffffc020068a:	96be                	add	a3,a3,a5
ffffffffc020068c:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc020068e:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200690:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9b30>
        SetPageReserved(pages + i);
ffffffffc0200694:	00176713          	ori	a4,a4,1
ffffffffc0200698:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020069c:	fef699e3          	bne	a3,a5,ffffffffc020068e <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006a0:	95b2                	add	a1,a1,a2
ffffffffc02006a2:	fec006b7          	lui	a3,0xfec00
ffffffffc02006a6:	96aa                	add	a3,a3,a0
ffffffffc02006a8:	058e                	slli	a1,a1,0x3
ffffffffc02006aa:	96ae                	add	a3,a3,a1
ffffffffc02006ac:	c02007b7          	lui	a5,0xc0200
ffffffffc02006b0:	0af6e663          	bltu	a3,a5,ffffffffc020075c <pmm_init+0x18c>
ffffffffc02006b4:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02006b6:	77fd                	lui	a5,0xfffff
ffffffffc02006b8:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006bc:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02006be:	04b6ed63          	bltu	a3,a1,ffffffffc0200718 <pmm_init+0x148>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02006c2:	601c                	ld	a5,0(s0)
ffffffffc02006c4:	7b9c                	ld	a5,48(a5)
ffffffffc02006c6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02006c8:	00001517          	auipc	a0,0x1
ffffffffc02006cc:	79050513          	addi	a0,a0,1936 # ffffffffc0201e58 <etext+0x34e>
ffffffffc02006d0:	a7dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02006d4:	00005597          	auipc	a1,0x5
ffffffffc02006d8:	92c58593          	addi	a1,a1,-1748 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02006dc:	00006797          	auipc	a5,0x6
ffffffffc02006e0:	e0b7b223          	sd	a1,-508(a5) # ffffffffc02064e0 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02006e4:	c02007b7          	lui	a5,0xc0200
ffffffffc02006e8:	0af5e263          	bltu	a1,a5,ffffffffc020078c <pmm_init+0x1bc>
ffffffffc02006ec:	6090                	ld	a2,0(s1)
}
ffffffffc02006ee:	7402                	ld	s0,32(sp)
ffffffffc02006f0:	70a2                	ld	ra,40(sp)
ffffffffc02006f2:	64e2                	ld	s1,24(sp)
ffffffffc02006f4:	6942                	ld	s2,16(sp)
ffffffffc02006f6:	69a2                	ld	s3,8(sp)
ffffffffc02006f8:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02006fa:	40c58633          	sub	a2,a1,a2
ffffffffc02006fe:	00006797          	auipc	a5,0x6
ffffffffc0200702:	dcc7bd23          	sd	a2,-550(a5) # ffffffffc02064d8 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200706:	00001517          	auipc	a0,0x1
ffffffffc020070a:	77250513          	addi	a0,a0,1906 # ffffffffc0201e78 <etext+0x36e>
}
ffffffffc020070e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200710:	bc35                	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200712:	c8000637          	lui	a2,0xc8000
ffffffffc0200716:	bf2d                	j	ffffffffc0200650 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200718:	6705                	lui	a4,0x1
ffffffffc020071a:	177d                	addi	a4,a4,-1
ffffffffc020071c:	96ba                	add	a3,a3,a4
ffffffffc020071e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200720:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200724:	02c7f063          	bgeu	a5,a2,ffffffffc0200744 <pmm_init+0x174>
    pmm_manager->init_memmap(base, n);
ffffffffc0200728:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020072a:	fff80737          	lui	a4,0xfff80
ffffffffc020072e:	973e                	add	a4,a4,a5
ffffffffc0200730:	00271793          	slli	a5,a4,0x2
ffffffffc0200734:	97ba                	add	a5,a5,a4
ffffffffc0200736:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200738:	8d95                	sub	a1,a1,a3
ffffffffc020073a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020073c:	81b1                	srli	a1,a1,0xc
ffffffffc020073e:	953e                	add	a0,a0,a5
ffffffffc0200740:	9702                	jalr	a4
}
ffffffffc0200742:	b741                	j	ffffffffc02006c2 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200744:	00001617          	auipc	a2,0x1
ffffffffc0200748:	6e460613          	addi	a2,a2,1764 # ffffffffc0201e28 <etext+0x31e>
ffffffffc020074c:	06900593          	li	a1,105
ffffffffc0200750:	00001517          	auipc	a0,0x1
ffffffffc0200754:	6f850513          	addi	a0,a0,1784 # ffffffffc0201e48 <etext+0x33e>
ffffffffc0200758:	a6bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020075c:	00001617          	auipc	a2,0x1
ffffffffc0200760:	6a460613          	addi	a2,a2,1700 # ffffffffc0201e00 <etext+0x2f6>
ffffffffc0200764:	06200593          	li	a1,98
ffffffffc0200768:	00001517          	auipc	a0,0x1
ffffffffc020076c:	64050513          	addi	a0,a0,1600 # ffffffffc0201da8 <etext+0x29e>
ffffffffc0200770:	a53ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200774:	00001617          	auipc	a2,0x1
ffffffffc0200778:	61460613          	addi	a2,a2,1556 # ffffffffc0201d88 <etext+0x27e>
ffffffffc020077c:	04a00593          	li	a1,74
ffffffffc0200780:	00001517          	auipc	a0,0x1
ffffffffc0200784:	62850513          	addi	a0,a0,1576 # ffffffffc0201da8 <etext+0x29e>
ffffffffc0200788:	a3bff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020078c:	86ae                	mv	a3,a1
ffffffffc020078e:	00001617          	auipc	a2,0x1
ffffffffc0200792:	67260613          	addi	a2,a2,1650 # ffffffffc0201e00 <etext+0x2f6>
ffffffffc0200796:	07c00593          	li	a1,124
ffffffffc020079a:	00001517          	auipc	a0,0x1
ffffffffc020079e:	60e50513          	addi	a0,a0,1550 # ffffffffc0201da8 <etext+0x29e>
ffffffffc02007a2:	a21ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007a6 <slub_nr_free_pages>:
}

// 返回空闲页面数
size_t slub_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02007a6:	00006517          	auipc	a0,0x6
ffffffffc02007aa:	d4a56503          	lwu	a0,-694(a0) # ffffffffc02064f0 <nr_free>
ffffffffc02007ae:	8082                	ret

ffffffffc02007b0 <slub_alloc_pages>:
    assert(n > 0);
ffffffffc02007b0:	cd41                	beqz	a0,ffffffffc0200848 <slub_alloc_pages+0x98>
    if (n > nr_free) {
ffffffffc02007b2:	00006897          	auipc	a7,0x6
ffffffffc02007b6:	d3e88893          	addi	a7,a7,-706 # ffffffffc02064f0 <nr_free>
ffffffffc02007ba:	0008a803          	lw	a6,0(a7)
ffffffffc02007be:	862a                	mv	a2,a0
ffffffffc02007c0:	02081793          	slli	a5,a6,0x20
ffffffffc02007c4:	9381                	srli	a5,a5,0x20
ffffffffc02007c6:	02a7e263          	bltu	a5,a0,ffffffffc02007ea <slub_alloc_pages+0x3a>
    list_entry_t *le = &free_list;
ffffffffc02007ca:	00006597          	auipc	a1,0x6
ffffffffc02007ce:	84e58593          	addi	a1,a1,-1970 # ffffffffc0206018 <free_list>
ffffffffc02007d2:	87ae                	mv	a5,a1
ffffffffc02007d4:	a801                	j	ffffffffc02007e4 <slub_alloc_pages+0x34>
        if (p->property >= n) {
ffffffffc02007d6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02007da:	02071693          	slli	a3,a4,0x20
ffffffffc02007de:	9281                	srli	a3,a3,0x20
ffffffffc02007e0:	00c6f763          	bgeu	a3,a2,ffffffffc02007ee <slub_alloc_pages+0x3e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02007e4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02007e6:	feb798e3          	bne	a5,a1,ffffffffc02007d6 <slub_alloc_pages+0x26>
        return NULL;
ffffffffc02007ea:	4501                	li	a0,0
}
ffffffffc02007ec:	8082                	ret
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02007ee:	0007b303          	ld	t1,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02007f2:	678c                	ld	a1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02007f4:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02007f8:	00060e1b          	sext.w	t3,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02007fc:	00b33423          	sd	a1,8(t1)
    next->prev = prev;
ffffffffc0200800:	0065b023          	sd	t1,0(a1)
        if (page->property > n) {
ffffffffc0200804:	02d67663          	bgeu	a2,a3,ffffffffc0200830 <slub_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc0200808:	00261693          	slli	a3,a2,0x2
ffffffffc020080c:	96b2                	add	a3,a3,a2
ffffffffc020080e:	068e                	slli	a3,a3,0x3
ffffffffc0200810:	96aa                	add	a3,a3,a0
            SetPageProperty(p);
ffffffffc0200812:	6690                	ld	a2,8(a3)
            p->property = page->property - n;
ffffffffc0200814:	41c7073b          	subw	a4,a4,t3
ffffffffc0200818:	ca98                	sw	a4,16(a3)
            SetPageProperty(p);
ffffffffc020081a:	00266713          	ori	a4,a2,2
ffffffffc020081e:	e698                	sd	a4,8(a3)
            list_add(prev, &(p->page_link));
ffffffffc0200820:	01868713          	addi	a4,a3,24 # fffffffffec00018 <end+0x3e9f9b20>
    prev->next = next->prev = elm;
ffffffffc0200824:	e198                	sd	a4,0(a1)
ffffffffc0200826:	00e33423          	sd	a4,8(t1)
    elm->next = next;
ffffffffc020082a:	f28c                	sd	a1,32(a3)
    elm->prev = prev;
ffffffffc020082c:	0066bc23          	sd	t1,24(a3)
        ClearPageProperty(page);
ffffffffc0200830:	ff07b703          	ld	a4,-16(a5)
        nr_free -= n;
ffffffffc0200834:	41c8083b          	subw	a6,a6,t3
ffffffffc0200838:	0108a023          	sw	a6,0(a7)
        ClearPageProperty(page);
ffffffffc020083c:	9b75                	andi	a4,a4,-3
ffffffffc020083e:	fee7b823          	sd	a4,-16(a5)
        page->property = n;
ffffffffc0200842:	ffc7ac23          	sw	t3,-8(a5)
ffffffffc0200846:	8082                	ret
struct Page *slub_alloc_pages(size_t n) {
ffffffffc0200848:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020084a:	00001697          	auipc	a3,0x1
ffffffffc020084e:	66e68693          	addi	a3,a3,1646 # ffffffffc0201eb8 <etext+0x3ae>
ffffffffc0200852:	00001617          	auipc	a2,0x1
ffffffffc0200856:	66e60613          	addi	a2,a2,1646 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc020085a:	1bc00593          	li	a1,444
ffffffffc020085e:	00001517          	auipc	a0,0x1
ffffffffc0200862:	67a50513          	addi	a0,a0,1658 # ffffffffc0201ed8 <etext+0x3ce>
struct Page *slub_alloc_pages(size_t n) {
ffffffffc0200866:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200868:	95bff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020086c <slub_init_memmap>:
void slub_init_memmap(struct Page *base, size_t n) {
ffffffffc020086c:	1141                	addi	sp,sp,-16
ffffffffc020086e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200870:	cde9                	beqz	a1,ffffffffc020094a <slub_init_memmap+0xde>
    for (; p != base + n; p++) {
ffffffffc0200872:	00259693          	slli	a3,a1,0x2
ffffffffc0200876:	96ae                	add	a3,a3,a1
ffffffffc0200878:	068e                	slli	a3,a3,0x3
ffffffffc020087a:	96aa                	add	a3,a3,a0
ffffffffc020087c:	87aa                	mv	a5,a0
ffffffffc020087e:	00d50f63          	beq	a0,a3,ffffffffc020089c <slub_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200882:	6798                	ld	a4,8(a5)
ffffffffc0200884:	8b05                	andi	a4,a4,1
ffffffffc0200886:	c355                	beqz	a4,ffffffffc020092a <slub_init_memmap+0xbe>
        p->flags = p->property = 0;
ffffffffc0200888:	0007a823          	sw	zero,16(a5)
ffffffffc020088c:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200890:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0200894:	02878793          	addi	a5,a5,40
ffffffffc0200898:	fed795e3          	bne	a5,a3,ffffffffc0200882 <slub_init_memmap+0x16>
    nr_free += n;
ffffffffc020089c:	00006817          	auipc	a6,0x6
ffffffffc02008a0:	c5480813          	addi	a6,a6,-940 # ffffffffc02064f0 <nr_free>
    SetPageProperty(base);
ffffffffc02008a4:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc02008a6:	00082703          	lw	a4,0(a6)
    return list->next == list;
ffffffffc02008aa:	00005697          	auipc	a3,0x5
ffffffffc02008ae:	76e68693          	addi	a3,a3,1902 # ffffffffc0206018 <free_list>
    base->property = n;
ffffffffc02008b2:	2581                	sext.w	a1,a1
ffffffffc02008b4:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc02008b6:	00266613          	ori	a2,a2,2
    nr_free += n;
ffffffffc02008ba:	9f2d                	addw	a4,a4,a1
    SetPageProperty(base);
ffffffffc02008bc:	e510                	sd	a2,8(a0)
    base->property = n;
ffffffffc02008be:	c90c                	sw	a1,16(a0)
    nr_free += n;
ffffffffc02008c0:	00e82023          	sw	a4,0(a6)
        list_add(&free_list, &(base->page_link));
ffffffffc02008c4:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc02008c8:	04d78a63          	beq	a5,a3,ffffffffc020091c <slub_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc02008cc:	fe878713          	addi	a4,a5,-24
ffffffffc02008d0:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02008d4:	4581                	li	a1,0
            if (base < page) {
ffffffffc02008d6:	00e56a63          	bltu	a0,a4,ffffffffc02008ea <slub_init_memmap+0x7e>
    return listelm->next;
ffffffffc02008da:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02008dc:	02d70263          	beq	a4,a3,ffffffffc0200900 <slub_init_memmap+0x94>
    for (; p != base + n; p++) {
ffffffffc02008e0:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02008e2:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02008e6:	fee57ae3          	bgeu	a0,a4,ffffffffc02008da <slub_init_memmap+0x6e>
ffffffffc02008ea:	c199                	beqz	a1,ffffffffc02008f0 <slub_init_memmap+0x84>
ffffffffc02008ec:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02008f0:	6398                	ld	a4,0(a5)
}
ffffffffc02008f2:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02008f4:	e390                	sd	a2,0(a5)
ffffffffc02008f6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02008f8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02008fa:	ed18                	sd	a4,24(a0)
ffffffffc02008fc:	0141                	addi	sp,sp,16
ffffffffc02008fe:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200900:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200902:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200904:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200906:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200908:	00d70663          	beq	a4,a3,ffffffffc0200914 <slub_init_memmap+0xa8>
    prev->next = next->prev = elm;
ffffffffc020090c:	8832                	mv	a6,a2
ffffffffc020090e:	4585                	li	a1,1
    for (; p != base + n; p++) {
ffffffffc0200910:	87ba                	mv	a5,a4
ffffffffc0200912:	bfc1                	j	ffffffffc02008e2 <slub_init_memmap+0x76>
}
ffffffffc0200914:	60a2                	ld	ra,8(sp)
ffffffffc0200916:	e290                	sd	a2,0(a3)
ffffffffc0200918:	0141                	addi	sp,sp,16
ffffffffc020091a:	8082                	ret
ffffffffc020091c:	60a2                	ld	ra,8(sp)
ffffffffc020091e:	e390                	sd	a2,0(a5)
ffffffffc0200920:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200922:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200924:	ed1c                	sd	a5,24(a0)
ffffffffc0200926:	0141                	addi	sp,sp,16
ffffffffc0200928:	8082                	ret
        assert(PageReserved(p));
ffffffffc020092a:	00001697          	auipc	a3,0x1
ffffffffc020092e:	5c668693          	addi	a3,a3,1478 # ffffffffc0201ef0 <etext+0x3e6>
ffffffffc0200932:	00001617          	auipc	a2,0x1
ffffffffc0200936:	58e60613          	addi	a2,a2,1422 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc020093a:	1a300593          	li	a1,419
ffffffffc020093e:	00001517          	auipc	a0,0x1
ffffffffc0200942:	59a50513          	addi	a0,a0,1434 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0200946:	87dff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc020094a:	00001697          	auipc	a3,0x1
ffffffffc020094e:	56e68693          	addi	a3,a3,1390 # ffffffffc0201eb8 <etext+0x3ae>
ffffffffc0200952:	00001617          	auipc	a2,0x1
ffffffffc0200956:	56e60613          	addi	a2,a2,1390 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc020095a:	1a000593          	li	a1,416
ffffffffc020095e:	00001517          	auipc	a0,0x1
ffffffffc0200962:	57a50513          	addi	a0,a0,1402 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0200966:	85dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020096a <slub_free_pages.part.0>:
    for (; p != base + n; p++) {
ffffffffc020096a:	00259793          	slli	a5,a1,0x2
ffffffffc020096e:	97ae                	add	a5,a5,a1
ffffffffc0200970:	078e                	slli	a5,a5,0x3
ffffffffc0200972:	00f506b3          	add	a3,a0,a5
ffffffffc0200976:	87aa                	mv	a5,a0
ffffffffc0200978:	00d50e63          	beq	a0,a3,ffffffffc0200994 <slub_free_pages.part.0+0x2a>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020097c:	6798                	ld	a4,8(a5)
ffffffffc020097e:	8b0d                	andi	a4,a4,3
ffffffffc0200980:	12071063          	bnez	a4,ffffffffc0200aa0 <slub_free_pages.part.0+0x136>
        p->flags = 0;
ffffffffc0200984:	0007b423          	sd	zero,8(a5)
ffffffffc0200988:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc020098c:	02878793          	addi	a5,a5,40
ffffffffc0200990:	fed796e3          	bne	a5,a3,ffffffffc020097c <slub_free_pages.part.0+0x12>
    nr_free += n;
ffffffffc0200994:	00006697          	auipc	a3,0x6
ffffffffc0200998:	b5c68693          	addi	a3,a3,-1188 # ffffffffc02064f0 <nr_free>
    SetPageProperty(base);
ffffffffc020099c:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc02009a0:	4298                	lw	a4,0(a3)
    return list->next == list;
ffffffffc02009a2:	00005617          	auipc	a2,0x5
ffffffffc02009a6:	67660613          	addi	a2,a2,1654 # ffffffffc0206018 <free_list>
    base->property = n;
ffffffffc02009aa:	2581                	sext.w	a1,a1
ffffffffc02009ac:	661c                	ld	a5,8(a2)
    SetPageProperty(base);
ffffffffc02009ae:	0028e813          	ori	a6,a7,2
    nr_free += n;
ffffffffc02009b2:	9f2d                	addw	a4,a4,a1
    base->property = n;
ffffffffc02009b4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02009b6:	01053423          	sd	a6,8(a0)
    nr_free += n;
ffffffffc02009ba:	c298                	sw	a4,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02009bc:	00c79763          	bne	a5,a2,ffffffffc02009ca <slub_free_pages.part.0+0x60>
ffffffffc02009c0:	a071                	j	ffffffffc0200a4c <slub_free_pages.part.0+0xe2>
    return listelm->next;
ffffffffc02009c2:	6794                	ld	a3,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02009c4:	08c68b63          	beq	a3,a2,ffffffffc0200a5a <slub_free_pages.part.0+0xf0>
ffffffffc02009c8:	87b6                	mv	a5,a3
            struct Page* page = le2page(le, page_link);
ffffffffc02009ca:	fe878713          	addi	a4,a5,-24
ffffffffc02009ce:	86ba                	mv	a3,a4
            if (base < page) {
ffffffffc02009d0:	fee579e3          	bgeu	a0,a4,ffffffffc02009c2 <slub_free_pages.part.0+0x58>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02009d4:	0007b803          	ld	a6,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc02009d8:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02009dc:	e398                	sd	a4,0(a5)
ffffffffc02009de:	00e83423          	sd	a4,8(a6)
    elm->next = next;
ffffffffc02009e2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02009e4:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc02009e8:	02c80563          	beq	a6,a2,ffffffffc0200a12 <slub_free_pages.part.0+0xa8>
        if (p + p->property == base) {
ffffffffc02009ec:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc02009f0:	fe880713          	addi	a4,a6,-24
        if (p + p->property == base) {
ffffffffc02009f4:	020e1313          	slli	t1,t3,0x20
ffffffffc02009f8:	02035313          	srli	t1,t1,0x20
ffffffffc02009fc:	00231693          	slli	a3,t1,0x2
ffffffffc0200a00:	969a                	add	a3,a3,t1
ffffffffc0200a02:	068e                	slli	a3,a3,0x3
ffffffffc0200a04:	96ba                	add	a3,a3,a4
ffffffffc0200a06:	06d50f63          	beq	a0,a3,ffffffffc0200a84 <slub_free_pages.part.0+0x11a>
    if (le != &free_list) {
ffffffffc0200a0a:	fe878693          	addi	a3,a5,-24
ffffffffc0200a0e:	00c78d63          	beq	a5,a2,ffffffffc0200a28 <slub_free_pages.part.0+0xbe>
        if (base + base->property == p) {
ffffffffc0200a12:	490c                	lw	a1,16(a0)
ffffffffc0200a14:	02059613          	slli	a2,a1,0x20
ffffffffc0200a18:	9201                	srli	a2,a2,0x20
ffffffffc0200a1a:	00261713          	slli	a4,a2,0x2
ffffffffc0200a1e:	9732                	add	a4,a4,a2
ffffffffc0200a20:	070e                	slli	a4,a4,0x3
ffffffffc0200a22:	972a                	add	a4,a4,a0
ffffffffc0200a24:	00e68363          	beq	a3,a4,ffffffffc0200a2a <slub_free_pages.part.0+0xc0>
ffffffffc0200a28:	8082                	ret
            base->property += p->property;
ffffffffc0200a2a:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200a2e:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a32:	0007b803          	ld	a6,0(a5)
ffffffffc0200a36:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200a38:	9db5                	addw	a1,a1,a3
ffffffffc0200a3a:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200a3c:	9b75                	andi	a4,a4,-3
ffffffffc0200a3e:	fee7b823          	sd	a4,-16(a5)
    prev->next = next;
ffffffffc0200a42:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200a46:	01063023          	sd	a6,0(a2)
ffffffffc0200a4a:	8082                	ret
        list_add(&free_list, &(base->page_link));
ffffffffc0200a4c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200a50:	e398                	sd	a4,0(a5)
ffffffffc0200a52:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200a54:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200a56:	ed1c                	sd	a5,24(a0)
    if (le != &free_list) {
ffffffffc0200a58:	8082                	ret
ffffffffc0200a5a:	883e                	mv	a6,a5
        if (p + p->property == base) {
ffffffffc0200a5c:	ff882e03          	lw	t3,-8(a6)
                list_add(le, &(base->page_link));
ffffffffc0200a60:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200a64:	e794                	sd	a3,8(a5)
        if (p + p->property == base) {
ffffffffc0200a66:	020e1313          	slli	t1,t3,0x20
ffffffffc0200a6a:	02035313          	srli	t1,t1,0x20
ffffffffc0200a6e:	e214                	sd	a3,0(a2)
ffffffffc0200a70:	00231693          	slli	a3,t1,0x2
ffffffffc0200a74:	969a                	add	a3,a3,t1
ffffffffc0200a76:	068e                	slli	a3,a3,0x3
    elm->prev = prev;
ffffffffc0200a78:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc0200a7a:	f110                	sd	a2,32(a0)
ffffffffc0200a7c:	96ba                	add	a3,a3,a4
    elm->prev = prev;
ffffffffc0200a7e:	87b2                	mv	a5,a2
ffffffffc0200a80:	f8d515e3          	bne	a0,a3,ffffffffc0200a0a <slub_free_pages.part.0+0xa0>
            p->property += base->property;
ffffffffc0200a84:	01c585bb          	addw	a1,a1,t3
ffffffffc0200a88:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200a8c:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200a90:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200a94:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200a98:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200a9c:	853a                	mv	a0,a4
ffffffffc0200a9e:	b7b5                	j	ffffffffc0200a0a <slub_free_pages.part.0+0xa0>
void slub_free_pages(struct Page *base, size_t n) {
ffffffffc0200aa0:	1141                	addi	sp,sp,-16
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200aa2:	00001697          	auipc	a3,0x1
ffffffffc0200aa6:	45e68693          	addi	a3,a3,1118 # ffffffffc0201f00 <etext+0x3f6>
ffffffffc0200aaa:	00001617          	auipc	a2,0x1
ffffffffc0200aae:	41660613          	addi	a2,a2,1046 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0200ab2:	1de00593          	li	a1,478
ffffffffc0200ab6:	00001517          	auipc	a0,0x1
ffffffffc0200aba:	42250513          	addi	a0,a0,1058 # ffffffffc0201ed8 <etext+0x3ce>
void slub_free_pages(struct Page *base, size_t n) {
ffffffffc0200abe:	e406                	sd	ra,8(sp)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ac0:	f02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200ac4 <slub_free_pages>:
    assert(n > 0);
ffffffffc0200ac4:	c191                	beqz	a1,ffffffffc0200ac8 <slub_free_pages+0x4>
ffffffffc0200ac6:	b555                	j	ffffffffc020096a <slub_free_pages.part.0>
void slub_free_pages(struct Page *base, size_t n) {
ffffffffc0200ac8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200aca:	00001697          	auipc	a3,0x1
ffffffffc0200ace:	3ee68693          	addi	a3,a3,1006 # ffffffffc0201eb8 <etext+0x3ae>
ffffffffc0200ad2:	00001617          	auipc	a2,0x1
ffffffffc0200ad6:	3ee60613          	addi	a2,a2,1006 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0200ada:	1db00593          	li	a1,475
ffffffffc0200ade:	00001517          	auipc	a0,0x1
ffffffffc0200ae2:	3fa50513          	addi	a0,a0,1018 # ffffffffc0201ed8 <etext+0x3ce>
void slub_free_pages(struct Page *base, size_t n) {
ffffffffc0200ae6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ae8:	edaff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200aec <slub_init.part.0>:
void slub_init(void) {
ffffffffc0200aec:	715d                	addi	sp,sp,-80
    cprintf("SLUB: Initializing SLUB allocator\n");
ffffffffc0200aee:	00001517          	auipc	a0,0x1
ffffffffc0200af2:	43a50513          	addi	a0,a0,1082 # ffffffffc0201f28 <etext+0x41e>
void slub_init(void) {
ffffffffc0200af6:	e0a2                	sd	s0,64(sp)
ffffffffc0200af8:	fc26                	sd	s1,56(sp)
ffffffffc0200afa:	f84a                	sd	s2,48(sp)
ffffffffc0200afc:	f44e                	sd	s3,40(sp)
ffffffffc0200afe:	f052                	sd	s4,32(sp)
ffffffffc0200b00:	ec56                	sd	s5,24(sp)
ffffffffc0200b02:	e85a                	sd	s6,16(sp)
ffffffffc0200b04:	e45e                	sd	s7,8(sp)
ffffffffc0200b06:	e062                	sd	s8,0(sp)
ffffffffc0200b08:	e486                	sd	ra,72(sp)
    cprintf("SLUB: Initializing SLUB allocator\n");
ffffffffc0200b0a:	e42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    elm->prev = elm->next = elm;
ffffffffc0200b0e:	00005797          	auipc	a5,0x5
ffffffffc0200b12:	50a78793          	addi	a5,a5,1290 # ffffffffc0206018 <free_list>
ffffffffc0200b16:	e79c                	sd	a5,8(a5)
ffffffffc0200b18:	e39c                	sd	a5,0(a5)
    nr_free = 0;
ffffffffc0200b1a:	00006797          	auipc	a5,0x6
ffffffffc0200b1e:	9c07ab23          	sw	zero,-1578(a5) # ffffffffc02064f0 <nr_free>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200b22:	00005417          	auipc	s0,0x5
ffffffffc0200b26:	64640413          	addi	s0,s0,1606 # ffffffffc0206168 <slub_caches+0x20>
ffffffffc0200b2a:	00005917          	auipc	s2,0x5
ffffffffc0200b2e:	4fe90913          	addi	s2,s2,1278 # ffffffffc0206028 <names.0>
ffffffffc0200b32:	00002997          	auipc	s3,0x2
ffffffffc0200b36:	84e98993          	addi	s3,s3,-1970 # ffffffffc0202380 <slub_sizes>
    nr_free = 0;
ffffffffc0200b3a:	47a1                	li	a5,8
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200b3c:	4481                	li	s1,0
        cache->align = 8;  // 默认8字节对齐
ffffffffc0200b3e:	4c21                	li	s8,8
        cache->objects_per_page = PGSIZE / cache->size;
ffffffffc0200b40:	6b85                	lui	s7,0x1
        snprintf(names[i], 32, "slub-%d", (int)cache->size);
ffffffffc0200b42:	00001b17          	auipc	s6,0x1
ffffffffc0200b46:	40eb0b13          	addi	s6,s6,1038 # ffffffffc0201f50 <etext+0x446>
        cprintf("SLUB: Cache[%d] initialized: size=%d, objects_per_page=%d\n", 
ffffffffc0200b4a:	00001a97          	auipc	s5,0x1
ffffffffc0200b4e:	40ea8a93          	addi	s5,s5,1038 # ffffffffc0201f58 <etext+0x44e>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200b52:	4a25                	li	s4,9
ffffffffc0200b54:	a019                	j	ffffffffc0200b5a <slub_init.part.0+0x6e>
        cache->size = slub_sizes[i];
ffffffffc0200b56:	0009b783          	ld	a5,0(s3)
        cache->objects_per_page = PGSIZE / cache->size;
ffffffffc0200b5a:	02fbd833          	divu	a6,s7,a5
ffffffffc0200b5e:	01040713          	addi	a4,s0,16
        cache->size = slub_sizes[i];
ffffffffc0200b62:	fef43423          	sd	a5,-24(s0)
ffffffffc0200b66:	ec18                	sd	a4,24(s0)
ffffffffc0200b68:	e818                	sd	a4,16(s0)
        cache->align = 8;  // 默认8字节对齐
ffffffffc0200b6a:	ff843823          	sd	s8,-16(s0)
        cache->nr_partial = 0;
ffffffffc0200b6e:	02043023          	sd	zero,32(s0)
        cache->nr_full = 0;
ffffffffc0200b72:	02043423          	sd	zero,40(s0)
        cache->total_objects = 0;
ffffffffc0200b76:	02043823          	sd	zero,48(s0)
        cache->used_objects = 0;
ffffffffc0200b7a:	02043c23          	sd	zero,56(s0)
ffffffffc0200b7e:	e400                	sd	s0,8(s0)
ffffffffc0200b80:	e000                	sd	s0,0(s0)
        snprintf(names[i], 32, "slub-%d", (int)cache->size);
ffffffffc0200b82:	0007869b          	sext.w	a3,a5
ffffffffc0200b86:	865a                	mv	a2,s6
ffffffffc0200b88:	02000593          	li	a1,32
ffffffffc0200b8c:	854a                	mv	a0,s2
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200b8e:	06040413          	addi	s0,s0,96
ffffffffc0200b92:	09a1                	addi	s3,s3,8
        cache->objects_per_page = PGSIZE / cache->size;
ffffffffc0200b94:	f9043c23          	sd	a6,-104(s0)
        snprintf(names[i], 32, "slub-%d", (int)cache->size);
ffffffffc0200b98:	687000ef          	jal	ra,ffffffffc0201a1e <snprintf>
        cprintf("SLUB: Cache[%d] initialized: size=%d, objects_per_page=%d\n", 
ffffffffc0200b9c:	f9843683          	ld	a3,-104(s0)
ffffffffc0200ba0:	f8843603          	ld	a2,-120(s0)
ffffffffc0200ba4:	85a6                	mv	a1,s1
ffffffffc0200ba6:	8556                	mv	a0,s5
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200ba8:	2485                	addiw	s1,s1,1
        cache->name = names[i];
ffffffffc0200baa:	f9243023          	sd	s2,-128(s0)
        cprintf("SLUB: Cache[%d] initialized: size=%d, objects_per_page=%d\n", 
ffffffffc0200bae:	d9eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200bb2:	02090913          	addi	s2,s2,32
ffffffffc0200bb6:	fb4490e3          	bne	s1,s4,ffffffffc0200b56 <slub_init.part.0+0x6a>
}
ffffffffc0200bba:	6406                	ld	s0,64(sp)
ffffffffc0200bbc:	60a6                	ld	ra,72(sp)
ffffffffc0200bbe:	74e2                	ld	s1,56(sp)
ffffffffc0200bc0:	7942                	ld	s2,48(sp)
ffffffffc0200bc2:	79a2                	ld	s3,40(sp)
ffffffffc0200bc4:	7a02                	ld	s4,32(sp)
ffffffffc0200bc6:	6ae2                	ld	s5,24(sp)
ffffffffc0200bc8:	6b42                	ld	s6,16(sp)
ffffffffc0200bca:	6ba2                	ld	s7,8(sp)
ffffffffc0200bcc:	6c02                	ld	s8,0(sp)
    slub_initialized = 1;
ffffffffc0200bce:	4785                	li	a5,1
ffffffffc0200bd0:	00006717          	auipc	a4,0x6
ffffffffc0200bd4:	92f72223          	sw	a5,-1756(a4) # ffffffffc02064f4 <slub_initialized>
    cprintf("SLUB: Initialization complete\n");
ffffffffc0200bd8:	00001517          	auipc	a0,0x1
ffffffffc0200bdc:	3c050513          	addi	a0,a0,960 # ffffffffc0201f98 <etext+0x48e>
}
ffffffffc0200be0:	6161                	addi	sp,sp,80
    cprintf("SLUB: Initialization complete\n");
ffffffffc0200be2:	d6aff06f          	j	ffffffffc020014c <cprintf>

ffffffffc0200be6 <slub_init>:
    if (slub_initialized) {
ffffffffc0200be6:	00006797          	auipc	a5,0x6
ffffffffc0200bea:	90e7a783          	lw	a5,-1778(a5) # ffffffffc02064f4 <slub_initialized>
ffffffffc0200bee:	c391                	beqz	a5,ffffffffc0200bf2 <slub_init+0xc>
}
ffffffffc0200bf0:	8082                	ret
ffffffffc0200bf2:	bded                	j	ffffffffc0200aec <slub_init.part.0>

ffffffffc0200bf4 <slub_alloc_object>:
static void *slub_alloc_object(struct slub_cache *cache) {
ffffffffc0200bf4:	1101                	addi	sp,sp,-32
ffffffffc0200bf6:	e04a                	sd	s2,0(sp)
    return list->next == list;
ffffffffc0200bf8:	02853903          	ld	s2,40(a0)
ffffffffc0200bfc:	e822                	sd	s0,16(sp)
ffffffffc0200bfe:	ec06                	sd	ra,24(sp)
ffffffffc0200c00:	e426                	sd	s1,8(sp)
    if (!list_empty(&cache->partial)) {
ffffffffc0200c02:	02050793          	addi	a5,a0,32
static void *slub_alloc_object(struct slub_cache *cache) {
ffffffffc0200c06:	842a                	mv	s0,a0
    if (!list_empty(&cache->partial)) {
ffffffffc0200c08:	06f90a63          	beq	s2,a5,ffffffffc0200c7c <slub_alloc_object+0x88>
    void *obj = sp->freelist;
ffffffffc0200c0c:	01893483          	ld	s1,24(s2)
    if (obj == NULL) {
ffffffffc0200c10:	12048063          	beqz	s1,ffffffffc0200d30 <slub_alloc_object+0x13c>
    sp->inuse++;
ffffffffc0200c14:	02095783          	lhu	a5,32(s2)
    cache->used_objects++;
ffffffffc0200c18:	6c38                	ld	a4,88(s0)
    sp->freelist = ((struct slub_object *)obj)->next;
ffffffffc0200c1a:	6090                	ld	a2,0(s1)
    sp->inuse++;
ffffffffc0200c1c:	2785                	addiw	a5,a5,1
ffffffffc0200c1e:	17c2                	slli	a5,a5,0x30
    if (sp->inuse == sp->objects) {
ffffffffc0200c20:	02295683          	lhu	a3,34(s2)
    sp->inuse++;
ffffffffc0200c24:	93c1                	srli	a5,a5,0x30
    sp->freelist = ((struct slub_object *)obj)->next;
ffffffffc0200c26:	00c93c23          	sd	a2,24(s2)
    sp->inuse++;
ffffffffc0200c2a:	02f91023          	sh	a5,32(s2)
    cache->used_objects++;
ffffffffc0200c2e:	0705                	addi	a4,a4,1
ffffffffc0200c30:	ec38                	sd	a4,88(s0)
    if (sp->inuse == sp->objects) {
ffffffffc0200c32:	02f69963          	bne	a3,a5,ffffffffc0200c64 <slub_alloc_object+0x70>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c36:	00893683          	ld	a3,8(s2)
ffffffffc0200c3a:	00093583          	ld	a1,0(s2)
        cache->nr_partial--;
ffffffffc0200c3e:	6038                	ld	a4,64(s0)
        cache->nr_full++;
ffffffffc0200c40:	643c                	ld	a5,72(s0)
    prev->next = next;
ffffffffc0200c42:	e594                	sd	a3,8(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c44:	7c10                	ld	a2,56(s0)
    next->prev = prev;
ffffffffc0200c46:	e28c                	sd	a1,0(a3)
        list_add(&cache->full, &sp->page_link);
ffffffffc0200c48:	03040693          	addi	a3,s0,48
    prev->next = next->prev = elm;
ffffffffc0200c4c:	01263023          	sd	s2,0(a2)
ffffffffc0200c50:	03243c23          	sd	s2,56(s0)
    elm->next = next;
ffffffffc0200c54:	00c93423          	sd	a2,8(s2)
    elm->prev = prev;
ffffffffc0200c58:	00d93023          	sd	a3,0(s2)
        cache->nr_partial--;
ffffffffc0200c5c:	177d                	addi	a4,a4,-1
        cache->nr_full++;
ffffffffc0200c5e:	0785                	addi	a5,a5,1
        cache->nr_partial--;
ffffffffc0200c60:	e038                	sd	a4,64(s0)
        cache->nr_full++;
ffffffffc0200c62:	e43c                	sd	a5,72(s0)
    memset(obj, 0, cache->size);
ffffffffc0200c64:	6410                	ld	a2,8(s0)
ffffffffc0200c66:	8526                	mv	a0,s1
ffffffffc0200c68:	4581                	li	a1,0
ffffffffc0200c6a:	68f000ef          	jal	ra,ffffffffc0201af8 <memset>
}
ffffffffc0200c6e:	60e2                	ld	ra,24(sp)
ffffffffc0200c70:	6442                	ld	s0,16(sp)
ffffffffc0200c72:	6902                	ld	s2,0(sp)
ffffffffc0200c74:	8526                	mv	a0,s1
ffffffffc0200c76:	64a2                	ld	s1,8(sp)
ffffffffc0200c78:	6105                	addi	sp,sp,32
ffffffffc0200c7a:	8082                	ret
    struct Page *page = slub_alloc_pages(1);
ffffffffc0200c7c:	4505                	li	a0,1
ffffffffc0200c7e:	b33ff0ef          	jal	ra,ffffffffc02007b0 <slub_alloc_pages>
    if (page == NULL) {
ffffffffc0200c82:	c55d                	beqz	a0,ffffffffc0200d30 <slub_alloc_object+0x13c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c84:	00006697          	auipc	a3,0x6
ffffffffc0200c88:	8446b683          	ld	a3,-1980(a3) # ffffffffc02064c8 <pages>
ffffffffc0200c8c:	40d506b3          	sub	a3,a0,a3
ffffffffc0200c90:	00002797          	auipc	a5,0x2
ffffffffc0200c94:	9887b783          	ld	a5,-1656(a5) # ffffffffc0202618 <nbase+0x8>
ffffffffc0200c98:	868d                	srai	a3,a3,0x3
ffffffffc0200c9a:	02f686b3          	mul	a3,a3,a5
ffffffffc0200c9e:	00002797          	auipc	a5,0x2
ffffffffc0200ca2:	9727b783          	ld	a5,-1678(a5) # ffffffffc0202610 <nbase>
    return KADDR(page2pa(page));
ffffffffc0200ca6:	00006717          	auipc	a4,0x6
ffffffffc0200caa:	81a73703          	ld	a4,-2022(a4) # ffffffffc02064c0 <npage>
ffffffffc0200cae:	96be                	add	a3,a3,a5
ffffffffc0200cb0:	00c69793          	slli	a5,a3,0xc
ffffffffc0200cb4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cb6:	06b2                	slli	a3,a3,0xc
ffffffffc0200cb8:	08e7f463          	bgeu	a5,a4,ffffffffc0200d40 <slub_alloc_object+0x14c>
    obj_start = (void *)ROUNDUP((uintptr_t)obj_start, cache->align);
ffffffffc0200cbc:	6818                	ld	a4,16(s0)
    return KADDR(page2pa(page));
ffffffffc0200cbe:	00006797          	auipc	a5,0x6
ffffffffc0200cc2:	82a7b783          	ld	a5,-2006(a5) # ffffffffc02064e8 <va_pa_offset>
ffffffffc0200cc6:	96be                	add	a3,a3,a5
    obj_start = (void *)ROUNDUP((uintptr_t)obj_start, cache->align);
ffffffffc0200cc8:	00e687b3          	add	a5,a3,a4
ffffffffc0200ccc:	02f78793          	addi	a5,a5,47
ffffffffc0200cd0:	02e7f733          	remu	a4,a5,a4
    sp->objects = cache->objects_per_page;
ffffffffc0200cd4:	01843883          	ld	a7,24(s0)
    sp->page = page;
ffffffffc0200cd8:	f688                	sd	a0,40(a3)
    sp->cache = cache;
ffffffffc0200cda:	ea80                	sd	s0,16(a3)
    sp->inuse = 0;
ffffffffc0200cdc:	02069023          	sh	zero,32(a3)
    sp->objects = cache->objects_per_page;
ffffffffc0200ce0:	03169123          	sh	a7,34(a3)
    for (int i = 0; i < cache->objects_per_page - 1; i++) {
ffffffffc0200ce4:	fff88313          	addi	t1,a7,-1
    obj_start = (void *)ROUNDUP((uintptr_t)obj_start, cache->align);
ffffffffc0200ce8:	40e78533          	sub	a0,a5,a4
    sp->freelist = obj_start;
ffffffffc0200cec:	ee88                	sd	a0,24(a3)
    for (int i = 0; i < cache->objects_per_page - 1; i++) {
ffffffffc0200cee:	02030063          	beqz	t1,ffffffffc0200d0e <slub_alloc_object+0x11a>
        obj->next = (struct slub_object *)((char *)current + cache->size);
ffffffffc0200cf2:	640c                	ld	a1,8(s0)
ffffffffc0200cf4:	fff8881b          	addiw	a6,a7,-1
    void *current = obj_start;
ffffffffc0200cf8:	87aa                	mv	a5,a0
    for (int i = 0; i < cache->objects_per_page - 1; i++) {
ffffffffc0200cfa:	4701                	li	a4,0
        obj->next = (struct slub_object *)((char *)current + cache->size);
ffffffffc0200cfc:	863e                	mv	a2,a5
ffffffffc0200cfe:	97ae                	add	a5,a5,a1
ffffffffc0200d00:	e21c                	sd	a5,0(a2)
    for (int i = 0; i < cache->objects_per_page - 1; i++) {
ffffffffc0200d02:	2705                	addiw	a4,a4,1
ffffffffc0200d04:	ff071ce3          	bne	a4,a6,ffffffffc0200cfc <slub_alloc_object+0x108>
        obj->next = (struct slub_object *)((char *)current + cache->size);
ffffffffc0200d08:	026585b3          	mul	a1,a1,t1
ffffffffc0200d0c:	952e                	add	a0,a0,a1
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d0e:	7410                	ld	a2,40(s0)
    cache->nr_partial++;
ffffffffc0200d10:	6038                	ld	a4,64(s0)
    ((struct slub_object *)current)->next = NULL;
ffffffffc0200d12:	00053023          	sd	zero,0(a0)
    cache->total_objects += cache->objects_per_page;
ffffffffc0200d16:	683c                	ld	a5,80(s0)
    prev->next = next->prev = elm;
ffffffffc0200d18:	e214                	sd	a3,0(a2)
ffffffffc0200d1a:	f414                	sd	a3,40(s0)
    elm->prev = prev;
ffffffffc0200d1c:	0126b023          	sd	s2,0(a3)
    elm->next = next;
ffffffffc0200d20:	e690                	sd	a2,8(a3)
    cache->nr_partial++;
ffffffffc0200d22:	0705                	addi	a4,a4,1
    cache->total_objects += cache->objects_per_page;
ffffffffc0200d24:	98be                	add	a7,a7,a5
    cache->nr_partial++;
ffffffffc0200d26:	e038                	sd	a4,64(s0)
    cache->total_objects += cache->objects_per_page;
ffffffffc0200d28:	05143823          	sd	a7,80(s0)
ffffffffc0200d2c:	8936                	mv	s2,a3
ffffffffc0200d2e:	bdf9                	j	ffffffffc0200c0c <slub_alloc_object+0x18>
}
ffffffffc0200d30:	60e2                	ld	ra,24(sp)
ffffffffc0200d32:	6442                	ld	s0,16(sp)
            return NULL;
ffffffffc0200d34:	4481                	li	s1,0
}
ffffffffc0200d36:	6902                	ld	s2,0(sp)
ffffffffc0200d38:	8526                	mv	a0,s1
ffffffffc0200d3a:	64a2                	ld	s1,8(sp)
ffffffffc0200d3c:	6105                	addi	sp,sp,32
ffffffffc0200d3e:	8082                	ret
    return KADDR(page2pa(page));
ffffffffc0200d40:	00001617          	auipc	a2,0x1
ffffffffc0200d44:	27860613          	addi	a2,a2,632 # ffffffffc0201fb8 <etext+0x4ae>
ffffffffc0200d48:	45a5                	li	a1,9
ffffffffc0200d4a:	00001517          	auipc	a0,0x1
ffffffffc0200d4e:	18e50513          	addi	a0,a0,398 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0200d52:	c70ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d56 <kva2page>:
struct Page *kva2page(void *kva) {
ffffffffc0200d56:	1141                	addi	sp,sp,-16
ffffffffc0200d58:	e406                	sd	ra,8(sp)
    return pa2page(PADDR(kva));
ffffffffc0200d5a:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d5e:	02f56f63          	bltu	a0,a5,ffffffffc0200d9c <kva2page+0x46>
ffffffffc0200d62:	00005697          	auipc	a3,0x5
ffffffffc0200d66:	7866b683          	ld	a3,1926(a3) # ffffffffc02064e8 <va_pa_offset>
ffffffffc0200d6a:	8d15                	sub	a0,a0,a3
    if (PPN(pa) >= npage) {
ffffffffc0200d6c:	8131                	srli	a0,a0,0xc
ffffffffc0200d6e:	00005797          	auipc	a5,0x5
ffffffffc0200d72:	7527b783          	ld	a5,1874(a5) # ffffffffc02064c0 <npage>
ffffffffc0200d76:	02f57f63          	bgeu	a0,a5,ffffffffc0200db4 <kva2page+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0200d7a:	00002697          	auipc	a3,0x2
ffffffffc0200d7e:	8966b683          	ld	a3,-1898(a3) # ffffffffc0202610 <nbase>
ffffffffc0200d82:	8d15                	sub	a0,a0,a3
}
ffffffffc0200d84:	60a2                	ld	ra,8(sp)
ffffffffc0200d86:	00251793          	slli	a5,a0,0x2
ffffffffc0200d8a:	953e                	add	a0,a0,a5
ffffffffc0200d8c:	050e                	slli	a0,a0,0x3
ffffffffc0200d8e:	00005797          	auipc	a5,0x5
ffffffffc0200d92:	73a7b783          	ld	a5,1850(a5) # ffffffffc02064c8 <pages>
ffffffffc0200d96:	953e                	add	a0,a0,a5
ffffffffc0200d98:	0141                	addi	sp,sp,16
ffffffffc0200d9a:	8082                	ret
    return pa2page(PADDR(kva));
ffffffffc0200d9c:	86aa                	mv	a3,a0
ffffffffc0200d9e:	00001617          	auipc	a2,0x1
ffffffffc0200da2:	06260613          	addi	a2,a2,98 # ffffffffc0201e00 <etext+0x2f6>
ffffffffc0200da6:	45b5                	li	a1,13
ffffffffc0200da8:	00001517          	auipc	a0,0x1
ffffffffc0200dac:	13050513          	addi	a0,a0,304 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0200db0:	c12ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200db4:	00001617          	auipc	a2,0x1
ffffffffc0200db8:	07460613          	addi	a2,a2,116 # ffffffffc0201e28 <etext+0x31e>
ffffffffc0200dbc:	06900593          	li	a1,105
ffffffffc0200dc0:	00001517          	auipc	a0,0x1
ffffffffc0200dc4:	08850513          	addi	a0,a0,136 # ffffffffc0201e48 <etext+0x33e>
ffffffffc0200dc8:	bfaff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200dcc <slub_free>:
    if (ptr == NULL) {
ffffffffc0200dcc:	cd29                	beqz	a0,ffffffffc0200e26 <slub_free+0x5a>
    uintptr_t page_addr = ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0200dce:	77fd                	lui	a5,0xfffff
ffffffffc0200dd0:	8fe9                	and	a5,a5,a0
    if (sp->cache != NULL && sp->cache->size <= SLUB_MAX_SIZE) {
ffffffffc0200dd2:	6b98                	ld	a4,16(a5)
ffffffffc0200dd4:	c719                	beqz	a4,ffffffffc0200de2 <slub_free+0x16>
ffffffffc0200dd6:	6710                	ld	a2,8(a4)
ffffffffc0200dd8:	6685                	lui	a3,0x1
ffffffffc0200dda:	80068693          	addi	a3,a3,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0200dde:	00c6fa63          	bgeu	a3,a2,ffffffffc0200df2 <slub_free+0x26>
void slub_free(void *ptr) {
ffffffffc0200de2:	1141                	addi	sp,sp,-16
ffffffffc0200de4:	e406                	sd	ra,8(sp)
        struct Page *page = kva2page(ptr);
ffffffffc0200de6:	f71ff0ef          	jal	ra,ffffffffc0200d56 <kva2page>
}
ffffffffc0200dea:	60a2                	ld	ra,8(sp)
ffffffffc0200dec:	4585                	li	a1,1
ffffffffc0200dee:	0141                	addi	sp,sp,16
ffffffffc0200df0:	bead                	j	ffffffffc020096a <slub_free_pages.part.0>
    sp->inuse--;
ffffffffc0200df2:	0207d683          	lhu	a3,32(a5) # fffffffffffff020 <end+0x3fdf8b28>
    obj->next = sp->freelist;
ffffffffc0200df6:	0187b803          	ld	a6,24(a5)
    cache->used_objects--;
ffffffffc0200dfa:	6f30                	ld	a2,88(a4)
    sp->inuse--;
ffffffffc0200dfc:	36fd                	addiw	a3,a3,-1
    if (sp->inuse == sp->objects - 1) {
ffffffffc0200dfe:	0227d583          	lhu	a1,34(a5)
    sp->inuse--;
ffffffffc0200e02:	16c2                	slli	a3,a3,0x30
    obj->next = sp->freelist;
ffffffffc0200e04:	01053023          	sd	a6,0(a0)
    sp->inuse--;
ffffffffc0200e08:	92c1                	srli	a3,a3,0x30
    cache->used_objects--;
ffffffffc0200e0a:	167d                	addi	a2,a2,-1
    sp->freelist = obj;
ffffffffc0200e0c:	ef88                	sd	a0,24(a5)
    sp->inuse--;
ffffffffc0200e0e:	02d79023          	sh	a3,32(a5)
    cache->used_objects--;
ffffffffc0200e12:	ef30                	sd	a2,88(a4)
    if (sp->inuse == sp->objects - 1) {
ffffffffc0200e14:	fff5861b          	addiw	a2,a1,-1
ffffffffc0200e18:	00d60863          	beq	a2,a3,ffffffffc0200e28 <slub_free+0x5c>
    else if (sp->inuse == 0 && cache->nr_partial > 1) {
ffffffffc0200e1c:	e689                	bnez	a3,ffffffffc0200e26 <slub_free+0x5a>
ffffffffc0200e1e:	6334                	ld	a3,64(a4)
ffffffffc0200e20:	4605                	li	a2,1
ffffffffc0200e22:	02d66963          	bltu	a2,a3,ffffffffc0200e54 <slub_free+0x88>
ffffffffc0200e26:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e28:	6788                	ld	a0,8(a5)
ffffffffc0200e2a:	0007b803          	ld	a6,0(a5)
        cache->nr_full--;
ffffffffc0200e2e:	6730                	ld	a2,72(a4)
        cache->nr_partial++;
ffffffffc0200e30:	6334                	ld	a3,64(a4)
    prev->next = next;
ffffffffc0200e32:	00a83423          	sd	a0,8(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e36:	770c                	ld	a1,40(a4)
    next->prev = prev;
ffffffffc0200e38:	01053023          	sd	a6,0(a0)
        list_add(&cache->partial, &sp->page_link);
ffffffffc0200e3c:	02070513          	addi	a0,a4,32
    prev->next = next->prev = elm;
ffffffffc0200e40:	e19c                	sd	a5,0(a1)
ffffffffc0200e42:	f71c                	sd	a5,40(a4)
    elm->next = next;
ffffffffc0200e44:	e78c                	sd	a1,8(a5)
    elm->prev = prev;
ffffffffc0200e46:	e388                	sd	a0,0(a5)
        cache->nr_full--;
ffffffffc0200e48:	167d                	addi	a2,a2,-1
        cache->nr_partial++;
ffffffffc0200e4a:	00168793          	addi	a5,a3,1
        cache->nr_full--;
ffffffffc0200e4e:	e730                	sd	a2,72(a4)
        cache->nr_partial++;
ffffffffc0200e50:	e33c                	sd	a5,64(a4)
ffffffffc0200e52:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e54:	0007b883          	ld	a7,0(a5)
ffffffffc0200e58:	0087b803          	ld	a6,8(a5)
    cache->total_objects -= sp->objects;
ffffffffc0200e5c:	6b30                	ld	a2,80(a4)
ffffffffc0200e5e:	7788                	ld	a0,40(a5)
    prev->next = next;
ffffffffc0200e60:	0108b423          	sd	a6,8(a7)
    next->prev = prev;
ffffffffc0200e64:	01183023          	sd	a7,0(a6)
ffffffffc0200e68:	40b605b3          	sub	a1,a2,a1
    cache->nr_partial--;
ffffffffc0200e6c:	16fd                	addi	a3,a3,-1
    cache->total_objects -= sp->objects;
ffffffffc0200e6e:	eb2c                	sd	a1,80(a4)
    cache->nr_partial--;
ffffffffc0200e70:	e334                	sd	a3,64(a4)
    assert(n > 0);
ffffffffc0200e72:	4585                	li	a1,1
ffffffffc0200e74:	bcdd                	j	ffffffffc020096a <slub_free_pages.part.0>

ffffffffc0200e76 <slub_print_info>:
void slub_print_info(void) {
ffffffffc0200e76:	1101                	addi	sp,sp,-32
    cprintf("\n========== SLUB Allocator Info ==========\n");
ffffffffc0200e78:	00001517          	auipc	a0,0x1
ffffffffc0200e7c:	16850513          	addi	a0,a0,360 # ffffffffc0201fe0 <etext+0x4d6>
void slub_print_info(void) {
ffffffffc0200e80:	e822                	sd	s0,16(sp)
ffffffffc0200e82:	e426                	sd	s1,8(sp)
ffffffffc0200e84:	e04a                	sd	s2,0(sp)
ffffffffc0200e86:	ec06                	sd	ra,24(sp)
ffffffffc0200e88:	00005417          	auipc	s0,0x5
ffffffffc0200e8c:	2c040413          	addi	s0,s0,704 # ffffffffc0206148 <slub_caches>
    cprintf("\n========== SLUB Allocator Info ==========\n");
ffffffffc0200e90:	abcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200e94:	00005917          	auipc	s2,0x5
ffffffffc0200e98:	61490913          	addi	s2,s2,1556 # ffffffffc02064a8 <is_panic>
        cprintf("Cache[%s]: size=%d, partial=%d, full=%d, "
ffffffffc0200e9c:	00001497          	auipc	s1,0x1
ffffffffc0200ea0:	17448493          	addi	s1,s1,372 # ffffffffc0202010 <etext+0x506>
ffffffffc0200ea4:	05843803          	ld	a6,88(s0)
ffffffffc0200ea8:	683c                	ld	a5,80(s0)
ffffffffc0200eaa:	6438                	ld	a4,72(s0)
ffffffffc0200eac:	6034                	ld	a3,64(s0)
ffffffffc0200eae:	6410                	ld	a2,8(s0)
ffffffffc0200eb0:	600c                	ld	a1,0(s0)
ffffffffc0200eb2:	8526                	mv	a0,s1
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200eb4:	06040413          	addi	s0,s0,96
        cprintf("Cache[%s]: size=%d, partial=%d, full=%d, "
ffffffffc0200eb8:	a94ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200ebc:	ff2414e3          	bne	s0,s2,ffffffffc0200ea4 <slub_print_info+0x2e>
}
ffffffffc0200ec0:	6442                	ld	s0,16(sp)
ffffffffc0200ec2:	60e2                	ld	ra,24(sp)
ffffffffc0200ec4:	64a2                	ld	s1,8(sp)
ffffffffc0200ec6:	6902                	ld	s2,0(sp)
    cprintf("==========================================\n\n");
ffffffffc0200ec8:	00001517          	auipc	a0,0x1
ffffffffc0200ecc:	19050513          	addi	a0,a0,400 # ffffffffc0202058 <etext+0x54e>
}
ffffffffc0200ed0:	6105                	addi	sp,sp,32
    cprintf("==========================================\n\n");
ffffffffc0200ed2:	a7aff06f          	j	ffffffffc020014c <cprintf>

ffffffffc0200ed6 <slub_check>:
void slub_check(void) {
ffffffffc0200ed6:	c9010113          	addi	sp,sp,-880
    cprintf("\n========== SLUB Allocator Test ==========\n");
ffffffffc0200eda:	00001517          	auipc	a0,0x1
ffffffffc0200ede:	1ae50513          	addi	a0,a0,430 # ffffffffc0202088 <etext+0x57e>
void slub_check(void) {
ffffffffc0200ee2:	36113423          	sd	ra,872(sp)
ffffffffc0200ee6:	35313423          	sd	s3,840(sp)
ffffffffc0200eea:	36813023          	sd	s0,864(sp)
ffffffffc0200eee:	34913c23          	sd	s1,856(sp)
ffffffffc0200ef2:	35213823          	sd	s2,848(sp)
ffffffffc0200ef6:	35413023          	sd	s4,832(sp)
ffffffffc0200efa:	33513c23          	sd	s5,824(sp)
ffffffffc0200efe:	33613823          	sd	s6,816(sp)
ffffffffc0200f02:	33713423          	sd	s7,808(sp)
ffffffffc0200f06:	33813023          	sd	s8,800(sp)
    cprintf("\n========== SLUB Allocator Test ==========\n");
ffffffffc0200f0a:	a42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Test 1: Basic allocation and free\n");
ffffffffc0200f0e:	00001517          	auipc	a0,0x1
ffffffffc0200f12:	1aa50513          	addi	a0,a0,426 # ffffffffc02020b8 <etext+0x5ae>
    if (!slub_initialized) {
ffffffffc0200f16:	00005997          	auipc	s3,0x5
ffffffffc0200f1a:	5de98993          	addi	s3,s3,1502 # ffffffffc02064f4 <slub_initialized>
    cprintf("Test 1: Basic allocation and free\n");
ffffffffc0200f1e:	a2eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!slub_initialized) {
ffffffffc0200f22:	0009a783          	lw	a5,0(s3)
ffffffffc0200f26:	4e078963          	beqz	a5,ffffffffc0201418 <slub_check+0x542>
    return slub_alloc_object(cache);
ffffffffc0200f2a:	00005517          	auipc	a0,0x5
ffffffffc0200f2e:	27e50513          	addi	a0,a0,638 # ffffffffc02061a8 <slub_caches+0x60>
ffffffffc0200f32:	cc3ff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
    if (!slub_initialized) {
ffffffffc0200f36:	0009a783          	lw	a5,0(s3)
    return slub_alloc_object(cache);
ffffffffc0200f3a:	842a                	mv	s0,a0
    if (!slub_initialized) {
ffffffffc0200f3c:	4c078b63          	beqz	a5,ffffffffc0201412 <slub_check+0x53c>
        if (slub_sizes[i] >= size) {
ffffffffc0200f40:	00001a97          	auipc	s5,0x1
ffffffffc0200f44:	440a8a93          	addi	s5,s5,1088 # ffffffffc0202380 <slub_sizes>
void slub_check(void) {
ffffffffc0200f48:	8756                	mv	a4,s5
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200f4a:	4781                	li	a5,0
ffffffffc0200f4c:	4625                	li	a2,9
        if (slub_sizes[i] >= size) {
ffffffffc0200f4e:	45cd                	li	a1,19
ffffffffc0200f50:	a029                	j	ffffffffc0200f5a <slub_check+0x84>
ffffffffc0200f52:	6714                	ld	a3,8(a4)
ffffffffc0200f54:	0721                	addi	a4,a4,8
ffffffffc0200f56:	04d5ed63          	bltu	a1,a3,ffffffffc0200fb0 <slub_check+0xda>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200f5a:	2785                	addiw	a5,a5,1
ffffffffc0200f5c:	fec79be3          	bne	a5,a2,ffffffffc0200f52 <slub_check+0x7c>
    if (!slub_initialized) {
ffffffffc0200f60:	0009a783          	lw	a5,0(s3)
        return NULL;
ffffffffc0200f64:	4481                	li	s1,0
    if (!slub_initialized) {
ffffffffc0200f66:	c7a5                	beqz	a5,ffffffffc0200fce <slub_check+0xf8>
        return NULL;
ffffffffc0200f68:	00001717          	auipc	a4,0x1
ffffffffc0200f6c:	41870713          	addi	a4,a4,1048 # ffffffffc0202380 <slub_sizes>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200f70:	4781                	li	a5,0
ffffffffc0200f72:	4625                	li	a2,9
        if (slub_sizes[i] >= size) {
ffffffffc0200f74:	06300593          	li	a1,99
ffffffffc0200f78:	a029                	j	ffffffffc0200f82 <slub_check+0xac>
ffffffffc0200f7a:	6714                	ld	a3,8(a4)
ffffffffc0200f7c:	0721                	addi	a4,a4,8
ffffffffc0200f7e:	04d5eb63          	bltu	a1,a3,ffffffffc0200fd4 <slub_check+0xfe>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0200f82:	2785                	addiw	a5,a5,1
ffffffffc0200f84:	fec79be3          	bne	a5,a2,ffffffffc0200f7a <slub_check+0xa4>
    assert(p1 != NULL);
ffffffffc0200f88:	66040763          	beqz	s0,ffffffffc02015f6 <slub_check+0x720>
    assert(p2 != NULL);
ffffffffc0200f8c:	64048563          	beqz	s1,ffffffffc02015d6 <slub_check+0x700>
    assert(p3 != NULL);
ffffffffc0200f90:	00001697          	auipc	a3,0x1
ffffffffc0200f94:	15068693          	addi	a3,a3,336 # ffffffffc02020e0 <etext+0x5d6>
ffffffffc0200f98:	00001617          	auipc	a2,0x1
ffffffffc0200f9c:	f2860613          	addi	a2,a2,-216 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0200fa0:	12000593          	li	a1,288
ffffffffc0200fa4:	00001517          	auipc	a0,0x1
ffffffffc0200fa8:	f3450513          	addi	a0,a0,-204 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0200fac:	a16ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            return &slub_caches[i];
ffffffffc0200fb0:	00179713          	slli	a4,a5,0x1
ffffffffc0200fb4:	97ba                	add	a5,a5,a4
ffffffffc0200fb6:	0796                	slli	a5,a5,0x5
ffffffffc0200fb8:	00005517          	auipc	a0,0x5
ffffffffc0200fbc:	19050513          	addi	a0,a0,400 # ffffffffc0206148 <slub_caches>
    return slub_alloc_object(cache);
ffffffffc0200fc0:	953e                	add	a0,a0,a5
ffffffffc0200fc2:	c33ff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
    if (!slub_initialized) {
ffffffffc0200fc6:	0009a783          	lw	a5,0(s3)
    return slub_alloc_object(cache);
ffffffffc0200fca:	84aa                	mv	s1,a0
    if (!slub_initialized) {
ffffffffc0200fcc:	ffd1                	bnez	a5,ffffffffc0200f68 <slub_check+0x92>
    if (slub_initialized) {
ffffffffc0200fce:	b1fff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc0200fd2:	bf59                	j	ffffffffc0200f68 <slub_check+0x92>
            return &slub_caches[i];
ffffffffc0200fd4:	00179513          	slli	a0,a5,0x1
ffffffffc0200fd8:	97aa                	add	a5,a5,a0
ffffffffc0200fda:	00579513          	slli	a0,a5,0x5
ffffffffc0200fde:	00005a17          	auipc	s4,0x5
ffffffffc0200fe2:	16aa0a13          	addi	s4,s4,362 # ffffffffc0206148 <slub_caches>
    return slub_alloc_object(cache);
ffffffffc0200fe6:	9552                	add	a0,a0,s4
ffffffffc0200fe8:	c0dff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
ffffffffc0200fec:	892a                	mv	s2,a0
    assert(p1 != NULL);
ffffffffc0200fee:	60040463          	beqz	s0,ffffffffc02015f6 <slub_check+0x720>
    assert(p2 != NULL);
ffffffffc0200ff2:	5e048263          	beqz	s1,ffffffffc02015d6 <slub_check+0x700>
    assert(p3 != NULL);
ffffffffc0200ff6:	dd49                	beqz	a0,ffffffffc0200f90 <slub_check+0xba>
    assert(p1 != p2 && p2 != p3 && p1 != p3);
ffffffffc0200ff8:	46848f63          	beq	s1,s0,ffffffffc0201476 <slub_check+0x5a0>
ffffffffc0200ffc:	46950d63          	beq	a0,s1,ffffffffc0201476 <slub_check+0x5a0>
ffffffffc0201000:	46850b63          	beq	a0,s0,ffffffffc0201476 <slub_check+0x5a0>
    slub_free(p1);
ffffffffc0201004:	8522                	mv	a0,s0
ffffffffc0201006:	dc7ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    slub_free(p2);
ffffffffc020100a:	8526                	mv	a0,s1
ffffffffc020100c:	dc1ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    slub_free(p3);
ffffffffc0201010:	854a                	mv	a0,s2
ffffffffc0201012:	dbbff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    cprintf("Test 1 passed!\n");
ffffffffc0201016:	00001517          	auipc	a0,0x1
ffffffffc020101a:	12250513          	addi	a0,a0,290 # ffffffffc0202138 <etext+0x62e>
ffffffffc020101e:	92eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Test 2: Multiple small allocations\n");
ffffffffc0201022:	00001517          	auipc	a0,0x1
ffffffffc0201026:	12650513          	addi	a0,a0,294 # ffffffffc0202148 <etext+0x63e>
ffffffffc020102a:	848a                	mv	s1,sp
ffffffffc020102c:	920ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201030:	8926                	mv	s2,s1
    for (int i = 0; i < 100; i++) {
ffffffffc0201032:	4401                	li	s0,0
ffffffffc0201034:	06400b13          	li	s6,100
ffffffffc0201038:	a829                	j	ffffffffc0201052 <slub_check+0x17c>
    return slub_alloc_object(cache);
ffffffffc020103a:	8552                	mv	a0,s4
ffffffffc020103c:	bb9ff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
        ptrs[i] = slub_alloc(8);
ffffffffc0201040:	00a93023          	sd	a0,0(s2)
        assert(ptrs[i] != NULL);
ffffffffc0201044:	40050963          	beqz	a0,ffffffffc0201456 <slub_check+0x580>
        *(int *)ptrs[i] = i;
ffffffffc0201048:	c100                	sw	s0,0(a0)
    for (int i = 0; i < 100; i++) {
ffffffffc020104a:	2405                	addiw	s0,s0,1
ffffffffc020104c:	0921                	addi	s2,s2,8
ffffffffc020104e:	01640863          	beq	s0,s6,ffffffffc020105e <slub_check+0x188>
    if (!slub_initialized) {
ffffffffc0201052:	0009a783          	lw	a5,0(s3)
ffffffffc0201056:	f3f5                	bnez	a5,ffffffffc020103a <slub_check+0x164>
    if (slub_initialized) {
ffffffffc0201058:	a95ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc020105c:	bff9                	j	ffffffffc020103a <slub_check+0x164>
ffffffffc020105e:	8726                	mv	a4,s1
    for (int i = 0; i < 100; i++) {
ffffffffc0201060:	4781                	li	a5,0
ffffffffc0201062:	06400613          	li	a2,100
        assert(*(int *)ptrs[i] == i);
ffffffffc0201066:	6314                	ld	a3,0(a4)
ffffffffc0201068:	4294                	lw	a3,0(a3)
ffffffffc020106a:	3cf69663          	bne	a3,a5,ffffffffc0201436 <slub_check+0x560>
    for (int i = 0; i < 100; i++) {
ffffffffc020106e:	2785                	addiw	a5,a5,1
ffffffffc0201070:	0721                	addi	a4,a4,8
ffffffffc0201072:	fec79ae3          	bne	a5,a2,ffffffffc0201066 <slub_check+0x190>
ffffffffc0201076:	32048413          	addi	s0,s1,800
        slub_free(ptrs[i]);
ffffffffc020107a:	6088                	ld	a0,0(s1)
    for (int i = 0; i < 100; i++) {
ffffffffc020107c:	04a1                	addi	s1,s1,8
        slub_free(ptrs[i]);
ffffffffc020107e:	d4fff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    for (int i = 0; i < 100; i++) {
ffffffffc0201082:	fe941ce3          	bne	s0,s1,ffffffffc020107a <slub_check+0x1a4>
    cprintf("Test 2 passed!\n");
ffffffffc0201086:	00001517          	auipc	a0,0x1
ffffffffc020108a:	11250513          	addi	a0,a0,274 # ffffffffc0202198 <etext+0x68e>
ffffffffc020108e:	8beff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Test 3: Different size allocations\n");
ffffffffc0201092:	00001517          	auipc	a0,0x1
ffffffffc0201096:	11650513          	addi	a0,a0,278 # ffffffffc02021a8 <etext+0x69e>
ffffffffc020109a:	8b2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!slub_initialized) {
ffffffffc020109e:	0009a783          	lw	a5,0(s3)
ffffffffc02010a2:	38078763          	beqz	a5,ffffffffc0201430 <slub_check+0x55a>
    return slub_alloc_object(cache);
ffffffffc02010a6:	00005517          	auipc	a0,0x5
ffffffffc02010aa:	0a250513          	addi	a0,a0,162 # ffffffffc0206148 <slub_caches>
ffffffffc02010ae:	b47ff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
    if (!slub_initialized) {
ffffffffc02010b2:	0009a783          	lw	a5,0(s3)
    return slub_alloc_object(cache);
ffffffffc02010b6:	84aa                	mv	s1,a0
    if (!slub_initialized) {
ffffffffc02010b8:	36078963          	beqz	a5,ffffffffc020142a <slub_check+0x554>
    return slub_alloc_object(cache);
ffffffffc02010bc:	00005517          	auipc	a0,0x5
ffffffffc02010c0:	0ec50513          	addi	a0,a0,236 # ffffffffc02061a8 <slub_caches+0x60>
ffffffffc02010c4:	b31ff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
    if (!slub_initialized) {
ffffffffc02010c8:	0009a783          	lw	a5,0(s3)
    return slub_alloc_object(cache);
ffffffffc02010cc:	842a                	mv	s0,a0
    if (!slub_initialized) {
ffffffffc02010ce:	34078b63          	beqz	a5,ffffffffc0201424 <slub_check+0x54e>
    for (int i = 0; i < 100; i++) {
ffffffffc02010d2:	00001717          	auipc	a4,0x1
ffffffffc02010d6:	2ae70713          	addi	a4,a4,686 # ffffffffc0202380 <slub_sizes>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc02010da:	4781                	li	a5,0
ffffffffc02010dc:	4625                	li	a2,9
        if (slub_sizes[i] >= size) {
ffffffffc02010de:	45fd                	li	a1,31
ffffffffc02010e0:	a029                	j	ffffffffc02010ea <slub_check+0x214>
ffffffffc02010e2:	6714                	ld	a3,8(a4)
ffffffffc02010e4:	0721                	addi	a4,a4,8
ffffffffc02010e6:	2ad5ec63          	bltu	a1,a3,ffffffffc020139e <slub_check+0x4c8>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc02010ea:	2785                	addiw	a5,a5,1
ffffffffc02010ec:	fec79be3          	bne	a5,a2,ffffffffc02010e2 <slub_check+0x20c>
    if (!slub_initialized) {
ffffffffc02010f0:	0009a783          	lw	a5,0(s3)
        return NULL;
ffffffffc02010f4:	4901                	li	s2,0
    if (!slub_initialized) {
ffffffffc02010f6:	2c078163          	beqz	a5,ffffffffc02013b8 <slub_check+0x4e2>
        return NULL;
ffffffffc02010fa:	00001717          	auipc	a4,0x1
ffffffffc02010fe:	28670713          	addi	a4,a4,646 # ffffffffc0202380 <slub_sizes>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201102:	4781                	li	a5,0
ffffffffc0201104:	4625                	li	a2,9
        if (slub_sizes[i] >= size) {
ffffffffc0201106:	03f00593          	li	a1,63
ffffffffc020110a:	a029                	j	ffffffffc0201114 <slub_check+0x23e>
ffffffffc020110c:	6714                	ld	a3,8(a4)
ffffffffc020110e:	0721                	addi	a4,a4,8
ffffffffc0201110:	2ad5e763          	bltu	a1,a3,ffffffffc02013be <slub_check+0x4e8>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201114:	2785                	addiw	a5,a5,1
ffffffffc0201116:	fec79be3          	bne	a5,a2,ffffffffc020110c <slub_check+0x236>
    if (!slub_initialized) {
ffffffffc020111a:	0009a783          	lw	a5,0(s3)
        return NULL;
ffffffffc020111e:	4b01                	li	s6,0
    if (!slub_initialized) {
ffffffffc0201120:	2a078c63          	beqz	a5,ffffffffc02013d8 <slub_check+0x502>
        return NULL;
ffffffffc0201124:	00001717          	auipc	a4,0x1
ffffffffc0201128:	25c70713          	addi	a4,a4,604 # ffffffffc0202380 <slub_sizes>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc020112c:	4781                	li	a5,0
ffffffffc020112e:	4625                	li	a2,9
        if (slub_sizes[i] >= size) {
ffffffffc0201130:	07f00593          	li	a1,127
ffffffffc0201134:	a029                	j	ffffffffc020113e <slub_check+0x268>
ffffffffc0201136:	6714                	ld	a3,8(a4)
ffffffffc0201138:	0721                	addi	a4,a4,8
ffffffffc020113a:	2ad5e263          	bltu	a1,a3,ffffffffc02013de <slub_check+0x508>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc020113e:	2785                	addiw	a5,a5,1
ffffffffc0201140:	fec79be3          	bne	a5,a2,ffffffffc0201136 <slub_check+0x260>
    if (!slub_initialized) {
ffffffffc0201144:	0009a783          	lw	a5,0(s3)
        return NULL;
ffffffffc0201148:	4b81                	li	s7,0
    if (!slub_initialized) {
ffffffffc020114a:	2a078763          	beqz	a5,ffffffffc02013f8 <slub_check+0x522>
        return NULL;
ffffffffc020114e:	00001717          	auipc	a4,0x1
ffffffffc0201152:	23270713          	addi	a4,a4,562 # ffffffffc0202380 <slub_sizes>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201156:	4781                	li	a5,0
ffffffffc0201158:	4625                	li	a2,9
        if (slub_sizes[i] >= size) {
ffffffffc020115a:	0ff00593          	li	a1,255
ffffffffc020115e:	a029                	j	ffffffffc0201168 <slub_check+0x292>
ffffffffc0201160:	6714                	ld	a3,8(a4)
ffffffffc0201162:	0721                	addi	a4,a4,8
ffffffffc0201164:	28d5ed63          	bltu	a1,a3,ffffffffc02013fe <slub_check+0x528>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201168:	2785                	addiw	a5,a5,1
ffffffffc020116a:	fec79be3          	bne	a5,a2,ffffffffc0201160 <slub_check+0x28a>
        return NULL;
ffffffffc020116e:	4c01                	li	s8,0
    assert(p8 && p16 && p32 && p64 && p128 && p256);
ffffffffc0201170:	44048363          	beqz	s1,ffffffffc02015b6 <slub_check+0x6e0>
ffffffffc0201174:	44040163          	beqz	s0,ffffffffc02015b6 <slub_check+0x6e0>
ffffffffc0201178:	42090f63          	beqz	s2,ffffffffc02015b6 <slub_check+0x6e0>
ffffffffc020117c:	420b0d63          	beqz	s6,ffffffffc02015b6 <slub_check+0x6e0>
ffffffffc0201180:	420b8b63          	beqz	s7,ffffffffc02015b6 <slub_check+0x6e0>
ffffffffc0201184:	420c0963          	beqz	s8,ffffffffc02015b6 <slub_check+0x6e0>
    memset(p8, 0x11, 8);
ffffffffc0201188:	4621                	li	a2,8
ffffffffc020118a:	45c5                	li	a1,17
ffffffffc020118c:	8526                	mv	a0,s1
ffffffffc020118e:	16b000ef          	jal	ra,ffffffffc0201af8 <memset>
    memset(p16, 0x22, 16);
ffffffffc0201192:	4641                	li	a2,16
ffffffffc0201194:	02200593          	li	a1,34
ffffffffc0201198:	8522                	mv	a0,s0
ffffffffc020119a:	15f000ef          	jal	ra,ffffffffc0201af8 <memset>
    memset(p32, 0x33, 32);
ffffffffc020119e:	02000613          	li	a2,32
ffffffffc02011a2:	03300593          	li	a1,51
ffffffffc02011a6:	854a                	mv	a0,s2
ffffffffc02011a8:	151000ef          	jal	ra,ffffffffc0201af8 <memset>
    memset(p64, 0x44, 64);
ffffffffc02011ac:	04000613          	li	a2,64
ffffffffc02011b0:	04400593          	li	a1,68
ffffffffc02011b4:	855a                	mv	a0,s6
ffffffffc02011b6:	143000ef          	jal	ra,ffffffffc0201af8 <memset>
    memset(p128, 0x55, 128);
ffffffffc02011ba:	08000613          	li	a2,128
ffffffffc02011be:	05500593          	li	a1,85
ffffffffc02011c2:	855e                	mv	a0,s7
ffffffffc02011c4:	135000ef          	jal	ra,ffffffffc0201af8 <memset>
    memset(p256, 0x66, 256);
ffffffffc02011c8:	10000613          	li	a2,256
ffffffffc02011cc:	06600593          	li	a1,102
ffffffffc02011d0:	8562                	mv	a0,s8
ffffffffc02011d2:	127000ef          	jal	ra,ffffffffc0201af8 <memset>
    assert(*(char *)p8 == 0x11);
ffffffffc02011d6:	0004c703          	lbu	a4,0(s1)
ffffffffc02011da:	47c5                	li	a5,17
ffffffffc02011dc:	3af71d63          	bne	a4,a5,ffffffffc0201596 <slub_check+0x6c0>
    assert(*(char *)p16 == 0x22);
ffffffffc02011e0:	00044703          	lbu	a4,0(s0)
ffffffffc02011e4:	02200793          	li	a5,34
ffffffffc02011e8:	30f71763          	bne	a4,a5,ffffffffc02014f6 <slub_check+0x620>
    assert(*(char *)p32 == 0x33);
ffffffffc02011ec:	00094703          	lbu	a4,0(s2)
ffffffffc02011f0:	03300793          	li	a5,51
ffffffffc02011f4:	2ef71163          	bne	a4,a5,ffffffffc02014d6 <slub_check+0x600>
    assert(*(char *)p64 == 0x44);
ffffffffc02011f8:	000b4703          	lbu	a4,0(s6)
ffffffffc02011fc:	04400793          	li	a5,68
ffffffffc0201200:	2af71b63          	bne	a4,a5,ffffffffc02014b6 <slub_check+0x5e0>
    assert(*(char *)p128 == 0x55);
ffffffffc0201204:	000bc703          	lbu	a4,0(s7) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201208:	05500793          	li	a5,85
ffffffffc020120c:	28f71563          	bne	a4,a5,ffffffffc0201496 <slub_check+0x5c0>
    assert(*(char *)p256 == 0x66);
ffffffffc0201210:	000c4703          	lbu	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc0201214:	06600793          	li	a5,102
ffffffffc0201218:	30f71f63          	bne	a4,a5,ffffffffc0201536 <slub_check+0x660>
    slub_free(p8);
ffffffffc020121c:	8526                	mv	a0,s1
ffffffffc020121e:	bafff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    slub_free(p16);
ffffffffc0201222:	8522                	mv	a0,s0
ffffffffc0201224:	ba9ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    slub_free(p32);
ffffffffc0201228:	854a                	mv	a0,s2
ffffffffc020122a:	ba3ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    slub_free(p64);
ffffffffc020122e:	855a                	mv	a0,s6
ffffffffc0201230:	b9dff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    slub_free(p128);
ffffffffc0201234:	855e                	mv	a0,s7
ffffffffc0201236:	b97ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    slub_free(p256);
ffffffffc020123a:	8562                	mv	a0,s8
ffffffffc020123c:	b91ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    cprintf("Test 3 passed!\n");
ffffffffc0201240:	00001517          	auipc	a0,0x1
ffffffffc0201244:	04850513          	addi	a0,a0,72 # ffffffffc0202288 <etext+0x77e>
ffffffffc0201248:	f05fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Test 4: Reuse after free\n");
ffffffffc020124c:	00001517          	auipc	a0,0x1
ffffffffc0201250:	04c50513          	addi	a0,a0,76 # ffffffffc0202298 <etext+0x78e>
ffffffffc0201254:	ef9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!slub_initialized) {
ffffffffc0201258:	0009a783          	lw	a5,0(s3)
ffffffffc020125c:	1c078163          	beqz	a5,ffffffffc020141e <slub_check+0x548>
        return NULL;
ffffffffc0201260:	00001717          	auipc	a4,0x1
ffffffffc0201264:	12070713          	addi	a4,a4,288 # ffffffffc0202380 <slub_sizes>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201268:	4781                	li	a5,0
ffffffffc020126a:	4625                	li	a2,9
        if (slub_sizes[i] >= size) {
ffffffffc020126c:	45fd                	li	a1,31
ffffffffc020126e:	a029                	j	ffffffffc0201278 <slub_check+0x3a2>
ffffffffc0201270:	6714                	ld	a3,8(a4)
ffffffffc0201272:	0721                	addi	a4,a4,8
ffffffffc0201274:	0ed5e963          	bltu	a1,a3,ffffffffc0201366 <slub_check+0x490>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201278:	2785                	addiw	a5,a5,1
ffffffffc020127a:	fec79be3          	bne	a5,a2,ffffffffc0201270 <slub_check+0x39a>
        return NULL;
ffffffffc020127e:	4401                	li	s0,0
    slub_free(q1);
ffffffffc0201280:	8522                	mv	a0,s0
ffffffffc0201282:	b4bff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    if (!slub_initialized) {
ffffffffc0201286:	0009a783          	lw	a5,0(s3)
ffffffffc020128a:	0e078e63          	beqz	a5,ffffffffc0201386 <slub_check+0x4b0>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc020128e:	4781                	li	a5,0
ffffffffc0201290:	46a5                	li	a3,9
        if (slub_sizes[i] >= size) {
ffffffffc0201292:	467d                	li	a2,31
ffffffffc0201294:	a031                	j	ffffffffc02012a0 <slub_check+0x3ca>
ffffffffc0201296:	008ab703          	ld	a4,8(s5)
ffffffffc020129a:	0aa1                	addi	s5,s5,8
ffffffffc020129c:	0ee66863          	bltu	a2,a4,ffffffffc020138c <slub_check+0x4b6>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc02012a0:	2785                	addiw	a5,a5,1
ffffffffc02012a2:	fed79ae3          	bne	a5,a3,ffffffffc0201296 <slub_check+0x3c0>
        return NULL;
ffffffffc02012a6:	4501                	li	a0,0
    assert(q1_addr == q2);
ffffffffc02012a8:	26851763          	bne	a0,s0,ffffffffc0201516 <slub_check+0x640>
    slub_free(q2);
ffffffffc02012ac:	b21ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    cprintf("Test 4 passed!\n");
ffffffffc02012b0:	00001517          	auipc	a0,0x1
ffffffffc02012b4:	01850513          	addi	a0,a0,24 # ffffffffc02022c8 <etext+0x7be>
ffffffffc02012b8:	e95fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Test 5: Stress test\n");
ffffffffc02012bc:	00001517          	auipc	a0,0x1
ffffffffc02012c0:	01c50513          	addi	a0,a0,28 # ffffffffc02022d8 <etext+0x7ce>
ffffffffc02012c4:	e89fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02012c8:	440d                	li	s0,3
    return slub_alloc_object(cache);
ffffffffc02012ca:	00005497          	auipc	s1,0x5
ffffffffc02012ce:	e7e48493          	addi	s1,s1,-386 # ffffffffc0206148 <slub_caches>
    if (!slub_initialized) {
ffffffffc02012d2:	0009a783          	lw	a5,0(s3)
ffffffffc02012d6:	c7c9                	beqz	a5,ffffffffc0201360 <slub_check+0x48a>
    return slub_alloc_object(cache);
ffffffffc02012d8:	8526                	mv	a0,s1
ffffffffc02012da:	91bff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
            assert(stress_ptrs[i] != NULL);
ffffffffc02012de:	28050c63          	beqz	a0,ffffffffc0201576 <slub_check+0x6a0>
            *(int *)stress_ptrs[i] = i;
ffffffffc02012e2:	00052023          	sw	zero,0(a0)
            slub_free(stress_ptrs[i]);
ffffffffc02012e6:	ae7ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    if (!slub_initialized) {
ffffffffc02012ea:	0009a783          	lw	a5,0(s3)
ffffffffc02012ee:	c7b5                	beqz	a5,ffffffffc020135a <slub_check+0x484>
    return slub_alloc_object(cache);
ffffffffc02012f0:	8526                	mv	a0,s1
ffffffffc02012f2:	903ff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
            assert(stress_ptrs[i] != NULL);
ffffffffc02012f6:	26050063          	beqz	a0,ffffffffc0201556 <slub_check+0x680>
    for (int round = 0; round < 3; round++) {
ffffffffc02012fa:	347d                	addiw	s0,s0,-1
            *(int *)stress_ptrs[i] = i * 2;
ffffffffc02012fc:	00052023          	sw	zero,0(a0)
                slub_free(stress_ptrs[i]);
ffffffffc0201300:	acdff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    for (int round = 0; round < 3; round++) {
ffffffffc0201304:	f479                	bnez	s0,ffffffffc02012d2 <slub_check+0x3fc>
    cprintf("Test 5 passed!\n");
ffffffffc0201306:	00001517          	auipc	a0,0x1
ffffffffc020130a:	00250513          	addi	a0,a0,2 # ffffffffc0202308 <etext+0x7fe>
ffffffffc020130e:	e3ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    slub_print_info();
ffffffffc0201312:	b65ff0ef          	jal	ra,ffffffffc0200e76 <slub_print_info>
    cprintf("All SLUB tests passed!\n");
ffffffffc0201316:	00001517          	auipc	a0,0x1
ffffffffc020131a:	00250513          	addi	a0,a0,2 # ffffffffc0202318 <etext+0x80e>
ffffffffc020131e:	e2ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0201322:	36013403          	ld	s0,864(sp)
ffffffffc0201326:	36813083          	ld	ra,872(sp)
ffffffffc020132a:	35813483          	ld	s1,856(sp)
ffffffffc020132e:	35013903          	ld	s2,848(sp)
ffffffffc0201332:	34813983          	ld	s3,840(sp)
ffffffffc0201336:	34013a03          	ld	s4,832(sp)
ffffffffc020133a:	33813a83          	ld	s5,824(sp)
ffffffffc020133e:	33013b03          	ld	s6,816(sp)
ffffffffc0201342:	32813b83          	ld	s7,808(sp)
ffffffffc0201346:	32013c03          	ld	s8,800(sp)
    cprintf("==========================================\n\n");
ffffffffc020134a:	00001517          	auipc	a0,0x1
ffffffffc020134e:	d0e50513          	addi	a0,a0,-754 # ffffffffc0202058 <etext+0x54e>
}
ffffffffc0201352:	37010113          	addi	sp,sp,880
    cprintf("==========================================\n\n");
ffffffffc0201356:	df7fe06f          	j	ffffffffc020014c <cprintf>
    if (slub_initialized) {
ffffffffc020135a:	f92ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc020135e:	bf49                	j	ffffffffc02012f0 <slub_check+0x41a>
ffffffffc0201360:	f8cff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc0201364:	bf95                	j	ffffffffc02012d8 <slub_check+0x402>
            return &slub_caches[i];
ffffffffc0201366:	00179513          	slli	a0,a5,0x1
ffffffffc020136a:	97aa                	add	a5,a5,a0
ffffffffc020136c:	00579513          	slli	a0,a5,0x5
    return slub_alloc_object(cache);
ffffffffc0201370:	9552                	add	a0,a0,s4
ffffffffc0201372:	883ff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
ffffffffc0201376:	842a                	mv	s0,a0
    slub_free(q1);
ffffffffc0201378:	8522                	mv	a0,s0
ffffffffc020137a:	a53ff0ef          	jal	ra,ffffffffc0200dcc <slub_free>
    if (!slub_initialized) {
ffffffffc020137e:	0009a783          	lw	a5,0(s3)
ffffffffc0201382:	f00796e3          	bnez	a5,ffffffffc020128e <slub_check+0x3b8>
    if (slub_initialized) {
ffffffffc0201386:	f66ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc020138a:	b711                	j	ffffffffc020128e <slub_check+0x3b8>
            return &slub_caches[i];
ffffffffc020138c:	00179513          	slli	a0,a5,0x1
ffffffffc0201390:	97aa                	add	a5,a5,a0
ffffffffc0201392:	00579513          	slli	a0,a5,0x5
    return slub_alloc_object(cache);
ffffffffc0201396:	9552                	add	a0,a0,s4
ffffffffc0201398:	85dff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
ffffffffc020139c:	b731                	j	ffffffffc02012a8 <slub_check+0x3d2>
            return &slub_caches[i];
ffffffffc020139e:	00179513          	slli	a0,a5,0x1
ffffffffc02013a2:	97aa                	add	a5,a5,a0
ffffffffc02013a4:	00579513          	slli	a0,a5,0x5
    return slub_alloc_object(cache);
ffffffffc02013a8:	9552                	add	a0,a0,s4
ffffffffc02013aa:	84bff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
    if (!slub_initialized) {
ffffffffc02013ae:	0009a783          	lw	a5,0(s3)
    return slub_alloc_object(cache);
ffffffffc02013b2:	892a                	mv	s2,a0
    if (!slub_initialized) {
ffffffffc02013b4:	d40793e3          	bnez	a5,ffffffffc02010fa <slub_check+0x224>
    if (slub_initialized) {
ffffffffc02013b8:	f34ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc02013bc:	bb3d                	j	ffffffffc02010fa <slub_check+0x224>
            return &slub_caches[i];
ffffffffc02013be:	00179513          	slli	a0,a5,0x1
ffffffffc02013c2:	97aa                	add	a5,a5,a0
ffffffffc02013c4:	00579513          	slli	a0,a5,0x5
    return slub_alloc_object(cache);
ffffffffc02013c8:	9552                	add	a0,a0,s4
ffffffffc02013ca:	82bff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
    if (!slub_initialized) {
ffffffffc02013ce:	0009a783          	lw	a5,0(s3)
    return slub_alloc_object(cache);
ffffffffc02013d2:	8b2a                	mv	s6,a0
    if (!slub_initialized) {
ffffffffc02013d4:	d40798e3          	bnez	a5,ffffffffc0201124 <slub_check+0x24e>
    if (slub_initialized) {
ffffffffc02013d8:	f14ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc02013dc:	b3a1                	j	ffffffffc0201124 <slub_check+0x24e>
            return &slub_caches[i];
ffffffffc02013de:	00179513          	slli	a0,a5,0x1
ffffffffc02013e2:	97aa                	add	a5,a5,a0
ffffffffc02013e4:	00579513          	slli	a0,a5,0x5
    return slub_alloc_object(cache);
ffffffffc02013e8:	9552                	add	a0,a0,s4
ffffffffc02013ea:	80bff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
    if (!slub_initialized) {
ffffffffc02013ee:	0009a783          	lw	a5,0(s3)
    return slub_alloc_object(cache);
ffffffffc02013f2:	8baa                	mv	s7,a0
    if (!slub_initialized) {
ffffffffc02013f4:	d4079de3          	bnez	a5,ffffffffc020114e <slub_check+0x278>
    if (slub_initialized) {
ffffffffc02013f8:	ef4ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc02013fc:	bb89                	j	ffffffffc020114e <slub_check+0x278>
            return &slub_caches[i];
ffffffffc02013fe:	00179513          	slli	a0,a5,0x1
ffffffffc0201402:	97aa                	add	a5,a5,a0
ffffffffc0201404:	00579513          	slli	a0,a5,0x5
    return slub_alloc_object(cache);
ffffffffc0201408:	9552                	add	a0,a0,s4
ffffffffc020140a:	feaff0ef          	jal	ra,ffffffffc0200bf4 <slub_alloc_object>
ffffffffc020140e:	8c2a                	mv	s8,a0
ffffffffc0201410:	b385                	j	ffffffffc0201170 <slub_check+0x29a>
    if (slub_initialized) {
ffffffffc0201412:	edaff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc0201416:	b62d                	j	ffffffffc0200f40 <slub_check+0x6a>
ffffffffc0201418:	ed4ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc020141c:	b639                	j	ffffffffc0200f2a <slub_check+0x54>
ffffffffc020141e:	eceff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc0201422:	bd3d                	j	ffffffffc0201260 <slub_check+0x38a>
ffffffffc0201424:	ec8ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc0201428:	b16d                	j	ffffffffc02010d2 <slub_check+0x1fc>
ffffffffc020142a:	ec2ff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc020142e:	b179                	j	ffffffffc02010bc <slub_check+0x1e6>
ffffffffc0201430:	ebcff0ef          	jal	ra,ffffffffc0200aec <slub_init.part.0>
ffffffffc0201434:	b98d                	j	ffffffffc02010a6 <slub_check+0x1d0>
        assert(*(int *)ptrs[i] == i);
ffffffffc0201436:	00001697          	auipc	a3,0x1
ffffffffc020143a:	d4a68693          	addi	a3,a3,-694 # ffffffffc0202180 <etext+0x676>
ffffffffc020143e:	00001617          	auipc	a2,0x1
ffffffffc0201442:	a8260613          	addi	a2,a2,-1406 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201446:	13400593          	li	a1,308
ffffffffc020144a:	00001517          	auipc	a0,0x1
ffffffffc020144e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201452:	d71fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(ptrs[i] != NULL);
ffffffffc0201456:	00001697          	auipc	a3,0x1
ffffffffc020145a:	d1a68693          	addi	a3,a3,-742 # ffffffffc0202170 <etext+0x666>
ffffffffc020145e:	00001617          	auipc	a2,0x1
ffffffffc0201462:	a6260613          	addi	a2,a2,-1438 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201466:	12d00593          	li	a1,301
ffffffffc020146a:	00001517          	auipc	a0,0x1
ffffffffc020146e:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201472:	d51fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != p2 && p2 != p3 && p1 != p3);
ffffffffc0201476:	00001697          	auipc	a3,0x1
ffffffffc020147a:	c9a68693          	addi	a3,a3,-870 # ffffffffc0202110 <etext+0x606>
ffffffffc020147e:	00001617          	auipc	a2,0x1
ffffffffc0201482:	a4260613          	addi	a2,a2,-1470 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201486:	12100593          	li	a1,289
ffffffffc020148a:	00001517          	auipc	a0,0x1
ffffffffc020148e:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201492:	d31fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(*(char *)p128 == 0x55);
ffffffffc0201496:	00001697          	auipc	a3,0x1
ffffffffc020149a:	dc268693          	addi	a3,a3,-574 # ffffffffc0202258 <etext+0x74e>
ffffffffc020149e:	00001617          	auipc	a2,0x1
ffffffffc02014a2:	a2260613          	addi	a2,a2,-1502 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc02014a6:	15500593          	li	a1,341
ffffffffc02014aa:	00001517          	auipc	a0,0x1
ffffffffc02014ae:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc02014b2:	d11fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(*(char *)p64 == 0x44);
ffffffffc02014b6:	00001697          	auipc	a3,0x1
ffffffffc02014ba:	d8a68693          	addi	a3,a3,-630 # ffffffffc0202240 <etext+0x736>
ffffffffc02014be:	00001617          	auipc	a2,0x1
ffffffffc02014c2:	a0260613          	addi	a2,a2,-1534 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc02014c6:	15400593          	li	a1,340
ffffffffc02014ca:	00001517          	auipc	a0,0x1
ffffffffc02014ce:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc02014d2:	cf1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(*(char *)p32 == 0x33);
ffffffffc02014d6:	00001697          	auipc	a3,0x1
ffffffffc02014da:	d5268693          	addi	a3,a3,-686 # ffffffffc0202228 <etext+0x71e>
ffffffffc02014de:	00001617          	auipc	a2,0x1
ffffffffc02014e2:	9e260613          	addi	a2,a2,-1566 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc02014e6:	15300593          	li	a1,339
ffffffffc02014ea:	00001517          	auipc	a0,0x1
ffffffffc02014ee:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc02014f2:	cd1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(*(char *)p16 == 0x22);
ffffffffc02014f6:	00001697          	auipc	a3,0x1
ffffffffc02014fa:	d1a68693          	addi	a3,a3,-742 # ffffffffc0202210 <etext+0x706>
ffffffffc02014fe:	00001617          	auipc	a2,0x1
ffffffffc0201502:	9c260613          	addi	a2,a2,-1598 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201506:	15200593          	li	a1,338
ffffffffc020150a:	00001517          	auipc	a0,0x1
ffffffffc020150e:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201512:	cb1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(q1_addr == q2);
ffffffffc0201516:	00001697          	auipc	a3,0x1
ffffffffc020151a:	da268693          	addi	a3,a3,-606 # ffffffffc02022b8 <etext+0x7ae>
ffffffffc020151e:	00001617          	auipc	a2,0x1
ffffffffc0201522:	9a260613          	addi	a2,a2,-1630 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201526:	16700593          	li	a1,359
ffffffffc020152a:	00001517          	auipc	a0,0x1
ffffffffc020152e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201532:	c91fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(*(char *)p256 == 0x66);
ffffffffc0201536:	00001697          	auipc	a3,0x1
ffffffffc020153a:	d3a68693          	addi	a3,a3,-710 # ffffffffc0202270 <etext+0x766>
ffffffffc020153e:	00001617          	auipc	a2,0x1
ffffffffc0201542:	98260613          	addi	a2,a2,-1662 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201546:	15600593          	li	a1,342
ffffffffc020154a:	00001517          	auipc	a0,0x1
ffffffffc020154e:	98e50513          	addi	a0,a0,-1650 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201552:	c71fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(stress_ptrs[i] != NULL);
ffffffffc0201556:	00001697          	auipc	a3,0x1
ffffffffc020155a:	d9a68693          	addi	a3,a3,-614 # ffffffffc02022f0 <etext+0x7e6>
ffffffffc020155e:	00001617          	auipc	a2,0x1
ffffffffc0201562:	96260613          	addi	a2,a2,-1694 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201566:	18800593          	li	a1,392
ffffffffc020156a:	00001517          	auipc	a0,0x1
ffffffffc020156e:	96e50513          	addi	a0,a0,-1682 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201572:	c51fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(stress_ptrs[i] != NULL);
ffffffffc0201576:	00001697          	auipc	a3,0x1
ffffffffc020157a:	d7a68693          	addi	a3,a3,-646 # ffffffffc02022f0 <etext+0x7e6>
ffffffffc020157e:	00001617          	auipc	a2,0x1
ffffffffc0201582:	94260613          	addi	a2,a2,-1726 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201586:	17500593          	li	a1,373
ffffffffc020158a:	00001517          	auipc	a0,0x1
ffffffffc020158e:	94e50513          	addi	a0,a0,-1714 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201592:	c31fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(*(char *)p8 == 0x11);
ffffffffc0201596:	00001697          	auipc	a3,0x1
ffffffffc020159a:	c6268693          	addi	a3,a3,-926 # ffffffffc02021f8 <etext+0x6ee>
ffffffffc020159e:	00001617          	auipc	a2,0x1
ffffffffc02015a2:	92260613          	addi	a2,a2,-1758 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc02015a6:	15100593          	li	a1,337
ffffffffc02015aa:	00001517          	auipc	a0,0x1
ffffffffc02015ae:	92e50513          	addi	a0,a0,-1746 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc02015b2:	c11fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p8 && p16 && p32 && p64 && p128 && p256);
ffffffffc02015b6:	00001697          	auipc	a3,0x1
ffffffffc02015ba:	c1a68693          	addi	a3,a3,-998 # ffffffffc02021d0 <etext+0x6c6>
ffffffffc02015be:	00001617          	auipc	a2,0x1
ffffffffc02015c2:	90260613          	addi	a2,a2,-1790 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc02015c6:	14600593          	li	a1,326
ffffffffc02015ca:	00001517          	auipc	a0,0x1
ffffffffc02015ce:	90e50513          	addi	a0,a0,-1778 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc02015d2:	bf1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);
ffffffffc02015d6:	00001697          	auipc	a3,0x1
ffffffffc02015da:	b1a68693          	addi	a3,a3,-1254 # ffffffffc02020f0 <etext+0x5e6>
ffffffffc02015de:	00001617          	auipc	a2,0x1
ffffffffc02015e2:	8e260613          	addi	a2,a2,-1822 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc02015e6:	11f00593          	li	a1,287
ffffffffc02015ea:	00001517          	auipc	a0,0x1
ffffffffc02015ee:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc02015f2:	bd1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc02015f6:	00001697          	auipc	a3,0x1
ffffffffc02015fa:	b0a68693          	addi	a3,a3,-1270 # ffffffffc0202100 <etext+0x5f6>
ffffffffc02015fe:	00001617          	auipc	a2,0x1
ffffffffc0201602:	8c260613          	addi	a2,a2,-1854 # ffffffffc0201ec0 <etext+0x3b6>
ffffffffc0201606:	11e00593          	li	a1,286
ffffffffc020160a:	00001517          	auipc	a0,0x1
ffffffffc020160e:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0201ed8 <etext+0x3ce>
ffffffffc0201612:	bb1fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201616 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201616:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020161a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020161c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201620:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201622:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201626:	f022                	sd	s0,32(sp)
ffffffffc0201628:	ec26                	sd	s1,24(sp)
ffffffffc020162a:	e84a                	sd	s2,16(sp)
ffffffffc020162c:	f406                	sd	ra,40(sp)
ffffffffc020162e:	e44e                	sd	s3,8(sp)
ffffffffc0201630:	84aa                	mv	s1,a0
ffffffffc0201632:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201634:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201638:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020163a:	03067e63          	bgeu	a2,a6,ffffffffc0201676 <printnum+0x60>
ffffffffc020163e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201640:	00805763          	blez	s0,ffffffffc020164e <printnum+0x38>
ffffffffc0201644:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201646:	85ca                	mv	a1,s2
ffffffffc0201648:	854e                	mv	a0,s3
ffffffffc020164a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020164c:	fc65                	bnez	s0,ffffffffc0201644 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020164e:	1a02                	slli	s4,s4,0x20
ffffffffc0201650:	00001797          	auipc	a5,0x1
ffffffffc0201654:	d7878793          	addi	a5,a5,-648 # ffffffffc02023c8 <slub_sizes+0x48>
ffffffffc0201658:	020a5a13          	srli	s4,s4,0x20
ffffffffc020165c:	9a3e                	add	s4,s4,a5
}
ffffffffc020165e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201660:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201664:	70a2                	ld	ra,40(sp)
ffffffffc0201666:	69a2                	ld	s3,8(sp)
ffffffffc0201668:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020166a:	85ca                	mv	a1,s2
ffffffffc020166c:	87a6                	mv	a5,s1
}
ffffffffc020166e:	6942                	ld	s2,16(sp)
ffffffffc0201670:	64e2                	ld	s1,24(sp)
ffffffffc0201672:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201674:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201676:	03065633          	divu	a2,a2,a6
ffffffffc020167a:	8722                	mv	a4,s0
ffffffffc020167c:	f9bff0ef          	jal	ra,ffffffffc0201616 <printnum>
ffffffffc0201680:	b7f9                	j	ffffffffc020164e <printnum+0x38>

ffffffffc0201682 <sprintputch>:
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
    b->cnt ++;
ffffffffc0201682:	499c                	lw	a5,16(a1)
    if (b->buf < b->ebuf) {
ffffffffc0201684:	6198                	ld	a4,0(a1)
ffffffffc0201686:	6594                	ld	a3,8(a1)
    b->cnt ++;
ffffffffc0201688:	2785                	addiw	a5,a5,1
ffffffffc020168a:	c99c                	sw	a5,16(a1)
    if (b->buf < b->ebuf) {
ffffffffc020168c:	00d77763          	bgeu	a4,a3,ffffffffc020169a <sprintputch+0x18>
        *b->buf ++ = ch;
ffffffffc0201690:	00170793          	addi	a5,a4,1
ffffffffc0201694:	e19c                	sd	a5,0(a1)
ffffffffc0201696:	00a70023          	sb	a0,0(a4)
    }
}
ffffffffc020169a:	8082                	ret

ffffffffc020169c <vprintfmt>:
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020169c:	7119                	addi	sp,sp,-128
ffffffffc020169e:	f4a6                	sd	s1,104(sp)
ffffffffc02016a0:	f0ca                	sd	s2,96(sp)
ffffffffc02016a2:	ecce                	sd	s3,88(sp)
ffffffffc02016a4:	e8d2                	sd	s4,80(sp)
ffffffffc02016a6:	e4d6                	sd	s5,72(sp)
ffffffffc02016a8:	e0da                	sd	s6,64(sp)
ffffffffc02016aa:	fc5e                	sd	s7,56(sp)
ffffffffc02016ac:	f06a                	sd	s10,32(sp)
ffffffffc02016ae:	fc86                	sd	ra,120(sp)
ffffffffc02016b0:	f8a2                	sd	s0,112(sp)
ffffffffc02016b2:	f862                	sd	s8,48(sp)
ffffffffc02016b4:	f466                	sd	s9,40(sp)
ffffffffc02016b6:	ec6e                	sd	s11,24(sp)
ffffffffc02016b8:	892a                	mv	s2,a0
ffffffffc02016ba:	84ae                	mv	s1,a1
ffffffffc02016bc:	8d32                	mv	s10,a2
ffffffffc02016be:	8a36                	mv	s4,a3
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016c0:	02500993          	li	s3,37
        width = precision = -1;
ffffffffc02016c4:	5b7d                	li	s6,-1
ffffffffc02016c6:	00001a97          	auipc	s5,0x1
ffffffffc02016ca:	d36a8a93          	addi	s5,s5,-714 # ffffffffc02023fc <slub_sizes+0x7c>
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016ce:	00001b97          	auipc	s7,0x1
ffffffffc02016d2:	f0ab8b93          	addi	s7,s7,-246 # ffffffffc02025d8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016d6:	000d4503          	lbu	a0,0(s10)
ffffffffc02016da:	001d0413          	addi	s0,s10,1
ffffffffc02016de:	01350a63          	beq	a0,s3,ffffffffc02016f2 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02016e2:	c121                	beqz	a0,ffffffffc0201722 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02016e4:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016e6:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02016e8:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016ea:	fff44503          	lbu	a0,-1(s0)
ffffffffc02016ee:	ff351ae3          	bne	a0,s3,ffffffffc02016e2 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016f2:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02016f6:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02016fa:	4c81                	li	s9,0
ffffffffc02016fc:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02016fe:	5c7d                	li	s8,-1
ffffffffc0201700:	5dfd                	li	s11,-1
ffffffffc0201702:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201706:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201708:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020170c:	0ff5f593          	zext.b	a1,a1
ffffffffc0201710:	00140d13          	addi	s10,s0,1
ffffffffc0201714:	04b56263          	bltu	a0,a1,ffffffffc0201758 <vprintfmt+0xbc>
ffffffffc0201718:	058a                	slli	a1,a1,0x2
ffffffffc020171a:	95d6                	add	a1,a1,s5
ffffffffc020171c:	4194                	lw	a3,0(a1)
ffffffffc020171e:	96d6                	add	a3,a3,s5
ffffffffc0201720:	8682                	jr	a3
}
ffffffffc0201722:	70e6                	ld	ra,120(sp)
ffffffffc0201724:	7446                	ld	s0,112(sp)
ffffffffc0201726:	74a6                	ld	s1,104(sp)
ffffffffc0201728:	7906                	ld	s2,96(sp)
ffffffffc020172a:	69e6                	ld	s3,88(sp)
ffffffffc020172c:	6a46                	ld	s4,80(sp)
ffffffffc020172e:	6aa6                	ld	s5,72(sp)
ffffffffc0201730:	6b06                	ld	s6,64(sp)
ffffffffc0201732:	7be2                	ld	s7,56(sp)
ffffffffc0201734:	7c42                	ld	s8,48(sp)
ffffffffc0201736:	7ca2                	ld	s9,40(sp)
ffffffffc0201738:	7d02                	ld	s10,32(sp)
ffffffffc020173a:	6de2                	ld	s11,24(sp)
ffffffffc020173c:	6109                	addi	sp,sp,128
ffffffffc020173e:	8082                	ret
            padc = '0';
ffffffffc0201740:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201742:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201746:	846a                	mv	s0,s10
ffffffffc0201748:	00140d13          	addi	s10,s0,1
ffffffffc020174c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201750:	0ff5f593          	zext.b	a1,a1
ffffffffc0201754:	fcb572e3          	bgeu	a0,a1,ffffffffc0201718 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201758:	85a6                	mv	a1,s1
ffffffffc020175a:	02500513          	li	a0,37
ffffffffc020175e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201760:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201764:	8d22                	mv	s10,s0
ffffffffc0201766:	f73788e3          	beq	a5,s3,ffffffffc02016d6 <vprintfmt+0x3a>
ffffffffc020176a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020176e:	1d7d                	addi	s10,s10,-1
ffffffffc0201770:	ff379de3          	bne	a5,s3,ffffffffc020176a <vprintfmt+0xce>
ffffffffc0201774:	b78d                	j	ffffffffc02016d6 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201776:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020177a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020177e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201780:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201784:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201788:	02d86463          	bltu	a6,a3,ffffffffc02017b0 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020178c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201790:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201794:	0186873b          	addw	a4,a3,s8
ffffffffc0201798:	0017171b          	slliw	a4,a4,0x1
ffffffffc020179c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020179e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02017a2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02017a4:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02017a8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02017ac:	fed870e3          	bgeu	a6,a3,ffffffffc020178c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02017b0:	f40ddce3          	bgez	s11,ffffffffc0201708 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02017b4:	8de2                	mv	s11,s8
ffffffffc02017b6:	5c7d                	li	s8,-1
ffffffffc02017b8:	bf81                	j	ffffffffc0201708 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02017ba:	fffdc693          	not	a3,s11
ffffffffc02017be:	96fd                	srai	a3,a3,0x3f
ffffffffc02017c0:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017c4:	00144603          	lbu	a2,1(s0)
ffffffffc02017c8:	2d81                	sext.w	s11,s11
ffffffffc02017ca:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02017cc:	bf35                	j	ffffffffc0201708 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02017ce:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017d2:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02017d6:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017d8:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02017da:	bfd9                	j	ffffffffc02017b0 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02017dc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02017de:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02017e2:	01174463          	blt	a4,a7,ffffffffc02017ea <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02017e6:	1a088e63          	beqz	a7,ffffffffc02019a2 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02017ea:	000a3603          	ld	a2,0(s4)
ffffffffc02017ee:	46c1                	li	a3,16
ffffffffc02017f0:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02017f2:	2781                	sext.w	a5,a5
ffffffffc02017f4:	876e                	mv	a4,s11
ffffffffc02017f6:	85a6                	mv	a1,s1
ffffffffc02017f8:	854a                	mv	a0,s2
ffffffffc02017fa:	e1dff0ef          	jal	ra,ffffffffc0201616 <printnum>
            break;
ffffffffc02017fe:	bde1                	j	ffffffffc02016d6 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201800:	000a2503          	lw	a0,0(s4)
ffffffffc0201804:	85a6                	mv	a1,s1
ffffffffc0201806:	0a21                	addi	s4,s4,8
ffffffffc0201808:	9902                	jalr	s2
            break;
ffffffffc020180a:	b5f1                	j	ffffffffc02016d6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020180c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020180e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201812:	01174463          	blt	a4,a7,ffffffffc020181a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201816:	18088163          	beqz	a7,ffffffffc0201998 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020181a:	000a3603          	ld	a2,0(s4)
ffffffffc020181e:	46a9                	li	a3,10
ffffffffc0201820:	8a2e                	mv	s4,a1
ffffffffc0201822:	bfc1                	j	ffffffffc02017f2 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201824:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201828:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020182a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020182c:	bdf1                	j	ffffffffc0201708 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020182e:	85a6                	mv	a1,s1
ffffffffc0201830:	02500513          	li	a0,37
ffffffffc0201834:	9902                	jalr	s2
            break;
ffffffffc0201836:	b545                	j	ffffffffc02016d6 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201838:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020183c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020183e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201840:	b5e1                	j	ffffffffc0201708 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201842:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201844:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201848:	01174463          	blt	a4,a7,ffffffffc0201850 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020184c:	14088163          	beqz	a7,ffffffffc020198e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201850:	000a3603          	ld	a2,0(s4)
ffffffffc0201854:	46a1                	li	a3,8
ffffffffc0201856:	8a2e                	mv	s4,a1
ffffffffc0201858:	bf69                	j	ffffffffc02017f2 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020185a:	03000513          	li	a0,48
ffffffffc020185e:	85a6                	mv	a1,s1
ffffffffc0201860:	e03e                	sd	a5,0(sp)
ffffffffc0201862:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201864:	85a6                	mv	a1,s1
ffffffffc0201866:	07800513          	li	a0,120
ffffffffc020186a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020186c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020186e:	6782                	ld	a5,0(sp)
ffffffffc0201870:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201872:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201876:	bfb5                	j	ffffffffc02017f2 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201878:	000a3403          	ld	s0,0(s4)
ffffffffc020187c:	008a0713          	addi	a4,s4,8
ffffffffc0201880:	e03a                	sd	a4,0(sp)
ffffffffc0201882:	14040263          	beqz	s0,ffffffffc02019c6 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201886:	0fb05763          	blez	s11,ffffffffc0201974 <vprintfmt+0x2d8>
ffffffffc020188a:	02d00693          	li	a3,45
ffffffffc020188e:	0cd79163          	bne	a5,a3,ffffffffc0201950 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201892:	00044783          	lbu	a5,0(s0)
ffffffffc0201896:	0007851b          	sext.w	a0,a5
ffffffffc020189a:	cf85                	beqz	a5,ffffffffc02018d2 <vprintfmt+0x236>
ffffffffc020189c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02018a0:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018a4:	000c4563          	bltz	s8,ffffffffc02018ae <vprintfmt+0x212>
ffffffffc02018a8:	3c7d                	addiw	s8,s8,-1
ffffffffc02018aa:	036c0263          	beq	s8,s6,ffffffffc02018ce <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02018ae:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02018b0:	0e0c8e63          	beqz	s9,ffffffffc02019ac <vprintfmt+0x310>
ffffffffc02018b4:	3781                	addiw	a5,a5,-32
ffffffffc02018b6:	0ef47b63          	bgeu	s0,a5,ffffffffc02019ac <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02018ba:	03f00513          	li	a0,63
ffffffffc02018be:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018c0:	000a4783          	lbu	a5,0(s4)
ffffffffc02018c4:	3dfd                	addiw	s11,s11,-1
ffffffffc02018c6:	0a05                	addi	s4,s4,1
ffffffffc02018c8:	0007851b          	sext.w	a0,a5
ffffffffc02018cc:	ffe1                	bnez	a5,ffffffffc02018a4 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02018ce:	01b05963          	blez	s11,ffffffffc02018e0 <vprintfmt+0x244>
ffffffffc02018d2:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02018d4:	85a6                	mv	a1,s1
ffffffffc02018d6:	02000513          	li	a0,32
ffffffffc02018da:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02018dc:	fe0d9be3          	bnez	s11,ffffffffc02018d2 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02018e0:	6a02                	ld	s4,0(sp)
ffffffffc02018e2:	bbd5                	j	ffffffffc02016d6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02018e4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02018e6:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02018ea:	01174463          	blt	a4,a7,ffffffffc02018f2 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02018ee:	08088d63          	beqz	a7,ffffffffc0201988 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02018f2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02018f6:	0a044d63          	bltz	s0,ffffffffc02019b0 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02018fa:	8622                	mv	a2,s0
ffffffffc02018fc:	8a66                	mv	s4,s9
ffffffffc02018fe:	46a9                	li	a3,10
ffffffffc0201900:	bdcd                	j	ffffffffc02017f2 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201902:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201906:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201908:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020190a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020190e:	8fb5                	xor	a5,a5,a3
ffffffffc0201910:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201914:	02d74163          	blt	a4,a3,ffffffffc0201936 <vprintfmt+0x29a>
ffffffffc0201918:	00369793          	slli	a5,a3,0x3
ffffffffc020191c:	97de                	add	a5,a5,s7
ffffffffc020191e:	639c                	ld	a5,0(a5)
ffffffffc0201920:	cb99                	beqz	a5,ffffffffc0201936 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201922:	86be                	mv	a3,a5
ffffffffc0201924:	00001617          	auipc	a2,0x1
ffffffffc0201928:	ad460613          	addi	a2,a2,-1324 # ffffffffc02023f8 <slub_sizes+0x78>
ffffffffc020192c:	85a6                	mv	a1,s1
ffffffffc020192e:	854a                	mv	a0,s2
ffffffffc0201930:	0ce000ef          	jal	ra,ffffffffc02019fe <printfmt>
ffffffffc0201934:	b34d                	j	ffffffffc02016d6 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201936:	00001617          	auipc	a2,0x1
ffffffffc020193a:	ab260613          	addi	a2,a2,-1358 # ffffffffc02023e8 <slub_sizes+0x68>
ffffffffc020193e:	85a6                	mv	a1,s1
ffffffffc0201940:	854a                	mv	a0,s2
ffffffffc0201942:	0bc000ef          	jal	ra,ffffffffc02019fe <printfmt>
ffffffffc0201946:	bb41                	j	ffffffffc02016d6 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201948:	00001417          	auipc	s0,0x1
ffffffffc020194c:	a9840413          	addi	s0,s0,-1384 # ffffffffc02023e0 <slub_sizes+0x60>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201950:	85e2                	mv	a1,s8
ffffffffc0201952:	8522                	mv	a0,s0
ffffffffc0201954:	e43e                	sd	a5,8(sp)
ffffffffc0201956:	142000ef          	jal	ra,ffffffffc0201a98 <strnlen>
ffffffffc020195a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020195e:	01b05b63          	blez	s11,ffffffffc0201974 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201962:	67a2                	ld	a5,8(sp)
ffffffffc0201964:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201968:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020196a:	85a6                	mv	a1,s1
ffffffffc020196c:	8552                	mv	a0,s4
ffffffffc020196e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201970:	fe0d9ce3          	bnez	s11,ffffffffc0201968 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201974:	00044783          	lbu	a5,0(s0)
ffffffffc0201978:	00140a13          	addi	s4,s0,1
ffffffffc020197c:	0007851b          	sext.w	a0,a5
ffffffffc0201980:	d3a5                	beqz	a5,ffffffffc02018e0 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201982:	05e00413          	li	s0,94
ffffffffc0201986:	bf39                	j	ffffffffc02018a4 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201988:	000a2403          	lw	s0,0(s4)
ffffffffc020198c:	b7ad                	j	ffffffffc02018f6 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020198e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201992:	46a1                	li	a3,8
ffffffffc0201994:	8a2e                	mv	s4,a1
ffffffffc0201996:	bdb1                	j	ffffffffc02017f2 <vprintfmt+0x156>
ffffffffc0201998:	000a6603          	lwu	a2,0(s4)
ffffffffc020199c:	46a9                	li	a3,10
ffffffffc020199e:	8a2e                	mv	s4,a1
ffffffffc02019a0:	bd89                	j	ffffffffc02017f2 <vprintfmt+0x156>
ffffffffc02019a2:	000a6603          	lwu	a2,0(s4)
ffffffffc02019a6:	46c1                	li	a3,16
ffffffffc02019a8:	8a2e                	mv	s4,a1
ffffffffc02019aa:	b5a1                	j	ffffffffc02017f2 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02019ac:	9902                	jalr	s2
ffffffffc02019ae:	bf09                	j	ffffffffc02018c0 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02019b0:	85a6                	mv	a1,s1
ffffffffc02019b2:	02d00513          	li	a0,45
ffffffffc02019b6:	e03e                	sd	a5,0(sp)
ffffffffc02019b8:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02019ba:	6782                	ld	a5,0(sp)
ffffffffc02019bc:	8a66                	mv	s4,s9
ffffffffc02019be:	40800633          	neg	a2,s0
ffffffffc02019c2:	46a9                	li	a3,10
ffffffffc02019c4:	b53d                	j	ffffffffc02017f2 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02019c6:	03b05163          	blez	s11,ffffffffc02019e8 <vprintfmt+0x34c>
ffffffffc02019ca:	02d00693          	li	a3,45
ffffffffc02019ce:	f6d79de3          	bne	a5,a3,ffffffffc0201948 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02019d2:	00001417          	auipc	s0,0x1
ffffffffc02019d6:	a0e40413          	addi	s0,s0,-1522 # ffffffffc02023e0 <slub_sizes+0x60>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019da:	02800793          	li	a5,40
ffffffffc02019de:	02800513          	li	a0,40
ffffffffc02019e2:	00140a13          	addi	s4,s0,1
ffffffffc02019e6:	bd6d                	j	ffffffffc02018a0 <vprintfmt+0x204>
ffffffffc02019e8:	00001a17          	auipc	s4,0x1
ffffffffc02019ec:	9f9a0a13          	addi	s4,s4,-1543 # ffffffffc02023e1 <slub_sizes+0x61>
ffffffffc02019f0:	02800513          	li	a0,40
ffffffffc02019f4:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02019f8:	05e00413          	li	s0,94
ffffffffc02019fc:	b565                	j	ffffffffc02018a4 <vprintfmt+0x208>

ffffffffc02019fe <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019fe:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201a00:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a04:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a06:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a08:	ec06                	sd	ra,24(sp)
ffffffffc0201a0a:	f83a                	sd	a4,48(sp)
ffffffffc0201a0c:	fc3e                	sd	a5,56(sp)
ffffffffc0201a0e:	e0c2                	sd	a6,64(sp)
ffffffffc0201a10:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201a12:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a14:	c89ff0ef          	jal	ra,ffffffffc020169c <vprintfmt>
}
ffffffffc0201a18:	60e2                	ld	ra,24(sp)
ffffffffc0201a1a:	6161                	addi	sp,sp,80
ffffffffc0201a1c:	8082                	ret

ffffffffc0201a1e <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
ffffffffc0201a1e:	711d                	addi	sp,sp,-96
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
    struct sprintbuf b = {str, str + size - 1, 0};
ffffffffc0201a20:	15fd                	addi	a1,a1,-1
    va_start(ap, fmt);
ffffffffc0201a22:	03810313          	addi	t1,sp,56
    struct sprintbuf b = {str, str + size - 1, 0};
ffffffffc0201a26:	95aa                	add	a1,a1,a0
snprintf(char *str, size_t size, const char *fmt, ...) {
ffffffffc0201a28:	f406                	sd	ra,40(sp)
ffffffffc0201a2a:	fc36                	sd	a3,56(sp)
ffffffffc0201a2c:	e0ba                	sd	a4,64(sp)
ffffffffc0201a2e:	e4be                	sd	a5,72(sp)
ffffffffc0201a30:	e8c2                	sd	a6,80(sp)
ffffffffc0201a32:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0201a34:	e01a                	sd	t1,0(sp)
    struct sprintbuf b = {str, str + size - 1, 0};
ffffffffc0201a36:	e42a                	sd	a0,8(sp)
ffffffffc0201a38:	e82e                	sd	a1,16(sp)
ffffffffc0201a3a:	cc02                	sw	zero,24(sp)
    if (str == NULL || b.buf > b.ebuf) {
ffffffffc0201a3c:	c115                	beqz	a0,ffffffffc0201a60 <snprintf+0x42>
ffffffffc0201a3e:	02a5e163          	bltu	a1,a0,ffffffffc0201a60 <snprintf+0x42>
        return -E_INVAL;
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
ffffffffc0201a42:	00000517          	auipc	a0,0x0
ffffffffc0201a46:	c4050513          	addi	a0,a0,-960 # ffffffffc0201682 <sprintputch>
ffffffffc0201a4a:	869a                	mv	a3,t1
ffffffffc0201a4c:	002c                	addi	a1,sp,8
ffffffffc0201a4e:	c4fff0ef          	jal	ra,ffffffffc020169c <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
ffffffffc0201a52:	67a2                	ld	a5,8(sp)
ffffffffc0201a54:	00078023          	sb	zero,0(a5)
    return b.cnt;
ffffffffc0201a58:	4562                	lw	a0,24(sp)
}
ffffffffc0201a5a:	70a2                	ld	ra,40(sp)
ffffffffc0201a5c:	6125                	addi	sp,sp,96
ffffffffc0201a5e:	8082                	ret
        return -E_INVAL;
ffffffffc0201a60:	5575                	li	a0,-3
ffffffffc0201a62:	bfe5                	j	ffffffffc0201a5a <snprintf+0x3c>

ffffffffc0201a64 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201a64:	4781                	li	a5,0
ffffffffc0201a66:	00004717          	auipc	a4,0x4
ffffffffc0201a6a:	5aa73703          	ld	a4,1450(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201a6e:	88ba                	mv	a7,a4
ffffffffc0201a70:	852a                	mv	a0,a0
ffffffffc0201a72:	85be                	mv	a1,a5
ffffffffc0201a74:	863e                	mv	a2,a5
ffffffffc0201a76:	00000073          	ecall
ffffffffc0201a7a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201a7c:	8082                	ret

ffffffffc0201a7e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201a7e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201a82:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201a84:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201a86:	cb81                	beqz	a5,ffffffffc0201a96 <strlen+0x18>
        cnt ++;
ffffffffc0201a88:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201a8a:	00a707b3          	add	a5,a4,a0
ffffffffc0201a8e:	0007c783          	lbu	a5,0(a5)
ffffffffc0201a92:	fbfd                	bnez	a5,ffffffffc0201a88 <strlen+0xa>
ffffffffc0201a94:	8082                	ret
    }
    return cnt;
}
ffffffffc0201a96:	8082                	ret

ffffffffc0201a98 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a98:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a9a:	e589                	bnez	a1,ffffffffc0201aa4 <strnlen+0xc>
ffffffffc0201a9c:	a811                	j	ffffffffc0201ab0 <strnlen+0x18>
        cnt ++;
ffffffffc0201a9e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201aa0:	00f58863          	beq	a1,a5,ffffffffc0201ab0 <strnlen+0x18>
ffffffffc0201aa4:	00f50733          	add	a4,a0,a5
ffffffffc0201aa8:	00074703          	lbu	a4,0(a4)
ffffffffc0201aac:	fb6d                	bnez	a4,ffffffffc0201a9e <strnlen+0x6>
ffffffffc0201aae:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201ab0:	852e                	mv	a0,a1
ffffffffc0201ab2:	8082                	ret

ffffffffc0201ab4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ab4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ab8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201abc:	cb89                	beqz	a5,ffffffffc0201ace <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201abe:	0505                	addi	a0,a0,1
ffffffffc0201ac0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ac2:	fee789e3          	beq	a5,a4,ffffffffc0201ab4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ac6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201aca:	9d19                	subw	a0,a0,a4
ffffffffc0201acc:	8082                	ret
ffffffffc0201ace:	4501                	li	a0,0
ffffffffc0201ad0:	bfed                	j	ffffffffc0201aca <strcmp+0x16>

ffffffffc0201ad2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ad2:	c20d                	beqz	a2,ffffffffc0201af4 <strncmp+0x22>
ffffffffc0201ad4:	962e                	add	a2,a2,a1
ffffffffc0201ad6:	a031                	j	ffffffffc0201ae2 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201ad8:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ada:	00e79a63          	bne	a5,a4,ffffffffc0201aee <strncmp+0x1c>
ffffffffc0201ade:	00b60b63          	beq	a2,a1,ffffffffc0201af4 <strncmp+0x22>
ffffffffc0201ae2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ae6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ae8:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201aec:	f7f5                	bnez	a5,ffffffffc0201ad8 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201aee:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201af2:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201af4:	4501                	li	a0,0
ffffffffc0201af6:	8082                	ret

ffffffffc0201af8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201af8:	ca01                	beqz	a2,ffffffffc0201b08 <memset+0x10>
ffffffffc0201afa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201afc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201afe:	0785                	addi	a5,a5,1
ffffffffc0201b00:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201b04:	fec79de3          	bne	a5,a2,ffffffffc0201afe <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201b08:	8082                	ret
