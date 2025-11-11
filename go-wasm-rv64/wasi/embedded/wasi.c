#include "w2c2_base.h"
#include <stdio.h>

#define TIME_OFFSET            1758880055000000000LL
#define PSEUDOCLOCK_INCREMENTS                 1e8

#define WASI_ERRNO_SUCCESS  0
#define WASI_ERRNO_BADF     8
#define WASI_ERRNO_NOSYS   52

wasmMemory*
wasiMemory(
	void* instance
);

bool wasiInit(int argc, char* argv[], char** envp) {
	return true;
}


void wasisnapshotpreview1Instantiate(void* instance, void* resolve(const char* module, const char* name)) {
	printf("wasisnapshotpreview1Instantiate\n");
}

void wasisnapshotpreview1FreeInstance(void* instance) {
	printf("wasisnapshotpreview1FreeInstance\n");
}

void wasi_snapshot_preview1__proc_exit(void* i, U32 l0) {
	printf("wasi_snapshot_preview1__proc_exit\n");
	exit(l0);
}

U32 wasi_snapshot_preview1__fd_prestat_get(void* i, U32 wasiFD, U32 resultPointer) {
	printf("wasi_snapshot_preview1__fd_prestat_get(wasiFD=%d)\n", wasiFD);
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__fd_prestat_dir_name(void* i, U32 l0, U32 l1, U32 l2) {
	printf("wasi_snapshot_preview1__fd_prestat_dir_name\n");
	return 0;
}

U32 wasi_snapshot_preview1__fd_fdstat_get(void* i, U32 wasiFD, U32 resultPointer) {
	printf("wasi_snapshot_preview1__fd_fdstat_get(wasiFD=%d)\n", wasiFD);
	return 0;
}

U32 wasi_snapshot_preview1__fd_fdstat_set_flags(void*,U32,U32) {
	printf("wasi_snapshot_preview1__fd_fdstat_set_flags\n");
	//return 0;
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__path_filestat_get(void* i, U32 l0, U32 l1, U32 l2, U32 l3, U32 l4) {
	printf("wasi_snapshot_preview1__path_filestat_get\n");
	return 0;
}

U32 wasi_snapshot_preview1__environ_sizes_get(void* i, U32 l0, U32 l1) {
	printf("wasi_snapshot_preview1__environ_sizes_get\n");
	return 0;
}

U32 wasi_snapshot_preview1__poll_oneoff(void* i, U32 inPointer, U32 outPointer, U32 subscriptionCount, U32 eventCount) {
	// printf("wasi_snapshot_preview1__poll_oneoff\n");
	return WASI_ERRNO_SUCCESS;
}

U32 wasi_snapshot_preview1__adapter_close_badfd(void* i, U32 l0) {
	printf("wasi_snapshot_preview1__adapter_close_badfd\n");
	return 0;
}

U32 wasi_snapshot_preview1__fd_close(void* i, U32 l0) {
	printf("wasi_snapshot_preview1__fd_close\n");
	return 0;
}

U32 wasi_snapshot_preview1__fd_read(void* i, U32 wasiFD, U32 iovecsPointer, U32 iovecsCount, U32 resultPointer) {
	printf("wasi_snapshot_preview1__fd_read(wasiFD=%d)\n", wasiFD);
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__environ_get(void* i, U32 l0, U32 l1) {
	printf("wasi_snapshot_preview1__environ_get\n");
	return 0;
}
// returns nanoseconds
U32 wasi_snapshot_preview1__clock_time_get(void* i, U32 clockID, U64 precision, U32 resultPointer) {
	static int64_t ticks = 1;

	wasmMemory* memory = wasiMemory(i);
	// TODO: For zkvms, we can return the number of cycles
	// printf("wasi_snapshot_preview1__clock_time_get\n");

	i64_store(memory, resultPointer, TIME_OFFSET+ticks);

	ticks += PSEUDOCLOCK_INCREMENTS;

	return 0;
}

U32 wasi_snapshot_preview1__fd_seek(void* i, U32 l0, U64 l1, U32 l2, U32 l3) {
	printf("wasi_snapshot_preview1__fd_seek\n");
	return 0;
}

U32 wasi_snapshot_preview1__sched_yield(void* i) {
	printf("wasi_snapshot_preview1__sched_yield\n");
	return 0;
}

struct iovec {
	void* iov_base;
	size_t iov_len;
};

#define WASI_ERRNO_NOMEM 48

static const size_t ciovecSize = 8;

/* use part of wasi.c from w2c2 here but avoid full implementation */
U32 wasi_snapshot_preview1__fd_write(void* i, U32 wasiFD, U32 ciovecsPointer, U32 ciovecsCount, U32 resultPointer) {
	wasmMemory* memory = wasiMemory(i);
	struct iovec* iovecs = NULL;
	I64 total = 0;
	if (wasiFD != 1 && wasiFD != 2) {
		printf("wasi_snapshot_preview1__fd_write(wasiFD=%d)\n", wasiFD);
	}

	iovecs = malloc(ciovecsCount * sizeof(struct iovec));
	if (iovecs == NULL) {
		printf("fd_write: no mem\n");
		return WASI_ERRNO_NOMEM;
	}

	/* Convert WASI ciovecs to native iovecs */
	{
		U32 ciovecIndex = 0;
		for (; ciovecIndex < ciovecsCount; ciovecIndex++) {
			U64 ciovecPointer = ciovecsPointer + ciovecIndex * ciovecSize;
			U32 bufferPointer = i32_load(memory, ciovecPointer);
			U32 length = i32_load(memory, ciovecPointer + 4);

			if (wasiFD != 1 && wasiFD != 2) {
				printf("length = %d\n", length);
			}

			iovecs[ciovecIndex].iov_base = memory->data + bufferPointer;
			iovecs[ciovecIndex].iov_len = length;
			total += length;

			for (int i = 0; i < iovecs[ciovecIndex].iov_len; i++) {
				putchar(((char*)iovecs[ciovecIndex].iov_base)[i]);
			}
		}
	}

	/* Store the amount of written bytes at the result pointer */
	i32_store(memory, resultPointer, total);
	return 0; // success
}

U32 wasi_snapshot_preview1__path_unlink_file(void* i, U32 l0, U32 l1, U32 l2) {
	printf("wasi_snapshot_preview1__path_unlink_file\n");
	return 0;
}

U32 wasi_snapshot_preview1__random_get(void*,U32,U32) {
	printf("wasi_snapshot_preview1__random_get\n");
	return 0;
}

U32 wasi_snapshot_preview1__args_get(void*,U32,U32) {
	printf("wasi_snapshot_preview1__args_get\n");
	return 0;
}

U32 wasi_snapshot_preview1__args_sizes_get(void*,U32,U32) {
	printf("wasi_snapshot_preview1__args_sizes_get\n");
	return 0;
}