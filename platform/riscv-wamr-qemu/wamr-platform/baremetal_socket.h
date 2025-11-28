/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#ifndef _BAREMETAL_SOCKET_H
#define _BAREMETAL_SOCKET_H

#ifdef __cplusplus
extern "C" {
#endif

uint32_t
htonl(uint32_t value);

uint16_t
htons(uint16_t value);

#ifdef __cplusplus
}
#endif

#endif /* end of _BAREMETAL_SOCKET_H */
