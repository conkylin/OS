#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>

// SLUB分配器的最大和最小对象大小
#define SLUB_MIN_SIZE       8       // 最小分配单元8字节
#define SLUB_MAX_SIZE       2048    // 最大分配单元2KB
#define SLUB_CACHE_NUM      9       // 缓存数量 (8, 16, 32, 64, 128, 256, 512, 1024, 2048)
#define le2slub_page(le, member) \
    ((struct slub_page *)((char *)(le) - offsetof(struct slub_page, member)))

// 页面和虚拟地址转换（在 slub_pmm.c 中实现）
void *page2kva(struct Page *page);
struct Page *kva2page(void *kva);

// SLUB对象头部信息
struct slub_object {
    struct slub_object *next;       // 指向下一个空闲对象
};

// SLUB页面信息
struct slub_page {
    list_entry_t page_link;         // 页面链表
    struct slub_cache *cache;       // 所属的cache
    void *freelist;                 // 空闲对象链表头
    uint16_t inuse;                 // 已使用的对象数
    uint16_t objects;               // 总对象数
    struct Page *page;              // 对应的物理页
};

// SLUB缓存结构
struct slub_cache {
    const char *name;               // 缓存名称
    size_t size;                    // 对象大小
    size_t align;                   // 对齐要求
    size_t objects_per_page;        // 每页对象数

    // 页面链表
    list_entry_t partial;           // 部分空闲页面链表
    list_entry_t full;              // 完全使用页面链表

    // 统计信息
    size_t nr_partial;              // 部分空闲页面数
    size_t nr_full;                 // 完全使用页面数
    size_t total_objects;           // 总对象数
    size_t used_objects;            // 已使用对象数
};

// SLUB分配器接口
void slub_init(void);
void slub_init_memmap(struct Page *base, size_t n);
struct Page *slub_alloc_pages(size_t n);
void slub_free_pages(struct Page *base, size_t n);
size_t slub_nr_free_pages(void);
void slub_check(void);

// SLUB 内部接口（用于小对象分配）
void *slub_alloc(size_t size);
void slub_free(void *ptr);
void slub_print_info(void);

// PMM管理器接口
extern const struct pmm_manager slub_pmm_manager;

#endif /* !__KERN_MM_SLUB_H__ */