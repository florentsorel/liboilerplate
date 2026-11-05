#include "mylib/error.h"

const char *mylib_error_string(MylibError error) {
    // No "default:" on purpose: when a code is added to MylibError and not
    // here, -Wswitch (part of -Wall) warns about this switch.
    switch (error) {
        case MYLIB_OK:
            return "no error";
        case MYLIB_ERR_EMPTY:
            return "empty text";
        case MYLIB_ERR_NOT_A_NUMBER:
            return "text contains a non-digit character";
        case MYLIB_ERR_OVERFLOW:
            return "number too large";
    }

    // Reached only with a value that is not a MylibError, e.g. (MylibError)42.
    return "unknown error";
}
