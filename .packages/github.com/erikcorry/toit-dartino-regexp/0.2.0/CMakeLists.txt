# Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.22)

# NONE means skip testing the C compiler.
project(regexp NONE)

enable_testing()
add_subdirectory(tests)
