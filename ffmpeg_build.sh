#!/bin/bash
#
# Copyright 2016 Eng Chong Meng
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://gcc.gnu.org/onlinedocs/gcc-4.9.4/gcc/Link-Options.html#Link-Options
# Data relocation and protection (RELRO): LDLFAGS="-z relro -z now"
# i686-linux-android-ld: -Wl,-z,relro -Wl,-z,now: unknown options
# lame checks stdlib for linkage! omit -nostdlib

# LDFLAGS='-pie -fuse-ld=gold -Wl,-z,relro -Wl,-z,now -nostdlib -lc -lm -ldl -llog'
# -fuse-ld=gold: use ld.gold linker but unavailable for ABI mips and mips64
LDFLAGS='-pie -lc -lm -ldl -llog'


echo -e "\n\n** BUILD STARTED: ffmpeg for ${1} **"
. settings.sh $*

pushd ffmpeg
make clean

case $1 in
  armeabi)
    LDFLAGS="$LDFLAGS -Wl,-z,relro -Wl,-z,now" 
  ;;
  armeabi-v7a)
    LDFLAGS="$LDFLAGS -Wl,-z,relro -Wl,-z,now" 
  ;;
  arm64-v8a)
    LDFLAGS="$LDFLAGS -Wl,-z,relro -Wl,-z,now" 
  ;;
  x86)
    LDFLAGS="$LDFLAGS" 
  ;;
  x86_64)
    LDFLAGS="$LDFLAGS" 
  ;;
  mips)
    LDFLAGS="$LDFLAGS -Wl,-z,relro -Wl,-z,now" 
  ;;
  mips64)
    LDFLAGS="$LDFLAGS -Wl,-z,relro -Wl,-z,now" 
  ;;
esac

# export LDFLAGS="-Wl,-rpath-link=${NDK_SYSROOT}/usr/lib -L${NDK_SYSROOT}/usr/lib ${LDFLAGS}"
export LDFLAGS="${LDFLAGS}"

MODULES=""
for m in "$@"
  do
    case $m in
      x264)
        MODULES="$MODULES --enable-libx264 --enable-gpl --enable-version3"
      ;;
      vpx)
        MODULES="$MODULES --enable-libvpx"
      ;;
      png)
        MODULES="$MODULES --enable-libpng"
      ;;
      lame)
        MODULES="$MODULES --enable-libmp3lame"
      ;;
    esac
 done

# do no set ld option and use as=gcc for clang
TC_OPTIONS="--nm=${NM} --ar=${AR} --as=${CROSS_PREFIX}gcc --strip=${STRIP} --cc=${CC} --cxx=${CXX}"

./configure \
  --prefix=$PREFIX \
  --cross-prefix=$CROSS_PREFIX \
  --sysroot=$NDK_SYSROOT \
  --target-os=linux \
  --arch=$NDK_ARCH \
  --cpu=$CPU \
  --enable-cross-compile \
  $TC_OPTIONS \
  --disable-debug \
  --disable-doc \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --disable-runtime-cpudetect \
  --enable-pthreads \
  --enable-hardcoded-tables \
  $MODULES \
  --disable-programs \
  --disable-ffplay \
  --disable-ffprobe \
  --enable-x86asm \
  --extra-cflags="-I$PREFIX/include $CFLAGS" \
  --extra-ldflags="-L$PREFIX/lib $LDFLAGS" \
  --extra-cxxflags="$CXXFLAGS" \
  --extra-libs="-lgcc" \
  --pkg-config=$FFMPEG_PKG_CONFIG || exit 1

make -j${HOST_NUM_CORES} && make install || exit 1
popd

echo -e "** BUILD COMPLETED: ffmpeg for ${1} **\n"
