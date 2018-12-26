#!/bin/bash
PROJECT_ROOT=$(readlink -f $(dirname $0))

CC=gcc
CC_X86="$CC -m32"
CC_X64="$CC -m64"

gcc -v |& grep disable-multilib
MULTILIB_ENABLED=$?

X86_OUT=$PROJECT_ROOT/runtimes/${RID}-x86/native
X64_OUT=$PROJECT_ROOT/runtimes/${RID}-x64/native

rm -f $X86_OUT/ $X64_OUT/
mkdir -p $X86_OUT/ $X64_OUT/

function compile_lzo2 {
  CC=$1 OUT=$2 TYPE=$3

  echo Compiling lzo2/$TYPE
  (cd src/lzo2 && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.lzo2.txt CMakeLists.txt &&
   mkdir build-$TYPE && cd build-$TYPE &&
   CC="$CC" cmake .. -DCMAKE_BUILD_TYPE=RELEASE && make -j4 &&
   cp liblzo2.so $OUT) >& $PROJECT_ROOT/lzo2-$TYPE.log &
}

function compile_bzip2 {
  CC=$1 OUT=$2 TYPE=$3

  echo Compiling bzip2/$TYPE
  (cd src/bzip2 && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.bzip2.txt CMakeLists.txt &&
   mkdir build-$TYPE && cd build-$TYPE &&
   CC="$CC" cmake .. -DCMAKE_BUILD_TYPE=RELEASE && make -j4 &&
   cp libbz2.so $OUT) >& $PROJECT_ROOT/bzip2-$TYPE.log &
}

function compile_lz4 {
  CC=$1 OUT=$2 TYPE=$3

  echo Compiling lz4/$TYPE
  (cd src/lz4/contrib/cmake_unofficial && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.lz4.txt CMakeLists.txt &&
   mkdir build-$TYPE && cd build-$TYPE &&
   CC="$CC" cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=RELEASE && make -j4 &&
   cp liblz4.so $OUT) >& $PROJECT_ROOT/lz4-$TYPE.log &
}

function compile_zlib {
  CC=$1 OUT=$2 ARCH=$3 TYPE=$4
  
  echo Compiling zlib-ng/$TYPE
  (cd src/zlib-ng && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.libz.txt CMakeLists.txt &&
   mkdir build-$TYPE && cd build-$TYPE &&
   CC="$CC" cmake .. -DCMAKE_BUILD_TYPE=RELEASE -DZLIB_COMPAT=1 -DARCH=$ARCH && make -j4 &&
   cp libz.so $OUT) >& $PROJECT_ROOT/zlib-ng-$TYPE.log &
}

function compile_zstd {
  CC=$1 OUT=$2 TYPE=$3

  echo Compiling zstd/$TYPE
  (cd src/zstd/build/cmake && 
   mkdir build-$TYPE && cd build-$TYPE &&
   CC="$CC" cmake .. -DCMAKE_BUILD_TYPE=RELEASE && make -j4 &&
   cp lib/libzstd.so $OUT) >& $PROJECT_ROOT/zstd-$TYPE.log &
}

function compile_lzma {
  CC=$1 OUT=$2 ARCH=$3 TYPE=$4
  
  echo Compiling xz/$TYPE
  (cd src/xz && ./autogen.sh && 
   mkdir build-$TYPE && cd build-$TYPE &&
   CC="$CC" ../configure --enable-shared=yes --host=$ARCH && make V=0 -j4 &&
   cp src/liblzma/.libs/liblzma.so $OUT) >& $PROJECT_ROOT/xz-$TYPE.log &
}

function test_output {
  FILE=$1

  if [[ ! -e "$FILE" ]]; then
    echo $FILE was not compiled... aborting...
    exit 666
  fi
}

compile_lzo2 "$CC_X64" "$X64_OUT" x64

compile_bzip2 "$CC_X64" "$X64_OUT" x64
compile_lz4 "$CC_X64" "$X64_OUT" x64
compile_zlib "$CC_X64" "$X64_OUT" amd64 x64
compile_zstd "$CC_X86" "$X86_OUT" x86
compile_zstd "$CC_X64" "$X64_OUT" x64
compile_lzma "$CC_X64" "$X64_OUT" x86_64-pc-linux-gnu x64

if [[ "$MULTILIB_ENABLED" == "1" ]]; then
  compile_lzo2 "$CC_X86" "$X86_OUT" x86
  compile_bzip2 "$CC_X86" "$X86_OUT" x86
  compile_lz4 "$CC_X86" "$X86_OUT" x86
  compile_zlib "$CC_X86" "$X86_OUT" i686 x86
  compile_lzma "$CC_X86" "$X86_OUT" i686-pc-linux-gnu x86
fi

echo -n Waiting for compilations to finish...
wait
sleep 5
echo Done.

test_output "$X64_OUT/libz.so"
test_output "$X64_OUT/libbz2.so"
test_output "$X64_OUT/liblzma.so"
test_output "$X64_OUT/liblz4.so"
test_output "$X64_OUT/liblzo2.so"
test_output "$X64_OUT/libzstd.so"

if [[ "$MULTILIB_ENABLED" == "1" ]]; then
  test_output "$X86_OUT/libz.so"
  test_output "$X86_OUT/libbz2.so"
  test_output "$X86_OUT/liblzma.so"
  test_output "$X86_OUT/liblz4.so"
  test_output "$X86_OUT/liblzo2.so"
  test_output "$X86_OUT/libzstd.so"
fi

echo Stripping shared objects...
echo Before strip: $(du -chs $PROJECT_ROOT/runtimes/${RID}*/native/*.so | tail -1 | cut -f 1)
for so in $PROJECT_ROOT/runtimes/${RID}*/native/*.so; do 
  strip --strip-unneeded $so
done
echo After strip: $(du -chs $PROJECT_ROOT/runtimes/${RID}*/native/*.so | tail -1 | cut -f 1)
