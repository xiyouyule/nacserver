#!/bin/sh
# Compile the stubs.m file into a .o file
xcrun clang -c stubs.m -o stubs.o -arch x86_64
# Link the stubs.o file into the output file
xcrun clang -shared stubs.o -o STUB -framework Foundation -arch x86_64
# Remove the stubs.o file
rm stubs.o

# If DEBUG is not defined, set it to 0
if [ -z $DEBUG ]; then DEBUG=0; fi
if [ -z $SHOOK ]; then SHOOK=0; fi
echo "DEBUG: "$DEBUG
echo "SHOOK: "$SHOOK
# Compile the viokit.m file into a .o file
xcrun clang -c viokit.m -o viokit.o -arch x86_64 -fobjc-arc -DDEBUG=$DEBUG -DSYSCTLHOOK=$SHOOK
# Compile fishhook
EXTRA=""
if [ $SHOOK -eq 1 ]
then
    xcrun clang -c fishhook.c -o fishhook.o -arch x86_64
    EXTRA="fishhook.o"
fi
# Link the viokit.o file into the output file

xcrun clang -shared viokit.o $EXTRA -o VIOKit -framework Foundation -arch x86_64 
# Remove the viokit.o file
rm viokit.o $EXTRA

# Compile test.m into an executable, don't warn about depracated functions
xcrun clang demo.m -o demo -framework Foundation -framework IOKit -arch x86_64  -fobjc-arc -Wno-deprecated-declarations
# Run the executable
./demo