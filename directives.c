#include <stdio.h>

typedef enum {
    ADD  = 0b0001,
    SUB  = 0b0010,
    AND  = 0b0011,
    OR   = 0b0100,
    XOR  = 0b0101,
    NOT  = 0b0110,
    MOV  = 0b0111,
    JMP  = 0b1000,
    JPN  = 0b1001,
    JPNZ = 0b1010,
    CMP  = 0b1011,
    NOP  = 0b1100,
    LBSH = 0b1101,
    RBSH = 0b1110,
    DISP = 0b1111
} DIRECTIVE;