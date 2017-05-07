#!/usr/bin/env bash
set -e

# Install the addon in the right location.
mv $TRAVIS_BUILD_DIR $OF_ROOT/addons/;

# Install target specific dependencies.
if [ -f scripts/ci/$TARGET/install.sh ]; then
    scripts/ci/$TARGET/install.sh;
fi

# Install pre-compiled binary of library, rather than recompile.
mkdir -p $OF_ROOT/libs/openFrameworksCompiled/lib/$TARGET/;

# Move into the target lib directory to download directly into the correct directory.
cd $OF_ROOT/libs/openFrameworksCompiled/lib/$TARGET/;

if [ "$TARGET" == "android" ]; then
    # Make android sub-directories.
    mkdir armv7;
    mkdir x86;
    cd armv7;
    wget http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/armv7/libopenFrameworksDebug.a;
    cd ../x86;
    wget http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/x86/libopenFrameworksDebug.a;
    cd ..;
elif [ "$TARGET" == "emscripten" ]; then
    wget http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/libopenFrameworksDebug.bc;
else
    wget http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/libopenFrameworksDebug.a;
fi

# Return to the OF_ROOT.
cd $OF_ROOT;

# Install 3rd party libraries.
if [ "$OF_BRANCH" == "master" ]; then
    if [ "$TARGET" == "linux64" ]; then
        # sudo apt-add-repository ppa:ubuntu-toolchain-r/test
        # sudo apt-get update
        # sudo apt-get install gcc-4.9 g++4.9 gdb
        # sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 1 --force
        # sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 1 --force
        gcc --version
        scripts/dev/download_libs.sh -a 64;
    elif [ "$TARGET" == "linuxarmv6l" ]; then
        scripts/linux/download_libs.sh -a armv6l;
    elif [ "$TARGET" == "linuxarmv7l" ]; then
        scripts/linux/download_libs.sh -a armv7l;
    elif [ "$TARGET" == "tvos" ]; then
        scripts/ios/download_libs.sh;
    else
        scripts/$TARGET/download_libs.sh;
    fi
fi

# Install any addon-specific dependencies.
if [ -f addons/${OF_ADDON_NAME}/scripts/ci/install.sh ]; then
    addons/${OF_ADDON_NAME}/scripts/ci/install.sh;
fi

# Install any addon-platform-specific dependencies.
if [ -f addons/${OF_ADDON_NAME}/scripts/ci/$TARGET/install.sh ]; then
    addons/${OF_ADDON_NAME}/scripts/ci/$TARGET/install.sh;
fi

# Copy project Makefiles into addon example directories.
for example in addons/${OF_ADDON_NAME}/example*; do
    cp ${OF_ROOT}/scripts/templates/$TARGET/Makefile $example/
    cp ${OF_ROOT}/scripts/templates/$TARGET/config.make $example/
done
