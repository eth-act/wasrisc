/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include "platform_api_vmcore.h"
#include "platform_api_extension.h"


korp_tid
os_self_thread()
{
    return 0;
}

int
os_mutex_init(korp_mutex *mutex)
{
    return BHT_OK;
}

int
os_mutex_destroy(korp_mutex *mutex)
{
    return BHT_OK;
}

int
os_mutex_lock(korp_mutex *mutex)
{
    return 0;
}

int
os_mutex_unlock(korp_mutex *mutex)
{
    return 0;
}

int
os_cond_init(korp_cond *cond)
{
    return BHT_OK;
}

int
os_cond_destroy(korp_cond *cond)
{
    return BHT_OK;
}

int
os_cond_wait(korp_cond *cond, korp_mutex *mutex)
{
    return BHT_OK;
}

int
os_cond_reltimedwait(korp_cond *cond, korp_mutex *mutex, uint64 useconds)
{
    os_printf("warning: baremetal pthread_cond_timedwait isn't supported, "
              "calling pthread_cond_wait instead!\n");
    return BHT_ERROR;
}

int
os_cond_signal(korp_cond *cond)
{
    return BHT_OK;
}

int
os_cond_broadcast(korp_cond *cond)
{
    return BHT_OK;
}

int
os_thread_join(korp_tid thread, void **value_ptr)
{
    return 0;
}

int
os_thread_detach(korp_tid thread)
{
    /* baremetal pthread_detach isn't provided, return directly. */
    return 0;
}

void
os_thread_exit(void *retval)
{
    return;
}

uint8 *
os_thread_get_stack_boundary()
{
    /* TODO: get baremetal stack boundary */
    return NULL;
}

void
os_thread_jit_write_protect_np(bool enabled)
{}

int
os_rwlock_init(korp_rwlock *lock)
{
    return BHT_OK;
}

int
os_rwlock_rdlock(korp_rwlock *lock)
{
    return BHT_OK;
}

int
os_rwlock_wrlock(korp_rwlock *lock)
{
    return BHT_OK;
}

int
os_rwlock_unlock(korp_rwlock *lock)
{
    return BHT_OK;
}

int
os_rwlock_destroy(korp_rwlock *lock)
{
    return BHT_OK;
}

int
os_thread_signal_init(os_signal_handler handler)
{
    return 0;
}

bool
os_thread_signal_inited()
{
    return false;
}

void
os_thread_signal_destroy()
{}

int pthread_once(pthread_once_t *once_control, void (*init_routine)(void)) {
    if (once_control != 0) {
        // TODO
        init_routine();
    }
    return 0;
}
