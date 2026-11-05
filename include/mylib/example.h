#ifndef MYLIB_EXAMPLE_H
#define MYLIB_EXAMPLE_H

// C has no namespaces: every public name of the library starts with "mylib_"
// so that it cannot collide with a name of the program that uses it.

// Returns a + b.
int mylib_add(int a, int b);

#endif
