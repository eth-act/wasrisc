#include "w2c2_base.h"
#include <stdio.h>
#include <math.h>

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

U32 wasi_snapshot_preview1__fd_fdstat_set_flags(void* i, U32 l0, U32 l1) {
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

U32 wasi_snapshot_preview1__fd_advise(void* i, U32 l0, U64 l1, U64 l2, U32 l3) {
	printf("wasi_snapshot_preview1__fd_advise\n");
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

// Size of a single ciovec item
static const size_t ciovecSize = 8;

// Number of iovecs to be pre-allocated. Choose a number high enough to
// let programs work that use file and socket I/O outside of printing to the
// console. But small enough to raise an error since this stub implementation
// would likely have to be extended in that case. (On Linux IOV_MAX is 1024)
//
// Pre-allocation is done to allow Console.WriteLine to work even when malloc
// fails.
#define IOVECS_SIZE 10

/* use part of wasi.c from w2c2 here but avoid full implementation */
U32 wasi_snapshot_preview1__fd_write(void* i, U32 wasiFD, U32 ciovecsPointer, U32 ciovecsCount, U32 resultPointer) {
	wasmMemory* memory = wasiMemory(i);
	struct iovec iovecs[IOVECS_SIZE];
	I64 total = 0;
	if (wasiFD != 1 && wasiFD != 2) {
		printf("wasi_snapshot_preview1__fd_write(wasiFD=%d)\n", wasiFD);
	}

	if (ciovecsCount > IOVECS_SIZE) {
		printf("fd_write: unexpected iovecs\n");
		return WASI_ERRNO_NOMEM;
	}

	/* Convert WASI ciovecs to native iovecs */
	{
		U32 ciovecIndex = 0;
		for (; ciovecIndex < ciovecsCount && ciovecIndex < IOVECS_SIZE; ciovecIndex++) {
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

U32 wasi_snapshot_preview1__random_get(void* i, U32 l0, U32 l1) {
	printf("wasi_snapshot_preview1__random_get\n");
	return 0;
}

U32 wasi_snapshot_preview1__args_get(void* i, U32 l0, U32 l1) {
	printf("wasi_snapshot_preview1__args_get\n");
	return 0;
}

U32 wasi_snapshot_preview1__args_sizes_get(void* i, U32 l0, U32 l1) {
	printf("wasi_snapshot_preview1__args_sizes_get\n");
	return 0;
}

U32 wasi_snapshot_preview1__fd_pread(void* i, U32 wasiFD, U32 iovecsPointer, U32 iovecsCount, U64 offset, U32 resultPointer) {
	printf("wasi_snapshot_preview1__fd_pread(wasiFD=%d)\n", wasiFD);
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__path_readlink(void* i, U32 l0, U32 l1, U32 l2, U32 l3, U32 l4, U32 l5) {
	printf("wasi_snapshot_preview1__path_readlink\n");
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__path_rename(void* i, U32 l0, U32 l1, U32 l2, U32 l3, U32 l4, U32 l5) {
	printf("wasi_snapshot_preview1__path_rename\n");
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__fd_filestat_get(void* i, U32 wasiFD, U32 resultPointer) {
	printf("wasi_snapshot_preview1__fd_filestat_get(wasiFD=%d)\n", wasiFD);
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__path_open(void* i, U32 l0, U32 l1, U32 l2, U32 l3, U32 l4, U64 l5, U64 l6, U32 l7, U32 l8) {
	printf("wasi_snapshot_preview1__path_open\n");
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__path_remove_directory(void* i, U32 l0, U32 l1, U32 l2) {
	printf("wasi_snapshot_preview1__path_remove_directory\n");
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__fd_sync(void* i, U32 wasiFD) {
	printf("wasi_snapshot_preview1__fd_sync(wasiFD=%d)\n", wasiFD);
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__path_create_directory(void* i, U32 l0, U32 l1, U32 l2) {
	printf("wasi_snapshot_preview1__path_create_directory\n");
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__fd_readdir(void* i, U32 wasiFD, U32 bufferPointer, U32 bufferLen, U64 cookie, U32 resultPointer) {
	printf("wasi_snapshot_preview1__fd_readdir(wasiFD=%d)\n", wasiFD);
	return WASI_ERRNO_BADF;
}

U32 wasi_snapshot_preview1__fd_filestat_set_size(void* i, U32 wasiFD, U64 size) {
	printf("wasi_snapshot_preview1__fd_filestat_set_size(wasiFD=%d, size=%llu)\n", wasiFD, size);
	return WASI_ERRNO_BADF;
}
