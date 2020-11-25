/*
 * Copyright 2006 The Android Open Source Project
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */
#ifndef SKIA_CONFIG_SKUSERCONFIG_H_
#define SKIA_CONFIG_SKUSERCONFIG_H_

#include "../core/SkTypes.h"

SK_API inline void SkDebugf(const char format[], ...) {}

[[noreturn]] inline void sk_abort_no_print() {}

#endif
