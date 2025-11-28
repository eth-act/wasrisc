#ifndef _BAREMETAL_THREAD_H
#define _BAREMETAL_THREAD_H

int pthread_condattr_init(pthread_condattr_t *attr);
int pthread_condattr_destroy(pthread_condattr_t *attr);

int pthread_cond_init(pthread_cond_t *restrict cond, const pthread_condattr_t *restrict attr);

int pthread_condattr_setclock(pthread_condattr_t *attr, clockid_t clock_id);

int pthread_once(pthread_once_t *once_control, void (*init_routine)(void));

#define PTHREAD_ONCE_INIT {}

#endif /* end of _BAREMETAL_THREAD_H */
