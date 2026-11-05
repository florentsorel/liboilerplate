// Including our own header lets the compiler check that the definitions
// below match the declarations users see.
#include "mylib/example.h"

// Helpers used only in this file should be "static".

int mylib_add(int a, int b) {
    return a + b;
}
