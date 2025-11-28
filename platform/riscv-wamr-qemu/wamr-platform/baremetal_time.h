#ifndef _BAREMETAL_TIME_H
#define _BAREMETAL_TIME_H

#ifdef __cplusplus
extern "C" {
#endif

int
clock_nanosleep(clockid_t clock_id, int flags, const struct timespec *request,
                struct timespec *remain);

#ifdef __cplusplus
}
#endif

#endif /* end of _BAREMETAL_TIME_H */