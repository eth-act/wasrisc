/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#ifndef _BAREMETAL_FILE_H
#define _BAREMETAL_FILE_H

#ifdef __cplusplus
extern "C" {
#endif

#define POLLIN 0x001
#define POLLPRI 0x002
#define POLLOUT 0x004
#define POLLERR 0x008
#define POLLHUP 0x010
#define POLLNVAL 0x020
#define POLLRDNORM 0x040
#define POLLRDBAND 0x080
#define POLLWRNORM 0x100
#define POLLWRBAND 0x200

#define FIONREAD 0x541B

struct pollfd {
    int fd;
    short events;
    short revents;
};

int
sched_yield(void);

int
get_errno(void);

#ifdef __cplusplus
}
#endif

#endif /* end of _BAREMETAL_FILE_H */
