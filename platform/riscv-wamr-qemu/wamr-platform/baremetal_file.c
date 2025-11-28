/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * Copyright (C) 2024 Grenoble INP - ESISAR.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include "platform_api_vmcore.h"
#include "platform_api_extension.h"

#include <string.h>
#include <stdlib.h>

int
ocall_get_errno()
{
    return errno;
}

static inline bool
os_is_virtual_fd(int fd)
{
    switch (fd) {
        case STDIN_FILENO:
        case STDOUT_FILENO:
        case STDERR_FILENO:
            return true;
        default:
            return false;
    };
}

__wasi_errno_t
os_fstat(os_file_handle handle, struct __wasi_filestat_t *buf)
{
    printf("os_fstat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_fstatat(os_file_handle handle, const char *path,
           struct __wasi_filestat_t *buf, __wasi_lookupflags_t lookup_flags)
{
    printf("os_fstatat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_file_get_fdflags(os_file_handle handle, __wasi_fdflags_t *flags)
{
    printf("os_file_get_fdflags\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_file_set_fdflags(os_file_handle handle, __wasi_fdflags_t flags)
{
    printf("os_file_set_fdflags\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_fdatasync(os_file_handle handle)
{
    printf("os_fdatasync\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_fsync(os_file_handle handle)
{
    printf("os_fsync\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_open_preopendir(const char *path, os_file_handle *out)
{
    printf("os_open_preopendir\n");
    return __WASI_ENOSYS;
}


__wasi_errno_t
os_openat(os_file_handle handle, const char *path, __wasi_oflags_t oflags,
          __wasi_fdflags_t fd_flags, __wasi_lookupflags_t lookup_flags,
          wasi_libc_file_access_mode access_mode, os_file_handle *out)
{
    printf("os_openat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_file_get_access_mode(os_file_handle handle,
                        wasi_libc_file_access_mode *access_mode)
{
    printf("os_file_get_access_mode\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_close(os_file_handle handle, bool is_stdio)
{
    printf("os_close\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_preadv(os_file_handle handle, const struct __wasi_iovec_t *iov, int iovcnt,
          __wasi_filesize_t offset, size_t *nread)
{
    printf("os_preadv\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_pwritev(os_file_handle handle, const struct __wasi_ciovec_t *iov, int iovcnt,
           __wasi_filesize_t offset, size_t *nwritten)
{
    printf("os_pwritev\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_readv(os_file_handle handle, const struct __wasi_iovec_t *iov, int iovcnt,
         size_t *nread)
{
    printf("os_readv\n");
    return __WASI_ENOSYS;
}

/* With wasi-libc we need to redirect write on stdout/err to printf */
// TODO: handle write on stdin
__wasi_errno_t
os_writev(os_file_handle handle, const struct __wasi_ciovec_t *iov, int iovcnt,
          size_t *nwritten)
{
    printf("os_writev\n");
    ssize_t total_written = 0;
    // Write data from each buffer
    for (int i = 0; i < iovcnt; i++) {
        printf("%s", iov[i].buf);
        total_written += iov[i].buf_len;
    }

    *nwritten = total_written;

    return __WASI_ESUCCESS;

}

__wasi_errno_t
os_fallocate(os_file_handle handle, __wasi_filesize_t offset,
             __wasi_filesize_t length)
{
    printf("os_fallocate\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_ftruncate(os_file_handle handle, __wasi_filesize_t size)
{
    printf("os_ftruncate\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_futimens(os_file_handle handle, __wasi_timestamp_t access_time,
            __wasi_timestamp_t modification_time, __wasi_fstflags_t fstflags)
{
    printf("os_futimens\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_utimensat(os_file_handle handle, const char *path,
             __wasi_timestamp_t access_time,
             __wasi_timestamp_t modification_time, __wasi_fstflags_t fstflags,
             __wasi_lookupflags_t lookup_flags)
{
    printf("os_utimensat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_readlinkat(os_file_handle handle, const char *path, char *buf,
              size_t bufsize, size_t *nread)
{
    printf("os_readlinkat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_linkat(os_file_handle from_handle, const char *from_path,
          os_file_handle to_handle, const char *to_path,
          __wasi_lookupflags_t lookup_flags)
{
    printf("os_linkat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_symlinkat(const char *old_path, os_file_handle handle, const char *new_path)
{
    printf("os_symlinkat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_mkdirat(os_file_handle handle, const char *path)
{
    printf("os_mkdirat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_renameat(os_file_handle old_handle, const char *old_path,
            os_file_handle new_handle, const char *new_path)
{
    printf("os_renameat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_unlinkat(os_file_handle handle, const char *path, bool is_dir)
{
    printf("os_unlinkat\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_lseek(os_file_handle handle, __wasi_filedelta_t offset,
         __wasi_whence_t whence, __wasi_filesize_t *new_offset)
{
    printf("os_lseek\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_fadvise(os_file_handle handle, __wasi_filesize_t offset,
           __wasi_filesize_t length, __wasi_advice_t advice)
{
    printf("os_fadvise\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_isatty(os_file_handle handle)
{
    printf("os_isatty\n");
    return __WASI_ENOTTY;
}

os_file_handle
os_convert_stdin_handle(os_raw_file_handle raw_stdin)
{
    return 0;
}

os_file_handle
os_convert_stdout_handle(os_raw_file_handle raw_stdout)
{
    return 1;
}

os_file_handle
os_convert_stderr_handle(os_raw_file_handle raw_stderr)
{
    return 2;
}

__wasi_errno_t
os_fdopendir(os_file_handle handle, os_dir_stream *dir_stream)
{
    printf("os_fdopendir\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_rewinddir(os_dir_stream dir_stream)
{
    printf("os_rewinddir\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_seekdir(os_dir_stream dir_stream, __wasi_dircookie_t position)
{
    printf("os_seekdir\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_readdir(os_dir_stream dir_stream, __wasi_dirent_t *entry,
           const char **d_name)
{
    printf("os_readdir\n");
    return __WASI_ENOSYS;
}

__wasi_errno_t
os_closedir(os_dir_stream dir_stream)
{
    printf("os_closedir\n");
    return __WASI_ENOSYS;
}

os_dir_stream
os_get_invalid_dir_stream()
{
    return NULL;
}

bool
os_is_dir_stream_valid(os_dir_stream *dir_stream)
{
    return false;
}

bool
os_is_handle_valid(os_file_handle *handle)
{
    if (handle == NULL)
        return false;
    return *handle >= 0;
}

char *
os_realpath(const char *path, char *resolved_path)
{
    return NULL;
}

bool
os_compare_file_handle(os_file_handle handle1, os_file_handle handle2)
{
    return handle1 == handle2;
}

bool
os_is_stdin_handle(os_file_handle handle)
{
    return handle == 0;
}

bool
os_is_stdout_handle(os_file_handle handle)
{
    return handle == 1;
}

bool
os_is_stderr_handle(os_file_handle handle)
{
    return handle == 2;
}

int
os_ioctl(os_file_handle handle, int request, ...)
{
    return __WASI_ENOSYS;
}

int
os_poll(os_poll_file_handle *fds, os_nfds_t nfs, int timeout)
{
    return BHT_ERROR;
}

int
sched_yield(void)
{
    return BHT_ERROR;
}

int
get_errno(void)
{
    int ret;

    if (ocall_get_errno(&ret) != 0) {
        return -1;
    }
    return ret;
}
