# SLUB内存分配器算法设计文档

## 概述

为常见的小对象预先准备固定大小的对象池，每次快速分配／释放；  
当对象池耗尽时申请新页并切分；  
当页面空闲回到一个阈值时释放回底层。

## 一、函数

### (1) 综述

- **`slub_init()`**  
  初始化所有 `slub_cache`，设置 `size`、`align`、`objects_per_page`。

- **`slub_get_cache(size)`**  
  将请求大小映射到一个合适的 cache。

- **`slub_alloc_page_internal(cache)`**  
  执行 “新页分配 → 创建 `slub_page` → 构建对象链表” 的流程。

- **`slub_alloc_object(cache)`**  
  从 cache 中取对象。

- **`slub_free_object(cache, ptr)` / `slub_free_page(cache, sp)`**  
  执行释放对象及可能释放页。

- **`slub_init_memmap()` / `slub_alloc_pages()` / `slub_free_pages()`**  
  实现底层页管理。

---

### (2) 具体实现

#### 初始化阶段

**`slub_init`**

- `free_list` 和 `nr_free` 用于底层页管理（PMM 空闲页链表）。  
- 对每个 `slub_cache`（对应不同对象大小，如 8B、16B … 2048B）进行设置：  
  - `cache->size = slub_sizes[i]`：设定该 cache 管理的对象大小。  
  - `cache->objects_per_page = PGSIZE / cache->size`：每页可容纳的对象数。  
- 初始化链表：
  - `partial`（部分使用中的页面）
  - `full`（已满的页面）
- 初始化统计变量：
  - `nr_partial`, `nr_full`, `total_objects`, `used_objects` 均归零。
- 初始化完成后：
  - 每个对象大小对应一个 cache；
  - 当前无已分配页，`partial` / `full` 链表为空。

---

#### PMM 初始化

- **`slub_init_memmap()`**  
  初始化物理页描述符。

- **`slub_alloc_pages()`**  
  查找 `p->property >= n` 的页块，如大于则分割剩余部分。

- **`slub_free_pages()`**  
  释放 `n` 页并插回 `free_list`，可合并相邻空闲块。

---

#### 对象分配流程

- **`slub_alloc(size)`**  
  - 若 `size > SLUB_MAX_SIZE` → 直接页分配（跳过小对象池）。  
  - 否则 → 调用 `slub_get_cache(size)` 获取对应 cache。

- **`slub_get_cache(size)`**  
  查找第一个 `slub_sizes[i] >= size` 的 cache。  
  例如：`size=20B` → 使用 `slub_sizes={8,16,32,…}` 中的 `32B` cache。

- **`slub_alloc_object(cache)`**
  1. 若 `cache->partial` 非空 → 取第一个 `slub_page`。  
  2. 若为空 → 调用 `slub_alloc_page_internal(cache)` 申请新页。  
  3. 从 `sp->freelist` 中取出对象，更新：
     - `sp->freelist`
     - `sp->inuse++`
     - `cache->used_objects++`
  4. 若 `sp->inuse == sp->objects` → 移入 `cache->full` 链表。  
  5. 返回对象地址（并清零内存）。

- **`slub_alloc_page_internal(cache)`**
  1. 从底层页分配器申请 1 页（`slub_alloc_pages(1)`）。
  2. 得到 `struct Page *page`。
  3. 虚拟地址：`page_addr = page2kva(page)`。
  4. 页首放置元数据结构：
     ```c
     struct slub_page *sp = (struct slub_page *)page_addr;
     ```
  5. 初始化：
     ```c
     sp->cache = cache;
     sp->page = page;
     sp->inuse = 0;
     sp->objects = cache->objects_per_page;
     ```
  6. 构建对象链表：
     - 计算对象起始位置：`obj_start = page_addr + sizeof(slub_page)`；
     - 按 `cache->align` 对齐；
     - 每隔 `cache->size` 字节设一个对象；
     - 最后一个对象 `next = NULL`。
  7. 插入 `cache->partial` 链表：
     - `cache->nr_partial++`
     - `cache->total_objects += objects_per_page`

---

#### 对象释放流程

- **`slub_free(ptr)`**
  1. `addr_to_slub_page(ptr)` 找到对应 `slub_page sp`；
  2. 若非 SLUB 管理（`sp->cache == NULL` 或 `sp->cache->size > SLUB_MAX_SIZE`），走页面释放路径；
  3. 否则 → 调用 `slub_free_object()`。

- **`slub_free_object(cache, ptr)`**
  1. `obj = (struct slub_object *)ptr`；
  2. 插入空闲链表：
     ```c
     obj->next = sp->freelist;
     sp->freelist = obj;
     ```
  3. 更新计数：
     - `sp->inuse--`
     - `cache->used_objects--`

- **`slub_free_page(cache, sp)`**
  - 若页从 “满” 变 “非满” → 从 `full` 移到 `partial`；
  - 若页完全空闲（`sp->inuse == 0`）且 `cache->nr_partial > 1`：
    - 调用 `slub_free_page(cache, sp)`：
      - 删除页链表节点；
      - 更新统计；
      - 调用 `slub_free_pages(sp->page, 1)` 将页释放回 PMM。
  - 此策略减少频繁申请/释放带来的性能损耗。

---

## 二、整体流程

### 1. 分配流程：`slub_alloc(size)`
1. 若 `size > SLUB_MAX_SIZE` → 直接页分配。
2. 否则：
   - 获取 cache；
   - 若 cache 有可用页 → 取对象；
   - 否则申请新页；
   - 更新计数；
   - 若页满 → 移入 `full`。

### 2. 释放流程：`slub_free(ptr)`
1. 根据地址找到页；
2. 若为 SLUB 管理：
   - 将对象插入 freelist；
   - 若页由满变部分 → 调整链表；
   - 若页空闲且部分页多于 1 → 释放页回 PMM。
3. 若非 SLUB 管理 → 页级释放。

### 3. 底层页分配器
- **`slub_alloc_pages(n)`**：查找可用空闲块并分割。  
- **`slub_free_pages(base, n)`**：释放并合并相邻空闲块，维护 `free_list`。

---


##三、测试

### 测试一：基本分配释放

1. 调用 `void *p1 = slub_alloc(10);`
   - size = 10 字节。
   - `slub_init` 如果尚未初始化则初始化。
   - 选择适当 cache（假设 cache sizes={8,16,32,…}，第一个 ≥10 是 16）, 即选择 16 字节缓存。
   - 调用 `slub_alloc_object(cache_16)` 分配一个对象。

2. 同理调用  
   `p2 = slub_alloc(20); → size=20 → cache size=32。`

3. 同理调用  
   `p3 = slub_alloc(100); → size=100 → 缓存 size 可能 128 或更大（如 128）。`

4. 三个指针断言非 NULL：  
   `assert(p1!=NULL && p2!=NULL && p3!=NULL);`

5. 断言三者地址互不相等：  
   `assert(p1!=p2 && p2!=p3 && p1!=p3);`  
   以确保分配器没有返回同一地址。

6. 释放这三个对象：  
   `slub_free(p1); slub_free(p2); slub_free(p3);`
   - 对于每个释放：找到其对应 slub_page，更新 freelist、inuse 计数、可能返还页。

### 测试二：大量小对象分配

1.声明 `void *ptrs[100];`。

2. 循环  
`for (int i=0; i<100; i++) { ptrs[i] = slub_alloc(8); assert(ptrs[i]!=NULL); *(int*)ptrs[i] = i; }`  
每次分配 size=8 字节（即最小缓存）100 个对象。  
为每个对象写入数据 i。  

4. 验证循环：  
`for (i=0; i<100; i++) assert(*(int*)ptrs[i] == i);`  
确认数据写入/读出正确。  

5. 释放所有对象：  
`for (i=0; i<100; i++) slub_free(ptrs[i]);`  

---

### 测试三：不同大小的分配

1.分配多个不同大小：  
`void *p8   = slub_alloc(8);`  
`void *p16  = slub_alloc(16);`  
`void *p32  = slub_alloc(32);`  
`void *p64  = slub_alloc(64);`  
`void *p128 = slub_alloc(128);`  
`void *p256 = slub_alloc(256);`  

确认每个非 NULL：`assert(p8 && p16 && p32 && p64 && p128 && p256);`  

2. 写入测试数据：  
`memset(p8,   0x11,   8);`  
`memset(p16,  0x22,  16);`  
`memset(p32,  0x33,  32);`  
`memset(p64,  0x44,  64);`  
`memset(p128, 0x55, 128);`  
`memset(p256, 0x66, 256);`  

3. 验证写入：  
`assert(*(char*)p8   == 0x11);`  
`assert(*(char*)p16  == 0x22);`  
etc…  

4. 释放所有对象:  
`slub_free(p8); slub_free(p16); slub_free(p32); slub_free(p64); slub_free(p128); slub_free(p256);`  

---

### 测试四：分配后重用

1.分配一个对象： `void *q1 = slub_alloc(32);`  
size=32 → 相应 cache。  

2. 保存其地址： `void *q1_addr = q1;`  
3. 释放该对象： `slub_free(q1);`  
4. 再次分配同样大小： `void *q2 = slub_alloc(32);`  
5. 断言新分配对象地址与上次相同： `assert(q1_addr == q2);`  
意味着释放后的对象被立即重用。  
6. 释放它： `slub_free(q2);`  

---

### 测试 5：压力测试  
(由于为简化实现，这里的 STRESS_COUNT 未设太大)

1.定义 `#define STRESS_COUNT 1` 和数组 `void *stress_ptrs[STRESS_COUNT];`  

2. 外循环 `for (round = 0; round < 3; round++) { … }` 重复三轮：  

分配阶段：  
`for (i=0; i<STRESS_COUNT; i++) { size_t size = (i%8 +1)*8; stress_ptrs[i] = slub_alloc(size); assert(stress_ptrs[i]!=NULL); *(int*)stress_ptrs[i] = i; }`  
→ 大量（1000）对象分配，大小按 8、16、24…64 字节循环。  

验证阶段：  
`for (i=0; i<STRESS_COUNT; i++) { assert(*(int*)stress_ptrs[i] == i); }`  
→ 确保所有写入的数据正确。  

释放一半：  
`for (i=0; i<STRESS_COUNT; i+=2) { slub_free(stress_ptrs[i]); stress_ptrs[i] = NULL; }`  
→ 释放偶数索引对象，奇数仍保留。  

重新分配释放掉的那一半：  
`for (i=0; i<STRESS_COUNT; i+=2) { size_t size = (i%8 +1)*8; stress_ptrs[i] = slub_alloc(size); assert(stress_ptrs[i]!=NULL); *(int*)stress_ptrs[i] = i*2; }`  
→ 分配同样大小对象，再写入值 i*2。  

全部释放阶段：  
`for (i=0; i<STRESS_COUNT; i++) { if (stress_ptrs[i]) slub_free(stress_ptrs[i]); }`  
→ 释放所有剩余对象。  
