#include <stdio.h>

char * ITS(int num, int bits) { //int to string (bit)
    char * string = calloc(bits+1, sizeof(char));
    for (int i = 0; i < bits; i++) {
        // Extract the bit at position (numBits - 1 - i) to ensure MSB comes first
        string[i] = ((num >> (bits - 1 - i)) & 1) +'0'; //moving the bit-string checking the last bit each time 10(1010)->1->10->101->1010
    }

    return string;
}

