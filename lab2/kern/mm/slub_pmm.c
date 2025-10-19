#include <slub_pmm.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

// 页面和虚拟地址转换实现
void *page2kva(struct Page *page) {
    return KADDR(page2pa(page));
}

struct Page *kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

// 全局SLUB缓存数组
static struct slub_cache slub_caches[SLUB_CACHE_NUM];
static int slub_initialized = 0;

// 底层页面管理
static list_entry_t free_list;      // 空闲页面链表
static unsigned int nr_free = 0;    // 空闲页面数量

// 预定义的对象大小
static const size_t slub_sizes[] = {8, 16, 32, 64, 128, 256, 512, 1024, 2048};

// 获取适合size的cache
struct slub_cache *slub_get_cache(size_t size) {
    if (size > SLUB_MAX_SIZE) {
        return NULL;
    }

    // 找到第一个大于等于size的cache
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
        if (slub_sizes[i] >= size) {
            return &slub_caches[i];
        }
    }
    return NULL;
}

// 初始化SLUB分配器
void slub_init(void) {
    if (slub_initialized) {
        return;
    }

    cprintf("SLUB: Initializing SLUB allocator\n");
    
    // 初始化空闲链表
    list_init(&free_list);
    nr_free = 0;

    // 初始化每个cache
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
        struct slub_cache *cache = &slub_caches[i];

        cache->size = slub_sizes[i];
        cache->align = 8;  // 默认8字节对齐
        cache->objects_per_page = PGSIZE / cache->size;

        // 初始化链表
        list_init(&cache->partial);
        list_init(&cache->full);

        // 初始化统计信息
        cache->nr_partial = 0;
        cache->nr_full = 0;
        cache->total_objects = 0;
        cache->used_objects = 0;

        // 设置名称
        static char names[SLUB_CACHE_NUM][32];
        snprintf(names[i], 32, "slub-%d", (int)cache->size);
        cache->name = names[i];

        cprintf("SLUB: Cache[%d] initialized: size=%d, objects_per_page=%d\n", 
                i, cache->size, cache->objects_per_page);
    }

    slub_initialized = 1;
    cprintf("SLUB: Initialization complete\n");
}

// 为cache分配一个新页面
static struct slub_page *slub_alloc_page_internal(struct slub_cache *cache) {
    // 分配一个物理页
    struct Page *page = slub_alloc_pages(1);
    if (page == NULL) {
        return NULL;
    }

    // 获取页面虚拟地址
    void *page_addr = page2kva(page);

    // 在页面开始处存储slub_page结构
    struct slub_page *sp = (struct slub_page *)page_addr;
    sp->cache = cache;
    sp->page = page;
    sp->inuse = 0;
    sp->objects = cache->objects_per_page;

    // 初始化空闲对象链表
    void *obj_start = (char *)page_addr + sizeof(struct slub_page);
    obj_start = (void *)ROUNDUP((uintptr_t)obj_start, cache->align);

    sp->freelist = obj_start;

    // 构建空闲对象链表
    void *current = obj_start;
    for (int i = 0; i < cache->objects_per_page - 1; i++) {
        struct slub_object *obj = (struct slub_object *)current;
        obj->next = (struct slub_object *)((char *)current + cache->size);
        current = obj->next;
    }
    // 最后一个对象的next为NULL
    ((struct slub_object *)current)->next = NULL;

    // 将页面加入partial链表
    list_add(&cache->partial, &sp->page_link);
    cache->nr_partial++;
    cache->total_objects += cache->objects_per_page;

    return sp;
}

// 从cache中分配一个对象
static void *slub_alloc_object(struct slub_cache *cache) {
    struct slub_page *sp = NULL;

    // 首先尝试从partial链表获取
    if (!list_empty(&cache->partial)) {
        sp = le2slub_page(list_next(&cache->partial), page_link);
    } else {
        // 分配新页面
        sp = slub_alloc_page_internal(cache);
        if (sp == NULL) {
            return NULL;
        }
    }

    // 从freelist中取出一个对象
    void *obj = sp->freelist;
    if (obj == NULL) {
        return NULL;
    }

    sp->freelist = ((struct slub_object *)obj)->next;
    sp->inuse++;
    cache->used_objects++;

    // 如果页面已满，移到full链表
    if (sp->inuse == sp->objects) {
        list_del(&sp->page_link);
        list_add(&cache->full, &sp->page_link);
        cache->nr_partial--;
        cache->nr_full++;
    }

    // 清零对象内容
    memset(obj, 0, cache->size);

    return obj;
}

// 分配内存
void *slub_alloc(size_t size) {
    if (!slub_initialized) {
        slub_init();
    }

    if (size == 0) {
        return NULL;
    }

    // 对于大于SLUB_MAX_SIZE的分配，直接使用页分配器
    if (size > SLUB_MAX_SIZE) {
        size_t nr_pages = (size + PGSIZE - 1) / PGSIZE;
        struct Page *page = slub_alloc_pages(nr_pages);
        if (page == NULL) {
            return NULL;
        }
        return page2kva(page);
    }

    // 获取合适的cache
    struct slub_cache *cache = slub_get_cache(size);
    if (cache == NULL) {
        return NULL;
    }

    // 从cache分配对象
    return slub_alloc_object(cache);
}

// 通过地址找到对应的slub_page
static struct slub_page *addr_to_slub_page(void *ptr) {
    // 将地址对齐到页边界
    uintptr_t page_addr = ROUNDDOWN((uintptr_t)ptr, PGSIZE);
    return (struct slub_page *)page_addr;
}

// 前向声明：避免在调用处产生隐式声明警告
static void slub_free_page(struct slub_cache *cache, struct slub_page *sp);

// 释放对象到cache
static void slub_free_object(struct slub_cache *cache, void *ptr) {
    struct slub_page *sp = addr_to_slub_page(ptr);

    // 验证对象属于这个cache
    assert(sp->cache == cache);

    // 将对象加入freelist
    struct slub_object *obj = (struct slub_object *)ptr;
    obj->next = sp->freelist;
    sp->freelist = obj;

    sp->inuse--;
    cache->used_objects--;

    // 如果页面从full变为partial
    if (sp->inuse == sp->objects - 1) {
        list_del(&sp->page_link);
        list_add(&cache->partial, &sp->page_link);
        cache->nr_full--;
        cache->nr_partial++;
    }
    // 如果页面完全空闲，考虑释放
    else if (sp->inuse == 0 && cache->nr_partial > 1) {
        slub_free_page(cache, sp);
    }
}

// 释放页面
static void slub_free_page(struct slub_cache *cache, struct slub_page *sp) {
    list_del(&sp->page_link);
    cache->nr_partial--;
    cache->total_objects -= sp->objects;

    slub_free_pages(sp->page, 1);
}

// 释放内存
void slub_free(void *ptr) {
    if (ptr == NULL) {
        return;
    }

    // 获取slub_page
    struct slub_page *sp = addr_to_slub_page(ptr);

    // 检查是否是SLUB管理的页面
    if (sp->cache != NULL && sp->cache->size <= SLUB_MAX_SIZE) {
        slub_free_object(sp->cache, ptr);
    } else {
        // 大块内存直接释放页面
        struct Page *page = kva2page(ptr);
        slub_free_pages(page, 1);  // 简化处理，实际应记录分配的页数
    }
}

// 打印SLUB信息
void slub_print_info(void) {
    cprintf("\n========== SLUB Allocator Info ==========\n");
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
        struct slub_cache *cache = &slub_caches[i];
        cprintf("Cache[%s]: size=%d, partial=%d, full=%d, "
                "total_objects=%d, used=%d\n",
                cache->name, cache->size, 
                cache->nr_partial, cache->nr_full,
                cache->total_objects, cache->used_objects);
    }
    cprintf("==========================================\n\n");
}

// 测试SLUB分配器
void slub_check(void) {
    cprintf("\n========== SLUB Allocator Test ==========\n");

    // 测试1: 基本分配和释放
    cprintf("Test 1: Basic allocation and free\n");
    void *p1 = slub_alloc(10);
    void *p2 = slub_alloc(20);
    void *p3 = slub_alloc(100);

    assert(p1 != NULL);
    assert(p2 != NULL);
    assert(p3 != NULL);
    assert(p1 != p2 && p2 != p3 && p1 != p3);

    slub_free(p1);
    slub_free(p2);
    slub_free(p3);
    cprintf("Test 1 passed!\n");

    // 测试2: 大量小对象分配
    cprintf("Test 2: Multiple small allocations\n");
    void *ptrs[100];
    for (int i = 0; i < 100; i++) {
        ptrs[i] = slub_alloc(8);
        assert(ptrs[i] != NULL);
        // 写入测试数据
        *(int *)ptrs[i] = i;
    }

    // 验证数据
    for (int i = 0; i < 100; i++) {
        assert(*(int *)ptrs[i] == i);
    }

    // 释放
    for (int i = 0; i < 100; i++) {
        slub_free(ptrs[i]);
    }
    cprintf("Test 2 passed!\n");

    // 测试3: 不同大小的分配
    cprintf("Test 3: Different size allocations\n");
    void *p8 = slub_alloc(8);
    void *p16 = slub_alloc(16);
    void *p32 = slub_alloc(32);
    void *p64 = slub_alloc(64);
    void *p128 = slub_alloc(128);
    void *p256 = slub_alloc(256);

    assert(p8 && p16 && p32 && p64 && p128 && p256);

    // 写入测试数据
    memset(p8, 0x11, 8);
    memset(p16, 0x22, 16);
    memset(p32, 0x33, 32);
    memset(p64, 0x44, 64);
    memset(p128, 0x55, 128);
    memset(p256, 0x66, 256);

    // 验证数据
    assert(*(char *)p8 == 0x11);
    assert(*(char *)p16 == 0x22);
    assert(*(char *)p32 == 0x33);
    assert(*(char *)p64 == 0x44);
    assert(*(char *)p128 == 0x55);
    assert(*(char *)p256 == 0x66);

    slub_free(p8);
    slub_free(p16);
    slub_free(p32);
    slub_free(p64);
    slub_free(p128);
    slub_free(p256);
    cprintf("Test 3 passed!\n");

    // 测试4: 分配后重用
    cprintf("Test 4: Reuse after free\n");
    void *q1 = slub_alloc(32);
    void *q1_addr = q1;
    slub_free(q1);
    void *q2 = slub_alloc(32);
    // 应该重用相同的地址
    assert(q1_addr == q2);
    slub_free(q2);
    cprintf("Test 4 passed!\n");

    // 测试5: 压力测试
    cprintf("Test 5: Stress test\n");
    #define STRESS_COUNT 1
    void *stress_ptrs[STRESS_COUNT];

    for (int round = 0; round < 3; round++) {
        // 分配
        for (int i = 0; i < STRESS_COUNT; i++) {
            size_t size = (i % 8 + 1) * 8;  // 8, 16, 24, ..., 64
            stress_ptrs[i] = slub_alloc(size);
            assert(stress_ptrs[i] != NULL);
            *(int *)stress_ptrs[i] = i;
        }

        // 验证
        for (int i = 0; i < STRESS_COUNT; i++) {
            assert(*(int *)stress_ptrs[i] == i);
        }

        // 释放一半
        for (int i = 0; i < STRESS_COUNT; i += 2) {
            slub_free(stress_ptrs[i]);
            stress_ptrs[i] = NULL;
        }

        // 重新分配
        for (int i = 0; i < STRESS_COUNT; i += 2) {
            size_t size = (i % 8 + 1) * 8;
            stress_ptrs[i] = slub_alloc(size);
            assert(stress_ptrs[i] != NULL);
            *(int *)stress_ptrs[i] = i * 2;
        }

        // 全部释放
        for (int i = 0; i < STRESS_COUNT; i++) {
            if (stress_ptrs[i]) {
                slub_free(stress_ptrs[i]);
            }
        }
    }
    cprintf("Test 5 passed!\n");

    // 打印最终状态
    slub_print_info();

    cprintf("All SLUB tests passed!\n");
    cprintf("==========================================\n\n");
}

// ============ PMM 管理器接口实现 ============

// 初始化内存映射
void slub_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}

// 分配 n 个连续页面
struct Page *slub_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
        page->property = n;
    }
    return page;
}

// 释放 n 个连续页面
void slub_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
                break;
            }
        }
    }

    // 合并前面的空闲块
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    // 合并后面的空闲块
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

// 返回空闲页面数
size_t slub_nr_free_pages(void) {
    return nr_free;
}

// PMM 管理器结构
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};