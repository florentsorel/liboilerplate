#ifndef MYLIB_ERROR_H
#define MYLIB_ERROR_H

// Codes returned by the functions that can fail. MYLIB_OK is 0, so
// `if (error != MYLIB_OK)` reads "if it failed".
//
// Convention: a function that fails returns its error code and leaves its
// out parameters untouched; they are written only on MYLIB_OK.
typedef enum {
    MYLIB_OK = 0,
    MYLIB_ERR_EMPTY,
    MYLIB_ERR_NOT_A_NUMBER,
    MYLIB_ERR_OVERFLOW,
} MylibError;

// Describes an error code in English: MYLIB_ERR_OVERFLOW -> "number too
// large". The string is static: do not free it.
const char *mylib_error_string(MylibError error);

#endif
