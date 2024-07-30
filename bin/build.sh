#!/bin/bash

set -e

release_build="$1"

clang-format -i code/**/*.m code/**/*.metal

rm -rf "build"

mkdir -p "build/Silk.app/Contents/MacOS"
mkdir -p "build/Silk.app/Contents/Resources"

cp "data/Info.plist" "build/Silk.app/Contents/Info.plist"

compiler_arguments=()

compiler_arguments+=(-o "build/Silk.app/Contents/MacOS/Silk")
compiler_arguments+=(-I "code")

if [ "$release_build" ]; then
	compiler_arguments+=(-Os -fwrapv -fno-strict-aliasing)
else
	compiler_arguments+=(-DDEBUG=1 -g3 -fsanitize=undefined)
fi

compiler_arguments+=(
	-fmodules
	-fobjc-arc
	-W
	-Wall
	-Wextra
	-Wpedantic
	-Wconversion
	-Wimplicit-fallthrough
	-Wmissing-prototypes
	-Wshadow
	-Wstrict-prototypes
)

compiler_arguments+=("code/silk/entry_point.m")

clang "${compiler_arguments[@]}"	

xcrun metal \
	-o "build/Silk.app/Contents/Resources/default.metallib" \
	-gline-tables-only -frecord-sources \
	"code/silk/shaders.metal"
