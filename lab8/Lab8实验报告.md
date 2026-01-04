# Lab8 实验报告

## 小组成员
| 姓名 | 学号 |
| :--- | :--- |
| 郑权 | 2312482 |
| 王玉涛 | 2312364 |
| 岳科言 | 2312163 |

## 实验目的
本次 Lab8 的目标是把前序实验中逐步建立起来的进程/内存/调度等机制，与文件系统真正“接起来”，最终实现“从文件系统加载并执行用户程序”的完整闭环。核心目的包括：

1. 理解并掌握 uCore 的文件系统抽象层次：**VFS（虚拟文件系统）** → 具体文件系统（SFS）→ 设备（disk0）之间的调用路径与职责划分。
2. 完成 SFS 文件数据读写的关键实现（练习 1），掌握：
   - 文件逻辑偏移（offset）到磁盘块号（block）的映射（bmap）
   - 非对齐读写、整块读写、尾部读写三种场景的处理
   - inode 元数据（size/dirty）维护与一致性思路
3. 完成基于文件系统的 `exec` 机制（练习 2），掌握：
   - 通过文件描述符读取 ELF 文件并装载到进程地址空间
   - 根据 ELF Program Header 建立 VMA、分配页、拷贝 TEXT/DATA、清零 BSS
   - 构造用户栈参数（argc/argv）并正确设置 trapframe，进入用户态运行
4. 在前序实验基础上完成必要的“系统集成改造”，使得：
   - `make qemu` 能进入 `sh` 用户交互程序
   - `make grade` 全部通过（本次实验达到 100/100）

## 实验环境
- 目标架构：RISC-V 64
- 运行器：QEMU（通过 `make qemu` 启动）
- 文件系统：SFS（Simple File System），挂载为 `disk0`，通过 VFS 统一访问
- 构建与测试：`make qemu`、`make grade`
- 用户程序位置：`user/` 目录（最终被打包进 `bin/sfs.img` 并由内核挂载）

## 实验内容
- 练习 0：将 Lab2～Lab7 的实现整合到 Lab8，并按 Lab8 的需要进行进一步修正，保证编译与测试通过。
- 练习 1：实现 `kern/fs/sfs/sfs_inode.c` 中 `sfs_io_nolock()` 的读文件部分（本实现同时覆盖读写通路）。
- 练习 2：改写 `kern/process/proc.c` 的 `load_icode()` 等相关逻辑，实现从文件系统加载 ELF 并执行的机制。
- Challenge1：给出在 uCore 中加入 UNIX Pipe 的概要设计（数据结构 + 接口语义 + 同步互斥考虑）。
- Challenge2：给出在 uCore 中加入 UNIX 硬链接与软链接的概要设计（数据结构 + 接口语义 + 同步互斥考虑）。

---

## 练习 0：填写已有实验并适配 Lab8

本次在 `proc_struct`、`fork/exit`、`proc_run`、`proc_init` 等位置补全或增强了“文件系统相关状态”的管理与必要的硬件行为。

#### 改动点 A：为进程增加并初始化 `filesp`（文件相关信息）
在 `kern/process/proc.c: alloc_proc()` 中新增初始化：

```c
// LAB8 add:
proc->filesp = NULL;
```

对应意义：
- `filesp` 指向 `struct files_struct`，内部维护：
  - 当前工作目录 `pwd`
  - 文件描述符数组 `fd_array`
  - 引用计数 `files_count`
  - 同步用信号量 `files_sem`
- 这使得“每个进程”都可以拥有独立或共享的文件视图（cwd+fd table），并为后续 `fork/exec/exit` 的语义落地提供支撑。

#### 改动点 B：`proc_init()` 初始化 `idleproc` 的 `filesp`
`idleproc` 是内核启动后的第一个内核线程，必须拥有基础的 `filesp`，否则之后的文件操作（例如 `sysfile_open`）会在缺乏 `current->filesp` 的情况下崩溃或行为未定义：

```c
if ((idleproc->filesp = files_create()) == NULL) {
    panic("create filesp (idleproc) failed.\n");
}
files_count_inc(idleproc->filesp);
```

#### 改动点 C：`proc_run()` 在切换页表后刷新 TLB
本次在 `proc_run()` 中，在 `lsatp(proc->pgdir)` 之后加入 `flush_tlb()`：

```c
// 加载新进程的页目录
lsatp(proc->pgdir);

// LAB8: 刷新TLB
flush_tlb();

// 上下文切换
switch_to(&(prev->context), &(proc->context));
```

原因说明：
- Lab8 引入更频繁的地址空间变化（尤其是 `exec` 时新建 mm + 切换 pgdir）。
- RISC-V 的 TLB 可能缓存旧的虚拟地址翻译。如果切换 SATP 后不刷新，可能出现：
  - 访问到旧进程的页表翻译（越权/错误数据）
  - 执行新程序时取指/访存异常
- 因此切换页表后刷新 TLB 是一种稳健做法（真实 OS 通常通过 `sfence.vma` 完成）。

#### 改动点 D：`do_fork()` 复制文件表（files_struct）
Lab8 的 `fork` 语义不仅要复制/共享内存，还要对文件相关状态做一致处理。实现采用引用计数与深拷贝结合的方式：

1) 若 `clone_flags & CLONE_FS`：共享父进程的 `filesp`（类似 Linux 共享文件系统上下文的语义）  
2) 否则：创建新的 `files_struct` 并 `dup_files()` 复制父进程已打开文件状态（文件描述符表）

关键代码路径：

```c
// LAB8: 复制文件描述符
if (copy_files(clone_flags, proc) != 0) {
    goto bad_fork_cleanup_kstack;
}
```

并在错误路径与退出路径做 `put_files(proc)`，确保引用计数正确回收。

#### 改动点 E：`do_exit()` 回收 files_struct
进程退出时不仅需要释放 mm，也需要释放与文件相关的资源：

```c
current->mm = NULL;
put_files(current);
```

该回收与 `files_count_dec()` 引用计数配合，确保：
- 多进程共享 `filesp` 时不会被提前销毁
- 最后一个引用退出后再释放 `files_struct` 与其中的 `fd_array` 等资源

---

## 练习 1：完成读文件操作 `sfs_io_nolock()` 的实现

### 1.1 任务描述
在 `kern/fs/sfs/sfs_inode.c` 中补全 `sfs_io_nolock()`，实现从指定 `offset` 开始、长度为 `*alenp` 的文件读操作（本实现同样支持写操作，因为函数本身以 `write` 参数区分读/写）。

### 1.2 打开/读文件的整体调用链
本练习编码点在 SFS 层，但要理解其位置，需要知道上层调用链大致如下：

1) 用户态：`read(fd, buf, len)`  
2) 系统调用：`sysfile_read(fd, ...)`（负责用户态/内核态缓冲区拷贝、循环读）  
3) VFS/File 层：`file_read(fd, ...)`（通过 file->node 调到 vnode/inode 的操作）  
4) VOP 层：`vop_read(inode, iobuf)`  
5) SFS 层：`sfs_read()` → `sfs_io()`（加锁封装） → `sfs_io_nolock()`（核心逻辑）

因此 `sfs_io_nolock()` 的正确性直接决定了整个文件读写体系是否可靠。

### 1.3 `sfs_io_nolock()` 关键设计点
`offset` 与 `endpos = offset + len` 可能不按块对齐，因此必须拆分为三段处理：

1) **首块非对齐段**：如果 `offset % BLKSIZE != 0`  
   - 读取/写入首个块的部分内容（从 `blkoff` 到块末尾）
2) **中间整块段**：对齐块的连续读/写  
   - 直接使用块读写函数进行整块操作，提高效率
3) **尾块非对齐段**：如果 `endpos % BLKSIZE != 0`  
   - 读取/写入最后一个块的前 `size` 字节

同时需要调用 `sfs_bmap_load_nolock()` 把“文件逻辑块号”映射到“磁盘块号”（或分配新块）。

### 1.4 代码实现（练习 1）
实现位于 `sfs_inode.c::sfs_io_nolock()`，核心片段如下（与源代码一致）：

```c
blkoff = offset % SFS_BLKSIZE;
if (blkoff != 0) {
    size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) {
        goto out;
    }
    alen += size;
    if (nblks == 0) {
        goto out;
    }
    buf += size;
    blkno++;
    nblks--;
}

// (2) 读写对齐的块
while (nblks > 0) {
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_block_op(sfs, buf, ino, 1)) != 0) {
        goto out;
    }
    alen += SFS_BLKSIZE;
    buf += SFS_BLKSIZE;
    blkno++;
    nblks--;
}

// (3) 尾部非对齐
size = endpos % SFS_BLKSIZE;
if (size != 0) {
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_buf_op(sfs, buf, size, ino, 0)) != 0) {
        goto out;
    }
    alen += size;
}
```

### 1.5 实现细节与边界条件说明
1. 读操作需要被文件大小截断：  
   - 若 `offset >= din->size` 直接返回 0  
   - 若 `endpos > din->size` 则 `endpos = din->size`  
   这样可以保证不会读到“文件末尾之外”的无效空间。

2. `SFS_MAX_FILE_SIZE` 上限保护：  
   - 防止越界读写导致元数据或块映射损坏。

3. inode size/dirty 维护：  
   在 `out:` 处根据 `offset + alen` 是否超过当前 size 更新 `din->size` 并设置 `sin->dirty = 1`，保证写入后元数据能被刷新到磁盘。

4. 加锁策略：  
   - `sfs_io()` 在调用 `sfs_io_nolock()` 前对 inode 加锁  
   - `sfs_io_nolock()` 假设外部已经持锁，因此内部不再加锁以避免重复锁开销与潜在死锁

---

## 练习 2：完成基于文件系统的执行程序机制（`exec`）

### 2.1 任务描述
改写 `kern/process/proc.c` 中的 `load_icode()` 与相关逻辑，实现：
- 通过文件系统读取 ELF 可执行文件
- 按 ELF Program Header 将程序段装载到新地址空间
- 正确建立用户栈与参数
- 通过 trapframe 设置，最终进入用户态运行（如 `sh`、`hello`、`exit` 等均在 SFS 中）

### 2.2 `exec` 的整体路径
以启动 `sh` 为例，路径可概括为：

1) `user_main()`（内核线程）调用 `KERNEL_EXECVE2(sh)`  
2) `kernel_execve()` 构造新的 trapframe 并调用 `do_execve()`  
3) `do_execve()`  
   - 拷贝用户态参数到内核（`copy_kargv`）  
   - 关闭旧进程打开的文件（`files_closeall`）  
   - `sysfile_open(path, O_RDONLY)` 打开 ELF 文件，得到 `fd`  
   - 若原 mm 存在则释放旧地址空间  
   - 调用 `load_icode(fd, argc, kargv)` 创建新 mm 并装载 ELF  
4) 成功后返回到 `__trapret`，通过 trapframe 进入用户态执行 ELF 的入口点 `e_entry`

### 2.3 `load_icode_read()`：基于 fd 的随机读取封装
为了在 ELF 装载时多次读取不同 offset 的内容，实现了：

```c
static int load_icode_read(int fd, void *buf, size_t len, off_t offset) {
    int ret;
    if ((ret = sysfile_seek(fd, offset, LSEEK_SET)) != 0) {
        return ret;
    }
    if ((ret = sysfile_read(fd, buf, len)) != len) {
        return (ret < 0) ? ret : -1;
    }
    return 0;
}
```

设计意义：
- ELF 头、Program Header、各段内容都位于不同 offset
- 把 “seek + read + 长度检查” 封装为一个工具函数，使 `load_icode()` 更清晰

### 2.4 `load_icode()` 的实现思路与步骤分解
`load_icode()` 的关键步骤与 Lab5 “从内存加载用户程序”类似，但数据来源变为“文件系统中的 ELF 文件”。

#### Step (1) 创建新的 mm
```c
if ((mm = mm_create()) == NULL) goto bad_mm;
```

#### Step (2) 创建页目录并挂接到 mm
```c
if (setup_pgdir(mm) != 0) goto bad_pgdir_cleanup_mm;
```

#### Step (3) 解析 ELF，并按 Program Header 装载各段
核心流程：
1) 读取 ELF Header，检查 `ELF_MAGIC`
2) 遍历 `e_phnum` 个 Program Header
3) 对 `PT_LOAD` 段：
   - 计算 VMA 权限与 PTE 权限（U/R/W/X）
   - `mm_map()` 建立 VMA
   - 按页分配并拷贝 `filesz` 内容（TEXT/DATA）
   - 对剩余 `memsz - filesz` 部分清零（BSS）

关键代码片段：

```c
// 读取ELF头并校验
if ((ret = load_icode_read(fd, elf, sizeof(struct elfhdr), 0)) != 0) goto bad_elf_cleanup_pgdir;
if (elf->e_magic != ELF_MAGIC) { ret = -E_INVAL_ELF; goto bad_elf_cleanup_pgdir; }

// 遍历 Program Header
for (phnum = 0; phnum < elf->e_phnum; phnum++) {
    off_t phoff = elf->e_phoff + sizeof(struct proghdr) * phnum;
    if ((ret = load_icode_read(fd, ph, sizeof(struct proghdr), phoff)) != 0) goto bad_cleanup_mmap;
    if (ph->p_type != ELF_PT_LOAD) continue;

    // 建立 vma
    vm_flags = 0, perm = PTE_U | PTE_V;
    ...
    if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) goto bad_cleanup_mmap;

    // 分页读入 filesz
    end = ph->p_va + ph->p_filesz;
    while (start < end) {
        if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) goto bad_cleanup_mmap;
        ...
        if ((ret = load_icode_read(fd, page2kva(page) + off, size, offset)) != 0) goto bad_cleanup_mmap;
        start += size, offset += size;
    }

    // 清零 BSS
    end = ph->p_va + ph->p_memsz;
    while (start < end) {
        if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) goto bad_cleanup_mmap;
        ...
        memset(page2kva(page) + off, 0, size);
        start += size;
    }
}
```

说明要点：
- `ROUNDDOWN(start, PGSIZE)` 让 `la` 对齐到页边界
- `pgdir_alloc_page(pgdir, la, perm)` 在页表中建立映射并分配物理页
- `page2kva(page)` 得到内核虚拟地址以便拷贝数据
- `filesz` 表示文件中真实存在的数据长度，`memsz` 表示运行时需要的内存大小，差值对应 BSS

#### Step (4) 建立用户栈 VMA 并预分配若干页
```c
vm_flags = VM_READ | VM_WRITE | VM_STACK;
mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL);

pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER);
pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER);
pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER);
pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER);
```

为什么要预分配多页：
- 便于放置 argv 字符串与 argv 指针数组
- 避免首次用户态访问栈顶就触发缺页异常

#### Step (5) 切换到新地址空间
```c
mm_count_inc(mm);
current->mm = mm;
current->pgdir = PADDR(mm->pgdir);
lsatp(PADDR(mm->pgdir));
```

#### Step (6) 构造用户栈上的 argc/argv
本实现把参数从内核 `kargv` 拷贝到用户栈空间，并设置 `a0/a1`：

```c
uintptr_t stacktop = USTACKTOP - (argc + 1) * sizeof(char *);
char **uargv = (char **)(stacktop - argc * sizeof(char *));
stacktop = (uintptr_t)uargv;

for (i = 0; i < argc; i++) {
    uargv[i] = strcpy((char *)(stacktop -= strlen(kargv[i]) + 1), kargv[i]);
}
stacktop = ROUNDDOWN(stacktop, sizeof(long));
stacktop -= sizeof(int);
*(int *)stacktop = argc;
```

语义说明：
- 用户栈从高地址向低地址增长，因此字符串与结构都向低地址压入
- `uargv[i]` 指向用户栈中对应的字符串位置
- 最终把 `argc` 与 `uargv` 分别放入 `a0/a1`

#### Step (7) 设置 trapframe 并进入用户态
```c
struct trapframe *tf = current->tf;
uintptr_t sstatus = tf->status;
memset(tf, 0, sizeof(struct trapframe));
tf->gpr.sp = stacktop;
tf->epc = elf->e_entry;
tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
tf->gpr.a0 = argc;
tf->gpr.a1 = (uintptr_t)uargv;
```

关键点解释：
- `epc = e_entry`：用户态从 ELF 入口点开始执行
- 清除 `SSTATUS_SPP`：确保返回时进入 U-mode
- `SSTATUS_SPIE`：开启用户态中断使能（返回后可响应中断）

#### Step (8) 错误处理与资源回收
在任意阶段失败，需要释放已创建资源：
- `exit_mmap(mm)`：释放 VMA 与已映射页面
- `put_pgdir(mm)`：释放页目录
- `mm_destroy(mm)`：释放 mm 结构本身

本实现采用 `goto` 错误路径集中回收。

---

## 实验验证与结果截图

1. `make qemu`：能够从文件系统执行 `sh`，并运行用户程序输出，最后 `exit` 正常执行。

![make qemu运行结果](lab8_qemu.png)

2. `make grade`：测试用例全部通过，总分 100/100。

![make grade运行结果](lab8_grade.png)

---

## 扩展练习 Challenge1：UNIX PIPE 机制的设计方案

### 设计目标与语义要求
Pipe 是一种典型 IPC（进程间通信）机制，语义要点包括：
1. `pipe(int fd[2])` 创建一条单向字节流通道，返回读端 `fd[0]`、写端 `fd[1]`
2. 读端：
   - 若缓冲区为空且写端仍存在：阻塞等待
   - 若写端全部关闭且缓冲区为空：读返回 0（EOF）
3. 写端：
   - 若缓冲区满且读端仍存在：阻塞等待
   - 若读端全部关闭：写返回错误（典型 UNIX 语义为 SIGPIPE/EPIPE）
4. 与 `fork/dup/close` 的交互：
   - `fork` 后 pipe 的两端文件描述符会被复制，引用计数增加
   - 当最后一个读端/写端关闭时释放 pipe 对象

### 需要新增/扩展的数据结构
把 pipe 做成一种“特殊文件”（special file），与现有 `file`/`inode`/`vop` 框架对齐。

1) pipe 核心对象：环形缓冲区 + 同步结构 + 引用计数

```c
#define PIPE_BUF 4096

typedef struct pipe {
    // 环形缓冲区
    uint8_t  buf[PIPE_BUF];
    uint32_t rpos;          // read position
    uint32_t wpos;          // write position
    uint32_t data;          // 当前有效数据量

    // 引用计数：分别统计读端/写端还有多少打开实例
    int readers;
    int writers;

    // 同步互斥
    semaphore_t mutex;      // 保护 rpos/wpos/data/readers/writers
    wait_queue_t rq;        // 读等待队列（buffer empty）
    wait_queue_t wq;        // 写等待队列（buffer full）
} pipe_t;
```

2) file 层对接：为 pipe 定义一套 file_ops/vop 接口
- 可以增加 `FD_PIPE` 或复用 `struct inode` 的一个新 type（如 `SFS_TYPE_PIPE` 也可行，但更常见是“无磁盘 inode 的匿名对象”）

```c
struct pipe_file {
    pipe_t *p;
    bool is_read_end;
};
```

### 需要提供的接口
系统调用层（用户可见）：
- `int sys_pipe(int fd[2]);`
  - 分配 pipe_t
  - 分配两个 file 对象，分别标记为读端/写端
  - 安装到当前进程 fd 表，返回两个 fd

file/vop 层（内核内部）：
- `ssize_t pipe_read(struct file *f, void *buf, size_t len, size_t *copied);`
- `ssize_t pipe_write(struct file *f, const void *buf, size_t len, size_t *copied);`
- `int pipe_close(struct file *f);`
- `int pipe_dup(struct file *to, struct file *from);`

### 同步互斥与竞态处理要点
1. 多读多写并发：  
   - 必须用 `mutex` 保护 `data/rpos/wpos` 等共享状态  
   - 防止两个 writer 同时写导致覆盖，两个 reader 同时读导致重复读取

2. 阻塞/唤醒条件：  
   - 读：`while (data == 0 && writers > 0) sleep(rq)`  
   - 写：`while (data == PIPE_BUF && readers > 0) sleep(wq)`  
   - 状态变化后 `wakeup(rq)` 或 `wakeup(wq)`  
   - 注意避免“丢失唤醒”：检查条件与入队睡眠必须在同一临界区（mutex 内）完成

3. 关闭语义：  
   - 关闭读端：`readers--`，若变为 0，唤醒所有 writer（使其返回 EPIPE）  
   - 关闭写端：`writers--`，若变为 0，唤醒所有 reader（使其读到 EOF 或继续消费缓冲区）

---

## 扩展练习 Challenge2：UNIX 软链接与硬链接机制的设计方案

### 2.1 硬链接（Hard Link）
硬链接的本质：**目录项（dirent）指向同一个 inode**，inode 内维护 `nlinks`（链接计数）。

#### 需要/复用的数据结构
uCore/SFS 本身已经有 `sfs_disk_inode.nlinks` 字段，可直接用于硬链接计数；目录项需要能存储 inode 号（SFS 通常目录项包含 inode number + name）。

#### 需要提供的接口
- `int sys_link(const char *oldpath, const char *newpath);`
  1) 解析 `oldpath` 得到 inode（必须存在、通常不允许为目录）
  2) 在 `newpath` 所在目录中创建新目录项，指向 old inode
  3) `inode->nlinks++`，并持久化 inode 与目录块

- `int sys_unlink(const char *path);`
  1) 在目录中删除该目录项
  2) `inode->nlinks--`
  3) 若 `nlinks==0` 且没有打开引用，则回收数据块与 inode

#### 同步互斥要点
- 目录修改必须加锁（避免并发创建同名项/删除同一项）
- inode 的 `nlinks` 更新必须与目录项变更原子化（至少在同一锁保护区内）
- 若有多级锁（目录锁 + inode 锁），需规定锁顺序避免死锁（例如：先锁目录，再锁 inode）

### 2.2 软链接（Symbolic Link）
软链接的本质：**一个独立的 inode，内容是目标路径字符串**。路径解析（namei）遇到 symlink 时需要“跳转”到目标路径继续解析。

#### 建议新增的数据结构/扩展点
1) 新 inode 类型：例如在 SFS 中增加
- `SFS_TYPE_SYMLINK`

2) symlink inode 的数据内容
- 最简单做法：把“目标路径字符串”当作普通文件内容存储（写入数据块），并用 `din->size` 记录长度
- 小路径可做 inode 内联优化

#### 需要提供的接口
- `int sys_symlink(const char *target, const char *linkpath);`
  1) 在 `linkpath` 创建一个新 inode，type=SYMLINK
  2) 写入 `target` 字符串到 symlink inode 数据区
  3) 在目录中创建目录项指向该 inode

- `int sys_readlink(const char *path, char *buf, size_t buflen);`
  1) 解析到 symlink inode
  2) 读取其内容（target path）到用户缓冲区（不追加 '\0' 或按 UNIX 语义处理）

- 路径解析增强：`namei()` / `vfs_lookup()` 遇到 symlink 时
  - 读取其目标路径
  - 若目标是相对路径：以 symlink 所在目录为基准拼接
  - 设置最大跳转深度（例如 8 或 40）防止循环链接：`ELOOP`

#### 同步互斥要点
- symlink 创建与读写需 inode 锁保护
- 路径解析时需要注意：解析过程可能跨目录/跨 inode，多锁情况下要严格锁顺序或使用引用计数与“逐段加锁、逐段释放”的策略降低死锁风险

---

## lab6、练习 1：理解调度器框架的实现

### 2.1 `sched_class` 结构体分析：函数指针含义、调用时机与设计原因

我在 `kern/schedule/sched.h` 中看到调度类的接口定义如下：  

```c
struct sched_class
{
    // the name of sched_class
    const char *name;
    // Init the run queue
    void (*init)(struct run_queue *rq);
    // put the proc into runqueue, and this function must be called with rq_lock
    void (*enqueue)(struct run_queue *rq, struct proc_struct *proc);
    // get the proc out runqueue, and this function must be called with rq_lock
    void (*dequeue)(struct run_queue *rq, struct proc_struct *proc);
    // choose the next runnable task
    struct proc_struct *(*pick_next)(struct run_queue *rq);
    // dealer of the time-tick
    void (*proc_tick)(struct run_queue *rq, struct proc_struct *proc);
    /* for SMP support in the future
     *  load_balance
     *     void (*load_balance)(struct rq* rq);
     *  get some proc from this rq, used in load_balance,
     *  return value is the num of gotten proc
     *  int (*get_proc)(struct rq* rq, struct proc* procs_moved[]);
     */
};
```

1）`name`  
用于标识调度类名字，主要用于调试输出。例如 `sched_init()` 最后会打印当前调度类名称。

2）`init(struct run_queue *rq)`  
初始化运行队列内部状态。调用时机：调度器初始化阶段（`sched_init()`）。

3）`enqueue(struct run_queue *rq, struct proc_struct *proc)`  
把可运行进程加入运行队列。典型调用时机：
- 进程被唤醒变为 runnable（`wakeup_proc()`）
- 当前进程在 `schedule()` 中仍保持 runnable，则重新入队
- 其它进入就绪态的路径（例如 fork 之后）也会触发入队

4）`dequeue(struct run_queue *rq, struct proc_struct *proc)`  
把进程从运行队列移除。典型调用时机：在 `schedule()` 选中 `next` 后将其出队，避免重复占用。

5）`pick_next(struct run_queue *rq)`  
选择下一个要运行的进程，这是调度策略的核心决策点。调用时机：`schedule()` 中。

6）`proc_tick(struct run_queue *rq, struct proc_struct *proc)`  
时钟 tick 处理：更新当前进程的时间片、必要时设置 `need_resched` 触发抢占。调用时机：每次时钟中断发生后。

为什么要用函数指针，而不是把 RR/Stride 写死在 `schedule()` 里？  
我的理解是：这是典型的“策略（policy）与机制（mechanism）分离”。框架提供固定骨架（临界区保护、上下文切换、安全调度点），算法通过接口注入“如何排队、如何选择、何时抢占”。这样做的直接好处是：新增/切换算法只改一个绑定点，不需要把框架改成一堆 if-else 分支。

另外，`sched_class` 里还留了 SMP 扩展接口的注释（`load_balance` 等），说明这个抽象也在为将来多核调度留接口。

---

### 2.2 `run_queue` 结构体分析：Lab5 vs Lab6 差异与“链表 + 斜堆”并存原因

我在 `kern/schedule/sched.h` 中看到 Lab6 的 `run_queue` 定义如下：  

```c
struct run_queue
{
    list_entry_t run_list;
    unsigned int proc_num;
    int max_time_slice;
    // For LAB6 ONLY
    skew_heap_entry_t *lab6_run_pool;
};
```

字段含义：

- `run_list`：就绪队列链表头。RR/FIFO 这类队列型算法使用它非常自然：队尾入队、队首出队。  
- `proc_num`：就绪队列里 runnable 进程的数量，用于判断空队列以及做一致性维护。  
- `max_time_slice`：统一的最大时间片配置，RR/Stride 都依赖它来决定抢占粒度。  
- `lab6_run_pool`：斜堆（skew heap）根指针，用于 Stride 的优先队列实现（按最小 pass/stride 取进程）。

我对 Lab5 与 Lab6 的差异理解：  
Lab5 多数情况下只用链表支撑简单调度；Lab6 为了支持 Stride 这种“每次选择 key 最小进程”的算法，如果只用链表，每次 `pick_next` 都要 O(n) 扫描找最小值，成本明显更高。因此 Lab6 增加 `lab6_run_pool` 支持 skew heap，使得插入/删除更高效，并能快速获得“最小 key 的进程”。

为什么 run_queue 要同时支持链表与斜堆？  
我认为这是“同一框架兼容多算法”的取舍：框架只持有 `run_queue`，不希望因算法不同而换结构体类型。具体算法内部再决定用链表还是堆（Stride 里用 `USE_SKEW_HEAP` 控制），保持可扩展性。

---

### 2.3 框架函数分析：`sched_init()`、`wakeup_proc()`、`schedule()` 如何与算法解耦

#### 2.3.1 `sched_init()`：绑定默认调度类 + 初始化 runqueue

```c
sched_init(void)
{
    list_init(&timer_list);

    sched_class = &default_sched_class;

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);

    cprintf("sched class: %s\n", sched_class->name);
}
```

我关注的点：

- `sched_class = &default_sched_class;`：默认绑定 RR 调度类。若要启用 Stride，只需要把这里改成 `&stride_sched_class`。  
- `rq->max_time_slice = MAX_TIME_SLICE;`：统一配置时间片上限。  
- `sched_class->init(rq);`：调用调度类自己的 init，让“队列内部结构初始化”与框架解耦。

#### 2.3.2 `wakeup_proc()`：框架负责状态切换，入队策略交给 sched_class

```c
wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
        {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            if (proc != current)
            {
                sched_class_enqueue(proc);
            }
```

我的理解：

- `wakeup_proc` 先把 `proc->state` 切到 `PROC_RUNNABLE`，清掉 `wait_state`；  
- 只要唤醒的不是当前进程，就调用 `sched_class_enqueue(proc)` 把它交给具体调度类入队；  
- 这个函数本身不关心“入队方式”，因此 RR/Stride 都能复用这条路径。

#### 2.3.3 `schedule()`：框架控制流固定，策略点由接口注入

```c
schedule(void)
{
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
        if (current->state == PROC_RUNNABLE)
        {
            sched_class_enqueue(current);
        }
```

我把它拆成两层理解：

- 框架固定骨架：关中断、清 `need_resched`、必要时把 current 入队、选 next、必要时出队、fallback idle、做上下文切换、恢复中断。  
- 策略注入点：`enqueue/dequeue/pick_next` 三个关键点完全由 `sched_class` 决定，因此能做到算法可插拔。

#### 2.3.4 idleproc 的特殊处理

```c
sched_class_enqueue(struct proc_struct *proc)
{
    if (proc != idleproc)
    {
        sched_class->enqueue(rq, proc);
    }
sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
    {
        sched_class->proc_tick(rq, proc);
    }
```

我认为这两处特殊处理很关键：

- idle 不入队：避免 idle 混入 RR/Stride 的正常队列导致逻辑混乱；  
- idle tick 强制 `need_resched = 1`：配合 `cpu_idle()` 让系统在 idle 状态下每个 tick 都会尝试一次 `schedule()`，从而能及时切换到新 runnable 进程。

---

### 2.4 调度器使用流程分析

#### 2.4.1 调度类初始化流程：从启动到 sched_init 完成

1）内核完成中断/时钟初始化，使 timer interrupt 能触发；  
2）创建并设置 `idleproc` 与 `current`；  
3）调用 `sched_init()`：绑定 `sched_class`，初始化 `rq`，调用 `sched_class->init`；  
4）之后每次 timer tick 都会调用 `sched_class_proc_tick(current)` 推进抢占式调度。

#### 2.4.2 进程调度流程图：timer interrupt → proc_tick → schedule

我在 `trap.c` 中看到 timer interrupt 会调用 `sched_class_proc_tick(current)`：

```c
    case IRQ_S_TIMER:
        // "All bits besides SSIP and USIP in the sip register are
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /* LAB3 :填写你在lab3中实现的代码 */
        // lab6: YOUR CODE  (update LAB3 steps)
        //  在时钟中断时调用调度器的 sched_class_proc_tick 函数
        clock_set_next_event();
        ticks++;
        sched_class_proc_tick(current);

        break;
    case IRQ_H_TIMER:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_TIMER:
        cprintf("Machine software interrupt\n");
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
```

同时，在 trap 从用户态返回前，如果 `need_resched` 为 1 会调用 `schedule()`（节选）：

```c

        current->tf = otf;
        if (!in_kernel)
        {
            if (current->flags & PF_EXITING)
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
            {
                schedule();
            }
        }
    }
```

我把整体过程做成流程图如下：

```mermaid
flowchart TD
  A[时钟中断 IRQ_S_TIMER] --> B[trap/interrupt handler]
  B --> C[clock_set_next_event & ticks++]
  C --> D[sched_class_proc_tick(current)]
  D --> E{{current 是否 idleproc?}}
  E -- 否 --> F[RR/Stride proc_tick: time_slice--]
  F --> G{{time_slice == 0?}}
  G -- 否 --> H[继续运行 current]
  G -- 是 --> I[current.need_resched = 1]
  E -- 是 --> J[idleproc.need_resched = 1]
  I --> K[返回 trap]
  J --> K
  K --> L{{是否从用户态返回?}}
  L -- 是 --> M{{need_resched == 1?}}
  M -- 是 --> N[schedule()]
  M -- 否 --> O[返回用户态继续]
  L -- 否 --> P[回到内核线程/idleproc]
  P --> Q{{cpu_idle 循环里 need_resched?}}
  Q -- 是 --> N
  Q -- 否 --> P
```

其中 `need_resched` 在我理解里是“延迟调度请求标志”：tick 中断里只置位，真正调度发生在 trap 返回用户态前或 idle 循环的安全点，避免在中断上下文随意切换带来的复杂性。

#### 2.4.3 调度算法切换机制：如何新增/切换（以 Stride 为例）

如果我要切换到 Stride，我需要改动非常集中：

1）`sched_init()`：把 `sched_class = &default_sched_class;` 改为 `&stride_sched_class;`  
2）保证 `default_sched_stride.c` 完整实现 `init/enqueue/dequeue/pick_next/proc_tick`  
3）保证 `proc_struct` 与 `run_queue` 的 Stride 相关字段存在并初始化

之所以切换容易，是因为 `schedule()` 的控制流不变，只是通过 `sched_class` 指针调用不同实现。

---

## lab6、练习 2：实现 Round Robin（RR）调度算法

### 3.1 选择一个 Lab5/Lab6 实现不同的函数进行比较：`schedule()` 的框架化

我认为 Lab6 相比 Lab5 的关键变化之一就是：`schedule()` 不再写死队列操作，而是通过 `sched_class` 抽象出策略点（enqueue/dequeue/pick_next/proc_tick）。  
如果不做这个改动，Stride 这种“按最小 key 取进程”的策略就很难融入，并且会造成严重耦合：每新增一种算法就要改动 `schedule()` 甚至唤醒路径，最终演变为难维护的分支堆叠。

---

### 3.2 RR 的实现位置与目标

RR 要求：队尾入队、队首出队；每个进程运行固定时间片，时间片耗尽后触发切换，并把当前进程重新入队到队尾。

我在 `kern/schedule/default_sched.c` 中实现/检查了 5 个函数：`RR_init/RR_enqueue/RR_dequeue/RR_pick_next/RR_proc_tick`。

---

### 3.3 `RR_init`：初始化队列

```c
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}
```

我用 `list_init` 初始化就绪链表，`proc_num=0` 表示空队列。

---

### 3.4 `RR_enqueue`：队尾入队 + 时间片修正 + 维护一致性

```c
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link));
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}
```

我这里选择 `list_add_before(&rq->run_list, &proc->run_link)` 来实现队尾插入。原因是 `run_list` 是哨兵头结点，在 head 之前插入等价于插入到链表最后，满足 RR 的 FIFO 入队语义。

时间片修正逻辑的目的：  
- `time_slice==0` 表示耗尽或未初始化，重新入队必须补满；  
- `time_slice` 异常过大也强制收敛，避免逻辑错误导致进程长期不被抢占。

---

### 3.5 `RR_dequeue`：出队并初始化节点

```c
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num--;
}
```

我使用 `list_del_init` 而不是仅删除，是为了把节点恢复到“未入队”的安全状态，后续 `assert(list_empty(&run_link))` 能更可靠地发现重复入队错误。

---

### 3.6 `RR_pick_next`：取队首

```c
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}
```

空队列返回 NULL，框架会 fallback 到 idleproc；非空则用 `le2proc` 把 `list_entry_t` 转回 `proc_struct*`。

---

### 3.7 `RR_proc_tick`：时间片递减与抢占触发

```c
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}
```

当 `time_slice==0` 时置 `need_resched=1`，使得抢占式 RR 生效。如果不置位，CPU-bound 进程会一直运行，RR 退化为非抢占式甚至类似 FIFO。

---

### 3.8 边界条件与异常处理

- 空队列：`RR_pick_next` 返回 NULL → `schedule()` 选 idle；  
- 重复入队：`assert(list_empty(&proc->run_link))` 防止结构损坏；  
- 重复出队：`list_del_init` + assert 防止二次删除；  
- 时间片异常：统一修正到 `max_time_slice`；  
- idle 进程：框架层排除，不参与 RR 队列。

---

## lab6、Challenge 1：实现 Stride Scheduling

### 4.1 Stride 的目标与核心思想

Stride 的目标是按权重比例公平：priority 更大者获得更多 CPU 份额。做法是维护每个进程的虚拟进度 pass，每次被调度就把 pass 增加 `BIG_STRIDE/priority`，并始终选择 pass 最小者运行。

---

### 4.2 数据结构：`proc_struct`、`run_queue` 与初始化

#### 4.2.1 `proc_struct` 字段（节选）

```c
    int exit_code;                          // exit code (be sent to parent proc)
    uint32_t wait_state;                    // waiting state
    struct proc_struct *cptr, *yptr, *optr; // relations between processes
    struct run_queue *rq;                   // running queue contains Process
    list_entry_t run_link;                  // the entry linked in run queue
    int time_slice;                         // time slice for occupying the CPU
    skew_heap_entry_t lab6_run_pool;        // FOR LAB6 ONLY: the entry in the run pool
    uint32_t lab6_stride;                   // FOR LAB6 ONLY: the current stride of the process
    uint32_t lab6_priority;                 // FOR LAB6 ONLY: the priority of process, set by lab6_set_priority(uint32_t)
};

#define PF_EXITING 0x00000001 // getting shutdown

#define WT_CHILD (0x00000001 | WT_INTERRUPTED)
#define WT_INTERRUPTED 0x80000000 // the wait state could be interrupted

#define le2proc(le, member) \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority);

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);
int do_yield(void);
```

#### 4.2.2 `alloc_proc()` 初始化（节选）

```c

        // LAB5:填写你在lab5中实现的代码 (update LAB4 steps)
        proc->wait_state = 0;        // 0 通常表示不在等待状态
        proc->cptr = NULL;           // child pointer: 还没有孩子
        proc->yptr = NULL;           // younger sibling: 还没有更"年轻"的兄弟
        proc->optr = NULL;           // older sibling: 还没有更"年长"的兄弟

        // LAB6:YOUR CODE (update LAB5 steps)
        proc->rq = NULL;             // 运行队列
        list_init(&(proc->run_link)); // 初始化运行队列链表项
        proc->time_slice = 0;        // 时间片
        proc->lab6_run_pool.left = proc->lab6_run_pool.right = proc->lab6_run_pool.parent = NULL;
        proc->lab6_stride = 0;       // stride值
        proc->lab6_priority = 0;     // 优先级
    }
    return proc;
}

```

把 `lab6_stride` 初始化为 0，`lab6_priority` 初始化为 0，并在后续计算时对 priority=0 做保护（或由系统调用改为至少 1）。

---

### 4.3 priority 设置链路：syscall + 内核函数

syscall：

```c
sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
    return 0;
}
```

内核实际设置：

```c
void lab6_set_priority(uint32_t priority)
{
    cprintf("set priority to %d\n", priority);
    if (priority == 0)
        current->lab6_priority = 1;
    else
        current->lab6_priority = priority;
}
```

priority=0 时强制设为 1，是为了避免除 0。

---

### 4.4 Stride 调度类逐函数解释

比较函数：

```c
proc_stride_comp_f(void *a, void *b)
{
     struct proc_struct *p = le2proc(a, lab6_run_pool);
     struct proc_struct *q = le2proc(b, lab6_run_pool);
     int32_t c = p->lab6_stride - q->lab6_stride;
     if (c > 0)
          return 1;
     else if (c == 0)
          return 0;
     else
          return -1;
}
```

初始化：

```c
stride_init(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: YOUR CODE
      * (1) init the ready process list: rq->run_list
      * (2) init the run pool: rq->lab6_run_pool
      * (3) set number of process: rq->proc_num to 0
      */
     list_init(&(rq->run_list));
     rq->lab6_run_pool = NULL;
     rq->proc_num = 0;
}
```

入队：

```c
stride_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: YOUR CODE
      * (1) insert the proc into rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_insert: insert a entry into skew_heap
      *         list_add_before: insert  a entry into the last of list
      * (2) recalculate proc->time_slice
      * (3) set proc->rq pointer to rq
      * (4) increase rq->proc_num
      */
#if USE_SKEW_HEAP
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
#else
     list_add_before(&(rq->run_list), &(proc->run_link));
#endif
     if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
          proc->time_slice = rq->max_time_slice;
     }
     proc->rq = rq;
     rq->proc_num++;
}
```

出队：

```c
stride_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: YOUR CODE
      * (1) remove the proc from rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_remove: remove a entry from skew_heap
      *         list_del_init: remove a entry from the  list
      */
#if USE_SKEW_HEAP
     rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
#else
     assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
     list_del_init(&(proc->run_link));
#endif
     rq->proc_num--;
}
```

选择下一个并更新 pass：

```c
stride_pick_next(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: YOUR CODE
      * (1) get a  proc_struct pointer p  with the minimum value of stride
             (1.1) If using skew_heap, we can use le2proc get the p from rq->lab6_run_pol
             (1.2) If using list, we have to search list to find the p with minimum stride value
      * (2) update p;s stride value: p->lab6_stride
      * (3) return p
      */
#if USE_SKEW_HEAP
     if (rq->lab6_run_pool == NULL) {
          return NULL;
     }
     struct proc_struct *p = le2proc(rq->lab6_run_pool, lab6_run_pool);
#else
     list_entry_t *le = list_next(&(rq->run_list));
     if (le == &(rq->run_list)) {
          return NULL;
     }
     struct proc_struct *p = le2proc(le, run_link);
     le = list_next(le);
     while (le != &(rq->run_list)) {
          struct proc_struct *q = le2proc(le, run_link);
          if ((int32_t)(q->lab6_stride - p->lab6_stride) < 0) {
               p = q;
          }
          le = list_next(le);
     }
#endif
     if (p->lab6_priority == 0) {
          p->lab6_stride += BIG_STRIDE;
     } else {
          p->lab6_stride += BIG_STRIDE / p->lab6_priority;
     }
     return p;
}
```

tick 驱动抢占：

```c
stride_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: YOUR CODE */
     if (proc->time_slice > 0) {
          proc->time_slice--;
     }
     if (proc->time_slice == 0) {
          proc->need_resched = 1;
     }
}
```

我认为这里最关键的是 `stride_pick_next`：选最小 pass 的进程，并在选中后更新其 pass（`pass += BIG_STRIDE/priority`），从而实现比例公平。

---

### 4.5 为什么“时间片数 ∝ priority”

如果进程 i 每获得一次时间片，其 pass 增加 `BIG_STRIDE/p_i`。当它获得 k_i 次时间片后，pass 增量约为 `k_i*BIG_STRIDE/p_i`。调度器总选 pass 最小者运行，会让各进程 pass 长期维持在同一数量级（否则 pass 大的会长期得不到运行，pass 小的会频繁运行直到追平）。因此长期平均上有：

`k_i*BIG_STRIDE/p_i ≈ k_j*BIG_STRIDE/p_j`  
推出 `k_i/k_j ≈ p_i/p_j`，即时间片分配近似与 priority 成比例。

---

### 4.6 多级反馈队列（MLFQ）调度算法设计

我给出一个可落地到 uCore 的设计方案：

- run_queue：L 个队列 `mlfq[L]`（每级一个链表），各自 quantum 不同；  
- proc_struct：增加 `mlfq_level`、`ticks_left`、`last_enqueue_tick`；  
- pick_next：从最高级队列找到第一个非空队列取队首；同级内部 RR；  
- 用完 quantum 不阻塞 → 降级（惩罚 CPU-bound）；提前阻塞 → 保持/提升（奖励交互）；  
- 防饥饿：periodic boost（周期性把所有 runnable 提升到最高级）或 aging（等待过久提升）。

MLFQ 也可以作为独立 `sched_class` 实现，不改 `schedule()` 主流程。

---

### 4.7 `priority` 用户程序

```c
#include <ulib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define TOTAL 5
/* to get enough accuracy, MAX_TIME (the running time of each process) should >1000 mseconds. */
#define MAX_TIME  2000
unsigned int acc[TOTAL];
int status[TOTAL];
int pids[TOTAL];

static void
spin_delay(void)
{
     int i;
     volatile int j;
     for (i = 0; i != 200; ++ i)
     {
          j = !j;
     }
}

int
main(void) {
     int i,time;
     memset(pids, 0, sizeof(pids));
     lab6_setpriority(TOTAL + 1);

     for (i = 0; i < TOTAL; i ++) {
          acc[i]=0;
          if ((pids[i] = fork()) == 0) {
               lab6_setpriority(i + 1);
               acc[i] = 0;
               while (1) {
                    spin_delay();
                    ++ acc[i];
                    if(acc[i]%4000==0) {
                        if((time=gettime_msec())>MAX_TIME) {
                            cprintf("child pid %d, acc %d, time %d\n",getpid(),acc[i],time);
                            exit(acc[i]);
                        }
                    }
               }
               
          }
          if (pids[i] < 0) {
               goto failed;
          }
     }

     cprintf("main: fork ok,now need to wait pids.\n");

     for (i = 0; i < TOTAL; i ++) {
         status[i]=0;
         waitpid(pids[i],&status[i]);
         cprintf("main: pid %d, acc %d, time %d\n",pids[i],status[i],gettime_msec()); 
     }
     cprintf("main: wait pids over\n");
     cprintf("sched result:");
     for (i = 0; i < TOTAL; i ++)
     {
         cprintf(" %d", (status[i] * 2 / status[0] + 1) / 2);
     }
     cprintf("\n");

     return 0;

failed:
     for (i = 0; i < TOTAL; i ++) {
          if (pids[i] > 0) {
               kill(pids[i]);
          }
     }
     panic("FAIL: T.T\n");
}

```
---

## lab6、Challenge 2：实现更多调度算法 

### 5.1 目标与总体思路

Challenge 2 的重点是：实现多种调度算法，并通过统一插桩与统一 workload，定量对比不同算法在响应时间、等待时间、周转时间、吞吐、公平性、上下文切换开销等方面的差异，最后总结适用范围。

### 5.2 算法实现方式：一算法一 `sched_class`

我倾向把每种算法都写成一个独立 sched_class（例如 `fifo_sched_class/sjf_sched_class/mlfq_sched_class`），这样切换算法只需要改 `sched_init()` 的绑定点，控制变量明确，便于对比实验。

### 5.3 指标体系与插桩位置

- create_tick：fork 时记录  
- first_run_tick：第一次被调度运行时记录  
- exit_tick：退出时记录  
- waiting_time：enqueue 时记录时间戳，dequeue 时累加等待  
- cpu_ticks：每 tick 若当前进程运行则累加  
- ctx_switches：统计 `proc_run()` 次数

公平性可用 Jain 指数，也可以直接用 `cpu_ticks` 比例来验证 RR（近似相等）与 Stride（按权重比例）。

---

## 本实验中的重要知识点与对应的 OS 原理

1. VFS 抽象与具体文件系统实现（SFS）
   - 原理侧：VFS 提供统一接口（open/read/write/lookup），屏蔽具体 FS 差异，是“面向对象式”的内核抽象。
   - 实验侧：通过 `vop_read` → `sfs_read` → `sfs_io_nolock` 体现出“接口与实现解耦”。
   - 关系：VFS 是上层“语义统一”，SFS 是下层“策略与布局具体化”；二者通过 vnode/inode 与 vop 表连接。

2. inode / 目录项 / 数据块：文件系统的核心元数据组织
   - 原理侧：inode 存储文件属性与数据块指针；目录项将文件名映射到 inode。
   - 实验侧：`sfs_disk_inode` 提供 `size/blocks/nlinks`，`sfs_bmap_load_nolock` 提供逻辑块到物理块映射，`sfs_io_nolock` 完成真正的数据读写。
   - 差异点：实验文件系统较简化（SFS），没有日志、没有复杂缓存策略，但核心元数据思想一致。

3. 文件读写的“对齐/非对齐”处理与块设备 I/O
   - 原理侧：文件系统通常以块为单位管理磁盘，非对齐读写需要读-改-写或部分读。
   - 实验侧：`sfs_io_nolock` 明确拆分三段（首块非对齐 / 中间整块 / 尾块非对齐），体现真实 FS 的典型处理方式。

4. 进程的文件描述符表与 fork/exit 资源管理
   - 原理侧：进程是资源容器，fd table 是“进程对文件对象的引用集合”；fork 需要复制引用，exit 需要释放引用。
   - 实验侧：`proc_struct.filesp` + `copy_files()` + `put_files()` + 引用计数 `files_count` 完成资源共享与回收。
   - 关系：这属于“面向资源的进程模型”，与 Linux/Unix 语义一致。

5. exec 装载器与 ELF 格式
   - 原理侧：exec 会用新程序替换当前进程地址空间；ELF 描述段布局与权限。
   - 实验侧：`load_icode_read` 从文件系统读取 ELF；`mm_map/pgdir_alloc_page` 建立映射；按 `filesz/memsz` 处理 DATA/BSS；设置 `epc/sp/a0/a1` 进入用户态。
   - 差异点：实验使用 eager 分配栈页、没有按需分页与 page cache，但整体装载逻辑与真实 OS 同构。

6. 地址空间切换与 TLB 一致性
   - 原理侧：切换页表后需要维护 TLB 与页表一致，否则会执行/访问错误映射。
   - 实验侧：`proc_run` 加入 `flush_tlb()`，与 RISC-V 的 `sfence.vma` 对应。

7. 用户态/内核态切换与 trapframe
   - 原理侧：系统调用/异常依赖保存现场与恢复现场；trapframe 是核心。
   - 实验侧：exec 完成后通过设置 trapframe 的 `epc/sp/status/a0/a1`，使 `__trapret` 能正确返回用户态运行新程序。

---

## OS 原理中很重要但在本实验中没有对应实现的知识点

1. 崩溃一致性与日志文件系统（Journaling / WAL）
   - 真实 OS 必须保证断电崩溃后文件系统一致性；SFS 实验未实现日志与事务。

2. Page Cache / Buffer Cache 的统一与写回策略
   - 真实系统通过页缓存减少磁盘 IO，并有复杂的写回/回收策略；实验中的缓存与一致性策略较简化。

3. 按需分页（Demand Paging）与缺页异常驱动的装载
   - 实验中 exec 时主动把段内容拷贝进内存并预分配栈；真实系统可采用按需调页、延迟分配与 COW 等优化。

4. 更丰富的权限与安全机制
   - UNIX 权限位、ACL、Capability、SELinux 等，在实验中未实现或未展开。

5. 更完整的 IPC 体系
   - 信号（signal）、共享内存、消息队列、socket 等；本实验仅在挑战题中讨论 pipe 的设计。

6. 多核并发下的可扩展性问题
   - 真实 OS 在 SMP 下需要更严格的锁设计、RCU、无锁数据结构等；实验平台多为单核/简化并发场景。

---

## 总结
Lab8 通过“补全文件系统读写关键路径”与“实现基于文件系统的 exec 装载”把 uCore 的多个子系统串联成一个可运行的最小操作系统：既能挂载文件系统，也能从磁盘读出 ELF 并运行用户程序。  
在实现过程中，最关键的经验是：单个功能点完成并不意味着系统可用，必须从调用链、资源生命周期、地址空间切换与同步互斥等角度做整体一致性检查。最终 `make qemu` 进入 `sh` 且 `make grade` 达到 100/100，说明核心机制实现正确并完成了系统集成目标。
