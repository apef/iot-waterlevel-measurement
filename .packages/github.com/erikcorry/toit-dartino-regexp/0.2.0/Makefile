# Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

.PHONY: all
all: test

.PHONY: install-pkgs
install-pkgs: rebuild-cmake
	cmake --build build --target install-pkgs
	cmake --build build --target install-pkgs-sputnik

.PHONY: test
test: install-pkgs rebuild-cmake
	cmake --build build --target check

# We rebuild the cmake file all the time.
# We use "glob" in the cmakefile, and wouldn't otherwise notice if a new
# file (for example a test) was added or removed.
# It takes <1s on Linux to run cmake, so it doesn't hurt to run it frequently.
.PHONY: rebuild-cmake
rebuild-cmake:
	mkdir -p build
	cmake -B build -DCMAKE_BUILD_TYPE=Release
