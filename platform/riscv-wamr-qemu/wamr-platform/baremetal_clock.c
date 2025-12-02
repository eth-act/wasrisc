/*
 * Copyright (C) 2024 Grenoble INP - ESISAR.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include "platform_api_extension.h"
#include "platform_api_vmcore.h"

// Jan 1st 2025 in nanoseconds
#define OS_CLOCK_TIME_START 1735686000e9

__wasi_errno_t
os_clock_res_get(__wasi_clockid_t clock_id, __wasi_timestamp_t *resolution)
{
    printf("os_clock_res_get\n");
    return __WASI_ENOSYS;
}

uint64 os_clock_current_time = 0;

__wasi_errno_t
os_clock_time_get(__wasi_clockid_t clock_id, __wasi_timestamp_t precision,
                  __wasi_timestamp_t *time)
{
    printf("os_clock_time_get\n");

    *time = OS_CLOCK_TIME_START + os_clock_current_time;
    os_clock_current_time += 100;

    return __WASI_ESUCCESS;
}
