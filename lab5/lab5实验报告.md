# uCore Lab5（COW）实验报告

作者：conkylin  
实验环境：RISC-V 64（RV64）、QEMU 4.1.1、双重 GDB（riscv64-unknown-elf-gdb + host gdb attach qemu）

---

## 一、实验目标与完成情况概述

本实验围绕“用户态程序执行”和“进程创建”的核心机制展开，主要完成了三件事：

1. 完成 `load_icode` 的关键步骤：为用户程序建立用户地址空间、设置用户栈、初始化 `trapframe`，确保 `sret` 后能从 ELF 的入口地址开始执行。
2. 补全 `copy_range` 并在 `fork` 路径中引入 Copy-on-Write（COW）：父子进程初始共享同一份物理页，写入时通过缺页异常拆分为私有页。
3. 阅读并梳理 uCore 的 `fork/exec/wait/exit` 与系统调用实现，并用双重 GDB 观察 QEMU 对 `ecall/sret` 与访存翻译（TLB + 页表遍历）的模拟流程。

代码层面，本次仓库中与本实验最直接相关的变更集中在：

- `kern/process/proc.c`：`load_icode` 第 6 步补全、`do_execve`/`kernel_execve` 路径、`do_fork`/`copy_thread` 等。
- `kern/mm/vmm.c`：`dup_mmap` 中启用 `copy_range(..., share=1)`，将 fork 的地址空间复制改为 COW 共享。
- `kern/mm/pmm.c`：补全 `copy_range`，实现“复制”与“共享（COW）”两种策略。
- `kern/trap/trap.c` 与 `kern/mm/mmu.h`：引入 `PTE_COW` 并在 store page fault 路径实现 COW 拆页。

---

## 二、练习0：填写已有实验（LAB2/3/4 代码合并与适配）

### 2.1 合并内容与依赖关系

Lab5 依赖 Lab2/3/4 的基础设施，主要包括：

- 物理内存管理（页分配/释放、引用计数、伙伴或 first-fit 等策略）
- 虚拟内存管理（页表建立、`get_pte/page_insert/page_remove`、VMA 管理、缺页处理入口 `do_pgfault`）
- 中断/异常与上下文保存恢复（`__alltraps/__trapret`、`trap_dispatch`、系统调用分发）
- 进程结构与调度框架（`proc_struct`、`proc_run/schedule`、上下文切换 `switch_to`）

为了让 Lab5 的用户程序测试通过，在“复用旧代码”的基础上，必须额外保证：

- 用户态地址空间布局（代码段/数据段/用户栈）正确映射且权限正确；
- trapframe 的关键寄存器（尤其是 `epc/sp/status`）满足从 S 态返回 U 态执行的条件；
- fork 的地址空间复制逻辑在 COW 场景下能正确共享并在写入时拆分；
- 缺页异常路径能区分“真实缺页（尚未映射）”与“COW 写入触发的保护异常”。

### 2.2 与本实验关联最紧密的“旧代码点”

本次仓库中能直接看到的标记主要位于 `kern/process/proc.c` 里 `trapframe` 初始化相关位置，例如：

- `proc->tf` 初始化与 `trapframe` 字段布局（与 Lab4 的 trap/调度衔接强相关）
- 在 `load_icode` 完成后对 `tf` 的设置（决定是否能进入 U 态、是否从正确入口执行）

这部分实际上体现了 Lab2/3/4 与 Lab5 的“接口契约”：Lab2/3/4 提供“页表/异常/调度的通用机制”，Lab5 负责把它们拼成“用户程序可运行”的完整链条。

---

## 三、练习1：加载应用程序并执行（需要编码）

### 3.1 关键实现：`load_icode` 的第 6 步（trapframe 初始化）

`do_execve` 会调用 `load_icode`（`kern/process/proc.c`）把一个“已经在内存中的 ELF 文件”加载到新建的用户地址空间里。这里最关键的是：加载完成后要让该进程未来获得 CPU 时，能通过一次 `sret` 直接进入 U 态执行应用的第一条指令。

本仓库中 `load_icode` 的“第 6 步”实现要点如下（节选自 `kern/process/proc.c`）：

```c
// (6) setup trapframe for user environment
struct trapframe *tf = current->tf;
memset(tf, 0, sizeof(struct trapframe));
tf->gpr.sp = USTACKTOP;       // 用户栈顶
tf->epc = elf->e_entry;       // ELF 入口地址
tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
```

设计思路：

1. `tf->epc = elf->e_entry`：`sret` 返回时，硬件（以及 QEMU 模拟）会把 `sepc`（或等价字段）作为下一条指令地址。uCore 的 trap return 逻辑会把 `tf->epc` 写回 `sepc`，因此这里必须指向用户程序入口。
2. `tf->gpr.sp = USTACKTOP`：用户态需要独立栈。uCore 采用“固定的用户栈顶地址”，并在页表中为用户栈区域映射物理页。
3. `tf->status`：核心是清掉 `SPP`，保证 `sret` 返回到 U 态；并设置 `SPIE`，保证返回用户态后中断使能语义正确（与 RISC-V 特权规范一致）。

从“能否跑起来”的角度看，`epc/sp/status` 是最刚性的三项。一旦设置错，最常见的现象是：

- `sret` 后仍在 S 态或直接触发非法指令/权限错误；
- `epc` 跳到未映射地址导致 instruction page fault；
- `sp` 指向未映射地址导致函数 prologue/store 触发 page fault。

### 3.2 用户态进程从 RUNNING 到执行第一条用户指令的完整经过

下面按时间顺序描述“一个用户态进程从被调度到真正执行用户第一条指令”的路径（以 `exec` 后的用户进程为例）：

1. **内核创建并装载用户程序**
   - 用户态调用 `exec`（本质是一次系统调用，见练习3）。
   - 内核进入 `do_execve`，为当前进程创建/替换 `mm_struct`，调用 `load_icode`：
     - 解析 ELF program header；
     - 为每个 loadable segment 分配物理页并映射到用户虚拟地址；
     - 把段内容从 ELF 拷贝到新分配的物理页；
     - 建立用户栈映射；
     - 设置 trapframe（`sp/epc/status`）。

2. **进程进入可运行队列**
   - `wakeup_proc(proc)` 把进程状态置为 `PROC_RUNNABLE`；
   - 调度器在后续某次时机选择该进程运行。

3. **调度器选择进程并切换上下文**
   - `schedule()` 选择一个 `PROC_RUNNABLE` 的进程；
   - `proc_run(next)`：
     - 更新 `current` 指针；
     - 切换页表（在 RISC-V 上体现为写 `satp`，并 `sfence.vma`）；
     - `switch_to(&prev->context, &next->context)` 完成内核栈/寄存器上下文切换。

4. **从内核返回到用户态**
   - 进程第一次运行时通常从 `forkret`/`trapret` 等路径返回；
   - `__trapret` 会按照 trapframe 的内容恢复通用寄存器，并写 `sstatus/sepc/sscratch` 等 CSR；
   - 执行 `sret`：
     - 特权级从 S -> U（取决于 `SPP`）；
     - PC 跳转到 `sepc`（来自 `tf->epc`）；
     - 用户态第一条指令开始执行（即 ELF 入口处的指令）。

这个链条中，`load_icode` 设置的 trapframe 是“用户第一条指令能否执行”的决定性因素；`schedule/proc_run/__trapret/sret` 是“执行权从内核交付给用户态”的关键机制。

---

## 四、练习2：父进程复制内存空间给子进程（需要编码）

### 4.1 `copy_range` 的实现思路（普通复制 + COW 共享两种策略）

在 uCore 中，`do_fork` 通过 `copy_mm`/`dup_mmap` 复制父进程的用户地址空间。调用链在代码注释中也给得很明确：

`do_fork -> copy_mm -> dup_mmap -> copy_range`

本次仓库在 `dup_mmap` 中选择了 **share=1**，即 fork 时启用 COW（节选 `kern/mm/vmm.c`）：

```c
bool share = 1;
if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
    return -E_NO_MEM;
}
```

因此 `copy_range` 必须同时支持：

- share=0：传统“深拷贝”，把每个页面内容复制到新的物理页并映射进子进程页表；
- share=1：COW 模式“共享映射”，父子指向同一物理页，但撤销写权限并打上 `PTE_COW` 标记。

### 4.2 本仓库 `copy_range` 的关键实现点（结合代码分析）

`copy_range` 位于 `kern/mm/pmm.c`。整体结构是按页遍历 `[start, end)`，对每个有效 PTE 分两类处理：

1. 如果 `share==0`：分配新页，拷贝内容，映射到子页表；
2. 如果 `share==1`：不分配新页，父子共享同一物理页：
   - 增加该物理页引用计数；
   - 取消父页表项写权限，并设置 `PTE_COW`；
   - 子页表项也设置 `PTE_COW` 且不带 `PTE_W`；
   - 使得后续任一方写入时触发 store page fault。

本仓库中对应逻辑（概括）：

- 取父页表项 `ptep = get_pte(from, start, 0)`；
- 若该页存在：
  - 得到 `struct Page *page = pte2page(*ptep)`；
  - `perm = (*ptep) & PTE_USER`（继承用户态权限位）；
  - COW 分支：
    - `page_ref_inc(page)`；
    - `perm = (perm & ~PTE_W) | PTE_COW`；
    - `page_insert(to, page, start, perm)`；
    - 同时修改父页表项：`*ptep = (*ptep & ~PTE_W) | PTE_COW`（并 `sfence_vma`）
  - 非 COW 分支：
    - `alloc_page()`；
    - `memcpy(page2kva(new), page2kva(old), PGSIZE)`；
    - `page_insert(to, newpage, start, perm)`。

这里最容易踩坑的点有三类：

- **权限位一致性**：COW 必须清除 `PTE_W`，否则写不会触发异常，COW 形同虚设。
- **父子一致性**：只改子不改父会导致父进程仍可写共享页，从而破坏“写时复制”的隔离。
- **TLB 刷新**：页表改完后如果不刷 TLB，CPU（或 QEMU）可能继续用旧的 TLB 项，造成“明明改成只读却还能写”的怪现象。本仓库在关键路径中调用 `sfence_vma()` 来避免该问题。

### 4.3 COW 机制的设计与实现（概要 + 详细）

#### 4.3.1 设计目标

- fork 后父子进程对同一虚拟页初始共享同一物理页，读共享；
- 任一方第一次写入该页时：
  - 如果该页仍被多个进程共享，则分配新页并复制内容；
  - 如果该页实际上只剩一个引用（ref==1），可直接恢复写权限而无需复制；
- 写入方获得私有页，其修改对另一方不可见。

#### 4.3.2 关键数据结构与标记位

- 新增 `PTE_COW`（本仓库位于 `kern/mm/mmu.h`）：
  - 它不是 RISC-V 硬件标准位，而是 uCore/QEMU 环境下“软件自定义位”（常用做法：用 PTE 的保留位或软件位）。
  - 语义：该页表项对应页面处于 COW 共享状态，当前映射必须是不可写的。

#### 4.3.3 fork 时的状态变化

以某个用户页为单位，fork 时发生：

- 父：`PTE_W=1`（可写）  ->  `PTE_W=0, PTE_COW=1`（只读共享）
- 子：新建映射指向同一物理页，`PTE_W=0, PTE_COW=1`
- 物理页 refcount：`ref = ref + 1`

#### 4.3.4 写入时的缺页异常处理（核心）

本仓库在 `trap_dispatch` 的 store page fault 分支中处理 COW（见 `kern/trap/trap.c` 的 `pgfault_handler`）：

处理逻辑要点：

1. 触发条件：异常原因为 `CAUSE_STORE_PAGE_FAULT`（写访问引发）；
2. 读出导致异常的虚拟地址 `addr = rcr2()`；
3. 找到当前页表项 `ptep = get_pte(current->mm->pgdir, addr, 0)`；
4. 判断是否为 COW 页：`(*ptep & PTE_COW)`；
5. 若是 COW：
   - 找到对应物理页 `page = pte2page(*ptep)`；
   - 若 `page_ref(page) > 1`：
     - 分配新页 `newpage = alloc_page()`；
     - `memcpy(page2kva(newpage), page2kva(page), PGSIZE)`；
     - 更新 PTE 指向新页，同时加上写权限并清除 COW；
     - `page_ref_dec(page)`（旧页引用数减 1）；
   - 若 `page_ref(page) == 1`：
     - 说明已无共享者，无需复制；
     - 直接在该 PTE 上恢复写权限并清掉 COW 标志；
   - `sfence_vma()` 刷新 TLB，确保新权限立即生效；
   - 返回，表示异常已被处理，指令可重试。

若不是 COW 页，则走常规 `do_pgfault` 分配映射流程（对应“真实缺页”）。

#### 4.3.5 COW 的有限状态机（按“单页”视角）

下面以一个虚拟页为对象给出一个简化 FSM（状态只关心“共享/私有、权限、引用数大概关系”）：

```
[Private-RW]  --fork/share-->  [Shared-RO+COW, ref>=2]
    |                                |
    | (另一方 exit/unmap)            | (write fault)
    v                                v
[Shared-RO+COW, ref==1] ----write----> [Private-RW]
    ^                                |
    | (write fault, ref==1)          | (fork again)
    +--------------------------------+
```

解释：

- `Private-RW`：单进程私有、可写页。
- `Shared-RO+COW`：多个进程共享同一物理页，映射为只读并携带 COW 标记。
- 当 ref==1 时，逻辑上已经“只有一个拥有者”，因此写入不必复制，只需恢复写权限。

### 4.4 测试用例：`user/cowtest.c` 的验证思路

仓库中提供了 `cowtest.c`，核心测试点包括：

- `fork()` 后父子各自写入数组，验证写入互不影响；
- 验证在 COW 下 fork 的开销降低（不需要立即拷贝大量页面）；
- 若实现错误，常见表现是：
  - 父写影响子（说明仍共享同一可写页，未触发 COW）；
  - 子写导致父数据变化；
  - 写入直接触发 panic（COW fault 未被识别并处理）；
  - 频繁 page fault 或死循环（TLB 未刷、PTE 更新错误）。

---

## 五、练习3：阅读分析 fork/exec/wait/exit 与系统调用实现（不需要编码）

### 5.1 用户态与内核态如何交错执行：系统调用的基本骨架

用户态系统调用入口在 `user/libs/syscall.c`，其核心就是把参数装入约定寄存器并执行 `ecall`：

```c
asm volatile (
    "ld a0, 8(sp)\n"
    ...
    "ecall\n"
    ...
);
```

执行流的交错关系可以概括为：

1. 用户态：准备参数 -> `ecall`
2. 硬件/模拟器：陷入 S 态 trap entry（PC 跳到 `stvec` 指向的入口）
3. 内核态：`__alltraps` 保存现场 -> `trap` -> `trap_dispatch`
4. 内核态：识别 system call -> `syscall()` -> `sys_*` -> `do_*`
5. 内核态：把返回值写回 trapframe 的 `a0`
6. 内核态：`__trapret` 恢复现场 -> `sret`
7. 用户态：回到 `ecall` 下一条指令继续执行

用户态完成的是“参数准备 + 发起陷入”，内核态完成的是“特权操作 + 状态管理 + 返回值写回”。

### 5.2 fork / exec / wait / exit 的执行流程分析

下面按四个系统调用逐个梳理“关键路径 + 用户态/内核态分工”。

#### 5.2.1 fork

用户态：
- 调用 `fork()`（库函数），最终会进入 `syscall(SYS_fork, ...)` 并执行 `ecall`。

内核态：
- `syscall()` 中根据 `tf->gpr.a0` 的 syscall number 分发；
- `sys_fork()` 调用 `do_fork(clone_flags, stack, tf)`；
- `do_fork` 的关键动作：
  1. `alloc_proc()` 分配并初始化子进程控制块；
  2. `copy_mm(clone_flags, proc)`：复制/共享父地址空间（本实验走 COW，共享+只读）；
  3. `copy_thread(proc, stack, tf)`：复制 trapframe 作为子进程“将来返回用户态”的依据；
  4. 建立父子关系，插入进程表；
  5. `wakeup_proc(proc)` 让子进程进入 `PROC_RUNNABLE`；
  6. 返回子进程 pid 给父进程。

返回到用户态：
- 父进程：`fork()` 返回子 pid；
- 子进程：通过 `copy_thread` 构造的 trapframe，使得其从 `__trapret/sret` 回到用户态后 `a0=0`，符合 fork 语义。

交错点：
- fork 的“分叉”不是用户态创建子进程，而是内核态创建；
- 用户态只是提出请求并在返回后观察到两个执行流。

#### 5.2.2 exec

用户态：
- 调用 `execve`（或实验封装），同样走 `ecall` 进入内核。

内核态：
- `sys_exec()` -> `do_execve(name, len, binary, size)`；
- `do_execve` 的关键动作：
  1. 校验用户传入的程序名/ELF 指针是否合法；
  2. 释放旧地址空间（必要时）；
  3. 调用 `load_icode` 建立新地址空间并加载 ELF；
  4. 设置 trapframe（练习1重点）。

返回用户态：
- exec 成功后，实际上不会回到旧程序继续执行，而是“从新 ELF 的入口开始”；
- 表象上看：用户态 `exec` 调用成功后，后续执行的是新程序逻辑。

交错点：
- exec 的本质是“替换当前进程的用户态上下文”，不是创建新进程；
- 用户态只触发一次系统调用，后续代码段完全变更。

#### 5.2.3 wait

用户态：
- 调用 `wait(pid, &status)` 进入内核。

内核态（`do_wait`）：
- 主要做两件事：查找可回收的僵尸子进程；若没有则睡眠等待。
- 若存在 `PROC_ZOMBIE` 子进程：
  - 回收其内核栈、mm、proc_struct 等资源；
  - 把退出码写回用户提供的地址（需检查用户内存合法性）；
  - 返回回收的 pid。
- 若不存在：
  - 当前进程设置为 `PROC_SLEEPING`，并挂到 `wait_state`；
  - 调度器切走，直到某个子进程 `exit` 时唤醒父进程。

返回用户态：
- wait 返回值/退出码通过 trapframe 写回给用户态。

交错点：
- wait 典型体现“用户态发起阻塞请求，内核态挂起进程，调度器切换”的交错执行。

#### 5.2.4 exit

用户态：
- 调用 `exit(code)` 触发系统调用。

内核态（`do_exit`）：
- 设置 `current->exit_code`；
- 释放用户地址空间：`exit_mmap/put_pgdir/mm_destroy`；
- 把进程状态置为 `PROC_ZOMBIE`；
- 唤醒等待自己的父进程（如果父在 wait）；
- 调用 `schedule()` 让出 CPU，当前进程不再返回用户态。

交错点：
- exit 的“结束”由内核完成（释放资源、状态转换），用户态不会再继续。

### 5.3 用户态进程生命周期图（字符图）

结合 `proc.h` 的状态定义与本实验涉及路径，给出一个简化状态机（只画常见路径）：

```
           (alloc_proc / do_fork)
                 |
                 v
            [UNINIT]
                 |
                 | (wakeup_proc)
                 v
            [RUNNABLE]  <----------------------+
                 |                              |
                 | (schedule/proc_run)          | (wakeup from wait/IO)
                 v                              |
            [RUNNING]                           |
              |   |                             |
              |   +--> (sleep_on/do_wait) --> [SLEEPING]
              |
              +--> (do_exit) ----------------> [ZOMBIE]
                                                   |
                                                   | (parent do_wait recycle)
                                                   v
                                                [freed]
```

事件/函数对应关系：

- `UNINIT -> RUNNABLE`：`wakeup_proc`
- `RUNNABLE -> RUNNING`：`schedule` 选择 + `proc_run`
- `RUNNING -> SLEEPING`：`do_wait` 等阻塞路径调用 `sleep_on`
- `SLEEPING -> RUNNABLE`：事件满足后 `wakeup_proc`
- `RUNNING -> ZOMBIE`：`do_exit`
- `ZOMBIE -> freed`：父进程 `do_wait` 回收资源

---

## 六、扩展练习 Challenge：实现 Copy-on-Write（COW）

### 6.1 实现源码位置与整体结构

本仓库的 COW 实现是一套“fork 时共享 + 写时拆分”的完整链条，主要由三部分组成：

1. **fork 阶段共享映射**
   - `kern/mm/vmm.c: dup_mmap`：调用 `copy_range(..., share=1)`；
   - `kern/mm/pmm.c: copy_range`：共享物理页、撤销写权限、标记 `PTE_COW`。

2. **写入触发异常**
   - `PTE_W=0` 导致写访问触发 store page fault；
   - trap 分发时识别 `CAUSE_STORE_PAGE_FAULT`。

3. **异常处理拆分**
   - `kern/trap/trap.c: pgfault_handler`：若 PTE 带 `PTE_COW`，执行“复制或恢复写权限”逻辑，并刷新 TLB。

### 6.2 COW 相关状态转换说明（更细颗粒度）

以“某进程对某虚拟页的映射”为对象，COW 下涉及的状态组合可用下面的表描述：

- 映射属性：`(W?, COW?)`
- 物理页属性：`refcount`

典型状态：

1. `W=1, COW=0, ref=1`：私有可写页（正常运行态）
2. `W=0, COW=1, ref>=2`：共享只读 COW 页（fork 后）
3. `W=0, COW=1, ref=1`：逻辑上已不共享，但仍保留 COW 标记（可优化为直接恢复写）
4. `W=1, COW=0, ref=1`：写 fault 后拆分出的私有可写页（新页或旧页恢复）

触发事件与动作：

- `fork`：状态 1 -> 状态 2（父子都变成状态 2）
- `write fault`：
  - 若 `ref>1`：分配新页并复制，写入方变为状态 4，另一方保持状态 2，旧页 ref--；
  - 若 `ref==1`：直接恢复 `W` 并清 `COW`，变为状态 4（无需复制）
- `exit/unmap`：ref--，可能导致另一方从 ref>1 变为 ref==1；下一次写可走“直接恢复写”分支。

### 6.3 Dirty COW（参考 dirtycow.ninja）的可模拟点与修复思路（结合本实验）

Dirty COW（Linux CVE-2016-5195）的本质是：在“写时复制”语义下，通过竞态或内核路径漏洞，让只读共享页被“绕过”并写入到共享底层（通常涉及页缓存、`mmap`、`/proc/self/mem`、race 等）。

在 uCore 的教学环境中，功能范围比 Linux 小很多（没有完整页缓存、复杂的 `mmap`/文件系统页共享路径），因此很难 1:1 复现 Dirty COW 的攻击链。但从“机制漏洞”的角度，本实验中确实存在可类比的两个风险点：

1. **忘记撤销父/子的写权限或忘记刷新 TLB**
   - 后果：写不会触发 page fault，COW 拆分逻辑不会执行，导致共享页被直接写穿。
   - 修复：fork 时父子都必须清 `PTE_W` 并设置 `PTE_COW`；更新 PTE 后必须 `sfence.vma`。

2. **拆页过程缺少并发保护（竞态条件）**
   - 若存在多核或可抢占并发，两个线程/进程可能同时对同一 COW 页触发 fault：
     - 可能出现重复复制、refcount 错误、PTE 更新覆盖等问题；
   - 修复：在 page fault 处理时对 mm/页表加锁，保证“检查 refcount -> 分配/复制 -> 更新 PTE -> 刷新 TLB”是原子序列。
   - 本实验环境单核为主，但该点在更真实 OS 中是必须考虑的。

结论：即便不复现 Dirty COW 的完整攻击路径，本实验仍能从中总结“COW 的正确性依赖权限位 + TLB 刷新 + 并发原子性”三条底线。

### 6.4 用户程序何时被预先加载到内存？与常用 OS 的区别与原因

在本实验中，用户程序并不是从磁盘文件系统按需加载，而是**在构建内核时就被链接进内核镜像**。证据可以在 `kern/process/proc.c: kernel_execve` 中看到：

```c
const char *argv[] = {"cowtest", "10", 0};
const uint8_t *binary = &_binary_obj___user_cowtest_out_start;
size_t size = _binary_obj___user_cowtest_out_size;
return do_execve("cowtest", 8, binary, size);
```

这说明：

- `obj/__user_*.out` 在编译阶段被作为二进制段嵌入到内核；
- 运行时内核直接拿到 `binary` 指针与 `size`，交给 `do_execve/load_icode` 解析 ELF。

与常用 OS（如 Linux）的对比：

- Linux：程序在磁盘文件系统中，`execve` 触发 VFS 打开文件、读 ELF 头与段，按需分页（demand paging）加载到内存；
- uCore Lab：没有完整文件系统/页缓存/按需加载机制，为了聚焦“进程与虚拟内存”，把程序静态打包进内核，减少 I/O 与 FS 复杂度。

原因：教学实验强调“机制主线”，用 link-in-kernel 方式把环境复杂度压低，让同学把精力放在 `exec/fork/COW/trap` 的核心链条上。

---

## 七、双重 GDB 调试附录：QEMU 如何处理访存翻译与 ecall/sret（实验要求补充部分）

说明：本部分是“练习外的调试实验”，用于理解 QEMU 4.1.1 的实现路径。它不是 Lab5 评分点，但能帮助把“OS 机制”与“模拟器实现”连起来。

### 7.1 访存指令的虚拟地址如何在 QEMU 中被翻译为物理地址（TLB + 页表遍历）

#### 7.1.1 关键调用路径（结合回溯）

在 host gdb attach 到 qemu 后，对一次写访存命中断点的 backtrace 可见典型链路：

`code_gen_buffer(翻译后 TB 执行) -> helper_ret_stb_mmu -> store_helper -> tlb_fill -> riscv_cpu_tlb_fill -> get_physical_address`

其中：

- `accel/tcg/cputlb.c: store_helper`：TCG 生成代码的通用访存 helper（带 TLB 快速路径）；
- `tlb_fill`：TLB miss 时调用架构相关的 `cpu_tlb_fill`；
- `target/riscv/cpu_helper.c: riscv_cpu_tlb_fill`：RISC-V 侧的 TLB refill；
- `get_physical_address`：真正执行“虚拟地址 -> 物理地址”的逻辑，包含 BARE/SV39 等分支与页表遍历。

#### 7.1.2 QEMU 的“先查 TLB，miss 再走页表”的代码位置

在 `accel/tcg/cputlb.c`，`store_helper` 里先执行：

```c
if (!tlb_hit(tlb_addr, addr)) {
    if (!victim_tlb_hit(...)) {
        tlb_fill(cpu, addr, ...);
        index = tlb_index(...);
        entry = tlb_entry(...);
    }
    tlb_addr = tlb_addr_write(entry) & ~TLB_INVALID_MASK;
}
haddr = (void *)((uintptr_t)addr + entry->addend);
stb_p(haddr, val);
```

理解要点：

- `tlb_hit`：检查当前页是否已有翻译缓存；
- `victim_tlb_hit`：类似“小型受害者缓存”，减少冲突 miss；
- `tlb_fill`：miss 时调用架构函数去“按规范走一遍翻译”，然后把结果塞回 QEMU 的软件 TLB；
- `entry->addend`：QEMU TLB 的关键字段之一，它缓存的是“guest 虚拟地址到 host 地址指针”的偏移量，从而在 fast path 里直接 `addr + addend` 得到 host 地址并访问。

#### 7.1.3 BARE（MODE=0）与 SV39（MODE=8）的核心行为差异

在 `target/riscv/cpu_helper.c: get_physical_address` 中可以观察到：

- **BARE（satp.MODE=0）**：直接走到“无需翻译”的分支：

```c
if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
    *physical = addr;
    *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
    return TRANSLATE_SUCCESS;
}
```

这对应“VA≈PA”的语义：QEMU 仍会用自己的 TLB 加速，但功能上等价于“地址不变”。

- **SV39（satp.MODE=8）**：进入 `levels=3` 的页表遍历循环：

```c
levels = 3; ptidxbits = 9; ptesize = 8;
...
for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
    idx = (addr >> (PGSHIFT + ptshift)) & ((1<<ptidxbits)-1);
    pte_addr = base + idx * ptesize;
    pte = ldq_phys(cs->as, pte_addr);
    ...
    if (!(pte & PTE_V)) { fault }
    else if (!(pte & (PTE_R|PTE_W|PTE_X))) { base = ppn<<PGSHIFT; continue; }
    else { leaf: 计算 physical，设置权限，返回成功 }
}
```

这正是“三级页表按 VPN[2:0] 查 PTE”的实现。调试时能看到类似把高半区内核 VA（如 `0xffffffffc02xxxxx`）翻译到物理地址（如 `0x802xxxxx`）的现象，并在翻译后回填 QEMU TLB。

#### 7.1.4 这三个循环/判断到底在做什么（把页表遍历拆开讲清楚）

以 SV39 为例：

1. **确定页表根**
   - `base = SATP.PPN << 12`：根页表物理地址（PPN 是物理页号）

2. **逐级索引（3 次）**
   - `ptshift` 初始为 `18`（因为 3 级，每级 9 bit：第一级对应 VPN[2]，次级 VPN[1]，末级 VPN[0]）
   - 每轮计算：
     - `idx = (addr >> (12 + ptshift)) & 0x1ff`
     - `pte_addr = base + idx * 8`
     - `pte = ldq_phys(..., pte_addr)`：从“当前页表页”里读取对应的 PTE（这一步就是“从当前页表取出页表项”）

3. **判断 PTE 类型**
   - `PTE_V==0`：无效映射，触发缺页
   - `R/W/X 都为 0`：非叶子 PTE（指向下一级页表），更新 `base = ppn << 12` 继续下一轮
   - `存在 R/W/X`：叶子 PTE（实际映射），计算最终物理地址并返回

4. **叶子 PTE 如何算物理地址**
   - `ppn = pte >> PTE_PPN_SHIFT`
   - `vpn = addr >> 12`
   - 最终物理页号：`ppn | (vpn & ((1<<ptshift)-1))`
     - 这一句是为了支持 superpage（大页）情形：如果在上层就遇到叶子映射，则低位 VPN 的一部分需要拼进最终 PPN。
   - 最终物理地址：`physical = (...) << 12`

---

### 7.2 ecall/sret 在 QEMU 中的处理（含 TCG Translation）

#### 7.2.1 ecall：从“指令翻译”到“异常处理”

在 QEMU 源码 `target/riscv/insn_trans/trans_privileged.inc.c`：

```c
static bool trans_ecall(DisasContext *ctx, arg_ecall *a) {
    generate_exception(ctx, RISCV_EXCP_U_ECALL);
    exit_tb(ctx);
    ctx->base.is_jmp = DISAS_NORETURN;
    return true;
}
```

调试观察到的要点：

- `trans_ecall` 发生在 **TCG 翻译阶段**：QEMU 把 guest 的 `ecall` 翻译成“抛出异常”的中间表示；
- 运行时该异常会通过 `riscv_raise_exception` 写入 `cs->exception_index`，并 `cpu_loop_exit_restore` 跳出 TB 执行回到主循环；
- 主循环随后进入 `riscv_cpu_do_interrupt`，按 RISC-V 规范更新 `scause/sepc/stvec/priv` 等，最终把 PC 设置为 trap 入口地址。

在 `target/riscv/cpu_helper.c: riscv_cpu_do_interrupt` 中可见关键分支：

- 将 `RISCV_EXCP_U_ECALL` 映射为与当前特权级相关的 cause；
- 判断是否委托到 S 态（`deleg` 判断）；
- 写 `sepc/scause` 并跳到 `stvec`；
- 调用 `riscv_cpu_set_mode(env, PRV_S)` 完成特权级切换。

#### 7.2.2 sret：从“翻译生成 helper”到“恢复特权级并返回 sepc”

在 `trans_sret` 中，QEMU 翻译阶段生成对 helper 的调用：

```c
tcg_gen_movi_tl(cpu_pc, ctx->base.pc_next);
gen_helper_sret(cpu_pc, cpu_env, cpu_pc);
exit_tb(ctx);
ctx->base.is_jmp = DISAS_NORETURN;
```

运行时进入 `target/riscv/op_helper.c: helper_sret`：

- 检查当前特权级是否允许执行 sret；
- `retpc = env->sepc` 作为返回地址；
- 按规范更新 `mstatus` 的 `SPP/SPIE/SIE` 等位；
- `riscv_cpu_set_mode(env, prev_priv)` 切回上一特权级（通常是 U）；
- 返回 `retpc` 使 TB 后续从用户态入口继续执行。

#### 7.2.3 TCG Translation 功能与两次实验的关系

- 在 `ecall/sret` 实验中，断点落在 `trans_ecall/trans_sret`，直接证明 QEMU 先把 guest 指令翻译成 TCG 中间代码，再生成 host 机器码 TB 执行。
- 在“地址翻译（TLB/page walk）”实验中，访存 helper（如 `store_helper`）同样是 TCG 生成代码的运行时支撑：TB 中遇到无法直连的访存，会调用这些 helper 走软件 TLB 与页表遍历。
- 因此，两次双重 GDB 实验都与 TCG Translation 强相关：一个观测特权指令（陷入/返回），一个观测访存翻译（TLB miss/refill）。

---

## 八、调试过程截图展示

![](lab5_1.png)
![](lab5_2.png)
![](lab5_3.png)
![](lab5_4.png)
![](lab5_5.png)
![](lab5_6.png)
![](lab5_7.png)
![](lab5_8.png)
![](lab5_9.png)
![](lab5_10.png)
![](lab5_11.png)
![](lab5_12.png)
![](lab5_13.png)
![](lab5_14.png)
![](lab5_15.png)

---
## 九、调试过程中的“抓马细节”与收获

1. **用户程序符号表默认不加载**
   - 直接对 `user/libs/syscall.c` 打断点会提示找不到源文件；
   - 解决：在 riscv gdb 中手动 `add-symbol-file obj/__user_exit.out`（或对应程序）加载符号表，才能在用户态库函数处断点/单步。

2. **“同一条指令”在 uCore 与 QEMU 两个世界里要配合观察**
   - 在 uCore gdb 里把 PC 单步到 `ecall` 前；
   - 在 qemu gdb 里提前下断点（如 `trans_ecall`/`riscv_cpu_do_interrupt`）；
   - uCore 执行 `ecall` 的那一刻，qemu 侧会命中断点，从而能把“软件触发”与“模拟器内部实现”对齐。

3. **TLB 的“存在感”比想象更强**
   - 真实 CPU：开启虚拟内存后先查硬件 TLB，miss 再走页表；
   - QEMU：即使 BARE 模式也会走自己的软件 TLB（这是加速结构而非硬件建模），因此看到 `store_helper -> tlb_fill` 并不意味着“硬件真的有同样行为”，而是 QEMU 的实现选择。

---

## 十、本实验重要知识点与 OS 原理对应关系（含理解）

| 实验知识点 | OS 原理知识点 | 我的理解（含关系/差异） |
|---|---|---|
| `load_icode` 建立用户地址空间 | `exec` 语义、ELF 装载、地址空间重建 | uCore 把程序预嵌入内核，省去 FS/I/O；但仍完整体现“按段映射 + 初始化用户栈 + 入口跳转”的 exec 主线。 |
| `trapframe` + `sret` 进入用户态 | 特权级切换、陷入/返回机制 | trapframe 是“软件保存的硬件上下文”；`sret` 根据 CSR 与 trapframe 恢复并切回 U 态，是用户态执行的最后一跳。 |
| `fork` 复制地址空间 | 进程创建、地址空间复制、资源继承 | 传统 fork 是深拷贝，开销大；COW 用“只读共享 + 写时拆分”把开销推迟到真正写入发生时。 |
| `PTE_COW` + store page fault 拆页 | COW、页表权限、缺页异常 | COW 依赖“撤销写权限”来让写入触发异常；异常处理里才做复制与 PTE 更新。 |
| QEMU `cputlb.c` 软件 TLB | TLB 缓存思想 | QEMU 的 TLB 是软件缓存，用于加速翻译后的 host 访问；它关注功能正确与性能，而不等价于硬件微结构实现。 |
| QEMU TCG 翻译与 TB 执行 | 动态二进制翻译（DBT） | guest 指令先翻译成 TCG IR，再生成 host code；特权指令/访存常通过 helper 与异常机制实现语义。 |

---

## 十一、OS 原理中重要但本实验未覆盖或覆盖较弱的知识点

1. 文件系统与 VFS：真实 OS 的 exec 依赖 VFS、inode、页缓存、demand paging，本实验被 link-in-kernel 简化。
2. 多核与并发：COW 在多核下必须考虑 page fault 并发、TLB shootdown、锁粒度等，本实验环境大多单核且弱并发。
3. IPC 与同步：管道、消息队列、共享内存、信号等未展开。
4. 安全机制：权限模型、隔离、capability、用户/内核内存访问审计等未深入。
5. 更完整的虚拟内存子系统：swap、页面置换算法、匿名页/文件页统一管理等在本实验中没有主线体现。

---

## 十二、实验中通过大模型解决的问题与交互记录（场景化总结）

1. **问题：为什么 user 目录的源码断点打不上？**
   - 现象：gdb 报 “No source file named user/libs/syscall.c”。
   - 思路：怀疑只加载了内核符号表。
   - 与大模型交互：询问“用户程序如何被加载、符号表如何让 gdb 识别”。
   - 结论与操作：使用 `add-symbol-file obj/__user_exit.out` 手动加载用户 ELF 符号表后，再对 `user/libs/syscall.c` 下断点即可命中。

2. **问题：QEMU 源码里 ecall/sret 在哪里处理？**
   - 目标：在 qemu 侧找到处理 `ecall` 的关键函数并打断点。
   - 与大模型交互：询问“riscv 的 ecall/sret 在 qemu 翻译与执行阶段分别对应哪些函数”。
   - 落地：使用 `info functions ecall/sret` 找到 `trans_ecall/trans_sret`，并进一步跟到 `riscv_raise_exception/riscv_cpu_do_interrupt/helper_sret`。

3. **问题：SV39 的 3 级循环到底在做什么？**
   - 现象：`get_physical_address` 中 `for (i=0; i<levels; i++)` 看起来很抽象。
   - 思路：需要把 idx/pte_addr/ldq_phys 与“查页表项”对应起来。
   - 与大模型交互：反复追问“哪一行在取 PTE、为什么 base 会更新、leaf/non-leaf 的判定条件是什么”。
   - 结论：每轮从“当前页表页”按 VPN 索引读取 PTE；非叶子则把 `base` 更新为下一级页表；叶子则拼出最终 PA 并返回。
