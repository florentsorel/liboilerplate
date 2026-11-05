#ifndef MYLIB_EXAMPLE_H
#define MYLIB_EXAMPLE_H

#include "mylib/error.h"

// C has no namespaces: every public name of the library starts with "mylib_"
// (or "Mylib" for types, "MYLIB_" for macros) so that it cannot collide with
// a name of the program that uses it.

// Returns a + b.
int mylib_add(int a, int b);

// Parses a non-negative decimal number: "42" -> 42. Every character must be
// a digit: no sign, no spaces. On failure, *out is left untouched.
MylibError mylib_parse_number(const char *text, int *out);

#endif
