# NACServer
This is a server that can generate "validation data" necessary for [pypush](https://github.com/JJTech0130/pypush) based on emulated values in a `data.plist`.

`data.plist` can either be obtained by asking me, or using `build_extractor.sh` to generate it on an older mac (M1 macs will not work, or anything without a board-id.

## Using Darling
Darling is now fully supported, however, it currently requires applying https://github.com/darlinghq/darling-xnu/pull/1.
Here are detailed instructions for Debian:
1. `sudo apt install cmake clang-11 bison flex xz-utils libfuse-dev libudev-dev pkg-config \
libc6-dev-i386 libcap2-bin git git-lfs python2 libglu1-mesa-dev libcairo2-dev \
libgl1-mesa-dev libtiff5-dev libfreetype6-dev libxml2-dev libegl1-mesa-dev libfontconfig1-dev \
libbsd-dev libxrandr-dev libxcursor-dev libgif-dev libpulse-dev libavformat-dev libavcodec-dev \
libswresample-dev libdbus-1-dev libxkbfile-dev libssl-dev llvm-dev`
2. `git clone --recursive https://github.com/darlinghq/darling.git`
3. `cd darling`
4. `cd src/external/xnu/`
5. `git pull https://github.com/JJTech0130/darling-xnu`
6. `cd ../../..`
7. `mkdir build && cd build`
8. `cmake .. -DCOMPONENTS=cli_dev -DCMAKE_BUILD_TYPE=Debug -DTARGET_i386=OFF`
9. `make -j4`
10. `sudo make install`
11. `darling shell zsh`
12. (In the Darling shell) `xcode-select --install`

## Running the server
1. `python3 ./stubber.py`
2. (In darling shell if using darling) `./build.sh`
3. (NOT in the darling shell) `python3 ./server.py`
