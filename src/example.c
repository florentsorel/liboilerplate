// Including our own header lets the compiler check that the definitions
// below match the declarations users see.
#include "mylib/example.h"

#include <ctype.h>   // isdigit
#include <limits.h>  // INT_MAX

// Helpers used only in this file should be "static".

int mylib_add(int a, int b) {
    return a + b;
}

MylibError mylib_parse_number(const char *text, int *out) {
    if (*text == '\0') {
        return MYLIB_ERR_EMPTY;
    }

    // The result goes into a local variable first: *out is written only
    // once the whole text has been checked.
    int value = 0;
    for (const char *p = text; *p != '\0'; p++) {
        // isdigit expects a value from 0 to 255: a char can be negative.
        if (!isdigit((unsigned char)*p)) {
            return MYLIB_ERR_NOT_A_NUMBER;
        }
        int digit = *p - '0';

        // value * 10 + digit > INT_MAX, written so that it cannot overflow
        // itself: signed overflow is undefined behaviour.
        if (value > (INT_MAX - digit) / 10) {
            return MYLIB_ERR_OVERFLOW;
        }
        value = value * 10 + digit;
    }

    *out = value;
    return MYLIB_OK;
}
