#!/bin/sh
# Compile the stubs.m file into a .o file
xcrun clang -c stubs.m -o stubs.o -arch x86_64
# Link the stubs.o file into the output file
xcrun clang -shared stubs.o -o STUB -framework Foundation -arch x86_64
# Remove the stubs.o file
rm stubs.o

# Compile the viokit.m file into a .o file
xcrun clang -c viokit.m -o viokit.o -arch x86_64
# Link the viokit.o file into the output file
xcrun clang -shared viokit.o -o VIOKit -framework Foundation -arch x86_64
# Remove the viokit.o file
rm viokit.o

# Compile test.m into an executable
xcrun clang demo.m -o demo -framework Foundation -framework IOKit -arch x86_64
# Run the executable
./demo