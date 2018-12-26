#!/bin/bash
PROJECT_ROOT=$(readlink -f $(dirname $0))

vs=$(/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/Installer/vswhere.exe -latest | grep installationPath | cut -f 2- -d : -d " ") 
MSBuildExePath="$vs/MSBuild/15.0/Bin/MSBuild.exe"

X86_OUT=$PROJECT_ROOT/nuget.package/runtimes/win7-x86/native
X64_OUT=$PROJECT_ROOT/nuget.package/runtimes/win7-x64/native
mkdir -p $X86_OUT
mkdir -p $X64_OUT
mkdir logs

git submodule foreach git clean -fdx
git submodule foreach git reset --hard

function compile_lzo2 {
  PLAT=$1 OUT=$2

  echo Compiling lzo2/$PLAT
  (cd src/lzo2 && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.lzo2.txt CMakeLists.txt &&
   mkdir -p build-$PLAT && cd build-$PLAT && 
   cmake .. -DCMAKE_BUILD_TYPE=RELEASE -G "Visual Studio 15 2017" -A $PLAT && 
   "$MSBuildExePath" lzo_shared.vcxproj -p:Configuration=Release &&
   cp Release/liblzo2.dll $OUT) >& logs/lzo2-$PLAT.log &
}
 
function compile_bzip2 {
  PLAT=$1 OUT=$2

  echo Compiling bzip2/$PLAT

  (cd src/bzip2 && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.bzip2.txt CMakeLists.txt &&
   mkdir -p build-$PLAT && cd build-$PLAT && 
   cmake .. -DCMAKE_BUILD_TYPE=RELEASE -G "Visual Studio 15 2017" -A $PLAT && 
   "$MSBuildExePath" libbz2.vcxproj -p:Configuration=Release &&
   cp Release/libbz2.dll $OUT) >& logs/bzip2-$PLAT.log &
}


function compile_lz4 {
  PLAT=$1 OUT=$2

  echo Compiling lz4/$PLAT
  (cd src/lz4/contrib/cmake_unofficial && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.lz4.txt CMakeLists.txt &&
   mkdir -p build-$PLAT && cd build-$PLAT && 
   cmake .. -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF -DCMAKE_BUILD_TYPE=RELEASE -G "Visual Studio 15 2017" -A $PLAT && 
   "$MSBuildExePath" lz4_shared.vcxproj -p:Configuration=Release &&
   cp Release/liblz4.dll $OUT) >& logs/lz4-$PLAT.log &
}

function compile_zlib {
  PLAT=$1 OUT=$2

  echo Compiling zlib/$PLAT
  (cd src/zlib-ng && 
   cp $PROJECT_ROOT/native-cmakes/CMakeLists.libz.txt CMakeLists.txt &&
   cp $PROJECT_ROOT/native-cmakes/zlib1.rc win32/zlib1.rc &&
   mkdir -p build-$PLAT && cd build-$PLAT && 
   cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=RELEASE -G "Visual Studio 15 2017" -A $PLAT &&
   "$MSBuildExePath" zlib.vcxproj -p:Configuration=Release &&
   cp Release/libz.dll $OUT) >& logs/zlib-$PLAT.log &
}

function compile_zstd {
  PLAT=$1 OUT=$2

  echo Compiling zstd/$PLAT
  (cd src/zstd/build/cmake && 
   mkdir build-$PLAT && cd build-$PLAT &&
   cmake .. -DCMAKE_BUILD_TYPE=RELEASE -G "Visual Studio 15 2017" -A $PLAT &&
   "$MSBuildExePath" lib/libzstd_shared.vcxproj -p:Configuration=Release &&
   cp lib/Release/zstd.dll $OUT) >& logs/zstd-$PLAT.log &
}

function compile_xz {
  PLAT=$1 OUT=$2

  echo Compiling xz/$PLAT
  (cd src/xz/windows && 
   cp -r vs2017 vs2017-$PLAT && cd vs2017-$PLAT &&
   "$MSBuildExePath" liblzma_dll.vcxproj -p:Configuration=Release -p:Platform=$PLAT &&
   cp Release/$PLAT/liblzma_dll/liblzma.dll $OUT) > logs/xz-$PLAT.log &
}

function test_output {
  FILE=$1

  if [[ ! -e "$FILE" ]]; then
    echo $FILE was not compiled... aborting...
    exit 666
  fi
}


compile_lzo2  "Win32" "$X86_OUT"
compile_lzo2  "x64"   "$X64_OUT"
compile_bzip2 "Win32" "$X86_OUT"
compile_bzip2 "x64"   "$X64_OUT"
compile_lz4   "Win32" "$X86_OUT"
compile_lz4   "x64"   "$X64_OUT"
compile_zlib  "Win32" "$X86_OUT"
compile_zlib  "x64"   "$X64_OUT"
compile_zstd  "Win32" "$X86_OUT"
compile_zstd  "x64"   "$X64_OUT"
compile_xz    "Win32" "$X86_OUT"
compile_xz    "x64"   "$X64_OUT"

echo -n Waiting for compilations to finish...
wait
sleep 5
echo Done.

test_output "$X64_OUT/libz.dll"
test_output "$X64_OUT/libbz2.dll"
test_output "$X64_OUT/liblzma.dll"
test_output "$X64_OUT/liblz4.dll"
test_output "$X64_OUT/liblzo2.dll"
test_output "$X64_OUT/zstd.dll"

test_output "$X86_OUT/libz.dll"
test_output "$X86_OUT/libbz2.dll"
test_output "$X86_OUT/liblzma.dll"
test_output "$X86_OUT/liblz4.dll"
test_output "$X86_OUT/liblzo2.dll"
test_output "$X86_OUT/zstd.dll"
