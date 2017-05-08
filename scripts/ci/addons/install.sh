#!/usr/bin/env bash
set -e

export OF_ROOT=$HOME/openFrameworks
export ADDON_NAME=$(basename ${TRAVIS_BUILD_DIR})

echo "OF_ROOT: ${OF_ROOT}"
echo "ADDON_NAME: ${ADDON_NAME}"

# Install the addon in the right location.
echo "Moving ${ADDON_NAME} to ${OF_ROOT}/addons/"
mv -v $TRAVIS_BUILD_DIR $OF_ROOT/addons/;

# Install target specific dependencies.
echo "Installing dependencies for ${TARGET} from ${OF_ROOT}/addons/"
if [ -f $OF_ROOT/scripts/ci/$TARGET/install.sh ]; then
    $OF_ROOT/scripts/ci/$TARGET/install.sh;
fi

# Install pre-compiled binary of library, rather than recompile.
mkdir -pv $OF_ROOT/libs/openFrameworksCompiled/lib/$TARGET/;

# Move into the target lib directory to download directly into the correct directory.
echo "Move into the ${OF_ROOT}/libs/openFrameworksCompiled/lib/${TARGET} directory.";
cd $OF_ROOT/libs/openFrameworksCompiled/lib/$TARGET/;

if [ "$TARGET" == "android" ]; then
    # Make android sub-directories.
    mkdir -v armv7;
    mkdir -v x86;
    cd armv7;
    wget -v http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/armv7/libopenFrameworksDebug.a;
    cd ../x86;
    wget -v http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/x86/libopenFrameworksDebug.a;
    cd ..;
elif [ "$TARGET" == "emscripten" ]; then
    wget -v http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/libopenFrameworksDebug.bc;
else
    wget -v http://ci.openframeworks.cc/openFrameworks_libs/$TARGET/libopenFrameworksDebug.a;
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
        $OF_ROOT/scripts/dev/download_libs.sh -a 64;
    elif [ "$TARGET" == "linuxarmv6l" ]; then
        $OF_ROOT/scripts/linux/download_libs.sh -a armv6l;
    elif [ "$TARGET" == "linuxarmv7l" ]; then
        $OF_ROOT/scripts/linux/download_libs.sh -a armv7l;
    elif [ "$TARGET" == "tvos" ]; then
        $OF_ROOT/scripts/ios/download_libs.sh;
    else
        $OF_ROOT/scripts/$TARGET/download_libs.sh;
    fi
fi

# Install any addon-specific dependencies.
echo "Installing shared addon-specific dependencies ..."
if [ -f $OF_ROOT/addons/$ADDON_NAME/scripts/ci/install.sh ]; then
  $OF_ROOT/addons/$ADDON_NAME/scripts/ci/install.sh;
else
  echo "No shared addon-specific dependencies found."
fi

# Install any platform-specific-addon-specific dependencies.
echo "Installing platform addon-specific dependencies ..."
if [ -f $OF_ROOT/addons/$ADDON_NAME/scripts/ci/$TARGET/install.sh ]; then
    $OF_ROOT/addons/$ADDON_NAME/scripts/ci/$TARGET/install.sh;
else
  echo "No platform addon-specific dependencies found."
fi

# Copy project Makefiles into addon example directories.
echo "Copy project makefiles into addon examples."
for example in ${OF_ROOT}/addons/${ADDON_NAME}/example*; do
    cp -v $OF_ROOT/scripts/templates/$TARGET/Makefile $example/
    cp -v $OF_ROOT/scripts/templates/$TARGET/config.make $example/
done

echo "install.sh finished."
