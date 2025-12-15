#include <ulib.h>
#include <stdio.h>
#include <string.h>

/*
 * cowtest - 简单的写时复制测试用例
 *
 * 父进程将全局缓冲区填充为 0xAA，fork() 后子进程将其全部修改为
 * 0x55 并通过退出码返回第一个字节的值。父进程等待子进程结束后
 * 检查自己的缓冲区是否仍然是 0xAA，以及子进程返回的退出码是否
 * 与期望一致。如果父缓冲区被修改或者子进程返回值不正确，则
 * 判定 COW 实现存在问题。
 */

static char buf[4096];

int
main(void) {
    memset(buf, 0xAA, sizeof(buf));
    int pid = fork();
    if (pid < 0) {
        cprintf("cowtest: fork failed\n");
        return 1;
    }
    if (pid == 0) {
        // 子进程修改缓冲区
        for (int i = 0; i < sizeof(buf); i++) {
            buf[i] = 0x55;
        }
        // 返回修改后的第一个字节
        exit((int)(unsigned char)buf[0]);
    }
    // 父进程等待子进程并获取退出码。
    // 子进程的退出码通过第二个参数返回。
    int exit_code = -1;
    int status = waitpid(pid, &exit_code);
    // 检查缓冲区是否被修改
    if ((unsigned char)buf[0] != 0xAA) {
        cprintf("cowtest failed: parent buffer modified (buf[0]=%x)\n", (unsigned char)buf[0]);
        return 1;
    }
    if (status != 0) {
        cprintf("cowtest failed: waitpid returned %d\n", status);
        return 1;
    }
    if (exit_code != 0x55) {
        cprintf("cowtest failed: unexpected child exit code %d\n", exit_code);
        return 1;
    }
    cprintf("cowtest pass. parent buf[0]=%x, child exit=%d\n",
           (unsigned char)buf[0], exit_code);
    return 0;
}