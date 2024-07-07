#!/bin/sh

set -e

clang-format -i code/**/*.m

rm -rf "build"

mkdir -p "build/Silk.app/Contents/MacOS"
mkdir -p "build/Silk.app/Contents/Resources"

cp "data/Info.plist" "build/Silk.app/Contents/Info.plist"

clang \
	-o "build/Silk.app/Contents/MacOS/Silk" \
	-I code \
	-fmodules -fobjc-arc \
	-g3 \
	-fsanitize=undefined \
	-W \
	-Wall \
	-Wextra \
	-Wpedantic \
	-Wconversion \
	-Wimplicit-fallthrough \
	-Wmissing-prototypes \
	-Wshadow \
	-Wstrict-prototypes \
	-Wno-unused-parameter \
	code/silk/entry_point.m
