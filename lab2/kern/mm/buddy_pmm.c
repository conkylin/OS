#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <buddy_pmm.h>
#include <memlayout.h>
free_buddy_t buddy_sys;

#define buddy_array (buddy_sys.free_array)
#define max_order (buddy_sys.max_order)
#define nr_free (buddy_sys.nr_free)

static int IS_POWER_OF_2(size_t n) {
    if (n == 0) return 0;
    return (n & (n - 1)) == 0;
}

// 返回一个数对应的幂指数
static unsigned int Get_Order_Of_2(size_t n) {
    if (n == 0) return 0;
    unsigned int order = 0;
    while (n > 1) {
        n >>= 1;
        order++;
    }
    return order;
}

// 找到比n小的最接近的2的幂
static size_t Find_The_Small_2(size_t n) {
    if (n == 0) return 0;
    size_t result = 1;
    while (result <= n) {
        result <<= 1;
    }
    return result >> 1;
}

// 找到比n大的最接近的2的幂
static size_t Find_The_Big_2(size_t n) {
    if (n == 0) return 1;
    if (IS_POWER_OF_2(n)) return n;
    
    size_t result = 1;
    while (result < n) {
        result <<= 1;
    }
    return result;
}

static void buddy_split(size_t n) {
    assert(n > 0 && n <= max_order);
    assert(!list_empty(&(buddy_array[n])));
    
    // 获取要分裂的块
    list_entry_t *le = list_next(&(buddy_array[n]));
    struct Page *page1 = le2page(le, page_link);
    
    // 计算分裂后的大小
    size_t split_size = 1 << (n - 1);
    struct Page *page2 = page1 + split_size;
    
    page1->property = n - 1;
    page2->property = n - 1;
    SetPageProperty(page1);
    SetPageProperty(page2);
    
    list_del(le);
    
    // 将分裂后的块添加到低一阶链表
    list_add(&(buddy_array[n - 1]), &(page2->page_link));
    list_add(&(buddy_array[n - 1]), &(page1->page_link));
    
}

// 获取伙伴块
static struct Page *get_buddy(struct Page *page, unsigned int order) {
    if (order > MAX_BUDDY_ORDER) return NULL;
    
    // 计算当前块的大小
    size_t real_block_size = 1 << order;  
    
    struct Page *base_addr = (struct Page *)0xffffffffc020f318;
    
    size_t relative_block_addr = (size_t)page - (size_t)base_addr;
    
    // 计算块的大小
    size_t sizeOfPage = real_block_size * sizeof(struct Page);
    
    // 计算伙伴块的相对地址
    size_t buddy_relative_addr = relative_block_addr ^ sizeOfPage;
    
    // 计算伙伴块的真实地址
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + (size_t)base_addr);
    
    return buddy_page;
}

// 显示空闲链表状态
static void show_buddy_array(int left, int right) {
    int empty = 1; 
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
    
    cprintf("---------- Buddy System Free Lists (Order %d to %d) ----------\n", left, right);
    for (int i = left; i <= right; i++) {
        list_entry_t *le = &buddy_array[i];
        if (list_next(le) != le) {
            empty = 0;
            cprintf("Order %d (%4d pages): ", i, 1 << i);
            int count = 0;
            list_entry_t *tmp = le->next;
            while (tmp != le) {
                struct Page *p = le2page(tmp, page_link);
                if (count > 0) cprintf(" -> ");
                cprintf("[addr:%p]", p);
                tmp = tmp->next;
                count++;
            }
            cprintf(" (total %d blocks)\n", count);
        }
    }
    if (empty) {
        cprintf("No free blocks in this range!\n");
    }
    cprintf("Total free pages: %u\n", nr_free);
    cprintf("------------------------------------------------------------\n\n");
}

// 初始化伙伴系统
static void buddy_init(void) {
    for (int i = 0; i <= MAX_BUDDY_ORDER; i++) {
        list_init(&(buddy_array[i]));
    }
    max_order = 0;
    nr_free = 0;
}

// 初始化内存映射
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base != NULL);
    
    // 计算可用的最大2的幂次方页面数
    size_t p_number = Find_The_Small_2(n);
    unsigned int order = Get_Order_Of_2(p_number);
    
    // 初始化页面
    struct Page *p = base;
    for (size_t i = 0; i < p_number; i++, p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
        ClearPageProperty(p);
        SetPageReserved(p);
    }
    
    // 设置基础页面属性
    base->property = order;
    SetPageProperty(base);
    
    // 添加到空闲链表
    list_add(&(buddy_array[order]), &(base->page_link));
    
    max_order = order;
    nr_free = p_number;
}

// 分配页面
static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    if (n > nr_free) {
        return NULL;
    }
    
    // 计算需要的阶数
    size_t adjusted_pages = Find_The_Big_2(n);
    unsigned int req_order = Get_Order_Of_2(adjusted_pages);
    
    // 查找合适的内存块
    unsigned int current_order = req_order;
    while (current_order <= max_order) {
        if (!list_empty(&(buddy_array[current_order]))) {
            break;
        }
        current_order++;
    }
    
    if (current_order > max_order) {
        return NULL;
    }
    
    // 如果需要分裂，递归分裂直到得到合适大小的块
    while (current_order > req_order) {
        buddy_split(current_order);
        current_order--;
    }
    
    // 分配块
    list_entry_t *le = list_next(&(buddy_array[req_order]));
    struct Page *page = le2page(le, page_link);
    list_del(le);
    
    // 更新页面属性
    struct Page *p = page;
    size_t allocated_pages = 1 << req_order;
    for (size_t i = 0; i < allocated_pages; i++) {
        ClearPageProperty(p);
        SetPageReserved(p);
        p++;
    }
    
    nr_free -= allocated_pages;
    return page;
}

// 释放页面
static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0 && base != NULL);

    unsigned int order = base->property;
    size_t freed_pages = 1 << order;

    // 1. 标记页面为空闲状态
    struct Page *p = base;
    for (size_t i = 0; i < freed_pages; i++) {
        assert(PageReserved(p));
        ClearPageReserved(p);
        SetPageProperty(p);
        p->property = 0;
        p++;
    }
    base->property = order;
    list_add(&(buddy_array[order]), &(base->page_link));
    nr_free += freed_pages;

    // 3. 合并逻辑
    struct Page *current_block = base;
    unsigned int current_order = order;

    while (current_order < max_order) {
        struct Page *buddy = get_buddy(current_block, current_order);
        
        // 简化检查条件：只检查伙伴块是否存在且是空闲的
        if (buddy == NULL || !PageProperty(buddy) || buddy->property != current_order) {
            break;
        }
        
        // 计算伙伴块的物理地址范围
        size_t buddy_pa_start = page2pa(buddy);
        size_t buddy_pa_end = buddy_pa_start + (1 << (current_order + PGSHIFT)) - 1;
        
        // 计算当前块的物理地址范围  
        size_t current_pa_start = page2pa(current_block);
        size_t current_pa_end = current_pa_start + (1 << (current_order + PGSHIFT)) - 1;
        
        // 验证两个块确实是相邻的伙伴
        size_t pa_difference = (current_pa_start > buddy_pa_start) ? 
                              (current_pa_start - buddy_pa_start) : 
                              (buddy_pa_start - current_pa_start);
        size_t expected_difference = 1 << (current_order + PGSHIFT);
        
        if (pa_difference != expected_difference) {
            break; 
        }
        
        int buddy_was_in_list = 0;
        list_entry_t *le = &(buddy->page_link);
        if (!list_empty(le)) {
            list_del_init(le); 
            buddy_was_in_list = 1;
        }
        
        // 也从链表中删除当前块
        list_del_init(&(current_block->page_link));
        
        if (!buddy_was_in_list) {
            // 伙伴不在链表中，恢复当前块到链表并退出
            list_add(&(buddy_array[current_order]), &(current_block->page_link));
            break;
        }
        
        // 选择地址较低的块作为合并后的基址
        if (page2pa(current_block) > page2pa(buddy)) {
            struct Page *temp = current_block;
            current_block = buddy;
            buddy = temp;
        }
        
        // 更新合并后块的属性
        current_order++;
        current_block->property = current_order;
        
        // 将合并后的块加入到更高阶的链表中
        list_add(&(buddy_array[current_order]), &(current_block->page_link));
        
    }
}

// 获取空闲页面数
static size_t buddy_nr_free_pages(void) {
    return nr_free;
}

// 测试函数
static void buddy_check(void) {
     cprintf("=== Starting Buddy System Check ===\n");
    
    // 1. 开始时直接查看空闲状态
    cprintf("1. Initial free state:\n");
    show_buddy_array(0, max_order);

    // 6. 分配一个16384页的块
    struct Page *p_large2;
    size_t n2 = 16384;
    assert((p_large2 = alloc_pages(n2)) != NULL);
    cprintf("6. After allocating a block of size %u pages:\n", n2);
    show_buddy_array(0, max_order);
    
    // 7. 释放16384页的块
    free_pages(p_large2, n2);
    cprintf("7. After freeing the block of size %u pages:\n", n2);
    show_buddy_array(0, max_order);

    // 2. 分配四个单页并查看状态
    struct Page *p0, *p1, *p2, *p3;
    p0 = p1 = p2 = p3 = NULL;
    size_t n0 = 2;
    assert((p0 = alloc_pages(n0)) != NULL);
    assert((p1 = alloc_pages(n0)) != NULL);
    assert((p2 = alloc_pages(n0)) != NULL);
    assert((p3 = alloc_pages(n0)) != NULL);
    
    assert(p0 != p1 && p0 != p2 && p0 != p3 && p1 != p2 && p1 != p3 && p2 != p3);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0 && page_ref(p3) == 0);
    
    cprintf("2. After allocating 8 single pages:\n");
    show_buddy_array(0, max_order);
    
    // 3. 释放所有四个页面并查看状态
    free_pages(p0,n0);
    free_pages(p1,n0);
    free_pages(p2,n0);
    free_pages(p3,n0);
    
    cprintf("3. After freeing all 8 single pages:\n");
    show_buddy_array(0, max_order);
    
    // 4. 分配一个257页的块（伙伴系统会调整为512页，即2的9次方）
    struct Page *p_large1;
    size_t n1 = 257;
    assert((p_large1 = alloc_pages(n1)) != NULL);
    cprintf("4. After allocating a block of size %u (adjusted to %u pages):\n", 
           n1, (1 << Get_Order_Of_2(Find_The_Big_2(n1))));
    show_buddy_array(0, max_order);
    
    // 5. 释放257页的块
    free_pages(p_large1, n1);
    cprintf("5. After freeing the block of size %u:\n", n1);
    show_buddy_array(0, max_order);
    
    cprintf("Buddy system check completed successfully!\n");
}

// 伙伴系统管理器
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};