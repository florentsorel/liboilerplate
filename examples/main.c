// A small program that uses the library the way its users will: through the
// public header, linked against build/<mode>/libmylib.a.
#include <stdio.h>

#include <mylib/example.h>

int main(void) {
    int result = mylib_add(2, 3);
    printf("mylib_add(2, 3) = %d\n", result);
    return 0;
}
